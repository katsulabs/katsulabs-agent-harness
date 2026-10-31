#!/usr/bin/env bash
# Document quality gate for the harness starter.
# Usage: ./scripts/doc-quality-gate.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Document quality gate"

files=()
while IFS= read -r -d '' f; do files+=("$f"); done < <(
  find docs .cursor/rules .github \
    \( -name '*.md' -o -name '*.mdc' \) \
    -print0 2>/dev/null
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No markdown/mdc files found."
  exit 1
fi

echo "Checking ${#files[@]} file(s) for broken links..."
failed=0
for f in "${files[@]}"; do
  if ! npx --yes markdown-link-check "$f" -q; then
    echo "FAIL: $f"
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "Document quality gate FAILED."
  exit 1
fi

echo "Document quality gate PASSED."
