#Requires -Version 7.4
<#
.SYNOPSIS
  오케스트레이션 플랜 — 전 역할 디스패치 프롬프트 + 상태 스켈레톤 생성.
.EXAMPLE
  pwsh scripts/dispatch-plan.ps1 -Ticket TB-101
.EXAMPLE
  pwsh scripts/dispatch-plan.ps1 -Ticket TB-101 -DryRun
.NOTES
  macOS/Linux/Git Bash: ./scripts/dispatch-plan.sh
#>
param(
    [Parameter(Mandatory)][string]$Ticket,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if ($Ticket -notmatch '^TB-\d+$') { Write-Host "FAIL: 티켓 형식 TB-{id} (받음: $Ticket)"; exit 1 }

$roles = @('Contract', 'Backend', 'Frontend', 'QA')
$statusPath = "docs/harness/handoffs/$Ticket-status.md"
$today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')

function Get-StatusSkeleton {
    @"
---
ticket: $Ticket
updated: $today
---

# Status — $Ticket

| role | status | artifacts | verified |
|------|--------|-----------|----------|
| Contract | todo | — | — |
| Backend | todo | — | — |
| Frontend | todo | — | — |
| QA | todo | — | — |
"@
}

$out = [System.Collections.Generic.List[string]]::new()
$out.Add("# Dispatch Plan — $Ticket")
$out.Add('')
$out.Add('흐름: Contract → Backend ∥ Frontend → QA')
$out.Add("상태 채널: $statusPath (스키마: docs/harness/status-schema.md)")
$out.Add("PR 전 게이트: pwsh scripts/collect-handoff.ps1 -Ticket $Ticket")
$out.Add('')
foreach ($r in $roles) {
    $out.Add("## [$Ticket][$r]")
    $out.Add('```text')
    $prompt = & pwsh -NoProfile -File (Join-Path $root 'scripts/dispatch-prompt.ps1') -Ticket $Ticket -Role $r
    foreach ($l in $prompt) { $out.Add([string]$l) }
    $out.Add('```')
    $out.Add('')
}
$out | ForEach-Object { Write-Output $_ }

if ($DryRun) {
    Write-Output '## 상태 스켈레톤 (dry-run · 미기록)'
    Write-Output '```markdown'
    Write-Output (Get-StatusSkeleton)
    Write-Output '```'
    Write-Output "DRYRUN: dispatch-plan ($Ticket)"
    exit 0
}

$statusFull = Join-Path $root $statusPath
if (Test-Path $statusFull) {
    Write-Output "SKIP: 상태 파일 이미 존재 — $statusPath"
} else {
    Set-Content -LiteralPath $statusFull -Value (Get-StatusSkeleton) -Encoding utf8
    Write-Output "CREATED: $statusPath"
}
Write-Output "PASS: dispatch-plan ($Ticket)"
