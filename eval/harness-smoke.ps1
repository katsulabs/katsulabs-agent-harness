#Requires -Version 7.4
<#
.SYNOPSIS
  하네스 자체 스모크 eval — 앱 테스트 러너 없을 때 run-eval 폴백.
.NOTES
  macOS/Linux/Git Bash: ./eval/harness-smoke.sh
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
# 리포트 경로: 브랜치 TB-{id} 기준 격리 (동시 실행 클로버 방지)
$branch = (git branch --show-current 2>$null)
$reportSub = if ($branch -match 'TB-(\d+)') { "eval/reports/TB-$($Matches[1])" } else { 'eval/reports' }
$reportDir = Join-Path $root $reportSub
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$failures = [System.Collections.Generic.List[string]]::new()
$checks = [System.Collections.Generic.List[hashtable]]::new()
function Fail([string]$msg) { $failures.Add($msg) }
function Add-Check([string]$name, [bool]$pass, [string]$detail) {
    $checks.Add(@{ name = $name; status = $(if ($pass) { 'PASS' } else { 'FAIL' }); detail = $detail })
    if (-not $pass) { Fail $detail }
}

# 1. harness-gate
& pwsh -NoProfile -File (Join-Path $root 'scripts/validate-harness.ps1')
Add-Check 'validate-harness' ($LASTEXITCODE -eq 0) 'validate-harness 실패'

# 2. handoff 린터
& pwsh -NoProfile -File (Join-Path $root 'scripts/validate-handoff.ps1')
Add-Check 'validate-handoff' ($LASTEXITCODE -eq 0) 'validate-handoff 실패'

# 2b. status 린터
& pwsh -NoProfile -File (Join-Path $root 'scripts/validate-status.ps1')
Add-Check 'validate-status' ($LASTEXITCODE -eq 0) 'validate-status 실패'

# 2c. 오케스트레이션 스캐폴딩
& pwsh -NoProfile -File (Join-Path $root 'scripts/dispatch-plan.ps1') -Ticket TB-000 -DryRun | Out-Null
Add-Check 'dispatch-plan' ($LASTEXITCODE -eq 0) 'dispatch-plan 실패'

& pwsh -NoProfile -File (Join-Path $root 'scripts/collect-handoff.ps1') -Path 'docs/harness/examples/status-complete.md' | Out-Null
Add-Check 'collect-handoff' ($LASTEXITCODE -eq 0) 'collect-handoff 실패'

# 3. agent-eval 프록시
& pwsh -NoProfile -File (Join-Path $root 'scripts/run-agent-eval.ps1')
Add-Check 'agent-eval' ($LASTEXITCODE -eq 0) 'agent-eval 실패'

& pwsh -NoProfile -File (Join-Path $root 'scripts/run-agent-llm-eval.ps1')
Add-Check 'agent-llm-eval' ($LASTEXITCODE -eq 0) 'agent-llm-eval 템플릿 실패'

& pwsh -NoProfile -File (Join-Path $root 'scripts/score-agent-llm.ps1') -Fixture
Add-Check 'score-agent-llm' ($LASTEXITCODE -eq 0) 'score-agent-llm fixture 실패'

& pwsh -NoProfile -File (Join-Path $root 'scripts/verify-dispatch.ps1')
Add-Check 'verify-dispatch' ($LASTEXITCODE -eq 0) 'verify-dispatch 실패'

# 4. eval 아티팩트
foreach ($f in @(
    'eval/agent-smoke.checklist.md',
    'docs/harness/handoff-schema.md',
    'docs/harness/mcp-setup.md',
    'scripts/validate-handoff.ps1',
    'scripts/validate-status.ps1',
    'scripts/dispatch-plan.ps1',
    'scripts/collect-handoff.ps1',
    'docs/harness/status-schema.md',
    'docs/harness/examples/status-example.md',
    'docs/harness/examples/status-complete.md',
    'scripts/run-agent-eval.ps1',
    'scripts/dispatch-prompt.ps1',
    'scripts/summarize-eval.ps1',
    'sample/package.json',
    'scripts/run-agent-llm-eval.ps1',
    'scripts/score-agent-llm.ps1',
    'scripts/cost-summary.ps1',
    'scripts/verify-dispatch.ps1',
    '.cursor/skills/dispatch/SKILL.md'
)) {
    $ok = Test-Path (Join-Path $root $f)
    Add-Check "artifact:$f" $ok "MISSING: $f"
}

# 5. run-eval 폴백
$runEval = Get-Content (Join-Path $root 'scripts/run-eval.ps1') -Raw
Add-Check 'run-eval-fallback' ($runEval -match 'harness-smoke') 'run-eval harness-smoke 폴백 없음'

# 6. 디스패치 규약
$playbook = Get-Content (Join-Path $root 'docs/harness/playbook.md') -Raw
foreach ($kw in @('서브에이전트', 'Task', 'handoff-schema')) {
    Add-Check "playbook:$kw" ($playbook -match [regex]::Escape($kw)) "PLAYBOOK: '$kw' 누락"
}

$timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$status = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$passCount = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$report = @{
    suite       = 'harness-smoke'
    timestamp   = $timestamp
    status      = $status
    duration_ms = $sw.ElapsedMilliseconds
    summary     = @{ pass = $passCount; fail = $failures.Count; total = $checks.Count }
    checks      = $checks
}
$reportJson = $report | ConvertTo-Json -Depth 5
Set-Content -LiteralPath (Join-Path $reportDir 'latest-harness-smoke.json') -Value $reportJson -Encoding utf8
$stamped = Join-Path $reportDir "harness-smoke-$($timestamp -replace '[:Z]','').json"
Set-Content -LiteralPath $stamped -Value $reportJson -Encoding utf8

if ($failures.Count -eq 0) {
    & pwsh -NoProfile -File (Join-Path $root 'scripts/cost-summary.ps1') | Out-Null
    Write-Host "PASS: harness-smoke -> eval/reports/latest-harness-smoke.json"
    exit 0
}

Write-Host "FAIL: harness-smoke ($($failures.Count) issues) -> eval/reports/latest-harness-smoke.json"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
