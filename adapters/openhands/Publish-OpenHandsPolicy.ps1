#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenHands Publish-Policy (fold core/policy into AGENTS.md; no rules/ tree).
#>

function Get-OpenHandsCorePolicyFileCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot
    )

    return @((Get-ChildItem -LiteralPath $SourcePolicyRoot -File -ErrorAction SilentlyContinue)).Count
}

function Invoke-OpenHandsPublishPolicy {
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
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:OpenHandsAdapterConstant.CoreDirectoryName) $script:OpenHandsAdapterConstant.PolicyDirectoryName
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:OpenHandsAdapterMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    $policyFileCount = Get-OpenHandsCorePolicyFileCount -SourcePolicyRoot $sourcePolicyRoot

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success            = $true
            Implemented        = $true
            CommandName        = 'Publish-Policy'
            WhatIf             = $true
            InstallRoot        = $resolvedInstallRoot
            AgentsMdPath       = $destinationAgentsMd
            SourceRoot         = $sourcePolicyRoot
            FilesCopied        = 0
            PolicyFileCount    = $policyFileCount
            PublishesCursorMdc = $false
            PublishesRulesTree = $false
            Message            = ($script:OpenHandsAdapterMessage.PolicyWhatIfOk -f $destinationAgentsMd)
            ExitCode           = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath
    $updated = Get-OpenHandsAgentsMdPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    Write-OpenHandsPublishedAgentsMarkdown -ResolvedInstallRoot $resolvedInstallRoot -DestinationAgentsMd $destinationAgentsMd -Content $updated

    return [PSCustomObject]@{
        Success            = $true
        Implemented        = $true
        CommandName        = 'Publish-Policy'
        WhatIf             = $false
        InstallRoot        = $resolvedInstallRoot
        AgentsMdPath       = $destinationAgentsMd
        SourceRoot         = $sourcePolicyRoot
        FilesCopied        = 1
        PolicyFileCount    = $policyFileCount
        PublishesCursorMdc = $false
        PublishesRulesTree = $false
        Message            = ($script:OpenHandsAdapterMessage.PolicyPublishedOk -f $policyFileCount, $destinationAgentsMd)
        ExitCode           = 0
    }
}
