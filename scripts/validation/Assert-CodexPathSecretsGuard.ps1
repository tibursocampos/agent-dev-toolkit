#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_HooksJsonWiresPreToolUse
#   Should_Pass_When_AgentsEmitToml
#
# Frente 2.3: Codex PreToolUse path + secrets + agents .toml.
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
        Write-Fail -TestName 'Assert-CodexPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
. $guardHarnessScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksAssets = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'codex') 'assets') 'hooks'
$guardScript = Join-Path $hooksAssets 'guard-pre-tool.ps1'
$commonScript = Join-Path $hooksAssets '_hook-common.ps1'
$publishHooks = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'codex') 'Publish-CodexHooks.ps1'
$publishAgents = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'codex') 'Publish-CodexAgents.ps1'
$codexAdapter = Join-Path (Join-Path (Join-Path $repoRoot 'adapters') 'codex') 'CodexAdapter.ps1'

if (-not (Test-Path -LiteralPath $guardScript) -or -not (Test-Path -LiteralPath $commonScript)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'missing Codex guard-pre-tool or _hook-common under assets/hooks'
}
. $commonScript
foreach ($cmdName in @('Get-ToolkitPathSecretsGuardVerdict', 'Write-CodexPreToolJson')) {
    if (-not (Get-Command -Name $cmdName -ErrorAction SilentlyContinue)) {
        Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason ("missing function {0}" -f $cmdName)
    }
}
Write-Pass -TestName 'Should_Pass_When_GuardHookPresent'

$fixtureRoot = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') 'validation') 'fixtures') 'codex-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$reparseTarget = Join-Path ([System.IO.Path]::GetTempPath()) 'agent-dev-toolkit-codex-reparse-target'
$reparseLink = Join-Path $fixtureRoot 'src\linked'
$null = New-Item -ItemType Directory -Path $reparseTarget -Force
$null = New-Item -ItemType Junction -Path $reparseLink -Target $reparseTarget
$reparsePayload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path $reparseLink 'escape.cs'); content = 'class X {}' }; cwd = $fixtureRoot }

$cases = @(
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ForbiddenSddPath'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'apply_patch'; tool_input = @{ command = "*** Add File: PRD/blocked.md`n+# blocked" }; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'expected deny for forbidden SDD path' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_SecretPatternDetected'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Bash'; tool_input = @{ command = 'echo ghp_TESTNOTREAL_aaaaabbbbbcccccddddd > src/ok.txt' }; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'expected deny for secret pattern' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_HookIdentityMissing'; Payload = @{ tool_name = 'Write'; tool_input = @{ path = (Join-Path $fixtureRoot 'src\missing-identity.cs'); content = 'class X {}' }; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'write without PreToolUse identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ShellHookIdentityMissing'; Payload = @{ tool_name = 'Bash'; tool_input = @{ command = 'Set-Content -Path src\missing-shell-identity.cs -Value x' }; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'shell without PreToolUse identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_DescendantReparseEscapesWorkspace'; Payload = $reparsePayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'write through an escaping junction must deny' }
)
try {
    Invoke-PathSecretsGuardHarness -AdapterName 'Codex' -HookScriptPath $guardScript -Cases $cases -GetDecision {
        param($Payload)
        if ($null -eq $Payload -or -not $Payload.hookSpecificOutput) { return $null }
        return [string]$Payload.hookSpecificOutput.permissionDecision
    }
}
finally {
    Remove-Item -LiteralPath $reparseLink -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $reparseTarget -Force -Recurse -ErrorAction SilentlyContinue
}

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

. $codexAdapter
$hooksObj = New-CodexPreToolUseHooksObject
$hooksJsonText = ($hooksObj | ConvertTo-Json -Depth 8)
if ($hooksJsonText -notmatch 'PreToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing PreToolUse'
}
if ($hooksJsonText -notmatch 'guard-pre-tool\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing guard-pre-tool.ps1 command'
}
if ($hooksJsonText -notmatch 'apply_patch\|Edit\|Write') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing apply_patch|Edit|Write matcher'
}
if ($hooksJsonText -notmatch '"Bash"') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing Bash matcher'
}
Write-Pass -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse'

$sampleMd = @"
---
name: sample-agent
description: Sample for toml emit test.
model: inherit
---

# sample-agent

Do useful work.
"@
$toml = Convert-CodexAgentMarkdownToToml -MarkdownText $sampleMd -SourcePath 'sample.md'
if ($toml -notmatch '(?m)^name = ') {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml missing name'
}
if ($toml -notmatch '(?m)^description = ') {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml missing description'
}
if ($toml -notmatch 'developer_instructions = ') {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml missing developer_instructions'
}
if ($toml -notmatch 'Do useful work') {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml body not mapped to developer_instructions'
}
if ($toml -notmatch [regex]::Escape('# toolkit.spawn.model = inherit')) {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml missing inherit honesty comment'
}
if ($toml -notmatch [regex]::Escape('# toolkit.spawn.developer_threads = 2')) {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml missing developer_threads honesty'
}
if ($toml -notmatch [regex]::Escape('# toolkit.spawn.orchestrate_threads = 4')) {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml missing orchestrate_threads honesty'
}
if ($toml -match '(?m)^\s*model\s*=') {
    Write-Fail -TestName 'Should_Pass_When_AgentsEmitToml' -Reason 'toml must omit model key (parent inherit)'
}
Write-Pass -TestName 'Should_Pass_When_AgentsEmitToml'

$divergentMd = @"
---
name: bad-agent
description: Must reject divergent model pin.
model: gpt-5.6-luna-medium
---

# bad-agent
"@
$divergentThrew = $false
try {
    [void](Convert-CodexAgentMarkdownToToml -MarkdownText $divergentMd -SourcePath 'bad.md')
}
catch {
    $divergentThrew = $true
}
if (-not $divergentThrew) {
    Write-Fail -TestName 'Should_Fail_When_DivergentModelPin' -Reason 'expected throw for luna pin'
}
Write-Pass -TestName 'Should_Fail_When_DivergentModelPin'

Write-Host 'Assert-CodexPathSecretsGuard: ALL PASS'
exit 0
