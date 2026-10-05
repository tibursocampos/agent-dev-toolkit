# PreToolUse - deny Bash / apply_patch (Edit|Write) outside allowed scopes; block secrets.
# Codex output: hookSpecificOutput.permissionDecision allow|deny (exit 0).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
if ($null -eq $inputJson) {
    Write-CodexPreToolJson @{
        permissionDecision       = 'deny'
        permissionDecisionReason = 'Hook denied malformed or empty JSON input; fail-closed.'
    }
}
if (-not (Test-ToolkitHookInputSchema -HookInput $inputJson)) {
    Write-CodexPreToolJson @{
        permissionDecision       = 'deny'
        permissionDecisionReason = 'Hook denied schema-invalid JSON input; expected a non-empty object.'
    }
}
$toolName = ''
if ($inputJson -and $inputJson.PSObject.Properties['tool_name']) {
    $toolName = [string]$inputJson.tool_name
}
$workspaceRoot = (Get-Location).Path
if ($inputJson -and $inputJson.PSObject.Properties['cwd'] -and -not [string]::IsNullOrWhiteSpace([string]$inputJson.cwd)) {
    $workspaceRoot = [string]$inputJson.cwd
}
$toolInput = $null
if ($inputJson -and $inputJson.PSObject.Properties['tool_input']) {
    $toolInput = $inputJson.tool_input
}

# Keep the host tool name so shared validation can read semantic Write/Edit
# fields such as tool_input.path instead of treating them as patch text.
$effectiveTool = $toolName

$isGuarded = (
    (Test-ToolkitWriteToolName $effectiveTool) -or
    (Test-ToolkitShellToolName $effectiveTool) -or
    (Test-ToolkitApplyPatchToolName $effectiveTool) -or
    ($toolName -match '^(?i)(Edit|Write)$')
)
if (-not $isGuarded) {
    Write-CodexPreToolJson @{ permissionDecision = 'allow' }
}

if (-not (Test-ToolkitHookEventIdentity -HookInput $inputJson -ExpectedEventNames @('PreToolUse', 'preToolUse'))) {
    Write-CodexPreToolJson @{
        permissionDecision       = 'deny'
        permissionDecisionReason = 'Hook denied write/shell event with missing or malformed PreToolUse identity; fail-closed.'
    }
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $effectiveTool `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    Write-CodexPreToolJson @{
        permissionDecision       = 'deny'
        permissionDecisionReason = [string]$verdict.AgentMessage
    }
}

Write-CodexPreToolJson @{ permissionDecision = 'allow' }
