#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Hooks (plugin/hooks/hooks.json).

.DESCRIPTION
  Writes filesystem hooks only. RN03: never invoke or assert Codex /hooks trust UI.
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

function New-CodexMinimalHooksObject {
    [CmdletBinding()]
    param()

    return [ordered]@{
        description = $script:CodexPathConstant.HooksDescription
        hooks       = [ordered]@{
            ($script:CodexPathConstant.HooksSessionStartEventName) = @(
                [ordered]@{
                    hooks = @(
                        [ordered]@{
                            type          = $script:CodexPathConstant.HooksCommandType
                            command       = $script:CodexPathConstant.HooksSessionStartCommandTemplate
                            statusMessage = $script:CodexPathConstant.HooksSessionStartStatusMessage
                        }
                    )
                }
            )
        }
    }
}

function Write-CodexSessionStartHookScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksDirectory
    )

    $scriptPath = Join-Path $HooksDirectory $script:CodexPathConstant.HooksSessionStartScriptName
    $lines = @(
        '#Requires -Version 5.1'
        '# Codex plugin SessionStart hook - exit 0; no trust UI interaction.'
        '# ' + $script:CodexPathConstant.HooksTrustComment
        'exit 0'
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($scriptPath, ($lines -join [Environment]::NewLine) + [Environment]::NewLine, $utf8NoBom)
    return $scriptPath
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
    $payload = New-CodexMinimalHooksObject
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
            Success       = $true
            Implemented   = $true
            Skipped       = $true
            CommandName   = 'Publish-Hooks'
            WhatIf        = $WhatIf.IsPresent
            InstallRoot   = $resolvedInstallRoot
            PluginRoot    = $pluginRoot
            HooksPath     = $null
            HooksRelative = $script:CodexPathConstant.HooksDefaultRelativePath
            HooksTrustNote = $script:CodexPathConstant.HooksTrustComment
            Message       = ($script:CodexPublishMessage.HooksSkippedNotCapable -f $pluginRoot)
            ExitCode      = 0
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
    $sessionScript = Write-CodexSessionStartHookScript -HooksDirectory $hooksDirectory

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        Skipped          = $false
        CommandName      = 'Publish-Hooks'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        PluginRoot       = $pluginRoot
        HooksPath        = $writtenHooks
        SessionStartPath = $sessionScript
        HooksRelative    = $script:CodexPathConstant.HooksDefaultRelativePath
        HooksTrustNote   = $script:CodexPathConstant.HooksTrustComment
        Message          = ($script:CodexPublishMessage.HooksPublishedOk -f $hooksDirectory)
        ExitCode         = 0
    }
}
