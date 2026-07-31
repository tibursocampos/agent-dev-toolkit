#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Antigravity Publish-Router (core/router -> skills/dev_persona + managed markdown).

.DESCRIPTION
  Materializes InstallRoot/config/skills/dev_persona/SKILL.md from core/router/AGENTS.md.
  Resolves placeholders relative to InstallRoot. Strips forbidden underscore-mandate phrasing.
  Upserts the managed begin/end block into config/AGENTS.md and config/GEMINI.md without wiping
  user content outside the markers (kebab + official config/skills paths via skills.json).
#>

function New-AntigravityDevPersonaSkillContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RouterSourcePath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap,

        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $raw = [System.IO.File]::ReadAllText($RouterSourcePath)
    $sanitized = Remove-AntigravityForbiddenUnderscoreMandate -Text $raw
    $resolved = Resolve-AntigravityPlaceholdersInText -Text $sanitized -PlaceholderMap $PlaceholderMap

    $parts = @(
        $script:AntigravityPathConstant.DevPersonaSkillFrontmatter.TrimEnd(),
        $script:AntigravityPathConstant.DevPersonaSkillIntro.TrimEnd(),
        $resolved.TrimEnd()
    )
    $combined = ($parts -join ([Environment]::NewLine + [Environment]::NewLine)) + [Environment]::NewLine
    Assert-AntigravityPlaceholdersResolvedInText -Text $combined -TargetPath $TargetPath
    Assert-AntigravityForbiddenPhraseAbsent -Text $combined -TargetPath $TargetPath
    return $combined
}

function New-AntigravityManagedMarkdownBlock {
    [CmdletBinding()]
    param()

    $begin = $script:AntigravityPathConstant.ManagedBlockBeginMarker
    $end = $script:AntigravityPathConstant.ManagedBlockEndMarker
    $body = $script:AntigravityPathConstant.ManagedAgentsBlockBody.TrimEnd()
    return ($begin + [Environment]::NewLine + $body + [Environment]::NewLine + $end + [Environment]::NewLine)
}

function Update-AntigravityManagedMarkdownFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath,

        [Parameter(Mandatory = $true)]
        [string] $ManagedBlock
    )

    $existing = ''
    if (Test-Path -LiteralPath $TargetPath) {
        $existing = [System.IO.File]::ReadAllText($TargetPath)
    }

    $begin = $script:AntigravityPathConstant.ManagedBlockBeginMarker
    $end = $script:AntigravityPathConstant.ManagedBlockEndMarker
    $pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
    $blockTrimmed = $ManagedBlock.TrimEnd()

    $newContent = $null
    if ($existing -match $pattern) {
        $newContent = [regex]::Replace($existing, $pattern, $blockTrimmed)
        if (-not $newContent.EndsWith("`n")) {
            $newContent += "`n"
        }
    }
    elseif ([string]::IsNullOrWhiteSpace($existing)) {
        $newContent = $ManagedBlock
        if (-not $newContent.EndsWith("`n")) {
            $newContent += "`n"
        }
    }
    else {
        $trimmed = $existing.TrimEnd()
        $newContent = $trimmed + "`n`n" + $ManagedBlock
        if (-not $newContent.EndsWith("`n")) {
            $newContent += "`n"
        }
    }

    $destDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($TargetPath, $newContent, $utf8NoBom)

    return [PSCustomObject]@{
        TargetPath       = $TargetPath
        ManagedBlockBegin = $begin
        ManagedBlockEnd   = $end
        ContentLength    = $newContent.Length
    }
}

function Invoke-AntigravityPublishRouter {
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
        throw $script:AntigravityPublishMessage.InstallRootRequired
    }

    $repoRoot = Get-AntigravityAdapterRepoRoot
    $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:AntigravityPathConstant.CoreDirectoryName) $script:AntigravityPathConstant.RouterDirectoryName
    ) $script:AntigravityPathConstant.RouterSourceFileName

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $destinationSkillDir = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialDevPersonaRelativePath -replace '/', $sep)
    $destinationSkillPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialDevPersonaSkillRelativePath -replace '/', $sep)
    $agentsMdPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialAgentsMdRelativePath -replace '/', $sep)
    $geminiMdPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialGeminiMdRelativePath -replace '/', $sep)

    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:AntigravityPublishMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success              = $true
            Implemented          = $true
            CommandName          = 'Publish-Router'
            WhatIf               = $true
            InstallRoot          = $resolvedInstallRoot
            DevPersonaPath       = $destinationSkillPath
            DevPersonaSkillDir   = $destinationSkillDir
            AgentsMdPath         = $agentsMdPath
            GeminiMdPath         = $geminiMdPath
            ManagedBlockBegin    = $script:AntigravityPathConstant.ManagedBlockBeginMarker
            ManagedBlockEnd      = $script:AntigravityPathConstant.ManagedBlockEndMarker
            SourceRoot           = $sourceRouterFile
            FilesCopied          = 0
            ManagedFilesUpserted = 0
            Message              = ($script:AntigravityPublishMessage.RouterWhatIfOk -f $destinationSkillPath)
            ExitCode             = 0
        }
    }

    $resolvedInstallRoot = Initialize-AntigravityInstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $destinationSkillDir = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialDevPersonaRelativePath -replace '/', $sep)
    $destinationSkillPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialDevPersonaSkillRelativePath -replace '/', $sep)
    $agentsMdPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialAgentsMdRelativePath -replace '/', $sep)
    $geminiMdPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialGeminiMdRelativePath -replace '/', $sep)

    $placeholderMap = Get-AntigravityPlaceholderMap -InstallRoot $resolvedInstallRoot
    $content = New-AntigravityDevPersonaSkillContent -RouterSourcePath $sourceRouterFile -PlaceholderMap $placeholderMap -TargetPath $destinationSkillPath

    if (-not (Test-Path -LiteralPath $destinationSkillDir)) {
        New-Item -ItemType Directory -Path $destinationSkillDir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationSkillPath, $content, $utf8NoBom)

    $managedBlock = New-AntigravityManagedMarkdownBlock
    Assert-AntigravityForbiddenPhraseAbsent -Text $managedBlock -TargetPath $agentsMdPath

    $agentsResult = Update-AntigravityManagedMarkdownFile -TargetPath $agentsMdPath -ManagedBlock $managedBlock
    $geminiResult = Update-AntigravityManagedMarkdownFile -TargetPath $geminiMdPath -ManagedBlock $managedBlock

    return [PSCustomObject]@{
        Success              = $true
        Implemented          = $true
        CommandName          = 'Publish-Router'
        WhatIf               = $false
        InstallRoot          = $resolvedInstallRoot
        DevPersonaPath       = $destinationSkillPath
        DevPersonaSkillDir   = $destinationSkillDir
        AgentsMdPath         = $agentsResult.TargetPath
        GeminiMdPath         = $geminiResult.TargetPath
        ManagedBlockBegin    = $script:AntigravityPathConstant.ManagedBlockBeginMarker
        ManagedBlockEnd      = $script:AntigravityPathConstant.ManagedBlockEndMarker
        SourceRoot           = $sourceRouterFile
        FilesCopied          = 1
        ManagedFilesUpserted = 2
        Message              = ($script:AntigravityPublishMessage.RouterPublishedOk -f $destinationSkillPath)
        ExitCode             = 0
    }
}
