#Requires -Version 5.1
<#
.SYNOPSIS
  Validates toolkit core for a selected agent; optional adapter smoke (no-op when adapter not implemented).

.DESCRIPTION
  Requires -Agent (registry lookup). By default runs scripts/validation/validate-core.ps1.
  Pass -SkipCore when the caller already ran validate-core (CI ephemeral smoke).
  After core passes (or is skipped), loads the adapter module and calls
  Invoke-SmokeValidate when InstallRoot is available. Stub adapters
  (Implemented = false) are treated as documented no-op / skip - core result
  still drives the exit code when core ran.

.PARAMETER Agent
  Registry agent id (required).

.PARAMETER InstallRoot
  Fixture InstallRoot for smoke. Defaults to in-repo fixture path.

.PARAMETER SkipSmoke
  Skip Invoke-SmokeValidate even when the module is loaded.

.PARAMETER SkipCore
  Skip validate-core (CI smoke harness only; local default still runs core).

.PARAMETER AllowUserHome
  Opt-in when InstallRoot resolves under USERPROFILE.

.PARAMETER FailFast
  Forwarded to validate-core.

.PARAMETER Quiet
  Forwarded to validate-core.

.PARAMETER Mode
  Required for -Agent copilot: user|repo (TE02 when missing/invalid). Ignored for other agents.

.EXAMPLE
  .\scripts\validate-agent.ps1 -Agent cursor

.EXAMPLE
  .\scripts\validate-agent.ps1 -Agent copilot -Mode user
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Agent,

    [Parameter()]
    [string] $InstallRoot,

    [Parameter()]
    [string] $Mode,

    [Parameter()]
    [switch] $SkipSmoke,

    [Parameter()]
    [switch] $SkipCore,

    [Parameter()]
    [switch] $AllowUserHome,

    [Parameter()]
    [switch] $FailFast,

    [Parameter()]
    [switch] $Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path $scriptDir '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'Resolve-InstallRoot.ps1')
. (Join-Path $libDir 'Resolve-RegistryAgent.ps1')
. (Join-Path $libDir 'Assert-CopilotAgentMode.ps1')
. (Join-Path $libDir 'Resolve-AdapterFixtureInstallRoot.ps1')

function Write-ValidateError {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host $Message -ForegroundColor Red
}

try {
    $repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
    Assert-AgentParameterPresent -RepoRoot $repoRoot -AgentId $Agent
    $resolved = Resolve-RegistryAgent -RepoRoot $repoRoot -AgentId $Agent
    $resolvedMode = Assert-CopilotAgentMode -AgentId $resolved.AgentId -Mode $Mode

    $validateCorePath = Join-Path $repoRoot ($script:ToolkitConstant.ValidateCoreRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $validateCorePath)) {
        Write-ValidateError -Message ($script:ToolkitMessage.ValidateCoreMissing -f $validateCorePath)
        exit 1
    }

    Write-Host ("Validate agent: {0} ({1})" -f $resolved.AgentId, $resolved.DisplayName) -ForegroundColor Cyan
    Write-Host ("Module: {0}" -f $resolved.ModuleRelative) -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($resolvedMode)) {
        Write-Host ("Mode: {0}" -f $resolvedMode) -ForegroundColor Cyan
    }

    if (-not $SkipCore) {
        $forwardArgs = @{}
        if ($FailFast) { $forwardArgs['FailFast'] = $true }
        if ($Quiet) { $forwardArgs['Quiet'] = $true }

        & $validateCorePath @forwardArgs
        $coreExit = $LASTEXITCODE
        if ($null -eq $coreExit) {
            $coreExit = 0
        }

        if ($coreExit -ne 0) {
            Write-ValidateError -Message ("Core validation failed (exit {0})." -f $coreExit)
            exit $coreExit
        }
    }
    else {
        Write-Host $script:ToolkitMessage.ToolkitCoreSkipped -ForegroundColor Yellow
    }

    if ($SkipSmoke) {
        Write-Host 'Adapter smoke skipped (-SkipSmoke).' -ForegroundColor Yellow
        if ($SkipCore) {
            Write-Host 'Validate agent completed (SkipCore + SkipSmoke).' -ForegroundColor Green
        }
        else {
            Write-Host 'Validate agent completed (core only).' -ForegroundColor Green
        }
        exit 0
    }

    # Dot-source before InstallRoot default so adapters can expose FixtureRelativePath.
    . $resolved.ModulePath

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        if ((Test-IsCopilotAgentId -AgentId $resolved.AgentId) -and -not [string]::IsNullOrWhiteSpace($resolvedMode)) {
            $copilotFixtureRel = if ($resolvedMode -eq $script:ToolkitConstant.CopilotModeRepo) {
                $script:ToolkitConstant.CopilotFixtureRepoRel
            }
            else {
                $script:ToolkitConstant.CopilotFixtureUserRel
            }
            $InstallRoot = Join-Path $repoRoot ($copilotFixtureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        }
        else {
            $InstallRoot = Resolve-AdapterFixtureInstallRoot -RepoRoot $repoRoot -AgentId $resolved.AgentId
        }
    }

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $resolvedInstallRoot = Confirm-InstallRootAllowsWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot

    $smokeArgs = @{
        InstallRoot    = $resolvedInstallRoot
        AllowUserHome  = $AllowUserHome
    }
    if (-not [string]::IsNullOrWhiteSpace($resolvedMode)) {
        $smokeArgs[$script:ToolkitConstant.ModeParameterName] = $resolvedMode
    }

    $smoke = Invoke-SmokeValidate @smokeArgs
    if ($null -eq $smoke) {
        Write-ValidateError -Message ($script:ToolkitMessage.SmokeFailed -f $resolved.AgentId, 'Invoke-SmokeValidate returned no result')
        exit 1
    }

    if ($smoke.PSObject.Properties.Name -contains 'Implemented' -and $smoke.Implemented -eq $false) {
        Write-Host $script:ToolkitMessage.SmokeSkippedNotImplemented -ForegroundColor Yellow
        Write-Host 'Validate agent completed (core PASS; adapter smoke no-op).' -ForegroundColor Green
        exit 0
    }

    if ($smoke.PSObject.Properties.Name -contains 'Success' -and $smoke.Success -eq $false) {
        $detail = if ($smoke.PSObject.Properties.Name -contains 'Message') { [string]$smoke.Message } else { 'smoke failed' }
        Write-ValidateError -Message ($script:ToolkitMessage.SmokeFailed -f $resolved.AgentId, $detail)
        exit 1
    }

    Write-Host 'Adapter smoke: PASS' -ForegroundColor Green
    Write-Host 'Validate agent completed.' -ForegroundColor Green
    exit 0
}
catch {
    Write-ValidateError -Message $_.Exception.Message
    exit 1
}
