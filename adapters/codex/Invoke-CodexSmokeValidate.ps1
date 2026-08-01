#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem-only Codex Invoke-SmokeValidate helper.

.DESCRIPTION
  Asserts InstallRoot after Codex sync:
  - plugin/.codex-plugin/plugin.json valid + plugin/skills/*/SKILL.md (TE02)
  - .agents/plugins/marketplace.json entry source.path resolves (TE03)
  - AGENTS.md at InstallRoot
  - plugin/hooks/hooks.json when hooks capable (TE04)
  - .agents/skills fixture path modeled (optional skill folders validated)
  Never invokes Codex runtime or /hooks trust UI (RN03 / TE05 out of scope).
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

function Test-CodexUserSkillsFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $UserSkillsRoot
    )

    if (-not (Test-Path -LiteralPath $UserSkillsRoot -PathType Container)) {
        return [PSCustomObject]@{
            Ok      = $false
            Message = ($script:CodexSmokeMessage.UserSkillsRootMissing -f $UserSkillsRoot)
        }
    }

    $manifestName = $script:CodexPathConstant.SkillManifestFileName
    $skillDirs = @(Get-ChildItem -LiteralPath $UserSkillsRoot -Directory -Force -ErrorAction SilentlyContinue)
    foreach ($dir in $skillDirs) {
        if ([string]::Equals($dir.Name, $script:CodexPathConstant.SharedSkillsDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $manifestPath = Join-Path $dir.FullName $manifestName
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            return [PSCustomObject]@{
                Ok      = $false
                Message = ($script:CodexSmokeMessage.UserSkillsIncomplete -f $manifestPath)
            }
        }
    }

    return [PSCustomObject]@{
        Ok      = $true
        Message = ''
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
    $userSkillsPath = $mapped.FixtureUserSkillsPath

    $checks = [ordered]@{
        PluginManifestValid   = $false
        PluginSkillsPresent   = $false
        MarketplaceEntryOk    = $false
        AgentsMdPresent       = $false
        HooksPresent          = $false
        HooksRequired         = $false
        UserSkillsFixtureOk   = $false
        SddLayoutPresent      = $false
        FilesystemOnly        = $true
        RequiresHooksTrust    = $false
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

    $agentsOk = $false
    if (Test-Path -LiteralPath $agentsPath -PathType Leaf) {
        $agentsText = [System.IO.File]::ReadAllText($agentsPath)
        $agentsOk = -not [string]::IsNullOrWhiteSpace($agentsText)
    }
    $checks.AgentsMdPresent = $agentsOk
    if (-not $agentsOk) {
        return New-CodexSmokeResult `
            -Success $false `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:CodexSmokeMessage.AgentsMdMissing -f $agentsPath) `
            -ExitCode $exitFail
    }

    $caps = Get-Capabilities
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
