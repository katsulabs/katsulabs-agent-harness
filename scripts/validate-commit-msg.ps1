#Requires -Version 7.4
<#
.SYNOPSIS
  PR 범위 커밋 메시지에 티켓 ID(TB-xxx) 포함 검증.
#>
param([switch]$Pr)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$range = if ($Pr) { 'main..HEAD' } else { 'HEAD~1..HEAD' }
$commits = git log $range --format='%H %s' 2>$null
if (-not $commits) {
    Write-Host 'SKIP: validate-commit-msg (커밋 없음)'
    exit 0
}

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($line in ($commits -split "`n")) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $msg = ($line -split ' ', 2)[1]
    if ($msg -notmatch 'TB-\d+') {
        $failures.Add("COMMIT_MSG: '$msg' — TB-{id} 누락")
    }
}

if ($failures.Count -eq 0) {
    Write-Host 'PASS: validate-commit-msg'
    exit 0
}
Write-Host "FAIL: validate-commit-msg ($($failures.Count))"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
