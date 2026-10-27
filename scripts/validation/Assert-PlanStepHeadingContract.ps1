$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixturePath = Join-Path $PSScriptRoot 'fixtures\sdd-artifacts\plan\valid.md'
$validatorPath = Join-Path $PSScriptRoot 'validate-plan.ps1'
$preflightPath = Join-Path $PSScriptRoot 'Invoke-O3ArtifactPreflight.ps1'

. (Join-Path $repoRoot 'scripts\_lib\ToolkitConstants.ps1')
$tokens = $null
$parseErrors = $null
$preflightAst = [System.Management.Automation.Language.Parser]::ParseFile($preflightPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'O3 preflight must parse before its step-heading contract is tested.' }
$preflightFunction = $preflightAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-PreflightStepHeadings' }, $true)
if ($null -eq $preflightFunction) { throw 'Get-PreflightStepHeadings must delegate to the shared parser.' }
. ([scriptblock]::Create($preflightFunction.Extent.Text))

function Assert-SameParse([string]$Text, [bool]$ExpectedValid, [string]$CaseName) {
    $shared = Get-SddArtifactPlanStepHeadings -Text $Text
    $preflight = Get-PreflightStepHeadings -Text $Text
    if ($ExpectedValid -and ($shared.Valid.Count -eq 0 -or $shared.Invalid.Count -gt 0)) { throw "${CaseName}: shared parser result disagreed with expectation." }
    if (-not $ExpectedValid -and $shared.Invalid.Count -eq 0) { throw "${CaseName}: shared parser failed to flag malformed syntax." }
    if ($ExpectedValid -and ($preflight.Valid.Count -eq 0 -or $preflight.Invalid.Count -gt 0)) { throw "${CaseName}: O3 parser result disagreed with expectation." }
    if (-not $ExpectedValid -and $preflight.Invalid.Count -eq 0) { throw "${CaseName}: O3 parser failed to flag malformed syntax." }
    if ($shared.Valid.Count -ne $preflight.Valid.Count -or ($shared.Invalid -join '|') -ne ($preflight.Invalid -join '|')) {
        throw "${CaseName}: validate-plan and O3 preflight parser projections differ."
    }
    if ($ExpectedValid) {
        for ($index = 0; $index -lt $shared.Valid.Count; $index++) {
            if ($shared.Valid[$index].Id -ne $preflight.Valid[$index].Id -or $shared.Valid[$index].Name -ne $preflight.Valid[$index].Name) {
                throw "${CaseName}: parsed semantic step differs between consumers."
            }
        }
    }
}

$original = Get-Content -LiteralPath $fixturePath -Raw -Encoding UTF8
$tempPath = [System.IO.Path]::GetTempFileName()
try {
    $validCases = @(
        @{ Name = 'English'; Prefixes = @('STEP','STEP') },
        @{ Name = 'Portuguese'; Prefixes = @('PASSO','ETAPA') },
        @{ Name = 'Mixed'; Prefixes = @('STEP','PASSO') }
    )
    foreach ($case in $validCases) {
        $stepIndex = 0
        $variant = [regex]::Replace($original, '(?m)^###\s*⏳\s*PASSO\s+(\d+)\s*—\s*S\d+:\s*(.+)$', {
            param($match)
            $stepIndex++
            return ('### {0} {1} — S{1}: {2}' -f $case.Prefixes[$stepIndex - 1], $match.Groups[1].Value, $match.Groups[2].Value)
        })
        Set-Content -LiteralPath $tempPath -Value $variant -Encoding UTF8
        & $validatorPath -Path $tempPath
        if ($LASTEXITCODE -ne 0) { throw "$($case.Name) heading syntax must pass validate-plan." }
        Assert-SameParse $variant $true $case.Name
    }

    $firstHeading = '(?m)^###\s*⏳\s*PASSO\s+1\s*—\s*S1:\s*First\s*$'
    $invalidCases = @(
        @{ Name = 'Missing ordinal'; Replacement = '### STEP X — S1: First' },
        @{ Name = 'Missing ID'; Replacement = '### PASSO 1: First' },
        @{ Name = 'Missing title'; Replacement = '### ETAPA 1 — S1' },
        @{ Name = 'Ordinal ID mismatch'; Replacement = '### STEP 1 — S2: First' },
        @{ Name = 'Unsupported level 2 heading'; Replacement = '## STEP 1 — S1: First' },
        @{ Name = 'Unsupported level 4 heading'; Replacement = '#### STEP 1 — S1: First' }
    )
    foreach ($case in $invalidCases) {
        $variant = [regex]::Replace($original, $firstHeading, $case.Replacement, 1)
        Set-Content -LiteralPath $tempPath -Value $variant -Encoding UTF8
        & $validatorPath -Path $tempPath
        if ($LASTEXITCODE -eq 0) { throw "$($case.Name) must fail validate-plan." }
        Assert-SameParse $variant $false $case.Name
    }
}
finally {
    if (Test-Path -LiteralPath $tempPath -PathType Leaf) { Remove-Item -LiteralPath $tempPath -Force }
}

Write-Host 'PlanStepHeadingContract: PASS (shared grammar and semantic extraction across validate-plan/O3; PT/EN/mixed accepted; malformed/unsupported rejected)'
