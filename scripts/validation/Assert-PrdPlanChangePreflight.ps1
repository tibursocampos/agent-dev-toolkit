#Requires -Version 5.1
# Tests:
#   Should_Pass_When_ConsistentPrdPlanChangePreflight
#   Should_Block_When_OrphanReqInPlanPreflight
#   Should_Block_When_NnnMismatchPreflight
#   Should_Block_When_BrownfieldChangeInvalidPreflight
#   Should_Block_When_AbsolutePrdPathInPlanHeader
#   Should_Pass_When_OrchestrateDeliverWiresPreflight
#   Should_Pass_When_PreflightScriptIsReadOnly
#
# REQ-004 / CA4: PRD→PLAN→CHANGE preflight blocks O3 with explicit reason.
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

function Invoke-Preflight {
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
    Write-Fail -TestName 'Assert-PrdPlanChangePreflightPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-PrdPlanChangePreflightPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$preflightRel = $script:ToolkitConstant.InvokePrdPlanChangePreflightScriptRelativePath
$deliverRefRel = $script:ToolkitConstant.PrdPlanChangePreflightDeliverRefRelativePath
$deliverIndexRel = $script:ToolkitConstant.PrdPlanChangePreflightDeliverIndexRelativePath
$deliverSkillRel = $script:ToolkitConstant.PrdPlanChangePreflightDeliverSkillRelativePath
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir
$exitAllow = [int]$script:ToolkitConstant.PrdPlanChangePreflightExitAllow
$exitBlock = [int]$script:ToolkitConstant.PrdPlanChangePreflightExitBlock
$reasonOrphan = [string]$script:ToolkitConstant.PrdPlanChangePreflightReasonOrphanReq
$reasonNnn = [string]$script:ToolkitConstant.PrdPlanChangePreflightReasonNnnMismatch
$reasonChange = [string]$script:ToolkitConstant.PrdPlanChangePreflightReasonChangeInvalid
$reasonPrdEscape = [string]$script:ToolkitConstant.PrdPlanChangePreflightReasonPrdPathEscape
$prdHeaderPattern = [string]$script:ToolkitConstant.SddArtifactPrdHeaderPattern
$prdHeaderReplacementFormat = '| **PRD** | {0} |'
$preflightPath = Join-Path $repoRoot ($preflightRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$deliverRefPath = Join-Path $repoRoot ($deliverRefRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$deliverIndexPath = Join-Path $repoRoot ($deliverIndexRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$deliverSkillPath = Join-Path $repoRoot ($deliverSkillRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $preflightPath)) {
    Write-Fail -TestName 'Assert-PrdPlanChangePreflightPreconditions' -Reason ("missing {0}" -f $preflightRel)
}

function Get-FixtureFeatureRoot {
    param([Parameter(Mandatory = $true)][string] $RelativeDir)
    $full = Join-Path $fixturesRoot ($RelativeDir -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Assert-PrdPlanChangePreflightPreconditions' -Reason ("missing fixture dir {0}" -f $RelativeDir)
    }
    return $full
}

function Find-FixturePlan {
    param([Parameter(Mandatory = $true)][string] $FeatureRootPath)
    $plans = @(Get-ChildItem -LiteralPath $FeatureRootPath -Recurse -Filter 'PLAN_*.md' -File)
    if ($plans.Count -lt 1) {
        Write-Fail -TestName 'Assert-PrdPlanChangePreflightPreconditions' -Reason ("no PLAN_*.md under {0}" -f $FeatureRootPath)
    }
    return $plans[0].FullName
}

# --- allow path ---
$validRoot = Get-FixtureFeatureRoot -RelativeDir $script:ToolkitConstant.PrdPlanChangePreflightFixtureValidRelativeDir
$validPlan = Find-FixturePlan -FeatureRootPath $validRoot
$validResult = Invoke-Preflight -ScriptPath $preflightPath -Arguments @{
    FeatureRoot = $validRoot
    PlanPath    = $validPlan
    RepoPath    = $repoRoot
}
if ($validResult.ExitCode -ne $exitAllow) {
    Write-Fail -TestName 'Should_Pass_When_ConsistentPrdPlanChangePreflight' -Reason ("expected exit {0}, got {1}. {2}" -f $exitAllow, $validResult.ExitCode, $validResult.Output.Trim())
}
if ($validResult.Output -notmatch 'ALLOW') {
    Write-Fail -TestName 'Should_Pass_When_ConsistentPrdPlanChangePreflight' -Reason 'expected ALLOW message'
}
Write-Pass -TestName 'Should_Pass_When_ConsistentPrdPlanChangePreflight'

# --- orphan REQ ---
$orphanRoot = Get-FixtureFeatureRoot -RelativeDir $script:ToolkitConstant.PrdPlanChangePreflightFixtureOrphanRelativeDir
$orphanPlan = Find-FixturePlan -FeatureRootPath $orphanRoot
$orphanResult = Invoke-Preflight -ScriptPath $preflightPath -Arguments @{
    FeatureRoot = $orphanRoot
    PlanPath    = $orphanPlan
    RepoPath    = $repoRoot
}
if ($orphanResult.ExitCode -ne $exitBlock) {
    Write-Fail -TestName 'Should_Block_When_OrphanReqInPlanPreflight' -Reason ("expected exit {0}, got {1}. {2}" -f $exitBlock, $orphanResult.ExitCode, $orphanResult.Output.Trim())
}
if ($orphanResult.Output -notmatch [regex]::Escape($reasonOrphan)) {
    Write-Fail -TestName 'Should_Block_When_OrphanReqInPlanPreflight' -Reason ("expected reason {0} in output" -f $reasonOrphan)
}
if ($orphanResult.Output -notmatch 'REQ-999') {
    Write-Fail -TestName 'Should_Block_When_OrphanReqInPlanPreflight' -Reason 'expected orphan REQ-999 in detail'
}
Write-Pass -TestName 'Should_Block_When_OrphanReqInPlanPreflight'

# --- NNN mismatch ---
$nnnRoot = Get-FixtureFeatureRoot -RelativeDir $script:ToolkitConstant.PrdPlanChangePreflightFixtureNnnRelativeDir
$nnnPlan = Find-FixturePlan -FeatureRootPath $nnnRoot
$nnnResult = Invoke-Preflight -ScriptPath $preflightPath -Arguments @{
    FeatureRoot = $nnnRoot
    PlanPath    = $nnnPlan
    RepoPath    = $repoRoot
}
if ($nnnResult.ExitCode -ne $exitBlock) {
    Write-Fail -TestName 'Should_Block_When_NnnMismatchPreflight' -Reason ("expected exit {0}, got {1}. {2}" -f $exitBlock, $nnnResult.ExitCode, $nnnResult.Output.Trim())
}
if ($nnnResult.Output -notmatch [regex]::Escape($reasonNnn)) {
    Write-Fail -TestName 'Should_Block_When_NnnMismatchPreflight' -Reason ("expected reason {0}" -f $reasonNnn)
}
Write-Pass -TestName 'Should_Block_When_NnnMismatchPreflight'

# --- CHANGE brownfield invalid ---
$changeRoot = Get-FixtureFeatureRoot -RelativeDir $script:ToolkitConstant.PrdPlanChangePreflightFixtureChangeRelativeDir
$changePlan = Find-FixturePlan -FeatureRootPath $changeRoot
$changeResult = Invoke-Preflight -ScriptPath $preflightPath -Arguments @{
    FeatureRoot = $changeRoot
    PlanPath    = $changePlan
    RepoPath    = $repoRoot
}
if ($changeResult.ExitCode -ne $exitBlock) {
    Write-Fail -TestName 'Should_Block_When_BrownfieldChangeInvalidPreflight' -Reason ("expected exit {0}, got {1}. {2}" -f $exitBlock, $changeResult.ExitCode, $changeResult.Output.Trim())
}
if ($changeResult.Output -notmatch [regex]::Escape($reasonChange)) {
    Write-Fail -TestName 'Should_Block_When_BrownfieldChangeInvalidPreflight' -Reason ("expected reason {0}" -f $reasonChange)
}
Write-Pass -TestName 'Should_Block_When_BrownfieldChangeInvalidPreflight'

# --- OS-absolute / parent-segment PRD from PLAN header ---
$absWork = Join-Path $env:TEMP ('adt-preflight-absolute-prd-{0}' -f [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $absWork -Force | Out-Null
    Copy-Item -LiteralPath $validRoot -Destination (Join-Path $absWork 'feature') -Recurse -Force
    $absFeature = Join-Path $absWork 'feature'
    $absPlan = Find-FixturePlan -FeatureRootPath $absFeature
    $absPrdFiles = @(Get-ChildItem -LiteralPath $absFeature -Recurse -Filter '*_preflight_valid.md' -File |
        Where-Object { $_.Directory.Name -eq 'PRD' })
    if ($absPrdFiles.Count -lt 1) {
        Write-Fail -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader' -Reason 'temp fixture PRD missing'
    }

    $planTextAbs = Get-Content -LiteralPath $absPlan -Raw -Encoding UTF8
    $absolutePrdPath = $absPrdFiles[0].FullName
    $planTextAbs = [regex]::Replace(
        $planTextAbs,
        $prdHeaderPattern,
        ($prdHeaderReplacementFormat -f $absolutePrdPath),
        1
    )
    [System.IO.File]::WriteAllText($absPlan, $planTextAbs, (New-Object System.Text.UTF8Encoding $false))

    $absResult = Invoke-Preflight -ScriptPath $preflightPath -Arguments @{
        FeatureRoot = $absFeature
        PlanPath    = $absPlan
        RepoPath    = $repoRoot
    }
    if ($absResult.ExitCode -ne $exitBlock) {
        Write-Fail -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader' -Reason ("expected exit {0}, got {1}. {2}" -f $exitBlock, $absResult.ExitCode, $absResult.Output.Trim())
    }
    if ($absResult.Output -notmatch [regex]::Escape($reasonPrdEscape)) {
        Write-Fail -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader' -Reason ("expected reason {0} in output" -f $reasonPrdEscape)
    }
    if ($absResult.Output -notmatch 'os_absolute') {
        Write-Fail -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader' -Reason 'expected os_absolute detail for rooted PLAN header PRD'
    }

    $planTextDotDot = Get-Content -LiteralPath $absPlan -Raw -Encoding UTF8
    $planTextDotDot = [regex]::Replace(
        $planTextDotDot,
        $prdHeaderPattern,
        ($prdHeaderReplacementFormat -f '../outside/PRD/escape.md'),
        1
    )
    [System.IO.File]::WriteAllText($absPlan, $planTextDotDot, (New-Object System.Text.UTF8Encoding $false))

    $dotDotResult = Invoke-Preflight -ScriptPath $preflightPath -Arguments @{
        FeatureRoot = $absFeature
        PlanPath    = $absPlan
        RepoPath    = $repoRoot
    }
    if ($dotDotResult.ExitCode -ne $exitBlock) {
        Write-Fail -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader' -Reason ("expected exit {0} for parent_segment, got {1}. {2}" -f $exitBlock, $dotDotResult.ExitCode, $dotDotResult.Output.Trim())
    }
    if ($dotDotResult.Output -notmatch [regex]::Escape($reasonPrdEscape)) {
        Write-Fail -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader' -Reason ("expected reason {0} for parent_segment" -f $reasonPrdEscape)
    }
    if ($dotDotResult.Output -notmatch 'parent_segment') {
        Write-Fail -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader' -Reason 'expected parent_segment detail for .. PLAN header PRD'
    }

    Write-Pass -TestName 'Should_Block_When_AbsolutePrdPathInPlanHeader'
}
finally {
    if (Test-Path -LiteralPath $absWork) {
        Remove-Item -LiteralPath $absWork -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- skill wiring ---
if (-not (Test-Path -LiteralPath $deliverRefPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDeliverWiresPreflight' -Reason ("missing {0}" -f $deliverRefRel)
}
if (-not (Test-Path -LiteralPath $deliverIndexPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDeliverWiresPreflight' -Reason ("missing {0}" -f $deliverIndexRel)
}
if (-not (Test-Path -LiteralPath $deliverSkillPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDeliverWiresPreflight' -Reason ("missing {0}" -f $deliverSkillRel)
}

$deliverRefText = Get-Content -LiteralPath $deliverRefPath -Raw -Encoding UTF8
$deliverIndexText = Get-Content -LiteralPath $deliverIndexPath -Raw -Encoding UTF8
$deliverSkillText = Get-Content -LiteralPath $deliverSkillPath -Raw -Encoding UTF8

$wiringMarkers = @(
    'REQ-004',
    'CA4',
    'Invoke-PrdPlanChangePreflight',
    'validate-prd',
    'validate-plan',
    'validate-change',
    'CHANGE-CONTRACT',
    'orphan_req',
    'nnn_mismatch',
    'SR-NO-FULL-DUMP'
)
foreach ($marker in $wiringMarkers) {
    if ($deliverRefText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_OrchestrateDeliverWiresPreflight' -Reason ("preflight ref missing marker '{0}'" -f $marker)
    }
}
if ($deliverIndexText -notmatch 'preflight-prd-plan-change\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDeliverWiresPreflight' -Reason 'orchestrate-deliver/reference.md must index preflight-prd-plan-change.md'
}
if ($deliverSkillText -notmatch 'preflight-prd-plan-change') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateDeliverWiresPreflight' -Reason 'orchestrate-deliver/SKILL.md must lazy-load preflight ref'
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateDeliverWiresPreflight'

# --- read-only (no mutating cmdlets) ---
$preflightText = Get-Content -LiteralPath $preflightPath -Raw -Encoding UTF8
$mutatingPattern = $script:ToolkitConstant.PrdPlanChangePreflightMutatingCmdPattern
if ($preflightText -match $mutatingPattern) {
    Write-Fail -TestName 'Should_Pass_When_PreflightScriptIsReadOnly' -Reason ("preflight script must not mutate files; matched '{0}'" -f $Matches[0])
}
Write-Pass -TestName 'Should_Pass_When_PreflightScriptIsReadOnly'

Write-Host 'Assert-PrdPlanChangePreflight: ALL PASS'
exit 0
