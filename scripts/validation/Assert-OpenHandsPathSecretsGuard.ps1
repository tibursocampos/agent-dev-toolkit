#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_HooksJsonWiresPreToolUse
#
# Frente 2.5: OpenHands pre_tool_use path + secrets guard.
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
        Write-Fail -TestName 'Assert-OpenHandsPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
. $guardHarnessScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksAssets = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'openhands') 'assets') 'hooks'
$guardPs1 = Join-Path $hooksAssets 'guard_pre_tool.ps1'
$guardSh = Join-Path $hooksAssets 'guard_pre_tool.sh'
$publishHooks = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'openhands') 'Publish-OpenHandsHooks.ps1'
$guardCommon = Join-Path (Join-Path $repoRoot 'adapters') '_shared\GuardCommon.ps1'
. $guardCommon

$guardCommonText = Get-Content -LiteralPath $guardCommon -Raw -Encoding UTF8
if ($guardCommonText -match '(?m)Get-Command\s+-Name\s+realpath|realpath\.Source') {
    Write-Fail -TestName 'Should_Not_ResolvePosixPath_From_Path' -Reason 'GuardCommon must not resolve realpath through PATH'
}
Write-Pass -TestName 'Should_Not_ResolvePosixPath_From_Path'

if (-not (Test-ToolkitIsWindows)) {
    $pathAttackRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("adt-realpath-path-" + $PID)
    $pathAttackRealpath = Join-Path $pathAttackRoot 'realpath'
    $originalPath = $env:PATH
    try {
        $null = New-Item -ItemType Directory -Path $pathAttackRoot -Force
        [System.IO.File]::WriteAllText($pathAttackRealpath, "#!/bin/sh`nprintf '/attacker-controlled-realpath'`n")
        $chmodPath = @('/bin/chmod', '/usr/bin/chmod') | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace([string]$chmodPath)) {
            Write-Fail -TestName 'Should_Ignore_AttackerControlledPosixPath' -Reason 'trusted chmod was unavailable'
        }
        & $chmodPath +x $pathAttackRealpath
        $env:PATH = $pathAttackRoot
        $resolvedUnderAttack = Resolve-ToolkitExistingPath -Path $repoRoot
        if ([string]$resolvedUnderAttack -eq '/attacker-controlled-realpath') {
            Write-Fail -TestName 'Should_Ignore_AttackerControlledPosixPath' -Reason 'resolver executed realpath selected from PATH'
        }
    }
    finally {
        $env:PATH = $originalPath
        Remove-Item -LiteralPath $pathAttackRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Pass -TestName 'Should_Ignore_AttackerControlledPosixPath'
}

if (-not (Test-Path -LiteralPath $guardPs1) -or -not (Test-Path -LiteralPath $guardSh) -or -not (Test-Path -LiteralPath $guardCommon)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'missing guard_pre_tool.ps1 or guard_pre_tool.sh'
}
Write-Pass -TestName 'Should_Pass_When_GuardHookPresent'

$fixtureRoot = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') 'validation') 'fixtures') 'openhands-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$deny = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'PRD\blocked.md')
        content = '# blocked'
    }
    cwd        = $fixtureRoot
}
$denied = ($deny.ExitCode -eq 2) -or ($null -ne $deny.Payload -and [string]$deny.Payload.decision -eq 'deny')
if (-not $denied) {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("expected deny; exit={0} output={1}" -f $deny.ExitCode, $deny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath'

$allowed = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'src\allowed.cs')
        content = 'namespace Fixture;'
    }
    cwd = $fixtureRoot
}
$allowedOk = ($allowed.ExitCode -eq 0) -and ($null -ne $allowed.Payload) -and [string]$allowed.Payload.decision -eq 'allow'
if (-not $allowedOk) {
    Write-Fail -TestName 'Should_Allow_When_ValidWorkspacePath' -Reason ("expected allow; exit={0} output={1}" -f $allowed.ExitCode, $allowed.Output.Trim())
}
Write-Pass -TestName 'Should_Allow_When_ValidWorkspacePath'

$secret = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'src\ok.cs')
        content = 'const string key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";'
    }
    cwd = $fixtureRoot
}
$secretDenied = ($secret.ExitCode -eq 2) -or ($null -ne $secret.Payload -and [string]$secret.Payload.decision -eq 'deny')
if (-not $secretDenied) {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("expected secret deny; exit={0} output={1}" -f $secret.ExitCode, $secret.Output.Trim())
}

$terminal = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'terminal'
    tool_input = @{ command = 'echo x > PRD/legacy.md' }
    cwd        = $fixtureRoot
}
$terminalDenied = ($terminal.ExitCode -eq 2) -or ($null -ne $terminal.Payload -and [string]$terminal.Payload.decision -eq 'deny')
if (-not $terminalDenied) {
    Write-Fail -TestName 'Should_Deny_When_TerminalForbiddenPath' -Reason ("expected terminal deny; exit={0} output={1}" -f $terminal.ExitCode, $terminal.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretPatternDetected'

$absOutside = Join-Path ([System.IO.Path]::GetTempPath().TrimEnd('\', '/')) 'agent-dev-toolkit-guard-abs-outside.cs'
$abs = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write'
    tool_input = @{
        path    = $absOutside
        content = 'namespace X;'
    }
    cwd        = $repoRoot
}
$absDenied = ($abs.ExitCode -eq 2) -or ($null -ne $abs.Payload -and [string]$abs.Payload.decision -eq 'deny')
if (-not $absDenied) {
    Write-Fail -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace' -Reason ("absolute .cs outside workspace must deny; exit={0} output={1}" -f $abs.ExitCode, $abs.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace'

$shText = Get-Content -LiteralPath $guardSh -Raw -Encoding UTF8
if ($shText -match 'fail-open') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'guard_pre_tool.sh must not fail-open when pwsh missing'
}
if ($shText -notmatch 'fail-closed') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'guard_pre_tool.sh must fail-closed when pwsh missing'
}

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

. (Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'openhands') 'OpenHandsPathConstants.ps1')
. $publishHooks
$hooksObj = New-OpenHandsMinimalHooksObject
$hooksText = ($hooksObj | ConvertTo-Json -Depth 8)
if ($hooksText -notmatch 'pre_tool_use') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing pre_tool_use'
}
if ($hooksText -notmatch 'guard_pre_tool\.sh') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing guard_pre_tool.sh command'
}
if ($hooksText -notmatch 'write\|terminal\|file_editor') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing write|terminal|file_editor matcher'
}
if ($script:OpenHandsAdapterConstant.SubagentsNone -ne 'none') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'OpenHands subagents must remain none'
}
Write-Pass -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse'

Write-Host 'Assert-OpenHandsPathSecretsGuard: ALL PASS'
exit 0
