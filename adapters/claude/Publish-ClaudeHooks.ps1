#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Claude Publish-Hooks (scripts + settings.json merge).

.DESCRIPTION
  Mapping: adapters/claude/assets/hooks/* -> <InstallRoot>/hooks/*
  After scripts, merges settings.json (hooks keyed + permissions.allow additive).
  Re-publish overwrites managed script files; does not delete alien files under hooks/.
  Smoke validates filesystem presence - Claude trust UI is out of scope.
#>

$script:ClaudeHooksHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeHooksHelperDirectory)) {
    $script:ClaudeHooksHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-ClaudeHooksAssetsRoot {
    [CmdletBinding()]
    param()

    return (Join-Path (
            Join-Path $script:ClaudeHooksHelperDirectory $script:ClaudePathConstant.AssetsDirectoryName
        ) $script:ClaudePathConstant.HooksDirectoryName)
}

function Copy-ClaudeHookScriptsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceHooksRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationHooksRoot
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

    return $filesCopied
}

function Invoke-ClaudePublishHooks {
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
        throw $script:ClaudePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ClaudeAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceHooksRoot = Get-ClaudeHooksAssetsRoot
    $destinationHooksRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.HooksDirectoryName

    if (-not (Test-Path -LiteralPath $sourceHooksRoot)) {
        throw ($script:ClaudePublishMessage.HooksAssetsMissing -f $sourceHooksRoot)
    }

    if ($WhatIf.IsPresent) {
        $settingsWhatIf = Invoke-ClaudeMergeSettings -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -WhatIf
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Hooks'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            HooksRoot    = $destinationHooksRoot
            SourceRoot   = $sourceHooksRoot
            SettingsPath = $settingsWhatIf.SettingsPath
            FilesCopied  = 0
            Message      = ('{0}; {1}' -f ($script:ClaudePublishMessage.HooksWhatIfOk -f $destinationHooksRoot), $settingsWhatIf.Message)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationHooksRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.HooksDirectoryName

    $filesCopied = Copy-ClaudeHookScriptsTree -SourceHooksRoot $sourceHooksRoot -DestinationHooksRoot $destinationHooksRoot
    $placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-ClaudePlaceholdersInTree -RootPath $destinationHooksRoot -PlaceholderMap $placeholderMap
    Assert-ClaudePlaceholdersResolved -RootPath $destinationHooksRoot

    $settingsMerge = Invoke-ClaudeMergeSettings -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    if ($null -eq $settingsMerge -or $settingsMerge.Success -ne $true) {
        $detail = if ($null -ne $settingsMerge -and $settingsMerge.PSObject.Properties.Name -contains 'Message') {
            [string]$settingsMerge.Message
        }
        else {
            'settings.json merge failed'
        }
        return [PSCustomObject]@{
            Success      = $false
            Implemented  = $true
            CommandName  = 'Publish-Hooks'
            WhatIf       = $false
            InstallRoot  = $resolvedInstallRoot
            HooksRoot    = $destinationHooksRoot
            SourceRoot   = $sourceHooksRoot
            SettingsPath = if ($null -ne $settingsMerge) { $settingsMerge.SettingsPath } else { $null }
            FilesCopied  = $filesCopied
            Message      = $detail
            ExitCode     = 1
        }
    }

    return [PSCustomObject]@{
        Success      = $true
        Implemented  = $true
        CommandName  = 'Publish-Hooks'
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        HooksRoot    = $destinationHooksRoot
        SourceRoot   = $sourceHooksRoot
        SettingsPath = $settingsMerge.SettingsPath
        BackupPath   = $settingsMerge.BackupPath
        BackupTaken  = $settingsMerge.BackupTaken
        FilesCopied  = $filesCopied
        Message      = ('{0}; {1}' -f ($script:ClaudePublishMessage.HooksPublishedOk -f $filesCopied, $destinationHooksRoot), $settingsMerge.Message)
        ExitCode     = 0
    }
}
