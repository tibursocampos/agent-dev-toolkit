#Requires -Version 5.1
# Tests:
#   Should_Pass_When_ValidMutualFixture_CT4
#   Should_Fail_When_NoMutualFixture_CT4
#   Should_Pass_When_StorageDefinesNavigationBlock
#   Should_Pass_When_TemplatesHaveRelatedHeading
#   Should_Pass_When_NoFeatureRefinementMd_OOS
#
# REQ-010 / CA3 / CT4 / CA5: NavigationBlock assert + minimal PRD<->PLAN fixtures in validate-core.
#
# Gate mode (CT4 exit codes):
#   .\Assert-NavigationBlock.ps1 -FeatureRoot <dir-with-PRD-and-PLAN>
# Meta-test mode (validate-core): omit -FeatureRoot.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $FeatureRoot = '',

    [Parameter(Mandatory = $false)]
    [string] $RepoPath = ''
)

$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

. $constantsScript

$exitOk = [int]$script:ToolkitConstant.NavigationBlockExitOk
$exitFail = [int]$script:ToolkitConstant.NavigationBlockExitFail
$exitUsage = [int]$script:ToolkitConstant.NavigationBlockExitUsage
$relatedHeading = [string]$script:ToolkitConstant.NavigationBlockRelatedHeading
$relatedSectionPattern = [string]$script:ToolkitConstant.NavigationBlockRelatedSectionPattern
$prdDirSegment = [string]$script:ToolkitConstant.NavigationBlockPrdDirSegment
$planDirSegment = [string]$script:ToolkitConstant.NavigationBlockPlanDirSegment
$planFilePrefix = [string]$script:ToolkitConstant.NavigationBlockPlanFilePrefix

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

function Write-GateUsageAndExit {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("USAGE: {0}" -f $Message)
    exit $exitUsage
}

function Resolve-RootPath {
    param(
        [Parameter(Mandatory = $true)][string] $Raw,
        [Parameter(Mandatory = $false)][string] $BaseRepo = ''
    )
    if ([string]::IsNullOrWhiteSpace($Raw)) {
        Write-GateUsageAndExit -Message 'FeatureRoot is required in gate mode.'
    }
    if ([System.IO.Path]::IsPathRooted($Raw)) {
        return [System.IO.Path]::GetFullPath($Raw)
    }
    $base = if (-not [string]::IsNullOrWhiteSpace($BaseRepo) -and (Test-Path -LiteralPath $BaseRepo)) {
        [System.IO.Path]::GetFullPath($BaseRepo)
    }
    else {
        (Get-Location).Path
    }
    return [System.IO.Path]::GetFullPath((Join-Path $base $Raw))
}

function Get-RelatedSectionText {
    param([Parameter(Mandatory = $true)][string] $Markdown)
    if ($Markdown -notmatch $relatedSectionPattern) {
        return $null
    }
    return [string]$Matches['body']
}

function Test-RelatedCitesSibling {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][string] $RelatedBody,
        [Parameter(Mandatory = $true)][string] $SiblingLeafName,
        [Parameter(Mandatory = $true)][string] $SiblingDirHint
    )
    if ([string]::IsNullOrWhiteSpace($RelatedBody)) {
        return $false
    }
    $normalized = $RelatedBody -replace '\\', '/'
    $leaf = [regex]::Escape($SiblingLeafName)
    if ($normalized -match $leaf) {
        return $true
    }
    $hint = [regex]::Escape(($SiblingDirHint -replace '\\', '/'))
    return ($normalized -match ("(?i){0}/[^`r`n|`]*{1}" -f $hint, $leaf))
}

function Find-PrdPlanPair {
    param([Parameter(Mandatory = $true)][string] $Root)
    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.md' -ErrorAction Stop)
    $prdFiles = @($files | Where-Object {
            ($_.FullName -replace '\\', '/') -match ("(?i)/{0}/" -f [regex]::Escape($prdDirSegment)) -and
            $_.Name -notlike ($planFilePrefix + '*')
        })
    $planFiles = @($files | Where-Object {
            ($_.FullName -replace '\\', '/') -match ("(?i)/{0}/" -f [regex]::Escape($planDirSegment)) -and
            $_.Name -like ($planFilePrefix + '*')
        })
    return [PSCustomObject]@{
        PrdFiles  = $prdFiles
        PlanFiles = $planFiles
    }
}

function Invoke-NavigationGate {
    param(
        [Parameter(Mandatory = $true)][string] $Root
    )
    # Use Write-Host for status (not Write-Output) so callers assigning the
    # return value do not capture status text into the exit-code pipeline.
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        Write-Host ("FAIL: FeatureRoot is not a directory: {0}" -f $Root)
        return $exitFail
    }

    $pair = Find-PrdPlanPair -Root $Root
    if ($pair.PrdFiles.Count -eq 0 -or $pair.PlanFiles.Count -eq 0) {
        # Classic omit-if-absent: do not fail when only one side exists.
        Write-Host 'Status: SKIP_PARTIAL (PRD or PLAN absent - no mutual check)'
        return $exitOk
    }

    $prd = $pair.PrdFiles[0]
    $plan = $pair.PlanFiles[0]
    $prdText = Get-Content -LiteralPath $prd.FullName -Raw -Encoding UTF8
    $planText = Get-Content -LiteralPath $plan.FullName -Raw -Encoding UTF8
    $prdRelated = Get-RelatedSectionText -Markdown $prdText
    $planRelated = Get-RelatedSectionText -Markdown $planText

    $prdCitesPlan = [bool](Test-RelatedCitesSibling -RelatedBody $prdRelated -SiblingLeafName $plan.Name -SiblingDirHint $planDirSegment)
    $planCitesPrd = [bool](Test-RelatedCitesSibling -RelatedBody $planRelated -SiblingLeafName $prd.Name -SiblingDirHint $prdDirSegment)

    if (-not $prdCitesPlan -or -not $planCitesPrd) {
        Write-Host ("FAIL: PRD<->PLAN Related reciprocity missing (prdCitesPlan={0}, planCitesPrd={1})" -f $prdCitesPlan, $planCitesPrd)
        return $exitFail
    }

    Write-Host 'Status: PASS (PRD<->PLAN Related reciprocal)'
    return $exitOk
}

function Invoke-SelfGate {
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

# --- Gate mode ---
if (-not [string]::IsNullOrWhiteSpace($FeatureRoot)) {
    $resolved = Resolve-RootPath -Raw $FeatureRoot -BaseRepo $RepoPath
    $code = [int](Invoke-NavigationGate -Root $resolved)
    exit $code
}

# --- Meta-test mode (validate-core) ---
if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-NavigationBlockPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir
$validRel = $script:ToolkitConstant.NavigationBlockFixtureValidRelativeDir
$noMutualRel = $script:ToolkitConstant.NavigationBlockFixtureNoMutualRelativeDir
$storageRels = @([string[]]$script:ToolkitConstant.NavigationBlockContractRelativePaths)
$templateRels = @([string[]]$script:ToolkitConstant.NavigationBlockTemplateRelativePaths)

$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validRoot = Join-Path $fixturesRoot ($validRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$noMutualRoot = Join-Path $fixturesRoot ($noMutualRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$selfPath = Join-Path $scriptDir $script:ToolkitConstant.AssertNavigationBlockScriptName

if (-not (Test-Path -LiteralPath $validRoot)) {
    Write-Fail -TestName 'Should_Pass_When_ValidMutualFixture_CT4' -Reason ("missing valid fixture {0}" -f $validRel)
}
if (-not (Test-Path -LiteralPath $noMutualRoot)) {
    Write-Fail -TestName 'Should_Fail_When_NoMutualFixture_CT4' -Reason ("missing no-mutual fixture {0}" -f $noMutualRel)
}
if (-not (Test-Path -LiteralPath $selfPath)) {
    Write-Fail -TestName 'Assert-NavigationBlockPreconditions' -Reason ("missing {0}" -f $script:ToolkitConstant.AssertNavigationBlockScriptName)
}

# --- STORAGE / PIPELINE Navigation block ---
foreach ($rel in $storageRels) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_StorageDefinesNavigationBlock' -Reason ("missing {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch [regex]::Escape('Navigation block')) {
        Write-Fail -TestName 'Should_Pass_When_StorageDefinesNavigationBlock' -Reason ("{0} missing Navigation block" -f $rel)
    }
    if ($text -notmatch [regex]::Escape($relatedHeading)) {
        Write-Fail -TestName 'Should_Pass_When_StorageDefinesNavigationBlock' -Reason ("{0} missing {1}" -f $rel, $relatedHeading)
    }
}
Write-Pass -TestName 'Should_Pass_When_StorageDefinesNavigationBlock'

# --- Templates include ## Related ---
foreach ($rel in $templateRels) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_TemplatesHaveRelatedHeading' -Reason ("missing template {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch [regex]::Escape($relatedHeading)) {
        Write-Fail -TestName 'Should_Pass_When_TemplatesHaveRelatedHeading' -Reason ("{0} missing {1}" -f $rel, $relatedHeading)
    }
}
Write-Pass -TestName 'Should_Pass_When_TemplatesHaveRelatedHeading'

# --- OOS: no feature-refinement.md SoT ---
$forbiddenRel = $script:ToolkitConstant.NavigationBlockForbiddenRefinementRelativePath
$forbiddenPath = Join-Path $repoRoot ($forbiddenRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $forbiddenPath) {
    Write-Fail -TestName 'Should_Pass_When_NoFeatureRefinementMd_OOS' -Reason ("OOS file must not exist: {0}" -f $forbiddenRel)
}
Write-Pass -TestName 'Should_Pass_When_NoFeatureRefinementMd_OOS'

# --- CT4 valid -> exit 0 ---
$validResult = Invoke-SelfGate -ScriptPath $selfPath -Arguments @{
    FeatureRoot = $validRoot
    RepoPath    = $repoRoot
}
if ($validResult.ExitCode -ne $exitOk) {
    Write-Fail -TestName 'Should_Pass_When_ValidMutualFixture_CT4' -Reason ("expected exit {0}, got {1}. {2}" -f $exitOk, $validResult.ExitCode, $validResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidMutualFixture_CT4'

# --- CT4 no mutual -> exit != 0 ---
$failResult = Invoke-SelfGate -ScriptPath $selfPath -Arguments @{
    FeatureRoot = $noMutualRoot
    RepoPath    = $repoRoot
}
if ($failResult.ExitCode -eq $exitOk) {
    Write-Fail -TestName 'Should_Fail_When_NoMutualFixture_CT4' -Reason 'expected non-zero exit when PRD+PLAN lack mutual Related citation'
}
Write-Pass -TestName 'Should_Fail_When_NoMutualFixture_CT4'

Write-Host 'Assert-NavigationBlock: ALL PASS'
exit 0
