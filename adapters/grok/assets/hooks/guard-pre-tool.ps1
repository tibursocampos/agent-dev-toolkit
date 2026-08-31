# Grok PreToolUse - deny Write/Edit/Bash outside allowed scopes; block secrets.
# stdout: {"decision":"deny","reason":"..."} or hookSpecificOutput.permissionDecision; deny exits 2.

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
    throw "GuardCommon.ps1 not found relative to $PSScriptRoot."
}
Remove-Variable -Name _guardCommonCandidates, _guardCommonLoaded, _guardCandidate, _guardFull -ErrorAction SilentlyContinue

function Write-GrokPreToolDecision {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('allow', 'deny')][string] $Decision,
        [string] $Reason = ''
    )
    $payload = [ordered]@{
        decision = $Decision
        hookSpecificOutput = [ordered]@{
            hookEventName      = 'PreToolUse'
            permissionDecision = $Decision
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($Reason)) {
        $payload['reason'] = $Reason
        $payload['hookSpecificOutput']['permissionDecisionReason'] = $Reason
    }
    Write-Output ($payload | ConvertTo-Json -Compress -Depth 6)
    if ($Decision -eq 'deny') {
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

$effective = $toolName
if ($toolName -match '(?i)^(Edit|Write)$') {
    $effective = 'Write'
}
elseif ($toolName -match '(?i)^Bash$') {
    $effective = 'Shell'
}

$isGuarded = (
    (Test-ToolkitWriteToolName $effective) -or
    (Test-ToolkitShellToolName $effective) -or
    (Test-ToolkitDeleteToolName $effective) -or
    (Test-ToolkitApplyPatchToolName $effective)
)
if (-not $isGuarded) {
    Write-GrokPreToolDecision -Decision 'allow'
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $effective `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    Write-GrokPreToolDecision -Decision 'deny' -Reason ([string]$verdict.AgentMessage)
}

Write-GrokPreToolDecision -Decision 'allow'
