#Requires -Version 5.1
# Tests:
#   Should_Pass_When_IntentClassificationContractPresent
#   Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification
#   Should_Pass_When_TriageCrossReferencesIntentClassification
#
# Frente E: intent-classification contract exists and is wired into O1 Step 1 triage entry.
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
    Write-Fail -TestName 'Assert-IntentClassificationPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-IntentClassificationPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$contractRel = $script:ToolkitConstant.IntentClassificationContractRelativePath
$contractPath = Join-Path $repoRoot $contractRel
$o1SkillRel = 'core/skills/orchestrate-analyze/SKILL.md'
$o1RefRel = 'core/skills/orchestrate-analyze/reference.md'
$o1TriageRel = 'core/skills/orchestrate-analyze/references/triage.md'

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason ("missing contract {0}" -f $contractRel)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
if ($contractText -notmatch 'Assert-IntentClassification') {
    Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason 'intent-classification.md must name Assert-IntentClassification.ps1 as enforcement'
}
foreach ($intentLabel in @('Existing Feature', 'New Feature', 'Product Initiative', 'Problem / Need', 'Idea')) {
    if ($contractText -notmatch [regex]::Escape($intentLabel)) {
        Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason ("intent-classification.md must define intent {0}" -f $intentLabel)
    }
}
if ($contractText -notmatch '(?i)Classic SDD' -or $contractText -notmatch '(?i)Backlog Refine' -or $contractText -notmatch '(?i)Full O1') {
    Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason 'intent-classification.md must map intents to Classic SDD, Backlog Refine, and full O1 paths'
}
if ($contractText -notmatch '(?i)before backlog synthesis') {
    Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason 'intent-classification.md must document when to spawn specialists before backlog synthesis'
}
Write-Pass -TestName 'Should_Pass_When_IntentClassificationContractPresent'

$o1SkillPath = Join-Path $repoRoot $o1SkillRel
$o1RefPath = Join-Path $repoRoot $o1RefRel
if (-not (Test-Path -LiteralPath $o1SkillPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason ("missing {0}" -f $o1SkillRel)
}
if (-not (Test-Path -LiteralPath $o1RefPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason ("missing {0}" -f $o1RefRel)
}

$o1SkillText = Get-Content -LiteralPath $o1SkillPath -Raw -Encoding UTF8
$o1RefText = Get-Content -LiteralPath $o1RefPath -Raw -Encoding UTF8

if ($o1SkillText -notmatch 'intent-classification\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason 'orchestrate-analyze/SKILL.md must reference intent-classification.md'
}
if ($o1SkillText -notmatch '(?i)Intent classification') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason 'orchestrate-analyze/SKILL.md must include Intent classification process step'
}
if ($o1RefText -notmatch 'intent-classification\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason 'orchestrate-analyze/reference.md must index intent-classification.md'
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification'

$o1TriagePath = Join-Path $repoRoot $o1TriageRel
if (-not (Test-Path -LiteralPath $o1TriagePath)) {
    Write-Fail -TestName 'Should_Pass_When_TriageCrossReferencesIntentClassification' -Reason ("missing {0}" -f $o1TriageRel)
}

$o1TriageText = Get-Content -LiteralPath $o1TriagePath -Raw -Encoding UTF8
if ($o1TriageText -notmatch 'intent-classification\.md') {
    Write-Fail -TestName 'Should_Pass_When_TriageCrossReferencesIntentClassification' -Reason 'triage.md must cross-reference intent-classification.md'
}
Write-Pass -TestName 'Should_Pass_When_TriageCrossReferencesIntentClassification'

Write-Host 'Assert-IntentClassification: ALL PASS'
exit 0
