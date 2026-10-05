#Requires -Version 5.1
# Tests:
#   Should_Pass_When_PlanTemplateHasRequiredSections
#   Should_Pass_When_SkillsWirePlanStructure
#
# REQ-ID / structural gates: PLAN template and skill wiring checks.
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
    Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$templateRel = $script:ToolkitConstant.PlanStructureTemplateRelativePath
$sectionMarkers = @($script:ToolkitConstant.PlanRequiredSectionMarkers)
$skillPaths = @($script:ToolkitConstant.PlanStructureSkillWiringRelativePaths)

$templatePath = Join-Path $repoRoot ($templateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $templatePath)) {
    Write-Fail -TestName 'Assert-PlanStructurePreconditions' -Reason ("missing template {0}" -f $templateRel)
}

$templateTest = 'Should_Pass_When_PlanTemplateHasRequiredSections'
$templateText = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
foreach ($marker in $sectionMarkers) {
    if ($templateText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName $templateTest -Reason ("{0} missing section marker: {1}" -f $templateRel, $marker)
    }
}
Write-Pass -TestName $templateTest

# PLAN fixture execution is centralized in Assert-ValidatePrdPlan.ps1.
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
