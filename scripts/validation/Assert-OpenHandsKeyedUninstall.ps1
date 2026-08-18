#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallOpenHandsFixture
#   Should_KeepUnrelatedFiles_When_UninstallOpenHandsFixture
#
# CU03 / RN07: keyed uninstall via direct module calls (registry wave 2 not wired).
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'
$ephemeralSmokeScript = Join-Path $scriptsRoot '_lib\Invoke-EphemeralFixtureSmoke.ps1'

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

foreach ($required in @($repoRootScript, $ephemeralSmokeScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-OpenHandsKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript
. $ephemeralSmokeScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$openHandsModulePath = Join-Path $repoRoot 'adapters\openhands\OpenHandsAdapter.ps1'
$seedFixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\openhands'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\openhands-keyed-uninstall-work'
$gitkeepName = '.gitkeep'
$configTomlName = 'config.toml'
$alienSkillId = 'alien-user-skill'
$alienHookFileName = 'alien-user-hook.sh'
$alienAgentFileName = 'alien-user-agent.md'
$alienPluginFileName = 'alien-plugin-note.txt'
$alienSkillMarker = 'alien-skill-keep'
$alienHookMarker = 'alien-hook-keep'
$alienAgentMarker = 'alien-agent-keep'
$alienPluginMarker = 'alien-plugin-keep'
$knownSkillId = 'commit'
$skillManifestName = 'SKILL.md'

if (-not (Test-Path -LiteralPath $openHandsModulePath)) {
    Write-Fail -TestName 'Assert-OpenHandsKeyedUninstallPreconditions' -Reason ("missing OpenHands module: {0}" -f $openHandsModulePath)
}
if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-Fail -TestName 'Assert-OpenHandsKeyedUninstallPreconditions' -Reason ("missing OpenHands fixture: {0}" -f $seedFixtureRoot)
}

. $openHandsModulePath

function Initialize-OpenHandsKeyedUninstallWorkRoot {
    Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
    New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $seedFixtureRoot -Force | Copy-Item -Destination $workInstallRoot -Recurse -Force
}

function Get-OpenHandsWorkMappedPaths {
    return (Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $workInstallRoot)
}

function Invoke-OpenHandsDirectPublishAll {
    $skills = Publish-Skills -InstallRoot $workInstallRoot
    if ($null -eq $skills -or $skills.Success -ne $true) {
        throw ("Publish-Skills failed: {0}" -f $(if ($null -eq $skills) { 'null' } else { $skills.Message }))
    }
    $policy = Publish-Policy -InstallRoot $workInstallRoot
    if ($null -eq $policy -or $policy.Success -ne $true) {
        throw ("Publish-Policy failed: {0}" -f $(if ($null -eq $policy) { 'null' } else { $policy.Message }))
    }
    $router = Publish-Router -InstallRoot $workInstallRoot
    if ($null -eq $router -or $router.Success -ne $true) {
        throw ("Publish-Router failed: {0}" -f $(if ($null -eq $router) { 'null' } else { $router.Message }))
    }
    $agents = Publish-Agents -InstallRoot $workInstallRoot
    if ($null -eq $agents -or $agents.Success -ne $true) {
        throw ("Publish-Agents failed: {0}" -f $(if ($null -eq $agents) { 'null' } else { $agents.Message }))
    }
    $hooks = Publish-Hooks -InstallRoot $workInstallRoot
    if ($null -eq $hooks -or $hooks.Success -ne $true) {
        throw ("Publish-Hooks failed: {0}" -f $(if ($null -eq $hooks) { 'null' } else { $hooks.Message }))
    }
    $sdd = Get-SddRoot -InstallRoot $workInstallRoot -Prepare
    if ($null -eq $sdd -or $sdd.Success -ne $true) {
        throw ("Get-SddRoot -Prepare failed: {0}" -f $(if ($null -eq $sdd) { 'null' } else { $sdd.Message }))
    }
}

function Test-OpenHandsToolkitSkillPresent {
    $mapped = Get-OpenHandsWorkMappedPaths
    $published = Join-Path $mapped.FixtureSkillsPath $knownSkillId
    return (Test-Path -LiteralPath (Join-Path $published $skillManifestName))
}

function Test-OpenHandsToolkitHooksPresent {
    $mapped = Get-OpenHandsWorkMappedPaths
    $hooksJson = Join-Path $mapped.FixtureHooksPath 'hooks.json'
    $hooksScript = Join-Path $mapped.FixtureHooksScriptsPath 'session_start.sh'
    return ((Test-Path -LiteralPath $hooksJson) -and (Test-Path -LiteralPath $hooksScript))
}

function Test-OpenHandsToolkitPluginPresent {
    $mapped = Get-OpenHandsWorkMappedPaths
    return (Test-Path -LiteralPath $mapped.FixturePluginManifestPath)
}

function Test-OpenHandsToolkitAgentsRosterPresent {
    $mapped = Get-OpenHandsWorkMappedPaths
    $sample = Join-Path $mapped.FixtureCustomAgentsPath 'architect.md'
    return (Test-Path -LiteralPath $sample)
}

function Test-OpenHandsToolkitAgentsMdPresent {
    $mapped = Get-OpenHandsWorkMappedPaths
    return (Test-Path -LiteralPath $mapped.FixtureProjectAgentsPath)
}

try {
    # --- Should_RemoveToolkitArtifacts_When_UninstallOpenHandsFixture ---
    $removeTest = 'Should_RemoveToolkitArtifacts_When_UninstallOpenHandsFixture'
    Initialize-OpenHandsKeyedUninstallWorkRoot
    try {
        Invoke-OpenHandsDirectPublishAll
    }
    catch {
        Write-Fail -TestName $removeTest -Reason $_.Exception.Message
    }

    if (-not (Test-OpenHandsToolkitSkillPresent)) {
        Write-Fail -TestName $removeTest -Reason 'expected toolkit skills under .agents/skills after publish'
    }
    if (-not (Test-OpenHandsToolkitHooksPresent)) {
        Write-Fail -TestName $removeTest -Reason 'expected toolkit hooks under .openhands after publish'
    }
    if (-not (Test-OpenHandsToolkitPluginPresent)) {
        Write-Fail -TestName $removeTest -Reason 'expected .plugin/plugin.json after publish'
    }
    if (-not (Test-OpenHandsToolkitAgentsRosterPresent)) {
        Write-Fail -TestName $removeTest -Reason 'expected toolkit agents markdown under .agents/agents after publish'
    }
    if (-not (Test-OpenHandsToolkitAgentsMdPresent)) {
        Write-Fail -TestName $removeTest -Reason 'expected AGENTS.md after publish'
    }

    $uninstall = Uninstall-Toolkit -InstallRoot $workInstallRoot
    if ($null -eq $uninstall -or $uninstall.Implemented -ne $true -or $uninstall.Success -ne $true) {
        Write-Fail -TestName $removeTest -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstall) { 'null' } else { $uninstall.Message }))
    }
    if ($uninstall.ExitCode -ne 0) {
        Write-Fail -TestName $removeTest -Reason ("expected ExitCode 0, got {0}" -f $uninstall.ExitCode)
    }
    if ($uninstall.RemovedCount -lt 1) {
        Write-Fail -TestName $removeTest -Reason 'expected at least one keyed artifact removed'
    }

    if (Test-OpenHandsToolkitSkillPresent) {
        Write-Fail -TestName $removeTest -Reason 'toolkit skills should be removed after uninstall'
    }
    if (Test-OpenHandsToolkitHooksPresent) {
        Write-Fail -TestName $removeTest -Reason 'toolkit hooks should be removed after uninstall'
    }
    if (Test-OpenHandsToolkitPluginPresent) {
        Write-Fail -TestName $removeTest -Reason '.plugin/plugin.json should be removed after uninstall'
    }
    if (Test-OpenHandsToolkitAgentsRosterPresent) {
        Write-Fail -TestName $removeTest -Reason 'toolkit agents markdown should be removed after uninstall'
    }
    if (Test-OpenHandsToolkitAgentsMdPresent) {
        Write-Fail -TestName $removeTest -Reason 'AGENTS.md should be removed after uninstall'
    }

    $mappedAfter = Get-OpenHandsWorkMappedPaths
    foreach ($dir in @($mappedAfter.FixtureSkillsPath, $mappedAfter.FixtureHooksPath, $workInstallRoot)) {
        if (-not (Test-Path -LiteralPath $dir)) {
            Write-Fail -TestName $removeTest -Reason ("keyed uninstall must not wipe directory tree: {0}" -f $dir)
        }
    }

    Write-Pass -TestName $removeTest

    # --- Should_KeepUnrelatedFiles_When_UninstallOpenHandsFixture ---
    $keepTest = 'Should_KeepUnrelatedFiles_When_UninstallOpenHandsFixture'
    Initialize-OpenHandsKeyedUninstallWorkRoot
    $mappedKeep = Get-OpenHandsWorkMappedPaths

    $alienSkillDir = Join-Path $mappedKeep.FixtureSkillsPath $alienSkillId
    New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $alienSkillDir $skillManifestName) -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

    $alienHookPath = Join-Path $mappedKeep.FixtureHooksScriptsPath $alienHookFileName
    Set-Content -LiteralPath $alienHookPath -Value ("# {0}`nexit 0`n" -f $alienHookMarker) -Encoding UTF8

    New-Item -ItemType Directory -Path $mappedKeep.FixtureCustomAgentsPath -Force | Out-Null
    $alienAgentPath = Join-Path $mappedKeep.FixtureCustomAgentsPath $alienAgentFileName
    Set-Content -LiteralPath $alienAgentPath -Value ("# {0}`n" -f $alienAgentMarker) -Encoding UTF8

    New-Item -ItemType Directory -Path $mappedKeep.FixturePluginPath -Force | Out-Null
    $alienPluginPath = Join-Path $mappedKeep.FixturePluginPath $alienPluginFileName
    Set-Content -LiteralPath $alienPluginPath -Value ("# {0}`n" -f $alienPluginMarker) -Encoding UTF8

    $configTomlPath = Join-Path $workInstallRoot $configTomlName
    Set-Content -LiteralPath $configTomlPath -Value ("# {0}`nkeep=true`n" -f $configTomlName) -Encoding UTF8

    try {
        Invoke-OpenHandsDirectPublishAll
    }
    catch {
        Write-Fail -TestName $keepTest -Reason $_.Exception.Message
    }

    $uninstallKeep = Uninstall-Toolkit -InstallRoot $workInstallRoot
    if ($null -eq $uninstallKeep -or $uninstallKeep.Success -ne $true) {
        Write-Fail -TestName $keepTest -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstallKeep) { 'null' } else { $uninstallKeep.Message }))
    }

    if (-not (Test-Path -LiteralPath (Join-Path $alienSkillDir $skillManifestName))) {
        Write-Fail -TestName $keepTest -Reason 'alien skill directory must survive keyed uninstall'
    }
    $alienSkillText = [System.IO.File]::ReadAllText((Join-Path $alienSkillDir $skillManifestName))
    if ($alienSkillText -notmatch [regex]::Escape($alienSkillMarker)) {
        Write-Fail -TestName $keepTest -Reason 'alien skill content must be preserved'
    }

    if (-not (Test-Path -LiteralPath $alienHookPath)) {
        Write-Fail -TestName $keepTest -Reason 'alien hook file must survive keyed uninstall'
    }
    $alienHookText = [System.IO.File]::ReadAllText($alienHookPath)
    if ($alienHookText -notmatch [regex]::Escape($alienHookMarker)) {
        Write-Fail -TestName $keepTest -Reason 'alien hook content must be preserved'
    }

    if (-not (Test-Path -LiteralPath $alienAgentPath)) {
        Write-Fail -TestName $keepTest -Reason 'alien agent markdown must survive keyed uninstall'
    }
    $alienAgentText = [System.IO.File]::ReadAllText($alienAgentPath)
    if ($alienAgentText -notmatch [regex]::Escape($alienAgentMarker)) {
        Write-Fail -TestName $keepTest -Reason 'alien agent content must be preserved'
    }

    if (-not (Test-Path -LiteralPath $alienPluginPath)) {
        Write-Fail -TestName $keepTest -Reason 'alien plugin sidecar must survive keyed uninstall'
    }
    $alienPluginText = [System.IO.File]::ReadAllText($alienPluginPath)
    if ($alienPluginText -notmatch [regex]::Escape($alienPluginMarker)) {
        Write-Fail -TestName $keepTest -Reason 'alien plugin sidecar content must be preserved'
    }

    if (-not (Test-Path -LiteralPath $configTomlPath)) {
        Write-Fail -TestName $keepTest -Reason 'config.toml must not be touched by uninstall (RN07)'
    }

    if (Test-OpenHandsToolkitSkillPresent) {
        Write-Fail -TestName $keepTest -Reason 'toolkit skills should still be removed while aliens remain'
    }
    if (Test-OpenHandsToolkitAgentsMdPresent) {
        Write-Fail -TestName $keepTest -Reason 'toolkit AGENTS.md should still be removed'
    }
    if (Test-OpenHandsToolkitPluginPresent) {
        Write-Fail -TestName $keepTest -Reason 'toolkit plugin.json should still be removed while alien sidecar remains'
    }

    Write-Pass -TestName $keepTest
}
finally {
    Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
}

Write-Host 'Assert-OpenHandsKeyedUninstall: ALL PASS'
exit 0
