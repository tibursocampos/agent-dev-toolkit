#Requires -Version 5.1
<#
.SYNOPSIS
  Orchestrates adapter Publish-* for a selected agent (fail-closed when not implemented).

.DESCRIPTION
  Resolves -Agent against adapters/registry.json, loads the adapter module, and
  invokes Publish-Skills / Publish-Policy / Publish-Router / Publish-Agents / Publish-Hooks, then
  always runs Get-SddRoot -Prepare (sessions directory + seed manifest.json if
  missing; never overwrites existing manifest or clears sessions).
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

.PARAMETER UserScope
  Forwarded to Publish-Skills when the adapter declares -UserScope (Codex).
  Opt-in only: mirrors to ~/.agents/skills. Do not enable by default — Codex
  already discovers InstallRoot/skills (~/.codex/skills); dual mirrors duplicate $ picks.

.PARAMETER DeferPreferences
  Internal toolkit wrapper signal. Direct sync stays non-interactive and seeds defaults;
  toolkit.ps1 initializes preferences after publication so its interactive menu can ask.

.PARAMETER Mode
  Required for -Agent copilot: user|repo (TE02 when missing/invalid). Ignored for other agents.

.EXAMPLE
  .\scripts\sync-agent.ps1 -Agent cursor

.EXAMPLE
  .\scripts\sync-agent.ps1 -Agent copilot -Mode user

.EXAMPLE
  .\scripts\sync-agent.ps1 -Agent codex -InstallRoot $env:USERPROFILE\.codex -AllowUserHome
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
    [switch] $AllowUserHome,

    [Parameter()]
    [switch] $UserScope,

    [Parameter()]
    [switch] $DeferPreferences
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
. (Join-Path $libDir 'Initialize-SddPreferences.ps1')
. (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')

function Write-SyncError {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-SyncPublishOk {
    <#
    .SYNOPSIS
      Default sync summary: OK plus adapter Message (counts/paths). Always on — not gated by -Verbose.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName,

        [Parameter()]
        $Result
    )

    Write-Host ("{0}: OK" -f $CommandName) -ForegroundColor Green

    if ($null -eq $Result) {
        return
    }

    $names = @($Result.PSObject.Properties.Name)
    if ($names -contains 'Message') {
        $detail = [string]$Result.Message
        if (-not [string]::IsNullOrWhiteSpace($detail)) {
            Write-Host ('  {0}' -f $detail.Trim()) -ForegroundColor DarkGray
            return
        }
    }

    $metricParts = New-Object System.Collections.Generic.List[string]
    if ($names -contains 'FilesCopied' -and $null -ne $Result.FilesCopied) {
        [void]$metricParts.Add(('files={0}' -f $Result.FilesCopied))
    }
    if ($names -contains 'SkillFolderCount' -and $null -ne $Result.SkillFolderCount) {
        [void]$metricParts.Add(('skills={0}' -f $Result.SkillFolderCount))
    }
    if ($names -contains 'SkillsRoot' -and -not [string]::IsNullOrWhiteSpace([string]$Result.SkillsRoot)) {
        [void]$metricParts.Add(('skillsRoot={0}' -f $Result.SkillsRoot))
    }
    if ($names -contains 'NoOp' -and [bool]$Result.NoOp) {
        [void]$metricParts.Add('no-op')
    }
    if ($metricParts.Count -gt 0) {
        Write-Host ('  {0}' -f ($metricParts -join '; ')) -ForegroundColor DarkGray
    }
}

function Invoke-SyncHooksPublish {
    param(
        [Parameter(Mandatory = $true)]
        $Command,

        [Parameter(Mandatory = $true)]
        [hashtable] $PublishArgs
    )

    try {
        $result = & $Command @PublishArgs
    }
    catch {
        return [PSCustomObject]@{
            Result  = $null
            Failed  = $true
            Message = $_.Exception.Message
        }
    }

    if ($null -eq $result) {
        return [PSCustomObject]@{
            Result  = $null
            Failed  = $true
            Message = $script:ToolkitMessage.SyncHookPublishNoResult
        }
    }

    $names = @($result.PSObject.Properties.Name)
    $failed = (($names -contains 'Success') -and $result.Success -eq $false) -or (($names -contains 'Implemented') -and $result.Implemented -eq $false)
    $message = $script:ToolkitMessage.SyncHookPublishFailedDefault
    if ($names -contains 'Message') {
        $message = [string]$result.Message
    }

    return [PSCustomObject]@{
        Result  = $result
        Failed  = [bool]$failed
        Message = $message
    }
}

function Get-SyncHookFixMessage {
    param($Activation)

    if ($null -ne $Activation -and $Activation.PSObject.Properties.Name -contains 'Steps' -and @($Activation.Steps).Count -gt 0) {
        return $script:ToolkitMessage.SyncHookFixSeeSteps
    }
    return $script:ToolkitMessage.SyncHookFixGeneric
}

function Get-SyncHookActivation {
    param($Result)

    if ($null -eq $Result -or $Result.PSObject.Properties.Name -notcontains 'HookActivation') {
        return $null
    }
    return $Result.HookActivation
}

function Write-SyncHookSummary {
    param(
        [Parameter(Mandatory = $true)]
        [bool] $IsWhatIf
    )

    $modeLabel = $script:ToolkitMessage.SyncModePublished
    if ($IsWhatIf) {
        $modeLabel = $script:ToolkitMessage.SyncModeSimulation
    }

    $activation = $script:SyncHookActivation
    if ($null -ne $activation) {
        Write-Host ($script:ToolkitMessage.SyncHookActivationLine -f $modeLabel, [string]$activation.State) -ForegroundColor Cyan
        if (-not [string]::IsNullOrWhiteSpace([string]$activation.Note)) {
            Write-Host ('  {0}' -f ([string]$activation.Note).Trim()) -ForegroundColor DarkGray
        }
        foreach ($step in @($activation.Steps)) {
            Write-Host ($script:ToolkitMessage.SyncHookStepLine -f [string]$step) -ForegroundColor DarkGray
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$activation.DocsUrl)) {
            Write-Host ($script:ToolkitMessage.SyncHookDocsLine -f [string]$activation.DocsUrl) -ForegroundColor DarkGray
        }
    }

    $failures = $script:SyncHookFailures.ToArray()
    if ($failures.Count -gt 0) {
        Write-SyncError -Message ($script:ToolkitMessage.SyncHookFailuresHeader -f $failures.Count)
        foreach ($failure in $failures) {
            Write-SyncError -Message ($script:ToolkitMessage.SyncHookFailureLine -f [string]$failure.Message)
            Write-Host ($script:ToolkitMessage.SyncHookFailureFixLine -f [string]$failure.Fix) -ForegroundColor Yellow
        }
    }
}

function Complete-SyncRun {
    param(
        [Parameter()]
        [string] $AgentId,

        [Parameter(Mandatory = $true)]
        [bool] $IsWhatIf,

        [Parameter(Mandatory = $true)]
        [int] $ExitCode
    )

    $summaryPath = [Environment]::GetEnvironmentVariable($script:ToolkitConstant.SyncSummaryEnvironmentName)
    if (-not [string]::IsNullOrWhiteSpace($summaryPath)) {
        $summary = [PSCustomObject]@{
            Agent          = $AgentId
            WhatIf         = $IsWhatIf
            ExitCode       = $ExitCode
            HookActivation = $script:SyncHookActivation
            HookFailures   = $script:SyncHookFailures.ToArray()
        }
        Set-Content -LiteralPath $summaryPath -Value ($summary | ConvertTo-Json -Depth 6) -Encoding UTF8
    }

    exit $ExitCode
}

function Publish-RuntimeScripts {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $AdapterId,
        [Parameter()][switch] $UserScope,
        [Parameter()][switch] $AllowUserHome
    )

    # Serialize the complete runtime manifest publication against uninstall.
    # The lifecycle mutex is shared with ToolkitUninstallArtifacts; the nested
    # helper state keeps lock-file retirement deferred until this scope exits.
    # A sync contending with uninstall fails closed instead of waiting and
    # republishing files after cleanup has retired the lock.
    Enter-ToolkitFilesystemGate -RootPath $InstallRoot -LockFileName '.toolkit-managed-publish.lock' -TimeoutSeconds 0
    try {

    $manifestPath = Join-Path $RepoRoot 'scripts/runtime/runtime-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw ("Runtime script manifest is missing: {0}" -f $manifestPath)
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $toolkitRoots = New-Object System.Collections.Generic.List[string]
    [void]$toolkitRoots.Add([System.IO.Path]::GetFullPath($InstallRoot))
    foreach ($mapping in @($manifest.additionalToolkitRoots)) {
        if (-not [string]::Equals([string]$mapping.adapter, $AdapterId, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $includeMapping = switch ([string]$mapping.when) {
            'always' { $true; break }
            'user-scope' { $UserScope.IsPresent; break }
            'project' {
                $installLeaf = Split-Path -Leaf ([System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/'))
                -not [string]::Equals($installLeaf, '.agents', [System.StringComparison]::OrdinalIgnoreCase)
                break
            }
            default { throw ("Invalid runtime toolkit-root condition '{0}' for adapter '{1}'" -f $mapping.when, $mapping.adapter) }
        }
        if (-not $includeMapping) { continue }

        $relativeRoot = [string]$mapping.path
        if ([System.IO.Path]::IsPathRooted($relativeRoot) -or $relativeRoot -match '(^|[\\/])\.\.([\\/]|$)') {
            throw ("Invalid additional toolkit root for adapter '{0}': {1}" -f $mapping.adapter, $relativeRoot)
        }
        [void]$toolkitRoots.Add([System.IO.Path]::GetFullPath((Join-Path $InstallRoot $relativeRoot)))
    }

    $uniqueRoots = @($toolkitRoots | Select-Object -Unique)
    foreach ($toolkitRoot in $uniqueRoots) {
        foreach ($entry in @($manifest.files)) {
            if ($entry.class -notin @('runtime', 'support')) {
                throw ("Invalid runtime manifest class '{0}' for {1}" -f $entry.class, $entry.source)
            }
            $source = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot ([string]$entry.source)))
            $destinationRelative = Join-Path ([string]$manifest.destinationRoot) ([string]$entry.destination)
            $destination = [System.IO.Path]::GetFullPath((Join-Path $toolkitRoot $destinationRelative))
            $installPrefix = $toolkitRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
            if (-not $destination.StartsWith($installPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw ("Runtime destination escapes toolkit root '{0}': {1}" -f $toolkitRoot, $entry.destination)
            }
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                throw ("Runtime source missing for caller '{0}': {1}" -f $entry.caller, $entry.source)
            }
            $destinationDirectory = Split-Path -Parent $destination
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

            # Re-resolve every path after directory creation and immediately before
            # copying. This closes the gap where an adapter publish or a reparse
            # point swap could redirect runtime files after the initial root check.
            $confirmedInstallRoot = Confirm-InstallRootAllowsWrite -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $RepoRoot
            $confirmedToolkitRoot = Confirm-InstallRootAllowsWrite -InstallRoot $toolkitRoot -AllowUserHome:$AllowUserHome -RepoRoot $RepoRoot
            $confirmedDestinationDirectory = Confirm-InstallRootAllowsWrite -InstallRoot $destinationDirectory -AllowUserHome:$AllowUserHome -RepoRoot $RepoRoot

            $comparison = [System.StringComparison]::Ordinal
            if (Test-ToolkitIsWindowsPlatform) {
                $comparison = [System.StringComparison]::OrdinalIgnoreCase
            }
            $installPrefix = $confirmedInstallRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
            if (-not [string]::Equals($confirmedToolkitRoot, $confirmedInstallRoot, $comparison) -and
                -not $confirmedToolkitRoot.StartsWith($installPrefix, $comparison)) {
                throw ("Runtime toolkit root resolves outside InstallRoot '{0}': {1}" -f $confirmedInstallRoot, $confirmedToolkitRoot)
            }
            $toolkitPrefix = $confirmedToolkitRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
            if (-not $confirmedDestinationDirectory.StartsWith($toolkitPrefix, $comparison)) {
                throw ("Runtime destination resolves outside toolkit root '{0}': {1}" -f $confirmedToolkitRoot, $confirmedDestinationDirectory)
            }

            $confirmedDestination = Join-Path $confirmedDestinationDirectory (Split-Path -Leaf $destination)
            Copy-Item -LiteralPath $source -Destination $confirmedDestination -Force
        }
    }
    Write-Host ("Publish-RuntimeScripts: OK ({0} allowlisted files across {1} toolkit root(s))" -f @($manifest.files).Count, $uniqueRoots.Count) -ForegroundColor Green
    }
    finally {
        Exit-ToolkitFilesystemGate -RootPath $InstallRoot -LockFileName '.toolkit-managed-publish.lock'
    }
}

$script:SyncHookActivation = $null
$script:SyncHookFailures = New-Object System.Collections.Generic.List[object]

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
        $paramNames = @($command.Parameters.Keys)
        if ($WhatIf.IsPresent -and ($paramNames -contains 'WhatIf')) {
            $publishArgs['WhatIf'] = $true
        }
        if (
            -not [string]::IsNullOrWhiteSpace($resolvedMode) -and
            ($paramNames -contains $script:ToolkitConstant.ModeParameterName)
        ) {
            $publishArgs[$script:ToolkitConstant.ModeParameterName] = $resolvedMode
        }
        if (
            $AllowUserHome.IsPresent -and
            ($paramNames -contains $script:ToolkitConstant.AllowUserHomeParameterName)
        ) {
            $publishArgs[$script:ToolkitConstant.AllowUserHomeParameterName] = $true
        }
        if (
            $UserScope.IsPresent -and
            ($paramNames -contains $script:ToolkitConstant.UserScopeParameterName)
        ) {
            $publishArgs[$script:ToolkitConstant.UserScopeParameterName] = $true
        }

        if ($commandName -eq $script:ToolkitConstant.HooksPublishCommandName) {
            $hookPublish = Invoke-SyncHooksPublish -Command $command -PublishArgs $publishArgs
            $script:SyncHookActivation = Get-SyncHookActivation -Result $hookPublish.Result
            if ($hookPublish.Failed) {
                Write-SyncError -Message ($script:ToolkitMessage.SyncHookPublishFailedNonFatal -f $resolved.AgentId, $hookPublish.Message)
                [void]$script:SyncHookFailures.Add([PSCustomObject]@{
                    Message = $hookPublish.Message
                    Fix     = (Get-SyncHookFixMessage -Activation $script:SyncHookActivation)
                })
                continue
            }
            Write-SyncPublishOk -CommandName $commandName -Result $hookPublish.Result
            continue
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

        Write-SyncPublishOk -CommandName $commandName -Result $result
    }

    if (-not $WhatIf.IsPresent) {
        $resolvedInstallRoot = Confirm-InstallRootAllowsWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
        Publish-RuntimeScripts -RepoRoot $repoRoot -InstallRoot $resolvedInstallRoot -AdapterId $resolved.AgentId -UserScope:$UserScope -AllowUserHome:$AllowUserHome
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
        Complete-SyncRun -AgentId $resolved.AgentId -IsWhatIf $WhatIf.IsPresent -ExitCode 1
    }
    if ($sddResult.PSObject.Properties.Name -contains 'Implemented' -and $sddResult.Implemented -eq $false) {
        $detail = if ($sddResult.PSObject.Properties.Name -contains 'Message') { [string]$sddResult.Message } else { 'Get-SddRoot' }
        Write-SyncError -Message ($script:ToolkitMessage.AdapterNotImplemented -f $resolved.AgentId, $detail)
        Complete-SyncRun -AgentId $resolved.AgentId -IsWhatIf $WhatIf.IsPresent -ExitCode 1
    }
    if ($sddResult.PSObject.Properties.Name -contains 'Success' -and $sddResult.Success -eq $false) {
        $detail = if ($sddResult.PSObject.Properties.Name -contains 'Message') { [string]$sddResult.Message } else { 'Get-SddRoot' }
        Write-SyncError -Message ($script:ToolkitMessage.SyncPublishFailed -f $resolved.AgentId, $detail)
        Complete-SyncRun -AgentId $resolved.AgentId -IsWhatIf $WhatIf.IsPresent -ExitCode 1
    }

    Write-SyncPublishOk -CommandName 'Get-SddRoot -Prepare' -Result $sddResult

    if (-not $WhatIf.IsPresent -and -not $DeferPreferences.IsPresent) {
        $null = Invoke-ToolkitEnsurePreferences -SddRoot $sddResult.SddRoot
    }

    Write-SyncHookSummary -IsWhatIf $WhatIf.IsPresent

    if ($script:SyncHookFailures.Count -gt 0) {
        Write-SyncError -Message $script:ToolkitMessage.SyncCompletedWithHookFailures
        Complete-SyncRun -AgentId $resolved.AgentId -IsWhatIf $WhatIf.IsPresent -ExitCode 0
    }

    Write-Host 'Sync completed.' -ForegroundColor Green
    Complete-SyncRun -AgentId $resolved.AgentId -IsWhatIf $WhatIf.IsPresent -ExitCode 0
}
catch {
    Write-SyncError -Message $_.Exception.Message
    Complete-SyncRun -AgentId $Agent -IsWhatIf $WhatIf.IsPresent -ExitCode 1
}
