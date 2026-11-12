#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptsRoot = Split-Path -Parent $PSScriptRoot
$preflight = Join-Path $scriptsRoot 'runtime/Test-DeliveryPlanPreflight.ps1'
. (Join-Path $scriptsRoot '_lib/DeliveryGrammar.ps1')

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-plan-preflight-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0
$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false
$lf = "`n"
$planRelative = 'features/001-demo/US01/PLAN.md'
$draftRelative = 'features/001-demo/scratch/delivery-review/draft-1.md'
$placeholderIdentity = '0' * 64
$progressJson = '{"schema":"delivery-progress/v1","cadence":"continuous"}'
$checkpointJson = '{"schema":"delivery-checkpoint/v1","branch":"codex/test","head":"abc123","active_step":null}'

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Get-DeclaredDependencyIds {
    param([AllowNull()][object] $Line)

    if ($null -eq $Line) { return $null }
    $text = [string]$Line
    if ($text -ceq 'none') { return , ([string[]]@()) }
    return , ([string[]]@($text -split ',' | ForEach-Object { $_.Trim() }))
}

function ConvertTo-JsonStringArray {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $Items)

    return '[' + (@($Items | ForEach-Object { '"' + $_ + '"' }) -join ',') + ']'
}

function Build-PlanText {
    param(
        [Parameter(Mandatory = $true)][object[]] $Declared,
        [object[]] $Blocks = $null,
        [Parameter(Mandatory = $true)][string] $ApprovalIdentity,
        [string] $ApprovalState = 'approved',
        [string] $ProgressJson = $progressJson,
        [bool] $NoStepsHeading = $false,
        [string] $CheckpointJson = $checkpointJson
    )

    if ($null -eq $Blocks) {
        $Blocks = @(foreach ($step in $Declared) { @{ Id = [string]$step.Id; Depends = (Get-DeclaredDependencyIds $step.Depends) } })
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]]@('# Test plan', '', 'Normative body: feature behavior.', ''))
    if (-not $NoStepsHeading) { $lines.AddRange([string[]]@('## Steps', '')) }
    foreach ($step in $Declared) {
        $lines.Add(('### {0} Title {0}' -f $step.Id))
        if ($null -ne $step.Depends) { $lines.Add('Depends on: ' + [string]$step.Depends) }
        if ($null -ne $step['Evidence']) { $lines.Add('Evidence: ' + [string]$step['Evidence']) }
        if ($null -ne $step['Needs']) { $lines.Add('Needs evidence: ' + [string]$step['Needs']) }
        if ($null -ne $step.Validation) { $lines.Add('Validation: ' + [string]$step.Validation) }
        $lines.Add('')
    }

    $approval = '{{"schema":"delivery-approval/v1","state":"{0}","identity":"{1}","input_identity":"{2}","review_identity":"{3}","review_state":"reviewed"}}' -f $ApprovalState, $ApprovalIdentity, ('A' * 64), ('B' * 64)
    $lines.AddRange([string[]]@(
        '<!-- DELIVERY:PROGRESS:BEGIN -->', $ProgressJson, '<!-- DELIVERY:PROGRESS:END -->',
        '<!-- DELIVERY:CHECKPOINT:BEGIN -->', $CheckpointJson, '<!-- DELIVERY:CHECKPOINT:END -->',
        '<!-- DELIVERY:APPROVAL:BEGIN -->', $approval, '<!-- DELIVERY:APPROVAL:END -->'))

    foreach ($block in $Blocks) {
        $dependsJson = ''
        if ($null -ne $block.Depends) { $dependsJson = ',"depends_on":' + (ConvertTo-JsonStringArray -Items ([string[]]$block.Depends)) }
        $refsJson = ''
        if ($null -ne $block['Refs']) { $refsJson = ',"evidence_refs":' + [string]$block['Refs'] }
        $payload = '{{"schema":"delivery-step/v1","id":"{0}","status":"PENDING"{1}{2}}}' -f $block.Id, $dependsJson, $refsJson
        $lines.AddRange([string[]]@(
            ('<!-- DELIVERY:STEP:{0}:BEGIN -->' -f $block.Id), $payload, ('<!-- DELIVERY:STEP:{0}:END -->' -f $block.Id)))
    }

    return (($lines -join $lf) + $lf)
}

function New-PlanText {
    param(
        [Parameter(Mandatory = $true)][object[]] $Declared,
        [object[]] $Blocks = $null,
        [string] $ApprovalIdentity = 'AUTO',
        [string] $ApprovalState = 'approved',
        [string] $ProgressJson = $progressJson,
        [switch] $NoStepsHeading,
        [string] $CheckpointJson = $checkpointJson
    )

    $common = @{
        Declared      = $Declared
        Blocks        = $Blocks
        ApprovalState = $ApprovalState
        ProgressJson  = $ProgressJson
        NoStepsHeading = [bool]$NoStepsHeading
        CheckpointJson = $CheckpointJson
    }
    $identity = $ApprovalIdentity
    if ($ApprovalIdentity -ceq 'AUTO') {
        $probe = Build-PlanText @common -ApprovalIdentity $placeholderIdentity
        $identity = Get-DeliveryNormativeIdentity -Text $probe
    }
    return Build-PlanText @common -ApprovalIdentity $identity
}

function Write-PlanFile {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Text,
        [string] $RelativePath = $planRelative
    )

    $repo = Join-Path $tempRoot $Name
    $path = Join-Path $repo ($RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [System.IO.File]::WriteAllText($path, $Text, $utf8)
    return $repo
}

function Invoke-Preflight {
    param(
        [Parameter(Mandatory = $true)][string] $Repo,
        [string[]] $Extra = @(),
        [string] $PlanPath = $planRelative
    )

    $checkParams = @{ RepoPath = $Repo; PlanPath = $PlanPath; AsLibrary = $true }
    for ($index = 0; $index -lt $Extra.Count; $index += 2) {
        $name = ([string]$Extra[$index]).TrimStart('-')
        if ($index + 1 -ge $Extra.Count) { throw "Missing value for preflight parameter '$name'." }
        $checkParams[$name] = $Extra[$index + 1]
    }
    $parsed = & $preflight @checkParams
    $issues = @($parsed.issues)
    $isRuntimeError = @($issues | Where-Object { [string]$_.code -ceq 'preflight_error' }).Count -gt 0
    $exitCode = if ($isRuntimeError) { 1 } elseif ($issues.Count -gt 0) { 3 } else { 0 }
    $stdoutText = $parsed | ConvertTo-Json -Compress -Depth 5
    return [pscustomobject]@{ ExitCode = $exitCode; Result = $parsed; Stdout = $stdoutText; Stderr = '' }
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Get-IssueCodes($Run) {
    if ($null -eq $Run.Result) { return @() }
    return @(@($Run.Result.issues) | ForEach-Object { [string]$_.code })
}

function Assert-ExitCode([int]$Expected, $Run, [string]$Name) {
    Assert-Equal ([string]$Expected) ([string]$Run.ExitCode) $Name
}

function Assert-IssueCode($Run, [string]$Code, [string]$Name) {
    $codes = Get-IssueCodes $Run
    if ($codes -notcontains $Code) { throw ('{0}: expected issue {1}, got [{2}]' -f $Name, $Code, ($codes -join ', ')) }
    $script:passed++
}

function Assert-IssueStep($Run, [string]$Code, [string]$Step, [string]$Name) {
    $match = @(@($Run.Result.issues) | Where-Object { [string]$_.code -ceq $Code })
    if (($match.Count -eq 0) -or ([string]$match[0].step -cne $Step)) { throw ('{0}: expected issue {1} naming step {2}' -f $Name, $Code, $Step) }
    $script:passed++
}

$validDeclared = @(
    @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests' },
    @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' }
)

try {
    $validText = New-PlanText -Declared $validDeclared
    $validRepo = Write-PlanFile 'valid' $validText
    $valid = Invoke-Preflight -Repo $validRepo
    Assert-ExitCode 0 $valid 'Should_ExitZero_When_PlanIsValid'
    Assert-True ($valid.Result.ok -eq $true) 'Should_ReturnOk_When_PlanIsValid'
    Assert-True (([string]$valid.Result.identity).Length -eq 64) 'Should_ReturnIdentity_When_PlanIsValid'
    Assert-True ($validText.Contains('"depends_on":["US01-S1"]')) 'Should_CoverSingleDependencyArray_When_StepDependsOnOneStep'
    $identity = [string]$valid.Result.identity

    $draftRepo = Write-PlanFile 'draft-valid' $validText $draftRelative
    $draft = Invoke-Preflight -Repo $draftRepo -PlanPath $draftRelative
    Assert-ExitCode 0 $draft 'Should_ExitZero_When_DraftSnapshotIsInScratchDeliveryReview'
    Assert-True ($draft.Result.ok -eq $true) 'Should_ReturnOk_When_DraftSnapshotIsInScratchDeliveryReview'

    $otherScratchRelative = 'features/001-demo/scratch/other/draft-1.md'
    $otherScratchRepo = Write-PlanFile 'draft-other' $validText $otherScratchRelative
    $otherScratch = Invoke-Preflight -Repo $otherScratchRepo -PlanPath $otherScratchRelative
    Assert-ExitCode 3 $otherScratch 'Should_ExitThree_When_DraftIsInOtherScratchFolder'
    Assert-IssueCode $otherScratch 'plan_path_invalid' 'Should_ReturnPlanPathInvalid_When_DraftIsInOtherScratchFolder'

    $outsideRepo = Write-PlanFile 'outside-features' $validText 'docs/PLAN.md'
    $outside = Invoke-Preflight -Repo $outsideRepo -PlanPath 'docs/PLAN.md'
    Assert-ExitCode 1 $outside 'Should_ExitOne_When_PlanIsOutsideFeatures'

    $traversal = Invoke-Preflight -Repo $validRepo -PlanPath 'features/001-demo/../../../escape/PLAN.md'
    Assert-ExitCode 1 $traversal 'Should_ExitOne_When_PlanPathTraversesOutOfRepo'

    $absolute = Invoke-Preflight -Repo $validRepo -PlanPath (Join-Path $validRepo $planRelative)
    Assert-ExitCode 1 $absolute 'Should_ExitOne_When_PlanPathIsAbsolute'

    $missingPlan = Invoke-Preflight -Repo $validRepo -PlanPath 'features/001-demo/US02/PLAN.md'
    Assert-ExitCode 3 $missingPlan 'Should_ExitThree_When_PlanFileIsMissing'
    Assert-IssueCode $missingPlan 'plan_path_invalid' 'Should_ReturnPlanPathInvalid_When_PlanFileIsMissing'

    $missingStepRepo = Write-PlanFile 'missing-step' (New-PlanText -Declared $validDeclared -Blocks @(@{ Id = 'US01-S1'; Depends = [string[]]@() }))
    Assert-IssueCode (Invoke-Preflight -Repo $missingStepRepo) 'missing_step' 'Should_ReturnMissingStep_When_DeclaredStepHasNoBlock'

    $undeclaredRepo = Write-PlanFile 'undeclared' (New-PlanText -Declared $validDeclared -Blocks @(
        @{ Id = 'US01-S1'; Depends = [string[]]@() },
        @{ Id = 'US01-S2'; Depends = [string[]]@('US01-S1') },
        @{ Id = 'US01-S3'; Depends = [string[]]@() }))
    Assert-IssueCode (Invoke-Preflight -Repo $undeclaredRepo) 'undeclared_step' 'Should_ReturnUndeclaredStep_When_BlockIsNotDeclared'

    $mismatchRepo = Write-PlanFile 'depends-mismatch' (New-PlanText -Declared $validDeclared -Blocks @(
        @{ Id = 'US01-S1'; Depends = [string[]]@() },
        @{ Id = 'US01-S2'; Depends = [string[]]@() }))
    Assert-IssueCode (Invoke-Preflight -Repo $mismatchRepo) 'depends_on_mismatch' 'Should_ReturnDependsOnMismatch_When_BlockDiffersFromDeclared'

    $unknownDepRepo = Write-PlanFile 'unknown-dependency' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests' },
        @{ Id = 'US01-S2'; Depends = 'US01-S9'; Validation = 'run-tests' }))
    Assert-IssueCode (Invoke-Preflight -Repo $unknownDepRepo) 'dependency_unknown' 'Should_ReturnDependencyUnknown_When_DependencyIsNotDeclared'

    $selfRepo = Write-PlanFile 'self-dependency' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'US01-S1'; Validation = 'run-tests' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' }))
    Assert-IssueCode (Invoke-Preflight -Repo $selfRepo) 'dependency_self' 'Should_ReturnDependencySelf_When_StepDependsOnItself'

    $cycleRepo = Write-PlanFile 'cycle' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'US01-S3'; Validation = 'run-tests' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' },
        @{ Id = 'US01-S3'; Depends = 'US01-S2'; Validation = 'run-tests' }))
    $cycle = Invoke-Preflight -Repo $cycleRepo
    Assert-IssueCode $cycle 'dependency_cycle' 'Should_ReturnDependencyCycle_When_StepsFormCycle'
    Assert-ExitCode 3 $cycle 'Should_ExitThree_When_DependencyCycleExists'

    $validationRepo = Write-PlanFile 'validation-missing' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = $null }))
    Assert-IssueCode (Invoke-Preflight -Repo $validationRepo) 'step_validation_missing' 'Should_ReturnStepValidationMissing_When_ValidationLineAbsent'

    $dependsRepo = Write-PlanFile 'depends-missing' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests' },
        @{ Id = 'US01-S2'; Depends = $null; Validation = 'run-tests' }))
    Assert-IssueCode (Invoke-Preflight -Repo $dependsRepo) 'step_depends_missing' 'Should_ReturnStepDependsMissing_When_DependsOnLineAbsent'

    $duplicateRepo = Write-PlanFile 'duplicate-declared' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' },
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests' }) -Blocks @(
        @{ Id = 'US01-S1'; Depends = [string[]]@() },
        @{ Id = 'US01-S2'; Depends = [string[]]@('US01-S1') }))
    Assert-IssueCode (Invoke-Preflight -Repo $duplicateRepo) 'duplicate_declared_step' 'Should_ReturnDuplicateDeclaredStep_When_IdRepeats'

    $noSectionRepo = Write-PlanFile 'no-steps-section' (New-PlanText -Declared $validDeclared -NoStepsHeading)
    Assert-IssueCode (Invoke-Preflight -Repo $noSectionRepo) 'steps_section_missing' 'Should_ReturnStepsSectionMissing_When_NoStepsHeading'

    $legacyText = $validText.Replace('<!-- DELIVERY:STEP:', '<!-- DELIVERY:STEP-')
    Assert-True ($legacyText -cne $validText) 'Should_ChangeFixture_When_LegacyMarkerInserted'
    $legacyRepo = Write-PlanFile 'legacy-marker' $legacyText
    $legacy = Invoke-Preflight -Repo $legacyRepo
    Assert-IssueCode $legacy 'grammar_invalid' 'Should_ReturnGrammarInvalid_When_LegacyStepMarkerUsed'

    $hiddenText = $validText.Replace('"id":"US01-S2","status":"PENDING"', '"id":"US01-S2","status":"PENDING","hidden_note":"x"')
    Assert-True ($hiddenText -cne $validText) 'Should_ChangeFixture_When_HiddenPropertyInserted'
    $hiddenRepo = Write-PlanFile 'unknown-property' $hiddenText
    Assert-IssueCode (Invoke-Preflight -Repo $hiddenRepo) 'grammar_invalid' 'Should_ReturnGrammarInvalid_When_BlockHasUnknownProperty'

    $staleRepo = Write-PlanFile 'approval-stale' (New-PlanText -Declared $validDeclared -ApprovalIdentity $placeholderIdentity)
    Assert-IssueCode (Invoke-Preflight -Repo $staleRepo) 'approval_identity_stale' 'Should_ReturnApprovalIdentityStale_When_ApprovedIdentityDiffers'

    $missingBindingText = (New-PlanText -Declared $validDeclared -ApprovalIdentity 'AUTO').Replace(('"input_identity":"' + ('A' * 64) + '","review_identity":"' + ('B' * 64) + '"'), '"input_identity":"INPUT-1"')
    $missingBindingRepo = Write-PlanFile 'approval-missing-binding' $missingBindingText
    Assert-IssueCode (Invoke-Preflight -Repo $missingBindingRepo) 'approval_binding_missing' 'Should_RequireInputAndReviewBinding_When_ApprovalApproved'

    $pendingRepo = Write-PlanFile 'approval-pending' (New-PlanText -Declared $validDeclared -ApprovalState 'pending')
    $pending = Invoke-Preflight -Repo $pendingRepo
    Assert-ExitCode 0 $pending 'Should_ExitZero_When_ApprovalPendingAndNoReviewRecordGiven'
    Assert-True ($pending.Result.ok -eq $true) 'Should_ReturnOk_When_ApprovalPendingAndNoReviewRecordGiven'
    Assert-True ((Get-IssueCodes $pending) -notcontains 'review_gate_blocked') 'Should_NotReportReviewGate_When_NoReviewRecordGiven'

    $wrongExpected = Invoke-Preflight -Repo $validRepo -Extra @('-ExpectedIdentity', ('A' * 64))
    Assert-ExitCode 3 $wrongExpected 'Should_ExitThree_When_ExpectedIdentityDiffers'
    Assert-IssueCode $wrongExpected 'identity_changed' 'Should_ReturnIdentityChanged_When_ExpectedIdentityDiffers'

    $matchExpected = Invoke-Preflight -Repo $validRepo -Extra @('-ExpectedIdentity', $identity)
    Assert-ExitCode 0 $matchExpected 'Should_ExitZero_When_ExpectedIdentityMatches'

    $reviewMissing = Invoke-Preflight -Repo $validRepo -Extra @('-ReviewRecordPath', 'features/001-demo/delivery-reviews/missing.json')
    Assert-ExitCode 3 $reviewMissing 'Should_ExitThree_When_ReviewRecordMissing'
    Assert-IssueCode $reviewMissing 'review_gate_blocked' 'Should_ReturnReviewGateBlocked_When_ReviewRecordMissing'

    $operationalText = New-PlanText -Declared $validDeclared -ProgressJson '{"schema":"delivery-progress/v1","cadence":"continuous","current_stage":"implementation"}'
    $operationalRepo = Write-PlanFile 'operational-edit' $operationalText
    $operational = Invoke-Preflight -Repo $operationalRepo
    Assert-ExitCode 0 $operational 'Should_ExitZero_When_OnlyOperationalPayloadChanged'
    Assert-Equal $identity ([string]$operational.Result.identity) 'Should_KeepIdentity_When_OnlyOperationalPayloadChanged'

    $duplicateDependsRepo = Write-PlanFile 'duplicate-depends-line' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1, US01-S1'; Validation = 'run-tests' }) -Blocks @(
        @{ Id = 'US01-S1'; Depends = [string[]]@() },
        @{ Id = 'US01-S2'; Depends = [string[]]@('US01-S1') }))
    $duplicateDepends = Invoke-Preflight -Repo $duplicateDependsRepo
    Assert-ExitCode 0 $duplicateDepends 'Should_ExitZero_When_DependsOnRepeatsSameStep'
    Assert-True ($duplicateDepends.Result.ok -eq $true) 'Should_TreatRepeatedDependencyAsSet_When_DependsOnRepeatsSameStep'

    $validSha = 'A' * 64
    $evidenceDeclared = @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests'; Evidence = 'plan-snapshot' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' },
        @{ Id = 'US01-S3'; Depends = 'US01-S2'; Validation = 'run-tests'; Needs = 'US01-S1/plan-snapshot' })
    $evidenceBlocks = @(
        @{ Id = 'US01-S1'; Depends = [string[]]@(); Refs = ('[{"name":"plan-snapshot","path":"features/001-demo/US01/evidence/US01-S1--plan-snapshot.md","sha256":"' + $validSha + '"}]') },
        @{ Id = 'US01-S2'; Depends = [string[]]@('US01-S1') },
        @{ Id = 'US01-S3'; Depends = [string[]]@('US01-S2') })
    $directoryCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S1/plan-snapshot"}'
    $evidenceValidRepo = Write-PlanFile 'evidence-valid' (New-PlanText -Declared $evidenceDeclared -Blocks $evidenceBlocks -CheckpointJson $directoryCheckpoint)
    $evidenceValid = Invoke-Preflight -Repo $evidenceValidRepo
    Assert-ExitCode 0 $evidenceValid 'Should_ExitZero_When_EvidenceDeclarationsAreValid'
    Assert-True ($evidenceValid.Result.ok -eq $true) 'Should_ReturnOk_When_TransitivePredecessorProvidesEvidenceAndBaseline'

    $unknownSourceRepo = Write-PlanFile 'evidence-source-unknown' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests'; Evidence = 'plan-snapshot' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests'; Needs = 'US01-S9/plan-snapshot' }))
    $unknownSource = Invoke-Preflight -Repo $unknownSourceRepo
    Assert-IssueCode $unknownSource 'evidence_source_unknown' 'Should_ReturnEvidenceSourceUnknown_When_NeedsUndeclaredStep'
    Assert-IssueStep $unknownSource 'evidence_source_unknown' 'US01-S2' 'Should_NameNeedingStep_When_EvidenceSourceUnknown'

    $undeclaredNameRepo = Write-PlanFile 'evidence-name-undeclared' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests'; Evidence = 'plan-snapshot' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests'; Needs = 'US01-S1/other' }))
    $undeclaredName = Invoke-Preflight -Repo $undeclaredNameRepo
    Assert-IssueCode $undeclaredName 'evidence_name_undeclared' 'Should_ReturnEvidenceNameUndeclared_When_NameNotDeclaredByProducer'
    Assert-IssueStep $undeclaredName 'evidence_name_undeclared' 'US01-S2' 'Should_NameNeedingStep_When_EvidenceNameUndeclared'

    $notPredecessorRepo = Write-PlanFile 'evidence-not-predecessor' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests'; Evidence = 'plan-snapshot' },
        @{ Id = 'US01-S2'; Depends = 'none'; Validation = 'run-tests'; Needs = 'US01-S1/plan-snapshot' }))
    $notPredecessor = Invoke-Preflight -Repo $notPredecessorRepo
    Assert-IssueCode $notPredecessor 'evidence_source_not_predecessor' 'Should_ReturnEvidenceSourceNotPredecessor_When_ProducerIsNotDependency'
    Assert-IssueStep $notPredecessor 'evidence_source_not_predecessor' 'US01-S2' 'Should_NameNeedingStep_When_EvidenceSourceNotPredecessor'

    $selfSourceRepo = Write-PlanFile 'evidence-self-source' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests'; Evidence = 'plan-snapshot'; Needs = 'US01-S1/plan-snapshot' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' }))
    Assert-IssueCode (Invoke-Preflight -Repo $selfSourceRepo) 'evidence_source_not_predecessor' 'Should_ReturnEvidenceSourceNotPredecessor_When_StepNeedsItsOwnEvidence'

    $baselineUnknownRepo = Write-PlanFile 'baseline-unknown' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests'; Evidence = 'plan-snapshot' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' }) -CheckpointJson '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S9/plan-snapshot"}')
    $baselineUnknown = Invoke-Preflight -Repo $baselineUnknownRepo
    Assert-IssueCode $baselineUnknown 'baseline_reference_unknown' 'Should_ReturnBaselineReferenceUnknown_When_BaselineStepUndeclared'
    Assert-IssueStep $baselineUnknown 'baseline_reference_unknown' 'US01-S9' 'Should_NameReferencedStep_When_BaselineReferenceUnknown'

    $baselineNameRepo = Write-PlanFile 'baseline-name-unknown' (New-PlanText -Declared @(
        @{ Id = 'US01-S1'; Depends = 'none'; Validation = 'run-tests'; Evidence = 'plan-snapshot' },
        @{ Id = 'US01-S2'; Depends = 'US01-S1'; Validation = 'run-tests' }) -CheckpointJson '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S1/other"}')
    Assert-IssueCode (Invoke-Preflight -Repo $baselineNameRepo) 'baseline_reference_unknown' 'Should_ReturnBaselineReferenceUnknown_When_BaselineNameUndeclared'

    # Plan-to-plan dependencies

    function Add-DependencySection([string]$Text, [string[]]$Lines) {
        $section = (@('## Plan dependencies', '') + $Lines + '') -join $lf
        $index = $Text.IndexOf('## Steps' + $lf, [System.StringComparison]::Ordinal)
        if ($index -lt 0) { throw 'fixture marker missing' }
        return $Text.Insert($index, $section + $lf)
    }

    function New-DependentPlanText([object[]]$Declared, [string[]]$Lines) {
        $probe = Add-DependencySection (Build-PlanText -Declared $Declared -ApprovalIdentity $placeholderIdentity) $Lines
        $dependentIdentity = Get-DeliveryNormativeIdentity -Text $probe
        return $probe.Replace('"identity":"' + $placeholderIdentity + '"', '"identity":"' + $dependentIdentity + '"')
    }

    function Add-RepoPlan([string]$Repo, [string]$RelativePath, [string]$Text) {
        $path = Join-Path $Repo ($RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        [System.IO.File]::WriteAllText($path, $Text, $utf8)
    }

    function Assert-IssueMessage($Run, [string]$Code, [string]$Fragment, [string]$Name) {
        $match = @(@($Run.Result.issues) | Where-Object { ([string]$_.code -ceq $Code) -and ([string]$_.message).Contains($Fragment) })
        if ($match.Count -eq 0) { throw ('{0}: expected issue {1} naming {2}' -f $Name, $Code, $Fragment) }
        $script:passed++
    }

    $depPredecessor = 'features/001-demo/US01/PLAN.md'
    $depRepo = Write-PlanFile 'dependency-base' $validText
    $depValidLine = 'Requires plan: ' + $depPredecessor + ' identity=' + $identity + ' steps=US01-S1'
    Add-RepoPlan $depRepo 'features/001-demo/US02/PLAN.md' (New-DependentPlanText -Declared $validDeclared -Lines @($depValidLine))
    $depValid = Invoke-Preflight -Repo $depRepo -PlanPath 'features/001-demo/US02/PLAN.md'
    Assert-ExitCode 0 $depValid 'Should_ExitZero_When_DependentPlanIsValid'
    Assert-True ($depValid.Result.ok -eq $true) 'Should_ReturnOk_When_DependentPlanIsValid'
    Assert-True (([string]$depValid.Result.identity).Length -eq 64) 'Should_ReturnIdentity_When_DependentPlanIsValid'
    Assert-True ((Get-IssueCodes $depValid) -notcontains 'plan_dependency_step_incomplete') 'Should_NotRequireCompletion_When_PredecessorStepIsPending'

    $depBadHexLine = 'Requires plan: ' + $depPredecessor + ' identity=' + $identity.ToLowerInvariant() + ' steps=US01-S1'
    Add-RepoPlan $depRepo 'features/001-demo/US03/PLAN.md' (New-DependentPlanText -Declared $validDeclared -Lines @($depBadHexLine))
    $depBadHex = Invoke-Preflight -Repo $depRepo -PlanPath 'features/001-demo/US03/PLAN.md'
    Assert-ExitCode 3 $depBadHex 'Should_ExitThree_When_DependencyIdentityMalformed'
    Assert-IssueCode $depBadHex 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_DependencyLineMalformed'

    $depMissingPath = 'features/001-demo/US09/PLAN.md'
    $depMissingLine = 'Requires plan: ' + $depMissingPath + ' identity=' + $identity + ' steps=US09-S1'
    Add-RepoPlan $depRepo 'features/001-demo/US04/PLAN.md' (New-DependentPlanText -Declared $validDeclared -Lines @($depMissingLine))
    $depMissing = Invoke-Preflight -Repo $depRepo -PlanPath 'features/001-demo/US04/PLAN.md'
    Assert-IssueCode $depMissing 'plan_dependency_missing' 'Should_ReturnPlanDependencyMissing_When_PredecessorFileAbsent'
    Assert-IssueMessage $depMissing 'plan_dependency_missing' $depMissingPath 'Should_NameDependencyPath_When_PredecessorFileAbsent'

    $depChangedLine = 'Requires plan: ' + $depPredecessor + ' identity=' + ('C' * 64) + ' steps=US01-S1'
    Add-RepoPlan $depRepo 'features/001-demo/US05/PLAN.md' (New-DependentPlanText -Declared $validDeclared -Lines @($depChangedLine))
    $depChanged = Invoke-Preflight -Repo $depRepo -PlanPath 'features/001-demo/US05/PLAN.md'
    Assert-IssueCode $depChanged 'plan_dependency_identity_changed' 'Should_ReturnPlanDependencyIdentityChanged_When_DeclaredIdentityDiffers'
    Assert-IssueMessage $depChanged 'plan_dependency_identity_changed' $depPredecessor 'Should_NameDependencyPath_When_IdentityChanged'

    $depUnknownStepLine = 'Requires plan: ' + $depPredecessor + ' identity=' + $identity + ' steps=US01-S9'
    Add-RepoPlan $depRepo 'features/001-demo/US06/PLAN.md' (New-DependentPlanText -Declared $validDeclared -Lines @($depUnknownStepLine))
    $depUnknownStep = Invoke-Preflight -Repo $depRepo -PlanPath 'features/001-demo/US06/PLAN.md'
    Assert-IssueCode $depUnknownStep 'plan_dependency_step_unknown' 'Should_ReturnPlanDependencyStepUnknown_When_StepNotDeclaredByPredecessor'
    Assert-IssueMessage $depUnknownStep 'plan_dependency_step_unknown' $depPredecessor 'Should_NameDependencyPath_When_StepUnknown'

    $depCycleA = 'features/001-demo/US07/PLAN.md'
    $depCycleB = 'features/001-demo/US08/PLAN.md'
    $depCycleLineToB = 'Requires plan: ' + $depCycleB + ' identity=' + ('D' * 64) + ' steps=US01-S1'
    $depCycleLineToA = 'Requires plan: ' + $depCycleA + ' identity=' + ('D' * 64) + ' steps=US01-S1'
    Add-RepoPlan $depRepo $depCycleA (New-DependentPlanText -Declared $validDeclared -Lines @($depCycleLineToB))
    Add-RepoPlan $depRepo $depCycleB (New-DependentPlanText -Declared $validDeclared -Lines @($depCycleLineToA))
    $depCycle = Invoke-Preflight -Repo $depRepo -PlanPath $depCycleA
    Assert-IssueCode $depCycle 'plan_dependency_cycle' 'Should_ReturnPlanDependencyCycle_When_PredecessorsReturnToPlan'
    Assert-IssueMessage $depCycle 'plan_dependency_cycle' $depCycleB 'Should_NameDependencyPath_When_CycleFound'

    $depSelfPath = 'features/001-demo/US10/PLAN.md'
    $depSelfLine = 'Requires plan: ' + $depSelfPath + ' identity=' + ('E' * 64) + ' steps=US01-S1'
    Add-RepoPlan $depRepo $depSelfPath (New-DependentPlanText -Declared $validDeclared -Lines @($depSelfLine))
    $depSelf = Invoke-Preflight -Repo $depRepo -PlanPath $depSelfPath
    Assert-IssueCode $depSelf 'plan_dependency_cycle' 'Should_ReturnPlanDependencyCycle_When_PlanRequiresItself'

    $depStrayLine = 'Requires plan: ' + $depPredecessor + ' identity=' + $identity + ' steps=US01-S1'
    $depStrayText = (Build-PlanText -Declared $validDeclared -ApprovalIdentity $identity).Replace('## Steps' + $lf, $depStrayLine + $lf + $lf + '## Steps' + $lf)
    Add-RepoPlan $depRepo 'features/001-demo/US11/PLAN.md' $depStrayText
    $depStray = Invoke-Preflight -Repo $depRepo -PlanPath 'features/001-demo/US11/PLAN.md'
    Assert-ExitCode 3 $depStray 'Should_ExitThree_When_RequiresLineOutsideHeading'
    Assert-IssueCode $depStray 'plan_dependency_invalid' 'Should_ReturnPlanDependencyInvalid_When_RequiresLineOutsideHeading'

    $writerScript = Join-Path $scriptsRoot 'runtime/Write-DeliveryReviewRecord.ps1'
    $sourceDocs = Join-Path $tempRoot 'preflight-sources\docs'
    New-Item -ItemType Directory -Path $sourceDocs -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $sourceDocs 'brief.md'), "# Brief`n", $utf8)
    $sourceCatalog = Join-Path $tempRoot 'preflight-sources\aliases.json'
    $sourceCatalogDocument = [ordered]@{ schema = 'delivery-input-aliases/v1'; aliases = @([ordered]@{ name = 'docs'; root = $sourceDocs; kind = 'directory' }) }
    [System.IO.File]::WriteAllText($sourceCatalog, ($sourceCatalogDocument | ConvertTo-Json -Depth 6), $utf8)
    $aliasRepo = Write-PlanFile 'alias-review' $validText
    $aliasRecordRel = 'features/001-demo/delivery-reviews/alias.json'
    $aliasRecordJson = '{"schema":"delivery-review-record/v1","state":"reviewed","inputs":[{"id":"SRC-1","path":"alias:docs/brief.md","role":"accepted refinement","impacted_ids":["S1"]}],"reviewers":{"reader":{"host":"Codex","observed_isolation":"fresh-context-instruction","result":{"paraphrases":{"proposal":"A plan.","current_system":"A baseline."},"lenses":["comprehension"],"findings":[]}},"critic":{"host":"Codex","observed_isolation":"fresh-context-instruction","result":{"lenses":["scope"],"findings":[]}}},"dispositions":[],"provenance":{}}'
    $aliasWrite = & $writerScript -Action save -RepoPath $aliasRepo -TargetPath $planRelative -TargetKind PLAN.md -Stage delivery_unit_plan_review -ArtifactText $validText -RecordPath (Join-Path $aliasRepo 'features\001-demo\delivery-reviews\alias.json') -RecordJson $aliasRecordJson -AliasCatalogPath $sourceCatalog
    Assert-True ([string]$aliasWrite -match '"status":"saved"') 'Should_SaveAliasReviewRecord_When_CatalogGiven'

    $aliasRecord = Get-Content -LiteralPath (Join-Path $aliasRepo 'features\001-demo\delivery-reviews\alias.json') -Raw | ConvertFrom-Json
    $aliasPlanPath = Join-Path $aliasRepo ($planRelative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    $aliasPlanText = [System.IO.File]::ReadAllText($aliasPlanPath)
    $placeholderBindings = '"input_identity":"' + ('A' * 64) + '","review_identity":"' + ('B' * 64) + '"'
    $correctBindings = '"input_identity":"' + $aliasRecord.material_input_identity + '","review_identity":"' + $aliasRecord.target.review_identity + '"'
    $aliasPlanText = $aliasPlanText.Replace($placeholderBindings, $correctBindings)
    [System.IO.File]::WriteAllText($aliasPlanPath, $aliasPlanText, $utf8)

    $aliasWithCatalog = Invoke-Preflight -Repo $aliasRepo -Extra @('-ReviewRecordPath', $aliasRecordRel, '-AliasCatalogPath', $sourceCatalog)
    Assert-ExitCode 0 $aliasWithCatalog 'Should_ExitZero_When_AliasReviewRecordGetsCatalog'
    Assert-True ($aliasWithCatalog.Result.ok -eq $true) 'Should_ReturnOk_When_AliasReviewRecordGetsCatalog'

    $staleInputPlan = $aliasPlanText.Replace($aliasRecord.material_input_identity, ('C' * 64))
    [System.IO.File]::WriteAllText($aliasPlanPath, $staleInputPlan, $utf8)
    $staleInputBinding = Invoke-Preflight -Repo $aliasRepo -Extra @('-ReviewRecordPath', $aliasRecordRel, '-AliasCatalogPath', $sourceCatalog)
    Assert-ExitCode 3 $staleInputBinding 'Should_BlockWhen_ApprovedMaterialInputBindingDiffersFromVerifiedRecord'
    Assert-IssueCode $staleInputBinding 'approval_input_identity_stale' 'Should_ReportStaleMaterialInputBinding_When_ApprovedInputIdentityDiffers'

    $staleReviewPlan = $aliasPlanText.Replace($aliasRecord.target.review_identity, ('D' * 64))
    [System.IO.File]::WriteAllText($aliasPlanPath, $staleReviewPlan, $utf8)
    $staleReviewBinding = Invoke-Preflight -Repo $aliasRepo -Extra @('-ReviewRecordPath', $aliasRecordRel, '-AliasCatalogPath', $sourceCatalog)
    Assert-ExitCode 3 $staleReviewBinding 'Should_BlockWhen_ApprovedReviewBindingDiffersFromVerifiedRecord'
    Assert-IssueCode $staleReviewBinding 'approval_review_identity_stale' 'Should_ReportStaleReviewBinding_When_ApprovedReviewIdentityDiffers'

    [System.IO.File]::WriteAllText($aliasPlanPath, $aliasPlanText, $utf8)

    $aliasWithoutCatalog = Invoke-Preflight -Repo $aliasRepo -Extra @('-ReviewRecordPath', $aliasRecordRel)
    Assert-ExitCode 3 $aliasWithoutCatalog 'Should_ExitThree_When_AliasReviewRecordHasNoCatalog'
    Assert-IssueCode $aliasWithoutCatalog 'review_gate_blocked' 'Should_ReturnReviewGateBlocked_When_AliasReviewRecordHasNoCatalog'
    Assert-IssueMessage $aliasWithoutCatalog 'review_gate_blocked' 'input_source_unavailable' 'Should_NameInputSourceUnavailable_When_AliasReviewRecordHasNoCatalog'

    # Refinement references

    $refinementCli = Join-Path $scriptsRoot 'runtime/Get-DeliveryRefinementItems.ps1'
    $refinementRelative = 'features/001-demo/REFINEMENT.md'

    function Add-PlanSection([string]$Text, [string]$Heading, [string[]]$Lines) {
        $section = (@("## $Heading", '') + $Lines + '') -join $lf
        $index = $Text.IndexOf('## Steps' + $lf, [System.StringComparison]::Ordinal)
        if ($index -lt 0) { throw 'fixture marker missing' }
        return $Text.Insert($index, $section + $lf)
    }

    function New-RefinementPlanText([string[]]$Lines, [string]$Heading = 'Refinement references') {
        $probe = Add-PlanSection (Build-PlanText -Declared $validDeclared -ApprovalIdentity $placeholderIdentity) $Heading $Lines
        $planIdentity = Get-DeliveryNormativeIdentity -Text $probe
        return $probe.Replace('"identity":"' + $placeholderIdentity + '"', '"identity":"' + $planIdentity + '"')
    }

    function New-RefinementFixtureText([string]$D1 = 'Decision one.', [string]$D2 = 'Decision two.', [string]$State = 'approved') {
        $prefix = @('# Refinement', '', '### D-001 First decision', $D1, '', '### D-002 Second decision', $D2, '', '## Approval', '')
        $approval = '{"schema":"delivery-approval/v1","state":"' + $State + '","identity":"' + $placeholderIdentity + '","input_identity":"INPUT-1","review_state":"reviewed"}'
        $probe = (($prefix + @('<!-- DELIVERY:APPROVAL:BEGIN -->', $approval, '<!-- DELIVERY:APPROVAL:END -->', '')) -join $lf)
        $refinementIdentity = Get-DeliveryNormativeIdentity -Text $probe
        return $probe.Replace('"identity":"' + $placeholderIdentity + '"', '"identity":"' + $refinementIdentity + '"')
    }

    function Get-RefinementItemHash([string]$Text, [string]$Id) {
        $found = @(@((Get-DeliveryRefinementItems -Text $Text).Items) | Where-Object { $_.Id -ceq $Id })
        return [string]$found[0].Hash
    }

    function Invoke-RefinementCli([string[]]$Arguments) {
        $cliParams = @{}
        for ($index = 0; $index -lt $Arguments.Count; $index += 2) {
            $name = ([string]$Arguments[$index]).TrimStart('-')
            if ($index + 1 -ge $Arguments.Count) { throw "Missing value for refinement CLI parameter '$name'." }
            $cliParams[$name] = $Arguments[$index + 1]
        }
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $childHost
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $refinementCli) + $Arguments
        $startInfo.Arguments = (@($argList | ForEach-Object { ConvertTo-ProcessArgument ([string]$_) }) -join ' ')
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.CreateNoWindow = $true
        $process = [System.Diagnostics.Process]::Start($startInfo)
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(15000)) {
            try { $process.Kill($true) } catch { }
            $process.WaitForExit()
            throw 'Refinement CLI exceeded the 15-second per-invocation limit; process tree was terminated.'
        }
        $stdoutText = $stdoutTask.Result
        $stderrText = $stderrTask.Result
        $parsed = $null
        try { $parsed = $stdoutText.Trim() | ConvertFrom-Json } catch { $parsed = $null }
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Result = $parsed; Stdout = $stdoutText; Stderr = $stderrText }
    }

    $refinementText = New-RefinementFixtureText
    $refinementHashD1 = Get-RefinementItemHash $refinementText 'D-001'
    $staleHash = 'F' * 64

    $refValidRepo = Write-PlanFile 'refinement-valid' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$refinementHashD1"))
    Add-RepoPlan $refValidRepo $refinementRelative $refinementText
    $refValid = Invoke-Preflight -Repo $refValidRepo
    Assert-ExitCode 0 $refValid 'Should_ExitZero_When_RefinementReferencesValidAndApproved'
    Assert-True ($refValid.Result.ok -eq $true) 'Should_ReturnOk_When_RefinementReferencesValidAndApproved'
    Assert-True (@(Get-IssueCodes $refValid).Count -eq 0) 'Should_ReturnNoIssues_When_ApprovalIdentityMatches'

    $refMalformedRepo = Write-PlanFile 'refinement-reference-invalid' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=abc"))
    Assert-IssueCode (Invoke-Preflight -Repo $refMalformedRepo) 'refinement_reference_invalid' 'Should_ReturnRefinementReferenceInvalid_When_UsesLineMalformed'

    $refDuplicateItemRepo = Write-PlanFile 'refinement-item-duplicate' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$refinementHashD1"))
    Add-RepoPlan $refDuplicateItemRepo $refinementRelative ($refinementText + "### D-001 Again`nx`n")
    Assert-IssueCode (Invoke-Preflight -Repo $refDuplicateItemRepo) 'refinement_reference_invalid' 'Should_ReturnRefinementReferenceInvalid_When_RefinementItemIdRepeats'

    $refBlockBrokenRepo = Write-PlanFile 'refinement-blocks-broken' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$refinementHashD1"))
    Add-RepoPlan $refBlockBrokenRepo $refinementRelative ($refinementText + "<!-- DELIVERY:APPROVAL:BEGIN -->`n")
    $refBlockBroken = Invoke-Preflight -Repo $refBlockBrokenRepo
    Assert-IssueCode $refBlockBroken 'refinement_reference_invalid' 'Should_ReturnRefinementReferenceInvalid_When_RefinementBlocksDoNotParse'

    $refMissingRepo = Write-PlanFile 'refinement-missing' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$refinementHashD1"))
    $refMissing = Invoke-Preflight -Repo $refMissingRepo
    Assert-IssueCode $refMissing 'refinement_reference_unknown' 'Should_ReturnRefinementReferenceUnknown_When_RefinementFileMissing'
    Assert-IssueMessage $refMissing 'refinement_reference_unknown' $refinementRelative 'Should_NameRefinementPath_When_RefinementFileMissing'

    $refUnknownIdRepo = Write-PlanFile 'refinement-unknown-id' (New-RefinementPlanText @("Uses: $refinementRelative D-009 hash=$refinementHashD1"))
    Add-RepoPlan $refUnknownIdRepo $refinementRelative $refinementText
    $refUnknownId = Invoke-Preflight -Repo $refUnknownIdRepo
    Assert-IssueCode $refUnknownId 'refinement_reference_unknown' 'Should_ReturnRefinementReferenceUnknown_When_IdIsNotAnItem'
    Assert-IssueMessage $refUnknownId 'refinement_reference_unknown' 'D-009' 'Should_NameItemId_When_IdIsNotAnItem'

    $refStaleRepo = Write-PlanFile 'refinement-stale' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$staleHash"))
    Add-RepoPlan $refStaleRepo $refinementRelative $refinementText
    $refStale = Invoke-Preflight -Repo $refStaleRepo
    Assert-IssueCode $refStale 'refinement_reference_stale' 'Should_ReturnRefinementReferenceStale_When_HashDiffers'
    Assert-IssueMessage $refStale 'refinement_reference_stale' 'D-001' 'Should_NameItemId_When_ReferenceStale'

    $supersededRefinement = New-RefinementFixtureText -D1 "Old decision.`nStatus: superseded by D-002"
    $supersededHash = Get-RefinementItemHash $supersededRefinement 'D-001'
    $refSupersededRepo = Write-PlanFile 'refinement-superseded' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$staleHash"))
    Add-RepoPlan $refSupersededRepo $refinementRelative $supersededRefinement
    $refSuperseded = Invoke-Preflight -Repo $refSupersededRepo
    Assert-IssueCode $refSuperseded 'refinement_reference_superseded' 'Should_ReturnRefinementReferenceSuperseded_When_ItemSuperseded'
    Assert-True ((Get-IssueCodes $refSuperseded) -notcontains 'refinement_reference_stale') 'Should_NotReportStale_When_ItemSupersededEvenIfHashDiffers'
    Assert-IssueMessage $refSuperseded 'refinement_reference_superseded' 'D-002' 'Should_NameSupersedingItem_When_ItemSuperseded'

    $refSupersededCurrentRepo = Write-PlanFile 'refinement-superseded-current' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$supersededHash"))
    Add-RepoPlan $refSupersededCurrentRepo $refinementRelative $supersededRefinement
    Assert-IssueCode (Invoke-Preflight -Repo $refSupersededCurrentRepo) 'refinement_reference_superseded' 'Should_ReturnRefinementReferenceSuperseded_When_HashMatchesSupersededItem'

    $pendingRefinement = New-RefinementFixtureText -State 'pending'
    $refPendingRepo = Write-PlanFile 'refinement-pending' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$(Get-RefinementItemHash $pendingRefinement 'D-001')"))
    Add-RepoPlan $refPendingRepo $refinementRelative $pendingRefinement
    $refPending = Invoke-Preflight -Repo $refPendingRepo
    Assert-IssueCode $refPending 'refinement_not_approved' 'Should_ReturnRefinementNotApproved_When_ApprovalPending'
    Assert-True (@(Get-IssueCodes $refPending | Where-Object { $_ -ceq 'refinement_not_approved' }).Count -eq 1) 'Should_ReportNotApprovedOnce_When_RefinementReferencedTwice'

    $editedApprovedRefinement = $refinementText.Replace('Decision one.', 'Decision one edited.')
    Assert-True ($editedApprovedRefinement -cne $refinementText) 'Should_ChangeFixture_When_ApprovedTextEdited'
    $refEditedRepo = Write-PlanFile 'refinement-edited-after-approval' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$(Get-RefinementItemHash $editedApprovedRefinement 'D-001')"))
    Add-RepoPlan $refEditedRepo $refinementRelative $editedApprovedRefinement
    $refEdited = Invoke-Preflight -Repo $refEditedRepo
    Assert-IssueCode $refEdited 'refinement_not_approved' 'Should_ReturnRefinementNotApproved_When_NormativeTextEditedAfterApproval'

    $unrelatedEditRefinement = $refinementText.Replace('Decision two.', 'Decision two changed.')
    $refUnrelatedRepo = Write-PlanFile 'refinement-unrelated-edit' (New-RefinementPlanText @("Uses: $refinementRelative D-001 hash=$refinementHashD1"))
    Add-RepoPlan $refUnrelatedRepo $refinementRelative $unrelatedEditRefinement
    $refUnrelated = Invoke-Preflight -Repo $refUnrelatedRepo
    Assert-True ((Get-IssueCodes $refUnrelated) -notcontains 'refinement_reference_stale') 'Should_NotReportStale_When_UnrelatedItemEdited'

    $restateProbe = Add-PlanSection (Add-PlanSection (Build-PlanText -Declared $validDeclared -ApprovalIdentity $placeholderIdentity) 'Notes' @('### D-001 Restated decision', 'Copied text.', '')) 'Refinement references' @("Uses: $refinementRelative D-001 hash=$refinementHashD1")
    $restatePlanText = $restateProbe.Replace('"identity":"' + $placeholderIdentity + '"', '"identity":"' + (Get-DeliveryNormativeIdentity -Text $restateProbe) + '"')
    $restateRepo = Write-PlanFile 'refinement-restates-cited' $restatePlanText
    Add-RepoPlan $restateRepo $refinementRelative $refinementText
    $restate = Invoke-Preflight -Repo $restateRepo
    Assert-IssueCode $restate 'plan_restates_refinement_item' 'Should_ReturnPlanRestatesRefinementItem_When_PlanDeclaresCitedItemId'
    Assert-IssueMessage $restate 'plan_restates_refinement_item' 'D-001' 'Should_NameItemId_When_PlanRestates'

    $noRefinementRepo = Write-PlanFile 'refinement-none' (New-RefinementPlanText @())
    $noRefinement = Invoke-Preflight -Repo $noRefinementRepo
    Assert-ExitCode 0 $noRefinement 'Should_ExitZero_When_PlanHasNoRefinementReferences'

    # refinement CLI

    $cliRepo = Write-PlanFile 'refinement-cli' $validText
    Add-RepoPlan $cliRepo $refinementRelative $refinementText
    $cliAll = Invoke-RefinementCli @('-RepoPath', $cliRepo, '-RefinementPath', $refinementRelative)
    Assert-ExitCode 0 $cliAll 'Should_ExitZero_When_RefinementListed'
    Assert-True ($cliAll.Result.ok -eq $true) 'Should_ReturnOkJson_When_RefinementListed'
    Assert-True (([string]$cliAll.Result.identity).Length -eq 64) 'Should_ReturnIdentity_When_RefinementListed'
    Assert-Equal '2' ([string]@($cliAll.Result.items).Count) 'Should_ListAllItems_When_NoIdGiven'
    Assert-Equal 'D-001' ([string]$cliAll.Result.items[0].id) 'Should_ReturnItemId_When_RefinementListed'
    Assert-Equal 'First decision' ([string]$cliAll.Result.items[0].title) 'Should_ReturnItemTitle_When_RefinementListed'
    Assert-Equal $refinementHashD1 ([string]$cliAll.Result.items[0].hash) 'Should_ReturnItemHash_When_RefinementListed'
    Assert-True ($null -eq $cliAll.Result.items[0].superseded_by) 'Should_ReturnNullSupersededBy_When_ItemNotSuperseded'

    $cliOne = Invoke-RefinementCli @('-RepoPath', $cliRepo, '-RefinementPath', $refinementRelative, '-Id', 'D-002')
    Assert-ExitCode 0 $cliOne 'Should_ExitZero_When_IdFilterMatches'
    Assert-Equal '1' ([string]@($cliOne.Result.items).Count) 'Should_ListOnlyRequestedItem_When_IdGiven'
    Assert-Equal 'D-002' ([string]$cliOne.Result.items[0].id) 'Should_ReturnRequestedId_When_IdGiven'

    $cliUnknown = Invoke-RefinementCli @('-RepoPath', $cliRepo, '-RefinementPath', $refinementRelative, '-Id', 'D-009')
    Assert-ExitCode 3 $cliUnknown 'Should_ExitThree_When_IdUnknown'
    Assert-Equal 'refinement_reference_unknown' ([string]$cliUnknown.Result.reason) 'Should_ReturnUnknownReason_When_IdUnknown'
    Assert-True ($cliUnknown.Result.ok -eq $false) 'Should_ReturnNotOk_When_IdUnknown'

    $cliOneItemRepo = Write-PlanFile 'refinement-cli-one' $validText
    Add-RepoPlan $cliOneItemRepo $refinementRelative ("# Refinement`n`n### R-001 Only risk`nText.`n")
    $cliOneItem = Invoke-RefinementCli @('-RepoPath', $cliOneItemRepo, '-RefinementPath', $refinementRelative)
    Assert-ExitCode 0 $cliOneItem 'Should_ExitZero_When_SingleItemRefinementListed'
    Assert-True ($cliOneItem.Stdout.Contains('"items":[{')) 'Should_KeepItemsArray_When_SingleItemRefinementListed'

    $cliSupersededRepo = Write-PlanFile 'refinement-cli-superseded' $validText
    Add-RepoPlan $cliSupersededRepo $refinementRelative $supersededRefinement
    $cliSuperseded = Invoke-RefinementCli @('-RepoPath', $cliSupersededRepo, '-RefinementPath', $refinementRelative, '-Id', 'D-001')
    Assert-ExitCode 0 $cliSuperseded 'Should_ExitZero_When_SupersededItemListed'
    Assert-Equal 'D-002' ([string]$cliSuperseded.Result.items[0].superseded_by) 'Should_ReturnSupersededBy_When_ItemSuperseded'

    $cliMissing = Invoke-RefinementCli @('-RepoPath', $validRepo, '-RefinementPath', 'features/001-demo/REFINEMENT.md')
    Assert-ExitCode 3 $cliMissing 'Should_ExitThree_When_RefinementMissing'
    Assert-Equal 'refinement_reference_unknown' ([string]$cliMissing.Result.reason) 'Should_ReturnUnknownReason_When_RefinementMissing'

    $cliBadPath = Invoke-RefinementCli @('-RepoPath', $cliRepo, '-RefinementPath', 'features/001-demo/../002-x/REFINEMENT.md')
    Assert-ExitCode 3 $cliBadPath 'Should_ExitThree_When_PathContainsParentSegment'
    Assert-Equal 'refinement_reference_invalid' ([string]$cliBadPath.Result.reason) 'Should_ReturnInvalidReason_When_PathContainsParentSegment'

    $cliBackslash = Invoke-RefinementCli @('-RepoPath', $cliRepo, '-RefinementPath', 'features\001-demo\REFINEMENT.md')
    Assert-ExitCode 3 $cliBackslash 'Should_ExitThree_When_PathUsesBackslashes'

    $cliBrokenRepo = Write-PlanFile 'refinement-cli-broken' $validText
    Add-RepoPlan $cliBrokenRepo $refinementRelative ("# Refinement`n`n<!-- DELIVERY:APPROVAL:BEGIN -->`n")
    $cliBroken = Invoke-RefinementCli @('-RepoPath', $cliBrokenRepo, '-RefinementPath', $refinementRelative)
    Assert-ExitCode 3 $cliBroken 'Should_ExitThree_When_RefinementGrammarFails'
    Assert-Equal 'refinement_reference_invalid' ([string]$cliBroken.Result.reason) 'Should_ReturnInvalidReason_When_RefinementGrammarFails'

    $cliBadId = Invoke-RefinementCli @('-RepoPath', $cliRepo, '-RefinementPath', $refinementRelative, '-Id', 'X-1')
    Assert-ExitCode 1 $cliBadId 'Should_ExitOne_When_IdParameterMalformed'

    $cliBadRepo = Invoke-RefinementCli @('-RepoPath', (Join-Path $tempRoot 'does-not-exist'), '-RefinementPath', $refinementRelative)
    Assert-ExitCode 1 $cliBadRepo 'Should_ExitOne_When_RepoPathMissing'

    Write-Output ('PASS: {0} delivery plan preflight assertions.' -f $passed)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
