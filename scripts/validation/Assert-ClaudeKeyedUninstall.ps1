#Requires -Version 5.1
# Tests:
#   Should_SyncViaOrchestrator_When_AgentClaudeAndInstallRootSet
#   Should_RemoveManagedArtifacts_When_UninstallClaudeOnFixture
#
# CU01/CU02: sync-agent orchestration + keyed Uninstall on Claude fixture.
# No USERPROFILE writes.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'
$syncAgentScript = Join-Path $scriptsRoot 'sync-agent.ps1'
$validateAgentScript = Join-Path $scriptsRoot 'validate-agent.ps1'
$toolkitScript = Join-Path $scriptsRoot 'toolkit.ps1'

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

foreach ($required in @($repoRootScript, $syncAgentScript, $validateAgentScript, $toolkitScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-ClaudeKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$claudeModulePath = Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1'
$seedFixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\claude'
$seedSettingsPath = Join-Path $seedFixtureRoot 'settings.json'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\claude-sync-uninstall'
$skillsDirName = 'skills'
$rulesDirName = 'rules'
$hooksDirName = 'hooks'
$claudeMdFileName = 'CLAUDE.md'
$settingsFileName = 'settings.json'
$fixtureReadmeName = 'README.md'
$alienSkillId = 'user-alien-skill-'
$alienRuleFileName = 'user-alien-rule-.md'
$alienHookFileName = 'user-alien-hook-.ps1'
$alienSkillManifest = "# Alien skill`nMust survive keyed uninstall.`n"
$alienRuleContent = "# Alien rule`nMust survive keyed uninstall.`n"
$alienHookContent = "# Alien hook`nMust survive keyed uninstall.`n"
$operatorCustomKey = 'operatorCustomKey'
$operatorCustomValue = 'must-survive-merge'
$alienNotificationMarker = 'alien-notification-hook'
$userAllowEntry = 'Bash(git status)'
$legacyBroadAllowPwsh = 'Bash(pwsh *)'
$legacyBroadAllowPowershell = 'Bash(powershell *)'
$staleUserPromptMarker = 'stale-user-prompt'
$userProbeRelative = '.agent-dev-toolkit--claude-uninstall-test'
$comparison = [System.StringComparison]::OrdinalIgnoreCase
$userProfile = $env:USERPROFILE

if (-not (Test-Path -LiteralPath $claudeModulePath)) {
    Write-Fail -TestName 'Assert-ClaudeKeyedUninstallPreconditions' -Reason ("missing Claude module: {0}" -f $claudeModulePath)
}
if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
    Write-Fail -TestName 'Assert-ClaudeKeyedUninstallPreconditions' -Reason ("missing Claude seed fixture: {0}" -f $seedFixtureRoot)
}
if (-not (Test-Path -LiteralPath $seedSettingsPath)) {
    Write-Fail -TestName 'Assert-ClaudeKeyedUninstallPreconditions' -Reason ("missing Claude seed settings: {0}" -f $seedSettingsPath)
}
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-ClaudeKeyedUninstallPreconditions' -Reason 'USERPROFILE is not set'
}

. $claudeModulePath

function Initialize-ClaudeStep8WorkRoot {
    if (Test-Path -LiteralPath $workInstallRoot) {
        Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null
    $seedText = [System.IO.File]::ReadAllText($seedSettingsPath)
    [System.IO.File]::WriteAllText((Join-Path $workInstallRoot $settingsFileName), $seedText, (Get-Utf8NoBomEncoding))

    $fixtureReadmeSrc = Join-Path $seedFixtureRoot $fixtureReadmeName
    if (Test-Path -LiteralPath $fixtureReadmeSrc) {
        Copy-Item -LiteralPath $fixtureReadmeSrc -Destination (Join-Path $workInstallRoot $fixtureReadmeName) -Force
    }
}

function Ensure-AlienArtifacts {
    $skillsPath = Join-Path $workInstallRoot $skillsDirName
    $rulesPath = Join-Path $workInstallRoot $rulesDirName
    $hooksPath = Join-Path $workInstallRoot $hooksDirName

    $alienSkillPath = Join-Path $skillsPath $alienSkillId
    if (-not (Test-Path -LiteralPath $alienSkillPath)) {
        New-Item -ItemType Directory -Path $alienSkillPath -Force | Out-Null
    }
    [System.IO.File]::WriteAllText((Join-Path $alienSkillPath 'SKILL.md'), $alienSkillManifest, (Get-Utf8NoBomEncoding))

    if (-not (Test-Path -LiteralPath $rulesPath)) {
        New-Item -ItemType Directory -Path $rulesPath -Force | Out-Null
    }
    [System.IO.File]::WriteAllText((Join-Path $rulesPath $alienRuleFileName), $alienRuleContent, (Get-Utf8NoBomEncoding))

    if (-not (Test-Path -LiteralPath $hooksPath)) {
        New-Item -ItemType Directory -Path $hooksPath -Force | Out-Null
    }
    [System.IO.File]::WriteAllText((Join-Path $hooksPath $alienHookFileName), $alienHookContent, (Get-Utf8NoBomEncoding))
}

function Assert-ManagedArtifactsPresent {
    param([Parameter(Mandatory = $true)][string] $TestName)

    $coreSkillsRoot = Join-Path (Join-Path $repoRoot 'core') $skillsDirName
    $managedIds = @(Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force | Select-Object -ExpandProperty Name)
    $skillsPath = Join-Path $workInstallRoot $skillsDirName
    foreach ($id in $managedIds) {
        if (-not (Test-Path -LiteralPath (Join-Path $skillsPath $id))) {
            Write-Fail -TestName $TestName -Reason ("expected managed skill after sync: {0}" -f $id)
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $workInstallRoot $claudeMdFileName))) {
        Write-Fail -TestName $TestName -Reason 'expected CLAUDE.md after sync'
    }

    $corePolicyRoot = Join-Path (Join-Path $repoRoot 'core') 'policy'
    $rulesPath = Join-Path $workInstallRoot $rulesDirName
    $policyFiles = @(Get-ChildItem -LiteralPath $corePolicyRoot -File -Force | Select-Object -ExpandProperty Name)
    foreach ($name in $policyFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $rulesPath $name))) {
            Write-Fail -TestName $TestName -Reason ("expected managed rule after sync: {0}" -f $name)
        }
    }

    $hooksPath = Join-Path $workInstallRoot $hooksDirName
    foreach ($hookName in @('context-before-prompt.ps1', 'context-pre-compact.ps1', 'plan-after-edit.ps1', '_hook-common.ps1')) {
        if (-not (Test-Path -LiteralPath (Join-Path $hooksPath $hookName))) {
            Write-Fail -TestName $TestName -Reason ("expected managed hook after sync: {0}" -f $hookName)
        }
    }
}

function Assert-ManagedArtifactsAbsent {
    param([Parameter(Mandatory = $true)][string] $TestName)

    $coreSkillsRoot = Join-Path (Join-Path $repoRoot 'core') $skillsDirName
    $managedIds = @(Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force | Select-Object -ExpandProperty Name)
    $skillsPath = Join-Path $workInstallRoot $skillsDirName
    foreach ($id in $managedIds) {
        if (Test-Path -LiteralPath (Join-Path $skillsPath $id)) {
            Write-Fail -TestName $TestName -Reason ("managed skill still present after uninstall: {0}" -f $id)
        }
    }

    if (Test-Path -LiteralPath (Join-Path $workInstallRoot $claudeMdFileName)) {
        Write-Fail -TestName $TestName -Reason 'CLAUDE.md must be removed by keyed uninstall'
    }

    $corePolicyRoot = Join-Path (Join-Path $repoRoot 'core') 'policy'
    $rulesPath = Join-Path $workInstallRoot $rulesDirName
    $policyFiles = @(Get-ChildItem -LiteralPath $corePolicyRoot -File -Force | Select-Object -ExpandProperty Name)
    foreach ($name in $policyFiles) {
        if (Test-Path -LiteralPath (Join-Path $rulesPath $name)) {
            Write-Fail -TestName $TestName -Reason ("managed rule still present after uninstall: {0}" -f $name)
        }
    }

    $hooksPath = Join-Path $workInstallRoot $hooksDirName
    foreach ($hookName in @('context-before-prompt.ps1', 'context-pre-compact.ps1', 'plan-after-edit.ps1', '_hook-common.ps1')) {
        if (Test-Path -LiteralPath (Join-Path $hooksPath $hookName)) {
            Write-Fail -TestName $TestName -Reason ("managed hook still present after uninstall: {0}" -f $hookName)
        }
    }
}

function Assert-AlienAndSettingsPreserved {
    param([Parameter(Mandatory = $true)][string] $TestName)

    if (-not (Test-Path -LiteralPath $workInstallRoot)) {
        Write-Fail -TestName $TestName -Reason 'InstallRoot itself must not be wiped'
    }

    $readmePath = Join-Path $workInstallRoot $fixtureReadmeName
    if ((Test-Path -LiteralPath (Join-Path $seedFixtureRoot $fixtureReadmeName)) -and -not (Test-Path -LiteralPath $readmePath)) {
        Write-Fail -TestName $TestName -Reason 'fixture README.md must survive uninstall'
    }

    $alienSkillManifestPath = Join-Path (Join-Path (Join-Path $workInstallRoot $skillsDirName) $alienSkillId) 'SKILL.md'
    if (-not (Test-Path -LiteralPath $alienSkillManifestPath)) {
        Write-Fail -TestName $TestName -Reason 'alien skill must survive keyed uninstall'
    }
    if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $workInstallRoot $rulesDirName) $alienRuleFileName))) {
        Write-Fail -TestName $TestName -Reason 'alien rule must survive keyed uninstall'
    }
    if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $workInstallRoot $hooksDirName) $alienHookFileName))) {
        Write-Fail -TestName $TestName -Reason 'alien hook must survive keyed uninstall'
    }

    $settingsPath = Join-Path $workInstallRoot $settingsFileName
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        Write-Fail -TestName $TestName -Reason 'settings.json must survive (reverse-merge, not wipe)'
    }

    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    if ($null -eq $settings.$operatorCustomKey -or [string]$settings.$operatorCustomKey -ne $operatorCustomValue) {
        Write-Fail -TestName $TestName -Reason 'operatorCustomKey must survive settings reverse-merge'
    }
    if ($null -eq $settings.env -or $null -eq $settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS) {
        Write-Fail -TestName $TestName -Reason 'env alien keys must survive settings reverse-merge'
    }
    if ($null -eq $settings.hooks -or $null -eq $settings.hooks.Notification) {
        Write-Fail -TestName $TestName -Reason 'alien Notification hook must survive'
    }
    $notificationJson = ($settings.hooks.Notification | ConvertTo-Json -Compress)
    if ($notificationJson -notmatch [regex]::Escape($alienNotificationMarker)) {
        Write-Fail -TestName $TestName -Reason 'alien Notification command must survive'
    }

    # Seed stale-user-prompt is not toolkit-managed (no hooks/<managed-file> identity),
    # so after sync+uninstall it remains as a co-located alien on UserPromptSubmit.
    if ($null -eq $settings.hooks.PSObject.Properties['UserPromptSubmit']) {
        Write-Fail -TestName $TestName -Reason 'UserPromptSubmit must remain when seed stale alien handler survives reverse-merge'
    }
    $userPromptJson = ($settings.hooks.UserPromptSubmit | ConvertTo-Json -Compress -Depth 10)
    if ($userPromptJson -notmatch [regex]::Escape($staleUserPromptMarker)) {
        Write-Fail -TestName $TestName -Reason 'stale/alien UserPromptSubmit handler must survive keyed uninstall'
    }
    if ($userPromptJson -match [regex]::Escape('context-before-prompt.ps1')) {
        Write-Fail -TestName $TestName -Reason 'toolkit UserPromptSubmit handler must be removed on uninstall'
    }
    if ($null -ne $settings.hooks.PSObject.Properties['PreCompact']) {
        Write-Fail -TestName $TestName -Reason 'managed PreCompact hook key must be removed on uninstall when empty'
    }
    if ($null -ne $settings.hooks.PSObject.Properties['PostToolUse']) {
        Write-Fail -TestName $TestName -Reason 'managed PostToolUse hook key must be removed on uninstall when empty'
    }

    $allowList = @($settings.permissions.allow)
    if ($allowList -notcontains $userAllowEntry) {
        Write-Fail -TestName $TestName -Reason 'user permissions.allow entry must survive'
    }
    foreach ($entry in @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $workInstallRoot)) {
        if ($allowList -contains $entry) {
            Write-Fail -TestName $TestName -Reason ("managed permissions.allow entry must be removed on uninstall: {0}" -f $entry)
        }
    }
    if ($allowList -contains $legacyBroadAllowPwsh -or $allowList -contains $legacyBroadAllowPowershell) {
        Write-Fail -TestName $TestName -Reason 'legacy broad permissions.allow entries must be removed on uninstall'
    }
    if ($null -eq $settings.permissions.deny -or @($settings.permissions.deny).Count -lt 1) {
        Write-Fail -TestName $TestName -Reason 'permissions.deny must survive'
    }
}

# --- Should_SyncViaOrchestrator_When_AgentClaudeAndInstallRootSet ---
$syncName = 'Should_SyncViaOrchestrator_When_AgentClaudeAndInstallRootSet'

Initialize-ClaudeStep8WorkRoot

$listLines = @(& $toolkitScript -Action ListAgents *>&1 | ForEach-Object { "$_" })
$listExit = $LASTEXITCODE
if ($null -eq $listExit) { $listExit = 0 }
$listOutput = ($listLines -join [Environment]::NewLine)
if ($listExit -ne 0) {
    Write-Fail -TestName $syncName -Reason ("toolkit.ps1 -Action ListAgents failed (exit {0}): {1}" -f $listExit, $listOutput.Trim())
}
if ($listOutput -notmatch '(?i)\bclaude\b') {
    Write-Fail -TestName $syncName -Reason ("toolkit ListAgents must include claude; got: {0}" -f $listOutput.Trim())
}

$syncLines = @(& $syncAgentScript -Agent claude -InstallRoot $workInstallRoot *>&1 | ForEach-Object { "$_" })
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
$syncOutput = ($syncLines -join [Environment]::NewLine)
if ($syncExit -ne 0) {
    Write-Fail -TestName $syncName -Reason ("sync-agent -Agent claude failed (exit {0}): {1}" -f $syncExit, $syncOutput.Trim())
}

$expectedPublishOrder = @('Publish-Skills', 'Publish-Policy', 'Publish-Router', 'Publish-Hooks')
$lastIndex = -1
foreach ($commandName in $expectedPublishOrder) {
    $matched = $false
    for ($i = 0; $i -lt $syncLines.Count; $i++) {
        if ($syncLines[$i] -match ("(?i)^{0}:\s*OK" -f [regex]::Escape($commandName))) {
            if ($i -le $lastIndex) {
                Write-Fail -TestName $syncName -Reason ("Publish order violated around {0}" -f $commandName)
            }
            $lastIndex = $i
            $matched = $true
            break
        }
    }
    if (-not $matched) {
        Write-Fail -TestName $syncName -Reason ("sync output missing {0}: OK" -f $commandName)
    }
}

Assert-ManagedArtifactsPresent -TestName $syncName

$validateLines = @(& $validateAgentScript -Agent claude -InstallRoot $workInstallRoot -Quiet *>&1 | ForEach-Object { "$_" })
$validateExit = $LASTEXITCODE
if ($null -eq $validateExit) { $validateExit = 0 }
if ($validateExit -ne 0) {
    Write-Fail -TestName $syncName -Reason ("validate-agent -Agent claude failed (exit {0}): {1}" -f $validateExit, ($validateLines -join [Environment]::NewLine).Trim())
}

$userProfileInstallRoot = Join-Path $userProfile $userProbeRelative
$syncHomeLines = @(& $syncAgentScript -Agent claude -InstallRoot $userProfileInstallRoot *>&1 | ForEach-Object { "$_" })
$syncHomeExit = $LASTEXITCODE
if ($null -eq $syncHomeExit) { $syncHomeExit = 0 }
if ($syncHomeExit -eq 0) {
    Write-Fail -TestName $syncName -Reason 'sync against USERPROFILE without -AllowUserHome must fail (no home write)'
}
if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Remove-Item -LiteralPath $userProfileInstallRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Fail -TestName $syncName -Reason 'USERPROFILE probe path must not be created without AllowUserHome'
}

$seedAfterSync = [System.IO.File]::ReadAllText($seedSettingsPath)
if ($seedAfterSync -notmatch [regex]::Escape('stale-user-prompt')) {
    Write-Fail -TestName $syncName -Reason 'versioned Claude seed settings.json must remain untouched'
}

Write-Pass -TestName $syncName

# --- Should_RemoveManagedArtifacts_When_UninstallClaudeOnFixture ---
$removeName = 'Should_RemoveManagedArtifacts_When_UninstallClaudeOnFixture'

Initialize-ClaudeStep8WorkRoot
Ensure-AlienArtifacts

$syncLines2 = @(& $syncAgentScript -Agent claude -InstallRoot $workInstallRoot *>&1 | ForEach-Object { "$_" })
$syncExit2 = $LASTEXITCODE
if ($null -eq $syncExit2) { $syncExit2 = 0 }
if ($syncExit2 -ne 0) {
    Write-Fail -TestName $removeName -Reason ("sync-agent prep failed (exit {0})" -f $syncExit2)
}

# Re-place aliens after sync (sync may not delete them, but ensure present)
Ensure-AlienArtifacts
Assert-ManagedArtifactsPresent -TestName $removeName

$whatIf = Uninstall-Toolkit -InstallRoot $workInstallRoot -WhatIf
if ($null -eq $whatIf -or $whatIf.Implemented -ne $true -or $whatIf.Success -ne $true -or $whatIf.WhatIf -ne $true) {
    Write-Fail -TestName $removeName -Reason 'Uninstall-Toolkit -WhatIf must succeed without mutating'
}
Assert-ManagedArtifactsPresent -TestName $removeName

$uninstall = Uninstall-Toolkit -InstallRoot $workInstallRoot
if ($null -eq $uninstall -or $uninstall.Implemented -ne $true -or $uninstall.Success -ne $true) {
    Write-Fail -TestName $removeName -Reason ("expected Successful Uninstall-Toolkit, got: {0}" -f $(if ($null -eq $uninstall) { 'null' } else { $uninstall.Message }))
}
if ($uninstall.ExitCode -ne 0) {
    Write-Fail -TestName $removeName -Reason ("expected ExitCode 0, got {0}" -f $uninstall.ExitCode)
}
if ($uninstall.RemovedCount -lt 1) {
    Write-Fail -TestName $removeName -Reason 'expected at least one keyed artifact removed'
}
if ($null -eq $uninstall.KeyedOnly -or $uninstall.KeyedOnly -ne $true) {
    Write-Fail -TestName $removeName -Reason 'KeyedOnly must be true'
}
if ($null -ne $uninstall.WholesaleWipe -and $uninstall.WholesaleWipe -eq $true) {
    Write-Fail -TestName $removeName -Reason 'WholesaleWipe must be false'
}

Assert-ManagedArtifactsAbsent -TestName $removeName
Assert-AlienAndSettingsPreserved -TestName $removeName

# Idempotent second uninstall
$uninstallAgain = Uninstall-Toolkit -InstallRoot $workInstallRoot
if ($null -eq $uninstallAgain -or $uninstallAgain.Success -ne $true -or $uninstallAgain.Implemented -ne $true) {
    Write-Fail -TestName $removeName -Reason 'idempotent Uninstall-Toolkit must remain Success when artifacts already gone'
}
Assert-AlienAndSettingsPreserved -TestName $removeName

$seedFinal = [System.IO.File]::ReadAllText($seedSettingsPath)
if ($seedFinal -notmatch [regex]::Escape('stale-user-prompt')) {
    Write-Fail -TestName $removeName -Reason 'versioned Claude seed settings.json must remain intact after Step 8'
}

Write-Pass -TestName $removeName

Write-Host 'Assert-ClaudeKeyedUninstall: ALL PASS'
exit 0
