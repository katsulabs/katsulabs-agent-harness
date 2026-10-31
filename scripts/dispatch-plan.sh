#!/usr/bin/env bash
# 오케스트레이션 플랜 — 전 역할 디스패치 프롬프트 + 상태 스켈레톤 생성 (macOS / Linux / Git Bash)
# Usage: dispatch-plan.sh TB-xxx [--dry-run]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TICKET="${1:?Usage: dispatch-plan.sh TB-xxx [--dry-run]}"
DRYRUN=false
[[ "${2:-}" == "--dry-run" || "${2:-}" == "-DryRun" ]] && DRYRUN=true
[[ "$TICKET" =~ ^TB-[0-9]+$ ]] || { echo "FAIL: 티켓 형식 TB-{id} (받음: $TICKET)"; exit 1; }

roles=(Contract Backend Frontend QA)
status_path="docs/harness/handoffs/${TICKET}-status.md"
today="$(date -u +%Y-%m-%d)"

emit_plan() {
  echo "# Dispatch Plan — $TICKET"
  echo
  echo "흐름: Contract → Backend ∥ Frontend → QA"
  echo "상태 채널: $status_path (스키마: docs/harness/status-schema.md)"
  echo "PR 전 게이트: ./scripts/collect-handoff.sh $TICKET"
  echo
  local r
  for r in "${roles[@]}"; do
    echo "## [$TICKET][$r]"
    echo '```text'
    bash ./scripts/dispatch-prompt.sh "$TICKET" "$r"
    echo '```'
    echo
  done
}

emit_status() {
  cat <<EOF
---
ticket: $TICKET
updated: $today
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

emit_plan

if $DRYRUN; then
  echo "## 상태 스켈레톤 (dry-run · 미기록)"
  echo '```markdown'
  emit_status
  echo '```'
  echo "DRYRUN: dispatch-plan ($TICKET)"
  exit 0
fi

if [[ -e "$status_path" ]]; then
  echo "SKIP: 상태 파일 이미 존재 — $status_path"
else
  emit_status > "$status_path"
  echo "CREATED: $status_path"
fi
echo "PASS: dispatch-plan ($TICKET)"
