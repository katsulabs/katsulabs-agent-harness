#!/usr/bin/env bash
# llm-run 리포트(eval/reports/llm-run-*.json) 토큰·비용 집계. 상한 초과 시 실패.
# Usage: llm-cost.sh [--max-usd N]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
MAX=""; [[ "${1:-}" == "--max-usd" ]] && MAX="${2:-}"
shopt -s nullglob
files=(eval/reports/llm-run-*.json)
[[ ${#files[@]} -gt 0 ]] || { echo "PASS: llm-cost (리포트 없음)"; exit 0; }
jq -s '{runs:length, input_tokens:(map(.usage.input_tokens)|add), output_tokens:(map(.usage.output_tokens)|add),
        cost_usd:(map(.usage.cost_usd)|add), failed_runs:(map(select(.status=="FAIL"))|length)}' "${files[@]}" | tee eval/reports/latest-llm-cost.json
if [[ -n "$MAX" ]]; then
  over=$(jq --argjson m "$MAX" '.cost_usd > $m' eval/reports/latest-llm-cost.json)
  [[ "$over" == "false" ]] || { echo "FAIL: llm-cost 상한 초과 (> \$$MAX)"; exit 1; }
fi
echo "PASS: llm-cost"
