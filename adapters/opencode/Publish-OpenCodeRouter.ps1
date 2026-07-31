#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenCode Publish-Router (core/router/AGENTS.md -> InstallRoot/AGENTS.md).

.DESCRIPTION
  Maps the neutral core router to the OpenCode config-root AGENTS.md surface
  (fixture models ~/.config/opencode/AGENTS.md). Resolves {{TOOLKIT_ROOT}},
  {{SDD_ROOT}}, and {{GUARDRAILS_PATH}} under InstallRoot. Does not publish a
  Cursor-style rules/*.mdc tree (rules capability is false; use Publish-Policy no-op).
  Uses Resolve-InstallRoot (USERPROFILE guard).
#>

$script:OpenCodeRouterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenCodeRouterModuleDirectory)) {
    $script:OpenCodeRouterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-OpenCodeRouterRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-OpenCodeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-OpenCodeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:OpenCodeRouterModuleDirectory))
}

function Invoke-OpenCodePublishRouter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenCodeRouterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterRoot = Join-Path (Join-Path $repoRoot $script:OpenCodePathConstant.CoreDirectoryName) $script:OpenCodePathConstant.RouterDirectoryName
    $sourceAgentsPath = Join-Path $sourceRouterRoot $script:OpenCodePathConstant.AgentsFileName
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.AgentsFileName

    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:OpenCodePublishMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success            = $true
            Implemented        = $true
            CommandName        = 'Publish-Router'
            WhatIf             = $true
            InstallRoot        = $resolvedInstallRoot
            AgentsPath         = $destinationAgentsPath
            SourcePath         = $sourceAgentsPath
            FilesCopied        = 0
            PublishesCursorMdc = $false
            PolicyNote         = $script:OpenCodePublishMessage.PolicyNoOp
            Message            = ($script:OpenCodePublishMessage.RouterWhatIfOk -f $destinationAgentsPath)
            ExitCode           = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.AgentsFileName

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    }
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $raw = [System.IO.File]::ReadAllText($sourceAgentsPath)
    $placeholderMap = Get-OpenCodePlaceholderMap -InstallRoot $resolvedInstallRoot
    $updated = $raw
    foreach ($key in $placeholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$placeholderMap[$key])
        }
    }

    foreach ($placeholder in @(
            $script:OpenCodePathConstant.PlaceholderToolkitRoot,
            $script:OpenCodePathConstant.PlaceholderSddRoot,
            $script:OpenCodePathConstant.PlaceholderGuardrailsPath
        )) {
        if ($updated.Contains($placeholder)) {
            throw ($script:OpenCodePublishMessage.PlaceholderUnresolved -f $placeholder, $destinationAgentsPath)
        }
    }

    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationAgentsPath, $updated, $utf8NoBom)

    return [PSCustomObject]@{
        Success            = $true
        Implemented        = $true
        CommandName        = 'Publish-Router'
        WhatIf             = $false
        InstallRoot        = $resolvedInstallRoot
        AgentsPath         = $destinationAgentsPath
        SourcePath         = $sourceAgentsPath
        FilesCopied        = 1
        PublishesCursorMdc = $false
        PolicyNote         = $script:OpenCodePublishMessage.PolicyNoOp
        Message            = ($script:OpenCodePublishMessage.RouterPublishedOk -f $destinationAgentsPath)
        ExitCode           = 0
    }
}
