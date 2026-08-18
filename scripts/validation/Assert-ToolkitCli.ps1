#Requires -Version 5.1
# Tests:
#   Should_ListRegistryAgents_When_ToolkitStartsAction
#   Should_RequireAgentChoice_When_SyncOrValidateSelected
#   Should_PassAgentToOrchestrator_When_AgentFlagSet
#   Should_RequireAgentAndWireUninstall_When_UninstallSelected
#   Should_FailBackupStub_When_ForceStubAbsent
#   Should_ExposeCliUiAndHelpConstants_When_LibsLoaded
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'
$toolkitScript = Join-Path $scriptsRoot 'toolkit.ps1'
$constantsScript = Join-Path $scriptsRoot '_lib\ToolkitConstants.ps1'
$cliUiScript = Join-Path $scriptsRoot '_lib\ToolkitCliUi.ps1'

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

function Invoke-ScriptCapture {
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter()][string[]] $ArgumentList = @()
    )

    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 0
    }

    return [PSCustomObject]@{
        ExitCode = [int]$code
        Output   = $output
    }
}

foreach ($required in @($repoRootScript, $toolkitScript, $constantsScript, $cliUiScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-ToolkitCliPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$expectedIds = @(
    'cursor',
    'antigravity',
    'claude',
    'codex',
    'copilot',
    'opencode',
    'grok',
    'zcode',
    'hermes',
    'openhands'
)

# --- Should_ExposeCliUiAndHelpConstants_When_LibsLoaded ---
$uiName = 'Should_ExposeCliUiAndHelpConstants_When_LibsLoaded'
. $constantsScript
. $cliUiScript
foreach ($fn in @('Clear-ToolkitScreen', 'Show-ToolkitHeader', 'Read-ToolkitChoice', 'Pause-Toolkit', 'Write-ToolkitHint')) {
    if (-not (Get-Command -Name $fn -ErrorAction SilentlyContinue)) {
        Write-Fail -TestName $uiName -Reason ("expected function {0} from ToolkitCliUi.ps1" -f $fn)
    }
}
foreach ($key in @('ToolkitHelpActionsBody', 'ToolkitHelpCoreVsAgentBody', 'ToolkitHelpFlagsBody', 'ToolkitMenuSyncLine', 'ToolkitMenuHelpLine')) {
    if (-not $script:ToolkitMessage.ContainsKey($key) -or [string]::IsNullOrWhiteSpace([string]$script:ToolkitMessage[$key])) {
        Write-Fail -TestName $uiName -Reason ("expected ToolkitMessage.{0}" -f $key)
    }
}
$expectedCiSmokeScriptCount = [int]$script:ToolkitConstant.ExpectedCiSmokeScriptCount
if (-not $script:ToolkitConstant.ContainsKey('CiSmokeScripts') -or @($script:ToolkitConstant.CiSmokeScripts).Count -lt $expectedCiSmokeScriptCount) {
    Write-Fail -TestName $uiName -Reason ('expected ToolkitConstant.CiSmokeScripts with {0} entries' -f $expectedCiSmokeScriptCount)
}
$labMenuChoices = @($script:ToolkitConstant.ToolkitLabMenuChoices)
foreach ($smoke in @($script:ToolkitConstant.CiSmokeScripts)) {
    $smokeId = [string]$smoke.Id
    if ($labMenuChoices -notcontains $smokeId) {
        Write-Fail -TestName $uiName -Reason ("expected ToolkitConstant.ToolkitLabMenuChoices to include smoke id '{0}'" -f $smokeId)
    }
}
if (-not $script:ToolkitConstant.ContainsKey('ToolkitMainMenuChoices')) {
    Write-Fail -TestName $uiName -Reason 'expected ToolkitConstant.ToolkitMainMenuChoices'
}
Write-Pass -TestName $uiName

# --- Should_ListRegistryAgents_When_ToolkitStartsAction ---
$listName = 'Should_ListRegistryAgents_When_ToolkitStartsAction'
$list = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'ListAgents')
if ($list.ExitCode -ne 0) {
    Write-Fail -TestName $listName -Reason ("expected exit 0 for ListAgents; exit={0}; output={1}" -f $list.ExitCode, $list.Output.Trim())
}
if ($list.Output -notmatch 'Available agents') {
    Write-Fail -TestName $listName -Reason 'expected Available agents header'
}
foreach ($id in $expectedIds) {
    if ($list.Output -notmatch [regex]::Escape($id)) {
        Write-Fail -TestName $listName -Reason ("expected registry agent id '{0}' in list output" -f $id)
    }
}
$syncList = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Sync')
if ($syncList.ExitCode -eq 0) {
    Write-Fail -TestName $listName -Reason 'Sync without -Agent must not succeed'
}
if ($syncList.Output -notmatch 'Available agents' -and $syncList.Output -notmatch 'cursor') {
    Write-Fail -TestName $listName -Reason ("expected agent listing when Sync starts without -Agent; got: {0}" -f $syncList.Output.Trim())
}
Write-Pass -TestName $listName

# --- Should_RequireAgentChoice_When_SyncOrValidateSelected ---
$requireName = 'Should_RequireAgentChoice_When_SyncOrValidateSelected'
foreach ($action in @('Sync', 'Validate')) {
    $result = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', $action)
    if ($result.ExitCode -eq 0) {
        Write-Fail -TestName $requireName -Reason ("expected non-zero exit for -Action {0} without -Agent" -f $action)
    }
    if ($result.Output -notmatch 'requires -Agent' -and $result.Output -notmatch 'Agent is required') {
        Write-Fail -TestName $requireName -Reason ("expected agent-required message for {0}; got: {1}" -f $action, $result.Output.Trim())
    }
}
Write-Pass -TestName $requireName

# --- Should_PassAgentToOrchestrator_When_AgentFlagSet ---
$passName = 'Should_PassAgentToOrchestrator_When_AgentFlagSet'
$sync = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Sync', '-Agent', 'cursor')
if ($sync.ExitCode -ne 0) {
    Write-Fail -TestName $passName -Reason ("expected toolkit sync cursor to succeed; exit={0}; output={1}" -f $sync.ExitCode, $sync.Output.Trim())
}
if ($sync.Output -notmatch 'Sync agent: cursor' -and $sync.Output -notmatch 'sync-agent') {
    Write-Fail -TestName $passName -Reason ("expected sync-agent orchestration for cursor; got: {0}" -f $sync.Output.Trim())
}
if ($sync.Output -notmatch 'Sync completed') {
    Write-Fail -TestName $passName -Reason ("expected Sync completed; got: {0}" -f $sync.Output.Trim())
}

$validate = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Validate', '-Agent', 'cursor', '-Quiet')
if ($validate.ExitCode -ne 0) {
    Write-Fail -TestName $passName -Reason ("expected validate via toolkit to pass; exit={0}; output={1}" -f $validate.ExitCode, $validate.Output.Trim())
}
if ($validate.Output -notmatch 'Validate agent: cursor' -and $validate.Output -notmatch 'validate-agent') {
    Write-Fail -TestName $passName -Reason ("expected validate-agent orchestration for cursor; got: {0}" -f $validate.Output.Trim())
}
Write-Pass -TestName $passName

# --- Should_RequireAgentAndWireUninstall_When_UninstallSelected ---
$uninstallName = 'Should_RequireAgentAndWireUninstall_When_UninstallSelected'
$uninstallMissing = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Uninstall')
if ($uninstallMissing.ExitCode -eq 0) {
    Write-Fail -TestName $uninstallName -Reason 'Uninstall without -Agent must not succeed'
}
if ($uninstallMissing.Output -notmatch 'requires -Agent' -and $uninstallMissing.Output -notmatch 'Agent is required') {
    Write-Fail -TestName $uninstallName -Reason ("expected agent-required message for Uninstall; got: {0}" -f $uninstallMissing.Output.Trim())
}

$uninstallCursor = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Uninstall', '-Agent', 'cursor')
if ($uninstallCursor.ExitCode -ne 0) {
    Write-Fail -TestName $uninstallName -Reason ("expected Uninstall cursor on fixture to succeed; exit={0}; output={1}" -f $uninstallCursor.ExitCode, $uninstallCursor.Output.Trim())
}
if ($uninstallCursor.Output -notmatch 'Uninstall completed') {
    Write-Fail -TestName $uninstallName -Reason ("expected Uninstall completed for cursor; got: {0}" -f $uninstallCursor.Output.Trim())
}

$uninstallClaude = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Uninstall', '-Agent', 'claude')
if ($uninstallClaude.ExitCode -ne 0) {
    Write-Fail -TestName $uninstallName -Reason ("expected Uninstall claude on fixture to succeed; exit={0}; output={1}" -f $uninstallClaude.ExitCode, $uninstallClaude.Output.Trim())
}
if ($uninstallClaude.Output -notmatch 'Uninstall completed') {
    Write-Fail -TestName $uninstallName -Reason ("expected Uninstall completed for claude; got: {0}" -f $uninstallClaude.Output.Trim())
}
Write-Pass -TestName $uninstallName

# --- Should_FailBackupStub_When_ForceStubAbsent ---
$backupName = 'Should_FailBackupStub_When_ForceStubAbsent'
$backup = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Backup')
if ($backup.ExitCode -eq 0) {
    Write-Fail -TestName $backupName -Reason 'Backup stub must exit non-zero without -ForceStub'
}
if ($backup.Output -notmatch '(?i)not implemented' -and $backup.Output -notmatch 'ForceStub') {
    Write-Fail -TestName $backupName -Reason ("expected Backup stub refusal message; got: {0}" -f $backup.Output.Trim())
}

$backupForced = Invoke-ScriptCapture -ScriptPath $toolkitScript -ArgumentList @('-Action', 'Backup', '-ForceStub')
if ($backupForced.ExitCode -ne 0) {
    Write-Fail -TestName $backupName -Reason ("Backup with -ForceStub must exit 0; exit={0}; output={1}" -f $backupForced.ExitCode, $backupForced.Output.Trim())
}
Write-Pass -TestName $backupName

Write-Host 'Assert-ToolkitCli: ALL PASS'
exit 0
