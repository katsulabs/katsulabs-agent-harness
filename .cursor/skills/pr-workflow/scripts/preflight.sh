#!/usr/bin/env bash
# PR preflight: is this branch ready for `gh pr create`? Standalone: git + bash (+ gh).
# Usage: preflight.sh
set -uo pipefail
TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "FAIL: not inside a git repository"; exit 1; }
cd "$TOP"

default_branch() {
  local b
  b="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')" || true
  [[ -n "$b" ]] && { echo "$b"; return; }
  for c in main master; do git show-ref --verify --quiet "refs/heads/$c" && { echo "$c"; return; }; done
  echo main
}
def="$(default_branch)"; branch="$(git branch --show-current 2>/dev/null || true)"
base="$def"; git show-ref --verify --quiet "refs/remotes/origin/$def" && base="origin/$def"
fails=0
ok()  { echo "  ok    $1"; }
bad() { echo "  FAIL  $1"; fails=$((fails + 1)); }
wrn() { echo "  warn  $1"; }

[[ -n "$branch" && "$branch" != "$def" ]] && ok "branch $branch" || bad "need a feature branch (on '${branch:-detached}')"
n="$(git rev-list --count "$base"..HEAD 2>/dev/null || echo 0)"
[[ "$n" -gt 0 ]] && ok "$n commit(s) ahead of $base" || bad "no commits ahead of $base"
[[ -z "$(git status --porcelain)" ]] && ok "working tree clean" || bad "uncommitted changes"
if git remote get-url origin >/dev/null 2>&1; then
  if git rev-parse --verify --quiet "origin/$branch" >/dev/null && [[ "$(git rev-list --count "origin/$branch"..HEAD)" -eq 0 ]]; then
    ok "branch pushed and up to date"
  else
    wrn "branch not pushed (git push -u origin $branch)"
  fi
else
  wrn "no 'origin' remote"
fi
if command -v gh >/dev/null 2>&1; then
  gh auth status >/dev/null 2>&1 && ok "gh authenticated" || wrn "gh not authenticated (gh auth login)"
else
  wrn "gh CLI not installed — open the PR in the web UI with the generated body"
fi
[[ $fails -eq 0 ]] && { echo "PASS: preflight"; exit 0; }
echo "FAIL: preflight ($fails issue(s))"; exit 1
