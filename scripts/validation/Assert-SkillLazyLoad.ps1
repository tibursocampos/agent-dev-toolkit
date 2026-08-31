#Requires -Version 5.1
# Tests:
#   Should_Pass_When_SkillReferenceRetrievalContractPresent
#   Should_Fail_When_InvocableSkillMissingLazyLoadTable
#   Should_Fail_When_InvocableSkillMissingNeverByDefault
#   Should_Pass_When_OrchestrateReferencesSplitPresent
#   Should_Fail_When_MonolithicReferenceWithoutSplit
#
# Frente B: lazy-load real references — invocable skills must declare Lazy-load
# and **Never by default:**; monolithic reference.md >150 lines without
# references/ or reference/ split is FAIL (not WARN).
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

function Test-HasReferenceSplit {
    param([Parameter(Mandatory = $true)][string] $SkillDir)
    $referencesDir = Join-Path $SkillDir 'references'
    $referenceDir = Join-Path $SkillDir 'reference'
    return ((Test-Path -LiteralPath $referencesDir) -or (Test-Path -LiteralPath $referenceDir))
}

function Get-ReferenceSplitDir {
    param([Parameter(Mandatory = $true)][string] $SkillDir)
    $referencesDir = Join-Path $SkillDir 'references'
    if (Test-Path -LiteralPath $referencesDir) {
        return $referencesDir
    }
    $referenceDir = Join-Path $SkillDir 'reference'
    if (Test-Path -LiteralPath $referenceDir) {
        return $referenceDir
    }
    return $null
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-SkillLazyLoadPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-SkillLazyLoadPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$guideRel = $script:ToolkitConstant.SkillReferenceRetrievalGuideRelativePath
$guidePath = Join-Path $repoRoot $guideRel
$ruleId = $script:ToolkitConstant.SkillReferenceRetrievalRuleId
$skillsRootRel = $script:ToolkitConstant.CoreSkillsRootRelativePath
$skillsRoot = Join-Path $repoRoot $skillsRootRel
$sharedDirName = $script:ToolkitConstant.SharedSkillsDirectoryName
$lazyLoadHeadingPattern = $script:ToolkitConstant.SkillLazyLoadHeadingPattern
$neverByDefaultPattern = $script:ToolkitConstant.SkillLazyLoadNeverByDefaultPattern
$referenceLineThreshold = $script:ToolkitConstant.SkillLazyLoadReferenceLineThreshold
$referenceIndexLineThreshold = $script:ToolkitConstant.SkillLazyLoadReferenceIndexLineThreshold

if (-not (Test-Path -LiteralPath $guidePath)) {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason ("missing guide {0}" -f $guideRel)
}

$guideText = Get-Content -LiteralPath $guidePath -Raw -Encoding UTF8
if ($guideText -notmatch [regex]::Escape($ruleId)) {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason ("guide missing rule id {0}" -f $ruleId)
}
if ($guideText -notmatch 'Assert-SkillLazyLoad') {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason 'guide must name Assert-SkillLazyLoad.ps1 as enforcement'
}
if ($guideText -notmatch '(?i)## Lazy-load' -or $guideText -notmatch '(?i)\*\*Never by default:\*\*') {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason 'guide must document mandatory Lazy-load + Never by default sections'
}
if (($guideText -notmatch '(?i)all invocable') -and ($guideText -notmatch '(?i)every invocable')) {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason 'guide must state contract applies to all/every invocable skills'
}
Write-Pass -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent'

$missingLazyLoad = [System.Collections.Generic.List[string]]::new()
$missingNeverByDefault = [System.Collections.Generic.List[string]]::new()
$monolithicFailures = [System.Collections.Generic.List[string]]::new()
$indexSoftWarnings = [System.Collections.Generic.List[string]]::new()

$skillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Where-Object {
        $_.Name -ne $sharedDirName
    })

foreach ($dir in $skillDirs) {
    $skillPath = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillPath)) {
        continue
    }

    $text = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
    if ($text -notmatch '(?m)^name:\s*\S+') {
        continue
    }

    if ($text -notmatch $lazyLoadHeadingPattern) {
        $missingLazyLoad.Add(("{0}/SKILL.md" -f $dir.Name))
    }
    elseif ($text -notmatch '\|\s*When\s*\|\s*Path') {
        $missingLazyLoad.Add(("{0}/SKILL.md (Lazy-load without routing table)" -f $dir.Name))
    }

    if ($text -notmatch $neverByDefaultPattern) {
        $missingNeverByDefault.Add(("{0}/SKILL.md" -f $dir.Name))
    }

    $referencePath = Join-Path $dir.FullName 'reference.md'
    if (-not (Test-Path -LiteralPath $referencePath)) {
        continue
    }

    $referenceLines = @(Get-Content -LiteralPath $referencePath -Encoding UTF8).Count
    $hasSplit = Test-HasReferenceSplit -SkillDir $dir.FullName
    $splitDir = Get-ReferenceSplitDir -SkillDir $dir.FullName

    if ($hasSplit) {
        $refFiles = @(Get-ChildItem -LiteralPath $splitDir -File -Filter '*.md')
        if ($refFiles.Count -eq 0) {
            $monolithicFailures.Add(("{0}: {1}/ exists but is empty" -f $dir.Name, (Split-Path -Leaf $splitDir)))
        }
        if ($referenceLines -gt $referenceIndexLineThreshold) {
            $indexSoftWarnings.Add(("{0}: reference.md index has {1} lines (soft target ≤{2})" -f $dir.Name, $referenceLines, $referenceIndexLineThreshold))
        }
    }
    elseif ($referenceLines -gt $referenceLineThreshold) {
        $monolithicFailures.Add(("{0}: reference.md has {1} lines without references/ or reference/ split (threshold {2})" -f $dir.Name, $referenceLines, $referenceLineThreshold))
    }
}

if ($missingLazyLoad.Count -gt 0) {
    Write-Fail -TestName 'Should_Fail_When_InvocableSkillMissingLazyLoadTable' -Reason ("missing Lazy-load table: {0}" -f ($missingLazyLoad -join ', '))
}
Write-Pass -TestName 'Should_Fail_When_InvocableSkillMissingLazyLoadTable'

if ($missingNeverByDefault.Count -gt 0) {
    Write-Fail -TestName 'Should_Fail_When_InvocableSkillMissingNeverByDefault' -Reason ("missing **Never by default:**: {0}" -f ($missingNeverByDefault -join ', '))
}
Write-Pass -TestName 'Should_Fail_When_InvocableSkillMissingNeverByDefault'

$orchestrateSkills = @('orchestrate-analyze', 'orchestrate-deliver', 'orchestrate-develop')
foreach ($skillName in $orchestrateSkills) {
    $refsDir = Join-Path (Join-Path $skillsRoot $skillName) 'references'
    if (-not (Test-Path -LiteralPath $refsDir)) {
        Write-Fail -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent' -Reason ("missing {0}/references/" -f $skillName)
    }
    $refIndex = Join-Path (Join-Path $skillsRoot $skillName) 'reference.md'
    if (-not (Test-Path -LiteralPath $refIndex)) {
        Write-Fail -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent' -Reason ("missing {0}/reference.md index" -f $skillName)
    }
    $indexLines = @(Get-Content -LiteralPath $refIndex -Encoding UTF8).Count
    if ($indexLines -gt $referenceIndexLineThreshold) {
        Write-Fail -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent' -Reason ("{0}/reference.md index has {1} lines (max {2})" -f $skillName, $indexLines, $referenceIndexLineThreshold)
    }
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent'

if ($monolithicFailures.Count -gt 0) {
    Write-Fail -TestName 'Should_Fail_When_MonolithicReferenceWithoutSplit' -Reason ($monolithicFailures -join '; ')
}
Write-Pass -TestName 'Should_Fail_When_MonolithicReferenceWithoutSplit'

if ($indexSoftWarnings.Count -gt 0) {
    foreach ($warn in $indexSoftWarnings) {
        Write-Warning ("Assert-SkillLazyLoad WARN: {0}" -f $warn)
    }
}

Write-Host 'Assert-SkillLazyLoad: ALL PASS'
exit 0
