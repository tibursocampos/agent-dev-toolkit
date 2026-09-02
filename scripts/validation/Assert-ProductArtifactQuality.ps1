#Requires -Version 5.1
# Tests:
#   Should_Fail_When_FeatureMissingGoals_CT1
#   Should_Reject_When_TitleTaskShaped_CT2
#   Should_Pass_When_StoryAcBudgetOk_CT3
#   Should_Fail_When_CapExceededWithoutRationale_CT4
#   Should_Pass_When_EvidenceHonestlyOmitted_CT6
#   Should_Pass_When_FixturesAreSynthetic_RNF001
#   Should_Pass_When_StorySynthesisDocumentsGates
#
# REQ-007 / CA5: golden fixtures + product artifact quality Assert (CT1–CT4, CT6).
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-ProductArtifactQualityPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-ProductArtifactQualityPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$fixturesRel = $script:ToolkitConstant.ProductArtifactQualityFixturesRelativeDir
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$maturityCap = [int]$script:ToolkitConstant.ProductArtifactQualityMaturityCap
$minProductDepth = [int]$script:ToolkitConstant.ProductArtifactQualityMinProductDepthBand
$evidenceOmittedMarker = $script:ToolkitConstant.ProductArtifactQualityEvidenceOmittedMarker
$taskShapedTitlePattern = $script:ToolkitConstant.ProductArtifactQualityTaskShapedTitlePattern
$capRationalePattern = $script:ToolkitConstant.ProductArtifactQualityCapRationalePattern
$storySynthesisRel = $script:ToolkitConstant.ProductArtifactQualityStorySynthesisRelativePath

function Get-FixtureFile {
    param(
        [Parameter(Mandatory = $true)][string] $RelativeUnderFixtures,
        [Parameter(Mandatory = $true)][string] $FileName
    )
    $dir = Join-Path $fixturesRoot ($RelativeUnderFixtures -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $full = Join-Path $dir $FileName
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-ProductArtifactQualityPreconditions' -Reason ("missing fixture {0}/{1}" -f $RelativeUnderFixtures, $FileName)
    }
    return $full
}

function Get-SectionBody {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Heading
    )
    $escaped = [regex]::Escape($Heading)
    $pattern = "(?ims)^##\s+$escaped\s*\r?\n(?<body>.*?)(?=^##\s+|\z)"
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups['body'].Value
}

function Test-NonEmptyProse {
    param([AllowNull()][string] $Body)
    if ([string]::IsNullOrWhiteSpace($Body)) {
        return $false
    }
    $stripped = ($Body -replace '(?m)^\s*\|.*\|\s*$', '' -replace '(?m)^\s*[-*]\s*$', '').Trim()
    return -not [string]::IsNullOrWhiteSpace($stripped)
}

function Test-NonEmptyBulletList {
    param([AllowNull()][string] $Body)
    if ([string]::IsNullOrWhiteSpace($Body)) {
        return $false
    }
    return [bool]($Body -match '(?m)^\s*[-*]\s+\S+')
}

function Get-MissingFeatureDepthFields {
    param([Parameter(Mandatory = $true)][string] $FeatureText)
    $missing = New-Object System.Collections.Generic.List[string]
    $problem = Get-SectionBody -Text $FeatureText -Heading 'Problem'
    if (-not (Test-NonEmptyProse -Body $problem)) {
        [void]$missing.Add('Problem')
    }
    $goals = Get-SectionBody -Text $FeatureText -Heading 'Goals'
    if (-not (Test-NonEmptyBulletList -Body $goals)) {
        [void]$missing.Add('Goals')
    }
    $nonGoals = Get-SectionBody -Text $FeatureText -Heading 'Non-goals'
    if (-not (Test-NonEmptyBulletList -Body $nonGoals)) {
        [void]$missing.Add('Non-goals')
    }
    # Unary comma keeps 0/1-element results as Object[] under StrictMode callers.
    return , @($missing.ToArray())
}

function Test-TaskShapedTitle {
    param([Parameter(Mandatory = $true)][string] $Title)
    return [bool]($Title -match $taskShapedTitlePattern)
}

function Get-HistoriaRowCount {
    param([Parameter(Mandatory = $true)][string] $FeatureText)
    $body = Get-SectionBody -Text $FeatureText -Heading 'Histórias'
    if ($null -eq $body) {
        $body = Get-SectionBody -Text $FeatureText -Heading 'Historias'
    }
    if ($null -eq $body) {
        return 0
    }
    $count = 0
    foreach ($line in ($body -split '\r?\n')) {
        if ($line -match '^\|\s*US\d+\s*\|' -or $line -match '^\|\s*TS\d+\s*\|') {
            $count++
        }
    }
    return $count
}

function Test-HasExplicitCapRationale {
    param([Parameter(Mandatory = $true)][string] $FeatureText)
    return [bool]($FeatureText -match $capRationalePattern)
}

function Test-AcBudgetComplete {
    param([Parameter(Mandatory = $true)][string] $StoryText)
    $slots = @('Happy', 'Rule\s*/\s*edge', 'Failure')
    foreach ($slot in $slots) {
        $headingPattern = "(?ims)^###\s+$slot\s*\r?\n(?<body>.*?)(?=^###\s+|^##\s+|\z)"
        $match = [regex]::Match($StoryText, $headingPattern)
        if (-not $match.Success) {
            return $false
        }
        $body = $match.Groups['body'].Value
        if ($body -notmatch '(?im)^\s*(Então|Then)\s+\S+') {
            return $false
        }
    }
    return $true
}

function Get-ProductDepthScore {
    param([Parameter(Mandatory = $true)][string] $StoryText)
    $match = [regex]::Match($StoryText, '(?im)^\|\s*Product depth\s*\|\s*(\d+)\s*\|')
    if (-not $match.Success) {
        return $null
    }
    return [int]$match.Groups[1].Value
}

function Test-EvidenceHonestOmit {
    param([Parameter(Mandatory = $true)][string] $StoryText)
    if ($StoryText -match [regex]::Escape($evidenceOmittedMarker)) {
        return $true
    }
    $evidence = Get-SectionBody -Text $StoryText -Heading 'Evidence'
    if ($null -eq $evidence) {
        return $true
    }
    return -not (Test-NonEmptyProse -Body ($evidence -replace '(?i)\*\*Evidence\*\*', '' -replace '\|', ' '))
}

# --- CT1: incomplete FEATURE must fail naming Goals ---
$ct1Path = Get-FixtureFile -RelativeUnderFixtures $script:ToolkitConstant.ProductArtifactQualityCt1RelativeDir -FileName 'FEATURE.md'
$ct1Text = Get-Content -LiteralPath $ct1Path -Raw -Encoding UTF8
$ct1Missing = Get-MissingFeatureDepthFields -FeatureText $ct1Text
if ($ct1Missing.Count -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_FeatureMissingGoals_CT1' -Reason 'expected FEATURE depth failure; fixture unexpectedly passed'
}
if ($ct1Missing -notcontains 'Goals') {
    Write-Fail -TestName 'Should_Fail_When_FeatureMissingGoals_CT1' -Reason ("expected missing field Goals; got: {0}" -f ($ct1Missing -join ', '))
}
Write-Pass -TestName 'Should_Fail_When_FeatureMissingGoals_CT1'

# --- CT2: task-shaped title rejected; outcome-shaped accepted ---
$ct2Path = Get-FixtureFile -RelativeUnderFixtures $script:ToolkitConstant.ProductArtifactQualityCt2RelativeDir -FileName 'candidates.md'
$ct2Text = Get-Content -LiteralPath $ct2Path -Raw -Encoding UTF8
$taskTitle = $script:ToolkitConstant.ProductArtifactQualityCt2TaskTitle
$outcomeTitle = $script:ToolkitConstant.ProductArtifactQualityCt2OutcomeTitle
if ($ct2Text -notmatch [regex]::Escape($taskTitle)) {
    Write-Fail -TestName 'Should_Reject_When_TitleTaskShaped_CT2' -Reason ("candidates fixture must include '{0}'" -f $taskTitle)
}
if ($ct2Text -notmatch [regex]::Escape($outcomeTitle)) {
    Write-Fail -TestName 'Should_Reject_When_TitleTaskShaped_CT2' -Reason ("candidates fixture must include '{0}'" -f $outcomeTitle)
}
if (-not (Test-TaskShapedTitle -Title $taskTitle)) {
    Write-Fail -TestName 'Should_Reject_When_TitleTaskShaped_CT2' -Reason ("expected task-shaped reject for '{0}'" -f $taskTitle)
}
if (Test-TaskShapedTitle -Title $outcomeTitle) {
    Write-Fail -TestName 'Should_Reject_When_TitleTaskShaped_CT2' -Reason ("outcome-shaped title incorrectly flagged: '{0}'" -f $outcomeTitle)
}
Write-Pass -TestName 'Should_Reject_When_TitleTaskShaped_CT2'

# --- CT3: AC budget + Product depth band ---
$ct3Path = Get-FixtureFile -RelativeUnderFixtures $script:ToolkitConstant.ProductArtifactQualityCt3RelativeDir -FileName 'STORY.md'
$ct3Text = Get-Content -LiteralPath $ct3Path -Raw -Encoding UTF8
if (-not (Test-AcBudgetComplete -StoryText $ct3Text)) {
    Write-Fail -TestName 'Should_Pass_When_StoryAcBudgetOk_CT3' -Reason 'golden STORY must include Happy + Rule/edge + Failure with observable Then'
}
$ct3Depth = Get-ProductDepthScore -StoryText $ct3Text
if ($null -eq $ct3Depth -or $ct3Depth -lt $minProductDepth) {
    Write-Fail -TestName 'Should_Pass_When_StoryAcBudgetOk_CT3' -Reason ("Product depth must be >= {0}; got {1}" -f $minProductDepth, $ct3Depth)
}
if ($ct3Text -notmatch '(?im)\*\*Who\*\*' -or $ct3Text -notmatch '(?im)\*\*Job\*\*' -or $ct3Text -notmatch '(?im)\*\*Outcome\*\*') {
    Write-Fail -TestName 'Should_Pass_When_StoryAcBudgetOk_CT3' -Reason 'golden US STORY must include Who/Job/Outcome'
}
Write-Pass -TestName 'Should_Pass_When_StoryAcBudgetOk_CT3'

# --- CT4: cap >4 without rationale ---
$ct4Path = Get-FixtureFile -RelativeUnderFixtures $script:ToolkitConstant.ProductArtifactQualityCt4RelativeDir -FileName 'FEATURE.md'
$ct4Text = Get-Content -LiteralPath $ct4Path -Raw -Encoding UTF8
$ct4Count = Get-HistoriaRowCount -FeatureText $ct4Text
if ($ct4Count -le $maturityCap) {
    Write-Fail -TestName 'Should_Fail_When_CapExceededWithoutRationale_CT4' -Reason ("fixture must have >{0} US/TS rows; got {1}" -f $maturityCap, $ct4Count)
}
if (Test-HasExplicitCapRationale -FeatureText $ct4Text) {
    Write-Fail -TestName 'Should_Fail_When_CapExceededWithoutRationale_CT4' -Reason 'CT4 fixture must NOT include explicit >4 split rationale'
}
$ct4CapFail = ($ct4Count -gt $maturityCap) -and -not (Test-HasExplicitCapRationale -FeatureText $ct4Text)
if (-not $ct4CapFail) {
    Write-Fail -TestName 'Should_Fail_When_CapExceededWithoutRationale_CT4' -Reason 'expected cap gate failure without rationale'
}
Write-Pass -TestName 'Should_Fail_When_CapExceededWithoutRationale_CT4'

# --- CT6: honest Evidence omission accepted ---
$ct6Path = Get-FixtureFile -RelativeUnderFixtures $script:ToolkitConstant.ProductArtifactQualityCt6RelativeDir -FileName 'STORY.md'
$ct6Text = Get-Content -LiteralPath $ct6Path -Raw -Encoding UTF8
if (-not (Test-EvidenceHonestOmit -StoryText $ct6Text)) {
    Write-Fail -TestName 'Should_Pass_When_EvidenceHonestlyOmitted_CT6' -Reason 'CT6 must mark Evidence omitted or leave Evidence empty'
}
if (-not (Test-AcBudgetComplete -StoryText $ct6Text)) {
    Write-Fail -TestName 'Should_Pass_When_EvidenceHonestlyOmitted_CT6' -Reason 'CT6 still requires AC budget so Product depth can pass without fabricated Evidence'
}
$ct6Depth = Get-ProductDepthScore -StoryText $ct6Text
if ($null -eq $ct6Depth -or $ct6Depth -lt $minProductDepth) {
    Write-Fail -TestName 'Should_Pass_When_EvidenceHonestlyOmitted_CT6' -Reason ("Product depth band must hold with omit; got {0}" -f $ct6Depth)
}
Write-Pass -TestName 'Should_Pass_When_EvidenceHonestlyOmitted_CT6'

# --- RNF-001: synthetic fixtures only ---
$fixtureFiles = Get-ChildItem -LiteralPath $fixturesRoot -Recurse -File -Filter '*.md'
foreach ($file in $fixtureFiles) {
    $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($raw -notmatch '(?i)synthetic') {
        Write-Fail -TestName 'Should_Pass_When_FixturesAreSynthetic_RNF001' -Reason ("{0} must declare synthetic" -f $file.FullName.Substring($repoRoot.Length).TrimStart('\', '/'))
    }
    if ($raw -match '(?i)\b(cpf|cnpj|password|secret|api[_-]?key)\b\s*[:=]') {
        Write-Fail -TestName 'Should_Pass_When_FixturesAreSynthetic_RNF001' -Reason ("possible secret/PII marker in {0}" -f $file.Name)
    }
    if ($raw -match '(?i)[a-z0-9._%+-]+@(?!example\.com)[a-z0-9.-]+\.[a-z]{2,}') {
        Write-Fail -TestName 'Should_Pass_When_FixturesAreSynthetic_RNF001' -Reason ("non-example email in fixture {0}" -f $file.Name)
    }
}
Write-Pass -TestName 'Should_Pass_When_FixturesAreSynthetic_RNF001'

# --- Gate docs still present in story-synthesis (complement StorySizing; do not duplicate) ---
$synthesisPath = Join-Path $repoRoot ($storySynthesisRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $synthesisPath)) {
    Write-Fail -TestName 'Should_Pass_When_StorySynthesisDocumentsGates' -Reason ("missing {0}" -f $storySynthesisRel)
}
$synthesisText = Get-Content -LiteralPath $synthesisPath -Raw -Encoding UTF8
$requiredMarkers = @(
    'Gate A',
    'Gate B',
    'Gate C',
    'TE01',
    'TE02',
    'anti-task-shatter',
    'Product depth',
    'omitted'
)
foreach ($marker in $requiredMarkers) {
    if ($synthesisText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_StorySynthesisDocumentsGates' -Reason ("story-synthesis.md missing marker '{0}'" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_StorySynthesisDocumentsGates'

Write-Host 'Assert-ProductArtifactQuality: ALL PASS'
exit 0
