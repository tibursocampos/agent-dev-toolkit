# preToolUse / beforeShellExecution - deny writes and mutating shell outside the workspace
# and outside user adapter homes, under .git, or in legacy PRD/PLAN trees; block secrets.
# Read and execute commands stay allowed. Global SDD under the user adapter home is allowed.
# Contract: sdd-pipeline-guards (features/ canonical SDD) + step-3.5-precommit-validation (secrets).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
if ($null -eq $inputJson) {
    Write-PreToolJson @{
        permission = 'deny'
        user_message = 'Blocked: malformed or empty hook input.'
        agent_message = 'Hook denied malformed or empty JSON input; fail-closed.'
    }
}
if (-not (Test-ToolkitHookInputSchema -HookInput $inputJson)) {
    Write-PreToolJson @{
        permission    = 'deny'
        user_message  = 'Blocked: schema-invalid hook input.'
        agent_message = 'Hook denied schema-invalid JSON input; expected a non-empty object.'
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

$directShell = ''

# beforeShellExecution payload: top-level command (+ cwd), no tool_name.
if ([string]::IsNullOrWhiteSpace($toolName) -and $inputJson -and $inputJson.PSObject.Properties['command']) {
    $toolName = 'Shell'
    $directShell = [string]$inputJson.command
}

$expectedEventNames = @('preToolUse', 'PreToolUse')
if (-not [string]::IsNullOrWhiteSpace($directShell)) {
    $expectedEventNames = @('beforeShellExecution')
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

if (-not (Test-ToolkitHookEventIdentity -HookInput $inputJson -ExpectedEventNames $expectedEventNames)) {
    Write-PreToolJson @{
        permission    = 'deny'
        user_message  = 'Blocked: missing or malformed hook event identity.'
        agent_message = 'Hook denied write/shell event with missing or malformed event identity; fail-closed.'
    }
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
