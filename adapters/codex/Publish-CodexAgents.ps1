#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Agents (copy core/agents -> InstallRoot/agents).

.DESCRIPTION
  Destination is InstallRoot/agents (live ~/.codex/agents/). Distinct from
  Codex USER skills root .agents/skills.
#>

function Invoke-CodexPublishAgents {
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
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-CodexPublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    Initialize-CodexToolkitManagedTreeLib

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.CustomAgentsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceAgentsRoot)) {
        throw ($script:CodexPublishMessage.CoreAgentsMissing -f $sourceAgentsRoot)
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
            Message          = ($script:CodexPublishMessage.AgentsWhatIfOk -f $agentFileCount, $destAgentsRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.CustomAgentsDirectoryName
    $homeSkillsRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.HomeSkillsRelativePath
    $placeholderMap = Get-CodexPlaceholderMap -InstallRoot $resolvedInstallRoot -PublishedSkillsRoot $homeSkillsRoot
    $publishResult = Invoke-ToolkitManagedAgentsPublish `
        -SourceAgentsRoot $sourceAgentsRoot `
        -DestinationAgentsRoot $destAgentsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:CodexPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CodexUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CodexPublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Agents'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsRoot = $sourceAgentsRoot
        DestAgentsRoot   = $destAgentsRoot
        AgentFileCount   = $publishResult.AgentFileCount
        Message          = ($script:CodexPublishMessage.AgentsPublishedOk -f $publishResult.AgentFileCount, $destAgentsRoot)
        ExitCode         = 0
    }
}
