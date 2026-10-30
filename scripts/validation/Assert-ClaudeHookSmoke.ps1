#Requires -Version 5.1
# Tests:
#   Should_ReturnFailOpenJson_When_ClaudeHookReceivesNoPayload
#   Should_UpdatePreferencesAndReportState_When_ClaudeHookCommandsSent
#   Should_TrackSkillInvocationForSlashForm_When_ClaudeTrackHookRuns
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
. (Join-Path $scriptsRoot '_lib\New-ToolkitWorkRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$hooksRoot = Join-Path $repoRoot 'adapters\claude\assets\hooks'

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }

function Invoke-HookScript {
    param([string] $ScriptName, [string] $Payload)
    $output = $Payload | & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $hooksRoot $ScriptName)
    if ($LASTEXITCODE -ne 0) { throw ("{0} exited {1}" -f $ScriptName, $LASTEXITCODE) }
    return (($output | Out-String).Trim())
}

$previousUserProfile = $env:USERPROFILE
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $fakeHome = Join-Path $work 'home'
    New-Item -ItemType Directory -Path $fakeHome -Force | Out-Null
    $env:USERPROFILE = $fakeHome
    $prefsPath = Join-Path (Join-Path $fakeHome '.claude\sdd') 'preferences.json'
    $statePath = Join-Path (Join-Path $fakeHome '.claude\hooks-state') 'sdd-session.json'

    $n = 'Should_ReturnFailOpenJson_When_ClaudeHookReceivesNoPayload'
    foreach ($script in @('session-start-context.ps1', 'preferences-command.ps1', 'track-sdd-invocation.ps1')) {
        $out = Invoke-HookScript -ScriptName $script -Payload ''
        $parsed = $out | ConvertFrom-Json
        if ($parsed.continue -ne $true -and $null -eq $parsed.hookSpecificOutput) { Write-Fail $n "$script did not return a fail-open JSON" }
    }
    $out = Invoke-HookScript -ScriptName 'preferences-command.ps1' -Payload 'not json'
    if (($out | ConvertFrom-Json).continue -ne $true) { Write-Fail $n 'malformed payload must continue' }
    Write-Pass $n

    $n = 'Should_UpdatePreferencesAndReportState_When_ClaudeHookCommandsSent'
    $absent = (Invoke-HookScript -ScriptName 'session-start-context.ps1' -Payload '{"hook_event_name":"SessionStart","source":"startup"}' | ConvertFrom-Json).hookSpecificOutput
    if ($absent.additionalContext -notmatch 'orchestrator_mode=missing') { Write-Fail $n 'absent preferences must report missing, not a hook-side default' }

    . (Join-Path $scriptsRoot '_lib\Initialize-SddPreferences.ps1')
    $null = Invoke-ToolkitEnsurePreferences -SddRoot (Split-Path -Parent $prefsPath)
    $start = (Invoke-HookScript -ScriptName 'session-start-context.ps1' -Payload '{"hook_event_name":"SessionStart","source":"startup"}' | ConvertFrom-Json).hookSpecificOutput
    if ($start.hookEventName -ne 'SessionStart' -or $start.additionalContext -notmatch 'orchestrator_mode=adaptive') { Write-Fail $n 'SessionStart must report the seeded default state' }

    $adaptive = (Invoke-HookScript -ScriptName 'preferences-command.ps1' -Payload '{"prompt":"orchestrator adaptive"}' | ConvertFrom-Json).hookSpecificOutput
    if ($adaptive.hookEventName -ne 'UserPromptSubmit' -or $adaptive.additionalContext -notmatch 'adaptive') { Write-Fail $n 'orchestrator adaptive must confirm' }
    $prefs = [System.IO.File]::ReadAllText($prefsPath) | ConvertFrom-Json
    if ($prefs.orchestrator_mode -ne 'adaptive') { Write-Fail $n 'orchestrator_mode must persist as adaptive' }

    $null = Invoke-HookScript -ScriptName 'preferences-command.ps1' -Payload '{"prompt":"caveman lite"}'
    $prefs = [System.IO.File]::ReadAllText($prefsPath) | ConvertFrom-Json
    if ($prefs.caveman_level -ne 'lite' -or $prefs.caveman_mode -ne $true) { Write-Fail $n 'caveman lite must set level and keep mode on' }
    if ($prefs.orchestrator_mode -ne 'adaptive') { Write-Fail $n 'unrelated preference must be preserved' }

    $before = [System.IO.File]::ReadAllText($prefsPath)
    $plain = Invoke-HookScript -ScriptName 'preferences-command.ps1' -Payload '{"prompt":"hello there"}'
    if (($plain | ConvertFrom-Json).continue -ne $true) { Write-Fail $n 'plain prompt must continue' }
    if ([System.IO.File]::ReadAllText($prefsPath) -ne $before) { Write-Fail $n 'plain prompt must not rewrite preferences' }

    [System.IO.File]::WriteAllText($prefsPath, '{ broken', (New-Object System.Text.UTF8Encoding $false))
    $null = Invoke-HookScript -ScriptName 'preferences-command.ps1' -Payload '{"prompt":"caveman full"}'
    if ([System.IO.File]::ReadAllText($prefsPath) -ne '{ broken') { Write-Fail $n 'unreadable preferences must not be overwritten' }
    Write-Pass $n

    $n = 'Should_TrackSkillInvocationForSlashForm_When_ClaudeTrackHookRuns'
    $null = Invoke-HookScript -ScriptName 'track-sdd-invocation.ps1' -Payload '{"prompt":"/sdd-develop features/001/PLAN.md step 2"}'
    if (([System.IO.File]::ReadAllText($statePath) | ConvertFrom-Json).last_skill -ne 'sdd-develop') { Write-Fail $n 'slash form must record sdd-develop' }
    $null = Invoke-HookScript -ScriptName 'track-sdd-invocation.ps1' -Payload '{"prompt":"use skill commit"}'
    if (([System.IO.File]::ReadAllText($statePath) | ConvertFrom-Json).last_skill -ne 'commit') { Write-Fail $n 'use skill form must record commit' }
    $null = Invoke-HookScript -ScriptName 'track-sdd-invocation.ps1' -Payload '{"prompt":"/unknown-thing"}'
    if (([System.IO.File]::ReadAllText($statePath) | ConvertFrom-Json).last_skill -ne 'commit') { Write-Fail $n 'unknown slash command must not change state' }
    Write-Pass $n
}
finally {
    $env:USERPROFILE = $previousUserProfile
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-ClaudeHookSmoke: ALL PASS'
exit 0
