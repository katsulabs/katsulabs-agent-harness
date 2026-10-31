#!/usr/bin/env bash
# 도구 중립 어댑터 동기화: 원본(.cursor/skills/<harness skill>/ 폴더 전체) → .claude/skills
# Usage: sync-adapters.sh [--check]   (--check: 불일치 시 exit 1, 쓰기 없음)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
CHECK=false; [[ "${1:-}" == "--check" ]] && CHECK=true

SKILLS=(harness-gate pr-workflow worktree-setup dispatch contract-handoff backend-test-gate)
drift=()
for s in "${SKILLS[@]}"; do
  src=".cursor/skills/$s"; dst=".claude/skills/$s"
  [[ -f "$src/SKILL.md" ]] || { echo "FAIL: 원본 없음 $src/SKILL.md"; exit 1; }
  # 폴더 전체(scripts/, references/ 포함) 비교·복사
  if ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
    if $CHECK; then drift+=("$dst"); else rm -rf "$dst"; mkdir -p ".claude/skills"; cp -R "$src" "$dst"; echo "sync: $dst"; fi
  fi
done

if $CHECK; then
  if [[ ${#drift[@]} -gt 0 ]]; then
    echo "FAIL: adapters out of sync (./scripts/sync-adapters.sh 실행)"; printf '  - %s\n' "${drift[@]}"; exit 1
  fi
  echo "PASS: adapters in sync (${#SKILLS[@]} skills)"
else
  echo "PASS: sync-adapters (${#SKILLS[@]} skills)"
fi
