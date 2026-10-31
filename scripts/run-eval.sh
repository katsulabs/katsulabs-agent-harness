#!/usr/bin/env bash
# 프로젝트 테스트 eval 스켈레톤 (macOS / Linux / Git Bash)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f package.json ]]; then
  echo 'RUN: npm test'
  npm test
  exit $?
fi
if [[ -f sample/package.json ]]; then
  echo 'RUN: sample npm test'
  (cd sample && npm test)
fi
if [[ -f pom.xml ]]; then
  echo 'RUN: mvn test -q'
  mvn test -q
  exit $?
fi
if [[ -f pyproject.toml ]]; then
  echo 'RUN: pytest'
  pytest
  exit $?
fi

echo 'RUN: harness-smoke (앱 테스트 러너 없음)'
bash ./eval/harness-smoke.sh
exit $?
