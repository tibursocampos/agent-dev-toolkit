# PreToolUse - deny Bash / apply_patch (Edit|Write) outside allowed scopes; block secrets.
# Codex output: hookSpecificOutput.permissionDecision allow|deny (exit 0).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
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

# Matcher may fire as Edit/Write aliases; normalize to apply_patch for content extraction.
$effectiveTool = $toolName
if ($toolName -match '^(?i)(Edit|Write)$') {
    $effectiveTool = 'apply_patch'
}

$isGuarded = (
    (Test-ToolkitWriteToolName $effectiveTool) -or
    (Test-ToolkitShellToolName $effectiveTool) -or
    (Test-ToolkitApplyPatchToolName $effectiveTool) -or
    ($toolName -match '^(?i)(Edit|Write)$')
)
if (-not $isGuarded) {
    Write-CodexPreToolJson @{ permissionDecision = 'allow' }
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
