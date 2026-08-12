#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Copilot Publish-Agents.

.DESCRIPTION
  Mode repo: copy core/agents -> InstallRoot/agents (.github/agents/).
  Mode user: documented no-op (no Copilot user-home agents directory).
#>

function Invoke-CopilotPublishAgents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [string] $Mode,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotPublishMessage.InstallRootRequired
    }

    $normalizedMode = Get-CopilotPublishNormalizedMode -Mode $Mode

    if ($normalizedMode -eq $script:CopilotPathConstant.ModeUser) {
        return [PSCustomObject]@{
            Success     = $true
            Implemented = $true
            CommandName = 'Publish-Agents'
            NoOp        = $true
            WhatIf      = [bool]$WhatIf.IsPresent
            Mode        = $normalizedMode
            InstallRoot = $InstallRoot.Trim()
            FilesCopied = 0
            Message     = $script:CopilotPublishMessage.AgentsUserModeNoOp
            ExitCode    = 0
        }
    }

    $repoRoot = Get-CopilotPublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    Initialize-CopilotToolkitManagedTreeLib

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CustomAgentsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceAgentsRoot)) {
        throw ($script:CopilotPublishMessage.CoreAgentsMissing -f $sourceAgentsRoot)
    }

    $agentFileCount = @(Get-ToolkitManagedAgentFileNames -SourceAgentsRoot $sourceAgentsRoot).Count

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Agents'
            WhatIf           = $true
            Mode             = $normalizedMode
            InstallRoot      = $resolvedInstallRoot
            SourceAgentsRoot = $sourceAgentsRoot
            DestAgentsRoot   = $destAgentsRoot
            AgentFileCount   = $agentFileCount
            Message          = ($script:CopilotPublishMessage.AgentsWhatIfOk -f $agentFileCount, $destAgentsRoot, $normalizedMode)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destAgentsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CustomAgentsDirectoryName
    $placeholderMap = Get-CopilotPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedAgentsPublish `
        -SourceAgentsRoot $sourceAgentsRoot `
        -DestinationAgentsRoot $destAgentsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:CopilotPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens @(
            $script:CopilotPathConstant.PlaceholderToolkitRoot,
            $script:CopilotPathConstant.PlaceholderSddRoot,
            $script:CopilotPathConstant.PlaceholderGuardrailsPath
        ) `
        -UnresolvedMessageFormat $script:CopilotPublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Agents'
        WhatIf           = $false
        Mode             = $normalizedMode
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsRoot = $sourceAgentsRoot
        DestAgentsRoot   = $destAgentsRoot
        AgentFileCount   = $publishResult.AgentFileCount
        Message          = ($script:CopilotPublishMessage.AgentsPublishedOk -f $publishResult.AgentFileCount, $destAgentsRoot, $normalizedMode)
        ExitCode         = 0
    }
}
