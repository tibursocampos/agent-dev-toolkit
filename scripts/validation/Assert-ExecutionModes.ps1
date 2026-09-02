#Requires -Version 5.1
# Tests:
#   Should_Pass_When_ExecutionModesRefPresent
#   Should_Pass_When_OrchestrateDevelopWiresExecutionModes
#   Should_Fail_When_SerialModeRejectsParallelSpawn
#   Should_Pass_When_ModeRejectWritesAudit
#   Should_Pass_When_AllowedSpawnClaimsLedger
#
# REQ-003 / CA3: execution modes honored; violations not silent; ledger integrated.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

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

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-ExecutionModesPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-ExecutionModesPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$modesRefRel = $script:ToolkitConstant.ExecutionModesReferenceRelativePath
$skillIndexRel = $script:ToolkitConstant.ExecutionModesSkillIndexRelativePath
$skillBodyRel = $script:ToolkitConstant.ExecutionModesSkillBodyRelativePath
$gateScriptRel = $script:ToolkitConstant.InvokeExecutionModeGateScriptRelativePath
$claimScriptRel = $script:ToolkitConstant.InvokePlanLedgerClaimScriptRelativePath

$modesRefPath = Join-Path $repoRoot ($modesRefRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$skillIndexPath = Join-Path $repoRoot ($skillIndexRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$skillBodyPath = Join-Path $repoRoot ($skillBodyRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$gateScriptPath = Join-Path $repoRoot ($gateScriptRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$claimScriptPath = Join-Path $repoRoot ($claimScriptRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $modesRefPath)) {
    Write-Fail -TestName 'Should_Pass_When_ExecutionModesRefPresent' -Reason ("missing {0}" -f $modesRefRel)
}
if (-not (Test-Path -LiteralPath $gateScriptPath)) {
    Write-Fail -TestName 'Should_Pass_When_ExecutionModesRefPresent' -Reason ("missing gate {0}" -f $gateScriptRel)
}
if (-not (Test-Path -LiteralPath $claimScriptPath)) {
    Write-Fail -TestName 'Should_Pass_When_ExecutionModesRefPresent' -Reason ("missing ledger claim {0}" -f $claimScriptRel)
}

$modesText = Get-Content -LiteralPath $modesRefPath -Raw -Encoding UTF8
$requiredMarkers = @(
    'REQ-003',
    'CA3',
    'serial',
    'parallel',
    'manual',
    'mode_parallel_forbidden',
    'PLAN-LEDGER',
    'Invoke-ExecutionModeGate',
    'Assert-ExecutionModes',
    'SR-NO-FULL-DUMP',
    'SUBAGENT-MODEL'
)
foreach ($marker in $requiredMarkers) {
    if ($modesText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_ExecutionModesRefPresent' -Reason ("execution-modes.md missing marker '{0}'" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_ExecutionModesRefPresent'

if (-not (Test-Path -LiteralPath $skillIndexPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDevelopWiresExecutionModes' -Reason ("missing {0}" -f $skillIndexRel)
}
if (-not (Test-Path -LiteralPath $skillBodyPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDevelopWiresExecutionModes' -Reason ("missing {0}" -f $skillBodyRel)
}

$skillIndexText = Get-Content -LiteralPath $skillIndexPath -Raw -Encoding UTF8
$skillBodyText = Get-Content -LiteralPath $skillBodyPath -Raw -Encoding UTF8

if ($skillIndexText -notmatch 'execution-modes\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDevelopWiresExecutionModes' -Reason 'reference.md must index execution-modes.md'
}
if ($skillBodyText -notmatch 'execution-modes\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDevelopWiresExecutionModes' -Reason 'SKILL.md must lazy-load execution-modes.md'
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateDevelopWiresExecutionModes'

$fixturePlanRel = $script:ToolkitConstant.PlanLedgerFixturePlanRelativePath
$fixturePlanPath = Join-Path $repoRoot ($fixturePlanRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $fixturePlanPath)) {
    Write-Fail -TestName 'Should_Fail_When_SerialModeRejectsParallelSpawn' -Reason ("missing fixture PLAN {0}" -f $fixturePlanRel)
}

$workRoot = Join-Path $env:TEMP ('adt-execution-modes-{0}' -f [Guid]::NewGuid().ToString('N'))
$sessionsRoot = Join-Path $workRoot 'sessions'
New-Item -ItemType Directory -Path $sessionsRoot -Force | Out-Null

try {
    $rejectOut = & $gateScriptPath -Mode serial -Intent parallel-spawn -PlanPath $fixturePlanPath -Step 3 -Holder 'mode-test' -RepoPath $repoRoot -SessionsRoot $sessionsRoot 2>&1 | Out-String
    $rejectCode = $LASTEXITCODE
    if ($null -eq $rejectCode) { $rejectCode = 0 }
    $expectedReject = [int]$script:ToolkitConstant.ExecutionModeExitRejected
    if ($rejectCode -ne $expectedReject) {
        Write-Fail -TestName 'Should_Fail_When_SerialModeRejectsParallelSpawn' -Reason ("expected exit {0}, got {1}: {2}" -f $expectedReject, $rejectCode, $rejectOut)
    }
    $reasonParallel = [string]$script:ToolkitConstant.ExecutionModeReasonParallelForbidden
    if ($rejectOut -notmatch [regex]::Escape($reasonParallel)) {
        Write-Fail -TestName 'Should_Fail_When_SerialModeRejectsParallelSpawn' -Reason ("output must include {0}" -f $reasonParallel)
    }
    Write-Pass -TestName 'Should_Fail_When_SerialModeRejectsParallelSpawn'

    $auditFiles = @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -Filter $script:ToolkitConstant.ExecutionModeAuditFileName -ErrorAction SilentlyContinue)
    if ($auditFiles.Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_ModeRejectWritesAudit' -Reason 'expected execution-mode.audit.jsonl after reject'
    }
    $auditText = Get-Content -LiteralPath $auditFiles[0].FullName -Raw -Encoding UTF8
    if ($auditText -notmatch [regex]::Escape($script:ToolkitConstant.ExecutionModeEventRejected)) {
        Write-Fail -TestName 'Should_Pass_When_ModeRejectWritesAudit' -Reason 'audit must record mode_rejected'
    }
    if ($auditText -notmatch [regex]::Escape($reasonParallel)) {
        Write-Fail -TestName 'Should_Pass_When_ModeRejectWritesAudit' -Reason 'audit must record mode_parallel_forbidden'
    }
    Write-Pass -TestName 'Should_Pass_When_ModeRejectWritesAudit'

    $holder = [string]$script:ToolkitConstant.PlanLedgerFixtureHolderA
    $stepNumber = [int]$script:ToolkitConstant.PlanLedgerFixtureStep
    $allowOut = & $gateScriptPath -Mode serial -Intent serial-spawn -PlanPath $fixturePlanPath -Step $stepNumber -Holder $holder -RepoPath $repoRoot -SessionsRoot $sessionsRoot 2>&1 | Out-String
    $allowCode = $LASTEXITCODE
    if ($null -eq $allowCode) { $allowCode = 0 }
    if ($allowCode -ne [int]$script:ToolkitConstant.ExecutionModeExitOk) {
        Write-Fail -TestName 'Should_Pass_When_AllowedSpawnClaimsLedger' -Reason ("expected exit 0, got {0}: {1}" -f $allowCode, $allowOut)
    }
    if ($allowOut -notmatch 'allowed') {
        Write-Fail -TestName 'Should_Pass_When_AllowedSpawnClaimsLedger' -Reason 'allowed gate output must include status allowed'
    }

    $claimFiles = @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -Filter '*.claim.json' -ErrorAction SilentlyContinue)
    if ($claimFiles.Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_AllowedSpawnClaimsLedger' -Reason 'allowed serial-spawn must create PLAN-LEDGER claim file'
    }
    $claimText = Get-Content -LiteralPath $claimFiles[0].FullName -Raw -Encoding UTF8
    if ($claimText -notmatch [regex]::Escape($holder)) {
        Write-Fail -TestName 'Should_Pass_When_AllowedSpawnClaimsLedger' -Reason 'claim file must record holder'
    }
    Write-Pass -TestName 'Should_Pass_When_AllowedSpawnClaimsLedger'
}
finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Assert-ExecutionModes: ALL PASS'
exit 0
