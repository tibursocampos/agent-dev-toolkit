#Requires -Version 5.1
# Tests:
#   Should_SyncAndValidateZcode_When_FixtureInstallRootUsed
#   Should_NotCopyToUserZcodeProfile_When_ZcodeSuiteRuns
#   Should_PublishOnlyCoreContent_When_ZcodeSyncRuns
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

function Get-DirectoryFingerprint {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return 'ABSENT'
    }

    $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue | Sort-Object FullName)
    if ($files.Count -eq 0) {
        return 'EMPTY_DIR'
    }

    $parts = foreach ($file in $files) {
        '{0}|{1}|{2}' -f $file.FullName.ToLowerInvariant(), $file.Length, $file.LastWriteTimeUtc.Ticks
    }
    return ($parts -join '`n')
}

foreach ($required in @($repoRootScript, $syncAgentScript, $validateAgentScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-ZcodeAdeLayoutPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$zcodeModulePath = Join-Path $repoRoot 'adapters\zcode\ZCodeAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\zcode-install-root'
$coreSkillsRoot = Join-Path (Join-Path $repoRoot 'core') 'skills'
$coreRouterAgents = Join-Path (Join-Path (Join-Path $repoRoot 'core') 'router') 'AGENTS.md'
$skillsDirName = 'skills'
$agentsFileName = 'AGENTS.md'
$cliDirName = 'cli'
$hooksDirName = 'hooks'
$cursorRulesDirName = 'rules'
$zcodeAgentId = 'zcode'
$comparison = [System.StringComparison]::OrdinalIgnoreCase
$userProfile = $env:USERPROFILE

if (-not (Test-Path -LiteralPath $zcodeModulePath)) {
    Write-Fail -TestName 'Assert-ZcodeAdeLayoutPreconditions' -Reason ("missing ZCode module: {0}" -f $zcodeModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-ZcodeAdeLayoutPreconditions' -Reason ("missing ZCode fixture: {0}" -f $fixtureInstallRoot)
}
if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
    Write-Fail -TestName 'Assert-ZcodeAdeLayoutPreconditions' -Reason ("missing core skills: {0}" -f $coreSkillsRoot)
}
if (-not (Test-Path -LiteralPath $coreRouterAgents)) {
    Write-Fail -TestName 'Assert-ZcodeAdeLayoutPreconditions' -Reason ("missing core router: {0}" -f $coreRouterAgents)
}
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-ZcodeAdeLayoutPreconditions' -Reason 'USERPROFILE is not set'
}

. $zcodeModulePath

function Clear-ZcodeFixturePublishedSurfaces {
    param([Parameter(Mandatory = $true)][string] $InstallRoot)

    $skillsRoot = Join-Path $InstallRoot $skillsDirName
    $agentsPath = Join-Path $InstallRoot $agentsFileName
    $cliRoot = Join-Path $InstallRoot $cliDirName
    $hooksRoot = Join-Path $InstallRoot $hooksDirName
    $rulesRoot = Join-Path $InstallRoot $cursorRulesDirName

    foreach ($path in @($skillsRoot, $cliRoot, $hooksRoot, $rulesRoot)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
    if (Test-Path -LiteralPath $agentsPath) {
        Remove-Item -LiteralPath $agentsPath -Force
    }
}

# --- Should_SyncAndValidateZcode_When_FixtureInstallRootUsed ---
$syncValidateName = 'Should_SyncAndValidateZcode_When_FixtureInstallRootUsed'

Clear-ZcodeFixturePublishedSurfaces -InstallRoot $fixtureInstallRoot

$installRoots = Get-InstallRoots -AgentId $zcodeAgentId
if ($null -eq $installRoots -or [string]::IsNullOrWhiteSpace([string]$installRoots.FixtureRelativePath)) {
    Write-Fail -TestName $syncValidateName -Reason 'Get-InstallRoots must expose FixtureRelativePath for orchestrator defaults'
}
if ($installRoots.FixtureRelativePath -notmatch '(?i)fixtures/zcode-install-root') {
    Write-Fail -TestName $syncValidateName -Reason ("unexpected FixtureRelativePath: {0}" -f $installRoots.FixtureRelativePath)
}

$policyNoOp = Publish-Policy -InstallRoot $fixtureInstallRoot
if ($null -eq $policyNoOp -or $policyNoOp.Success -ne $true -or $policyNoOp.Implemented -ne $true -or $policyNoOp.NoOp -ne $true) {
    Write-Fail -TestName $syncValidateName -Reason 'Publish-Policy must be documented no-op (Implemented=true Success=true NoOp=true) for sync-agent'
}

& $syncAgentScript -Agent zcode -InstallRoot $fixtureInstallRoot
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
if ($syncExit -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason ("sync-agent -Agent zcode -InstallRoot <fixture> failed (exit {0})" -f $syncExit)
}

$skillsRoot = Join-Path $fixtureInstallRoot $skillsDirName
$agentsPath = Join-Path $fixtureInstallRoot $agentsFileName
$cliConfigPath = Join-Path (Join-Path $fixtureInstallRoot $cliDirName) 'config.json'
$hooksJsonPath = Join-Path (Join-Path $fixtureInstallRoot $hooksDirName) 'hooks.json'
$rulesRoot = Join-Path $fixtureInstallRoot $cursorRulesDirName

if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) {
    Write-Fail -TestName $syncValidateName -Reason 'skills/ missing after sync-agent'
}
$skillManifests = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -Filter 'SKILL.md' -File)
if ($skillManifests.Count -lt 1) {
    Write-Fail -TestName $syncValidateName -Reason 'expected skills/*/SKILL.md after sync-agent'
}
if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
    Write-Fail -TestName $syncValidateName -Reason 'AGENTS.md missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $cliConfigPath -PathType Leaf)) {
    Write-Fail -TestName $syncValidateName -Reason 'cli/config.json missing after sync-agent'
}
if (-not (Test-Path -LiteralPath $hooksJsonPath -PathType Leaf)) {
    Write-Fail -TestName $syncValidateName -Reason 'hooks/hooks.json missing after sync-agent'
}
if (Test-Path -LiteralPath $rulesRoot) {
    Write-Fail -TestName $syncValidateName -Reason 'sync must not publish Cursor rules/*.mdc tree under ZCode InstallRoot'
}

& $validateAgentScript -Agent zcode -InstallRoot $fixtureInstallRoot -Quiet
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason ("validate-agent -Agent zcode -InstallRoot <fixture> failed (exit {0})" -f $validateExit)
}

$smokeAfter = Invoke-SmokeValidate -InstallRoot $fixtureInstallRoot
if ($null -eq $smokeAfter -or $smokeAfter.Implemented -ne $true -or $smokeAfter.Success -ne $true -or $smokeAfter.ExitCode -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason 'Invoke-SmokeValidate must remain Implemented+Success after validate-agent (not stub no-op)'
}

# Default InstallRoot path (FixtureRelativePath) also greens validate-agent
& $validateAgentScript -Agent zcode -Quiet
$validateDefaultExit = $LASTEXITCODE
if ($null -eq $validateDefaultExit) { $validateDefaultExit = 0 }
if ($validateDefaultExit -ne 0) {
    Write-Fail -TestName $syncValidateName -Reason ("validate-agent -Agent zcode (default FixtureRelativePath) failed (exit {0})" -f $validateDefaultExit)
}

Write-Pass -TestName $syncValidateName

# --- Should_NotCopyToUserZcodeProfile_When_ZcodeSuiteRuns ---
$homeGuardName = 'Should_NotCopyToUserZcodeProfile_When_ZcodeSuiteRuns'

$userZcodeRoot = [System.IO.Path]::GetFullPath((Join-Path $userProfile '.zcode'))
$beforeFingerprint = Get-DirectoryFingerprint -Path $userZcodeRoot
$userZcodeExistedBefore = Test-Path -LiteralPath $userZcodeRoot

Clear-ZcodeFixturePublishedSurfaces -InstallRoot $fixtureInstallRoot
& $syncAgentScript -Agent zcode -InstallRoot $fixtureInstallRoot
$syncHomeExit = $LASTEXITCODE
if ($null -eq $syncHomeExit) { $syncHomeExit = 0 }
if ($syncHomeExit -ne 0) {
    Write-Fail -TestName $homeGuardName -Reason ("sync-agent fixture run failed during home-guard check (exit {0})" -f $syncHomeExit)
}

& $validateAgentScript -Agent zcode -InstallRoot $fixtureInstallRoot -Quiet
$validateHomeExit = $LASTEXITCODE
if ($null -eq $validateHomeExit) { $validateHomeExit = 0 }
if ($validateHomeExit -ne 0) {
    Write-Fail -TestName $homeGuardName -Reason ("validate-agent fixture run failed during home-guard check (exit {0})" -f $validateHomeExit)
}

$afterFingerprint = Get-DirectoryFingerprint -Path $userZcodeRoot
$userZcodeExistsAfter = Test-Path -LiteralPath $userZcodeRoot

if ($userZcodeExistedBefore -ne $userZcodeExistsAfter) {
    Write-Fail -TestName $homeGuardName -Reason 'suite must not create or remove ~/.zcode under USERPROFILE'
}
if (-not [string]::Equals($beforeFingerprint, $afterFingerprint, $comparison)) {
    Write-Fail -TestName $homeGuardName -Reason 'suite must not mutate USERPROFILE/.zcode contents'
}

# Explicit home InstallRoot without -AllowUserHome must fail closed
$probeRelative = '.agent-dev-toolkit-zcode-home-guard-test'
$userProbeRoot = Join-Path $userProfile $probeRelative
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
}

& $syncAgentScript -Agent zcode -InstallRoot $userProbeRoot
$syncBlockedExit = $LASTEXITCODE
if ($null -eq $syncBlockedExit) { $syncBlockedExit = 0 }
if ($syncBlockedExit -eq 0) {
    Write-Fail -TestName $homeGuardName -Reason 'sync-agent against USERPROFILE without -AllowUserHome must exit non-zero'
}
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Fail -TestName $homeGuardName -Reason 'sync-agent must not create USERPROFILE probe InstallRoot without -AllowUserHome'
}

Write-Pass -TestName $homeGuardName

# --- Should_PublishOnlyCoreContent_When_ZcodeSyncRuns ---
$coreOnlyName = 'Should_PublishOnlyCoreContent_When_ZcodeSyncRuns'

Clear-ZcodeFixturePublishedSurfaces -InstallRoot $fixtureInstallRoot
& $syncAgentScript -Agent zcode -InstallRoot $fixtureInstallRoot
$syncCoreExit = $LASTEXITCODE
if ($null -eq $syncCoreExit) { $syncCoreExit = 0 }
if ($syncCoreExit -ne 0) {
    Write-Fail -TestName $coreOnlyName -Reason ("sync-agent failed during core-content check (exit {0})" -f $syncCoreExit)
}

$publishSkills = Publish-Skills -InstallRoot $fixtureInstallRoot -WhatIf
if ($null -eq $publishSkills) {
    Write-Fail -TestName $coreOnlyName -Reason 'Publish-Skills -WhatIf returned null'
}
$normalizedSource = [System.IO.Path]::GetFullPath([string]$publishSkills.SourceRoot)
$normalizedCoreSkills = [System.IO.Path]::GetFullPath($coreSkillsRoot)
if (-not [string]::Equals($normalizedSource, $normalizedCoreSkills, $comparison)) {
    Write-Fail -TestName $coreOnlyName -Reason ("publish source must be core/skills only, got: {0}" -f $publishSkills.SourceRoot)
}
if ($normalizedSource -match '(?i)athena' -or $normalizedSource -match '(?i)ai-prompts') {
    Write-Fail -TestName $coreOnlyName -Reason 'publish source path must not be Athena / ai-prompts catalog'
}

$agentsText = [System.IO.File]::ReadAllText((Join-Path $fixtureInstallRoot $agentsFileName))
$coreAgentsText = [System.IO.File]::ReadAllText($coreRouterAgents)
# Destination may have placeholders resolved; core keeps tokens - still must not inject Athena catalog.
if ($agentsText -match '(?i)athena\s+catalog' -or $agentsText -match '(?i)ai-prompts') {
    Write-Fail -TestName $coreOnlyName -Reason 'AGENTS.md must not contain Athena catalog content'
}
if ($coreAgentsText -match '(?i)athena\s+catalog') {
    Write-Fail -TestName $coreOnlyName -Reason 'precondition failed: core/router/AGENTS.md unexpectedly references Athena catalog'
}

$publishedSkillsRoot = Join-Path $fixtureInstallRoot $skillsDirName
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

if (Test-Path -LiteralPath (Join-Path $fixtureInstallRoot $cursorRulesDirName)) {
    Write-Fail -TestName $coreOnlyName -Reason 'core-only publish must not create rules/ under ZCode fixture'
}

Write-Pass -TestName $coreOnlyName

Write-Host 'Assert-ZcodeAdeLayout: ALL PASS'
exit 0
