#Requires -Version 5.1
# Tests:
#   Should_Pass_When_PluginGuardPresent
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_AgentsCapabilityTrue
#
# Frente 2.8: OpenCode tool.execute.before path + secrets + agents publish.
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

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-OpenCodePathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$pluginPath = Join-Path $repoRoot 'adapters\opencode\assets\plugins\agent-dev-toolkit-marker.js'
$opencodeAdapter = Join-Path $repoRoot 'adapters\opencode\OpenCodeAdapter.ps1'
$publishAgents = Join-Path $repoRoot 'adapters\opencode\Publish-OpenCodeAgents.ps1'
$registryPath = Join-Path $repoRoot 'adapters\registry.json'

if (-not (Test-Path -LiteralPath $pluginPath)) {
    Write-Fail -TestName 'Should_Pass_When_PluginGuardPresent' -Reason 'missing agent-dev-toolkit-marker.js'
}
$pluginText = Get-Content -LiteralPath $pluginPath -Raw -Encoding UTF8
if ($pluginText -notmatch 'tool\.execute\.before') {
    Write-Fail -TestName 'Should_Pass_When_PluginGuardPresent' -Reason 'plugin missing tool.execute.before'
}
if ($pluginText -notmatch 'evaluatePathSecretsGuard') {
    Write-Fail -TestName 'Should_Pass_When_PluginGuardPresent' -Reason 'plugin missing evaluatePathSecretsGuard export'
}
if ($pluginText -notmatch 'throw new Error') {
    Write-Fail -TestName 'Should_Pass_When_PluginGuardPresent' -Reason 'plugin must throw to deny'
}
Write-Pass -TestName 'Should_Pass_When_PluginGuardPresent'

$nodeCmd = Get-Command -Name node -ErrorAction SilentlyContinue
if ($null -eq $nodeCmd) {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason 'node is required to evaluate OpenCode plugin guard helpers'
}

$denyEval = @'
import { pathToFileURL } from 'url';
const m = await import(pathToFileURL(process.argv[1]).href);
const v = m.evaluatePathSecretsGuard('write', { path: 'PRD/blocked.md', content: '# x' }, process.cwd());
if (v.decision !== 'deny') { console.error(JSON.stringify(v)); process.exit(1); }
console.log('deny-ok');
'@
$denyOut = & node --input-type=module -e $denyEval $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $denyOut -notmatch 'deny-ok') {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("expected deny; output={0}" -f $denyOut.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath'

$secretEval = @'
import { pathToFileURL } from 'url';
const m = await import(pathToFileURL(process.argv[1]).href);
const v = m.evaluatePathSecretsGuard('write', { path: 'src/ok.ts', content: 'const k = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";' }, process.cwd());
if (v.decision !== 'deny') { console.error(JSON.stringify(v)); process.exit(1); }
console.log('secret-ok');
'@
$secretOut = & node --input-type=module -e $secretEval $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $secretOut -notmatch 'secret-ok') {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("expected secret deny; output={0}" -f $secretOut.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretPatternDetected'

$absEval = @'
import { pathToFileURL } from 'url';
import path from 'path';
import os from 'os';
const m = await import(pathToFileURL(process.argv[1]).href);
const outside = path.join(os.tmpdir(), 'agent-dev-toolkit-guard-abs-outside.cs');
const v = m.evaluatePathSecretsGuard('write', { path: outside, content: 'namespace X;' }, process.cwd());
if (v.decision !== 'deny') { console.error(JSON.stringify(v)); process.exit(1); }
const shell = m.evaluatePathSecretsGuard('bash', { command: `Set-Content -Path "${outside}" -Value x` }, process.cwd());
if (shell.decision !== 'deny') { console.error(JSON.stringify(shell)); process.exit(1); }
const missing = m.evaluatePathSecretsGuard('write', { content: 'x' }, process.cwd());
if (missing.decision !== 'deny') { console.error(JSON.stringify(missing)); process.exit(1); }
console.log('abs-ok');
'@
$absOut = & node --input-type=module -e $absEval $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $absOut -notmatch 'abs-ok') {
    Write-Fail -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace' -Reason ("expected abs/named-path/missing deny; output={0}" -f $absOut.Trim())
}
Write-Pass -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace'

if ($pluginText -notmatch 'pathsFromShell' -and $pluginText -notmatch 'SHELL_PATH') {
    Write-Fail -TestName 'Should_Pass_When_PluginGuardPresent' -Reason 'plugin must extract shell paths beyond forbidden literals'
}

. $opencodeAdapter
$caps = Get-Capabilities
if (-not $caps.Capabilities.agents) {
    Write-Fail -TestName 'Should_Pass_When_AgentsCapabilityTrue' -Reason 'Get-Capabilities agents must be true'
}
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$entry = @($registry.agents | Where-Object { $_.id -eq 'opencode' })[0]
if (-not $entry.capabilities.agents) {
    Write-Fail -TestName 'Should_Pass_When_AgentsCapabilityTrue' -Reason 'registry.json opencode.agents must be true'
}
if (-not (Test-Path -LiteralPath $publishAgents)) {
    Write-Fail -TestName 'Should_Pass_When_AgentsCapabilityTrue' -Reason 'missing Publish-OpenCodeAgents.ps1'
}
Write-Pass -TestName 'Should_Pass_When_AgentsCapabilityTrue'

Write-Host 'Assert-OpenCodePathSecretsGuard: ALL PASS'
exit 0
