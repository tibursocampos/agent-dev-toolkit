#Requires -Version 5.1
<#
.SYNOPSIS
  Structural validation for Classic SDD PLAN markdown (REQ-003 / CA2).

.DESCRIPTION
  Deterministic checks only — no LLM. Requires a REQ->step map and full coverage
  of every REQ-NNN from the linked PRD. Exit 0 on success; exit 1 on failure.

.PARAMETER Path
  Absolute or relative path to a PLAN .md file.

.PARAMETER PrdPath
  Optional PRD path. When omitted, resolved from the PLAN header PRD field when present.

.EXAMPLE
  .\scripts\validation\validate-plan.ps1 -Path features\005-x\US01\PLAN\PLAN_005_x.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $false)]
    [string] $PrdPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')

function Write-ValidateFail {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-plan: FAIL - {0}" -f $Message) -ForegroundColor Red
}

function Write-ValidatePass {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-plan: PASS - {0}" -f $Message) -ForegroundColor Green
}

function Resolve-ExistingPath {
    param([Parameter(Mandatory = $true)][string] $Candidate)
    if ([System.IO.Path]::IsPathRooted($Candidate)) {
        return $Candidate
    }
    return (Join-Path (Get-Location).Path $Candidate)
}

function Collect-SddReqIdsIntoList {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]] $Target
    )
    $pattern = $script:ToolkitConstant.SddArtifactReqIdPattern
    $reqMatchList = [regex]::Matches($Text, $pattern)
    foreach ($reqMatch in $reqMatchList) {
        $id = 'REQ-{0}' -f $reqMatch.Groups[1].Value.ToUpperInvariant()
        if (-not $Target.Contains($id)) {
            [void]$Target.Add($id)
        }
    }
}

function Resolve-PrdPathFromPlan {
    param(
        [Parameter(Mandatory = $true)][string] $PlanText,
        [Parameter(Mandatory = $true)][string] $PlanFilePath
    )
    $headerPattern = $script:ToolkitConstant.SddArtifactPrdHeaderPattern
    $headerMatch = [regex]::Match($PlanText, $headerPattern)
    if (-not $headerMatch.Success) {
        return $null
    }
    $raw = $headerMatch.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    if ([System.IO.Path]::IsPathRooted($raw)) {
        [void]$candidates.Add($raw)
    }
    else {
        [void]$candidates.Add((Join-Path (Get-Location).Path $raw))
        $planDir = Split-Path -Parent $PlanFilePath
        [void]$candidates.Add((Join-Path $planDir $raw))
        $storyDir = Split-Path -Parent $planDir
        $featureDir = Split-Path -Parent $storyDir
        $featuresParent = Split-Path -Parent $featureDir
        if ($raw -like 'features/*' -or $raw -like 'features\*') {
            [void]$candidates.Add((Join-Path $featuresParent $raw))
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return $null
}

$resolvedPlan = Resolve-ExistingPath -Candidate $Path
if (-not (Test-Path -LiteralPath $resolvedPlan)) {
    Write-ValidateFail -Message ("file not found: {0}" -f $Path)
    exit 1
}

$planItem = Get-Item -LiteralPath $resolvedPlan
if ($planItem.Length -le 0) {
    Write-ValidateFail -Message ("empty file: {0}" -f $resolvedPlan)
    exit 1
}

$planText = Get-Content -LiteralPath $resolvedPlan -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($planText)) {
    Write-ValidateFail -Message ("empty content: {0}" -f $resolvedPlan)
    exit 1
}

$mapSectionPattern = $script:ToolkitConstant.SddArtifactReqMapSectionPattern
if ($planText -notmatch $mapSectionPattern) {
    Write-ValidateFail -Message 'missing REQ-to-step map section (expected "Mapa REQ -> passo" or equivalent)'
    exit 1
}

$planReqIds = New-Object 'System.Collections.Generic.List[string]'
Collect-SddReqIdsIntoList -Text $planText -Target $planReqIds
if ($planReqIds.Count -lt 1) {
    Write-ValidateFail -Message 'REQ-to-step map has no REQ-NNN identifiers'
    exit 1
}

$resolvedPrd = $null
if (-not [string]::IsNullOrWhiteSpace($PrdPath)) {
    $resolvedPrd = Resolve-ExistingPath -Candidate $PrdPath
    if (-not (Test-Path -LiteralPath $resolvedPrd)) {
        Write-ValidateFail -Message ("PRD file not found: {0}" -f $PrdPath)
        exit 1
    }
}
else {
    $resolvedPrd = Resolve-PrdPathFromPlan -PlanText $planText -PlanFilePath $resolvedPlan
}

if ([string]::IsNullOrWhiteSpace($resolvedPrd)) {
    Write-ValidateFail -Message 'cannot resolve PRD path (pass -PrdPath or set PLAN header PRD to an existing portable path)'
    exit 1
}

$prdText = Get-Content -LiteralPath $resolvedPrd -Raw -Encoding UTF8
$prdReqIds = New-Object 'System.Collections.Generic.List[string]'
Collect-SddReqIdsIntoList -Text $prdText -Target $prdReqIds
if ($prdReqIds.Count -lt 1) {
    Write-ValidateFail -Message ("linked PRD has no REQ-NNN identifiers: {0}" -f $resolvedPrd)
    exit 1
}

$missing = New-Object 'System.Collections.Generic.List[string]'
foreach ($prdReqId in $prdReqIds) {
    if (-not $planReqIds.Contains($prdReqId)) {
        [void]$missing.Add($prdReqId)
    }
}
if ($missing.Count -gt 0) {
    Write-ValidateFail -Message ("PLAN omits REQ coverage for: {0}" -f ([string]::Join(', ', $missing.ToArray())))
    exit 1
}

Write-ValidatePass -Message ("REQ map covers {0} PRD REQ id(s)" -f $prdReqIds.Count)
exit 0
