# Antigravity PreToolUse - deny write/edit/shell outside allowed scopes; block secret patterns.
# Output: { decision: "allow"|"deny", reason? } (official Antigravity hooks contract).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson

$toolName = ''
if ($inputJson -and $inputJson.PSObject.Properties['toolCall'] -and $inputJson.toolCall) {
    if ($inputJson.toolCall.PSObject.Properties['name']) {
        $toolName = [string]$inputJson.toolCall.name
    }
}
elseif ($inputJson -and $inputJson.PSObject.Properties['tool_name']) {
    $toolName = [string]$inputJson.tool_name
}

$workspaceRoot = (Get-Location).Path
if ($inputJson -and $inputJson.PSObject.Properties['workspacePaths']) {
    $paths = @($inputJson.workspacePaths)
    if ($paths.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$paths[0])) {
        $workspaceRoot = [string]$paths[0]
    }
}
elseif ($inputJson -and $inputJson.PSObject.Properties['cwd'] -and -not [string]::IsNullOrWhiteSpace([string]$inputJson.cwd)) {
    $workspaceRoot = [string]$inputJson.cwd
}

$toolInput = $null
if ($inputJson -and $inputJson.PSObject.Properties['toolCall'] -and $inputJson.toolCall -and $inputJson.toolCall.PSObject.Properties['args']) {
    $toolInput = $inputJson.toolCall.args
}
elseif ($inputJson -and $inputJson.PSObject.Properties['tool_input']) {
    $toolInput = $inputJson.tool_input
}

# Map Antigravity tool ids onto shared GuardCommon matchers.
$effective = $toolName
if ($toolName -match '(?i)^run_command$') {
    $effective = 'Shell'
}
elseif ($toolName -match '(?i)^(write_to_file|replace_file_content|multi_replace_file_content)$') {
    $effective = 'Write'
}

$isGuarded = (
    (Test-ToolkitWriteToolName $effective) -or
    (Test-ToolkitDeleteToolName $effective) -or
    (Test-ToolkitShellToolName $effective) -or
    (Test-ToolkitApplyPatchToolName $effective)
)
if (-not $isGuarded) {
    Write-AntigravityPreToolAllow
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $effective `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    Write-AntigravityPreToolDeny -Reason ([string]$verdict.AgentMessage)
}

Write-AntigravityPreToolAllow
