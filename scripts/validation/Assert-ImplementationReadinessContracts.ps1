#Requires -Version 5.1
# Static behavior contracts for direct and orchestrated implementation DoR/DoD.
# These checks assert both the success criteria and the documented stop cases.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path (Join-Path $scriptsRoot '_lib') 'Get-ToolkitRepoRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

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

function ConvertTo-SemanticContractText {
    param([Parameter(Mandatory = $true)][string] $Text)

    $normalized = $Text.ToLowerInvariant()
    # Compare meaning-bearing words, not Markdown decoration, symbols, or layout.
    $normalized = [System.Text.RegularExpressions.Regex]::Replace($normalized, '[`*_#>|]', ' ')
    $normalized = [System.Text.RegularExpressions.Regex]::Replace($normalized, '[\p{P}\p{S}]', ' ')
    return [System.Text.RegularExpressions.Regex]::Replace($normalized, '\s+', ' ').Trim()
}

function Assert-ContractSemanticTokens {
    param(
        [Parameter(Mandatory = $true)][string] $Case,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string[]] $Tokens
    )

    $normalized = ConvertTo-SemanticContractText -Text $Text
    foreach ($token in $Tokens) {
        $escapedToken = [System.Text.RegularExpressions.Regex]::Escape($token.ToLowerInvariant())
        if ($normalized -notmatch "(?<![\p{L}\p{N}])$escapedToken(?![\p{L}\p{N}])") {
            throw "$Case failed; missing semantic token: $token"
        }
    }
    Write-Host "$Case`: PASS"
}

$planContract = Read-Contract 'core/skills/sdd-develop/references/plan-contract.md'
$developSkill = Read-Contract 'core/skills/sdd-develop/SKILL.md'
$planAcquisition = Read-Contract 'core/skills/sdd-develop/references/plan-acquisition.md'
$planUpdate = Read-Contract 'core/skills/sdd-develop/references/plan-update.md'
$executionDisplay = Read-Contract 'core/skills/sdd-develop/references/execution-display.md'
$directFlow = Read-Contract 'core/skills/sdd-develop/references/command.md'
$orchestratedSkill = Read-Contract 'core/skills/orchestrate-develop/SKILL.md'
$stepQueue = Read-Contract 'core/skills/orchestrate-develop/references/step-queue-spawn.md'
$receiptContract = Read-Contract 'core/skills/_shared/agents/RECEIPT.md'
$orchestratedFlow = Read-Contract 'core/skills/orchestrate-develop/references/preconditions.md'
$reviewContract = Read-Contract 'core/skills/code-review/references/contracts.md'

# Successful DoR requires the complete approved PRD/PLAN trace and an evidenced review.
Assert-ContractText -Case 'Should_PassDirectDoR_When_AllRequiredInputsArePresent' -Text $planContract -Markers @(
    'canonical PRD and PLAN are approved',
    'Every in-scope PRD REQ maps to a verifiable CA',
    'each step has acceptance text tied to its REQ/CA',
    'names its applicable validation',
    'scope/OOS source',
    'The PLAN records a review result and portable supporting'
)
Assert-ContractText -Case 'Should_ApplySharedDoR_BeforeDirectFirstStep' -Text $directFlow -Markers @(
    'On the first implementation step, evaluate the shared PLAN DoR',
    '`references/plan-contract.md`'
)

# O3 must apply the exact same contract before it spawns its first child.
Assert-ContractText -Case 'Should_PassOrchestratedDoR_When_SharedChecklistPasses' -Text $orchestratedFlow -Markers @(
    'Before the first child spawn, shared implementation DoR',
    'approved canonical PRD/PLAN',
    'complete REQ→CA→step and step-acceptance mapping',
    'declared validations',
    'recorded readiness review with portable evidence',
    'sdd-develop/references/plan-contract.md'
)

# Missing mapping/evidence blocks both routes; clarification READY is independent.
Assert-ContractText -Case 'Should_BlockBothFlows_When_DoRMappingOrEvidenceIsMissing' -Text $planContract -Markers @(
    'If any item is absent, contradictory, or unverifiable, stop before the first',
    'leave the step',
    'existing `BLOCKED` status',
    '`READY` only closes',
    'never substitutes for this DoR'
)
Assert-ContractText -Case 'Should_BlockOrchestratedFlow_When_DoRIsIncomplete' -Text $orchestratedFlow -Markers @(
    'A missing, contradictory, or unverifiable item blocks queue creation',
    'all spawns',
    'A green',
    'clarification `READY` does not pass this implementation gate'
)

# Direct execution treats the approved PLAN as the step unit without inferring
# context from siblings; optional task rows are used only by explicit adoption.
$directDevelopContract = $developSkill + "`n" + $planAcquisition + "`n" + $planUpdate + "`n" + $executionDisplay + "`n" + $planContract
Assert-ContractText -Case 'Should_AllowDirectStep_WhenChecklistIsAbsent' -Text $directDevelopContract -Markers @(
    'In `direct`, the approved PLAN step',
    'do not read, require, or create `REFINE/tasks.md`',
    'the canonical approved PLAN is sufficient',
    'absence of a checklist is not a blocker',
    'dependencies, and declared validations are sufficient execution inputs'
)
Assert-ContractText -Case 'Should_UseDirectChecklistOnly_WhenExplicitlyAdopted' -Text $directDevelopContract -Markers @(
    'explicitly adopts a checklist',
    'relationship to the PLAN is explicit and consistent',
    'direct` does not read or write a checklist unless the invocation explicitly adopted'
)

# O3 remains parent-scoped: explicit orchestrated context, checklist and
# preflight are required; an invalid receipt cannot claim persisted completion.
$orchestratedDevelopContract = $orchestratedSkill + "`n" + $stepQueue + "`n" + $planAcquisition
Assert-ContractText -Case 'Should_RequireO3ChecklistAndPreflight_WhenOrchestrated' -Text $orchestratedDevelopContract -Markers @(
    'Set `invocation_context=orchestrated` explicitly in every child handoff',
    'scoped checklist input required by the O3 contract',
    'require the O3 parent''s explicit scoped checklist input',
    'Preserve O3 preflight and claim gates',
    'absent or inconsistent required rows block/return to O2'
)
Assert-ContractText -Case 'Should_BlockO3BeforeEffects_WhenPreflightIsMissing' -Text $orchestratedSkill -Markers @(
    'Any nonzero result is `plan_stale` / blocked',
    'do not create or update a session, claim, or specialist',
    'Re-run after checkpoint/CONTINUITY reconciliation and immediately before every subsequent effect'
)
$receiptStatusContract = $receiptContract + "`n" + $planContract
$normalizedReceiptStatusContract = ConvertTo-SemanticContractText -Text $receiptStatusContract
Assert-ContractSemanticTokens -Case 'Should_KeepCanonicalO3ReceiptStatusesDistinctFromPlanLifecycle' -Text $receiptStatusContract -Tokens @(
    'done', 'blocked', 'failed', 'completed', 'receipt', 'plan', 'lifecycle', 'never'
)
if ($normalizedReceiptStatusContract -notmatch '\b(alias|aliases)\b' -or
    $normalizedReceiptStatusContract -notmatch '\bnormaliz\w*\b' -or
    $normalizedReceiptStatusContract -notmatch '\bunknown\b') {
    throw 'Should_KeepCanonicalO3ReceiptStatusesDistinctFromPlanLifecycle failed; alias normalization and unknown-status rejection must remain documented.'
}

# A step cannot close on acceptance alone or without its required evidence.
Assert-ContractText -Case 'Should_BlockCompletion_When_AcceptanceHasNoValidation' -Text $planContract -Markers @(
    'every declared applicable validation passed',
    'Acceptance without validation',
    'a planned check without a result'
)
Assert-ContractText -Case 'Should_BlockCompletion_When_RequiredEvidenceIsMissing' -Text $planContract -Markers @(
    'evidence are recorded',
    'missing required evidence reference is not completion',
    'A failure sets the step to `BLOCKED`',
    'Dependents stay `PENDING`'
)

# PLAN/US review must reject uncovered requirements and unresolved blocking findings.
Assert-ContractText -Case 'Should_BlockPlanClose_When_RequirementOrBlockingFindingRemains' -Text $reviewContract -Markers @(
    'uncovered mandatory REQ/CA',
    'unresolved blocking review finding',
    'report it as **Changes required**',
    'do not accept the completion claim'
)
Assert-ContractText -Case 'Should_ReconcilePlanDoD_BeforePlanClose' -Text $planContract -Markers @(
    'required REQ and CA to completed steps',
    'all required validations have passed',
    'no unresolved mandatory'
)

Write-Host 'Assert-ImplementationReadinessContracts: all checks passed.'
exit 0
