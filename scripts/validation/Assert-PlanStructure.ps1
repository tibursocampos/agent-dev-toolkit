#Requires -Version 5.1
# Tests:
#   Should_Pass_When_PlanTemplateHasRequiredSections
#   Should_Pass_When_ValidPlanFixtureHasSections
#   Should_Fail_When_PlanMissingRequiredSections
#   Should_Pass_When_SkillsWirePlanStructure
#
# REQ-ID / structural gates: PLAN template + validate-plan section checks.
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
    Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$templateRel = $script:ToolkitConstant.PlanStructureTemplateRelativePath
$validatePlanName = $script:ToolkitConstant.ValidatePlanScriptName
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir
$sectionMarkers = @($script:ToolkitConstant.PlanRequiredSectionMarkers)
$skillPaths = @($script:ToolkitConstant.PlanStructureSkillWiringRelativePaths)

$templatePath = Join-Path $repoRoot ($templateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validatePlanPath = Join-Path $scriptDir $validatePlanName
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $templatePath)) {
    Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing template {0}" -f $templateRel)
}
if (-not (Test-Path -LiteralPath $validatePlanPath)) {
    Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing {0}" -f $validatePlanName)
}

function Get-FixturePath {
    param([Parameter(Mandatory = $true)][string] $RelativeUnderFixtures)
    $full = Join-Path $fixturesRoot ($RelativeUnderFixtures -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing fixture {0}" -f $RelativeUnderFixtures)
    }
    return $full
}

$templateTest = 'Should_Pass_When_PlanTemplateHasRequiredSections'
$templateText = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
foreach ($marker in $sectionMarkers) {
    if ($templateText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName $templateTest -Reason ("{0} missing section marker: {1}" -f $templateRel, $marker)
    }
}
Write-Pass -TestName $templateTest

$validPlan = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePlanFixtureValidRelativePath
$companionPrd = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePlanFixtureCompanionPrdRelativePath
Push-Location $repoRoot
try {
    $validResult = Invoke-Validator -ScriptPath $validatePlanPath -Arguments @{
        Path    = $validPlan
        PrdPath = $companionPrd
    }
}
finally {
    Pop-Location
}
if ($validResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ValidPlanFixtureHasSections' -Reason ("expected exit 0, got {0}. {1}" -f $validResult.ExitCode, $validResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidPlanFixtureHasSections'

$invalidPlan = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePlanFixtureInvalidNoSectionsRelativePath
Push-Location $repoRoot
try {
    $invalidResult = Invoke-Validator -ScriptPath $validatePlanPath -Arguments @{
        Path    = $invalidPlan
        PrdPath = $companionPrd
    }
}
finally {
    Pop-Location
}
if ($invalidResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_PlanMissingRequiredSections' -Reason 'expected non-zero exit for PLAN missing required sections'
}
Write-Pass -TestName 'Should_Fail_When_PlanMissingRequiredSections'

$skillTest = 'Should_Pass_When_SkillsWirePlanStructure'
foreach ($rel in $skillPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $skillTest -Reason ("missing skill file {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch 'REQ-NNN|Mapa REQ') {
        Write-Fail -TestName $skillTest -Reason ("{0} must reference REQ mapping" -f $rel)
    }
    if ($text -notmatch 'validate-plan') {
        Write-Fail -TestName $skillTest -Reason ("{0} must reference validate-plan" -f $rel)
    }
    if ($text -notmatch 'Execution policy') {
        Write-Fail -TestName $skillTest -Reason ("{0} must reference Execution policy" -f $rel)
    }
}
Write-Pass -TestName $skillTest

Write-Host 'Assert-PlanStructure: all checks passed.'
exit 0
