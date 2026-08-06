#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Grok Publish-Hooks (native JSON under InstallRoot/hooks).
#>

function New-GrokMinimalHooksObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SessionStartScriptPath
    )

    $command = ($script:GrokAdapterConstant.HooksSessionStartCommandTemplate -f $SessionStartScriptPath)

    return [ordered]@{
        description = $script:GrokAdapterConstant.HooksDescription
        hooks       = [ordered]@{
            ($script:GrokAdapterConstant.HooksSessionStartEventName) = @(
                [ordered]@{
                    hooks = @(
                        [ordered]@{
                            type    = $script:GrokAdapterConstant.HooksCommandType
                            command = $command
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
    $normalizedScriptPath = Get-GrokNormalizedForwardSlashPath -Path $sessionScriptPath
    $hooksPath = Join-Path $HooksDirectory $script:GrokAdapterConstant.HooksJsonFileName
    $payload = New-GrokMinimalHooksObject -SessionStartScriptPath $normalizedScriptPath
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
    $hooksJsonPath = Join-Path $hooksDirectory $script:GrokAdapterConstant.HooksJsonFileName

    $writtenSession = Write-GrokSessionStartHookScript -HooksDirectory $hooksDirectory
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
        HooksRelative    = $script:GrokAdapterConstant.OfficialHooksRelativePath
        HooksTrustNote   = $hooksTrustNote
        Message          = ($script:GrokAdapterMessage.HooksPublishedOk -f $hooksDirectory)
        ExitCode         = 0
    }
}

