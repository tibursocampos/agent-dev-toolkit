#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Hermes Publish-Router (core/router/AGENTS.md + folded policy -> InstallRoot/AGENTS.md).
#>

function Invoke-HermesPublishRouter {
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-HermesAdapterRepoRoot
    Initialize-HermesInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.RouterDirectoryName
    ) $script:HermesAdapterConstant.RouterSourceFileName
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath

    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:HermesAdapterMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Router'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            AgentsMdPath = $destinationAgentsMd
            SourceRoot   = $sourceRouterFile
            FilesCopied  = 0
            Message      = ($script:HermesAdapterMessage.RouterWhatIfOk -f $destinationAgentsMd)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath
    $null = Write-HermesManagedAgentsMd -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome

    return [PSCustomObject]@{
        Success      = $true
        Implemented  = $true
        CommandName  = 'Publish-Router'
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        AgentsMdPath = $destinationAgentsMd
        SourceRoot   = $sourceRouterFile
        FilesCopied  = 1
        Message      = ($script:HermesAdapterMessage.RouterPublishedOk -f $destinationAgentsMd)
        ExitCode     = 0
    }
}
