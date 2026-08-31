#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_HooksJsonWiresPreToolUse
#
# Frente 2.9: Antigravity PreToolUse path + secrets guard.
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
        Write-Fail -TestName 'Assert-AntigravityPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksRoot = Join-Path $repoRoot 'adapters\antigravity\assets\hooks'
$guardScript = Join-Path $hooksRoot 'guard-pre-tool.ps1'
$hooksJsonPath = Join-Path $hooksRoot 'hooks.json'
$commonScript = Join-Path $hooksRoot '_hook-common.ps1'
$publishHooks = Join-Path $repoRoot 'adapters\antigravity\Publish-AntigravityHooks.ps1'

if (-not (Test-Path -LiteralPath $guardScript) -or -not (Test-Path -LiteralPath $commonScript)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'missing Antigravity guard-pre-tool or _hook-common under assets/hooks'
}
if (-not (Test-Path -LiteralPath $publishHooks)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'missing Publish-AntigravityHooks.ps1'
}
. $commonScript
if (-not (Get-Command -Name Get-ToolkitPathSecretsGuardVerdict -ErrorAction SilentlyContinue)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'GuardCommon helpers not loaded'
}
Write-Pass -TestName 'Should_Pass_When_GuardHookPresent'

$fixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\antigravity-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$deny = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    toolCall = @{
        name = 'write_to_file'
        args = @{
            TargetFile  = (Join-Path $fixtureRoot 'PRD\blocked.md')
            CodeContent = '# blocked'
        }
    }
    workspacePaths = @($fixtureRoot)
}
$denied = ($null -ne $deny.Payload -and [string]$deny.Payload.decision -eq 'deny')
if (-not $denied) {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("expected deny; exit={0} output={1}" -f $deny.ExitCode, $deny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath'

$secret = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    toolCall = @{
        name = 'write_to_file'
        args = @{
            TargetFile  = (Join-Path $fixtureRoot 'src\ok.cs')
            CodeContent = 'const string key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";'
        }
    }
    workspacePaths = @($fixtureRoot)
}
$secretDenied = ($null -ne $secret.Payload -and [string]$secret.Payload.decision -eq 'deny')
if (-not $secretDenied) {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("expected secret deny; exit={0} output={1}" -f $secret.ExitCode, $secret.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretPatternDetected'

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing hooks.json'
}
$hooksText = Get-Content -LiteralPath $hooksJsonPath -Raw -Encoding UTF8
if ($hooksText -notmatch '(?i)PreToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json missing PreToolUse'
}
if ($hooksText -notmatch 'write_to_file\|replace_file_content\|multi_replace_file_content\|run_command') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json missing Antigravity tool matcher'
}
if ($hooksText -notmatch 'guard-pre-tool\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json must wire guard-pre-tool.ps1'
}
Write-Pass -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse'

Write-Host 'Assert-AntigravityPathSecretsGuard: ALL PASS'
exit 0
