#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Cursor Publish-Agents (copy core/agents -> InstallRoot/agents).
#>

function Invoke-CursorPublishAgents {
    <#
    .SYNOPSIS
      Publish core/agents/*.md into InstallRoot/agents (Cursor Task targets).
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
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-CursorAdapterRepoRoot
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot

    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    if (-not (Test-Path -LiteralPath $sourceAgentsRoot)) {
        throw ($script:CursorAdapterMessage.CoreAgentsMissing -f $sourceAgentsRoot)
    }

    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.CustomAgentsDirectoryName
    $agentFileCount = @(Get-ToolkitManagedAgentFileNames -SourceAgentsRoot $sourceAgentsRoot).Count

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Agents'
            InstallRoot      = $resolvedInstallRoot
            SourceAgentsRoot = $sourceAgentsRoot
            DestAgentsRoot   = $destAgentsRoot
            AgentFileCount   = $agentFileCount
            WhatIf           = $true
            Message          = ($script:CursorAdapterMessage.AgentsWouldPublish -f $agentFileCount, $destAgentsRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.CustomAgentsDirectoryName

    $placeholderMap = Get-CursorPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedAgentsPublish `
        -SourceAgentsRoot $sourceAgentsRoot `
        -DestinationAgentsRoot $destAgentsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:CursorAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CursorSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CursorAdapterMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Agents'
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsRoot = $sourceAgentsRoot
        DestAgentsRoot   = $destAgentsRoot
        AgentFileCount   = $publishResult.AgentFileCount
        WhatIf           = $false
        Message          = ($script:CursorAdapterMessage.AgentsPublished -f $publishResult.AgentFileCount, $destAgentsRoot)
        ExitCode         = 0
    }
}
