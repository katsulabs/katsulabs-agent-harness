# Harness scripts require PowerShell 7.4+
$script:HarnessMinPwshVersion = [Version]'7.4.0'

function Test-HarnessPwshVersion {
    if ($PSVersionTable.PSVersion -lt $script:HarnessMinPwshVersion) {
        Write-Host "FAIL: PowerShell $($PSVersionTable.PSVersion) — minimum $($script:HarnessMinPwshVersion)" -ForegroundColor Red
        Write-Host @"

Install / align to PowerShell 7.4+:

  Windows (winget):
    winget install --id Microsoft.PowerShell --source winget
    winget upgrade --id Microsoft.PowerShell

  macOS (Homebrew):
    brew install powershell/tap/powershell
    brew upgrade powershell

  Verify:
    pwsh -NoProfile -Command '$PSVersionTable.PSVersion'

See: docs/harness/setup-shell.md
"@
        exit 1
    }
}

Test-HarnessPwshVersion
