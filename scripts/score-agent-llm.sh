#!/usr/bin/env bash
# LLM 응답 자동 채점 — fixture 모드 (macOS / Linux / Git Bash)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
pwsh ./scripts/score-agent-llm.ps1 -Fixture "$@"
