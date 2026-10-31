#!/usr/bin/env bash
# 에이전트 훅 (Stop) — 종료 직전 validate-harness. 실패 시 exit 2로 세션 재개 유도.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
input="$(cat)"
# 무한 루프 방지: 이미 훅이 재개시킨 턴이면 통과
if command -v jq >/dev/null 2>&1 && [[ "$(jq -r '.stop_hook_active // false' <<<"$input")" == "true" ]]; then exit 0; fi
out="$(bash "$ROOT/scripts/validate-harness.sh" 2>&1)" && exit 0
echo "harness-gate FAIL — 수정 후 재검증 (scripts/validate-harness.sh):" >&2
echo "$out" | head -20 >&2
exit 2
