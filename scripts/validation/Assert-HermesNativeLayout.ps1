#Requires -Version 5.1
# Tests:
#   Should_MapHermesRootsUnderFixture_When_InstallRootProvided
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
        Write-Fail -TestName 'Assert-HermesNativeLayoutPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript
. $resolveInstallRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$hermesAgentId = 'hermes'
$hermesModulePath = Join-Path $repoRoot 'adapters\hermes\HermesAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\hermes'
$officialUserRootName = '.hermes'
$skillsDirectoryName = 'skills'
$agentsFileName = 'AGENTS.md'
$userProfile = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-HermesNativeLayoutPreconditions' -Reason 'USERPROFILE is not set'
}

if (-not (Test-Path -LiteralPath $hermesModulePath)) {
    Write-Fail -TestName 'Assert-HermesNativeLayoutPreconditions' -Reason ("missing Hermes module: {0}" -f $hermesModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-HermesNativeLayoutPreconditions' -Reason ("missing Hermes fixture: {0}" -f $fixtureInstallRoot)
}

$expectedSkillsDir = Join-Path $fixtureInstallRoot $skillsDirectoryName
if (-not (Test-Path -LiteralPath $expectedSkillsDir)) {
    Write-Fail -TestName 'Assert-HermesNativeLayoutPreconditions' -Reason ("fixture skeleton missing: {0}" -f $expectedSkillsDir)
}

$rulesDir = Join-Path $fixtureInstallRoot 'rules'
if (Test-Path -LiteralPath $rulesDir) {
    Write-Fail -TestName 'Assert-HermesNativeLayoutPreconditions' -Reason 'Hermes fixture must not contain a rules/ tree'
}

$hooksDir = Join-Path $fixtureInstallRoot 'hooks'
if (Test-Path -LiteralPath $hooksDir) {
    Write-Fail -TestName 'Assert-HermesNativeLayoutPreconditions' -Reason 'Hermes fixture must not contain a hooks/ tree'
}

. $hermesModulePath

# --- Should_MapHermesRootsUnderFixture_When_InstallRootProvided ---
$mapName = 'Should_MapHermesRootsUnderFixture_When_InstallRootProvided'
$roots = Get-InstallRoots -AgentId $hermesAgentId -InstallRoot $fixtureInstallRoot
if ($null -eq $roots -or $roots.Implemented -ne $true -or $roots.Success -ne $true) {
    Write-Fail -TestName $mapName -Reason 'Get-InstallRoots must succeed with InstallRoot fixture'
}

$expectedUserRoot = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
$expectedProjectRoot = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
$expectedSkills = [System.IO.Path]::GetFullPath((Join-Path $fixtureInstallRoot $skillsDirectoryName))
$expectedAgents = [System.IO.Path]::GetFullPath((Join-Path $fixtureInstallRoot $agentsFileName))

if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialUserRootRelativePath) -or $roots.OfficialUserRootRelativePath -ne $officialUserRootName) {
    Write-Fail -TestName $mapName -Reason ("expected OfficialUserRootRelativePath {0}, got {1}" -f $officialUserRootName, $roots.OfficialUserRootRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialProjectRootRelativePath) -or $roots.OfficialProjectRootRelativePath -ne $officialUserRootName) {
    Write-Fail -TestName $mapName -Reason ("expected OfficialProjectRootRelativePath {0}, got {1}" -f $officialUserRootName, $roots.OfficialProjectRootRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialSkillsRelativePath) -or $roots.OfficialSkillsRelativePath -ne $skillsDirectoryName) {
    Write-Fail -TestName $mapName -Reason ("expected OfficialSkillsRelativePath {0}, got {1}" -f $skillsDirectoryName, $roots.OfficialSkillsRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialRulesRelativePath) -or $roots.OfficialRulesRelativePath -ne $agentsFileName) {
    Write-Fail -TestName $mapName -Reason ("expected OfficialRulesRelativePath {0} (folded policy), got {1}" -f $agentsFileName, $roots.OfficialRulesRelativePath)
}
if ([string]::IsNullOrWhiteSpace([string]$roots.OfficialAgentsFileName) -or $roots.OfficialAgentsFileName -ne $agentsFileName) {
    Write-Fail -TestName $mapName -Reason ("expected OfficialAgentsFileName {0}, got {1}" -f $agentsFileName, $roots.OfficialAgentsFileName)
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
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureRulesPath), $expectedAgents, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureRulesPath mismatch (must be AGENTS.md): {0}" -f $roots.FixtureRulesPath)
}
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureProjectAgentsPath), $expectedAgents, $comparison)) {
    Write-Fail -TestName $mapName -Reason ("FixtureProjectAgentsPath mismatch: {0}" -f $roots.FixtureProjectAgentsPath)
}

if (-not (Test-IsPathUnderOrEqual -ChildPath $roots.FixtureUserRootPath -ParentPath $repoRoot)) {
    Write-Fail -TestName $mapName -Reason 'mapped USER .hermes path must stay under repo (fixture), not real HOME'
}
if (-not (Test-IsPathUnderOrEqual -ChildPath $roots.ResolvedInstallRoot -ParentPath $repoRoot)) {
    Write-Fail -TestName $mapName -Reason 'ResolvedInstallRoot must stay under repo root'
}

$homeHermes = Join-Path $userProfile $officialUserRootName
if ([string]::Equals([System.IO.Path]::GetFullPath([string]$roots.FixtureUserRootPath), [System.IO.Path]::GetFullPath($homeHermes), $comparison)) {
    Write-Fail -TestName $mapName -Reason 'FixtureUserRootPath must not equal real USERPROFILE/.hermes'
}

$caps = Get-Capabilities -AgentId $hermesAgentId
if ($caps.Capabilities.hooks -ne $false) {
    Write-Fail -TestName $mapName -Reason 'hooks capability must be false'
}
if ($caps.Capabilities.agents -ne $false) {
    Write-Fail -TestName $mapName -Reason 'agents capability must be false'
}
if ($caps.Capabilities.plugin -ne $false) {
    Write-Fail -TestName $mapName -Reason 'plugin capability must be false'
}
if ($caps.Capabilities.subagents -ne 'native') {
    Write-Fail -TestName $mapName -Reason 'subagents capability must be native'
}

Write-Pass -TestName $mapName

# --- Should_Fail_When_InstallRootUnderUserProfileWithoutAllowUserHome ---
$failName = 'Should_Fail_When_InstallRootUnderUserProfileWithoutAllowUserHome'
$userProfileInstallRoot = Join-Path $userProfile '.agent-dev-toolkit-hermes-layout-test-install'

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
    $null = Get-InstallRoots -AgentId $hermesAgentId -InstallRoot $userProfileInstallRoot
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

$allowedRoots = Get-InstallRoots -AgentId $hermesAgentId -InstallRoot $userProfileInstallRoot -AllowUserHome
$expectedAllowedSkills = [System.IO.Path]::GetFullPath((Join-Path $userProfileInstallRoot $skillsDirectoryName))
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$allowedRoots.FixtureSkillsPath), $expectedAllowedSkills, $comparison)) {
    Write-Fail -TestName $failName -Reason ("AllowUserHome mapping mismatch: {0}" -f $allowedRoots.FixtureSkillsPath)
}

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $failName -Reason 'tests must not create directories under real USERPROFILE'
}

Write-Pass -TestName $failName

Write-Host 'Assert-HermesNativeLayout: ALL PASS'
exit 0
