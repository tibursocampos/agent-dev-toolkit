[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$writer = Join-Path $PSScriptRoot '..\runtime\Write-DeliveryReviewRecord.ps1'
$writer = [System.IO.Path]::GetFullPath($writer)
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-review-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
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
$childHost = (Get-Process -Id $PID).Path
$gateScript = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\runtime\Test-DeliveryReviewRecord.ps1'))
function Invoke-Gate([string]$TargetPath, [string]$RecordPath) {
    $output = & $childHost -NoProfile -ExecutionPolicy Bypass -File $gateScript -RepoPath $tempRoot -TargetPath $TargetPath -RecordPath $RecordPath 2>&1 | Out-String
    $code = $LASTEXITCODE
    $verdict = $null
    try { $verdict = $output.Trim() | ConvertFrom-Json } catch { $verdict = $null }
    return [pscustomobject]@{ code = $code; verdict = $verdict; output = $output.Trim() }
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
    $goldenWritten = $golden.output | ConvertFrom-Json
    $goldenPayload = '{"target_kind":"PLAN.md","stage":"delivery_unit_plan_review","target_path":"features/052-golden/US01/PLAN.md","normative_content_sha256":"' + (Get-IndependentSha256Hex $goldenBody) + '","inputs":[{"id":"REQ-1","path":"features/052-golden/REFINEMENT.md","sha256":"' + (Get-IndependentSha256Hex $goldenInputBody) + '","role":"accepted refinement","impacted_ids":["S1"]}]}'
    $goldenExpected = Get-IndependentSha256Hex $goldenPayload
    Assert ($goldenWritten.review_identity -ceq $goldenExpected) "Writer review identity drifted from the golden formula: $($goldenWritten.review_identity)"
    $libraryIdentity = Get-DeliveryReviewIdentity -TargetKind 'PLAN.md' -Stage 'delivery_unit_plan_review' -TargetPath $goldenTargetRel -NormativeSha (Get-IndependentSha256Hex $goldenBody) -Inputs @([pscustomobject]@{ id = 'REQ-1'; path = $goldenInputRel; sha256 = (Get-IndependentSha256Hex $goldenInputBody); role = 'accepted refinement'; impacted_ids = @('S1') })
    Assert ($libraryIdentity -ceq $goldenExpected) 'Library review identity drifted from the golden formula.'
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

    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'wrong-schema.json' $gateRecordText.Replace('delivery-review-record/v1', 'delivery-review-record/v0'))
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
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'review_identity_mismatch') "Tampered input role must block as review_identity_mismatch: $($gate.output)"

    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'features\050-gate\REFINEMENT-copy.md'), '# Gate input v1', $utf8NoBom)
    $pathTampered = [regex]::Replace($gateRecordText, '"path":\s*"features/050-gate/REFINEMENT\.md"', '"path": "features/050-gate/REFINEMENT-copy.md"')
    Assert ($pathTampered -cne $gateRecordText) 'Path tamper fixture must change the record.'
    $gate = Invoke-Gate $gateTargetRel (Save-RecordFile 'path-tampered.json' $pathTampered)
    Assert ($gate.code -eq 3 -and $gate.verdict.reason -eq 'review_identity_mismatch') "Tampered input path must block as review_identity_mismatch: $($gate.output)"

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
    $gate = Invoke-Gate $gateTargetRel 'features/050-gate/delivery-reviews/approved.json'
    Assert ($gate.code -eq 0 -and $gate.verdict.reason -eq 'reviewed') "Approved record with approval.operator_choice must pass: $($gate.output)"

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

    'PASS: review-record gate, golden identity, saved-record verdicts, and approval/bypass field rules.'
    'PASS: schema, identity, marker rejection, legacy STEP rejection, unclosed fence rejection, findings gate, generic targets, no-block drafts, controlled drafts, stale snapshot rejection, traversal, and reparse containment.'
} finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
exit 0
