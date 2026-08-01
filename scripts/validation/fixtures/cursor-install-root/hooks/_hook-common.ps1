# Shared helpers for agent-dev-toolkit Cursor hooks (Windows PowerShell 5.1+).
# Dot-sourced by hook scripts; not invoked directly by hooks.json.

Set-StrictMode -Version Latest

$script:ToolkitHooksStateDir = Join-Path $env:USERPROFILE '.cursor\hooks-state'

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

function Get-StatePath([string] $FileName) {
    Ensure-HooksStateDir
    return Join-Path $script:ToolkitHooksStateDir $FileName
}

function Set-SddState([string] $SkillName) {
    $path = Get-StatePath 'sdd-session.json'
    $payload = @{
        last_skill   = $SkillName
        last_seen_utc = (Get-Date).ToUniversalTime().ToString('o')
    }
    $payload | ConvertTo-Json -Compress | Set-Content -Path $path -Encoding UTF8
}

function Set-PlanEditState([string] $PlanPath) {
    $path = Get-StatePath 'plan-edit.json'
    $payload = @{
        plan_path      = $PlanPath
        last_edit_utc  = (Get-Date).ToUniversalTime().ToString('o')
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
