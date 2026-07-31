#Requires -Version 5.1
<#
.SYNOPSIS
  Orchestrates adapter Publish-* for a selected agent (fail-closed when not implemented).

.DESCRIPTION
  Resolves -Agent against adapters/registry.json, loads the adapter module, and
  invokes Publish-Skills / Publish-Policy / Publish-Router / Publish-Hooks.
  When Get-Capabilities reports sdd=true, also runs Get-SddRoot -Prepare
  (sessions directory + seed manifest.json if missing).
  Stub modules return Implemented = false; sync exits non-zero (TE04) without
  writing under USERPROFILE.

.PARAMETER Agent
  Registry agent id (required).

.PARAMETER InstallRoot
  Target install root for Publish-*. Defaults to in-repo fixture path under the
  toolkit repo (safe for stub orchestration; still fail-closed via Resolve-InstallRoot).

.PARAMETER WhatIf
  Forwarded to Publish-* commands.

.PARAMETER AllowUserHome
  Opt-in when InstallRoot resolves under USERPROFILE.

.PARAMETER Mode
  Required for -Agent copilot: user|repo (TE02 when missing/invalid). Ignored for other agents.

.EXAMPLE
  .\scripts\sync-agent.ps1 -Agent cursor

.EXAMPLE
  .\scripts\sync-agent.ps1 -Agent copilot -Mode user
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
    [switch] $WhatIf,

    [Parameter()]
    [switch] $AllowUserHome
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

function Write-SyncError {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host $Message -ForegroundColor Red
}

try {
    $repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
    Assert-AgentParameterPresent -RepoRoot $repoRoot -AgentId $Agent
    $resolved = Resolve-RegistryAgent -RepoRoot $repoRoot -AgentId $Agent
    $resolvedMode = Assert-CopilotAgentMode -AgentId $resolved.AgentId -Mode $Mode

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

    Write-Host ("Sync agent: {0} ({1})" -f $resolved.AgentId, $resolved.DisplayName) -ForegroundColor Cyan
    Write-Host ("InstallRoot: {0}" -f $resolvedInstallRoot) -ForegroundColor Cyan
    Write-Host ("Module: {0}" -f $resolved.ModuleRelative) -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($resolvedMode)) {
        Write-Host ("Mode: {0}" -f $resolvedMode) -ForegroundColor Cyan
    }

    if (-not $WhatIf.IsPresent) {
        # Lexical Resolve already applied; create only then Confirm (TOCTOU / reparse).
        $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    }

    $publishNames = @($script:ToolkitConstant.PublishCommandNames)
    foreach ($commandName in $publishNames) {
        $command = Get-Command -Name $commandName -ErrorAction Stop
        $publishArgs = @{ InstallRoot = $resolvedInstallRoot }
        if ($WhatIf.IsPresent) {
            $publishArgs['WhatIf'] = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($resolvedMode)) {
            $publishArgs[$script:ToolkitConstant.ModeParameterName] = $resolvedMode
        }
        if ($AllowUserHome.IsPresent) {
            $publishArgs[$script:ToolkitConstant.AllowUserHomeParameterName] = $true
        }

        $result = & $command @publishArgs
        if ($null -eq $result) {
            Write-SyncError -Message ($script:ToolkitMessage.SyncPublishFailed -f $resolved.AgentId, ("{0} returned no result" -f $commandName))
            exit 1
        }

        if ($result.PSObject.Properties.Name -contains 'Implemented' -and $result.Implemented -eq $false) {
            $detail = if ($result.PSObject.Properties.Name -contains 'Message') { [string]$result.Message } else { $commandName }
            Write-SyncError -Message ($script:ToolkitMessage.AdapterNotImplemented -f $resolved.AgentId, $detail)
            exit 1
        }

        if ($result.PSObject.Properties.Name -contains 'Success' -and $result.Success -eq $false) {
            $detail = if ($result.PSObject.Properties.Name -contains 'Message') { [string]$result.Message } else { $commandName }
            Write-SyncError -Message ($script:ToolkitMessage.SyncPublishFailed -f $resolved.AgentId, $detail)
            exit 1
        }

        Write-Host ("{0}: OK" -f $commandName) -ForegroundColor Green
    }

    $capabilities = Get-Capabilities -AgentId $resolved.AgentId
    $sddCapable = $false
    if ($null -ne $capabilities -and $null -ne $capabilities.Capabilities -and $capabilities.Capabilities.PSObject.Properties.Name -contains 'sdd') {
        $sddCapable = [bool]$capabilities.Capabilities.sdd
    }

    if ($sddCapable) {
        if (-not $WhatIf.IsPresent) {
            $resolvedInstallRoot = Confirm-InstallRootAllowsWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
        }
        $sddArgs = @{
            InstallRoot = $resolvedInstallRoot
            Prepare     = $true
        }
        if ($WhatIf.IsPresent) {
            $sddArgs['WhatIf'] = $true
        }
        if ($AllowUserHome.IsPresent) {
            $sddArgs[$script:ToolkitConstant.AllowUserHomeParameterName] = $true
        }

        $sddResult = Get-SddRoot @sddArgs
        if ($null -eq $sddResult) {
            Write-SyncError -Message ($script:ToolkitMessage.SyncPublishFailed -f $resolved.AgentId, 'Get-SddRoot -Prepare returned no result')
            exit 1
        }
        if ($sddResult.PSObject.Properties.Name -contains 'Implemented' -and $sddResult.Implemented -eq $false) {
            $detail = if ($sddResult.PSObject.Properties.Name -contains 'Message') { [string]$sddResult.Message } else { 'Get-SddRoot' }
            Write-SyncError -Message ($script:ToolkitMessage.AdapterNotImplemented -f $resolved.AgentId, $detail)
            exit 1
        }
        if ($sddResult.PSObject.Properties.Name -contains 'Success' -and $sddResult.Success -eq $false) {
            $detail = if ($sddResult.PSObject.Properties.Name -contains 'Message') { [string]$sddResult.Message } else { 'Get-SddRoot' }
            Write-SyncError -Message ($script:ToolkitMessage.SyncPublishFailed -f $resolved.AgentId, $detail)
            exit 1
        }

        Write-Host 'Get-SddRoot -Prepare: OK' -ForegroundColor Green
    }

    Write-Host 'Sync completed.' -ForegroundColor Green
    exit 0
}
catch {
    Write-SyncError -Message $_.Exception.Message
    exit 1
}
