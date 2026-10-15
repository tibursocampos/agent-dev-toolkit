#Requires -Version 5.1
# Static contracts for mixed per-step testing, final US consolidation, and evidence history.
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Read-Contract {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    $path = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing contract: $RelativePath" }
    return [System.IO.File]::ReadAllText($path)
}

function Assert-ContractText {
    param(
        [Parameter(Mandatory = $true)][string] $Case,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string[]] $Markers
    )
    foreach ($marker in $Markers) {
        if ($Text.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "$Case failed; missing contract marker: $marker"
        }
    }
    Write-Host "$Case`: PASS"
}

$planTemplate = Read-Contract 'core/skills/_shared/templates/sdd/PLAN.md'
$planUsage = Read-Contract 'core/skills/sdd-plan/references/template-usage.md'
$planContract = Read-Contract 'core/skills/sdd-develop/references/plan-contract.md'
$evidenceContract = Read-Contract 'core/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md'
$developEvidence = Read-Contract 'core/skills/sdd-develop/references/evidence-or-zero.md'
$o3Queue = Read-Contract 'core/skills/orchestrate-develop/references/step-queue-spawn.md'

Assert-ContractText -Case 'Should_NotApproveIntermediateStep_When_CheckIsDeferred' -Text $planContract -Markers @(
    'A deferred check is pending, never a pass',
    'cannot satisfy an intermediate step''s acceptance or approve that step',
    'may be assigned to the final test-consolidation step only',
    'it does not gate',
    'the current step''s acceptance'
)
Assert-ContractText -Case 'Should_RequireFinalConsolidation_When_USDoDCloses' -Text ($planTemplate + $planUsage + $o3Queue) -Markers @(
    'final test-consolidation step',
    'maps each',
    'applicable acceptance criterion to tests and recorded evidence',
    'before the US/PLAN DoD can close',
    'maps acceptance criteria to tests/evidence'
)
Assert-ContractText -Case 'Should_PreserveUniqueCoverage_When_ConsolidatingTests' -Text ($planTemplate + $planUsage) -Markers @(
    'no unique acceptance, path, boundary, or failure-mode coverage',
    'unit tests that provide distinct feedback',
    'Preserve unrelated smoke tests'
)
Assert-ContractText -Case 'Should_RequireStateEvidenceAtConfiguredLevel_When_Consolidating' -Text ($planTemplate + $evidenceContract + $developEvidence) -Markers @(
    'update `STATE.md` and `EVD/`',
    'reads **Evidence level** from `STATE.md`',
    'so the STATE setting or',
    'repository default governs'
)
Assert-ContractText -Case 'Should_SupersedeEvidenceOnly_When_ReplacementIsLegitimate' -Text ($evidenceContract + $developEvidence) -Markers @(
    'equivalent',
    'stronger',
    'covers the same criterion',
    'retain the old artifact',
    'superseded path, replacement path, and reason'
)

Write-Host 'Assert-MixedTestStrategyContracts: all checks passed.'
exit 0
