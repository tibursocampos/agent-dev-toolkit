#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = [System.Collections.Generic.List[string]]::new()
$checks = 0

function Assert-CatchAll($Provider, [bool] $Condition, $Evidence) {
    $script:checks++
    if (-not $Condition) { $script:failures.Add("${Provider}: configured guard does not capture every tool ($Evidence)") }
    else { Write-Host ("{0}: catch-all configuration verified ({1})" -f $Provider, $Evidence) }
}

$cursor = Get-Content (Join-Path $repoRoot 'adapters/cursor/assets/hooks/hooks.json') -Raw | ConvertFrom-Json
Assert-CatchAll 'cursor' ($cursor.hooks.preToolUse[0].matcher -eq '') 'empty matcher means all'

$antigravity = Get-Content (Join-Path $repoRoot 'adapters/antigravity/assets/hooks/hooks.json') -Raw | ConvertFrom-Json
Assert-CatchAll 'antigravity' ($antigravity.'agent-dev-toolkit-path-secrets-guard'.PreToolUse[0].matcher -eq '.*') 'regex matcher . *'

$claudeConstants = Get-Content (Join-Path $repoRoot 'adapters/claude/ClaudePathConstants.ps1') -Raw
Assert-CatchAll 'claude' ($claudeConstants -match "HookMatcherPreToolUse\s*=\s*'\*'" ) 'wildcard matcher'

. (Join-Path $repoRoot 'adapters/codex/CodexPathConstants.ps1')
. (Join-Path $repoRoot 'adapters/codex/Publish-CodexHooks.ps1')
$codex = New-CodexPreToolUseHooksObject
$codexGroups = @($codex.hooks.PreToolUse)
Assert-CatchAll 'codex' ($codexGroups.Count -eq 1 -and $codexGroups[0].matcher -eq '.*') 'single PreToolUse group with matcher .*'

$copilot = Get-Content (Join-Path $repoRoot 'adapters/copilot/assets/hooks/hooks.json') -Raw | ConvertFrom-Json
Assert-CatchAll 'copilot' ($copilot.hooks.preToolUse.Count -eq 1 -and -not $copilot.hooks.preToolUse[0].PSObject.Properties['matcher']) 'preToolUse event has no matcher filter'

$openCodeSource = Get-Content (Join-Path $repoRoot 'adapters/opencode/assets/plugins/agent-dev-toolkit-marker.js') -Raw
Assert-CatchAll 'opencode' ($openCodeSource -match "'tool\.execute\.before'\s*:\s*async") 'global before-tool plugin callback'

$grokConstants = Get-Content (Join-Path $repoRoot 'adapters/grok/GrokPathConstants.ps1') -Raw
Assert-CatchAll 'grok' ($grokConstants -match "HooksPreToolUseMatcher\s*=\s*'\*'") 'wildcard matcher'

$zcodeHooks = Get-Content (Join-Path $repoRoot 'adapters/zcode/hooks/hooks.json') -Raw | ConvertFrom-Json
$zcodeCli = Get-Content (Join-Path $repoRoot 'adapters/zcode/cli/config.json') -Raw | ConvertFrom-Json
Assert-CatchAll 'zcode' ($zcodeHooks.hooks.PreToolUse[0].matcher -eq '*' -and $zcodeCli.hooks.events.PreToolUse[0].matcher -eq '*') 'both installed configs use wildcard'

$hermesConstants = Get-Content (Join-Path $repoRoot 'adapters/hermes/HermesPathConstants.ps1') -Raw
Assert-CatchAll 'hermes' ($hermesConstants -match "HooksPreToolCallMatcher\s*=\s*'\.\*'") 'regex matcher . *'

$openHandsConstants = Get-Content (Join-Path $repoRoot 'adapters/openhands/OpenHandsPathConstants.ps1') -Raw
Assert-CatchAll 'openhands' ($openHandsConstants -match "HooksPreToolUseMatcher\s*=\s*'\*'") 'wildcard matcher'

if ($failures.Count -gt 0) { throw ($failures -join [Environment]::NewLine) }
Write-Host ("Assert-ProviderCatchAllConfiguration: PASS ({0} providers)" -f $checks)
