#Requires -Version 5.1
# Tests:
#   Should_ListOfficialRoots_When_GetInstallRootsCalled
#   Should_DocumentLegacyBridge_When_AdaptersDocRead
#   Should_ReturnHooksCapability_When_GetCapabilitiesCalled
#   Should_ResolveSubagentsOverride_When_EnvSet
#   Should_ResolveSubagentsNone_When_HostUnverifiable
#   Should_ResolveSubagentsNative_When_ProductVersionAtLeastTwo
#   Should_ResolveSubagentsNone_When_ProductVersionPreTwo
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'

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

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-AntigravityOfficialLayoutPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$modulePath = Join-Path $repoRoot 'adapters\antigravity\AntigravityAdapter.ps1'
$adaptersDocPath = Join-Path $repoRoot 'docs\ADAPTERS.md'
$antigravityAgentId = 'antigravity'

if (-not (Test-Path -LiteralPath $modulePath)) {
    Write-Fail -TestName 'Assert-AntigravityOfficialLayoutPreconditions' -Reason ("module missing: {0}" -f $modulePath)
}

if (-not (Test-Path -LiteralPath $adaptersDocPath)) {
    Write-Fail -TestName 'Assert-AntigravityOfficialLayoutPreconditions' -Reason ("docs missing: {0}" -f $adaptersDocPath)
}

. $modulePath

# --- Should_ListOfficialRoots_When_GetInstallRootsCalled ---
$rootsName = 'Should_ListOfficialRoots_When_GetInstallRootsCalled'
$roots = Get-InstallRoots -AgentId $antigravityAgentId

if ($null -eq $roots -or $roots.Implemented -ne $true -or $roots.Success -ne $true) {
    Write-Fail -TestName $rootsName -Reason 'Get-InstallRoots must return Implemented=true Success=true'
}

if ($roots.AgentId -ne $antigravityAgentId) {
    Write-Fail -TestName $rootsName -Reason ("expected AgentId {0}, got {1}" -f $antigravityAgentId, $roots.AgentId)
}

$expectedRelative = '.gemini'
if ($roots.OfficialUserRootRelativePath -ne $expectedRelative) {
    Write-Fail -TestName $rootsName -Reason ("expected OfficialUserRootRelativePath '{0}', got '{1}'" -f $expectedRelative, $roots.OfficialUserRootRelativePath)
}

$requiredConfigPaths = @{
    OfficialSkillsRelativePath     = 'config/skills'
    OfficialPluginsRelativePath    = 'config/plugins'
    OfficialHooksRelativePath      = 'config/hooks'
    OfficialSkillsJsonRelativePath = 'config/skills.json'
    OfficialAgentsMdRelativePath   = 'config/AGENTS.md'
    OfficialGeminiMdRelativePath   = 'config/GEMINI.md'
}

foreach ($key in $requiredConfigPaths.Keys) {
    $actual = [string]$roots.$key
    $expected = $requiredConfigPaths[$key]
    if ($actual -ne $expected) {
        Write-Fail -TestName $rootsName -Reason ("{0}: expected '{1}', got '{2}'" -f $key, $expected, $actual)
    }
}

if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialConfigDescription)) {
    Write-Fail -TestName $rootsName -Reason 'OfficialConfigDescription must describe config layout'
}

if ($roots.OverrideParameter -ne 'InstallRoot') {
    Write-Fail -TestName $rootsName -Reason 'OverrideParameter must be InstallRoot'
}

$userHome = [Environment]::GetFolderPath('UserProfile')
if (-not [string]::IsNullOrWhiteSpace($userHome)) {
    $expectedFull = Join-Path $userHome $expectedRelative
    if ($roots.OfficialUserRootPath -ne $expectedFull) {
        Write-Fail -TestName $rootsName -Reason ("OfficialUserRootPath expected '{0}', got '{1}'" -f $expectedFull, $roots.OfficialUserRootPath)
    }
}

Write-Pass -TestName $rootsName

# --- Should_DocumentLegacyBridge_When_AdaptersDocRead ---
$docName = 'Should_DocumentLegacyBridge_When_AdaptersDocRead'
$docText = Get-Content -LiteralPath $adaptersDocPath -Raw

if ($docText -notmatch '(?i)Antigravity') {
    Write-Fail -TestName $docName -Reason 'docs/ADAPTERS.md must contain an Antigravity section'
}

if ($docText -notmatch 'antigravity-ide/plugins') {
    Write-Fail -TestName $docName -Reason 'docs must mention legacy bridge path antigravity-ide/plugins'
}

if ($docText -notmatch '(?i)legacy|bridge|non-default|opt-in') {
    Write-Fail -TestName $docName -Reason 'docs must describe legacy bridge as non-default / opt-in'
}

if ($docText -notmatch 'config/skills') {
    Write-Fail -TestName $docName -Reason 'docs must mention official config/skills layout'
}

$legacyFromModule = [string]$roots.LegacyBridgeRelativePath
if ($legacyFromModule -ne 'antigravity-ide/plugins') {
    Write-Fail -TestName $docName -Reason ("Get-InstallRoots LegacyBridgeRelativePath expected antigravity-ide/plugins, got '{0}'" -f $legacyFromModule)
}

if ([string]::IsNullOrWhiteSpace([string]$roots.LegacyBridgeDescription) -or $roots.LegacyBridgeDescription -notmatch '(?i)non-default|opt-in|not a CI') {
    Write-Fail -TestName $docName -Reason 'LegacyBridgeDescription must state non-default / not CI gate'
}

Write-Pass -TestName $docName

# --- Should_ReturnHooksCapability_When_GetCapabilitiesCalled ---
$capsName = 'Should_ReturnHooksCapability_When_GetCapabilitiesCalled'
$caps = Get-Capabilities -AgentId $antigravityAgentId

if ($null -eq $caps -or $caps.Implemented -ne $true) {
    Write-Fail -TestName $capsName -Reason 'Get-Capabilities must return Implemented=true'
}

if ($caps.AgentId -ne $antigravityAgentId) {
    Write-Fail -TestName $capsName -Reason ("expected AgentId {0}, got {1}" -f $antigravityAgentId, $caps.AgentId)
}

$c = $caps.Capabilities
if ($null -eq $c) {
    Write-Fail -TestName $capsName -Reason 'Capabilities object missing'
}

if ($c.skills -ne $true -or $c.rules -ne $true -or $c.router -ne $true -or $c.plugin -ne $true) {
    Write-Fail -TestName $capsName -Reason 'expected skills/rules/router/plugin = true'
}

if ($c.hooks -ne $false) {
    Write-Fail -TestName $capsName -Reason 'hooks must be false (honest: no native shell-hook parity)'
}

if ($c.sdd -ne $false) {
    Write-Fail -TestName $capsName -Reason 'sdd must be false for Antigravity MVP capability honesty'
}

if ([string]::IsNullOrWhiteSpace([string]$caps.Message) -or $caps.Message -notmatch '(?i)hooks') {
    Write-Fail -TestName $capsName -Reason 'Capabilities Message must mention hooks honesty'
}

Write-Pass -TestName $capsName

# --- Subagents probe (fail-closed + override) ---
$subagentsOverrideEnv = 'ADT_ANTIGRAVITY_SUBAGENTS'
$productVersionEnv = 'ADT_ANTIGRAVITY_PRODUCT_VERSION'
$savedOverride = [Environment]::GetEnvironmentVariable($subagentsOverrideEnv)
$savedProduct = [Environment]::GetEnvironmentVariable($productVersionEnv)

function Restore-AntigravitySubagentsProbeEnv {
    if ($null -eq $savedOverride) {
        [Environment]::SetEnvironmentVariable($subagentsOverrideEnv, $null)
    }
    else {
        [Environment]::SetEnvironmentVariable($subagentsOverrideEnv, $savedOverride)
    }

    if ($null -eq $savedProduct) {
        [Environment]::SetEnvironmentVariable($productVersionEnv, $null)
    }
    else {
        [Environment]::SetEnvironmentVariable($productVersionEnv, $savedProduct)
    }
}

try {
    $overrideNativeName = 'Should_ResolveSubagentsOverride_When_EnvSet'
    [Environment]::SetEnvironmentVariable($productVersionEnv, $null)
    [Environment]::SetEnvironmentVariable($subagentsOverrideEnv, 'native')
    $capsNative = Get-Capabilities -AgentId $antigravityAgentId
    if ([string]$capsNative.Capabilities.subagents -ne 'native') {
        Write-Fail -TestName $overrideNativeName -Reason ("expected subagents=native with override, got '{0}'" -f $capsNative.Capabilities.subagents)
    }

    [Environment]::SetEnvironmentVariable($subagentsOverrideEnv, 'none')
    $capsNoneOverride = Get-Capabilities -AgentId $antigravityAgentId
    if ([string]$capsNoneOverride.Capabilities.subagents -ne 'none') {
        Write-Fail -TestName $overrideNativeName -Reason ("expected subagents=none with override, got '{0}'" -f $capsNoneOverride.Capabilities.subagents)
    }

    Write-Pass -TestName $overrideNativeName

    $unverifiableName = 'Should_ResolveSubagentsNone_When_HostUnverifiable'
    [Environment]::SetEnvironmentVariable($subagentsOverrideEnv, $null)
    [Environment]::SetEnvironmentVariable($productVersionEnv, $null)
    $capsUnverifiable = Get-Capabilities -AgentId $antigravityAgentId
    $agyPresent = $null -ne (Get-Command -Name 'agy' -ErrorAction SilentlyContinue)
    if (-not $agyPresent) {
        if ([string]$capsUnverifiable.Capabilities.subagents -ne 'none') {
            Write-Fail -TestName $unverifiableName -Reason ("without agy/override expected subagents=none, got '{0}'" -f $capsUnverifiable.Capabilities.subagents)
        }
    }
    else {
        $effective = [string]$capsUnverifiable.Capabilities.subagents
        if (($effective -ne 'native') -and ($effective -ne 'none')) {
            Write-Fail -TestName $unverifiableName -Reason ("with agy present subagents must be native|none, got '{0}'" -f $effective)
        }
    }

    Write-Pass -TestName $unverifiableName

    $productNativeName = 'Should_ResolveSubagentsNative_When_ProductVersionAtLeastTwo'
    [Environment]::SetEnvironmentVariable($subagentsOverrideEnv, $null)
    [Environment]::SetEnvironmentVariable($productVersionEnv, '2.0.0')
    $capsProductNative = Get-Capabilities -AgentId $antigravityAgentId
    if ([string]$capsProductNative.Capabilities.subagents -ne 'native') {
        Write-Fail -TestName $productNativeName -Reason ("product 2.0.0 expected native, got '{0}'" -f $capsProductNative.Capabilities.subagents)
    }

    Write-Pass -TestName $productNativeName

    $productPreName = 'Should_ResolveSubagentsNone_When_ProductVersionPreTwo'
    [Environment]::SetEnvironmentVariable($productVersionEnv, '1.9.0')
    $capsProductPre = Get-Capabilities -AgentId $antigravityAgentId
    if ([string]$capsProductPre.Capabilities.subagents -ne 'none') {
        Write-Fail -TestName $productPreName -Reason ("product 1.9.0 expected none, got '{0}'" -f $capsProductPre.Capabilities.subagents)
    }

    Write-Pass -TestName $productPreName
}
finally {
    Restore-AntigravitySubagentsProbeEnv
}

Write-Host 'Assert-AntigravityOfficialLayout: ALL PASS'
exit 0
