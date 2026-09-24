#Requires -Version 5.1
# Tests:
#   Should_Pass_When_ReadyFixture_CT3
#   Should_Fail_When_OpenBiFixture_CT3
#   Should_Pass_When_ContractCitesMachineGate_REQ006
#   Should_Pass_When_NoJarvisAdoPythonRuntime
#
# REQ-006 / CA2 / CT3 / RNF-001: selective readiness assert + deterministic fixtures.
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

function Invoke-Gate {
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
    Write-Fail -TestName 'Assert-SiblingReadinessGatePreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-SiblingReadinessGatePreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$invokeRel = $script:ToolkitConstant.InvokeSiblingReadinessGateScriptRelativePath
$contractRel = $script:ToolkitConstant.SiblingReadinessContractRelativePath
$fixturesRel = $script:ToolkitConstant.SddArtifactFixturesRelativeDir
$readyRel = $script:ToolkitConstant.SiblingReadinessFixtureReadyRelativeDir
$openRel = $script:ToolkitConstant.SiblingReadinessFixtureOpenBiRelativeDir
$exitReady = [int]$script:ToolkitConstant.SiblingReadinessExitReady
$exitNeeds = [int]$script:ToolkitConstant.SiblingReadinessExitNeeds
$statusReady = [string]$script:ToolkitConstant.SiblingReadinessStatusReady
$statusNeeds = [string]$script:ToolkitConstant.SiblingReadinessStatusNeeds

$invokePath = Join-Path $repoRoot ($invokeRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$contractPath = Join-Path $repoRoot ($contractRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixturesRoot = Join-Path $repoRoot ($fixturesRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$readyRoot = Join-Path $fixturesRoot ($readyRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$openRoot = Join-Path $fixturesRoot ($openRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $invokePath)) {
    Write-Fail -TestName 'Assert-SiblingReadinessGatePreconditions' -Reason ("missing {0}" -f $invokeRel)
}
if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_ContractCitesMachineGate_REQ006' -Reason ("missing {0}" -f $contractRel)
}
if (-not (Test-Path -LiteralPath $readyRoot)) {
    Write-Fail -TestName 'Should_Pass_When_ReadyFixture_CT3' -Reason ("missing ready fixture {0}" -f $readyRel)
}
if (-not (Test-Path -LiteralPath $openRoot)) {
    Write-Fail -TestName 'Should_Fail_When_OpenBiFixture_CT3' -Reason ("missing open-bi fixture {0}" -f $openRel)
}

# --- REQ-006 contract cites machine gate scripts ---
$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
foreach ($marker in @(
        'Assert-SiblingReadinessGate',
        'Invoke-SiblingReadinessGate',
        'REQ-006',
        $statusReady,
        $statusNeeds
    )) {
    if ($contractText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_ContractCitesMachineGate_REQ006' -Reason ("contract missing marker '{0}'" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_ContractCitesMachineGate_REQ006'

# --- No Jarvis / ADO / Python runtime in Invoke (needles built to avoid self-match) ---
$invokeBody = Get-Content -LiteralPath $invokePath -Raw -Encoding UTF8
$forbiddenNeedles = @(
    ('jarvis' + '_contract_runtime'),
    ('JARVIS' + '_'),
    ('azure' + '.devops'),
    ('from' + ' azure')
)
foreach ($forbidden in $forbiddenNeedles) {
    if ($invokeBody -match [regex]::Escape($forbidden)) {
        Write-Fail -TestName 'Should_Pass_When_NoJarvisAdoPythonRuntime' -Reason ("Invoke must not embed runtime marker '{0}'" -f $forbidden)
    }
}
if ($invokeBody -match '(?i)\bpython\.exe\b' -or $invokeBody -match '(?i)\bpip\s+install\b' -or $invokeBody -match '(?i)\.py\b') {
    Write-Fail -TestName 'Should_Pass_When_NoJarvisAdoPythonRuntime' -Reason 'Invoke must not invoke Python runtime'
}
Write-Pass -TestName 'Should_Pass_When_NoJarvisAdoPythonRuntime'

# --- CT3 READY → pass ---
$readyResult = Invoke-Gate -ScriptPath $invokePath -Arguments @{
    FeatureRoot = $readyRoot
    RepoPath    = $repoRoot
}
if ($readyResult.ExitCode -ne $exitReady) {
    Write-Fail -TestName 'Should_Pass_When_ReadyFixture_CT3' -Reason ("expected exit {0}, got {1}. {2}" -f $exitReady, $readyResult.ExitCode, $readyResult.Output.Trim())
}
if ($readyResult.Output -notmatch [regex]::Escape("Status: $statusReady")) {
    Write-Fail -TestName 'Should_Pass_When_ReadyFixture_CT3' -Reason ("expected Status: {0}" -f $statusReady)
}
Write-Pass -TestName 'Should_Pass_When_ReadyFixture_CT3'

# --- CT3 open B/I → fail / NEEDS ---
$openResult = Invoke-Gate -ScriptPath $invokePath -Arguments @{
    FeatureRoot = $openRoot
    RepoPath    = $repoRoot
}
if ($openResult.ExitCode -ne $exitNeeds) {
    Write-Fail -TestName 'Should_Fail_When_OpenBiFixture_CT3' -Reason ("expected exit {0}, got {1}. {2}" -f $exitNeeds, $openResult.ExitCode, $openResult.Output.Trim())
}
if ($openResult.Output -notmatch [regex]::Escape("Status: $statusNeeds")) {
    Write-Fail -TestName 'Should_Fail_When_OpenBiFixture_CT3' -Reason ("expected Status: {0}" -f $statusNeeds)
}
Write-Pass -TestName 'Should_Fail_When_OpenBiFixture_CT3'

Write-Host 'Assert-SiblingReadinessGate: ALL PASS'
exit 0
