#Requires -Version 5.1
# Tests:
#   Should_Pass_When_ValidPrdFixture
#   Should_Fail_When_PrdMissingReq
#   Should_Fail_When_PrdMissingAcceptance
#   Should_Pass_When_ValidPlanFixture
#   Should_Fail_When_PlanOmitsReq
#   Should_Pass_When_SkillsWireValidateScripts
#
# REQ-003 / CA2 / RNF-001: structural validate-prd / validate-plan with fixtures.
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
    Write-Fail -TestName 'Assert-ValidatePrdPlanPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-ValidatePrdPlanPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$validatePrdName = $script:ToolkitConstant.ValidatePrdScriptName
$validatePlanName = $script:ToolkitConstant.ValidatePlanScriptName
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir

$validatePrdPath = Join-Path $scriptDir $validatePrdName
$validatePlanPath = Join-Path $scriptDir $validatePlanName
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $validatePrdPath)) {
    Write-Fail -TestName 'Assert-ValidatePrdPlanPreconditions' -Reason ("missing {0}" -f $validatePrdName)
}
if (-not (Test-Path -LiteralPath $validatePlanPath)) {
    Write-Fail -TestName 'Assert-ValidatePrdPlanPreconditions' -Reason ("missing {0}" -f $validatePlanName)
}
if (-not (Test-Path -LiteralPath $fixturesRoot)) {
    Write-Fail -TestName 'Assert-ValidatePrdPlanPreconditions' -Reason ("missing fixtures dir {0}" -f $fixturesRel)
}

function Get-FixturePath {
    param([Parameter(Mandatory = $true)][string] $RelativeUnderFixtures)
    $full = Join-Path $fixturesRoot ($RelativeUnderFixtures -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-ValidatePrdPlanPreconditions' -Reason ("missing fixture {0}" -f $RelativeUnderFixtures)
    }
    return $full
}

# --- PRD fixtures ---

$validPrd = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePrdFixtureValidRelativePath
$validPrdResult = Invoke-Validator -ScriptPath $validatePrdPath -Arguments @{ Path = $validPrd }
if ($validPrdResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ValidPrdFixture' -Reason ("expected exit 0, got {0}. {1}" -f $validPrdResult.ExitCode, $validPrdResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidPrdFixture'

$noReq = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePrdFixtureInvalidNoReqRelativePath
$noReqResult = Invoke-Validator -ScriptPath $validatePrdPath -Arguments @{ Path = $noReq }
if ($noReqResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_PrdMissingReq' -Reason 'expected non-zero exit for PRD without REQ ids'
}
Write-Pass -TestName 'Should_Fail_When_PrdMissingReq'

$noAc = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePrdFixtureInvalidNoAcRelativePath
$noAcResult = Invoke-Validator -ScriptPath $validatePrdPath -Arguments @{ Path = $noAc }
if ($noAcResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_PrdMissingAcceptance' -Reason 'expected non-zero exit for PRD without CA headings'
}
Write-Pass -TestName 'Should_Fail_When_PrdMissingAcceptance'

# --- PLAN fixtures ---

$validPlan = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePlanFixtureValidRelativePath
$companionPrd = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePlanFixtureCompanionPrdRelativePath
Push-Location $repoRoot
try {
    $validPlanResult = Invoke-Validator -ScriptPath $validatePlanPath -Arguments @{
        Path    = $validPlan
        PrdPath = $companionPrd
    }
}
finally {
    Pop-Location
}
if ($validPlanResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ValidPlanFixture' -Reason ("expected exit 0, got {0}. {1}" -f $validPlanResult.ExitCode, $validPlanResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidPlanFixture'

$missingReqPlan = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidatePlanFixtureInvalidMissingReqRelativePath
Push-Location $repoRoot
try {
    $missingReqResult = Invoke-Validator -ScriptPath $validatePlanPath -Arguments @{
        Path    = $missingReqPlan
        PrdPath = $companionPrd
    }
}
finally {
    Pop-Location
}
if ($missingReqResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_PlanOmitsReq' -Reason 'expected non-zero exit when PLAN omits a PRD REQ'
}
Write-Pass -TestName 'Should_Fail_When_PlanOmitsReq'

# --- Skill wiring (call path unchanged; validate before advance) ---

$wiringPaths = $script:ToolkitConstant.ValidatePrdPlanSkillWiringRelativePaths
foreach ($rel in $wiringPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireValidateScripts' -Reason ("missing skill file {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    $needsPrd = $rel -match 'sdd-spec'
    $needsPlan = $rel -match 'sdd-plan'
    if ($needsPrd -and ($text -notmatch 'validate-prd')) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireValidateScripts' -Reason ("{0} must reference validate-prd" -f $rel)
    }
    if ($needsPlan -and ($text -notmatch 'validate-plan')) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireValidateScripts' -Reason ("{0} must reference validate-plan" -f $rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_SkillsWireValidateScripts'

Write-Host 'Assert-ValidatePrdPlan: all checks passed.'
exit 0
