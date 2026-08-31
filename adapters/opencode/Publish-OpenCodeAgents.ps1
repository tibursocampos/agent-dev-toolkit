#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenCode Publish-Agents (copy core/agents -> InstallRoot/agents).
#>

function Invoke-OpenCodePublishAgents {
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
        throw $script:OpenCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenCodeAdapterRepoRoot
    Initialize-OpenCodeInstallRootResolver
    if (-not (Get-Command -Name Invoke-ToolkitManagedAgentsPublish -ErrorAction SilentlyContinue)) {
        $libDir = Join-Path $repoRoot 'scripts\_lib'
        . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    }

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.CustomAgentsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceAgentsRoot)) {
        throw ($script:OpenCodePublishMessage.CoreAgentsMissing -f $sourceAgentsRoot)
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
            Message          = ($script:OpenCodePublishMessage.AgentsWhatIfOk -f $agentFileCount, $destAgentsRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.CustomAgentsDirectoryName

    $toolkitRoot = ($resolvedInstallRoot -replace '\\', '/')
    $sddRoot = ((Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.SddDirectoryName) -replace '\\', '/')
    $guardrailsPath = ((Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.AgentsFileName) -replace '\\', '/')
    $placeholderMap = [ordered]@{
        ($script:OpenCodePathConstant.PlaceholderToolkitRoot)     = $toolkitRoot
        ($script:OpenCodePathConstant.PlaceholderSddRoot)         = $sddRoot
        ($script:OpenCodePathConstant.PlaceholderGuardrailsPath)  = $guardrailsPath
    }

    $publishResult = Invoke-ToolkitManagedAgentsPublish `
        -SourceAgentsRoot $sourceAgentsRoot `
        -DestinationAgentsRoot $destAgentsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:OpenCodePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens @(
            $script:OpenCodePathConstant.PlaceholderToolkitRoot,
            $script:OpenCodePathConstant.PlaceholderSddRoot,
            $script:OpenCodePathConstant.PlaceholderGuardrailsPath
        ) `
        -UnresolvedMessageFormat $script:OpenCodePublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Agents'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsRoot = $sourceAgentsRoot
        DestAgentsRoot   = $destAgentsRoot
        AgentFileCount   = $publishResult.AgentFileCount
        Message          = ($script:OpenCodePublishMessage.AgentsPublishedOk -f $publishResult.AgentFileCount, $destAgentsRoot)
        ExitCode         = 0
    }
}
