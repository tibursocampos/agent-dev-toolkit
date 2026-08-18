#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallHermesFixture
#   Should_KeepUnrelatedFiles_When_UninstallHermesFixture
#
# CU03 / RN07: keyed uninstall on a temp copy of the Hermes fixture via direct
# adapter module calls (sync-agent cannot resolve hermes until registry wave).
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
    Write-Fail -TestName 'Assert-HermesKeyedUninstallPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$hermesModulePath = Join-Path $repoRoot 'adapters\hermes\HermesAdapter.ps1'
$seedFixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\hermes'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\hermes-keyed-uninstall-work'
$configYamlName = 'config.yaml'
$memoryFileName = 'MEMORY.md'
$soulFileName = 'SOUL.md'
$agentsFileName = 'AGENTS.md'
$skillsDirectoryName = 'skills'
$sddDirectoryName = 'sdd'
$sessionsDirectoryName = 'sessions'
$manifestFileName = 'manifest.json'
$skillManifestName = 'SKILL.md'
$knownSkillId = 'commit'
$alienSkillId = 'alien-user-skill'
$alienSkillMarker = 'alien-skill-keep'
$alienMemoryMarker = 'alien-memory-keep'
$alienSoulMarker = 'alien-soul-keep'
$configYamlMarker = 'keep=true'
$sessionAlienName = 'alien-session.json'
$sessionAlienMarker = 'alien-session-keep'

if (-not (Test-Path -LiteralPath $hermesModulePath)) {
    Write-Fail -TestName 'Assert-HermesKeyedUninstallPreconditions' -Reason ("missing Hermes module: {0}" -f $hermesModulePath)
}
if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-Fail -TestName 'Assert-HermesKeyedUninstallPreconditions' -Reason ("missing Hermes fixture: {0}" -f $seedFixtureRoot)
}

. $hermesModulePath

function Remove-HermesKeyedUninstallWorkRoot {
    if (Test-Path -LiteralPath $workInstallRoot) {
        Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
    }
}

function Initialize-HermesKeyedUninstallWorkRoot {
    Remove-HermesKeyedUninstallWorkRoot
    New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $seedFixtureRoot -Force | Copy-Item -Destination $workInstallRoot -Recurse -Force
}

function Get-HermesWorkSkillsRoot {
    return (Join-Path $workInstallRoot $skillsDirectoryName)
}

function Get-HermesWorkAgentsPath {
    return (Join-Path $workInstallRoot $agentsFileName)
}

function Test-HermesToolkitSkillPresent {
    $published = Join-Path (Get-HermesWorkSkillsRoot) $knownSkillId
    return (Test-Path -LiteralPath (Join-Path $published $skillManifestName))
}

function Invoke-HermesDirectPublishAndPrepare {
    $skillsResult = Publish-Skills -InstallRoot $workInstallRoot
    if ($null -eq $skillsResult -or $skillsResult.Success -ne $true) {
        throw ("Publish-Skills failed: {0}" -f $(if ($null -eq $skillsResult) { 'null' } else { $skillsResult.Message }))
    }

    $policyResult = Publish-Policy -InstallRoot $workInstallRoot
    if ($null -eq $policyResult -or $policyResult.Success -ne $true) {
        throw ("Publish-Policy failed: {0}" -f $(if ($null -eq $policyResult) { 'null' } else { $policyResult.Message }))
    }

    $routerResult = Publish-Router -InstallRoot $workInstallRoot
    if ($null -eq $routerResult -or $routerResult.Success -ne $true) {
        throw ("Publish-Router failed: {0}" -f $(if ($null -eq $routerResult) { 'null' } else { $routerResult.Message }))
    }

    $hooksResult = Publish-Hooks -InstallRoot $workInstallRoot
    if ($null -eq $hooksResult -or $hooksResult.Success -ne $true) {
        throw ("Publish-Hooks failed: {0}" -f $(if ($null -eq $hooksResult) { 'null' } else { $hooksResult.Message }))
    }

    $agentsResult = Publish-Agents -InstallRoot $workInstallRoot
    if ($null -eq $agentsResult -or $agentsResult.Success -ne $true) {
        throw ("Publish-Agents failed: {0}" -f $(if ($null -eq $agentsResult) { 'null' } else { $agentsResult.Message }))
    }

    $sddResult = Get-SddRoot -InstallRoot $workInstallRoot -Prepare
    if ($null -eq $sddResult -or $sddResult.Success -ne $true) {
        throw ("Get-SddRoot -Prepare failed: {0}" -f $(if ($null -eq $sddResult) { 'null' } else { $sddResult.Message }))
    }
}

try {
    # --- Should_RemoveToolkitArtifacts_When_UninstallHermesFixture ---
    $removeTest = 'Should_RemoveToolkitArtifacts_When_UninstallHermesFixture'
    Initialize-HermesKeyedUninstallWorkRoot
    Invoke-HermesDirectPublishAndPrepare

    if (-not (Test-HermesToolkitSkillPresent)) {
        Write-Fail -TestName $removeTest -Reason 'expected toolkit skills under skills/ after publish'
    }
    if (-not (Test-Path -LiteralPath (Get-HermesWorkAgentsPath))) {
        Write-Fail -TestName $removeTest -Reason 'expected AGENTS.md after publish'
    }
    $memoryPath = Join-Path $workInstallRoot $memoryFileName
    if (-not (Test-Path -LiteralPath $memoryPath)) {
        Write-Fail -TestName $removeTest -Reason 'expected MEMORY.md seed after publish'
    }
    $soulPath = Join-Path $workInstallRoot $soulFileName
    if (Test-Path -LiteralPath $soulPath) {
        Write-Fail -TestName $removeTest -Reason 'publish must not create SOUL.md'
    }

    $smoke = Invoke-SmokeValidate -InstallRoot $workInstallRoot
    if ($null -eq $smoke -or $smoke.Success -ne $true) {
        Write-Fail -TestName $removeTest -Reason ("expected Invoke-SmokeValidate PASS, got: {0}" -f $(if ($null -eq $smoke) { 'null' } else { $smoke.Message }))
    }

    $uninstall = Uninstall-Toolkit -InstallRoot $workInstallRoot
    if ($null -eq $uninstall -or $uninstall.Implemented -ne $true -or $uninstall.Success -ne $true) {
        Write-Fail -TestName $removeTest -Reason ("expected successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstall) { 'null' } else { $uninstall.Message }))
    }
    if ($uninstall.ExitCode -ne 0) {
        Write-Fail -TestName $removeTest -Reason ("expected ExitCode 0, got {0}" -f $uninstall.ExitCode)
    }
    if ($uninstall.RemovedCount -lt 1) {
        Write-Fail -TestName $removeTest -Reason 'expected at least one keyed artifact removed'
    }

    if (Test-HermesToolkitSkillPresent) {
        Write-Fail -TestName $removeTest -Reason 'toolkit skills should be removed after uninstall'
    }
    if (Test-Path -LiteralPath (Get-HermesWorkAgentsPath)) {
        Write-Fail -TestName $removeTest -Reason 'AGENTS.md should be removed after uninstall'
    }
    if (-not (Test-Path -LiteralPath $memoryPath)) {
        Write-Fail -TestName $removeTest -Reason 'MEMORY.md seed must survive keyed uninstall'
    }
    if (-not (Test-Path -LiteralPath $workInstallRoot)) {
        Write-Fail -TestName $removeTest -Reason 'keyed uninstall must not wipe InstallRoot'
    }
    if (-not (Test-Path -LiteralPath (Get-HermesWorkSkillsRoot))) {
        Write-Fail -TestName $removeTest -Reason 'keyed uninstall must not wipe skills directory'
    }

    $sddRoot = Join-Path $workInstallRoot $sddDirectoryName
    $sessionsRoot = Join-Path $sddRoot $sessionsDirectoryName
    $manifestPath = Join-Path $sddRoot $manifestFileName
    if (-not (Test-Path -LiteralPath $sessionsRoot)) {
        Write-Fail -TestName $removeTest -Reason 'sdd/sessions must survive keyed uninstall'
    }
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Write-Fail -TestName $removeTest -Reason 'sdd/manifest.json must survive keyed uninstall'
    }

    Write-Pass -TestName $removeTest

    # --- Should_KeepUnrelatedFiles_When_UninstallHermesFixture ---
    $keepTest = 'Should_KeepUnrelatedFiles_When_UninstallHermesFixture'
    Initialize-HermesKeyedUninstallWorkRoot

    $alienSkillDir = Join-Path (Get-HermesWorkSkillsRoot) $alienSkillId
    New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $alienSkillDir $skillManifestName) -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

    $alienMemoryPath = Join-Path $workInstallRoot $memoryFileName
    Set-Content -LiteralPath $alienMemoryPath -Value ("# {0}`n" -f $alienMemoryMarker) -Encoding UTF8

    $alienSoulPath = Join-Path $workInstallRoot $soulFileName
    Set-Content -LiteralPath $alienSoulPath -Value ("# {0}`n" -f $alienSoulMarker) -Encoding UTF8

    $configYamlPath = Join-Path $workInstallRoot $configYamlName
    Set-Content -LiteralPath $configYamlPath -Value ("# {0}`n{1}`n" -f $configYamlName, $configYamlMarker) -Encoding UTF8

    Invoke-HermesDirectPublishAndPrepare

    $sddRoot = Join-Path $workInstallRoot $sddDirectoryName
    $sessionsRoot = Join-Path $sddRoot $sessionsDirectoryName
    if (-not (Test-Path -LiteralPath $sessionsRoot)) {
        New-Item -ItemType Directory -Path $sessionsRoot -Force | Out-Null
    }
    $sessionAlienPath = Join-Path $sessionsRoot $sessionAlienName
    Set-Content -LiteralPath $sessionAlienPath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionAlienMarker) -Encoding UTF8

    $uninstallKeep = Uninstall-Toolkit -InstallRoot $workInstallRoot
    if ($null -eq $uninstallKeep -or $uninstallKeep.Success -ne $true) {
        Write-Fail -TestName $keepTest -Reason ("expected successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstallKeep) { 'null' } else { $uninstallKeep.Message }))
    }

    if (-not (Test-Path -LiteralPath (Join-Path $alienSkillDir $skillManifestName))) {
        Write-Fail -TestName $keepTest -Reason 'alien skill directory must survive keyed uninstall'
    }
    $alienSkillText = [System.IO.File]::ReadAllText((Join-Path $alienSkillDir $skillManifestName))
    if ($alienSkillText -notmatch [regex]::Escape($alienSkillMarker)) {
        Write-Fail -TestName $keepTest -Reason 'alien skill content must be preserved'
    }

    $memoryText = [System.IO.File]::ReadAllText($alienMemoryPath)
    if ($memoryText -notmatch [regex]::Escape($alienMemoryMarker)) {
        Write-Fail -TestName $keepTest -Reason 'existing MEMORY.md must not be overwritten or removed'
    }

    $soulText = [System.IO.File]::ReadAllText($alienSoulPath)
    if ($soulText -notmatch [regex]::Escape($alienSoulMarker)) {
        Write-Fail -TestName $keepTest -Reason 'existing SOUL.md must not be overwritten or removed'
    }

    if (-not (Test-Path -LiteralPath $configYamlPath)) {
        Write-Fail -TestName $keepTest -Reason 'config.yaml must not be touched by uninstall'
    }

    $sessionText = [System.IO.File]::ReadAllText($sessionAlienPath)
    if ($sessionText -notmatch [regex]::Escape($sessionAlienMarker)) {
        Write-Fail -TestName $keepTest -Reason 'sdd/sessions alien file must be preserved'
    }

    $manifestPath = Join-Path $sddRoot $manifestFileName
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Write-Fail -TestName $keepTest -Reason 'sdd/manifest.json must be preserved'
    }

    if (Test-HermesToolkitSkillPresent) {
        Write-Fail -TestName $keepTest -Reason 'toolkit skills should still be removed while aliens remain'
    }
    if (Test-Path -LiteralPath (Get-HermesWorkAgentsPath)) {
        Write-Fail -TestName $keepTest -Reason 'toolkit AGENTS.md should still be removed'
    }

    Write-Pass -TestName $keepTest
}
finally {
    Remove-HermesKeyedUninstallWorkRoot
}

Write-Host 'Assert-HermesKeyedUninstall: ALL PASS'
exit 0
