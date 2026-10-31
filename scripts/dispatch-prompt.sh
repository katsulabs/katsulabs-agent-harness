#!/usr/bin/env bash
# 서브에이전트 디스패치 프롬프트 생성
set -euo pipefail

TICKET="${1:?Usage: dispatch-prompt.sh TB-xxx Role}"
ROLE="${2:?Usage: dispatch-prompt.sh TB-xxx Editor|Contract|Backend|Frontend|QA}"

case "$ROLE" in
  Editor)   SCOPE='docs/**, .cursor/**, .github/**' ;;
  Contract) SCOPE='db/**, **/dto/**, contracts/**, api-spec/**' ;;
  Backend)  SCOPE='modules/**, backend/**, server/**, api/**' ;;
  Frontend) SCOPE='frontend/**, client/**, apps/web/**' ;;
  QA)       SCOPE='validate-harness, run-eval, CI' ;;
  *) echo "Unknown role: $ROLE" >&2; exit 1 ;;
esac

cat <<EOF
[$TICKET][$ROLE]

## 범위
$SCOPE

## 지시
역할 규칙(.cursor/rules)과 playbook 서브에이전트 섹션을 따른다.

## DoD
- docs/harness/todo.md 의 $TICKET DoD 충족
- PR 직전: validate-harness -Pr + run-eval

## 참조
- AGENTS.md · playbook.md (필요 섹션만)
- sample: docs/harness/examples/sample-ticket-code.md
EOF
