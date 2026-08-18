#Requires -Version 5.1
# Tests:
#   Should_MapOpenHandsRootsUnderFixture_When_InstallRootProvided
#   Should_Fail_When_InstallRootUnderUserProfileWithoutAllowUserHome
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

foreach ($required in @($repoRootScript, $resolveInstallRootScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-OpenHandsNativeLayoutPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript
. $resolveInstallRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$openHandsAgentId = 'openhands'
$openHandsModulePath = Join-Path $repoRoot 'adapters\openhands\OpenHandsAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\openhands'
$userProfile = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-OpenHandsNativeLayoutPreconditions' -Reason 'USERPROFILE is not set'
}

if (-not (Test-Path -LiteralPath $openHandsModulePath)) {
    Write-Fail -TestName 'Assert-OpenHandsNativeLayoutPreconditions' -Reason ("missing OpenHands module: {0}" -f $openHandsModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-OpenHandsNativeLayoutPreconditions' -Reason ("missing OpenHands fixture: {0}" -f $fixtureInstallRoot)
}

$expectedRelativeDirs = @(
    (Join-Path '.agents' 'skills'),
    (Join-Path '.agents' 'agents'),
    (Join-Path '.openhands' 'hooks'),
    '.plugin'
)

foreach ($rel in $expectedRelativeDirs) {
    $full = Join-Path $fixtureInstallRoot $rel
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-OpenHandsNativeLayoutPreconditions' -Reason ("fixture skeleton missing: {0}" -f $full)
    }
}

. $openHandsModulePath

# --- Should_MapOpenHandsRootsUnderFixture_When_InstallRootProvided ---
$mapName = 'Should_MapOpenHandsRootsUnderFixture_When_InstallRootProvided'
$roots = Get-InstallRoots -AgentId $openHandsAgentId -InstallRoot $fixtureInstallRoot
if ($null -eq $roots -or $roots.Implemented -ne $true -or $roots.Success -ne $true) {
    Write-Fail -TestName $mapName -Reason 'Get-InstallRoots must succeed with InstallRoot fixture'
}

$expectedUserRoot = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
$expectedProjectRoot = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
$expectedSkills = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $fixtureInstallRoot '.agents') 'skills'))
$expectedRules = [System.IO.Path]::GetFullPath((Join-Path $fixtureInstallRoot 'AGENTS.md'))
$expectedHooks = [System.IO.Path]::GetFullPath((Join-Path $fixtureInstallRoot '.openhands'))
$expectedAgents = [System.IO.Path]::GetFullPath((Join-Path $fixtureInstallRoot 'AGENTS.md'))
$expectedPlugin = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $fixtureInstallRoot '.plugin') 'plugin.json'))
$expectedCustomAgents = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $fixtureInstallRoot '.agents') 'agents'))

if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialUserRootRelativePath) -or $roots.OfficialUserRootRelativePath -ne '.agents') {
    Write-Fail -TestName $mapName -Reason ("expected OfficialUserRootRelativePath .agents, got {0}" -f $roots.OfficialUserRootRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialSkillsRelativePath) -or $roots.OfficialSkillsRelativePath -ne '.agents/skills') {
    Write-Fail -TestName $mapName -Reason ("expected OfficialSkillsRelativePath .agents/skills, got {0}" -f $roots.OfficialSkillsRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialRulesRelativePath) -or $roots.OfficialRulesRelativePath -ne 'AGENTS.md') {
    Write-Fail -TestName $mapName -Reason ("expected OfficialRulesRelativePath AGENTS.md, got {0}" -f $roots.OfficialRulesRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialHooksRelativePath) -or $roots.OfficialHooksRelativePath -ne '.openhands') {
    Write-Fail -TestName $mapName -Reason ("expected OfficialHooksRelativePath .openhands, got {0}" -f $roots.OfficialHooksRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialAgentsFileName) -or $roots.OfficialAgentsFileName -ne 'AGENTS.md') {
    Write-Fail -TestName $mapName -Reason ("expected OfficialAgentsFileName AGENTS.md, got {0}" -f $roots.OfficialAgentsFileName)
}

$comparison = [System.StringComparison]::OrdinalIgnoreCase
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureUserRootPath), $expectedUserRoot, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureUserRootPath mismatch: {0}" -f $roots.FixtureUserRootPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureProjectRootPath), $expectedProjectRoot, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureProjectRootPath mismatch: {0}" -f $roots.FixtureProjectRootPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureSkillsPath), $expectedSkills, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureSkillsPath mismatch: {0}" -f $roots.FixtureSkillsPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureRulesPath), $expectedRules, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureRulesPath mismatch: {0}" -f $roots.FixtureRulesPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureHooksPath), $expectedHooks, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureHooksPath mismatch: {0}" -f $roots.FixtureHooksPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureProjectAgentsPath), $expectedAgents, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureProjectAgentsPath mismatch: {0}" -f $roots.FixtureProjectAgentsPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixturePluginManifestPath), $expectedPlugin, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixturePluginManifestPath mismatch: {0}" -f $roots.FixturePluginManifestPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureCustomAgentsPath), $expectedCustomAgents, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureCustomAgentsPath mismatch: {0}" -f $roots.FixtureCustomAgentsPath)
}

if (-not (Test-IsPathUnderOrEqual -ChildPath $roots.FixtureUserRootPath -ParentPath $repoRoot)) {
    Write-Fail -TestName $mapName -Reason 'mapped project path must stay under repo (fixture), not real HOME'
}
if (-not (Test-IsPathUnderOrEqual -ChildPath $roots.ResolvedInstallRoot -ParentPath $repoRoot)) {
    Write-Fail -TestName $mapName -Reason 'ResolvedInstallRoot must stay under repo root'
}

$homeAgents = Join-Path $userProfile '.agents'
if ([string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureUserRootPath), [System.IO.Path]::GetFullPath($homeAgents), $comparison)) {
    Write-Fail -TestName $mapName -Reason 'FixtureUserRootPath must not equal real USERPROFILE/.agents'
}

$caps = Get-Capabilities -AgentId $openHandsAgentId
if ($caps.Capabilities.subagents -ne 'none') {
    Write-Fail -TestName $mapName -Reason ("expected subagents none, got {0}" -f $caps.Capabilities.subagents)
}
if ($caps.Capabilities.plugin -ne $true -or $caps.Capabilities.agents -ne $true) {
    Write-Fail -TestName $mapName -Reason 'expected plugin=true and agents=true'
}

Write-Pass -TestName $mapName

# --- Should_Fail_When_InstallRootUnderUserProfileWithoutAllowUserHome ---
$failName = 'Should_Fail_When_InstallRootUnderUserProfileWithoutAllowUserHome'
$userProfileInstallRoot = Join-Path $userProfile '.agent-dev-toolkit-openhands-layout-test-install'

$rejectedViaResolve = $false
try {
    $null = Resolve-InstallRoot -InstallRoot $userProfileInstallRoot
}
catch {
    $rejectedViaResolve = $true
    $message = $_.Exception.Message
    if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
        Write-Fail -TestName $failName -Reason ("Resolve-InstallRoot unexpected message: {0}" -f $message)
    }
}
if (-not $rejectedViaResolve) {
    Write-Fail -TestName $failName -Reason 'expected Resolve-InstallRoot throw for USERPROFILE without -AllowUserHome'
}

$rejectedViaAdapter = $false
try {
    $null = Get-InstallRoots -AgentId $openHandsAgentId -InstallRoot $userProfileInstallRoot
}
catch {
    $rejectedViaAdapter = $true
    $message = $_.Exception.Message
    if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
        Write-Fail -TestName $failName -Reason ("Get-InstallRoots unexpected message: {0}" -f $message)
    }
}
if (-not $rejectedViaAdapter) {
    Write-Fail -TestName $failName -Reason 'expected Get-InstallRoots throw for USERPROFILE InstallRoot without -AllowUserHome'
}

$allowedRoots = Get-InstallRoots -AgentId $openHandsAgentId -InstallRoot $userProfileInstallRoot -AllowUserHome
$expectedAllowedSkills = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $userProfileInstallRoot '.agents') 'skills'))
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$allowedRoots.FixtureSkillsPath), $expectedAllowedSkills, $comparison)) {
    Write-Fail -TestName $failName -Reason ("AllowUserHome mapping mismatch: {0}" -f $allowedRoots.FixtureSkillsPath)
}

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $failName -Reason 'tests must not create directories under real USERPROFILE'
}

Write-Pass -TestName $failName

Write-Host 'Assert-OpenHandsNativeLayout: ALL PASS'
exit 0
