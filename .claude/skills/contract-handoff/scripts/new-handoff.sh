#!/usr/bin/env bash
# Create a contract handoff skeleton for a ticket. Standalone: bash only.
# Usage: new-handoff.sh <TICKET-ID> [--lang ko|en]
# Env:   HANDOFF_DIR (default: docs/harness/handoffs if it exists, else docs/handoffs)
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ID="${1:?Usage: new-handoff.sh <TICKET-ID> [--lang ko|en]}"; shift || true
LANG_=ko
[[ "${1:-}" == "--lang" ]] && LANG_="${2:-ko}"
[[ "$ID" =~ ^[A-Za-z]+-[0-9]+$ ]] || { echo "FAIL: ticket id like TB-101 (got: $ID)"; exit 1; }

dir="${HANDOFF_DIR:-}"
if [[ -z "$dir" ]]; then if [[ -d docs/harness/handoffs ]]; then dir=docs/harness/handoffs; else dir=docs/handoffs; fi; fi
mkdir -p "$dir"
out="$dir/${ID}-handoff.md"
[[ ! -e "$out" ]] || { echo "FAIL: $out already exists"; exit 1; }

if [[ "$LANG_" == "en" ]]; then API='## API changes'; else API='## API 변경'; fi
cat > "$out" <<EOF
---
ticket: $ID
from: Contract
to: [Backend, Frontend]
status: blocked
breaking: false
---

$API
- \`GET /api/...\` — query, status codes

## DTO
\`\`\`json
{ "id": "uuid" }
\`\`\`

## DB
- migration: none · additive only · rollback: n/a

## Backend TODO
- [ ]

## Frontend TODO
- [ ]

## Breaking change
없음 / none
EOF
echo "CREATED: $out  (set status: ready when the contract is final)"
