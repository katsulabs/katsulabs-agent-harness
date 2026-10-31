#!/usr/bin/env bash
# Print a role-scoped prompt for one subagent. Standalone: bash only.
# Usage: dispatch-prompt.sh <TICKET-ID> <Role>
# Roles/scopes: defaults below; override per project in .harness/roles.conf, one line per role:
#   Backend=src/main/**, services/**
# Env:   TODO_FILE (default: docs/harness/todo.md or TODO.md, first that exists) - used to quote the ticket's DoD
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

TICKET="${1:?Usage: dispatch-prompt.sh <TICKET-ID> <Role>}"
ROLE="${2:?Usage: dispatch-prompt.sh <TICKET-ID> Editor|Contract|Backend|Frontend|QA}"
[[ "$TICKET" =~ ^[A-Za-z]+-[0-9]+$ ]] || { echo "FAIL: ticket id like TB-101 (got: $TICKET)" >&2; exit 1; }

case "$ROLE" in
  Editor)   SCOPE='docs/**, .cursor/**, .claude/**, .github/**' ;;
  Contract) SCOPE='db/**, **/dto/**, **/openapi.*, contracts/**, api-spec/**' ;;
  Backend)  SCOPE='modules/**, backend/**, server/**, api/**' ;;
  Frontend) SCOPE='frontend/**, client/**, apps/web/**' ;;
  QA)       SCOPE='tests and CI config only; run the project gate, do not edit product code' ;;
  *) echo "Unknown role: $ROLE (Editor|Contract|Backend|Frontend|QA)" >&2; exit 1 ;;
esac
if [[ -f .harness/roles.conf ]]; then
  line="$(grep -E "^${ROLE}=" .harness/roles.conf | head -n1 || true)"
  [[ -n "$line" ]] && SCOPE="${line#*=}"
fi

todo="${TODO_FILE:-}"
if [[ -z "$todo" ]]; then
  for c in docs/harness/todo.md TODO.md docs/todo.md; do [[ -f "$c" ]] && { todo="$c"; break; }; done
fi
dod=""
[[ -n "$todo" && -f "$todo" ]] && dod="$(grep -F "$TICKET" "$todo" | head -n 3 || true)"

hdir="docs/handoffs"; [[ -d docs/harness/handoffs ]] && hdir="docs/harness/handoffs"

cat <<EOF
[$TICKET][$ROLE]

## Scope (edit only these paths)
$SCOPE

## Instructions
- You are the $ROLE agent for $TICKET. Stay inside the scope above; do not touch other roles' files.
- Work only in this ticket's worktree/branch. Never commit to the default branch.
- Read the Contract handoff first if it exists: $hdir/$TICKET-handoff.md
- When done, update ONLY your own row in $hdir/$TICKET-status.md (status, artifacts, verified). Do not report verbally instead.

## Definition of done
${dod:-"(no DoD found - ask the orchestrator; ticket file: ${todo:-none})"}
- tests/checks for your scope pass; record the result in the status file's 'verified' column
EOF
