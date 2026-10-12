#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Allow_When_ReadOnlyToolIsCaptured
#   Should_Allow_When_MutatingToolIsWithinWorkspace
#   Should_Allow_When_HostOwnsForbiddenSddPath
#   Should_Allow_AndRedact_When_SecretPatternDetected
#   Should_Allow_When_HostOwnsUnknownToolAuthorization
#   Should_Deny_When_MalformedOrEmptyInput
#   Should_Deny_When_InvalidHookIdentity
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
$reparseStatus = 'SKIPPED'

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
    Write-ValidatorResult -Status 'FAIL' -ExitCode 1 -PhysicalStatus $reparseStatus
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

$mixedSecretFindings = @(Get-ToolkitSecretFindings -Content 'example documentation: api_key=realfixturevalue123')
if ($mixedSecretFindings.Count -eq 0) {
    Write-Fail -TestName 'Should_Deny_When_SecretSharesLineWithPlaceholderContext' -Reason 'placeholder context must not suppress a real secret candidate on the same line'
}
Write-Pass -TestName 'Should_Deny_When_SecretSharesLineWithPlaceholderContext'

$placeholderFindings = @(Get-ToolkitSecretFindings -Content 'example documentation: api_key=YOUR_API_KEY')
if ($placeholderFindings.Count -ne 0) {
    Write-Fail -TestName 'Should_Ignore_When_SecretCandidateIsExplicitPlaceholder' -Reason 'an exact placeholder candidate should remain exempt without suppressing other line content'
}
Write-Pass -TestName 'Should_Ignore_When_SecretCandidateIsExplicitPlaceholder'

$placeholderThenRealFindings = @(Get-ToolkitSecretFindings -Content 'api_key=YOUR_API_KEY api_key=realfixturevalue123')
if ($placeholderThenRealFindings.Count -eq 0) {
    Write-Fail -TestName 'Should_Deny_When_RealSecretFollowsPlaceholderOnSameLine' -Reason 'a later real candidate on the same line must not be suppressed'
}
Write-Pass -TestName 'Should_Deny_When_RealSecretFollowsPlaceholderOnSameLine'

$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-dev-toolkit-codex-path-guard-{0}" -f ([guid]::NewGuid().ToString('N')))
$reparseTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-dev-toolkit-codex-reparse-target-{0}" -f ([guid]::NewGuid().ToString('N')))
$reparseLink = Join-Path (Join-Path $fixtureRoot 'src') 'linked'
$reparseAvailable = $false
$reparsePayload = $null
$setupStage = 'workspace'

try {
    $null = New-Item -ItemType Directory -Path $fixtureRoot -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'src') -Force
    $setupStage = 'reparse'
    $null = New-Item -ItemType Directory -Path $reparseTarget -Force
    $reparseItemType = if ($env:OS -eq 'Windows_NT') { 'Junction' } else { 'SymbolicLink' }
    $null = New-Item -ItemType $reparseItemType -Path $reparseLink -Target $reparseTarget
    $reparseAvailable = $true
    $reparsePayload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path $reparseLink 'escape.cs'); content = 'class X {}' }; cwd = $fixtureRoot }
}
catch {
    $setupText = $_.Exception.ToString()
    if ($setupStage -eq 'reparse' -and $setupText -match '(?i)access is denied|eacces|eperm|operation not permitted|privilege') {
        Write-Host 'Should_Deny_When_DescendantReparseEscapesWorkspace: SKIPPED - Windows reparse creation is unavailable under current ACL/privilege; no bypass attempted.'
    }
    else {
        Remove-Item -LiteralPath $reparseLink -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $reparseTarget -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
        Write-Fail -TestName 'Should_Deny_When_DescendantReparseEscapesWorkspace' -Reason ("reparse fixture setup failed unexpectedly: {0}" -f $_.Exception.Message)
    }
}

$cases = @(
    [PSCustomObject]@{ TestName = 'Should_Allow_When_ReadOnlyToolIsCaptured'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Read'; tool_input = @{ path = (Join-Path $fixtureRoot 'srcknown.cs') }; cwd = $fixtureRoot }; ExpectedDecision = 'allow'; Acceptance = 'Decision'; FailureReason = 'supported read-only tool must be allowed after valid catch-all capture' }
    [PSCustomObject]@{ TestName = 'Should_Allow_When_MutatingToolIsWithinWorkspace'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path $fixtureRoot 'srcknown.cs'); content = 'class X {}' }; cwd = $fixtureRoot }; ExpectedDecision = 'allow'; Acceptance = 'Decision'; FailureReason = 'supported mutating tool within workspace must be allowed' }
    [PSCustomObject]@{ TestName = 'Should_Allow_When_HostOwnsForbiddenSddPath'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'apply_patch'; tool_input = @{ command = "*** Add File: PRD/blocked.md`n+# blocked" }; cwd = $fixtureRoot }; ExpectedDecision = 'allow'; Acceptance = 'Decision'; FailureReason = 'Toolkit hook must not veto the host authorization decision for a path' }
    [PSCustomObject]@{ TestName = 'Should_Allow_AndRedact_When_SecretPatternDetected'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Bash'; tool_input = @{ command = 'echo ghp_TESTNOTREAL_aaaaabbbbbcccccddddd > src/ok.txt' }; cwd = $fixtureRoot }; ExpectedDecision = 'allow'; Acceptance = 'Decision'; FailureReason = 'host-owned authorization must not be vetoed'; MustNotContain = 'ghp_TESTNOTREAL_aaaaabbbbbcccccddddd' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_HookIdentityMissing'; Payload = @{ tool_name = 'Write'; tool_input = @{ path = (Join-Path $fixtureRoot 'src\missing-identity.cs'); content = 'class X {}' }; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'write without PreToolUse identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ShellHookIdentityMissing'; Payload = @{ tool_name = 'Bash'; tool_input = @{ command = 'Set-Content -Path src\missing-shell-identity.cs -Value x' }; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'shell without PreToolUse identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Allow_When_HostOwnsUnknownToolAuthorization'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'FutureCodexTool'; tool_input = @{}; cwd = $fixtureRoot }; ExpectedDecision = 'allow'; Acceptance = 'Decision'; FailureReason = 'Toolkit hook must not veto host authorization for unknown tools' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_InvalidHookIdentity'; Payload = @{ hook_event_name = 'PostToolUse'; tool_name = 'Read'; tool_input = @{}; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'read-only tool with invalid event identity must deny' }
)

if ($reparseAvailable) {
    $cases += [PSCustomObject]@{ TestName = 'Should_Allow_When_HostOwnsEscapingPathAuthorization'; Payload = $reparsePayload; ExpectedDecision = 'allow'; Acceptance = 'Decision'; FailureReason = 'Toolkit hook must not veto the host authorization decision for a path' }
}

try {
    Invoke-PathSecretsGuardHarness -AdapterName 'Codex' -HookScriptPath $guardScript -Cases $cases -GetDecision {
        param($Payload)
        if ($null -eq $Payload -or -not $Payload.hookSpecificOutput) { return $null }
        return [string]$Payload.hookSpecificOutput.permissionDecision
    }
    if ($reparseAvailable) {
        $reparseStatus = 'PASS'
    }
}
finally {
    Remove-Item -LiteralPath $reparseLink -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $reparseTarget -Force -Recurse -ErrorAction SilentlyContinue
}

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

function Assert-CodexRawInputDenied {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [AllowEmptyString()][string] $RawInput,
        [Parameter(Mandatory = $true)][string] $FailureReason
    )

    $hostCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($null -eq $hostCommand) {
        $hostCommand = Get-Command powershell -ErrorAction SilentlyContinue
    }
    if ($null -eq $hostCommand) {
        Write-Fail -TestName $TestName -Reason 'PowerShell host is unavailable for raw-input coverage'
    }

    $output = $RawInput | & $hostCommand.Source -NoProfile -File $guardScript 2>&1 | Out-String
    $parsed = $null
    try { $parsed = $output.Trim() | ConvertFrom-Json -ErrorAction Stop } catch { }
    $decision = if ($null -ne $parsed -and $null -ne $parsed.hookSpecificOutput) { [string]$parsed.hookSpecificOutput.permissionDecision } else { '' }
    if ($decision -ne 'deny') {
        Write-Fail -TestName $TestName -Reason ("{0}; output={1}" -f $FailureReason, $output.Trim())
    }
    Write-Pass -TestName $TestName
}

Assert-CodexRawInputDenied -TestName 'Should_Deny_When_MalformedOrEmptyInput' -RawInput '{not-json' -FailureReason 'malformed input must be denied'
Assert-CodexRawInputDenied -TestName 'Should_Deny_When_EmptyInput' -RawInput '' -FailureReason 'empty input must be denied'

. $codexAdapter
$hooksObj = New-CodexPreToolUseHooksObject
$preToolUseHooks = @($hooksObj.hooks.PreToolUse)
if ($preToolUseHooks.Count -ne 1) {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'expected one catch-all PreToolUse matcher group'
}
if ($preToolUseHooks[0].matcher -ne '.*') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'PreToolUse matcher must catch every Codex tool event'
}
$hooksJsonText = ($hooksObj | ConvertTo-Json -Depth 8)
if ($hooksJsonText -notmatch 'PreToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing PreToolUse'
}
if ($hooksJsonText -notmatch 'guard-pre-tool\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing guard-pre-tool.ps1 command'
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

$overallStatus = if ($reparseStatus -eq 'SKIPPED') { 'SKIPPED' } else { 'PASS' }
Write-Host ("Assert-CodexPathSecretsGuard: {0} (physical reparse case)" -f $reparseStatus)
Write-ValidatorResult -Status $overallStatus -ExitCode 0 -PhysicalStatus $reparseStatus
exit 0
