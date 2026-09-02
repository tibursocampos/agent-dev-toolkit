#Requires -Version 5.1
# Tests:
#   Should_Pass_When_AxesNormativeProsePresentInContracts (CT5 / REQ-007 / CA4)
#   Should_Pass_When_AxisASpawnChoicePreserved (CT5 / RN01)
#   Should_Pass_When_AxisBCModelLockPresent (CT5 / RN02)
#
# Prose smoke: A≠B≠C normative markers across SUBAGENT-MODEL / SPAWN / router / orchestrator-session.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'

$script:AxesMarkerPattern = 'A\s*[\u2260!=]+\s*B\s*[\u2260!=]+\s*C'
$script:ThinTrivialMarker = 'Thin trivial'
$script:InParentMarker = 'in-parent'
$script:OmitModelMarker = 'omit'
$script:InheritOrSameMarkerPattern = '(?i)(inherit|same model as (the )?parent|same as parent)'
$script:SilenceNotApprovalPattern = '(?i)[Ss]ilence\s*[\u2260!=]+\s*approval'
$script:NoPinChildPattern = '(?i)(does\s+\*{0,2}not\*{0,2}\s+pin|pinning child model|child model\s*[\u2260!=]+\s*parent|filho\s*[\u2260!=]+\s*pai)'
$script:DoesNotDecideSpawnPattern = '(?i)does not decide spawn'
$script:AxisAPreservePattern = '(?i)(never remove spawn choice|Thin trivial exception intact)'
$script:AxisTokenPattern = '(?i)(Axis\s+\*{{0,2}}{0}\*{{0,2}}|\|\s*\*\*{0}\*\*\s*\|)'
$script:Utf8 = New-Object System.Text.UTF8Encoding $false

$script:RelativePaths = @(
    'core/skills/_shared/agents/SUBAGENT-MODEL.md',
    'core/skills/_shared/agents/SPAWN.md',
    'core/router/AGENTS.md',
    'core/policy/orchestrator-session.md'
)

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

function Get-ContractText {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )
    $path = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Fail -TestName 'Assert-InvocationAxesPreconditions' -Reason ("missing {0}" -f $RelativePath)
    }
    return [System.IO.File]::ReadAllText($path, $script:Utf8)
}

function Test-AxisTokenPresent {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $AxisLetter
    )
    $pattern = ($script:AxisTokenPattern -f $AxisLetter)
    return ($Text -match $pattern)
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-InvocationAxesPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$texts = @{}
foreach ($rel in $script:RelativePaths) {
    $texts[$rel] = Get-ContractText -RepoRoot $repoRoot -RelativePath $rel
}

# --- Should_Pass_When_AxesNormativeProsePresentInContracts ---
$proseName = 'Should_Pass_When_AxesNormativeProsePresentInContracts'
foreach ($rel in $script:RelativePaths) {
    $text = $texts[$rel]
    if ($text -notmatch $script:AxesMarkerPattern) {
        Write-Fail -TestName $proseName -Reason ("{0} missing marker A!=B!=C / A≠B≠C" -f $rel)
    }
    if (-not (Test-AxisTokenPresent -Text $text -AxisLetter 'A')) {
        Write-Fail -TestName $proseName -Reason ("{0} missing Axis A token" -f $rel)
    }
    if (-not (Test-AxisTokenPresent -Text $text -AxisLetter 'B')) {
        Write-Fail -TestName $proseName -Reason ("{0} missing Axis B token" -f $rel)
    }
    if (-not (Test-AxisTokenPresent -Text $text -AxisLetter 'C')) {
        Write-Fail -TestName $proseName -Reason ("{0} missing Axis C token" -f $rel)
    }
}
Write-Pass -TestName $proseName

# --- Should_Pass_When_AxisASpawnChoicePreserved ---
$axisAName = 'Should_Pass_When_AxisASpawnChoicePreserved'
$spawnText = $texts['core/skills/_shared/agents/SPAWN.md']
$subagentText = $texts['core/skills/_shared/agents/SUBAGENT-MODEL.md']
if ($spawnText -notmatch [regex]::Escape($script:ThinTrivialMarker)) {
    Write-Fail -TestName $axisAName -Reason 'SPAWN.md missing Thin trivial exception (Axis A choice)'
}
if ($spawnText -notmatch [regex]::Escape($script:InParentMarker)) {
    Write-Fail -TestName $axisAName -Reason 'SPAWN.md missing in-parent path (Axis A choice)'
}
if ($spawnText -notmatch $script:AxisAPreservePattern) {
    Write-Fail -TestName $axisAName -Reason 'SPAWN.md missing explicit Axis A preservation wording'
}
if ($subagentText -notmatch $script:DoesNotDecideSpawnPattern) {
    Write-Fail -TestName $axisAName -Reason 'SUBAGENT-MODEL.md must state it does not decide spawn (A≠B)'
}
Write-Pass -TestName $axisAName

# --- Should_Pass_When_AxisBCModelLockPresent ---
$axisBCName = 'Should_Pass_When_AxisBCModelLockPresent'
if ($subagentText -notmatch [regex]::Escape($script:OmitModelMarker)) {
    Write-Fail -TestName $axisBCName -Reason 'SUBAGENT-MODEL.md missing omit model default (Axis B)'
}
if ($subagentText -notmatch $script:InheritOrSameMarkerPattern) {
    Write-Fail -TestName $axisBCName -Reason 'SUBAGENT-MODEL.md missing inherit/same-as-parent wording (Axis B)'
}
if ($subagentText -notmatch $script:SilenceNotApprovalPattern) {
    Write-Fail -TestName $axisBCName -Reason 'SUBAGENT-MODEL.md missing silence≠approval (Axis C)'
}
$policyText = $texts['core/policy/orchestrator-session.md']
if ($policyText -notmatch [regex]::Escape($script:OmitModelMarker)) {
    Write-Fail -TestName $axisBCName -Reason 'orchestrator-session.md missing omit model default (Axis B)'
}
if ($spawnText -notmatch $script:NoPinChildPattern) {
    Write-Fail -TestName $axisBCName -Reason 'SPAWN.md must forbid pin child≠parent (Axis B/C boundary)'
}
Write-Pass -TestName $axisBCName

Write-Host 'Assert-InvocationAxes: ALL PASS'
exit 0
