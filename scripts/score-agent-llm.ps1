#Requires -Version 7.4
<#
.SYNOPSIS
  LLM 응답 자동 채점 — expected 패턴·fixtures 검증.
#>
param(
    [switch]$Fixture,
    [string]$Session = 'eval/reports/agent-llm-session.md'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
$expectedDir = Join-Path $root 'eval/agent-tasks/expected'
$fixtureDir = Join-Path $root 'eval/agent-tasks/fixtures'
$reportDir = Join-Path $root 'eval/reports'

function Test-Rules([string]$text, $rules) {
    $lower = $text.ToLowerInvariant()
    foreach ($m in @($rules.must)) {
        if ($text -notmatch [regex]::Escape($m) -and $lower -notmatch [regex]::Escape($m.ToLowerInvariant())) {
            return @{ pass = $false; reason = "missing must: $m" }
        }
    }
    if ($rules.PSObject.Properties['must_any']) {
        $any = $false
        foreach ($m in @($rules.must_any)) {
            if ($text -match [regex]::Escape($m) -or $lower -match [regex]::Escape($m.ToLowerInvariant())) { $any = $true }
        }
        if (-not $any) { return @{ pass = $false; reason = 'missing must_any' } }
    }
    foreach ($m in @($rules.must_not)) {
        if ($text -match [regex]::Escape($m) -or $lower -match [regex]::Escape($m.ToLowerInvariant())) {
            return @{ pass = $false; reason = "forbidden: $m" }
        }
    }
    return @{ pass = $true; reason = 'ok' }
}

function Get-RulesPath([string]$id) {
    $num = [int]($id -replace 'AL-', '')
    Join-Path $expectedDir ("al-{0:D2}.json" -f $num)
}

function Score-Id([string]$id, [string]$text) {
    $path = Get-RulesPath $id
    if (-not (Test-Path $path)) { return @{ id = $id; pass = $false; reason = 'no rules' } }
    $rules = Get-Content $path -Raw | ConvertFrom-Json
    $r = Test-Rules $text $rules
    return @{ id = $id; pass = $r.pass; reason = $r.reason }
}

$results = [System.Collections.Generic.List[hashtable]]::new()
$failures = 0

if ($Fixture) {
    foreach ($rulesFile in Get-ChildItem $expectedDir -Filter 'al-*.json' | Sort-Object Name) {
        $rules = Get-Content $rulesFile.FullName -Raw | ConvertFrom-Json
        $id = $rules.id
        $goodPath = Join-Path $fixtureDir "$($id.ToLower())-good.txt"
        if (Test-Path $goodPath) {
            $r = Score-Id $id (Get-Content $goodPath -Raw)
            $results.Add($r)
            if (-not $r.pass) { $failures++ }
        }
        $badPath = Join-Path $fixtureDir "$($id.ToLower())-bad.txt"
        if (Test-Path $badPath) {
            $r = Score-Id $id (Get-Content $badPath -Raw)
            if ($r.pass) {
                $results.Add(@{ id = "${id}-bad"; pass = $false; reason = 'bad fixture should fail' })
                $failures++
            } else {
                $results.Add(@{ id = "${id}-bad"; pass = $true; reason = 'correctly rejected' })
            }
        }
    }
} elseif (Test-Path (Join-Path $root $Session)) {
    $content = Get-Content (Join-Path $root $Session) -Raw
    foreach ($m in [regex]::Matches($content, '(?m)^\| (AL-\d+) \|[^|]*\| ([^|]+) \|')) {
        $id = $m.Groups[1].Value
        $response = $m.Groups[2].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($response)) { continue }
        $r = Score-Id $id $response
        $results.Add($r)
        if (-not $r.pass) { $failures++ }
    }
} else {
    Write-Host "FAIL: session 없음 ($Session)"
    exit 1
}

$status = if ($failures -eq 0) { 'PASS' } else { 'FAIL' }
$pass = @($results | Where-Object { $_.pass }).Count
$report = @{
    suite     = 'agent-llm-score'
    timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    status    = $status
    mode      = if ($Fixture) { 'fixture' } else { 'session' }
    summary   = @{ pass = $pass; fail = $failures; total = $results.Count }
    results   = $results
}
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
Set-Content (Join-Path $reportDir 'latest-agent-llm-score.json') -Value ($report | ConvertTo-Json -Depth 5) -Encoding utf8

if ($failures -eq 0) {
    Write-Host "PASS: score-agent-llm ($($results.Count) scored)"
    exit 0
}
Write-Host "FAIL: score-agent-llm ($failures issues)"
foreach ($r in $results) { if (-not $r.pass) { Write-Host "  - $($r.id): $($r.reason)" } }
exit 1
