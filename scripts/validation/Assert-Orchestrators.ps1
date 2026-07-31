#Requires -Version 5.1
# Tests:
#   Should_FailSync_When_AgentMissing
#   Should_FailSync_When_AgentUnknown
#   Should_SyncAndValidate_When_AgentImplemented
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'
$syncScript = Join-Path $scriptsRoot 'sync-agent.ps1'
$validateScript = Join-Path $scriptsRoot 'validate-agent.ps1'

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

function Invoke-ScriptCapture {
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter(Mandatory = $false)][object[]] $ArgumentList = @()
    )
    $output = & pwsh -NoProfile -File $ScriptPath @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-OrchestratorsPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
. $repoRootScript | Out-Null

$required = @($syncScript, $validateScript)
foreach ($requiredPath in $required) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail -TestName 'Assert-OrchestratorsPreconditions' -Reason ("missing {0}" -f $requiredPath)
    }
}

# --- Should_FailSync_When_AgentMissing ---
$missingName = 'Should_FailSync_When_AgentMissing'
$missing = Invoke-ScriptCapture -ScriptPath $syncScript -ArgumentList @()
if ($missing.ExitCode -eq 0) {
    Write-Fail -TestName $missingName -Reason 'expected non-zero exit when -Agent is omitted'
}
if ($missing.Output -notmatch 'Agent is required' -and $missing.Output -notmatch '-Agent') {
    Write-Fail -TestName $missingName -Reason ("expected Agent required message, got: {0}" -f $missing.Output.Trim())
}
if ($missing.Output -notmatch 'cursor') {
    Write-Fail -TestName $missingName -Reason 'expected available agent ids (e.g. cursor) in message'
}
Write-Pass -TestName $missingName

# --- Should_FailSync_When_AgentUnknown ---
$unknownName = 'Should_FailSync_When_AgentUnknown'
$unknown = Invoke-ScriptCapture -ScriptPath $syncScript -ArgumentList @('-Agent', 'not-a-real-agent')
if ($unknown.ExitCode -eq 0) {
    Write-Fail -TestName $unknownName -Reason 'expected non-zero exit for unknown agent'
}
if ($unknown.Output -notmatch 'Unknown agent' -and $unknown.Output -notmatch 'not-a-real-agent') {
    Write-Fail -TestName $unknownName -Reason ("expected unknown-agent message, got: {0}" -f $unknown.Output.Trim())
}
if ($unknown.Output -notmatch 'cursor') {
    Write-Fail -TestName $unknownName -Reason 'expected valid agent ids listed'
}
Write-Pass -TestName $unknownName

# --- Should_SyncAndValidate_When_AgentImplemented ---
$implName = 'Should_SyncAndValidate_When_AgentImplemented'
$sync = Invoke-ScriptCapture -ScriptPath $syncScript -ArgumentList @('-Agent', 'cursor')
if ($sync.ExitCode -ne 0) {
    Write-Fail -TestName $implName -Reason ("expected sync cursor to succeed on default fixture; exit={0}; output={1}" -f $sync.ExitCode, $sync.Output.Trim())
}
if ($sync.Output -notmatch 'Sync completed') {
    Write-Fail -TestName $implName -Reason ("expected Sync completed marker, got: {0}" -f $sync.Output.Trim())
}

$validate = Invoke-ScriptCapture -ScriptPath $validateScript -ArgumentList @('-Agent', 'cursor', '-Quiet')
if ($validate.ExitCode -ne 0) {
    Write-Fail -TestName $implName -Reason ("expected validate cursor to pass; exit={0}; output={1}" -f $validate.ExitCode, $validate.Output.Trim())
}
if ($validate.Output -notmatch 'Core validation PASSED' -and $validate.Output -notmatch 'core PASS') {
    Write-Fail -TestName $implName -Reason ("expected core PASS marker, got: {0}" -f $validate.Output.Trim())
}
if ($validate.Output -notmatch 'Adapter smoke: PASS' -and $validate.Output -notmatch 'Validate agent completed') {
    Write-Fail -TestName $implName -Reason ("expected adapter smoke pass, got: {0}" -f $validate.Output.Trim())
}
Write-Pass -TestName $implName

Write-Host 'Assert-Orchestrators: ALL PASS'
exit 0