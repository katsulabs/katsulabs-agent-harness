#!/usr/bin/env bash
# Agent eval 정적 프록시 (macOS / Linux / Git Bash)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# 리포트 경로: 인자 우선 · 없으면 브랜치 TB-{id} 기준 격리 (동시 실행 클로버 방지)
if [[ -n "${1:-}" ]]; then
  REPORT_DIR="$1"
else
  _branch="$(git branch --show-current 2>/dev/null || true)"
  if [[ "$_branch" =~ TB-([0-9]+) ]]; then REPORT_DIR="eval/reports/TB-${BASH_REMATCH[1]}"; else REPORT_DIR="eval/reports"; fi
fi

failures=0
results=()

add_check() {
  local id="$1" name="$2" pass="$3" detail="$4"
  local status="PASS"
  if [[ "$pass" != "true" ]]; then
    status="FAIL"
    failures=$((failures + 1))
  fi
  results+=("    {\"id\":\"$id\",\"name\":\"$name\",\"status\":\"$status\",\"detail\":\"$detail\"}")
}

orch="$(cat .cursor/rules/orchestrator.mdc)"
pr_skill="$(cat .cursor/skills/pr-workflow/SKILL.md)"
handoff="$(cat docs/harness/examples/contract-handoff.md)"

if grep -q 'todo\.md' <<<"$orch" && grep -q 'playbook 전체 로드 금지' <<<"$orch"; then
  add_check 'AS-01' 'todo 우선 로드' true 'orchestrator에 todo.md·playbook 전체 로드 금지'
else
  add_check 'AS-01' 'todo 우선 로드' false 'orchestrator에 todo.md·playbook 전체 로드 금지'
fi

if [[ -f docs/harness/handoff-schema.md ]] && head -1 docs/harness/examples/contract-handoff.md | grep -q '^---'; then
  add_check 'AS-02' 'handoff 형식' true 'handoff-schema + 예시 frontmatter'
else
  add_check 'AS-02' 'handoff 형식' false 'handoff-schema + 예시 frontmatter'
fi

if grep -q 'validate-harness' <<<"$pr_skill" && grep -q 'run-eval' <<<"$pr_skill"; then
  add_check 'AS-03' 'PR 검증 절차' true 'pr-workflow에 validate-harness + run-eval'
else
  add_check 'AS-03' 'PR 검증 절차' false 'pr-workflow에 validate-harness + run-eval'
fi

if grep -q 'main' <<<"$orch" && grep -q '직접 커밋 금지' <<<"$orch"; then
  add_check 'AS-04' 'main 커밋 금지' true 'orchestrator main 직접 커밋 금지'
else
  add_check 'AS-04' 'main 커밋 금지' false 'orchestrator main 직접 커밋 금지'
fi

timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
total=4
pass_count=$((total - failures))
status="PASS"
[[ $failures -eq 0 ]] || status="FAIL"

mkdir -p "$REPORT_DIR"
checks_joined=$(IFS=,; echo "${results[*]}")
report=$(cat <<EOF
{
  "suite": "agent-eval",
  "timestamp": "$timestamp",
  "status": "$status",
  "summary": { "pass": $pass_count, "fail": $failures, "total": $total },
  "checks": [
$checks_joined
  ]
}
EOF
)

stamped="$REPORT_DIR/agent-eval-${timestamp//:/-}"
stamped="${stamped//Z/}"
echo "$report" > "$REPORT_DIR/latest-agent-eval.json"
echo "$report" > "${stamped}.json"

if [[ $failures -eq 0 ]]; then
  echo "PASS: agent-eval ($total checks) -> $REPORT_DIR/latest-agent-eval.json"
  exit 0
fi

echo "FAIL: agent-eval ($failures/$total) -> $REPORT_DIR/latest-agent-eval.json"
exit 1
