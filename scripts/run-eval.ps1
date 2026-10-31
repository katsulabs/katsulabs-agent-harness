#Requires -Version 7.4
<#
.SYNOPSIS
  프로젝트 테스트 eval 스켈레톤. 팀 스택에 맞게 수정.
.NOTES
  macOS/Linux/Git Bash: ./scripts/run-eval.sh
#>
. "$PSScriptRoot/shell-env.ps1"
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (Test-Path 'package.json') {
    Write-Host 'RUN: npm test'
    npm test
    exit $LASTEXITCODE
}
if (Test-Path 'sample/package.json') {
    Write-Host 'RUN: sample npm test'
    Push-Location (Join-Path $root 'sample')
    try {
        npm test
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } finally {
        Pop-Location
    }
}
if (Test-Path 'pom.xml') {
    Write-Host 'RUN: mvn test -q'
    mvn test -q
    exit $LASTEXITCODE
}
if (Test-Path 'pyproject.toml') {
    Write-Host 'RUN: pytest'
    pytest
    exit $LASTEXITCODE
}

Write-Host 'RUN: harness-smoke (앱 테스트 러너 없음)'
& pwsh -NoProfile -File (Join-Path $root 'eval/harness-smoke.ps1')
exit $LASTEXITCODE
