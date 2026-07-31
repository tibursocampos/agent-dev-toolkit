#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for ZCode Publish-Skills (idempotent copy of core/skills kebab folders).

.DESCRIPTION
  Copies core/skills into InstallRoot/skills and resolves {{TOOLKIT_ROOT}},
  {{SDD_ROOT}}, and {{GUARDRAILS_PATH}} at the destination only (core/ on disk
  keeps placeholders). Uses Resolve-InstallRoot (USERPROFILE guard).
#>

$script:ZCodeAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ZCodeAdapterModuleDirectory)) {
    $script:ZCodeAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_zcodeToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:ZCodeAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_zcodeToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _zcodeToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-ZCodeAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:ZCodeAdapterModuleDirectory))
}

function Get-ZCodeNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:ZCodePathConstant.PathSeparatorForwardSlash)
}

function Get-ZCodePlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-ZCodeNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-ZCodeNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:ZCodePathConstant.SddDirectoryName)
    $guardrailsPath = Get-ZCodeNormalizedForwardSlashPath -Path (
        Join-Path (Join-Path $InstallRoot $script:ZCodePathConstant.CursorRulesDirectoryName) $script:ZCodePathConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:ZCodePathConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:ZCodePathConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:ZCodePathConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Get-ZCodeSupportedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:ZCodePathConstant.PlaceholderToolkitRoot,
        $script:ZCodePathConstant.PlaceholderSddRoot,
        $script:ZCodePathConstant.PlaceholderGuardrailsPath
    )
}

function Initialize-ZCodeToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-ZCodeAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ("ZCode Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Resolve-ZCodePlaceholdersInText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    $updated = $Text
    foreach ($key in $PlaceholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$PlaceholderMap[$key])
        }
    }

    return $updated
}

function Resolve-ZCodePlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-ZCodeToolkitManagedTreeLib
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:ZCodePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ZCodeSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ZCodePublishMessage.PlaceholderUnresolved
}

function Assert-ZCodePlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Initialize-ZCodeToolkitManagedTreeLib
    $identityMap = [ordered]@{}
    foreach ($token in (Get-ZCodeSupportedPlaceholderTokens)) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:ZCodePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ZCodeSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ZCodePublishMessage.PlaceholderUnresolved
}

function Assert-ZCodePlaceholdersResolvedInFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    foreach ($placeholder in (Get-ZCodeSupportedPlaceholderTokens)) {
        if ($Text.Contains($placeholder)) {
            throw ($script:ZCodePublishMessage.PlaceholderUnresolved -f $placeholder, $FilePath)
        }
    }
}

function Copy-ZCodeCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-ZCodeToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Invoke-ZCodePublishSkills {
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
        throw $script:ZCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ZCodeAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:ZCodePathConstant.CoreDirectoryName) $script:ZCodePathConstant.SkillsDirectoryName
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:ZCodePathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:ZCodePublishMessage.CoreSkillsMissing -f $sourceSkillsRoot)
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
            Message     = ($script:ZCodePublishMessage.WhatIfOk -f $destinationSkillsRoot)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:ZCodePathConstant.SkillsDirectoryName

    Initialize-ZCodeToolkitManagedTreeLib
    $placeholderMap = Get-ZCodePlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:ZCodePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ZCodeSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ZCodePublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Skills'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        SkillsRoot  = $destinationSkillsRoot
        SourceRoot  = $sourceSkillsRoot
        FilesCopied = $publishResult.FilesCopied
        Message     = ($script:ZCodePublishMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot)
        ExitCode    = 0
    }
}
