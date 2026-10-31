#Requires -Version 7.4
<#
.SYNOPSIS
  eval 리포트 duration 집계·비용 추정 요약.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$reportDir = Join-Path $root 'eval/reports'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$totalMs = 0
$entries = [System.Collections.Generic.List[hashtable]]::new()
foreach ($name in @(
    'latest-harness-smoke.json', 'latest-agent-eval.json',
    'latest-agent-llm-eval.json', 'latest-agent-llm-score.json'
)) {
    $path = Join-Path $reportDir $name
    if (-not (Test-Path $path)) { continue }
    $j = Get-Content $path -Raw | ConvertFrom-Json
    $ms = [long]($j.duration_ms ?? 0)
    $totalMs += $ms
    $entries.Add(@{ suite = $j.suite; status = $j.status; duration_ms = $ms })
}

# 스크립트 실행 시간 기반 추정 단위 (토큰 대용 지표)
$costUnits = [math]::Round($totalMs / 1000.0, 2)
$report = @{
    suite            = 'cost-summary'
    timestamp        = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    total_duration_ms = $totalMs
    cost_units       = $costUnits
    note             = 'cost_units = total_duration_ms/1000 (스크립트 부하 추정, LLM 토큰 아님)'
    entries          = $entries
}
Set-Content (Join-Path $reportDir 'latest-cost-summary.json') -Value ($report | ConvertTo-Json -Depth 5) -Encoding utf8
Write-Host "PASS: cost-summary ${totalMs}ms · cost_units=$costUnits"
exit 0
