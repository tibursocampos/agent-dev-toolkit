# Shared helpers for agent-dev-toolkit Claude hooks (pwsh 7+ / Windows PowerShell 5.1+).
# Dot-sourced by hook scripts; not invoked directly by settings.json.
# Path/secret guards: adapters/_shared/GuardCommon.ps1 (see guard-rules.md).

Set-StrictMode -Version Latest

$_hooksUserHome = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($_hooksUserHome)) {
    $_hooksUserHome = $env:HOME
}
if ([string]::IsNullOrWhiteSpace($_hooksUserHome)) {
    $_hooksUserHome = [Environment]::GetFolderPath('UserProfile')
}
$script:ToolkitHooksStateDir = Join-Path (Join-Path $_hooksUserHome '.claude') 'hooks-state'
Remove-Variable -Name _hooksUserHome -ErrorAction SilentlyContinue

# Load shared path/secret helpers (sibling after publish, or adapters/_shared in-repo).
$_guardCommonCandidates = @(
    (Join-Path $PSScriptRoot 'GuardCommon.ps1'),
    (Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot '..') '..') '..') (Join-Path '_shared' 'GuardCommon.ps1'))
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
        try {
            . $_guardFull
            $_guardCommonLoaded = $true
        }
        catch {
            $_guardCommonLoaded = $false
        }
        break
    }
}
# Fail-open: a missing GuardCommon.ps1 must never block the session; hooks here do not call its helpers.
Remove-Variable -Name _guardCommonCandidates, _guardCommonLoaded, _guardCandidate, _guardFull -ErrorAction SilentlyContinue

function Ensure-HooksStateDir {
    if (-not (Test-Path $script:ToolkitHooksStateDir)) {
        New-Item -ItemType Directory -Path $script:ToolkitHooksStateDir -Force | Out-Null
    }
}

function Read-HookInputJson {
    $raw = ''
    try {
        $stream = [Console]::OpenStandardInput()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.UTF8Encoding]::new($false), $true, 4096, $true)
        $raw = $reader.ReadToEnd()
    }
    catch {
        $raw = ''
    }
    if ([string]::IsNullOrWhiteSpace($raw)) {
        try {
            $raw = [Console]::In.ReadToEnd()
        }
        catch {
            $raw = ''
        }
    }
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

function Get-HookToolFilePath {
    <#
    .SYNOPSIS
      Claude tool payload file path: tool_input.file_path, falling back to top-level file_path.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $InputJson
    )

    if ($null -eq $InputJson) {
        return ''
    }

    $toolInput = $InputJson.PSObject.Properties['tool_input']
    if ($null -ne $toolInput -and $null -ne $toolInput.Value) {
        $nested = $toolInput.Value.PSObject.Properties['file_path']
        if ($null -ne $nested -and -not [string]::IsNullOrWhiteSpace([string]$nested.Value)) {
            return [string]$nested.Value
        }
    }

    $topLevel = $InputJson.PSObject.Properties['file_path']
    if ($null -ne $topLevel) {
        return [string]$topLevel.Value
    }

    return ''
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

$script:ToolkitSddSkillNameAlternatives = 'sdd-spec|sdd-plan|sdd-develop|orchestrate-analyze|orchestrate-deliver|orchestrate-develop|commit|push|code-review|developer|document-plan|document-implement|refine-story|requirement-review|split-story-checklist|repair-dotnet-build|test-coverage|run-tests|ef-add-migration|scaffold-message-handler|refactor|api-integrate|performance-profile|containerize|i18n-manager'

$script:ToolkitPreferencesDefaults = [ordered]@{
    caveman_mode      = $true
    caveman_level     = 'full'
    artifact_language = $null
    verify_mode       = $false
}

function Get-HookPromptText {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $InputJson
    )

    if ($null -eq $InputJson) {
        return ''
    }

    $promptProperty = $InputJson.PSObject.Properties['prompt']
    if ($null -eq $promptProperty -or $null -eq $promptProperty.Value) {
        return ''
    }

    return [string]$promptProperty.Value
}

function Test-SddSkillPrompt([string] $Prompt) {
    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        return $false
    }
    return $Prompt -match ('(?i)(?:use\s+skill\s+|^\s*/)(?:{0})(?![\w-])' -f $script:ToolkitSddSkillNameAlternatives)
}

function Get-SddSkillNameFromPrompt([string] $Prompt) {
    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        return ''
    }
    if ($Prompt -match ('(?i)(?:use\s+skill\s+|^\s*/)({0})(?![\w-])' -f $script:ToolkitSddSkillNameAlternatives)) {
        return $Matches[1].ToLowerInvariant()
    }
    return ''
}

function Get-ClaudeHookUserHome {
    $userHome = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($userHome)) {
        $userHome = $env:HOME
    }
    if ([string]::IsNullOrWhiteSpace($userHome)) {
        $userHome = [Environment]::GetFolderPath('UserProfile')
    }
    return $userHome
}

function Get-ClaudePreferencesPath {
    return (Join-Path (Join-Path (Join-Path (Get-ClaudeHookUserHome) '.claude') 'sdd') 'preferences.json')
}

function Read-ClaudePreferences {
    <#
    .SYNOPSIS
      Preferences with defaults applied; unknown keys in the file are kept.
    #>
    $values = [ordered]@{}
    foreach ($key in $script:ToolkitPreferencesDefaults.Keys) {
        $values[$key] = $script:ToolkitPreferencesDefaults[$key]
    }

    $path = Get-ClaudePreferencesPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [PSCustomObject]@{ Values = $values; Readable = $true; Path = $path }
    }

    try {
        $parsed = [System.IO.File]::ReadAllText($path) | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return [PSCustomObject]@{ Values = $values; Readable = $false; Path = $path }
    }

    if ($null -eq $parsed -or -not ($parsed -is [PSCustomObject])) {
        return [PSCustomObject]@{ Values = $values; Readable = $false; Path = $path }
    }

    foreach ($property in $parsed.PSObject.Properties) {
        $values[$property.Name] = $property.Value
    }
    return [PSCustomObject]@{ Values = $values; Readable = $true; Path = $path }
}

function Write-ClaudePreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Values
    )

    $path = Get-ClaudePreferencesPath
    $directory = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $json = $Values | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding $false))
}

function Format-ClaudePreferencesStateLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $Preferences
    )

    if (-not $Preferences.Readable) {
        return ('[Toolkit] Preferences file is unreadable ({0}); defaults apply until it is fixed.' -f $Preferences.Path)
    }

    $values = $Preferences.Values
    $caveman = 'off'
    if ([bool]$values['caveman_mode']) {
        $caveman = 'on'
    }
    $orchestrator = [string]$values['orchestrator_mode']
    if ([string]::IsNullOrWhiteSpace($orchestrator)) {
        $orchestrator = 'missing'
    }
    return ('[Toolkit] orchestrator_mode={0}; caveman={1} (level={2}).' -f $orchestrator, $caveman, $values['caveman_level'])
}

