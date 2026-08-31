# preToolUse / beforeShellExecution - deny writes, deletes, and shell outside allowed scopes;
# block obvious secret patterns.
# Contract: sdd-pipeline-guards (features/ canonical SDD) + step-3.5-precommit-validation (secrets).

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

$directShell = ''

# beforeShellExecution payload: top-level command (+ cwd), no tool_name.
if ([string]::IsNullOrWhiteSpace($toolName) -and $inputJson -and $inputJson.PSObject.Properties['command']) {
    $toolName = 'Shell'
    $directShell = [string]$inputJson.command
}

$isGuarded = (
    (Test-ToolkitWriteToolName $toolName) -or
    (Test-ToolkitDeleteToolName $toolName) -or
    (Test-ToolkitShellToolName $toolName) -or
    (Test-ToolkitApplyPatchToolName $toolName)
)
if (-not $isGuarded) {
    Write-PreToolJson @{ permission = 'allow' }
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $toolName `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot `
    -DirectShellCommand $directShell

if ($verdict.Decision -eq 'deny') {
    Write-PreToolJson @{
        permission    = 'deny'
        user_message  = [string]$verdict.UserMessage
        agent_message = [string]$verdict.AgentMessage
    }
}

Write-PreToolJson @{ permission = 'allow' }
