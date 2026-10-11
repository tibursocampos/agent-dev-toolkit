# PreToolUse - deny Write/Edit/Bash/PowerShell outside allowed scopes; block secret patterns.
# Claude output: hookSpecificOutput.permissionDecision allow|deny (exit 0).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
if ($null -eq $inputJson -or -not (Test-ToolkitHookInputSchema -HookInput $inputJson)) {
    Write-ClaudePreToolJson @{ permissionDecision = 'deny'; permissionDecisionReason = 'Hook denied malformed, empty, or schema-invalid input; fail-closed.' }
}
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
if (Test-ToolkitReadOnlyToolName -ProviderId 'claude' -ToolName $toolName) {
    Write-ClaudePreToolJson @{ permissionDecision = 'allow' }
}
if (-not $isGuarded) {
    Write-ClaudePreToolJson @{ permissionDecision = 'deny'; permissionDecisionReason = ('Hook denied unclassified tool surface: ' + $toolName) }
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
