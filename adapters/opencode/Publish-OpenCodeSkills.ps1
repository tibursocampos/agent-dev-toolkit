#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenCode Publish-Skills (copy core/skills + resolve placeholders).

.DESCRIPTION
  Copies core/skills into InstallRoot/skills keeping kebab-case folder names
  (no underscore remapping). Resolves {{TOOLKIT_ROOT}}, {{SDD_ROOT}}, and
  {{GUARDRAILS_PATH}} under the published InstallRoot. Uses Resolve-InstallRoot
  (USERPROFILE guard).
#>

$script:OpenCodeAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenCodeAdapterModuleDirectory)) {
    $script:OpenCodeAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_opencodeToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:OpenCodeAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_opencodeToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _opencodeToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-OpenCodePublishAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:OpenCodeAdapterModuleDirectory))
}

function Get-OpenCodeNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:OpenCodePathConstant.PathSeparatorForwardSlash)
}

function Get-OpenCodePlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-OpenCodeNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-OpenCodeNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:OpenCodePathConstant.SddDirectoryName)
    $guardrailsPath = Get-OpenCodeNormalizedForwardSlashPath -Path (
        Join-Path (Join-Path $InstallRoot $script:OpenCodePathConstant.RulesDirectoryName) $script:OpenCodePathConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:OpenCodePathConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:OpenCodePathConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:OpenCodePathConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Initialize-OpenCodeToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-OpenCodePublishAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ("OpenCode Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Get-OpenCodeUnresolvedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:OpenCodePathConstant.PlaceholderToolkitRoot,
        $script:OpenCodePathConstant.PlaceholderSddRoot,
        $script:OpenCodePathConstant.PlaceholderGuardrailsPath
    )
}

function Copy-OpenCodeCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-OpenCodeToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Resolve-OpenCodePlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-OpenCodeToolkitManagedTreeLib
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:OpenCodePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-OpenCodeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:OpenCodePublishMessage.PlaceholderUnresolved
}

function Assert-OpenCodePlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Initialize-OpenCodeToolkitManagedTreeLib
    $identityMap = [ordered]@{}
    foreach ($token in (Get-OpenCodeUnresolvedPlaceholderTokens)) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:OpenCodePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-OpenCodeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:OpenCodePublishMessage.PlaceholderUnresolved
}

function Invoke-OpenCodePublishSkills {
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
        throw $script:OpenCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenCodePublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:OpenCodePathConstant.CoreDirectoryName) $script:OpenCodePathConstant.SkillsDirectoryName
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:OpenCodePublishMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success     = $true
            Implemented = $true
            CommandName = 'Publish-Skills'
            WhatIf      = $true
            InstallRoot = $resolvedInstallRoot
            SkillsRoot  = $destinationSkillsRoot
            SourceRoot  = $sourceSkillsRoot
            FilesCopied = 0
            Message     = ($script:OpenCodePublishMessage.WhatIfOk -f $destinationSkillsRoot)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.SkillsDirectoryName

    Initialize-OpenCodeToolkitManagedTreeLib
    $placeholderMap = Get-OpenCodePlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:OpenCodePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-OpenCodeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:OpenCodePublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Skills'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        SkillsRoot  = $destinationSkillsRoot
        SourceRoot  = $sourceSkillsRoot
        FilesCopied = $publishResult.FilesCopied
        Message     = ($script:OpenCodePublishMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot)
        ExitCode    = 0
    }
}
