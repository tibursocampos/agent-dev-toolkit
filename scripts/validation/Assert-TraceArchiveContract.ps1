#Requires -Version 5.1
# Tests:
#   Should_Pass_When_TraceArchiveContractPresent
#   Should_Pass_When_ValidTraceFixture
#   Should_Fail_When_IncompleteTrace_RequireArchive
#   Should_Fail_When_BadJsonTrace
#   Should_Fail_When_InvalidOrchestrationEvents
#   Should_Pass_When_ArchiveSmoke_BrownfieldChange_CheapToStandard
#   Should_Pass_When_SkillsWireTraceArchiveContract
#
# REQ-006 / CA5: converge -> sync current -> archive; TRACE.jsonl; living markdown SoT.
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
    Write-Fail -TestName 'Assert-TraceArchiveContractPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-TraceArchiveContractPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$contractRel = $script:ToolkitConstant.TraceArchiveContractGuideRelativePath
$templateRel = $script:ToolkitConstant.TraceTemplateRelativePath
$validateName = $script:ToolkitConstant.ValidateTraceScriptName
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir

$contractPath = Join-Path $repoRoot ($contractRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$templatePath = Join-Path $repoRoot ($templateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validatePath = Join-Path $scriptDir $validateName
$validateChangePath = Join-Path $scriptDir $script:ToolkitConstant.ValidateChangeScriptName
$validateEvidencePath = Join-Path $scriptDir $script:ToolkitConstant.ValidateEvidenceScriptName
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_TraceArchiveContractPresent' -Reason ("missing guide {0}" -f $contractRel)
}
if (-not (Test-Path -LiteralPath $templatePath)) {
    Write-Fail -TestName 'Should_Pass_When_TraceArchiveContractPresent' -Reason ("missing template {0}" -f $templateRel)
}
if (-not (Test-Path -LiteralPath $validatePath)) {
    Write-Fail -TestName 'Should_Pass_When_TraceArchiveContractPresent' -Reason ("missing {0}" -f $validateName)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
$requiredContractMarkers = @(
    'features/NNN-slug/TRACE.jsonl',
    'converge',
    'sync_current',
    'archive',
    'validate-trace',
    'memory-bank/',
    'openspec',
    'retrieval',
    'gate',
    'spawn',
    'specialist_complete'
)
foreach ($marker in $requiredContractMarkers) {
    if ($contractText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_TraceArchiveContractPresent' -Reason ("guide missing marker '{0}'" -f $marker)
    }
}

$templateText = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
foreach ($ev in @('converge', 'sync_current', 'archive')) {
    if ($templateText -notmatch [regex]::Escape(('"event":"{0}"' -f $ev))) {
        # tolerate spacing variants
        if ($templateText -notmatch ('"event"\s*:\s*"{0}"' -f $ev)) {
            Write-Fail -TestName 'Should_Pass_When_TraceArchiveContractPresent' -Reason ("TRACE template missing event {0}" -f $ev)
        }
    }
}
Write-Pass -TestName 'Should_Pass_When_TraceArchiveContractPresent'

function Get-FixtureRoot {
    param([Parameter(Mandatory = $true)][string] $RelativeUnderFixtures)
    $full = Join-Path $fixturesRoot ($RelativeUnderFixtures -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-TraceArchiveContractPreconditions' -Reason ("missing fixture {0}" -f $RelativeUnderFixtures)
    }
    return $full
}

$validRoot = Get-FixtureRoot -RelativeUnderFixtures $script:ToolkitConstant.ValidateTraceFixtureValidRelativeDir
$validResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ FeatureRoot = $validRoot; RequireArchiveComplete = $true }
if ($validResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ValidTraceFixture' -Reason ("expected exit 0, got {0}. {1}" -f $validResult.ExitCode, $validResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ValidTraceFixture'

$incompleteRoot = Get-FixtureRoot -RelativeUnderFixtures $script:ToolkitConstant.ValidateTraceFixtureInvalidIncompleteRelativeDir
$incompleteResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ FeatureRoot = $incompleteRoot; RequireArchiveComplete = $true }
if ($incompleteResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_IncompleteTrace_RequireArchive' -Reason 'expected non-zero exit for incomplete living-loop TRACE'
}
Write-Pass -TestName 'Should_Fail_When_IncompleteTrace_RequireArchive'

$badJsonRoot = Get-FixtureRoot -RelativeUnderFixtures $script:ToolkitConstant.ValidateTraceFixtureInvalidBadJsonRelativeDir
$badJsonResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ FeatureRoot = $badJsonRoot }
if ($badJsonResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_BadJsonTrace' -Reason 'expected non-zero exit for invalid JSONL'
}
Write-Pass -TestName 'Should_Fail_When_BadJsonTrace'

$invalidOrchestrationRoot = Get-FixtureRoot -RelativeUnderFixtures $script:ToolkitConstant.ValidateTraceFixtureInvalidOrchestrationRelativeDir
$invalidOrchestrationResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ FeatureRoot = $invalidOrchestrationRoot }
if ($invalidOrchestrationResult.ExitCode -eq 0) {
    Write-Fail -TestName 'Should_Fail_When_InvalidOrchestrationEvents' -Reason 'expected non-zero exit for normative orchestration event schema violations'
}
Write-Pass -TestName 'Should_Fail_When_InvalidOrchestrationEvents'

$smokeRoot = Get-FixtureRoot -RelativeUnderFixtures $script:ToolkitConstant.ValidateTraceFixtureArchiveSmokeRelativeDir
$changePath = Join-Path $smokeRoot 'CHANGE.md'
if (-not (Test-Path -LiteralPath $changePath)) {
    Write-Fail -TestName 'Should_Pass_When_ArchiveSmoke_BrownfieldChange_CheapToStandard' -Reason 'archive-smoke missing CHANGE.md'
}
$changeResult = Invoke-Validator -ScriptPath $validateChangePath -Arguments @{ Path = $changePath }
if ($changeResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ArchiveSmoke_BrownfieldChange_CheapToStandard' -Reason ("validate-change failed: {0}" -f $changeResult.Output.Trim())
}
$cheapResult = Invoke-Validator -ScriptPath $validateEvidencePath -Arguments @{ FeatureRoot = $smokeRoot; Level = 'cheap' }
if ($cheapResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ArchiveSmoke_BrownfieldChange_CheapToStandard' -Reason ("validate-evidence cheap failed: {0}" -f $cheapResult.Output.Trim())
}
$standardResult = Invoke-Validator -ScriptPath $validateEvidencePath -Arguments @{ FeatureRoot = $smokeRoot; Level = 'standard' }
if ($standardResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ArchiveSmoke_BrownfieldChange_CheapToStandard' -Reason ("validate-evidence standard failed: {0}" -f $standardResult.Output.Trim())
}
$traceSmokeResult = Invoke-Validator -ScriptPath $validatePath -Arguments @{ FeatureRoot = $smokeRoot; RequireArchiveComplete = $true }
if ($traceSmokeResult.ExitCode -ne 0) {
    Write-Fail -TestName 'Should_Pass_When_ArchiveSmoke_BrownfieldChange_CheapToStandard' -Reason ("validate-trace archive-complete failed: {0}" -f $traceSmokeResult.Output.Trim())
}
Write-Pass -TestName 'Should_Pass_When_ArchiveSmoke_BrownfieldChange_CheapToStandard'

$wiringPaths = $script:ToolkitConstant.TraceArchiveContractSkillWiringRelativePaths
foreach ($rel in $wiringPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireTraceArchiveContract' -Reason ("missing skill file {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch 'TRACE\.jsonl|TRACE-ARCHIVE-CONTRACT|validate-trace|sync_current|living loop') {
        Write-Fail -TestName 'Should_Pass_When_SkillsWireTraceArchiveContract' -Reason ("{0} must reference TRACE/archive living-loop contract" -f $rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_SkillsWireTraceArchiveContract'

Write-Host 'Assert-TraceArchiveContract: all checks passed.'
exit 0
