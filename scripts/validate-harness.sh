#!/usr/bin/env bash
# Harness Gate — 링크·규칙·일관성·템플릿 자동 검증 (macOS / Linux / Git Bash)
# Usage: ./scripts/validate-harness.sh [-Pr]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PR_MODE=false
for arg in "$@"; do
  case "$arg" in
    -Pr|--pr) PR_MODE=true ;;
  esac
done

failures=()
fail() { failures+=("$1"); }

stale_refs=(
  'agent-hierarchy.md' 'workflow.md' 'reference-baseline.md'
  'doc-link-validation' 'cursor-rule-validation' 'doc-consistency' 'pr-quality-gate'
)

# --- helpers ---
resolve_link() {
  local file_dir="$1" target="$2"
  target="${target%%#*}"
  target="$(printf '%s' "$target" | tr -d ' ')"
  [[ -z "$target" ]] && return 1
  if [[ "$target" == /* ]]; then
    echo "$ROOT${target}"
  else
    echo "$(cd "$file_dir" && pwd)/$target"
  fi
}

# --- 1. 링크 ---
md_count=0
while IFS= read -r -d '' file; do
  ((md_count++)) || true
  rel="${file#./}"
  dir="$(dirname "$file")"
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    [[ "$target" =~ ^https?:// ]] && continue
    [[ "$target" =~ ^mailto: ]] && continue
    [[ "$target" =~ ^# ]] && continue
    resolved="$(resolve_link "$dir" "$target" || true)"
    [[ -z "$resolved" ]] && continue
    if [[ ! -e "$resolved" ]]; then
      fail "BROKEN_LINK: $rel -> $target"
    fi
  done < <(grep -oE '\[[^]]*\]\([^)]+\)' "$file" 2>/dev/null | sed -E 's/\[[^]]*\]\(([^)]+)\)/\1/' || true)
done < <(find . -name '*.md' -not -path './.git/*' -print0)

# --- 2. 구 참조·playbook 포맷 ---
while IFS= read -r -d '' file; do
  rel="${file#./}"
  content="$(cat "$file")"
  for stale in "${stale_refs[@]}"; do
    if grep -qF "$stale" <<<"$content"; then
      fail "STALE_REF: $rel — '$stale' 참조"
    fi
  done
  if [[ "$rel" == "docs/harness/playbook.md" ]]; then
    blank=0
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%$'\r'}"
      if [[ -z "$line" ]]; then
        blank=$((blank + 1))
        if (( blank >= 3 )); then
          fail "FORMAT: playbook.md — 연속 빈 줄 3개 이상"
          break
        fi
      else
        blank=0
      fi
    done <<< "$content"
    h1_count="$(grep -cE '^# ' <<<"$content" || true)"
    if (( h1_count > 1 )); then
      fail "FORMAT: playbook.md — h1은 1개만"
    fi
  fi
done < <(find . -name '*.md' -not -path './.git/*' -print0)

# --- 3. 규칙 (.mdc) ---
mdc_dir=".cursor/rules"
always_apply=()
mdc_count=0
if [[ -d "$mdc_dir" ]]; then
  for mdc in "$mdc_dir"/*.mdc; do
    [[ -f "$mdc" ]] || continue
    ((mdc_count++)) || true
    name="$(basename "$mdc")"
    text="$(cat "$mdc")"
    if [[ ! "$text" =~ ^--- ]]; then
      fail "MDC_FORMAT: $name — front-matter 누락"
      continue
    fi
    grep -qE '^description:[[:space:]]*.+' <<<"$text" || fail "MDC_FIELD: $name — description 누락"
    if grep -qE '^alwaysApply:[[:space:]]*true' <<<"$text"; then
      always_apply+=("$name")
      grep -qE '^#[[:space:]]' <<<"$text" || fail "MDC_BODY: $name — 제목 누락"
    else
      grep -qE '^globs:[[:space:]]*.+' <<<"$text" || fail "MDC_FIELD: $name — globs 누락"
    fi
  done
  if [[ ${#always_apply[@]} -ne 1 || "${always_apply[0]}" != "orchestrator.mdc" ]]; then
    fail "MDC_POLICY: alwaysApply:true는 orchestrator.mdc만 (현재: ${always_apply[*]:-none})"
  fi
fi

# --- 4. 역할 규칙 ↔ playbook 범위 ---
playbook_path="docs/harness/playbook.md"
check_role_scopes() {
  local mdc_name="$1" pb_content="$2"
  shift 2
  local mdc_path="$mdc_dir/$mdc_name"
  if [[ ! -f "$mdc_path" ]]; then
    fail "MISSING: .cursor/rules/$mdc_name"
    return
  fi
  local mdc_text scope
  mdc_text="$(cat "$mdc_path")"
  for scope in "$@"; do
    if ! grep -qF "$scope" <<<"$pb_content" || ! grep -qF "$scope" <<<"$mdc_text"; then
      fail "SCOPE_SYNC: $mdc_name ↔ playbook.md — '$scope' 불일치"
    fi
  done
}
if [[ -f "$playbook_path" ]]; then
  pb="$(cat "$playbook_path")"
  check_role_scopes "editor.mdc" "$pb" "docs/**" ".cursor/**" ".github/**"
  check_role_scopes "contract.mdc" "$pb" "db/**" "**/dto/**" "**/openapi.*" "contracts/**" "api-spec/**"
  check_role_scopes "backend.mdc" "$pb" "modules/**" "backend/**" "server/**" "api/**"
  check_role_scopes "frontend.mdc" "$pb" "frontend/**" "client/**" "apps/web/**"
fi

# --- 5. PR 템플릿 ---
pr_tpl=".github/PULL_REQUEST_TEMPLATE.md"
if [[ -f "$pr_tpl" ]]; then
  tpl="$(cat "$pr_tpl")"
  for section in '## 요약' '## 검증 계획' '## 테스트 게이트' '## 하드 게이트'; do
    grep -qF "$section" <<<"$tpl" || fail "PR_TEMPLATE: 필수 섹션 누락 — $section"
  done
else
  fail "MISSING: .github/PULL_REQUEST_TEMPLATE.md"
fi

# --- 6. 일관성 ---
if [[ ! -f "$playbook_path" ]]; then
  fail "MISSING: docs/harness/playbook.md"
else
  pb="$(cat "$playbook_path")"
  for role in Main Editor Contract Backend Frontend QA; do
    grep -qF "$role" <<<"$pb" || fail "CONSISTENCY: playbook.md에 '$role' 없음"
  done
  for mdc in contract.mdc backend.mdc frontend.mdc; do
    [[ -f "$mdc_dir/$mdc" ]] || fail "MISSING: .cursor/rules/$mdc"
  done
fi

[[ -f ".cursor/skills/harness-gate/SKILL.md" ]] || fail "MISSING: .cursor/skills/harness-gate/SKILL.md"

workflow=".github/workflows/harness-gate.yml"
if [[ ! -f "$workflow" ]]; then
  fail "MISSING: .github/workflows/harness-gate.yml"
elif ! grep -q 'test:' "$workflow"; then
  fail "CI: test job 누락"
fi

# --- 6b. 3세대 필수 파일 ---
for f in \
  AGENTS.md CONTRIBUTING.md docs/harness/TEMPLATE.md \
  scripts/run-eval.ps1 scripts/run-eval.sh \
  scripts/validate-harness.sh docs/harness/setup-shell.md \
  .cursor/mcp.json.example docs/harness/examples/sample-ticket-code.md \
  eval/harness-smoke.ps1 eval/harness-smoke.sh \
  eval/agent-smoke.checklist.md eval/reports/README.md \
  docs/harness/handoff-schema.md docs/harness/mcp-setup.md \
  scripts/validate-handoff.ps1 scripts/validate-handoff.sh \
  scripts/validate-status.ps1 scripts/validate-status.sh \
  scripts/dispatch-plan.ps1 scripts/dispatch-plan.sh \
  scripts/collect-handoff.ps1 scripts/collect-handoff.sh \
  docs/harness/status-schema.md docs/harness/examples/status-example.md \
  docs/harness/examples/status-complete.md \
  scripts/run-agent-eval.ps1 scripts/run-agent-eval.sh \
  scripts/dispatch-prompt.ps1 scripts/dispatch-prompt.sh \
  scripts/summarize-eval.ps1 scripts/summarize-eval.sh \
  sample/package.json sample/server/users.test.js \
  docs/harness/secrets.md docs/harness/agent-llm-eval.md \
  .env.example eval/agent-tasks/harness-baseline.md \
  scripts/run-agent-llm-eval.ps1 scripts/run-agent-llm-eval.sh \
  scripts/score-agent-llm.ps1 scripts/score-agent-llm.sh \
  scripts/cost-summary.ps1 scripts/cost-summary.sh \
  scripts/verify-dispatch.ps1 scripts/verify-dispatch.sh \
  docs/harness/secrets-rotation.md \
  eval/agent-tasks/expected/al-01.json \
  docs/harness/first-ticket.md docs/harness/presets/node.md \
  docs/harness/handoffs/README.md \
  scripts/validate-commit-msg.ps1 scripts/validate-todo-sync.ps1 \
  scripts/validate-pr-body.ps1 scripts/validate-staged-handoff.ps1 \
  docs/harness/glossary.md docs/harness/eval-guide.md \
  docs/harness/scripts-reference.md \
  CLAUDE.md .claude/settings.json scripts/role-scopes.json \
  scripts/guard-tool.sh scripts/stop-gate.sh scripts/sync-adapters.sh \
  scripts/context-budget.sh scripts/run-llm-ci.sh scripts/llm-cost.sh \
  docs/harness/modernization.md .github/workflows/llm-eval.yml \
  eval/skills-standalone.test.sh scripts/package-skills.sh \
  .cursor/skills/dispatch/scripts/dispatch-plan.sh .cursor/skills/harness-gate/scripts/gate.sh; do
  [[ -e "$f" ]] || fail "MISSING: $f"
done

# --- 6c. 도구 중립 어댑터 · 컨텍스트 예산 ---
if [[ -f scripts/sync-adapters.sh ]]; then
  bash scripts/sync-adapters.sh --check >/dev/null || fail "ADAPTER: .claude/skills 가 .cursor/skills 와 불일치 — ./scripts/sync-adapters.sh"
fi
grep -qF '@AGENTS.md' CLAUDE.md 2>/dev/null || fail "ADAPTER: CLAUDE.md 는 @AGENTS.md 를 import 해야 함"
if [[ -f scripts/context-budget.sh ]]; then
  bash scripts/context-budget.sh >/dev/null 2>&1 || fail "CONTEXT_BUDGET: 상주 컨텍스트 예산 초과 — scripts/context-budget.sh"
fi
agents="$(cat AGENTS.md)"
grep -q '문서 전용' <<<"$agents" && fail "AGENTS.md: 코드 저장소 계약으로 갱신 필요"

for skill in harness-gate pr-workflow worktree-setup dispatch contract-handoff backend-test-gate; do
  [[ -f ".cursor/skills/$skill/SKILL.md" ]] || fail "MISSING: .cursor/skills/$skill/SKILL.md"
done

# --- 7. PR 모드 ---
if $PR_MODE; then
  branch="$(git branch --show-current 2>/dev/null || true)"
  [[ "$branch" == "main" ]] && fail "PR_BRANCH: main에서 PR 불가"
  commits="$(git log main..HEAD --oneline 2>/dev/null || true)"
  [[ -z "$commits" ]] && fail "PR_COMMITS: main 대비 커밋 없음"
  bash ./scripts/verify-dispatch.sh || fail "DISPATCH: verify-dispatch 실패"
  bash ./scripts/validate-todo-sync.sh || fail "TODO_SYNC: validate-todo-sync 실패"
  bash ./scripts/validate-commit-msg.sh -Pr || fail "COMMIT: validate-commit-msg 실패"
fi

# --- 결과 ---
if [[ ${#failures[@]} -eq 0 ]]; then
  echo "PASS: harness-gate ($md_count md, $mdc_count mdc)"
  exit 0
fi

echo "FAIL: harness-gate (${#failures[@]} issues)"
for f in "${failures[@]}"; do
  echo "  - $f"
done
exit 1
