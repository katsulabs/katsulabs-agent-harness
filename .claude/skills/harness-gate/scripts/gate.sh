#!/usr/bin/env bash
# Pre-PR quality gate for any git repo. Standalone: git + bash (+ your test runner).
# Usage: gate.sh [--no-tests]
# Env:   TICKET_PATTERN (default '[A-Za-z]+-[0-9]+')  BASE  TEST_CMD  SKIP_TESTS=1
# Exit:  0 all required checks pass, 1 otherwise
set -uo pipefail

TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "FAIL: not inside a git repository"; exit 1; }
cd "$TOP"
PATTERN="${TICKET_PATTERN:-[A-Za-z]+-[0-9]+}"
RUN_TESTS=true
[[ "${1:-}" == "--no-tests" || "${SKIP_TESTS:-}" == "1" ]] && RUN_TESTS=false

default_branch() {
  local b
  b="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')" || true
  [[ -n "$b" ]] && { echo "$b"; return; }
  for c in main master; do git show-ref --verify --quiet "refs/heads/$c" && { echo "$c"; return; }; done
  echo main
}
detect_test_cmd() {
  if [[ -n "${TEST_CMD:-}" ]]; then echo "$TEST_CMD"
  elif [[ -f package.json ]] && grep -q '"test"' package.json; then echo "npm test"
  elif [[ -x ./gradlew ]]; then echo "./gradlew test"
  elif [[ -f pom.xml ]]; then echo "mvn -q test"
  elif [[ -f go.mod ]]; then echo "go test ./..."
  elif [[ -f Cargo.toml ]]; then echo "cargo test"
  elif [[ -f pytest.ini || -f pyproject.toml || -d tests ]] && command -v pytest >/dev/null 2>&1; then echo "pytest -q"
  elif [[ -f Makefile ]] && grep -qE '^test:' Makefile; then echo "make test"
  fi
}

fails=(); warns=()
ok()   { echo "  ok    $1"; }
bad()  { echo "  FAIL  $1"; fails+=("$1"); }
warn() { echo "  warn  $1"; warns+=("$1"); }

def="$(default_branch)"
base="${BASE:-}"
if [[ -z "$base" ]]; then
  if git show-ref --verify --quiet "refs/remotes/origin/$def"; then base="origin/$def"; else base="$def"; fi
fi
branch="$(git branch --show-current 2>/dev/null || true)"
echo "gate: branch=${branch:-detached} base=$base"

# 1. never gate from the default branch
if [[ -z "$branch" ]]; then warn "detached HEAD"
elif [[ "$branch" == "$def" ]]; then bad "on default branch '$def' — work on a feature branch"
else ok "branch '$branch' is not '$def'"; fi

# 2. commits ahead of base
ahead="$(git rev-list --count "$base"..HEAD 2>/dev/null || echo 0)"
if [[ "$ahead" -gt 0 ]]; then ok "$ahead commit(s) ahead of $base"; else bad "no commits ahead of $base"; fi

# 3. ticket id in every commit subject
missing=0
while IFS= read -r subj; do
  [[ -z "$subj" ]] && continue
  grep -qE "$PATTERN" <<<"$subj" || { missing=$((missing + 1)); echo "        no ticket id: $subj"; }
done < <(git log --format=%s "$base"..HEAD 2>/dev/null)
[[ $missing -eq 0 ]] && ok "all commit subjects carry a ticket id ($PATTERN)" || bad "$missing commit subject(s) without ticket id"

# 4. clean working tree
if [[ -z "$(git status --porcelain)" ]]; then ok "working tree clean"; else bad "uncommitted changes present"; fi

# 5. project's own harness validator, when present (full katsulabs harness)
if [[ -f scripts/validate-harness.sh ]]; then
  if bash scripts/validate-harness.sh -Pr >/dev/null 2>&1; then ok "scripts/validate-harness.sh -Pr"; else bad "scripts/validate-harness.sh -Pr failed (run it for details)"; fi
fi

# 6. tests
if $RUN_TESTS; then
  cmd="$(detect_test_cmd)"
  if [[ -z "$cmd" ]]; then
    warn "no test command detected — set TEST_CMD"
  elif bash -c "$cmd" >/tmp/gate-tests.$$ 2>&1; then
    ok "tests: $cmd"
  else
    bad "tests failed: $cmd (last lines below)"; tail -n 15 /tmp/gate-tests.$$ | sed 's/^/        /'
  fi
  rm -f /tmp/gate-tests.$$
else
  warn "tests skipped"
fi

if [[ ${#fails[@]} -eq 0 ]]; then echo "PASS: gate (${#warns[@]} warning(s))"; exit 0; fi
echo "FAIL: gate (${#fails[@]} issue(s))"; exit 1
