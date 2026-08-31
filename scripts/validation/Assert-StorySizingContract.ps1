#Requires -Version 5.1
# Tests:
#   Should_Pass_When_StorySizingContractPresent
#   Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing
#   Should_Pass_When_RefineStoryScorecardHasStoryScope
#
# Frente A: story-sizing contract exists and is wired into O1 synthesis + refine scorecard.
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
    Write-Fail -TestName 'Assert-StorySizingContractPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-StorySizingContractPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$contractRel = $script:ToolkitConstant.StorySizingContractRelativePath
$contractPath = Join-Path $repoRoot $contractRel
$o1SkillRel = 'core/skills/orchestrate-analyze/SKILL.md'
$o1RefRel = 'core/skills/orchestrate-analyze/reference.md'
$o1SynthesisRel = 'core/skills/orchestrate-analyze/references/story-synthesis.md'
$refineRefRel = 'core/skills/refine-story/reference.md'

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason ("missing contract {0}" -f $contractRel)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
if ($contractText -notmatch 'Assert-StorySizingContract') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must name Assert-StorySizingContract.ps1 as enforcement'
}
if ($contractText -notmatch '(?i)one verifiable') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must define minimum story as one verifiable outcome'
}
if ($contractText -notmatch '(?i)anti-pattern') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must document anti-patterns'
}
if ($contractText -notmatch '(?i)NuGet') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must reference NuGet example'
}
Write-Pass -TestName 'Should_Pass_When_StorySizingContractPresent'

$o1SkillPath = Join-Path $repoRoot $o1SkillRel
$o1RefPath = Join-Path $repoRoot $o1RefRel
$o1SynthesisPath = Join-Path $repoRoot $o1SynthesisRel
if (-not (Test-Path -LiteralPath $o1SkillPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason ("missing {0}" -f $o1SkillRel)
}
if (-not (Test-Path -LiteralPath $o1RefPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason ("missing {0}" -f $o1RefRel)
}
if (-not (Test-Path -LiteralPath $o1SynthesisPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason ("missing {0}" -f $o1SynthesisRel)
}

$o1SkillText = Get-Content -LiteralPath $o1SkillPath -Raw -Encoding UTF8
$o1RefText = Get-Content -LiteralPath $o1RefPath -Raw -Encoding UTF8
$o1SynthesisText = Get-Content -LiteralPath $o1SynthesisPath -Raw -Encoding UTF8
$o1DetailText = ($o1RefText + "`n" + $o1SynthesisText)

if ($o1SkillText -notmatch 'story-sizing\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason 'orchestrate-analyze/SKILL.md must reference story-sizing.md'
}
if ($o1SkillText -notmatch '(?i)merge policy') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason 'orchestrate-analyze/SKILL.md synthesis step must mention merge policy'
}
if ($o1SkillText -notmatch '(?i)Rationale') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason 'orchestrate-analyze/SKILL.md must require FEATURE Rationale column'
}
if ($o1DetailText -notmatch 'story-sizing\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason 'orchestrate-analyze reference index or story-synthesis must reference story-sizing.md'
}
if ($o1DetailText -notmatch '(?i)merge policy') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason 'orchestrate-analyze reference detail must document merge policy'
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing'

$refineRefPath = Join-Path $repoRoot $refineRefRel
if (-not (Test-Path -LiteralPath $refineRefPath)) {
    Write-Fail -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope' -Reason ("missing {0}" -f $refineRefRel)
}

$refineRefText = Get-Content -LiteralPath $refineRefPath -Raw -Encoding UTF8
if ($refineRefText -notmatch '(?i)Story scope') {
    Write-Fail -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope' -Reason 'refine-story/reference.md must include Story scope scorecard criterion'
}
if ($refineRefText -notmatch 'story-sizing\.md') {
    Write-Fail -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope' -Reason 'refine-story/reference.md must reference story-sizing.md'
}
Write-Pass -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope'

Write-Host 'Assert-StorySizingContract: ALL PASS'
exit 0
