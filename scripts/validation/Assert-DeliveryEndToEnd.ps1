#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$cli = @{
    Preflight  = Join-Path $scriptsRoot 'runtime/Test-DeliveryPlanPreflight.ps1'
    NewRecord  = Join-Path $scriptsRoot 'runtime/New-DeliveryReviewRecord.ps1'
    SaveRecord = Join-Path $scriptsRoot 'runtime/Write-DeliveryReviewRecord.ps1'
    TestRecord = Join-Path $scriptsRoot 'runtime/Test-DeliveryReviewRecord.ps1'
    Evidence   = Join-Path $scriptsRoot 'runtime/Invoke-DeliveryEvidence.ps1'
    Resolver   = Join-Path $scriptsRoot 'ledger/Resolve-DeliveryExecution.ps1'
    Setter     = Join-Path $scriptsRoot 'ledger/Set-DeliveryExecutionBlock.ps1'
}
. (Join-Path $scriptsRoot '_lib/DeliveryGrammar.ps1')

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-end-to-end-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$utf8 = [System.Text.UTF8Encoding]::new($false)
$passed = 0

$planRelative = 'features/900-e2e/US01/PLAN.md'
$refinementRelative = 'features/900-e2e/REFINEMENT.md'
$draftRelative = 'features/900-e2e/scratch/delivery-review/US01-plan-draft.json'
$recordRelative = 'features/900-e2e/delivery-reviews/US01-plan.json'
$baselineRelative = 'features/900-e2e/US01/evidence/US01-S1--baseline.txt'
$resultRelative = 'features/900-e2e/US01/evidence/US01-S1--result.txt'
$baselineContent = 'synthetic baseline content'
$resultContent = 'synthetic result content'
$pendingApproval = '{"schema":"delivery-approval/v1","state":"pending"}'
$gitCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null}'
$directoryCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S1/baseline"}'
$progressPayload = '{"schema":"delivery-progress/v1","cadence":"step_by_step"}'
$step2Pending = '{"schema":"delivery-step/v1","id":"US01-S2","status":"PENDING","depends_on":["US01-S1"]}'

$readerJson = '{"paraphrases":{"proposal":"Synthetic proposal paraphrase.","current_system":"Synthetic current system paraphrase."},"lenses":["scope","sequencing"],"findings":[{"id":"R1-001","severity":"MINOR","category":"GAP","section":"Steps","evidence":"Synthetic wording note.","recommendation":"Reword the validation line."}]}'
$criticJson = '{"lenses":["risk"],"findings":[]}'
$inputsJson = '[{"id":"refinement","path":"features/900-e2e/REFINEMENT.md","role":"normative_source","impacted_ids":["US01-S1","US01-S2"]}]'
$dispositionsJson = '[{"id":"R1-001","disposition":"accepted_minor","reason":"Synthetic minor finding accepted without change."}]'

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Assert-ExitCode([int]$Expected, $Run, [string]$Name) {
    if ([string]$Expected -cne [string]$Run.ExitCode) {
        throw ('{0}: expected exit {1}, got {2}; stdout: {3}; stderr: {4}' -f $Name, $Expected, $Run.ExitCode, $Run.Stdout.Trim(), $Run.Stderr.Trim())
    }
    $script:passed++
}

function Assert-Field($Run, [string]$Field, [string]$Expected, [string]$Name) {
    Assert-Equal $Expected ([string](Get-Prop $Run.Result $Field)) $Name
}

function Assert-Issue($Run, [string]$Code, [string]$Name) {
    $codes = Get-IssueCodes $Run
    if ($codes -cnotcontains $Code) { throw ('{0}: expected issue {1}, got [{2}]' -f $Name, $Code, ($codes -join ', ')) }
    $script:passed++
}

function Get-Prop($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-IssueCodes($Run) {
    return @(@(Get-Prop $Run.Result 'issues') | ForEach-Object { [string](Get-Prop $_ 'code') })
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-Cli {
    param(
        [Parameter(Mandatory = $true)][string] $Script,
        [string[]] $Arguments = @()
    )

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script) + $Arguments
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $childHost
    $startInfo.Arguments = (@($argList | ForEach-Object { ConvertTo-ProcessArgument ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $process.StandardInput.Close()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdoutText = $stdoutTask.Result
    $stderrText = $stderrTask.Result

    $parsed = $null
    if (-not [string]::IsNullOrWhiteSpace($stdoutText)) {
        try { $parsed = $stdoutText.Trim() | ConvertFrom-Json } catch { $parsed = $null }
    }
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Result = $parsed; Stdout = $stdoutText; Stderr = $stderrText }
}

function Get-RepoPath([string]$Repo, [string]$Relative) {
    return [System.IO.Path]::GetFullPath((Join-Path $Repo $Relative))
}

function Write-RepoFile([string]$Repo, [string]$Relative, [string]$Text) {
    $path = Get-RepoPath $Repo $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [System.IO.File]::WriteAllText($path, $Text, $utf8)
}

function Read-RepoText([string]$Repo, [string]$Relative) {
    return [System.IO.File]::ReadAllText((Get-RepoPath $Repo $Relative))
}

function Edit-File([string]$Path, [string]$Old, [string]$New) {
    $text = [System.IO.File]::ReadAllText($Path)
    if (-not $text.Contains($Old)) { throw "Fixture edit target not found in $Path" }
    [System.IO.File]::WriteAllText($Path, $text.Replace($Old, $New), $utf8)
}

function Get-FileBase64([string]$Path) {
    return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

function Get-Sha256Upper([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Copy-State([string]$Source, [string]$Name) {
    $destination = Join-Path $tempRoot $Name
    Copy-Item -LiteralPath $Source -Destination $destination -Recurse -Force
    return $destination
}

function Get-BlockHashFromFile([string]$Path, [string]$Block) {
    $type = $Block
    $id = ''
    if ($Block.StartsWith('STEP:', [System.StringComparison]::Ordinal)) {
        $type = 'STEP'
        $id = $Block.Substring('STEP:'.Length)
    }
    $parsed = Read-DeliveryBlocks -Text ([System.IO.File]::ReadAllText($Path))
    $found = @($parsed.Blocks | Where-Object { ($_.Type -ceq $type) -and (([string]$_.Id) -ceq $id) })
    if ($found.Count -ne 1) { throw "Block $Block is not present exactly once in $Path" }
    return (Get-DeliveryBlockHash -Payload $found[0].Payload)
}

function Invoke-Setter([string]$Repo, [string]$PlanFull, [string]$Block, [string]$Payload) {
    $hash = Get-BlockHashFromFile -Path $PlanFull -Block $Block
    return Invoke-Cli -Script $cli.Setter -Arguments @(
        '-RepoPath', $Repo, '-PlanPath', $PlanFull, '-Block', $Block,
        '-ExpectedBlockHash', $hash, '-PayloadJson', $Payload)
}

function Invoke-Preflight([string]$Repo, [string[]]$Extra = @()) {
    return Invoke-Cli -Script $cli.Preflight -Arguments (@('-RepoPath', $Repo, '-PlanPath', $planRelative) + $Extra)
}

function Invoke-Resolver([string]$PlanFull, [string]$InputIdentity) {
    return Invoke-Cli -Script $cli.Resolver -Arguments @(
        '-PlanPath', $PlanFull, '-Cadence', 'step_by_step', '-CurrentInputIdentity', $InputIdentity,
        '-CurrentBranch', '', '-CurrentHead', '', '-StepAuthorization')
}

function Invoke-EvidenceWrite([string]$Repo, [string]$Name, [string]$Content) {
    return Invoke-Cli -Script $cli.Evidence -Arguments @(
        '-Action', 'write', '-RepoPath', $Repo, '-PlanPath', $planRelative,
        '-Step', 'US01-S1', '-Name', $Name, '-Content', $Content, '-Extension', 'txt')
}

function Invoke-EvidenceVerify([string]$Repo, [string]$Name, [string]$ExpectedSha) {
    $arguments = @('-Action', 'verify', '-RepoPath', $Repo, '-PlanPath', $planRelative,
        '-Step', 'US01-S1', '-Name', $Name)
    if ($ExpectedSha.Length -gt 0) { $arguments += @('-ExpectedSha256', $ExpectedSha) }
    return Invoke-Cli -Script $cli.Evidence -Arguments $arguments
}

function New-RefinementText {
    return (@(
        '# Refinement 900', '',
        'Normative body: synthetic refinement for the delivery end-to-end self-test.', '',
        '<!-- DELIVERY:APPROVAL:BEGIN -->', $pendingApproval, '<!-- DELIVERY:APPROVAL:END -->', ''
    ) -join "`n") + "`n"
}

function New-PlanText {
    $lines = @(
        '# US01 plan', '',
        'Normative body: synthetic unit plan for the delivery end-to-end self-test.', '',
        '## Steps', '',
        '### US01-S1 Produce evidence',
        'Depends on: none',
        'Evidence: baseline, result',
        'Validation: synthetic check one', '',
        '### US01-S2 Consume evidence',
        'Depends on: US01-S1',
        'Needs evidence: US01-S1/result',
        'Validation: synthetic check two', '',
        '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressPayload, '<!-- DELIVERY:PROGRESS:END -->',
        '<!-- DELIVERY:CHECKPOINT:BEGIN -->', $gitCheckpoint, '<!-- DELIVERY:CHECKPOINT:END -->',
        '<!-- DELIVERY:APPROVAL:BEGIN -->', $pendingApproval, '<!-- DELIVERY:APPROVAL:END -->',
        '<!-- DELIVERY:STEP:US01-S1:BEGIN -->', '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[]}', '<!-- DELIVERY:STEP:US01-S1:END -->',
        '<!-- DELIVERY:STEP:US01-S2:BEGIN -->', $step2Pending, '<!-- DELIVERY:STEP:US01-S2:END -->'
    )
    return (($lines -join "`n") + "`n")
}

function New-StepPayload([string]$Id, [string]$Status, [string]$DependsJson, [string]$RefsJson = '') {
    $refs = ''
    if ($RefsJson.Length -gt 0) { $refs = ',"evidence_refs":' + $RefsJson }
    return '{"schema":"delivery-step/v1","id":"' + $Id + '","status":"' + $Status + '","depends_on":' + $DependsJson + $refs + '}'
}

function New-RefJson([string]$Name, [string]$Path, [string]$Sha) {
    return '{"name":"' + $Name + '","path":"' + $Path + '","sha256":"' + $Sha + '"}'
}

try {
    # Scenario A: directory unit, lifecycle through the public CLIs.
    $repoA = Join-Path $tempRoot 'scenario-a'
    New-Item -ItemType Directory -Path (Get-RepoPath $repoA 'features/900-e2e/scratch/delivery-review') -Force | Out-Null
    Write-RepoFile $repoA $refinementRelative (New-RefinementText)
    Write-RepoFile $repoA $planRelative (New-PlanText)
    $planA = Get-RepoPath $repoA $planRelative
    $refinementA = Get-RepoPath $repoA $refinementRelative
    $recordA = Get-RepoPath $repoA $recordRelative

    # A2: fresh plan preflight.
    $preflightFresh = Invoke-Preflight $repoA
    Assert-ExitCode 0 $preflightFresh 'Should_ExitZero_When_FreshPlanPreflight'
    Assert-Field $preflightFresh 'ok' 'True' 'Should_ReturnOk_When_FreshPlanPreflight'
    $identity = [string](Get-Prop $preflightFresh.Result 'identity')
    Assert-True ($identity -cmatch '^[0-9A-F]{64}$') 'Should_ReturnIdentity_When_FreshPlanPreflight'

    # A3: synthetic review, record save, record check, preflight with the review gate.
    $reviewDir = Get-RepoPath $repoA 'features/900-e2e/scratch/delivery-review'
    $readerPath = Join-Path $reviewDir 'reader.json'
    $criticPath = Join-Path $reviewDir 'critic.json'
    $inputsPath = Join-Path $reviewDir 'inputs.json'
    $dispositionsPath = Join-Path $reviewDir 'dispositions.json'
    [System.IO.File]::WriteAllText($readerPath, $readerJson, $utf8)
    [System.IO.File]::WriteAllText($criticPath, $criticJson, $utf8)
    [System.IO.File]::WriteAllText($inputsPath, $inputsJson, $utf8)
    [System.IO.File]::WriteAllText($dispositionsPath, $dispositionsJson, $utf8)

    $newRun = Invoke-Cli -Script $cli.NewRecord -Arguments @(
        '-State', 'reviewed', '-RepoPath', $repoA,
        '-ReaderResultPath', $readerPath, '-CriticResultPath', $criticPath,
        '-ReaderHost', 'synthetic', '-ReaderIsolation', 'synthetic',
        '-CriticHost', 'synthetic', '-CriticIsolation', 'synthetic',
        '-InputsPath', $inputsPath, '-DispositionsPath', $dispositionsPath,
        '-OutPath', $draftRelative)
    Assert-ExitCode 0 $newRun 'Should_ExitZero_When_ReviewDraftBuilt'
    Assert-Field $newRun 'ok' 'True' 'Should_ReturnOk_When_ReviewDraftComplete'

    $draftText = Read-RepoText $repoA $draftRelative
    $saveRun = Invoke-Cli -Script $cli.SaveRecord -Arguments @(
        '-Action', 'save', '-RepoPath', $repoA, '-TargetPath', $planRelative,
        '-TargetKind', 'PLAN.md', '-Stage', 'delivery_unit_plan_review',
        '-ArtifactText', (Read-RepoText $repoA $planRelative),
        '-RecordPath', $recordA, '-RecordJson', $draftText)
    Assert-ExitCode 0 $saveRun 'Should_ExitZero_When_ReviewRecordSaved'
    Assert-Field $saveRun 'status' 'saved' 'Should_ReturnSaved_When_ReviewRecordSaved'
    $reviewIdentity = [string](Get-Prop $saveRun.Result 'review_identity')
    Assert-True ($reviewIdentity -cmatch '^[0-9A-F]{64}$') 'Should_ReturnReviewIdentity_When_ReviewRecordSaved'

    $checkRun = Invoke-Cli -Script $cli.TestRecord -Arguments @('-RepoPath', $repoA, '-TargetPath', $planRelative, '-RecordPath', $recordA)
    Assert-ExitCode 0 $checkRun 'Should_ExitZero_When_ReviewRecordAllowed'
    Assert-Field $checkRun 'allowed' 'True' 'Should_Allow_When_ReviewRecordReviewed'
    Assert-Field $checkRun 'reason' 'reviewed' 'Should_ReturnReasonReviewed_When_ReviewRecordReviewed'

    $gatedPreflight = Invoke-Preflight $repoA @('-ReviewRecordPath', $recordA)
    Assert-ExitCode 0 $gatedPreflight 'Should_ExitZero_When_ReviewGateSatisfied'
    Assert-Field $gatedPreflight 'ok' 'True' 'Should_ReturnOk_When_ReviewGateSatisfied'

    $stateReviewed = Copy-State $repoA 'state-reviewed'

    # A4: approve through the setter, then confirm the expected identity.
    $inputIdentity = Get-Sha256Upper $refinementA
    $approvalPayload = '{"schema":"delivery-approval/v1","state":"approved","identity":"' + $identity +
        '","input_identity":"' + $inputIdentity + '","review_state":"reviewed","review_identity":"' + $reviewIdentity +
        '","blocking_findings":[],"unresolved_decisions":[],"approved_utc":"2026-11-11T12:00:00Z"}'
    $approveRun = Invoke-Setter $repoA $planA 'APPROVAL' $approvalPayload
    Assert-ExitCode 0 $approveRun 'Should_ExitZero_When_ApprovalWritten'
    Assert-Field $approveRun 'code' 'written_and_verified' 'Should_ReturnWrittenAndVerified_When_ApprovalWritten'

    $approvedPreflight = Invoke-Preflight $repoA @('-ExpectedIdentity', $identity)
    Assert-ExitCode 0 $approvedPreflight 'Should_ExitZero_When_ApprovedPlanMatchesExpectedIdentity'
    Assert-Field $approvedPreflight 'ok' 'True' 'Should_ReturnOk_When_ApprovedPlanMatchesExpectedIdentity'

    $stateApproved = Copy-State $repoA 'state-approved'

    # A5: two directory evidence files, step evidence references, directory checkpoint.
    $baselineRun = Invoke-EvidenceWrite $repoA 'baseline' $baselineContent
    Assert-ExitCode 0 $baselineRun 'Should_ExitZero_When_BaselineEvidenceWritten'
    Assert-Field $baselineRun 'path' $baselineRelative 'Should_ReturnBaselinePath_When_BaselineEvidenceWritten'
    $baselineSha = [string](Get-Prop $baselineRun.Result 'sha256')

    $resultRun = Invoke-EvidenceWrite $repoA 'result' $resultContent
    Assert-ExitCode 0 $resultRun 'Should_ExitZero_When_ResultEvidenceWritten'
    Assert-Field $resultRun 'path' $resultRelative 'Should_ReturnResultPath_When_ResultEvidenceWritten'
    $resultSha = [string](Get-Prop $resultRun.Result 'sha256')

    $verifyRun = Invoke-EvidenceVerify $repoA 'result' $resultSha
    Assert-ExitCode 0 $verifyRun 'Should_ExitZero_When_ResultEvidenceVerified'

    $refs = '[' + (New-RefJson 'baseline' $baselineRelative $baselineSha) + ',' + (New-RefJson 'result' $resultRelative $resultSha) + ']'
    $step1Run = Invoke-Setter $repoA $planA 'STEP:US01-S1' (New-StepPayload 'US01-S1' 'PENDING' '[]' $refs)
    Assert-ExitCode 0 $step1Run 'Should_ExitZero_When_EvidenceReferencesRecorded'
    $checkpointRun = Invoke-Setter $repoA $planA 'CHECKPOINT' $directoryCheckpoint
    Assert-ExitCode 0 $checkpointRun 'Should_ExitZero_When_DirectoryCheckpointWritten'

    $baselinePreflight = Invoke-Preflight $repoA
    Assert-ExitCode 0 $baselinePreflight 'Should_ExitZero_When_DirectoryBaselineRecorded'
    Assert-Field $baselinePreflight 'identity' $identity 'Should_KeepIdentity_When_OperationalBlocksWritten'

    $stateBaseline = Copy-State $repoA 'state-baseline'

    # A6: resolver eligibility, completion, and dependent eligibility.
    $firstDecision = Invoke-Resolver $planA $inputIdentity
    Assert-ExitCode 0 $firstDecision 'Should_ExitZero_When_FirstStepEligible'
    Assert-Field $firstDecision 'step' 'US01-S1' 'Should_SelectFirstStep_When_NothingCompleted'

    $completeRun = Invoke-Setter $repoA $planA 'STEP:US01-S1' (New-StepPayload 'US01-S1' 'COMPLETED' '[]' $refs)
    Assert-ExitCode 0 $completeRun 'Should_ExitZero_When_FirstStepCompleted'

    $secondDecision = Invoke-Resolver $planA $inputIdentity
    Assert-ExitCode 0 $secondDecision 'Should_ExitZero_When_DependentStepEligible'
    Assert-Field $secondDecision 'step' 'US01-S2' 'Should_SelectDependentStep_When_EvidenceSatisfied'

    $stateDone = Copy-State $repoA 'state-done'

    # Scenario B: one defect per copy of the state named in its header.
    $repoB1 = Copy-State $stateApproved 'b1-normative-edit'
    $planB1 = Get-RepoPath $repoB1 $planRelative
    Edit-File $planB1 'Validation: synthetic check one' 'Validation: changed check one'
    $b1Resolver = Invoke-Resolver $planB1 $inputIdentity
    Assert-ExitCode 1 $b1Resolver 'Should_ExitOne_When_NormativeTextEditedAfterApproval'
    Assert-Field $b1Resolver 'reason' 'approval_identity_stale' 'Should_ReturnApprovalIdentityStale_When_NormativeTextEditedAfterApproval'
    $b1Preflight = Invoke-Preflight $repoB1 @('-ExpectedIdentity', $identity)
    Assert-ExitCode 3 $b1Preflight 'Should_ExitThree_When_NormativeTextEditedAfterApproval'
    Assert-Issue $b1Preflight 'identity_changed' 'Should_ReturnIdentityChanged_When_NormativeTextEditedAfterApproval'

    $repoB2 = Copy-State $stateApproved 'b2-legacy-marker'
    $planB2 = Get-RepoPath $repoB2 $planRelative
    Edit-File $planB2 '<!-- DELIVERY:STEP:US01-S1:BEGIN -->' '<!-- DELIVERY:STEP-US01-S1:BEGIN -->'
    $b2Resolver = Invoke-Resolver $planB2 $inputIdentity
    Assert-ExitCode 1 $b2Resolver 'Should_ExitOne_When_LegacyStepMarkerPresent'
    Assert-Field $b2Resolver 'reason' 'legacy_marker' 'Should_ReturnLegacyMarker_When_LegacyStepMarkerPresent'
    $b2Preflight = Invoke-Preflight $repoB2
    Assert-ExitCode 3 $b2Preflight 'Should_ExitThree_When_LegacyStepMarkerPresent'
    Assert-Issue $b2Preflight 'grammar_invalid' 'Should_ReturnGrammarInvalid_When_LegacyStepMarkerPresent'

    $repoB3 = Copy-State $stateBaseline 'b3-baseline-edit'
    $planB3 = Get-RepoPath $repoB3 $planRelative
    [System.IO.File]::WriteAllText((Get-RepoPath $repoB3 $baselineRelative), 'tampered baseline content', $utf8)
    $b3Resolver = Invoke-Resolver $planB3 $inputIdentity
    Assert-ExitCode 1 $b3Resolver 'Should_ExitOne_When_BaselineEvidenceEditedAfterRecording'
    Assert-Field $b3Resolver 'reason' 'baseline_changed' 'Should_ReturnBaselineChanged_When_BaselineEvidenceEditedAfterRecording'

    $repoB4 = Copy-State $stateReviewed 'b4-record-deleted'
    Remove-Item -LiteralPath (Get-RepoPath $repoB4 $recordRelative) -Force
    $b4Check = Invoke-Cli -Script $cli.TestRecord -Arguments @('-RepoPath', $repoB4, '-TargetPath', $planRelative, '-RecordPath', (Get-RepoPath $repoB4 $recordRelative))
    Assert-ExitCode 3 $b4Check 'Should_ExitThree_When_ReviewRecordDeleted'
    Assert-Field $b4Check 'reason' 'record_missing' 'Should_ReturnRecordMissing_When_ReviewRecordDeleted'

    $repoB5 = Copy-State $stateReviewed 'b5-input-edit'
    Edit-File (Get-RepoPath $repoB5 $refinementRelative) 'Normative body:' ('Changed after review.' + "`n" + 'Normative body:')
    $b5Check = Invoke-Cli -Script $cli.TestRecord -Arguments @('-RepoPath', $repoB5, '-TargetPath', $planRelative, '-RecordPath', (Get-RepoPath $repoB5 $recordRelative))
    Assert-ExitCode 3 $b5Check 'Should_ExitThree_When_DeclaredInputEditedAfterRecord'
    Assert-Field $b5Check 'reason' 'inputs_changed' 'Should_ReturnInputsChanged_When_DeclaredInputEditedAfterRecord'

    $repoB6 = Copy-State $stateApproved 'b6-unknown-key'
    $planB6 = Get-RepoPath $repoB6 $planRelative
    $beforeB6 = Get-FileBase64 $planB6
    $b6Setter = Invoke-Setter $repoB6 $planB6 'STEP:US01-S1' '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[],"bogus":"x"}'
    Assert-ExitCode 1 $b6Setter 'Should_ExitOne_When_SetterPayloadHasUnknownKey'
    Assert-Field $b6Setter 'code' 'invalid_payload' 'Should_ReturnInvalidPayload_When_SetterPayloadHasUnknownKey'
    Assert-Equal 'True' ([string]((Get-FileBase64 $planB6) -ceq $beforeB6)) 'Should_LeaveFileUnchanged_When_SetterPayloadHasUnknownKey'

    $repoB7 = Copy-State $stateApproved 'b7-depends-tampered'
    $planB7 = Get-RepoPath $repoB7 $planRelative
    $b7Setter = Invoke-Setter $repoB7 $planB7 'STEP:US01-S2' '{"schema":"delivery-step/v1","id":"US01-S2","status":"PENDING","depends_on":[]}'
    Assert-ExitCode 0 $b7Setter 'Should_ExitZero_When_OperationalDependsOnRewritten'
    $b7Preflight = Invoke-Preflight $repoB7
    Assert-ExitCode 3 $b7Preflight 'Should_ExitThree_When_StepDependsOnDiffersFromDeclared'
    Assert-Issue $b7Preflight 'depends_on_mismatch' 'Should_ReturnDependsOnMismatch_When_StepDependsOnDiffersFromDeclared'

    $repoB9 = Copy-State $stateApproved 'b9-operational-edit'
    $planB9 = Get-RepoPath $repoB9 $planRelative
    $b9Setter = Invoke-Setter $repoB9 $planB9 'PROGRESS' '{"schema":"delivery-progress/v1","cadence":"step_by_step","current_stage":"implementation"}'
    Assert-ExitCode 0 $b9Setter 'Should_ExitZero_When_ProgressStageWritten'
    $b9Preflight = Invoke-Preflight $repoB9 @('-ExpectedIdentity', $identity)
    Assert-ExitCode 0 $b9Preflight 'Should_ExitZero_When_OnlyOperationalBlockChanged'
    Assert-Field $b9Preflight 'identity' $identity 'Should_KeepIdentity_When_OnlyOperationalBlockChanged'
    $b9Resolver = Invoke-Resolver $planB9 $inputIdentity
    Assert-ExitCode 0 $b9Resolver 'Should_ExitZero_When_OnlyOperationalBlockChangedResolver'
    Assert-Field $b9Resolver 'step' 'US01-S1' 'Should_KeepEligibility_When_OnlyOperationalBlockChanged'

    # B8: the S2 evidence reference is removed after S1 completed.
    $repoB8 = Copy-State $stateDone 'b8-result-ref-removed'
    $planB8 = Get-RepoPath $repoB8 $planRelative
    $refsNoResult = '[' + (New-RefJson 'baseline' $baselineRelative $baselineSha) + ']'
    $b8Setter = Invoke-Setter $repoB8 $planB8 'STEP:US01-S1' (New-StepPayload 'US01-S1' 'COMPLETED' '[]' $refsNoResult)
    Assert-ExitCode 0 $b8Setter 'Should_ExitZero_When_ResultReferenceRemoved'
    $b8Resolver = Invoke-Resolver $planB8 $inputIdentity
    Assert-ExitCode 1 $b8Resolver 'Should_ExitOne_When_ResultReferenceRemoved'
    Assert-Field $b8Resolver 'reason' 'evidence_missing' 'Should_ReturnEvidenceMissing_When_ResultReferenceRemoved'
    Assert-Field $b8Resolver 'evidence' 'US01-S1/result' 'Should_NameResultReference_When_ResultReferenceRemoved'

    # B8b: the baseline reference is removed; the unit-level precondition denies every selection.
    $repoB8b = Copy-State $stateBaseline 'b8b-baseline-ref-removed'
    $planB8b = Get-RepoPath $repoB8b $planRelative
    $refsNoBaseline = '[' + (New-RefJson 'result' $resultRelative $resultSha) + ']'
    $b8bSetter = Invoke-Setter $repoB8b $planB8b 'STEP:US01-S1' (New-StepPayload 'US01-S1' 'PENDING' '[]' $refsNoBaseline)
    Assert-ExitCode 0 $b8bSetter 'Should_ExitZero_When_BaselineReferenceRemoved'
    $b8bFirst = Invoke-Resolver $planB8b $inputIdentity
    Assert-ExitCode 1 $b8bFirst 'Should_ExitOne_When_BaselineReferenceRemovedBeforeFirstSelection'
    Assert-Field $b8bFirst 'reason' 'baseline_missing' 'Should_ReturnBaselineMissing_When_BaselineReferenceRemovedBeforeFirstSelection'
    $b8bCompleted = Invoke-Setter $repoB8b $planB8b 'STEP:US01-S1' (New-StepPayload 'US01-S1' 'COMPLETED' '[]' $refsNoBaseline)
    Assert-ExitCode 0 $b8bCompleted 'Should_ExitZero_When_BaselineReferenceRemovedAfterCompletion'
    $b8bSecond = Invoke-Resolver $planB8b $inputIdentity
    Assert-ExitCode 1 $b8bSecond 'Should_ExitOne_When_BaselineReferenceRemovedAfterCompletion'
    Assert-Field $b8bSecond 'reason' 'baseline_missing' 'Should_ReturnBaselineMissing_When_BaselineReferenceRemovedAfterCompletion'

    # B8c: the result evidence file is edited after recording; S2 must be denied.
    $repoB8c = Copy-State $stateDone 'b8c-result-file-edit'
    $planB8c = Get-RepoPath $repoB8c $planRelative
    [System.IO.File]::WriteAllText((Get-RepoPath $repoB8c $resultRelative), 'tampered result content', $utf8)
    $b8cResolver = Invoke-Resolver $planB8c $inputIdentity
    Assert-ExitCode 1 $b8cResolver 'Should_ExitOne_When_ResultEvidenceEditedAfterRecording'
    Assert-Field $b8cResolver 'reason' 'evidence_changed' 'Should_ReturnEvidenceChanged_When_ResultEvidenceEditedAfterRecording'
    Assert-Field $b8cResolver 'evidence' 'US01-S1/result' 'Should_NameResultReference_When_ResultEvidenceEditedAfterRecording'

    Write-Output ('PASS: {0} delivery end-to-end assertions.' -f $passed)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
