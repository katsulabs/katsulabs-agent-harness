#Requires -Version 7.4
<#
.SYNOPSIS
  git hooksPath를 .githooks로 설정
.NOTES
  macOS/Linux/Git Bash: ./scripts/install-githooks.sh
#>
. "$PSScriptRoot/shell-env.ps1"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
git config core.hooksPath .githooks
Write-Host "Installed: core.hooksPath=.githooks"
Write-Host "Pre-commit: pwsh scripts/validate-harness.ps1 (or ./scripts/validate-harness.sh)"
Write-Host "Setup: docs/harness/setup-shell.md"
