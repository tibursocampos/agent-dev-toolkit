#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallCodexFixture
#   Should_KeepUnrelatedFiles_When_UninstallCodexFixture
# E2E: sync-agent -> validate-agent -> Uninstall-Toolkit on Codex fixture (CU03 / RN07)
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
        Write-Fail -TestName 'Assert-CodexKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$codexModulePath = Join-Path $repoRoot 'adapters\codex\CodexAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\codex'
$pluginRoot = Join-Path $fixtureInstallRoot 'plugin'
$pluginSkillsRoot = Join-Path $pluginRoot 'skills'
$homeSkillsRoot = Join-Path $fixtureInstallRoot 'skills'
$pluginHooksRoot = Join-Path $pluginRoot 'hooks'
$pluginManifestPath = Join-Path $pluginRoot '.codex-plugin\plugin.json'
$marketplacePath = Join-Path $fixtureInstallRoot '.agents\plugins\marketplace.json'
$agentsPath = Join-Path $fixtureInstallRoot 'AGENTS.md'
$customAgentSamplePath = Join-Path $fixtureInstallRoot 'agents\repo-analyst.md'
$userSkillsRoot = Join-Path $fixtureInstallRoot '.agents\skills'
$gitkeepName = '.gitkeep'
$alienSkillId = 'alien-codex-skill-'
$alienHookFileName = 'alien-user-hook.json'
$alienHookMarker = 'alien-hook-keep'
$alienSkillMarker = 'alien-skill-keep'
$alienConfigRelative = '.codex\config.toml'
$alienConfigMarker = 'alien-codex-config-keep'
$alienMarketplaceNoteName = 'alien-marketplace-note.txt'
$alienMarketplaceNoteMarker = 'alien-marketplace-keep'

if (-not (Test-Path -LiteralPath $codexModulePath)) {
    Write-Fail -TestName 'Assert-CodexKeyedUninstallPreconditions' -Reason ("missing Codex module: {0}" -f $codexModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-CodexKeyedUninstallPreconditions' -Reason ("missing Codex fixture: {0}" -f $fixtureInstallRoot)
}

. $codexModulePath

function Get-CodexCoreSkillIds {
    $coreSkillsRoot = Join-Path (Join-Path $repoRoot 'core') 'skills'
    return @(
        Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force |
            Select-Object -ExpandProperty Name
    )
}

function Clear-CodexPublishedTreeContents {
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

function Clear-CodexFixturePublishedArtifacts {
    Clear-CodexPublishedTreeContents -DirectoryPath $pluginSkillsRoot
    Clear-CodexPublishedTreeContents -DirectoryPath $homeSkillsRoot
    Clear-CodexPublishedTreeContents -DirectoryPath $pluginHooksRoot
    Clear-CodexPublishedTreeContents -DirectoryPath (Join-Path $pluginRoot '.codex-plugin')
    Clear-CodexPublishedTreeContents -DirectoryPath $userSkillsRoot

    if (Test-Path -LiteralPath $agentsPath) {
        Remove-Item -LiteralPath $agentsPath -Force
    }
    if (Test-Path -LiteralPath $marketplacePath) {
        Remove-Item -LiteralPath $marketplacePath -Force
    }
}

function Test-CodexToolkitPluginPresent {
    if (-not (Test-Path -LiteralPath $pluginManifestPath)) {
        return $false
    }

    $knownSkillId = 'commit'
    $published = Join-Path $pluginSkillsRoot $knownSkillId
    return (Test-Path -LiteralPath (Join-Path $published 'SKILL.md'))
}

function Test-CodexToolkitHooksPresent {
    $hooksJson = Join-Path $pluginHooksRoot 'hooks.json'
    $hooksScript = Join-Path $pluginHooksRoot 'session_start.ps1'
    return ((Test-Path -LiteralPath $hooksJson) -and (Test-Path -LiteralPath $hooksScript))
}

function Assert-CodexToolkitArtifactsAbsent {
    param([Parameter(Mandatory = $true)][string] $TestName)

    if (Test-Path -LiteralPath $pluginManifestPath) {
        Write-Fail -TestName $TestName -Reason 'plugin.json must be removed by keyed uninstall'
    }

    foreach ($id in (Get-CodexCoreSkillIds)) {
        $pluginSkill = Join-Path $pluginSkillsRoot $id
        if (Test-Path -LiteralPath $pluginSkill) {
            Write-Fail -TestName $TestName -Reason ("managed plugin skill still present: {0}" -f $id)
        }

        $homeSkill = Join-Path $homeSkillsRoot $id
        if (Test-Path -LiteralPath $homeSkill) {
            Write-Fail -TestName $TestName -Reason ("managed home skill ($ discovery) still present: {0}" -f $id)
        }

        $userSkill = Join-Path $userSkillsRoot $id
        if (Test-Path -LiteralPath $userSkill) {
            Write-Fail -TestName $TestName -Reason ("managed USER skill still present: {0}" -f $id)
        }
    }

    if (Test-CodexToolkitHooksPresent) {
        Write-Fail -TestName $TestName -Reason 'toolkit hooks files must be removed'
    }
    if (Test-Path -LiteralPath $agentsPath) {
        Write-Fail -TestName $TestName -Reason 'AGENTS.md must be removed by keyed uninstall'
    }
    if (Test-Path -LiteralPath $customAgentSamplePath) {
        Write-Fail -TestName $TestName -Reason 'custom subagent file must be removed by keyed uninstall'
    }
    if (Test-Path -LiteralPath $marketplacePath) {
        $raw = [System.IO.File]::ReadAllText($marketplacePath)
        if ($raw -match 'agent-dev-toolkit') {
            Write-Fail -TestName $TestName -Reason 'marketplace must not retain toolkit plugin entry'
        }
    }
}

# --- Should_RemoveToolkitArtifacts_When_UninstallCodexFixture (e2e sync -> validate -> uninstall) ---
$removeTest = 'Should_RemoveToolkitArtifacts_When_UninstallCodexFixture'

Clear-CodexFixturePublishedArtifacts

$syncLines = @(& $syncAgentScript -Agent codex -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
if ($syncExit -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("sync-agent -Agent codex failed (exit {0}): {1}" -f $syncExit, ($syncLines -join [Environment]::NewLine).Trim())
}

# Optional USER-scope mirror so uninstall also covers .agents/skills (opt-in path)
$userScopePublish = Publish-Skills -InstallRoot $fixtureInstallRoot -UserScope
if ($null -eq $userScopePublish -or $userScopePublish.Success -ne $true) {
    Write-Fail -TestName $removeTest -Reason 'Publish-Skills -UserScope failed while preparing uninstall fixture'
}

if (-not (Test-CodexToolkitPluginPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit plugin skills after sync'
}
$homeHelpSkills = Join-Path $homeSkillsRoot 'help-skills\SKILL.md'
if (-not (Test-Path -LiteralPath $homeHelpSkills -PathType Leaf)) {
    Write-Fail -TestName $removeTest -Reason ("expected home skills ($ discovery) after sync: {0}" -f $homeHelpSkills)
}
if (-not (Test-CodexToolkitHooksPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit hooks after sync'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $removeTest -Reason 'expected AGENTS.md after sync'
}
if (-not (Test-Path -LiteralPath $customAgentSamplePath)) {
    Write-Fail -TestName $removeTest -Reason 'expected custom subagent file after sync'
}
if (-not (Test-Path -LiteralPath $marketplacePath)) {
    Write-Fail -TestName $removeTest -Reason 'expected marketplace.json after sync'
}

$validateLines = @(& $validateAgentScript -Agent codex -Quiet *>&1 | ForEach-Object { "$_" })
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("validate-agent -Agent codex failed (exit {0}): {1}" -f $validateExit, ($validateLines -join [Environment]::NewLine).Trim())
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
if ($null -eq $uninstall.KeyedOnly -or $uninstall.KeyedOnly -ne $true) {
    Write-Fail -TestName $removeTest -Reason 'KeyedOnly must be true (RN07)'
}
if ($null -eq $uninstall.WholesaleWipe -or $uninstall.WholesaleWipe -ne $false) {
    Write-Fail -TestName $removeTest -Reason 'WholesaleWipe must be false (RN07)'
}

Assert-CodexToolkitArtifactsAbsent -TestName $removeTest

# Skeleton dirs must remain (no wholesale plugin / skills / .agents wipe)
foreach ($dir in @($pluginRoot, $pluginSkillsRoot, $homeSkillsRoot, $pluginHooksRoot, (Join-Path $fixtureInstallRoot '.agents'), $userSkillsRoot)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        Write-Fail -TestName $removeTest -Reason ("keyed uninstall must not wipe directory tree: {0}" -f $dir)
    }
}

Write-Pass -TestName $removeTest

# --- Should_KeepUnrelatedFiles_When_UninstallCodexFixture ---
$keepTest = 'Should_KeepUnrelatedFiles_When_UninstallCodexFixture'

Clear-CodexFixturePublishedArtifacts

$alienSkillDir = Join-Path $pluginSkillsRoot $alienSkillId
New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $alienSkillDir 'SKILL.md') -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

$alienHookPath = Join-Path $pluginHooksRoot $alienHookFileName
if (-not (Test-Path -LiteralPath $pluginHooksRoot)) {
    New-Item -ItemType Directory -Path $pluginHooksRoot -Force | Out-Null
}
Set-Content -LiteralPath $alienHookPath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $alienHookMarker) -Encoding UTF8

$alienConfigPath = Join-Path $fixtureInstallRoot ($alienConfigRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$alienConfigDir = Split-Path -Parent $alienConfigPath
New-Item -ItemType Directory -Path $alienConfigDir -Force | Out-Null
Set-Content -LiteralPath $alienConfigPath -Value ("# {0}`nkeep=true`n" -f $alienConfigMarker) -Encoding UTF8

$marketplaceDir = Split-Path -Parent $marketplacePath
if (-not (Test-Path -LiteralPath $marketplaceDir)) {
    New-Item -ItemType Directory -Path $marketplaceDir -Force | Out-Null
}
$alienMarketplaceNotePath = Join-Path $marketplaceDir $alienMarketplaceNoteName
Set-Content -LiteralPath $alienMarketplaceNotePath -Value ("{0}`n" -f $alienMarketplaceNoteMarker) -Encoding UTF8

$alienUserSkillDir = Join-Path $userSkillsRoot $alienSkillId
New-Item -ItemType Directory -Path $alienUserSkillDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $alienUserSkillDir 'SKILL.md') -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

$alienHomeSkillDir = Join-Path $homeSkillsRoot $alienSkillId
New-Item -ItemType Directory -Path $alienHomeSkillDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $alienHomeSkillDir 'SKILL.md') -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

$syncLines2 = @(& $syncAgentScript -Agent codex -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
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
    Write-Fail -TestName $keepTest -Reason 'alien plugin skill directory must survive keyed uninstall'
}
$alienSkillText = [System.IO.File]::ReadAllText((Join-Path $alienSkillDir 'SKILL.md'))
if ($alienSkillText -notmatch [regex]::Escape($alienSkillMarker)) {
    Write-Fail -TestName $keepTest -Reason 'alien plugin skill content must be preserved'
}

if (-not (Test-Path -LiteralPath $alienHookPath)) {
    Write-Fail -TestName $keepTest -Reason 'alien hook file must survive keyed uninstall'
}
$alienHookText = [System.IO.File]::ReadAllText($alienHookPath)
if ($alienHookText -notmatch [regex]::Escape($alienHookMarker)) {
    Write-Fail -TestName $keepTest -Reason 'alien hook content must be preserved'
}

if (-not (Test-Path -LiteralPath $alienConfigPath)) {
    Write-Fail -TestName $keepTest -Reason '.codex/config.toml alien path must not be touched (RN07)'
}
$alienConfigText = [System.IO.File]::ReadAllText($alienConfigPath)
if ($alienConfigText -notmatch [regex]::Escape($alienConfigMarker)) {
    Write-Fail -TestName $keepTest -Reason 'alien .codex config content must be preserved'
}

if (-not (Test-Path -LiteralPath $alienMarketplaceNotePath)) {
    Write-Fail -TestName $keepTest -Reason 'alien marketplace-adjacent file must survive'
}
$alienNoteText = [System.IO.File]::ReadAllText($alienMarketplaceNotePath)
if ($alienNoteText -notmatch [regex]::Escape($alienMarketplaceNoteMarker)) {
    Write-Fail -TestName $keepTest -Reason 'alien marketplace note content must be preserved'
}

if (-not (Test-Path -LiteralPath (Join-Path $alienUserSkillDir 'SKILL.md'))) {
    Write-Fail -TestName $keepTest -Reason 'alien USER skill must survive keyed uninstall'
}

if (-not (Test-Path -LiteralPath (Join-Path $alienHomeSkillDir 'SKILL.md'))) {
    Write-Fail -TestName $keepTest -Reason 'alien home skill ($ discovery) must survive keyed uninstall'
}

Assert-CodexToolkitArtifactsAbsent -TestName $keepTest

# Idempotent / WhatIf smoke
$whatIfResult = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot -WhatIf
if ($null -eq $whatIfResult -or $whatIfResult.Success -ne $true -or $whatIfResult.WhatIf -ne $true) {
    Write-Fail -TestName $keepTest -Reason 'Uninstall-Toolkit -WhatIf must succeed after keyed removal'
}

$idempotent = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $idempotent -or $idempotent.Success -ne $true) {
    Write-Fail -TestName $keepTest -Reason 'idempotent Uninstall-Toolkit must remain Success when artifacts already gone'
}

# Cleanup alien probes so fixture stays tidy for later steps
Remove-Item -LiteralPath $alienSkillDir -Recurse -Force
Remove-Item -LiteralPath $alienHookPath -Force
Remove-Item -LiteralPath $alienConfigPath -Force
Remove-Item -LiteralPath $alienConfigDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $alienMarketplaceNotePath -Force
Remove-Item -LiteralPath $alienUserSkillDir -Recurse -Force
Remove-Item -LiteralPath $alienHomeSkillDir -Recurse -Force

# Restore a clean published fixture for subsequent steps / local use
Clear-CodexFixturePublishedArtifacts
$restoreLines = @(& $syncAgentScript -Agent codex -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
$restoreExit = $LASTEXITCODE
if ($null -eq $restoreExit) { $restoreExit = 0 }
if ($restoreExit -ne 0) {
    Write-Fail -TestName 'Assert-CodexKeyedUninstallRestore' -Reason ("fixture restore sync failed (exit {0}): {1}" -f $restoreExit, ($restoreLines -join [Environment]::NewLine).Trim())
}

Write-Pass -TestName $keepTest

Write-Host 'Assert-CodexKeyedUninstall: ALL PASS'
exit 0
