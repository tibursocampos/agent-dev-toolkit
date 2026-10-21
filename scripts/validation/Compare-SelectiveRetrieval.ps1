#Requires -Version 5.1
[CmdletBinding()]
param(
    [string] $CaseSetPath = (Join-Path $PSScriptRoot 'fixtures/selective-retrieval-evaluation/cases.json'),
    [string] $ReportPath = (Join-Path $PSScriptRoot 'fixtures/selective-retrieval-evaluation/reference-report.json'),
    [switch] $SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-Problem {
    param([System.Collections.Generic.List[string]] $Problems, [string] $Message)
    $Problems.Add($Message)
}

function Test-PortableFixturePath {
    param([string] $Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:' -or $Path.StartsWith('/') -or $Path.StartsWith('\')) {
        return $false
    }
    $segments = $Path -split '[\\/]'
    return -not ($segments -contains '..' -or $segments -contains '.')
}

function Get-ComparisonProblems {
    param(
        [Parameter(Mandatory = $true)] $CaseSet,
        [Parameter(Mandatory = $true)] $Report,
        [Parameter(Mandatory = $true)][string] $FixtureRoot
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    if ($CaseSet.schemaVersion -ne 1 -or $Report.schemaVersion -ne 1) {
        Add-Problem -Problems $problems -Message 'schemaVersion must be 1 in case set and report'
    }

    $metadata = $Report.PSObject.Properties['runMetadata']
    if ($null -eq $metadata -or $null -eq $metadata.Value) {
        Add-Problem -Problems $problems -Message 'report.runMetadata is required with host, retrievalGuidanceRevision, and runLabel'
    } else {
        foreach ($field in @('host', 'retrievalGuidanceRevision', 'runLabel')) {
            $property = $metadata.Value.PSObject.Properties[$field]
            if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                Add-Problem -Problems $problems -Message ("report.runMetadata.{0} is required and must be non-empty" -f $field)
            }
        }
    }

    $caseById = @{}
    foreach ($case in @($CaseSet.cases)) {
        if ([string]::IsNullOrWhiteSpace([string]$case.id) -or $caseById.ContainsKey([string]$case.id)) {
            Add-Problem -Problems $problems -Message 'case ids must be present and unique'
            continue
        }
        $caseById[[string]$case.id] = $case
        foreach ($path in @($case.availablePaths)) {
            if (-not (Test-PortableFixturePath -Path ([string]$path))) {
                Add-Problem -Problems $problems -Message ("case {0} has non-portable path {1}" -f $case.id, $path)
                continue
            }
            if (-not (Test-Path -LiteralPath (Join-Path $FixtureRoot $path) -PathType Leaf)) {
                Add-Problem -Problems $problems -Message ("case {0} references missing fixture {1}" -f $case.id, $path)
            }
        }
    }

    $resultById = @{}
    foreach ($result in @($Report.results)) {
        $caseId = [string]$result.caseId
        if ([string]::IsNullOrWhiteSpace($caseId) -or $resultById.ContainsKey($caseId)) {
            Add-Problem -Problems $problems -Message 'result case ids must be present and unique'
            continue
        }
        if (-not $caseById.ContainsKey($caseId)) {
            Add-Problem -Problems $problems -Message ("report contains unknown case {0}" -f $caseId)
            continue
        }
        $resultById[$caseId] = $result
        $case = $caseById[$caseId]

        if ([string]$result.outcome -notin @('answered', 'insufficient', 'conflict')) {
            Add-Problem -Problems $problems -Message ("case {0} has invalid outcome" -f $caseId)
        } elseif ([string]$result.outcome -ne [string]$case.expectedOutcome) {
            Add-Problem -Problems $problems -Message ("case {0} outcome mismatch: expected {1}, got {2}" -f $caseId, $case.expectedOutcome, $result.outcome)
        }

        if ([string]$result.semanticReview -notin @('not-reviewed', 'pass', 'fail')) {
            Add-Problem -Problems $problems -Message ("case {0} semanticReview must be not-reviewed, pass, or fail" -f $caseId)
        }

        $allowed = @($case.availablePaths | ForEach-Object { [string]$_ })
        foreach ($field in @('consultedPaths', 'citedPaths')) {
            $paths = @($result.$field | ForEach-Object { [string]$_ })
            foreach ($path in $paths) {
                if (-not (Test-PortableFixturePath -Path $path)) {
                    Add-Problem -Problems $problems -Message ("case {0} {1} contains non-portable path {2}" -f $caseId, $field, $path)
                } elseif ($allowed -notcontains $path) {
                    Add-Problem -Problems $problems -Message ("case {0} {1} uses unavailable path {2}" -f $caseId, $field, $path)
                }
            }
            $requiredField = 'required' + $field.Substring(0, 1).ToUpperInvariant() + $field.Substring(1)
            foreach ($requiredPath in @($case.$requiredField)) {
                if ($paths -notcontains [string]$requiredPath) {
                    Add-Problem -Problems $problems -Message ("case {0} {1} omitted required path {2}" -f $caseId, $field, $requiredPath)
                }
            }
            foreach ($forbiddenPath in @($case.forbiddenPaths)) {
                if ($paths -contains [string]$forbiddenPath) {
                    Add-Problem -Problems $problems -Message ("case {0} {1} includes irrelevant/forbidden path {2}" -f $caseId, $field, $forbiddenPath)
                }
            }
        }
    }

    foreach ($caseId in $caseById.Keys) {
        if (-not $resultById.ContainsKey($caseId)) {
            Add-Problem -Problems $problems -Message ("report is missing case {0}" -f $caseId)
        }
    }

    if ($null -ne $Report.hostMetrics) {
        $availability = [string]$Report.hostMetrics.availability
        if ($availability -notin @('available', 'unavailable')) {
            Add-Problem -Problems $problems -Message 'hostMetrics.availability must be available or unavailable when hostMetrics is present'
        }
        $tokenCountProperty = $Report.hostMetrics.PSObject.Properties['tokenCount']
        $durationProperty = $Report.hostMetrics.PSObject.Properties['durationMs']
        $tokenCount = if ($null -eq $tokenCountProperty) { $null } else { $tokenCountProperty.Value }
        $durationMs = if ($null -eq $durationProperty) { $null } else { $durationProperty.Value }
        foreach ($metricName in @('tokenCount', 'durationMs')) {
            $metric = if ($metricName -eq 'tokenCount') { $tokenCount } else { $durationMs }
            if ($null -ne $metric -and (([double]$metric -lt 0) -or ([double]$metric -ne [math]::Floor([double]$metric)))) {
                Add-Problem -Problems $problems -Message ("hostMetrics.{0} must be a non-negative integer" -f $metricName)
            }
        }
        if ($availability -eq 'available' -and $null -eq $tokenCount -and $null -eq $durationMs) {
            Add-Problem -Problems $problems -Message 'hostMetrics marked available but has no tokenCount or durationMs'
        }
    }

    return ,$problems
}

function Get-EvaluationStatus {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]] $ObjectiveProblems,
        [Parameter(Mandatory = $true)] $Report
    )

    if ($ObjectiveProblems.Count -gt 0) { return 'FAIL' }
    if (@($Report.results | Where-Object { [string]$_.semanticReview -eq 'fail' }).Count -gt 0) {
        return 'REVIEW-FAIL'
    }
    return 'PASS'
}

if (-not (Test-Path -LiteralPath $CaseSetPath -PathType Leaf)) {
    Write-Error ("Missing case set: {0}" -f $CaseSetPath)
    exit 2
}
if (-not (Test-Path -LiteralPath $ReportPath -PathType Leaf)) {
    Write-Error ("Missing report: {0}" -f $ReportPath)
    exit 2
}

$fixtureRoot = Split-Path -Parent $CaseSetPath
$caseSet = Get-Content -LiteralPath $CaseSetPath -Raw -Encoding UTF8 | ConvertFrom-Json
$report = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
$problems = Get-ComparisonProblems -CaseSet $caseSet -Report $report -FixtureRoot $fixtureRoot

if ($SelfTest) {
    if ($problems.Count -gt 0) {
        Write-Error ("Evaluator self-test valid report failed: {0}" -f ($problems -join '; '))
        exit 1
    }
    $mutated = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mutated.results[0].consultedPaths += 'case-01/retry-decoy.md'
    $negativeProblems = Get-ComparisonProblems -CaseSet $caseSet -Report $mutated -FixtureRoot $fixtureRoot
    if ($negativeProblems.Count -eq 0) {
        Write-Error 'Evaluator self-test failed to reject an irrelevant consulted source'
        exit 1
    }
    $mutatedOutcome = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mutatedOutcome.results[1].outcome = 'answered'
    $outcomeProblems = Get-ComparisonProblems -CaseSet $caseSet -Report $mutatedOutcome -FixtureRoot $fixtureRoot
    if ($outcomeProblems.Count -eq 0) {
        Write-Error 'Evaluator self-test failed to reject an incorrect outcome'
        exit 1
    }
    $mutatedEvidence = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mutatedEvidence.results[0].citedPaths = @()
    $evidenceProblems = Get-ComparisonProblems -CaseSet $caseSet -Report $mutatedEvidence -FixtureRoot $fixtureRoot
    if ($evidenceProblems.Count -eq 0) {
        Write-Error 'Evaluator self-test failed to reject missing required evidence'
        exit 1
    }
    $mutatedMetadata = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mutatedMetadata.PSObject.Properties.Remove('runMetadata')
    $metadataProblems = Get-ComparisonProblems -CaseSet $caseSet -Report $mutatedMetadata -FixtureRoot $fixtureRoot
    if ($metadataProblems.Count -eq 0) {
        Write-Error 'Evaluator self-test failed to reject missing run metadata'
        exit 1
    }
    $mutatedMetadataField = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mutatedMetadataField.runMetadata.host = ' '
    $metadataFieldProblems = Get-ComparisonProblems -CaseSet $caseSet -Report $mutatedMetadataField -FixtureRoot $fixtureRoot
    if ($metadataFieldProblems.Count -eq 0) {
        Write-Error 'Evaluator self-test failed to reject an empty run metadata field'
        exit 1
    }
    $mutatedSemanticReview = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mutatedSemanticReview.results[0].semanticReview = 'fail'
    $semanticReviewProblems = Get-ComparisonProblems -CaseSet $caseSet -Report $mutatedSemanticReview -FixtureRoot $fixtureRoot
    $objectiveStatus = if ($semanticReviewProblems.Count -eq 0) { 'PASS' } else { 'FAIL' }
    $overallStatus = Get-EvaluationStatus -ObjectiveProblems $semanticReviewProblems -Report $mutatedSemanticReview
    if ($objectiveStatus -ne 'PASS' -or $overallStatus -ne 'REVIEW-FAIL') {
        Write-Error 'Evaluator self-test failed to preserve objective PASS while surfacing semantic review failure as REVIEW-FAIL'
        exit 1
    }
    $unreviewed = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $unreviewedStatus = Get-EvaluationStatus -ObjectiveProblems $problems -Report $unreviewed
    if ($unreviewedStatus -ne 'PASS' -or @($unreviewed.results | Where-Object { [string]$_.semanticReview -eq 'not-reviewed' }).Count -eq 0) {
        Write-Error 'Evaluator self-test failed to preserve not-reviewed as distinct from semantic pass'
        exit 1
    }
    Write-Host 'SelectiveRetrievalEvaluatorSelfTest: PASS (valid report accepted; irrelevant path, wrong outcome, missing citation, missing metadata, empty metadata field, semantic review failure status, and not-reviewed distinction covered)'
    exit 0
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) { Write-Error $problem }
    Write-Host 'ObjectiveChecks: FAIL'
    Write-Host 'SemanticReviewStatus: not evaluated because objective checks failed'
    Write-Host 'OverallEvaluation: FAIL'
    Write-Host 'SelectiveRetrievalComparison: FAIL'
    exit 1
}

Write-Host ("ObjectiveChecks: PASS ({0} cases; path/outcome checks only)" -f @($caseSet.cases).Count)
foreach ($result in @($report.results)) {
    if ([string]$result.semanticReview -eq 'not-reviewed') {
        Write-Host ("HumanSemanticReview: {0} = NOT-REVIEWED (semantic quality was not evaluated; this is not a semantic PASS)" -f $result.caseId)
    } else {
        Write-Host ("HumanSemanticReview: {0} = {1}" -f $result.caseId, $result.semanticReview.ToUpperInvariant())
    }
}
$evaluationStatus = Get-EvaluationStatus -ObjectiveProblems $problems -Report $report
Write-Host ("OverallEvaluation: {0}" -f $evaluationStatus)
Write-Host ("SelectiveRetrievalComparison: {0}" -f $evaluationStatus)
if ($evaluationStatus -eq 'REVIEW-FAIL') { exit 1 }
exit 0