#Requires -Version 5.1
# Tests:
#   Should_Pass_When_ChangeContractPresent
#   Should_Pass_When_ValidChangeFixture
#   Should_Fail_When_ChangeMissingSections
#   Should_Pass_When_SkillsWireChangeContract
#   Should_Pass_When_TasksPolicyDocumented
#
# REQ-004 / CA3: brownfield CHANGE.md + TASKS≥medium + current specs (no openspec/).
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
    Write-Fail -TestName 'Assert-ChangeContractPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-ChangeContractPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$contractRel = $script:ToolkitConstant.ChangeContractGuideRelativePath
$templateRel = $script:ToolkitConstant.ChangeTemplateRelativePath
$validateName = $script:ToolkitConstant.ValidateChangeScriptName
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir

$contractPath = Join-Path $repoRoot ($contractRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$templatePath = Join-Path $repoRoot ($templateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validatePath = Join-Path $scriptDir $validateName
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason ("missing guide {0}" -f $contractRel)
}
if (-not (Test-Path -LiteralPath $templatePath)) {
    Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason ("missing template {0}" -f $templateRel)
}
if (-not (Test-Path -LiteralPath $validatePath)) {
    Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason ("missing {0}" -f $validateName)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
$requiredContractMarkers = @(
    'features/NNN-slug/CHANGE.md',
    'ADDED',
    'MODIFIED',
    'REMOVED',
    'memory-bank',
    'openspec',
    'trivial',
    'medium',
    'orchestrate-analyze',
    'orchestrate-deliver',
    'orchestrate-develop',
    'explore',
    'apply',
    'greenfield'
)
foreach ($marker in $requiredContractMarkers) {
    if ($contractText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason ("guide missing marker '{0}'" -f $marker)
    }
}

$templateText = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
foreach ($section in @('## ADDED', '## MODIFIED', '## REMOVED')) {
    if ($templateText -notmatch [regex]::Escape($section)) {
        Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason ("template missing {0}" -f $section)
    }
}
Write-Pass -TestName 'Should_Pass_When_ChangeContractPresent'

function Get-FixturePath {
    param([Parameter(Mandatory = $true)][string] $RelativeUnderFixtures)
    $full = Join-Path $fixturesRoot ($RelativeUnderFixtures -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-ChangeContractPreconditions' -Reason ("missing fixture {0}" -f $RelativeUnderFixtures)
    }
    return $full
}

$validChange = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidateChangeFixtureValidRelativePath
$validResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ Path = $validChange }
if ($validResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ValidChangeFixture' -Reason ("expected exit 0, got {0}. {1}" -f $validResult.ExitCode, $validResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidChangeFixture'

$invalidChange = Get-FixturePath -RelativeUnderFixtures $script:ToolkitConstant.ValidateChangeFixtureInvalidNoSectionsRelativePath
$invalidResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ Path = $invalidChange }
if ($invalidResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_ChangeMissingSections' -Reason 'expected non-zero exit when CHANGE lacks ADDED|MODIFIED|REMOVED'
}
Write-Pass -TestName 'Should_Fail_When_ChangeMissingSections'

$wiringPaths = $script:ToolkitConstant.ChangeContractSkillWiringRelativePaths
foreach ($rel in $wiringPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireChangeContract' -Reason ("missing skill file {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch 'CHANGE\.md|CHANGE-CONTRACT') {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireChangeContract' -Reason ("{0} must reference CHANGE.md or CHANGE-CONTRACT" -f $rel)
    }
    if ($rel -match 'sdd-spec|orchestrate-deliver') {
        if ($text -notmatch '(?i)brownfield') {
            Write-Fail -TestName 'Should_Pass_When_SkillsWireChangeContract' -Reason ("{0} must mention brownfield CHANGE gate" -f $rel)
        }
        if ($text -notmatch '(?i)greenfield') {
            Write-Fail -TestName 'Should_Pass_When_SkillsWireChangeContract' -Reason ("{0} must state greenfield does not force empty CHANGE" -f $rel)
        }
    }
    if ($rel -match 'orchestrate-analyze' -and ($text -notmatch '(?i)explore')) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireChangeContract' -Reason ("{0} must document O1≈explore mental map" -f $rel)
    }
    if ($rel -match 'orchestrate-develop' -and ($text -notmatch '(?i)apply')) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireChangeContract' -Reason ("{0} must document O3≈apply mental map" -f $rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_SkillsWireChangeContract'

$tasksPaths = $script:ToolkitConstant.ChangeContractTasksPolicyRelativePaths
foreach ($rel in $tasksPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_TasksPolicyDocumented' -Reason ("missing {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch '(?i)medium') {
        Write-Fail -TestName 'Should_Pass_When_TasksPolicyDocumented' -Reason ("{0} must mention medium complexity TASKS gate" -f $rel)
    }
    if ($text -notmatch '(?i)trivial|small') {
        Write-Fail -TestName 'Should_Pass_When_TasksPolicyDocumented' -Reason ("{0} must mention trivial/small without TASKS" -f $rel)
    }
    if ($text -notmatch '(?i)TASKS') {
        Write-Fail -TestName 'Should_Pass_When_TasksPolicyDocumented' -Reason ("{0} must mention TASKS policy" -f $rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_TasksPolicyDocumented'

Write-Host 'Assert-ChangeContract: all checks passed.'
exit 0
