#Requires -Version 5.1
<#
.SYNOPSIS
  Validate SESSION gate approval (repo or develop scope).

.DESCRIPTION
  REQ-014: structural gate reader matching SESSION.md hashing rules.
  Exit 0 = required gate is true; exit 1 = blocked (missing/false).

.PARAMETER RepoPath
  Repository root (hashed for repo session path).

.PARAMETER PlanPath
  Required for develop gates (step_confirmed / tests_run).

.PARAMETER Step
  Optional PLAN step for plan-{hash}-step-{N}.json scoping.

.PARAMETER RequiredGate
  storage_confirmed | write_confirmed | step_confirmed | tests_run

.PARAMETER SessionsRoot
  Sessions root (testable). Defaults to <SddRoot>/sessions when -SddRoot given.

.PARAMETER SddRoot
  Optional SDD runtime root; sessions = Join-Path SddRoot 'sessions'.

.EXAMPLE
  .\scripts\validation\validate-session-gates.ps1 -RepoPath . -SessionsRoot $env:TEMP\sdd-sessions -RequiredGate write_confirmed
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoPath,

    [string] $PlanPath,

    [ValidateRange(1, 9999)]
    [int] $Step = 0,

    [Parameter(Mandatory = $true)]
    [ValidateSet('storage_confirmed', 'write_confirmed', 'step_confirmed', 'tests_run')]
    [string] $RequiredGate,

    [string] $SessionsRoot,

    [string] $SddRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'ToolkitConstants.ps1')

$exitOk = [int]$script:ToolkitConstant.SessionGateValidateExitOk
$exitBlocked = [int]$script:ToolkitConstant.SessionGateValidateExitBlocked
$exitUsage = [int]$script:ToolkitConstant.SessionGateValidateExitUsage
$sessionsFolderName = [string]$script:ToolkitConstant.PlanLedgerSessionsFolderName

$repoGates = @('storage_confirmed', 'write_confirmed')
$developGates = @('step_confirmed', 'tests_run')

function Get-NormalizedPathForHash {
    param([Parameter(Mandatory = $true)][string] $PathValue)
    return $PathValue.Replace('\', '/').TrimEnd('/')
}

function Get-Sha256Hex16 {
    param([Parameter(Mandatory = $true)][string] $Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hash = $sha.ComputeHash($bytes)
        $hex = ([BitConverter]::ToString($hash)).Replace('-', '').ToLowerInvariant()
        return $hex.Substring(0, 16)
    }
    finally {
        $sha.Dispose()
    }
}

function Test-GateTrue {
    param($GatesObject, [string] $GateName)
    if ($null -eq $GatesObject) {
        return $false
    }
    $prop = $GatesObject.PSObject.Properties[$GateName]
    if ($null -eq $prop) {
        return $false
    }
    $value = $prop.Value
    if ($value -is [bool]) {
        return [bool]$value
    }
    if ($null -eq $value) {
        return $false
    }
    return ([string]$value).Equals('true', [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-HasPlanStepSessionFiles {
    param(
        [Parameter(Mandatory = $true)][string] $RepoSessionsDir,
        [Parameter(Mandatory = $true)][string] $PlanHash
    )
    if (-not (Test-Path -LiteralPath $RepoSessionsDir)) {
        return $false
    }
    $pattern = ('plan-{0}-step-*.json' -f $PlanHash)
    $hits = @(Get-ChildItem -LiteralPath $RepoSessionsDir -Filter $pattern -File -ErrorAction SilentlyContinue)
    return ($hits.Count -gt 0)
}

function Resolve-SessionsRootPath {
    if (-not [string]::IsNullOrWhiteSpace($SessionsRoot)) {
        return $SessionsRoot
    }
    if (-not [string]::IsNullOrWhiteSpace($SddRoot)) {
        return (Join-Path $SddRoot $sessionsFolderName)
    }
    Write-Error $script:ToolkitConstant.PlanLedgerSessionsRootRequired
    exit $exitUsage
}

if (-not (Test-Path -LiteralPath $RepoPath)) {
    Write-Error ($script:ToolkitConstant.PlanLedgerRepoPathMissing -f $RepoPath)
    exit $exitUsage
}

$repoResolved = (Resolve-Path -LiteralPath $RepoPath).Path
$sessionsResolvedCandidate = Resolve-SessionsRootPath
if (-not (Test-Path -LiteralPath $sessionsResolvedCandidate)) {
    Write-Host ($script:ToolkitConstant.SessionGateValidateBlockedFormat -f $RequiredGate, 'sessions_root_missing')
    exit $exitBlocked
}
$sessionsResolved = (Resolve-Path -LiteralPath $sessionsResolvedCandidate).Path

$repoHash = Get-Sha256Hex16 -Text (Get-NormalizedPathForHash -PathValue $repoResolved)

if ($repoGates -contains $RequiredGate) {
    $sessionPath = Join-Path $sessionsResolved ('{0}.json' -f $repoHash)
    if (-not (Test-Path -LiteralPath $sessionPath)) {
        Write-Host ($script:ToolkitConstant.SessionGateValidateBlockedFormat -f $RequiredGate, 'session_missing')
        exit $exitBlocked
    }
    $session = Get-Content -LiteralPath $sessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (Test-GateTrue -GatesObject $session.gates -GateName $RequiredGate) {
        Write-Host ($script:ToolkitConstant.SessionGateValidateOkFormat -f $RequiredGate)
        exit $exitOk
    }
    Write-Host ($script:ToolkitConstant.SessionGateValidateBlockedFormat -f $RequiredGate, 'gate_false')
    exit $exitBlocked
}

if ($developGates -contains $RequiredGate) {
    if ([string]::IsNullOrWhiteSpace($PlanPath)) {
        Write-Error $script:ToolkitConstant.SessionGateValidatePlanPathRequired
        exit $exitUsage
    }

    $planCandidate = $PlanPath
    if (-not [System.IO.Path]::IsPathRooted($planCandidate)) {
        $planCandidate = Join-Path $repoResolved ($PlanPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    }
    if (-not (Test-Path -LiteralPath $planCandidate)) {
        Write-Error ($script:ToolkitConstant.PlanLedgerPlanPathMissing -f $PlanPath)
        exit $exitUsage
    }

    $planResolved = (Resolve-Path -LiteralPath $planCandidate).Path
    $planHash = Get-Sha256Hex16 -Text (Get-NormalizedPathForHash -PathValue $planResolved)
    $repoSessionsDir = Join-Path $sessionsResolved $repoHash

    $useStepScope = $Step -gt 0
    if (-not $useStepScope -and (Test-HasPlanStepSessionFiles -RepoSessionsDir $repoSessionsDir -PlanHash $planHash)) {
        Write-Error $script:ToolkitConstant.DevelopSessionGateStepRequiredWhenParallelExists
        exit $exitUsage
    }

    if ($useStepScope) {
        $fileName = ('plan-{0}-step-{1}.json' -f $planHash, $Step)
    }
    else {
        $fileName = ('plan-{0}.json' -f $planHash)
    }

    $sessionPath = Join-Path $repoSessionsDir $fileName
    if (-not (Test-Path -LiteralPath $sessionPath)) {
        Write-Host ($script:ToolkitConstant.SessionGateValidateBlockedFormat -f $RequiredGate, 'session_missing')
        exit $exitBlocked
    }

    $session = Get-Content -LiteralPath $sessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (Test-GateTrue -GatesObject $session.gates -GateName $RequiredGate) {
        Write-Host ($script:ToolkitConstant.SessionGateValidateOkFormat -f $RequiredGate)
        exit $exitOk
    }
    Write-Host ($script:ToolkitConstant.SessionGateValidateBlockedFormat -f $RequiredGate, 'gate_false')
    exit $exitBlocked
}

Write-Error ($script:ToolkitConstant.SessionGateValidateUnknownGateFormat -f $RequiredGate)
exit $exitUsage
