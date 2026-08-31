#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Hooks (plugin/hooks/hooks.json + guard-pre-tool.ps1).

.DESCRIPTION
  Writes PreToolUse path/secrets guard for Bash and apply_patch|Edit|Write.
  RN03: never invoke or assert Codex /hooks trust UI.
#>

$script:CodexHooksModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CodexHooksModuleDirectory)) {
    $script:CodexHooksModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-CodexHooksAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:CodexHooksModuleDirectory))
}

function New-CodexPreToolUseHooksObject {
    [CmdletBinding()]
    param()

    $c = $script:CodexPathConstant
    $guardCommand = $c.HooksPreToolUseCommandTemplate
    $bashMatcher = $c.HooksPreToolUseBashMatcher
    $patchMatcher = $c.HooksPreToolUsePatchMatcher

    return [ordered]@{
        description = $c.HooksDescription
        hooks       = [ordered]@{
            ($c.HooksPreToolUseEventName) = @(
                [ordered]@{
                    matcher = $bashMatcher
                    hooks   = @(
                        [ordered]@{
                            type          = $c.HooksCommandType
                            command       = $guardCommand
                            statusMessage = $c.HooksPreToolUseStatusMessage
                        }
                    )
                },
                [ordered]@{
                    matcher = $patchMatcher
                    hooks   = @(
                        [ordered]@{
                            type          = $c.HooksCommandType
                            command       = $guardCommand
                            statusMessage = $c.HooksPreToolUseStatusMessage
                        }
                    )
                }
            )
        }
    }
}

function Write-CodexGuardPreToolScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksDirectory,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    if (-not (Test-Path -LiteralPath $HooksDirectory)) {
        New-Item -ItemType Directory -Path $HooksDirectory -Force | Out-Null
    }

    $sourceGuard = Join-Path $script:CodexHooksModuleDirectory $script:CodexPathConstant.HooksGuardAssetsRelativePath
    if (-not (Test-Path -LiteralPath $sourceGuard)) {
        # Fallback: write inline from shared helpers pattern (assets may live under adapters/codex/assets).
        $sourceGuard = Join-Path (Join-Path $script:CodexHooksModuleDirectory 'assets\hooks') $script:CodexPathConstant.HooksGuardScriptName
    }
    $destGuard = Join-Path $HooksDirectory $script:CodexPathConstant.HooksGuardScriptName
    if (Test-Path -LiteralPath $sourceGuard) {
        Copy-Item -LiteralPath $sourceGuard -Destination $destGuard -Force
    }
    else {
        throw ($script:CodexPublishMessage.HooksAssetsMissing -f $sourceGuard)
    }

    $sharedSource = Join-Path $RepoRoot $script:CodexPathConstant.SharedGuardCommonRelativePath
    if (Test-Path -LiteralPath $sharedSource) {
        $sharedDest = Join-Path $HooksDirectory $script:CodexPathConstant.SharedGuardCommonFileName
        Copy-Item -LiteralPath $sharedSource -Destination $sharedDest -Force
    }

    # Thin _hook-common for Codex (loads GuardCommon + Read/Write helpers).
    $commonSource = Join-Path (Split-Path -Parent $sourceGuard) '_hook-common.ps1'
    $destCommon = Join-Path $HooksDirectory '_hook-common.ps1'
    if (Test-Path -LiteralPath $commonSource) {
        Copy-Item -LiteralPath $commonSource -Destination $destCommon -Force
    }

    return $destGuard
}

function Write-CodexHooksJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksDirectory
    )

    if (-not (Test-Path -LiteralPath $HooksDirectory)) {
        New-Item -ItemType Directory -Path $HooksDirectory -Force | Out-Null
    }

    $hooksPath = Join-Path $HooksDirectory $script:CodexPathConstant.HooksFileName
    $payload = New-CodexPreToolUseHooksObject
    $json = ($payload | ConvertTo-Json -Depth 8)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($hooksPath, $json, $utf8NoBom)
    return $hooksPath
}

function Invoke-CodexPublishHooks {
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

    $repoRoot = Get-CodexHooksAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $pluginRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.PluginRootDirectoryName
    $hooksDirectory = Join-Path $pluginRoot $script:CodexPathConstant.HooksDirectoryName
    $hooksJsonPath = Join-Path $hooksDirectory $script:CodexPathConstant.HooksFileName

    $hooksCapable = $true
    if ($null -ne $script:CodexAdapterCapabilityFlags -and $script:CodexAdapterCapabilityFlags.Contains('hooks')) {
        $hooksCapable = [bool]$script:CodexAdapterCapabilityFlags['hooks']
    }

    if (-not $hooksCapable) {
        return [PSCustomObject]@{
            Success        = $true
            Implemented    = $true
            Skipped        = $true
            CommandName    = 'Publish-Hooks'
            WhatIf         = $WhatIf.IsPresent
            InstallRoot    = $resolvedInstallRoot
            PluginRoot     = $pluginRoot
            HooksPath      = $null
            HooksRelative  = $script:CodexPathConstant.HooksDefaultRelativePath
            HooksTrustNote = $script:CodexPathConstant.HooksTrustComment
            Message        = ($script:CodexPublishMessage.HooksSkippedNotCapable -f $pluginRoot)
            ExitCode       = 0
        }
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success        = $true
            Implemented    = $true
            Skipped        = $false
            CommandName    = 'Publish-Hooks'
            WhatIf         = $true
            InstallRoot    = $resolvedInstallRoot
            PluginRoot     = $pluginRoot
            HooksPath      = $hooksJsonPath
            HooksRelative  = $script:CodexPathConstant.HooksDefaultRelativePath
            HooksTrustNote = $script:CodexPathConstant.HooksTrustComment
            Message        = ($script:CodexPublishMessage.HooksWhatIfOk -f $hooksDirectory)
            ExitCode       = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $pluginRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.PluginRootDirectoryName
    $hooksDirectory = Join-Path $pluginRoot $script:CodexPathConstant.HooksDirectoryName
    $hooksJsonPath = Join-Path $hooksDirectory $script:CodexPathConstant.HooksFileName

    if (-not (Test-Path -LiteralPath $pluginRoot)) {
        New-Item -ItemType Directory -Path $pluginRoot -Force | Out-Null
    }

    $writtenHooks = Write-CodexHooksJson -HooksDirectory $hooksDirectory
    $guardPath = Write-CodexGuardPreToolScript -HooksDirectory $hooksDirectory -RepoRoot $repoRoot

    # Remove legacy SessionStart-only script if present (replaced by PreToolUse guard).
    $legacySession = Join-Path $hooksDirectory $script:CodexPathConstant.HooksSessionStartScriptName
    if (Test-Path -LiteralPath $legacySession) {
        Remove-Item -LiteralPath $legacySession -Force -ErrorAction SilentlyContinue
    }

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        Skipped          = $false
        CommandName      = 'Publish-Hooks'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        PluginRoot       = $pluginRoot
        HooksPath        = $writtenHooks
        GuardScriptPath  = $guardPath
        HooksRelative    = $script:CodexPathConstant.HooksDefaultRelativePath
        HooksTrustNote   = $script:CodexPathConstant.HooksTrustComment
        Message          = ($script:CodexPublishMessage.HooksPublishedOk -f $hooksDirectory)
        ExitCode         = 0
    }
}
