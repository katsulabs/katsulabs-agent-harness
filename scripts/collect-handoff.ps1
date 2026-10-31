#Requires -Version 7.4
<#
.SYNOPSIS
  오케스트레이션 게이트 — 전 역할 status=done + verified 확인.
.EXAMPLE
  pwsh scripts/collect-handoff.ps1 -Ticket TB-101
.EXAMPLE
  pwsh scripts/collect-handoff.ps1 -Path docs/harness/examples/status-complete.md
.NOTES
  macOS/Linux/Git Bash: ./scripts/collect-handoff.sh
#>
param(
    [string]$Ticket,
    [string]$Path
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (-not $Path) {
    if (-not $Ticket) { Write-Host 'Usage: collect-handoff.ps1 -Ticket TB-xxx | -Path <file>'; exit 1 }
    if ($Ticket -notmatch '^TB-\d+$') { Write-Host "FAIL: 티켓 형식 TB-{id} (받음: $Ticket)"; exit 1 }
    $Path = "docs/harness/handoffs/$Ticket-status.md"
}

$full = Join-Path $root $Path
if (-not (Test-Path $full)) { Write-Host "FAIL: 상태 파일 없음 — $Path (dispatch-plan 먼저)"; exit 1 }

$failures = [System.Collections.Generic.List[string]]::new()
$seen = 0
$qaDone = $false
foreach ($line in (Get-Content -LiteralPath $full)) {
    if ($line -notmatch '^\|') { continue }
    if ($line -match '^\|\s*-+') { continue }
    $cells = $line.Trim('|').Split('|') | ForEach-Object { $_.Trim() }
    if ($cells.Count -lt 4) { continue }
    $role = $cells[0]; $status = $cells[1]; $verified = $cells[3]
    if ($role -eq 'role' -or -not $role) { continue }
    $seen++
    if ($status -ne 'done') {
        $failures.Add("${role}: status=$status (done 아님)")
    } elseif (-not $verified -or $verified -eq '—') {
        $failures.Add("${role}: verified 비어있음")
    }
    if ($role -eq 'QA' -and $status -eq 'done') { $qaDone = $true }
}

if ($seen -eq 0) { $failures.Add('역할 행 없음') }
if (-not $qaDone) { $failures.Add('QA done 아님 (PR 게이트)') }

if ($failures.Count -eq 0) {
    Write-Host "PASS: collect-handoff ($Path · $seen roles done)"
    exit 0
}
Write-Host "FAIL: collect-handoff ($($failures.Count) issues) -> $Path"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
