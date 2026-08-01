#Requires -Version 5.1
# Tests:
#   Should_NotOverwriteOperatorManifest_When_GetSddRootPrepareTwice
#   Should_PreserveSessions_When_GetSddRootPrepareTwice
#   Should_NotOverwriteOperatorManifest_When_SyncPrepareTwice
#
# SDD runtime contract: Get-SddRoot -Prepare seeds manifest only when absent and
# never clears sessions/. Uses the Cursor fixture InstallRoot shape.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'
$syncAgentScript = Join-Path $scriptsRoot 'sync-agent.ps1'

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

foreach ($required in @($repoRootScript, $syncAgentScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-SddRootPrepareIdempotentPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$cursorModulePath = Join-Path $repoRoot 'adapters\cursor\CursorAdapter.ps1'
$workInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\sdd-prepare-idempotent-work'
$sddRoot = Join-Path $workInstallRoot 'sdd'
$sessionsPath = Join-Path $sddRoot 'sessions'
$manifestPath = Join-Path $sddRoot 'manifest.json'
$sessionProbeFileName = 'prepare-idempotent-probe.json'
$sessionProbeMarker = 'sdd-session-must-survive-prepare-twice'
$operatorManifestKey = 'operator_note'
$operatorManifestValue = 'must-not-be-overwritten-by-prepare'

if (-not (Test-Path -LiteralPath $cursorModulePath)) {
    Write-Fail -TestName 'Assert-SddRootPrepareIdempotentPreconditions' -Reason ("missing Cursor module: {0}" -f $cursorModulePath)
}

. $cursorModulePath

function Initialize-SddPrepareWorkRoot {
    if (Test-Path -LiteralPath $workInstallRoot) {
        Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null
}

function Write-OperatorManifest {
    $payload = @{
        schema_version = 2
        repositories   = @{}
        $operatorManifestKey = $operatorManifestValue
    } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($manifestPath, $payload, (Get-Utf8NoBomEncoding))
}

function Assert-OperatorManifestUnchanged {
    param([Parameter(Mandatory = $true)][string] $TestName)

    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Write-Fail -TestName $TestName -Reason 'operator manifest must remain present after second prepare'
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($null -eq $manifest.$operatorManifestKey -or [string]$manifest.$operatorManifestKey -ne $operatorManifestValue) {
        Write-Fail -TestName $TestName -Reason 'second Get-SddRoot -Prepare must not overwrite operator manifest content'
    }
}

# --- Should_NotOverwriteOperatorManifest_When_GetSddRootPrepareTwice ---
$prepareTwiceTest = 'Should_NotOverwriteOperatorManifest_When_GetSddRootPrepareTwice'

Initialize-SddPrepareWorkRoot

$prepareFirst = Get-SddRoot -InstallRoot $workInstallRoot -Prepare
if ($null -eq $prepareFirst -or $prepareFirst.Success -ne $true -or $prepareFirst.Prepared -ne $true) {
    Write-Fail -TestName $prepareTwiceTest -Reason ("first Get-SddRoot -Prepare failed: {0}" -f $(if ($null -eq $prepareFirst) { 'null' } else { $prepareFirst.Message }))
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Fail -TestName $prepareTwiceTest -Reason 'first prepare must seed manifest.json when absent'
}

Write-OperatorManifest

$prepareSecond = Get-SddRoot -InstallRoot $workInstallRoot -Prepare
if ($null -eq $prepareSecond -or $prepareSecond.Success -ne $true -or $prepareSecond.Prepared -ne $true) {
    Write-Fail -TestName $prepareTwiceTest -Reason ("second Get-SddRoot -Prepare failed: {0}" -f $(if ($null -eq $prepareSecond) { 'null' } else { $prepareSecond.Message }))
}

Assert-OperatorManifestUnchanged -TestName $prepareTwiceTest

Write-Pass -TestName $prepareTwiceTest

# --- Should_PreserveSessions_When_GetSddRootPrepareTwice ---
$sessionsTest = 'Should_PreserveSessions_When_GetSddRootPrepareTwice'

Initialize-SddPrepareWorkRoot

$prepareSeed = Get-SddRoot -InstallRoot $workInstallRoot -Prepare
if ($null -eq $prepareSeed -or $prepareSeed.Success -ne $true) {
    Write-Fail -TestName $sessionsTest -Reason ("initial Get-SddRoot -Prepare failed: {0}" -f $(if ($null -eq $prepareSeed) { 'null' } else { $prepareSeed.Message }))
}

$sessionProbePath = Join-Path $sessionsPath $sessionProbeFileName
Set-Content -LiteralPath $sessionProbePath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionProbeMarker) -Encoding UTF8
Write-OperatorManifest

$prepareAgain = Get-SddRoot -InstallRoot $workInstallRoot -Prepare
if ($null -eq $prepareAgain -or $prepareAgain.Success -ne $true) {
    Write-Fail -TestName $sessionsTest -Reason ("second Get-SddRoot -Prepare failed: {0}" -f $(if ($null -eq $prepareAgain) { 'null' } else { $prepareAgain.Message }))
}

if (-not (Test-Path -LiteralPath $sessionProbePath)) {
    Write-Fail -TestName $sessionsTest -Reason 'sessions/ probe file must survive second prepare'
}
$sessionProbeText = [System.IO.File]::ReadAllText($sessionProbePath)
if ($sessionProbeText -notmatch [regex]::Escape($sessionProbeMarker)) {
    Write-Fail -TestName $sessionsTest -Reason 'sessions/ probe content must be preserved across prepare'
}

Assert-OperatorManifestUnchanged -TestName $sessionsTest

Write-Pass -TestName $sessionsTest

# --- Should_NotOverwriteOperatorManifest_When_SyncPrepareTwice ---
$syncTwiceTest = 'Should_NotOverwriteOperatorManifest_When_SyncPrepareTwice'

Initialize-SddPrepareWorkRoot

$syncLines = @(& $syncAgentScript -Agent cursor -InstallRoot $workInstallRoot *>&1 | ForEach-Object { "$_" })
$syncExit = $LASTEXITCODE
if ($null -eq $syncExit) { $syncExit = 0 }
if ($syncExit -ne 0) {
    Write-Fail -TestName $syncTwiceTest -Reason ("first sync-agent prepare failed (exit {0}): {1}" -f $syncExit, ($syncLines -join [Environment]::NewLine).Trim())
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Fail -TestName $syncTwiceTest -Reason 'first sync must seed manifest.json when absent'
}

Write-OperatorManifest
Set-Content -LiteralPath $sessionProbePath -Value ("{{ `"marker`": `"{0}`" }}`n" -f $sessionProbeMarker) -Encoding UTF8

$syncLines2 = @(& $syncAgentScript -Agent cursor -InstallRoot $workInstallRoot *>&1 | ForEach-Object { "$_" })
$syncExit2 = $LASTEXITCODE
if ($null -eq $syncExit2) { $syncExit2 = 0 }
if ($syncExit2 -ne 0) {
    Write-Fail -TestName $syncTwiceTest -Reason ("second sync-agent prepare failed (exit {0}): {1}" -f $syncExit2, ($syncLines2 -join [Environment]::NewLine).Trim())
}

Assert-OperatorManifestUnchanged -TestName $syncTwiceTest
if (-not (Test-Path -LiteralPath $sessionProbePath)) {
    Write-Fail -TestName $syncTwiceTest -Reason 'sessions/ probe must survive second sync prepare'
}

if (Test-Path -LiteralPath $workInstallRoot) {
    Remove-Item -LiteralPath $workInstallRoot -Recurse -Force
}

Write-Pass -TestName $syncTwiceTest

Write-Host 'Assert-SddRootPrepareIdempotent: ALL PASS'
exit 0
