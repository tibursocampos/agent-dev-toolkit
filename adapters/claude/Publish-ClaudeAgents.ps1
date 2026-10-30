#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Claude Publish-Agents (copy core/agents -> InstallRoot/agents).
#>

$script:ClaudeAgentsModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeAgentsModuleDirectory)) {
    $script:ClaudeAgentsModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$_claudeSpawnKnobsPath = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:ClaudeAgentsModuleDirectory)
) 'adapters\_shared\SpawnPublishKnobs.ps1'
. $_claudeSpawnKnobsPath
Remove-Variable -Name _claudeSpawnKnobsPath -ErrorAction SilentlyContinue

function Add-ClaudeAgentDisallowedToolsFrontmatter {
    <#
    .SYNOPSIS
      Add `disallowedTools: Agent` after `model: inherit` in each published Claude agent so a child cannot spawn subagents.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentsRoot,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $modelLinePattern = '(?m)^model:[ \t]*inherit[ \t]*(\r?\n)'
    $disallowedLinePattern = '(?m)^disallowedTools:[ \t]*Agent[ \t]*\r?$'
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $changedPaths = New-Object System.Collections.Generic.List[string]
    foreach ($file in @(Get-ChildItem -LiteralPath $AgentsRoot -File -Filter '*.md')) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        if ($text -match $disallowedLinePattern) { continue }
        if ($text -notmatch $modelLinePattern) {
            throw ("Claude agent {0} has no 'model: inherit' frontmatter line; cannot add disallowedTools" -f $file.Name)
        }
        $updated = [regex]::Replace($text, $modelLinePattern, '$0disallowedTools: Agent$1', 1)
        [System.IO.File]::WriteAllText($file.FullName, $updated, $utf8NoBom)
        $changedPaths.Add([System.IO.Path]::GetFullPath($file.FullName)) | Out-Null
    }

    if ($changedPaths.Count -gt 0) {
        Enter-ToolkitFilesystemGate -RootPath $InstallRoot -LockFileName '.toolkit-managed-publish.lock'
        try {
            Update-ToolkitManagedCopyInventory -InstallRoot $InstallRoot -Paths @($changedPaths.ToArray())
        }
        finally {
            Exit-ToolkitFilesystemGate -RootPath $InstallRoot -LockFileName '.toolkit-managed-publish.lock'
        }
    }
}
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
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
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

    $null = Invoke-ClaudeManagedReferenceRewrite -ManagedPaths @($script:ToolkitLastManagedCopyPaths.ToArray()) -RepoRoot $repoRoot -PlaceholderMap $placeholderMap
    Add-ClaudeAgentDisallowedToolsFrontmatter -AgentsRoot $destAgentsRoot -InstallRoot $resolvedInstallRoot
    Assert-MarkdownAgentsSpawnKnobs -AgentsRoot $destAgentsRoot -Label 'claude-agents'

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
