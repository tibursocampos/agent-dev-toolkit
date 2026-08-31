#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Copilot Publish-Hooks (adapter assets -> InstallRoot/hooks).

.DESCRIPTION
  Mapping (Mode user|repo; relative paths identical under InstallRoot):
  adapters/copilot/assets/hooks/* -> InstallRoot/hooks/*
  Mode user: InstallRoot models ~/.copilot. Mode repo: InstallRoot models .github.
  When hooks capability is false: documented no-op (no files written).
  Re-publish overwrites managed files; does not delete aliens under hooks/.
  Smoke validates filesystem presence - Copilot IDE extension is out of scope.
  Mode repo must target a fixture InstallRoot - never the toolkit working-tree .github by default.
#>

$script:CopilotHooksHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CopilotHooksHelperDirectory)) {
    $script:CopilotHooksHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-CopilotHooksAssetsRoot {
    [CmdletBinding()]
    param()

    return (Join-Path (
            Join-Path $script:CopilotHooksHelperDirectory $script:CopilotPathConstant.AssetsDirectoryName
        ) $script:CopilotPathConstant.HooksDirectoryName)
}

function Test-CopilotHooksCapable {
    [CmdletBinding()]
    param()

    if ($null -eq $script:CopilotAdapterCapabilityFlags) {
        return $true
    }

    $hooksFlag = $script:CopilotAdapterCapabilityFlags['hooks']
    if ($null -eq $hooksFlag) {
        return $true
    }

    return [bool]$hooksFlag
}

function Copy-CopilotHookFilesTree {
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
    $sourceFiles = Get-ChildItem -LiteralPath $SourceHooksRoot -Recurse -File
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
        $sharedSource = Join-Path $RepoRoot $script:CopilotPathConstant.SharedGuardCommonRelativePath
        if (Test-Path -LiteralPath $sharedSource) {
            $sharedDest = Join-Path $DestinationHooksRoot $script:CopilotPathConstant.SharedGuardCommonFileName
            Copy-Item -LiteralPath $sharedSource -Destination $sharedDest -Force
            $filesCopied++
        }
    }

    return $filesCopied
}

function Invoke-CopilotPublishHooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [string] $Mode,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotPublishMessage.InstallRootRequired
    }

    $normalizedMode = Get-CopilotPublishNormalizedMode -Mode $Mode

    if (-not (Test-CopilotHooksCapable)) {
        return [PSCustomObject]@{
            Success                 = $true
            Implemented             = $true
            CommandName             = 'Publish-Hooks'
            NoOp                    = $true
            WhatIf                  = [bool]$WhatIf.IsPresent
            Mode                    = $normalizedMode
            InstallRoot             = $InstallRoot.Trim()
            HooksRoot               = $null
            SourceRoot              = $null
            FilesCopied             = 0
            Message                 = $script:CopilotPublishMessage.HooksNoOpNotCapable
            ExitCode                = 0
            SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        }
    }

    $repoRoot = Get-CopilotPublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceHooksRoot = Get-CopilotHooksAssetsRoot
    $destinationHooksRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.HooksDirectoryName

    if (-not (Test-Path -LiteralPath $sourceHooksRoot)) {
        throw ($script:CopilotPublishMessage.HooksAssetsMissing -f $sourceHooksRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success                 = $true
            Implemented             = $true
            CommandName             = 'Publish-Hooks'
            NoOp                    = $false
            WhatIf                  = $true
            Mode                    = $normalizedMode
            InstallRoot             = $resolvedInstallRoot
            HooksRoot               = $destinationHooksRoot
            SourceRoot              = $sourceHooksRoot
            FilesCopied             = 0
            Message                 = ($script:CopilotPublishMessage.HooksWhatIfOk -f $destinationHooksRoot, $normalizedMode)
            ExitCode                = 0
            SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationHooksRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.HooksDirectoryName

    $filesCopied = Copy-CopilotHookFilesTree `
        -SourceHooksRoot $sourceHooksRoot `
        -DestinationHooksRoot $destinationHooksRoot `
        -RepoRoot $repoRoot
    $placeholderMap = Get-CopilotPlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-CopilotPlaceholdersInTree -RootPath $destinationHooksRoot -PlaceholderMap $placeholderMap
    Assert-CopilotPlaceholdersResolved -RootPath $destinationHooksRoot

    return [PSCustomObject]@{
        Success                 = $true
        Implemented             = $true
        CommandName             = 'Publish-Hooks'
        NoOp                    = $false
        WhatIf                  = $false
        Mode                    = $normalizedMode
        InstallRoot             = $resolvedInstallRoot
        HooksRoot               = $destinationHooksRoot
        SourceRoot              = $sourceHooksRoot
        FilesCopied             = $filesCopied
        Message                 = ($script:CopilotPublishMessage.HooksPublishedOk -f $filesCopied, $destinationHooksRoot, $normalizedMode)
        ExitCode                = 0
        SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
    }
}
