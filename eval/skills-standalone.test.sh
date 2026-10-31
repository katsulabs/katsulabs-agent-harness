#!/usr/bin/env bash
# Proves each packaged skill works OUTSIDE this repository:
# copies only the skill folders into a temp area and runs them against a fresh git repo.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/.cursor/skills"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
SK="$tmp/skills"; mkdir -p "$SK"
for s in worktree-setup harness-gate pr-workflow contract-handoff backend-test-gate dispatch; do cp -R "$SRC/$s" "$SK/$s"; done

fails=0
expect() { # want_rc name cmd...
  local want="$1" name="$2"; shift 2
  local out rc; out="$("$@" 2>&1)"; rc=$?
  if [[ $rc -ne $want ]]; then echo "FAIL: $name (rc=$rc want=$want)"; echo "$out" | sed 's/^/    /' | tail -n 8; fails=$((fails + 1)); fi
}

# --- fresh repo with a bare origin, no harness files at all ---
git init -q --bare -b main "$tmp/origin.git"
git clone -q "$tmp/origin.git" "$tmp/work" 2>/dev/null
cd "$tmp/work"
git config user.email t@example.com; git config user.name t
printf 'test:\n\t@echo tests-ok\n' > Makefile
git add Makefile; git commit -q -m "init"; git push -q -u origin main 2>/dev/null
git remote set-head origin main >/dev/null 2>&1 || true

# worktree-setup
WT="$tmp/wt"
expect 0 "worktree create" env WT_DIR="$WT" bash "$SK/worktree-setup/scripts/worktree.sh" create TB-1 demo
[[ -d "$WT/TB-1-demo" ]] || { echo "FAIL: worktree dir missing"; fails=$((fails + 1)); }
expect 1 "worktree create duplicate rejected" env WT_DIR="$WT" bash "$SK/worktree-setup/scripts/worktree.sh" create TB-1 demo
expect 1 "worktree bad name rejected" env WT_DIR="$WT" bash "$SK/worktree-setup/scripts/worktree.sh" create TB-2 "Bad Name"

# work in the ticket worktree
cd "$WT/TB-1-demo"
git config user.email t@example.com; git config user.name t
expect 1 "gate: no commits ahead" bash "$SK/harness-gate/scripts/gate.sh"
mkdir -p server; echo 'x' > server/a.js; git add .; git commit -q -m "TB-1 add server"
expect 0 "gate passes (make test auto-detected)" bash "$SK/harness-gate/scripts/gate.sh"
echo y > server/b.js; git add .; git commit -q -m "no ticket here"
expect 1 "gate: commit without ticket id" bash "$SK/harness-gate/scripts/gate.sh"
git reset -q --soft HEAD~1; git commit -q -m "TB-1 add b"
echo dirty > dirty.txt
expect 1 "gate: dirty tree" bash "$SK/harness-gate/scripts/gate.sh"
rm dirty.txt

# backend-test-gate
expect 0 "test-gate runs on backend change" bash "$SK/backend-test-gate/scripts/test-gate.sh"
out="$(bash "$SK/backend-test-gate/scripts/test-gate.sh" 2>&1)"; grep -q 'PR line: Backend test gate: PASS' <<<"$out" || { echo "FAIL: test-gate PR line"; fails=$((fails + 1)); }
expect 1 "test-gate fails when tests fail" env TEST_CMD="false" bash "$SK/backend-test-gate/scripts/test-gate.sh"

# pr-workflow
expect 0 "pr preflight (warnings allowed)" bash "$SK/pr-workflow/scripts/preflight.sh"
body="$(bash "$SK/pr-workflow/scripts/pr-body.sh" --tests "make test: ok" 2>&1)"
for h in '## 요약' '## 검증 계획' '## 테스트 게이트' '## 하드 게이트'; do grep -qF "$h" <<<"$body" || { echo "FAIL: pr-body missing $h"; fails=$((fails + 1)); }; done
grep -q 'TB-1' <<<"$body" || { echo "FAIL: pr-body missing ticket"; fails=$((fails + 1)); }
body_en="$(PR_LANG=en bash "$SK/pr-workflow/scripts/pr-body.sh" 2>&1)"; grep -qF '## Summary' <<<"$body_en" || { echo "FAIL: pr-body en"; fails=$((fails + 1)); }

# contract-handoff
expect 0 "new-handoff" bash "$SK/contract-handoff/scripts/new-handoff.sh" TB-1 --lang en
expect 0 "validate-handoff on fresh skeleton" bash "$SK/contract-handoff/scripts/validate-handoff.sh"
sed -i.bak '/^## DTO/d' docs/handoffs/TB-1-handoff.md; rm -f docs/handoffs/TB-1-handoff.md.bak
expect 1 "validate-handoff catches missing section" bash "$SK/contract-handoff/scripts/validate-handoff.sh"

# dispatch
expect 0 "dispatch-plan" bash "$SK/dispatch/scripts/dispatch-plan.sh" TB-1
expect 0 "validate-status on skeleton" bash "$SK/dispatch/scripts/validate-status.sh"
expect 1 "collect-handoff blocks while todo" bash "$SK/dispatch/scripts/collect-handoff.sh" TB-1
sed -i.bak -E 's/\| todo \| — \| — \|/| done | x | PASS |/' docs/handoffs/TB-1-status.md; rm -f docs/handoffs/TB-1-status.md.bak
expect 0 "collect-handoff passes when all done" bash "$SK/dispatch/scripts/collect-handoff.sh" TB-1
printf '[Backend]\n' >/dev/null
echo 'Backend=src/**' > /dev/null; mkdir -p .harness; echo 'Backend=src/main/**' > .harness/roles.conf
out="$(bash "$SK/dispatch/scripts/dispatch-prompt.sh" TB-1 Backend)"; grep -qF 'src/main/**' <<<"$out" || { echo "FAIL: roles.conf override"; fails=$((fails + 1)); }

if [[ $fails -eq 0 ]]; then echo "PASS: skills-standalone (6 skills, outside repo)"; exit 0; fi
echo "FAIL: skills-standalone ($fails)"; exit 1
