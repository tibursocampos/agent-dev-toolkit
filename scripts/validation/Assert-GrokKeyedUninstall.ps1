#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallGrokFixture
#   Should_KeepUnrelatedFiles_When_UninstallGrokFixture
#
# CU03 / RN07: keyed uninstall + e2e sync -> validate -> uninstall on Grok fixture.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'
$syncAgentScript = Join-Path $scriptsRoot 'sync-agent.ps1'
$validateAgentScript = Join-Path $scriptsRoot 'validate-agent.ps1'

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

foreach ($required in @($repoRootScript, $syncAgentScript, $validateAgentScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-GrokKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$grokModulePath = Join-Path $repoRoot 'adapters\grok\GrokAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\grok'
$skillsRoot = Join-Path $fixtureInstallRoot 'skills'
$rulesRoot = Join-Path $fixtureInstallRoot 'rules'
$hooksRoot = Join-Path $fixtureInstallRoot 'hooks'
$agentsPath = Join-Path $fixtureInstallRoot 'AGENTS.md'
$gitkeepName = '.gitkeep'
$configTomlName = 'config.toml'
$alienSkillId = 'alien-user-skill'
$alienRuleFileName = 'alien-user-rule.md'
$alienHookFileName = 'alien-user-hook.json'
$alienSkillMarker = 'alien-skill-keep'
$alienRuleMarker = 'alien-rule-keep'
$alienHookMarker = 'alien-hook-keep'

if (-not (Test-Path -LiteralPath $grokModulePath)) {
    Write-Fail -TestName 'Assert-GrokKeyedUninstallPreconditions' -Reason ("missing Grok module: {0}" -f $grokModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-GrokKeyedUninstallPreconditions' -Reason ("missing Grok fixture: {0}" -f $fixtureInstallRoot)
}

. $grokModulePath

function Clear-GrokPublishedTreeContents {
    param(
        [Parameter(Mandatory = $true)]
        [string] $DirectoryPath
    )

    if (-not (Test-Path -LiteralPath $DirectoryPath)) {
        New-Item -ItemType Directory -Path $DirectoryPath -Force | Out-Null
        return
    }

    Get-ChildItem -LiteralPath $DirectoryPath -Force | Where-Object {
        $_.Name -ne $gitkeepName
    } | Remove-Item -Recurse -Force
}

function Clear-GrokFixturePublishedArtifacts {
    Clear-GrokPublishedTreeContents -DirectoryPath $skillsRoot
    Clear-GrokPublishedTreeContents -DirectoryPath $rulesRoot
    Clear-GrokPublishedTreeContents -DirectoryPath $hooksRoot
    if (Test-Path -LiteralPath $agentsPath) {
        Remove-Item -LiteralPath $agentsPath -Force
    }

    $configToml = Join-Path $fixtureInstallRoot $configTomlName
    if (Test-Path -LiteralPath $configToml) {
        Remove-Item -LiteralPath $configToml -Force
    }
}

function Test-GrokToolkitSkillPresent {
    $manifestName = 'SKILL.md'
    $knownSkillId = 'commit'
    $published = Join-Path $skillsRoot $knownSkillId
    return (Test-Path -LiteralPath (Join-Path $published $manifestName))
}

function Test-GrokToolkitRulePresent {
    $corePolicy = Join-Path (Join-Path $repoRoot 'core') 'policy'
    $sample = Get-ChildItem -LiteralPath $corePolicy -File | Select-Object -First 1
    if ($null -eq $sample) {
        return $false
    }

    return (Test-Path -LiteralPath (Join-Path $rulesRoot $sample.Name))
}

function Test-GrokToolkitHooksPresent {
    $hooksJson = Join-Path $hooksRoot 'toolkit-session-start.json'
    $hooksScript = Join-Path $hooksRoot 'session_start.ps1'
    return ((Test-Path -LiteralPath $hooksJson) -and (Test-Path -LiteralPath $hooksScript))
}

# --- Should_RemoveToolkitArtifacts_When_UninstallGrokFixture (e2e sync -> validate -> uninstall) ---
$removeTest = 'Should_RemoveToolkitArtifacts_When_UninstallGrokFixture'

Clear-GrokFixturePublishedArtifacts

$syncLines = @(& $syncAgentScript -Agent grok -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
if ($syncExit -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("sync-agent -Agent grok failed (exit {0}): {1}" -f $syncExit, ($syncLines -join [Environment]::NewLine).Trim())
}

if (-not (Test-GrokToolkitSkillPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit skills under skills/ after sync'
}
if (-not (Test-GrokToolkitRulePresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit rules under rules/ after sync'
}
if (-not (Test-GrokToolkitHooksPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit hooks under hooks/ after sync'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $removeTest -Reason 'expected AGENTS.md after sync'
}

$validateLines = @(& $validateAgentScript -Agent grok -Quiet -SkipCore *>&1 | ForEach-Object { "$_" })
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("validate-agent -Agent grok -SkipCore failed (exit {0}): {1}" -f $validateExit, ($validateLines -join [Environment]::NewLine).Trim())
}

$uninstall = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstall -or $uninstall.Implemented -ne $true -or $uninstall.Success -ne $true) {
    Write-Fail -TestName $removeTest -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstall) { 'null' } else { $uninstall.Message }))
}
if ($uninstall.ExitCode -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("expected ExitCode 0, got {0}" -f $uninstall.ExitCode)
}
if ($uninstall.RemovedCount -lt 1) {
    Write-Fail -TestName $removeTest -Reason 'expected at least one keyed artifact removed'
}

if (Test-GrokToolkitSkillPresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit skills should be removed after uninstall'
}
if (Test-GrokToolkitRulePresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit rules should be removed after uninstall'
}
if (Test-GrokToolkitHooksPresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit hooks should be removed after uninstall'
}
if (Test-Path -LiteralPath $agentsPath) {
    Write-Fail -TestName $removeTest -Reason 'AGENTS.md should be removed after uninstall'
}

# Skeleton dirs must remain (no wholesale InstallRoot wipe)
foreach ($dir in @($skillsRoot, $rulesRoot, $hooksRoot, $fixtureInstallRoot)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        Write-Fail -TestName $removeTest -Reason ("keyed uninstall must not wipe directory tree: {0}" -f $dir)
    }
}

Write-Pass -TestName $removeTest

# --- Should_KeepUnrelatedFiles_When_UninstallGrokFixture ---
$keepTest = 'Should_KeepUnrelatedFiles_When_UninstallGrokFixture'

Clear-GrokFixturePublishedArtifacts

$alienSkillDir = Join-Path $skillsRoot $alienSkillId
New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $alienSkillDir 'SKILL.md') -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

$alienRulePath = Join-Path $rulesRoot $alienRuleFileName
Set-Content -LiteralPath $alienRulePath -Value ("# {0}`n" -f $alienRuleMarker) -Encoding UTF8

$alienHookPath = Join-Path $hooksRoot $alienHookFileName
Set-Content -LiteralPath $alienHookPath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $alienHookMarker) -Encoding UTF8

$configTomlPath = Join-Path $fixtureInstallRoot $configTomlName
Set-Content -LiteralPath $configTomlPath -Value ("# {0}`nkeep=true`n" -f $configTomlName) -Encoding UTF8

$syncLines2 = @(& $syncAgentScript -Agent grok -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
$syncExit2 = $LASTEXITCODE
if ($null -eq $syncExit2) { $syncExit2 = 0 }
if ($syncExit2 -ne 0) {
    Write-Fail -TestName $keepTest -Reason ("sync-agent failed before keep-unrelated uninstall (exit {0}): {1}" -f $syncExit2, ($syncLines2 -join [Environment]::NewLine).Trim())
}

$uninstallKeep = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallKeep -or $uninstallKeep.Success -ne $true) {
    Write-Fail -TestName $keepTest -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstallKeep) { 'null' } else { $uninstallKeep.Message }))
}

if (-not (Test-Path -LiteralPath (Join-Path $alienSkillDir 'SKILL.md'))) {
    Write-Fail -TestName $keepTest -Reason 'alien skill directory must survive keyed uninstall'
}
$alienSkillText = [System.IO.File]::ReadAllText((Join-Path $alienSkillDir 'SKILL.md'))
if ($alienSkillText -notmatch [regex]::Escape($alienSkillMarker)) {
    Write-Fail -TestName $keepTest -Reason 'alien skill content must be preserved'
}

if (-not (Test-Path -LiteralPath $alienRulePath)) {
    Write-Fail -TestName $keepTest -Reason 'alien rule file must survive keyed uninstall'
}
$alienRuleText = [System.IO.File]::ReadAllText($alienRulePath)
if ($alienRuleText -notmatch [regex]::Escape($alienRuleMarker)) {
    Write-Fail -TestName $keepTest -Reason 'alien rule content must be preserved'
}

if (-not (Test-Path -LiteralPath $alienHookPath)) {
    Write-Fail -TestName $keepTest -Reason 'alien hook file must survive keyed uninstall'
}
$alienHookText = [System.IO.File]::ReadAllText($alienHookPath)
if ($alienHookText -notmatch [regex]::Escape($alienHookMarker)) {
    Write-Fail -TestName $keepTest -Reason 'alien hook content must be preserved'
}

if (-not (Test-Path -LiteralPath $configTomlPath)) {
    Write-Fail -TestName $keepTest -Reason 'config.toml must not be touched by uninstall (RN07)'
}

if (Test-GrokToolkitSkillPresent) {
    Write-Fail -TestName $keepTest -Reason 'toolkit skills should still be removed while aliens remain'
}
if (Test-Path -LiteralPath $agentsPath) {
    Write-Fail -TestName $keepTest -Reason 'toolkit AGENTS.md should still be removed'
}

# Cleanup alien probes so fixture stays tidy for later steps
Remove-Item -LiteralPath $alienSkillDir -Recurse -Force
Remove-Item -LiteralPath $alienRulePath -Force
Remove-Item -LiteralPath $alienHookPath -Force
Remove-Item -LiteralPath $configTomlPath -Force

# Restore a clean published fixture for subsequent steps / local use
Clear-GrokFixturePublishedArtifacts
$restoreLines = @(& $syncAgentScript -Agent grok -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
$restoreExit = $LASTEXITCODE
if ($null -eq $restoreExit) { $restoreExit = 0 }
if ($restoreExit -ne 0) {
    Write-Fail -TestName 'Assert-GrokKeyedUninstallRestore' -Reason ("fixture restore sync failed (exit {0}): {1}" -f $restoreExit, ($restoreLines -join [Environment]::NewLine).Trim())
}

Write-Pass -TestName $keepTest

Write-Host 'Assert-GrokKeyedUninstall: ALL PASS'
exit 0
