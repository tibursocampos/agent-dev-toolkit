#Requires -Version 5.1
# Tests:
#   Should_PassValidateAgent_When_AntigravityFixtureUsed
#   Should_NotWriteUserGeminiProfile_When_CiSmokeRuns
#   Should_FailSync_When_InstallRootIsUserProfileWithoutAllow
#
# fixture (no USERPROFILE/.gemini writes). Optional keyed Uninstall cleanup.
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
        Write-Fail -TestName 'Assert-AntigravityKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$modulePath = Join-Path $repoRoot 'adapters\antigravity\AntigravityAdapter.ps1'
$seedFixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\antigravity-install-root'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\antigravity-keyed-uninstall'
$agentId = 'antigravity'
$fixtureRelativeToken = 'fixtures/antigravity-install-root'
$userGeminiSentinelRel = '.agent-dev-toolkit--antigravity-e2e-sentinel'
$userProbeRelative = '.agent-dev-toolkit--antigravity-e2e-home-test'
$alienSkillFolderName = 'operator-alien-skill'
$seedAgentsMarker = '# Seed AGENTS'
$comparison = [System.StringComparison]::OrdinalIgnoreCase
$userProfile = $env:USERPROFILE
$sep = [System.IO.Path]::DirectorySeparatorChar

if (-not (Test-Path -LiteralPath $modulePath)) {
    Write-Fail -TestName 'Assert-AntigravityKeyedUninstallPreconditions' -Reason ("missing Antigravity module: {0}" -f $modulePath)
}
if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-Fail -TestName 'Assert-AntigravityKeyedUninstallPreconditions' -Reason ("missing Antigravity seed fixture: {0}" -f $seedFixtureRoot)
}
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-AntigravityKeyedUninstallPreconditions' -Reason 'USERPROFILE is not set'
}

. $modulePath

function Initialize-AntigravityE2EWorkRoot {
    if (Test-Path -LiteralPath $workInstallRoot) {
        Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null

    $configDirs = @(
        (Join-Path $workInstallRoot 'config\skills'),
        (Join-Path $workInstallRoot 'config\plugins'),
        (Join-Path $workInstallRoot 'config\hooks')
    )
    foreach ($dir in $configDirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $utf8 = Get-Utf8NoBomEncoding
    [System.IO.File]::WriteAllText((Join-Path $workInstallRoot 'config\skills.json'), '{}', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $workInstallRoot 'config\AGENTS.md'), ($seedAgentsMarker + "`n"), $utf8)
    [System.IO.File]::WriteAllText((Join-Path $workInstallRoot 'config\GEMINI.md'), "# Seed GEMINI`n", $utf8)

    $alienSkillDir = Join-Path (Join-Path $workInstallRoot 'config\skills') $alienSkillFolderName
    New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $alienSkillDir 'SKILL.md'), "# Alien skill`n", $utf8)
}

# --- Should_PassValidateAgent_When_AntigravityFixtureUsed ---
$passName = 'Should_PassValidateAgent_When_AntigravityFixtureUsed'

Initialize-AntigravityE2EWorkRoot

$installRoots = Get-InstallRoots -AgentId $agentId
if ($null -eq $installRoots -or [string]::IsNullOrWhiteSpace([string]$installRoots.FixtureRelativePath)) {
    Write-Fail -TestName $passName -Reason 'Get-InstallRoots must expose FixtureRelativePath for orchestrator defaults'
}
if ($installRoots.FixtureRelativePath -notmatch [regex]::Escape($fixtureRelativeToken)) {
    Write-Fail -TestName $passName -Reason ("unexpected FixtureRelativePath: {0}" -f $installRoots.FixtureRelativePath)
}

& $syncAgentScript -Agent $agentId -InstallRoot $workInstallRoot
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
if ($syncExit -ne 0) {
    Write-Fail -TestName $passName -Reason ("sync-agent -Agent antigravity -InstallRoot <fixture> failed (exit {0})" -f $syncExit)
}

$skillsRoot = Join-Path $workInstallRoot ('config' + $sep + 'skills')
$skillsJsonPath = Join-Path $workInstallRoot ('config' + $sep + 'skills.json')
$guardrailsPath = Join-Path $workInstallRoot ('config' + $sep + 'plugins' + $sep + 'agent-dev-toolkit' + $sep + 'GUARDRAILS.md')
$devPersonaPath = Join-Path $skillsRoot ('dev_persona' + $sep + 'SKILL.md')
$agentsPath = Join-Path $workInstallRoot ('config' + $sep + 'AGENTS.md')

if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) {
    Write-Fail -TestName $passName -Reason 'config/skills missing after sync-agent'
}
$skillManifests = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -Filter 'SKILL.md' -File)
if ($skillManifests.Count -lt 2) {
    Write-Fail -TestName $passName -Reason 'expected published skills/*/SKILL.md after sync-agent'
}
if (-not (Test-Path -LiteralPath $skillsJsonPath -PathType Leaf)) {
    Write-Fail -TestName $passName -Reason 'config/skills.json missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $guardrailsPath -PathType Leaf)) {
    Write-Fail -TestName $passName -Reason 'GUARDRAILS.md missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $devPersonaPath -PathType Leaf)) {
    Write-Fail -TestName $passName -Reason 'dev_persona/SKILL.md missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
    Write-Fail -TestName $passName -Reason 'config/AGENTS.md missing after sync-agent'
}
$agentsText = [System.IO.File]::ReadAllText($agentsPath)
if ($agentsText -notmatch [regex]::Escape($seedAgentsMarker)) {
    Write-Fail -TestName $passName -Reason 'sync must preserve seed content outside managed AGENTS.md block'
}
if ($agentsText -notmatch 'agent-dev-toolkit:managed:begin') {
    Write-Fail -TestName $passName -Reason 'sync must upsert managed AGENTS.md block'
}

& $validateAgentScript -Agent $agentId -InstallRoot $workInstallRoot -Quiet
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $passName -Reason ("validate-agent -Agent antigravity -InstallRoot <fixture> failed (exit {0})" -f $validateExit)
}

$smokeAfter = Invoke-SmokeValidate -InstallRoot $workInstallRoot
if ($null -eq $smokeAfter -or $smokeAfter.Implemented -ne $true -or $smokeAfter.Success -ne $true -or $smokeAfter.ExitCode -ne 0) {
    Write-Fail -TestName $passName -Reason 'Invoke-SmokeValidate must remain Implemented+Success after validate-agent (not stub no-op)'
}

$whatIfUninstall = Uninstall-Toolkit -InstallRoot $workInstallRoot -WhatIf
if ($null -eq $whatIfUninstall -or $whatIfUninstall.Success -ne $true -or $whatIfUninstall.Implemented -ne $true) {
    Write-Fail -TestName $passName -Reason 'Uninstall-Toolkit -WhatIf must succeed without mutating'
}
if (-not (Test-Path -LiteralPath $guardrailsPath -PathType Leaf)) {
    Write-Fail -TestName $passName -Reason 'Uninstall-Toolkit -WhatIf must not remove GUARDRAILS.md'
}

$uninstall = Uninstall-Toolkit -InstallRoot $workInstallRoot
if ($null -eq $uninstall -or $uninstall.Success -ne $true -or $uninstall.Implemented -ne $true) {
    Write-Fail -TestName $passName -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstall) { 'null' } else { $uninstall.Message }))
}
if (Test-Path -LiteralPath $guardrailsPath) {
    Write-Fail -TestName $passName -Reason 'Uninstall-Toolkit must remove managed plugin GUARDRAILS directory'
}
if (Test-Path -LiteralPath $devPersonaPath) {
    Write-Fail -TestName $passName -Reason 'Uninstall-Toolkit must remove skills/dev_persona'
}
$alienSkillPath = Join-Path $skillsRoot $alienSkillFolderName
if (-not (Test-Path -LiteralPath $alienSkillPath -PathType Container)) {
    Write-Fail -TestName $passName -Reason 'Uninstall-Toolkit must preserve alien skill folders'
}
$agentsAfterUninstall = [System.IO.File]::ReadAllText($agentsPath)
if ($agentsAfterUninstall -match 'agent-dev-toolkit:managed:begin') {
    Write-Fail -TestName $passName -Reason 'Uninstall-Toolkit must strip managed AGENTS.md block'
}
if ($agentsAfterUninstall -notmatch [regex]::Escape($seedAgentsMarker)) {
    Write-Fail -TestName $passName -Reason 'Uninstall-Toolkit must preserve seed AGENTS.md content outside managed block'
}

$uninstallAgain = Uninstall-Toolkit -InstallRoot $workInstallRoot
if ($null -eq $uninstallAgain -or $uninstallAgain.Success -ne $true) {
    Write-Fail -TestName $passName -Reason 'idempotent Uninstall-Toolkit must remain Success when artifacts already gone'
}

if (-not (Test-Path -LiteralPath $seedFixtureRoot -PathType Container)) {
    Write-Fail -TestName $passName -Reason 'versioned antigravity-install-root seed must remain intact'
}

Write-Pass -TestName $passName

# --- Should_NotWriteUserGeminiProfile_When_CiSmokeRuns ---
$homeGuardName = 'Should_NotWriteUserGeminiProfile_When_CiSmokeRuns'

$userGeminiRoot = [System.IO.Path]::GetFullPath((Join-Path $userProfile '.gemini'))
$userGeminiSentinel = Join-Path $userGeminiRoot $userGeminiSentinelRel
$sentinelExistedBefore = Test-Path -LiteralPath $userGeminiSentinel
$normalizedRepoRoot = [System.IO.Path]::GetFullPath($repoRoot)

Initialize-AntigravityE2EWorkRoot
& $syncAgentScript -Agent $agentId -InstallRoot $workInstallRoot
$syncHomeExit = $LASTEXITCODE
if ($null -eq $syncHomeExit) { $syncHomeExit = 0 }
if ($syncHomeExit -ne 0) {
    Write-Fail -TestName $homeGuardName -Reason ("sync-agent fixture run failed during home-guard check (exit {0})" -f $syncHomeExit)
}

$normalizedWorkRoot = [System.IO.Path]::GetFullPath($workInstallRoot)
if ($normalizedWorkRoot.StartsWith($userGeminiRoot, $comparison)) {
    Write-Fail -TestName $homeGuardName -Reason 'work InstallRoot must not resolve under USERPROFILE/.gemini'
}
if (-not $normalizedWorkRoot.StartsWith($normalizedRepoRoot, $comparison)) {
    Write-Fail -TestName $homeGuardName -Reason 'work InstallRoot must stay under the toolkit repo'
}
if (-not (Test-Path -LiteralPath (Join-Path $workInstallRoot ('config' + $sep + 'AGENTS.md')))) {
    Write-Fail -TestName $homeGuardName -Reason 'fixture sync must publish AGENTS.md under in-repo work InstallRoot (not home)'
}

& $validateAgentScript -Agent $agentId -InstallRoot $workInstallRoot -Quiet
$validateHomeExit = $LASTEXITCODE
if ($null -eq $validateHomeExit) { $validateHomeExit = 0 }
if ($validateHomeExit -ne 0) {
    Write-Fail -TestName $homeGuardName -Reason ("validate-agent fixture run failed during home-guard check (exit {0})" -f $validateHomeExit)
}

$sentinelExistsAfter = Test-Path -LiteralPath $userGeminiSentinel
if ($sentinelExistedBefore -ne $sentinelExistsAfter) {
    Write-Fail -TestName $homeGuardName -Reason 'suite must not create or remove sentinel under USERPROFILE/.gemini'
}

Write-Pass -TestName $homeGuardName

# --- Should_FailSync_When_InstallRootIsUserProfileWithoutAllow ---
$failSyncName = 'Should_FailSync_When_InstallRootIsUserProfileWithoutAllow'

$userProbeRoot = Join-Path $userProfile $userProbeRelative
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$syncBlockedOut = & pwsh -NoProfile -File $syncAgentScript -Agent $agentId -InstallRoot $userProbeRoot 2>&1
$syncBlockedExit = $LASTEXITCODE
if ($null -eq $syncBlockedExit) { $syncBlockedExit = 0 }
$syncBlockedText = ($syncBlockedOut | Out-String)
if ($syncBlockedExit -eq 0) {
    Write-Fail -TestName $failSyncName -Reason 'sync-agent against USERPROFILE without -AllowUserHome must exit non-zero'
}
if ($syncBlockedText -notmatch '(?i)AllowUserHome' -or $syncBlockedText -notmatch '(?i)USERPROFILE') {
    Write-Fail -TestName $failSyncName -Reason ("blocked sync must mention AllowUserHome/USERPROFILE; got: {0}" -f $syncBlockedText.Trim())
}
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Fail -TestName $failSyncName -Reason 'sync-agent must not create USERPROFILE probe InstallRoot without -AllowUserHome'
}

Write-Pass -TestName $failSyncName

# Cleanup ephemeral work root; leave versioned seed fixture untouched
if (Test-Path -LiteralPath $workInstallRoot) {
    Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
}

Write-Host 'Assert-AntigravityKeyedUninstall: ALL PASS'
exit 0
