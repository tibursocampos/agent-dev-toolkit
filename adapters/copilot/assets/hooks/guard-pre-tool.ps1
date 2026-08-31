# preToolUse - deny write/edit/shell/delete outside allowed scopes; block secret patterns.
# Copilot: JSON permissionDecision + exit 2 on deny.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson

# Copilot may use toolName / toolArgs (JSON string) instead of tool_name / tool_input.
$toolName = ''
if ($inputJson -and $inputJson.PSObject.Properties['tool_name']) {
    $toolName = [string]$inputJson.tool_name
}
elseif ($inputJson -and $inputJson.PSObject.Properties['toolName']) {
    $toolName = [string]$inputJson.toolName
}

$workspaceRoot = if ($inputJson -and $inputJson.cwd) {
    [string]$inputJson.cwd
}
else {
    (Get-Location).Path
}

$toolInput = $null
if ($inputJson -and $inputJson.PSObject.Properties['tool_input']) {
    $toolInput = $inputJson.tool_input
}
elseif ($inputJson -and $inputJson.PSObject.Properties['toolArgs']) {
    $argsRaw = [string]$inputJson.toolArgs
    if (-not [string]::IsNullOrWhiteSpace($argsRaw)) {
        try {
            $toolInput = $argsRaw | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            $toolInput = [PSCustomObject]@{ command = $argsRaw }
        }
    }
}

# Normalize common Copilot tool names onto shared matchers.
$effective = $toolName
if ($toolName -match '(?i)^(bash|shell|powershell)$') {
    $effective = 'Shell'
}
elseif ($toolName -match '(?i)^(edit|write|create|strreplace|search_replace)$') {
    $effective = 'Write'
}
elseif ($toolName -match '(?i)^delete$') {
    $effective = 'Delete'
}

$isGuarded = (
    (Test-ToolkitWriteToolName $effective) -or
    (Test-ToolkitDeleteToolName $effective) -or
    (Test-ToolkitShellToolName $effective) -or
    (Test-ToolkitApplyPatchToolName $effective)
)
if (-not $isGuarded) {
    Write-CopilotPreToolAllow
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $effective `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    Write-CopilotPreToolDeny -Reason ([string]$verdict.AgentMessage)
}

Write-CopilotPreToolAllow
