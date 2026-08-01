#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Router (core/router -> InstallRoot/AGENTS.md).
#>

$script:CodexRouterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CodexRouterModuleDirectory)) {
    $script:CodexRouterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-CodexRouterAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:CodexRouterModuleDirectory))
}

function Get-CodexRouterPublishContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexPublishMessage.InstallRootRequired
    }

    $repoRoot = Get-CodexRouterAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsPath = Join-Path (
        Join-Path (Join-Path $repoRoot $script:CodexPathConstant.CoreDirectoryName) $script:CodexPathConstant.RouterDirectoryName
    ) $script:CodexPathConstant.AgentsFileName
    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:CodexPublishMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    return [System.IO.File]::ReadAllText($sourceAgentsPath)
}

function Invoke-CodexPublishRouter {
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
        throw $script:CodexPublishMessage.InstallRootRequired
    }

    $repoRoot = Get-CodexRouterAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsPath = Join-Path (
        Join-Path (Join-Path $repoRoot $script:CodexPathConstant.CoreDirectoryName) $script:CodexPathConstant.RouterDirectoryName
    ) $script:CodexPathConstant.AgentsFileName
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:CodexPathConstant.AgentsFileName

    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:CodexPublishMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success     = $true
            Implemented = $true
            CommandName = 'Publish-Router'
            WhatIf      = $true
            InstallRoot = $resolvedInstallRoot
            SourcePath  = $sourceAgentsPath
            AgentsPath  = $destinationAgentsPath
            Message     = ($script:CodexPublishMessage.RouterWhatIfOk -f $destinationAgentsPath)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:CodexPathConstant.AgentsFileName

    $publishedContent = Get-CodexRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationAgentsPath, $publishedContent, $utf8NoBom)

    . (Join-Path $libDir 'ToolkitManagedPublishInventory.ps1')
    Set-ToolkitManagedPublishInventoryEntryFromContent `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:CodexPathConstant.AgentsFileName `
        -PublishedContent $publishedContent

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Router'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        SourcePath  = $sourceAgentsPath
        AgentsPath  = $destinationAgentsPath
        Message     = ($script:CodexPublishMessage.RouterPublishedOk -f $destinationAgentsPath)
        ExitCode    = 0
    }
}
