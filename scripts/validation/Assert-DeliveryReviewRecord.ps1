[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$writer = Join-Path $PSScriptRoot '..\runtime\Write-DeliveryReviewRecord.ps1'
$writer = [System.IO.Path]::GetFullPath($writer)
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-review-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:passed++
}
function Invoke-Writer([string]$TargetPath, [string]$RecordPath, [string]$Json, [string]$Text,
    [string]$TargetKind='PLAN.md', [string]$Stage='delivery_unit_plan_review', [string]$SnapshotPath='') {
    $params = @{
        Action = 'save'; RepoPath = $tempRoot; TargetPath = $TargetPath; TargetKind = $TargetKind; Stage = $Stage
        ArtifactText = $Text; RecordPath = $RecordPath; RecordJson = $Json
    }
    if (-not [string]::IsNullOrWhiteSpace($SnapshotPath)) { $params['SnapshotPath'] = $SnapshotPath }
    try {
        $output = & $writer @params 2>&1 | Out-String
        return [pscustomobject]@{ output = $output.Trim(); code = 0 }
    }
    catch {
        return [pscustomobject]@{ output = [string]$_.Exception.Message; code = 1 }
    }
}
$gateScript = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\runtime\Test-DeliveryReviewRecord.ps1'))
function Invoke-Gate([string]$TargetPath, [string]$RecordPath, [string]$SnapshotPath='') {
    $gateParams = @{ RepoPath = $tempRoot; TargetPath = $TargetPath; RecordPath = $RecordPath; AsLibrary = $true }
    if (-not [string]::IsNullOrWhiteSpace($SnapshotPath)) { $gateParams['SnapshotPath'] = $SnapshotPath }
    $result = & $gateScript @gateParams
    $output = if ($null -ne $result.Result) { $result.Result | ConvertTo-Json -Compress -Depth 10 } else { [string]$result.Error }
    return [pscustomobject]@{ code = [int]$result.ExitCode; verdict = $result.Result; output = $output }
}
function Get-IndependentSha256Hex([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text)) } finally { $sha.Dispose() }
    return (-join ($hash | ForEach-Object { $_.ToString('X2') }))
}
function New-ReviewerBlock([object[]]$Findings = @()) {
    return @{
        reader = @{ host = 'Codex'; observed_isolation = 'fresh-context-instruction'; result = @{ paraphrases = @{ proposal = 'A bounded plan.'; current_system = 'A declared baseline.' }; lenses = @('comprehension'); findings = @($Findings) } }
        critic = @{ host = 'Codex'; observed_isolation = 'fresh-context-instruction'; result = @{ lenses = @('scope'); findings = @() } }
    }
}
function ConvertTo-RecordJson([hashtable]$Record) {
    if (-not $Record.ContainsKey('provenance')) { $Record['provenance'] = @{} }
    return ($Record | ConvertTo-Json -Depth 20)
}
function Save-RecordFile([string]$FileName, [string]$Json) {
    [System.IO.File]::WriteAllText((Join-Path $tempRoot ('features\050-gate\delivery-reviews\' + $FileName)), $Json, [System.Text.UTF8Encoding]::new($false))
    return ('features/050-gate/delivery-reviews/' + $FileName)
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

$builderScript = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\runtime\New-DeliveryReviewRecord.ps1'))
$priorIdentity = '0123456789ABCDEF' * 4
function New-ShapeRecord([hashtable]$Overrides = @{}) {
    $record = @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; inputs = @(); reviewers = (New-ReviewerBlock); dispositions = @() }
    foreach ($key in $Overrides.Keys) { $record[$key] = $Overrides[$key] }
    return ($record | ConvertTo-Json -Depth 20)
}
function Get-ShapeError([string]$Json) {
    $candidate = $Json | ConvertFrom-Json -Depth 50
    try { Assert-DeliveryReviewRecordShape -Value $candidate; return '' }
    catch { return [string]$_.Exception.Message }
}
function Assert-ShapeError([string]$Json, [string]$Pattern, [string]$Name) {
    $message = Get-ShapeError $Json
    Assert ($message -match $Pattern) "${Name}: expected shape error matching '$Pattern', got '$message'"
}
function Assert-ShapePasses([string]$Json, [string]$Name) {
    $message = Get-ShapeError $Json
    Assert ($message -eq '') "${Name}: expected shape to pass, got '$message'"
}
function New-Finding([string]$Id, [string]$Severity = 'B', [hashtable]$Extra = @{}) {
    $finding = @{ id = $Id; severity = $Severity; category = 'GAP'; section = 'scope'; evidence = 'missing'; recommendation = 'clarify' }
    foreach ($key in $Extra.Keys) { $finding[$key] = $Extra[$key] }
    return $finding
}
function Save-GateRecord([string]$FileName, [string]$Json, [string]$ArtifactText = $text) {
    return Invoke-Writer $gateTargetRel (Join-Path $tempRoot ('features\050-gate\delivery-reviews\' + $FileName)) $Json $ArtifactText
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
{"schema":"delivery-progress/v1","cadence":"step_by_step","current_stage":"draft","completed":0,"total":1}
<!-- DELIVERY:PROGRESS:END -->
<!-- DELIVERY:CHECKPOINT:BEGIN -->
{"schema":"delivery-checkpoint/v1","branch":"feature/demo","head":"0123456789ABCDEF0123456789ABCDEF01234567","active_step":null}
<!-- DELIVERY:CHECKPOINT:END -->
<!-- DELIVERY:APPROVAL:BEGIN -->
{"schema":"delivery-approval/v1","state":"pending"}
<!-- DELIVERY:APPROVAL:END -->
<!-- DELIVERY:STEP:US01-S1:BEGIN -->
{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING"}
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

    $operationalUpdate = $text.Replace('"current_stage":"draft"', '"current_stage":"in progress"')
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

    $stepUpdate = $text.Replace('"status":"PENDING"', '"status":"COMPLETED"')
    Set-Content -LiteralPath $target -Value $stepUpdate -NoNewline
    $stepResult = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $stepUpdate
    Assert ($stepResult.code -eq 0) "STEP status update failed: $($stepResult.output)"
    $identity4 = (Get-Content -LiteralPath $recordRel -Raw | ConvertFrom-Json).target.review_identity
    Assert ($identity3 -eq $identity4) 'STEP status change must preserve review identity.'

    $normativeChange = $text.Replace('Stable normative criterion.', 'Revised normative criterion.')
    Set-Content -LiteralPath $target -Value $normativeChange -NoNewline
    $normativeResult = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $normativeChange
    Assert ($normativeResult.code -eq 0) "Normative text change failed to save: $($normativeResult.output)"
    $identity5 = (Get-Content -LiteralPath $recordRel -Raw | ConvertFrom-Json).target.review_identity
    Assert ($identity3 -ne $identity5) 'Normative text changes must invalidate review identity.'

    $badText = $text.Replace('<!-- DELIVERY:APPROVAL:END -->', '')
    Set-Content -LiteralPath $target -Value $badText -NoNewline
    $malformed = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $badText
    Assert ($malformed.code -ne 0) 'Unmatched operational markers must fail closed.'
    $unknownText = $text.Replace('# Plan', "# Plan`n<!-- DELIVERY:UNKNOWN:BEGIN -->")
    Set-Content -LiteralPath $target -Value $unknownText -NoNewline
    $unknown = Invoke-Writer $targetRel $recordRel (New-Record $inputRel) $unknownText
    Assert ($unknown.code -ne 0) 'Unknown operational markers must fail closed.'

    $legacyText = $text.Replace('<!-- DELIVERY:STEP:US01-S1:BEGIN -->', '<!-- DELIVERY:STEP-US01-S1:BEGIN -->').Replace('<!-- DELIVERY:STEP:US01-S1:END -->', '<!-- DELIVERY:STEP-US01-S1:END -->')
    Set-Content -LiteralPath $target -Value $legacyText -NoNewline
    $legacy = Invoke-Writer $targetRel (Join-Path $feature 'delivery-reviews\legacy.json') (New-Record $inputRel) $legacyText
    Assert ($legacy.code -ne 0) 'Legacy STEP- markers must fail closed.'
    Assert ($legacy.output -match 'legacy_step_marker') "Legacy STEP- rejection must name legacy_step_marker: $($legacy.output)"
    Assert (-not (Test-Path -LiteralPath (Join-Path $feature 'delivery-reviews\legacy.json'))) 'Rejected legacy target must not write a record.'

    $unclosedText = $text + "`n" + '```text' + "`nopen example`n"
    Set-Content -LiteralPath $target -Value $unclosedText -NoNewline
    $unclosed = Invoke-Writer $targetRel (Join-Path $feature 'delivery-reviews\unclosed.json') (New-Record $inputRel) $unclosedText
    Assert ($unclosed.code -ne 0) 'Unclosed fence must fail closed.'
    Assert ($unclosed.output -match 'unclosed_fence') "Unclosed fence rejection must name unclosed_fence: $($unclosed.output)"

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

    # A unit plan with no DELIVERY blocks is a valid draft and saves normally.
    $noBlocksPlanRel = 'features/031-generic-delivery/US03/PLAN.md'
    $noBlocksPlan = Join-Path $tempRoot ($noBlocksPlanRel -replace '/', '\')
    New-Item -ItemType Directory -Path (Split-Path -Parent $noBlocksPlan) -Force | Out-Null
    $noBlocksText = "# Draft plan`nNo delivery blocks yet.`n"
    Set-Content -LiteralPath $noBlocksPlan -Value $noBlocksText -NoNewline
    $noBlocks = Invoke-Writer $noBlocksPlanRel (Join-Path $genericReviews 'no-blocks.json') (New-Record $genericInputRel) $noBlocksText
    Assert ($noBlocks.code -eq 0) "Plan without DELIVERY blocks failed to save: $($noBlocks.output)"
    Assert ((($noBlocks.output | ConvertFrom-Json).status) -eq 'saved') 'Plan without DELIVERY blocks must report saved.'

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
    $draftGate = Invoke-Gate $draftTargetRel 'features/031-generic-delivery/delivery-reviews/draft.json' $draftRel
    Assert ($draftGate.code -eq 0 -and $draftGate.verdict.reason -eq 'reviewed') "Review record gate must validate the controlled draft snapshot before canonical write: $($draftGate.output)"
    Assert ($draftGate.verdict.identity.review_identity -cmatch '\A[0-9A-F]{64}\z' -and $draftGate.verdict.identity.material_input_identity -cmatch '\A[0-9A-F]{64}\z') 'Allowed gate verdict must return the verified v2 review and material-input identities.'
    $wrongFeatureSnapshot = Invoke-Gate $draftTargetRel 'features/031-generic-delivery/delivery-reviews/draft.json' 'features/032-other-feature/scratch/delivery-review/draft.md'
    Assert ($wrongFeatureSnapshot.code -eq 1 -and $wrongFeatureSnapshot.output -match 'selected feature') "Snapshot gate must reject a snapshot from another feature: $($wrongFeatureSnapshot.output)"
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

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $goldenFeature = Join-Path $tempRoot 'features\052-golden'
    New-Item -ItemType Directory -Path (Join-Path $goldenFeature 'US01'), (Join-Path $goldenFeature 'delivery-reviews') -Force | Out-Null
    $goldenTargetRel = 'features/052-golden/US01/PLAN.md'
    $goldenBody = "# Golden identity`nNormative criterion.`n"
    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\052-golden\US01\PLAN.md'), $goldenBody, $utf8NoBom)
    $goldenInputRel = 'features/052-golden/REFINEMENT.md'
    $goldenInputBody = "# Golden input`n"
    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\052-golden\REFINEMENT.md'), $goldenInputBody, $utf8NoBom)
    $goldenRecordRel = 'features/052-golden/delivery-reviews/plan.json'
    $golden = Invoke-Writer $goldenTargetRel (Join-Path $tempRoot 'features\052-golden\delivery-reviews\plan.json') (New-Record $goldenInputRel) $goldenBody
    Assert ($golden.code -eq 0) "Golden record save failed: $($golden.output)"
    $goldenWritten = [System.IO.File]::ReadAllText((Join-Path $tempRoot $goldenRecordRel)) | ConvertFrom-Json
    Assert ($goldenWritten.schema -ceq 'delivery-review-record/v2') 'Newly written records must use the bound v2 schema.'
    $goldenInputs = @([pscustomobject]@{ id = 'REQ-1'; path = $goldenInputRel; sha256 = (Get-IndependentSha256Hex $goldenInputBody); role = 'accepted refinement'; impacted_ids = @('S1') })
    $goldenMaterialIdentity = Get-DeliveryMaterialInputIdentity -Inputs $goldenInputs
    Assert ($goldenWritten.material_input_identity -ceq $goldenMaterialIdentity) 'Writer material input identity drifted from the library formula.'
    $goldenBindingIdentity = Get-DeliveryReviewRecordBindingIdentity -Record $goldenWritten -MaterialInputIdentity $goldenMaterialIdentity
    Assert ($goldenWritten.target.review_identity -ceq $goldenBindingIdentity) 'Writer review binding identity drifted from the library formula.'
    $goldenGate = Invoke-Gate $goldenTargetRel $goldenRecordRel
    Assert ($goldenGate.code -eq 0 -and $goldenGate.verdict.reason -eq 'reviewed') "Golden record must pass the gate: $($goldenGate.output)"

    $gateFeature = Join-Path $tempRoot 'features\050-gate'
    New-Item -ItemType Directory -Path (Join-Path $gateFeature 'US01'), (Join-Path $gateFeature 'delivery-reviews') -Force | Out-Null
    $gateTargetRel = 'features/050-gate/US01/PLAN.md'
    $gateTarget = Join-Path $tempRoot 'features\050-gate\US01\PLAN.md'
    $gateInputRel = 'features/050-gate/REFINEMENT.md'
    $gateInput = Join-Path $tempRoot 'features\050-gate\REFINEMENT.md'
    $gateRecordRel = 'features/050-gate/delivery-reviews/plan.json'
    $gateRecord = Join-Path $tempRoot 'features\050-gate\delivery-reviews\plan.json'
    [System.IO.File]::WriteAllText($gateTarget, $text, $utf8NoBom)
    [System.IO.File]::WriteAllText($gateInput, '# Gate input v1', $utf8NoBom)
    $saved = Invoke-Writer $gateTargetRel $gateRecord (New-Record $gateInputRel) $text
    Assert ($saved.code -eq 0) "Gate fixture save failed: $($saved.output)"
    $gateRecordText = [System.IO.File]::ReadAllText($gateRecord)

    $gate = Invoke-Gate $gateTargetRel $gateRecordRel
    Assert ($gate.code -eq 0 -and $gate.verdict.allowed -eq $true -and $gate.verdict.reason -eq 'reviewed') "Saved reviewed record must pass: $($gate.output)"
    $gateAbsolute = Invoke-Gate $gateTargetRel $gateRecord
    Assert ($gateAbsolute.code -eq 0 -and $gateAbsolute.verdict.reason -eq 'reviewed') 'Absolute record path under delivery-reviews must pass.'

    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/absent.json'
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_missing') "Missing record must block as record_missing: $($gate.output)"

    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'truncated.json' $gateRecordText.Substring(0, [Math]::Floor($gateRecordText.Length / 2)))
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_unreadable') "Truncated JSON must block as record_unreadable: $($gate.output)"

    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'wrong-schema.json' $gateRecordText.Replace('delivery-review-record/v2', 'delivery-review-record/v0'))
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid') "Wrong schema string must block as record_schema_invalid: $($gate.output)"

    $gate = Invoke-Gate 'features/050-gate/US02/PLAN.md' $gateRecordRel
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'target_mismatch') "Record for another target must block as target_mismatch: $($gate.output)"

    [System.IO.File]::WriteAllText($gateTarget, $text.Replace('Stable normative criterion.', 'Revised normative criterion.'), $utf8NoBom)
    $gate = Invoke-Gate $gateTargetRel $gateRecordRel
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'identity_stale') "Normative edit after save must block as identity_stale: $($gate.output)"

    [System.IO.File]::WriteAllText($gateTarget, $text.Replace('"status":"PENDING"', '"status":"COMPLETED"'), $utf8NoBom)
    $gate = Invoke-Gate $gateTargetRel $gateRecordRel
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Operational edit after save must stay allowed: $($gate.output)"
    [System.IO.File]::WriteAllText($gateTarget, $text, $utf8NoBom)

    [System.IO.File]::WriteAllText($gateInput, '# Gate input v2', $utf8NoBom)
    $gate = Invoke-Gate $gateTargetRel $gateRecordRel
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and (@($gate.verdict.details) -contains 'REQ-1')) "Edited input must block as inputs_changed naming REQ-1: $($gate.output)"
    [System.IO.File]::WriteAllText($gateInput, '# Gate input v1', $utf8NoBom)

    $roleTampered = [regex]::Replace($gateRecordText, '"role":\s*"accepted refinement"', '"role": "tampered refinement"')
    Assert ($roleTampered -cne $gateRecordText) 'Role tamper fixture must change the record.'
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'role-tampered.json' $roleTampered)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'material_input_identity_mismatch') "Tampered input role must block as material_input_identity_mismatch: $($gate.output)"

    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\050-gate\REFINEMENT-copy.md'), "# Gate input v1`n", $utf8NoBom)
    $pathTampered = [regex]::Replace($gateRecordText, '"path":\s*"features/050-gate/REFINEMENT\.md"', '"path": "features/050-gate/REFINEMENT-copy.md"')
    Assert ($pathTampered -cne $gateRecordText) 'Path tamper fixture must change the record.'
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'path-tampered.json' $pathTampered)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'material_input_identity_mismatch') "Tampered input path must block as material_input_identity_mismatch: $($gate.output)"

    $findingB = @{ id = 'F-1'; severity = 'B'; category = 'GAP'; section = 'scope'; evidence = 'missing'; recommendation = 'clarify' }
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'no-disposition.json' (ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; inputs = @(); reviewers = (New-ReviewerBlock -Findings @($findingB)); dispositions = @() }))
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'has no disposition')) "Finding without disposition must block as record_schema_invalid: $($gate.output)"

    $findingB2 = @{ id = 'F-2'; severity = 'B'; category = 'GAP'; section = 'scope'; evidence = 'missing'; recommendation = 'clarify' }
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'blank-evidence.json' (ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; inputs = @(); reviewers = (New-ReviewerBlock -Findings @($findingB2)); dispositions = @(@{ id = 'F-2'; severity = 'B'; disposition = 'resolved'; evidence = '' }) }))
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'requires evidence')) "Blank blocking evidence must block as record_schema_invalid: $($gate.output)"

    $findingMinor = @{ id = 'F-3'; severity = 'MINOR'; category = 'STYLE'; section = 'wording'; evidence = 'loose'; recommendation = 'tighten' }
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'blank-minor-reason.json' (ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; inputs = @(); reviewers = (New-ReviewerBlock -Findings @($findingMinor)); dispositions = @(@{ id = 'F-3'; severity = 'MINOR'; disposition = 'accepted_minor'; reason = '' }) }))
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'reasoned disposition')) "Blank MINOR reason must block as record_schema_invalid: $($gate.output)"

    $notRunWrite = Invoke-Writer $gateTargetRel (Join-Path $tempRoot 'features\050-gate\delivery-reviews\not-run.json') (ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'not_run'; reason = 'reviewer host unavailable'; inputs = @(); reviewers = @{}; dispositions = @() }) $text
    Assert ($notRunWrite.code -eq 0) "not_run record save failed: $($notRunWrite.output)"
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/not-run.json'
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'review_not_run') "not_run record must block as review_not_run: $($gate.output)"

    $bypassJson = ConvertTo-RecordJson @{
        schema = 'delivery-review-record/v1'; state = 'bypassed'; reason = 'Cold review unavailable'
        operator_choice = @{ choice = 'bypass'; evidence = 'operator accepted the bypass' }
        inputs = @(@{ id = 'REQ-1'; path = $gateInputRel; role = 'accepted refinement'; impacted_ids = @('S1') })
        reviewers = @{}
        dispositions = @()
    }
    $bypassWrite = Invoke-Writer $gateTargetRel (Join-Path $tempRoot 'features\050-gate\delivery-reviews\bypass.json') $bypassJson $text
    Assert ($bypassWrite.code -eq 0) "Bypassed record without reviewer findings must save: $($bypassWrite.output)"
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/bypass.json'
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'bypassed' -and (@($gate.verdict.details) -contains 'Cold review unavailable')) "Bypassed record must be allowed with its reason: $($gate.output)"

    $bypassWithDispositions = ConvertTo-RecordJson @{
        schema = 'delivery-review-record/v1'; state = 'bypassed'; reason = 'Cold review unavailable'
        operator_choice = @{ choice = 'bypass'; evidence = 'operator accepted the bypass' }
        inputs = @(); reviewers = @{}
        dispositions = @(@{ id = 'MINOR-1'; severity = 'MINOR'; disposition = 'accepted_minor'; reason = 'noted' })
    }
    $bypassDispWrite = Invoke-Writer $gateTargetRel (Join-Path $tempRoot 'features\050-gate\delivery-reviews\bypass-dispositions.json') $bypassWithDispositions $text
    Assert ($bypassDispWrite.code -ne 0 -and ($bypassDispWrite.output -match 'cannot carry')) "Writer must reject a bypassed record with dispositions: $($bypassDispWrite.output)"
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'bypass-dispositions.json' $bypassWithDispositions)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'cannot carry')) "Bypassed record with a dispositions array must block as record_schema_invalid: $($gate.output)"

    $bypassFinding = @{ id = 'F-9'; severity = 'B'; category = 'GAP'; section = 'scope'; evidence = 'missing'; recommendation = 'clarify' }
    $bypassWithFinding = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'bypassed'; reason = 'Cold review unavailable'; operator_choice = @{ choice = 'bypass'; evidence = 'operator accepted the bypass' }; inputs = @(); reviewers = (New-ReviewerBlock -Findings @($bypassFinding)); dispositions = @() }
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'bypass-with-finding.json' $bypassWithFinding)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'cannot carry')) "Bypassed record hiding a B finding must block as record_schema_invalid: $($gate.output)"

    foreach ($wrongState in @('NOT_RUN', 'Reviewed', 'BYPASSED')) {
        $wrongStateJson = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = $wrongState; reason = 'case probe'; operator_choice = @{ choice = 'bypass'; evidence = 'operator accepted the bypass' }; inputs = @(); reviewers = (New-ReviewerBlock); dispositions = @() }
        $gate = Invoke-Gate $gateTargetRel (Save-RecordFile ('wrong-state-' + $wrongState + '.json') $wrongStateJson)
        Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'Invalid review state')) "State $wrongState in wrong case must block as record_schema_invalid: $($gate.output)"
    }

    $wrongChoiceJson = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'bypassed'; reason = 'probe'; operator_choice = @{ choice = 'BYPASS'; evidence = 'operator accepted the bypass' }; inputs = @(); reviewers = @{}; dispositions = @() }
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'wrong-choice-case.json' $wrongChoiceJson)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid') "Operator choice BYPASS in wrong case must block as record_schema_invalid: $($gate.output)"

    $bypassNoReason = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'bypassed'; operator_choice = @{ choice = 'bypass'; evidence = 'operator accepted the bypass' }; inputs = @(); reviewers = @{}; dispositions = @() }
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'bypass-no-reason.json' $bypassNoReason)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'Bypass requires a reason')) "Bypass without reason must block as record_schema_invalid: $($gate.output)"

    $approvalAtTopLevel = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; approval = @{ status = 'approved' }; operator_choice = @{ choice = 'content_approval'; evidence = 'operator confirmed' }; inputs = @(); reviewers = (New-ReviewerBlock); dispositions = @() }
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'approval-top-level-choice.json' $approvalAtTopLevel)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'approval.operator_choice')) "Approved without approval.operator_choice must block as record_schema_invalid: $($gate.output)"
    $approvalWriteRejected = Invoke-Writer $gateTargetRel (Join-Path $tempRoot 'features\050-gate\delivery-reviews\approval-rejected.json') $approvalAtTopLevel $text
    Assert ($approvalWriteRejected.code -ne 0) 'Writer must reject approval without approval.operator_choice.'

    $approvalJson = ConvertTo-RecordJson @{
        schema = 'delivery-review-record/v1'; state = 'reviewed'
        approval = @{ status = 'approved'; operator_choice = @{ choice = 'content_approval'; evidence = 'operator confirmed the normative content' } }
        inputs = @(@{ id = 'REQ-1'; path = $gateInputRel; role = 'accepted refinement'; impacted_ids = @('S1') })
        reviewers = (New-ReviewerBlock); dispositions = @()
    }
    $approvalWrite = Invoke-Writer $gateTargetRel (Join-Path $tempRoot 'features\050-gate\delivery-reviews\approved.json') $approvalJson $text
    Assert ($approvalWrite.code -eq 0) "Approved record with approval.operator_choice must save: $($approvalWrite.output)"
    $approvedPersisted = [System.IO.File]::ReadAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\approved.json')) | ConvertFrom-Json
    Assert ($approvedPersisted.schema -ceq 'delivery-review-record/v2') 'Writer must upgrade approved draft records to v2 before persistence.'
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/approved.json'
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Approved record with approval.operator_choice must pass: $($gate.output)"
    $legacyApproved = $approvedPersisted | ConvertTo-Json -Depth 50 | ConvertFrom-Json
    $legacyApproved.schema = 'delivery-review-record/v1'
    $legacyApproved.PSObject.Properties.Remove('material_input_identity')
    $legacyInputs = @($legacyApproved.inputs | ForEach-Object {
        [pscustomobject]@{ id = $_.id; path = $_.path; sha256 = $_.sha256; role = $_.role; impacted_ids = $_.impacted_ids }
    })
    $legacyApproved.target.review_identity = Get-DeliveryReviewIdentity -TargetKind $legacyApproved.target.kind -Stage $legacyApproved.target.stage -TargetPath $legacyApproved.target.path -NormativeSha $legacyApproved.target.content_sha256 -Inputs $legacyInputs
    $legacyApprovedPath = Join-Path $tempRoot 'features\050-gate\delivery-reviews\approved-v1.json'
    [System.IO.File]::WriteAllText($legacyApprovedPath, ($legacyApproved | ConvertTo-Json -Depth 50), $utf8NoBom)
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/approved-v1.json'
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'approval_binding_missing' -and ($gate.output -match 'obtain approval again')) "Approved v1 record must fail closed with migration guidance: $($gate.output)"

    $noImpactedIds = [regex]::Replace($gateRecordText, ',\s*"impacted_ids":\s*\[[^\]]*\]', '')
    $scalarImpactedIds = [regex]::Replace($gateRecordText, '"impacted_ids":\s*\[[^\]]*\]', '"impacted_ids": "S1"')
    Assert ($noImpactedIds -cne $gateRecordText -and $scalarImpactedIds -cne $gateRecordText) 'impacted_ids fixtures must change the record.'
    [System.IO.File]::WriteAllText($gateTarget, $text.Replace('Stable normative criterion.', 'Edited criterion.'), $utf8NoBom)
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'impacted-missing.json' $noImpactedIds)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'impacted_ids')) "Missing impacted_ids must win over identity_stale as record_schema_invalid: $($gate.output)"
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'impacted-scalar.json' $scalarImpactedIds)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'impacted_ids')) "Non-array impacted_ids must win over identity_stale as record_schema_invalid: $($gate.output)"
    [System.IO.File]::WriteAllText($gateTarget, $text, $utf8NoBom)

    $writerNoImpacted = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; inputs = @(@{ id = 'REQ-1'; path = $gateInputRel; role = 'accepted refinement' }); reviewers = (New-ReviewerBlock); dispositions = @() }
    $writerNoImpactedResult = Invoke-Writer $gateTargetRel (Join-Path $tempRoot 'features\050-gate\delivery-reviews\no-impacted.json') $writerNoImpacted $text
    Assert ($writerNoImpactedResult.code -ne 0 -and -not (Test-Path -LiteralPath (Join-Path $tempRoot 'features\050-gate\delivery-reviews\no-impacted.json'))) 'Writer must refuse an input without impacted_ids and write nothing.'

    $danglingTargetDir = Join-Path $tempRoot 'dangling-junction-target'
    $danglingLink = Join-Path $tempRoot 'features\050-gate\delivery-reviews\dangling'
    New-Item -ItemType Directory -Path $danglingTargetDir -Force | Out-Null
    $danglingCreated = $true
    try { New-Item -ItemType Junction -Path $danglingLink -Target $danglingTargetDir | Out-Null } catch { $danglingCreated = $false; Write-Output "SKIP: dangling junction could not be created: $($_.Exception.Message)" }
    if ($danglingCreated) {
        Remove-Item -LiteralPath $danglingTargetDir -Recurse -Force
        $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/dangling/plan.json'
        Assert ($gate.code -ne 0 -and $gate.code -ne 3 -and ($gate.output -match 'Reparse-point')) "Dangling junction ancestor must be rejected: $($gate.output)"
        $danglingWrite = Invoke-Writer $gateTargetRel (Join-Path $danglingLink 'new.json') (New-Record $gateInputRel) $text
        Assert ($danglingWrite.code -ne 0 -and -not (Test-Path -LiteralPath $danglingTargetDir)) "Writer must reject a dangling junction ancestor without creating its target: $($danglingWrite.output)"
    }

    $gate = Invoke-Gate '../outside/PLAN.md' $gateRecordRel
    Assert ($gate.code -eq 1) "Target traversal must exit 1: $($gate.output)"
    $gate = Invoke-Gate $gateTargetRel '../../outside.json'
    Assert ($gate.code -eq 1) "Record path escape must exit 1: $($gate.output)"

    $identityFeature = Join-Path $tempRoot 'features\053-input-identity'
    New-Item -ItemType Directory -Path (Join-Path $identityFeature 'US01'), (Join-Path $identityFeature 'delivery-reviews') -Force | Out-Null
    $identityTargetRel = 'features/053-input-identity/US01/PLAN.md'
    $identityTarget = Join-Path $tempRoot 'features\053-input-identity\US01\PLAN.md'
    $identityTargetText = "# Target plan`nDepends on the predecessor plan.`n"
    [System.IO.File]::WriteAllText($identityTarget, $identityTargetText, $utf8NoBom)

    $identityPlanRel = 'features/053-input-identity/US02/PLAN.md'
    $identityPlan = Join-Path $tempRoot 'features\053-input-identity\US02\PLAN.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $identityPlan) -Force | Out-Null
    [System.IO.File]::WriteAllText($identityPlan, $text, $utf8NoBom)
    $identityPlanRecord = Join-Path $identityFeature 'delivery-reviews\plan-input.json'
    $planInput = Invoke-Writer $identityTargetRel $identityPlanRecord (New-Record $identityPlanRel) $identityTargetText
    Assert ($planInput.code -eq 0) "Plan input record save failed: $($planInput.output)"
    $identityPlanRecordRel = 'features/053-input-identity/delivery-reviews/plan-input.json'
    $planPersisted = Get-Content -LiteralPath $identityPlanRecord -Raw | ConvertFrom-Json
    Assert ($planPersisted.inputs[0].sha256 -ceq (Get-DeliveryNormativeIdentity -Text $text)) 'Plan input must record its normative identity.'

    $planOperational = $text.Replace('"current_stage":"draft"', '"current_stage":"in progress"').Replace('"status":"PENDING"', '"status":"COMPLETED"')
    [System.IO.File]::WriteAllText($identityPlan, $planOperational, $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel $identityPlanRecordRel
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Operational edit in an input plan must stay allowed: $($gate.output)"

    $planNormative = $text.Replace('Stable normative criterion.', 'Revised normative criterion.')
    [System.IO.File]::WriteAllText($identityPlan, $planNormative, $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel $identityPlanRecordRel
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and (@($gate.verdict.details) -contains 'REQ-1')) "Normative edit in an input plan must block as inputs_changed: $($gate.output)"

    $planBroken = $text.Replace('<!-- DELIVERY:PROGRESS:END -->', '')
    [System.IO.File]::WriteAllText($identityPlan, $planBroken, $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel $identityPlanRecordRel
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and ($gate.output -match 'REQ-1') -and ($gate.output -match 'invalid DELIVERY blocks')) "Input plan with broken grammar must block as inputs_changed naming REQ-1: $($gate.output)"
    [System.IO.File]::WriteAllText($identityPlan, $text, $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel $identityPlanRecordRel
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Restored input plan must pass again: $($gate.output)"

    $planLegacyRel = 'features/053-input-identity/TS03/PLAN.md'
    $planLegacy = Join-Path $tempRoot 'features\053-input-identity\TS03\PLAN.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $planLegacy) -Force | Out-Null
    $legacyInputText = $text.Replace('<!-- DELIVERY:STEP:US01-S1:BEGIN -->', '<!-- DELIVERY:STEP-US01-S1:BEGIN -->').Replace('<!-- DELIVERY:STEP:US01-S1:END -->', '<!-- DELIVERY:STEP-US01-S1:END -->')
    [System.IO.File]::WriteAllText($planLegacy, $legacyInputText, $utf8NoBom)
    $legacyInput = Invoke-Writer $identityTargetRel (Join-Path $identityFeature 'delivery-reviews\legacy-input.json') (New-Record $planLegacyRel) $identityTargetText
    Assert ($legacyInput.code -ne 0 -and ($legacyInput.output -match 'REQ-1') -and ($legacyInput.output -match 'invalid DELIVERY blocks') -and ($legacyInput.output -match 'legacy_step_marker')) "Legacy STEP- marker in an input plan must fail the writer with the input id: $($legacyInput.output)"
    Assert (-not (Test-Path -LiteralPath (Join-Path $identityFeature 'delivery-reviews\legacy-input.json'))) 'Writer must not record an input plan with invalid DELIVERY blocks.'

    $refinementInputRel = 'features/053-input-identity/REFINEMENT.md'
    $refinementInput = Join-Path $tempRoot 'features\053-input-identity\REFINEMENT.md'
    $approvalPending = '{"schema":"delivery-approval/v1","state":"pending"}'
    $refinementInputText = "# Feature refinement`n<!-- DELIVERY:APPROVAL:BEGIN -->`n$approvalPending`n<!-- DELIVERY:APPROVAL:END -->`n"
    [System.IO.File]::WriteAllText($refinementInput, $refinementInputText, $utf8NoBom)
    $refinementRecordPath = Join-Path $identityFeature 'delivery-reviews\refinement-input.json'
    $refinementRecordSave = Invoke-Writer $identityTargetRel $refinementRecordPath (New-Record $refinementInputRel) $identityTargetText
    Assert ($refinementRecordSave.code -eq 0) "Refinement input record save failed: $($refinementRecordSave.output)"
    $refinementRecordRel = 'features/053-input-identity/delivery-reviews/refinement-input.json'
    $refinementApprovalEdit = $refinementInputText.Replace('"state":"pending"', '"state":"superseded"')
    [System.IO.File]::WriteAllText($refinementInput, $refinementApprovalEdit, $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel $refinementRecordRel
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "APPROVAL edit in a refinement input must stay allowed: $($gate.output)"
    [System.IO.File]::WriteAllText($refinementInput, $refinementInputText, $utf8NoBom)

    $notesInputRel = 'features/053-input-identity/NOTES.md'
    $notesInput = Join-Path $tempRoot 'features\053-input-identity\NOTES.md'
    $notesInputText = "# Notes`n# Comment v1`n"
    [System.IO.File]::WriteAllText($notesInput, $notesInputText, $utf8NoBom)
    $notesRecordPath = Join-Path $identityFeature 'delivery-reviews\notes-input.json'
    $notesRecordSave = Invoke-Writer $identityTargetRel $notesRecordPath (New-Record $notesInputRel) $identityTargetText
    Assert ($notesRecordSave.code -eq 0) "Ordinary input record save failed: $($notesRecordSave.output)"
    $notesPersisted = Get-Content -LiteralPath $notesRecordPath -Raw | ConvertFrom-Json
    Assert ($notesPersisted.inputs[0].sha256 -ceq (Get-IndependentSha256Hex $notesInputText)) 'Ordinary input must record the SHA-256 of its raw bytes.'
    $notesRecordRel = 'features/053-input-identity/delivery-reviews/notes-input.json'
    [System.IO.File]::WriteAllText($notesInput, "# Notes`n# Comment v2`n", $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel $notesRecordRel
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and (@($gate.verdict.details) -contains 'REQ-1')) "Comment edit in an ordinary input must block as inputs_changed: $($gate.output)"
    [System.IO.File]::WriteAllText($notesInput, $notesInputText, $utf8NoBom)

    'PASS: review-record gate, golden identity, saved-record verdicts, and approval/bypass field rules.'
    $segmentRecord = Join-Path $identityFeature 'delivery-reviews\parent-segment.json'
    foreach ($segmentPath in @('features/../REFINEMENT.md', 'features/053-input-identity/./NOTES.md')) {
        $segmentWrite = Invoke-Writer $identityTargetRel $segmentRecord (New-Record $segmentPath) $identityTargetText
        Assert ($segmentWrite.code -ne 0 -and ($segmentWrite.output -match 'REQ-1') -and ($segmentWrite.output -match 'parent segment')) "Writer must reject input path $segmentPath with the input id: $($segmentWrite.output)"
        Assert (-not (Test-Path -LiteralPath $segmentRecord)) "Writer must not record input path $segmentPath."
    }

    $notesRecordJson = [System.IO.File]::ReadAllText($notesRecordPath)
    $dotSegmentJson = [regex]::Replace($notesRecordJson, '"path":\s*"features/053-input-identity/NOTES\.md"', '"path": "features/053-input-identity/./NOTES.md"')
    Assert ($dotSegmentJson -cne $notesRecordJson) 'Dot-segment checker fixture must change the record.'
    [System.IO.File]::WriteAllText((Join-Path $identityFeature 'delivery-reviews\dot-segment.json'), $dotSegmentJson, $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel 'features/053-input-identity/delivery-reviews/dot-segment.json'
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'parent segment')) "Dot-segment input path must block as record_schema_invalid: $($gate.output)"

    $parentSegmentJson = [regex]::Replace($notesRecordJson, '"path":\s*"features/053-input-identity/NOTES\.md"', '"path": "features/../features/053-input-identity/NOTES.md"')
    Assert ($parentSegmentJson -cne $notesRecordJson) 'Parent-segment checker fixture must change the record.'
    [System.IO.File]::WriteAllText((Join-Path $identityFeature 'delivery-reviews\parent-segment-checker.json'), $parentSegmentJson, $utf8NoBom)
    $gate = Invoke-Gate $identityTargetRel 'features/053-input-identity/delivery-reviews/parent-segment-checker.json'
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'record_schema_invalid' -and ($gate.output -match 'parent segment')) "Parent-segment input path must block as record_schema_invalid: $($gate.output)"

    'PASS: delivery-document inputs use normative identity (plans and refinements), ordinary inputs use raw bytes, invalid input grammar fails closed on write and check.'
    'PASS: schema, identity, marker rejection, legacy STEP rejection, unclosed fence rejection, findings gate, generic targets, no-block drafts, controlled drafts, stale snapshot rejection, traversal, and reparse containment.'

    # Re-audit round fields: shape rules.
    Assert-ShapeError (New-ShapeRecord @{ round = 2 }) 'prior_review_identity is required' 'round 2 without prior'
    Assert-ShapeError (New-ShapeRecord @{ round = 1; prior_review_identity = $priorIdentity }) 'prior_review_identity is allowed only' 'round 1 with prior'
    Assert-ShapeError (New-ShapeRecord @{ prior_review_identity = $priorIdentity }) 'prior_review_identity is allowed only' 'absent round with prior'
    Assert-ShapeError (New-ShapeRecord @{ round = 0 }) 'round must be' 'round 0'
    Assert-ShapeError (New-ShapeRecord @{ round = '2'; prior_review_identity = $priorIdentity }) 'round must be' 'string round'
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity.ToLowerInvariant() }) 'prior_review_identity must be' 'lowercase prior'
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity.Substring(0, 63) }) 'prior_review_identity must be' '63 character prior'
    Assert-ShapePasses (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity }) 'round 2 with prior'
    Assert-ShapePasses (New-ShapeRecord @{ round = 1 }) 'explicit round 1 without prior'

    $roundEntry = @{ round = 2; role = 'critic'; inputs = @(@{ id = 'IN-1'; reason = 'Section 3 changed' }); reported_tokens = $null; reported_tool_calls = 3; duration_s = 41 }
    Assert-ShapePasses (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundEntry) }) 'rounds entry with null tokens'
    $oneRoundJson = New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundEntry) }
    Assert ($oneRoundJson -match '"rounds":\s*\[\s*\{') 'one-element rounds must serialize as an array'
    Assert ($oneRoundJson -match '"inputs":\s*\[\s*\{') 'one-element rounds inputs must serialize as an array'
    Assert-ShapePasses $oneRoundJson 'one-element rounds and inputs arrays'
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @{ round = 2 } }) 'rounds must be an array' 'rounds as object'
    $roundUnknownKey = $roundEntry.Clone(); $roundUnknownKey['author'] = 'x'
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundUnknownKey) }) 'unknown key author' 'rounds entry unknown key'
    $roundBadRole = $roundEntry.Clone(); $roundBadRole['role'] = 'author'
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundBadRole) }) 'role must be reader or critic' 'rounds entry bad role'
    $roundNegative = $roundEntry.Clone(); $roundNegative['reported_tokens'] = -1
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundNegative) }) 'reported_tokens' 'rounds entry negative tokens'
    $roundStringTokens = $roundEntry.Clone(); $roundStringTokens['reported_tokens'] = '5'
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundStringTokens) }) 'reported_tokens' 'rounds entry string tokens'
    $roundBlankReason = $roundEntry.Clone(); $roundBlankReason['inputs'] = @(@{ id = 'IN-1'; reason = ' ' })
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundBlankReason) }) 'reason must be a non-blank string' 'rounds input blank reason'
    $roundInputUnknown = $roundEntry.Clone(); $roundInputUnknown['inputs'] = @(@{ id = 'IN-1'; reason = 'x'; extra = 'y' })
    Assert-ShapeError (New-ShapeRecord @{ round = 2; prior_review_identity = $priorIdentity; rounds = @($roundInputUnknown) }) 'unknown key extra' 'rounds input unknown key'

    $lateStringFinding = New-Finding 'R2-001' 'B' @{ late = 'yes' }
    $resolvedB = @(@{ id = 'R2-001'; severity = 'B'; disposition = 'resolved'; evidence = 'Section 2 now names one output.' })
    Assert-ShapeError (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @($lateStringFinding)); dispositions = $resolvedB }) 'late must be a boolean' 'late as string'
    Assert-ShapePasses (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B' @{ late = $true }))); dispositions = $resolvedB }) 'late true'
    Assert-ShapeError (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B' @{ repeats = 'R2-001' }))); dispositions = $resolvedB }) 'cannot repeat itself' 'repeats equal to own id'
    Assert-ShapeError (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B' @{ repeats = '' }))); dispositions = $resolvedB }) 'repeats must be a non-blank string' 'blank repeats'
    Assert-ShapeError (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B' @{ repeats = 3 }))); dispositions = $resolvedB }) 'repeats must be a non-blank string' 'repeats as number'
    Assert-ShapePasses (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B' @{ repeats = 'R1-001' }))); dispositions = $resolvedB }) 'repeats pointing at prior id'

    # Corrected B, insufficient correction, contested B, MINOR reasons.
    Assert-ShapePasses (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B'))); dispositions = @(@{ id = 'R2-001'; severity = 'B'; disposition = 'contested'; evidence = 'Section 2 is explicit.' }) }) 'contested B with evidence'
    Assert-ShapeError (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B'))); dispositions = @(@{ id = 'R2-001'; severity = 'B'; disposition = 'contested'; evidence = '' }) }) 'requires evidence' 'contested B without evidence'
    Assert-ShapeError (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-002' 'MINOR'))); dispositions = @(@{ id = 'R2-002'; severity = 'MINOR'; disposition = 'accepted_minor' }) }) 'reasoned disposition' 'MINOR without reason'
    Assert-ShapePasses (New-ShapeRecord @{ reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-002' 'MINOR'))); dispositions = @(@{ id = 'R2-002'; severity = 'MINOR'; disposition = 'accepted_minor'; reason = 'Wording is acceptable.' }) }) 'MINOR with reason'

    # Reviewer unavailable on a later round: bypassed or not_run, reasoned, no findings.
    Assert-ShapePasses (New-ShapeRecord @{ state = 'bypassed'; round = 2; prior_review_identity = $priorIdentity; reason = 'Review host offline'; operator_choice = @{ choice = 'bypass'; evidence = 'Operator chose bypass in chat' }; reviewers = @{} }) 'bypassed round 2 without findings'
    Assert-ShapePasses (New-ShapeRecord @{ state = 'not_run'; round = 2; prior_review_identity = $priorIdentity; reason = 'Review host unavailable'; reviewers = @{} }) 'not_run round 2 without findings'
    Assert-ShapeError (New-ShapeRecord @{ state = 'bypassed'; round = 2; prior_review_identity = $priorIdentity; reason = 'Review host offline'; operator_choice = @{ choice = 'bypass'; evidence = 'Operator chose bypass in chat' }; reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-009'))); dispositions = @() }) 'cannot carry' 'bypassed round 2 carrying a finding'

    # Writer and gate: corrected B, insufficient correction, contested evidence, bypass on a later round.
    [System.IO.File]::WriteAllText($gateTarget, $text, $utf8NoBom)
    $gateInputs = @(@{ id = 'REQ-1'; path = $gateInputRel; role = 'accepted refinement'; impacted_ids = @('S1') })

    $correctedJson = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; round = 2; prior_review_identity = $priorIdentity; inputs = $gateInputs; reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-001' 'B'))); dispositions = @(@{ id = 'R2-001'; severity = 'B'; disposition = 'resolved'; evidence = 'Section 2 now names one output.' }) }
    $corrected = Save-GateRecord 'round2-corrected.json' $correctedJson
    Assert ($corrected.code -eq 0) "Corrected round 2 B finding must save: $($corrected.output)"
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/round2-corrected.json'
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Corrected round 2 B finding must pass the gate: $($gate.output)"

    $insufficientFinding = New-Finding 'R2-002' 'B' @{ repeats = 'R1-001' }
    $insufficientJson = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; round = 2; prior_review_identity = $priorIdentity; inputs = $gateInputs; reviewers = (New-ReviewerBlock -Findings @($insufficientFinding)); dispositions = @() }
    $insufficient = Save-GateRecord 'round2-insufficient.json' $insufficientJson
    Assert ($insufficient.code -ne 0 -and $insufficient.output -match 'R2-002 has no disposition') "Repeat finding without disposition must not save: $($insufficient.output)"
    $insufficientDisposed = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; round = 2; prior_review_identity = $priorIdentity; inputs = $gateInputs; reviewers = (New-ReviewerBlock -Findings @($insufficientFinding)); dispositions = @(@{ id = 'R2-002'; severity = 'B'; disposition = 'contested'; evidence = 'Section 1 already states the rule.' }) }
    $insufficientSaved = Save-GateRecord 'round2-insufficient.json' $insufficientDisposed
    Assert ($insufficientSaved.code -eq 0) "Disposed repeat finding must save: $($insufficientSaved.output)"

    $contestedNoEvidence = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; round = 2; prior_review_identity = $priorIdentity; inputs = $gateInputs; reviewers = (New-ReviewerBlock -Findings @((New-Finding 'R2-003' 'B'))); dispositions = @(@{ id = 'R2-003'; severity = 'B'; disposition = 'contested'; evidence = '' }) }
    $contestedResult = Save-GateRecord 'round2-contested-blank.json' $contestedNoEvidence
    Assert ($contestedResult.code -ne 0 -and $contestedResult.output -match 'requires evidence') "Contested B without evidence must not save: $($contestedResult.output)"

    $bypassRoundJson = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'bypassed'; round = 2; prior_review_identity = $priorIdentity; reason = 'Cold review unavailable'; operator_choice = @{ choice = 'bypass'; evidence = 'operator accepted the bypass' }; inputs = @(); reviewers = @{}; dispositions = @() }
    $bypassRoundResult = Save-GateRecord 'round2-bypass.json' $bypassRoundJson
    Assert ($bypassRoundResult.code -eq 0) "Bypassed round 2 must save: $($bypassRoundResult.output)"
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/round2-bypass.json'
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'bypassed') "Bypassed round 2 must pass with its reason: $($gate.output)"

    # Round 2 end to end: round 1 saved, target corrected, builder links the prior identity, writer and gate accept.
    $round1Json = ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; inputs = $gateInputs; reviewers = (New-ReviewerBlock); dispositions = @() }
    $round1Saved = Save-GateRecord 'round1-linked.json' $round1Json
    Assert ($round1Saved.code -eq 0) "Round 1 record must save: $($round1Saved.output)"
    $round1Identity = [string](($round1Saved.output | ConvertFrom-Json).review_identity)

    $round2Text = $text.Replace('Stable normative criterion.', 'Corrected normative criterion.')
    [System.IO.File]::WriteAllText($gateTarget, $round2Text, $utf8NoBom)
    $e2eDir = Join-Path $tempRoot 'e2e-round2'
    New-Item -ItemType Directory -Path $e2eDir -Force | Out-Null
    $e2eReader = Join-Path $e2eDir 'reader.json'
    $e2eCritic = Join-Path $e2eDir 'critic.json'
    $e2eInputs = Join-Path $e2eDir 'inputs.json'
    $e2eDispositions = Join-Path $e2eDir 'dispositions.json'
    $e2eRounds = Join-Path $e2eDir 'rounds.json'
    [System.IO.File]::WriteAllText($e2eReader, '{"paraphrases":{"proposal":"A corrected plan.","current_system":"A declared baseline."},"lenses":["comprehension"],"findings":[]}', $utf8NoBom)
    [System.IO.File]::WriteAllText($e2eCritic, '{"lenses":["consistency"],"findings":[{"id":"C2-001","severity":"I","category":"CONTRADICTION","section":"Section 3","evidence":"Section 3 still differs.","recommendation":"Align Section 3.","late":true,"repeats":"C1-001"}]}', $utf8NoBom)
    [System.IO.File]::WriteAllText($e2eInputs, '[{"id":"REQ-1","path":"features/050-gate/REFINEMENT.md","role":"accepted refinement","impacted_ids":["S1"]}]', $utf8NoBom)
    [System.IO.File]::WriteAllText($e2eDispositions, '[{"id":"C2-001","disposition":"resolved","evidence":"Section 3 now matches the criterion."}]', $utf8NoBom)
    [System.IO.File]::WriteAllText($e2eRounds, '[{"round":2,"role":"critic","inputs":[{"id":"REQ-1","reason":"Criterion revised"}],"reported_tokens":null,"reported_tool_calls":3,"duration_s":41}]', $utf8NoBom)
    $builderArgs = @('-State', 'reviewed', '-RepoPath', $tempRoot,
        '-ReaderResultPath', $e2eReader, '-CriticResultPath', $e2eCritic,
        '-ReaderHost', 'host-reader', '-ReaderIsolation', 'context-only',
        '-CriticHost', 'host-critic', '-CriticIsolation', 'not_reported',
        '-InputsPath', $e2eInputs, '-DispositionsPath', $e2eDispositions, '-RoundsPath', $e2eRounds,
        '-Round', '2', '-PriorReviewIdentity', $round1Identity,
        '-OutPath', 'features/050-gate/scratch/delivery-review/round2.json')
    $builderParams = @{}
    for ($index = 0; $index -lt $builderArgs.Count; $index += 2) {
        $builderParams[([string]$builderArgs[$index]).TrimStart('-')] = $builderArgs[$index + 1]
    }
    $builderCode = 0
    try { $builderOutput = & $builderScript @builderParams 2>&1 | Out-String }
    catch { $builderCode = 1; $builderOutput = [string]$_.Exception.Message }
    Assert ($builderCode -eq 0) "Round 2 builder must exit 0: $builderOutput"
    $round2Json = [System.IO.File]::ReadAllText((Join-Path $tempRoot 'features\050-gate\scratch\delivery-review\round2.json'))
    $round2Saved = Save-GateRecord 'round2-linked.json' $round2Json $round2Text
    Assert ($round2Saved.code -eq 0) "Round 2 record must save through the writer: $($round2Saved.output)"
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/round2-linked.json'
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Round 2 record must pass the gate: $($gate.output)"
    $round2Persisted = Get-Content -LiteralPath (Join-Path $tempRoot 'features\050-gate\delivery-reviews\round2-linked.json') -Raw | ConvertFrom-Json
    Assert ([int]$round2Persisted.round -eq 2) 'Persisted round 2 record must keep round 2.'
    Assert ([string]$round2Persisted.prior_review_identity -ceq $round1Identity) 'Persisted round 2 record must keep the prior review identity.'
    Assert ([string]$round2Persisted.rounds[0].role -ceq 'critic') 'Persisted round 2 record must keep its rounds entry.'
    Assert ([bool]$round2Persisted.reviewers.critic.result.findings[0].late) 'Persisted round 2 finding must keep late.'
    [System.IO.File]::WriteAllText($gateTarget, $text, $utf8NoBom)

    'PASS: re-audit round shape rules, late and repeats fields, contested and MINOR reasons, later-round bypass, and round 2 end to end.'
    'PASS: schema, identity, marker rejection, legacy STEP rejection, unclosed fence rejection, findings gate, generic targets, no-block drafts, controlled drafts, stale snapshot rejection, traversal, and reparse containment.'

    # External input sources: alias paths and source objects (shape rules first).
    function New-ShapeInput([hashtable] $Extra = @{}) {
        $shapeInput = @{ id = 'IN-A'; path = 'alias:docs/brief.md'; role = 'source'; impacted_ids = @('S1') }
        foreach ($key in $Extra.Keys) { $shapeInput[$key] = $Extra[$key] }
        return $shapeInput
    }
    function New-ShapeInputRecord([hashtable] $Extra = @{}) {
        return New-ShapeRecord @{ inputs = @(New-ShapeInput $Extra) }
    }
    $fullRevision = 'a' * 40
    Assert-ShapePasses (New-ShapeInputRecord @{}) 'alias file without source'
    Assert-ShapePasses (New-ShapeInputRecord @{ source = @{ kind = 'file' } }) 'alias file with explicit file source'
    Assert-ShapePasses (New-ShapeInputRecord @{ path = 'alias:docs/specs'; source = @{ kind = 'fileset'; files = @('a.md') } }) 'alias fileset with one-element files'
    Assert-ShapePasses (New-ShapeInputRecord @{ path = 'alias:docs'; source = @{ kind = 'fileset'; files = @('a.md', 'nested/b.md') } }) 'alias-only fileset root'
    Assert-ShapePasses (New-ShapeInputRecord @{ path = 'features/050-gate/specs'; source = @{ kind = 'fileset'; files = @('a.md') } }) 'repository-relative fileset'
    Assert-ShapePasses (New-ShapeInputRecord @{ path = 'alias:gitsrc'; source = @{ kind = 'revision'; revision = $fullRevision } }) 'alias-only revision'
    Assert-ShapePasses (New-ShapeInputRecord @{ path = 'alias:gitsrc'; source = @{ kind = 'revision'; revision = $fullRevision.ToUpperInvariant() } }) 'uppercase revision id'
    $oneFilesJson = New-ShapeInputRecord @{ path = 'alias:docs/specs'; source = @{ kind = 'fileset'; files = @('a.md') } }
    Assert ($oneFilesJson -match '"files":\s*\[\s*"a\.md"\s*\]') 'one-element files must serialize as an array'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'features/050-gate/REFINEMENT.md'; source = @{ kind = 'file' } }) 'plain repository files take no source' 'repository file with file source'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'features/050-gate/REFINEMENT.md'; source = @{ kind = 'revision'; revision = $fullRevision } }) 'alias-only path' 'repository path with revision source'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:gitsrc/notes.txt'; source = @{ kind = 'revision'; revision = $fullRevision } }) 'alias-only path' 'alias with relative part and revision source'
    Assert-ShapeError (New-ShapeInputRecord @{ source = @{ kind = 'folder' } }) 'kind must be' 'unknown source kind'
    Assert-ShapeError (New-ShapeInputRecord @{ source = @{ kind = 'File' } }) 'kind must be' 'source kind wrong case'
    Assert-ShapeError (New-ShapeInputRecord @{ source = @{ Kind = 'file' } }) 'kind must be' 'source key wrong case'
    Assert-ShapeError (New-ShapeInputRecord @{ source = @{ kind = $null } }) 'kind must be' 'null source kind'
    Assert-ShapeError (New-ShapeInputRecord @{ source = @{ files = @('a.md') } }) 'kind must be' 'source without kind'
    Assert-ShapeError (New-ShapeInputRecord @{ source = 'fileset' }) 'must be an object' 'scalar source'
    Assert-ShapeError (New-ShapeInputRecord @{ source = $null }) 'must be an object' 'null source'
    Assert-ShapeError (New-ShapeInputRecord @{ source = @{ kind = 'file'; files = @('a.md') } }) 'unknown key' 'file source with files key'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/specs'; source = @{ kind = 'fileset'; files = @('a.md'); revision = $fullRevision } }) 'unknown key' 'fileset source with revision key'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:gitsrc'; source = @{ kind = 'revision'; revision = $fullRevision; files = @('a.md') } }) 'unknown key' 'revision source with files key'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/specs'; source = @{ kind = 'fileset'; files = @() } }) 'non-empty array' 'empty fileset files'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/specs'; source = @{ kind = 'fileset'; files = 'a.md' } }) 'non-empty array' 'fileset files as string'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/specs'; source = @{ kind = 'fileset' } }) 'non-empty array' 'fileset without files'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/specs'; source = @{ kind = 'fileset'; files = @(' ') } }) 'non-blank' 'blank fileset member'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:gitsrc'; source = @{ kind = 'revision'; revision = 'a' * 39 } }) 'exactly 40' 'short revision'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:gitsrc'; source = @{ kind = 'revision'; revision = ('g' * 40) } }) 'exactly 40' 'non-hex revision'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:gitsrc'; source = @{ kind = 'revision' } }) 'exactly 40' 'revision without id'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:Docs/brief.md' }) 'lowercase slug' 'uppercase alias name'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:' }) 'lowercase slug' 'empty alias name'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/' }) 'must not end with a slash' 'alias trailing slash'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs//brief.md' }) 'empty, current or parent segment' 'alias empty segment'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/../brief.md' }) 'parent segment' 'alias parent segment'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs/./brief.md' }) 'parent segment' 'alias current segment'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs' }) 'alias-only path requires' 'alias-only path without source is a file'
    Assert-ShapeError (New-ShapeInputRecord @{ path = 'alias:docs'; source = @{ kind = 'file' } }) 'alias-only path requires' 'alias-only path with file source'

    # Writer and gate: alias file, fileset and revision inputs over a temp catalog.
    $sourcesRoot = Join-Path $tempRoot 'external-sources'
    $docsRoot = Join-Path $sourcesRoot 'docs'
    $specsRoot = Join-Path $docsRoot 'specs'
    New-Item -ItemType Directory -Path $specsRoot -Force | Out-Null
    $briefFile = Join-Path $docsRoot 'brief.md'
    $specAFile = Join-Path $specsRoot 'a.md'
    $specBFile = Join-Path $specsRoot 'b.md'
    $externalPlanFile = Join-Path $docsRoot 'external-plan.md'
    [System.IO.File]::WriteAllText($briefFile, "# Brief v1`n", $utf8NoBom)
    [System.IO.File]::WriteAllText($specAFile, "A v1`n", $utf8NoBom)
    [System.IO.File]::WriteAllText($specBFile, "B v1`n", $utf8NoBom)
    [System.IO.File]::WriteAllText($externalPlanFile, $text, $utf8NoBom)

    $gitSourceRoot = Join-Path $sourcesRoot 'gitsrc'
    $gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
    $aliasEntries = [System.Collections.Generic.List[object]]::new()
    $aliasEntries.Add([ordered]@{ name = 'docs'; root = $docsRoot; kind = 'directory' })
    $revisionCommit = ''
    $revisionTree = ''
    if ($gitAvailable) {
        New-Item -ItemType Directory -Path $gitSourceRoot -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $gitSourceRoot 'notes.txt'), "notes v1`n", $utf8NoBom)
        $gitInit = & git -C $gitSourceRoot -c init.defaultBranch=main init -q 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git fixture init failed: $gitInit" }
        $gitAdd = & git -C $gitSourceRoot add -- notes.txt 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git fixture add failed: $gitAdd" }
        $gitCommit = & git -C $gitSourceRoot -c user.name=t -c user.email=t@t.t -c commit.gpgsign=false commit -q -m 'test: seed fixture' 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git fixture commit failed: $gitCommit" }
        $revisionCommit = (& git -C $gitSourceRoot rev-parse HEAD).Trim()
        $revisionTree = (& git -C $gitSourceRoot rev-parse 'HEAD^{tree}').Trim()
        $aliasEntries.Add([ordered]@{ name = 'gitsrc'; root = $gitSourceRoot; kind = 'git' })
    }
    else {
        Write-Output 'SKIP: revision source cases; git is not available.'
    }
    $catalogPath = Join-Path $sourcesRoot 'aliases.json'
    $catalogDocument = [ordered]@{ schema = 'delivery-input-aliases/v1'; aliases = $aliasEntries.ToArray() }
    [System.IO.File]::WriteAllText($catalogPath, ($catalogDocument | ConvertTo-Json -Depth 6), $utf8NoBom)

    function Get-RawFileSha256([string] $Path) {
        return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.IO.File]::ReadAllBytes($Path)))
    }
    function New-SourceRecordJson([object[]] $Inputs) {
        return ConvertTo-RecordJson @{ schema = 'delivery-review-record/v1'; state = 'reviewed'; inputs = @($Inputs); reviewers = (New-ReviewerBlock); dispositions = @() }
    }
    function Invoke-SourceWriter([string] $RecordPath, [string] $Json, [AllowNull()][string] $CatalogPath) {
        $params = @{
            Action = 'save'; RepoPath = $tempRoot; TargetPath = $gateTargetRel; TargetKind = 'PLAN.md'; Stage = 'delivery_unit_plan_review'
            ArtifactText = $text; RecordPath = $RecordPath; RecordJson = $Json
        }
        if (-not [string]::IsNullOrWhiteSpace($CatalogPath)) { $params['AliasCatalogPath'] = $CatalogPath }
        try {
            $output = & $writer @params 2>&1 | Out-String
            return [pscustomobject]@{ output = $output.Trim(); code = 0 }
        }
        catch {
            return [pscustomobject]@{ output = [string]$_.Exception.Message; code = 1 }
        }
    }
    function Save-SourceRecord([string] $Name, [string] $Json, [AllowNull()][string] $CatalogPath) {
        return Invoke-SourceWriter (Join-Path $tempRoot ('features\050-gate\delivery-reviews\' + $Name + '.json')) $Json $CatalogPath
    }
    function Read-SourceRecord([string] $Name) {
        return [System.IO.File]::ReadAllText((Join-Path $tempRoot ('features\050-gate\delivery-reviews\' + $Name + '.json'))) | ConvertFrom-Json
    }
    function Invoke-SourceGate([string] $Name, [AllowNull()][string] $CatalogPath) {
        $gateParams = @{ RepoPath = $tempRoot; TargetPath = $gateTargetRel; RecordPath = ('features/050-gate/delivery-reviews/' + $Name + '.json'); AsLibrary = $true }
        if (-not [string]::IsNullOrWhiteSpace($CatalogPath)) { $gateParams['AliasCatalogPath'] = $CatalogPath }
        $result = & $gateScript @gateParams
        $output = if ($null -ne $result.Result) { $result.Result | ConvertTo-Json -Compress -Depth 10 } else { [string]$result.Error }
        return [pscustomobject]@{ code = [int]$result.ExitCode; verdict = $result.Result; output = $output }
    }

    $srcFileInput = @{ id = 'SRC-FILE'; path = 'alias:docs/brief.md'; role = 'accepted refinement'; impacted_ids = @('S1') }
    $srcFileSave = Save-SourceRecord 'src-file' (New-SourceRecordJson @($srcFileInput)) $catalogPath
    Assert ($srcFileSave.code -eq 0) "Alias file input must save: $($srcFileSave.output)"
    $srcFileRaw = [System.IO.File]::ReadAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-file.json'))
    Assert (-not $srcFileRaw.Contains($sourcesRoot) -and -not $srcFileRaw.Contains($sourcesRoot.Replace('\', '/'))) 'Saved record must not contain the alias root.'
    $srcFilePersisted = Read-SourceRecord 'src-file'
    Assert ($srcFilePersisted.inputs[0].path -ceq 'alias:docs/brief.md') 'Alias file path must be recorded as written.'
    Assert ($srcFilePersisted.inputs[0].sha256 -ceq (Get-RawFileSha256 $briefFile)) 'Alias file input must record the SHA-256 of its raw bytes.'
    Assert (-not $srcFilePersisted.inputs[0].PSObject.Properties['source']) 'Alias file without source must not echo a source.'

    $srcSetInput = @{ id = 'SRC-SET'; path = 'alias:docs/specs'; role = 'accepted refinement'; impacted_ids = @('S1'); source = @{ kind = 'fileset'; files = @('b.md', 'a.md') } }
    $srcSetSave = Save-SourceRecord 'src-set' (New-SourceRecordJson @($srcSetInput)) $catalogPath
    Assert ($srcSetSave.code -eq 0) "Alias fileset input must save: $($srcSetSave.output)"
    $srcSetPersisted = Read-SourceRecord 'src-set'
    $expectedSetIdentity = Get-IndependentSha256Hex ('[{"path":"a.md","sha256":"' + (Get-RawFileSha256 $specAFile) + '"},{"path":"b.md","sha256":"' + (Get-RawFileSha256 $specBFile) + '"}]')
    Assert ($srcSetPersisted.inputs[0].sha256 -ceq $expectedSetIdentity) 'Fileset input must record the sorted per-file identity.'
    Assert ($srcSetPersisted.inputs[0].source.kind -ceq 'fileset' -and @($srcSetPersisted.inputs[0].source.files).Count -eq 2) 'Fileset input must echo its source.'

    if ($gitAvailable) {
        $srcRevInput = @{ id = 'SRC-REV'; path = 'alias:gitsrc'; role = 'accepted refinement'; impacted_ids = @('S1'); source = @{ kind = 'revision'; revision = $revisionCommit } }
        $srcRevSave = Save-SourceRecord 'src-rev' (New-SourceRecordJson @($srcRevInput)) $catalogPath
        Assert ($srcRevSave.code -eq 0) "Revision input must save: $($srcRevSave.output)"
        $srcRevPersisted = Read-SourceRecord 'src-rev'
        $expectedRevIdentity = Get-IndependentSha256Hex ('{"kind":"revision","alias":"gitsrc","commit":"' + $revisionCommit + '","tree":"' + $revisionTree + '"}')
        Assert ($srcRevPersisted.inputs[0].sha256 -ceq $expectedRevIdentity) 'Revision input must record the commit and tree identity.'
        Assert ($srcRevPersisted.inputs[0].source.revision -ceq $revisionCommit) 'Revision input must echo its revision.'
    }

    $unknownAliasInput = @{ id = 'SRC-BAD'; path = 'alias:nope/brief.md'; role = 'source'; impacted_ids = @('S1') }
    $unknownAlias = Save-SourceRecord 'src-unknown' (New-SourceRecordJson @($unknownAliasInput)) $catalogPath
    Assert ($unknownAlias.code -ne 0 -and $unknownAlias.output -match "Input 'SRC-BAD': alias_unknown: ") "Unknown alias must fail the writer with its code and input id: $($unknownAlias.output)"
    Assert (-not (Test-Path -LiteralPath (Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-unknown.json'))) 'Unknown alias must not write a record.'
    $noCatalog = Save-SourceRecord 'src-nocatalog' (New-SourceRecordJson @($srcFileInput)) $null
    Assert ($noCatalog.code -ne 0 -and $noCatalog.output -match "Input 'SRC-FILE': alias_catalog_missing: ") "Alias input without a catalog must fail with alias_catalog_missing: $($noCatalog.output)"
    $driveEscape = Save-SourceRecord 'src-drive' (New-SourceRecordJson @(@{ id = 'SRC-ESC'; path = 'alias:docs/C:/outside.txt'; role = 'source'; impacted_ids = @('S1') })) $catalogPath
    Assert ($driveEscape.code -ne 0 -and $driveEscape.output -match "Input 'SRC-ESC': source_path_invalid: ") "Drive-form alias path must fail with source_path_invalid: $($driveEscape.output)"
    $parentEscape = Save-SourceRecord 'src-parent' (New-SourceRecordJson @(@{ id = 'SRC-UP'; path = 'alias:docs/../brief.md'; role = 'source'; impacted_ids = @('S1') })) $catalogPath
    Assert ($parentEscape.code -ne 0 -and $parentEscape.output -match 'parent segment' -and -not (Test-Path -LiteralPath (Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-parent.json'))) "Parent-segment alias path must fail before any record is written: $($parentEscape.output)"

    $gate = Invoke-SourceGate 'src-file' $catalogPath
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Alias file input must pass the gate: $($gate.output)"
    $gate = Invoke-SourceGate 'src-set' $catalogPath
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Alias fileset input must pass the gate: $($gate.output)"
    if ($gitAvailable) {
        $gate = Invoke-SourceGate 'src-rev' $catalogPath
        Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Revision input must pass the gate: $($gate.output)"
    }

    [System.IO.File]::WriteAllText($briefFile, "# Brief v2`n", $utf8NoBom)
    $gate = Invoke-SourceGate 'src-file' $catalogPath
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and (@($gate.verdict.details) -contains 'SRC-FILE')) "Edited alias file must block as inputs_changed naming SRC-FILE: $($gate.output)"
    [System.IO.File]::WriteAllText($briefFile, "# Brief v1`n", $utf8NoBom)

    [System.IO.File]::WriteAllText($specAFile, "A v2`n", $utf8NoBom)
    $gate = Invoke-SourceGate 'src-set' $catalogPath
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and (@($gate.verdict.details) -contains 'SRC-SET')) "Changed listed fileset member must block as inputs_changed: $($gate.output)"
    [System.IO.File]::WriteAllText($specAFile, "A v1`n", $utf8NoBom)

    $specCFile = Join-Path $specsRoot 'c.md'
    [System.IO.File]::WriteAllText($specCFile, "C v1`n", $utf8NoBom)
    $gate = Invoke-SourceGate 'src-set' $catalogPath
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "A file added to the directory but not to the recorded list is not part of the identity: $($gate.output)"
    Remove-Item -LiteralPath $specCFile -Force

    $setRaw = [System.IO.File]::ReadAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-set.json'))
    $setDropped = [regex]::Replace($setRaw, '"files":\s*\[\s*"b\.md",\s*"a\.md"\s*\]', '"files": ["a.md"]')
    Assert ($setDropped -cne $setRaw) 'Fileset tamper fixture must change the record.'
    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-set-dropped.json'), $setDropped, $utf8NoBom)
    $gate = Invoke-SourceGate 'src-set-dropped' $catalogPath
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and (@($gate.verdict.details) -contains 'SRC-SET')) "Tampered source.files that changes the set must block as inputs_changed: $($gate.output)"

    $setReordered = [regex]::Replace($setRaw, '"files":\s*\[\s*"b\.md",\s*"a\.md"\s*\]', '"files": ["a.md", "b.md"]')
    Assert ($setReordered -cne $setRaw) 'Fileset reorder fixture must change the record.'
    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-set-reordered.json'), $setReordered, $utf8NoBom)
    $gate = Invoke-SourceGate 'src-set-reordered' $catalogPath
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Reordered source.files is not part of the identity and stays reviewed: $($gate.output)"

    $gate = Invoke-SourceGate 'src-file' $null
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'input_source_unavailable' -and (@($gate.verdict.details) -contains 'SRC-FILE: alias_catalog_missing')) "Gate without a catalog must block as input_source_unavailable: $($gate.output)"

    $srcFileUnknownRaw = [regex]::Replace($srcFileRaw, '"path":\s*"alias:docs/brief\.md"', '"path": "alias:nope/brief.md"')
    Assert ($srcFileUnknownRaw -cne $srcFileRaw) 'Unknown alias fixture must change the record.'
    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-file-unknown.json'), $srcFileUnknownRaw, $utf8NoBom)
    $gate = Invoke-SourceGate 'src-file-unknown' $catalogPath
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'input_source_unavailable' -and (@($gate.verdict.details) -contains 'SRC-FILE: alias_unknown')) "Unknown alias must block as input_source_unavailable: $($gate.output)"

    Move-Item -LiteralPath $briefFile -Destination ($briefFile + '.moved') -Force
    $gate = Invoke-SourceGate 'src-file' $catalogPath
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'input_source_unavailable' -and (@($gate.verdict.details) -contains 'SRC-FILE: source_missing')) "Missing alias file must block as input_source_unavailable: $($gate.output)"
    Move-Item -LiteralPath ($briefFile + '.moved') -Destination $briefFile -Force

    if ($gitAvailable) {
        $srcRevRaw = [System.IO.File]::ReadAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-rev.json'))
        $srcRevUnknownRaw = $srcRevRaw.Replace($revisionCommit, ('f' * 40))
        Assert ($srcRevUnknownRaw -cne $srcRevRaw) 'Unreachable revision fixture must change the record.'
        [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-rev-unknown.json'), $srcRevUnknownRaw, $utf8NoBom)
        $gate = Invoke-SourceGate 'src-rev-unknown' $catalogPath
        Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'input_source_unavailable' -and (@($gate.verdict.details) -contains 'SRC-REV: revision_unavailable')) "Unreachable revision must block as input_source_unavailable: $($gate.output)"
    }

    $overlongMember = 'a' * 33000
    $setOverlong = [regex]::Replace($setRaw, '"files":\s*\[\s*"b\.md",\s*"a\.md"\s*\]', ('"files": ["' + $overlongMember + '"]'))
    Assert ($setOverlong -cne $setRaw) 'Overlong member fixture must change the record.'
    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\050-gate\delivery-reviews\src-set-overlong.json'), $setOverlong, $utf8NoBom)
    $gate = Invoke-SourceGate 'src-set-overlong' $catalogPath
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'input_source_unavailable' -and @($gate.verdict.details).Count -eq 1 -and @($gate.verdict.details)[0].StartsWith('SRC-SET: ', [System.StringComparison]::Ordinal)) "A non-code failure on a source-bearing input must block as input_source_unavailable: $($gate.output)"
    Assert (-not (@($gate.verdict.details)[0] -cmatch '^SRC-SET: source_')) "Overlong member must fail outside the coded source errors: $($gate.output)"

    $srcPlanInput = @{ id = 'SRC-PLAN'; path = 'alias:docs/external-plan.md'; role = 'accepted refinement'; impacted_ids = @('S1') }
    $srcPlanSave = Save-SourceRecord 'src-plan' (New-SourceRecordJson @($srcPlanInput)) $catalogPath
    Assert ($srcPlanSave.code -eq 0) "Alias plan input must save: $($srcPlanSave.output)"
    $srcPlanPersisted = Read-SourceRecord 'src-plan'
    Assert ($srcPlanPersisted.inputs[0].sha256 -ceq (Get-RawFileSha256 $externalPlanFile)) 'Alias plan input must be identified by raw bytes, not by its normative identity.'
    $externalOperational = $text.Replace('"status":"PENDING"', '"status":"COMPLETED"')
    [System.IO.File]::WriteAllText($externalPlanFile, $externalOperational, $utf8NoBom)
    $gate = Invoke-SourceGate 'src-plan' $catalogPath
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'inputs_changed' -and (@($gate.verdict.details) -contains 'SRC-PLAN')) "Operational edit in an alias plan must block as inputs_changed (raw bytes): $($gate.output)"
    [System.IO.File]::WriteAllText($externalPlanFile, $text, $utf8NoBom)

    'PASS: external input source shape rules, alias and source writer records, gate verdicts (inputs_changed and input_source_unavailable), and raw-byte alias plan identity.'
    Write-Output ('PASS: {0} delivery review record assertions.' -f $passed)
} finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
exit 0
