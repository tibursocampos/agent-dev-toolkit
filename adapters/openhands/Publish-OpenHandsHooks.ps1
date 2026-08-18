#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenHands Publish-Hooks (.openhands/hooks.json + .openhands/hooks/*.sh).
#>

$script:OpenHandsHooksModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenHandsHooksModuleDirectory)) {
    $script:OpenHandsHooksModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-OpenHandsHooksAssetPath {
    [CmdletBinding()]
    param()

    return (Join-Path (
            Join-Path (Join-Path $script:OpenHandsHooksModuleDirectory $script:OpenHandsAdapterConstant.AssetsDirectoryName) $script:OpenHandsAdapterConstant.AssetsHooksDirectoryName
        ) $script:OpenHandsAdapterConstant.HooksSessionStartScriptName)
}

function New-OpenHandsMinimalHooksObject {
    [CmdletBinding()]
    param()

    return [ordered]@{
        ($script:OpenHandsAdapterConstant.HooksSessionStartEventSnake) = @(
            [ordered]@{
                matcher = $script:OpenHandsAdapterConstant.HooksMatcherAll
                hooks   = @(
                    [ordered]@{
                        command = $script:OpenHandsAdapterConstant.HooksSessionStartCommandRelative
                        timeout = [int]$script:OpenHandsAdapterConstant.HooksTimeoutSeconds
                    }
                )
            }
        )
    }
}

function Write-OpenHandsSessionStartHookScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksScriptsDirectory,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $sourceScript = Get-OpenHandsHooksAssetPath
    if (-not (Test-Path -LiteralPath $sourceScript)) {
        throw ($script:OpenHandsAdapterMessage.HooksAssetsMissing -f $sourceScript)
    }

    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $HooksScriptsDirectory -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $HooksScriptsDirectory)) {
        New-Item -ItemType Directory -Path $HooksScriptsDirectory -Force | Out-Null
    }

    $destinationPath = Join-Path $HooksScriptsDirectory $script:OpenHandsAdapterConstant.HooksSessionStartScriptName
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationPath `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    Copy-Item -LiteralPath $sourceScript -Destination $destinationPath -Force
    return $destinationPath
}

function Write-OpenHandsHooksJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksDirectory,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $HooksDirectory -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $HooksDirectory)) {
        New-Item -ItemType Directory -Path $HooksDirectory -Force | Out-Null
    }

    $hooksPath = Join-Path $HooksDirectory $script:OpenHandsAdapterConstant.HooksJsonFileName
    Assert-ToolkitManagedPathContained `
        -CandidatePath $hooksPath `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $payload = New-OpenHandsMinimalHooksObject
    $json = ($payload | ConvertTo-Json -Depth $script:OpenHandsAdapterConstant.JsonConvertDepthDeep)
    Write-OpenHandsUtf8NoBomFile -Path $hooksPath -Content $json
    return $hooksPath
}

function Invoke-OpenHandsPublishHooks {
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenHandsAdapterRepoRoot
    Initialize-OpenHandsInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $hooksDirectory = $mapped.FixtureHooksPath
    $hooksScriptsDirectory = $mapped.FixtureHooksScriptsPath
    $hooksJsonPath = Join-Path $hooksDirectory $script:OpenHandsAdapterConstant.HooksJsonFileName
    $hooksScriptPath = Join-Path $hooksScriptsDirectory $script:OpenHandsAdapterConstant.HooksSessionStartScriptName

    $hooksCapable = $true
    if ($null -ne $script:OpenHandsAdapterCapabilityFlags -and $script:OpenHandsAdapterCapabilityFlags.Contains('hooks')) {
        $hooksCapable = [bool]$script:OpenHandsAdapterCapabilityFlags['hooks']
    }

    if (-not $hooksCapable) {
        return [PSCustomObject]@{
            Success        = $true
            Implemented    = $true
            Skipped        = $true
            CommandName    = 'Publish-Hooks'
            WhatIf         = $WhatIf.IsPresent
            InstallRoot    = $resolvedInstallRoot
            HooksRoot      = $hooksDirectory
            HooksPath      = $null
            SessionStartPath = $null
            HooksRelative  = $script:OpenHandsAdapterConstant.OfficialHooksRelativePath
            HooksTrustNote = $script:OpenHandsAdapterConstant.HooksFilesystemOnlyNote
            Message        = ($script:OpenHandsAdapterMessage.HooksSkippedNotCapable -f $hooksDirectory)
            ExitCode       = 0
        }
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            Skipped          = $false
            CommandName      = 'Publish-Hooks'
            WhatIf           = $true
            InstallRoot      = $resolvedInstallRoot
            HooksRoot        = $hooksDirectory
            HooksPath        = $hooksJsonPath
            SessionStartPath = $hooksScriptPath
            HooksRelative    = $script:OpenHandsAdapterConstant.OfficialHooksRelativePath
            HooksTrustNote   = $script:OpenHandsAdapterConstant.HooksFilesystemOnlyNote
            Message          = ($script:OpenHandsAdapterMessage.HooksWhatIfOk -f $hooksDirectory)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $hooksDirectory = $mapped.FixtureHooksPath
    $hooksScriptsDirectory = $mapped.FixtureHooksScriptsPath

    $writtenSession = Write-OpenHandsSessionStartHookScript -HooksScriptsDirectory $hooksScriptsDirectory -InstallRoot $resolvedInstallRoot
    $writtenHooks = Write-OpenHandsHooksJson -HooksDirectory $hooksDirectory -InstallRoot $resolvedInstallRoot

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        Skipped          = $false
        CommandName      = 'Publish-Hooks'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        HooksRoot        = $hooksDirectory
        HooksPath        = $writtenHooks
        SessionStartPath = $writtenSession
        HooksRelative    = $script:OpenHandsAdapterConstant.OfficialHooksRelativePath
        HooksTrustNote   = $script:OpenHandsAdapterConstant.HooksFilesystemOnlyNote
        Message          = ($script:OpenHandsAdapterMessage.HooksPublishedOk -f $writtenHooks, $writtenSession)
        ExitCode         = 0
    }
}
