#Requires -Version 7.4
<#
.SYNOPSIS
  LLM agent eval 세션 템플릿 생성·(선택) 채점 검증.
.EXAMPLE
  pwsh scripts/run-agent-llm-eval.ps1
.EXAMPLE
  pwsh scripts/run-agent-llm-eval.ps1 -Validate
#>
param([switch]$Validate, [switch]$AutoScore)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$baseline = Join-Path $root 'eval/agent-tasks/harness-baseline.md'
$reportDir = Join-Path $root 'eval/reports'
$template = Join-Path $reportDir 'agent-llm-session.template.md'
$session = Join-Path $reportDir 'agent-llm-session.md'

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

if (-not (Test-Path $baseline)) {
    Write-Host 'FAIL: harness-baseline.md 없음'
    exit 1
}

$lines = Get-Content -LiteralPath $baseline
$tasks = [System.Collections.Generic.List[hashtable]]::new()
foreach ($line in $lines) {
    if ($line -match '^\| (AL-\d+) \| (.+) \| (.+) \|') {
        $tasks.Add(@{ id = $Matches[1]; prompt = $Matches[2]; expect = $Matches[3] })
    }
}

if ($tasks.Count -eq 0) {
    Write-Host 'FAIL: AL-* 태스크 없음'
    exit 1
}

$out = [System.Collections.Generic.List[string]]::new()
$out.Add('# Agent LLM Session')
$out.Add('')
$out.Add("생성: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))")
$out.Add('')
$out.Add('| ID | 결과 (PASS/FAIL) | 응답 요약 | 메모 |')
$out.Add('|----|------------------|-----------|------|')
foreach ($t in $tasks) {
    $out.Add("| $($t.id) | | | $($t.prompt) → $($t.expect) |")
}
$out.Add('')
$out.Add('응답 요약 채운 뒤 `-AutoScore` 또는 `score-agent-llm -Session` · `run-agent-llm-eval -Validate`')

Set-Content -LiteralPath $template -Value ($out -join "`n") -Encoding utf8

if (-not $Validate) {
    if (-not (Test-Path $session)) {
        Copy-Item -LiteralPath $template -Destination $session
    }
    $sw.Stop()
    Write-Host "PASS: agent-llm-eval template ($($tasks.Count) tasks) -> eval/reports/agent-llm-session.md"
    exit 0
}

if (-not (Test-Path $session)) {
    Write-Host 'FAIL: agent-llm-session.md 없음 (템플릿 생성 후 수동 채점)'
    exit 1
}

if ($AutoScore) {
    & pwsh -NoProfile -File (Join-Path $root 'scripts/score-agent-llm.ps1') -Session 'eval/reports/agent-llm-session.md'
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$failures = [System.Collections.Generic.List[string]]::new()
$sessionText = Get-Content -LiteralPath $session -Raw
foreach ($t in $tasks) {
    $id = $t.id
    if ($sessionText -notmatch "\| $id \| (PASS|FAIL) \|") {
        $failures.Add("${id}: PASS/FAIL 미기록")
    }
}

$sw.Stop()
$status = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$report = @{
    suite       = 'agent-llm-eval'
    timestamp   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    status      = $status
    duration_ms = $sw.ElapsedMilliseconds
    summary     = @{ pass = ($tasks.Count - $failures.Count); fail = $failures.Count; total = $tasks.Count }
}
Set-Content -LiteralPath (Join-Path $reportDir 'latest-agent-llm-eval.json') -Value ($report | ConvertTo-Json -Depth 4) -Encoding utf8

if ($failures.Count -eq 0) {
    Write-Host "PASS: agent-llm-eval validate ($($tasks.Count) tasks)"
    exit 0
}

Write-Host "FAIL: agent-llm-eval ($($failures.Count) issues)"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
