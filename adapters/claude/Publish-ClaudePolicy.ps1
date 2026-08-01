#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Claude Publish-Policy (core/policy -> InstallRoot/rules).

.DESCRIPTION
  Mapping: core/policy/{name}.md -> <InstallRoot>/rules/{name}.md (keep .md; Claude does not require Cursor .mdc).
  Placeholders resolved after copy. Re-publish overwrites managed rule files; does not delete alien files.
#>

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
    $sourceFiles = Get-ChildItem -LiteralPath $SourcePolicyRoot -Recurse -File
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($SourcePolicyRoot.Length).TrimStart('\', '/')
        $destinationPath = Join-Path $DestinationRulesRoot $relative
        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
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
    $libDir = Join-Path $repoRoot 'scripts\_lib'
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
    $placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-ClaudePlaceholdersInTree -RootPath $destinationRulesRoot -PlaceholderMap $placeholderMap
    Assert-ClaudePlaceholdersResolved -RootPath $destinationRulesRoot

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
