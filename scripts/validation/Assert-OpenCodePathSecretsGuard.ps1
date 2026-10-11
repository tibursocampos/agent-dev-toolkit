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
$physicalStatus = 'SKIPPED'

function Write-ValidatorResult {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('PASS', 'SKIPPED', 'FAIL')][string] $Status,
        [Parameter(Mandatory = $true)][int] $ExitCode,
        [Parameter(Mandatory = $true)][string] $PhysicalStatus
    )
    $result = [ordered]@{
        Status = $Status
        ExitCode = $ExitCode
        PhysicalStatus = $PhysicalStatus
    }
    Write-Host ('VALIDATOR_RESULT ' + ($result | ConvertTo-Json -Compress))
}

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
    Write-ValidatorResult -Status 'FAIL' -ExitCode 1 -PhysicalStatus $physicalStatus
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

$pluginPath = Join-Path (Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'opencode') 'assets') 'plugins') 'agent-dev-toolkit-marker.js'
$opencodeAdapter = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'opencode') 'OpenCodeAdapter.ps1'
$publishAgents = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'opencode') 'Publish-OpenCodeAgents.ps1'
$registryPath = Join-Path (Join-Path $repoRoot 'adapters') 'registry.json'

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

$mixedSecretEval = @'
import { pathToFileURL } from 'url';
const m = await import(pathToFileURL(process.argv[1]).href);
const mixed = m.findSecretFindings('example documentation: api_key=realfixturevalue123');
if (!Array.isArray(mixed) || mixed.length === 0) { console.error(JSON.stringify(mixed)); process.exit(1); }
const placeholder = m.findSecretFindings('example documentation: api_key=YOUR_API_KEY');
if (placeholder.length !== 0) { console.error(JSON.stringify(placeholder)); process.exit(1); }
const placeholderThenReal = m.findSecretFindings('api_key=YOUR_API_KEY api_key=realfixturevalue123');
if (!Array.isArray(placeholderThenReal) || placeholderThenReal.length === 0) { console.error(JSON.stringify(placeholderThenReal)); process.exit(1); }
console.log('mixed-secret-ok');
'@
$mixedSecretOut = & node --input-type=module -e $mixedSecretEval $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $mixedSecretOut -notmatch 'mixed-secret-ok') {
    Write-Fail -TestName 'Should_Deny_When_SecretSharesLineWithPlaceholderContext' -Reason ("placeholder context must not suppress a real secret candidate; output={0}" -f $mixedSecretOut.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretSharesLineWithPlaceholderContext'

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

$shellClassificationEval = @'
import { pathToFileURL } from 'url';
const m = await import(pathToFileURL(process.argv[1]).href);
const mutation = m.evaluatePathSecretsGuard('bash', { command: `python -c "open('src/out.txt','w').write('x')"` }, process.cwd());
if (mutation.decision !== 'deny' || !mutation.reason.includes('write-capable')) { console.error(JSON.stringify(mutation)); process.exit(1); }
const unknown = m.evaluatePathSecretsGuard('bash', { command: 'future-shell --write src/out.txt' }, process.cwd());
if (unknown.decision !== 'deny' || !unknown.reason.includes('effect')) { console.error(JSON.stringify(unknown)); process.exit(1); }
const readOnly = m.evaluatePathSecretsGuard('bash', { command: 'Get-Date' }, process.cwd());
if (readOnly.decision !== 'allow') { console.error(JSON.stringify(readOnly)); process.exit(1); }
console.log('shell-classification-ok');
'@
$shellClassificationOut = & node --input-type=module -e $shellClassificationEval $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $shellClassificationOut -notmatch 'shell-classification-ok') {
    Write-Fail -TestName 'Should_Deny_When_ShellEffectIsUnclassified' -Reason ("write-capable and unknown shell forms must fail closed; output={0}" -f $shellClassificationOut.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ShellEffectIsUnclassified'

$physicalEval = @'
import { pathToFileURL } from 'url';
import fs from 'fs';
import os from 'os';
import path from 'path';
const m = await import(pathToFileURL(process.argv[1]).href);
let workspace = null;
let outside = null;
let link = null;
let physicalFixtureCreated = false;
try {
  workspace = fs.mkdtempSync(path.join(os.tmpdir(), 'opencode-ct11-workspace-'));
  outside = fs.mkdtempSync(path.join(os.tmpdir(), 'opencode-ct11-outside-'));
  link = path.join(workspace, 'linked');
  fs.symlinkSync(outside, link, 'junction');
  physicalFixtureCreated = true;
  const escapedMissing = path.join(link, 'missing.ts');
  const escaped = m.evaluatePathSecretsGuard('write', { path: escapedMissing, content: 'const safe = true;' }, workspace);
  if (escaped.decision !== 'deny') { console.error(JSON.stringify(escaped)); process.exit(1); }
  const allowedMissing = m.evaluatePathSecretsGuard('write', { path: 'src/missing.ts', content: 'const safe = true;' }, workspace);
  if (allowedMissing.decision !== 'allow') { console.error(JSON.stringify(allowedMissing)); process.exit(1); }
  console.log('physical-ok');
} catch (error) {
  const code = error && error.code ? String(error.code) : '';
  const message = error && error.message ? String(error.message) : String(error);
  if (!physicalFixtureCreated && (code === 'EACCES' || code === 'EPERM' || /access is denied|not have sufficient privilege|operation not permitted/i.test(message))) {
    console.log('physical-skip');
  } else {
    console.error(message);
    process.exitCode = 1;
  }
} finally {
  if (workspace) { fs.rmSync(workspace, { recursive: true, force: true }); }
  if (outside) { fs.rmSync(outside, { recursive: true, force: true }); }
}
'@
$physicalOut = & node --input-type=module -e $physicalEval $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -eq 0 -and $physicalOut -match 'physical-ok') {
    $physicalStatus = 'PASS'
    Write-Pass -TestName 'Should_Deny_When_SymlinkEscapes_With_MissingFinalDestination'
} elseif ($LASTEXITCODE -eq 0 -and $physicalOut -match 'physical-skip') {
    Write-Host 'Should_Deny_When_SymlinkEscapes_With_MissingFinalDestination: SKIPPED - Windows symlink/junction creation is unavailable under current ACL/privilege; no bypass attempted.'
} else {
    Write-Fail -TestName 'Should_Deny_When_SymlinkEscapes_With_MissingFinalDestination' -Reason ("expected physical containment; output={0}" -f $physicalOut.Trim())
}

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

if ($physicalStatus -eq 'PASS') { $overallStatus = 'PASS' } else { $overallStatus = 'SKIPPED' }
Write-Host ("Assert-OpenCodePathSecretsGuard: {0} (physical reparse case)" -f $physicalStatus)
Write-ValidatorResult -Status $overallStatus -ExitCode 0 -PhysicalStatus $physicalStatus
exit 0
