#Requires -Version 5.1
# Tests:
#   Should_Pass_When_PlanLedgerContractPresent
#   Should_Pass_When_SddPlanWiresPlanLedger
#   Should_Pass_When_FirstClaimSucceeds
#   Should_Fail_When_SecondClaimSameStep
#   Should_Pass_When_AuditTrailRecordsRejection
#
# REQ-002 / CA2: PLAN-LEDGER atomic claim; double-claim fails audibly.
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
    Write-Fail -TestName 'Assert-PlanLedgerContractPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-PlanLedgerContractPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$contractRel = $script:ToolkitConstant.PlanLedgerContractRelativePath
$skillRefRel = $script:ToolkitConstant.PlanLedgerSddPlanReferenceRelativePath
$claimScriptRel = $script:ToolkitConstant.InvokePlanLedgerClaimScriptRelativePath
$skillIndexRel = $script:ToolkitConstant.PlanLedgerSddPlanIndexRelativePath
$skillBodyRel = $script:ToolkitConstant.PlanLedgerSddPlanSkillRelativePath

$contractPath = Join-Path $repoRoot ($contractRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$skillRefPath = Join-Path $repoRoot ($skillRefRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$claimScriptPath = Join-Path $repoRoot ($claimScriptRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$skillIndexPath = Join-Path $repoRoot ($skillIndexRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$skillBodyPath = Join-Path $repoRoot ($skillBodyRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_PlanLedgerContractPresent' -Reason ("missing contract {0}" -f $contractRel)
}
if (-not (Test-Path -LiteralPath $claimScriptPath)) {
    Write-Fail -TestName 'Should_Pass_When_PlanLedgerContractPresent' -Reason ("missing claim script {0}" -f $claimScriptRel)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
$requiredMarkers = @(
    'REQ-002',
    'CA2',
    'Assert-PlanLedgerContract',
    'Invoke-PlanLedgerClaim',
    'plan-ledger-claim/v1',
    'step_already_claimed',
    'CreateNew',
    'holder',
    'SR-NO-FULL-DUMP'
)
foreach ($marker in $requiredMarkers) {
    if ($contractText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_PlanLedgerContractPresent' -Reason ("contract missing marker '{0}'" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_PlanLedgerContractPresent'

if (-not (Test-Path -LiteralPath $skillRefPath)) {
    Write-Fail -TestName 'Should_Pass_When_SddPlanWiresPlanLedger' -Reason ("missing {0}" -f $skillRefRel)
}
if (-not (Test-Path -LiteralPath $skillIndexPath)) {
    Write-Fail -TestName 'Should_Pass_When_SddPlanWiresPlanLedger' -Reason ("missing {0}" -f $skillIndexRel)
}
if (-not (Test-Path -LiteralPath $skillBodyPath)) {
    Write-Fail -TestName 'Should_Pass_When_SddPlanWiresPlanLedger' -Reason ("missing {0}" -f $skillBodyRel)
}

$skillRefText = Get-Content -LiteralPath $skillRefPath -Raw -Encoding UTF8
$skillIndexText = Get-Content -LiteralPath $skillIndexPath -Raw -Encoding UTF8
$skillBodyText = Get-Content -LiteralPath $skillBodyPath -Raw -Encoding UTF8

if ($skillRefText -notmatch 'PLAN-LEDGER-CONTRACT') {
    Write-Fail -TestName 'Should_Pass_When_SddPlanWiresPlanLedger' -Reason 'plan-ledger.md must cite PLAN-LEDGER-CONTRACT'
}
if ($skillIndexText -notmatch 'plan-ledger\.md') {
    Write-Fail -TestName 'Should_Pass_When_SddPlanWiresPlanLedger' -Reason 'sdd-plan/reference.md must index plan-ledger.md'
}
if ($skillBodyText -notmatch 'PLAN-LEDGER-CONTRACT') {
    Write-Fail -TestName 'Should_Pass_When_SddPlanWiresPlanLedger' -Reason 'sdd-plan/SKILL.md must lazy-load PLAN-LEDGER-CONTRACT'
}
Write-Pass -TestName 'Should_Pass_When_SddPlanWiresPlanLedger'

$fixturePlanRel = $script:ToolkitConstant.PlanLedgerFixturePlanRelativePath
$fixturePlanPath = Join-Path $repoRoot ($fixturePlanRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $fixturePlanPath)) {
    Write-Fail -TestName 'Should_Pass_When_FirstClaimSucceeds' -Reason ("missing fixture PLAN {0}" -f $fixturePlanRel)
}

$workRoot = Join-Path $env:TEMP ('adt-plan-ledger-{0}' -f [Guid]::NewGuid().ToString('N'))
$sessionsRoot = Join-Path $workRoot 'sessions'
New-Item -ItemType Directory -Path $sessionsRoot -Force | Out-Null

$holderA = $script:ToolkitConstant.PlanLedgerFixtureHolderA
$holderB = $script:ToolkitConstant.PlanLedgerFixtureHolderB
$stepNumber = [int]$script:ToolkitConstant.PlanLedgerFixtureStep

try {
    $firstOut = & $claimScriptPath -Action claim -PlanPath $fixturePlanPath -Step $stepNumber -Holder $holderA -RepoPath $repoRoot -SessionsRoot $sessionsRoot 2>&1 | Out-String
    $firstCode = $LASTEXITCODE
    if ($null -eq $firstCode) { $firstCode = 0 }
    if ($firstCode -ne 0) {
        Write-Fail -TestName 'Should_Pass_When_FirstClaimSucceeds' -Reason ("first claim exit {0}: {1}" -f $firstCode, $firstOut)
    }
    if ($firstOut -notmatch [regex]::Escape($holderA)) {
        Write-Fail -TestName 'Should_Pass_When_FirstClaimSucceeds' -Reason 'first claim output must include holder A'
    }
    Write-Pass -TestName 'Should_Pass_When_FirstClaimSucceeds'

    $secondOut = & $claimScriptPath -Action claim -PlanPath $fixturePlanPath -Step $stepNumber -Holder $holderB -RepoPath $repoRoot -SessionsRoot $sessionsRoot 2>&1 | Out-String
    $secondCode = $LASTEXITCODE
    if ($null -eq $secondCode) { $secondCode = 0 }
    $expectedReject = [int]$script:ToolkitConstant.PlanLedgerExitClaimRejected
    if ($secondCode -ne $expectedReject) {
        Write-Fail -TestName 'Should_Fail_When_SecondClaimSameStep' -Reason ("expected exit {0}, got {1}: {2}" -f $expectedReject, $secondCode, $secondOut)
    }
    if ($secondOut -notmatch [regex]::Escape($script:ToolkitConstant.PlanLedgerReasonStepAlreadyClaimed) -and $secondOut -notmatch [regex]::Escape($holderA)) {
        Write-Fail -TestName 'Should_Fail_When_SecondClaimSameStep' -Reason 'second claim must mention existing holder or step_already_claimed'
    }
    Write-Pass -TestName 'Should_Fail_When_SecondClaimSameStep'

    $auditFiles = @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -Filter '*.audit.jsonl' -ErrorAction SilentlyContinue)
    if ($auditFiles.Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_AuditTrailRecordsRejection' -Reason 'expected at least one audit.jsonl after rejected claim'
    }
    $auditText = Get-Content -LiteralPath $auditFiles[0].FullName -Raw -Encoding UTF8
    if ($auditText -notmatch [regex]::Escape($script:ToolkitConstant.PlanLedgerEventClaimRejected)) {
        Write-Fail -TestName 'Should_Pass_When_AuditTrailRecordsRejection' -Reason 'audit must record claim_rejected'
    }
    if ($auditText -notmatch [regex]::Escape($holderB)) {
        Write-Fail -TestName 'Should_Pass_When_AuditTrailRecordsRejection' -Reason 'audit must record attempted_holder B'
    }
    if ($auditText -notmatch [regex]::Escape($holderA)) {
        Write-Fail -TestName 'Should_Pass_When_AuditTrailRecordsRejection' -Reason 'audit must record existing_holder A'
    }
    Write-Pass -TestName 'Should_Pass_When_AuditTrailRecordsRejection'
}
finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Assert-PlanLedgerContract: ALL PASS'
exit 0
