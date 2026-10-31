#Requires -Version 7.4
<#
.SYNOPSIS
  Agent eval 정적 프록시 — checklist 항목을 파일·규약으로 자동 검증.
.NOTES
  LLM 시뮬레이션은 eval/agent-smoke.checklist.md 수동. macOS/Linux: ./scripts/run-agent-eval.sh
#>
param([string]$ReportDir = '')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

# 리포트 경로: 인자 우선 · 없으면 브랜치 TB-{id} 기준 격리 (동시 실행 클로버 방지)
if (-not $ReportDir) {
    $branch = (git branch --show-current 2>$null)
    $ReportDir = if ($branch -match 'TB-(\d+)') { "eval/reports/TB-$($Matches[1])" } else { 'eval/reports' }
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$checks = [System.Collections.Generic.List[hashtable]]::new()
$failures = 0

function Add-Check([string]$id, [string]$name, [bool]$pass, [string]$detail) {
    $script:checks.Add(@{ id = $id; name = $name; status = $(if ($pass) { 'PASS' } else { 'FAIL' }); detail = $detail })
    if (-not $pass) { $script:failures++ }
}

$orch = Get-Content '.cursor/rules/orchestrator.mdc' -Raw
$prSkill = Get-Content '.cursor/skills/pr-workflow/SKILL.md' -Raw
$handoff = Get-Content 'docs/harness/examples/contract-handoff.md' -Raw

# AS-01: todo 우선 로드 규약
Add-Check 'AS-01' 'todo 우선 로드' `
    ($orch -match 'todo\.md' -and $orch -match 'playbook 전체 로드 금지') `
    'orchestrator에 todo.md·playbook 전체 로드 금지'

# AS-02: handoff 스키마 산출 가능
Add-Check 'AS-02' 'handoff 형식' `
    ((Test-Path 'docs/harness/handoff-schema.md') -and ($handoff -match '(?s)\A---\r?\n')) `
    'handoff-schema + 예시 frontmatter'

# AS-03: PR 전 검증 절차
Add-Check 'AS-03' 'PR 검증 절차' `
    ($prSkill -match 'validate-harness' -and $prSkill -match 'run-eval') `
    'pr-workflow에 validate-harness + run-eval'

# AS-04: main 직접 커밋 금지
Add-Check 'AS-04' 'main 커밋 금지' `
    ($orch -match 'main' -and $orch -match '직접 커밋 금지') `
    'orchestrator main 직접 커밋 금지'

$status = if ($failures -eq 0) { 'PASS' } else { 'FAIL' }
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

$reportDirPath = Join-Path $root $ReportDir
New-Item -ItemType Directory -Force -Path $reportDirPath | Out-Null
$report = @{
    suite       = 'agent-eval'
    timestamp   = $timestamp
    status      = $status
    duration_ms = $sw.ElapsedMilliseconds
    summary     = @{ pass = ($checks.Count - $failures); fail = $failures; total = $checks.Count }
    checks      = $checks
}
$reportJson = $report | ConvertTo-Json -Depth 5
$latest = Join-Path $reportDirPath 'latest-agent-eval.json'
$stamped = Join-Path $reportDirPath "agent-eval-$($timestamp -replace '[:Z]','').json"
Set-Content -LiteralPath $latest -Value $reportJson -Encoding utf8
Set-Content -LiteralPath $stamped -Value $reportJson -Encoding utf8

if ($failures -eq 0) {
    Write-Host "PASS: agent-eval ($($checks.Count) checks) -> $ReportDir/latest-agent-eval.json"
    exit 0
}

Write-Host "FAIL: agent-eval ($failures/$($checks.Count)) -> $ReportDir/latest-agent-eval.json"
foreach ($c in $checks) {
    if ($c.status -eq 'FAIL') { Write-Host "  - $($c.id): $($c.detail)" }
}
exit 1
