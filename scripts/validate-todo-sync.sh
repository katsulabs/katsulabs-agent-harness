#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
branch="$(git branch --show-current 2>/dev/null || true)"
[[ -n "$branch" && "$branch" != "main" ]] || { echo 'SKIP: validate-todo-sync (main)'; exit 0; }
[[ "$branch" =~ TB-([0-9]+) ]] || { echo "FAIL: validate-todo-sync — $branch"; exit 1; }
ticket="TB-${BASH_REMATCH[1]}"
grep -qF "$ticket" docs/harness/todo.md || { echo "FAIL: validate-todo-sync — $ticket 없음"; exit 1; }
echo "PASS: validate-todo-sync ($ticket)"
exit 0
