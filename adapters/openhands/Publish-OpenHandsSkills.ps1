#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenHands Publish-Skills (core/skills -> .agents/skills + .plugin/plugin.json).
#>

$script:OpenHandsAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenHandsAdapterModuleDirectory)) {
    $script:OpenHandsAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_openHandsToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:OpenHandsAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_openHandsToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _openHandsToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-OpenHandsAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:OpenHandsAdapterModuleDirectory))
}

function Initialize-OpenHandsInstallRootResolver {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue) {
        return
    }

    $repoRoot = Get-OpenHandsAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:OpenHandsAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:OpenHandsAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
}

function Convert-OpenHandsRelativeToOsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    return ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Test-OpenHandsInstallRootIsUserAgentsHome {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $leaf = Split-Path -Leaf $ResolvedInstallRoot
    return [string]::Equals(
        $leaf,
        $script:OpenHandsAdapterConstant.OfficialUserRootRelativePath,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Get-OpenHandsMappedInstallPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $isUserHome = Test-OpenHandsInstallRootIsUserAgentsHome -ResolvedInstallRoot $ResolvedInstallRoot
    $sep = [System.IO.Path]::DirectorySeparatorChar

    if ($isUserHome) {
        $skillsRel = $script:OpenHandsAdapterConstant.OfficialUserSkillsRelativePath
        $agentsRel = $script:OpenHandsAdapterConstant.AgentsDirectoryName
        $toolkitRoot = $ResolvedInstallRoot
    }
    else {
        $skillsRel = Convert-OpenHandsRelativeToOsPath -RelativePath $script:OpenHandsAdapterConstant.OfficialSkillsRelativePath
        $agentsRel = Convert-OpenHandsRelativeToOsPath -RelativePath $script:OpenHandsAdapterConstant.OfficialCustomAgentsRelativePath
        $toolkitRoot = Join-Path $ResolvedInstallRoot $script:OpenHandsAdapterConstant.DotAgentsDirectoryName
    }

    $hooksRel = Convert-OpenHandsRelativeToOsPath -RelativePath $script:OpenHandsAdapterConstant.OfficialHooksRelativePath
    $hooksScriptsRel = Convert-OpenHandsRelativeToOsPath -RelativePath $script:OpenHandsAdapterConstant.OfficialHooksScriptsRelativePath
    $pluginRel = Convert-OpenHandsRelativeToOsPath -RelativePath $script:OpenHandsAdapterConstant.OfficialPluginRelativePath

    return [PSCustomObject]@{
        FixtureUserRootPath           = $ResolvedInstallRoot
        FixtureProjectRootPath        = $ResolvedInstallRoot
        FixtureSkillsPath             = Join-Path $ResolvedInstallRoot $skillsRel
        FixtureRulesPath              = Join-Path $ResolvedInstallRoot $script:OpenHandsAdapterConstant.OfficialAgentsFileName
        FixtureHooksPath              = Join-Path $ResolvedInstallRoot $hooksRel
        FixtureHooksScriptsPath       = Join-Path $ResolvedInstallRoot $hooksScriptsRel
        FixturePluginPath             = Join-Path $ResolvedInstallRoot $pluginRel
        FixturePluginManifestPath     = Join-Path (Join-Path $ResolvedInstallRoot $pluginRel) $script:OpenHandsAdapterConstant.PluginManifestFileName
        FixtureCustomAgentsPath       = Join-Path $ResolvedInstallRoot $agentsRel
        FixtureProjectAgentsPath      = Join-Path $ResolvedInstallRoot $script:OpenHandsAdapterConstant.OfficialAgentsFileName
        ToolkitRootPath               = $toolkitRoot
        IsUserAgentsHome              = $isUserHome
        PathSeparator                 = $sep
    }
}

function Get-OpenHandsNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:OpenHandsAdapterConstant.PathSeparatorForwardSlash)
}

function Get-OpenHandsSupportedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:OpenHandsAdapterConstant.PlaceholderToolkitRoot,
        $script:OpenHandsAdapterConstant.PlaceholderSddRoot,
        $script:OpenHandsAdapterConstant.PlaceholderGuardrailsPath
    )
}

function Get-OpenHandsPlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $InstallRoot
    $toolkitRoot = Get-OpenHandsNormalizedForwardSlashPath -Path $mapped.ToolkitRootPath
    $sddRoot = Get-OpenHandsNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:OpenHandsAdapterConstant.SddDirectoryName)
    $guardrailsPath = Get-OpenHandsNormalizedForwardSlashPath -Path $mapped.FixtureProjectAgentsPath

    return [ordered]@{
        ($script:OpenHandsAdapterConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:OpenHandsAdapterConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:OpenHandsAdapterConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Initialize-OpenHandsToolkitManagedTreeLib {
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-OpenHandsAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ($script:OpenHandsAdapterMessage.ManagedTreeLibMissing -f $libPath)
    }
}

function Write-OpenHandsUtf8NoBomFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function New-OpenHandsPluginManifestObject {
    [CmdletBinding()]
    param()

    return [ordered]@{
        name        = $script:OpenHandsAdapterConstant.PluginName
        version     = $script:OpenHandsAdapterConstant.PluginVersion
        description = $script:OpenHandsAdapterConstant.PluginDescription
        author      = $script:OpenHandsAdapterConstant.PluginAuthor
        skills      = $script:OpenHandsAdapterConstant.PluginSkillsManifestRelative
        hooks       = $script:OpenHandsAdapterConstant.PluginHooksManifestRelative
    }
}

function Write-OpenHandsPluginManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $MappedPaths
    )

    $pluginDir = $MappedPaths.FixturePluginPath
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $pluginDir -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $pluginDir)) {
        New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    }

    $manifestPath = $MappedPaths.FixturePluginManifestPath
    Assert-ToolkitManagedPathContained `
        -CandidatePath $manifestPath `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $json = (New-OpenHandsPluginManifestObject | ConvertTo-Json -Depth $script:OpenHandsAdapterConstant.JsonConvertDepthShallow)
    Write-OpenHandsUtf8NoBomFile -Path $manifestPath -Content $json
    return $manifestPath
}

function Invoke-OpenHandsPublishSkills {
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenHandsAdapterRepoRoot
    Initialize-OpenHandsInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:OpenHandsAdapterConstant.CoreDirectoryName) $script:OpenHandsAdapterConstant.SkillsDirectoryName
    $destinationSkillsRoot = $mapped.FixtureSkillsPath

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:OpenHandsAdapterMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success           = $true
            Implemented       = $true
            CommandName       = 'Publish-Skills'
            WhatIf            = $true
            InstallRoot       = $resolvedInstallRoot
            SkillsRoot        = $destinationSkillsRoot
            PluginManifestPath = $mapped.FixturePluginManifestPath
            SourceRoot        = $sourceSkillsRoot
            FilesCopied       = 0
            Message           = ($script:OpenHandsAdapterMessage.WhatIfOk -f $destinationSkillsRoot)
            ExitCode          = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationSkillsRoot = $mapped.FixtureSkillsPath

    Initialize-OpenHandsToolkitManagedTreeLib
    $placeholderMap = Get-OpenHandsPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:OpenHandsAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens @(Get-OpenHandsSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:OpenHandsAdapterMessage.PlaceholderUnresolved

    $pluginPath = Write-OpenHandsPluginManifest -InstallRoot $resolvedInstallRoot -MappedPaths $mapped
    if (-not (Test-Path -LiteralPath $pluginPath)) {
        throw ($script:OpenHandsAdapterMessage.PluginManifestMissing -f $pluginPath)
    }

    return [PSCustomObject]@{
        Success            = $true
        Implemented        = $true
        CommandName        = 'Publish-Skills'
        WhatIf             = $false
        InstallRoot        = $resolvedInstallRoot
        SkillsRoot         = $destinationSkillsRoot
        PluginManifestPath = $pluginPath
        SourceRoot         = $sourceSkillsRoot
        FilesCopied        = $publishResult.FilesCopied
        Message            = ($script:OpenHandsAdapterMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot, $pluginPath)
        ExitCode           = 0
    }
}
