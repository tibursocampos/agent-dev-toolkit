#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallOpenCodeFixture
#   Should_KeepUnrelatedFiles_When_UninstallOpenCodeFixture
# E2E: sync-agent -> validate-agent -> Uninstall-Toolkit on fixture (CU03 / RN07)
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

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-OpenCodeKeyedUninstallPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $syncAgentScript)) {
    Write-Fail -TestName 'Assert-OpenCodeKeyedUninstallPreconditions' -Reason ("missing {0}" -f $syncAgentScript)
}
if (-not (Test-Path -LiteralPath $validateAgentScript)) {
    Write-Fail -TestName 'Assert-OpenCodeKeyedUninstallPreconditions' -Reason ("missing {0}" -f $validateAgentScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$opencodeModulePath = Join-Path $repoRoot 'adapters\opencode\OpenCodeAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\opencode'
$skillsDirName = 'skills'
$agentsFileName = 'AGENTS.md'
$pluginsDirName = 'plugins'
$pluginMarkerFileName = 'agent-dev-toolkit-marker.js'
$fixtureReadmeName = 'README.md'
$alienSkillId = 'user-alien-skill-'
$alienPluginFileName = 'user-alien-plugin-.js'
$alienPluginContent = '// alien OpenCode plugin - must survive Uninstall-Toolkit (RN07)'
$alienSkillManifestName = 'SKILL.md'
$alienSkillManifestContent = "# Alien skill`nMust survive keyed uninstall.`n"

if (-not (Test-Path -LiteralPath $opencodeModulePath)) {
    Write-Fail -TestName 'Assert-OpenCodeKeyedUninstallPreconditions' -Reason ("missing OpenCode module: {0}" -f $opencodeModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-OpenCodeKeyedUninstallPreconditions' -Reason ("missing OpenCode fixture: {0}" -f $fixtureInstallRoot)
}

. $opencodeModulePath

$skillsPath = Join-Path $fixtureInstallRoot $skillsDirName
$agentsPath = Join-Path $fixtureInstallRoot $agentsFileName
$pluginsPath = Join-Path $fixtureInstallRoot $pluginsDirName
$pluginMarkerPath = Join-Path $pluginsPath $pluginMarkerFileName
$fixtureReadmePath = Join-Path $fixtureInstallRoot $fixtureReadmeName
$alienSkillPath = Join-Path $skillsPath $alienSkillId
$alienSkillManifestPath = Join-Path $alienSkillPath $alienSkillManifestName
$alienPluginPath = Join-Path $pluginsPath $alienPluginFileName
$pluginsGitkeepPath = Join-Path $pluginsPath '.gitkeep'

function Ensure-AlienArtifacts {
    if (-not (Test-Path -LiteralPath $alienSkillPath)) {
        New-Item -ItemType Directory -Path $alienSkillPath -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($alienSkillManifestPath, $alienSkillManifestContent)
    if (-not (Test-Path -LiteralPath $pluginsPath)) {
        New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($alienPluginPath, $alienPluginContent)
}

function Assert-ToolkitArtifactsAbsent {
    param([Parameter(Mandatory = $true)][string] $TestName)

    $coreSkillsRoot = Join-Path (Join-Path $repoRoot 'core') $skillsDirName
    $managedIds = @(Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force | Select-Object -ExpandProperty Name)
    foreach ($id in $managedIds) {
        $managedSkillPath = Join-Path $skillsPath $id
        if (Test-Path -LiteralPath $managedSkillPath) {
            Write-Fail -TestName $TestName -Reason ("managed skill still present after uninstall: {0}" -f $id)
        }
    }

    if (Test-Path -LiteralPath $agentsPath) {
        Write-Fail -TestName $TestName -Reason 'AGENTS.md must be removed by keyed uninstall'
    }
    if (Test-Path -LiteralPath $pluginMarkerPath) {
        Write-Fail -TestName $TestName -Reason 'toolkit plugin marker must be removed by keyed uninstall'
    }
}

function Assert-UnrelatedPreserved {
    param([Parameter(Mandatory = $true)][string] $TestName)

    if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
        Write-Fail -TestName $TestName -Reason 'InstallRoot itself must not be wiped (RN07)'
    }
    if (-not (Test-Path -LiteralPath $fixtureReadmePath)) {
        Write-Fail -TestName $TestName -Reason 'fixture README.md must survive uninstall'
    }
    if (-not (Test-Path -LiteralPath $skillsPath)) {
        Write-Fail -TestName $TestName -Reason 'skills/ directory shell must survive (keyed removal only)'
    }
    if (-not (Test-Path -LiteralPath $pluginsPath)) {
        Write-Fail -TestName $TestName -Reason 'plugins/ directory shell must survive (keyed removal only)'
    }
    if (-not (Test-Path -LiteralPath $alienSkillManifestPath)) {
        Write-Fail -TestName $TestName -Reason 'alien skill must survive keyed uninstall'
    }
    if (-not (Test-Path -LiteralPath $alienPluginPath)) {
        Write-Fail -TestName $TestName -Reason 'alien plugin must survive keyed uninstall'
    }
    $alienPluginText = [System.IO.File]::ReadAllText($alienPluginPath)
    if ($alienPluginText -ne $alienPluginContent) {
        Write-Fail -TestName $TestName -Reason 'alien plugin content must be unchanged'
    }
    if ((Test-Path -LiteralPath $pluginsGitkeepPath) -eq $false) {
        # .gitkeep is optional after publish; only assert if it existed before - soft check skipped
    }
}

# --- E2E seed: sync -> validate ---
& $syncAgentScript -Agent opencode -InstallRoot $fixtureInstallRoot
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
if ($syncExit -ne 0) {
    Write-Fail -TestName 'Assert-OpenCodeKeyedUninstallE2ESync' -Reason ("sync-agent -Agent opencode failed (exit {0})" -f $syncExit)
}

& $validateAgentScript -Agent opencode -InstallRoot $fixtureInstallRoot -Quiet
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName 'Assert-OpenCodeKeyedUninstallE2EValidate' -Reason ("validate-agent -Agent opencode failed (exit {0})" -f $validateExit)
}

Ensure-AlienArtifacts

# --- Should_RemoveToolkitArtifacts_When_UninstallOpenCodeFixture ---
$removeName = 'Should_RemoveToolkitArtifacts_When_UninstallOpenCodeFixture'

$uninstallResult = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallResult -or $uninstallResult.Implemented -ne $true) {
    Write-Fail -TestName $removeName -Reason 'Uninstall-Toolkit must be implemented'
}
if ($uninstallResult.Success -ne $true -or $uninstallResult.ExitCode -ne 0) {
    Write-Fail -TestName $removeName -Reason ("expected Success=true ExitCode=0; got Success={0} Message={1}" -f $uninstallResult.Success, $uninstallResult.Message)
}
if ($null -eq $uninstallResult.KeyedOnly -or $uninstallResult.KeyedOnly -ne $true) {
    Write-Fail -TestName $removeName -Reason 'KeyedOnly must be true (RN07)'
}
if ($null -eq $uninstallResult.WholesaleWipe -or $uninstallResult.WholesaleWipe -ne $false) {
    Write-Fail -TestName $removeName -Reason 'WholesaleWipe must be false (RN07)'
}
if ($uninstallResult.RemovedCount -lt 1) {
    Write-Fail -TestName $removeName -Reason 'expected at least one keyed path removed after sync'
}
if ([string]$uninstallResult.Message -notmatch '(?i)keyed|RN07|wholesale') {
    Write-Fail -TestName $removeName -Reason 'uninstall message must document keyed / RN07 semantics'
}

Assert-ToolkitArtifactsAbsent -TestName $removeName

# Smoke must fail after uninstall (skills/AGENTS gone) - proves removal took effect
$smokeAfter = Invoke-SmokeValidate -InstallRoot $fixtureInstallRoot
if ($null -eq $smokeAfter -or $smokeAfter.Success -ne $false) {
    Write-Fail -TestName $removeName -Reason 'Invoke-SmokeValidate must fail after uninstall removed toolkit artifacts'
}

Write-Pass -TestName $removeName

# --- Should_KeepUnrelatedFiles_When_UninstallOpenCodeFixture ---
$keepName = 'Should_KeepUnrelatedFiles_When_UninstallOpenCodeFixture'

Assert-UnrelatedPreserved -TestName $keepName

# Re-run uninstall when already clean - still Success, still preserve aliens
$uninstallAgain = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallAgain -or $uninstallAgain.Success -ne $true -or $uninstallAgain.Implemented -ne $true) {
    Write-Fail -TestName $keepName -Reason 'idempotent Uninstall-Toolkit must remain Success when artifacts already gone'
}
Assert-UnrelatedPreserved -TestName $keepName

# WhatIf must not delete aliens or recreate wipe
Ensure-AlienArtifacts
# Re-sync then WhatIf
& $syncAgentScript -Agent opencode -InstallRoot $fixtureInstallRoot
$syncWhatIfPrep = $LASTEXITCODE
if ($null -eq $syncWhatIfPrep) { $syncWhatIfPrep = 0 }
if ($syncWhatIfPrep -ne 0) {
    Write-Fail -TestName $keepName -Reason ("sync before WhatIf failed (exit {0})" -f $syncWhatIfPrep)
}
Ensure-AlienArtifacts

$whatIfResult = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot -WhatIf
if ($null -eq $whatIfResult -or $whatIfResult.Success -ne $true -or $whatIfResult.WhatIf -ne $true) {
    Write-Fail -TestName $keepName -Reason 'WhatIf uninstall must return Success with WhatIf=true'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $keepName -Reason 'WhatIf must not remove AGENTS.md'
}
if (-not (Test-Path -LiteralPath $pluginMarkerPath)) {
    Write-Fail -TestName $keepName -Reason 'WhatIf must not remove plugin marker'
}
if (-not (Test-Path -LiteralPath $alienSkillManifestPath)) {
    Write-Fail -TestName $keepName -Reason 'WhatIf must preserve alien skill'
}
if (-not (Test-Path -LiteralPath $alienPluginPath)) {
    Write-Fail -TestName $keepName -Reason 'WhatIf must preserve alien plugin'
}

# Final e2e: real uninstall after WhatIf sync state
$finalUninstall = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $finalUninstall -or $finalUninstall.Success -ne $true) {
    Write-Fail -TestName $keepName -Reason 'final Uninstall-Toolkit after WhatIf prep must succeed'
}
Assert-ToolkitArtifactsAbsent -TestName $keepName
Assert-UnrelatedPreserved -TestName $keepName

# Cleanup alien artifacts so fixture stays lean for sibling asserts (keep README / dir shells)
if (Test-Path -LiteralPath $alienSkillPath) {
    Remove-Item -LiteralPath $alienSkillPath -Recurse -Force
}
if (Test-Path -LiteralPath $alienPluginPath) {
    Remove-Item -LiteralPath $alienPluginPath -Force
}

# Restore publish so later  steps / local validate still have a complete fixture
& $syncAgentScript -Agent opencode -InstallRoot $fixtureInstallRoot
$restoreExit = $LASTEXITCODE
if ($null -eq $restoreExit) { $restoreExit = 0 }
if ($restoreExit -ne 0) {
    Write-Fail -TestName $keepName -Reason ("fixture restore sync failed (exit {0})" -f $restoreExit)
}

Write-Pass -TestName $keepName

Write-Host 'Assert-OpenCodeKeyedUninstall: ALL PASS'
exit 0
