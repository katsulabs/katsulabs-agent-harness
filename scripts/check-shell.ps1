#Requires -Version 7.4
<#
.SYNOPSIS
  PowerShell 버전 확인 (Harness 최소 7.4)
.EXAMPLE
  pwsh scripts/check-shell.ps1
#>
. "$PSScriptRoot/shell-env.ps1"
Write-Host "PASS: PowerShell $($PSVersionTable.PSVersion) (>= $($script:HarnessMinPwshVersion))"
