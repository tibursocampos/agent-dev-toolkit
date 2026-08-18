#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo OpenHands CI smoke (direct adapter publish + validate against fixture seed).

.DESCRIPTION
  Copies the versioned OpenHands fixture into an ephemeral work InstallRoot, then
  dot-sources OpenHandsAdapter.ps1 and runs Publish-* / Get-SddRoot -Prepare /
  Invoke-SmokeValidate. Does not require registry.json (wave 2), Canvas, or
  USERPROFILE writes. Never passes -AllowUserHome. The ephemeral work InstallRoot
  is removed after evaluation (pass or fail) unless -KeepWorkRoot is set.

  sync-agent -Agent openhands fails until the registry lists this adapter — expected.

.PARAMETER Quiet
  Suppress banners; print summary only.

.PARAMETER KeepWorkRoot
  Skip deleting the ephemeral work InstallRoot after evaluation (debugging aid).

.EXAMPLE
  pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1
#>
[CmdletBinding()]
param(
    [switch] $Quiet,
    [switch] $KeepWorkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Invoke-EphemeralFixtureSmoke.ps1')

$suiteTitle = 'agent-dev-toolkit OpenHands CI smoke'
$seedFixtureRel = 'scripts\validation\fixtures\openhands'
$workFixtureRel = 'scripts\validation\fixtures\openhands-ci-smoke'
$adapterRel = 'adapters\openhands\OpenHandsAdapter.ps1'
$suitePassMarker = 'Invoke-OpenHandsCiSmoke: PASS'
$adapterSmokePassMarker = $script:ToolkitConstant.AdapterSmokePassMarker

function Write-SuiteBanner {
    param([Parameter(Mandatory = $true)][string] $Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

function Write-SuiteFail {
    param([Parameter(Mandatory = $true)][string] $Reason)
    Write-Host ("Invoke-OpenHandsCiSmoke: FAIL - {0}" -f $Reason) -ForegroundColor Red
}

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$seedFixtureRoot = Join-Path $repoRoot $seedFixtureRel
$workInstallRoot = Join-Path $repoRoot $workFixtureRel
$adapterPath = Join-Path $repoRoot $adapterRel

Write-SuiteBanner $suiteTitle

if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-SuiteFail -Reason ("missing seed fixture: {0}" -f $seedFixtureRoot)
    exit 1
}
if (-not (Test-Path -LiteralPath $adapterPath)) {
    Write-SuiteFail -Reason ("missing OpenHands adapter: {0}" -f $adapterPath)
    exit 1
}

try {
    Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
    New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $seedFixtureRoot -Force | Copy-Item -Destination $workInstallRoot -Recurse -Force

    . $adapterPath

    $publishSkills = Publish-Skills -InstallRoot $workInstallRoot
    if ($null -eq $publishSkills -or $publishSkills.Success -ne $true) {
        Write-SuiteFail -Reason ("Publish-Skills failed: {0}" -f $(if ($null -eq $publishSkills) { 'null' } else { $publishSkills.Message }))
        exit 1
    }

    $publishPolicy = Publish-Policy -InstallRoot $workInstallRoot
    if ($null -eq $publishPolicy -or $publishPolicy.Success -ne $true) {
        Write-SuiteFail -Reason ("Publish-Policy failed: {0}" -f $(if ($null -eq $publishPolicy) { 'null' } else { $publishPolicy.Message }))
        exit 1
    }

    $publishRouter = Publish-Router -InstallRoot $workInstallRoot
    if ($null -eq $publishRouter -or $publishRouter.Success -ne $true) {
        Write-SuiteFail -Reason ("Publish-Router failed: {0}" -f $(if ($null -eq $publishRouter) { 'null' } else { $publishRouter.Message }))
        exit 1
    }

    $publishAgents = Publish-Agents -InstallRoot $workInstallRoot
    if ($null -eq $publishAgents -or $publishAgents.Success -ne $true) {
        Write-SuiteFail -Reason ("Publish-Agents failed: {0}" -f $(if ($null -eq $publishAgents) { 'null' } else { $publishAgents.Message }))
        exit 1
    }

    $publishHooks = Publish-Hooks -InstallRoot $workInstallRoot
    if ($null -eq $publishHooks -or $publishHooks.Success -ne $true) {
        Write-SuiteFail -Reason ("Publish-Hooks failed: {0}" -f $(if ($null -eq $publishHooks) { 'null' } else { $publishHooks.Message }))
        exit 1
    }

    $sdd = Get-SddRoot -InstallRoot $workInstallRoot -Prepare
    if ($null -eq $sdd -or $sdd.Success -ne $true) {
        Write-SuiteFail -Reason ("Get-SddRoot -Prepare failed: {0}" -f $(if ($null -eq $sdd) { 'null' } else { $sdd.Message }))
        exit 1
    }

    $smoke = Invoke-SmokeValidate -InstallRoot $workInstallRoot
    if ($null -eq $smoke -or $smoke.Success -ne $true -or $smoke.ExitCode -ne 0) {
        Write-SuiteFail -Reason ("Invoke-SmokeValidate failed: {0}" -f $(if ($null -eq $smoke) { 'null' } else { $smoke.Message }))
        exit 1
    }

    if ([string]$smoke.Message -notlike ('*{0}*' -f $adapterSmokePassMarker)) {
        Write-SuiteFail -Reason ("smoke message missing marker '{0}': {1}" -f $adapterSmokePassMarker, $smoke.Message)
        exit 1
    }

    if (-not $Quiet) {
        Write-Host $smoke.Message
    }
    Write-Host $suitePassMarker -ForegroundColor Green
    exit 0
}
finally {
    if (-not $KeepWorkRoot) {
        Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
    }
}
