#Requires -Version 5.1
# Tests:
#   Should_ReleaseOnlyValidatedDoneReceipt_When_AllParentGatesPass
#   Should_Reject_When_ReceiptIsMissing
#   Should_Reject_When_ReceiptIsIncomplete
#   Should_Reject_When_ReceiptDoesNotMatchInvocation
#   Should_Reject_When_StatusIsUnknown
#   Should_NotRelease_When_StatusIsBlockedOrFailed
#   Should_Reject_When_ReceiptContainsUnknownFields
#   Should_Reject_When_FilesAreAbsolute_Traversing_Duplicated_Or_OutOfScope
#   Should_Reject_When_DoneTestsSummaryIsInvalidOrNotPassing
#   Should_EmitManualSddDevelopHandoff_When_O3CannotSpawn
#   Should_StopAndRequireAgentMode_When_PlanOrAskBlocksWrites
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$queuePath = Join-Path $repoRoot 'core\skills\orchestrate-develop\references\step-queue-spawn.md'
$planContractPath = Join-Path $repoRoot 'core\skills\orchestrate-develop\references\plan-contract.md'
$spawnContractPath = Join-Path $repoRoot 'core\skills\_shared\agents\SPAWN.md'
$executionModesPath = Join-Path $repoRoot 'core\skills\orchestrate-develop\references\execution-modes.md'
$registryPath = Join-Path $repoRoot 'adapters\registry.json'
$rosterPath = Join-Path $repoRoot 'core\skills\_shared\agents\ROSTER.md'
$matrixPath = Join-Path $repoRoot 'features\014-improve-and-fix-disagreements\US03\ANALYSIS\adapter-role-matrix.md'
if (-not (Test-Path -LiteralPath $queuePath) -or -not (Test-Path -LiteralPath $planContractPath) -or
    -not (Test-Path -LiteralPath $spawnContractPath) -or -not (Test-Path -LiteralPath $executionModesPath) -or
    -not (Test-Path -LiteralPath $registryPath) -or -not (Test-Path -LiteralPath $rosterPath) -or
    -not (Test-Path -LiteralPath $matrixPath)) {
    throw 'Required O3 receipt, fallback, registry, roster, or matrix artifacts are missing.'
}
$queueContract = Get-Content -LiteralPath $queuePath -Raw -Encoding UTF8
$planContract = Get-Content -LiteralPath $planContractPath -Raw -Encoding UTF8
$spawnContract = Get-Content -LiteralPath $spawnContractPath -Raw -Encoding UTF8
$executionModes = Get-Content -LiteralPath $executionModesPath -Raw -Encoding UTF8
foreach ($marker in @('positive numeric `step`', 'known terminal `status`', 'scoped `step_confirmed` and `tests_run`', 'Neither status releases dependencies')) {
    if (-not $queueContract.Contains($marker)) { throw "Queue contract is missing marker: $marker" }
}
foreach ($marker in @('`done`', '`blocked`', '`failed`', 'do not release dependencies', 'unknown status')) {
    if (-not $planContract.Contains($marker)) { throw "PLAN contract is missing marker: $marker" }
}
foreach ($marker in @('`subagents=none`', 'Manual `/sdd-develop - <portable-plan-path> - Step N` handoff', 'parent stops and does not implement')) {
    if (-not $spawnContract.Contains($marker)) { throw "SPAWN fallback contract is missing marker: $marker" }
}
$handoffPath = 'features/014-improve-and-fix-disagreements/US03/PLAN/PLAN_014_us03_fallback_receipts.md'
$handoffCommand = "/sdd-develop - $handoffPath - Step 3"
if (-not $executionModes.Contains('/sdd-develop - <portable-plan-path> - Step N') -or
    $handoffCommand -cne '/sdd-develop - features/014-improve-and-fix-disagreements/US03/PLAN/PLAN_014_us03_fallback_receipts.md - Step 3') {
    throw 'The manual handoff must resolve to this story PLAN and selected numeric step.'
}
Write-Host 'Should_EmitManualSddDevelopHandoff_When_O3CannotSpawn: PASS'

foreach ($marker in @('### Manual handoff and host-mode gate', 'Agent mode is required', 'stop without editing application files', 'do not imply that the step was started or completed')) {
    if (-not $executionModes.Contains($marker)) { throw "Execution mode fallback contract is missing marker: $marker" }
}
Write-Host 'Should_StopAndRequireAgentMode_When_PlanOrAskBlocksWrites: PASS'

$matrix = Get-Content -LiteralPath $matrixPath -Raw -Encoding UTF8
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$adapterIds = @($registry.agents | ForEach-Object { [string]$_.id })
if ($adapterIds.Count -ne 10) { throw "Expected ten declared adapters; found $($adapterIds.Count)." }
foreach ($adapterId in $adapterIds) {
    if (-not $matrix.Contains(('`' + $adapterId + '`'))) { throw "Matrix is missing adapter ID: $adapterId" }
}
$roleIds = @('repo_analyst', 'architect', 'security', 'database', 'qa_checklist')
$roster = Get-Content -LiteralPath $rosterPath -Raw -Encoding UTF8
foreach ($roleId in $roleIds) {
    if (-not $roster.Contains(('`' + $roleId + '`')) -or -not $matrix.Contains(('`' + $roleId + '`'))) {
        throw "Roster or matrix is missing role ID: $roleId"
    }
}
if (-not $matrix.Contains('Parent-only') -or -not $matrix.Contains('não afirma que os hosts foram executados') -or
    -not $matrix.Contains('nem que há paridade entre adapters') -or
    -not $matrix.Contains('não executado nem validado no host')) {
    throw 'Matrix must keep qa_checklist parent-only and distinguish declared capabilities from host execution evidence.'
}
foreach ($adapterId in $adapterIds) {
    $adapterLine = @($matrix -split "`r?`n" | Where-Object { $_.Contains(('`' + $adapterId + '`')) })
    if ($adapterLine.Count -ne 1 -or -not $adapterLine[0].Contains('Declarado;') -or
        -not $adapterLine[0].Contains('não executado nem validado no host')) {
        throw "Matrix evidence for adapter '$adapterId' must be individual and must not imply host execution."
    }
}
Write-Host 'Should_CoverTenAdaptersAndFiveRolesWithoutClaimingParity: PASS'

$expectedPlan = 'features/014-improve-and-fix-disagreements/US03/PLAN/PLAN_014_us03_fallback_receipts.md'
$expectedStep = 2
$allowedFiles = @(
    'core/skills/orchestrate-develop/references/step-queue-spawn.md',
    'core/skills/orchestrate-develop/references/plan-contract.md',
    'scripts/validation/Test-Us03FallbackReceipts.ps1'
)
$allowedFields = @('planPath', 'step', 'status', 'files', 'testsSummary', 'nextStep', 'blockedReason')
function Test-ReceiptForQueue {
    param(
        [AllowNull()][object] $Receipt,
        [string] $PlanPath = $expectedPlan,
        [int] $Step = $expectedStep,
        [bool] $StepConfirmed = $true,
        [bool] $TestsRun = $true,
        [bool] $ClaimValid = $true
    )

    if ($null -eq $Receipt -or $Receipt -isnot [System.Collections.IDictionary]) {
        return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'receipt_missing_or_invalid' }
    }
    foreach ($key in $Receipt.Keys) {
        if ($key -notin $allowedFields) {
            return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'unknown_field' }
        }
    }
    foreach ($key in @('planPath', 'step', 'status', 'files', 'testsSummary')) {
        if (-not $Receipt.Contains($key)) {
            return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'required_field_missing' }
        }
    }
    if ($Receipt.planPath -cne $PlanPath -or $Receipt.step -isnot [int] -or $Receipt.step -ne $Step) {
        return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'invocation_mismatch' }
    }
    if ($Receipt.status -cnotin @('done', 'blocked', 'failed')) {
        return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'unknown_status' }
    }
    $summary = [string]$Receipt.testsSummary
    if ($Receipt.files -isnot [array] -or $Receipt.files.Count -eq 0 -or [string]::IsNullOrWhiteSpace($summary) -or
        $summary.Length -gt 500 -or $summary.Contains("`n") -or $summary.Contains("`r")) {
        return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'field_shape_invalid' }
    }
    if ($summary -notmatch '(?i)\b(PASS|BLOCKED|FAIL)\b') {
        return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'tests_summary_outcome_missing' }
    }
    $seenFiles = @{}
    foreach ($file in $Receipt.files) {
        if ($file -isnot [string] -or [string]::IsNullOrWhiteSpace($file)) {
            return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'file_path_invalid' }
        }
        $portablePath = $file.Replace('\', '/')
        if ($portablePath.StartsWith('/') -or $portablePath -match '^[A-Za-z]:' -or
            $portablePath -match '(^|/)\.\.?(/|$)' -or $portablePath.Contains('?') -or $portablePath.Contains('#') -or
            $portablePath.Contains(':') -or $portablePath.Contains("`n") -or $portablePath.Contains("`r")) {
            return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'file_path_invalid' }
        }
        if ($portablePath -cnotin $allowedFiles) {
            return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'file_path_out_of_scope' }
        }
        if ($seenFiles.ContainsKey($portablePath)) {
            return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'duplicate_file_path' }
        }
        $seenFiles[$portablePath] = $true
    }
    if ($Receipt.status -ceq 'done' -and $summary -notmatch '(?i)\bPASS\b') {
        return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'done_tests_not_passing' }
    }
    if ($Receipt.status -cin @('blocked', 'failed')) {
        if (-not $Receipt.Contains('blockedReason') -or $Receipt.blockedReason -isnot [string] -or
            [string]::IsNullOrWhiteSpace($Receipt.blockedReason) -or $Receipt.blockedReason.Length -gt 300 -or
            $Receipt.blockedReason.Contains("`n") -or $Receipt.blockedReason.Contains("`r")) {
            return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'blocked_reason_invalid' }
        }
    }
    if ($Receipt.status -ceq 'done' -and $Receipt.Contains('blockedReason')) {
        return [pscustomobject]@{ Valid = $false; CanRelease = $false; Reason = 'done_has_blocked_reason' }
    }
    $canRelease = $Receipt.status -ceq 'done' -and $StepConfirmed -and $TestsRun -and $ClaimValid
    return [pscustomobject]@{ Valid = $true; CanRelease = $canRelease; Reason = if ($canRelease) { 'reconciled_done' } else { [string]$Receipt.status } }
}

function New-ValidReceipt {
    return @{
        planPath = $expectedPlan
        step = 2
        status = 'done'
        files = @('core/skills/orchestrate-develop/references/step-queue-spawn.md')
        testsSummary = 'Focused contract checks PASS.'
    }
}

$valid = Test-ReceiptForQueue -Receipt (New-ValidReceipt)
if (-not $valid.Valid -or -not $valid.CanRelease) { throw 'A valid done receipt with all parent gates must release eligible dependencies.' }
Write-Host 'Should_ReleaseOnlyValidatedDoneReceipt_When_AllParentGatesPass: PASS'

$missing = Test-ReceiptForQueue -Receipt $null
if ($missing.Valid -or $missing.CanRelease) { throw 'A missing receipt must not release dependencies.' }
Write-Host 'Should_Reject_When_ReceiptIsMissing: PASS'

$incompleteReceipt = New-ValidReceipt
$incompleteReceipt.Remove('testsSummary')
$incomplete = Test-ReceiptForQueue -Receipt $incompleteReceipt
if ($incomplete.Valid -or $incomplete.CanRelease) { throw 'An incomplete receipt must not release dependencies.' }
Write-Host 'Should_Reject_When_ReceiptIsIncomplete: PASS'

$inconsistentReceipt = New-ValidReceipt
$inconsistentReceipt.planPath = 'features/other/PLAN.md'
$inconsistent = Test-ReceiptForQueue -Receipt $inconsistentReceipt
if ($inconsistent.Valid -or $inconsistent.CanRelease) { throw 'A receipt for another PLAN must not release dependencies.' }
Write-Host 'Should_Reject_When_ReceiptDoesNotMatchInvocation: PASS'

$unknownReceipt = New-ValidReceipt
$unknownReceipt.status = 'complete'
$unknown = Test-ReceiptForQueue -Receipt $unknownReceipt
if ($unknown.Valid -or $unknown.CanRelease) { throw 'An unknown status must not release dependencies.' }
foreach ($uppercaseStatus in @('DONE', 'BLOCKED', 'FAILED')) {
    $caseReceipt = New-ValidReceipt
    $caseReceipt.status = $uppercaseStatus
    $result = Test-ReceiptForQueue -Receipt $caseReceipt
    if ($result.Valid -or $result.CanRelease) { throw "Uppercase status '$uppercaseStatus' must be rejected." }
}
Write-Host 'Should_Reject_When_StatusIsUnknown: PASS'

foreach ($terminal in @('blocked', 'failed')) {
    $terminalReceipt = New-ValidReceipt
    $terminalReceipt.status = $terminal
    $terminalReceipt.blockedReason = 'Acceptance or validation did not pass.'
    $result = Test-ReceiptForQueue -Receipt $terminalReceipt
    if (-not $result.Valid -or $result.CanRelease) { throw "A $terminal receipt must retain its outcome and block advancement." }
}
Write-Host 'Should_NotRelease_When_StatusIsBlockedOrFailed: PASS'

foreach ($invalidReason in @('', '   ', $null, 42, (('x' * 301)), "first line`nsecond line", "first line`rsecond line")) {
    $reasonReceipt = New-ValidReceipt
    $reasonReceipt.status = 'blocked'
    $reasonReceipt.blockedReason = $invalidReason
    $result = Test-ReceiptForQueue -Receipt $reasonReceipt
    if ($result.Valid -or $result.CanRelease) { throw 'A missing, malformed, multiline, or overlong blockedReason must be rejected.' }
}
Write-Host 'Should_Reject_When_BlockedReasonIsMalformed: PASS'

$extraFieldReceipt = New-ValidReceipt
$extraFieldReceipt['commentary'] = 'untrusted'
$extraField = Test-ReceiptForQueue -Receipt $extraFieldReceipt
if ($extraField.Valid -or $extraField.CanRelease) { throw 'An unallowlisted field must invalidate the receipt.' }
Write-Host 'Should_Reject_When_ReceiptContainsUnknownFields: PASS'

foreach ($invalidPath in @(
    'C:/private/file.txt',
    '\\server/share/file.txt',
    'core/../private/file.txt',
    'core/skills/orchestrate-develop/references/step-queue-spawn.md?download=1',
    'core/skills/orchestrate-develop/references/step-queue-spawn.md#section',
    'features/other/PLAN.md'
)) {
    $pathReceipt = New-ValidReceipt
    $pathReceipt.files = @($invalidPath)
    $result = Test-ReceiptForQueue -Receipt $pathReceipt
    if ($result.Valid -or $result.CanRelease) { throw "Invalid or duplicate file path '$invalidPath' must not release dependencies." }
}
$duplicateReceipt = New-ValidReceipt
$duplicateReceipt.files = @($allowedFiles[0], $allowedFiles[0])
$duplicate = Test-ReceiptForQueue -Receipt $duplicateReceipt
if ($duplicate.Valid -or $duplicate.CanRelease) { throw 'Duplicate file paths must not release dependencies.' }
Write-Host 'Should_Reject_When_FilesAreAbsolute_Traversing_Duplicated_Or_OutOfScope: PASS'

foreach ($invalidSummary in @(
    'Focused contract checks FAIL.',
    'Focused contract checks complete.',
    ('PASS ' + ('x' * 500))
)) {
    $summaryReceipt = New-ValidReceipt
    $summaryReceipt.testsSummary = $invalidSummary
    $result = Test-ReceiptForQueue -Receipt $summaryReceipt
    if ($result.Valid -or $result.CanRelease) { throw 'A done receipt with a failing, non-PASS, or overlong summary must not release dependencies.' }
}
$multilineReceipt = New-ValidReceipt
$multilineReceipt.testsSummary = "Focused checks PASS.`nSecond line."
$multiline = Test-ReceiptForQueue -Receipt $multilineReceipt
if ($multiline.Valid -or $multiline.CanRelease) { throw 'A multiline test summary must not release dependencies.' }
Write-Host 'Should_Reject_When_DoneTestsSummaryIsInvalidOrNotPassing: PASS'

foreach ($invalidGate in @(
    @{ StepConfirmed = $false; TestsRun = $true; ClaimValid = $true }
    @{ StepConfirmed = $true; TestsRun = $false; ClaimValid = $true }
    @{ StepConfirmed = $true; TestsRun = $true; ClaimValid = $false }
)) {
    $result = Test-ReceiptForQueue -Receipt (New-ValidReceipt) -StepConfirmed $invalidGate.StepConfirmed -TestsRun $invalidGate.TestsRun -ClaimValid $invalidGate.ClaimValid
    if ($result.CanRelease) { throw 'A receipt must not release dependencies when any parent gate is invalid.' }
}
Write-Host 'Should_RequireParentGates_When_ReconcilingDoneReceipt: PASS'
Write-Host 'Test-Us03FallbackReceipts: ALL PASS'
exit 0
