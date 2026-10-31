#!/usr/bin/env bash
# eval JSON 리포트를 PR용 Markdown 요약으로 출력
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_REPORTS="$ROOT/eval/reports"
# 티켓 격리 리포트 우선, 없으면 루트 폴백
_branch="$(git branch --show-current 2>/dev/null || true)"
if [[ "$_branch" =~ TB-([0-9]+) ]]; then TICKET_REPORTS="$ROOT/eval/reports/TB-${BASH_REMATCH[1]}"; else TICKET_REPORTS="$ROOT_REPORTS"; fi
resolve_report() {
  local n="$1"
  if [[ -f "$TICKET_REPORTS/$n" ]]; then echo "$TICKET_REPORTS/$n"; else echo "$ROOT_REPORTS/$n"; fi
}

read_field() {
  local file="$1" field="$2"
  [[ -f "$file" ]] || return 1
  grep -o "\"$field\": *\"[^\"]*\"" "$file" | head -1 | sed 's/.*: *"\([^"]*\)"/\1/'
}

echo '## Eval 요약'
echo

smoke="$(resolve_report latest-harness-smoke.json)"
agent="$(resolve_report latest-agent-eval.json)"

if [[ -f "$smoke" ]]; then
  st=$(read_field "$smoke" status || echo '?')
  ts=$(read_field "$smoke" timestamp || echo '?')
  echo "- harness-smoke: **$st** ($ts)"
else
  echo '- harness-smoke: _(리포트 없음 — run-eval 실행)_'
fi

if [[ -f "$agent" ]]; then
  st=$(read_field "$agent" status || echo '?')
  ts=$(read_field "$agent" timestamp || echo '?')
  echo "- agent-eval: **$st** ($ts)"
else
  echo '- agent-eval: _(리포트 없음 — run-agent-eval 실행)_'
fi

echo
echo '_생성: `./scripts/summarize-eval.sh`_'
