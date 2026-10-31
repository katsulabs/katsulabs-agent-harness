#!/usr/bin/env bash
# guard-tool.sh 훅 단위 테스트 (main 브랜치 케이스는 임시 repo 로 격리)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq 없음"; exit 0; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q -b main
git -C "$tmp" symbolic-ref HEAD refs/heads/feature/TB-000-t
fails=0
run() { # want_rc role json name
  local want="$1" role="$2" json="$3" name="$4" rc
  HARNESS_ROLE="$role" bash "$ROOT/scripts/guard-tool.sh" <<<"$json" >/dev/null 2>&1; rc=$?
  [[ $rc -eq $want ]] || { echo "FAIL: $name (rc=$rc want=$want)"; fails=$((fails + 1)); }
}
bashj() { jq -nc --arg c "$1" --arg d "$tmp" '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}'; }
editj() { jq -nc --arg f "$tmp/$1" --arg d "$tmp" '{tool_name:"Edit",cwd:$d,tool_input:{file_path:$f}}'; }

run 0 "" "$(bashj 'git commit -m x')" "feature commit allowed"
run 2 "" "$(bashj 'git push origin main')" "push main denied"
run 2 "" "$(bashj 'ls && git push --force origin feature/x')" "force push denied"
run 0 "" "$(bashj 'git push -u origin feature/TB-000-t')" "push feature allowed"
git -C "$tmp" symbolic-ref HEAD refs/heads/main
run 2 "" "$(bashj 'git commit -m x')" "main commit denied"
run 0 "" "$(bashj 'git status')" "main status allowed"
git -C "$tmp" symbolic-ref HEAD refs/heads/feature/TB-000-t
run 0 Backend "$(editj server/a.js)" "BE server allowed"
run 2 Backend "$(editj client/a.js)" "BE client denied"
run 0 Contract "$(editj x/api-spec/openapi.yaml)" "contract nested openapi allowed"
run 2 Contract "$(editj server/a.js)" "contract server denied"
run 0 Frontend "$(editj apps/web/a.tsx)" "FE web allowed"
run 2 Nope "$(editj a)" "unknown role denied"
run 0 "" "$(editj anything)" "no role passes"

if [[ $fails -eq 0 ]]; then echo "PASS: guard-tool (13 cases)"; exit 0; fi
echo "FAIL: guard-tool ($fails)"; exit 1
