#Requires -Version 5.1
# Exercises sizing and API contract blocking. O3 strategy execution is reported
# as SKIPPED when this harness cannot invoke an observable host/model runner.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\Get-ToolkitRelativePath.ps1')
. (Join-Path $PSScriptRoot '..\_lib\Format-O3PlanProgressTable.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Throws {
    param([scriptblock] $Action, [string] $Message)
    try { & $Action } catch { return }
    throw $Message
}

$sixStepPlan = @(
    [PSCustomObject]@{ Id='S1'; Name='Inspect scope' },
    [PSCustomObject]@{ Id='S2'; Name='Implement core behavior' },
    [PSCustomObject]@{ Id='S3'; Name='Add service integration' },
    [PSCustomObject]@{ Id='S4'; Name='Add persistence behavior' },
    [PSCustomObject]@{ Id='S5'; Name='Validate access paths' },
    [PSCustomObject]@{ Id='S6'; Name='Reconcile closeout' }
)
$initialSixStepRows = @(
    [PSCustomObject]@{ Id='S1'; Status='COMPLETED'; Dependencies='none'; Evidence='checkpoint S1' },
    [PSCustomObject]@{ Id='S2'; Status='PENDING'; Dependencies='S1'; Evidence='not started' },
    [PSCustomObject]@{ Id='S3'; Status='PENDING'; Dependencies='S2'; Evidence='not started' },
    [PSCustomObject]@{ Id='S4'; Status='PENDING'; Dependencies='S3'; Evidence='not started' },
    [PSCustomObject]@{ Id='S5'; Status='PENDING'; Dependencies='S4'; Evidence='not started' },
    [PSCustomObject]@{ Id='S6'; Status='PENDING'; Dependencies='S5'; Evidence='not started' }
)
$initialTable = Format-O3PlanProgressTable -PlanSteps $sixStepPlan -StepRows $initialSixStepRows
foreach ($step in $sixStepPlan) {
    $rowMatches = [regex]::Matches($initialTable, ('(?m)^\|\s*{0}\s*\|' -f $step.Id))
    Assert-True ($rowMatches.Count -eq 1) "Initial six-step summary must render $($step.Id) exactly once."
    Assert-True ($initialTable -match ('(?m)^\|\s*{0}\s*\|[^\r\n]*\|\s*{1}\s*\|' -f $step.Id, $(if ($step.Id -eq 'S1') { 'COMPLETED' } else { 'PENDING' }))) "Initial six-step summary has the wrong status for $($step.Id)."
}
$mixedRows = @(
    [PSCustomObject]@{ Id='S1'; Status='COMPLETED'; Dependencies='none'; Evidence='checkpoint S1' },
    [PSCustomObject]@{ Id='S2'; Status='IN_PROGRESS'; Dependencies='S1'; Evidence='active claim S2' },
    [PSCustomObject]@{ Id='S3'; Status='PENDING'; Dependencies='S2'; Evidence='awaiting dependency' },
    [PSCustomObject]@{ Id='S4'; Status='BLOCKED'; Dependencies='S3'; Evidence='validated blocker' },
    [PSCustomObject]@{ Id='S5'; Status='PENDING'; Dependencies='S4'; Evidence='not started' },
    [PSCustomObject]@{ Id='S6'; Status='PENDING'; Dependencies='S5'; Evidence='not started' }
)
$mixedTable = Format-O3PlanProgressTable -PlanSteps $sixStepPlan -StepRows $mixedRows
foreach ($step in $sixStepPlan) {
    $expectedStatus = [string]($mixedRows | Where-Object Id -eq $step.Id | Select-Object -First 1).Status
    $rowMatches = [regex]::Matches($mixedTable, ('(?m)^\|\s*{0}\s*\|[^\r\n]*\|\s*{1}\s*\|' -f $step.Id, $expectedStatus))
    Assert-True ($rowMatches.Count -eq 1) "Mixed-state summary must render $($step.Id) exactly once with $expectedStatus."
}
Assert-Throws { Format-O3PlanProgressTable -PlanSteps $sixStepPlan -StepRows @($mixedRows | Where-Object Id -ne 'S6') } 'Formatter must reject a missing step-state row.'
Assert-Throws { Format-O3PlanProgressTable -PlanSteps $sixStepPlan -StepRows (@($mixedRows) + @($mixedRows[0])) } 'Formatter must reject a duplicate step-state row.'
Assert-Throws { Format-O3PlanProgressTable -PlanSteps $sixStepPlan -StepRows (@($mixedRows) + @([PSCustomObject]@{ Id='S7'; Status='PENDING'; Dependencies='S6'; Evidence='extra' })) } 'Formatter must reject a row outside the canonical PLAN.'
Write-Host 'O3ProgressTableBehavior: PASS (six-step initial and mixed summaries; exact ID set enforced)'

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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pathSeparator = [string][IO.Path]::DirectorySeparatorChar
$relativeChild = Get-ToolkitRelativePath -BasePath $repoRoot -TargetPath (Join-Path $repoRoot ('alpha{0}beta' -f $pathSeparator))
Assert-True ($relativeChild -eq ('alpha{0}beta' -f $pathSeparator)) 'Relative-path helper must resolve a child path on PowerShell 5.1.'
$relativeParent = Get-ToolkitRelativePath -BasePath (Join-Path $repoRoot ('alpha{0}beta' -f $pathSeparator)) -TargetPath $repoRoot
Assert-True ($relativeParent -eq ('..{0}..' -f $pathSeparator)) 'Relative-path helper must preserve parent traversal for containment checks.'
$samePath = Get-ToolkitRelativePath -BasePath $repoRoot -TargetPath $repoRoot
Assert-True ($samePath -eq '.') 'Relative-path helper must return dot for identical paths.'
Write-Host 'ToolkitRelativePath: PASS (child, parent traversal, identical path)'
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
$canonicalLines = @(
    [string]$fixture.input.plan
    [string]$fixture.input.environment
    [string]$fixture.input.configuration
)
$canonicalLines += @($fixture.seededContradictions | ForEach-Object { '{0}|{1}|{2}' -f $_.id, $_.claimA, $_.claimB })
$canonicalInput = $canonicalLines -join "`n"
$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $actualHash = ([System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($canonicalInput)))).Replace('-', '').ToLowerInvariant()
} finally {
    $sha.Dispose()
}
Assert-True ($fixture.input.sha256 -eq $actualHash) 'O3 fixture input hash must match its plan, conditions, and seeded contradictions.'
Assert-True ($fixture.reviews.full.inputSha256 -eq $fixture.reviews.deltaRisk.inputSha256) 'O3 strategies must use identical hashed inputs.'
Assert-True ($fixture.reviews.full.inputSha256 -eq $fixture.input.sha256) 'Review input hashes must match the fixture input hash.'
foreach ($mode in @('full', 'deltaRisk')) {
    Assert-True ($fixture.reviews.$mode.status -eq 'SKIPPED') "$mode detection must not be inferred from prerecorded results."
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$fixture.reviews.$mode.reason)) "$mode skipped detection must state the missing observable runner."
    Assert-True ($null -eq $fixture.reviews.$mode.detected) "$mode fixture must not contain prerecorded detection results."
    Write-Host ("O3 {0} strategy execution: SKIPPED - {1}" -f $mode, $fixture.reviews.$mode.reason)
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
Write-Host ("O3 paired input identity: PASS ({0}; {1} seeded contradictions; strategy outcomes SKIPPED)" -f $fixture.input.sha256, $seedIds.Count)

# O3's artifact preflight is an existing validation entry point. Exercise its
# allow path and two fail-closed regressions with disposable canonical paths.
$preflightPath = Join-Path $PSScriptRoot 'Invoke-O3ArtifactPreflight.ps1'
$artifactFixture = Join-Path $PSScriptRoot 'fixtures\o3-artifact-preflight'
Assert-True (Test-Path -LiteralPath $preflightPath) 'O3 artifact preflight script must exist.'
$tempFeature = Join-Path $repoRoot ('features\000-o3-preflight-{0}' -f [Guid]::NewGuid().ToString('N'))
$tempFeatureTs = Join-Path $repoRoot ('features\000-o3-preflight-ts-{0}' -f [Guid]::NewGuid().ToString('N'))
$storyRoot = Join-Path $tempFeature 'US01'
$planDir = Join-Path $storyRoot 'PLAN'
$prdDir = Join-Path $storyRoot 'PRD'
$refineDir = Join-Path $storyRoot 'REFINE'
$tempSdd = Join-Path ([IO.Path]::GetTempPath()) ('adt-o3-preflight-sdd-{0}' -f [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $planDir,$prdDir,$refineDir,$tempSdd -Force | Out-Null
    Copy-Item (Join-Path $artifactFixture 'FEATURE.md') (Join-Path $tempFeature 'FEATURE.md')
    Copy-Item (Join-Path $artifactFixture 'CONTINUITY.md') (Join-Path $tempFeature 'CONTINUITY.md')
    $tempFeatureRelative = (Get-ToolkitRelativePath -BasePath $repoRoot -TargetPath $tempFeature).Replace('\','/')
    $continuityPath = Join-Path $tempFeature 'CONTINUITY.md'
    $continuityFixtureText = Get-Content -LiteralPath $continuityPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($continuityPath, $continuityFixtureText.Replace('features/000-o3-preflight-fixture',$tempFeatureRelative), (New-Object Text.UTF8Encoding $false))
    $storyPath = Join-Path $storyRoot 'STORY.md'
    $storyFixtureText = Get-Content -LiteralPath (Join-Path $artifactFixture 'STORY.md') -Raw -Encoding UTF8
    [IO.File]::WriteAllText($storyPath, $storyFixtureText.Replace('features/000-o3-preflight-fixture',$tempFeatureRelative), (New-Object Text.UTF8Encoding $false))
    $prdPath = Join-Path $prdDir '000_o3_preflight.md'
    $prdFixtureText = Get-Content -LiteralPath (Join-Path $artifactFixture 'PRD.md') -Raw -Encoding UTF8
    [IO.File]::WriteAllText($prdPath,$prdFixtureText.Replace('features/000-o3-preflight-fixture',$tempFeatureRelative),(New-Object Text.UTF8Encoding $false))
    Copy-Item (Join-Path $artifactFixture 'tasks.md') (Join-Path $refineDir 'tasks.md')
    $planPath = Join-Path $planDir 'PLAN_000_o3_preflight.md'
    Copy-Item (Join-Path $artifactFixture 'PLAN.md') $planPath
    $repoManifest = @{ schema_version = 2; repositories = @{ $repoRoot = @{ classic = @{ storage_mode = 'repository'; path = $repoRoot; features_versioned = $false } } } } | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText((Join-Path $tempSdd 'manifest.json'),$repoManifest,(New-Object Text.UTF8Encoding $false))
    $allow = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Host $allow }
    Assert-True ($LASTEXITCODE -eq 0 -and $allow -match 'preflight: ALLOW' -and $allow -match 'features_versioned=false') 'Consistent approved artifacts must pass and accurately report local-only storage.'
    Write-Host 'O3ArtifactPreflight: PASS (consistent artifact set and local-only report)'
    $renderedAllow = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd -EmitStepTable 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $renderedAllow -match '## O3 progress table') 'The preflight table option must emit a deterministic display projection.'
    foreach ($stepId in @('S1','S2')) {
        $renderedRows = [regex]::Matches($renderedAllow, ('(?m)^\|\s*{0}\s*\|' -f $stepId))
        Assert-True ($renderedRows.Count -eq 1) "Preflight projection must render $stepId exactly once."
        Assert-True ($renderedAllow -match ('(?m)^\|\s*{0}\s*\|[^\r\n]*\|\s*PENDING\s*\|' -f $stepId)) "Preflight projection must preserve $stepId's canonical PLAN status."
    }
    Write-Host 'O3ArtifactPreflight: PASS (complete table emitted from canonical PLAN rows)'
    $stepStatusOverridesPath = Join-Path $tempSdd 'o3-step-state-projection.json'
    $stepStatusOverrides = @(
        [PSCustomObject]@{ Id='S1'; Status='PENDING'; Evidence='PLAN row remains pending' },
        [PSCustomObject]@{ Id='S2'; Status='IN_PROGRESS'; Evidence='validated active claim and session' }
    ) | ConvertTo-Json -Depth 4
    [IO.File]::WriteAllText($stepStatusOverridesPath,$stepStatusOverrides,(New-Object Text.UTF8Encoding $false))
    $overlaidAllow = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd -EmitStepTable -StepStateOverridesPath $stepStatusOverridesPath 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $overlaidAllow -match 'preflight: ALLOW') 'A validated complete operational status projection must remain a display-only overlay.'
    Assert-True ($overlaidAllow -match '(?m)^\|\s*S2\s*\|[^\r\n]*\|\s*IN_PROGRESS\s*\|[^\r\n]*validated active claim and session') 'The complete O3 projection must show reconciled operational status and evidence.'
    Assert-True ((Get-Content -LiteralPath $planPath -Raw -Encoding UTF8) -match '\| S2 \| Revalidate the saved O3 artifacts \| S1 \| Medium \| `PENDING`') 'Operational display overrides must not write to or replace durable PLAN status.'
    [IO.File]::WriteAllText($stepStatusOverridesPath,'[]',(New-Object Text.UTF8Encoding $false))
    $missingOverride = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd -EmitStepTable -StepStateOverridesPath $stepStatusOverridesPath 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $missingOverride -match 'Expected exactly one status projection') 'An empty override file must not silently fall back to PLAN-only display.'
    Write-Host 'O3ArtifactPreflight: PASS (validated status overlay is display-only)'

    # Semantic parser regression: presentation changes and story cross-links
    # must not alter step identity, dependency comparison, or navigation.
    $planText = Get-Content -LiteralPath $planPath -Raw -Encoding UTF8
    $storyText = Get-Content -LiteralPath $storyPath -Raw -Encoding UTF8
    $prdText = Get-Content -LiteralPath (Join-Path $prdDir '000_o3_preflight.md') -Raw -Encoding UTF8
    $taskText = Get-Content -LiteralPath (Join-Path $refineDir 'tasks.md') -Raw -Encoding UTF8
    $semanticPlan = $planText.Replace('| **Progresso** | 0/2 |','| 📊 Progresso | 0 / 2 |').Replace('## Progresso da implementação','## 📈 PROGRESSO   da implementação').Replace('### STEP 1 — S1:','### ✅ **passo 1** — **S1**:').Replace('### STEP 2 — S2:','### 🔧 step 2 - S2:').Replace('| S2 | Revalidate the saved O3 artifacts | S1 |','| S2 | Revalidate the saved O3 artifacts | S1, US01 |')
    $semanticTasks = $taskText.Replace('### STEP 1 — S1:','### ✅ **passo 1** — **S1**:').Replace('### STEP 2 — S2:','### 🔧 step 2 - S2:').Replace('- **Depends on:** S1','- Depends on: S1, US02')
    $semanticStory = $storyText.Replace('PLAN: `./PLAN/PLAN_000_o3_preflight.md`','Related PLAN: [Approved plan](./PLAN/PLAN_000_o3_preflight.md#step-1)')
    $semanticPrd = $prdText.Replace('PLAN: `features/','🗂 **Plan**: [Canonical plan](features/')
    $semanticPrd = $semanticPrd.Replace('/PLAN/PLAN_000_o3_preflight.md`','/PLAN/PLAN_000_o3_preflight.md "PLAN" )')
    [IO.File]::WriteAllText($planPath,$semanticPlan,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($storyPath,$semanticStory,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $prdDir '000_o3_preflight.md'),$semanticPrd,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $refineDir 'tasks.md'),$semanticTasks,(New-Object Text.UTF8Encoding $false))
    $semanticResult = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Host $semanticResult }
    Assert-True ($LASTEXITCODE -eq 0 -and $semanticResult -match 'preflight: ALLOW') 'Semantic labels, Markdown decoration, STEP/PASSO headings, anchor links, and US/TS references must preserve the valid preflight result.'
    Write-Host 'O3ArtifactPreflight: PASS (semantic labels, heading variants, portable links, story references)'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($storyPath,$storyText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $prdDir '000_o3_preflight.md'),$prdText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $refineDir 'tasks.md'),$taskText,(New-Object Text.UTF8Encoding $false))

    $escapingStoryPath = 'PLAN: [Escaping reference](../../{0}/US01/PLAN/PLAN_000_o3_preflight.md)' -f $tempFeatureRelative
    $escapingStory = $storyText.Replace('PLAN: `./PLAN/PLAN_000_o3_preflight.md`',$escapingStoryPath)
    [IO.File]::WriteAllText($storyPath,$escapingStory,(New-Object Text.UTF8Encoding $false))
    $escapingPlanResult = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $escapingPlanResult -match 'story_prd_plan_navigation_mismatch') 'A relative traversal link that only looks canonical after stripping dot/slash characters must remain blocked.'
    [IO.File]::WriteAllText($storyPath,$storyText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (traversal-like PLAN reference rejected)'

    $missingStoryPlan = $storyText -replace '(?m)^PLAN:.*(?:\r?\n)?',''
    [IO.File]::WriteAllText($storyPath,$missingStoryPlan,(New-Object Text.UTF8Encoding $false))
    $missingPlanResult = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $missingPlanResult -match 'story_prd_plan_navigation_mismatch') 'A genuinely missing canonical STORY PLAN reference must remain blocked.'
    [IO.File]::WriteAllText($storyPath,$storyText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (genuinely missing canonical PLAN link remains blocked)'

    # The canonical story contract supports both user and technical stories.
    # Build a separate TS01 fixture so the existing US01 cases remain unchanged.
    $tsStoryRoot = Join-Path $tempFeatureTs 'TS01'
    $tsPlanDir = Join-Path $tsStoryRoot 'PLAN'
    $tsPrdDir = Join-Path $tsStoryRoot 'PRD'
    $tsRefineDir = Join-Path $tsStoryRoot 'REFINE'
    New-Item -ItemType Directory -Path $tempFeatureTs,$tsPlanDir,$tsPrdDir,$tsRefineDir -Force | Out-Null
    $tsFeatureRelative = (Get-ToolkitRelativePath -BasePath $repoRoot -TargetPath $tempFeatureTs).Replace('\','/')
    $tsFeatureText = Get-Content -LiteralPath (Join-Path $artifactFixture 'FEATURE.md') -Raw -Encoding UTF8
    $tsFeatureText = $tsFeatureText.Replace('features/000-o3-preflight-fixture',$tsFeatureRelative).Replace('/US01/STORY.md','/TS01/STORY.md')
    [IO.File]::WriteAllText((Join-Path $tempFeatureTs 'FEATURE.md'),$tsFeatureText,(New-Object Text.UTF8Encoding $false))
    $tsContinuityText = Get-Content -LiteralPath (Join-Path $artifactFixture 'CONTINUITY.md') -Raw -Encoding UTF8
    $tsContinuityText = $tsContinuityText.Replace('features/000-o3-preflight-fixture',$tsFeatureRelative).Replace('/US01/PLAN/','/TS01/PLAN/')
    [IO.File]::WriteAllText((Join-Path $tempFeatureTs 'CONTINUITY.md'),$tsContinuityText,(New-Object Text.UTF8Encoding $false))
    $tsStoryText = Get-Content -LiteralPath (Join-Path $artifactFixture 'STORY.md') -Raw -Encoding UTF8
    $tsStoryText = $tsStoryText.Replace('US01','TS01').Replace('features/000-o3-preflight-fixture',$tsFeatureRelative)
    [IO.File]::WriteAllText((Join-Path $tsStoryRoot 'STORY.md'),$tsStoryText,(New-Object Text.UTF8Encoding $false))
    $tsPrdText = Get-Content -LiteralPath (Join-Path $artifactFixture 'PRD.md') -Raw -Encoding UTF8
    $tsPrdText = $tsPrdText.Replace('features/000-o3-preflight-fixture',$tsFeatureRelative).Replace('/US01/PLAN/','/TS01/PLAN/')
    [IO.File]::WriteAllText((Join-Path $tsPrdDir '000_o3_preflight.md'),$tsPrdText,(New-Object Text.UTF8Encoding $false))
    Copy-Item (Join-Path $artifactFixture 'tasks.md') (Join-Path $tsRefineDir 'tasks.md')
    $tsPlanPath = Join-Path $tsPlanDir 'PLAN_000_o3_preflight.md'
    Copy-Item (Join-Path $artifactFixture 'PLAN.md') $tsPlanPath
    $tsAllow = & $preflightPath -FeatureRoot $tempFeatureTs -PlanPath $tsPlanPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Host $tsAllow }
    Assert-True ($LASTEXITCODE -eq 0 -and $tsAllow -match 'preflight: ALLOW') 'A canonical TS01 PLAN with matching story/feature artifacts must pass the O3 preflight.'
    Write-Host 'O3ArtifactPreflight: PASS (canonical TS01 story accepted)'

    foreach ($malformedStoryId in @('TS1','US001','XX01')) {
        $malformedPlanDir = Join-Path (Join-Path $tempFeatureTs $malformedStoryId) 'PLAN'
        New-Item -ItemType Directory -Path $malformedPlanDir -Force | Out-Null
        $malformedPlanPath = Join-Path $malformedPlanDir 'PLAN_000_o3_preflight.md'
        Copy-Item (Join-Path $artifactFixture 'PLAN.md') $malformedPlanPath
        $malformedStoryPreflight = & $preflightPath -FeatureRoot $tempFeatureTs -PlanPath $malformedPlanPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -eq 2 -and $malformedStoryPreflight -match 'code=non_canonical_feature_or_plan_path') "Malformed story id '$malformedStoryId' must remain rejected by canonical path validation."
    }
    Write-Host 'O3ArtifactPreflight: PASS (malformed story ids rejected)'

    $planText = Get-Content -LiteralPath $planPath -Raw -Encoding UTF8
    $plainStatusPlan = $planText.Replace('| **Status** | approved |','| Status | approved |')
    [IO.File]::WriteAllText($planPath,$plainStatusPlan,(New-Object Text.UTF8Encoding $false))
    $plainStatusPreflight = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $plainStatusPreflight -match 'preflight: ALLOW') 'Plain PLAN Status label must pass the O3 preflight.'
    $sessionGate = Join-Path $repoRoot 'scripts\session\Invoke-DevelopSessionGate.ps1'
    $claimGate = Join-Path $repoRoot 'scripts\ledger\Invoke-PlanLedgerClaim.ps1'
    $powerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
    $savedErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $plainStatusSession = & $powerShellExe -NoProfile -File $sessionGate -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd -Step 1 -Action ensure 2>&1 | Out-String
    $plainStatusSessionExit = $LASTEXITCODE
    $plainStatusClaim = & $powerShellExe -NoProfile -File $claimGate -Action claim -PlanPath $planPath -Step 1 -Holder 'plain-status-test' -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    $plainStatusClaimExit = $LASTEXITCODE
    $ErrorActionPreference = $savedErrorPreference
    Assert-True ($plainStatusSessionExit -eq 0 -and $plainStatusSession -notmatch 'plan_not_explicitly_approved') 'Session gate must accept the same plain approved PLAN Status label.'
    Assert-True ($plainStatusClaimExit -eq 0 -and $plainStatusClaim -notmatch 'plan_not_explicitly_approved') 'PLAN ledger claim must accept the same plain approved PLAN Status label.'
    Write-Host 'O3ArtifactPreflight: PASS (plain Status label accepted consistently by preflight, session, and claim gates)'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))

    $continuityBeforeEnglish = Get-Content -LiteralPath (Join-Path $tempFeature 'CONTINUITY.md') -Raw -Encoding UTF8
    $englishPlan = $planText.Replace('**Progresso**','**Progress**').Replace('## Progresso da implementação','## Implementation progress')
    [IO.File]::WriteAllText($planPath,$englishPlan,(New-Object Text.UTF8Encoding $false))
    $continuityEnglish = $continuityBeforeEnglish
    $continuityEnglish = $continuityEnglish.Replace('## Estado atual do O3','## Current O3 state').Replace('Progresso:','Progress:').Replace('Concluídos:','Completed:').Replace('Próximo:','Next:')
    [IO.File]::WriteAllText((Join-Path $tempFeature 'CONTINUITY.md'),$continuityEnglish,(New-Object Text.UTF8Encoding $false))
    $englishArtifacts = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $englishArtifacts -match 'preflight: ALLOW') 'Equivalent English PLAN progress and CONTINUITY fields must pass the O3 preflight.'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $tempFeature 'CONTINUITY.md'),$continuityBeforeEnglish,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (English and Portuguese progress contracts accepted equivalently)'

    $featurePath = Join-Path $tempFeature 'FEATURE.md'
    $featureText = Get-Content -LiteralPath $featurePath -Raw -Encoding UTF8
    $prdPath = Join-Path $prdDir '000_o3_preflight.md'
    $prdFixtureText = Get-Content -LiteralPath $prdPath -Raw -Encoding UTF8
    $refinePath = Join-Path $refineDir 'tasks.md'
    $refineOriginal = Get-Content -LiteralPath $refinePath -Raw -Encoding UTF8
    $continuityFixtureText = Get-Content -LiteralPath (Join-Path $tempFeature 'CONTINUITY.md') -Raw -Encoding UTF8
    $canonicalFeatureId = Split-Path $tempFeature -Leaf
    $mismatchedFeatureId = $canonicalFeatureId -replace '^000-','000-other-'
    [IO.File]::WriteAllText($featurePath,$featureText.Replace('| **Id** | `000` |',('| **Id** | `{0}` |' -f $canonicalFeatureId)),(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($prdPath,$prdFixtureText.Replace('Feature `000`',('Feature `{0}`' -f $canonicalFeatureId)),(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($refinePath,$refineOriginal.Replace('Feature `000`',('Feature `{0}`' -f $canonicalFeatureId)),(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $tempFeature 'CONTINUITY.md'),$continuityFixtureText.Replace('Feature `000`',('Feature `{0}`' -f $canonicalFeatureId)),(New-Object Text.UTF8Encoding $false))
    $canonicalFeatureId = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Host $canonicalFeatureId }
    Assert-True ($LASTEXITCODE -eq 0 -and $canonicalFeatureId -match 'preflight: ALLOW') 'Canonical NNN-slug FEATURE Id matching the feature folder must pass.'
    [IO.File]::WriteAllText($featurePath,$featureText.Replace('| **Id** | `000` |',('| **Id** | `{0}` |' -f $mismatchedFeatureId)),(New-Object Text.UTF8Encoding $false))
    $wrongFeatureSlug = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $wrongFeatureSlug -match 'feature_identity_unverifiable') 'Canonical FEATURE Id with a slug differing from the folder must remain blocked.'
    [IO.File]::WriteAllText($featurePath,$featureText.Replace('| **Id** | `000` |','| **Id** | `001` |'),(New-Object Text.UTF8Encoding $false))
    $wrongLegacyFeatureId = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $wrongLegacyFeatureId -match 'feature_identity_unverifiable') 'Legacy numeric FEATURE Id differing from the folder prefix must remain blocked.'
    [IO.File]::WriteAllText($featurePath,$featureText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($prdPath,$prdFixtureText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($refinePath,$refineOriginal,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $tempFeature 'CONTINUITY.md'),$continuityFixtureText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (legacy numeric and canonical NNN-slug FEATURE identities; mismatched identities blocked)'

    [IO.File]::WriteAllText($planPath,$planText.Replace('### STEP ','### PASSO '),(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($refinePath,$refineOriginal.Replace('### STEP ','### PASSO '),(New-Object Text.UTF8Encoding $false))
    $portugueseHeadings = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $portugueseHeadings -match 'preflight: ALLOW') 'Portuguese PASSO headings in PLAN and REFINE must pass without bypassing dependency/state checks.'
    $malformedHeadingPlan = $planText.Replace('### STEP 1 — S1: Reconcile the saved O3 artifacts','### STEP 1 — Reconcile the saved O3 artifacts').Replace('### STEP 2 — S2: Revalidate the saved O3 artifacts','### PASSO 2 — S2')
    [IO.File]::WriteAllText($planPath,$malformedHeadingPlan,(New-Object Text.UTF8Encoding $false))
    $malformedHeadingBlock = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    $malformedHeadingExit = $LASTEXITCODE
    Assert-True ($malformedHeadingPlan -match '(?m)^### STEP 1 — Reconcile' -and $malformedHeadingPlan -match '(?m)^### PASSO 2 — S2\s*$') 'Negative-control PLAN must include malformed English and Portuguese step headings.'
    Assert-True ($malformedHeadingExit -eq 2 -and $malformedHeadingBlock -match 'plan_steps_missing') 'PLAN with malformed STEP and PASSO headings must block with plan_steps_missing.'
    Write-Host 'O3ArtifactPreflight: PASS (malformed STEP and PASSO headings blocked as plan_steps_missing)'
    Assert-True ($malformedHeadingBlock -notmatch 'plan_progress_total_mismatch') 'Missing parsed step headings must not create a dependent progress-total diagnostic.'
    Write-Host 'O3ArtifactPreflight: PASS (dependent progress-total cascade excluded)'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($refinePath,$refineOriginal,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (STEP and PASSO headings accepted in PLAN and REFINE)'

    # Localized aliases are deliberately narrow. Keep canonical step states in
    # English and make unsupported state values fail with an actionable issue.
    $unsupportedStatePlan = $planText.Replace('| `PENDING` |','| `CONCLUÍDO AGORA` |')
    [IO.File]::WriteAllText($planPath,$unsupportedStatePlan,(New-Object Text.UTF8Encoding $false))
    $unsupportedState = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $unsupportedState -match 'plan_step_state_invalid:S1' -and $unsupportedState -match 'field=.*Status' -and $unsupportedState -match 'observed=.*CONCLUÍDO AGORA' -and $unsupportedState -match 'expected=.*COMPLETED.*PENDING.*IN_PROGRESS.*BLOCKED.*SKIPPED' -and $unsupportedState -match 'next=') 'Unsupported near-match localized step-state values must be rejected with field, observed value, expected canonical states, and next action.'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (unsupported localized step state rejected with actionable canonical-state guidance)'

    $localizedStatePlan = $planText.Replace('| `PENDING` |','| `PENDENTE` |')
    [IO.File]::WriteAllText($planPath,$localizedStatePlan,(New-Object Text.UTF8Encoding $false))
    $localizedState = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $localizedState -match 'preflight: NORMALIZED' -and $localizedState -match 'input=''PENDENTE'' canonical=PENDING' -and $localizedState -match 'preflight: ALLOW') 'An explicit Portuguese step status must normalize to the same canonical status as English.'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (Portuguese step status normalizes to canonical PENDING)'

    $failedStatePlan = $planText.Replace('| S1 | Reconcile the saved O3 artifacts | none | Medium | `PENDING` | — |','| S1 | Reconcile the saved O3 artifacts | none | Medium | `FAILED` | failure |')
    [IO.File]::WriteAllText($planPath,$failedStatePlan,(New-Object Text.UTF8Encoding $false))
    $failedState = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $failedState -match 'plan_step_state_invalid:S1') 'FAILED must be rejected because it is not a canonical PLAN lifecycle token.'
    $skippedPlan = $planText.Replace('| S1 | Reconcile the saved O3 artifacts | none | Medium | `PENDING` | — |','| S1 | Reconcile the saved O3 artifacts | none | Medium | `SKIPPED` | approved omission reason |')
    [IO.File]::WriteAllText($planPath,$skippedPlan,(New-Object Text.UTF8Encoding $false))
    $skippedContinuity = Get-Content -LiteralPath (Join-Path $tempFeature 'CONTINUITY.md') -Raw -Encoding UTF8
    [IO.File]::WriteAllText((Join-Path $tempFeature 'CONTINUITY.md'),$skippedContinuity.Replace('Próximo: S1 — Reconcile the saved O3 artifacts','Próximo: none'),(New-Object Text.UTF8Encoding $false))
    $skippedStep = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $skippedStep -match 'preflight: ALLOW' -and $skippedStep -match 'completed=0') 'SKIPPED must be preserved as a distinct non-completed state and must not unlock its dependent step.'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText((Join-Path $tempFeature 'CONTINUITY.md'),$continuityFixtureText,(New-Object Text.UTF8Encoding $false))

    $storyDocPath = Join-Path $storyRoot 'STORY.md'
    $storyDocOriginal = Get-Content -LiteralPath $storyDocPath -Raw -Encoding UTF8
    $independentPlan = $planText.Replace('| **Status** | approved |','| **Status** | draft |').Replace('| **Progresso** | 0/2 |','| **Progresso** | 0/3 |')
    [IO.File]::WriteAllText($planPath,$independentPlan,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($storyDocPath,$storyDocOriginal.Replace('PLAN_000_o3_preflight.md','PLAN_999_o3_preflight.md'),(New-Object Text.UTF8Encoding $false))
    $independentIssues = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $independentIssues -match 'preflight: BLOCK - errors=3' -and $independentIssues -match 'plan_not_explicitly_approved' -and $independentIssues -match 'plan_progress_total_mismatch' -and $independentIssues -match 'story_prd_plan_navigation_mismatch') 'Independent approval, progress, and navigation issues must appear together while preflight blocks.'
    Assert-True ($independentIssues -match 'artifact=.*; field=.*; observed=.*; expected=.*; owner=.*; next=') 'Every aggregated issue must expose artifact, field, observed, expected, owner, and next action.'
    [IO.File]::WriteAllText($planPath,$planText,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($storyDocPath,$storyDocOriginal,(New-Object Text.UTF8Encoding $false))
    $revalidated = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $revalidated -match 'preflight: ALLOW') 'After repairing all reported issues, the complete preflight set must be rerun and pass.'
    Write-Host 'O3ArtifactPreflight: PASS (independent issues aggregated, blocker retained, full revalidation allowed)'

    $mismatchedPlan = Join-Path $planDir 'PLAN_001_o3_preflight.md'
    Copy-Item $planPath $mismatchedPlan
    $planIdentityDrift = & $preflightPath -FeatureRoot $tempFeature -PlanPath $mismatchedPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $planIdentityDrift -match 'feature_plan_prd_identity_mismatch:feature=000;plan=001;prd=000') 'PLAN sequence differing from the feature directory and PRD must block at preflight before O3 effects.'
    Remove-Item -LiteralPath $mismatchedPlan -Force
    $prdPath = Join-Path $prdDir '000_o3_preflight.md'
    $mismatchedPrd = Join-Path $prdDir '001_o3_preflight.md'
    Move-Item -LiteralPath $prdPath -Destination $mismatchedPrd
    try {
        $prdIdentityDrift = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -eq 2 -and $prdIdentityDrift -match 'feature_plan_prd_identity_mismatch:feature=000;plan=000;prd=001') 'PRD sequence differing from the feature directory and PLAN must block at preflight before O3 effects.'
    } finally { Move-Item -LiteralPath $mismatchedPrd -Destination $prdPath }
    Write-Host 'O3ArtifactPreflight: PASS (feature, PLAN, and PRD sequence identity mismatch blocked)'

    $refinePath = Join-Path $refineDir 'tasks.md'
    $refineOriginal = Get-Content -LiteralPath $refinePath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($refinePath, $refineOriginal.Replace('- **Depends on:** S1','- **Depends on:** none'), (New-Object Text.UTF8Encoding $false))
    $dependencyDrift = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $dependencyDrift -match 'plan_refine_dependency_mismatch:S2') 'PLAN/REFINE dependency divergence must block preflight.'
    [IO.File]::WriteAllText($refinePath, $refineOriginal, (New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (PLAN/REFINE dependency drift blocked)'

    $planText = Get-Content $planPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($planPath, $planText.Replace('| **Status** | approved |','| **Status** | draft |'), (New-Object Text.UTF8Encoding $false))
    $draft = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $draft -match 'plan_not_explicitly_approved') 'Unapproved PLAN must block preflight.'
    Write-Host 'O3ArtifactPreflight: PASS (unapproved PLAN blocked)'

    $sessionGate = Join-Path $repoRoot 'scripts\session\Invoke-DevelopSessionGate.ps1'
    $powerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
    $savedErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $sessionResult = & $powerShellExe -NoProfile -File $sessionGate -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd -Step 1 -Action ensure 2>&1 | Out-String
    $sessionExit = $LASTEXITCODE
    Assert-True ($sessionExit -ne 0 -and $sessionResult -match 'plan_not_explicitly_approved') 'Session creation helper must fail closed for an unapproved PLAN.'
    $claimGate = Join-Path $repoRoot 'scripts\ledger\Invoke-PlanLedgerClaim.ps1'
    $claimResult = & $powerShellExe -NoProfile -File $claimGate -Action claim -PlanPath $planPath -Step 1 -Holder 'preflight-test' -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    $claimExit = $LASTEXITCODE
    $ErrorActionPreference = $savedErrorPreference
    Assert-True ($claimExit -ne 0 -and $claimResult -match 'plan_not_explicitly_approved') 'PLAN ledger claim helper must fail closed for an unapproved PLAN.'
    Write-Host 'O3ArtifactPreflight: PASS (session and claim helpers fail closed before reservation)'

    $globalRoot = Join-Path $tempSdd 'repo-global'
    $globalFeature = Join-Path $globalRoot 'features\000-o3-preflight-fixture'
    $globalStory = Join-Path $globalFeature 'US01'
    $globalPlanDir = Join-Path $globalStory 'PLAN'
    $globalPrdDir = Join-Path $globalStory 'PRD'
    $globalRefineDir = Join-Path $globalStory 'REFINE'
    New-Item -ItemType Directory -Path $globalPlanDir,$globalPrdDir,$globalRefineDir -Force | Out-Null
    foreach ($name in @('FEATURE.md','CONTINUITY.md')) { Copy-Item (Join-Path $artifactFixture $name) (Join-Path $globalFeature $name) }
    Copy-Item (Join-Path $artifactFixture 'STORY.md') (Join-Path $globalStory 'STORY.md')
    Copy-Item (Join-Path $artifactFixture 'PRD.md') (Join-Path $globalPrdDir '000_o3_preflight.md')
    Copy-Item (Join-Path $artifactFixture 'tasks.md') (Join-Path $globalRefineDir 'tasks.md')
    $globalPlan = Join-Path $globalPlanDir 'PLAN_000_o3_preflight.md'
    Copy-Item (Join-Path $artifactFixture 'PLAN.md') $globalPlan
    $portableGlobalFeature = 'sdd/repo-global/features/000-o3-preflight-fixture/'
    foreach ($path in @((Join-Path $globalFeature 'CONTINUITY.md'),(Join-Path $globalStory 'STORY.md'),(Join-Path $globalPrdDir '000_o3_preflight.md'))) {
        $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        $text = $text.Replace('features/000-o3-preflight-fixture',$portableGlobalFeature.TrimEnd('/'))
        [IO.File]::WriteAllText($path,$text,(New-Object Text.UTF8Encoding $false))
    }
    $globalManifest = @{ schema_version = 2; repositories = @{ $repoRoot = @{ classic = @{ storage_mode = 'global'; path = $globalRoot; features_versioned = $false } } } } | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText((Join-Path $tempSdd 'manifest.json'),$globalManifest,(New-Object Text.UTF8Encoding $false))
    $externalPlan = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $externalPlan -match 'non_canonical_feature_or_plan_path') 'A repository PLAN outside the manifest-declared global feature root must remain blocked.'
    $globalAllow = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Host $globalAllow }
    Assert-True ($LASTEXITCODE -eq 0 -and $globalAllow -match 'preflight: ALLOW' -and $globalAllow -match 'sdd/repo-global/features/000-o3-preflight-fixture/US01/PLAN') 'Canonical global feature storage must pass preflight.'
    Write-Host 'O3ArtifactPreflight: PASS (canonical global storage allowed)'
    $globalPlanText = Get-Content -LiteralPath $globalPlan -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPlan,$globalPlanText.Replace('| **Status** | approved |','| **Status** | draft |'),(New-Object Text.UTF8Encoding $false))
    $globalDraft = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $globalDraft -match 'plan_not_explicitly_approved') 'Unapproved canonical global PLAN must be blocked.'
    $ErrorActionPreference = 'Continue'
    $globalSession = & $powerShellExe -NoProfile -File $sessionGate -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -Step 1 -Action ensure 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -ne 0 -and $globalSession -match 'plan_not_explicitly_approved') 'Session creation must reject an unapproved canonical global PLAN.'
    $globalClaim = & $powerShellExe -NoProfile -File $claimGate -Action claim -PlanPath $globalPlan -Step 1 -Holder 'global-preflight-test' -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -ne 0 -and $globalClaim -match 'plan_not_explicitly_approved') 'PLAN claim must reject an unapproved canonical global PLAN.'
    $ErrorActionPreference = $savedErrorPreference
    Write-Host 'O3ArtifactPreflight: PASS (global draft blocked by preflight, session, and claim)'

    $globalPlanText = $globalPlanText.Replace('| **Implementation status** | IN_PROGRESS |','| **Implementation status** | COMPLETED |').Replace('| **Progresso** | 0/2 |','| **Progresso** | 2/2 |').Replace('| `PENDING` |','| `COMPLETED` |')
    [IO.File]::WriteAllText($globalPlan,$globalPlanText,(New-Object Text.UTF8Encoding $false))
    $globalRefinePath = Join-Path $globalRefineDir 'tasks.md'
    $globalRefineText = Get-Content -LiteralPath $globalRefinePath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalRefinePath,$globalRefineText.Replace('☐ `PENDING`','☑ `COMPLETED`'),(New-Object Text.UTF8Encoding $false))
    $globalPrdPath = Join-Path $globalPrdDir '000_o3_preflight.md'
    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Status** | Pronto para planejamento |','| **Status** | Ready for planning |'),(New-Object Text.UTF8Encoding $false))
    $globalContinuityPath = Join-Path $globalFeature 'CONTINUITY.md'
    $globalContinuityText = Get-Content -LiteralPath $globalContinuityPath -Raw -Encoding UTF8
    $globalContinuityText = $globalContinuityText.Replace('Progresso: 0/2','Progresso: 2/2').Replace('Concluídos: none','Concluídos: S1, S2').Replace('Próximo: S1 — Reconcile the saved O3 artifacts','Próximo: none')
    [IO.File]::WriteAllText($globalContinuityPath,$globalContinuityText,(New-Object Text.UTF8Encoding $false))
    $skippedCompletionPlan = $globalPlanText.Replace('| S1 | Reconcile the saved O3 artifacts | none | Medium | `COMPLETED` | — |','| S1 | Reconcile the saved O3 artifacts | none | Medium | `SKIPPED` | approved omission reason |').Replace('| **Progresso** | 2/2 |','| **Progresso** | 1/2 |')
    [IO.File]::WriteAllText($globalPlan,$skippedCompletionPlan,(New-Object Text.UTF8Encoding $false))
    $skippedCompletion = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $skippedCompletion -match 'terminal_transition_plan_not_closed') 'A skipped PLAN step must never satisfy overall PLAN closure or authorize the PRD transition.'
    [IO.File]::WriteAllText($globalPlan,$globalPlanText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (SKIPPED remains distinct and prevents terminal closure)'
    $stalePrd = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $stalePrd -match 'completed_plan_prd_status_mismatch') 'Completed PLAN with a planning-ready PRD status must be blocked.'
    Write-Host 'O3ArtifactPreflight: PASS (completed PLAN requires Implementado/Implemented PRD status)'

    # Reproduce the closeout drift reported from the TS01 flow: PLAN says 6/6,
    # CONTINUITY still says 5/6, and the PRD remains planning-ready. The
    # preflight must reject the mismatched cross-artifact state, not reinterpret
    # it as an ordinary pending step or allow terminal closeout.
    $planBeforeSixOfSixDrift = Get-Content -LiteralPath $globalPlan -Raw -Encoding UTF8
    $refineBeforeSixOfSixDrift = Get-Content -LiteralPath $globalRefinePath -Raw -Encoding UTF8
    $prdBeforeSixOfSixDrift = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    $continuityBeforeSixOfSixDrift = Get-Content -LiteralPath $globalContinuityPath -Raw -Encoding UTF8
    try {
        $sixStepPlanText = [regex]::Replace($planBeforeSixOfSixDrift,'(?im)^\s*\|\s*\*\*Progresso\*\*\s*\|\s*2\s*/\s*2\s*\|\s*$', '| **Progresso** | 6/6 |', 1)
        $stepRows = [System.Collections.Generic.List[string]]::new()
        $stepHeadings = [System.Collections.Generic.List[string]]::new()
        for ($stepNumber = 3; $stepNumber -le 6; $stepNumber++) {
            $previousStep = $stepNumber - 1
            $stepId = "S$stepNumber"
            $stepName = "Verify closeout item $stepNumber"
            $stepRows.Add("| $stepId | $stepName | S$previousStep | Medium | ``COMPLETED`` | checkpoint $stepId |")
            $stepHeadings.Add("### STEP $stepNumber — ${stepId}: $stepName`n`n- **Depends on:** S$previousStep")
        }
        $lastBaseRow = '| S2 | Revalidate the saved O3 artifacts | S1 | Medium | `COMPLETED` | — |'
        $sixStepPlanText = $sixStepPlanText.Replace($lastBaseRow, ($lastBaseRow + "`n" + ($stepRows -join "`n")))
        $sixStepPlanText += "`n`n" + ($stepHeadings -join "`n`n") + "`n"
        $sixStepPlanText = [regex]::Replace($sixStepPlanText,'(?im)^\s*\|\s*\*\*Implementation status\*\*\s*\|\s*[^|]+\|\s*$', '| **Implementation status** | COMPLETED |', 1)

        $sixStepRefineText = $refineBeforeSixOfSixDrift
        for ($stepNumber = 3; $stepNumber -le 6; $stepNumber++) {
            $previousStep = $stepNumber - 1
            $stepId = "S$stepNumber"
            $stepName = "Verify closeout item $stepNumber"
            $sixStepRefineText += "`n`n### STEP $stepNumber — ${stepId}: $stepName`n`n☑ ``COMPLETED```n- **Depends on:** S$previousStep`n${stepId} — $stepName"
        }

        $sixOfSixPrdText = [regex]::Replace($prdBeforeSixOfSixDrift,'(?im)^\s*\|\s*\*\*Status\*\*\s*\|\s*[^|]+\|\s*$', '| **Status** | Ready for planning |', 1)
        $fiveOfSixContinuityText = [regex]::Replace($continuityBeforeSixOfSixDrift,'(?im)^\s*-\s*Progresso\s*:\s*.*$', '- Progresso: 5/6', 1)
        $fiveOfSixContinuityText = [regex]::Replace($fiveOfSixContinuityText,'(?im)^\s*-\s*Concluídos\s*:\s*.*$', '- Concluídos: S1, S2, S3, S4, S5', 1)
        $fiveOfSixContinuityText = [regex]::Replace($fiveOfSixContinuityText,'(?im)^\s*-\s*Próximo\s*:\s*.*$', '- Próximo: S6 — Verify closeout item 6', 1)

        [IO.File]::WriteAllText($globalPlan,$sixStepPlanText,(New-Object Text.UTF8Encoding $false))
        [IO.File]::WriteAllText($globalRefinePath,$sixStepRefineText,(New-Object Text.UTF8Encoding $false))
        [IO.File]::WriteAllText($globalPrdPath,$sixOfSixPrdText,(New-Object Text.UTF8Encoding $false))
        [IO.File]::WriteAllText($globalContinuityPath,$fiveOfSixContinuityText,(New-Object Text.UTF8Encoding $false))
        $sixOfSixDrift = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -eq 2 -and $sixOfSixDrift -match 'preflight: BLOCK' -and $sixOfSixDrift -match 'completed_plan_prd_status_mismatch' -and $sixOfSixDrift -match 'continuity_plan_reconciliation_mismatch:progress' -and $sixOfSixDrift -match 'continuity_plan_reconciliation_mismatch:completed') 'A 6/6 completed PLAN with 5/6 CONTINUITY and a planning-ready PRD must remain blocked with the exact cross-artifact diagnostics.'
        Write-Host 'O3ArtifactPreflight: PASS (6/6 PLAN vs 5/6 CONTINUITY and planning-ready PRD blocked)'
    } finally {
        [IO.File]::WriteAllText($globalPlan,$planBeforeSixOfSixDrift,(New-Object Text.UTF8Encoding $false))
        [IO.File]::WriteAllText($globalRefinePath,$refineBeforeSixOfSixDrift,(New-Object Text.UTF8Encoding $false))
        [IO.File]::WriteAllText($globalPrdPath,$prdBeforeSixOfSixDrift,(New-Object Text.UTF8Encoding $false))
        [IO.File]::WriteAllText($globalContinuityPath,$continuityBeforeSixOfSixDrift,(New-Object Text.UTF8Encoding $false))
    }

    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Content approval** | Approved by operator on 2026-10-24 |','| **Content approval** | [pending] |'),(New-Object Text.UTF8Encoding $false))
    $missingApproval = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $missingApproval -match 'terminal_transition_content_approval_missing') 'Transition mode must reject a missing persisted PRD content approval.'
    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Content approval** | [pending] |','| **Content approval** | Approved by operator on 2026-10-24 |'),(New-Object Text.UTF8Encoding $false))
    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    $transitionReady = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $transitionReady -match 'preflight: TRANSITION_READY' -and $transitionReady -match 'source=Ready for planning; target=Implemented' -and $transitionReady -match 'no files changed') ("Authorized owner transition must report only the fixed localized destination without writing files. Output: $transitionReady")
    $negatedApprovalText = $globalPrdText.Replace('| **Content approval** | Approved by operator on 2026-10-24 |','| **Content approval** | Not approved by operator on 2026-10-24 |')
    [IO.File]::WriteAllText($globalPrdPath,$negatedApprovalText,(New-Object Text.UTF8Encoding $false))
    $negatedTransitionApproval = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $negatedTransitionApproval -match 'terminal_transition_content_approval_missing') 'Negated English approval text must not authorize the PRD transition.'
    $revokedTransitionText = $globalPrdText.Replace('| **Content approval** | Approved by operator on 2026-10-24 |','| **Content approval** | Approved by operator on 2026-10-24, but later revoked |')
    [IO.File]::WriteAllText($globalPrdPath,$revokedTransitionText,(New-Object Text.UTF8Encoding $false))
    $revokedTransitionApproval = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $revokedTransitionApproval -match 'terminal_transition_content_approval_missing') 'A revoked approval record must not authorize the PRD transition.'
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (authorized PRD transition preconditions are narrow and read-only)'

    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    $localizedPrdText = $globalPrdText.Replace('| **Status** | Ready for planning |','| **Status** | Pronto para planejamento |').Replace('| **Content approval** | Approved by operator on 2026-10-24 |','| **Aprovação do conteúdo** | Aprovado pelo operador em 2026-10-24 |')
    [IO.File]::WriteAllText($globalPrdPath,$localizedPrdText,(New-Object Text.UTF8Encoding $false))
    $localizedTransitionReady = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $localizedTransitionReady -match 'preflight: TRANSITION_READY' -and $localizedTransitionReady -match 'source=Pronto para planejamento; target=Implementado' -and $localizedTransitionReady -match 'no files changed') ("Supported Portuguese PRD status, approval label, and approval value must produce the same transition decision as the English pair. Output: $localizedTransitionReady")
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText,(New-Object Text.UTF8Encoding $false))
    $unsupportedPrdText = $globalPrdText.Replace('| **Status** | Ready for planning |','| **Status** | Em andamento |')
    [IO.File]::WriteAllText($globalPrdPath,$unsupportedPrdText,(New-Object Text.UTF8Encoding $false))
    $unsupportedPrdStatus = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $unsupportedPrdStatus -match 'terminal_transition_source_invalid' -and $unsupportedPrdStatus -match 'field=.*Status' -and $unsupportedPrdStatus -match 'observed=.*Em andamento' -and $unsupportedPrdStatus -match 'expected=.*Pronto para planejamento or Ready for planning' -and $unsupportedPrdStatus -match 'next=') 'Unsupported localized PRD status must be rejected with field, observed value, expected forms, and next action.'
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText,(New-Object Text.UTF8Encoding $false))
    Write-Host 'O3ArtifactPreflight: PASS (paired English/Portuguese transition decision; unsupported localized PRD status rejected actionably)'

    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Status** | Ready for planning |','| **Status** | Implemented |'),(New-Object Text.UTF8Encoding $false))
    $postTransition = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $postTransition -match 'preflight: ALLOW' -and $postTransition -match 'completed=2') 'Standard preflight must accept the coherent terminal state after PRD transition.'
    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Status** | Implemented |','| **Status** | Implementado |'),(New-Object Text.UTF8Encoding $false))
    $localizedPostTransition = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0 -and $localizedPostTransition -match 'preflight: ALLOW' -and $localizedPostTransition -match 'completed=2') 'Supported Portuguese terminal PRD status must produce the same allow decision as Implemented.'
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText,(New-Object Text.UTF8Encoding $false))
    $terminalNegatedText = $globalPrdText.Replace('| **Status** | Ready for planning |','| **Status** | Implemented |').Replace('| **Content approval** | Approved by operator on 2026-10-24 |','| **Content approval** | Approved but not approved by operator |')
    [IO.File]::WriteAllText($globalPrdPath,$terminalNegatedText,(New-Object Text.UTF8Encoding $false))
    $terminalNegatedApproval = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $terminalNegatedApproval -match 'completed_plan_content_approval_missing') 'A positive approval token followed by a negation must not satisfy the terminal approval invariant.'
    $terminalRevokedText = $globalPrdText.Replace('| **Status** | Ready for planning |','| **Status** | Implemented |').Replace('| **Content approval** | Approved by operator on 2026-10-24 |','| **Content approval** | Approved by operator on 2026-10-24, but later revoked |')
    [IO.File]::WriteAllText($globalPrdPath,$terminalRevokedText,(New-Object Text.UTF8Encoding $false))
    $terminalRevokedApproval = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $terminalRevokedApproval -match 'completed_plan_content_approval_missing') 'A revoked approval record must not satisfy the terminal approval invariant.'
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText,(New-Object Text.UTF8Encoding $false))
    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Content approval** | Approved by operator on 2026-10-24 |','| **Content approval** | [pending] |'),(New-Object Text.UTF8Encoding $false))
    $terminalApprovalMissing = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $terminalApprovalMissing -match 'completed_plan_content_approval_missing') 'Post-transition invariants must retain the persisted PRD approval record.'
    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Content approval** | [pending] |','| **Content approval** | Approved by operator on 2026-10-24 |'),(New-Object Text.UTF8Encoding $false))
    $globalPrdText = Get-Content -LiteralPath $globalPrdPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($globalPrdPath,$globalPrdText.Replace('| **Status** | Implemented |','| **Status** | In progress |'),(New-Object Text.UTF8Encoding $false))
    $wrongTransitionSource = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd -AuthorizeCompletedPlanPrdTransition 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $wrongTransitionSource -match 'terminal_transition_source_invalid') 'Transition mode must reject a source state outside the two planning-ready statuses.'
    $incompatibleTerminal = & $preflightPath -FeatureRoot $globalFeature -PlanPath $globalPlan -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $incompatibleTerminal -match 'completed_plan_prd_status_mismatch') 'Standard preflight must reject an incompatible PRD status after PLAN completion.'
    Write-Host 'O3ArtifactPreflight: PASS (post-transition invariants accept coherent and reject incompatible states)'

    [IO.File]::WriteAllText((Join-Path $tempSdd 'manifest.json'),$repoManifest,(New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($planPath, $planText, (New-Object Text.UTF8Encoding $false))
    $continuityPath = Join-Path $tempFeature 'CONTINUITY.md'
    $continuityText = Get-Content $continuityPath -Raw -Encoding UTF8
    [IO.File]::WriteAllText($continuityPath, $continuityText.Replace('S1 — Reconcile the saved O3 artifacts','S2 — Stale next step'), (New-Object Text.UTF8Encoding $false))
    $drift = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 2 -and $drift -match 'continuity_plan_reconciliation_mismatch') 'Stale CONTINUITY next step must block preflight.'
    Write-Host 'O3ArtifactPreflight: PASS (stale CONTINUITY blocked)'

    # A blocked first step must prevent its dependent from becoming the next
    # eligible step, even though the completed prefix is still zero.
    [IO.File]::WriteAllText($planPath, $planText.Replace('| `PENDING` | — |','| `BLOCKED` | — |'), (New-Object Text.UTF8Encoding $false))
    $blockedContinuity = Get-Content -LiteralPath $continuityPath -Raw -Encoding UTF8
    $blockedContinuity = $blockedContinuity.Replace('Próximo: S2 — Stale next step','Próximo: none')
    [IO.File]::WriteAllText($continuityPath, $blockedContinuity, (New-Object Text.UTF8Encoding $false))
    $blocked = & $preflightPath -FeatureRoot $tempFeature -PlanPath $planPath -RepoPath $repoRoot -SddRoot $tempSdd 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Host $blocked }
    Assert-True ($LASTEXITCODE -eq 0 -and $blocked -match 'preflight: ALLOW' -and $blocked -match 'completed=0') 'A blocked step must reconcile with no next step and must keep dependent steps ineligible.'
    Write-Host 'O3ArtifactPreflight: PASS (blocked step prevents dependent eligibility)'
}
finally {
    if (Test-Path -LiteralPath $tempFeature) { Remove-Item -LiteralPath $tempFeature -Recurse -Force }
    if (Test-Path -LiteralPath $tempFeatureTs) { Remove-Item -LiteralPath $tempFeatureTs -Recurse -Force }
    if (Test-Path -LiteralPath $tempSdd) { Remove-Item -LiteralPath $tempSdd -Recurse -Force }
}
Write-Host 'Assert-PlanningO3Behavior: ALL PASS'
exit 0
