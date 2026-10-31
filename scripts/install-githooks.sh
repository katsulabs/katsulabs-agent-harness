#!/usr/bin/env bash
# git hooksPath를 .githooks로 설정 (macOS / Linux / Git Bash)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
git config core.hooksPath .githooks
echo "Installed: core.hooksPath=.githooks"
echo "Pre-commit: pwsh scripts/validate-harness.ps1 (or ./scripts/validate-harness.sh)"
echo "Setup: docs/harness/setup-shell.md"
