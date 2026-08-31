#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Antigravity Publish-Hooks (config/hooks path+secrets guard).

.DESCRIPTION
  Mapping:
  adapters/antigravity/assets/hooks/* -> InstallRoot/config/hooks/*
  Also copies adapters/_shared/GuardCommon.ps1 beside published hooks.
  When hooks capability is false: documented no-op (no files written).
  Never writes under legacy antigravity-ide/plugins. Sidecars/Automations OOS.
#>

$script:AntigravityHooksHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:AntigravityHooksHelperDirectory)) {
    $script:AntigravityHooksHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-AntigravityHooksAssetsRoot {
    [CmdletBinding()]
    param()

    return (Join-Path (
            Join-Path $script:AntigravityHooksHelperDirectory $script:AntigravityPathConstant.AssetsDirectoryName
        ) $script:AntigravityPathConstant.HooksDirectoryName)
}

function Test-AntigravityHooksCapable {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AntigravityAdapterCapabilityFlags) {
        return $true
    }

    if (-not $script:AntigravityAdapterCapabilityFlags.Contains('hooks')) {
        return $true
    }

    return [bool]$script:AntigravityAdapterCapabilityFlags['hooks']
}

function Copy-AntigravityHookFilesTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceHooksRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationHooksRoot,

        [Parameter()]
        [string] $RepoRoot
    )

    if (-not (Test-Path -LiteralPath $DestinationHooksRoot)) {
        New-Item -ItemType Directory -Path $DestinationHooksRoot -Force | Out-Null
    }

    $filesCopied = 0
    $sourceFiles = Get-ChildItem -LiteralPath $SourceHooksRoot -Recurse -File -ErrorAction Stop
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($SourceHooksRoot.Length).TrimStart('\', '/')
        $destinationPath = Join-Path $DestinationHooksRoot $relative
        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
        $filesCopied++
    }

    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        $sharedSource = Join-Path $RepoRoot $script:AntigravityPathConstant.SharedGuardCommonRelativePath
        if (Test-Path -LiteralPath $sharedSource) {
            $sharedDest = Join-Path $DestinationHooksRoot $script:AntigravityPathConstant.SharedGuardCommonFileName
            Copy-Item -LiteralPath $sharedSource -Destination $sharedDest -Force
            $filesCopied++
        }
    }

    return $filesCopied
}

function Invoke-AntigravityPublishHooks {
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
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
    $mapped = Get-AntigravityMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationHooksRoot = $mapped.FixtureHooksPath
    $legacyBridgeRelative = $script:AntigravityAdapterConstant.LegacyBridgeRelativePath
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $legacyBridgePath = Join-Path $resolvedInstallRoot ($legacyBridgeRelative -replace '/', $sep)

    if (-not (Test-AntigravityHooksCapable)) {
        $message = if ($WhatIf.IsPresent) {
            ($script:AntigravityAdapterMessage.HooksWouldNoOp -f $script:AntigravityAdapterConstant.OfficialHooksRelativePath, $legacyBridgeRelative)
        }
        else {
            $script:AntigravityAdapterMessage.HooksNoOpNotCapable
        }

        return [PSCustomObject]@{
            Success                   = $true
            Implemented               = $true
            NoOp                      = $true
            Skipped                   = $true
            CommandName               = 'Publish-Hooks'
            WhatIf                    = [bool]$WhatIf.IsPresent
            InstallRoot               = $resolvedInstallRoot
            OfficialHooksRelativePath = $script:AntigravityAdapterConstant.OfficialHooksRelativePath
            OfficialHooksPath         = $destinationHooksRoot
            LegacyBridgeRelativePath  = $legacyBridgeRelative
            LegacyBridgePath          = $legacyBridgePath
            FilesCopied               = 0
            RequiresShellHooks        = $false
            SmokeIgnoresHooks         = $true
            SmokeTargetsLegacyBridge  = $false
            Message                   = $message
            ExitCode                  = 0
        }
    }

    $repoRoot = Get-AntigravityAdapterRepoRoot
    $sourceHooksRoot = Get-AntigravityHooksAssetsRoot
    if (-not (Test-Path -LiteralPath $sourceHooksRoot)) {
        throw ($script:AntigravityPublishMessage.HooksAssetsMissing -f $sourceHooksRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success                   = $true
            Implemented               = $true
            NoOp                      = $false
            Skipped                   = $false
            CommandName               = 'Publish-Hooks'
            WhatIf                    = $true
            InstallRoot               = $resolvedInstallRoot
            OfficialHooksRelativePath = $script:AntigravityAdapterConstant.OfficialHooksRelativePath
            OfficialHooksPath         = $destinationHooksRoot
            SourceRoot                = $sourceHooksRoot
            LegacyBridgeRelativePath  = $legacyBridgeRelative
            LegacyBridgePath          = $legacyBridgePath
            FilesCopied               = 0
            RequiresShellHooks        = $true
            SmokeIgnoresHooks         = $false
            SmokeTargetsLegacyBridge  = $false
            Message                   = ($script:AntigravityPublishMessage.HooksWhatIfOk -f $destinationHooksRoot)
            ExitCode                  = 0
        }
    }

    $resolvedInstallRoot = Initialize-AntigravityInstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $mapped = Get-AntigravityMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationHooksRoot = $mapped.FixtureHooksPath

    $filesCopied = Copy-AntigravityHookFilesTree `
        -SourceHooksRoot $sourceHooksRoot `
        -DestinationHooksRoot $destinationHooksRoot `
        -RepoRoot $repoRoot

    return [PSCustomObject]@{
        Success                   = $true
        Implemented               = $true
        NoOp                      = $false
        Skipped                   = $false
        CommandName               = 'Publish-Hooks'
        WhatIf                    = $false
        InstallRoot               = $resolvedInstallRoot
        OfficialHooksRelativePath = $script:AntigravityAdapterConstant.OfficialHooksRelativePath
        OfficialHooksPath         = $destinationHooksRoot
        SourceRoot                = $sourceHooksRoot
        LegacyBridgeRelativePath  = $legacyBridgeRelative
        LegacyBridgePath          = $legacyBridgePath
        FilesCopied               = $filesCopied
        RequiresShellHooks        = $true
        SmokeIgnoresHooks         = $false
        SmokeTargetsLegacyBridge  = $false
        Message                   = ($script:AntigravityPublishMessage.HooksPublishedOk -f $filesCopied, $destinationHooksRoot)
        ExitCode                  = 0
    }
}
