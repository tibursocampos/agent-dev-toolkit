#Requires -Version 5.1
# Tests:
#   Should_Pass_When_SelectiveRetrievalContractPresent
#   Should_Fail_When_FullDumpPrescriptionPresent
#   Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills
#
# CT5 / REQ-002: selective retrieval must be documented and enforceable.
# Scans in-scope SDD skills/templates for full memory-bank / PRD dump prescriptions.
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
    Write-Fail -TestName 'Assert-SelectiveRetrievalPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-SelectiveRetrievalPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$selectiveRetrievalRel = $script:ToolkitConstant.SelectiveRetrievalGuideRelativePath
$selectiveRetrievalPath = Join-Path $repoRoot $selectiveRetrievalRel
$ruleId = $script:ToolkitConstant.SelectiveRetrievalRuleId
$inScopeRelativePaths = $script:ToolkitConstant.SelectiveRetrievalInScopeRelativePaths

if (-not (Test-Path -LiteralPath $selectiveRetrievalPath)) {
    Write-Fail -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent' -Reason ("missing guide {0}" -f $selectiveRetrievalRel)
}

$guideText = Get-Content -LiteralPath $selectiveRetrievalPath -Raw -Encoding UTF8
if ($guideText -notmatch [regex]::Escape($ruleId)) {
    Write-Fail -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent' -Reason ("guide missing rule id {0}" -f $ruleId)
}
if ($guideText -notmatch 'Assert-SelectiveRetrieval') {
    Write-Fail -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent' -Reason 'guide must name Assert-SelectiveRetrieval.ps1 as enforcement'
}
Write-Pass -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent'

# Prescriptions that order a full dump (positive instruction). Lines that only forbid dumps are allowed.
$dumpPrescriptionPatterns = @(
    '(?i)\b(dump|paste|load|include|colar|despejar)\b.{0,80}\b(entire|full|all|integral|completo|inteiro)\b.{0,80}\bmemory-bank\b',
    '(?i)\b(dump|paste|load|include|colar|despejar)\b.{0,80}\bmemory-bank\b.{0,40}\b(entire|full|all|integral|completo|inteiro)\b',
    '(?i)\b(dump|paste|include|colar)\b.{0,80}\b(entire|full|all|integral|completo|inteiro)\b.{0,80}\bPRD\b',
    '(?i)\b(dump|paste|include|colar)\b.{0,80}\bPRD\b.{0,40}\b(entire|full|all|integral|completo|body|inteiro)\b',
    '(?i)\bread\s+all\s+files\s+under\s+memory-bank',
    '(?i)\bload\s+every\s+file\s+(under|in)\s+memory-bank',
    '(?i)\bdump\s+integral\s+(do|de)\s+memory-bank',
    '(?i)\bcolar\s+o\s+PRD\s+completo\b'
)

$antiDumpRequiredPattern = '(?i)(SR-NO-FULL-DUMP|SELECTIVE-RETRIEVAL|selective retrieval|selective read|never dump|must not dump|do not dump|no full dump|sem dump integral|não.*dump integral)'

$forbidNegationPattern = '(?i)(\bnever\b|\bdo\s+\*{0,2}not\*{0,2}\b|\bmust\s+\*{0,2}not\*{0,2}\b|\bprohibit|\bforbid|\bnão\b|\bnao\b|\bproibido\b|\bsem\b)'

$dumpHits = [System.Collections.Generic.List[string]]::new()
$missingAntiDump = [System.Collections.Generic.List[string]]::new()

foreach ($rel in $inScopeRelativePaths) {
    $full = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills' -Reason ("missing in-scope file {0}" -f $rel)
    }

    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8

    if ($rel -match 'SELECTIVE-RETRIEVAL\.md$') {
        # Contract lists forbidden dump phrases as examples; do not treat as prescriptions.
        if ($text -notmatch $antiDumpRequiredPattern) {
            $missingAntiDump.Add($rel)
        }
        continue
    }

    $lines = $text -split "`r?`n"
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        foreach ($pattern in $dumpPrescriptionPatterns) {
            if ($line -match $pattern) {
                if ($line -match $forbidNegationPattern) {
                    continue
                }
                $dumpHits.Add(("{0}:{1}: {2}" -f $rel, $lineNum, $line.Trim()))
            }
        }
    }

    if ($rel -match 'templates/sdd/') {
        continue
    }
    if ($text -notmatch $antiDumpRequiredPattern) {
        $missingAntiDump.Add($rel)
    }
}

if ($dumpHits.Count -gt 0) {
    $sample = ($dumpHits | Select-Object -First 5) -join '; '
    Write-Fail -TestName 'Should_Fail_When_FullDumpPrescriptionPresent' -Reason ("dump prescription(s) found: {0}" -f $sample)
}
Write-Pass -TestName 'Should_Fail_When_FullDumpPrescriptionPresent'

if ($missingAntiDump.Count -gt 0) {
    Write-Fail -TestName 'Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills' -Reason ("missing selective/anti-dump marker in: {0}" -f ($missingAntiDump -join ', '))
}
Write-Pass -TestName 'Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills'

# Templates must require REQ-IDs and OOS (REQ-001 contract surface).
$prdTemplateRel = 'core/skills/_shared/templates/sdd/PRD.md'
$planTemplateRel = 'core/skills/_shared/templates/sdd/PLAN.md'
$prdTemplate = Get-Content -LiteralPath (Join-Path $repoRoot $prdTemplateRel) -Raw -Encoding UTF8
$planTemplate = Get-Content -LiteralPath (Join-Path $repoRoot $planTemplateRel) -Raw -Encoding UTF8

if ($prdTemplate -notmatch 'REQ-001' -or $prdTemplate -notmatch 'Fora de escopo \(OOS\)' -or $prdTemplate -notmatch 'Blast radius') {
    Write-Fail -TestName 'Should_Pass_When_PrdTemplateHasReqAcOos' -Reason 'PRD template missing REQ-001, OOS, or blast-radius section'
}
if ($prdTemplate -notmatch '(?i)EARS' -or $prdTemplate -notmatch '(?i)não universal|not universal|opcional') {
    Write-Fail -TestName 'Should_Pass_When_PrdTemplateHasReqAcOos' -Reason 'PRD template must document hybrid EARS as optional/not universal'
}
Write-Pass -TestName 'Should_Pass_When_PrdTemplateHasReqAcOos'

$arrow = [string][char]0x2192
if ($planTemplate -notmatch ("REQ {0} passo" -f $arrow) -and $planTemplate -notmatch 'REQ -> passo' -and $planTemplate -notmatch 'Mapa REQ') {
    Write-Fail -TestName 'Should_Pass_When_PlanTemplateMapsReqToStep' -Reason 'PLAN template missing REQ-to-step map'
}
Write-Pass -TestName 'Should_Pass_When_PlanTemplateMapsReqToStep'

Write-Host 'Assert-SelectiveRetrieval: ALL PASS'
exit 0
