#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardPluginAndHooksPresent
#   Should_Deny_When_ForbiddenSddPath_ShellHook
#   Should_Deny_When_SecretPattern_PluginEvaluate  (PS1 agent-hook path; not Python plugin)
#   Should_Pass_When_ConfigYamlKeysDocumented
#
# Frente 2.10: Hermes plugin + agent-hooks path/secrets guard.
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
        Write-Fail -TestName 'Assert-HermesPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
. $guardHarnessScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$pluginRoot = Join-Path (Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'hermes') 'assets') 'plugins') 'agent-dev-toolkit-guard'
$pluginYaml = Join-Path $pluginRoot 'plugin.yaml'
$pluginInit = Join-Path $pluginRoot '__init__.py'
$agentHooksRoot = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'hermes') 'assets') 'agent-hooks'
$guardPs1 = Join-Path $agentHooksRoot 'guard-pre-tool.ps1'
$guardSh = Join-Path $agentHooksRoot 'guard-pre-tool.sh'
$publishHooks = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'hermes') 'Publish-HermesHooks.ps1'
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

foreach ($path in @($pluginYaml, $pluginInit, $guardPs1, $guardSh, $publishHooks, $guardCommon)) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Fail -TestName 'Should_Pass_When_GuardPluginAndHooksPresent' -Reason ("missing {0}" -f $path)
    }
}
$pluginYamlText = Get-Content -LiteralPath $pluginYaml -Raw -Encoding UTF8
if ($pluginYamlText -notmatch 'agent-dev-toolkit-guard') {
    Write-Fail -TestName 'Should_Pass_When_GuardPluginAndHooksPresent' -Reason 'plugin.yaml missing name agent-dev-toolkit-guard'
}
$initText = Get-Content -LiteralPath $pluginInit -Raw -Encoding UTF8
if ($initText -notmatch 'pre_tool_call' -or $initText -notmatch 'action.+block') {
    Write-Fail -TestName 'Should_Pass_When_GuardPluginAndHooksPresent' -Reason '__init__.py must register pre_tool_call with action block'
}
Write-Pass -TestName 'Should_Pass_When_GuardPluginAndHooksPresent'

$fixtureRoot = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') 'validation') 'fixtures') 'hermes-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$deny = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write_file'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'PRD\blocked.md')
        content = '# blocked'
    }
    cwd        = $fixtureRoot
}
$denied = ($null -ne $deny.Payload -and [string]$deny.Payload.action -eq 'block')
if (-not $denied) {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath_ShellHook' -Reason ("expected block; exit={0} output={1}" -f $deny.ExitCode, $deny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath_ShellHook'

$allowed = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write_file'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'src\allowed.cs')
        content = 'namespace Fixture;'
    }
    cwd        = $fixtureRoot
}
$allowedAction = ''
if ($null -ne $allowed.Payload -and $allowed.Payload.PSObject.Properties['action']) {
    $allowedAction = [string]$allowed.Payload.action
}
$allowedOk = ($allowed.ExitCode -eq 0) -and ($null -ne $allowed.Payload) -and [string]::IsNullOrWhiteSpace($allowedAction)
if (-not $allowedOk) {
    Write-Fail -TestName 'Should_Allow_When_ValidWorkspacePath' -Reason ("expected allow; exit={0} output={1}" -f $allowed.ExitCode, $allowed.Output.Trim())
}
Write-Pass -TestName 'Should_Allow_When_ValidWorkspacePath'

$secret = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write_file'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'src\ok.cs')
        content = 'const string key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";'
    }
    cwd        = $fixtureRoot
}
$secretDenied = ($null -ne $secret.Payload -and [string]$secret.Payload.action -eq 'block')
if (-not $secretDenied) {
    Write-Fail -TestName 'Should_Deny_When_SecretPattern_PluginEvaluate' -Reason ("expected secret block; exit={0} output={1}" -f $secret.ExitCode, $secret.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretPattern_PluginEvaluate'

$absOutside = Join-Path ([System.IO.Path]::GetTempPath().TrimEnd('\', '/')) 'agent-dev-toolkit-guard-abs-outside.cs'
$abs = Invoke-GuardHook -HookScriptPath $guardPs1 -Payload @{
    tool_name  = 'write_file'
    tool_input = @{
        path    = $absOutside
        content = 'namespace X;'
    }
    cwd        = $repoRoot
}
$absDenied = ($null -ne $abs.Payload -and [string]$abs.Payload.action -eq 'block')
if (-not $absDenied) {
    Write-Fail -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace' -Reason ("absolute .cs outside workspace must block; exit={0} output={1}" -f $abs.ExitCode, $abs.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace'

$shText = Get-Content -LiteralPath $guardSh -Raw -Encoding UTF8
if ($shText -match 'Lightweight fallback' -or ($shText -match 'fail-open')) {
    Write-Fail -TestName 'Should_Pass_When_ConfigYamlKeysDocumented' -Reason 'guard-pre-tool.sh must fail-closed when pwsh absent'
}
if ($shText -notmatch 'fail-closed') {
    Write-Fail -TestName 'Should_Pass_When_ConfigYamlKeysDocumented' -Reason 'guard-pre-tool.sh must document fail-closed'
}
if ($initText -notmatch '_paths_from_shell' -and $initText -notmatch 'paths_from_shell' -and $initText -notmatch 'SHELL_PATH') {
    Write-Fail -TestName 'Should_Pass_When_GuardPluginAndHooksPresent' -Reason '__init__.py must extract shell paths for terminal tools'
}

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

$publishText = Get-Content -LiteralPath $publishHooks -Raw -Encoding UTF8
if ($publishText -notmatch 'plugins\.enabled' -and $publishText -notmatch 'Merge-HermesPluginsEnabledList') {
    Write-Fail -TestName 'Should_Pass_When_ConfigYamlKeysDocumented' -Reason 'Publish-HermesHooks must keyed-merge plugins.enabled'
}
if ($publishText -notmatch 'fail_closed' -or $publishText -notmatch 'pre_tool_call') {
    Write-Fail -TestName 'Should_Pass_When_ConfigYamlKeysDocumented' -Reason 'Publish-HermesHooks must merge hooks.pre_tool_call with fail_closed'
}
if ($publishText -match 'SOUL\.md' -and $publishText -match 'WriteAllText.*SOUL') {
    Write-Fail -TestName 'Should_Pass_When_ConfigYamlKeysDocumented' -Reason 'must not write SOUL.md'
}
Write-Pass -TestName 'Should_Pass_When_ConfigYamlKeysDocumented'

Write-Host 'Assert-HermesPathSecretsGuard: ALL PASS'
exit 0
