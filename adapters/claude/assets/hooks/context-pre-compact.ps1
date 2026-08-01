# Claude hook script - remind user to save PLAN at high context usage.
# Wiring into settings.json happens during settings merge. Smoke validates file presence only.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
$usagePct = 0
if ($inputJson -and $null -ne $inputJson.context_usage_percent) {
    $usagePct = [int]$inputJson.context_usage_percent
}

$parts = @()
if ($usagePct -ge 80) {
    $parts += '[CRITICAL] Context at or above 80%. Stop this session; start a new chat. Apply context-management policy.'
}
elseif ($usagePct -ge 40) {
    $parts += '[WARNING] Context at or above 40%. Save PLAN/PRD checkboxes now; do not start the next PLAN step in this session.'
}
else {
    $parts += '[INFO] Context compaction is about to run. Persist PLAN/PRD progress if you are in a multi-step skill.'
}

$planStatePath = Get-StatePath 'plan-edit.json'
if (Test-Path $planStatePath) {
    try {
        $planState = Get-Content $planStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($planState.plan_path) {
            $parts += "Recent PLAN edit: $($planState.plan_path). Mark step status and progress before continuing."
        }
    }
    catch {
        # ignore corrupt state
    }
}

$parts += 'Hooks do not select models or read Claude session JSONL. Smoke validates files only (trust UI out of scope).'

Write-HookJson @{ user_message = ($parts -join ' ') }
