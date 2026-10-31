#!/usr/bin/env bash
# Lint status files (frontmatter + role table). Standalone: bash only.
# Usage: validate-status.sh [file ...]   (default: all *-status.md in the handoff dir)
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

dir="${HANDOFF_DIR:-}"
if [[ -z "$dir" ]]; then if [[ -d docs/harness/handoffs ]]; then dir=docs/harness/handoffs; else dir=docs/handoffs; fi; fi
allowed_status=" todo in_progress done blocked "
allowed_role=" Contract Backend Frontend QA Editor "
failures=(); fail() { failures+=("$1"); }

check() {
  local f="$1" seen=0 line role status
  [[ -f "$f" ]] || { fail "MISSING: $f"; return; }
  [[ "$(head -n 1 "$f")" == "---" ]] || { fail "FRONTMATTER: $f — must start with '---'"; return; }
  grep -qE '^ticket:' "$f" || fail "FRONTMATTER: $f — 'ticket:' missing"
  grep -qE '^\|[[:space:]]*role[[:space:]]*\|[[:space:]]*status[[:space:]]*\|[[:space:]]*artifacts[[:space:]]*\|[[:space:]]*verified[[:space:]]*\|' "$f" \
    || { fail "HEADER: $f — table header 'role|status|artifacts|verified' missing"; return; }
  while IFS= read -r line; do
    [[ "$line" =~ ^\| ]] || continue
    [[ "$line" =~ ^\|[[:space:]]*-+ ]] && continue
    role="$(awk -F'|' '{print $2}' <<<"$line" | xargs)"; status="$(awk -F'|' '{print $3}' <<<"$line" | xargs)"
    [[ -z "$role" || "$role" == "role" ]] && continue
    seen=$((seen + 1))
    [[ "$allowed_role" == *" $role "* ]] || fail "ROLE: $f — unknown role '$role'"
    [[ "$allowed_status" == *" $status "* ]] || fail "STATUS: $f — unknown status '$status' ($role)"
  done < "$f"
  [[ $seen -gt 0 ]] || fail "ROWS: $f — no role rows"
}

targets=("$@")
if [[ ${#targets[@]} -eq 0 && -d "$dir" ]]; then
  while IFS= read -r f; do targets+=("$f"); done < <(find "$dir" -name '*-status.md' -type f | sort)
fi
if [[ ${#targets[@]} -eq 0 ]]; then echo "PASS: validate-status (no status files in $dir)"; exit 0; fi
for t in "${targets[@]}"; do check "$t"; done
if [[ ${#failures[@]} -eq 0 ]]; then echo "PASS: validate-status (${#targets[@]} file(s))"; exit 0; fi
echo "FAIL: validate-status (${#failures[@]} issue(s))"; printf '  - %s\n' "${failures[@]}"; exit 1
