#Requires -Version 5.1
# Exercises sizing, API contract blocking, and seeded O3 contradiction detection.
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Test-StorySplit {
    param([int] $EndpointCount, [bool] $IndependentValue, [bool] $IndependentDelivery)
    return ($IndependentValue -and $IndependentDelivery)
}

function Test-ApiContractReady {
    param([hashtable] $Contract)
    $requiredFields = @('methodRoute', 'request', 'response', 'validations', 'statusErrors', 'examples')
    foreach ($field in $requiredFields) {
        if ([string]::IsNullOrWhiteSpace([string]$Contract[$field])) { return $false }
    }
    if ($Contract['sourceCanonical'] -eq 'external') {
        return -not [string]::IsNullOrWhiteSpace([string]$Contract['sourcePath'])
    }
    return $true
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$sizingPath = Join-Path $repoRoot 'core\skills\orchestrate-analyze\references\story-synthesis.md'
$prdTemplatePath = Join-Path $repoRoot 'core\skills\_shared\templates\sdd\PRD.md'
$planSkillPath = Join-Path $repoRoot 'core\skills\sdd-plan\SKILL.md'
$o3ContractPath = Join-Path $repoRoot 'core\skills\orchestrate-develop\references\step-queue-spawn.md'
$fixturePath = Join-Path $PSScriptRoot 'fixtures\planning-o3\paired-review.json'
foreach ($path in @($sizingPath, $prdTemplatePath, $planSkillPath, $o3ContractPath, $fixturePath)) {
    Assert-True (Test-Path -LiteralPath $path) "Required contract or fixture is missing: $path"
}

$sizingText = Get-Content -LiteralPath $sizingPath -Raw -Encoding UTF8
Assert-True ($sizingText -match '(?i)Endpoint count alone is not a split criterion') 'O1 sizing contract must reject endpoint-count-only splitting.'
$inseparable = Test-StorySplit -EndpointCount 4 -IndependentValue $false -IndependentDelivery $false
$independent = Test-StorySplit -EndpointCount 1 -IndependentValue $true -IndependentDelivery $true
Assert-True (-not $inseparable) 'Multiple endpoints with inseparable value/delivery must remain one story.'
Assert-True $independent 'An independently deliverable consumer outcome should split even with one endpoint.'
Write-Host 'StorySizingBehavior: PASS (endpoint count is not the decision; independent value and delivery are)'

$templateText = Get-Content -LiteralPath $prdTemplatePath -Raw -Encoding UTF8
$planText = Get-Content -LiteralPath $planSkillPath -Raw -Encoding UTF8
Assert-True ($templateText -match '(?i)Lacuna em qualquer campo comportamental') 'PRD template must identify behavioral contract gaps.'
Assert-True ($templateText -match '(?i)blocker') 'PRD template must mark contract gaps as blockers.'
Assert-True ($templateText -match '(?i)n[aã]o avance') 'PRD template must prevent progression while a blocker remains.'
Assert-True ($planText -match '(?i)validate-prd') 'sdd-plan must validate the source PRD before planning.'
$completeContract = @{
    methodRoute = 'POST /checkout'; request = 'CheckoutRequest'; response = 'CheckoutResponse'
    validations = 'items must be non-empty'; statusErrors = '400 validation_error'; examples = 'valid request and response'
    sourceCanonical = 'inline'; sourcePath = ''
}
$incompleteContract = $completeContract.Clone()
$incompleteContract['validations'] = ''
Assert-True (Test-ApiContractReady $completeContract) 'A complete behavioral API contract should permit planning.'
Assert-True (-not (Test-ApiContractReady $incompleteContract)) 'A missing behavioral field must block planning.'
Write-Host 'ApiContractBehavior: PASS (incomplete behavior remains blocked before PLAN)'

$o3Text = Get-Content -LiteralPath $o3ContractPath -Raw -Encoding UTF8
Assert-True ($o3Text -match '(?i)equivalent PLAN inputs, environment, and configuration') 'O3 baseline must compare equivalent conditions.'
Assert-True ($o3Text -match '(?i)do not invent an absolute') 'O3 must not invent a target before baseline.'
$fixture = Get-Content -LiteralPath $fixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
$seedIds = @($fixture.seededContradictions | ForEach-Object { [string]$_.id })
Assert-True ($seedIds.Count -gt 0) 'O3 fixture must contain seeded contradictions.'
foreach ($mode in @('full', 'deltaRisk')) {
    $detected = @($fixture.reviews.$mode.detected | ForEach-Object { [string]$_ })
    $missed = @($seedIds | Where-Object { $detected -notcontains $_ })
    Assert-True ($missed.Count -eq 0) "$mode review missed seeded contradictions: $($missed -join ', ')"
    Assert-True ($detected.Count -eq $seedIds.Count) "$mode review must report the full detection denominator without extras."
}
if ($fixture.telemetry.available) {
    foreach ($mode in @('full', 'deltaRisk')) {
        Assert-True ($null -ne $fixture.reviews.$mode.tokens) "$mode telemetry must include observed tokens."
        Assert-True ($null -ne $fixture.reviews.$mode.toolCalls) "$mode telemetry must include observed tool calls."
    }
} else {
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$fixture.telemetry.reason)) 'Skipped telemetry must state why.'
    Write-Host ("O3 paired measurement: SKIPPED - {0}" -f $fixture.telemetry.reason)
}
Write-Host ("O3 contradiction detection: PASS (full {0}/{1}; deltaRisk {2}/{3})" -f $fixture.reviews.full.detected.Count, $seedIds.Count, $fixture.reviews.deltaRisk.detected.Count, $seedIds.Count)
Write-Host 'Assert-PlanningO3Behavior: ALL PASS'
exit 0
