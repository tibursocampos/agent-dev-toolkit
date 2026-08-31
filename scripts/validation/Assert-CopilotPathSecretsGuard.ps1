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

function Invoke-GuardHook {
    param(
        [Parameter(Mandatory = $true)][string] $HookScriptPath,
        [Parameter(Mandatory = $true)][hashtable] $Payload
    )

    $json = $Payload | ConvertTo-Json -Compress -Depth 6
    $output = $json | pwsh -NoProfile -File $HookScriptPath 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
    $parsed = $null
    try {
        $parsed = $output.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $parsed = $null
    }
    return [PSCustomObject]@{ ExitCode = [int]$code; Output = $output; Payload = $parsed }
}

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CopilotPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksRoot = Join-Path $repoRoot 'adapters\copilot\assets\hooks'
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

$fixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\copilot-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$deny = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    toolName = 'write'
    toolArgs = (@{ path = (Join-Path $fixtureRoot 'PRD\blocked.md'); content = '# blocked' } | ConvertTo-Json -Compress)
    cwd      = $fixtureRoot
}
$denied = ($deny.ExitCode -eq 2) -or ($null -ne $deny.Payload -and [string]$deny.Payload.permissionDecision -eq 'deny')
if (-not $denied) {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("expected deny; exit={0} output={1}" -f $deny.ExitCode, $deny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath'

$secret = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    toolName = 'write'
    toolArgs = (@{
            path    = (Join-Path $fixtureRoot 'src\ok.cs')
            content = 'const string key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";'
        } | ConvertTo-Json -Compress)
    cwd = $fixtureRoot
}
$secretDenied = ($secret.ExitCode -eq 2) -or ($null -ne $secret.Payload -and [string]$secret.Payload.permissionDecision -eq 'deny')
if (-not $secretDenied) {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("expected secret deny; exit={0} output={1}" -f $secret.ExitCode, $secret.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretPatternDetected'

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
