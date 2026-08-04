#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Policy (core/policy -> InstallRoot/rules).

.DESCRIPTION
  Mapping: core/policy/{name}.md -> <InstallRoot>/rules/{name}.md (keep .md; Claude layout).
  Placeholders resolved after copy. Re-publish overwrites managed rule files; does not delete alien files.
  TOOLKIT_ROOT for policy trees is InstallRoot (rules live under InstallRoot/rules).
#>

function Copy-CodexCorePolicyTree {
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

function Get-CodexPolicyPlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    # Policy/rules live under InstallRoot; TOOLKIT_ROOT matches Claude (InstallRoot).
    $syntheticSkillsRoot = Join-Path $InstallRoot $script:CodexPathConstant.SkillsDirectoryName
    return (Get-CodexPlaceholderMap -InstallRoot $InstallRoot -PublishedSkillsRoot $syntheticSkillsRoot)
}

function Invoke-CodexPublishPolicy {
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
        throw $script:CodexPublishMessage.InstallRootRequired
    }

    $repoRoot = Get-CodexPublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:CodexPathConstant.CoreDirectoryName) $script:CodexPathConstant.PolicyDirectoryName
    $destinationRulesRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.RulesDirectoryName

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:CodexPublishMessage.CorePolicyMissing -f $sourcePolicyRoot)
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
            Message     = ($script:CodexPublishMessage.PolicyWhatIfOk -f $destinationRulesRoot)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationRulesRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.RulesDirectoryName

    $filesCopied = Copy-CodexCorePolicyTree -SourcePolicyRoot $sourcePolicyRoot -DestinationRulesRoot $destinationRulesRoot
    $placeholderMap = Get-CodexPolicyPlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-CodexPlaceholdersInTree -RootPath $destinationRulesRoot -PlaceholderMap $placeholderMap
    Assert-CodexPlaceholdersResolved -RootPath $destinationRulesRoot

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Policy'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        RulesRoot   = $destinationRulesRoot
        SourceRoot  = $sourcePolicyRoot
        FilesCopied = $filesCopied
        Message     = ($script:CodexPublishMessage.PolicyPublishedOk -f $filesCopied, $destinationRulesRoot)
        ExitCode    = 0
    }
}
