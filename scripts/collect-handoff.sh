#!/usr/bin/env bash
# 오케스트레이션 게이트 — 전 역할 status=done + verified 확인 (macOS / Linux / Git Bash)
# Usage: collect-handoff.sh TB-xxx | collect-handoff.sh --path <status-file>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

path=""
if [[ "${1:-}" == "--path" || "${1:-}" == "-Path" ]]; then
  path="${2:?--path 뒤 상태 파일 경로 필요}"
else
  ticket="${1:?Usage: collect-handoff.sh TB-xxx | --path <file>}"
  [[ "$ticket" =~ ^TB-[0-9]+$ ]] || { echo "FAIL: 티켓 형식 TB-{id} (받음: $ticket)"; exit 1; }
  path="docs/harness/handoffs/${ticket}-status.md"
fi

[[ -f "$path" ]] || { echo "FAIL: 상태 파일 없음 — $path (dispatch-plan 먼저)"; exit 1; }

failures=()
seen=0
qa_done=false
while IFS= read -r line; do
  [[ "$line" =~ ^\| ]] || continue
  [[ "$line" =~ ^\|[[:space:]]*-+ ]] && continue
  role="$(awk -F'|' '{print $2}' <<<"$line" | xargs)"
  status="$(awk -F'|' '{print $3}' <<<"$line" | xargs)"
  verified="$(awk -F'|' '{print $5}' <<<"$line" | xargs)"
  [[ "$role" == "role" || -z "$role" ]] && continue
  seen=$((seen + 1))
  if [[ "$status" != "done" ]]; then
    failures+=("$role: status=$status (done 아님)")
  elif [[ -z "$verified" || "$verified" == "—" ]]; then
    failures+=("$role: verified 비어있음")
  fi
  [[ "$role" == "QA" && "$status" == "done" ]] && qa_done=true
done < "$path"

[[ $seen -gt 0 ]] || failures+=("역할 행 없음")
$qa_done || failures+=("QA done 아님 (PR 게이트)")

if [[ ${#failures[@]} -eq 0 ]]; then
  echo "PASS: collect-handoff ($path · $seen roles done)"
  exit 0
fi
echo "FAIL: collect-handoff (${#failures[@]} issues) -> $path"
for f in "${failures[@]}"; do echo "  - $f"; done
exit 1
