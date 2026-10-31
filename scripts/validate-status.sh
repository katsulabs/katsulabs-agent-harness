#!/usr/bin/env bash
# Status 파일 린터 — frontmatter·역할 상태 표 검증 (macOS / Linux / Git Bash)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

allowed_status="todo in_progress done blocked"
allowed_role="Contract Backend Frontend QA Editor"

failures=()
fail() { failures+=("$1"); }

in_list() { local needle="$1" list="$2" x; for x in $list; do [[ "$x" == "$needle" ]] && return 0; done; return 1; }

test_status_file() {
  local rel="$1" path="$ROOT/$1"
  [[ -f "$path" ]] || return 0

  if ! awk 'BEGIN{n=0} /^---$/{n++} END{exit (n>=2 && NR>1)?0:1}' "$path"; then
    fail "STATUS_FM: $rel — YAML frontmatter 누락"; return
  fi
  grep -qE '^ticket:' "$path" || fail "STATUS_FM: $rel — 'ticket:' 누락"

  grep -qE '^\|[[:space:]]*role[[:space:]]*\|[[:space:]]*status[[:space:]]*\|[[:space:]]*artifacts[[:space:]]*\|[[:space:]]*verified[[:space:]]*\|' "$path" \
    || { fail "STATUS_HDR: $rel — role|status|artifacts|verified 헤더 누락"; return; }

  local seen=0 line role status
  while IFS= read -r line; do
    [[ "$line" =~ ^\| ]] || continue
    [[ "$line" =~ ^\|[[:space:]]*-+ ]] && continue
    role="$(awk -F'|' '{print $2}' <<<"$line" | xargs)"
    status="$(awk -F'|' '{print $3}' <<<"$line" | xargs)"
    [[ "$role" == "role" ]] && continue
    [[ -z "$role" ]] && continue
    seen=$((seen + 1))
    in_list "$role" "$allowed_role" || fail "STATUS_ROLE: $rel — 알 수 없는 role '$role'"
    in_list "$status" "$allowed_status" || fail "STATUS_STATUS: $rel — 알 수 없는 status '$status' ($role)"
  done < "$path"
  [[ $seen -gt 0 ]] || fail "STATUS_ROWS: $rel — 역할 행 없음"
}

targets=(docs/harness/examples/status-example.md docs/harness/examples/status-complete.md)
if [[ -d docs/harness/handoffs ]]; then
  while IFS= read -r f; do targets+=("$f"); done < <(find docs/harness/handoffs -name '*-status.md' -type f 2>/dev/null | sort)
fi

for t in "${targets[@]}"; do test_status_file "$t"; done

if [[ ${#failures[@]} -eq 0 ]]; then
  echo "PASS: validate-status (${#targets[@]} files)"
  exit 0
fi

echo "FAIL: validate-status (${#failures[@]} issues)"
for f in "${failures[@]}"; do echo "  - $f"; done
exit 1
