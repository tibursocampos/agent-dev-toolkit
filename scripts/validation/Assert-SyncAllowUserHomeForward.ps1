#Requires -Version 5.1
# Tests:
#   Should_ForwardAllowUserHomeIntoPublishArgs_When_SourceInspected
#   Should_BlockPublishUnderUserProfile_When_AllowUserHomeAbsent
#   Should_PublishUnderUserProfile_When_AllowUserHomePresent
#   Should_ForwardAllowUserHome_When_ClaudeUninstallToolkitInvoked
#   Should_ForwardAllowUserHome_When_SampleAdapterUninstallToolkitInvoked (codex, antigravity, grok, opencode, copilot)
#
# C1: sync-agent.ps1 must forward -AllowUserHome into every Publish-* call's
# $publishArgs, not just its own top-level Resolve-InstallRoot check. Each
# adapter Publish-* re-resolves InstallRoot with its own -AllowUserHome switch,
# so a missing forward fails deep inside the adapter even when sync-agent's own
# guard passed.
# C2: Uninstall-Toolkit for Claude and sample adapters that implement keyed
# uninstall must accept and forward -AllowUserHome the same way.
#
# Probe location: MUST stay under USERPROFILE. Resolve-InstallRoot only blocks
# paths under USERPROFILE without -AllowUserHome; a TEMP probe would not exercise
# the guard. Prefer unique GUID subdirs + try/finally cleanup (and orphan sweep)
# over TEMP. Workflow does not need if: always() when this finally runs.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$syncAgentScript = Join-Path $scriptsRoot 'sync-agent.ps1'
$claudeModuleRelativePath = 'adapters\claude\ClaudeAdapter.ps1'

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

function Remove-ProbeDirectoryIfPresent {
    param([Parameter(Mandatory = $true)][string] $Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function New-DisposableUserProfileProbeRoot {
    param(
        [Parameter(Mandatory = $true)][string] $UserProfile,
        [Parameter(Mandatory = $true)][string] $Label,
        [Parameter(Mandatory = $true)][string] $NamePrefix
    )

    $probeRelative = ('{0}{1}-{2}' -f $NamePrefix, $Label, [guid]::NewGuid().ToString('N'))
    return (Join-Path $UserProfile $probeRelative)
}

function Register-AllowUserHomeProbe {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][System.Collections.IList] $Registry
    )
    [void]$Registry.Add($Path)
    return $Path
}

function Remove-RegisteredAllowUserHomeProbes {
    param([Parameter(Mandatory = $true)][System.Collections.IList] $Registry)
    foreach ($probePath in @($Registry)) {
        Remove-ProbeDirectoryIfPresent -Path $probePath
    }
    $Registry.Clear()
}

function Remove-OrphanAllowUserHomeProbes {
    param(
        [Parameter(Mandatory = $true)][string] $UserProfile,
        [Parameter(Mandatory = $true)][string] $NamePrefix
    )

    if (-not (Test-Path -LiteralPath $UserProfile)) {
        return
    }

    Get-ChildItem -LiteralPath $UserProfile -Force -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name.StartsWith($NamePrefix, [System.StringComparison]::OrdinalIgnoreCase) } |
        ForEach-Object { Remove-ProbeDirectoryIfPresent -Path $_.FullName }
}

function Assert-AdapterUninstallAllowUserHomeForward {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter(Mandatory = $true)][string] $ModulePath,
        [Parameter(Mandatory = $true)][string] $ProbeInstallRoot,
        [Parameter(Mandatory = $true)][string] $MarkerRelativePath,
        [Parameter(Mandatory = $true)][string] $SyncAgentPath,
        [Parameter()][string] $Mode
    )

    $syncArgs = @{
        Agent       = $AgentId
        InstallRoot = $ProbeInstallRoot
        AllowUserHome = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($Mode)) {
        $syncArgs['Mode'] = $Mode
    }

    $publishLines = @(& $SyncAgentPath @syncArgs *>&1 | ForEach-Object { "$_" })
    $publishExit = $LASTEXITCODE
    if ($null -eq $publishExit) { $publishExit = 0 }
    $publishText = ($publishLines -join [Environment]::NewLine)
    if ($publishExit -ne 0) {
        Write-Fail -TestName $TestName -Reason ("sync-agent {0} with -AllowUserHome must succeed under USERPROFILE; exit {1}: {2}" -f $AgentId, $publishExit, $publishText.Trim())
    }

    $markerPath = Join-Path $ProbeInstallRoot $MarkerRelativePath
    if (-not (Test-Path -LiteralPath $markerPath)) {
        Write-Fail -TestName $TestName -Reason ("expected published marker missing under USERPROFILE probe for {0}: {1}" -f $AgentId, $markerPath)
    }

    # Drop prior adapter's Uninstall-Toolkit before loading the next module.
    Remove-Item -Path 'Function:\Uninstall-Toolkit' -ErrorAction SilentlyContinue
    . $ModulePath

    $uninstallBlockedThrew = $false
    try {
        if (-not [string]::IsNullOrWhiteSpace($Mode)) {
            $null = Uninstall-Toolkit -InstallRoot $ProbeInstallRoot -Mode $Mode
        }
        else {
            $null = Uninstall-Toolkit -InstallRoot $ProbeInstallRoot
        }
    }
    catch {
        $uninstallBlockedThrew = $true
        $blockedMessage = $_.Exception.Message
        if ($blockedMessage -notmatch '(?i)AllowUserHome' -or $blockedMessage -notmatch '(?i)USERPROFILE') {
            Write-Fail -TestName $TestName -Reason ("blocked Uninstall-Toolkit ({0}) must mention AllowUserHome/USERPROFILE; got: {1}" -f $AgentId, $blockedMessage)
        }
    }
    if (-not $uninstallBlockedThrew) {
        Write-Fail -TestName $TestName -Reason ("Uninstall-Toolkit ({0}) against USERPROFILE without -AllowUserHome must throw" -f $AgentId)
    }
    if (-not (Test-Path -LiteralPath $markerPath)) {
        Write-Fail -TestName $TestName -Reason ("probe marker must still exist after blocked Uninstall-Toolkit ({0}): {1}" -f $AgentId, $markerPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($Mode)) {
        $uninstallAllowed = Uninstall-Toolkit -InstallRoot $ProbeInstallRoot -Mode $Mode -AllowUserHome
    }
    else {
        $uninstallAllowed = Uninstall-Toolkit -InstallRoot $ProbeInstallRoot -AllowUserHome
    }
    if ($null -eq $uninstallAllowed -or $uninstallAllowed.Success -ne $true -or $uninstallAllowed.Implemented -ne $true) {
        $detail = if ($null -eq $uninstallAllowed) { 'null' } else { [string]$uninstallAllowed.Message }
        Write-Fail -TestName $TestName -Reason ("Uninstall-Toolkit ({0}) with -AllowUserHome must succeed under USERPROFILE; got: {1}" -f $AgentId, $detail)
    }

    $removedCount = 0
    if ($uninstallAllowed.PSObject.Properties.Name -contains 'RemovedCount') {
        $removedCount = [int]$uninstallAllowed.RemovedCount
    }
    elseif ($uninstallAllowed.PSObject.Properties.Name -contains 'RemovedPathCount') {
        $removedCount = [int]$uninstallAllowed.RemovedPathCount
    }

    if ($removedCount -lt 1) {
        Write-Fail -TestName $TestName -Reason ("expected at least one keyed artifact removed by Uninstall-Toolkit -AllowUserHome ({0})" -f $AgentId)
    }
    if (Test-Path -LiteralPath $markerPath) {
        Write-Fail -TestName $TestName -Reason ("marker must be removed after Uninstall-Toolkit -AllowUserHome ({0}): {1}" -f $AgentId, $markerPath)
    }
}

foreach ($required in @($repoRootScript, $constantsScript, $syncAgentScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-SyncAllowUserHomeForwardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript
. $constantsScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

# Publish-* adapters dotsource Copy-ToolkitManagedTree.ps1 inside an Initialize-*
# helper (function scope). Preload at script scope so Invoke-ToolkitManagedSkillsPublish
# remains visible for sync-agent invocations in this process.
$managedTreeLib = Join-Path $libDir 'Copy-ToolkitManagedTree.ps1'
if (-not (Test-Path -LiteralPath $managedTreeLib)) {
    Write-Fail -TestName 'Assert-SyncAllowUserHomeForwardPreconditions' -Reason ("missing {0}" -f $managedTreeLib)
}
. $managedTreeLib

$claudeModulePath = Join-Path $repoRoot $claudeModuleRelativePath
if (-not (Test-Path -LiteralPath $claudeModulePath)) {
    Write-Fail -TestName 'Assert-SyncAllowUserHomeForwardPreconditions' -Reason ("missing Claude module: {0}" -f $claudeModulePath)
}

$userProfile = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-SyncAllowUserHomeForwardPreconditions' -Reason 'USERPROFILE is not set'
}

$probeNamePrefix = $script:ToolkitConstant.AllowUserHomeProbeNamePrefix
$registeredProbes = New-Object System.Collections.Generic.List[string]

# Unique probe per run avoids collisions when asserts/smokes overlap or AV locks a prior folder.
$probeInstallRoot = Register-AllowUserHomeProbe `
    -Path (New-DisposableUserProfileProbeRoot -UserProfile $userProfile -Label 'claude' -NamePrefix $probeNamePrefix) `
    -Registry $registeredProbes
$claudeAgentId = 'claude'
$skillsDirName = 'skills'
$rulesDirName = 'rules'
$claudeMdFileName = 'CLAUDE.md'
$agentsMdFileName = 'AGENTS.md'

$sampleUninstallAdapters = @(
    @{
        AgentId            = 'codex'
        ModuleRelativePath = 'adapters\codex\CodexAdapter.ps1'
        MarkerRelativePath = $agentsMdFileName
    },
    @{
        AgentId            = 'antigravity'
        ModuleRelativePath = 'adapters\antigravity\AntigravityAdapter.ps1'
        MarkerRelativePath = (Join-Path (Join-Path 'config' 'plugins') (Join-Path 'agent-dev-toolkit' 'GUARDRAILS.md'))
    },
    @{
        AgentId            = 'grok'
        ModuleRelativePath = 'adapters\grok\GrokAdapter.ps1'
        MarkerRelativePath = $agentsMdFileName
    },
    @{
        AgentId            = 'opencode'
        ModuleRelativePath = 'adapters\opencode\OpenCodeAdapter.ps1'
        MarkerRelativePath = $agentsMdFileName
    },
    @{
        AgentId            = 'copilot'
        ModuleRelativePath = 'adapters\copilot\CopilotAdapter.ps1'
        MarkerRelativePath = 'copilot-instructions.md'
        Mode               = 'user'
    }
)

foreach ($sample in $sampleUninstallAdapters) {
    $modulePath = Join-Path $repoRoot $sample.ModuleRelativePath
    if (-not (Test-Path -LiteralPath $modulePath)) {
        Write-Fail -TestName 'Assert-SyncAllowUserHomeForwardPreconditions' -Reason ("missing adapter module: {0}" -f $modulePath)
    }
}

Remove-ProbeDirectoryIfPresent -Path $probeInstallRoot
Remove-OrphanAllowUserHomeProbes -UserProfile $userProfile -NamePrefix $probeNamePrefix

# --- Should_ForwardAllowUserHomeIntoPublishArgs_When_SourceInspected ---
$sourceCheckName = 'Should_ForwardAllowUserHomeIntoPublishArgs_When_SourceInspected'
$syncAgentText = Get-Content -LiteralPath $syncAgentScript -Raw
$forwardPattern = '\$publishArgs\[\$script:ToolkitConstant\.AllowUserHomeParameterName\]\s*=\s*\$true'
if ($syncAgentText -notmatch $forwardPattern) {
    Write-Fail -TestName $sourceCheckName -Reason 'sync-agent.ps1 does not forward AllowUserHome into $publishArgs before invoking Publish-* commands'
}
Write-Pass -TestName $sourceCheckName

try {
    # --- Should_BlockPublishUnderUserProfile_When_AllowUserHomeAbsent ---
    $blockName = 'Should_BlockPublishUnderUserProfile_When_AllowUserHomeAbsent'
    $blockedLines = @(& $syncAgentScript -Agent $claudeAgentId -InstallRoot $probeInstallRoot *>&1 | ForEach-Object { "$_" })
    $blockedExit = $LASTEXITCODE
    if ($null -eq $blockedExit) { $blockedExit = 0 }
    $blockedText = ($blockedLines -join [Environment]::NewLine)
    if ($blockedExit -eq 0) {
        Write-Fail -TestName $blockName -Reason 'sync-agent against USERPROFILE without -AllowUserHome must exit non-zero'
    }
    if ($blockedText -notmatch '(?i)AllowUserHome' -or $blockedText -notmatch '(?i)USERPROFILE') {
        Write-Fail -TestName $blockName -Reason ("blocked sync must mention AllowUserHome/USERPROFILE; got: {0}" -f $blockedText.Trim())
    }
    if (Test-Path -LiteralPath $probeInstallRoot) {
        Write-Fail -TestName $blockName -Reason 'sync-agent must not create USERPROFILE probe InstallRoot without -AllowUserHome'
    }
    Write-Pass -TestName $blockName

    # --- Should_PublishUnderUserProfile_When_AllowUserHomePresent ---
    $publishName = 'Should_PublishUnderUserProfile_When_AllowUserHomePresent'
    $publishLines = @(& $syncAgentScript -Agent $claudeAgentId -InstallRoot $probeInstallRoot -AllowUserHome *>&1 | ForEach-Object { "$_" })
    $publishExit = $LASTEXITCODE
    if ($null -eq $publishExit) { $publishExit = 0 }
    $publishText = ($publishLines -join [Environment]::NewLine)
    if ($publishExit -ne 0) {
        Write-Fail -TestName $publishName -Reason ("sync-agent with -AllowUserHome must succeed under USERPROFILE; exit {0}: {1}" -f $publishExit, $publishText.Trim())
    }

    $probeSkillsPath = Join-Path $probeInstallRoot $skillsDirName
    $probeRulesPath = Join-Path $probeInstallRoot $rulesDirName
    $probeClaudeMdPath = Join-Path $probeInstallRoot $claudeMdFileName
    foreach ($expectedPath in @($probeSkillsPath, $probeRulesPath, $probeClaudeMdPath)) {
        if (-not (Test-Path -LiteralPath $expectedPath)) {
            Write-Fail -TestName $publishName -Reason ("expected published artifact missing under USERPROFILE probe (AllowUserHome forwarding likely broken): {0}" -f $expectedPath)
        }
    }
    Write-Pass -TestName $publishName

    # --- Should_ForwardAllowUserHome_When_ClaudeUninstallToolkitInvoked ---
    $uninstallForwardName = 'Should_ForwardAllowUserHome_When_ClaudeUninstallToolkitInvoked'
    . $claudeModulePath

    $uninstallBlockedThrew = $false
    try {
        $null = Uninstall-Toolkit -InstallRoot $probeInstallRoot
    }
    catch {
        $uninstallBlockedThrew = $true
        $blockedMessage = $_.Exception.Message
        if ($blockedMessage -notmatch '(?i)AllowUserHome' -or $blockedMessage -notmatch '(?i)USERPROFILE') {
            Write-Fail -TestName $uninstallForwardName -Reason ("blocked Uninstall-Toolkit must mention AllowUserHome/USERPROFILE; got: {0}" -f $blockedMessage)
        }
    }
    if (-not $uninstallBlockedThrew) {
        Write-Fail -TestName $uninstallForwardName -Reason 'Uninstall-Toolkit against USERPROFILE without -AllowUserHome must throw'
    }
    if (-not (Test-Path -LiteralPath $probeClaudeMdPath)) {
        Write-Fail -TestName $uninstallForwardName -Reason 'probe CLAUDE.md must still exist after blocked Uninstall-Toolkit attempt'
    }

    $uninstallAllowed = Uninstall-Toolkit -InstallRoot $probeInstallRoot -AllowUserHome
    if ($null -eq $uninstallAllowed -or $uninstallAllowed.Success -ne $true -or $uninstallAllowed.Implemented -ne $true) {
        $detail = if ($null -eq $uninstallAllowed) { 'null' } else { [string]$uninstallAllowed.Message }
        Write-Fail -TestName $uninstallForwardName -Reason ("Uninstall-Toolkit with -AllowUserHome must succeed under USERPROFILE; got: {0}" -f $detail)
    }
    if ($uninstallAllowed.RemovedCount -lt 1) {
        Write-Fail -TestName $uninstallForwardName -Reason 'expected at least one keyed artifact removed by Uninstall-Toolkit -AllowUserHome'
    }
    if (Test-Path -LiteralPath $probeClaudeMdPath) {
        Write-Fail -TestName $uninstallForwardName -Reason 'CLAUDE.md must be removed after Uninstall-Toolkit -AllowUserHome'
    }

    Write-Pass -TestName $uninstallForwardName

    # --- Should_ForwardAllowUserHome_When_SampleAdapterUninstallToolkitInvoked ---
    $sampleUninstallName = 'Should_ForwardAllowUserHome_When_SampleAdapterUninstallToolkitInvoked'
    foreach ($sample in $sampleUninstallAdapters) {
        $sampleProbe = Register-AllowUserHomeProbe `
            -Path (New-DisposableUserProfileProbeRoot -UserProfile $userProfile -Label $sample.AgentId -NamePrefix $probeNamePrefix) `
            -Registry $registeredProbes
        try {
            Remove-ProbeDirectoryIfPresent -Path $sampleProbe
            Assert-AdapterUninstallAllowUserHomeForward `
                -TestName $sampleUninstallName `
                -AgentId $sample.AgentId `
                -ModulePath (Join-Path $repoRoot $sample.ModuleRelativePath) `
                -ProbeInstallRoot $sampleProbe `
                -MarkerRelativePath $sample.MarkerRelativePath `
                -SyncAgentPath $syncAgentScript `
                -Mode $sample.Mode
        }
        finally {
            Remove-ProbeDirectoryIfPresent -Path $sampleProbe
        }
    }
    Write-Pass -TestName $sampleUninstallName
}
finally {
    # Always wipe registered probes + any orphaned prefix matches (crash / AV lock leftovers).
    Remove-RegisteredAllowUserHomeProbes -Registry $registeredProbes
    Remove-OrphanAllowUserHomeProbes -UserProfile $userProfile -NamePrefix $probeNamePrefix
}

Write-Host 'Assert-SyncAllowUserHomeForward: ALL PASS'
exit 0
