#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Claude Publish-Router (core/router -> InstallRoot/CLAUDE.md).

.DESCRIPTION
  Mapping: core/router/AGENTS.md -> <InstallRoot>/CLAUDE.md (neutral core router; not Athena).
  After placeholder resolve, rewrite rules/*.mdc path refs to *.md to match Publish-Policy layout.
  Re-publish overwrites CLAUDE.md; does not wipe unrelated InstallRoot files.
#>

function Convert-ClaudeRouterMdcReferencesToMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $mdcExtension = $script:ClaudePathConstant.CursorRuleExtension
    $mdExtension = $script:ClaudePathConstant.MarkdownExtension
    if ([string]::IsNullOrEmpty($mdcExtension) -or [string]::IsNullOrEmpty($mdExtension)) {
        return $Text
    }

    return $Text.Replace($mdcExtension, $mdExtension)
}

function Invoke-ClaudePublishRouter {
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
        throw $script:ClaudePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ClaudeAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:ClaudePathConstant.CoreDirectoryName) $script:ClaudePathConstant.RouterDirectoryName
    ) $script:ClaudePathConstant.RouterSourceFileName
    $destinationClaudeMd = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.ClaudeMdFileName

    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:ClaudePublishMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Router'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            ClaudeMdPath = $destinationClaudeMd
            SourceRoot   = $sourceRouterFile
            FilesCopied  = 0
            Message      = ($script:ClaudePublishMessage.RouterWhatIfOk -f $destinationClaudeMd)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationClaudeMd = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.ClaudeMdFileName

    $raw = [System.IO.File]::ReadAllText($sourceRouterFile)
    $placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $resolvedInstallRoot
    $updated = $raw
    foreach ($key in $placeholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$placeholderMap[$key])
        }
    }

    $updated = Convert-ClaudeRouterMdcReferencesToMd -Text $updated

    foreach ($placeholder in @(
            $script:ClaudePathConstant.PlaceholderToolkitRoot,
            $script:ClaudePathConstant.PlaceholderSddRoot,
            $script:ClaudePathConstant.PlaceholderGuardrailsPath
        )) {
        if ($updated.Contains($placeholder)) {
            throw ($script:ClaudePublishMessage.PlaceholderUnresolved -f $placeholder, $destinationClaudeMd)
        }
    }

    $destinationDir = Split-Path -Parent $destinationClaudeMd
    if (-not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationClaudeMd, $updated, $utf8NoBom)

    return [PSCustomObject]@{
        Success      = $true
        Implemented  = $true
        CommandName  = 'Publish-Router'
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        ClaudeMdPath = $destinationClaudeMd
        SourceRoot   = $sourceRouterFile
        FilesCopied  = 1
        Message      = ($script:ClaudePublishMessage.RouterPublishedOk -f $destinationClaudeMd)
        ExitCode     = 0
    }
}
