#Requires -Version 5.1
# Tests:
#   Should_ReplaceStaleToolkitHookAndPreserveAlien_When_CursorHooksMerged
#   Should_NotDuplicateToolkitHook_When_CursorHooksMergedTwice
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-CursorHooksMergePreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$cursorModulePath = Join-Path $repoRoot 'adapters\cursor\CursorAdapter.ps1'
$toolkitHooksPath = Join-Path $repoRoot 'adapters\cursor\assets\hooks\hooks.json'

if (-not (Test-Path -LiteralPath $cursorModulePath)) {
    Write-Fail -TestName 'Assert-CursorHooksMergePreconditions' -Reason ("missing Cursor module: {0}" -f $cursorModulePath)
}
if (-not (Test-Path -LiteralPath $toolkitHooksPath)) {
    Write-Fail -TestName 'Assert-CursorHooksMergePreconditions' -Reason ("missing toolkit hooks.json: {0}" -f $toolkitHooksPath)
}

. $cursorModulePath

$alienHookMarker = "powershell -NoProfile -Command Write-Output 'cursor-alien-hook-marker'"
$staleBeforeSubmit = 'powershell -NoProfile -File ./hooks/context-before-prompt.ps1 -StaleToolkitFlag'
$hooksMergeHarness = Join-Path $repoRoot 'scripts\validation\fixtures\cursor-hooks-merge-harness'

function Reset-HooksMergeHarness {
    if (Test-Path -LiteralPath $hooksMergeHarness) {
        Remove-Item -LiteralPath $hooksMergeHarness -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path $hooksMergeHarness -Force
    return (Join-Path $hooksMergeHarness 'hooks.json')
}

# --- Should_ReplaceStaleToolkitHookAndPreserveAlien_When_CursorHooksMerged ---
$hooksUpsertName = 'Should_ReplaceStaleToolkitHookAndPreserveAlien_When_CursorHooksMerged'
$userHooksPath = Reset-HooksMergeHarness
$staleSeed = @{
    version = 1
    hooks   = @{
        beforeSubmitPrompt = @(
            @{ command = $alienHookMarker },
            @{ command = $staleBeforeSubmit }
        )
        afterFileEdit      = @(
            @{ command = 'powershell -NoProfile -File ./hooks/plan-after-edit.ps1 -Old' }
        )
        preCompact         = @(
            @{ command = 'powershell -NoProfile -File ./hooks/context-pre-compact.ps1 -Old' }
        )
        sessionStart       = @(
            @{ command = "powershell -NoProfile -Command Write-Output 'alien-session-start'" }
        )
    }
} | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($userHooksPath, $staleSeed, (Get-Utf8NoBomEncoding))

$mergeResult = Merge-CursorHooksJsonContent -ToolkitHooksPath $toolkitHooksPath -UserHooksPath $userHooksPath
if ($null -eq $mergeResult -or $null -eq $mergeResult.Payload) {
    Write-Fail -TestName $hooksUpsertName -Reason 'Merge-CursorHooksJsonContent returned null payload'
}
if ($mergeResult.Changed -ne $true) {
    Write-Fail -TestName $hooksUpsertName -Reason 'expected Changed=true when replacing stale toolkit hook commands'
}

$mergedHooks = $mergeResult.Payload.hooks
$beforeSubmit = @($mergedHooks['beforeSubmitPrompt'])
if ($beforeSubmit.Count -lt 2) {
    Write-Fail -TestName $hooksUpsertName -Reason ("beforeSubmitPrompt must keep toolkit + alien; got {0} entr(y/ies)" -f $beforeSubmit.Count)
}
$beforeSubmitCommands = @($beforeSubmit | ForEach-Object { [string]$_.command })
if ($beforeSubmitCommands[0] -notmatch '(?i)[\\/]hooks[\\/]context-before-prompt\.ps1') {
    Write-Fail -TestName $hooksUpsertName -Reason 'toolkit beforeSubmitPrompt entry must be prepended first'
}
if ($beforeSubmitCommands[0] -match '(?i)-StaleToolkitFlag') {
    Write-Fail -TestName $hooksUpsertName -Reason 'stale toolkit beforeSubmitPrompt command must be replaced'
}
if (-not ($beforeSubmitCommands -contains $alienHookMarker)) {
    Write-Fail -TestName $hooksUpsertName -Reason 'alien beforeSubmitPrompt command must be preserved'
}
if ($beforeSubmitCommands -contains $staleBeforeSubmit) {
    Write-Fail -TestName $hooksUpsertName -Reason 'stale toolkit beforeSubmitPrompt command must not remain'
}

foreach ($eventName in @('afterFileEdit', 'preCompact')) {
    $entries = @($mergedHooks[$eventName])
    if ($entries.Count -lt 1) {
        Write-Fail -TestName $hooksUpsertName -Reason ("managed event missing after merge: {0}" -f $eventName)
    }
    $cmds = @($entries | ForEach-Object { [string]$_.command })
    if ($cmds | Where-Object { $_ -match '(?i)-Old\b' }) {
        Write-Fail -TestName $hooksUpsertName -Reason ("stale -Old toolkit command must not remain on {0}" -f $eventName)
    }
}

$sessionEntries = @($mergedHooks['sessionStart'])
if ($sessionEntries.Count -ne 1) {
    Write-Fail -TestName $hooksUpsertName -Reason 'alien-only sessionStart event must remain intact'
}
if ([string]$sessionEntries[0].command -notmatch 'alien-session-start') {
    Write-Fail -TestName $hooksUpsertName -Reason 'alien sessionStart command must be preserved'
}

Write-Pass -TestName $hooksUpsertName

# --- Should_NotDuplicateToolkitHook_When_CursorHooksMergedTwice ---
$idempotentName = 'Should_NotDuplicateToolkitHook_When_CursorHooksMergedTwice'
$jsonAfter = ($mergeResult.Payload | ConvertTo-Json -Depth 8)
[System.IO.File]::WriteAllText($userHooksPath, $jsonAfter, (Get-Utf8NoBomEncoding))
$mergeAgain = Merge-CursorHooksJsonContent -ToolkitHooksPath $toolkitHooksPath -UserHooksPath $userHooksPath
$beforeAgain = @($mergeAgain.Payload.hooks['beforeSubmitPrompt'])
$beforeAgainCommands = @($beforeAgain | ForEach-Object { [string]$_.command })
$toolkitBeforeCount = @($beforeAgainCommands | Where-Object { $_ -match '(?i)[\\/]hooks[\\/]context-before-prompt\.ps1' }).Count
if ($toolkitBeforeCount -ne 1) {
    Write-Fail -TestName $idempotentName -Reason ("re-merge must not duplicate toolkit beforeSubmitPrompt; got {0}" -f $toolkitBeforeCount)
}
if (-not ($beforeAgainCommands -contains $alienHookMarker)) {
    Write-Fail -TestName $idempotentName -Reason 'alien beforeSubmitPrompt must survive re-merge'
}

if (Test-Path -LiteralPath $hooksMergeHarness) {
    Remove-Item -LiteralPath $hooksMergeHarness -Recurse -Force
}

Write-Pass -TestName $idempotentName

Write-Host 'Assert-CursorHooksMerge: ALL PASS'
exit 0
