#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallCursorFixture
#   Should_KeepUnrelatedFilesAndSdd_When_UninstallCursorFixture
#   Should_PreserveAlienHooksJsonAndStrictMatching_When_UninstallCursorFixture
#   Should_FailClosedWhen_InvalidHooksJsonOnUninstallCursorFixture
#   Should_NotMutateOnWhatIfAndBeIdempotent_When_UninstallCursorFixture
#
# CU03 / RN07: keyed uninstall + e2e sync -> validate -> uninstall on Cursor fixture.
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
        Write-Fail -TestName 'Assert-CursorKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$cursorModulePath = Join-Path $repoRoot 'adapters\cursor\CursorAdapter.ps1'
$seedFixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\cursor-install-root'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\cursor-keyed-uninstall-work'
$fixtureInstallRoot = $workInstallRoot
$skillsRoot = Join-Path $fixtureInstallRoot 'skills'
$rulesRoot = Join-Path $fixtureInstallRoot 'rules'
$hooksRoot = Join-Path $fixtureInstallRoot 'hooks'
$agentsPath = Join-Path $fixtureInstallRoot 'AGENTS.md'
$customAgentSamplePath = Join-Path $fixtureInstallRoot 'agents\repo-analyst.md'
$hooksJsonPath = Join-Path $fixtureInstallRoot 'hooks.json'
$sddRoot = Join-Path $fixtureInstallRoot 'sdd'
$sessionsPath = Join-Path $sddRoot 'sessions'
$manifestPath = Join-Path $sddRoot 'manifest.json'
$alienSkillId = 'alien-user-skill'
$alienRuleFileName = 'alien-user-rule.mdc'
$alienHookScriptName = 'alien-user-hook.ps1'
$sessionProbeFileName = 'uninstall-preserve-probe.json'
$alienSkillMarker = 'alien-skill-keep'
$alienRuleMarker = 'alien-rule-keep'
$alienHookMarker = 'alien-hook-keep'
$sessionProbeMarker = 'sdd-session-must-survive'
$alienHooksMetadataKey = 'metadata'
$alienHooksMetadataSource = 'user'
$broadPathHookCommand = 'powershell -NoProfile -Command Write-Output ''alien-broad-path-hook-survives''; & ./hooks/context-before-prompt.ps1'
$invalidHooksJsonPayload = '{ "version": 1, "hooks": { invalid }'

if (-not (Test-Path -LiteralPath $cursorModulePath)) {
    Write-Fail -TestName 'Assert-CursorKeyedUninstallPreconditions' -Reason ("missing Cursor module: {0}" -f $cursorModulePath)
}
if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-Fail -TestName 'Assert-CursorKeyedUninstallPreconditions' -Reason ("missing Cursor seed fixture: {0}" -f $seedFixtureRoot)
}

. $cursorModulePath

function Initialize-CursorKeyedUninstallWorkRoot {
    if (Test-Path -LiteralPath $workInstallRoot) {
        Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
    }
    Copy-Item -LiteralPath $seedFixtureRoot -Destination $workInstallRoot -Recurse -Force
}

function Invoke-CursorKeyedUninstallSync {
    param([Parameter(Mandatory = $true)][string] $TestName)

    $syncLines = @(& $syncAgentScript -Agent cursor -InstallRoot $fixtureInstallRoot *>&1 | ForEach-Object { "$_" })
    $syncExit = $LASTEXITCODE
    if ($null -eq $syncExit) { $syncExit = 0 }
    if ($syncExit -ne 0) {
        Write-Fail -TestName $TestName -Reason ("sync-agent -Agent cursor failed (exit {0}): {1}" -f $syncExit, ($syncLines -join [Environment]::NewLine).Trim())
    }
}

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Clear-CursorPublishedTreeContents {
    param(
        [Parameter(Mandatory = $true)]
        [string] $DirectoryPath
    )

    if (-not (Test-Path -LiteralPath $DirectoryPath)) {
        New-Item -ItemType Directory -Path $DirectoryPath -Force | Out-Null
        return
    }

    $cleared = $false
    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        try {
            Remove-Item -LiteralPath $DirectoryPath -Recurse -Force -ErrorAction Stop
            $cleared = $true
            break
        }
        catch {
            if ($attempt -lt 2) {
                Start-Sleep -Milliseconds 250
            }
        }
    }

    if (-not $cleared -and (Test-Path -LiteralPath $DirectoryPath)) {
        $emptyDir = Join-Path $env:TEMP ('adt-empty-{0}' -f [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        & robocopy.exe $emptyDir $DirectoryPath /MIR /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
        Remove-Item -LiteralPath $emptyDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path -LiteralPath $DirectoryPath)) {
        New-Item -ItemType Directory -Path $DirectoryPath -Force | Out-Null
    }
}

function Clear-CursorFixturePublishedArtifacts {
    Clear-CursorPublishedTreeContents -DirectoryPath $skillsRoot
    Clear-CursorPublishedTreeContents -DirectoryPath $rulesRoot
    Clear-CursorPublishedTreeContents -DirectoryPath $hooksRoot
    if (Test-Path -LiteralPath $agentsPath) {
        Remove-Item -LiteralPath $agentsPath -Force
    }
    if (Test-Path -LiteralPath $hooksJsonPath) {
        Remove-Item -LiteralPath $hooksJsonPath -Force
    }
}

function Test-CursorToolkitSkillPresent {
    $knownSkillId = 'commit'
    return (Test-Path -LiteralPath (Join-Path (Join-Path $skillsRoot $knownSkillId) 'SKILL.md'))
}

function Test-CursorToolkitRulePresent {
    $corePolicy = Join-Path (Join-Path $repoRoot 'core') 'policy'
    $sample = Get-ChildItem -LiteralPath $corePolicy -File | Select-Object -First 1
    if ($null -eq $sample) {
        return $false
    }

    $destName = [System.IO.Path]::ChangeExtension($sample.Name, '.mdc')
    return (Test-Path -LiteralPath (Join-Path $rulesRoot $destName))
}

function Test-CursorToolkitHookScriptPresent {
    $scriptName = '_hook-common.ps1'
    return (Test-Path -LiteralPath (Join-Path $hooksRoot $scriptName))
}

function Add-CursorFixtureHooksJsonAlienOverlay {
    if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
        throw 'hooks.json missing before alien overlay injection'
    }

    $payload = Get-Content -LiteralPath $hooksJsonPath -Raw | ConvertFrom-Json
    $payload | Add-Member -NotePropertyName $alienHooksMetadataKey -NotePropertyValue ([ordered]@{ source = $alienHooksMetadataSource }) -Force

    $beforeSubmit = @($payload.hooks.beforeSubmitPrompt)
    $beforeSubmit = ,@(@{ command = $broadPathHookCommand }) + $beforeSubmit
    $payload.hooks.beforeSubmitPrompt = $beforeSubmit

    $json = $payload | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($hooksJsonPath, $json, (Get-Utf8NoBomEncoding))
}

function Assert-CursorHooksJsonReverseMergePreserved {
    param([Parameter(Mandatory = $true)][string] $TestName)

    if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
        Write-Fail -TestName $TestName -Reason 'hooks.json must survive reverse-merge uninstall'
    }

    $payload = Get-Content -LiteralPath $hooksJsonPath -Raw | ConvertFrom-Json
    if ($null -eq $payload.$alienHooksMetadataKey -or [string]$payload.$alienHooksMetadataKey.source -ne $alienHooksMetadataSource) {
        Write-Fail -TestName $TestName -Reason 'alien top-level hooks.json metadata must survive reverse-merge'
    }

    $beforeSubmit = @($payload.hooks.beforeSubmitPrompt)
    $beforeSubmitCommands = @($beforeSubmit | ForEach-Object { [string]$_.command })
    if ($beforeSubmitCommands -notcontains $broadPathHookCommand) {
        Write-Fail -TestName $TestName -Reason 'broad-path hook without -File must survive strict uninstall matching'
    }
    if ($beforeSubmitCommands | Where-Object { $_ -match '(?i)-File\s+[^\r\n]*[\\/]hooks[\\/]context-before-prompt\.ps1' }) {
        Write-Fail -TestName $TestName -Reason 'toolkit -File beforeSubmitPrompt handler must be removed on uninstall'
    }

    foreach ($eventName in @('afterFileEdit', 'preCompact')) {
        if ($null -ne $payload.hooks.PSObject.Properties[$eventName]) {
            $eventCommands = @($payload.hooks.$eventName | ForEach-Object { [string]$_.command })
            if ($eventCommands | Where-Object { $_ -match '(?i)-File\s+[^\r\n]*[\\/]hooks[\\/]' }) {
                Write-Fail -TestName $TestName -Reason ("toolkit -File handler must be removed from {0}" -f $eventName)
            }
        }
    }
}

# --- Should_RemoveToolkitArtifacts_When_UninstallCursorFixture ---
$removeTest = 'Should_RemoveToolkitArtifacts_When_UninstallCursorFixture'

Initialize-CursorKeyedUninstallWorkRoot
Clear-CursorFixturePublishedArtifacts
Invoke-CursorKeyedUninstallSync -TestName $removeTest

if (-not (Test-CursorToolkitSkillPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit skills after sync'
}
if (-not (Test-CursorToolkitRulePresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit rules after sync'
}
if (-not (Test-CursorToolkitHookScriptPresent)) {
    Write-Fail -TestName $removeTest -Reason 'expected toolkit hook scripts after sync'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $removeTest -Reason 'expected AGENTS.md after sync'
}
if (-not (Test-Path -LiteralPath $customAgentSamplePath)) {
    Write-Fail -TestName $removeTest -Reason 'expected custom subagent file after sync'
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

$validateLines = @(& $validateAgentScript -Agent cursor -Quiet -SkipCore *>&1 | ForEach-Object { "$_" })
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $removeTest -Reason ("validate-agent -Agent cursor -SkipCore failed (exit {0}): {1}" -f $validateExit, ($validateLines -join [Environment]::NewLine).Trim())
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

if (Test-CursorToolkitSkillPresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit skills should be removed after uninstall'
}
if (Test-CursorToolkitRulePresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit rules should be removed after uninstall'
}
if (Test-CursorToolkitHookScriptPresent) {
    Write-Fail -TestName $removeTest -Reason 'toolkit hook scripts should be removed after uninstall'
}
if (Test-Path -LiteralPath $agentsPath) {
    Write-Fail -TestName $removeTest -Reason 'AGENTS.md should be removed after uninstall'
}
if (Test-Path -LiteralPath $customAgentSamplePath) {
    Write-Fail -TestName $removeTest -Reason 'custom subagent file should be removed after uninstall'
}

if (-not (Test-Path -LiteralPath $sessionProbePath)) {
    Write-Fail -TestName $removeTest -Reason 'sdd/sessions probe must survive uninstall'
}
$sessionProbeText = [System.IO.File]::ReadAllText($sessionProbePath)
if ($sessionProbeText -notmatch [regex]::Escape($sessionProbeMarker)) {
    Write-Fail -TestName $removeTest -Reason 'sdd session content must be preserved'
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Fail -TestName $removeTest -Reason 'sdd/manifest.json must survive uninstall'
}
$manifestAfter = [System.IO.File]::ReadAllText($manifestPath)
if ($manifestAfter -ne $manifestBefore) {
    Write-Fail -TestName $removeTest -Reason 'sdd/manifest.json must not be modified by uninstall'
}

Write-Pass -TestName $removeTest

# --- Should_KeepUnrelatedFilesAndSdd_When_UninstallCursorFixture ---
# --- Should_PreserveAlienHooksJsonAndStrictMatching_When_UninstallCursorFixture ---
# One Publish-Skills: plant aliens, sync, overlay hooks.json, uninstall once.
$keepTest = 'Should_KeepUnrelatedFilesAndSdd_When_UninstallCursorFixture'
$hooksJsonTest = 'Should_PreserveAlienHooksJsonAndStrictMatching_When_UninstallCursorFixture'

Clear-CursorFixturePublishedArtifacts

$alienSkillDir = Join-Path $skillsRoot $alienSkillId
New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $alienSkillDir 'SKILL.md') -Value ("# {0}`n" -f $alienSkillMarker) -Encoding UTF8

$alienRulePath = Join-Path $rulesRoot $alienRuleFileName
Set-Content -LiteralPath $alienRulePath -Value ("# {0}`n" -f $alienRuleMarker) -Encoding UTF8

$alienHookPath = Join-Path $hooksRoot $alienHookScriptName
Set-Content -LiteralPath $alienHookPath -Value ("# {0}`n" -f $alienHookMarker) -Encoding UTF8

if (-not (Test-Path -LiteralPath $sessionsPath)) {
    New-Item -ItemType Directory -Path $sessionsPath -Force | Out-Null
}
Set-Content -LiteralPath $sessionProbePath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionProbeMarker) -Encoding UTF8

Invoke-CursorKeyedUninstallSync -TestName $keepTest
Add-CursorFixtureHooksJsonAlienOverlay

$uninstallKeep = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallKeep -or $uninstallKeep.Success -ne $true) {
    Write-Fail -TestName $keepTest -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstallKeep) { 'null' } else { $uninstallKeep.Message }))
}

if (-not (Test-Path -LiteralPath (Join-Path $alienSkillDir 'SKILL.md'))) {
    Write-Fail -TestName $keepTest -Reason 'alien skill directory must survive keyed uninstall'
}
if (-not (Test-Path -LiteralPath $alienRulePath)) {
    Write-Fail -TestName $keepTest -Reason 'alien rule file must survive keyed uninstall'
}
if (-not (Test-Path -LiteralPath $alienHookPath)) {
    Write-Fail -TestName $keepTest -Reason 'alien hook script must survive keyed uninstall'
}
if (-not (Test-Path -LiteralPath $sessionProbePath)) {
    Write-Fail -TestName $keepTest -Reason 'sdd session probe must survive keyed uninstall'
}

if (Test-CursorToolkitSkillPresent) {
    Write-Fail -TestName $keepTest -Reason 'toolkit skills should still be removed while aliens remain'
}
if (Test-Path -LiteralPath $agentsPath) {
    Write-Fail -TestName $keepTest -Reason 'toolkit AGENTS.md should still be removed'
}

Write-Pass -TestName $keepTest

Assert-CursorHooksJsonReverseMergePreserved -TestName $hooksJsonTest
Write-Pass -TestName $hooksJsonTest

# --- Should_FailClosedWhen_InvalidHooksJsonOnUninstallCursorFixture ---
# --- Should_NotMutateOnWhatIfAndBeIdempotent_When_UninstallCursorFixture ---
# One Publish-Skills: fail-closed on invalid JSON, then restore hooks.json (no resync) for WhatIf.
$invalidJsonTest = 'Should_FailClosedWhen_InvalidHooksJsonOnUninstallCursorFixture'
$whatIfTest = 'Should_NotMutateOnWhatIfAndBeIdempotent_When_UninstallCursorFixture'

Clear-CursorFixturePublishedArtifacts
Invoke-CursorKeyedUninstallSync -TestName $invalidJsonTest

if (-not (Test-CursorToolkitSkillPresent)) {
    Write-Fail -TestName $invalidJsonTest -Reason 'expected toolkit skills after sync before invalid hooks.json injection'
}

$hooksJsonBeforeInvalid = [System.IO.File]::ReadAllText($hooksJsonPath)
[System.IO.File]::WriteAllText($hooksJsonPath, $invalidHooksJsonPayload, (Get-Utf8NoBomEncoding))

$uninstallInvalid = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallInvalid -or $uninstallInvalid.Success -ne $false) {
    Write-Fail -TestName $invalidJsonTest -Reason 'Uninstall-Toolkit must fail closed when hooks.json is invalid (JSON-first contract)'
}
if ($uninstallInvalid.ExitCode -eq 0) {
    Write-Fail -TestName $invalidJsonTest -Reason 'invalid hooks.json uninstall must not return ExitCode 0'
}
if (-not (Test-CursorToolkitSkillPresent)) {
    Write-Fail -TestName $invalidJsonTest -Reason 'toolkit FS artifacts must remain when hooks.json reverse-merge fails first'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $invalidJsonTest -Reason 'AGENTS.md must remain when hooks.json reverse-merge fails first'
}

Write-Pass -TestName $invalidJsonTest

[System.IO.File]::WriteAllText($hooksJsonPath, $hooksJsonBeforeInvalid, (Get-Utf8NoBomEncoding))

if (-not (Test-Path -LiteralPath $sessionsPath)) {
    New-Item -ItemType Directory -Path $sessionsPath -Force | Out-Null
}
Set-Content -LiteralPath $sessionProbePath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionProbeMarker) -Encoding UTF8
$manifestBeforeWhatIf = [System.IO.File]::ReadAllText($manifestPath)
$hooksJsonBeforeWhatIf = [System.IO.File]::ReadAllText($hooksJsonPath)

$whatIfResult = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot -WhatIf
if ($null -eq $whatIfResult -or $whatIfResult.Success -ne $true -or $whatIfResult.WhatIf -ne $true) {
    Write-Fail -TestName $whatIfTest -Reason 'Uninstall-Toolkit -WhatIf must succeed without mutating'
}
if (-not (Test-CursorToolkitSkillPresent)) {
    Write-Fail -TestName $whatIfTest -Reason 'WhatIf must not remove toolkit skills'
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Fail -TestName $whatIfTest -Reason 'WhatIf must not remove AGENTS.md'
}
if ([System.IO.File]::ReadAllText($hooksJsonPath) -ne $hooksJsonBeforeWhatIf) {
    Write-Fail -TestName $whatIfTest -Reason 'WhatIf must not mutate hooks.json'
}

$uninstallReal = Uninstall-Toolkit -InstallRoot $fixtureInstallRoot
if ($null -eq $uninstallReal -or $uninstallReal.Success -ne $true) {
    Write-Fail -TestName $whatIfTest -Reason ("real Uninstall-Toolkit after WhatIf must succeed, got: {0}" -f $(if ($null -eq $uninstallReal) { 'null' } else { $uninstallReal.Message }))
}
if (Test-CursorToolkitSkillPresent) {
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

Write-Host 'Assert-CursorKeyedUninstall: ALL PASS'
exit 0
