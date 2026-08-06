#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Skills (plugin.json + copy core/skills + placeholders).
#>

$script:CodexAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CodexAdapterModuleDirectory)) {
    $script:CodexAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_codexToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CodexAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_codexToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _codexToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-CodexPublishAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:CodexAdapterModuleDirectory))
}

function Get-CodexNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:CodexPathConstant.PathSeparatorForwardSlash)
}

function Test-CodexIsLiveOfficialInstallRoot {
    <#
    .SYNOPSIS
      True when ResolvedInstallRoot is the live official ~/.codex home and -AllowUserHome is set.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if (-not $AllowUserHome.IsPresent) {
        return $false
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    if ([string]::IsNullOrWhiteSpace($userHome)) {
        return $false
    }

    $officialCodexHome = Join-Path $userHome $script:CodexPathConstant.OfficialCodexHomeRelativePath
    $installFull = Get-CodexNormalizedForwardSlashPath -Path $ResolvedInstallRoot
    $officialFull = Get-CodexNormalizedForwardSlashPath -Path $officialCodexHome
    return [string]::Equals($installFull, $officialFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-CodexUserSkillsRoot {
    <#
    .SYNOPSIS
      Resolve USER-scope skills destination (fixture vs live ~/.agents/skills).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    $relative = $script:CodexPathConstant.UserSkillsRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
    if (Test-CodexIsLiveOfficialInstallRoot -ResolvedInstallRoot $ResolvedInstallRoot -AllowUserHome:$AllowUserHome) {
        $userHome = [Environment]::GetFolderPath('UserProfile')
        if ([string]::IsNullOrWhiteSpace($userHome)) {
            throw $script:CodexPublishMessage.LiveUserScopeRequiresAllowUserHome
        }

        return [System.IO.Path]::GetFullPath((Join-Path $userHome $relative))
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ResolvedInstallRoot $relative))
}

function Resolve-CodexUserSkillsContainmentRoot {
    <#
    .SYNOPSIS
      Containment root for managed publish/delete of USER-scope skills.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if (Test-CodexIsLiveOfficialInstallRoot -ResolvedInstallRoot $ResolvedInstallRoot -AllowUserHome:$AllowUserHome) {
        $userHome = [Environment]::GetFolderPath('UserProfile')
        if ([string]::IsNullOrWhiteSpace($userHome)) {
            throw $script:CodexPublishMessage.LiveUserScopeRequiresAllowUserHome
        }

        return [System.IO.Path]::GetFullPath($userHome)
    }

    return [System.IO.Path]::GetFullPath($ResolvedInstallRoot)
}

function Get-CodexPlaceholderMap {
    <#
    .SYNOPSIS
      Build placeholder map for a skills publish destination.

    .DESCRIPTION
      TOOLKIT_ROOT is the parent of PublishedSkillsRoot (plugin root, InstallRoot for
      home skills, or .agents for USER-scope), so {{TOOLKIT_ROOT}}/skills/_shared
      resolves beside the published skills tree.
      SDD_ROOT and GUARDRAILS_PATH stay under product InstallRoot (sdd/, rules/).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $PublishedSkillsRoot
    )

    $toolkitRootPath = Split-Path -Parent $PublishedSkillsRoot
    if ([string]::IsNullOrWhiteSpace($toolkitRootPath)) {
        $toolkitRootPath = $PublishedSkillsRoot
    }

    $toolkitRoot = Get-CodexNormalizedForwardSlashPath -Path $toolkitRootPath
    $sddRoot = Get-CodexNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:CodexPathConstant.SddDirectoryName)
    $guardrailsPath = Get-CodexNormalizedForwardSlashPath -Path (
        Join-Path (Join-Path $InstallRoot $script:CodexPathConstant.RulesDirectoryName) $script:CodexPathConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:CodexPathConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:CodexPathConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:CodexPathConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Initialize-CodexToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-CodexPublishAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ("Codex Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Get-CodexUnresolvedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:CodexPathConstant.PlaceholderToolkitRoot,
        $script:CodexPathConstant.PlaceholderSddRoot,
        $script:CodexPathConstant.PlaceholderGuardrailsPath
    )
}

function Copy-CodexCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-CodexToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Resolve-CodexPlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-CodexToolkitManagedTreeLib
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:CodexPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CodexUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CodexPublishMessage.PlaceholderUnresolved
}

function Assert-CodexPlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Initialize-CodexToolkitManagedTreeLib
    $identityMap = [ordered]@{}
    foreach ($token in (Get-CodexUnresolvedPlaceholderTokens)) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:CodexPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CodexUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CodexPublishMessage.PlaceholderUnresolved
}

function New-CodexPluginManifestObject {
    [CmdletBinding()]
    param()

    return [ordered]@{
        name        = $script:CodexPathConstant.PluginName
        version     = $script:CodexPathConstant.PluginVersion
        description = $script:CodexPathConstant.PluginDescription
        skills      = $script:CodexPathConstant.PluginSkillsManifestRelative
        interface   = [ordered]@{
            displayName = $script:CodexPathConstant.PluginDisplayName
        }
    }
}

function Write-CodexPluginManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginRoot,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $manifestDir = Join-Path $PluginRoot $script:CodexPathConstant.PluginManifestDirectoryName
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $manifestDir -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $manifestDir)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $manifestDir -InstallRoot $InstallRoot

    $existing = @(Get-ChildItem -LiteralPath $manifestDir -Force -ErrorAction SilentlyContinue | Where-Object {
        -not $_.PSIsContainer -and $_.Name -ne $script:CodexPathConstant.PluginManifestFileName
    })
    foreach ($extra in $existing) {
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $extra.FullName -InstallRoot $InstallRoot
        Remove-Item -LiteralPath $extra.FullName -Force
    }

    $manifestPath = Join-Path $manifestDir $script:CodexPathConstant.PluginManifestFileName
    Assert-ToolkitManagedPathContained `
        -CandidatePath $manifestPath `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    $manifest = New-CodexPluginManifestObject
    $json = ($manifest | ConvertTo-Json -Depth $script:CodexPathConstant.JsonConvertDepthShallow)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($manifestPath, $json, $utf8NoBom)

    $remainingExtras = @(Get-ChildItem -LiteralPath $manifestDir -Force -File | Where-Object {
        $_.Name -ne $script:CodexPathConstant.PluginManifestFileName
    })
    if ($remainingExtras.Count -gt 0) {
        $names = ($remainingExtras | ForEach-Object { $_.Name }) -join ', '
        throw ($script:CodexPublishMessage.ManifestExtraFiles -f $names)
    }

    return $manifestPath
}

function Get-CodexMarketplaceCatalogPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $agentsDir = Join-Path $InstallRoot $script:CodexPathConstant.AgentsDirectoryName
    $pluginsDir = Join-Path $agentsDir $script:CodexPathConstant.PluginsDirectoryName
    return Join-Path $pluginsDir $script:CodexPathConstant.MarketplaceFileName
}

function New-CodexMarketplaceCatalogObject {
    [CmdletBinding()]
    param()

    return [ordered]@{
        name      = $script:CodexPathConstant.MarketplaceName
        interface = [ordered]@{
            displayName = $script:CodexPathConstant.MarketplaceDisplayName
        }
        plugins   = @(
            [ordered]@{
                name     = $script:CodexPathConstant.PluginName
                source   = [ordered]@{
                    source = $script:CodexPathConstant.PluginMarketplaceSourceKind
                    path   = $script:CodexPathConstant.PluginMarketplaceSourcePath
                }
                policy   = [ordered]@{
                    installation    = $script:CodexPathConstant.MarketplacePolicyInstallation
                    authentication  = $script:CodexPathConstant.MarketplacePolicyAuthentication
                }
                category = $script:CodexPathConstant.MarketplacePluginCategory
            }
        )
    }
}

function Resolve-CodexMarketplacePluginPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $SourcePath
    )

    $trimmed = $SourcePath.Trim()
    if (-not $trimmed.StartsWith('./')) {
        throw ($script:CodexPublishMessage.MarketplaceSourceInvalid -f $SourcePath)
    }

    $relative = $trimmed.Substring(2).TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    if ([string]::IsNullOrWhiteSpace($relative)) {
        throw ($script:CodexPublishMessage.MarketplaceSourceInvalid -f $SourcePath)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $InstallRoot $relative))
}

function Write-CodexMarketplaceCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $PluginRoot
    )

    $marketplacePath = Get-CodexMarketplaceCatalogPath -InstallRoot $InstallRoot
    $marketplaceDir = Split-Path -Parent $marketplacePath
    if (-not (Test-Path -LiteralPath $marketplaceDir)) {
        New-Item -ItemType Directory -Path $marketplaceDir -Force | Out-Null
    }

    $resolvedPluginFromEntry = Resolve-CodexMarketplacePluginPath -InstallRoot $InstallRoot -SourcePath $script:CodexPathConstant.PluginMarketplaceSourcePath
    $expectedPluginRoot = [System.IO.Path]::GetFullPath($PluginRoot)
    if (-not [string]::Equals($resolvedPluginFromEntry, $expectedPluginRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ($script:CodexPublishMessage.MarketplacePluginMissing -f $resolvedPluginFromEntry)
    }
    if (-not (Test-Path -LiteralPath $resolvedPluginFromEntry)) {
        throw ($script:CodexPublishMessage.MarketplacePluginMissing -f $resolvedPluginFromEntry)
    }

    $catalog = New-CodexMarketplaceCatalogObject
    $json = ($catalog | ConvertTo-Json -Depth $script:CodexPathConstant.JsonConvertDepthDeep)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($marketplacePath, $json, $utf8NoBom)

    return $marketplacePath
}

function Invoke-CodexPublishSkills {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $UserScope,

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
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:CodexPathConstant.CoreDirectoryName) $script:CodexPathConstant.SkillsDirectoryName
    $pluginRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.PluginRootDirectoryName
    $destinationSkillsRoot = Join-Path $pluginRoot $script:CodexPathConstant.SkillsDirectoryName
    $homeSkillsRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.HomeSkillsRelativePath
    $userSkillsRoot = Resolve-CodexUserSkillsRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $userSkillsContainmentRoot = Resolve-CodexUserSkillsContainmentRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $manifestPath = Join-Path (Join-Path $pluginRoot $script:CodexPathConstant.PluginManifestDirectoryName) $script:CodexPathConstant.PluginManifestFileName
    $marketplacePath = Get-CodexMarketplaceCatalogPath -InstallRoot $resolvedInstallRoot
    $userScopeEnabled = $UserScope.IsPresent
    $liveUserScope = Test-CodexIsLiveOfficialInstallRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:CodexPublishMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    if ($WhatIf.IsPresent) {
        $whatIfMessage = if ($userScopeEnabled) {
            ($script:CodexPublishMessage.WhatIfOkWithUserScope -f $pluginRoot, $userSkillsRoot)
        }
        else {
            ($script:CodexPublishMessage.WhatIfOk -f $pluginRoot)
        }

        return [PSCustomObject]@{
            Success                = $true
            Implemented            = $true
            CommandName            = 'Publish-Skills'
            WhatIf                 = $true
            UserScope              = $userScopeEnabled
            LiveUserScope          = $(if ($userScopeEnabled) { $liveUserScope } else { $false })
            InstallRoot            = $resolvedInstallRoot
            PluginRoot             = $pluginRoot
            ManifestPath           = $manifestPath
            MarketplacePath        = $marketplacePath
            SkillsRoot             = $destinationSkillsRoot
            HomeSkillsRoot         = $homeSkillsRoot
            UserSkillsRoot         = $(if ($userScopeEnabled) { $userSkillsRoot } else { $null })
            SourceRoot             = $sourceSkillsRoot
            FilesCopied            = 0
            HomeSkillsFilesCopied  = 0
            UserSkillsFilesCopied  = 0
            Message                = $whatIfMessage
            ExitCode               = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $pluginRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.PluginRootDirectoryName
    $destinationSkillsRoot = Join-Path $pluginRoot $script:CodexPathConstant.SkillsDirectoryName
    $homeSkillsRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.HomeSkillsRelativePath
    $userSkillsRoot = Resolve-CodexUserSkillsRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $userSkillsContainmentRoot = Resolve-CodexUserSkillsContainmentRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $liveUserScope = Test-CodexIsLiveOfficialInstallRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $manifestPath = Join-Path (Join-Path $pluginRoot $script:CodexPathConstant.PluginManifestDirectoryName) $script:CodexPathConstant.PluginManifestFileName
    $marketplacePath = Get-CodexMarketplaceCatalogPath -InstallRoot $resolvedInstallRoot

    if (-not (Test-Path -LiteralPath $pluginRoot)) {
        New-Item -ItemType Directory -Path $pluginRoot -Force | Out-Null
    }

    $writtenManifest = Write-CodexPluginManifest -PluginRoot $pluginRoot -InstallRoot $resolvedInstallRoot
    Initialize-CodexToolkitManagedTreeLib
    $pluginPlaceholderMap = Get-CodexPlaceholderMap -InstallRoot $resolvedInstallRoot -PublishedSkillsRoot $destinationSkillsRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $pluginPlaceholderMap `
        -TextFileExtensionPattern $script:CodexPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CodexUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CodexPublishMessage.PlaceholderUnresolved
    $filesCopied = $publishResult.FilesCopied
    $writtenMarketplace = Write-CodexMarketplaceCatalog -InstallRoot $resolvedInstallRoot -PluginRoot $pluginRoot

    $homePlaceholderMap = Get-CodexPlaceholderMap -InstallRoot $resolvedInstallRoot -PublishedSkillsRoot $homeSkillsRoot
    $homePublishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $homeSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $homePlaceholderMap `
        -TextFileExtensionPattern $script:CodexPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CodexUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CodexPublishMessage.PlaceholderUnresolved
    $homeSkillsFilesCopied = $homePublishResult.FilesCopied

    $userSkillsFilesCopied = 0
    $publishedUserSkillsRoot = $null
    $userSkillsPruned = 0
    if ($userScopeEnabled) {
        if ($liveUserScope) {
            $null = Initialize-InstallRootForWrite -InstallRoot $userSkillsContainmentRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
        }

        $userPlaceholderMap = Get-CodexPlaceholderMap -InstallRoot $resolvedInstallRoot -PublishedSkillsRoot $userSkillsRoot
        $userPublishResult = Invoke-ToolkitManagedSkillsPublish `
            -SourceSkillsRoot $sourceSkillsRoot `
            -DestinationSkillsRoot $userSkillsRoot `
            -InstallRoot $userSkillsContainmentRoot `
            -PlaceholderMap $userPlaceholderMap `
            -TextFileExtensionPattern $script:CodexPathConstant.TextFileExtensionPattern `
            -UnresolvedTokens (Get-CodexUnresolvedPlaceholderTokens) `
            -UnresolvedMessageFormat $script:CodexPublishMessage.PlaceholderUnresolved
        $userSkillsFilesCopied = $userPublishResult.FilesCopied
        $publishedUserSkillsRoot = $userSkillsRoot
    }
    else {
        # Without -UserScope, prune a leftover USER mirror so Codex $ does not list
        # the same skill twice (InstallRoot/skills + ~/.agents/skills).
        $userManagedManifest = Join-Path $userSkillsRoot $script:ToolkitConstant.ManagedSkillsManifestFileName
        if (Test-Path -LiteralPath $userManagedManifest) {
            if ($liveUserScope) {
                $null = Initialize-InstallRootForWrite -InstallRoot $userSkillsContainmentRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
            }

            $prunedUserSkillNames = @(
                Sync-ToolkitManagedSkillFolders `
                    -DestinationSkillsRoot $userSkillsRoot `
                    -CurrentSkillNames @() `
                    -InstallRoot $userSkillsContainmentRoot
            )
            $userSkillsPruned = $prunedUserSkillNames.Count
        }
    }

    $message = if ($userScopeEnabled) {
        ($script:CodexPublishMessage.PublishedOkWithUserScope -f $filesCopied, $homeSkillsFilesCopied, $homeSkillsRoot, $userSkillsFilesCopied, $userSkillsRoot)
    }
    else {
        ($script:CodexPublishMessage.PublishedOk -f $filesCopied, $homeSkillsFilesCopied, $homeSkillsRoot)
    }

    return [PSCustomObject]@{
        Success               = $true
        Implemented           = $true
        CommandName           = 'Publish-Skills'
        WhatIf                = $false
        UserScope             = $userScopeEnabled
        LiveUserScope         = $(if ($userScopeEnabled) { $liveUserScope } else { $false })
        InstallRoot           = $resolvedInstallRoot
        PluginRoot            = $pluginRoot
        ManifestPath          = $writtenManifest
        MarketplacePath       = $writtenMarketplace
        SkillsRoot            = $destinationSkillsRoot
        HomeSkillsRoot        = $homeSkillsRoot
        UserSkillsRoot        = $publishedUserSkillsRoot
        SourceRoot            = $sourceSkillsRoot
        FilesCopied           = $filesCopied
        HomeSkillsFilesCopied = $homeSkillsFilesCopied
        UserSkillsFilesCopied = $userSkillsFilesCopied
        UserSkillsPruned      = $userSkillsPruned
        Message               = $message
        ExitCode              = 0
    }
}
