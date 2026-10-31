#!/usr/bin/env bash
# Generate a PR description from the branch's commits. Standalone: git + bash.
# Usage: pr-body.sh [--tests "result text"] [--lang ko|en]   (prints Markdown to stdout)
# Env:   BASE (default origin/<default branch>)  PR_LANG (ko|en, default ko)
set -euo pipefail
TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "FAIL: not inside a git repository" >&2; exit 1; }
cd "$TOP"

LANG_="${PR_LANG:-ko}"; TESTS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tests) TESTS="$2"; shift 2 ;;
    --lang)  LANG_="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

default_branch() {
  local b
  b="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')" || true
  [[ -n "$b" ]] && { echo "$b"; return; }
  for c in main master; do git show-ref --verify --quiet "refs/heads/$c" && { echo "$c"; return; }; done
  echo main
}
def="$(default_branch)"
base="${BASE:-}"
if [[ -z "$base" ]]; then
  if git show-ref --verify --quiet "refs/remotes/origin/$def"; then base="origin/$def"; else base="$def"; fi
fi
[[ "$(git rev-list --count "$base"..HEAD)" -gt 0 ]] || { echo "FAIL: no commits ahead of $base" >&2; exit 1; }

tickets="$(git log --format=%s "$base"..HEAD | grep -oE '[A-Za-z]+-[0-9]+' | sort -u | paste -sd, - | sed 's/,/, /g')"
if [[ "$LANG_" == "en" ]]; then
  H_SUM="## Summary"; H_VER="## Verification plan"; H_TEST="## Test gate"; H_HARD="## Hard gates"
  L_TICKET="Tickets"; L_FILES="Changed files"; L_NONE="(not recorded)"
  GATES=$'- [ ] not merged directly into the default branch\n- [ ] changes stay within the ticket scope\n- [ ] gate/CI green'
else
  H_SUM="## 요약"; H_VER="## 검증 계획"; H_TEST="## 테스트 게이트"; H_HARD="## 하드 게이트"
  L_TICKET="티켓"; L_FILES="변경 파일"; L_NONE="(미기록)"
  GATES=$'- [ ] 기본 브랜치 직접 반영 없음\n- [ ] 티켓 범위 밖 변경 없음\n- [ ] 게이트/CI green'
fi

echo "$H_SUM"; echo
echo "$L_TICKET: ${tickets:-—}"; echo
git log --reverse --format='- %s' "$base"..HEAD; echo
echo "$H_VER"; echo
echo "$L_FILES:"; echo '```text'
git diff --stat "$base"...HEAD | tail -n 30
echo '```'; echo
echo "$H_TEST"; echo
echo "${TESTS:-$L_NONE}"; echo
echo "$H_HARD"; echo
echo "$GATES"
