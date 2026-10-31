#Requires -Version 7.4
<#
.SYNOPSIS
  브랜치·티켓 디스패치 규약 검증.
.EXAMPLE
  pwsh scripts/verify-dispatch.ps1
.EXAMPLE
  pwsh scripts/verify-dispatch.ps1 -Ticket TB-101
#>
param([string]$Ticket)

$ErrorActionPreference = 'Stop'
$branch = (git branch --show-current 2>$null)
# CI detached-HEAD(pull_request) 폴백: GitHub Actions 브랜치 환경변수 사용
if (-not $branch) { $branch = if ($env:GITHUB_HEAD_REF) { $env:GITHUB_HEAD_REF } else { $env:GITHUB_REF_NAME } }
if (-not $branch) {
    Write-Host 'FAIL: git branch 확인 불가'
    exit 1
}

if ($branch -eq 'main') {
    Write-Host 'FAIL: main — feature 브랜치에서 디스패치'
    exit 1
}

if ($branch -notmatch '^feature/TB-(\d+)') {
    Write-Host "FAIL: DISPATCH_BRANCH: '$branch' — feature/TB-{id}-* 필요"
    exit 1
}

$branchTicket = "TB-$($Matches[1])"
if ($Ticket -and $Ticket -ne $branchTicket) {
    Write-Host "FAIL: DISPATCH_TICKET: 브랜치 $branchTicket ≠ 인자 $Ticket"
    exit 1
}

Write-Host "PASS: verify-dispatch ($branch · $branchTicket)"
exit 0
