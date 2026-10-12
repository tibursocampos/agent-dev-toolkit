#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$hooksRoot = Join-Path $repoRoot 'adapters/cursor/assets/hooks'
$hooksJsonPath = Join-Path $hooksRoot 'hooks.json'
if (-not (Test-Path -LiteralPath $hooksJsonPath -PathType Leaf)) {
    throw "Cursor hooks.json is missing: $hooksJsonPath"
}

$hooks = Get-Content -LiteralPath $hooksJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($eventName in @('preToolUse', 'beforeShellExecution')) {
    if (@($hooks.hooks.$eventName).Count -gt 0) {
        throw "Cursor must leave $eventName authorization decisions to the host."
    }
}

$managedLifecycleEvents = @('postToolUse', 'subagentStop', 'beforeSubmitPrompt', 'afterFileEdit')
foreach ($eventName in $managedLifecycleEvents) {
    $handlers = @($hooks.hooks.$eventName)
    if ($handlers.Count -eq 0) {
        throw "Cursor lifecycle hook $eventName must remain published."
    }
    foreach ($handler in $handlers) {
        $command = [string]$handler.command
        if ($command -match '(?i)guard-pre-tool') {
            throw "Cursor must not publish Toolkit authorization hook in $eventName."
        }
        if ($command -match '(?i)\./hooks/([^\s"]+)') {
            $assetPath = Join-Path $hooksRoot $Matches[1]
            if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
                throw "Cursor lifecycle hook asset is missing: $assetPath"
            }
        }
    }
}

Write-Host 'Assert-CursorPathSecretsGuard: PASS (host-owned authorization; Toolkit lifecycle hooks retained)'
