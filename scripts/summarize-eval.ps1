#Requires -Version 7.4
<#
.SYNOPSIS
  eval JSON 리포트를 PR용 Markdown 요약으로 출력.
.EXAMPLE
  pwsh scripts/summarize-eval.ps1 -OutFile eval/reports/pr-eval-summary.md
#>
param([string]$OutFile)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$rootReports = Join-Path $root 'eval/reports'
$reportDir = $rootReports  # session·cost는 루트 유지
# 티켓 격리 리포트 우선, 없으면 루트 폴백
$branch = (git branch --show-current 2>$null)
$ticketReports = if ($branch -match 'TB-(\d+)') { Join-Path $root "eval/reports/TB-$($Matches[1])" } else { $rootReports }

function Read-Report([string]$name) {
    $path = Join-Path $ticketReports $name
    if (-not (Test-Path $path)) { $path = Join-Path $rootReports $name }
    if (-not (Test-Path $path)) { return $null }
    Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

$lines = [System.Collections.Generic.List[string]]::new()
function Add-Line([string]$s) { $lines.Add($s) }

function Format-ReportLine([string]$label, $report) {
    if (-not $report) {
        Add-Line "- ${label}: _(리포트 없음)_"
        return
    }
    $dur = if ($report.PSObject.Properties['duration_ms']) { " · $($report.duration_ms)ms" } else { '' }
    Add-Line "- ${label}: **$($report.status)** ($($report.timestamp)$dur)"
    if ($report.summary) {
        Add-Line "  - checks: $($report.summary.pass)/$($report.summary.total) pass"
    }
}

$smoke = Read-Report 'latest-harness-smoke.json'
$agent = Read-Report 'latest-agent-eval.json'
$llm = Read-Report 'latest-agent-llm-eval.json'
$session = Join-Path $reportDir 'agent-llm-session.md'

Add-Line '## Eval 요약'
Add-Line ''
Format-ReportLine 'harness-smoke' $smoke
Format-ReportLine 'agent-eval' $agent

if ($llm) {
    Format-ReportLine 'agent-llm-eval' $llm
} elseif (Test-Path $session) {
    Add-Line '- agent-llm-eval: _(세션 있음 — `-Validate`로 채점)_'
} else {
    Add-Line '- agent-llm-eval: _(미실행 — run-agent-llm-eval)_'
}

if ($agent -and $agent.checks) {
    $failed = @($agent.checks | Where-Object { $_.status -eq 'FAIL' })
    foreach ($f in $failed) { Add-Line "  - FAIL $($f.id): $($f.detail)" }
}

$costPath = Join-Path $reportDir 'latest-cost-summary.json'
if (Test-Path $costPath) {
    $cost = Get-Content $costPath -Raw | ConvertFrom-Json
    Add-Line "- cost-summary: **$($cost.total_duration_ms)ms** · cost_units=$($cost.cost_units)"
}

Add-Line ''
Add-Line '_생성: `pwsh scripts/summarize-eval.ps1`_'

$out = $lines -join "`n"
if ($OutFile) {
    $path = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $root $OutFile }
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    Set-Content -LiteralPath $path -Value $out -Encoding utf8
    Write-Host "PASS: summarize-eval -> $OutFile"
} else {
    $out | ForEach-Object { Write-Output $_ }
}
