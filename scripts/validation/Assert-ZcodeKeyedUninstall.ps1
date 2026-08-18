#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallZcodeFixture
#   Should_KeepUnrelatedFilesAndSdd_When_UninstallZcodeFixture
#   Should_FailClosedWhen_InvalidJsonOverlayOnUninstallZcodeFixture
#   Should_NotMutateOnWhatIfAndBeIdempotent_When_UninstallZcodeFixture
#
# CU03 / RN07: keyed uninstall + e2e sync -> validate -> uninstall on ZCode fixture.
# SDD sessions/manifest must survive uninstall.
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
        Write-Fail -TestName 'Assert-ZcodeKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$zcodeModulePath = Join-Path $repoRoot 'adapters\zcode\ZCodeAdapter.ps1'
$seedFixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\zcode-install-root'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\zcode-keyed-uninstall-work'
$fixtureInstallRoot = $workInstallRoot
$skillsRoot = Join-Path $fixtureInstallRoot 'skills'
$agentsPath = Join-Path $fixtureInstallRoot 'AGENTS.md'
$customAgentSamplePath = Join-Path $fixtureInstallRoot 'agents\repo-analyst.md'
$cliConfigPath = Join-Path $fixtureInstallRoot 'cli\config.json'
$hooksJsonPath = Join-Path $fixtureInstallRoot 'hooks\hooks.json'
$sddRoot = Join-Path $fixtureInstallRoot 'sdd'
$sessionsPath = Join-Path $sddRoot 'sessions'
$manifestPath = Join-Path $sddRoot 'manifest.json'
$gitkeepName = '.gitkeep'
$alienSkillId = 'alien-user-skill'
$alienSkillMarker = 'alien-skill-keep'
$alienCliKey = 'operatorCustomKey'
$alienCliValue = 'must-survive-uninstall'
$alienHooksKey = 'operatorHooksKey'
$alienHooksValue = 'must-survive-uninstall'
$zcodeCliHooksMarker = 'agent-dev-toolkit-zcode-hooks'
$zcodeHooksSessionMarker = 'agent-dev-toolkit-zcode-session-start'
$invalidJsonOverlayPayload = '{ "hooks": { invalid }'
$sessionProbeFileName = 'uninstall-preserve-probe.json'
$sessionProbeMarker = 'sdd-session-must-survive'

if (-not (Test-Path -LiteralPath $zcodeModulePath)) {
    Write-Fail -TestName 'Assert-ZcodeKeyedUninstallPreconditions' -Reason ("missing ZCode module: {0}" -f $zcodeModulePath)
}
if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-Fail -TestName 'Assert-ZcodeKeyedUninstallPreconditions' -Reason ("missing ZCode seed fixture: {0}" -f $seedFixtureRoot)
}

. $zcodeModulePath

function Initialize-ZcodeKeyedUninstallWorkRoot {
    if (Test-Path -LiteralPath $workInstallRoot) {
        Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
    }
    Copy-Item -LiteralPath $seedFixtureRoot -Destination $workInstallRoot -Recurse -Force
}

function Invoke-ZcodeKeyedUninstallSync {
    param([Parameter(Mandatory = $true)][string] $TestName)

    $syncLines = @(& $syncAgentScript -Agent zcode -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
    $syncExit = $LASTEXITCODE
    if ($null -eq $syncExit) { $syncExit = 0 }
    if ($syncExit -ne 0) {
        Write-Fail -TestName $TestName -Reason ("sync-agent -Agent zcode failed (exit {0}): {1}" -f $syncExit, ($syncLines -join [Environment]::NewLine).Trim())
    }
}

function Clear-ZcodePublishedTreeContents {
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
    } | ForEach-Object {
        $target = $_.FullName
        if (Test-Path -LiteralPath $target) {
            Get-ChildItem -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue |
                ForEach-Object { $_.Attributes = 'Normal' }
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
        }
    }
}

function Clear-ZcodeFixturePublishedArtifacts {
    Clear-ZcodePublishedTreeContents -DirectoryPath $skillsRoot
    if (Test-Path -LiteralPath $agentsPath) {
        Remove-Item -LiteralPath $agentsPath -Force
    }
    if (Test-Path -LiteralPath $cliConfigPath) {
        Remove-Item -LiteralPath $cliConfigPath -Force
    }
    if (Test-Path -LiteralPath $hooksJsonPath) {
        Remove-Item -LiteralPath $hooksJsonPath -Force
    }
}

function Test-ZcodeToolkitSkillPresent {
    $knownSkillId = 'commit'
    return (Test-Path -LiteralPath (Join-Path (Join-Path $skillsRoot $knownSkillId) 'SKILL.md'))
}

function Test-ZcodeToolkitHooksMarkerPresent {
    if (-not (Test-Path -LiteralPath $cliConfigPath)) {
        return $false
    }
    $raw = [System.IO.File]::ReadAllText($cliConfigPath)
    return ($raw -match [regex]::Escape($zcodeCliHooksMarker))
}

function Test-ZcodeToolkitHooksOverlayPresent {
    if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
        return $false
    }
    $raw = [System.IO.File]::ReadAllText($hooksJsonPath)
    return ($raw -match [regex]::Escape($zcodeHooksSessionMarker))
}

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Assert-ZcodeAlienJsonKeysPreserved {
    param([Parameter(Mandatory = $true)][string] $TestName)

    if (-not (Test-Path -LiteralPath $cliConfigPath)) {
        Write-Fail -TestName $TestName -Reason 'cli/config.json must survive reverse-merge uninstall'
    }
    $cliConfig = Get-Content -LiteralPath $cliConfigPath -Raw | ConvertFrom-Json
    if ($null -eq $cliConfig.$alienCliKey -or [string]$cliConfig.$alienCliKey -ne $alienCliValue) {
        Write-Fail -TestName $TestName -Reason 'alien cli/config.json key must survive reverse-merge uninstall'
    }
    if ($null -ne $cliConfig.hooks -and ($cliConfig.hooks | ConvertTo-Json -Compress -Depth 10) -match [regex]::Escape($zcodeCliHooksMarker)) {
        Write-Fail -TestName $TestName -Reason 'toolkit cli hooks marker must be removed on uninstall'
    }

    if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
        Write-Fail -TestName $TestName -Reason 'hooks/hooks.json must survive reverse-merge uninstall'
    }
    $hooksConfig = Get-Content -LiteralPath $hooksJsonPath -Raw | ConvertFrom-Json
    if ($null -eq $hooksConfig.$alienHooksKey -or [string]$hooksConfig.$alienHooksKey -ne $alienHooksValue) {
        Write-Fail -TestName $TestName -Reason 'alien hooks/hooks.json key must survive reverse-merge uninstall'
    }
    $hooksJson = ($hooksConfig | ConvertTo-Json -Compress -Depth 10)
    if ($hooksJson -match [regex]::Escape($zcodeHooksSessionMarker)) {
        Write-Fail -TestName $TestName -Reason 'toolkit hooks/hooks.json overlay must be removed on uninstall'
    }
}

# --- Should_RemoveToolkitArtifacts_When_UninstallZcodeFixture ---
$removeTest = 'Should_RemoveToolkitArtifacts_When_UninstallZcodeFixture'

Initialize-ZcodeKeyedUninstallWorkRoot
Clear-ZcodeFixturePublishedArtifacts
Invoke-ZcodeKeyedUninstallSync -TestName $removeTest

if (-not (Test-ZcodeToolkitSkillPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit skills after sync'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $removeTest -Reason 'expected AGENTS.md after sync'
}
if (-not (Test-Path -LiteralPath $customAgentSamplePath)) {
    Write-Fail -TestName $removeTest -Reason 'expected custom subagent file after sync'
}
if (-not (Test-ZcodeToolkitHooksMarkerPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit hooks marker in cli/config.json after sync'
}
if (-not (Test-Path -LiteralPath $sessionsPath)) {
    Write-Fail -TestName $removeTest -Reason 'expected sdd/sessions after sync'
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Fail -TestName $removeTest -Reason 'expected sdd/manifest.json after sync'
}

$sessionProbePath = Join-Path $sessionsPath $sessionProbeFileName
Set-Content -LiteralPath $sessionProbePath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionProbeMarker) -Encoding UTF8
$manifestBefore = [System.IO.File]::ReadAllText($manifestPath)

$validateLines = @(& $validateAgentScript -Agent zcode -Quiet -SkipCore *>&1 | ForEach-Object { "$_" })
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("validate-agent -Agent zcode -SkipCore failed (exit {0}): {1}" -f $validateExit, ($validateLines -join [Environment]::NewLine).Trim())
}

$uninstall = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstall -or $uninstall.Implemented -ne $true -or $uninstall.Success -ne $true) {
    Write-Fail -TestName $removeTest -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstall) { 'null' } else { $uninstall.Message }))
}
if ($uninstall.ExitCode -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("expected ExitCode 0, got {0}" -f $uninstall.ExitCode)
}

if (Test-ZcodeToolkitSkillPresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit skills should be removed after uninstall'
}
if (Test-Path -LiteralPath $agentsPath) {
    Write-Fail -TestName $removeTest -Reason 'AGENTS.md should be removed after uninstall'
}
if (Test-Path -LiteralPath $customAgentSamplePath) {
    Write-Fail -TestName $removeTest -Reason 'custom subagent file should be removed after uninstall'
}
if (Test-ZcodeToolkitHooksMarkerPresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit hooks marker should be removed from cli/config.json'
}
if (Test-ZcodeToolkitHooksOverlayPresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit hooks/hooks.json overlay should be removed on uninstall'
}

if (-not (Test-Path -LiteralPath $sessionProbePath)) {
    Write-Fail -TestName $removeTest -Reason 'sdd/sessions probe must survive uninstall'
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Fail -TestName $removeTest -Reason 'sdd/manifest.json must survive uninstall'
}
$manifestAfter = [System.IO.File]::ReadAllText($manifestPath)
if ($manifestAfter -ne $manifestBefore) {
    Write-Fail -TestName $removeTest -Reason 'sdd/manifest.json must not be modified by uninstall'
}

Write-Pass -TestName $removeTest

# --- Should_KeepUnrelatedFilesAndSdd_When_UninstallZcodeFixture ---
$keepTest = 'Should_KeepUnrelatedFilesAndSdd_When_UninstallZcodeFixture'

Clear-ZcodeFixturePublishedArtifacts

$alienSkillDir = Join-Path $skillsRoot $alienSkillId
New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $alienSkillDir 'SKILL.md') -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

$cliDir = Split-Path -Parent $cliConfigPath
if (-not (Test-Path -LiteralPath $cliDir)) {
    New-Item -ItemType Directory -Path $cliDir -Force | Out-Null
}
Set-Content -LiteralPath $cliConfigPath -Value ("{{ `"{0}`": `"{1}`" }}`n" -f $alienCliKey, $alienCliValue) -Encoding UTF8

$hooksDir = Split-Path -Parent $hooksJsonPath
if (-not (Test-Path -LiteralPath $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
}
Set-Content -LiteralPath $hooksJsonPath -Value ("{{ `"{0}`": `"{1}`" }}`n" -f $alienHooksKey, $alienHooksValue) -Encoding UTF8

if (-not (Test-Path -LiteralPath $sessionsPath)) {
    New-Item -ItemType Directory -Path $sessionsPath -Force | Out-Null
}
Set-Content -LiteralPath $sessionProbePath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionProbeMarker) -Encoding UTF8

Invoke-ZcodeKeyedUninstallSync -TestName $keepTest

$uninstallKeep = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallKeep -or $uninstallKeep.Success -ne $true) {
    Write-Fail -TestName $keepTest -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstallKeep) { 'null' } else { $uninstallKeep.Message }))
}

if (-not (Test-Path -LiteralPath (Join-Path $alienSkillDir 'SKILL.md'))) {
    Write-Fail -TestName $keepTest -Reason 'alien skill directory must survive keyed uninstall'
}
if (-not (Test-Path -LiteralPath $cliConfigPath)) {
    Write-Fail -TestName $keepTest -Reason 'cli/config.json must survive (alien keys preserved)'
}
Assert-ZcodeAlienJsonKeysPreserved -TestName $keepTest
if (-not (Test-Path -LiteralPath $sessionProbePath)) {
    Write-Fail -TestName $keepTest -Reason 'sdd session probe must survive keyed uninstall'
}

if (Test-ZcodeToolkitSkillPresent) {
    Write-Fail -TestName $keepTest -Reason 'toolkit skills should still be removed while aliens remain'
}
if (Test-Path -LiteralPath $agentsPath) {
    Write-Fail -TestName $keepTest -Reason 'toolkit AGENTS.md should still be removed'
}

Write-Pass -TestName $keepTest

# --- Should_FailClosedWhen_InvalidJsonOverlayOnUninstallZcodeFixture ---
# --- Should_NotMutateOnWhatIfAndBeIdempotent_When_UninstallZcodeFixture ---
$invalidJsonTest = 'Should_FailClosedWhen_InvalidJsonOverlayOnUninstallZcodeFixture'
$whatIfTest = 'Should_NotMutateOnWhatIfAndBeIdempotent_When_UninstallZcodeFixture'

Clear-ZcodeFixturePublishedArtifacts
Invoke-ZcodeKeyedUninstallSync -TestName $invalidJsonTest

if (-not (Test-ZcodeToolkitSkillPresent)) {
    Write-Fail -TestName $invalidJsonTest -Reason 'expected toolkit skills after sync before invalid JSON injection'
}

$cliBeforeInvalid = [System.IO.File]::ReadAllText($cliConfigPath)
[System.IO.File]::WriteAllText($cliConfigPath, $invalidJsonOverlayPayload, (Get-Utf8NoBomEncoding))

$uninstallInvalid = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallInvalid -or $uninstallInvalid.Success -ne $false) {
    Write-Fail -TestName $invalidJsonTest -Reason 'Uninstall-Toolkit must fail closed when cli/config.json overlay is invalid (JSON-first contract)'
}
if ($uninstallInvalid.ExitCode -eq 0) {
    Write-Fail -TestName $invalidJsonTest -Reason 'invalid JSON overlay uninstall must not return ExitCode 0'
}
if (-not (Test-ZcodeToolkitSkillPresent)) {
    Write-Fail -TestName $invalidJsonTest -Reason 'toolkit FS skills must remain when JSON reverse-merge fails first'
}

Write-Pass -TestName $invalidJsonTest

[System.IO.File]::WriteAllText($cliConfigPath, $cliBeforeInvalid, (Get-Utf8NoBomEncoding))

if (-not (Test-Path -LiteralPath $sessionsPath)) {
    New-Item -ItemType Directory -Path $sessionsPath -Force | Out-Null
}
Set-Content -LiteralPath $sessionProbePath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionProbeMarker) -Encoding UTF8
$manifestBeforeWhatIf = [System.IO.File]::ReadAllText($manifestPath)
$cliBeforeWhatIf = if (Test-Path -LiteralPath $cliConfigPath) { [System.IO.File]::ReadAllText($cliConfigPath) } else { $null }

$whatIfResult = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot -WhatIf
if ($null -eq $whatIfResult -or $whatIfResult.Success -ne $true -or $whatIfResult.WhatIf -ne $true) {
    Write-Fail -TestName $whatIfTest -Reason 'Uninstall-Toolkit -WhatIf must succeed without mutating'
}
if (-not (Test-ZcodeToolkitSkillPresent)) {
    Write-Fail -TestName $whatIfTest -Reason 'WhatIf must not remove toolkit skills'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $whatIfTest -Reason 'WhatIf must not remove AGENTS.md'
}
if ($null -ne $cliBeforeWhatIf -and [System.IO.File]::ReadAllText($cliConfigPath) -ne $cliBeforeWhatIf) {
    Write-Fail -TestName $whatIfTest -Reason 'WhatIf must not mutate cli/config.json'
}

$uninstallReal = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallReal -or $uninstallReal.Success -ne $true) {
    Write-Fail -TestName $whatIfTest -Reason ("real Uninstall-Toolkit after WhatIf must succeed, got: {0}" -f $(if ($null -eq $uninstallReal) { 'null' } else { $uninstallReal.Message }))
}
if (Test-ZcodeToolkitSkillPresent) {
    Write-Fail -TestName $whatIfTest -Reason 'real uninstall must remove toolkit skills after WhatIf'
}

$uninstallAgain = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallAgain -or $uninstallAgain.Success -ne $true) {
    Write-Fail -TestName $whatIfTest -Reason 'idempotent second Uninstall-Toolkit must remain Success'
}
if ($uninstallAgain.RemovedCount -gt 0) {
    Write-Fail -TestName $whatIfTest -Reason 'idempotent second Uninstall-Toolkit should remove little or nothing'
}
if (-not (Test-Path -LiteralPath $sessionProbePath)) {
    Write-Fail -TestName $whatIfTest -Reason 'sdd session probe must survive idempotent uninstall cycle'
}
if ([System.IO.File]::ReadAllText($manifestPath) -ne $manifestBeforeWhatIf) {
    Write-Fail -TestName $whatIfTest -Reason 'sdd/manifest.json must remain unchanged across WhatIf/idempotent uninstall'
}

Write-Pass -TestName $whatIfTest

if (Test-Path -LiteralPath $workInstallRoot) {
    Remove-Item -LiteralPath $workInstallRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Assert-ZcodeKeyedUninstall: ALL PASS'
exit 0
