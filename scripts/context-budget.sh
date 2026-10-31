#!/usr/bin/env bash
# 컨텍스트 예산: 상주(always-on) 문서의 대략 토큰(≈ bytes/3, 보수적)을 측정·상한 검사.
# Usage: context-budget.sh [--json]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BUDGET_ALWAYS=${BUDGET_ALWAYS:-1500}     # 상주 합계 상한 (tokens)
BUDGET_PLAYBOOK=${BUDGET_PLAYBOOK:-1700} # playbook 상한

tok() { local c; c=$(wc -c < "$1" | tr -d " "); echo $(( (c + 2) / 3 )); }  # bytes/3: 한글(3B≈1tok)·영문 혼합 보수적 근사
always=(AGENTS.md CLAUDE.md .cursor/rules/orchestrator.mdc)
total=0; rows=()
for f in "${always[@]}"; do
  [[ -f "$f" ]] || continue
  t=$(tok "$f"); total=$((total + t)); rows+=("$f $t")
done
pb=$(tok docs/harness/playbook.md)

if [[ "${1:-}" == "--json" ]]; then
  printf '{"always_on_tokens":%d,"playbook_tokens":%d,"budget_always":%d,"budget_playbook":%d}\n' "$total" "$pb" "$BUDGET_ALWAYS" "$BUDGET_PLAYBOOK"
else
  printf '%-40s %s\n' "file" "~tokens"
  for r in "${rows[@]}"; do printf '%-40s %s\n' "${r% *}" "${r##* }"; done
  printf '%-40s %s (budget %s)\n' "ALWAYS-ON total" "$total" "$BUDGET_ALWAYS"
  printf '%-40s %s (budget %s)\n' "docs/harness/playbook.md" "$pb" "$BUDGET_PLAYBOOK"
fi
fail=0
(( total > BUDGET_ALWAYS )) && { echo "FAIL: always-on 컨텍스트 초과 ($total > $BUDGET_ALWAYS)" >&2; fail=1; }
(( pb > BUDGET_PLAYBOOK )) && { echo "FAIL: playbook 초과 ($pb > $BUDGET_PLAYBOOK)" >&2; fail=1; }
[[ $fail -eq 0 ]] && echo "PASS: context-budget"
exit $fail
