#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_HooksJsonVersion1PreToolUse
#
# Frente 2.4: Copilot version:1 preToolUse path + secrets guard.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$guardHarnessScript = Join-Path $libDir 'Invoke-PathSecretsGuardHarness.ps1'

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

foreach ($required in @($repoRootScript, $constantsScript, $guardHarnessScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CopilotPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
. $guardHarnessScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksRoot = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'copilot') 'assets') 'hooks'
$guardScript = Join-Path $hooksRoot 'guard-pre-tool.ps1'
$hooksJsonPath = Join-Path $hooksRoot 'hooks.json'
$commonScript = Join-Path $hooksRoot '_hook-common.ps1'

if (-not (Test-Path -LiteralPath $guardScript) -or -not (Test-Path -LiteralPath $commonScript)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'missing Copilot guard-pre-tool or _hook-common'
}
. $commonScript
if (-not (Get-Command -Name Get-ToolkitPathSecretsGuardVerdict -ErrorAction SilentlyContinue)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'GuardCommon helpers not loaded'
}
Write-Pass -TestName 'Should_Pass_When_GuardHookPresent'

$fixtureRoot = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') 'validation') 'fixtures') 'copilot-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$reparseTarget = Join-Path ([System.IO.Path]::GetTempPath()) 'agent-dev-toolkit-copilot-reparse-target'
$reparseLink = Join-Path (Join-Path $fixtureRoot 'src') 'linked'
$null = New-Item -ItemType Directory -Path $reparseTarget -Force
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $reparseLink) -Force
$reparseItemType = if ($env:OS -eq 'Windows_NT') { 'Junction' } else { 'SymbolicLink' }
$null = New-Item -ItemType $reparseItemType -Path $reparseLink -Target $reparseTarget
$reparsePayload = @{ hookEventName = 'preToolUse'; toolName = 'write'; toolArgs = (@{ path = (Join-Path $reparseLink 'escape.cs'); content = 'class X {}' } | ConvertTo-Json -Compress); cwd = $fixtureRoot }

$cases = @(
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ForbiddenSddPath'; Payload = @{ hookEventName = 'preToolUse'; toolName = 'write'; toolArgs = (@{ path = (Join-Path $fixtureRoot 'PRD\blocked.md'); content = '# blocked' } | ConvertTo-Json -Compress); cwd = $fixtureRoot }; ExpectedDecision = 'deny'; ExpectedExitCodes = @(2); Acceptance = 'ExitCodeOrDecision'; FailureReason = 'expected deny for forbidden SDD path' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_SecretPatternDetected'; Payload = @{ hookEventName = 'preToolUse'; toolName = 'write'; toolArgs = (@{ path = (Join-Path $fixtureRoot 'src\ok.cs'); content = 'const string key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";' } | ConvertTo-Json -Compress); cwd = $fixtureRoot }; ExpectedDecision = 'deny'; ExpectedExitCodes = @(2); Acceptance = 'ExitCodeOrDecision'; FailureReason = 'expected deny for secret pattern' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_HookIdentityMissing'; Payload = @{ toolName = 'write'; toolArgs = (@{ path = (Join-Path $fixtureRoot 'src\missing-identity.cs'); content = 'class X {}' } | ConvertTo-Json -Compress); cwd = $fixtureRoot }; ExpectedDecision = 'deny'; ExpectedExitCodes = @(2); Acceptance = 'ExitCodeOrDecision'; FailureReason = 'write without preToolUse identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ShellHookIdentityMissing'; Payload = @{ toolName = 'bash'; toolArgs = (@{ command = 'Set-Content -Path src\missing-shell-identity.cs -Value x' } | ConvertTo-Json -Compress); cwd = $fixtureRoot }; ExpectedDecision = 'deny'; ExpectedExitCodes = @(2); Acceptance = 'ExitCodeOrDecision'; FailureReason = 'shell without preToolUse identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_DescendantReparseEscapesWorkspace'; Payload = $reparsePayload; ExpectedDecision = 'deny'; ExpectedExitCodes = @(2); Acceptance = 'ExitCodeOrDecision'; FailureReason = 'write through an escaping junction must deny' }
)
try {
    Invoke-PathSecretsGuardHarness -AdapterName 'Copilot' -HookScriptPath $guardScript -Cases $cases -GetDecision {
        param($Payload)
        if ($null -eq $Payload) { return $null }
        return [string]$Payload.permissionDecision
    }
}
finally {
    Remove-Item -LiteralPath $reparseLink -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $reparseTarget -Force -Recurse -ErrorAction SilentlyContinue
}

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonVersion1PreToolUse' -Reason 'missing hooks.json'
}
$hooksText = Get-Content -LiteralPath $hooksJsonPath -Raw -Encoding UTF8
$hooksObj = $hooksText | ConvertFrom-Json
if ([int]$hooksObj.version -ne 1) {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonVersion1PreToolUse' -Reason 'hooks.json version must be 1'
}
if ($hooksText -notmatch '(?i)preToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonVersion1PreToolUse' -Reason 'hooks.json missing preToolUse'
}
if ($hooksText -notmatch 'guard-pre-tool\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonVersion1PreToolUse' -Reason 'hooks.json must wire guard-pre-tool.ps1'
}
if ($hooksText -match 'toolkit-session-start') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonVersion1PreToolUse' -Reason 'legacy marker hooks must be replaced'
}
Write-Pass -TestName 'Should_Pass_When_HooksJsonVersion1PreToolUse'

Write-Host 'Assert-CopilotPathSecretsGuard: ALL PASS'
exit 0
