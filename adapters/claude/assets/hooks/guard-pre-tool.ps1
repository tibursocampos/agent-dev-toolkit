# PreToolUse - deny Write/Edit/Bash/PowerShell outside allowed scopes; block secret patterns.
# Claude output: hookSpecificOutput.permissionDecision allow|deny (exit 0).

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
elseif ($inputJson -and $inputJson.PSObject.Properties['cwd_path'] -and -not [string]::IsNullOrWhiteSpace([string]$inputJson.cwd_path)) {
    $workspaceRoot = [string]$inputJson.cwd_path
}
$toolInput = $null
if ($inputJson -and $inputJson.PSObject.Properties['tool_input']) {
    $toolInput = $inputJson.tool_input
}

$isGuarded = (
    (Test-ToolkitWriteToolName $toolName) -or
    (Test-ToolkitShellToolName $toolName) -or
    (Test-ToolkitDeleteToolName $toolName) -or
    (Test-ToolkitApplyPatchToolName $toolName)
)
if (-not $isGuarded) {
    Write-ClaudePreToolJson @{ permissionDecision = 'allow' }
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $toolName `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    Write-ClaudePreToolJson @{
        permissionDecision       = 'deny'
        permissionDecisionReason = [string]$verdict.AgentMessage
    }
}

Write-ClaudePreToolJson @{ permissionDecision = 'allow' }
