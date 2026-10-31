#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
file="${1:-}"
if [[ -n "$file" ]]; then text="$(cat "$file")"; else text="$(cat)"; fi
[[ -n "$text" ]] || { echo 'FAIL: validate-pr-body — 본문 없음'; exit 1; }
failures=()
for sec in '## 요약' '## 검증 계획' '## 테스트 게이트' '## 하드 게이트'; do
  grep -qF "$sec" <<<"$text" || failures+=("PR_BODY: $sec 누락")
done
grep -q 'validate-harness' <<<"$text" || failures+=('PR_BODY: validate-harness 누락')
[[ ${#failures[@]} -eq 0 ]] && { echo 'PASS: validate-pr-body'; exit 0; }
echo "FAIL: validate-pr-body (${#failures[@]})"
for f in "${failures[@]}"; do echo "  - $f"; done
exit 1
