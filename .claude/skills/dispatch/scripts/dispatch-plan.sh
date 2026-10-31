#!/usr/bin/env bash
# Plan a multi-agent run: one prompt per role + a status file skeleton. Standalone: bash only.
# Usage: dispatch-plan.sh <TICKET-ID> [--dry-run]
# Env:   HANDOFF_DIR (default: docs/harness/handoffs if it exists, else docs/handoffs)
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TICKET="${1:?Usage: dispatch-plan.sh <TICKET-ID> [--dry-run]}"
DRY=false; [[ "${2:-}" == "--dry-run" ]] && DRY=true
[[ "$TICKET" =~ ^[A-Za-z]+-[0-9]+$ ]] || { echo "FAIL: ticket id like TB-101 (got: $TICKET)"; exit 1; }

dir="${HANDOFF_DIR:-}"
if [[ -z "$dir" ]]; then if [[ -d docs/harness/handoffs ]]; then dir=docs/harness/handoffs; else dir=docs/handoffs; fi; fi
status="$dir/$TICKET-status.md"
roles=(Contract Backend Frontend QA)

echo "# Dispatch Plan — $TICKET"
echo
echo "Order: Contract -> Backend || Frontend -> QA   (Backend and Frontend may run in parallel)"
echo "Status channel: $status"
echo "Before the PR: bash $HERE/collect-handoff.sh $TICKET"
echo
for r in "${roles[@]}"; do
  echo "## [$TICKET][$r]"; echo '```text'
  HANDOFF_DIR="$dir" bash "$HERE/dispatch-prompt.sh" "$TICKET" "$r"
  echo '```'; echo
done

skeleton() {
cat <<EOF
---
ticket: $TICKET
updated: $(date -u +%Y-%m-%d)
---

# Status — $TICKET

| role | status | artifacts | verified |
|------|--------|-----------|----------|
| Contract | todo | — | — |
| Backend | todo | — | — |
| Frontend | todo | — | — |
| QA | todo | — | — |
EOF
}

if $DRY; then
  echo "## Status skeleton (dry-run, not written)"; echo '```markdown'; skeleton; echo '```'
  echo "DRYRUN: dispatch-plan ($TICKET)"; exit 0
fi
mkdir -p "$dir"
if [[ -e "$status" ]]; then echo "SKIP: status file exists — $status"; else skeleton > "$status"; echo "CREATED: $status"; fi
echo "PASS: dispatch-plan ($TICKET)"
