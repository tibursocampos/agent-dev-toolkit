#Requires -Version 5.1
$script:ToolkitCopyHelperRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')

<#
.SYNOPSIS
  Helpers for Cursor Publish-Policy (core/policy -> InstallRoot/rules as .mdc).
#>

function Publish-CursorPolicyAsMdcRules {
    param(
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][string] $DestRoot,
        [Parameter(Mandatory = $true)][string] $InstallRoot
    )

    $sourceExt = $script:CursorAdapterConstant.PolicySourceExtension
    $destExt = $script:CursorAdapterConstant.PolicyDestExtension
    $published = 0

    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $DestRoot -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $DestRoot)) {
        New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null
    }
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $DestRoot -InstallRoot $InstallRoot

    $sourceFiles = @(Get-ChildItem -LiteralPath $SourceRoot -File -Filter ('*{0}' -f $sourceExt) -ErrorAction Stop)
    foreach ($sourceFile in $sourceFiles) {
        $destName = [System.IO.Path]::ChangeExtension($sourceFile.Name, $destExt)
        $destPath = Join-Path $DestRoot $destName
        Assert-ToolkitManagedPathContained `
            -CandidatePath $destPath `
            -RootPath $InstallRoot `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
            -RequireStrictChild
        $null = Copy-ToolkitFileIfAbsent -SourcePath $sourceFile.FullName -DestinationPath $destPath
        $published++
    }

    # Plain .md files in the shared rules folder have no verifiable ownership.
    # Preserve them instead of treating their extension as proof of toolkit ownership.

    # Do not delete .mdc files with no matching core/policy .md source: DestRoot is a shared,
    # user-writable rules folder and unmatched .mdc may be the user's own custom rules, not
    # toolkit leftovers. Only publish/overwrite toolkit-managed .mdc; never purge alien files.
    return $published
}

function Invoke-CursorPublishPolicy {
    <#
    .SYNOPSIS
      Publish core/policy/*.md into InstallRoot/rules as Cursor *.mdc rules.
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

    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:CursorAdapterConstant.CoreDirectoryName) $script:CursorAdapterConstant.PolicyDirectoryName
    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:CursorAdapterMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    $destRulesRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.RulesDirectoryName
    $policyFileCount = @(Get-ChildItem -LiteralPath $sourcePolicyRoot -File -Filter ('*{0}' -f $script:CursorAdapterConstant.PolicySourceExtension) -ErrorAction Stop).Count

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Policy'
            InstallRoot      = $resolvedInstallRoot
            SourcePolicyRoot = $sourcePolicyRoot
            DestRulesRoot    = $destRulesRoot
            PolicyFileCount  = $policyFileCount
            WhatIf           = $true
            Message          = ($script:CursorAdapterMessage.PolicyWouldPublish -f $policyFileCount, $destRulesRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destRulesRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.RulesDirectoryName

    $publishedCount = Publish-CursorPolicyAsMdcRules -SourceRoot $sourcePolicyRoot -DestRoot $destRulesRoot -InstallRoot $resolvedInstallRoot
    $placeholderMap = Get-CursorPlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-CursorPlaceholdersInTree -RootPath $destRulesRoot -PlaceholderMap $placeholderMap
    Assert-CursorPlaceholdersResolved -RootPath $destRulesRoot

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Policy'
        InstallRoot      = $resolvedInstallRoot
        SourcePolicyRoot = $sourcePolicyRoot
        DestRulesRoot    = $destRulesRoot
        PolicyFileCount  = $publishedCount
        WhatIf           = $false
        Message          = ($script:CursorAdapterMessage.PolicyPublished -f $publishedCount, $destRulesRoot)
        ExitCode         = 0
    }
}

