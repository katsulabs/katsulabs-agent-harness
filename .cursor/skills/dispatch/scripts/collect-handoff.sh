#!/usr/bin/env bash
# PR gate for multi-agent work: every role must be status=done with a non-empty 'verified'. Standalone: bash only.
# Usage: collect-handoff.sh <TICKET-ID> | collect-handoff.sh --path <status-file>
# Env:   HANDOFF_DIR (default: docs/harness/handoffs if it exists, else docs/handoffs)
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [[ "${1:-}" == "--path" ]]; then
  path="${2:?--path needs a status file}"
else
  ticket="${1:?Usage: collect-handoff.sh <TICKET-ID> | --path <file>}"
  [[ "$ticket" =~ ^[A-Za-z]+-[0-9]+$ ]] || { echo "FAIL: ticket id like TB-101 (got: $ticket)"; exit 1; }
  dir="${HANDOFF_DIR:-}"
  if [[ -z "$dir" ]]; then if [[ -d docs/harness/handoffs ]]; then dir=docs/harness/handoffs; else dir=docs/handoffs; fi; fi
  path="$dir/$ticket-status.md"
fi
[[ -f "$path" ]] || { echo "FAIL: status file not found — $path (run dispatch-plan first)"; exit 1; }

failures=(); seen=0; qa_done=false
while IFS= read -r line; do
  [[ "$line" =~ ^\| ]] || continue
  [[ "$line" =~ ^\|[[:space:]]*-+ ]] && continue
  role="$(awk -F'|' '{print $2}' <<<"$line" | xargs)"
  status="$(awk -F'|' '{print $3}' <<<"$line" | xargs)"
  verified="$(awk -F'|' '{print $5}' <<<"$line" | xargs)"
  [[ -z "$role" || "$role" == "role" ]] && continue
  seen=$((seen + 1))
  if [[ "$status" != "done" ]]; then failures+=("$role: status=$status (not done)")
  elif [[ -z "$verified" || "$verified" == "—" ]]; then failures+=("$role: 'verified' is empty"); fi
  [[ "$role" == "QA" && "$status" == "done" ]] && qa_done=true
done < "$path"

[[ $seen -gt 0 ]] || failures+=("no role rows found")
$qa_done || failures+=("QA is not done (PR gate)")

if [[ ${#failures[@]} -eq 0 ]]; then echo "PASS: collect-handoff ($path · $seen roles done)"; exit 0; fi
echo "FAIL: collect-handoff (${#failures[@]} issue(s)) -> $path"
printf '  - %s\n' "${failures[@]}"
exit 1
