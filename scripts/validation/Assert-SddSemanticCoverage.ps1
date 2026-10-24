#Requires -Version 5.1
[CmdletBinding()]
param(
    [string] $CaseSetPath = (Join-Path $PSScriptRoot 'fixtures/sdd-semantic-coverage/cases.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-Problem {
    param([System.Collections.Generic.List[string]] $Problems, [string] $Message)
    [void]$Problems.Add($Message)
}

function Test-PortableRepositoryPath {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:' -or $Path.StartsWith('/') -or $Path.StartsWith('\')) {
        return $false
    }

    $segments = $Path -split '[\\/]'
    if (@($segments | Where-Object {
        [string]::IsNullOrWhiteSpace($_) -or
        $_ -in @('.', '..') -or
        $_ -match '[<>:"|?*\x00-\x1F]' -or
        $_.EndsWith('.') -or
        $_.EndsWith(' ') -or
        $_ -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$'
    }).Count -gt 0) {
        return $false
    }

    return $true
}

function Add-RepositoryReference {
    param(
        [Parameter(Mandatory = $true)][string] $CaseId,
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $ReferenceKind,
        [Parameter(Mandatory = $true)][string] $RepositoryRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]] $Problems,
        [Parameter(Mandatory = $true)][hashtable] $PathCounts
    )

    $PathCounts.Total++
    if (-not (Test-PortableRepositoryPath -Path $Path)) {
        Add-Problem -Problems $Problems -Message ("{0} has non-portable {1} path {2}" -f $CaseId, $ReferenceKind, $Path)
        return
    }

    $segments = $Path -split '[\\/]'
    $isFeatureLocal = $segments[0] -ieq 'features'
    $fullPath = Join-Path $RepositoryRoot $Path
    $pathExists = Test-Path -LiteralPath $fullPath

    if (-not $pathExists) {
        if ($isFeatureLocal) {
            $PathCounts.FeatureLocalUnavailable++
        } else {
            $PathCounts.RequiredMissing++
            Add-Problem -Problems $Problems -Message ("{0} references missing versioned {1} {2}" -f $CaseId, $ReferenceKind, $Path)
        }
        return
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Problem -Problems $Problems -Message ("{0} references non-file {1} {2}" -f $CaseId, $ReferenceKind, $Path)
        return
    }

    if ($isFeatureLocal) {
        $PathCounts.FeatureLocalPresent++
    } else {
        $PathCounts.RequiredPresent++
    }
}

function Write-RepositoryReferenceSummary {
    param([Parameter(Mandatory = $true)][hashtable] $PathCounts)

    Write-Host ("RepositoryReferences: total={0}; versioned-present={1}; feature-local-present={2}; feature-local-unavailable={3}; versioned-missing={4}" -f `
        $PathCounts.Total, $PathCounts.RequiredPresent, $PathCounts.FeatureLocalPresent, $PathCounts.FeatureLocalUnavailable, $PathCounts.RequiredMissing)
}

function Test-RequiredText {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)][string] $Name
    )

    $property = $Object.PSObject.Properties[$Name]
    return $null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)
}

function Test-ExpectedStringSet {
    param(
        [string[]] $Actual,
        [string[]] $Expected
    )

    return (@($Actual | Sort-Object) -join ',') -eq (@($Expected | Sort-Object) -join ',')
}

function Get-SddSemanticCoverageProblems {
    param(
        [Parameter(Mandatory = $true)] $CaseSet,
        [Parameter(Mandatory = $true)][string] $RepositoryRoot,
        [Parameter(Mandatory = $true)][hashtable] $PathCounts
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    if ($CaseSet.schemaVersion -ne 1) {
        Add-Problem -Problems $problems -Message 'schemaVersion must be 1'
    }
    if (-not (Test-RequiredText -Object $CaseSet -Name 'contractSetVersion')) {
        Add-Problem -Problems $problems -Message 'contractSetVersion is required'
    }

    $expectedById = @{
        CT1 = @{ group = 'G1'; requirements = @('REQ-001'); acceptanceCriteria = @('CA1') }
        CT2 = @{ group = 'G1'; requirements = @('REQ-002'); acceptanceCriteria = @('CA2') }
        CT3 = @{ group = 'G1'; requirements = @('REQ-003'); acceptanceCriteria = @('CA3') }
        CT4 = @{ group = 'G1'; requirements = @('REQ-003'); acceptanceCriteria = @('CA3') }
        CT5 = @{ group = 'G2'; requirements = @('REQ-004'); acceptanceCriteria = @('CA4') }
        CT6 = @{ group = 'G1'; requirements = @('REQ-005'); acceptanceCriteria = @('CA5') }
        CT7 = @{ group = 'G3'; requirements = @('REQ-006'); acceptanceCriteria = @('CA6') }
        CT8 = @{ group = 'G3'; requirements = @('REQ-006'); acceptanceCriteria = @('CA6') }
        CT9 = @{ group = 'G3'; requirements = @('REQ-007'); acceptanceCriteria = @('CA7') }
        CT10 = @{ group = 'G2'; requirements = @('REQ-008'); acceptanceCriteria = @('CA8') }
        CT11 = @{ group = 'G2'; requirements = @('REQ-009'); acceptanceCriteria = @('CA9') }
        CT12 = @{ group = 'G4'; requirements = @('REQ-010'); acceptanceCriteria = @('CA10') }
        CT13 = @{ group = 'G4'; requirements = @('REQ-010'); acceptanceCriteria = @('CA10') }
    }

    $caseById = @{}
    $cases = @($CaseSet.cases)
    if ($cases.Count -ne $expectedById.Count) {
        Add-Problem -Problems $problems -Message ("cases must contain exactly {0} scenarios CT1-CT13" -f $expectedById.Count)
    }

    foreach ($case in $cases) {
        $caseId = [string]$case.id
        if ([string]::IsNullOrWhiteSpace($caseId) -or $caseById.ContainsKey($caseId)) {
            Add-Problem -Problems $problems -Message 'case ids must be present and unique'
            continue
        }
        $caseById[$caseId] = $case

        if (-not $expectedById.ContainsKey($caseId)) {
            Add-Problem -Problems $problems -Message ("unknown case id {0}" -f $caseId)
            continue
        }

        $expected = $expectedById[$caseId]
        if ([string]$case.group -ne [string]$expected.group) {
            Add-Problem -Problems $problems -Message ("{0} must belong to {1}" -f $caseId, $expected.group)
        }
        if (-not (Test-ExpectedStringSet -Actual @($case.requirements | ForEach-Object { [string]$_ }) -Expected $expected.requirements)) {
            Add-Problem -Problems $problems -Message ("{0} REQ coverage does not match the approved CT mapping" -f $caseId)
        }
        if (-not (Test-ExpectedStringSet -Actual @($case.acceptanceCriteria | ForEach-Object { [string]$_ }) -Expected $expected.acceptanceCriteria)) {
            Add-Problem -Problems $problems -Message ("{0} CA coverage does not match the approved CT mapping" -f $caseId)
        }

        foreach ($field in @('minimalInput', 'expectedDecision', 'contractVersion')) {
            if (-not (Test-RequiredText -Object $case -Name $field)) {
                Add-Problem -Problems $problems -Message ("{0}.{1} is required" -f $caseId, $field)
            }
        }
        if ([string]$case.contractVersion -ne [string]$CaseSet.contractSetVersion) {
            Add-Problem -Problems $problems -Message ("{0}.contractVersion must identify the corpus contract snapshot" -f $caseId)
        }

        if ($null -eq $case.sourceOracle -or @($case.sourceOracle).Count -eq 0) {
            Add-Problem -Problems $problems -Message ("{0}.sourceOracle must identify at least one source and section" -f $caseId)
        } else {
            foreach ($source in @($case.sourceOracle)) {
                if (-not (Test-RequiredText -Object $source -Name 'section')) {
                    Add-Problem -Problems $problems -Message ("{0}.sourceOracle entries require a section" -f $caseId)
                }
                $sourcePath = [string]$source.path
                Add-RepositoryReference -CaseId $caseId -Path $sourcePath -ReferenceKind 'source' -RepositoryRoot $RepositoryRoot -Problems $problems -PathCounts $PathCounts
            }
        }

        if ($null -eq $case.evaluatedOutput) {
            Add-Problem -Problems $problems -Message ("{0}.evaluatedOutput is required" -f $caseId)
        } else {
            foreach ($field in @('kind', 'summary')) {
                if (-not (Test-RequiredText -Object $case.evaluatedOutput -Name $field)) {
                    Add-Problem -Problems $problems -Message ("{0}.evaluatedOutput.{1} is required" -f $caseId, $field)
                }
            }
            $liveProperty = $case.evaluatedOutput.PSObject.Properties['liveObserved']
            if ($null -eq $liveProperty -or $liveProperty.Value -isnot [bool]) {
                Add-Problem -Problems $problems -Message ("{0}.evaluatedOutput.liveObserved must be a Boolean" -f $caseId)
            } elseif ($liveProperty.Value) {
                Add-Problem -Problems $problems -Message ("{0} cannot claim live output in this static S6 corpus" -f $caseId)
            }

            $evidencePaths = @($case.evaluatedOutput.evidencePaths)
            if ($evidencePaths.Count -eq 0) {
                Add-Problem -Problems $problems -Message ("{0}.evaluatedOutput must cite evidence paths" -f $caseId)
            }
            foreach ($evidencePath in $evidencePaths) {
                $relativePath = [string]$evidencePath
                Add-RepositoryReference -CaseId $caseId -Path $relativePath -ReferenceKind 'evidence' -RepositoryRoot $RepositoryRoot -Problems $problems -PathCounts $PathCounts
            }
        }

        if ($null -eq $case.objectiveCheck -or [string]$case.objectiveCheck.expected -ne 'PASS' -or -not (Test-RequiredText -Object $case.objectiveCheck -Name 'scope')) {
            Add-Problem -Problems $problems -Message ("{0}.objectiveCheck must state expected PASS and its limited scope" -f $caseId)
        }
        if ($null -eq $case.objectiveResult -or [string]$case.objectiveResult.status -ne 'PASS' -or -not (Test-RequiredText -Object $case.objectiveResult -Name 'basis')) {
            Add-Problem -Problems $problems -Message ("{0}.objectiveResult must record PASS and its structural-only basis" -f $caseId)
        }
        if ($null -eq $case.semanticReview -or [string]$case.semanticReview.verdict -notin @('PASS', 'FAIL', 'PENDING') -or -not (Test-RequiredText -Object $case.semanticReview -Name 'evidenceClass') -or -not (Test-RequiredText -Object $case.semanticReview -Name 'basis')) {
            Add-Problem -Problems $problems -Message ("{0}.semanticReview requires an explicit verdict, evidenceClass, and basis" -f $caseId)
        }
    }

    foreach ($caseId in $expectedById.Keys) {
        if (-not $caseById.ContainsKey($caseId)) {
            Add-Problem -Problems $problems -Message ("corpus is missing {0}" -f $caseId)
        }
    }

    if ($caseById.ContainsKey('CT1')) {
        $positive = $caseById.CT1
        if ([string]$positive.scenarioRole -ne 'positive' -or [string]$positive.semanticReview.verdict -ne 'PASS') {
            Add-Problem -Problems $problems -Message 'CT1 must remain an intact positive control with semantic PASS'
        }
    }
    if ($caseById.ContainsKey('CT3')) {
        $negative = $caseById.CT3
        if ([string]$negative.scenarioRole -ne 'negative' -or $negative.candidateHasValidIdsAndLinks -ne $true -or [string]$negative.semanticReview.verdict -ne 'FAIL') {
            Add-Problem -Problems $problems -Message 'CT3 must be a contradictory negative control with valid IDs/links and semantic FAIL'
        }
    }
    if ($caseById.ContainsKey('CT12')) {
        $direct = $caseById.CT12
        if ([string]$direct.authoritativeContext -ne 'direct' -or $direct.featureStorageIgnored -ne $true -or [string]::IsNullOrWhiteSpace([string]$direct.contextDecoy) -or [string]$direct.evaluatedOutput.integrationStatus -ne 'PENDING-S8') {
            Add-Problem -Problems $problems -Message 'CT12 must preserve direct context, ignored feature storage, its context decoy, and pending integrated proof'
        }
    }
    if ($caseById.ContainsKey('CT13')) {
        $orchestrated = $caseById.CT13
        if ([string]$orchestrated.authoritativeContext -ne 'orchestrated' -or [string]::IsNullOrWhiteSpace([string]$orchestrated.contextDecoy) -or [string]$orchestrated.evaluatedOutput.integrationStatus -ne 'PENDING-S8') {
            Add-Problem -Problems $problems -Message 'CT13 must preserve orchestrated context despite a decoy and pending integrated proof'
        }
    }

    return ,$problems
}

if (-not (Test-Path -LiteralPath $CaseSetPath -PathType Leaf)) {
    Write-Host ("Missing semantic coverage corpus: {0}" -f $CaseSetPath) -ForegroundColor Red
    exit 2
}

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$caseSet = $null
try {
    $caseSet = Get-Content -LiteralPath $CaseSetPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Host ("Invalid semantic coverage JSON: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 2
}

$pathCounts = @{
    Total = 0
    RequiredPresent = 0
    FeatureLocalPresent = 0
    FeatureLocalUnavailable = 0
    RequiredMissing = 0
}
$problems = Get-SddSemanticCoverageProblems -CaseSet $caseSet -RepositoryRoot $repositoryRoot -PathCounts $pathCounts
if ($problems.Count -gt 0) {
    foreach ($problem in $problems) {
        Write-Host ("ObjectiveCorpusProblem: {0}" -f $problem) -ForegroundColor Red
    }
    Write-RepositoryReferenceSummary -PathCounts $pathCounts
    Write-Host ("ObjectiveCorpusIntegrity: FAIL ({0} scenarios)" -f @($caseSet.cases).Count) -ForegroundColor Red
    Write-Host 'Path presence reflects this checkout only; semantic source/evidence was not revalidated by this structural assertion.'
    exit 1
}

Write-RepositoryReferenceSummary -PathCounts $pathCounts
Write-Host ("ObjectiveCorpusIntegrity: PASS ({0} scenarios; CT1-CT13; G1-G4; structural corpus checks)" -f @($caseSet.cases).Count) -ForegroundColor Green
foreach ($case in @($caseSet.cases | Sort-Object { [int]([string]$_.id -replace '^CT', '') })) {
    Write-Host ("ObjectiveCorpusRecord: PASS ({0}; group={1}; objectiveResult={2}; semanticReview={3}; evidenceClass={4})" -f $case.id, $case.group, $case.objectiveResult.status, $case.semanticReview.verdict, $case.semanticReview.evidenceClass)
}
Write-Host 'SemanticReview: recorded manual judgments only; CT3 must remain FAIL despite valid IDs/links.'
Write-Host 'Path presence reflects this checkout only; feature-local absences are unavailable references, and semantic source/evidence was not revalidated.'
Write-Host 'LiveOutput: none; static corpus checks do not establish model, host, or integrated workflow execution.'
exit 0
