#Requires -Version 5.1
# Tests:
#   Should_Pass_When_PlanAndPrdTemplatesHaveExecutionPolicy
#   Should_Pass_When_SddSkillsWireExecutionPolicy
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
    Write-Fail -TestName 'Assert-PlanExecutionPolicyPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-PlanExecutionPolicyPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$heading = $script:ToolkitConstant.ExecutionPolicyHeadingMarker
$templatePaths = @($script:ToolkitConstant.ExecutionPolicyTemplateRelativePaths)
$skillPaths = @($script:ToolkitConstant.ExecutionPolicySkillWiringRelativePaths)

$templateTest = 'Should_Pass_When_PlanAndPrdTemplatesHaveExecutionPolicy'
foreach ($rel in $templatePaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $templateTest -Reason ("missing template {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch [regex]::Escape($heading)) {
        Write-Fail -TestName $templateTest -Reason ("{0} missing {1}" -f $rel, $heading)
    }
}
Write-Pass -TestName $templateTest

$skillTest = 'Should_Pass_When_SddSkillsWireExecutionPolicy'
foreach ($rel in $skillPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $skillTest -Reason ("missing skill {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch 'Execution policy') {
        Write-Fail -TestName $skillTest -Reason ("{0} must reference Execution policy" -f $rel)
    }
}
Write-Pass -TestName $skillTest

Write-Host 'Assert-PlanExecutionPolicy: ALL PASS'
exit 0
