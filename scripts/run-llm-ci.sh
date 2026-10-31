#!/usr/bin/env bash
# 실제 LLM 에이전트 회귀 (헤드리스 `claude -p`) + 토큰/비용 기록.
# Usage: run-llm-ci.sh [--ids AL-01,AL-03,AL-04] [--model M] [--budget USD] [--dry-run]
#   --dry-run: LLM 호출 없이 fixture(good) 응답 + 가짜 usage로 파이프라인만 검증 (CI 무료)
# 의존: bash, jq, claude CLI (실호출 시, ANTHROPIC_API_KEY 또는 로그인)
# 산출: eval/reports/llm-run-<UTC>.json · latest-llm-run.json
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v jq >/dev/null 2>&1 || { echo "FAIL: jq 필요"; exit 1; }

IDS="AL-01,AL-03,AL-04"; MODEL=""; BUDGET="0.50"; DRY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ids) IDS="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --budget) BUDGET="$2"; shift 2 ;;
    --dry-run) DRY=true; shift ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done
$DRY || command -v claude >/dev/null 2>&1 || { echo "FAIL: claude CLI 없음 (--dry-run 가능)"; exit 1; }

BASELINE=eval/agent-tasks/harness-baseline.md
OUT=eval/reports; mkdir -p "$OUT"

# must / must_not 채점 (score-agent-llm.ps1 Test-Rules 와 동일 의미, 대소문자 무시 부분 문자열)
score() { # $1=rules.json $2=text → "ok" | "missing must: x" | "forbidden: x"
  local rules="$1" text lower m
  text="$2"; lower="$(tr '[:upper:]' '[:lower:]' <<<"$text")"
  while IFS= read -r m; do
    [[ -z "$m" ]] && continue
    grep -qiF -- "$m" <<<"$text" || { echo "missing must: $m"; return 1; }
  done < <(jq -r '.must[]?' "$rules")
  if [[ "$(jq -r '(.must_any // []) | length' "$rules")" -gt 0 ]]; then
    local any=1
    while IFS= read -r m; do grep -qiF -- "$m" <<<"$text" && any=0; done < <(jq -r '.must_any[]' "$rules")
    [[ $any -eq 0 ]] || { echo "missing must_any"; return 1; }
  fi
  while IFS= read -r m; do
    [[ -z "$m" ]] && continue
    grep -qiF -- "$m" <<<"$text" && { echo "forbidden: $m"; return 1; }
  done < <(jq -r '.must_not[]?' "$rules")
  echo ok
}

results='[]'; fails=0; in_tok=0; out_tok=0; cost=0
IFS=',' read -r -a id_arr <<<"$IDS"
for id in "${id_arr[@]}"; do
  num=$((10#${id#AL-})); n=$(printf '%02d' "$num")
  rules="eval/agent-tasks/expected/al-$n.json"
  [[ -f "$rules" ]] || { echo "skip $id: rules 없음"; continue; }
  prompt="$(grep -E "^\| $id \|" "$BASELINE" | awk -F'|' '{print $3}' | sed -E 's/^ *`?//; s/`? *$//')"
  [[ -n "$prompt" ]] || { echo "skip $id: prompt 없음"; continue; }

  if $DRY; then
    fx="eval/agent-tasks/fixtures/al-$n-good.txt"
    [[ -f "$fx" ]] || { echo "skip $id: fixture 없음"; continue; }
    raw="$(jq -n --rawfile r "$fx" '{result:$r,total_cost_usd:0,duration_ms:0,usage:{input_tokens:0,output_tokens:0}}')"
  else
    args=(-p "$prompt" --output-format json --permission-mode plan --no-session-persistence --max-budget-usd "$BUDGET")
    [[ -n "$MODEL" ]] && args+=(--model "$MODEL")
    raw="$(claude "${args[@]}" 2>/dev/null)" || raw='{"is_error":true,"result":""}'
    jq -e . >/dev/null 2>&1 <<<"$raw" || raw="$(jq -n --arg r "$raw" '{is_error:true,result:$r}')"
  fi

  text="$(jq -r '.result // ""' <<<"$raw")"
  reason="$(score "$rules" "$text")"; rc=$?
  [[ $rc -eq 0 ]] || fails=$((fails + 1))
  i=$(jq -r '(.usage.input_tokens // 0) + (.usage.cache_creation_input_tokens // 0) + (.usage.cache_read_input_tokens // 0)' <<<"$raw")
  o=$(jq -r '.usage.output_tokens // 0' <<<"$raw")
  c=$(jq -r '.total_cost_usd // 0' <<<"$raw")
  d=$(jq -r '.duration_ms // 0' <<<"$raw")
  in_tok=$((in_tok + i)); out_tok=$((out_tok + o)); cost=$(awk -v a="$cost" -v b="$c" 'BEGIN{printf "%.6f", a+b}')
  results="$(jq --arg id "$id" --argjson pass "$([[ $rc -eq 0 ]] && echo true || echo false)" --arg reason "$reason" \
    --argjson i "$i" --argjson o "$o" --argjson c "$c" --argjson d "$d" \
    '. + [{id:$id,pass:$pass,reason:$reason,input_tokens:$i,output_tokens:$o,cost_usd:$c,duration_ms:$d}]' <<<"$results")"
  echo "$([[ $rc -eq 0 ]] && echo PASS || echo FAIL) $id — $reason (in=$i out=$o \$$c)"
done

total=$(jq 'length' <<<"$results")
[[ $total -gt 0 ]] || { echo "FAIL: 실행된 태스크 없음"; exit 1; }
status=PASS; [[ $fails -eq 0 ]] || status=FAIL
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
report="$(jq -n --arg ts "$ts" --arg st "$status" --arg model "${MODEL:-default}" --argjson dry "$DRY" \
  --argjson r "$results" --argjson i "$in_tok" --argjson o "$out_tok" --argjson c "$cost" \
  '{suite:"llm-run",timestamp:$ts,status:$st,model:$model,dry_run:$dry,
    summary:{pass:($r|map(select(.pass))|length),fail:($r|map(select(.pass|not))|length),total:($r|length)},
    usage:{input_tokens:$i,output_tokens:$o,cost_usd:$c},results:$r}')"
stamp="${ts//[:-]/}"
echo "$report" > "$OUT/llm-run-$stamp.json"; echo "$report" > "$OUT/latest-llm-run.json"
echo "$status: llm-run ($total tasks, dry=$DRY, \$$cost) -> $OUT/latest-llm-run.json"
[[ $fails -eq 0 ]]
