#Requires -Version 7.4
<#
.SYNOPSIS
  Handoff 문서 린터 — frontmatter·필수 섹션 검증.
.EXAMPLE
  pwsh scripts/validate-handoff.ps1
.NOTES
  macOS/Linux/Git Bash: ./scripts/validate-handoff.sh
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$requiredFm = @('ticket:', 'from:', 'to:', 'status:', 'breaking:')
$requiredSections = @(
    '## API 변경', '## DTO', '## DB',
    '## Backend TODO', '## Frontend TODO', '## Breaking change'
)

$failures = [System.Collections.Generic.List[string]]::new()
function Fail([string]$msg) { $failures.Add($msg) }

function Test-HandoffFile([string]$relPath) {
    $path = Join-Path $root $relPath
    if (-not (Test-Path $path)) { return }
    $content = Get-Content -LiteralPath $path -Raw

    if ($content -notmatch '(?s)\A---\r?\n.+?\r?\n---') {
        Fail "HANDOFF_FM: $relPath — YAML frontmatter 누락 (파일 시작)"
        return
    }
    $fm = $Matches[0]
    foreach ($key in $requiredFm) {
        if ($fm -notmatch "(?m)^$([regex]::Escape($key.TrimEnd(':'))):") {
            Fail "HANDOFF_FM: $relPath — '$key' 누락"
        }
    }
    foreach ($section in $requiredSections) {
        if ($content -notmatch [regex]::Escape($section)) {
            Fail "HANDOFF_SEC: $relPath — '$section' 누락"
        }
    }
}

$targets = @('docs/harness/examples/contract-handoff.md')
$handoffDir = Join-Path $root 'docs/harness/handoffs'
if (Test-Path $handoffDir) {
    $targets += @(Get-ChildItem $handoffDir -Filter '*.md' -File |
        Where-Object { $_.Name -ne 'README.md' -and $_.Name -notlike '*-status.md' } |
        ForEach-Object { $_.FullName.Substring($root.Length + 1) -replace '\\', '/' })
}
if ($targets.Count -eq 0) {
    Fail 'HANDOFF: 검사 대상 없음'
}

foreach ($t in $targets) { Test-HandoffFile $t }

if ($failures.Count -eq 0) {
    Write-Host "PASS: validate-handoff ($($targets.Count) files)"
    exit 0
}

Write-Host "FAIL: validate-handoff ($($failures.Count) issues)"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
