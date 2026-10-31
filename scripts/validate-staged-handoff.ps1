#Requires -Version 7.4
<#
.SYNOPSIS
  staged handoff 파일 변경 시 validate-handoff 실행.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$staged = git diff --cached --name-only 2>$null
$handoff = @($staged | Where-Object {
    $_ -match 'handoff.*\.md$' -or $_ -like 'docs/harness/handoffs/*.md'
})
if ($handoff.Count -eq 0) { exit 0 }

& pwsh -NoProfile -File (Join-Path $root 'scripts/validate-handoff.ps1')
exit $LASTEXITCODE
