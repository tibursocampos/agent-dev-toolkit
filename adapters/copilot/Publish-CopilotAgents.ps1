#Requires -Version 5.1
$script:ToolkitCopyHelperRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')

<#
.SYNOPSIS
  Helpers for Copilot Publish-Agents.

.DESCRIPTION
  Publish core/agents as one nome.agent.md profile per agent.
  Copilot CLI and VS Code both discover that suffix.
#>

$script:CopilotAgentsModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CopilotAgentsModuleDirectory)) {
    $script:CopilotAgentsModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$_copilotSpawnKnobsPath = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CopilotAgentsModuleDirectory)
) 'adapters\_shared\SpawnPublishKnobs.ps1'
. $_copilotSpawnKnobsPath
Remove-Variable -Name _copilotSpawnKnobsPath -ErrorAction SilentlyContinue

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

    $repoRoot = Get-CopilotPublishAdapterRepoRoot
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
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
    Enter-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
    try {
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

    # Copilot CLI and VS Code discover nome.agent.md. Drop the parallel nome.md this copy just wrote.
    foreach ($sourceName in $publishResult.AgentFileNames) {
        $legacyPath = Join-Path $destAgentsRoot $sourceName
        $agentName = [System.IO.Path]::GetFileNameWithoutExtension($sourceName)
        $profilePath = Join-Path $destAgentsRoot ($agentName + '.agent.md')
        if (-not (Test-Path -LiteralPath $legacyPath -PathType Leaf)) {
            throw ("Copilot Publish-Agents: expected copied profile missing: {0}" -f $legacyPath)
        }

        $profileText = [System.IO.File]::ReadAllText($legacyPath)
        if ($agentName -in @('architect', 'database', 'repo-analyst', 'security') -and
            $profileText -match '(?m)^---\s*$') {
            $firstFence = [regex]::Match($profileText, '(?m)^---\s*$')
            $secondFence = [regex]::Match($profileText, '(?m)^---\s*$', $firstFence.Index + $firstFence.Length)
            if ($secondFence.Success) {
                $frontmatter = $profileText.Substring($firstFence.Index, $secondFence.Index - $firstFence.Index)
                if ($frontmatter -notmatch '(?m)^include-custom-instructions\s*:') {
                    $frontmatterStart = $firstFence.Index + $firstFence.Length
                    if ($profileText.Substring($frontmatterStart).StartsWith("`r`n", [System.StringComparison]::Ordinal)) {
                        $frontmatterStart += 2
                    }
                    elseif ($profileText.Substring($frontmatterStart).StartsWith("`n", [System.StringComparison]::Ordinal)) {
                        $frontmatterStart += 1
                    }
                    $profileText = $profileText.Insert($frontmatterStart, "include-custom-instructions: true`r`n")
                }
            }
        }

        $null = Write-ToolkitFileIfAbsent `
            -Path $profilePath `
            -Content $profileText `
            -Encoding (New-Object System.Text.UTF8Encoding $false) `
            -InstallRoot $resolvedInstallRoot `
            -RelativePath ('{0}/{1}' -f $script:CopilotPathConstant.CustomAgentsDirectoryName, ($agentName + $script:CopilotPathConstant.CustomAgentProfileExtension))
        # The managed copy emits nome.md. This publish owns that file and keeps only nome.agent.md.
        $legacyFinal = Assert-PathUnderInstallRootForDelete -CandidatePath $legacyPath -InstallRoot $resolvedInstallRoot
        [System.IO.File]::Delete($legacyFinal)
    }

        Assert-MarkdownAgentsSpawnKnobs -AgentsRoot $destAgentsRoot -Label 'copilot-agents'

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
    finally {
        Exit-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
    }
    }
    finally {
        Exit-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
    }
}
