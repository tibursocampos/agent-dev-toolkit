#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Grok Publish-Hooks (native JSON under InstallRoot/hooks).
#>

$script:GrokHooksModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:GrokHooksModuleDirectory)) {
    $script:GrokHooksModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-GrokHooksAssetsDirectory {
    [CmdletBinding()]
    param()

    return (Join-Path (
            Join-Path $script:GrokHooksModuleDirectory $script:GrokAdapterConstant.AssetsDirectoryName
        ) $script:GrokAdapterConstant.AssetsHooksDirectoryName)
}

function New-GrokMinimalHooksObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SessionStartScriptPath,

        [Parameter(Mandatory = $true)]
        [string] $GuardPreToolScriptPath
    )

    $sessionCommand = ($script:GrokAdapterConstant.HooksSessionStartCommandTemplate -f $SessionStartScriptPath)
    $guardCommand = ($script:GrokAdapterConstant.HooksSessionStartCommandTemplate -f $GuardPreToolScriptPath)

    return [ordered]@{
        description = $script:GrokAdapterConstant.HooksDescription
        hooks       = [ordered]@{
            ($script:GrokAdapterConstant.HooksSessionStartEventName) = @(
                [ordered]@{
                    hooks = @(
                        [ordered]@{
                            type    = $script:GrokAdapterConstant.HooksCommandType
                            command = $sessionCommand
                        }
                    )
                }
            )
            ($script:GrokAdapterConstant.HooksPreToolUseEventName) = @(
                [ordered]@{
                    matcher = $script:GrokAdapterConstant.HooksPreToolUseMatcher
                    hooks   = @(
                        [ordered]@{
                            type    = $script:GrokAdapterConstant.HooksCommandType
                            command = $guardCommand
                        }
                    )
                }
            )
        }
    }
}

function Write-GrokSessionStartHookScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksDirectory
    )

    if (-not (Test-Path -LiteralPath $HooksDirectory)) {
        New-Item -ItemType Directory -Path $HooksDirectory -Force | Out-Null
    }

    $scriptPath = Join-Path $HooksDirectory $script:GrokAdapterConstant.HooksSessionStartScriptName
    $lines = @(
        '#Requires -Version 5.1'
        '# Grok Build SessionStart hook - exit 0; no trust UI interaction.'
        '# ' + $script:GrokAdapterConstant.HooksTrustNote
        'exit 0'
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($scriptPath, ($lines -join [Environment]::NewLine) + [Environment]::NewLine, $utf8NoBom)
    return $scriptPath
}

function Copy-GrokGuardHookAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksDirectory,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        $repoRoot = Get-GrokAdapterRepoRoot
        . (Join-Path (Join-Path $repoRoot 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1')
    }

    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $HooksDirectory -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $HooksDirectory)) {
        New-Item -ItemType Directory -Path $HooksDirectory -Force | Out-Null
    }

    $assetsDir = Get-GrokHooksAssetsDirectory
    $sourceGuard = Join-Path $assetsDir $script:GrokAdapterConstant.HooksGuardPreToolScriptName
    if (-not (Test-Path -LiteralPath $sourceGuard)) {
        throw ($script:GrokAdapterMessage.HooksAssetsMissing -f $sourceGuard)
    }

    $destGuard = Join-Path $HooksDirectory $script:GrokAdapterConstant.HooksGuardPreToolScriptName
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destGuard `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    Copy-Item -LiteralPath $sourceGuard -Destination $destGuard -Force

    $repoRoot = Get-GrokAdapterRepoRoot
    $sourceCommon = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') '_shared') $script:GrokAdapterConstant.SharedGuardCommonFileName
    if (-not (Test-Path -LiteralPath $sourceCommon)) {
        throw ($script:GrokAdapterMessage.HooksAssetsMissing -f $sourceCommon)
    }
    $destCommon = Join-Path $HooksDirectory $script:GrokAdapterConstant.SharedGuardCommonFileName
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destCommon `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    Copy-Item -LiteralPath $sourceCommon -Destination $destCommon -Force

    return $destGuard
}

function Write-GrokHooksJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksDirectory
    )

    if (-not (Test-Path -LiteralPath $HooksDirectory)) {
        New-Item -ItemType Directory -Path $HooksDirectory -Force | Out-Null
    }

    $sessionScriptPath = Join-Path $HooksDirectory $script:GrokAdapterConstant.HooksSessionStartScriptName
    $guardScriptPath = Join-Path $HooksDirectory $script:GrokAdapterConstant.HooksGuardPreToolScriptName
    $normalizedSession = Get-GrokNormalizedForwardSlashPath -Path $sessionScriptPath
    $normalizedGuard = Get-GrokNormalizedForwardSlashPath -Path $guardScriptPath
    $hooksPath = Join-Path $HooksDirectory $script:GrokAdapterConstant.HooksJsonFileName
    $payload = New-GrokMinimalHooksObject -SessionStartScriptPath $normalizedSession -GuardPreToolScriptPath $normalizedGuard
    $json = ($payload | ConvertTo-Json -Depth $script:GrokAdapterConstant.JsonConvertDepthDeep)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($hooksPath, $json, $utf8NoBom)
    return $hooksPath
}

function Invoke-GrokPublishHooks {
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $hooksDirectory = $mapped.FixtureHooksPath
    $hooksJsonPath = Join-Path $hooksDirectory $script:GrokAdapterConstant.HooksJsonFileName
    $hooksTrustNote = $script:GrokAdapterConstant.HooksTrustNote

    $hooksCapable = $true
    if ($null -ne $script:GrokAdapterCapabilityFlags -and $script:GrokAdapterCapabilityFlags.Contains('hooks')) {
        $hooksCapable = [bool]$script:GrokAdapterCapabilityFlags['hooks']
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
            HooksRelative  = $script:GrokAdapterConstant.OfficialHooksRelativePath
            HooksTrustNote = $hooksTrustNote
            Message        = ($script:GrokAdapterMessage.HooksSkippedNotCapable -f $hooksDirectory)
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
            HooksRoot      = $hooksDirectory
            HooksPath      = $hooksJsonPath
            HooksRelative  = $script:GrokAdapterConstant.OfficialHooksRelativePath
            HooksTrustNote = $hooksTrustNote
            Message        = ($script:GrokAdapterMessage.HooksWhatIfOk -f $hooksDirectory)
            ExitCode       = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $hooksDirectory = $mapped.FixtureHooksPath

    $writtenSession = Write-GrokSessionStartHookScript -HooksDirectory $hooksDirectory
    $writtenGuard = Copy-GrokGuardHookAssets -HooksDirectory $hooksDirectory -InstallRoot $resolvedInstallRoot
    $writtenHooks = Write-GrokHooksJson -HooksDirectory $hooksDirectory

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
        GuardPreToolPath = $writtenGuard
        HooksRelative    = $script:GrokAdapterConstant.OfficialHooksRelativePath
        HooksTrustNote   = $hooksTrustNote
        Message          = ($script:GrokAdapterMessage.HooksPublishedOk -f $hooksDirectory)
        ExitCode         = 0
    }
}
