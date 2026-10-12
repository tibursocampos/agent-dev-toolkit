#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'adapters/claude/ClaudeAdapter.ps1')

$fixtureRoot = Join-Path $repoRoot 'scripts/validation/fixtures/claude'
$managedHooks = Get-ClaudeManagedHooksObject -InstallRoot $fixtureRoot
$preToolUseEvent = [string]$script:ClaudeSettingsJsonConstant.HookEventPreToolUse
$preToolUseHandlers = @($managedHooks[$preToolUseEvent])
if ($preToolUseHandlers.Count -gt 0) {
    throw 'Claude must leave PreToolUse authorization decisions to the host.'
}

$hooksAssets = Join-Path $repoRoot 'adapters/claude/assets/hooks'
if (Test-Path -LiteralPath (Join-Path $hooksAssets 'guard-pre-tool.ps1')) {
    throw 'Claude must not retain the Toolkit-only authorization hook asset.'
}

foreach ($scriptName in @('context-before-prompt.ps1', 'plan-after-edit.ps1', 'emit-trace.ps1')) {
    if (-not (Test-Path -LiteralPath (Join-Path $hooksAssets $scriptName) -PathType Leaf)) {
        throw "Claude lifecycle hook asset is missing: $scriptName"
    }
}

foreach ($eventName in @(
        $script:ClaudeSettingsJsonConstant.HookEventUserPromptSubmit,
        $script:ClaudeSettingsJsonConstant.HookEventPostToolUse,
        $script:ClaudeSettingsJsonConstant.HookEventSubagentStop
    )) {
    if (@($managedHooks[$eventName]).Count -eq 0) {
        throw "Claude lifecycle event is missing from managed publication: $eventName"
    }
}

Write-Host 'Assert-ClaudePathSecretsGuard: PASS (host-owned authorization; Toolkit lifecycle hooks retained)'
