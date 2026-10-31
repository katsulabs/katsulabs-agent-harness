#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
branch="$(git branch --show-current 2>/dev/null || true)"
# CI detached-HEAD(pull_request) 폴백: GitHub Actions 브랜치 환경변수 사용
[[ -z "$branch" ]] && branch="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"
[[ -n "$branch" ]] || { echo 'FAIL: git branch 확인 불가'; exit 1; }
[[ "$branch" != "main" ]] || { echo 'FAIL: main — feature 브랜치 필요'; exit 1; }
[[ "$branch" =~ ^feature/TB-[0-9]+ ]] || { echo "FAIL: DISPATCH_BRANCH: $branch"; exit 1; }
echo "PASS: verify-dispatch ($branch)"
exit 0
