#Requires -Version 5.1
# Tests:
#   Should_SyncAndValidateCursor_When_FixtureInstallRootUsed
#   Should_NotCopyToUserCursorProfile_When_CursorSuiteRuns
#   Should_PublishOnlyCoreContent_When_CursorSyncRuns
# against in-repo Cursor fixture (no USERPROFILE/.cursor writes).
# Hooks keyed upsert: Assert-CursorHooksMerge.ps1 (validate-core).
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

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

foreach ($required in @($repoRootScript, $syncAgentScript, $validateAgentScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CursorSyncValidatePreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$cursorModulePath = Join-Path $repoRoot 'adapters\cursor\CursorAdapter.ps1'
$seedFixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\cursor-install-root'
$seedHooksJsonPath = Join-Path $seedFixtureRoot 'hooks.json'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\cursor-sync-validate'
$coreSkillsRoot = Join-Path (Join-Path $repoRoot 'core') 'skills'
$coreRouterAgents = Join-Path (Join-Path (Join-Path $repoRoot 'core') 'router') 'AGENTS.md'
$skillsDirName = 'skills'
$rulesDirName = 'rules'
$hooksDirName = 'hooks'
$hooksJsonFileName = 'hooks.json'
$agentsFileName = 'AGENTS.md'
$sddDirName = 'sdd'
$sessionsDirName = 'sessions'
$manifestFileName = 'manifest.json'
$cursorAgentId = 'cursor'
$comparison = [System.StringComparison]::OrdinalIgnoreCase
$userProfile = $env:USERPROFILE

if (-not (Test-Path -LiteralPath $cursorModulePath)) {
    Write-Fail -TestName 'Assert-CursorSyncValidatePreconditions' -Reason ("missing Cursor module: {0}" -f $cursorModulePath)
}
if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-Fail -TestName 'Assert-CursorSyncValidatePreconditions' -Reason ("missing Cursor seed fixture: {0}" -f $seedFixtureRoot)
}
if (-not (Test-Path -LiteralPath $seedHooksJsonPath)) {
    Write-Fail -TestName 'Assert-CursorSyncValidatePreconditions' -Reason ("missing seed hooks.json: {0}" -f $seedHooksJsonPath)
}
if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
    Write-Fail -TestName 'Assert-CursorSyncValidatePreconditions' -Reason ("missing core skills: {0}" -f $coreSkillsRoot)
}
if (-not (Test-Path -LiteralPath $coreRouterAgents)) {
    Write-Fail -TestName 'Assert-CursorSyncValidatePreconditions' -Reason ("missing core router: {0}" -f $coreRouterAgents)
}
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-CursorSyncValidatePreconditions' -Reason 'USERPROFILE is not set'
}

. $cursorModulePath

function Initialize-CursorE2EWorkRoot {
    if (Test-Path -LiteralPath $workInstallRoot) {
        Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null
    $seedText = [System.IO.File]::ReadAllText($seedHooksJsonPath)
    [System.IO.File]::WriteAllText((Join-Path $workInstallRoot $hooksJsonFileName), $seedText, (Get-Utf8NoBomEncoding))
}

function Clear-CursorPublishedSurfaces {
    param([Parameter(Mandatory = $true)][string] $InstallRoot)

    $skillsRoot = Join-Path $InstallRoot $skillsDirName
    $rulesRoot = Join-Path $InstallRoot $rulesDirName
    $hooksRoot = Join-Path $InstallRoot $hooksDirName
    $agentsPath = Join-Path $InstallRoot $agentsFileName
    $sddRoot = Join-Path $InstallRoot $sddDirName
    $hooksJsonPath = Join-Path $InstallRoot $hooksJsonFileName

    foreach ($path in @($skillsRoot, $rulesRoot, $hooksRoot, $sddRoot)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
    if (Test-Path -LiteralPath $agentsPath) {
        Remove-Item -LiteralPath $agentsPath -Force
    }

    # Restore versioned seed hooks.json so Publish-Hooks merge has a valid user baseline.
    $seedText = [System.IO.File]::ReadAllText($seedHooksJsonPath)
    [System.IO.File]::WriteAllText($hooksJsonPath, $seedText, (Get-Utf8NoBomEncoding))
}

# --- Should_SyncAndValidateCursor_When_FixtureInstallRootUsed ---
$syncValidateName = 'Should_SyncAndValidateCursor_When_FixtureInstallRootUsed'

Initialize-CursorE2EWorkRoot

$installRoots = Get-InstallRoots -AgentId $cursorAgentId
if ($null -eq $installRoots -or [string]::IsNullOrWhiteSpace([string]$installRoots.FixtureRelativePath)) {
    Write-Fail -TestName $syncValidateName -Reason 'Get-InstallRoots must expose FixtureRelativePath for orchestrator defaults'
}
if ($installRoots.FixtureRelativePath -notmatch '(?i)fixtures/cursor-install-root') {
    Write-Fail -TestName $syncValidateName -Reason ("unexpected FixtureRelativePath: {0}" -f $installRoots.FixtureRelativePath)
}

& $syncAgentScript -Agent cursor -InstallRoot $workInstallRoot
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
if ($syncExit -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason ("sync-agent -Agent cursor -InstallRoot <fixture> failed (exit {0})" -f $syncExit)
}

$skillsRoot = Join-Path $workInstallRoot $skillsDirName
$rulesRoot = Join-Path $workInstallRoot $rulesDirName
$hooksRoot = Join-Path $workInstallRoot $hooksDirName
$agentsPath = Join-Path $workInstallRoot $agentsFileName
$hooksJsonPath = Join-Path $workInstallRoot $hooksJsonFileName
$sessionsPath = Join-Path (Join-Path $workInstallRoot $sddDirName) $sessionsDirName
$manifestPath = Join-Path (Join-Path $workInstallRoot $sddDirName) $manifestFileName

if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) {
    Write-Fail -TestName $syncValidateName -Reason 'skills/ missing after sync-agent'
}
$skillManifests = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -Filter 'SKILL.md' -File)
if ($skillManifests.Count -lt 1) {
    Write-Fail -TestName $syncValidateName -Reason 'expected skills/*/SKILL.md after sync-agent'
}
$mdcRules = @(Get-ChildItem -LiteralPath $rulesRoot -Filter '*.mdc' -File -ErrorAction SilentlyContinue)
if ($mdcRules.Count -lt 1) {
    Write-Fail -TestName $syncValidateName -Reason 'expected rules/*.mdc after sync-agent'
}
if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
    Write-Fail -TestName $syncValidateName -Reason 'AGENTS.md missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $hooksRoot -PathType Container)) {
    Write-Fail -TestName $syncValidateName -Reason 'hooks/ missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $hooksJsonPath -PathType Leaf)) {
    Write-Fail -TestName $syncValidateName -Reason 'hooks.json missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $sessionsPath -PathType Container)) {
    Write-Fail -TestName $syncValidateName -Reason 'sdd/sessions missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Fail -TestName $syncValidateName -Reason 'sdd/manifest.json missing after sync-agent'
}

& $validateAgentScript -Agent cursor -InstallRoot $workInstallRoot -Quiet
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason ("validate-agent -Agent cursor -InstallRoot <fixture> failed (exit {0})" -f $validateExit)
}

$smokeAfter = Invoke-SmokeValidate -InstallRoot $workInstallRoot
if ($null -eq $smokeAfter -or $smokeAfter.Implemented -ne $true -or $smokeAfter.Success -ne $true -or $smokeAfter.ExitCode -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason 'Invoke-SmokeValidate must remain Implemented+Success after validate-agent (not stub no-op)'
}

# Default InstallRoot via FixtureRelativePath: sync then validate without explicit -InstallRoot
Clear-CursorPublishedSurfaces -InstallRoot $seedFixtureRoot
& $syncAgentScript -Agent cursor
$syncDefaultExit = $LASTEXITCODE
if ($null -eq $syncDefaultExit) { $syncDefaultExit = 0 }
if ($syncDefaultExit -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason ("sync-agent -Agent cursor (default FixtureRelativePath) failed (exit {0})" -f $syncDefaultExit)
}

& $validateAgentScript -Agent cursor -Quiet
$validateDefaultExit = $LASTEXITCODE
if ($null -eq $validateDefaultExit) { $validateDefaultExit = 0 }
if ($validateDefaultExit -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason ("validate-agent -Agent cursor (default FixtureRelativePath) failed (exit {0})" -f $validateDefaultExit)
}

Write-Pass -TestName $syncValidateName

# --- Should_NotCopyToUserCursorProfile_When_CursorSuiteRuns ---
$homeGuardName = 'Should_NotCopyToUserCursorProfile_When_CursorSuiteRuns'

# Live ~/.cursor mutates under the IDE; fingerprint a sentinel toolkit never publishes.
$userCursorSentinelRel = '.agent-dev-toolkit--cursor-e2e-sentinel'
$userCursorSentinel = Join-Path (Join-Path $userProfile '.cursor') $userCursorSentinelRel
$userCursorRoot = [System.IO.Path]::GetFullPath((Join-Path $userProfile '.cursor'))
$sentinelExistedBefore = Test-Path -LiteralPath $userCursorSentinel
$normalizedUserCursor = [System.IO.Path]::GetFullPath($userCursorRoot)
$normalizedRepoRoot = [System.IO.Path]::GetFullPath($repoRoot)

Initialize-CursorE2EWorkRoot
& $syncAgentScript -Agent cursor -InstallRoot $workInstallRoot
$syncHomeExit = $LASTEXITCODE
if ($null -eq $syncHomeExit) { $syncHomeExit = 0 }
if ($syncHomeExit -ne 0) {
    Write-Fail -TestName $homeGuardName -Reason ("sync-agent fixture run failed during home-guard check (exit {0})" -f $syncHomeExit)
}

$normalizedWorkRoot = [System.IO.Path]::GetFullPath($workInstallRoot)
if ($normalizedWorkRoot.StartsWith($normalizedUserCursor, $comparison)) {
    Write-Fail -TestName $homeGuardName -Reason 'work InstallRoot must not resolve under USERPROFILE/.cursor'
}
if (-not $normalizedWorkRoot.StartsWith($normalizedRepoRoot, $comparison)) {
    Write-Fail -TestName $homeGuardName -Reason 'work InstallRoot must stay under the toolkit repo'
}
if (-not (Test-Path -LiteralPath (Join-Path $workInstallRoot $agentsFileName))) {
    Write-Fail -TestName $homeGuardName -Reason 'fixture sync must publish AGENTS.md under in-repo work InstallRoot (not home)'
}

& $validateAgentScript -Agent cursor -InstallRoot $workInstallRoot -Quiet
$validateHomeExit = $LASTEXITCODE
if ($null -eq $validateHomeExit) { $validateHomeExit = 0 }
if ($validateHomeExit -ne 0) {
    Write-Fail -TestName $homeGuardName -Reason ("validate-agent fixture run failed during home-guard check (exit {0})" -f $validateHomeExit)
}

$sentinelExistsAfter = Test-Path -LiteralPath $userCursorSentinel
if ($sentinelExistedBefore -ne $sentinelExistsAfter) {
    Write-Fail -TestName $homeGuardName -Reason 'suite must not create or remove sentinel under USERPROFILE/.cursor'
}

# Explicit home InstallRoot without -AllowUserHome must fail closed
$probeRelative = '.agent-dev-toolkit--cursor-e2e-home-test'
$userProbeRoot = Join-Path $userProfile $probeRelative
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$syncBlockedOut = & pwsh -NoProfile -File $syncAgentScript -Agent cursor -InstallRoot $userProbeRoot 2>&1
$syncBlockedExit = $LASTEXITCODE
if ($null -eq $syncBlockedExit) { $syncBlockedExit = 0 }
$syncBlockedText = ($syncBlockedOut | Out-String)
if ($syncBlockedExit -eq 0) {
    Write-Fail -TestName $homeGuardName -Reason 'sync-agent against USERPROFILE without -AllowUserHome must exit non-zero'
}
if ($syncBlockedText -notmatch '(?i)AllowUserHome' -or $syncBlockedText -notmatch '(?i)USERPROFILE') {
    Write-Fail -TestName $homeGuardName -Reason ("blocked sync must mention AllowUserHome/USERPROFILE; got: {0}" -f $syncBlockedText.Trim())
}
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Fail -TestName $homeGuardName -Reason 'sync-agent must not create USERPROFILE probe InstallRoot without -AllowUserHome'
}

Write-Pass -TestName $homeGuardName

# --- Should_PublishOnlyCoreContent_When_CursorSyncRuns ---
$coreOnlyName = 'Should_PublishOnlyCoreContent_When_CursorSyncRuns'

Initialize-CursorE2EWorkRoot
& $syncAgentScript -Agent cursor -InstallRoot $workInstallRoot
$syncCoreExit = $LASTEXITCODE
if ($null -eq $syncCoreExit) { $syncCoreExit = 0 }
if ($syncCoreExit -ne 0) {
    Write-Fail -TestName $coreOnlyName -Reason ("sync-agent failed during core-content check (exit {0})" -f $syncCoreExit)
}

$publishSkills = Publish-Skills -InstallRoot $workInstallRoot -WhatIf
if ($null -eq $publishSkills) {
    Write-Fail -TestName $coreOnlyName -Reason 'Publish-Skills -WhatIf returned null'
}
$normalizedSource = [System.IO.Path]::GetFullPath([string]$publishSkills.SourceSkillsRoot)
$normalizedCoreSkills = [System.IO.Path]::GetFullPath($coreSkillsRoot)
if (-not [string]::Equals($normalizedSource, $normalizedCoreSkills, $comparison)) {
    Write-Fail -TestName $coreOnlyName -Reason ("publish source must be core/skills only, got: {0}" -f $publishSkills.SourceSkillsRoot)
}
if ($normalizedSource -match '(?i)athena' -or $normalizedSource -match '(?i)ai-prompts') {
    Write-Fail -TestName $coreOnlyName -Reason 'publish source path must not be Athena / ai-prompts catalog'
}

$agentsText = [System.IO.File]::ReadAllText((Join-Path $workInstallRoot $agentsFileName))
$coreAgentsText = [System.IO.File]::ReadAllText($coreRouterAgents)
if ($agentsText -match '(?i)athena\s+catalog' -or $agentsText -match '(?i)ai-prompts') {
    Write-Fail -TestName $coreOnlyName -Reason 'AGENTS.md must not contain Athena catalog content'
}
if ($coreAgentsText -match '(?i)athena\s+catalog') {
    Write-Fail -TestName $coreOnlyName -Reason 'precondition failed: core/router/AGENTS.md unexpectedly references Athena catalog'
}

$publishedSkillsRoot = Join-Path $workInstallRoot $skillsDirName
$sampleSkillManifests = @(Get-ChildItem -LiteralPath $publishedSkillsRoot -Directory | ForEach-Object {
        $manifest = Join-Path $_.FullName 'SKILL.md'
        if (Test-Path -LiteralPath $manifest -PathType Leaf) { $manifest }
    } | Select-Object -First 3)
if ($sampleSkillManifests.Count -lt 1) {
    Write-Fail -TestName $coreOnlyName -Reason 'expected at least one skills/<id>/SKILL.md after sync'
}
foreach ($skillMd in $sampleSkillManifests) {
    $published = [System.IO.File]::ReadAllText($skillMd)
    if ($published -match '(?i)athena\s+catalog' -or $published -match '(?i)\\ai-prompts\\') {
        Write-Fail -TestName $coreOnlyName -Reason ("published skill must not embed Athena catalog paths: {0}" -f $skillMd)
    }
}

$publishedRulesRoot = Join-Path $workInstallRoot $rulesDirName
$mdcAfterCore = @(Get-ChildItem -LiteralPath $publishedRulesRoot -Filter '*.mdc' -File -ErrorAction SilentlyContinue)
if ($mdcAfterCore.Count -lt 1) {
    Write-Fail -TestName $coreOnlyName -Reason 'core-only Cursor publish must create rules/*.mdc from core/policy'
}

# Cleanup ephemeral work root; leave versioned seed fixture as last default sync left it
if (Test-Path -LiteralPath $workInstallRoot) {
    Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
}

Write-Pass -TestName $coreOnlyName

Write-Host 'Assert-CursorSyncValidate: ALL PASS'
exit 0
