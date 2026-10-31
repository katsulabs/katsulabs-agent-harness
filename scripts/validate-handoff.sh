#!/usr/bin/env bash
# Handoff 문서 린터 (macOS / Linux / Git Bash)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=()
fail() { failures+=("$1"); }

required_fm=(ticket from to status breaking)
required_sections=(
  '## API 변경' '## DTO' '## DB'
  '## Backend TODO' '## Frontend TODO' '## Breaking change'
)

test_handoff_file() {
  local rel="$1"
  local path="$ROOT/$rel"
  [[ -f "$path" ]] || return 0
  local content
  content="$(cat "$path")"

  if ! awk 'BEGIN{n=0} /^---$/{n++} END{exit (n>=2 && NR>1)?0:1}' "$path"; then
    fail "HANDOFF_FM: $rel — YAML frontmatter 누락 (파일 시작)"
    return
  fi

  for key in "${required_fm[@]}"; do
    grep -qE "^${key}:" <<<"$content" || fail "HANDOFF_FM: $rel — '${key}:' 누락"
  done
  for sec in "${required_sections[@]}"; do
    grep -qF "$sec" <<<"$content" || fail "HANDOFF_SEC: $rel — '$sec' 누락"
  done
}

targets=(docs/harness/examples/contract-handoff.md)
if [[ -d docs/harness/handoffs ]]; then
  while IFS= read -r f; do
    [[ "$(basename "$f")" == "README.md" ]] && continue
    [[ "$(basename "$f")" == *-status.md ]] && continue   # status 파일은 validate-status 담당
    targets+=("$f")
  done < <(find docs/harness/handoffs -name '*.md' -type f 2>/dev/null | sort)
fi
[[ ${#targets[@]} -gt 0 ]] || fail 'HANDOFF: 검사 대상 없음'

for t in "${targets[@]}"; do test_handoff_file "$t"; done

if [[ ${#failures[@]} -eq 0 ]]; then
  echo "PASS: validate-handoff (${#targets[@]} files)"
  exit 0
fi

echo "FAIL: validate-handoff (${#failures[@]} issues)"
for f in "${failures[@]}"; do echo "  - $f"; done
exit 1
