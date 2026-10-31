#Requires -Version 7.4
<#
.SYNOPSIS
  PR 본문 필수 섹션 검증.
.EXAMPLE
  pwsh scripts/validate-pr-body.ps1 -File pr-body.md
#>
param([string]$File)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$text = if ($File) { Get-Content (Join-Path $root $File) -Raw } else { [Console]::In.ReadToEnd() }
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-Host 'FAIL: validate-pr-body — 본문 없음'
    exit 1
}

$required = @('## 요약', '## 검증 계획', '## 테스트 게이트', '## 하드 게이트')
$failures = [System.Collections.Generic.List[string]]::new()
foreach ($sec in $required) {
    if ($text -notmatch [regex]::Escape($sec)) { $failures.Add("PR_BODY: '$sec' 누락") }
}
if ($text -notmatch 'validate-harness') { $failures.Add('PR_BODY: validate-harness 언급 누락') }

if ($failures.Count -eq 0) {
    Write-Host 'PASS: validate-pr-body'
    exit 0
}
Write-Host "FAIL: validate-pr-body ($($failures.Count))"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
