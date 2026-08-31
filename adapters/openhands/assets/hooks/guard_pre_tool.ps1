# OpenHands PreToolUse evaluator (invoked by guard_pre_tool.sh).
# stdin JSON -> stdout {"decision":"allow|deny","reason":"..."} ; deny exits 2.

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
    Write-Output '{"decision":"deny","reason":"GuardCommon.ps1 missing; OpenHands guard fail-closed"}'
    exit 2
}
Remove-Variable -Name _guardCommonCandidates, _guardCommonLoaded, _guardCandidate, _guardFull -ErrorAction SilentlyContinue

function Write-OpenHandsGuardDecision {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('allow', 'deny')][string] $Decision,
        [string] $Reason = ''
    )
    $payload = [ordered]@{ decision = $Decision }
    if (-not [string]::IsNullOrWhiteSpace($Reason)) {
        $payload['reason'] = $Reason
    }
    Write-Output ($payload | ConvertTo-Json -Compress -Depth 4)
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
elseif ($inputJson -and $inputJson.PSObject.Properties['toolName']) {
    $toolName = [string]$inputJson.toolName
}

$workspaceRoot = (Get-Location).Path
if ($inputJson -and $inputJson.PSObject.Properties['cwd'] -and -not [string]::IsNullOrWhiteSpace([string]$inputJson.cwd)) {
    $workspaceRoot = [string]$inputJson.cwd
}

$toolInput = $null
if ($inputJson -and $inputJson.PSObject.Properties['tool_input']) {
    $toolInput = $inputJson.tool_input
}
elseif ($inputJson -and $inputJson.PSObject.Properties['tool_args']) {
    $toolInput = $inputJson.tool_args
}

# Map OpenHands tool ids onto GuardCommon matchers (write / terminal).
$effective = $toolName
if ($toolName -match '(?i)^(write|file_editor|str_replace_editor|edit_file)$') {
    $effective = 'Write'
}
elseif ($toolName -match '(?i)^(terminal|bash|run_terminal_cmd|execute_bash)$') {
    $effective = 'Shell'
}

$isGuarded = (
    (Test-ToolkitWriteToolName $effective) -or
    (Test-ToolkitShellToolName $effective)
)
if (-not $isGuarded) {
    Write-OpenHandsGuardDecision -Decision 'allow'
}

$verdict = Get-ToolkitPathSecretsGuardVerdict `
    -ToolName $effective `
    -ToolInput $toolInput `
    -WorkspaceRoot $workspaceRoot

if ($verdict.Decision -eq 'deny') {
    $reason = [string]$verdict.AgentMessage
    if ([string]::IsNullOrWhiteSpace($reason)) {
        $reason = [string]$verdict.UserMessage
    }
    Write-OpenHandsGuardDecision -Decision 'deny' -Reason $reason
}

Write-OpenHandsGuardDecision -Decision 'allow'
