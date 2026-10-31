#Requires -Version 5.1
$script:ToolkitCopyHelperRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')
. (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'adapters') '_shared\PublishAuthorizationContract.ps1')

<#
.SYNOPSIS
  Helpers for Codex Publish-Hooks (plugin/hooks/hooks.json + emit-trace.ps1).

.DESCRIPTION
  Writes one SubagentStop trace hook (emit-trace.ps1). No PreToolUse guard is registered.
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

function New-CodexSubagentStopHooksObject {
    [CmdletBinding()]
    param()

    $c = $script:CodexPathConstant
    return [ordered]@{
        description = $c.HooksDescription
        hooks       = [ordered]@{
            ($c.HooksSubagentStopEventName) = @(
                [ordered]@{
                    hooks = @(
                        [ordered]@{
                            type          = $c.HooksCommandType
                            command       = $c.HooksSubagentStopCommandTemplate
                            statusMessage = $c.HooksSubagentStopStatusMessage
                        }
                    )
                }
            )
        }
    }
}

function Write-CodexTraceEmitScripts {
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

    $sourceEmit = Join-Path $script:CodexHooksModuleDirectory ($script:CodexPathConstant.HooksTraceEmitAssetsRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $sourceEmit -PathType Leaf)) {
        throw ($script:CodexPublishMessage.HooksAssetsMissing -f $sourceEmit)
    }
    $destEmit = Join-Path $HooksDirectory $script:CodexPathConstant.HooksTraceEmitScriptName
    $null = Copy-ToolkitFileIfAbsent -SourcePath $sourceEmit -DestinationPath $destEmit

    $commonSource = Join-Path $RepoRoot ($script:CodexPathConstant.SharedTraceEmitCommonRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $commonSource -PathType Leaf)) {
        throw ($script:CodexPublishMessage.HooksAssetsMissing -f $commonSource)
    }
    $destCommon = Join-Path $HooksDirectory $script:CodexPathConstant.TraceEmitCommonFileName
    $null = Copy-ToolkitFileIfAbsent -SourcePath $commonSource -DestinationPath $destCommon

    $sourceHooksCommon = Join-Path (Join-Path (Join-Path $script:CodexHooksModuleDirectory 'assets') 'hooks') $script:CodexPathConstant.HooksCommonFileName
    if (-not (Test-Path -LiteralPath $sourceHooksCommon -PathType Leaf)) {
        throw ($script:CodexPublishMessage.HooksAssetsMissing -f $sourceHooksCommon)
    }
    $destHooksCommon = Join-Path $HooksDirectory $script:CodexPathConstant.HooksCommonFileName
    $null = Copy-ToolkitFileIfAbsent -SourcePath $sourceHooksCommon -DestinationPath $destHooksCommon

    return $destEmit
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
    $payload = New-CodexSubagentStopHooksObject
    $json = ($payload | ConvertTo-Json -Depth 8)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $null = Write-ToolkitFileIfAbsent -Path $hooksPath -Content $json -Encoding $utf8NoBom
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
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
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
            HookActivation = New-HookActivation -State 'unavailable' -Note 'Hook capability is disabled; no hook files were written.'
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
            HookActivation = New-HookActivation -State 'manual' -Steps @($script:CodexPathConstant.HooksActivationStep) -Note $script:CodexPathConstant.HooksActivationNote
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
    $traceEmitPath = Write-CodexTraceEmitScripts -HooksDirectory $hooksDirectory -RepoRoot $repoRoot

    # Preserve the legacy SessionStart-only script; no ownership marker proves it belongs to this toolkit.
    $legacySession = Join-Path $hooksDirectory $script:CodexPathConstant.HooksSessionStartScriptName
    if (Test-Path -LiteralPath $legacySession) {
        Write-Warning ("Preserved legacy hook file because ownership is not proven: {0}" -f $legacySession)
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
        TraceEmitScriptPath = $traceEmitPath
        HooksRelative    = $script:CodexPathConstant.HooksDefaultRelativePath
        HooksTrustNote   = $script:CodexPathConstant.HooksTrustComment
        Message          = ($script:CodexPublishMessage.HooksPublishedOk -f $hooksDirectory)
        HookActivation   = New-HookActivation -State 'manual' -Steps @($script:CodexPathConstant.HooksActivationStep) -Note $script:CodexPathConstant.HooksActivationNote
        ExitCode         = 0
    }
}
