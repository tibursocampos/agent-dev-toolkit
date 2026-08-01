#Requires -Version 5.1
<#
.SYNOPSIS
  Core-focused validate-all entry (alias of validate-core).

.DESCRIPTION
  Runs in-repo core checks only. Does not deploy to ~/.cursor or require -AllowUserHome.
  Full agent sync/validate is covered by adapter smoke/CI suites.
#>
[CmdletBinding()]
param(
    [switch] $FailFast,
    [switch] $Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$coreEntryName = 'validate-core.ps1'
$coreEntry = Join-Path $PSScriptRoot $coreEntryName
if (-not (Test-Path -LiteralPath $coreEntry)) {
    Write-Host "Missing $coreEntryName next to validate-all.ps1" -ForegroundColor Red
    exit 1
}

$forwardArgs = @()
if ($FailFast) { $forwardArgs += '-FailFast' }
if ($Quiet) { $forwardArgs += '-Quiet' }

& $coreEntry @forwardArgs
exit $LASTEXITCODE
