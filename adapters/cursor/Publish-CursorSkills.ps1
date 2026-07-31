#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Cursor Publish-Skills (copy core/skills + resolve placeholders).
#>

$script:CursorAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CursorAdapterModuleDirectory)) {
    $script:CursorAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_cursorToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CursorAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_cursorToolkitLibDirectory 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $_cursorToolkitLibDirectory 'Resolve-InstallRoot.ps1')
. (Join-Path $_cursorToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _cursorToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-CursorAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:CursorAdapterModuleDirectory))
}

function Copy-CursorSkillDirectoryTree {
    param(
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][string] $DestRoot
    )

    $null = Copy-ToolkitManagedTree -SourceRoot $SourceRoot -DestinationRoot $DestRoot
    return @(Get-ToolkitSourceSkillNames -SourceSkillsRoot $SourceRoot).Count
}

function Get-CursorNormalizedForwardSlashPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:CursorAdapterConstant.PathSeparatorForwardSlash)
}

function Get-CursorSupportedPlaceholderTokens {
    return @(
        $script:CursorAdapterConstant.PlaceholderToolkitRoot,
        $script:CursorAdapterConstant.PlaceholderSddRoot,
        $script:CursorAdapterConstant.PlaceholderGuardrailsPath
    )
}

function Get-CursorPlaceholderMap {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-CursorNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-CursorNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:CursorAdapterConstant.SddDirectoryName)
    $guardrailsPath = Get-CursorNormalizedForwardSlashPath -Path (
        Join-Path (Join-Path $InstallRoot $script:CursorAdapterConstant.RulesDirectoryName) $script:CursorAdapterConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:CursorAdapterConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:CursorAdapterConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:CursorAdapterConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Resolve-CursorPlaceholdersInText {
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

function Resolve-CursorPlaceholdersInTree {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:CursorAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CursorSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CursorAdapterMessage.PlaceholderUnresolved
}

function Assert-CursorPlaceholdersResolved {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    $identityMap = [ordered]@{}
    foreach ($token in (Get-CursorSupportedPlaceholderTokens)) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:CursorAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CursorSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CursorAdapterMessage.PlaceholderUnresolved
}

function Assert-CursorPlaceholdersResolvedInFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    foreach ($placeholder in (Get-CursorSupportedPlaceholderTokens)) {
        if ($Text.Contains($placeholder)) {
            throw ($script:CursorAdapterMessage.PlaceholderUnresolved -f $placeholder, $FilePath)
        }
    }
}

function Invoke-CursorPublishSkills {
    <#
    .SYNOPSIS
      Publish core/skills (kebab folders) into InstallRoot/skills.
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

    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:CursorAdapterConstant.CoreDirectoryName) $script:CursorAdapterConstant.SkillsDirectoryName
    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:CursorAdapterMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    $destSkillsRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.SkillsDirectoryName
    $skillFolderCount = @(Get-ChildItem -LiteralPath $sourceSkillsRoot -Directory -ErrorAction Stop).Count

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Skills'
            InstallRoot      = $resolvedInstallRoot
            SourceSkillsRoot = $sourceSkillsRoot
            DestSkillsRoot   = $destSkillsRoot
            SkillFolderCount = $skillFolderCount
            WhatIf           = $true
            Message          = ($script:CursorAdapterMessage.SkillsWouldPublish -f $skillFolderCount, $destSkillsRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destSkillsRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.SkillsDirectoryName

    $placeholderMap = Get-CursorPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:CursorAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CursorSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CursorAdapterMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Skills'
        InstallRoot      = $resolvedInstallRoot
        SourceSkillsRoot = $sourceSkillsRoot
        DestSkillsRoot   = $destSkillsRoot
        SkillFolderCount = $publishResult.SkillFolderCount
        WhatIf           = $false
        Message          = ($script:CursorAdapterMessage.SkillsPublished -f $publishResult.SkillFolderCount, $destSkillsRoot)
        ExitCode         = 0
    }
}

