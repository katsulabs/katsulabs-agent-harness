#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
range='HEAD~1..HEAD'
[[ "${1:-}" == "-Pr" ]] && range='main..HEAD'

failures=()
commits="$(git log "$range" --format='%h %s' 2>/dev/null || true)"
if [[ -z "$commits" ]]; then echo 'SKIP: validate-commit-msg'; exit 0; fi
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  msg="${line#* }"
  grep -qE 'TB-[0-9]+' <<<"$msg" || failures+=("COMMIT_MSG: '$msg'")
done <<<"$commits"

if [[ ${#failures[@]} -eq 0 ]]; then echo 'PASS: validate-commit-msg'; exit 0; fi
echo "FAIL: validate-commit-msg (${#failures[@]})"
for f in "${failures[@]}"; do echo "  - $f"; done
exit 1
