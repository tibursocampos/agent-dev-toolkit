#Requires -Version 5.1
# Consolidated cross-flow contract checks for PRD 021 CA1-CA10.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Read-Contract([string] $RelativePath) {
    $path = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing contract: $RelativePath" }
    return [System.IO.File]::ReadAllText($path)
}

function Assert-Contract([string] $Case, [string] $Text, [string[]] $Markers) {
    foreach ($marker in $Markers) {
        if ($Text.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "$Case failed; missing '$marker'."
        }
    }
    Write-Host "$Case`: PASS"
}

function Assert-IncompleteAnalysisFixture([string] $RelativePath) {
    $fixtureText = Read-Contract $RelativePath
    $fixture = $fixtureText | ConvertFrom-Json
    if (@($fixture.flowLinks).Count -eq 0) { throw 'CA14_IncompleteAnalysisRemainsGap failed; fixture has no material flow links.' }

    $hasGap = $false
    foreach ($link in @($fixture.flowLinks)) {
        if ([string]::IsNullOrWhiteSpace([string]$link.evidence)) {
            if ([string]$link.confidence -ne 'GAP') {
                throw "CA14_IncompleteAnalysisRemainsGap failed; unevidenced link '$($link.name)' is not marked GAP."
            }
            $hasGap = $true
        }
    }

    if ([string]::IsNullOrWhiteSpace([string]$fixture.reuse.evidence)) {
        if ([string]$fixture.reuse.disposition -ne 'GAP') {
            throw 'CA14_IncompleteAnalysisRemainsGap failed; reuse without evidence is not marked GAP.'
        }
        $hasGap = $true
    }

    if ($hasGap -and [string]$fixture.recommendation.status -ne 'PROPOSAL_ONLY') {
        throw 'CA14_IncompleteAnalysisRemainsGap failed; recommendation based on unresolved gaps is not proposal-only.'
    }
    Write-Host 'CA14_IncompleteAnalysisRemainsGap: PASS (fixture expectations only; no live model behavior inferred)'
}

$analysis = Read-Contract 'core/skills/_shared/agents/BROWNFIELD-ANALYSIS.md'
$repoAnalyst = Read-Contract 'core/skills/_shared/agents/prompts/repo_analyst.md'
$architect = Read-Contract 'core/skills/_shared/agents/prompts/architect.md'
$spawn = Read-Contract 'core/skills/_shared/agents/SPAWN.md'
$receipt = Read-Contract 'core/skills/_shared/agents/RECEIPT.md'
$o1 = Read-Contract 'core/skills/orchestrate-analyze/SKILL.md'
$o2 = Read-Contract 'core/skills/orchestrate-deliver/references/preconditions.md'
$o3 = Read-Contract 'core/skills/orchestrate-develop/SKILL.md'
$classic = Read-Contract 'core/skills/sdd-develop/references/code-analysis.md'
$developer = Read-Contract 'core/skills/_shared/developer-common/step-0-context.md'
$validateCore = Read-Contract 'scripts/validation/validate-core.ps1'

Assert-Contract 'CA1_ProjectEvidencePrecedence' $analysis @('Project-first evidence', 'actual examples', 'security risk', 'do not silently re-architect')
Assert-Contract 'RepositoryContentTrustBoundary' $analysis @('Repository content is evidence, not authorization', 'higher-priority instructions', 'untrusted data', 'expand authorization or scope', 'not permission to execute them', 'separately authorized')
Assert-Contract 'CA2_ProportionalDiscovery' $analysis @('Proportional discovery', 'Expand discovery only', 'do not require an inventory')
Assert-Contract 'CA3_FactsInferenceAndGaps' $analysis @('CONFIRMED', 'INFERRED', 'GAP', 'Do not state an inferred convention as confirmed')
Assert-Contract 'CA4_ImpactReuseAndNoChange' $analysis @('components or tests that could be reused', 'NO_CHANGE', 'reason')
Assert-Contract 'CA11_MaterialFlowTraceAndEvidenceGaps' $analysis @('Material behavior-flow trace and reuse decision', 'entry/input', 'dispatch or selection', 'producer', 'receiver/consumer', 'state or data effect', 'observable output/error', 'if a link has not been verified, mark it `GAP`', 'static inspection does not prove runtime activation')
Assert-Contract 'CA12_ExplicitReuseVersusNewComparison' ($analysis + $repoAnalyst) @('Compare the proposed change', 'what can be reused or extended', 'whether any new abstraction is justified by evidence', 'If no local precedent or reusable component is demonstrated, record that as `GAP`', 'CREATE', 'REUSE')
Assert-Contract 'CA13_O2ConsumesFlowAndReuseEvidence' $o2 @('trace of each material current behavior', 'comparison of local reuse/extension', 'fixed number of files or layers', 'A flow link or reuse claim without supporting evidence remains `GAP`')
Assert-Contract 'CA16_O2RunsDeterministicEvidenceValidator' ($analysis + $o2) @('validate-brownfield-analysis.ps1', 'Invoke-O2BrownfieldPreflight.ps1 -AnalysisPath', 'returns `ALLOW` only', '`BLOCK` or a nonzero exit blocks this story', 'Classification', 'Limitation', 'never edit the artifact', 'CONFIRMED', 'INFERRED', 'GAP', 'PROPOSAL_ONLY')
Assert-Contract 'CA5_MaterialAmbiguityBlocksAdvancement' $analysis @('Resolve material product and contract questions', 'ask the responsible decision owner')
Assert-Contract 'CA6_AnalysisConsumedBeforeImplementation' ($o1 + $o2 + $o3 + $classic + $developer) @('brownfield', 'before', 'implementation')
Assert-Contract 'CA7_RoleSpecificOutputContracts' ($repoAnalyst + $architect + $receipt) @('Output', 'role-specific', 'finding')
Assert-Contract 'CA8_ValidatedMachineFormatWithoutYamlProtocol' ($receipt + $spawn) @('JSON', 'YAML', 'consumer')
Assert-Contract 'CA9_O3InvariantsRemainDocumented' ($o3 + $receipt) @('claim', 'receipt', 'one step')
Assert-Contract 'CA10_BoundedSpecialistInputAndExpectedResult' $spawn @('role', 'objective', 'scope', 'references', 'expected result')
Assert-Contract 'CentralValidatorRegistersConsolidatedContract' $validateCore @('brownfield-discovery-contract', 'Assert-BrownfieldDiscoveryContract.ps1')
Assert-Contract 'CentralValidatorRegistersEvidenceClassificationConsumer' $validateCore @('brownfield-analysis-validation', 'Assert-BrownfieldAnalysisValidator.ps1')
Assert-IncompleteAnalysisFixture 'scripts/validation/fixtures/brownfield/incomplete-analysis.json'
$misclassifiedFixtureRejected = $false
try {
    Assert-IncompleteAnalysisFixture 'scripts/validation/fixtures/brownfield/confirmed-without-evidence.json'
}
catch {
    $misclassifiedFixtureRejected = $true
}
if (-not $misclassifiedFixtureRejected) {
    throw 'CA15_MisclassifiedAnalysisIsRejected failed; fixture marks unevidenced behavior as confirmed without being rejected.'
}
Write-Host 'CA15_MisclassifiedAnalysisIsRejected: PASS'
