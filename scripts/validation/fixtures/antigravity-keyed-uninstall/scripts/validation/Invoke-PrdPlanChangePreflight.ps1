#Requires -Version 5.1
<#
.SYNOPSIS
  Preflight consistency gate for PRD → PLAN → CHANGE before O3 (REQ-004 / CA4).

.DESCRIPTION
  Deterministic checks only — no LLM. Invokes validate-prd / validate-plan /
  validate-change (does not replace them). Blocks O3 with an explicit reason
  code when inconsistent. Read-only: never mutates app or artifact files.

.PARAMETER FeatureRoot
  Absolute or repo-relative feature root (features/NNN-slug).

.PARAMETER PlanPath
  Absolute or relative PLAN path. Required.

.PARAMETER PrdPath
  Optional PRD path. When omitted, resolved from the PLAN header PRD field.

.PARAMETER ChangePath
  Optional CHANGE.md path. Defaults to <FeatureRoot>/CHANGE.md.

.PARAMETER Nature
  Optional FEATURE Nature override (brownfield|greenfield|operational).
  When omitted, read from FEATURE.md under FeatureRoot.

.PARAMETER RepoPath
  Optional repository root for portable path rendering.

.EXAMPLE
  .\scripts\validation\Invoke-PrdPlanChangePreflight.ps1 `
    -FeatureRoot features\006-skills-maturity-parity `
    -PlanPath features\006-skills-maturity-parity\TS01\PLAN\PLAN_006_operator_governance.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $FeatureRoot,

    [Parameter(Mandatory = $true)]
    [string] $PlanPath,

    [Parameter(Mandatory = $false)]
    [string] $PrdPath = '',

    [Parameter(Mandatory = $false)]
    [string] $ChangePath = '',

    [Parameter(Mandatory = $false)]
    [string] $Nature = '',

    [Parameter(Mandatory = $false)]
    [string] $RepoPath = ''
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
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
if (-not (Get-Command -Name Test-IsPathUnderOrEqual -ErrorAction SilentlyContinue)) {
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
}

$exitAllow = [int]$script:ToolkitConstant.PrdPlanChangePreflightExitAllow
$exitUsage = [int]$script:ToolkitConstant.PrdPlanChangePreflightExitUsage
$exitBlock = [int]$script:ToolkitConstant.PrdPlanChangePreflightExitBlock

$script:PrdHeaderRejectReason = $null

function Write-PreflightBlock {
    param(
        [Parameter(Mandatory = $true)][string] $Reason,
        [Parameter(Mandatory = $true)][string] $Detail
    )
    $msg = $script:ToolkitConstant.PrdPlanChangePreflightBlockFormat -f $Reason, $Detail
    Write-Output $msg
    exit $exitBlock
}

function Write-PreflightUsage {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Output ("preflight: USAGE - {0}" -f $Message)
    exit $exitUsage
}

function Resolve-ExistingPath {
    param([Parameter(Mandatory = $true)][string] $Candidate)
    if ([System.IO.Path]::IsPathRooted($Candidate)) {
        return $Candidate
    }
    return (Join-Path (Get-Location).Path $Candidate)
}

function Get-PortablePath {
    param(
        [Parameter(Mandatory = $true)][string] $AbsolutePath,
        [Parameter(Mandatory = $true)][string] $RepoRootPath
    )
    $full = Get-NormalizedFullPath -Path $AbsolutePath
    $root = (Get-NormalizedFullPath -Path $RepoRootPath).TrimEnd('\', '/')
    if (Test-IsPathUnderOrEqual -ChildPath $full -ParentPath $RepoRootPath) {
        $rel = $full.Substring($root.Length).TrimStart('\', '/')
        return ($rel -replace '\\', '/')
    }
    return ($full -replace '\\', '/')
}

function Test-PrdHeaderRelativePathSafe {
    param([Parameter(Mandatory = $true)][string] $RawPath)

    $script:PrdHeaderRejectReason = $null
    if ([string]::IsNullOrWhiteSpace($RawPath)) {
        return $false
    }

    if ([System.IO.Path]::IsPathRooted($RawPath)) {
        $script:PrdHeaderRejectReason = 'os_absolute'
        return $false
    }

    $portable = ($RawPath -replace '\\', '/')
    $parentSegment = [string]$script:ToolkitConstant.RelativeParentPathSegment
    $segments = @($portable -split '/')
    foreach ($segment in $segments) {
        if ($segment -eq $parentSegment) {
            $script:PrdHeaderRejectReason = 'parent_segment'
            return $false
        }
    }

    return $true
}

function Collect-SddReqIds {
    param([Parameter(Mandatory = $true)][string] $Text)
    $list = New-Object 'System.Collections.Generic.List[string]'
    $pattern = $script:ToolkitConstant.SddArtifactReqIdPattern
    foreach ($m in [regex]::Matches($Text, $pattern)) {
        $id = 'REQ-{0}' -f $m.Groups[1].Value.ToUpperInvariant()
        if (-not $list.Contains($id)) {
            [void]$list.Add($id)
        }
    }
    return $list
}

function Resolve-PrdPathFromPlan {
    param(
        [Parameter(Mandatory = $true)][string] $PlanText,
        [Parameter(Mandatory = $true)][string] $PlanFilePath,
        [Parameter(Mandatory = $true)][string] $RepoRootPath,
        [Parameter(Mandatory = $true)][string] $FeatureRootPath
    )
    $script:PrdHeaderRejectReason = $null
    $headerPattern = $script:ToolkitConstant.SddArtifactPrdHeaderPattern
    $headerMatch = [regex]::Match($PlanText, $headerPattern)
    if (-not $headerMatch.Success) {
        return $null
    }
    $raw = $headerMatch.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    if (-not (Test-PrdHeaderRelativePathSafe -RawPath $raw)) {
        return $null
    }

    $candidates = New-Object 'System.Collections.Generic.List[string]'
    [void]$candidates.Add((Join-Path (Get-Location).Path $raw))
    [void]$candidates.Add((Join-Path $RepoRootPath ($raw -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    $planDir = Split-Path -Parent $PlanFilePath
    [void]$candidates.Add((Join-Path $planDir $raw))
    $storyDir = Split-Path -Parent $planDir
    [void]$candidates.Add((Join-Path $storyDir ($raw -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    $featureDir = Split-Path -Parent $storyDir
    if ($raw -like 'features/*' -or $raw -like 'features\*') {
        $featuresParent = Split-Path -Parent $featureDir
        [void]$candidates.Add((Join-Path $featuresParent $raw))
    }

    foreach ($candidate in $candidates) {
        if (-not (Test-Path -LiteralPath $candidate)) {
            continue
        }

        $resolved = (Resolve-Path -LiteralPath $candidate).Path
        if (-not (Test-IsPathUnderOrEqual -ChildPath $resolved -ParentPath $FeatureRootPath)) {
            $script:PrdHeaderRejectReason = 'outside_feature_root'
            return $null
        }

        return $resolved
    }

    return $null
}

function Invoke-ChildValidator {
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
        Output   = $output.Trim()
    }
}

function Get-FileNnn {
    param(
        [Parameter(Mandatory = $true)][string] $FileName,
        [Parameter(Mandatory = $true)][string] $Pattern
    )
    $m = [regex]::Match($FileName, $Pattern)
    if ($m.Success) {
        return $m.Groups[1].Value
    }
    return $null
}

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    $repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
}
else {
    $repoRoot = Resolve-ExistingPath -Candidate $RepoPath
    if (-not (Test-Path -LiteralPath $repoRoot)) {
        Write-PreflightUsage -Message ("RepoPath not found: {0}" -f $RepoPath)
    }
}

$resolvedFeature = Resolve-ExistingPath -Candidate $FeatureRoot
if (-not (Test-Path -LiteralPath $resolvedFeature)) {
    Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonFeatureMissing -Detail (Get-PortablePath -AbsolutePath $resolvedFeature -RepoRootPath $repoRoot)
}

$resolvedPlan = Resolve-ExistingPath -Candidate $PlanPath
if (-not (Test-Path -LiteralPath $resolvedPlan)) {
    Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonPlanMissing -Detail (Get-PortablePath -AbsolutePath $resolvedPlan -RepoRootPath $repoRoot)
}

$planText = Get-Content -LiteralPath $resolvedPlan -Raw -Encoding UTF8
$resolvedPrd = $null
if (-not [string]::IsNullOrWhiteSpace($PrdPath)) {
    $resolvedPrd = Resolve-ExistingPath -Candidate $PrdPath
    if (-not [string]::IsNullOrWhiteSpace($resolvedPrd) -and (Test-Path -LiteralPath $resolvedPrd)) {
        if (-not (Test-IsPathUnderOrEqual -ChildPath $resolvedPrd -ParentPath $resolvedFeature)) {
            Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonPrdPathEscape -Detail (Get-PortablePath -AbsolutePath $resolvedPrd -RepoRootPath $repoRoot)
        }
    }
}
else {
    $resolvedPrd = Resolve-PrdPathFromPlan -PlanText $planText -PlanFilePath $resolvedPlan -RepoRootPath $repoRoot -FeatureRootPath $resolvedFeature
    if ([string]::IsNullOrWhiteSpace($resolvedPrd) -and -not [string]::IsNullOrWhiteSpace($script:PrdHeaderRejectReason)) {
        $detail = ('header_reject={0}' -f $script:PrdHeaderRejectReason)
        Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonPrdPathEscape -Detail $detail
    }
}
if ([string]::IsNullOrWhiteSpace($resolvedPrd) -or -not (Test-Path -LiteralPath $resolvedPrd)) {
    $detail = if ([string]::IsNullOrWhiteSpace($PrdPath)) { 'unresolved from PLAN header' } else { Get-PortablePath -AbsolutePath $resolvedPrd -RepoRootPath $repoRoot }
    Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonPrdMissing -Detail $detail
}

if ([string]::IsNullOrWhiteSpace($ChangePath)) {
    $resolvedChange = Join-Path $resolvedFeature $script:ToolkitConstant.PrdPlanChangePreflightChangeFileName
}
else {
    $resolvedChange = Resolve-ExistingPath -Candidate $ChangePath
}

$portablePlan = Get-PortablePath -AbsolutePath $resolvedPlan -RepoRootPath $repoRoot
$portablePrd = Get-PortablePath -AbsolutePath $resolvedPrd -RepoRootPath $repoRoot
$portableChange = Get-PortablePath -AbsolutePath $resolvedChange -RepoRootPath $repoRoot

$natureValue = $Nature
if ([string]::IsNullOrWhiteSpace($natureValue)) {
    $featureMd = Join-Path $resolvedFeature $script:ToolkitConstant.PrdPlanChangePreflightFeatureFileName
    if (Test-Path -LiteralPath $featureMd) {
        $featureText = Get-Content -LiteralPath $featureMd -Raw -Encoding UTF8
        $natureMatch = [regex]::Match($featureText, $script:ToolkitConstant.PrdPlanChangePreflightFeatureNaturePattern)
        if ($natureMatch.Success) {
            $natureValue = $natureMatch.Groups[1].Value.Trim().ToLowerInvariant()
        }
    }
}
else {
    $natureValue = $natureValue.Trim().ToLowerInvariant()
}

$validatePrdPath = Join-Path $scriptDir $script:ToolkitConstant.ValidatePrdScriptName
$validatePlanPath = Join-Path $scriptDir $script:ToolkitConstant.ValidatePlanScriptName
$validateChangePath = Join-Path $scriptDir $script:ToolkitConstant.ValidateChangeScriptName

$prdResult = Invoke-ChildValidator -ScriptPath $validatePrdPath -Arguments @{ Path = $resolvedPrd }
if ($prdResult.ExitCode -ne 0) {
    Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonValidatePrd -Detail ("{0} :: {1}" -f $portablePrd, $prdResult.Output)
}

$planResult = Invoke-ChildValidator -ScriptPath $validatePlanPath -Arguments @{ Path = $resolvedPlan; PrdPath = $resolvedPrd }
if ($planResult.ExitCode -ne 0) {
    Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonValidatePlan -Detail ("{0} :: {1}" -f $portablePlan, $planResult.Output)
}

$prdText = Get-Content -LiteralPath $resolvedPrd -Raw -Encoding UTF8
$prdReqs = Collect-SddReqIds -Text $prdText
$planReqs = Collect-SddReqIds -Text $planText
$orphans = New-Object 'System.Collections.Generic.List[string]'
foreach ($planReq in $planReqs) {
    if (-not $prdReqs.Contains($planReq)) {
        [void]$orphans.Add($planReq)
    }
}
if ($orphans.Count -gt 0) {
    $detail = ("plan={0}; orphan={1}" -f $portablePlan, ([string]::Join(',', $orphans.ToArray())))
    Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonOrphanReq -Detail $detail
}

$prdNnn = Get-FileNnn -FileName ([System.IO.Path]::GetFileName($resolvedPrd)) -Pattern $script:ToolkitConstant.PrdPlanChangePreflightPrdFileNnnPattern
$planNnn = Get-FileNnn -FileName ([System.IO.Path]::GetFileName($resolvedPlan)) -Pattern $script:ToolkitConstant.PrdPlanChangePreflightPlanFileNnnPattern
if (-not [string]::IsNullOrWhiteSpace($prdNnn) -and -not [string]::IsNullOrWhiteSpace($planNnn) -and ($prdNnn -ne $planNnn)) {
    $detail = ("prd_nnn={0}; plan_nnn={1}; prd={2}; plan={3}" -f $prdNnn, $planNnn, $portablePrd, $portablePlan)
    Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonNnnMismatch -Detail $detail
}

$featureLeaf = Split-Path -Leaf $resolvedFeature
$featureNnnMatch = [regex]::Match($featureLeaf, '^(?i)(\d{3})-')
if ($featureNnnMatch.Success -and -not [string]::IsNullOrWhiteSpace($planNnn)) {
    $featureNnn = $featureNnnMatch.Groups[1].Value
    if ($featureNnn -ne $planNnn) {
        $detail = ("feature_nnn={0}; plan_nnn={1}; plan={2}" -f $featureNnn, $planNnn, $portablePlan)
        Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonNnnMismatch -Detail $detail
    }
}

$brownfield = $script:ToolkitConstant.PrdPlanChangePreflightNatureBrownfield
if ($natureValue -eq $brownfield) {
    if (-not (Test-Path -LiteralPath $resolvedChange)) {
        Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonChangeMissing -Detail $portableChange
    }
    $changeResult = Invoke-ChildValidator -ScriptPath $validateChangePath -Arguments @{ Path = $resolvedChange }
    if ($changeResult.ExitCode -ne 0) {
        $detail = ("{0} :: {1}" -f $portableChange, $changeResult.Output)
        Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonChangeInvalid -Detail $detail
    }
}
elseif ((Test-Path -LiteralPath $resolvedChange)) {
    $changeResult = Invoke-ChildValidator -ScriptPath $validateChangePath -Arguments @{ Path = $resolvedChange }
    if ($changeResult.ExitCode -ne 0) {
        $detail = ("{0} :: {1}" -f $portableChange, $changeResult.Output)
        Write-PreflightBlock -Reason $script:ToolkitConstant.PrdPlanChangePreflightReasonValidateChange -Detail $detail
    }
}

$allowMsg = $script:ToolkitConstant.PrdPlanChangePreflightAllowFormat -f $portablePlan, $portablePrd, $(if (Test-Path -LiteralPath $resolvedChange) { $portableChange } else { '(none)' })
Write-Output $allowMsg
exit $exitAllow
