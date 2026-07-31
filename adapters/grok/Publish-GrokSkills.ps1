#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Grok Publish-Skills (copy core/skills + resolve placeholders).
#>

$script:GrokAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:GrokAdapterModuleDirectory)) {
    $script:GrokAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_grokToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:GrokAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_grokToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _grokToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-GrokAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:GrokAdapterModuleDirectory))
}

function Initialize-GrokInstallRootResolver {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue) {
        return
    }

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
}

function Get-GrokMappedInstallPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $projectRoot = Join-Path $ResolvedInstallRoot ($script:GrokAdapterConstant.OfficialProjectRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)

    return [PSCustomObject]@{
        FixtureUserRootPath      = Join-Path $ResolvedInstallRoot ($script:GrokAdapterConstant.OfficialUserRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        FixtureProjectRootPath   = $projectRoot
        FixtureSkillsPath        = Join-Path $ResolvedInstallRoot ($script:GrokAdapterConstant.OfficialSkillsRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        FixtureRulesPath         = Join-Path $ResolvedInstallRoot ($script:GrokAdapterConstant.OfficialRulesRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        FixtureHooksPath         = Join-Path $ResolvedInstallRoot ($script:GrokAdapterConstant.OfficialHooksRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        FixtureProjectAgentsPath = Join-Path $ResolvedInstallRoot $script:GrokAdapterConstant.OfficialAgentsFileName
    }
}

function Get-GrokNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:GrokAdapterConstant.PathSeparatorForwardSlash)
}

function Get-GrokSupportedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:GrokAdapterConstant.PlaceholderToolkitRoot,
        $script:GrokAdapterConstant.PlaceholderSddRoot,
        $script:GrokAdapterConstant.PlaceholderGuardrailsPath
    )
}

function Get-GrokPlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-GrokNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-GrokNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:GrokAdapterConstant.SddDirectoryName)
    $rulesRoot = Join-Path $InstallRoot ($script:GrokAdapterConstant.OfficialRulesRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $guardrailsPath = Get-GrokNormalizedForwardSlashPath -Path (
        Join-Path $rulesRoot $script:GrokAdapterConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:GrokAdapterConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:GrokAdapterConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:GrokAdapterConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Initialize-GrokToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-GrokAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ("Grok Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Copy-GrokCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-GrokToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Resolve-GrokPlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-GrokToolkitManagedTreeLib
    $tokens = @(Get-GrokSupportedPlaceholderTokens)
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:GrokAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens $tokens `
        -UnresolvedMessageFormat $script:GrokAdapterMessage.PlaceholderUnresolved
}

function Assert-GrokPlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Initialize-GrokToolkitManagedTreeLib
    $tokens = @(Get-GrokSupportedPlaceholderTokens)
    $identityMap = [ordered]@{}
    foreach ($token in $tokens) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:GrokAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens $tokens `
        -UnresolvedMessageFormat $script:GrokAdapterMessage.PlaceholderUnresolved
}

function Invoke-GrokPublishSkills {
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:GrokAdapterConstant.CoreDirectoryName) $script:GrokAdapterConstant.SkillsDirectoryName
    $destinationSkillsRoot = $mapped.FixtureSkillsPath

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:GrokAdapterMessage.CoreSkillsMissing -f $sourceSkillsRoot)
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
            Message     = ($script:GrokAdapterMessage.WhatIfOk -f $destinationSkillsRoot)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationSkillsRoot = $mapped.FixtureSkillsPath

    Initialize-GrokToolkitManagedTreeLib
    $placeholderMap = Get-GrokPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:GrokAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens @(Get-GrokSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:GrokAdapterMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Skills'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        SkillsRoot  = $destinationSkillsRoot
        SourceRoot  = $sourceSkillsRoot
        FilesCopied = $publishResult.FilesCopied
        Message     = ($script:GrokAdapterMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot)
        ExitCode    = 0
    }
}

