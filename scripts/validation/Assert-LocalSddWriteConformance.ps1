#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$registry = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters\registry.json') -Raw | ConvertFrom-Json
$common = Join-Path $repoRoot 'adapters\_shared\GuardCommon.ps1'
$harness = Join-Path $repoRoot 'scripts\_lib\Invoke-PathSecretsGuardHarness.ps1'
. $common
. $harness

foreach ($invalidShellInput in @(
    [pscustomobject]@{},
    [pscustomobject]@{ command = '   ' },
    [pscustomobject]@{ command = @{ nested = 'Set-Content' } }
)) {
    $invalidShell = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Shell' -ToolInput $invalidShellInput -WorkspaceRoot (Get-Location).Path
    if ($invalidShell.Decision -ne 'deny' -or $invalidShell.Reason -ne 'invalid_shell_payload') {
        throw 'PowerShell GuardCommon did not visibly deny a missing, empty, or malformed shell command.'
    }
}
Write-Host 'PowerShell GuardCommon: missing, empty, and malformed shell payloads visibly denied'

$homeRoot = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($homeRoot)) { $homeRoot = $env:HOME }
if ([string]::IsNullOrWhiteSpace($homeRoot)) { throw 'User home could not be resolved for local SDD conformance.' }
$workspaceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-local-sdd-workspace-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $workspaceRoot -Force
$failures = [System.Collections.Generic.List[string]]::new()
$readOnlyToolNames = @{
    cursor = 'Read'; antigravity = 'read_file'; claude = 'Read'; codex = 'Read'; copilot = 'view'
    grok = 'Read'; zcode = 'Read'; hermes = 'read_file'; openhands = 'read'
}

function Get-HookDecision {
    param($Result)
    if ($null -eq $Result.Payload) { return '' }
    if ($Result.Payload.PSObject.Properties['permission']) { return [string]$Result.Payload.permission }
    if ($Result.Payload.PSObject.Properties['decision']) {
        if ([string]$Result.Payload.decision -eq 'block') { return 'deny' }
        return [string]$Result.Payload.decision
    }
    if ($Result.Payload.PSObject.Properties['permissionDecision']) { return [string]$Result.Payload.permissionDecision }
    if ($Result.Payload.PSObject.Properties['action'] -and [string]$Result.Payload.action -eq 'block') { return 'deny' }
    if ($Result.Payload.PSObject.Properties['hookSpecificOutput'] -and $Result.Payload.hookSpecificOutput.PSObject.Properties['permissionDecision']) { return [string]$Result.Payload.hookSpecificOutput.permissionDecision }
    if ($Result.ExitCode -eq 2) { return 'deny' }
    return ''
}

try {
    foreach ($provider in @($registry.agents)) {
        $homeName = switch ([string]$provider.id) {
            'antigravity' { '.gemini' }
            'openhands' { '.agents' }
            default { '.' + [string]$provider.id }
        }
        $installRoot = if ($provider.id -eq 'opencode') { Join-Path $homeRoot '.config\opencode' } else { Join-Path $homeRoot $homeName }
        if ($provider.id -eq 'hermes' -and -not [string]::IsNullOrWhiteSpace($env:HERMES_HOME)) { $installRoot = $env:HERMES_HOME }
        if ($provider.id -eq 'hermes' -and [string]::IsNullOrWhiteSpace($env:HERMES_HOME) -and -not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { $installRoot = Join-Path $env:LOCALAPPDATA 'hermes' }
        $root = Join-Path $installRoot 'sdd'
        $target = Join-Path (Join-Path $root 'sessions') 'probe.json'
        $verdict = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([PSCustomObject]@{ path = $target; content = '{}' }) -WorkspaceRoot $workspaceRoot
        if ($verdict.Decision -ne 'allow') { $failures.Add(('{0}: {1}' -f $provider.id, $verdict.Reason)) }
        else { Write-Host ('{0}: local SDD target outside CWD allowed by shared guard' -f $provider.id) }
    }

    $openCodeRoot = Join-Path $homeRoot '.config\opencode'
    $openCodeConfig = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([PSCustomObject]@{ path = (Join-Path $openCodeRoot 'opencode.json'); content = '{}' }) -WorkspaceRoot $workspaceRoot
    if ($openCodeConfig.Decision -ne 'deny') { $failures.Add(('opencode: sibling provider config was not denied ({0})' -f $openCodeConfig.Reason)) }
    else { Write-Host 'opencode: sibling provider config outside local SDD denied by shared guard' }

    $originalHermesHome = $env:HERMES_HOME
    $testHermesHome = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-hermes-home-' + [guid]::NewGuid().ToString('N'))
    try {
        $env:HERMES_HOME = $testHermesHome
        $hermesSdd = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([PSCustomObject]@{ path = (Join-Path $testHermesHome 'sdd\sessions\probe.json'); content = '{}' }) -WorkspaceRoot $workspaceRoot
        if ($hermesSdd.Decision -ne 'allow') { $failures.Add(('hermes: configured local SDD root was not allowed ({0})' -f $hermesSdd.Reason)) }
        else { Write-Host 'hermes: configured local SDD subtree outside CWD allowed by shared guard' }

        $hermesConfig = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([PSCustomObject]@{ path = (Join-Path $testHermesHome 'config.yaml'); content = 'x: y' }) -WorkspaceRoot $workspaceRoot
        if ($hermesConfig.Decision -ne 'deny') { $failures.Add(('hermes: sibling provider config was not denied ({0})' -f $hermesConfig.Reason)) }
        else { Write-Host 'hermes: sibling provider config outside local SDD denied by shared guard' }
    }
    finally { $env:HERMES_HOME = $originalHermesHome }

    $hookScripts = @{
        cursor = 'adapters/cursor/assets/hooks/guard-pre-tool.ps1'
        antigravity = 'adapters/antigravity/assets/hooks/guard-pre-tool.ps1'
        claude = 'adapters/claude/assets/hooks/guard-pre-tool.ps1'
        codex = 'adapters/codex/assets/hooks/guard-pre-tool.ps1'
        copilot = 'adapters/copilot/assets/hooks/guard-pre-tool.ps1'
        grok = 'adapters/grok/assets/hooks/guard-pre-tool.ps1'
        zcode = 'adapters/zcode/hooks/guard-pre-tool.ps1'
        hermes = 'adapters/hermes/assets/agent-hooks/guard-pre-tool.ps1'
        openhands = 'adapters/openhands/assets/hooks/guard_pre_tool.ps1'
    }
    foreach ($provider in @($registry.agents | Where-Object { $hookScripts.ContainsKey([string]$_.id) })) {
        $hookPath = Join-Path $repoRoot ($hookScripts[[string]$provider.id] -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $result = Invoke-PathSecretsGuardHook -HookScriptPath $hookPath -Payload @{}
        $decision = Get-HookDecision -Result $result
        if ($decision -ne 'deny') { $failures.Add(('{0}: empty hook event was not visibly denied' -f $provider.id)) }
        else { Write-Host ('{0}: empty hook event visibly denied' -f $provider.id) }

        $malformedPayload = switch ([string]$provider.id) {
            'antigravity' { @{ toolCall = @{ name = 'write_to_file'; args = 'not-an-object' }; workspacePaths = @($workspaceRoot) } }
            'copilot' { @{ hookEventName = 'preToolUse'; toolName = 'write'; toolArgs = '{broken-json'; cwd = $workspaceRoot } }
            'hermes' { @{ tool_name = 'write_file'; tool_input = 'not-an-object'; cwd = $workspaceRoot } }
            default { @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = 'not-an-object'; cwd = $workspaceRoot } }
        }
        $malformedResult = Invoke-PathSecretsGuardHook -HookScriptPath $hookPath -Payload $malformedPayload
        if ((Get-HookDecision -Result $malformedResult) -ne 'deny') {
            $failures.Add(('{0}: malformed write payload was not visibly denied (exit {1}; {2})' -f $provider.id, $malformedResult.ExitCode, $malformedResult.Output.Trim()))
        }
        else { Write-Host ('{0}: malformed write payload visibly denied' -f $provider.id) }

        $homeName = switch ([string]$provider.id) {
            'antigravity' { '.gemini' }
            'openhands' { '.agents' }
            default { '.' + [string]$provider.id }
        }
        $installRoot = if ($provider.id -eq 'opencode') { Join-Path $homeRoot '.config\opencode' } else { Join-Path $homeRoot $homeName }
        if ($provider.id -eq 'hermes' -and -not [string]::IsNullOrWhiteSpace($env:HERMES_HOME)) { $installRoot = $env:HERMES_HOME }
        if ($provider.id -eq 'hermes' -and [string]::IsNullOrWhiteSpace($env:HERMES_HOME) -and -not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { $installRoot = Join-Path $env:LOCALAPPDATA 'hermes' }
        $target = Join-Path (Join-Path $installRoot 'sdd') 'sessions\hook-probe.json'
        $hookPayload = switch ([string]$provider.id) {
            'antigravity' { @{ toolCall = @{ name = 'write_to_file'; args = @{ path = $target; content = '{}' } }; workspacePaths = @($workspaceRoot) } }
            'copilot' { @{ hookEventName = 'preToolUse'; toolName = 'write'; toolArgs = (@{ path = $target; content = '{}' } | ConvertTo-Json -Compress); cwd = $workspaceRoot } }
            default { @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = @{ path = $target; content = '{}' }; cwd = $workspaceRoot } }
        }
        if ($provider.id -eq 'hermes') {
            $hookPayload = @{ tool_name = 'terminal'; tool_input = @{ command = ("Set-Content -Path '{0}' -Value '{{}}'" -f $target) }; cwd = $workspaceRoot }
        }
        elseif ($provider.id -eq 'openhands') {
            $hookPayload = @{ tool_name = 'write'; tool_input = @{ path = $target; content = '{}' }; cwd = $workspaceRoot }
        }
        $allowed = Invoke-PathSecretsGuardHook -HookScriptPath $hookPath -Payload $hookPayload
        $allowDecision = ''
        if ($null -ne $allowed.Payload) {
            if ($allowed.Payload.PSObject.Properties['permission']) { $allowDecision = [string]$allowed.Payload.permission }
            elseif ($allowed.Payload.PSObject.Properties['decision']) { $allowDecision = [string]$allowed.Payload.decision }
            elseif ($allowed.Payload.PSObject.Properties['permissionDecision']) { $allowDecision = [string]$allowed.Payload.permissionDecision }
            elseif ($allowed.Payload.PSObject.Properties['hookSpecificOutput'] -and $allowed.Payload.hookSpecificOutput.PSObject.Properties['permissionDecision']) { $allowDecision = [string]$allowed.Payload.hookSpecificOutput.permissionDecision }
            elseif ($provider.id -eq 'hermes' -and @($allowed.Payload.PSObject.Properties).Count -eq 0 -and $allowed.ExitCode -eq 0) { $allowDecision = 'allow' }
        }
        if ($allowDecision -ne 'allow') { $failures.Add(('{0}: native hook did not allow local SDD target outside CWD (exit {1}; {2})' -f $provider.id, $allowed.ExitCode, $allowed.Output.Trim())) }
        else { Write-Host ('{0}: native hook allows local SDD target outside CWD' -f $provider.id) }

        $workspaceTarget = Join-Path (Join-Path $workspaceRoot 'sessions') 'workspace-probe.json'
        $workspacePayload = switch ([string]$provider.id) {
            'antigravity' { @{ toolCall = @{ name = 'write_to_file'; args = @{ path = $workspaceTarget; content = '{}' } }; workspacePaths = @($workspaceRoot) } }
            'copilot' { @{ hookEventName = 'preToolUse'; toolName = 'write'; toolArgs = (@{ path = $workspaceTarget; content = '{}' } | ConvertTo-Json -Compress); cwd = $workspaceRoot } }
            'hermes' { @{ tool_name = 'terminal'; tool_input = @{ command = ("Set-Content -Path '{0}' -Value '{{}}'" -f $workspaceTarget) }; cwd = $workspaceRoot } }
            'openhands' { @{ tool_name = 'write'; tool_input = @{ path = $workspaceTarget; content = '{}' }; cwd = $workspaceRoot } }
            default { @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = @{ path = $workspaceTarget; content = '{}' }; cwd = $workspaceRoot } }
        }
        $workspaceAllowed = Invoke-PathSecretsGuardHook -HookScriptPath $hookPath -Payload $workspacePayload
        $workspaceDecision = Get-HookDecision -Result $workspaceAllowed
        if ($provider.id -eq 'hermes' -and $workspaceAllowed.ExitCode -eq 0 -and $null -ne $workspaceAllowed.Payload -and @($workspaceAllowed.Payload.PSObject.Properties).Count -eq 0) { $workspaceDecision = 'allow' }
        if ($workspaceDecision -ne 'allow') { $failures.Add(('{0}: native hook did not allow active workspace target (exit {1}; {2})' -f $provider.id, $workspaceAllowed.ExitCode, $workspaceAllowed.Output.Trim())) }
        else { Write-Host ('{0}: native hook allows active workspace target' -f $provider.id) }

        $unknownPayload = @{} + $hookPayload
        if ($provider.id -eq 'antigravity') { $unknownPayload.toolCall = @{} + $hookPayload.toolCall; $unknownPayload.toolCall.name = 'provider_unknown_probe' }
        elseif ($provider.id -eq 'copilot') { $unknownPayload.toolName = 'provider_unknown_probe' }
        else { $unknownPayload.tool_name = 'provider_unknown_probe' }
        $unknownResult = Invoke-PathSecretsGuardHook -HookScriptPath $hookPath -Payload $unknownPayload
        if ((Get-HookDecision -Result $unknownResult) -ne 'deny' -or $unknownResult.Output -notmatch 'unclassified') {
            $failures.Add(('{0}: unclassified tool was not observably denied (exit {1}; {2})' -f $provider.id, $unknownResult.ExitCode, $unknownResult.Output.Trim()))
        }
        else { Write-Host ('{0}: unclassified tool was observably denied' -f $provider.id) }

        $readOnlyPayload = @{} + $hookPayload
        if ($provider.id -eq 'antigravity') { $readOnlyPayload.toolCall = @{} + $hookPayload.toolCall; $readOnlyPayload.toolCall.name = $readOnlyToolNames[[string]$provider.id] }
        elseif ($provider.id -eq 'copilot') { $readOnlyPayload.toolName = $readOnlyToolNames[[string]$provider.id] }
        else { $readOnlyPayload.tool_name = $readOnlyToolNames[[string]$provider.id] }
        $readOnlyResult = Invoke-PathSecretsGuardHook -HookScriptPath $hookPath -Payload $readOnlyPayload
        $readOnlyDecision = Get-HookDecision -Result $readOnlyResult
        if ($provider.id -eq 'hermes' -and $readOnlyResult.ExitCode -eq 0 -and $null -ne $readOnlyResult.Payload -and @($readOnlyResult.Payload.PSObject.Properties).Count -eq 0) { $readOnlyDecision = 'allow' }
        if ($readOnlyDecision -ne 'allow') {
            $failures.Add(('{0}: classified read-only tool was not allowed (exit {1}; {2})' -f $provider.id, $readOnlyResult.ExitCode, $readOnlyResult.Output.Trim()))
        }
        else { Write-Host ('{0}: classified read-only tool remains allowed' -f $provider.id) }
    }

    $outside = Join-Path ([System.IO.Path]::GetTempPath()) 'adt-local-sdd-denied.cs'
    $denied = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([PSCustomObject]@{ path = $outside; content = 'class Safe {}' }) -WorkspaceRoot $workspaceRoot
    if ($denied.Decision -ne 'deny') { $failures.Add('unrelated external path was not denied') }

    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($null -ne $node) {
        $pluginPath = Join-Path $repoRoot 'adapters\opencode\assets\plugins\agent-dev-toolkit-marker.js'
        $nodeProbe = @'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const m = await import(pathToFileURL(process.argv[1]).href);
const home = process.env.USERPROFILE || process.env.HOME;
const roots = {cursor:'.cursor',codex:'.codex',claude:'.claude',copilot:'.copilot',grok:'.grok',hermes:'.hermes',opencode:'.config/opencode',zcode:'.zcode',antigravity:'.gemini',openhands:'.agents'};
for (const [provider, install] of Object.entries(roots)) {
  const root = path.join(home, install, 'sdd');
  const v = m.evaluatePathSecretsGuard('write', {path:path.join(root,'sessions','probe.json'),content:'{}'}, process.cwd());
  if (v.decision !== 'allow') throw new Error(`${provider}: ${v.reason}`);
}
const bad = m.evaluatePathSecretsGuard('write', {path:path.join(home,'.codex','sdd-evil','probe.json'),content:'{}'}, process.cwd());
if (bad.decision !== 'deny') throw new Error('sibling prefix was accepted');
const openCodeConfig = m.evaluatePathSecretsGuard('write', {path:path.join(home,'.config','opencode','opencode.json'),content:'{}'}, process.cwd());
if (openCodeConfig.decision !== 'deny') throw new Error('OpenCode sibling config was accepted');
if (process.env.HERMES_HOME) {
  const hermesSdd = m.evaluatePathSecretsGuard('write', {path:path.join(process.env.HERMES_HOME,'sdd','sessions','probe.json'),content:'{}'}, process.cwd());
  const hermesConfig = m.evaluatePathSecretsGuard('write', {path:path.join(process.env.HERMES_HOME,'config.yaml'),content:'x: y'}, process.cwd());
  if (hermesSdd.decision !== 'allow' || hermesConfig.decision !== 'deny') throw new Error('HERMES_HOME SDD/config scope was incorrect');
}
const invalid = m.evaluatePathSecretsGuard('write', {}, process.cwd());
if (invalid.decision !== 'deny') throw new Error('write without path was accepted');
const malformed = m.evaluatePathSecretsGuard('write', 'not-an-object', process.cwd());
if (malformed.decision !== 'deny') throw new Error('malformed write args were accepted');
for (const args of [{}, {command:'  '}, {command:{nested:'Set-Content'}}]) {
  const shell = m.evaluatePathSecretsGuard('bash', args, process.cwd());
  if (shell.decision !== 'deny' || !shell.reason.includes('command')) throw new Error('missing, empty, or malformed shell payload was not observably denied');
}
const unknown = m.evaluatePathSecretsGuard('provider_unknown_probe', {}, process.cwd());
if (unknown.decision !== 'deny' || !unknown.reason.includes('unclassified')) throw new Error('unknown tool was not observably denied');
if (m.evaluatePathSecretsGuard('read', {}, process.cwd()).decision !== 'allow') throw new Error('classified read-only tool was blocked');
console.log('OpenCode: all local SDD roots outside CWD allowed; sibling prefix denied');
'@
        $savedHermesHome = $env:HERMES_HOME
        $env:HERMES_HOME = $testHermesHome
        try { $nodeOut = & $node.Source --input-type=module -e $nodeProbe $pluginPath 2>&1 | Out-String }
        finally { $env:HERMES_HOME = $savedHermesHome }
        if ($LASTEXITCODE -ne 0) { $failures.Add(('OpenCode JS: {0}' -f $nodeOut.Trim())) }
        else { Write-Host $nodeOut.Trim() }
    }
    else { Write-Host 'OpenCode JS: NOT REPRODUCED (Node.js unavailable)' }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
    if ($null -ne $python) {
        $pluginPath = Join-Path $repoRoot 'adapters\hermes\assets\plugins\agent-dev-toolkit-guard\__init__.py'
        $pythonProbe = @'
import importlib.util, os, pathlib, sys
spec = importlib.util.spec_from_file_location("adt_guard", sys.argv[1]); mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
home = pathlib.Path.home()
roots = {"cursor":".cursor","codex":".codex","claude":".claude","copilot":".copilot","grok":".grok","hermes":".hermes","opencode":".config/opencode","zcode":".zcode","antigravity":".gemini","openhands":".agents"}
for provider, install in roots.items():
    root = home / install / "sdd"
    if mod.evaluate_tool_call("write_file", {"path": str(root / "sessions/probe.json"), "content": "{}"}) is not None: raise RuntimeError(provider)
if mod.evaluate_tool_call("write_file", {"path": str(home / ".codex/sdd-evil/probe.json"), "content": "{}"}) is None: raise RuntimeError("sibling prefix accepted")
if mod.evaluate_tool_call("write_file", {"path": str(home / ".config/opencode/opencode.json"), "content": "{}"}) is None: raise RuntimeError("OpenCode sibling config was accepted")
hermes_home = pathlib.Path(os.environ["HERMES_HOME"])
if mod.evaluate_tool_call("write_file", {"path": str(hermes_home / "sdd/sessions/probe.json"), "content": "{}"}) is not None: raise RuntimeError("HERMES_HOME SDD was denied")
if mod.evaluate_tool_call("write_file", {"path": str(hermes_home / "config.yaml"), "content": "x: y"}) is None: raise RuntimeError("HERMES_HOME sibling config was accepted")
if mod.evaluate_tool_call("write_file", {}) is None: raise RuntimeError("write without path was accepted")
if mod.evaluate_tool_call("write_file", "not-an-object") is None: raise RuntimeError("malformed write args were accepted")
for args in ({}, {"command": "  "}, {"command": {"nested": "Set-Content"}}):
    denied = mod.evaluate_tool_call("terminal", args)
    if not denied or denied.get("action") != "block" or "command" not in denied.get("message", ""):
        raise RuntimeError("missing, empty, or malformed terminal payload was not observably denied")
unknown = mod.evaluate_tool_call("provider_unknown_probe", {})
if not unknown or unknown.get("action") != "block": raise RuntimeError("unknown tool was not blocked")
if mod.evaluate_tool_call("read_file", {}) is not None: raise RuntimeError("classified read-only tool was blocked")
print("Hermes Python: all local SDD roots outside CWD allowed; sibling prefix denied")
'@
        $savedHermesHome = $env:HERMES_HOME
        $env:HERMES_HOME = $testHermesHome
        try { $pythonOut = $pythonProbe | & $python.Source - $pluginPath 2>&1 | Out-String }
        finally { $env:HERMES_HOME = $savedHermesHome }
        if ($LASTEXITCODE -ne 0) { $failures.Add(('Hermes Python: {0}' -f $pythonOut.Trim())) }
        else { Write-Host $pythonOut.Trim() }
    }
    else { Write-Host 'Hermes Python: NOT REPRODUCED (Python unavailable)' }
}
finally {
    Remove-Item -LiteralPath $workspaceRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) { throw ($failures -join [Environment]::NewLine) }
Write-Host ('Assert-LocalSddWriteConformance: PASS ({0} registry providers checked against GuardCommon)' -f @($registry.agents).Count)
