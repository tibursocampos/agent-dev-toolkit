#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) '_lib/DeliveryGrammar.ps1')

$passed = 0
$lf = "`n"
$bom = [string][char]0xFEFF

$progressJson = '{"schema":"delivery-progress/v1","cadence":"continuous"}'
$checkpointJson = '{"schema":"delivery-checkpoint/v1","run_id":"run-1","branch":"feature/integrated-delivery-flow","head":"0123456789abcdef","active_step":null}'
$approvalJson = '{"schema":"delivery-approval/v1","state":"approved","identity":"plan-identity-1","input_identity":"input-identity-1","review_state":"reviewed"}'

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Assert-Throws([scriptblock]$Action, [string]$Name) {
    $threw = $false
    try { & $Action | Out-Null } catch { $threw = $true }
    if (-not $threw) { throw ('{0}: expected an exception' -f $Name) }
    $script:passed++
}

function Get-GrammarErrorCodes($Result) {
    return @(@($Result.Errors) | ForEach-Object { [string]$_.code })
}

function Assert-GrammarError([string]$Text, [string]$Code, [string]$Name) {
    $result = Read-DeliveryBlocks -Text $Text
    $codes = Get-GrammarErrorCodes $result
    if ($result.Ok -ne $false) { throw ('{0}: expected Ok false' -f $Name) }
    if ($codes -notcontains $Code) { throw ('{0}: expected code {1}, got [{2}]' -f $Name, $Code, ($codes -join ', ')) }
    $script:passed++
}

function Assert-GrammarErrorAny([string]$Text, [string[]]$Expected, [string]$Name) {
    $result = Read-DeliveryBlocks -Text $Text
    $actual = Get-GrammarErrorCodes $result
    if ($result.Ok -ne $false) { throw ('{0}: expected Ok false' -f $Name) }
    $matched = @($Expected | Where-Object { $actual -contains $_ })
    if ($matched.Count -eq 0) { throw ('{0}: expected one of [{1}], got [{2}]' -f $Name, ($Expected -join ', '), ($actual -join ', ')) }
    $script:passed++
}

function Assert-IssueCode($Issues, [string]$Code, [string]$Name) {
    $codes = @(@($Issues) | ForEach-Object { [string]$_.code })
    if ($codes -notcontains $Code) { throw ('{0}: expected issue {1}, got [{2}]' -f $Name, $Code, ($codes -join ', ')) }
    $script:passed++
}

function New-GrammarStepJson([string]$Id, [string]$Status = 'PENDING') {
    return ('{{"schema":"delivery-step/v1","id":"{0}","status":"{1}"}}' -f $Id, $Status)
}

function New-GrammarBlockLines([string]$Marker, [string]$Payload) {
    return @(('<!-- DELIVERY:{0}:BEGIN -->' -f $Marker), $Payload, ('<!-- DELIVERY:{0}:END -->' -f $Marker))
}

function New-GrammarPlan([string[]]$StepIds = @('US01-S1', 'US01-S2'), [string]$Progress = $progressJson, [string]$Body = 'Normative body.', [string]$StepStatus = 'PENDING') {
    $lines = @('# Plan', '', $Body, '')
    $lines += New-GrammarBlockLines 'PROGRESS' $Progress
    $lines += New-GrammarBlockLines 'CHECKPOINT' $checkpointJson
    $lines += New-GrammarBlockLines 'APPROVAL' $approvalJson
    foreach ($id in $StepIds) {
        $lines += New-GrammarBlockLines ('STEP:' + $id) (New-GrammarStepJson $id $StepStatus)
    }
    return (($lines -join $lf) + $lf)
}

# Identity and normalization

$basePlan = New-GrammarPlan

Assert-Equal (Get-DeliveryNormativeIdentity -Text $basePlan) (Get-DeliveryNormativeIdentity -Text ($basePlan.Replace($lf, "`r`n"))) 'Should_SameIdentity_When_LfCrlfVariants'
Assert-Equal (Get-DeliveryNormativeIdentity -Text $basePlan) (Get-DeliveryNormativeIdentity -Text ($bom + $basePlan)) 'Should_SameIdentity_When_BomVariant'

$operationalEdit = New-GrammarPlan -Progress '{"schema":"delivery-progress/v1","cadence":"step_by_step"}' -StepStatus 'COMPLETED'
Assert-Equal (Get-DeliveryNormativeIdentity -Text $basePlan) (Get-DeliveryNormativeIdentity -Text $operationalEdit) 'Should_KeepIdentity_When_OnlyBlockPayloadsChange'

$optionalCheckpointEdit = $basePlan.Replace('"run_id":"run-1"', '"run_id":"run-2"')
Assert-True ($optionalCheckpointEdit -cne $basePlan) 'Should_ChangeFixture_When_OptionalCheckpointFieldEdited'
Assert-Equal (Get-DeliveryNormativeIdentity -Text $basePlan) (Get-DeliveryNormativeIdentity -Text $optionalCheckpointEdit) 'Should_KeepIdentity_When_OptionalCheckpointFieldChanges'

$normativeEdit = New-GrammarPlan -Body 'Changed normative body.'
Assert-True ((Get-DeliveryNormativeIdentity -Text $basePlan) -cne (Get-DeliveryNormativeIdentity -Text $normativeEdit)) 'Should_ChangeIdentity_When_NormativeTextChanges'

Assert-Equal (Get-DeliverySha256Hex -Text (Get-DeliveryNormativeProjection -Text $basePlan)) (Get-DeliveryNormativeIdentity -Text $basePlan) 'Should_DeriveIdentityFromProjection_When_Hashing'

$projectionInput = (@('# Title', '', 'Body', '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '<!-- DELIVERY:PROGRESS:END -->', '', 'Tail', '', '') -join $lf)
$projectionExpected = (@('# Title', '', 'Body', '', 'Tail') -join $lf) + $lf
Assert-Equal $projectionExpected (Get-DeliveryNormativeProjection -Text $projectionInput) 'Should_RemoveBlocksAndTrimTrailingNewlines_When_ProjectingBalancedText'

Assert-Equal "a`nb`nc" (ConvertTo-DeliveryNormalizedText -Text ($bom + 'a' + "`r`n" + 'b' + "`r" + 'c')) 'Should_StripBomAndNormalizeNewlines_When_NormalizingText'
Assert-Equal 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD' (Get-DeliverySha256Hex -Text 'abc') 'Should_ReturnUppercaseHex_When_HashingKnownVector'

# Projection of fenced and unbalanced content

$fenced = (@('# Doc', '', '```markdown', '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '<!-- DELIVERY:PROGRESS:END -->', '```', '') -join $lf)
$fencedRead = Read-DeliveryBlocks -Text $fenced
Assert-True ($fencedRead.Ok -eq $true) 'Should_ReturnOk_When_MarkerIsInsideFencedCodeBlock'
Assert-Equal '0' ([string]@($fencedRead.Blocks).Count) 'Should_NotParseBlock_When_MarkerIsInsideFencedCodeBlock'
Assert-True ((Get-DeliveryNormativeProjection -Text $fenced).Contains('<!-- DELIVERY:PROGRESS:BEGIN -->')) 'Should_KeepMarkerInProjection_When_InsideFencedCodeBlock'

$unbalanced = (@('# Doc', '', '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '') -join $lf)
Assert-Throws { Get-DeliveryNormativeProjection -Text $unbalanced } 'Should_ThrowProjection_When_BlockIsUnbalanced'

$unclosedFenceDoc = (@('# Doc', '', '```markdown', 'body', '') -join $lf)
Assert-Throws { Get-DeliveryNormativeProjection -Text $unclosedFenceDoc } 'Should_ThrowProjection_When_FenceIsUnclosed'

# Read-DeliveryBlocks happy path

$validRead = Read-DeliveryBlocks -Text $basePlan
Assert-True ($validRead.Ok -eq $true) 'Should_ReturnOk_When_PlanHasValidBlocks'
Assert-Equal '5' ([string]@($validRead.Blocks).Count) 'Should_ReturnFiveBlocks_When_PlanHasProgressCheckpointApprovalAndTwoSteps'

$dottedStep = (New-GrammarBlockLines 'STEP:US01.S_1' (New-GrammarStepJson 'US01.S_1')) -join $lf
$dottedRead = Read-DeliveryBlocks -Text $dottedStep
Assert-True ($dottedRead.Ok -eq $true) 'Should_ReturnOk_When_StepIdContainsDotAndUnderscore'
Assert-True (@($dottedRead.Blocks | Where-Object { $_.Id -ceq 'US01.S_1' }).Count -eq 1) 'Should_ReturnBlockId_When_StepIdContainsDotAndUnderscore'

$caseDistinctRead = Read-DeliveryBlocks -Text (New-GrammarPlan -StepIds @('US01-S1', 'us01-s1'))
Assert-True ($caseDistinctRead.Ok -eq $true) 'Should_ReturnOk_When_StepIdsDifferOnlyByCase'
Assert-True (@($caseDistinctRead.Blocks | Where-Object { $_.Id -ceq 'US01-S1' }).Count -eq 1) 'Should_ReturnUpperCaseStepId_When_StepIdsDifferOnlyByCase'
Assert-True (@($caseDistinctRead.Blocks | Where-Object { $_.Id -ceq 'us01-s1' }).Count -eq 1) 'Should_ReturnLowerCaseStepId_When_StepIdsDifferOnlyByCase'

# Read-DeliveryBlocks error codes

Assert-GrammarError ((New-GrammarBlockLines 'BOGUS' '{"schema":"delivery-progress/v1"}') -join $lf) 'unknown_marker' 'Should_ReturnUnknownMarker_When_DeliveryMarkerIsNotInVocabulary'
Assert-GrammarError ((New-GrammarBlockLines 'STEP-US01-S1' (New-GrammarStepJson 'US01-S1')) -join $lf) 'legacy_step_marker' 'Should_ReturnLegacyStepMarker_When_StepUsesHyphenForm'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:-bad' (New-GrammarStepJson '-bad')) -join $lf) 'invalid_step_id' 'Should_ReturnInvalidStepId_When_IdStartsWithHyphen'
Assert-GrammarError (((New-GrammarBlockLines 'PROGRESS' $progressJson) + (New-GrammarBlockLines 'PROGRESS' $progressJson)) -join $lf) 'duplicate_block' 'Should_ReturnDuplicateBlock_When_TypeAppearsTwice'
Assert-GrammarError (((New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S1')) + (New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S1'))) -join $lf) 'duplicate_step_id' 'Should_ReturnDuplicateStepId_When_IdRepeats'
Assert-GrammarError (@('<!-- DELIVERY:PROGRESS:BEGIN -->', '<!-- DELIVERY:CHECKPOINT:BEGIN -->', $checkpointJson, '<!-- DELIVERY:CHECKPOINT:END -->', '<!-- DELIVERY:PROGRESS:END -->') -join $lf) 'nested_block' 'Should_ReturnNestedBlock_When_BlocksOverlap'
Assert-GrammarError (@('<!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '') -join $lf) 'unbalanced_block' 'Should_ReturnUnbalancedBlock_When_EndMarkerIsMissing'
Assert-GrammarError (@('<!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '<!-- DELIVERY:CHECKPOINT:END -->') -join $lf) 'mismatched_end' 'Should_ReturnMismatchedEnd_When_BeginAndEndTypesDiffer'
Assert-GrammarErrorAny (@('# Doc', '', '<!-- DELIVERY:PROGRESS:END -->', '') -join $lf) @('unbalanced_block', 'mismatched_end') 'Should_ReturnUnbalancedOrMismatchedEnd_When_EndMarkerIsOrphan'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '{"schema":') -join $lf) 'invalid_json' 'Should_ReturnInvalidJson_When_PayloadIsNotJson'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '["delivery-progress/v1"]') -join $lf) 'json_not_object' 'Should_ReturnJsonNotObject_When_PayloadIsArray'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '42') -join $lf) 'json_not_object' 'Should_ReturnJsonNotObject_When_PayloadIsScalar'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' 'null') -join $lf) 'json_not_object' 'Should_ReturnJsonNotObject_When_PayloadIsNull'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '{"cadence":"continuous"}') -join $lf) 'missing_schema' 'Should_ReturnMissingSchema_When_SchemaPropertyAbsent'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '{"SCHEMA":"delivery-progress/v1","cadence":"continuous"}') -join $lf) 'missing_schema' 'Should_ReturnMissingSchema_When_SchemaKeyDiffersInCase'
Assert-GrammarErrorAny ((New-GrammarBlockLines 'PROGRESS' '{"schema":["delivery-progress/v1"],"cadence":"continuous"}') -join $lf) @('wrong_schema', 'invalid_field') 'Should_ReturnWrongSchemaOrInvalidField_When_SchemaIsArray'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '{"schema":"delivery-progress/v0","cadence":"continuous"}') -join $lf) 'wrong_schema' 'Should_ReturnWrongSchema_When_SchemaVersionDiffers'

# Payload schema validation

$hiddenProgress = '{"schema":"delivery-progress/v1","cadence":"continuous","hidden_note":"secret"}'
$hiddenCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"feature/x","head":"abc","active_step":null,"hidden_note":"secret"}'
$hiddenApproval = '{"schema":"delivery-approval/v1","state":"pending","hidden_note":"secret"}'
$hiddenStep = '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","hidden_note":"secret"}'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' $hiddenProgress) -join $lf) 'unknown_property' 'Should_ReturnUnknownProperty_When_ProgressPayloadHasHiddenKey'
Assert-GrammarError ((New-GrammarBlockLines 'CHECKPOINT' $hiddenCheckpoint) -join $lf) 'unknown_property' 'Should_ReturnUnknownProperty_When_CheckpointPayloadHasHiddenKey'
Assert-GrammarError ((New-GrammarBlockLines 'APPROVAL' $hiddenApproval) -join $lf) 'unknown_property' 'Should_ReturnUnknownProperty_When_ApprovalPayloadHasHiddenKey'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' $hiddenStep) -join $lf) 'unknown_property' 'Should_ReturnUnknownProperty_When_StepPayloadHasHiddenKey'

$validAuthorization = '{"kind":"bounded","scope":"plan","granted_utc":"2026-11-11T00:00:00Z","plan_identity":"plan-identity-1","step_ids":["US01-S1"]}'
$validRepository = '{"path":"repo","base":"master","branch":"feature/x","head":"0123456789abcdef"}'
$validValidationResult = '{"command":"run-tests","result":"pass","exit_code":0,"at_utc":"2026-11-11T00:00:00Z"}'
$nestedProgress = '{"schema":"delivery-progress/v1","cadence":"continuous","authorization":' + $validAuthorization + '}'
$nestedCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"feature/x","head":"abc","active_step":null,"repositories":[' + $validRepository + ']}'
$nestedStep = '{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","validation_results":[' + $validValidationResult + ']}'
$nestedRead = Read-DeliveryBlocks -Text (((New-GrammarBlockLines 'PROGRESS' $nestedProgress) + (New-GrammarBlockLines 'CHECKPOINT' $nestedCheckpoint) + (New-GrammarBlockLines 'STEP:US01-S1' $nestedStep)) -join $lf)
Assert-True ($nestedRead.Ok -eq $true) 'Should_ReturnOk_When_NestedObjectsAreFullyValid'

Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' ('{"schema":"delivery-progress/v1","cadence":"continuous","authorization":{"kind":"bounded","scope":"plan","granted_utc":"2026-11-11T00:00:00Z","plan_identity":"plan-identity-1","step_ids":["US01-S1"],"hidden_note":"x"}}')) -join $lf) 'unknown_property' 'Should_ReturnUnknownProperty_When_AuthorizationHasHiddenKey'
Assert-GrammarError ((New-GrammarBlockLines 'CHECKPOINT' ('{"schema":"delivery-checkpoint/v1","branch":"feature/x","head":"abc","active_step":null,"repositories":[{"path":"repo","base":"master","branch":"feature/x","head":"abc","hidden_note":"x"}]}')) -join $lf) 'unknown_property' 'Should_ReturnUnknownProperty_When_RepositoryEntryHasHiddenKey'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","validation_results":[{"command":"run-tests","result":"pass","exit_code":0,"at_utc":"2026-11-11T00:00:00Z","hidden_note":"x"}]}')) -join $lf) 'unknown_property' 'Should_ReturnUnknownProperty_When_ValidationResultEntryHasHiddenKey'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","validation_results":[{"result":"pass","exit_code":0,"at_utc":"2026-11-11T00:00:00Z"}]}')) -join $lf) 'missing_field' 'Should_ReturnMissingField_When_ValidationResultOmitsCommand'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","validation_results":[{"command":"run-tests","result":"pass","exit_code":"0","at_utc":"2026-11-11T00:00:00Z"}]}')) -join $lf) 'invalid_field' 'Should_ReturnInvalidField_When_ValidationResultExitCodeIsString'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' ('{"schema":"delivery-progress/v1","cadence":"continuous","authorization":{"kind":"bounded","scope":"plan","granted_utc":"2026-11-11T00:00:00Z","plan_identity":"plan-identity-1","step_ids":"US01-S1"}}')) -join $lf) 'invalid_field' 'Should_ReturnInvalidField_When_AuthorizationStepIdsIsNotArray'

$reviewIdentityRead = Read-DeliveryBlocks -Text ((New-GrammarBlockLines 'APPROVAL' '{"schema":"delivery-approval/v1","state":"approved","identity":"plan-identity-1","input_identity":"input-identity-1","review_state":"reviewed","review_identity":"reviewer-1"}') -join $lf)
Assert-True ($reviewIdentityRead.Ok -eq $true) 'Should_ReturnOk_When_ApprovalHasOptionalReviewIdentity'

Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '{"schema":"delivery-progress/v1"}') -join $lf) 'missing_field' 'Should_ReturnMissingField_When_ProgressOmitsCadence'
Assert-GrammarError ((New-GrammarBlockLines 'CHECKPOINT' '{"schema":"delivery-checkpoint/v1","head":"abc","active_step":null}') -join $lf) 'missing_field' 'Should_ReturnMissingField_When_CheckpointOmitsBranch'
Assert-GrammarError ((New-GrammarBlockLines 'APPROVAL' '{"schema":"delivery-approval/v1"}') -join $lf) 'missing_field' 'Should_ReturnMissingField_When_ApprovalOmitsState'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' '{"schema":"delivery-step/v1","id":"US01-S1"}') -join $lf) 'missing_field' 'Should_ReturnMissingField_When_StepOmitsStatus'
Assert-GrammarError ((New-GrammarBlockLines 'APPROVAL' '{"schema":"delivery-approval/v1","state":"approved","input_identity":"input-1","review_state":"reviewed"}') -join $lf) 'missing_field' 'Should_ReturnMissingField_When_ApprovedApprovalOmitsIdentity'

$pendingApprovalRead = Read-DeliveryBlocks -Text ((New-GrammarBlockLines 'APPROVAL' '{"schema":"delivery-approval/v1","state":"pending"}') -join $lf)
Assert-True ($pendingApprovalRead.Ok -eq $true) 'Should_ReturnOk_When_PendingApprovalOmitsIdentity'

Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S1' 'DONE')) -join $lf) 'invalid_field' 'Should_ReturnInvalidField_When_StepStatusIsDone'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '{"schema":"delivery-progress/v1","cadence":"weekly"}') -join $lf) 'invalid_field' 'Should_ReturnInvalidField_When_CadenceIsOutsideEnum'
Assert-GrammarError ((New-GrammarBlockLines 'PROGRESS' '{"schema":"delivery-progress/v1","cadence":"continuous","completed":"2"}') -join $lf) 'invalid_field' 'Should_ReturnInvalidField_When_CompletedIsString'
Assert-GrammarErrorAny ((New-GrammarBlockLines 'APPROVAL' '{"schema":"delivery-approval/v1","state":"approved","identity":"plan-1","input_identity":"input-1","review_state":"reviewed","operator_choice":{"choice":"confirm","evidence":"sim","extra":"x"}}') -join $lf) @('unknown_property', 'invalid_field') 'Should_ReturnUnknownPropertyOrInvalidField_When_OperatorChoiceHasExtraKey'

# Fences and step payload ids

Assert-GrammarError (@('# Doc', '', '```markdown', 'body text', '') -join $lf) 'unclosed_fence' 'Should_ReportUnclosedFence_When_FenceNeverCloses'
Assert-GrammarError (@('# Doc', '', '````markdown', 'body text', '```', '') -join $lf) 'unclosed_fence' 'Should_ReportUnclosedFence_When_ClosingFenceIsShorterThanOpener'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S2')) -join $lf) 'step_id_mismatch' 'Should_ReportStepIdMismatch_When_PayloadIdDiffers'
Assert-GrammarErrorAny ((New-GrammarBlockLines 'STEP:US01-S1' '{"schema":"delivery-step/v1","status":"PENDING"}') -join $lf) @('missing_field', 'step_id_mismatch') 'Should_ReportMissingFieldOrStepIdMismatch_When_StepPayloadIdMissing'
Assert-GrammarError ((New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'us01-s1')) -join $lf) 'step_id_mismatch' 'Should_ReportStepIdMismatch_When_IdDiffersOnlyByCase'

$dottedIdRead = Read-DeliveryBlocks -Text ((New-GrammarBlockLines 'STEP:US01.S_1' (New-GrammarStepJson 'US01.S_1')) -join $lf)
Assert-True ($dottedIdRead.Ok -eq $true) 'Should_AcceptStep_When_PayloadIdMatchesMarkerWithDotAndUnderscore'

$closedFence = (@('# Doc', '', '```markdown') + (New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S1')) + @('```', '')) -join $lf
$closedFenceRead = Read-DeliveryBlocks -Text $closedFence
Assert-True ($closedFenceRead.Ok -eq $true) 'Should_KeepMarkersPlain_When_FenceIsClosedProperly'
Assert-Equal '0' ([string]@($closedFenceRead.Blocks).Count) 'Should_KeepMarkersPlain_When_FenceIsClosedProperly'
Assert-True ((Get-DeliveryNormativeProjection -Text $closedFence).Contains('<!-- DELIVERY:STEP:US01-S1:BEGIN -->')) 'Should_KeepMarkersPlain_When_FenceIsClosedProperly'
Assert-True ((Get-DeliveryNormativeProjection -Text $closedFence).Contains((New-GrammarStepJson 'US01-S1'))) 'Should_KeepMarkersPlain_When_FenceIsClosedProperly'

$tildeFence = (@('# Doc', '', '~~~markdown') + (New-GrammarBlockLines 'PROGRESS' $progressJson) + @('~~~', '')) -join $lf
$tildeRead = Read-DeliveryBlocks -Text $tildeFence
Assert-True ($tildeRead.Ok -eq $true) 'Should_ReturnOk_When_MarkerIsInsideTildeFence'
Assert-Equal '0' ([string]@($tildeRead.Blocks).Count) 'Should_NotParseBlock_When_MarkerIsInsideTildeFence'
Assert-True ((Get-DeliveryNormativeProjection -Text $tildeFence).Contains('<!-- DELIVERY:PROGRESS:BEGIN -->')) 'Should_KeepMarkerInProjection_When_InsideTildeFence'

$quadFence = (@('````markdown', '```', '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '<!-- DELIVERY:PROGRESS:END -->', '````', '') -join $lf)
$quadRead = Read-DeliveryBlocks -Text $quadFence
Assert-True ($quadRead.Ok -eq $true) 'Should_ReturnOk_When_FourBacktickFenceClosedByFourBackticks'
Assert-Equal '0' ([string]@($quadRead.Blocks).Count) 'Should_NotParseBlock_When_FourBacktickFenceClosedByFourBackticks'

$indentedFence = (@('# Doc', '', '    ```', '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '<!-- DELIVERY:PROGRESS:END -->', '') -join $lf)
$indentedFenceRead = Read-DeliveryBlocks -Text $indentedFence
Assert-True ($indentedFenceRead.Ok -eq $true) 'Should_ReturnOk_When_FourSpaceIndentedBacktickLineFollowedByBlock'
Assert-Equal '1' ([string]@($indentedFenceRead.Blocks).Count) 'Should_ParseBlock_When_FourSpaceIndentedBacktickLineIsNotAFence'

$indentedMarker = (@('# Doc', '', '  <!-- DELIVERY:PROGRESS:BEGIN -->', $progressJson, '  <!-- DELIVERY:PROGRESS:END -->', '') -join $lf)
$indentedMarkerRead = Read-DeliveryBlocks -Text $indentedMarker
Assert-True ($indentedMarkerRead.Ok -eq $true) 'Should_ReturnOk_When_MarkerIsIndentedByTwoSpaces'
Assert-Equal '0' ([string]@($indentedMarkerRead.Blocks).Count) 'Should_NotParseBlock_When_MarkerIsIndentedByTwoSpaces'
Assert-True ((Get-DeliveryNormativeProjection -Text $indentedMarker).Contains('  <!-- DELIVERY:PROGRESS:BEGIN -->')) 'Should_KeepIndentedMarkerInProjection_When_MarkerIsIndentedByTwoSpaces'

# Test-DeliveryRequiredBlocks

$planIssues = Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text $basePlan) -Kind PLAN -StepIds @('US01-S1', 'US01-S2')
Assert-Equal '0' ([string]@($planIssues).Count) 'Should_PassRequiredBlocks_When_PlanHasAllBlocks'

$noCheckpoint = (@('# Plan', '') + (New-GrammarBlockLines 'PROGRESS' $progressJson) + (New-GrammarBlockLines 'APPROVAL' $approvalJson) + (New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S1')) + '') -join $lf
$noCheckpointIssues = Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text $noCheckpoint) -Kind PLAN -StepIds @('US01-S1')
Assert-IssueCode $noCheckpointIssues 'missing_block' 'Should_ReturnMissingBlock_When_PlanOmitsCheckpoint'

$missingStepIssues = Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text (New-GrammarPlan -StepIds @('US01-S1'))) -Kind PLAN -StepIds @('US01-S1', 'US01-S2')
Assert-IssueCode $missingStepIssues 'missing_step' 'Should_ReturnMissingStep_When_PlanOmitsDeclaredStep'

$undeclaredStepIssues = Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text (New-GrammarPlan -StepIds @('US01-S1', 'US01-S2', 'US01-S3'))) -Kind PLAN -StepIds @('US01-S1', 'US01-S2')
Assert-IssueCode $undeclaredStepIssues 'undeclared_step' 'Should_ReturnUndeclaredStep_When_PlanHasExtraStep'

$planBlocks = @((Read-DeliveryBlocks -Text $basePlan).Blocks)
$duplicateProgressResult = [pscustomobject]@{
    Ok     = $true
    Errors = @()
    Blocks = @($planBlocks + $planBlocks[0])
}
$duplicateIssues = Test-DeliveryRequiredBlocks -Result $duplicateProgressResult -Kind PLAN -StepIds @('US01-S1', 'US01-S2')
Assert-IssueCode $duplicateIssues 'unexpected_block' 'Should_ReturnUnexpectedBlock_When_PlanHasDuplicateNonStepBlock'

$refinementText = (@('# Refinement', '') + (New-GrammarBlockLines 'APPROVAL' $approvalJson) + '') -join $lf
$refinementIssues = Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text $refinementText) -Kind REFINEMENT -StepIds @()
Assert-Equal '0' ([string]@($refinementIssues).Count) 'Should_PassRefinement_When_OnlyApprovalPresent'

$refinementWithStep = (@('# Refinement', '') + (New-GrammarBlockLines 'APPROVAL' $approvalJson) + (New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S1')) + '') -join $lf
$refinementStepIssues = Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text $refinementWithStep) -Kind REFINEMENT -StepIds @()
Assert-IssueCode $refinementStepIssues 'unexpected_block' 'Should_ReturnUnexpectedBlock_When_RefinementHasStepBlock'

$requiredCountZero = @(Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text $basePlan) -Kind PLAN -StepIds @('US01-S1', 'US01-S2')).Count
Assert-Equal '0' ([string]$requiredCountZero) 'Should_CountZeroIssues_When_RequiredBlocksPass'
$requiredCountOne = @(Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text $noCheckpoint) -Kind PLAN -StepIds @('US01-S1')).Count
Assert-Equal '1' ([string]$requiredCountOne) 'Should_CountOneIssue_When_CheckpointMissing'
$onlyStepText = (@('# Plan', '') + (New-GrammarBlockLines 'PROGRESS' $progressJson) + (New-GrammarBlockLines 'STEP:US01-S1' (New-GrammarStepJson 'US01-S1')) + '') -join $lf
$requiredCountTwo = @(Test-DeliveryRequiredBlocks -Result (Read-DeliveryBlocks -Text $onlyStepText) -Kind PLAN -StepIds @('US01-S1')).Count
Assert-Equal '2' ([string]$requiredCountTwo) 'Should_CountTwoIssues_When_CheckpointAndApprovalMissing'

$declaredText = (@('# Plan', '', '## Steps', '', '### US01-S1 First step', 'Depends on: none', 'Validation: run-tests', '', '### US01-S2 Second step', 'Depends on: US01-S1', 'Validation: run-tests', '') -join $lf)
$declared = Get-DeliveryDeclaredSteps -Text $declaredText
Assert-Equal '2' ([string]@($declared.Steps).Count) 'Should_ReturnTwoSteps_When_StepsSectionDeclaresTwo'
Assert-Equal '0' ([string]@($declared.Errors).Count) 'Should_ReturnNoErrors_When_DeclaredStepsAreValid'
Assert-Equal '0' ([string]@($declared.Steps[0].DependsOn).Count) 'Should_ReturnEmptyDependsOn_When_DependsOnIsNone'
Assert-Equal 'US01-S1' ([string]$declared.Steps[1].DependsOn[0]) 'Should_ReturnDependency_When_DependsOnNamesStep'
$numberedDeclared = Get-DeliveryDeclaredSteps -Text ((@('## 3. Steps', '', '### US01-S1 A', 'Depends on: none', 'Validation: x', '') -join $lf))
Assert-Equal '0' ([string]@($numberedDeclared.Errors).Count) 'Should_AcceptNumberedStepsHeading_When_PrefixIsPresent'
$fencedDeclared = Get-DeliveryDeclaredSteps -Text ((@('# Plan', '', '```markdown', '## Steps', '### US01-S1 A', 'Depends on: none', 'Validation: x', '```', '') -join $lf))
Assert-IssueCode $fencedDeclared.Errors 'steps_section_missing' 'Should_IgnoreFencedStepsHeading_When_HeadingIsInsideFence'
$invalidIdDeclared = Get-DeliveryDeclaredSteps -Text ((@('## Steps', '', '### -bad A', 'Depends on: none', 'Validation: x', '') -join $lf))
Assert-IssueCode $invalidIdDeclared.Errors 'step_id_invalid' 'Should_ReturnStepIdInvalid_When_HeadingTokenIsInvalid'
$duplicateDeclared = Get-DeliveryDeclaredSteps -Text ((@('## Steps', '', '### US01-S1 A', 'Depends on: none', 'Validation: x', '', '### US01-S1 B', 'Depends on: none', 'Validation: x', '') -join $lf))
Assert-IssueCode $duplicateDeclared.Errors 'duplicate_declared_step' 'Should_ReturnDuplicateDeclaredStep_When_IdRepeats'

# Block payload hashing

Assert-Equal (Get-DeliverySha256Hex -Text '{"a":1}') (Get-DeliveryBlockHash -Payload '{"a":1}') 'Should_HashPayloadAsText_When_NoTrailingNewline'
Assert-Equal (Get-DeliveryBlockHash -Payload ("{`"a`":1,`n`"b`":2}" + "`n")) (Get-DeliveryBlockHash -Payload ("{`"a`":1,`r`n`"b`":2}" + "`r`n")) 'Should_MatchBlockHash_When_PayloadUsesCrlf'
Assert-True ((Get-DeliveryBlockHash -Payload '{"a":1}') -cne (Get-DeliveryBlockHash -Payload '{"a":2}')) 'Should_ChangeBlockHash_When_PayloadChanges'

# Evidence declarations and evidence references

function New-GrammarStepDeclaration([string[]]$Extra = @()) {
    return ((@('## Steps', '', '### US01-S1 A', 'Depends on: none', 'Validation: run-tests') + $Extra + '') -join $lf)
}

function New-GrammarCheckpointText([string]$Payload) {
    return ((New-GrammarBlockLines 'CHECKPOINT' $Payload) -join $lf)
}

function New-GrammarStepText([string]$Payload) {
    return ((New-GrammarBlockLines 'STEP:US01-S1' $Payload) -join $lf)
}

$evidenceDeclared = Get-DeliveryDeclaredSteps -Text (@('## Steps', '', '### US01-S1 First', 'Depends on: none', 'Validation: run-tests', 'Evidence: plan-snapshot, design-note', '', '### US01-S2 Second', 'Depends on: US01-S1', 'Validation: run-tests', 'Needs evidence: US01-S1/plan-snapshot, US01-S1/design-note', 'Evidence: none', '', '### US01-S3 Third', 'Depends on: US01-S2', 'Validation: run-tests', 'Needs evidence: US01-S2/only-one', 'Evidence: only-one', '') -join $lf)
Assert-Equal '0' ([string]@($evidenceDeclared.Errors).Count) 'Should_ReturnNoErrors_When_EvidenceDeclarationsAreValid'
Assert-Equal '2' ([string]@($evidenceDeclared.Steps[0].Evidence).Count) 'Should_ReturnTwoEvidenceNames_When_EvidenceLineListsTwo'
Assert-Equal 'design-note' ([string]$evidenceDeclared.Steps[0].Evidence[1]) 'Should_ReturnEvidenceNamesInOrder_When_EvidenceLineListsTwo'
Assert-Equal '0' ([string]@($evidenceDeclared.Steps[0].Needs).Count) 'Should_ReturnEmptyNeeds_When_NeedsLineAbsent'
Assert-Equal '0' ([string]@($evidenceDeclared.Steps[1].Evidence).Count) 'Should_ReturnEmptyEvidence_When_EvidenceLineIsNone'
Assert-Equal '2' ([string]@($evidenceDeclared.Steps[1].Needs).Count) 'Should_ReturnTwoNeeds_When_NeedsLineListsTwo'
Assert-Equal 'US01-S1' ([string]$evidenceDeclared.Steps[1].Needs[0].Step) 'Should_ReturnNeedsStep_When_NeedsReferenceIsValid'
Assert-Equal 'plan-snapshot' ([string]$evidenceDeclared.Steps[1].Needs[0].Name) 'Should_ReturnNeedsName_When_NeedsReferenceIsValid'
Assert-True ($evidenceDeclared.Steps[2].Evidence -is [System.Array]) 'Should_ReturnArrayEvidence_When_SingleNameDeclared'
Assert-True ($evidenceDeclared.Steps[2].Needs -is [System.Array]) 'Should_ReturnArrayNeeds_When_SingleReferenceDeclared'
Assert-Equal '1' ([string]@($evidenceDeclared.Steps[2].Evidence).Count) 'Should_ReturnOneEvidenceName_When_SingleNameDeclared'
Assert-Equal '1' ([string]@($evidenceDeclared.Steps[2].Needs).Count) 'Should_ReturnOneNeed_When_SingleReferenceDeclared'

$labelCaseDeclared = Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('evidence: x'))
Assert-Equal '0' ([string]@($labelCaseDeclared.Steps[0].Evidence).Count) 'Should_IgnoreEvidenceLine_When_LabelDiffersInCase'
Assert-Equal '0' ([string]@($labelCaseDeclared.Errors).Count) 'Should_ReturnNoErrors_When_LowerCaseLabelIsPlainText'

Assert-IssueCode (Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Evidence: Plan-Snapshot'))).Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_EvidenceNameIsUppercase'
Assert-IssueCode (Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Evidence: a, a'))).Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_EvidenceNameRepeatsInStep'
Assert-IssueCode (Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Needs evidence: S1'))).Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_NeedsReferenceHasNoSlash'
Assert-IssueCode (Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Evidence: a,,b'))).Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_EvidenceHasEmptyToken'

$lineCheck = Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Evidence: Plan-Snapshot'))
Assert-Equal '6' ([string]$lineCheck.Errors[0].line) 'Should_ReportEvidenceLineNumber_When_EvidenceDeclarationInvalid'

Assert-IssueCode (Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Evidence: none, a'))).Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_EvidenceCombinesNoneWithName'
Assert-IssueCode (Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Needs evidence: none, US01-S1/x'))).Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_NeedsCombinesNoneWithReference'
$repeatedEvidence = Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Evidence: a', 'Evidence: b'))
Assert-IssueCode $repeatedEvidence.Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_EvidenceLineRepeats'
Assert-Equal '7' ([string]$repeatedEvidence.Errors[0].line) 'Should_ReportSecondEvidenceLineNumber_When_EvidenceLineRepeats'
Assert-IssueCode (Get-DeliveryDeclaredSteps -Text (New-GrammarStepDeclaration @('Needs evidence: US01-S1/a', 'Needs evidence: US01-S1/b'))).Errors 'evidence_declaration_invalid' 'Should_ReturnEvidenceDeclarationInvalid_When_NeedsLineRepeats'

Assert-IssueCode (Get-DeliveryDeclaredSteps -Text ((@('## Steps', '', '### US01--S1 A', 'Depends on: none', 'Validation: x', '') -join $lf))).Errors 'step_id_invalid' 'Should_ReturnStepIdInvalid_When_DeclaredIdContainsDoubleHyphen'
$caseAliasDeclared = Get-DeliveryDeclaredSteps -Text ((@('## Steps', '', '### US01-S1 A', 'Depends on: none', 'Validation: x', '', '### us01-s1 B', 'Depends on: none', 'Validation: x', '') -join $lf))
Assert-IssueCode $caseAliasDeclared.Errors 'duplicate_declared_step' 'Should_ReturnDuplicateDeclaredStep_When_IdsDifferOnlyByCase'
$singleHyphenDeclared = Get-DeliveryDeclaredSteps -Text ((@('## Steps', '', '### US01-A-S1 A', 'Depends on: none', 'Validation: x', '') -join $lf))
Assert-Equal '0' ([string]@($singleHyphenDeclared.Errors).Count) 'Should_ReturnNoErrors_When_DeclaredIdHasSingleHyphens'
Assert-Equal '1' ([string]@($singleHyphenDeclared.Steps).Count) 'Should_ReturnOneStep_When_DeclaredIdHasSingleHyphens'

$dirCheckpointOk = Read-DeliveryBlocks -Text (New-GrammarCheckpointText '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S1/plan-snapshot"}')
Assert-True ($dirCheckpointOk.Ok -eq $true) 'Should_ReturnOk_When_DirectoryCheckpointHasEmptyBranchHeadAndBaseline'

$gitBaselineOk = Read-DeliveryBlocks -Text (New-GrammarCheckpointText '{"schema":"delivery-checkpoint/v1","branch":"feature/x","head":"abc","active_step":null,"location_kind":"git","baseline_evidence":"US01-S1/plan-snapshot"}')
Assert-True ($gitBaselineOk.Ok -eq $true) 'Should_ReturnOk_When_GitCheckpointHasValidBaselineEvidence'

Assert-GrammarError (New-GrammarCheckpointText '{"schema":"delivery-checkpoint/v1","branch":"","head":"abc","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S1/plan-snapshot"}') 'invalid_field' 'Should_ReturnInvalidField_When_DirectoryCheckpointHeadIsNotEmpty'
Assert-GrammarError (New-GrammarCheckpointText '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory"}') 'missing_field' 'Should_ReturnMissingField_When_DirectoryCheckpointOmitsBaselineEvidence'
Assert-GrammarError (New-GrammarCheckpointText '{"schema":"delivery-checkpoint/v1","branch":"feature/x","head":"abc","active_step":null,"baseline_evidence":"US01"}') 'invalid_field' 'Should_ReturnInvalidField_When_BaselineEvidenceFormatIsWrong'
Assert-GrammarError (New-GrammarCheckpointText '{"schema":"delivery-checkpoint/v1","branch":"feature/x","head":"abc","active_step":null,"location_kind":"Git"}') 'invalid_field' 'Should_ReturnInvalidField_When_LocationKindHasWrongCase'
Assert-GrammarError (New-GrammarCheckpointText '{"schema":"delivery-checkpoint/v1","branch":"feature/x","head":"abc","active_step":null,"location_kind":"svn"}') 'invalid_field' 'Should_ReturnInvalidField_When_LocationKindIsOutsideEnum'

$shaUpper = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
$shaUpperTwo = 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD'
$refOne = '{"name":"plan-snapshot","path":"features/001-x/US01/evidence/plan-snapshot.md","sha256":"' + $shaUpper + '"}'
$refTwo = '{"name":"design-note","path":"features/001-x/US01/evidence/design-note.md","sha256":"' + $shaUpperTwo + '"}'

$refOneRead = Read-DeliveryBlocks -Text (New-GrammarStepText ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","evidence_refs":[' + $refOne + ']}'))
Assert-True ($refOneRead.Ok -eq $true) 'Should_ReturnOk_When_StepHasOneEvidenceRef'
$refTwoRead = Read-DeliveryBlocks -Text (New-GrammarStepText ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","evidence_refs":[' + $refOne + ',' + $refTwo + ']}'))
Assert-True ($refTwoRead.Ok -eq $true) 'Should_ReturnOk_When_StepHasTwoEvidenceRefs'
$refEmptyRead = Read-DeliveryBlocks -Text (New-GrammarStepText '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","evidence_refs":[]}')
Assert-True ($refEmptyRead.Ok -eq $true) 'Should_ReturnOk_When_EvidenceRefsIsEmptyArray'

Assert-GrammarError (New-GrammarStepText ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","evidence_refs":[' + $refOne.Replace($shaUpper, $shaUpper.ToLowerInvariant()) + ']}')) 'invalid_field' 'Should_ReturnInvalidField_When_EvidenceSha256IsLowercase'
Assert-GrammarError (New-GrammarStepText ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","evidence_refs":[{"name":"plan-snapshot","path":"p","sha256":"' + $shaUpper.Substring(0, 63) + '"}]}')) 'invalid_field' 'Should_ReturnInvalidField_When_EvidenceSha256IsSixtyThreeChars'
Assert-GrammarError (New-GrammarStepText ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","evidence_refs":[{"name":"plan-snapshot","path":"p","sha256":"' + $shaUpper + '","hidden_note":"x"}]}')) 'unknown_property' 'Should_ReturnUnknownProperty_When_EvidenceRefHasExtraKey'
Assert-GrammarError (New-GrammarStepText ('{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","evidence_refs":[{"name":"plan-snapshot","sha256":"' + $shaUpper + '"}]}')) 'missing_field' 'Should_ReturnMissingField_When_EvidenceRefOmitsPath'

# Plan dependency declarations

$depPathA = 'features/001-demo/US01/PLAN.md'
$depPathB = 'features/001-demo/TS02/PLAN.md'
$depHexA = 'A' * 64
$depHexB = 'B' * 64
$depStepsTail = @('## Steps', '', '### US01-S1 First', 'Depends on: none', 'Validation: run-tests', '')

function New-DependencyText([string[]]$Lines) {
    return ((@('# Plan', '', 'Normative body.', '', '## Plan dependencies', '') + $Lines + @('') + $depStepsTail) -join $lf)
}

$depOne = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$depHexA steps=US01-S1"))
Assert-Equal '0' ([string]@($depOne.Errors).Count) 'Should_ReturnNoErrors_When_OneDependencyIsValid'
Assert-Equal '1' ([string]@($depOne.Dependencies).Count) 'Should_ReturnOneDependency_When_OneRequiresLineIsValid'
Assert-Equal $depPathA ([string]$depOne.Dependencies[0].Path) 'Should_ReturnPath_When_RequiresLineIsValid'
Assert-Equal $depHexA ([string]$depOne.Dependencies[0].Identity) 'Should_ReturnIdentity_When_RequiresLineIsValid'
Assert-Equal '1' ([string]@($depOne.Dependencies[0].Steps).Count) 'Should_ReturnOneStep_When_StepsListHasOneId'
Assert-True ($depOne.Dependencies[0].Steps -is [System.Array]) 'Should_KeepStepsArray_When_StepsListHasOneId'
Assert-Equal '7' ([string]$depOne.Dependencies[0].Line) 'Should_ReturnLineNumber_When_RequiresLineIsValid'

$depTwo = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$depHexA steps=US01-S1,US01-S2", "", "Requires plan: $depPathB identity=$depHexB steps=TS02-S1"))
Assert-Equal '0' ([string]@($depTwo.Errors).Count) 'Should_ReturnNoErrors_When_TwoDependenciesAreValid'
Assert-Equal '2' ([string]@($depTwo.Dependencies).Count) 'Should_ReturnTwoDependencies_When_TwoRequiresLinesAreValid'
Assert-Equal '2' ([string]@($depTwo.Dependencies[0].Steps).Count) 'Should_ReturnBothSteps_When_StepsListHasTwoIds'
Assert-Equal $depPathB ([string]$depTwo.Dependencies[1].Path) 'Should_ReturnSecondPath_When_TwoRequiresLinesAreValid'

$depNone = Get-DeliveryPlanDependencies -Text (New-GrammarPlan)
Assert-Equal '0' ([string]@($depNone.Dependencies).Count) 'Should_ReturnNoDependencies_When_HeadingAbsent'
Assert-Equal '0' ([string]@($depNone.Errors).Count) 'Should_ReturnNoErrors_When_HeadingAbsent'
$depEmptySection = Get-DeliveryPlanDependencies -Text (New-DependencyText @())
Assert-Equal '0' ([string]@($depEmptySection.Dependencies).Count) 'Should_ReturnNoDependencies_When_HeadingHasNoLines'
Assert-Equal '0' ([string]@($depEmptySection.Errors).Count) 'Should_ReturnNoErrors_When_HeadingHasNoLines'

$depLowerHex = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$($depHexA.ToLowerInvariant()) steps=US01-S1"))
Assert-IssueCode $depLowerHex.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_IdentityIsLowercase'
Assert-Equal '0' ([string]@($depLowerHex.Dependencies).Count) 'Should_ExcludeDependency_When_IdentityIsLowercase'

$depBadPathParent = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: features/001-demo/../002-x/US01/PLAN.md identity=$depHexA steps=US01-S1"))
Assert-IssueCode $depBadPathParent.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_PathContainsParentSegment'
$depBadPathDrive = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: C:/repo/features/001-demo/US01/PLAN.md identity=$depHexA steps=US01-S1"))
Assert-IssueCode $depBadPathDrive.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_PathHasDrive'
$depBadPathName = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: features/001-demo/US01/notes.md identity=$depHexA steps=US01-S1"))
Assert-IssueCode $depBadPathName.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_PathIsNotPlanFile'

$depEmptySteps = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$depHexA steps="))
Assert-IssueCode $depEmptySteps.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_StepsAreEmpty'
$depTrailingComma = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$depHexA steps=US01-S1,"))
Assert-IssueCode $depTrailingComma.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_StepsHaveEmptyToken'
$depBadStepId = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$depHexA steps=-US01"))
Assert-IssueCode $depBadStepId.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_StepIdIsMalformed'

$depDuplicate = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$depHexA steps=US01-S1", "Requires plan: $depPathA identity=$depHexB steps=US01-S2"))
Assert-IssueCode $depDuplicate.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_PathRepeats'
Assert-Equal '1' ([string]@($depDuplicate.Dependencies).Count) 'Should_KeepFirstDependency_When_PathRepeats'

$depStray = Get-DeliveryPlanDependencies -Text (New-DependencyText @("Requires plan: $depPathA identity=$depHexA steps=US01-S1", "Note: stray text"))
Assert-IssueCode $depStray.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_StrayLineUnderHeading'
Assert-Equal '1' ([string]@($depStray.Dependencies).Count) 'Should_KeepValidDependency_When_StrayLineAlsoPresent'

$depFencedHeading = Get-DeliveryPlanDependencies -Text (@('# Plan', '', '```markdown', '## Plan dependencies', "Requires plan: $depPathA identity=$depHexA steps=US01-S1", '```', '') -join $lf)
Assert-Equal '0' ([string]@($depFencedHeading.Dependencies).Count) 'Should_IgnoreDependency_When_HeadingIsInsideFence'
Assert-Equal '0' ([string]@($depFencedHeading.Errors).Count) 'Should_ReturnNoErrors_When_HeadingIsInsideFence'

$depFencedLine = Get-DeliveryPlanDependencies -Text (New-DependencyText @('```', 'Example text under the heading', '```', "Requires plan: $depPathA identity=$depHexA steps=US01-S1"))
Assert-Equal '1' ([string]@($depFencedLine.Dependencies).Count) 'Should_IgnoreFencedLinesUnderHeading_When_FenceIsClosed'
Assert-Equal '0' ([string]@($depFencedLine.Errors).Count) 'Should_ReturnNoErrors_When_FenceUnderHeadingIsClosed'

$depStrayBeforeHeading = Get-DeliveryPlanDependencies -Text ((@('# Plan', '', "Requires plan: $depPathA identity=$depHexA steps=US01-S1", '', '## Plan dependencies', '', '## Steps', '', '### US01-S1 First', 'Depends on: none', 'Validation: run-tests', '') -join $lf))
Assert-IssueCode $depStrayBeforeHeading.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_RequiresLineIsBeforeHeading'
$depStrayAfterSection = Get-DeliveryPlanDependencies -Text ((@('# Plan', '', '## Notes', '', "Requires plan: $depPathA identity=$depHexA steps=US01-S1", '', '## Plan dependencies', '', '## Steps', '', '### US01-S1 First', 'Depends on: none', 'Validation: run-tests', '') -join $lf))
Assert-IssueCode $depStrayAfterSection.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_RequiresLineIsAfterOtherSection'
$depStrayNoHeading = Get-DeliveryPlanDependencies -Text ((@('# Plan', '', "Requires plan: $depPathA identity=$depHexA steps=US01-S1", '', '## Steps', '', '### US01-S1 First', 'Depends on: none', 'Validation: run-tests', '') -join $lf))
Assert-IssueCode $depStrayNoHeading.Errors 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_RequiresLineHasNoHeading'
Assert-Equal '0' ([string]@($depStrayNoHeading.Dependencies).Count) 'Should_NotDeclareDependency_When_RequiresLineIsOutsideHeading'
$depFencedOutside = Get-DeliveryPlanDependencies -Text ((@('# Plan', '', '```text', "Requires plan: $depPathA identity=$depHexA steps=US01-S1", '```', '', '## Plan dependencies', '', '## Steps', '', '### US01-S1 First', 'Depends on: none', 'Validation: run-tests', '') -join $lf))
Assert-Equal '0' ([string]@($depFencedOutside.Errors).Count) 'Should_IgnoreRequiresLine_When_InsideFencedCodeOutsideHeading'

# Refinement items

function Get-ExpectedSha256Hex([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function Get-ItemById($Items, [string]$Id) {
    return @(@($Items) | Where-Object { $_.Id -ceq $Id })[0]
}

$refinementItemsText = (@('# Refinement', '', '### D-001 Use cache', 'Cache results.', '', '### CA-002 Latency', 'Under 200 ms.', '', '### R-003 Load', 'Peak load risk.', '') -join $lf)
$refinementItems = Get-DeliveryRefinementItems -Text $refinementItemsText
Assert-Equal '3' ([string]@($refinementItems.Items).Count) 'Should_ParseThreeItems_When_DecisionCriterionAndRiskHeadingsPresent'
Assert-Equal 'D-001,CA-002,R-003' (@($refinementItems.Items | ForEach-Object { $_.Id }) -join ',') 'Should_ReturnItemIdsInOrder_When_ItemsParsed'
Assert-Equal 'Use cache' ([string]$refinementItems.Items[0].Title) 'Should_ReturnTitle_When_ItemHeadingHasTitle'
Assert-Equal '0' ([string]@($refinementItems.Errors).Count) 'Should_ReturnNoErrors_When_ItemsAreValid'
Assert-True ($refinementItems.Items[0].Body -ceq "### D-001 Use cache`nCache results.`n") 'Should_EndBodyBeforeNextHeading_When_ItemFollowedByHeading'
Assert-True (-not $refinementItems.Items[0].Body.Contains('CA-002')) 'Should_NotIncludeNextItem_When_BodyEndsAtNextHeading'

$fencedItemsText = (@('# Refinement', '', '### D-001 Example', 'Text.', '```markdown', '### D-009 Fake', '```', 'More.', '') -join $lf)
$fencedItems = Get-DeliveryRefinementItems -Text $fencedItemsText
Assert-Equal '1' ([string]@($fencedItems.Items).Count) 'Should_IgnoreFencedItemHeading_When_HeadingIsInsideFence'
Assert-True ($fencedItems.Items[0].Body.Contains('### D-009 Fake')) 'Should_KeepFencedHeadingInBody_When_HeadingIsInsideFence'

$ordinaryItemsText = (@('# Refinement', '', '### D-001 Decision', 'Text.', '', '### Notes', 'Not an item.', '') -join $lf)
$ordinaryItems = Get-DeliveryRefinementItems -Text $ordinaryItemsText
Assert-Equal '1' ([string]@($ordinaryItems.Items).Count) 'Should_IgnoreOrdinaryHeading_When_FirstTokenIsNotItemId'
Assert-True (-not $ordinaryItems.Items[0].Body.Contains('Not an item.')) 'Should_EndBody_When_OrdinaryLevelThreeHeadingFollows'

$duplicateItemsText = (@('### D-001 First', 'a', '', '### D-001 Second', 'b', '') -join $lf)
$duplicateItems = Get-DeliveryRefinementItems -Text $duplicateItemsText
Assert-IssueCode $duplicateItems.Errors 'refinement_item_invalid' 'Should_ReturnRefinementItemInvalid_When_IdRepeats'
Assert-True ([string]$duplicateItems.Errors[0].message).Contains('line 1') 'Should_NameFirstLine_When_IdRepeats'
Assert-True ([string]$duplicateItems.Errors[0].message).Contains('line 4') 'Should_NameSecondLine_When_IdRepeats'

$hashText = (@('# R', '', '### D-001 Use X', 'Body line.', '', '### D-002 Y', 'z', '') -join $lf)
$hashItems = Get-DeliveryRefinementItems -Text $hashText
Assert-Equal (Get-ExpectedSha256Hex "### D-001 Use X`nBody line.`n") ([string](Get-ItemById $hashItems.Items 'D-001').Hash) 'Should_MatchIndependentSha256_When_HashingItemBody'

$editedItemsText = $hashText.Replace('z', 'changed')
$editedItems = Get-DeliveryRefinementItems -Text $editedItemsText
Assert-True ((Get-ItemById $hashItems.Items 'D-002').Hash -cne (Get-ItemById $editedItems.Items 'D-002').Hash) 'Should_ChangeHash_When_OwnItemTextChanges'
Assert-Equal (Get-ItemById $hashItems.Items 'D-001').Hash (Get-ItemById $editedItems.Items 'D-001').Hash 'Should_KeepHash_When_OtherItemTextChanges'

$renamedText = $hashText.Replace('### D-001 Use X', '### D-001 Use Y')
$renamedItems = Get-DeliveryRefinementItems -Text $renamedText
Assert-True ((Get-ItemById $hashItems.Items 'D-001').Hash -cne (Get-ItemById $renamedItems.Items 'D-001').Hash) 'Should_ChangeHash_When_HeadingTitleRenamed'

$supersededText = (@('### D-001 Old', 'Status: superseded by D-002', '', '### D-002 New', 'Current.', '') -join $lf)
$superseded = Get-DeliveryRefinementItems -Text $supersededText
Assert-Equal 'D-002' ([string](Get-ItemById $superseded.Items 'D-001').SupersededBy) 'Should_DetectSupersededBy_When_StatusLinePresent'
Assert-Equal '' ([string](Get-ItemById $superseded.Items 'D-002').SupersededBy) 'Should_LeaveSupersededByEmpty_When_NoStatusLine'

$arrayOne = Get-DeliveryRefinementItems -Text ((@('### R-001 Only', 'x', '') -join $lf))
Assert-True ($arrayOne.Items -is [System.Array]) 'Should_KeepItemsArray_When_OneItemParsed'
Assert-Equal '1' ([string]@($arrayOne.Items).Count) 'Should_ReturnOneItem_When_OneItemParsed'
$arrayNone = Get-DeliveryRefinementItems -Text '# Empty'
Assert-True ($arrayNone.Items -is [System.Array]) 'Should_KeepItemsArray_When_NoItemsParsed'
Assert-Equal '0' ([string]@($arrayNone.Items).Count) 'Should_ReturnNoItems_When_NoItemHeadings'

# Refinement references

$shaRef = 'A' * 64
$refOneText = (@('# Plan', '', '## Refinement references', '', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", '', '## Steps', '') -join $lf)
$refOne = Get-DeliveryRefinementReferences -Text $refOneText
Assert-Equal '0' ([string]@($refOne.Errors).Count) 'Should_ReturnNoErrors_When_OneReferenceValid'
Assert-Equal '1' ([string]@($refOne.References).Count) 'Should_ReturnOneReference_When_OneUsesLineValid'
Assert-Equal 'D-001' ([string]$refOne.References[0].Id) 'Should_ReturnReferenceId_When_UsesLineValid'
Assert-Equal $shaRef ([string]$refOne.References[0].Hash) 'Should_ReturnReferenceHash_When_UsesLineValid'
Assert-Equal 'features/001-demo/REFINEMENT.md' ([string]$refOne.References[0].Path) 'Should_ReturnReferencePath_When_UsesLineValid'

$refManyText = (@('## 2. Refinement references', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", "Uses: features/001-demo/REFINEMENT.md CA-002 hash=$shaRef", "Uses: features/002-other/REFINEMENT.md R-003 hash=$shaRef", '', '## Steps', '') -join $lf)
$refMany = Get-DeliveryRefinementReferences -Text $refManyText
Assert-Equal '0' ([string]@($refMany.Errors).Count) 'Should_ReturnNoErrors_When_ManyReferencesValid'
Assert-Equal '3' ([string]@($refMany.References).Count) 'Should_ReturnAllReferences_When_ManyUsesLinesValid'
Assert-Equal 'R-003' ([string]$refMany.References[2].Id) 'Should_KeepOrder_When_ManyUsesLinesValid'

Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('## Refinement references', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$($shaRef.ToLowerInvariant())", '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_HashIsLowercase'
Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('## Refinement references', "Uses: features/001-demo/../002-x/REFINEMENT.md D-001 hash=$shaRef", '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_PathContainsParentSegment'
Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('## Refinement references', "Uses: features/001-demo/PLAN.md D-001 hash=$shaRef", '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_PathIsNotRefinement'
Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('## Refinement references', "Uses: features/001-demo/REFINEMENT.md X-1 hash=$shaRef", '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_IdIsMalformed'
Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('## Refinement references', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_PathAndIdRepeat'
Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('## Refinement references', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", 'Note: stray text', '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_OtherTextUnderHeading'
Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('# Plan', '', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", '', '## Refinement references', '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_UsesLineIsOutsideHeading'
Assert-IssueCode (Get-DeliveryRefinementReferences -Text ((@('## Refinement references', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", '## Notes', '## Refinement references', '') -join $lf))).Errors 'refinement_reference_invalid' 'Should_ReturnReferenceInvalid_When_SecondHeadingPresent'
$fencedRefs = Get-DeliveryRefinementReferences -Text ((@('## Refinement references', '```text', "Uses: features/001-demo/REFINEMENT.md D-001 hash=$shaRef", '```', '') -join $lf))
Assert-Equal '0' ([string]@($fencedRefs.References).Count) 'Should_IgnoreFencedUsesLine_When_LineIsInsideFence'
Assert-Equal '0' ([string]@($fencedRefs.Errors).Count) 'Should_ReturnNoErrors_When_FencedLineUnderHeading'
$noRefHeading = Get-DeliveryRefinementReferences -Text '# Plan'
Assert-True ($noRefHeading.References -is [System.Array]) 'Should_KeepReferencesArray_When_NoHeading'
Assert-Equal '0' ([string]@($noRefHeading.References).Count) 'Should_ReturnNoReferences_When_NoHeading'
Assert-Equal '0' ([string]@($noRefHeading.Errors).Count) 'Should_ReturnNoErrors_When_NoHeading'

Write-Output ('PASS: {0} delivery grammar assertions.' -f $passed)
exit 0
