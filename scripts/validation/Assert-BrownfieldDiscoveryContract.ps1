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
Assert-Contract 'CA5_MaterialAmbiguityBlocksAdvancement' $analysis @('Resolve material product and contract questions', 'ask the responsible decision owner')
Assert-Contract 'CA6_AnalysisConsumedBeforeImplementation' ($o1 + $o2 + $o3 + $classic + $developer) @('brownfield', 'before', 'implementation')
Assert-Contract 'CA7_RoleSpecificOutputContracts' ($repoAnalyst + $architect + $receipt) @('Output', 'role-specific', 'finding')
Assert-Contract 'CA8_ValidatedMachineFormatWithoutYamlProtocol' ($receipt + $spawn) @('JSON', 'YAML', 'consumer')
Assert-Contract 'CA9_O3InvariantsRemainDocumented' ($o3 + $receipt) @('claim', 'receipt', 'one step')
Assert-Contract 'CA10_BoundedSpecialistInputAndExpectedResult' $spawn @('role', 'objective', 'scope', 'references', 'expected result')
Assert-Contract 'CentralValidatorRegistersConsolidatedContract' $validateCore @('brownfield-discovery-contract', 'Assert-BrownfieldDiscoveryContract.ps1')
