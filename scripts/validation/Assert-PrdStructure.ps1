#Requires -Version 5.1
# Tests:
#   Should_Pass_When_PrdTemplateHasRequiredSections
#   Should_Pass_When_ValidPrdFixtureHasSections
#   Should_Fail_When_PrdMissingRequiredSections
#   Should_Pass_When_SkillsWireReqIds
#
# REQ-ID / structural gates: PRD template + validate-prd section checks.
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
    Write-Fail -TestName 'Assert-PrdStructurePreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-PrdStructurePreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$templateRel = $script:ToolkitConstant.PrdStructureTemplateRelativePath
$validatePrdName = $script:ToolkitConstant.ValidatePrdScriptName
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir
$sectionMarkers = @($script:ToolkitConstant.PrdRequiredSectionMarkers)
$skillPaths = @($script:ToolkitConstant.PrdStructureSkillWiringRelativePaths)

$templatePath = Join-Path $repoRoot ($templateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validatePrdPath = Join-Path $scriptDir $validatePrdName
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $templatePath)) {
    Write-Fail -TestName 'Assert-PrdStructurePreconditions' -Reason ("missing template {0}" -f $templateRel)
}
if (-not (Test-Path -LiteralPath $validatePrdPath)) {
    Write-Fail -TestName 'Assert-PrdStructurePreconditions' -Reason ("missing {0}" -f $validatePrdName)
}

function Get-FixturePath {
    param([Parameter(Mandatory = $true)][string] $RelativeUnderFixtures)
    $full = Join-Path $fixturesRoot ($RelativeUnderFixtures -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-PrdStructurePreconditions' -Reason ("missing fixture {0}" -f $RelativeUnderFixtures)
    }
    return $full
}

$templateTest = 'Should_Pass_When_PrdTemplateHasRequiredSections'
$templateText = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
foreach ($marker in $sectionMarkers) {
    if ($templateText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName $templateTest -Reason ("{0} missing section marker: {1}" -f $templateRel, $marker)
    }
}
Write-Pass -TestName $templateTest

$validPrd = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePrdFixtureValidRelativePath
$validResult = Invoke-Validator -ScriptPath $validatePrdPath -Arguments @{ Path = $validPrd }
if ($validResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ValidPrdFixtureHasSections' -Reason ("expected exit 0, got {0}. {1}" -f $validResult.ExitCode, $validResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidPrdFixtureHasSections'

$invalidSections = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePrdFixtureInvalidNoSectionsRelativePath
$invalidResult = Invoke-Validator -ScriptPath $validatePrdPath -Arguments @{ Path = $invalidSections }
if ($invalidResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_PrdMissingRequiredSections' -Reason 'expected non-zero exit for PRD missing required sections'
}
Write-Pass -TestName 'Should_Fail_When_PrdMissingRequiredSections'

$skillTest = 'Should_Pass_When_SkillsWireReqIds'
foreach ($rel in $skillPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $skillTest -Reason ("missing skill file {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch 'REQ-NNN') {
        Write-Fail -TestName $skillTest -Reason ("{0} must reference REQ-NNN" -f $rel)
    }
    if ($text -notmatch 'validate-prd') {
        Write-Fail -TestName $skillTest -Reason ("{0} must reference validate-prd" -f $rel)
    }
}
Write-Pass -TestName $skillTest

Write-Host 'Assert-PrdStructure: all checks passed.'
exit 0
