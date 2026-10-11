#Requires -Version 5.1
# Tests the CT13 separation between technical authorization, operator confirmation, and O3 eligibility.
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
. (Join-Path $repoRoot 'core\policy\authorization.ps1')
. (Join-Path $repoRoot 'core\policy\continuous-queue.ps1')

$technicalAllow = Test-ActionAuthorization `
    -Effect 'file.write' `
    -Scope 'workspace:alpha' `
    -Authorizations @([PSCustomObject]@{ Effect = 'file.write'; Scope = 'workspace:alpha' })
$technicalAllow = [PSCustomObject]@{
    Allowed = $technicalAllow.Allowed
    Reason = $technicalAllow.Reason
    ActionId = 'ct13-file-write-alpha'
    Effect = $technicalAllow.Effect
    Scope = $technicalAllow.Scope
}
$technicalDeny = Test-ActionAuthorization `
    -Effect 'file.write' `
    -Scope 'workspace:outside' `
    -Authorizations @([PSCustomObject]@{ Effect = 'file.write'; Scope = 'workspace:alpha' })

$queue = @(
    [PSCustomObject]@{ Step = 1; Status = 'COMPLETED'; DependsOn = @() }
    [PSCustomObject]@{ Step = 2; Status = 'PENDING'; DependsOn = @(1) }
    [PSCustomObject]@{ Step = 3; Status = 'PENDING'; DependsOn = @(2) }
)
$continuousAllow = Test-ContinuousQueueStepAuthorization `
    -ReceiptValid $true -SessionGatesValid $true -ClaimValid $true `
    -QueueSteps $queue -RequestedStep 2 `
    -CheckpointPersisted $true -CheckpointReread $true -ResultPresented $true
$continuousDeny = Test-ContinuousQueueStepAuthorization `
    -ReceiptValid $true -SessionGatesValid $true -ClaimValid $true `
    -QueueSteps $queue -RequestedStep 3 `
    -CheckpointPersisted $true -CheckpointReread $true -ResultPresented $true

$operatorConfirmation = New-OperatorConfirmationEvidence `
    -ActionId 'ct13-file-write-alpha' `
    -Effect 'file.write' `
    -Scope 'workspace:alpha'

$allowWithoutSim = Test-AuthorizedActionExecution `
    -TechnicalAuthorization $technicalAllow `
    -OperatorConfirmation ([PSCustomObject]@{ Boundary = 'operator_action_boundary'; Decision = 'no'; Confirmed = $false; ActionId = 'ct13-file-write-alpha'; Effect = 'file.write'; Scope = 'workspace:alpha' }) `
    -ContinuousAuthorization $continuousAllow `
    -ExpectedActionId 'ct13-file-write-alpha'
if ($allowWithoutSim.Allowed -or $allowWithoutSim.Reason -ne 'operator_confirmation_invalid') {
    throw 'A technical allow must not authorize the current action without operator confirmation.'
}
Write-Host 'Should_Deny_TechnicalAllow_WithoutOperatorConfirmation: PASS'

$confirmedEligible = Test-AuthorizedActionExecution `
    -TechnicalAuthorization $technicalAllow -OperatorConfirmation $operatorConfirmation `
    -ContinuousAuthorization $continuousAllow -ExpectedActionId 'ct13-file-write-alpha'
if (-not $confirmedEligible.Allowed -or $confirmedEligible.Reason -ne 'action_authorized' -or $confirmedEligible.ConfirmationBoundary -ne 'operator_action_boundary') {
    throw 'A confirmed technically authorized action must proceed for the eligible O3 step.'
}
Write-Host 'Should_Allow_ConfirmedTechnicalAllow_ForEligibleO3Step: PASS'

$confirmedNonEligible = Test-AuthorizedActionExecution `
    -TechnicalAuthorization $technicalAllow -OperatorConfirmation $operatorConfirmation `
    -ContinuousAuthorization $continuousDeny -ExpectedActionId 'ct13-file-write-alpha'
if ($confirmedNonEligible.Allowed -or $confirmedNonEligible.Reason -ne 'continuous_authorization_denied') {
    throw 'Operator confirmation must not authorize a non-eligible O3 step.'
}
Write-Host 'Should_Deny_ConfirmedTechnicalAllow_ForNonEligibleO3Step: PASS'

$operatorConfirmedTechnicalDeny = Test-AuthorizedActionExecution `
    -TechnicalAuthorization $technicalDeny -OperatorConfirmation $operatorConfirmation `
    -ContinuousAuthorization $continuousAllow -ExpectedActionId 'ct13-file-write-alpha'
if ($operatorConfirmedTechnicalDeny.Allowed -or $operatorConfirmedTechnicalDeny.Reason -ne 'technical_authorization_denied') {
    throw 'Operator confirmation must not override a technical authorization denial.'
}
Write-Host 'Should_Deny_OperatorConfirmation_WhenTechnicalAuthorizationDenied: PASS'

$missingEvidence = Test-AuthorizedActionExecution `
    -TechnicalAuthorization $technicalAllow `
    -OperatorConfirmation ([PSCustomObject]@{ Confirmed = $true }) `
    -ContinuousAuthorization $continuousAllow -ExpectedActionId 'ct13-file-write-alpha'
if ($missingEvidence.Allowed -or $missingEvidence.Reason -ne 'operator_confirmation_required') {
    throw 'A caller-controlled confirmation flag without boundary evidence must not authorize the action.'
}
Write-Host 'Should_Deny_ConfirmationWithoutBoundaryEvidence: PASS'

$mismatchedEvidence = New-OperatorConfirmationEvidence `
    -ActionId 'ct13-file-write-outside' `
    -Effect 'file.write' `
    -Scope 'workspace:outside'
$mismatch = Test-AuthorizedActionExecution `
    -TechnicalAuthorization $technicalAllow `
    -OperatorConfirmation $mismatchedEvidence `
    -ContinuousAuthorization $continuousAllow -ExpectedActionId 'ct13-file-write-alpha'
if ($mismatch.Allowed -or $mismatch.Reason -ne 'operator_confirmation_mismatch') {
    throw 'Operator confirmation for another effect/scope must not authorize the current action.'
}
Write-Host 'Should_Deny_MismatchedOperatorConfirmation: PASS'

$contextlessTechnicalAllow = Test-AuthorizedActionExecution `
    -TechnicalAuthorization ([PSCustomObject]@{ Allowed = $true }) `
    -OperatorConfirmation $operatorConfirmation `
    -ContinuousAuthorization $continuousAllow -ExpectedActionId 'ct13-file-write-alpha'
if ($contextlessTechnicalAllow.Allowed -or $contextlessTechnicalAllow.Reason -ne 'technical_authorization_missing_context') {
    throw 'A caller-controlled technical allow without effect/scope context must not reach the action boundary.'
}
Write-Host 'Should_Deny_ContextlessTechnicalAuthorization: PASS'

$replayedConfirmation = New-OperatorConfirmationEvidence `
    -ActionId 'ct13-file-write-alpha-old' `
    -Effect 'file.write' `
    -Scope 'workspace:alpha'
$replay = Test-AuthorizedActionExecution `
    -TechnicalAuthorization ([PSCustomObject]@{ Allowed = $true; Reason = 'authorized'; ActionId = 'ct13-file-write-alpha-new'; Effect = 'file.write'; Scope = 'workspace:alpha' }) `
    -OperatorConfirmation $replayedConfirmation `
    -ContinuousAuthorization $continuousAllow `
    -ExpectedActionId 'ct13-file-write-alpha-new'
if ($replay.Allowed -or $replay.Reason -ne 'action_identity_mismatch') {
    throw 'A confirmation for the same effect/scope but a different ActionId must not authorize the current action.'
}
Write-Host 'Should_Deny_ReplayedConfirmation_WithDifferentActionId: PASS'

Write-Host 'Assert-OperatorConfirmationPolicy: ALL PASS'
exit 0
