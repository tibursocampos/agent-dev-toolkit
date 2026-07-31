#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenCode Publish-Hooks (Decision A: minimal JS plugin under plugins/).

.DESCRIPTION
  Mapping:
  adapters/opencode/assets/plugins/* -> InstallRoot/plugins/*
  Official layout: ~/.config/opencode/plugins/*.js (https://opencode.ai/docs/plugins/).
  RN03: never publish or assert shell/PS1 hooks.
  RN04: Decision A publishes a minimal JS marker plugin; smoke is filesystem-only.
  Re-publish overwrites managed plugin files; does not delete alien files under plugins/.
#>

$script:OpenCodeHooksHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenCodeHooksHelperDirectory)) {
    $script:OpenCodeHooksHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-OpenCodeHooksAssetsRoot {
    [CmdletBinding()]
    param()

    return (Join-Path (
            Join-Path $script:OpenCodeHooksHelperDirectory $script:OpenCodePathConstant.AssetsDirectoryName
        ) $script:OpenCodePathConstant.PluginsDirectoryName)
}

function Test-OpenCodeHooksCapable {
    [CmdletBinding()]
    param()

    if ($null -eq $script:OpenCodeAdapterCapabilityFlags) {
        return $true
    }

    $hooksFlag = $script:OpenCodeAdapterCapabilityFlags['hooks']
    if ($null -eq $hooksFlag) {
        return $true
    }

    return [bool]$hooksFlag
}

function Copy-OpenCodePluginFilesTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePluginsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationPluginsRoot,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        $hooksRepoRoot = Split-Path -Parent (Split-Path -Parent $script:OpenCodeHooksHelperDirectory)
        . (Join-Path (Join-Path $hooksRepoRoot 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1')
    }

    $sourceRootFull = Get-NormalizedFullPath -Path $SourcePluginsRoot
    $destinationRootFull = Get-NormalizedFullPath -Path $DestinationPluginsRoot
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destinationRootFull -InstallRoot $InstallRoot

    if (-not (Test-Path -LiteralPath $destinationRootFull)) {
        New-Item -ItemType Directory -Path $destinationRootFull -Force | Out-Null
    }

    # Re-assert after create / when dest already existed as a reparse child.
    $destinationRootFull = Get-NormalizedFullPath -Path $destinationRootFull
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destinationRootFull -InstallRoot $InstallRoot

    $filesCopied = 0
    $sourceFiles = Get-ChildItem -LiteralPath $sourceRootFull -Recurse -File -ErrorAction Stop
    foreach ($file in $sourceFiles) {
        Assert-ToolkitManagedPathContained `
            -CandidatePath $file.FullName `
            -RootPath $sourceRootFull `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot

        $relative = $file.FullName.Substring($sourceRootFull.Length).TrimStart('\', '/')
        if (Test-ToolkitManagedRelativeHasParentSegment -RelativePath $relative) {
            throw ($script:ToolkitMessage.ManagedCopyRelativePathInvalid -f $relative)
        }

        $destinationPath = Join-Path $destinationRootFull $relative
        Assert-ToolkitManagedPathContained `
            -CandidatePath $destinationPath `
            -RootPath $destinationRootFull `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot
        Assert-ToolkitManagedPathContained `
            -CandidatePath $destinationPath `
            -RootPath $InstallRoot `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
            -RequireStrictChild

        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
        $filesCopied++
    }

    return $filesCopied
}

function Invoke-OpenCodePublishHooks {
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

    $repoRoot = Get-OpenCodePublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationPluginsRoot = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.PluginsDirectoryName

    if (-not (Test-OpenCodeHooksCapable)) {
        return [PSCustomObject]@{
            Success                 = $true
            Implemented             = $true
            CommandName             = 'Publish-Hooks'
            NoOp                    = $true
            WhatIf                  = [bool]$WhatIf.IsPresent
            MvpHooksDecision        = $script:OpenCodePathConstant.MvpHooksDecisionA
            HooksSemantics          = $script:OpenCodeAdapterConstant.HooksSemanticsValue
            InstallRoot             = $resolvedInstallRoot
            PluginsRoot             = $destinationPluginsRoot
            SourceRoot              = $null
            PluginPath              = $null
            FilesCopied             = 0
            RequiresShellHooks      = $false
            Message                 = $script:OpenCodePublishMessage.HooksNoOpNotCapable
            ExitCode                = 0
            SmokeFilesystemOnlyNote = $script:OpenCodePathConstant.SmokeFilesystemOnlyNote
        }
    }

    $sourcePluginsRoot = Get-OpenCodeHooksAssetsRoot
    $markerFileName = $script:OpenCodePathConstant.PluginMarkerFileName
    $destinationPluginPath = Join-Path $destinationPluginsRoot $markerFileName

    if (-not (Test-Path -LiteralPath $sourcePluginsRoot)) {
        throw ($script:OpenCodePublishMessage.HooksAssetsMissing -f $sourcePluginsRoot)
    }

    $markerSource = Join-Path $sourcePluginsRoot $markerFileName
    if (-not (Test-Path -LiteralPath $markerSource)) {
        throw ($script:OpenCodePublishMessage.HooksAssetsMissing -f $markerSource)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success                 = $true
            Implemented             = $true
            CommandName             = 'Publish-Hooks'
            NoOp                    = $false
            WhatIf                  = $true
            MvpHooksDecision        = $script:OpenCodePathConstant.MvpHooksDecisionA
            HooksSemantics          = $script:OpenCodeAdapterConstant.HooksSemanticsValue
            InstallRoot             = $resolvedInstallRoot
            PluginsRoot             = $destinationPluginsRoot
            SourceRoot              = $sourcePluginsRoot
            PluginPath              = $destinationPluginPath
            FilesCopied             = 0
            RequiresShellHooks      = $false
            Message                 = ($script:OpenCodePublishMessage.HooksWhatIfOk -f $destinationPluginsRoot)
            ExitCode                = 0
            SmokeFilesystemOnlyNote = $script:OpenCodePathConstant.SmokeFilesystemOnlyNote
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationPluginsRoot = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.PluginsDirectoryName
    $destinationPluginPath = Join-Path $destinationPluginsRoot $script:OpenCodePathConstant.PluginMarkerFileName
    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $destinationPluginsRoot -InstallRoot $resolvedInstallRoot
    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $destinationPluginPath -InstallRoot $resolvedInstallRoot

    $filesCopied = Copy-OpenCodePluginFilesTree `
        -SourcePluginsRoot $sourcePluginsRoot `
        -DestinationPluginsRoot $destinationPluginsRoot `
        -InstallRoot $resolvedInstallRoot

    return [PSCustomObject]@{
        Success                 = $true
        Implemented             = $true
        CommandName             = 'Publish-Hooks'
        NoOp                    = $false
        WhatIf                  = $false
        MvpHooksDecision        = $script:OpenCodePathConstant.MvpHooksDecisionA
        HooksSemantics          = $script:OpenCodeAdapterConstant.HooksSemanticsValue
        InstallRoot             = $resolvedInstallRoot
        PluginsRoot             = $destinationPluginsRoot
        SourceRoot              = $sourcePluginsRoot
        PluginPath              = $destinationPluginPath
        FilesCopied             = $filesCopied
        RequiresShellHooks      = $false
        Message                 = ($script:OpenCodePublishMessage.HooksPublishedOk -f $filesCopied, $destinationPluginsRoot)
        ExitCode                = 0
        SmokeFilesystemOnlyNote = $script:OpenCodePathConstant.SmokeFilesystemOnlyNote
    }
}
