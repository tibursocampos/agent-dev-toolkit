#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem-only Codex Invoke-SmokeValidate helper.

.DESCRIPTION
  Asserts InstallRoot after Codex sync:
  - plugin/.codex-plugin/plugin.json valid + plugin/skills/*/SKILL.md (TE02)
  - plugin/skills/help-skills/SKILL.md + plugin/skills/_shared/skills-catalog/CATALOG.md
  - .agents/plugins/marketplace.json entry source.path resolves (TE03)
  - InstallRoot/rules/*.md when rules capable (Publish-Policy)
  - AGENTS.md materialized (no {{…}} placeholders, no docs/ live links, dual-root paths)
  - plugin/hooks/hooks.json when hooks capable (TE04)
  - .agents/skills: absent or empty skeleton OK (plugin-only); when UserScope mirrored, assert help-skills + CATALOG
  Never invokes Codex runtime or /hooks trust UI (RN03 / TE05 out of scope).
  Live UserScope root is $HOME/.agents/skills (via Resolve-CodexUserSkillsRoot); fixture uses InstallRoot/.agents/skills.
#>

$script:CodexSmokeHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CodexSmokeHelperDirectory)) {
    $script:CodexSmokeHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function New-CodexSmokeResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Success,

        [Parameter()]
        [string] $Message = '',

        [Parameter()]
        [string] $ErrorCode = '',

        [Parameter()]
        [string] $ResolvedInstallRoot = $null,

        [Parameter()]
        [hashtable] $Checks = $null,

        [Parameter()]
        [int] $ExitCode = 0
    )

    if ($null -eq $Checks) {
        $Checks = @{}
    }

    return [PSCustomObject]@{
        Success             = $Success
        Implemented         = $true
        CommandName         = 'Invoke-SmokeValidate'
        AgentId             = $script:CodexAdapterAgentId
        FilesystemOnly      = $true
        RequiresRuntime     = $false
        RequiresHooksTrust  = $false
        ErrorCode           = $ErrorCode
        ResolvedInstallRoot = $ResolvedInstallRoot
        Checks              = [PSCustomObject]$Checks
        Message             = $Message
        ExitCode            = $ExitCode
    }
}

function Test-CodexSmokeSkillManifestPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
        return $false
    }

    $manifestName = $script:CodexPathConstant.SkillManifestFileName
    $skillDirs = @(Get-ChildItem -LiteralPath $SkillsRoot -Directory -Force -ErrorAction SilentlyContinue)
    foreach ($dir in $skillDirs) {
        if ([string]::Equals($dir.Name, $script:CodexPathConstant.SharedSkillsDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $sharedManifest = Join-Path $dir.FullName $manifestName
            if (Test-Path -LiteralPath $sharedManifest -PathType Leaf) {
                return $true
            }
            continue
        }

        $manifestPath = Join-Path $dir.FullName $manifestName
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            return $true
        }
    }

    return $false
}

function Test-CodexPluginManifestSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return $false
    }

    try {
        $raw = [System.IO.File]::ReadAllText($ManifestPath)
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $false
        }

        $json = $raw | ConvertFrom-Json
    }
    catch {
        return $false
    }

    if ($null -eq $json) {
        return $false
    }

    $props = @($json.PSObject.Properties.Name)
    foreach ($required in @('name', 'version', 'description', 'skills')) {
        if ($props -notcontains $required) {
            return $false
        }
        if ([string]::IsNullOrWhiteSpace([string]$json.$required)) {
            return $false
        }
    }

    if ($props -notcontains 'interface' -or $null -eq $json.interface) {
        return $false
    }

    $interfaceProps = @($json.interface.PSObject.Properties.Name)
    if ($interfaceProps -notcontains 'displayName') {
        return $false
    }
    if ([string]::IsNullOrWhiteSpace([string]$json.interface.displayName)) {
        return $false
    }

    return $true
}

function Get-CodexSmokeMarketplaceEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $MarketplaceJson
    )

    if ($null -eq $MarketplaceJson -or $null -eq $MarketplaceJson.plugins) {
        return , @()
    }

    return , @($MarketplaceJson.plugins)
}

function Get-CodexSmokeMarketplaceSourcePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $PluginEntry
    )

    if ($null -eq $PluginEntry.source) {
        return $null
    }

    if ($PluginEntry.source -is [string]) {
        return [string]$PluginEntry.source
    }

    if ($PluginEntry.source.PSObject.Properties.Name -contains 'path') {
        return [string]$PluginEntry.source.path
    }

    return $null
}

function Get-CodexSmokeHelpSkillsManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    return [System.IO.Path]::GetFullPath(
        (Join-Path (Join-Path $SkillsRoot $script:CodexPathConstant.HelpSkillsSkillId) $script:CodexPathConstant.SkillManifestFileName)
    )
}

function Get-CodexSmokeSkillsCatalogPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    $sharedRoot = Join-Path $SkillsRoot $script:CodexPathConstant.SharedSkillsDirectoryName
    $catalogDir = Join-Path $sharedRoot $script:CodexPathConstant.SkillsCatalogDirectoryName
    return [System.IO.Path]::GetFullPath(
        (Join-Path $catalogDir $script:CodexPathConstant.SkillsCatalogFileName)
    )
}

function Test-CodexSmokeHelpSkillsAndCatalogPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    $helpSkillsPath = Get-CodexSmokeHelpSkillsManifestPath -SkillsRoot $SkillsRoot
    if (-not (Test-Path -LiteralPath $helpSkillsPath -PathType Leaf)) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.Te02HelpSkillsMissing -f $helpSkillsPath)
        }
    }

    $catalogPath = Get-CodexSmokeSkillsCatalogPath -SkillsRoot $SkillsRoot
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.Te02SkillsCatalogMissing -f $catalogPath)
        }
    }

    return [PSCustomObject]@{
        Ok      = $true
        Message = ''
    }
}

function Test-CodexSmokeRulesPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RulesRoot,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter()]
        [System.Collections.Generic.List[string]] $MissingRelative
    )

    if ($null -eq $MissingRelative) {
        $MissingRelative = [System.Collections.Generic.List[string]]::new()
    }

    $sourcePolicyRoot = Join-Path (
        Join-Path $RepoRoot $script:CodexPathConstant.CoreDirectoryName
    ) $script:CodexPathConstant.PolicyDirectoryName

    if (-not (Test-Path -LiteralPath $RulesRoot -PathType Container)) {
        $MissingRelative.Add(($script:CodexPathConstant.RulesDirectoryName + '/'))
        return $false
    }

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot -PathType Container)) {
        $MissingRelative.Add(($script:CodexPathConstant.CoreDirectoryName + '/' + $script:CodexPathConstant.PolicyDirectoryName))
        return $false
    }

    $extension = $script:CodexPathConstant.MarkdownExtension
    $sourceFiles = @(
        Get-ChildItem -LiteralPath $sourcePolicyRoot -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -eq $extension }
    )

    if ($sourceFiles.Count -lt 1) {
        $MissingRelative.Add(($script:CodexPathConstant.CoreDirectoryName + '/' + $script:CodexPathConstant.PolicyDirectoryName + '/*' + $extension))
        return $false
    }

    $ok = $true
    foreach ($sourceFile in $sourceFiles) {
        $relative = $sourceFile.FullName.Substring($sourcePolicyRoot.Length).TrimStart('\', '/')
        $destinationPath = Join-Path $RulesRoot ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $destinationPath -PathType Leaf)) {
            $MissingRelative.Add(($script:CodexPathConstant.RulesDirectoryName + '/' + ($relative -replace '\\', '/')))
            $ok = $false
        }
    }

    return $ok
}

function Test-CodexSmokeAgentsMaterialized {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentsPath,

        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $PluginRootPath
    )

    if (-not (Test-Path -LiteralPath $AgentsPath -PathType Leaf)) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.AgentsMdMissing -f $AgentsPath)
        }
    }

    $agentsText = [System.IO.File]::ReadAllText($AgentsPath)
    if ([string]::IsNullOrWhiteSpace($agentsText)) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.AgentsMdMissing -f $AgentsPath)
        }
    }

    if ($agentsText -match $script:CodexPathConstant.PlaceholderResidualPattern) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.AgentsPlaceholderResidual -f $AgentsPath)
        }
    }

    if (
        ($agentsText -match $script:CodexPathConstant.RepoDocsBacktickLinkPattern) -or
        ($agentsText -match $script:CodexPathConstant.RepoDocsBarePathPattern)
    ) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.AgentsDocsLinkForbidden -f $AgentsPath)
        }
    }

    if (-not (Get-Command -Name Get-CodexNormalizedForwardSlashPath -ErrorAction SilentlyContinue)) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.AgentsDualRootMissing -f $AgentsPath)
        }
    }

    $installAbsolute = Get-CodexNormalizedForwardSlashPath -Path $ResolvedInstallRoot
    $pluginAbsolute = Get-CodexNormalizedForwardSlashPath -Path $PluginRootPath
    $hasDualRootHeading = $agentsText.Contains($script:CodexPathConstant.RouterDualRootHeading)
    $hasInstallPath = $agentsText.Contains($installAbsolute)
    $hasPluginPath = $agentsText.Contains($pluginAbsolute)

    if (-not ($hasDualRootHeading -and $hasInstallPath -and $hasPluginPath)) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.AgentsDualRootMissing -f $AgentsPath)
        }
    }

    return [PSCustomObject]@{
        Ok      = $true
        Message = ''
    }
}

function Test-CodexUserSkillsFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $UserSkillsRoot
    )

    # Absent root is valid: default Publish-Skills is plugin-only (live ~/.codex has no InstallRoot/.agents/skills).
    if (-not (Test-Path -LiteralPath $UserSkillsRoot -PathType Container)) {
        return [PSCustomObject]@{
            Ok       = $true
            Mirrored = $false
            Message  = ''
        }
    }

    $manifestName = $script:CodexPathConstant.SkillManifestFileName
    $skillDirs = @(Get-ChildItem -LiteralPath $UserSkillsRoot -Directory -Force -ErrorAction SilentlyContinue)
    $kebabSkillDirs = @(
        $skillDirs | Where-Object {
            -not [string]::Equals($_.Name, $script:CodexPathConstant.SharedSkillsDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)
        }
    )

    # Empty skeleton (.gitkeep only) is valid: default Publish-Skills is plugin-only.
    if ($kebabSkillDirs.Count -lt 1) {
        return [PSCustomObject]@{
            Ok       = $true
            Mirrored = $false
            Message  = ''
        }
    }

    foreach ($dir in $kebabSkillDirs) {
        $manifestPath = Join-Path $dir.FullName $manifestName
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            return [PSCustomObject]@{
                Ok       = $false
                Mirrored = $true
                Message  = ($script:CodexSmokeMessage.UserSkillsIncomplete -f $manifestPath)
            }
        }
    }

    $helpSkillsPath = Get-CodexSmokeHelpSkillsManifestPath -SkillsRoot $UserSkillsRoot
    if (-not (Test-Path -LiteralPath $helpSkillsPath -PathType Leaf)) {
        return [PSCustomObject]@{
            Ok       = $false
            Mirrored = $true
            Message  = ($script:CodexSmokeMessage.UserSkillsHelpSkillsMissing -f $helpSkillsPath)
        }
    }

    $catalogPath = Get-CodexSmokeSkillsCatalogPath -SkillsRoot $UserSkillsRoot
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
        return [PSCustomObject]@{
            Ok       = $false
            Mirrored = $true
            Message  = ($script:CodexSmokeMessage.UserSkillsCatalogMissing -f $catalogPath)
        }
    }

    return [PSCustomObject]@{
        Ok       = $true
        Mirrored = $true
        Message  = ''
    }
}

function Invoke-CodexSmokeValidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    $exitFail = [int]$script:CodexPathConstant.SmokeExitFailure
    $exitOk = [int]$script:CodexPathConstant.SmokeExitSuccess

    $resolvedInstallRoot = $null
    try {
        # Dot-source in this function scope so Resolve-InstallRoot remains callable here
        # (nested Initialize-CodexInstallRootResolver would drop the function on return).
        $repoRoot = Get-CodexAdapterRepoRoot
        $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
        . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    }
    catch {
        $detail = $_.Exception.Message
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe01Code `
            -Message ($script:CodexSmokeMessage.Te01InvalidInstallRoot -f $detail) `
            -ExitCode $exitFail
    }

    $mapped = Get-CodexMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $manifestPath = $mapped.FixturePluginManifestPath
    $pluginSkillsPath = $mapped.FixturePluginSkillsPath
    $marketplaceDir = $mapped.FixtureMarketplacePath
    $marketplacePath = Join-Path $marketplaceDir $script:CodexPathConstant.MarketplaceFileName
    $agentsPath = $mapped.FixtureProjectAgentsPath
    $hooksPath = Join-Path $mapped.FixturePluginHooksPath $script:CodexPathConstant.HooksFileName
    $userSkillsPath = Resolve-CodexUserSkillsRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $rulesPath = Join-Path $resolvedInstallRoot $script:CodexPathConstant.RulesDirectoryName

    $checks = [ordered]@{
        PluginManifestValid      = $false
        PluginSkillsPresent      = $false
        HelpSkillsCatalogPresent = $false
        MarketplaceEntryOk       = $false
        RulesPresent             = $false
        RulesRequired            = $false
        AgentsMdPresent          = $false
        AgentsMaterializedOk     = $false
        HooksPresent             = $false
        HooksRequired            = $false
        UserSkillsFixtureOk      = $false
        UserSkillsMirrored       = $false
        SddLayoutPresent         = $false
        FilesystemOnly           = $true
        RequiresHooksTrust       = $false
    }

    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe02Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.Te02PluginManifestMissing -f $manifestPath) `
            -ExitCode $exitFail
    }

    $manifestOk = Test-CodexPluginManifestSchema -ManifestPath $manifestPath
    $checks.PluginManifestValid = $manifestOk
    if (-not $manifestOk) {
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe02Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.Te02PluginManifestInvalid -f $manifestPath) `
            -ExitCode $exitFail
    }

    $skillsOk = Test-CodexSmokeSkillManifestPresent -SkillsRoot $pluginSkillsPath
    $checks.PluginSkillsPresent = $skillsOk
    if (-not $skillsOk) {
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe02Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.Te02PluginSkillsMissing -f $pluginSkillsPath) `
            -ExitCode $exitFail
    }

    $catalogCheck = Test-CodexSmokeHelpSkillsAndCatalogPresent -SkillsRoot $pluginSkillsPath
    $checks.HelpSkillsCatalogPresent = [bool]$catalogCheck.Ok
    if (-not $catalogCheck.Ok) {
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe02Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message $catalogCheck.Message `
            -ExitCode $exitFail
    }

    if (-not (Test-Path -LiteralPath $marketplacePath -PathType Leaf)) {
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe03Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.Te03MarketplaceMissing -f $marketplacePath) `
            -ExitCode $exitFail
    }

    $marketplaceJson = $null
    try {
        $marketplaceJson = [System.IO.File]::ReadAllText($marketplacePath) | ConvertFrom-Json
    }
    catch {
        $marketplaceJson = $null
    }

    $entries = @()
    if ($null -ne $marketplaceJson) {
        $entries = @(Get-CodexSmokeMarketplaceEntries -MarketplaceJson $marketplaceJson)
    }

    if ($null -eq $marketplaceJson -or $entries.Count -lt 1) {
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe03Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.Te03MarketplaceInvalid -f $marketplacePath) `
            -ExitCode $exitFail
    }

    $entryOk = $false
    $brokenDetail = 'no resolvable source.path'
    $brokenEntryName = '(unknown)'
    foreach ($entry in $entries) {
        $entryName = if ($null -ne $entry.name) { [string]$entry.name } else { '(unnamed)' }
        $sourcePath = Get-CodexSmokeMarketplaceSourcePath -PluginEntry $entry
        if ([string]::IsNullOrWhiteSpace($sourcePath)) {
            $brokenEntryName = $entryName
            $brokenDetail = 'source.path missing'
            continue
        }

        try {
            $resolvedPlugin = Resolve-CodexMarketplacePluginPath -InstallRoot $resolvedInstallRoot -SourcePath $sourcePath
            if (-not (Test-Path -LiteralPath $resolvedPlugin -PathType Container)) {
                $brokenEntryName = $entryName
                $brokenDetail = ("resolved path does not exist: {0}" -f $resolvedPlugin)
                continue
            }

            $expectedPlugin = [System.IO.Path]::GetFullPath($mapped.FixturePluginRootPath)
            if (-not [string]::Equals($resolvedPlugin, $expectedPlugin, [System.StringComparison]::OrdinalIgnoreCase)) {
                # Relative path may still be valid if it points at an existing plugin tree.
                $pluginManifestUnderEntry = Join-Path $resolvedPlugin (
                    $script:CodexPathConstant.PluginManifestDirectoryName + [System.IO.Path]::DirectorySeparatorChar + $script:CodexPathConstant.PluginManifestFileName
                )
                if (-not (Test-Path -LiteralPath $pluginManifestUnderEntry -PathType Leaf)) {
                    $brokenEntryName = $entryName
                    $brokenDetail = ("resolved plugin root lacks .codex-plugin/plugin.json: {0}" -f $resolvedPlugin)
                    continue
                }
            }

            $entryOk = $true
            break
        }
        catch {
            $brokenEntryName = $entryName
            $brokenDetail = $_.Exception.Message
        }
    }

    $checks.MarketplaceEntryOk = $entryOk
    if (-not $entryOk) {
        return New-CodexSmokeResult `
            -Success $false `
            -ErrorCode $script:CodexPathConstant.SmokeTe03Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.Te03MarketplaceEntryBroken -f $brokenEntryName, $marketplacePath, $brokenDetail) `
            -ExitCode $exitFail
    }

    $agentsCheck = Test-CodexSmokeAgentsMaterialized `
        -AgentsPath $agentsPath `
        -ResolvedInstallRoot $resolvedInstallRoot `
        -PluginRootPath $mapped.FixturePluginRootPath
    $checks.AgentsMdPresent = (Test-Path -LiteralPath $agentsPath -PathType Leaf)
    $checks.AgentsMaterializedOk = [bool]$agentsCheck.Ok
    if (-not $agentsCheck.Ok) {
        return New-CodexSmokeResult `
            -Success $false `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message $agentsCheck.Message `
            -ExitCode $exitFail
    }

    $caps = Get-Capabilities
    $rulesRequired = ($null -ne $caps) -and ($null -ne $caps.Capabilities) -and ($caps.Capabilities.rules -eq $true)
    $checks.RulesRequired = [bool]$rulesRequired
    if ($rulesRequired) {
        $rulesMissing = [System.Collections.Generic.List[string]]::new()
        $rulesOk = Test-CodexSmokeRulesPresent -RulesRoot $rulesPath -RepoRoot $repoRoot -MissingRelative $rulesMissing
        $checks.RulesPresent = $rulesOk
        if (-not $rulesOk) {
            $listText = ($rulesMissing.ToArray() -join ', ')
            return New-CodexSmokeResult `
                -Success $false `
                -ResolvedInstallRoot $resolvedInstallRoot `
                -Checks $checks `
                -Message ($script:CodexSmokeMessage.RulesMissing -f $listText) `
                -ExitCode $exitFail
        }
    }
    else {
        $checks.RulesPresent = Test-Path -LiteralPath $rulesPath -PathType Container
    }

    $hooksRequired = ($null -ne $caps) -and ($null -ne $caps.Capabilities) -and ($caps.Capabilities.hooks -eq $true)
    $checks.HooksRequired = [bool]$hooksRequired

    if ($hooksRequired) {
        if (-not (Test-Path -LiteralPath $hooksPath -PathType Leaf)) {
            return New-CodexSmokeResult `
                -Success $false `
                -ErrorCode $script:CodexPathConstant.SmokeTe04Code `
                -ResolvedInstallRoot $resolvedInstallRoot `
                -Checks $checks `
                -Message ($script:CodexSmokeMessage.Te04HooksMissing -f $hooksPath) `
                -ExitCode $exitFail
        }

        try {
            $null = [System.IO.File]::ReadAllText($hooksPath) | ConvertFrom-Json
            $checks.HooksPresent = $true
        }
        catch {
            return New-CodexSmokeResult `
                -Success $false `
                -ErrorCode $script:CodexPathConstant.SmokeTe04Code `
                -ResolvedInstallRoot $resolvedInstallRoot `
                -Checks $checks `
                -Message ($script:CodexSmokeMessage.Te04HooksInvalid -f $hooksPath) `
                -ExitCode $exitFail
        }
    }
    else {
        $checks.HooksPresent = Test-Path -LiteralPath $hooksPath -PathType Leaf
    }

    $userSkillsCheck = Test-CodexUserSkillsFixture -UserSkillsRoot $userSkillsPath
    $checks.UserSkillsFixtureOk = [bool]$userSkillsCheck.Ok
    $checks.UserSkillsMirrored = [bool]$userSkillsCheck.Mirrored
    if (-not $userSkillsCheck.Ok) {
        return New-CodexSmokeResult `
            -Success $false `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message $userSkillsCheck.Message `
            -ExitCode $exitFail
    }

    $sddMissing = [System.Collections.Generic.List[string]]::new()
    $sddOk = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $sddMissing
    $checks.SddLayoutPresent = $sddOk
    if (-not $sddOk) {
        $listText = ($sddMissing.ToArray() -join ', ')
        return New-CodexSmokeResult `
            -Success $false `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.SddLayoutMissing -f $listText) `
            -ExitCode $exitFail
    }

    $passMessage = ($script:CodexSmokeMessage.Passed -f $resolvedInstallRoot) + ' ' + $script:CodexSmokeMessage.FilesystemOnlyNote
    return New-CodexSmokeResult `
        -Success $true `
        -ResolvedInstallRoot $resolvedInstallRoot `
        -Checks $checks `
        -Message $passMessage `
        -ExitCode $exitOk
}
