#!/usr/bin/env bash
# 마켓플레이스/배포용: 스킬 폴더를 개별 아카이브로 패키징 (dist/skills/<name>.zip)
# Usage: package-skills.sh [skill ...]   (기본: 6개 전부)
# 먼저 단독 동작 테스트(eval/skills-standalone.test.sh)를 통과해야 패키징한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SKILLS=("$@"); [[ ${#SKILLS[@]} -gt 0 ]] || SKILLS=(harness-gate pr-workflow worktree-setup dispatch contract-handoff backend-test-gate)

bash eval/skills-standalone.test.sh || { echo "FAIL: 단독 동작 테스트 실패 — 패키징 중단"; exit 1; }
[[ -f LICENSE ]] || echo "WARN: LICENSE 없음 — 배포 전 확인"
out="dist/skills"; rm -rf "$out"; mkdir -p "$out"
for s in "${SKILLS[@]}"; do
  d=".cursor/skills/$s"; [[ -f "$d/SKILL.md" ]] || { echo "FAIL: $d/SKILL.md 없음"; exit 1; }
  stage="$(mktemp -d)"; cp -R "$d" "$stage/$s"
  [[ -f LICENSE ]] && cp LICENSE "$stage/$s/LICENSE"
  if command -v zip >/dev/null 2>&1; then (cd "$stage" && zip -qr "$ROOT/$out/$s.zip" "$s")
  else tar -czf "$out/$s.tar.gz" -C "$stage" "$s"; fi
  rm -rf "$stage"
  echo "packaged: $s"
done
ls -1 "$out"
echo "PASS: package-skills (${#SKILLS[@]})"
