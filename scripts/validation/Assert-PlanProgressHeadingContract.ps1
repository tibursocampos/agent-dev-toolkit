# Exercises the structural PLAN progress-heading allowlist in both consumers.
$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$planValidator = Join-Path $PSScriptRoot 'validate-plan.ps1'
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures\sdd-artifacts\plan'
$validPlan = Join-Path $fixtureRoot 'valid.md'
$validEnglishPlan = Join-Path $fixtureRoot 'valid-progress-english.md'
$invalidNearMissPlan = Join-Path $fixtureRoot 'invalid-progress-near-miss.md'

foreach ($path in @($validPlan, $validEnglishPlan)) {
    & $planValidator -Path $path
    Assert-True ($LASTEXITCODE -eq 0) "validate-plan must accept supported heading in $path"
}
& $planValidator -Path $invalidNearMissPlan
Assert-True ($LASTEXITCODE -ne 0) 'validate-plan must reject the unsupported near-miss heading.'

# Evaluate the actual section parser functions without running O3 preflight's
# unrelated FEATURE/STORY/CONTINUITY gates (this PLAN is Classic/direct).
$preflightPath = Join-Path $PSScriptRoot 'Invoke-O3ArtifactPreflight.ps1'
. (Join-Path $repoRoot 'scripts\_lib\ToolkitConstants.ps1')
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($preflightPath, [ref]$tokens, [ref]$parseErrors)
Assert-True ($parseErrors.Count -eq 0) 'O3 preflight source must parse before its heading contract is exercised.'
$functions = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in @('ConvertTo-PreflightLabel', 'Remove-PreflightDecoration', 'Get-PreflightTableCells', 'Get-PreflightSection', 'Get-PreflightDependencyIds', 'Get-PreflightStepTableRows') }, $true))
Assert-True ($functions.Count -eq 6) 'Expected the O3 section and table-parser functions.'
foreach ($function in $functions) { . ([scriptblock]::Create($function.Extent.Text)) }

$supportedHeadings = @('Implementation progress', 'Progresso da implementação', 'Progresso de implementação')
foreach ($heading in $supportedHeadings) {
    $section = Get-PreflightSection "## $heading`n| S1 | PENDING |`n## Next" $supportedHeadings
    Assert-True ($section -match 'S1') "O3 preflight must recognize supported heading '$heading'."
}
$aliasCases = @(
    @{ Domain='execution-status'; Value='Concluído'; Canonical='COMPLETED' },
    @{ Domain='execution-status'; Value='Em andamento'; Canonical='IN_PROGRESS' },
    @{ Domain='evidence-classification'; Value='Confirmada'; Canonical='CONFIRMED' },
    @{ Domain='evidence-classification'; Value='Inferido'; Canonical='INFERRED' },
    @{ Domain='evidence-classification'; Value='Lacuna'; Canonical='GAP' },
    @{ Domain='evidence-classification'; Value='Apenas proposta'; Canonical='PROPOSAL_ONLY' }
)
foreach ($case in $aliasCases) {
    $resolvedAlias = Resolve-SddArtifactAlias -Domain $case.Domain -Value $case.Value
    Assert-True ($resolvedAlias.Recognized -and $resolvedAlias.Canonical -eq $case.Canonical) "Alias '$($case.Value)' must normalize to $($case.Canonical)."
}
Assert-True ((Resolve-SddArtifactAlias -Domain 'execution-status' -Value 'CONFIRMED').Recognized -eq $false) 'Evidence classification values must not be accepted as execution statuses.'
Assert-True ((Resolve-SddArtifactAlias -Domain 'evidence-classification' -Value 'COMPLETED').Recognized -eq $false) 'Execution status values must not be accepted as evidence classifications.'
$nearMiss = Get-PreflightSection "## Progresso implementação`n| S1 | PENDING |`n## Next" $supportedHeadings
Assert-True ([string]::IsNullOrWhiteSpace($nearMiss)) 'O3 preflight must reject the unsupported near-miss heading.'

$mixedRows = @(Get-PreflightStepTableRows "| ID da etapa | Dependencies | Situação | Evidência |`n|---|---|---|---|`n| S1 | none | PENDENTE | Lacuna |")
Assert-True ($mixedRows.Count -eq 1 -and $mixedRows[0].Id -eq 'S1' -and $mixedRows[0].StatusCanonical -eq 'PENDING') 'Mixed PT/EN columns and Portuguese status must resolve to canonical fields.'
Assert-True ((Resolve-SddArtifactAlias -Domain 'evidence-classification' -Value $mixedRows[0].Evidence).Canonical -eq 'GAP') 'Portuguese evidence classification must remain separate from step status.'
$conflictingRows = @(Get-PreflightStepTableRows "| Step ID | Dependencies | Status | Estado |`n|---|---|---|---|`n| S1 | none | PENDING | CONCLUÍDO |")
Assert-True ($conflictingRows.Count -eq 1 -and $conflictingRows[0].Conflicts.Count -eq 1) 'Conflicting duplicate columns in mixed languages must be reported.'
$missingRows = @(Get-PreflightStepTableRows "| Step ID | Dependencies | Status |`n|---|---|---|`n| S1 |")
Assert-True ($missingRows.Count -eq 1 -and [string]::IsNullOrWhiteSpace($missingRows[0].Status)) 'Missing required values must remain a detectable validation issue instead of throwing.'

Write-Host 'PlanProgressHeadingContract: PASS (validate-plan and O3 preflight agree on 3 explicit aliases and reject the unsupported near miss)'
