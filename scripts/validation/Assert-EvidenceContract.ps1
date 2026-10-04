#Requires -Version 5.1
# Tests:
#   Should_Pass_When_EvidenceContractPresent
#   Should_Pass_When_ValidEvidenceFixture_Cheap
#   Should_Fail_When_CheapWithZeroEvidence
#   Should_Pass_When_LevelOffSkipsGate
#   Should_Pass_When_SkillsWireEvidenceContract
#   Should_Pass_When_VerifierForbidsO3Parallelism
#
# REQ-005 / CA4: EVD/ + STATE.md + evidence-or-zero levels; verifier != O3 parallel.
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

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter(Mandatory = $true)][hashtable] $Arguments
    )
    $output = & $ScriptPath @Arguments 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 0
    }
    return [PSCustomObject]@{
        ExitCode = [int]$code
        Output   = $output
    }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-EvidenceContractPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-EvidenceContractPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$contractRel = $script:ToolkitConstant.EvidenceContractGuideRelativePath
$stateTemplateRel = $script:ToolkitConstant.StateTemplateRelativePath
$evdTemplateRel = $script:ToolkitConstant.EvdTemplateReadmeRelativePath
$validateName = $script:ToolkitConstant.ValidateEvidenceScriptName
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir

$contractPath = Join-Path $repoRoot ($contractRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$stateTemplatePath = Join-Path $repoRoot ($stateTemplateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$evdTemplatePath = Join-Path $repoRoot ($evdTemplateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validatePath = Join-Path $scriptDir $validateName
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_EvidenceContractPresent' -Reason ("missing guide {0}" -f $contractRel)
}
if (-not (Test-Path -LiteralPath $stateTemplatePath)) {
    Write-Fail -TestName 'Should_Pass_When_EvidenceContractPresent' -Reason ("missing template {0}" -f $stateTemplateRel)
}
if (-not (Test-Path -LiteralPath $evdTemplatePath)) {
    Write-Fail -TestName 'Should_Pass_When_EvidenceContractPresent' -Reason ("missing template {0}" -f $evdTemplateRel)
}
if (-not (Test-Path -LiteralPath $validatePath)) {
    Write-Fail -TestName 'Should_Pass_When_EvidenceContractPresent' -Reason ("missing {0}" -f $validateName)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
$requiredContractMarkers = @(
    'features/NNN-slug/{USnn|TSnn}/EVD/',
    'features/NNN-slug/{USnn|TSnn}/STATE.md',
    'StoryRoot',
    'PlanPath',
    'StoryPath',
    'historical feature-root evidence',
    'off',
    'cheap',
    'standard',
    'strict',
    'evidence-or-zero',
    'O3',
    'validate-evidence'
)
foreach ($marker in $requiredContractMarkers) {
    if ($contractText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_EvidenceContractPresent' -Reason ("guide missing marker '{0}'" -f $marker)
    }
}

$stateTemplateText = Get-Content -LiteralPath $stateTemplatePath -Raw -Encoding UTF8
if ($stateTemplateText -notmatch '(?i)AC\s*.{1,3}\s*evidence matrix') {
    Write-Fail -TestName 'Should_Pass_When_EvidenceContractPresent' -Reason 'STATE template missing AC evidence matrix heading'
}
if ($stateTemplateText -notmatch '(?i)Evidence level') {
    Write-Fail -TestName 'Should_Pass_When_EvidenceContractPresent' -Reason 'STATE template missing Evidence level field'
}
Write-Pass -TestName 'Should_Pass_When_EvidenceContractPresent'

function Get-FixtureRoot {
    param([Parameter(Mandatory = $true)][string] $RelativeUnderFixtures)
    $full = Join-Path $fixturesRoot ($RelativeUnderFixtures -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-EvidenceContractPreconditions' -Reason ("missing fixture {0}" -f $RelativeUnderFixtures)
    }
    return $full
}

$validFixtureBase = Get-FixtureRoot -RelativeUnderFixtures $script:ToolkitConstant.ValidateEvidenceFixtureValidRelativeDir
$validRoot = Join-Path $validFixtureBase 'features/000-fixture-evidence/TS01'
$validResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ StoryRoot = $validRoot; RepoPath = $validFixtureBase; Level = 'cheap' }
if ($validResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ValidEvidenceFixture_Cheap' -Reason ("expected exit 0, got {0}. {1}" -f $validResult.ExitCode, $validResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidEvidenceFixture_Cheap'

$zeroFixtureBase = Get-FixtureRoot -RelativeUnderFixtures $script:ToolkitConstant.ValidateEvidenceFixtureInvalidZeroRelativeDir
$zeroRoot = Join-Path $zeroFixtureBase 'features/000-fixture-evidence-zero/TS01'
$zeroResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ StoryRoot = $zeroRoot; RepoPath = $zeroFixtureBase; Level = 'cheap' }
if ($zeroResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_CheapWithZeroEvidence' -Reason 'expected non-zero exit when cheap has zero usable evidence'
}
Write-Pass -TestName 'Should_Fail_When_CheapWithZeroEvidence'

$offResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ StoryRoot = $zeroRoot; RepoPath = $zeroFixtureBase; Level = 'off' }
if ($offResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_LevelOffSkipsGate' -Reason ("expected exit 0 for level=off, got {0}" -f $offResult.ExitCode)
}
Write-Pass -TestName 'Should_Pass_When_LevelOffSkipsGate'

$featureRoot = Split-Path -Parent $validRoot
$featureResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ StoryRoot = $featureRoot; RepoPath = $validFixtureBase; Level = 'off' }
if ($featureResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_FeatureRootUsedAsStoryRoot' -Reason 'feature-root fallback must be rejected even when level=off'
}
Write-Pass -TestName 'Should_Fail_When_FeatureRootUsedAsStoryRoot'

$storyPathResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ StoryPath = (Join-Path $validRoot 'STORY.md'); RepoPath = $validFixtureBase; Level = 'cheap' }
if ($storyPathResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_StoryPathDerivesStoryRoot' -Reason ("expected exit 0, got {0}. {1}" -f $storyPathResult.ExitCode, $storyPathResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_StoryPathDerivesStoryRoot'

$wiringPaths = $script:ToolkitConstant.EvidenceContractSkillWiringRelativePaths
foreach ($rel in $wiringPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireEvidenceContract' -Reason ("missing skill file {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch 'EVD|STATE\.md|EVD-STATE-CONTRACT|evidence-or-zero|validate-evidence') {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireEvidenceContract' -Reason ("{0} must reference EVD/STATE/evidence contract" -f $rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_SkillsWireEvidenceContract'

$verifierPaths = $script:ToolkitConstant.EvidenceVerifierNoO3RelativePaths
$verifierPhrase = '(?i)(Verifier.{0,6}O3|must not use O3|does not use O3|not use O3.{0,40}parallel|evidence verification.{0,80}sequential|verifier.{0,40}not.{0,40}O3)'
foreach ($rel in $verifierPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_VerifierForbidsO3Parallelism' -Reason ("missing {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch $verifierPhrase) {
        Write-Fail -TestName 'Should_Pass_When_VerifierForbidsO3Parallelism' -Reason ("{0} must state verifier does not use O3 parallelism" -f $rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_VerifierForbidsO3Parallelism'

Write-Host 'Assert-EvidenceContract: all checks passed.'
exit 0
