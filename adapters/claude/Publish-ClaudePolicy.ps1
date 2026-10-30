#Requires -Version 5.1
$script:ToolkitCopyHelperRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')

<#
.SYNOPSIS
  Helpers for Claude Publish-Policy (core/policy -> InstallRoot/rules).

.DESCRIPTION
  Mapping: core/policy/{name}.md -> <InstallRoot>/rules/{name}.md (keep .md; Claude does not require Cursor .mdc).
  Placeholders resolved after copy. Re-publish overwrites managed rule files; does not delete alien files.
#>

function ConvertTo-ClaudeRuleFrontmatterText {
    <#
    .SYNOPSIS
      Shape one rule's frontmatter for Claude: drop Cursor-only alwaysApply; map globs to paths.

    .DESCRIPTION
      Rules without globs load unconditionally in Claude, so only path-scoped rules keep a
      paths: key. Body text is untouched. Text without a leading frontmatter block is returned as-is.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $RuleText
    )

    $frontmatterMatch = [regex]::Match(
        $RuleText,
        '\A---\r?\n(?<frontmatter>.*?)\r?\n---[ \t]*(\r?\n|\z)',
        [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $frontmatterMatch.Success) {
        return $RuleText
    }

    $newline = if ($RuleText.Contains("`r`n")) { "`r`n" } else { "`n" }
    $kept = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @($frontmatterMatch.Groups['frontmatter'].Value -split '\r?\n')) {
        if ($line -match '^alwaysApply:') {
            continue
        }
        if ($line -match '^globs:(?<value>.*)$') {
            $kept.Add('paths:' + $Matches['value'])
            continue
        }
        $kept.Add($line)
    }

    $body = $RuleText.Substring($frontmatterMatch.Length)
    return ('---' + $newline + ($kept -join $newline) + $newline + '---' + $newline + $body)
}

function Convert-ClaudeRuleFrontmatterInFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $Files
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $changed = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $Files) {
        $text = [System.IO.File]::ReadAllText($file)
        $converted = ConvertTo-ClaudeRuleFrontmatterText -RuleText $text
        if ($converted -cne $text) {
            [System.IO.File]::WriteAllText($file, $converted, $utf8NoBom)
            $changed.Add([System.IO.Path]::GetFullPath($file)) | Out-Null
        }
    }

    return [string[]]$changed.ToArray()
}

function Copy-ClaudeCorePolicyTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationRulesRoot
    )

    if (-not (Test-Path -LiteralPath $DestinationRulesRoot)) {
        New-Item -ItemType Directory -Path $DestinationRulesRoot -Force | Out-Null
    }

    $filesCopied = 0
    $sourceFiles = Get-ChildItem -LiteralPath $SourcePolicyRoot -Recurse -File -Filter *.md
    foreach ($file in $sourceFiles) {
        if ($script:ClaudeUnpublishedPolicyFileNames -contains $file.Name) {
            continue
        }
        $relative = $file.FullName.Substring($SourcePolicyRoot.Length).TrimStart('\', '/')
        $destinationPath = Join-Path $DestinationRulesRoot $relative
        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        $null = Copy-ToolkitFileIfAbsent -SourcePath $file.FullName -DestinationPath $destinationPath
        $filesCopied++
    }

    return $filesCopied
}

function Invoke-ClaudePublishPolicy {
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
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:ClaudePathConstant.CoreDirectoryName) $script:ClaudePathConstant.PolicyDirectoryName
    $destinationRulesRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.RulesDirectoryName

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:ClaudePublishMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success     = $true
            Implemented = $true
            CommandName = 'Publish-Policy'
            WhatIf      = $true
            InstallRoot = $resolvedInstallRoot
            RulesRoot   = $destinationRulesRoot
            SourceRoot  = $sourcePolicyRoot
            FilesCopied = 0
            Message     = ($script:ClaudePublishMessage.PolicyWhatIfOk -f $destinationRulesRoot)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationRulesRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.RulesDirectoryName

    $filesCopied = Copy-ClaudeCorePolicyTree -SourcePolicyRoot $sourcePolicyRoot -DestinationRulesRoot $destinationRulesRoot
    $null = Convert-ClaudeRuleFrontmatterInFiles -Files @(Get-ChildItem -LiteralPath $destinationRulesRoot -Recurse -File -Filter *.md | ForEach-Object { $_.FullName })
    $placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-ClaudePlaceholdersInTree -RootPath $destinationRulesRoot -PlaceholderMap $placeholderMap
    $markdownRules = @(Get-ChildItem -LiteralPath $destinationRulesRoot -Recurse -File -Filter *.md | ForEach-Object { $_.FullName })
    $null = Convert-ClaudeMdcReferencesInFiles -Files $markdownRules
    Assert-ClaudePlaceholdersResolved -RootPath $destinationRulesRoot
    if ($markdownRules.Count -gt 0) {
        Enter-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
        try {
            Update-ToolkitManagedCopyInventory -InstallRoot $resolvedInstallRoot -Paths $markdownRules
        }
        finally {
            Exit-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
        }
    }

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Policy'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        RulesRoot   = $destinationRulesRoot
        SourceRoot  = $sourcePolicyRoot
        FilesCopied = $filesCopied
        Message     = ($script:ClaudePublishMessage.PolicyPublishedOk -f $filesCopied, $destinationRulesRoot)
        ExitCode    = 0
    }
}
