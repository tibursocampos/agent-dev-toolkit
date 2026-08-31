# Shared helpers for agent-dev-toolkit Claude hooks (Windows PowerShell 5.1+).
# Dot-sourced by hook scripts; not invoked directly by settings.json.
# Path/secret guards: adapters/_shared/GuardCommon.ps1 (see guard-rules.md).

Set-StrictMode -Version Latest

$script:ToolkitHooksStateDir = Join-Path $env:USERPROFILE '.claude\hooks-state'

# Load shared path/secret helpers (sibling after publish, or adapters/_shared in-repo).
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
    throw "GuardCommon.ps1 not found relative to $PSScriptRoot (expected sibling or adapters/_shared)."
}
Remove-Variable -Name _guardCommonCandidates, _guardCommonLoaded, _guardCandidate, _guardFull -ErrorAction SilentlyContinue

function Ensure-HooksStateDir {
    if (-not (Test-Path $script:ToolkitHooksStateDir)) {
        New-Item -ItemType Directory -Path $script:ToolkitHooksStateDir -Force | Out-Null
    }
}

function Read-HookInputJson {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }
    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Write-HookJson([hashtable] $Payload) {
    $json = $Payload | ConvertTo-Json -Compress -Depth 5
    Write-Output $json
    exit 0
}

function Write-ClaudePreToolJson([hashtable] $Payload) {
    <#
    .SYNOPSIS
      Emit Claude PreToolUse hookSpecificOutput (permissionDecision allow|deny).
    #>
    $decision = 'allow'
    if ($Payload.ContainsKey('permissionDecision')) {
        $decision = [string]$Payload['permissionDecision']
    }
    elseif ($Payload.ContainsKey('permission')) {
        $decision = [string]$Payload['permission']
    }

    $reason = ''
    if ($Payload.ContainsKey('permissionDecisionReason')) {
        $reason = [string]$Payload['permissionDecisionReason']
    }
    elseif ($Payload.ContainsKey('agent_message')) {
        $reason = [string]$Payload['agent_message']
    }
    elseif ($Payload.ContainsKey('user_message')) {
        $reason = [string]$Payload['user_message']
    }

    $hookOut = [ordered]@{
        hookEventName      = 'PreToolUse'
        permissionDecision = $decision
    }
    if (-not [string]::IsNullOrWhiteSpace($reason)) {
        $hookOut['permissionDecisionReason'] = $reason
    }

    $envelope = [ordered]@{
        hookSpecificOutput = $hookOut
    }
    $json = $envelope | ConvertTo-Json -Compress -Depth 6
    Write-Output $json
    exit 0
}

function Get-StatePath([string] $FileName) {
    Ensure-HooksStateDir
    return Join-Path $script:ToolkitHooksStateDir $FileName
}

function Set-SddState([string] $SkillName) {
    $path = Get-StatePath 'sdd-session.json'
    $payload = @{
        last_skill    = $SkillName
        last_seen_utc = (Get-Date).ToUniversalTime().ToString('o')
    }
    $payload | ConvertTo-Json -Compress | Set-Content -Path $path -Encoding UTF8
}

function Set-PlanEditState([string] $PlanPath) {
    $path = Get-StatePath 'plan-edit.json'
    $payload = @{
        plan_path     = $PlanPath
        last_edit_utc = (Get-Date).ToUniversalTime().ToString('o')
    }
    $payload | ConvertTo-Json -Compress | Set-Content -Path $path -Encoding UTF8
}

function Test-PlanFilePath([string] $FilePath) {
    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        return $false
    }
    $name = [System.IO.Path]::GetFileName($FilePath)
    if ($name -like 'PLAN_*.md') {
        if ($FilePath -match '[\\/]PLAN[\\/]') {
            return $true
        }
        return $FilePath -match '[\\/]\.cursor[\\/]sdd[\\/][^\\/]+[\\/]PLAN[\\/]'
    }
    return $false
}

function Test-SddSkillPrompt([string] $Prompt) {
    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        return $false
    }
    return $Prompt -match '(?i)use\s+skill\s+(sdd-spec|sdd-plan|sdd-develop|orchestrate-analyze|orchestrate-deliver|orchestrate-develop|commit|push|code-review|developer|document-plan|document-implement|refine-story|split-story-checklist|repair-dotnet-build|test-coverage|ef-add-migration|scaffold-message-handler|refactor|api-integrate|performance-profile|containerize|i18n-manager)'
}
