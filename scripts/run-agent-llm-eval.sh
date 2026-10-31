#!/usr/bin/env bash
# LLM agent eval 세션 템플릿 생성·(선택) 채점 검증
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
VALIDATE=false
[[ "${1:-}" == "-Validate" || "${1:-}" == "--validate" ]] && VALIDATE=true

BASELINE="$ROOT/eval/agent-tasks/harness-baseline.md"
REPORT_DIR="$ROOT/eval/reports"
TEMPLATE="$REPORT_DIR/agent-llm-session.template.md"
SESSION="$REPORT_DIR/agent-llm-session.md"
mkdir -p "$REPORT_DIR"

[[ -f "$BASELINE" ]] || { echo 'FAIL: harness-baseline.md 없음'; exit 1; }

start_ms=$(date +%s%3N 2>/dev/null || echo 0)

{
  echo '# Agent LLM Session'
  echo ''
  echo "생성: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ''
  echo '| ID | 결과 (PASS/FAIL) | 메모 |'
  echo '|----|------------------|------|'
  grep -E '^\| AL-' "$BASELINE" | while IFS='|' read -r _ id prompt expect _; do
    id=$(echo "$id" | xargs)
    prompt=$(echo "$prompt" | xargs)
    expect=$(echo "$expect" | xargs)
    echo "| $id | | $prompt → $expect |"
  done
  echo ''
  echo '수동 실행 후 agent-llm-session.md 저장 · run-agent-llm-eval.sh -Validate'
} > "$TEMPLATE"

task_count=$(grep -cE '^\| AL-' "$BASELINE" || true)

if ! $VALIDATE; then
  [[ -f "$SESSION" ]] || cp "$TEMPLATE" "$SESSION"
  echo "PASS: agent-llm-eval template ($task_count tasks) -> eval/reports/agent-llm-session.md"
  exit 0
fi

[[ -f "$SESSION" ]] || { echo 'FAIL: agent-llm-session.md 없음'; exit 1; }

failures=0
while IFS='|' read -r _ id _ _ _; do
  id=$(echo "$id" | xargs)
  [[ "$id" =~ ^AL- ]] || continue
  grep -qE "\| $id \| (PASS|FAIL) \|" "$SESSION" || failures=$((failures + 1))
done < <(grep -E '^\| AL-' "$BASELINE")

status="PASS"
[[ $failures -eq 0 ]] || status="FAIL"
pass_count=$((task_count - failures))
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

printf '%s\n' "{
  \"suite\": \"agent-llm-eval\",
  \"timestamp\": \"$ts\",
  \"status\": \"$status\",
  \"summary\": { \"pass\": $pass_count, \"fail\": $failures, \"total\": $task_count }
}" > "$REPORT_DIR/latest-agent-llm-eval.json"

if [[ $failures -eq 0 ]]; then
  echo "PASS: agent-llm-eval validate ($task_count tasks)"
  exit 0
fi

echo "FAIL: agent-llm-eval ($failures issues)"
exit 1
