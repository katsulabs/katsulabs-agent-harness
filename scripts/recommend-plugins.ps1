#Requires -Version 7.4
<#
.SYNOPSIS
  Repo 프로파일 후 서드파티 플러그인 추천·선택 설치
.NOTES
  macOS/Linux/Git Bash: ./scripts/recommend-plugins.sh
  See: docs/harness/third-party-plugins.md
#>
. "$PSScriptRoot/shell-env.ps1"
$bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bash) {
  Write-Error "bash not found. Use Git Bash or ./scripts/recommend-plugins.sh on macOS/Linux."
  exit 1
}
$script = Join-Path $PSScriptRoot "recommend-plugins.sh"
& $bash.Source $script @args
exit $LASTEXITCODE
