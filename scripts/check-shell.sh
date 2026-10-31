#!/usr/bin/env bash
# Harness shell check — bash (macOS/Linux/Git Bash) + optional pwsh
set -euo pipefail

MIN_BASH_MAJOR=3
MIN_PWSH_VERSION="7.4.0"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

bash_major="${BASH_VERSINFO[0]:-0}"
if (( bash_major < MIN_BASH_MAJOR )); then
  fail "bash $BASH_VERSION — minimum ${MIN_BASH_MAJOR}.x"
fi
echo "PASS: bash $BASH_VERSION"

if command -v pwsh >/dev/null 2>&1; then
  pwsh_ver="$(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null || true)"
  if [[ -n "$pwsh_ver" ]]; then
    # shellcheck disable=SC3010
    if [[ "$(printf '%s\n' "$MIN_PWSH_VERSION" "$pwsh_ver" | sort -V | head -1)" != "$MIN_PWSH_VERSION" ]]; then
      fail "pwsh $pwsh_ver — minimum $MIN_PWSH_VERSION (see docs/harness/setup-shell.md)"
    fi
    echo "PASS: pwsh $pwsh_ver (>= $MIN_PWSH_VERSION)"
  fi
else
  echo "INFO: pwsh not found — use ./scripts/*.sh on macOS/Linux/Git Bash"
fi
