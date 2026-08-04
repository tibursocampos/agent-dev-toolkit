#Requires -Version 5.1
# Tests:
#   Should_WriteMarketplaceEntry_When_SyncCodex
#   Should_ResolvePluginPathFromMarketplace_When_EntryPresent
#   Should_PublishHelpSkillsAndCatalog_When_SyncCodex
#   Should_MirrorHelpSkillsCatalog_When_UserScope
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'
$resolveInstallRootScript = Join-Path $scriptsRoot '_lib\Resolve-InstallRoot.ps1'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

function Get-CodexMarketplacePluginEntries {
    param([Parameter(Mandatory = $true)] $MarketplaceJson)

    if ($null -eq $MarketplaceJson.plugins) {
        return , @()
    }

    # Comma prevents PowerShell from unwrapping a single-element array on return.
    return , @($MarketplaceJson.plugins)
}

function Get-CodexMarketplaceSourcePath {
    param([Parameter(Mandatory = $true)] $PluginEntry)

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

foreach ($required in @($repoRootScript, $resolveInstallRootScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CodexPluginLayoutPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$codexModulePath = Join-Path $repoRoot 'adapters\codex\CodexAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\codex'
$pluginRoot = Join-Path $fixtureInstallRoot 'plugin'
$manifestPath = Join-Path $pluginRoot '.codex-plugin\plugin.json'
$publishedSkillsRoot = Join-Path $pluginRoot 'skills'
$marketplacePath = Join-Path $fixtureInstallRoot '.agents\plugins\marketplace.json'
$userSkillsRoot = Join-Path $fixtureInstallRoot '.agents\skills'
$helpSkillsPluginPath = Join-Path $publishedSkillsRoot 'help-skills\SKILL.md'
$catalogPluginPath = Join-Path $publishedSkillsRoot '_shared\skills-catalog\CATALOG.md'
$operatorPluginPath = Join-Path $publishedSkillsRoot '_shared\skills-catalog\OPERATOR.md'
$helpSkillsUserPath = Join-Path $userSkillsRoot 'help-skills\SKILL.md'
$catalogUserPath = Join-Path $userSkillsRoot '_shared\skills-catalog\CATALOG.md'
$operatorUserPath = Join-Path $userSkillsRoot '_shared\skills-catalog\OPERATOR.md'
$expectedSourcePath = './plugin'
$expectedPluginName = 'agent-dev-toolkit'

if (-not (Test-Path -LiteralPath $codexModulePath)) {
    Write-Fail -TestName 'Assert-CodexPluginLayoutPreconditions' -Reason ("missing Codex module: {0}" -f $codexModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-CodexPluginLayoutPreconditions' -Reason ("missing Codex fixture: {0}" -f $fixtureInstallRoot)
}

. $codexModulePath

function Clear-CodexPublishedArtifacts {
    if (Test-Path -LiteralPath $publishedSkillsRoot) {
        Get-ChildItem -LiteralPath $publishedSkillsRoot -Force | Remove-Item -Recurse -Force
    }
    if (Test-Path -LiteralPath $manifestPath) {
        Remove-Item -LiteralPath $manifestPath -Force
    }
    if (Test-Path -LiteralPath $marketplacePath) {
        Remove-Item -LiteralPath $marketplacePath -Force
    }
    if (Test-Path -LiteralPath $userSkillsRoot) {
        Get-ChildItem -LiteralPath $userSkillsRoot -Force | Remove-Item -Recurse -Force
    }
}

function Restore-CodexFixtureGitkeep {
    param([Parameter(Mandatory = $true)][string] $DirectoryPath)

    if (-not (Test-Path -LiteralPath $DirectoryPath -PathType Container)) {
        New-Item -ItemType Directory -Path $DirectoryPath -Force | Out-Null
    }

    $gitkeepPath = Join-Path $DirectoryPath '.gitkeep'
    if (-not (Test-Path -LiteralPath $gitkeepPath -PathType Leaf)) {
        New-Item -ItemType File -Path $gitkeepPath -Force | Out-Null
    }
}

Clear-CodexPublishedArtifacts

# --- Should_WriteMarketplaceEntry_When_SyncCodex ---
$writeTestName = 'Should_WriteMarketplaceEntry_When_SyncCodex'

$publishResult = Publish-Skills -InstallRoot $fixtureInstallRoot
if ($null -eq $publishResult -or $publishResult.Success -ne $true -or $publishResult.Implemented -ne $true) {
    Write-Fail -TestName $writeTestName -Reason 'Publish-Skills must succeed with Implemented = true'
}
if (-not (Test-Path -LiteralPath $marketplacePath)) {
    Write-Fail -TestName $writeTestName -Reason ("marketplace.json missing: {0}" -f $marketplacePath)
}

$normalizedMarketplace = [System.IO.Path]::GetFullPath([string]$publishResult.MarketplacePath)
$expectedMarketplace = [System.IO.Path]::GetFullPath($marketplacePath)
if (-not [string]::Equals($normalizedMarketplace, $expectedMarketplace, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $writeTestName -Reason ("MarketplacePath mismatch: {0}" -f $publishResult.MarketplacePath)
}

$marketplaceJson = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$marketplaceJson.name)) {
    Write-Fail -TestName $writeTestName -Reason 'marketplace.json name is required'
}
if ($null -eq $marketplaceJson.interface -or [string]::IsNullOrWhiteSpace([string]$marketplaceJson.interface.displayName)) {
    Write-Fail -TestName $writeTestName -Reason 'marketplace.json interface.displayName is required'
}

$pluginEntries = Get-CodexMarketplacePluginEntries -MarketplaceJson $marketplaceJson
if ($pluginEntries.Count -lt 1) {
    Write-Fail -TestName $writeTestName -Reason 'marketplace.json plugins[] must contain at least one entry'
}

$toolkitEntry = $pluginEntries | Where-Object { [string]$_.name -eq $expectedPluginName } | Select-Object -First 1
if ($null -eq $toolkitEntry) {
    Write-Fail -TestName $writeTestName -Reason ("marketplace plugins[] missing entry name={0}" -f $expectedPluginName)
}

$sourcePath = Get-CodexMarketplaceSourcePath -PluginEntry $toolkitEntry
if ([string]::IsNullOrWhiteSpace($sourcePath)) {
    Write-Fail -TestName $writeTestName -Reason 'plugin entry source.path is required'
}
if (-not $sourcePath.StartsWith('./')) {
    Write-Fail -TestName $writeTestName -Reason ("source.path must be ./prefixed, got: {0}" -f $sourcePath)
}
if ($sourcePath -ne $expectedSourcePath) {
    Write-Fail -TestName $writeTestName -Reason ("expected source.path '{0}', got: {1}" -f $expectedSourcePath, $sourcePath)
}
if ($null -eq $toolkitEntry.policy -or [string]::IsNullOrWhiteSpace([string]$toolkitEntry.policy.installation)) {
    Write-Fail -TestName $writeTestName -Reason 'plugin entry policy.installation is required'
}
if ([string]::IsNullOrWhiteSpace([string]$toolkitEntry.category)) {
    Write-Fail -TestName $writeTestName -Reason 'plugin entry category is required'
}

# Idempotent re-publish keeps marketplace
$second = Publish-Skills -InstallRoot $fixtureInstallRoot
if ($null -eq $second -or $second.Success -ne $true) {
    Write-Fail -TestName $writeTestName -Reason 're-publish must remain successful (idempotent)'
}
if (-not (Test-Path -LiteralPath $marketplacePath)) {
    Write-Fail -TestName $writeTestName -Reason 'marketplace.json must remain after idempotent re-publish'
}

Write-Pass -TestName $writeTestName

# --- Should_ResolvePluginPathFromMarketplace_When_EntryPresent ---
$resolveTestName = 'Should_ResolvePluginPathFromMarketplace_When_EntryPresent'

$relative = $sourcePath.Substring(2).TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
$resolvedPluginPath = [System.IO.Path]::GetFullPath((Join-Path $fixtureInstallRoot $relative))
$expectedPluginPath = [System.IO.Path]::GetFullPath($pluginRoot)
if (-not [string]::Equals($resolvedPluginPath, $expectedPluginPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $resolveTestName -Reason ("resolved path mismatch: {0}" -f $resolvedPluginPath)
}
if (-not (Test-Path -LiteralPath $resolvedPluginPath)) {
    Write-Fail -TestName $resolveTestName -Reason ("marketplace source.path does not exist: {0}" -f $resolvedPluginPath)
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Fail -TestName $resolveTestName -Reason ("plugin manifest missing at resolved path: {0}" -f $manifestPath)
}

$pluginManifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ([string]$pluginManifest.name -ne $expectedPluginName) {
    Write-Fail -TestName $resolveTestName -Reason ("resolved plugin.json name mismatch: {0}" -f $pluginManifest.name)
}

Write-Pass -TestName $resolveTestName

# --- Should_PublishHelpSkillsAndCatalog_When_SyncCodex ---
$helpCatalogTestName = 'Should_PublishHelpSkillsAndCatalog_When_SyncCodex'

if (-not (Test-Path -LiteralPath $helpSkillsPluginPath -PathType Leaf)) {
    Write-Fail -TestName $helpCatalogTestName -Reason ("plugin help-skills SKILL.md missing: {0}" -f $helpSkillsPluginPath)
}
if (-not (Test-Path -LiteralPath $catalogPluginPath -PathType Leaf)) {
    Write-Fail -TestName $helpCatalogTestName -Reason ("plugin skills catalog missing: {0}" -f $catalogPluginPath)
}
if (-not (Test-Path -LiteralPath $operatorPluginPath -PathType Leaf)) {
    Write-Fail -TestName $helpCatalogTestName -Reason ("plugin skills OPERATOR.md missing: {0}" -f $operatorPluginPath)
}

Write-Pass -TestName $helpCatalogTestName

# --- Should_MirrorHelpSkillsCatalog_When_UserScope ---
$userScopeTestName = 'Should_MirrorHelpSkillsCatalog_When_UserScope'

$userScopePublish = Publish-Skills -InstallRoot $fixtureInstallRoot -UserScope
if ($null -eq $userScopePublish -or $userScopePublish.Success -ne $true -or $userScopePublish.Implemented -ne $true) {
    Write-Fail -TestName $userScopeTestName -Reason 'Publish-Skills -UserScope must succeed with Implemented = true'
}
if (-not (Test-Path -LiteralPath $helpSkillsUserPath -PathType Leaf)) {
    Write-Fail -TestName $userScopeTestName -Reason ("USER-scope help-skills SKILL.md missing: {0}" -f $helpSkillsUserPath)
}
if (-not (Test-Path -LiteralPath $catalogUserPath -PathType Leaf)) {
    Write-Fail -TestName $userScopeTestName -Reason ("USER-scope skills catalog missing: {0}" -f $catalogUserPath)
}
if (-not (Test-Path -LiteralPath $operatorUserPath -PathType Leaf)) {
    Write-Fail -TestName $userScopeTestName -Reason ("USER-scope skills OPERATOR.md missing: {0}" -f $operatorUserPath)
}
if ($null -eq $userScopePublish.UserScope -or $userScopePublish.UserScope -ne $true) {
    Write-Fail -TestName $userScopeTestName -Reason 'Publish-Skills -UserScope result must report UserScope = true'
}
if ($null -ne $userScopePublish.PSObject.Properties['LiveUserScope'] -and $userScopePublish.LiveUserScope -eq $true) {
    Write-Fail -TestName $userScopeTestName -Reason 'fixture InstallRoot UserScope must not report LiveUserScope = true'
}

Write-Pass -TestName $userScopeTestName

# Keep fixture seed lean: drop published artifacts (dirs from Step 2 remain).
Clear-CodexPublishedArtifacts
Restore-CodexFixtureGitkeep -DirectoryPath $publishedSkillsRoot
Restore-CodexFixtureGitkeep -DirectoryPath (Join-Path $pluginRoot 'hooks')
Restore-CodexFixtureGitkeep -DirectoryPath $userSkillsRoot
Restore-CodexFixtureGitkeep -DirectoryPath (Split-Path -Parent $marketplacePath)

Write-Host 'Assert-CodexPluginLayout: ALL PASS'
exit 0
