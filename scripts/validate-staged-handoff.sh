#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
staged="$(git diff --cached --name-only 2>/dev/null || true)"
echo "$staged" | grep -qE 'handoff.*\.md$|docs/harness/handoffs/.+\.md$' || exit 0
bash ./scripts/validate-handoff.sh
