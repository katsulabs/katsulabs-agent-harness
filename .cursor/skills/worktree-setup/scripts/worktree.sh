#!/usr/bin/env bash
# Create / remove / list one git worktree per ticket. Standalone: needs only git + bash.
# Usage:
#   worktree.sh create <TICKET-ID> <short-name>
#   worktree.sh remove <TICKET-ID> <short-name> [--delete-branch]
#   worktree.sh list
# Env: WT_DIR (default ../.worktrees)  BRANCH_PREFIX (default feature/)  BASE (default: origin/<default branch>)
set -euo pipefail

TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "FAIL: not inside a git repository"; exit 1; }
cd "$TOP"
WT_DIR="${WT_DIR:-../.worktrees}"
PREFIX="${BRANCH_PREFIX:-feature/}"

default_branch() {
  local b
  b="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')" || true
  [[ -n "$b" ]] && { echo "$b"; return; }
  for c in main master; do git show-ref --verify --quiet "refs/heads/$c" && { echo "$c"; return; }; done
  echo main
}

check_args() {
  [[ "${1:-}" =~ ^[A-Za-z]+-[0-9]+$ ]] || { echo "FAIL: ticket id like TB-101 (got: ${1:-})"; exit 1; }
  [[ "${2:-}" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "FAIL: short-name must be lowercase kebab-case (got: ${2:-})"; exit 1; }
}

cmd="${1:-}"; shift || true
case "$cmd" in
  create)
    check_args "${1:-}" "${2:-}"
    id="$1"; name="$2"; branch="${PREFIX}${id}-${name}"; path="$WT_DIR/${id}-${name}"
    def="$(default_branch)"
    git fetch origin "$def" >/dev/null 2>&1 || echo "WARN: could not fetch origin/$def (continuing with local refs)"
    base="${BASE:-}"
    if [[ -z "$base" ]]; then
      if git show-ref --verify --quiet "refs/remotes/origin/$def"; then base="origin/$def"; else base="$def"; fi
    fi
    [[ ! -e "$path" ]] || { echo "FAIL: $path already exists (one worktree per ticket)"; exit 1; }
    git show-ref --verify --quiet "refs/heads/$branch" && { echo "FAIL: branch $branch already exists"; exit 1; }
    git worktree add "$path" -b "$branch" "$base"
    # keep worktrees out of git if the directory lives inside the repo
    abs="$(cd "$path" && pwd)"
    if [[ "$abs" == "$TOP"/* ]]; then
      rel="${abs#"$TOP"/}"; top_dir="${rel%%/*}/"
      grep -qxF "$top_dir" .gitignore 2>/dev/null || { echo "$top_dir" >> .gitignore; echo "added $top_dir to .gitignore"; }
    fi
    echo "PASS: worktree $path (branch $branch, base $base)"
    ;;
  remove)
    check_args "${1:-}" "${2:-}"
    id="$1"; name="$2"; branch="${PREFIX}${id}-${name}"; path="$WT_DIR/${id}-${name}"
    git worktree remove "$path"
    if [[ "${3:-}" == "--delete-branch" ]]; then git branch -d "$branch"; fi
    echo "PASS: removed $path"
    ;;
  list)
    git worktree list
    ;;
  *)
    echo "Usage: worktree.sh create <ID> <name> | remove <ID> <name> [--delete-branch] | list"; exit 1 ;;
esac
