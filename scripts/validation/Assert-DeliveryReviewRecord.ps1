[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$writer = Join-Path $PSScriptRoot '..\runtime\Write-DeliveryReviewRecord.ps1'
$writer = [System.IO.Path]::GetFullPath($writer)
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-review-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Invoke-Writer([string]$TargetPath, [string]$RecordPath, [string]$Json, [string]$Text,
    [string]$TargetKind='PLAN.md', [string]$Stage='delivery_unit_plan_review', [string]$SnapshotPath='') {
    $args = @('-NoProfile', '-File', $writer, '-Action', 'save', '-RepoPath', $tempRoot,
        '-TargetPath', $TargetPath, '-TargetKind', $TargetKind, '-Stage', $Stage,
        '-ArtifactText', $Text, '-RecordPath', $RecordPath, '-RecordJson', $Json)
    if (-not [string]::IsNullOrWhiteSpace($SnapshotPath)) { $args += @('-SnapshotPath', $SnapshotPath) }
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $output = & pwsh @args 2>&1; $code = $LASTEXITCODE }
    finally { $ErrorActionPreference = $oldPreference }
    return [pscustomobject]@{ output = ($output -join "`n"); code = $code }
}
function New-Record([string]$InputPath='features/030-demo/REFINEMENT.md') {
    return [ordered]@{
        schema = 'delivery-review-record/v1'
        state = 'reviewed'
        inputs = @(@{ id='REQ-1'; path=$InputPath; role='accepted refinement'; impacted_ids=@('S1') })
        reviewers = @{
            reader=@{ host='Codex'; observed_isolation='fresh-context-instruction'; result=@{ paraphrases=@{ proposal='A one unit plan.'; current_system='The current system has a declared baseline.' }; lenses=@('comprehension'); findings=@() } }
            critic=@{ host='Codex'; observed_isolation='fresh-context-instruction'; result=@{ lenses=@('scope', 'evidence'); findings=@() } }
        }
        dispositions = @()
        provenance = @{}
    } | ConvertTo-Json -Depth 20 -Compress
}

try {
    $feature = Join-Path $tempRoot 'features\030-demo'
    New-Item -ItemType Directory -Path (Join-Path $feature 'US01') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $feature 'delivery-reviews') -Force | Out-Null
    $targetRel = 'features/030-demo/US01/PLAN.md'
    $target = Join-Path $tempRoot ($targetRel -replace '/', '\')
    $inputRel = 'features/030-demo/REFINEMENT.md'
    $input = Join-Path $tempRoot ($inputRel -replace '/', '\')
    $recordRel = Join-Path $feature 'delivery-reviews\plan.json'
    $text = @'
# Plan
Stable normative criterion.
<!-- DELIVERY:PROGRESS:BEGIN -->
state: draft
<!-- DELIVERY:PROGRESS:END -->
<!-- DELIVERY:CHECKPOINT:BEGIN -->
current: S1
<!-- DELIVERY:CHECKPOINT:END -->
<!-- DELIVERY:APPROVAL:BEGIN -->
approved: false
<!-- DELIVERY:APPROVAL:END -->
<!-- DELIVERY:STEP:US01-S1:BEGIN -->
status: PENDING
<!-- DELIVERY:STEP:US01-S1:END -->
'@
    Set-Content -LiteralPath $target -Value $text -NoNewline
    Set-Content -LiteralPath $input -Value '# Accepted input v1' -NoNewline

    $first = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $text
    Assert ($first.code -eq 0) "Valid record failed: $($first.output)"
    $firstData = $first.output | ConvertFrom-Json
    Assert ($firstData.status -eq 'saved') 'Expected successful save.'
    $persisted = Get-Content -LiteralPath $recordRel -Raw | ConvertFrom-Json
    $identity1 = $persisted.target.review_identity

    $operationalUpdate = $text.Replace('state: draft', 'state: in progress')
    Set-Content -LiteralPath $target -Value $operationalUpdate -NoNewline
    $second = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $operationalUpdate
    Assert ($second.code -eq 0) "Operational-only update failed: $($second.output)"
    $identity2 = (Get-Content -LiteralPath $recordRel -Raw | ConvertFrom-Json).target.review_identity
    Assert ($identity1 -eq $identity2) 'Operational block changes must preserve review identity.'

    Set-Content -LiteralPath $input -Value '# Accepted input v2' -NoNewline
    Set-Content -LiteralPath $target -Value $text -NoNewline
    $third = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $text
    Assert ($third.code -eq 0) "Changed material input failed to save: $($third.output)"
    $identity3 = (Get-Content -LiteralPath $recordRel -Raw | ConvertFrom-Json).target.review_identity
    Assert ($identity1 -ne $identity3) 'Material input changes must invalidate review identity.'

    $badText = $text.Replace('<!-- DELIVERY:APPROVAL:END -->', '')
    Set-Content -LiteralPath $target -Value $badText -NoNewline
    $malformed = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $badText
    Assert ($malformed.code -ne 0) 'Unmatched operational markers must fail closed.'
    $unknownText = $text.Replace('# Plan', "# Plan`n<!-- DELIVERY:UNKNOWN:BEGIN -->")
    Set-Content -LiteralPath $target -Value $unknownText -NoNewline
    $unknown = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $unknownText
    Assert ($unknown.code -ne 0) 'Unknown operational markers must fail closed.'

    $badRecord = [ordered]@{
        schema='delivery-review-record/v1'; state='reviewed'; inputs=@();
        reviewers=@{
            reader=@{host='Codex';observed_isolation='context-only';result=@{paraphrases=@{proposal='Plan';current_system='System'};lenses=@('comprehension');findings=@(@{id='F-1';severity='B';category='GAP';section='scope';evidence='missing';recommendation='clarify'})}}
            critic=@{host='Codex';observed_isolation='context-only';result=@{lenses=@('scope');findings=@()}}
        };
        dispositions=@(@{id='F-1'; severity='B'; disposition='accepted_minor'})
    } | ConvertTo-Json -Depth 20 -Compress
    Set-Content -LiteralPath $target -Value $text -NoNewline
    $blocking = Invoke-Writer $targetRel $recordRel $badRecord $text
    Assert ($blocking.code -ne 0) 'Unresolved blocking findings must fail closed.'

    $escape = Invoke-Writer '../outside/PLAN.md' $recordRel (New-Record $inputRel) $text
    Assert ($escape.code -ne 0) 'Target traversal must fail closed.'
    $outsideRecord = Join-Path $tempRoot 'features\030-demo\outside.json'
    $wrongStore = Invoke-Writer $targetRel $outsideRecord (New-Record $inputRel) $text
    Assert ($wrongStore.code -ne 0) 'Record path outside delivery-reviews must fail closed.'
    $external = Join-Path $tempRoot 'external'
    New-Item -ItemType Directory -Path $external | Out-Null
    $link = Join-Path $feature 'delivery-reviews\linked'
    New-Item -ItemType Junction -Path $link -Target $external | Out-Null
    $linkedRecord = Join-Path $link 'record.json'
    $junction = Invoke-Writer $targetRel $linkedRecord (New-Record $inputRel) $text
    Assert ($junction.code -ne 0) 'Reparse-point storage ancestors must fail closed.'

    # The runtime must accept canonical integrated-delivery targets outside the design feature 030.
    $genericFeature = Join-Path $tempRoot 'features\031-generic-delivery'
    $genericUnit = Join-Path $genericFeature 'US01'
    $genericReviews = Join-Path $genericFeature 'delivery-reviews'
    New-Item -ItemType Directory -Path $genericUnit, $genericReviews -Force | Out-Null
    $genericPlanRel = 'features/031-generic-delivery/US01/PLAN.md'
    $genericPlan = Join-Path $tempRoot ($genericPlanRel -replace '/', '\')
    $genericInputRel = 'features/031-generic-delivery/REFINEMENT.md'
    $genericInput = Join-Path $tempRoot ($genericInputRel -replace '/', '\')
    $genericRecord = Join-Path $genericReviews 'plan.json'
    Set-Content -LiteralPath $genericPlan -Value $text -NoNewline
    Set-Content -LiteralPath $genericInput -Value '# Generic accepted refinement' -NoNewline
    $generic = Invoke-Writer $genericPlanRel $genericRecord (New-Record $genericInputRel) $text
    Assert ($generic.code -eq 0) "Canonical non-030 unit plan failed: $($generic.output)"

    # Technical Stories use the same canonical plan contract as User Stories.
    $technicalFeature = Join-Path $tempRoot 'features\147-toolkit-delivery'
    $technicalUnit = Join-Path $technicalFeature 'TS01'
    $technicalReviews = Join-Path $technicalFeature 'delivery-reviews'
    New-Item -ItemType Directory -Path $technicalUnit, $technicalReviews -Force | Out-Null
    $technicalPlanRel = 'features/147-toolkit-delivery/TS01/PLAN.md'
    $technicalPlan = Join-Path $tempRoot ($technicalPlanRel -replace '/', '\')
    $technicalInputRel = 'features/147-toolkit-delivery/REFINEMENT.md'
    $technicalInput = Join-Path $tempRoot ($technicalInputRel -replace '/', '\')
    Set-Content -LiteralPath $technicalPlan -Value $text -NoNewline
    Set-Content -LiteralPath $technicalInput -Value '# Technical refinement' -NoNewline
    $technicalRecord = Join-Path $technicalReviews 'plan.json'
    $technical = Invoke-Writer $technicalPlanRel $technicalRecord (New-Record $technicalInputRel) $text
    Assert ($technical.code -eq 0) "Canonical TS01 plan under an arbitrary feature number failed: $($technical.output)"
    $malformedTechnical = Invoke-Writer 'features/147-toolkit-delivery/TS1/PLAN.md' $technicalRecord (New-Record $technicalInputRel) $text
    Assert ($malformedTechnical.code -ne 0) 'Malformed TS unit identifiers must fail closed.'
    $technicalEscape = Invoke-Writer 'features/147-toolkit-delivery/TS01/../../outside/PLAN.md' $technicalRecord (New-Record $technicalInputRel) $text
    Assert ($technicalEscape.code -ne 0) 'Escaping TS unit paths must fail closed.'

    # Pre-approval review can bind to a controlled draft snapshot before canonical write.
    $draftRel = 'features/031-generic-delivery/scratch/delivery-review/US01-PLAN.md'
    $draft = Join-Path $tempRoot ($draftRel -replace '/', '\')
    New-Item -ItemType Directory -Path (Split-Path -Parent $draft) -Force | Out-Null
    Set-Content -LiteralPath $draft -Value $text -NoNewline
    $draftTargetRel = 'features/031-generic-delivery/US02/PLAN.md'
    $draftRecord = Join-Path $genericReviews 'draft.json'
    $draftResult = Invoke-Writer $draftTargetRel $draftRecord (New-Record $genericInputRel) $text 'PLAN.md' 'delivery_unit_plan_review' $draftRel
    Assert ($draftResult.code -eq 0) "Controlled draft review before canonical write failed: $($draftResult.output)"
    $stale = Invoke-Writer $draftTargetRel (Join-Path $genericReviews 'stale.json') (New-Record $genericInputRel) ($text + "`nchanged") 'PLAN.md' 'delivery_unit_plan_review' $draftRel
    Assert ($stale.code -ne 0) 'ArtifactText that differs from the designated draft snapshot must fail closed.'

    # Controlled draft snapshots retain the same behavior for Technical Story plans.
    $technicalDraftRel = 'features/147-toolkit-delivery/scratch/delivery-review/TS01-PLAN.md'
    $technicalDraft = Join-Path $tempRoot ($technicalDraftRel -replace '/', '\')
    New-Item -ItemType Directory -Path (Split-Path -Parent $technicalDraft) -Force | Out-Null
    Set-Content -LiteralPath $technicalDraft -Value $text -NoNewline
    $technicalDraftResult = Invoke-Writer 'features/147-toolkit-delivery/TS02/PLAN.md' (Join-Path $technicalReviews 'draft.json') (New-Record $technicalInputRel) $text 'PLAN.md' 'delivery_unit_plan_review' $technicalDraftRel
    Assert ($technicalDraftResult.code -eq 0) "Controlled TS draft review before canonical write failed: $($technicalDraftResult.output)"

    # A feature-level refinement is also a canonical target; the record remains beside that feature.
    $refinementRel = 'features/031-generic-delivery/REFINEMENT.md'
    $refinement = Join-Path $tempRoot ($refinementRel -replace '/', '\')
    $refinementText = $text.Replace('# Plan', '# Feature refinement')
    Set-Content -LiteralPath $refinement -Value $refinementText -NoNewline
    $refinementRecord = Join-Path $genericReviews 'refinement.json'
    $refinementResult = Invoke-Writer $refinementRel $refinementRecord (New-Record $genericInputRel) $refinementText 'REFINEMENT.md' 'delivery_refinement_review'
    Assert ($refinementResult.code -eq 0) "Canonical feature refinement failed: $($refinementResult.output)"

    # A lexically canonical target still cannot traverse a junction out of the authorized repo root.
    $externalPlan = Join-Path $external 'PLAN.md'
    Set-Content -LiteralPath $externalPlan -Value $text -NoNewline
    $linkedFeature = Join-Path $tempRoot 'features\032-linked-feature'
    New-Item -ItemType Directory -Path (Split-Path -Parent $linkedFeature) -Force | Out-Null
    New-Item -ItemType Junction -Path $linkedFeature -Target $external | Out-Null
    $linkedTarget = Invoke-Writer 'features/032-linked-feature/US01/PLAN.md' (Join-Path $genericReviews 'linked.json') (New-Record $genericInputRel) $text
    Assert ($linkedTarget.code -ne 0) 'Reparse-point target ancestors must fail closed.'

    $snapshotLink = Join-Path $genericFeature 'scratch\delivery-review\linked'
    New-Item -ItemType Junction -Path $snapshotLink -Target $external | Out-Null
    $linkedSnapshot = Invoke-Writer $draftTargetRel (Join-Path $genericReviews 'linked-snapshot.json') (New-Record $genericInputRel) $text 'PLAN.md' 'delivery_unit_plan_review' 'features/031-generic-delivery/scratch/delivery-review/linked/PLAN.md'
    Assert ($linkedSnapshot.code -ne 0) 'Reparse-point draft snapshot ancestors must fail closed.'

    'PASS: schema, identity, marker rejection, findings gate, generic targets, controlled drafts, stale snapshot rejection, traversal, and reparse containment.'
} finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
exit 0
