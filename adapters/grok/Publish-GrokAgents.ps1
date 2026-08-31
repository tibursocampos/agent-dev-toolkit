#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Grok Publish-Agents (copy core/agents -> InstallRoot/agents).
#>

function Invoke-GrokPublishAgents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-GrokAdapterRepoRoot
    Initialize-GrokInstallRootResolver
    Initialize-GrokToolkitManagedTreeLib

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:GrokAdapterConstant.CustomAgentsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceAgentsRoot)) {
        throw ($script:GrokAdapterMessage.CoreAgentsMissing -f $sourceAgentsRoot)
    }

    $agentFileCount = @(Get-ToolkitManagedAgentFileNames -SourceAgentsRoot $sourceAgentsRoot).Count

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Agents'
            WhatIf           = $true
            InstallRoot      = $resolvedInstallRoot
            SourceAgentsRoot = $sourceAgentsRoot
            DestAgentsRoot   = $destAgentsRoot
            AgentFileCount   = $agentFileCount
            Message          = ($script:GrokAdapterMessage.AgentsWhatIfOk -f $agentFileCount, $destAgentsRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:GrokAdapterConstant.CustomAgentsDirectoryName
    $placeholderMap = Get-GrokPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedAgentsPublish `
        -SourceAgentsRoot $sourceAgentsRoot `
        -DestinationAgentsRoot $destAgentsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:GrokAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens @(Get-GrokSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:GrokAdapterMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Agents'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsRoot = $sourceAgentsRoot
        DestAgentsRoot   = $destAgentsRoot
        AgentFileCount   = $publishResult.AgentFileCount
        Message          = ($script:GrokAdapterMessage.AgentsPublishedOk -f $publishResult.AgentFileCount, $destAgentsRoot)
        ExitCode         = 0
    }
}
