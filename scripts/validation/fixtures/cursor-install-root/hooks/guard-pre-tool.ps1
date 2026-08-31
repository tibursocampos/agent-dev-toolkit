# preToolUse - deny Write outside allowed scopes and block obvious secret patterns.
# Contract: sdd-pipeline-guards (features/ canonical SDD) + step-3.5-precommit-validation (secrets).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
$toolName = if ($inputJson -and $inputJson.tool_name) { [string]$inputJson.tool_name } else { '' }

if (-not (Test-ToolkitWriteToolName $toolName)) {
    Write-PreToolJson @{ permission = 'allow' }
}

$workspaceRoot = if ($inputJson -and $inputJson.cwd) { [string]$inputJson.cwd } else { (Get-Location).Path }
$toolInput = if ($inputJson -and $inputJson.tool_input) { $inputJson.tool_input } else { $null }
$filePath = Get-WriteToolPathFromInput $toolInput
$relativePath = Get-ToolkitNormalizedRelativePath -FilePath $filePath -WorkspaceRoot $workspaceRoot
$content = Get-WriteToolContentFromInput $toolInput

if (-not [string]::IsNullOrWhiteSpace($relativePath)) {
    if (-not (Test-ToolkitAllowedWritePath -RelativePath $relativePath)) {
        Write-PreToolJson @{
            permission    = 'deny'
            user_message  = "Write blocked: path outside allowed scopes ($relativePath)."
            agent_message = "Hook denied Write to '$relativePath'. SDD artifacts belong under features/ (see sdd-pipeline-guards). Application code must live under standard source trees (src/, tests/, app/, etc.) or use an allowed extension. memory-bank/ and docs/ are also allowed."
        }
    }
}

$secretFindings = @(Get-ToolkitSecretFindings -Content $content)
if ($secretFindings.Count -gt 0) {
    $first = $secretFindings[0]
    Write-PreToolJson @{
        permission    = 'deny'
        user_message  = "Write blocked: possible secret ($($first.Type)) near line $($first.Line)."
        agent_message = "Hook denied Write because content matches secret pattern '$($first.Type)'. Use env var names or placeholders (YOUR_, TOKEN placeholder, masked values). Never commit API keys, tokens, passwords, or private keys."
    }
}

Write-PreToolJson @{ permission = 'allow' }
