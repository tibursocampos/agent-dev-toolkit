# ZCode PreToolUse - deny Write/Edit/Bash/PowerShell outside allowed scopes; block secrets.
# Output: hookSpecificOutput.permissionDecision allow|deny; deny also exits 2.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$_guardCommonCandidates = @(
    (Join-Path $PSScriptRoot 'GuardCommon.ps1'),
    (Join-Path $PSScriptRoot '..\..\_shared\GuardCommon.ps1')
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
    throw "GuardCommon.ps1 not found relative to $PSScriptRoot."
}
Remove-Variable -Name _guardCommonCandidates, _guardCommonLoaded, _guardCandidate, _guardFull -ErrorAction SilentlyContinue

function Write-ZCodePreToolJson {
    param([hashtable] $Payload)
    $decision = 'allow'
    if ($Payload.ContainsKey('permissionDecision')) {
        $decision = [string]$Payload['permissionDecision']
    }
    $reason = ''
    if ($Payload.ContainsKey('permissionDecisionReason')) {
        $reason = [string]$Payload['permissionDecisionReason']
    }
    $hookOut = [ordered]@{
        hookEventName      = 'PreToolUse'
        permissionDecision = $decision
    }
    if (-not [string]::IsNullOrWhiteSpace($reason)) {
        $hookOut['permissionDecisionReason'] = $reason
    }
    $envelope = [ordered]@{ hookSpecificOutput = $hookOut }
    Write-Output ($envelope | ConvertTo-Json -Compress -Depth 6)
    if ($decision -eq 'deny') {
        exit 2
    }
    exit 0
}

$raw = [Console]::In.ReadToEnd()
$inputJson = $null
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try {
        $inputJson = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $inputJson = $null
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

$isGuarded = (
    (Test-ToolkitWriteToolName $toolName) -or
    (Test-ToolkitShellToolName $toolName) -or
    (Test-ToolkitDeleteToolName $toolName) -or
    (Test-ToolkitApplyPatchToolName $toolName)
)
if (-not $isGuarded) {
    Write-ZCodePreToolJson @{ permissionDecision = 'allow' }
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $toolName `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    Write-ZCodePreToolJson @{
        permissionDecision       = 'deny'
        permissionDecisionReason = [string]$verdict.AgentMessage
    }
}

Write-ZCodePreToolJson @{ permissionDecision = 'allow' }
