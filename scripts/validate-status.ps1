#Requires -Version 7.4
<#
.SYNOPSIS
  Status 파일 린터 — frontmatter·역할 상태 표 검증.
.EXAMPLE
  pwsh scripts/validate-status.ps1
.NOTES
  macOS/Linux/Git Bash: ./scripts/validate-status.sh
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$allowedStatus = @('todo', 'in_progress', 'done', 'blocked')
$allowedRole = @('Contract', 'Backend', 'Frontend', 'QA', 'Editor')

$failures = [System.Collections.Generic.List[string]]::new()
function Fail([string]$msg) { $failures.Add($msg) }

function Test-StatusFile([string]$relPath) {
    $path = Join-Path $root $relPath
    if (-not (Test-Path $path)) { return }
    $content = Get-Content -LiteralPath $path -Raw

    if ($content -notmatch '(?s)\A---\r?\n.+?\r?\n---') {
        Fail "STATUS_FM: $relPath — YAML frontmatter 누락"
        return
    }
    if ($content -notmatch '(?m)^ticket:') {
        Fail "STATUS_FM: $relPath — 'ticket:' 누락"
    }

    $hasHeader = $false
    $rows = 0
    foreach ($line in (Get-Content -LiteralPath $path)) {
        if ($line -notmatch '^\|') { continue }
        if ($line -match '^\|\s*role\s*\|\s*status\s*\|\s*artifacts\s*\|\s*verified\s*\|') { $hasHeader = $true; continue }
        if ($line -match '^\|\s*-+') { continue }
        $cells = $line.Trim('|').Split('|') | ForEach-Object { $_.Trim() }
        if ($cells.Count -lt 2) { continue }
        $role = $cells[0]; $status = $cells[1]
        if (-not $role) { continue }
        $rows++
        if ($allowedRole -notcontains $role) { Fail "STATUS_ROLE: $relPath — 알 수 없는 role '$role'" }
        if ($allowedStatus -notcontains $status) { Fail "STATUS_STATUS: $relPath — 알 수 없는 status '$status' ($role)" }
    }
    if (-not $hasHeader) { Fail "STATUS_HDR: $relPath — role|status|artifacts|verified 헤더 누락" }
    if ($rows -eq 0) { Fail "STATUS_ROWS: $relPath — 역할 행 없음" }
}

$targets = @('docs/harness/examples/status-example.md', 'docs/harness/examples/status-complete.md')
$handoffDir = Join-Path $root 'docs/harness/handoffs'
if (Test-Path $handoffDir) {
    $targets += @(Get-ChildItem $handoffDir -Filter '*-status.md' -File |
        ForEach-Object { $_.FullName.Substring($root.Length + 1) -replace '\\', '/' })
}

foreach ($t in $targets) { Test-StatusFile $t }

if ($failures.Count -eq 0) {
    Write-Host "PASS: validate-status ($($targets.Count) files)"
    exit 0
}

Write-Host "FAIL: validate-status ($($failures.Count) issues)"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
