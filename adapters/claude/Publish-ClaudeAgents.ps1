#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Claude Publish-Agents (copy core/agents -> InstallRoot/agents).
#>

function Invoke-ClaudePublishAgents {
    <#
    .SYNOPSIS
      Publish core/agents/*.md into InstallRoot/agents (Claude Code Agent targets).
    #>
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
        throw $script:ClaudePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ClaudeAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    Initialize-ClaudeToolkitManagedTreeLib

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.CustomAgentsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceAgentsRoot)) {
        throw ($script:ClaudePublishMessage.CoreAgentsMissing -f $sourceAgentsRoot)
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
            Message          = ($script:ClaudePublishMessage.AgentsWhatIfOk -f $agentFileCount, $destAgentsRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.CustomAgentsDirectoryName
    $placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedAgentsPublish `
        -SourceAgentsRoot $sourceAgentsRoot `
        -DestinationAgentsRoot $destAgentsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:ClaudePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ClaudeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ClaudePublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Agents'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsRoot = $sourceAgentsRoot
        DestAgentsRoot   = $destAgentsRoot
        AgentFileCount   = $publishResult.AgentFileCount
        Message          = ($script:ClaudePublishMessage.AgentsPublishedOk -f $publishResult.AgentFileCount, $destAgentsRoot)
        ExitCode         = 0
    }
}
