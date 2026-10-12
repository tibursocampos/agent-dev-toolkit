#Requires -Version 5.1
# Tests:
#   Should_Allow_OnlyNextEligibleStep_When_Reconciled
#   Should_Deny_When_ReceiptIsMissingOrInconsistent
#   Should_Deny_When_ReconciliationIsIncomplete
#   Should_Deny_When_RequestIsOutsideQueue
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$policyPath = Join-Path $repoRoot 'core\policy\continuous-queue.ps1'
if (-not (Test-Path -LiteralPath $policyPath)) {
    throw "Missing queue authorization policy: $policyPath"
}
. $policyPath

$planPath = 'features/014-example/US01/PLAN/PLAN_014_example.md'
$queue = @(
    [PSCustomObject]@{ Step = 1; Status = 'COMPLETED'; DependsOn = @() }
    [PSCustomObject]@{ Step = 2; Status = 'PENDING'; DependsOn = @(1) }
    [PSCustomObject]@{ Step = 3; Status = 'PENDING'; DependsOn = @(2) }
)
function Invoke-QueuePolicy {
    param(
        [bool] $ReceiptValid = $true,
        [bool] $SessionGatesValid = $true,
        [bool] $ClaimValid = $true,
        [object[]] $QueueValue = $queue,
        [int] $RequestedStep = 2,
        [bool] $Persisted = $true,
        [bool] $Reread = $true,
        [bool] $Presented = $true
    )

    return (Test-ContinuousQueueStepAuthorization `
        -ReceiptValid $ReceiptValid `
        -SessionGatesValid $SessionGatesValid `
        -ClaimValid $ClaimValid `
        -QueueSteps $QueueValue `
        -RequestedStep $RequestedStep `
        -CheckpointPersisted $Persisted `
        -CheckpointReread $Reread `
        -ResultPresented $Presented)
}

$allowed = Invoke-QueuePolicy
if (-not $allowed.Allowed -or $allowed.Step -ne 2 -or $allowed.Reason -ne 'next_step_authorized') {
    throw 'A reconciled receipt must authorize exactly the next eligible step.'
}
Write-Host 'Should_Allow_OnlyNextEligibleStep_When_Reconciled: PASS'

$laterStep = Invoke-QueuePolicy -RequestedStep 3
if ($laterStep.Allowed -or $laterStep.Reason -ne 'step_outside_next_eligible') {
    throw 'A step later in the queue must not be authorized.'
}
Write-Host 'Should_Deny_When_RequestIsOutsideQueue: PASS'

$missingReceipt = Invoke-QueuePolicy -ReceiptValid $false
$inconsistentReceipt = Invoke-QueuePolicy -ReceiptValid $false
if ($missingReceipt.Allowed -or $missingReceipt.Reason -ne 'receipt_invalid' -or
    $inconsistentReceipt.Allowed -or $inconsistentReceipt.Reason -ne 'receipt_invalid') {
    throw 'A missing or non-done receipt must block queue advancement.'
}
Write-Host 'Should_Deny_When_ReceiptIsMissingOrInconsistent: PASS'

$invalidSession = Invoke-QueuePolicy -SessionGatesValid $false
$invalidClaim = Invoke-QueuePolicy -ClaimValid $false
if ($invalidSession.Allowed -or $invalidSession.Reason -ne 'session_gates_invalid' -or
    $invalidClaim.Allowed -or $invalidClaim.Reason -ne 'claim_invalid') {
    throw 'Invalid session gates or claim must block queue advancement.'
}
Write-Host 'Should_Deny_When_SessionOrClaimIsInvalid: PASS'

$invalidQueues = @(
    @{ Queue = @([PSCustomObject]@{ Step = 1; Status = 'COMPLETED'; DependsOn = @() }, [PSCustomObject]@{ Step = 1; Status = 'PENDING'; DependsOn = @() }) }
    @{ Queue = @([PSCustomObject]@{ Step = 1; Status = 'UNKNOWN'; DependsOn = @() }) }
    @{ Queue = @([PSCustomObject]@{ Step = 1; Status = 'PENDING'; DependsOn = @(2) }) }
    @{ Queue = @([PSCustomObject]@{ Step = 1; Status = 'PENDING'; DependsOn = @('2') }) }
)
foreach ($invalidQueue in $invalidQueues) {
    $result = Invoke-QueuePolicy -QueueValue $invalidQueue.Queue
    if ($result.Allowed -or $result.Reason -ne 'queue_invalid') {
        throw 'Malformed, duplicate, or unresolved queue entries must block advancement.'
    }
}
Write-Host 'Should_Deny_When_QueueIsMalformed: PASS'

foreach ($case in @(
    @{ Persisted = $false; Reread = $true; Presented = $true }
    @{ Persisted = $true; Reread = $false; Presented = $true }
    @{ Persisted = $true; Reread = $true; Presented = $false }
)) {
    $result = Invoke-QueuePolicy -Persisted $case.Persisted -Reread $case.Reread -Presented $case.Presented
    if ($result.Allowed -or $result.Reason -ne 'reconciliation_incomplete') {
        throw 'Incomplete checkpoint persistence, reread, or result presentation must block advancement.'
    }
}
Write-Host 'Should_Deny_When_ReconciliationIsIncomplete: PASS'

Write-Host 'Assert-ContinuousQueueAuthorization: ALL PASS'
exit 0
