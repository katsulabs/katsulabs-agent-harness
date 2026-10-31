#Requires -Version 7.4
<#
.SYNOPSIS
  브랜치 티켓 ID가 todo.md에 존재하는지 검증.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$branch = (git branch --show-current 2>$null)
if (-not $branch -or $branch -eq 'main') {
    Write-Host 'SKIP: validate-todo-sync (main)'
    exit 0
}
if ($branch -notmatch 'TB-(\d+)') {
    Write-Host "FAIL: validate-todo-sync — 브랜치 '$branch'에 TB-{id} 없음"
    exit 1
}
$ticket = "TB-$($Matches[1])"
$todo = Get-Content 'docs/harness/todo.md' -Raw
if ($todo -notmatch [regex]::Escape($ticket)) {
    Write-Host "FAIL: validate-todo-sync — $ticket 가 todo.md에 없음"
    exit 1
}
Write-Host "PASS: validate-todo-sync ($ticket)"
exit 0
