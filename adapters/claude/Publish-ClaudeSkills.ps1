#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Claude Publish-Skills (copy core/skills + resolve placeholders).
#>

$script:ClaudeAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeAdapterModuleDirectory)) {
    $script:ClaudeAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_claudeToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:ClaudeAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_claudeToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _claudeToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-ClaudeAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:ClaudeAdapterModuleDirectory))
}

function Initialize-ClaudeToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-ClaudeAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ("Claude Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Get-ClaudeNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:ClaudePathConstant.PathSeparatorForwardSlash)
}

function Get-ClaudePlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-ClaudeNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-ClaudeNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:ClaudePathConstant.SddDirectoryName)
    $guardrailsPath = Get-ClaudeNormalizedForwardSlashPath -Path (
        Join-Path (Join-Path $InstallRoot $script:ClaudePathConstant.RulesDirectoryName) $script:ClaudePathConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:ClaudePathConstant.PlaceholderToolkitRoot)     = $toolkitRoot
        ($script:ClaudePathConstant.PlaceholderSddRoot)         = $sddRoot
        ($script:ClaudePathConstant.PlaceholderGuardrailsPath)  = $guardrailsPath
    }
}

function Get-ClaudeUnresolvedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:ClaudePathConstant.PlaceholderToolkitRoot,
        $script:ClaudePathConstant.PlaceholderSddRoot,
        $script:ClaudePathConstant.PlaceholderGuardrailsPath
    )
}

function Copy-ClaudeCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-ClaudeToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Resolve-ClaudePlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-ClaudeToolkitManagedTreeLib
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:ClaudePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ClaudeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ClaudePublishMessage.PlaceholderUnresolved
}

function Assert-ClaudePlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    # Resolve-ClaudePlaceholdersInTree already asserts; keep for callers that only assert.
    Initialize-ClaudeToolkitManagedTreeLib
    $identityMap = [ordered]@{}
    foreach ($token in (Get-ClaudeUnresolvedPlaceholderTokens)) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:ClaudePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ClaudeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ClaudePublishMessage.PlaceholderUnresolved
}

function Invoke-ClaudePublishSkills {
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
    Initialize-ClaudeToolkitManagedTreeLib

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:ClaudePathConstant.CoreDirectoryName) $script:ClaudePathConstant.SkillsDirectoryName
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:ClaudePublishMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Skills'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            SkillsRoot   = $destinationSkillsRoot
            SourceRoot   = $sourceSkillsRoot
            FilesCopied  = 0
            Message      = ($script:ClaudePublishMessage.WhatIfOk -f $destinationSkillsRoot)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.SkillsDirectoryName

    $placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:ClaudePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ClaudeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ClaudePublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Skills'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        SkillsRoot  = $destinationSkillsRoot
        SourceRoot  = $sourceSkillsRoot
        FilesCopied = $publishResult.FilesCopied
        Message     = ($script:ClaudePublishMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot)
        ExitCode    = 0
    }
}
