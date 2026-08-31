#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Agents (core/agents/*.md -> InstallRoot/agents/*.toml).

.DESCRIPTION
  Emits Codex custom agent TOML (name, description, developer_instructions)
  from roster markdown under core/agents/. Destination is InstallRoot/agents
  (live ~/.codex/agents/). Distinct from Codex USER skills root .agents/skills.
#>

function ConvertTo-CodexTomlSingleQuotedString {
    param([Parameter(Mandatory = $true)][string] $Value)
    # TOML single-quoted: only escape single quotes by doubling.
    return ("'{0}'" -f ($Value -replace "'", "''"))
}

function ConvertTo-CodexTomlMultilineBasicString {
    param([Parameter(Mandatory = $true)][string] $Value)
    # Prefer """ ... """; escape backslash and triple-quote edge cases lightly.
    $escaped = $Value -replace '\\', '\\'
    $escaped = $escaped -replace '"""', '\"""'
    return ('"""{0}{1}{0}"""' -f [Environment]::NewLine, $escaped.TrimEnd())
}

function Get-CodexAgentFrontmatterFields {
    param([Parameter(Mandatory = $true)][string] $MarkdownText)

    $name = ''
    $description = ''
    $body = $MarkdownText

    if ($MarkdownText -match '(?s)\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\z') {
        $fm = $Matches[1]
        $body = $Matches[2]
        if ($fm -match '(?m)^name:\s*(.+)$') {
            $name = $Matches[1].Trim().Trim('"').Trim("'")
        }
        if ($fm -match '(?m)^description:\s*(.+)$') {
            $description = $Matches[1].Trim().Trim('"').Trim("'")
        }
    }

    return [PSCustomObject]@{
        Name        = $name
        Description = $description
        Body        = $body.Trim()
    }
}

function Convert-CodexAgentMarkdownToToml {
    param(
        [Parameter(Mandatory = $true)][string] $MarkdownText,
        [Parameter(Mandatory = $true)][string] $SourcePath
    )

    $fields = Get-CodexAgentFrontmatterFields -MarkdownText $MarkdownText
    if ([string]::IsNullOrWhiteSpace($fields.Name) -or [string]::IsNullOrWhiteSpace($fields.Description)) {
        throw ($script:CodexPublishMessage.AgentsFrontmatterMissing -f $SourcePath)
    }

    $lines = @(
        ('name = {0}' -f (ConvertTo-CodexTomlSingleQuotedString -Value $fields.Name))
        ('description = {0}' -f (ConvertTo-CodexTomlSingleQuotedString -Value $fields.Description))
        ('developer_instructions = {0}' -f (ConvertTo-CodexTomlMultilineBasicString -Value $fields.Body))
    )
    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

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

    $sourceFiles = @(
        Get-ChildItem -LiteralPath $sourceAgentsRoot -File -ErrorAction Stop |
            Where-Object { $_.Extension -eq '.md' }
    )
    $agentFileCount = $sourceFiles.Count

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

    if (-not (Test-Path -LiteralPath $destAgentsRoot)) {
        New-Item -ItemType Directory -Path $destAgentsRoot -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $published = 0
    foreach ($mdFile in $sourceFiles) {
        $raw = [System.IO.File]::ReadAllText($mdFile.FullName)
        foreach ($key in @($placeholderMap.Keys)) {
            $raw = $raw.Replace([string]$key, [string]$placeholderMap[$key])
        }
        $toml = Convert-CodexAgentMarkdownToToml -MarkdownText $raw -SourcePath $mdFile.FullName
        $destName = [System.IO.Path]::ChangeExtension($mdFile.Name, $script:CodexPathConstant.CustomAgentTomlExtension)
        $destPath = Join-Path $destAgentsRoot $destName
        [System.IO.File]::WriteAllText($destPath, $toml, $utf8NoBom)
        $published++

        # Drop stale .md copy if a prior publish left one.
        $staleMd = Join-Path $destAgentsRoot $mdFile.Name
        if (Test-Path -LiteralPath $staleMd) {
            Remove-Item -LiteralPath $staleMd -Force -ErrorAction SilentlyContinue
        }
    }

    foreach ($token in (Get-CodexUnresolvedPlaceholderTokens)) {
        $hits = Get-ChildItem -LiteralPath $destAgentsRoot -Filter '*.toml' -File -ErrorAction SilentlyContinue |
            Where-Object { [System.IO.File]::ReadAllText($_.FullName).Contains($token) }
        if (@($hits).Count -gt 0) {
            throw ($script:CodexPublishMessage.PlaceholderUnresolved -f $token, $destAgentsRoot)
        }
    }

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Agents'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsRoot = $sourceAgentsRoot
        DestAgentsRoot   = $destAgentsRoot
        AgentFileCount   = $published
        Message          = ($script:CodexPublishMessage.AgentsPublishedOk -f $published, $destAgentsRoot)
        ExitCode         = 0
    }
}
