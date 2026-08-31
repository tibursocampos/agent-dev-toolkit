# Hermes agent-hooks pre_tool_call - path/secrets guard (Windows).
# Output: { "action": "block", "message": "..." } or {}

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$_guardCommonCandidates = @(
    (Join-Path $PSScriptRoot 'GuardCommon.ps1'),
    (Join-Path $PSScriptRoot '..\..\..\_shared\GuardCommon.ps1')
)
$_guardCommonLoaded = $false
foreach ($_guardCandidate in $_guardCommonCandidates) {
    try {
        $_guardFull = [System.IO.Path]::GetFullPath($_guardCandidate)
    }
    catch {
        continue
    }
    if (Test-Path -LiteralPath $_guardFull) {
        . $_guardFull
        $_guardCommonLoaded = $true
        break
    }
}
if (-not $_guardCommonLoaded) {
    Write-Output '{"action":"block","message":"GuardCommon.ps1 missing for Hermes agent-hooks guard."}'
    exit 2
}
Remove-Variable -Name _guardCommonCandidates, _guardCommonLoaded, _guardCandidate, _guardFull -ErrorAction SilentlyContinue

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Output '{}'
    exit 0
}

try {
    $inputJson = $raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Output '{}'
    exit 0
}

$toolName = ''
if ($inputJson.PSObject.Properties['tool_name']) {
    $toolName = [string]$inputJson.tool_name
}

$workspaceRoot = (Get-Location).Path
if ($inputJson.PSObject.Properties['cwd'] -and -not [string]::IsNullOrWhiteSpace([string]$inputJson.cwd)) {
    $workspaceRoot = [string]$inputJson.cwd
}

$toolInput = $null
if ($inputJson.PSObject.Properties['tool_input']) {
    $toolInput = $inputJson.tool_input
}

$effective = $toolName
if ($toolName -match '(?i)^terminal$') {
    $effective = 'Shell'
}
elseif ($toolName -match '(?i)^write_file$') {
    $effective = 'Write'
}
elseif ($toolName -match '(?i)^patch$') {
    $effective = 'apply_patch'
}

$isGuarded = (
    (Test-ToolkitWriteToolName $effective) -or
    (Test-ToolkitShellToolName $effective) -or
    (Test-ToolkitApplyPatchToolName $effective)
)
if (-not $isGuarded) {
    Write-Output '{}'
    exit 0
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $effective `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    $payload = [ordered]@{
        action  = 'block'
        message = [string]$verdict.AgentMessage
    }
    Write-Output ($payload | ConvertTo-Json -Compress -Depth 5)
    exit 2
}

Write-Output '{}'
exit 0
