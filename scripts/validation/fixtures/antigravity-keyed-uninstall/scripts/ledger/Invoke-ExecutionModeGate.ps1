#Requires -Version 5.1
<#
.SYNOPSIS
  Gate orchestrate-develop spawn intents against declared execution modes (REQ-003 / CA3).

.DESCRIPTION
  Honors serial | parallel | manual. Rejects invalid mode/intent pairings with an
  auditable JSONL trail. When the spawn is allowed, requires a successful
  PLAN-LEDGER claim (PASSO 2 integration).

.PARAMETER Mode
  Declared execution mode: serial | parallel | manual

.PARAMETER Intent
  serial-spawn | parallel-spawn | manual-handoff

.PARAMETER PlanPath
  PLAN path (required for claim on allowed Task spawn intents).

.PARAMETER Step
  1-based step number (required with PlanPath for claim).

.PARAMETER Holder
  Ledger holder id (required for claim on allowed Task spawn).

.PARAMETER RepoPath
  Repository root for ledger hashing.

.PARAMETER SessionsRoot
  Sessions root (testable). Defaults via -SddRoot when provided.

.PARAMETER SddRoot
  Optional SDD runtime root; sessions = <SddRoot>/sessions.

.PARAMETER SkipClaim
  Test-only: skip ledger claim after mode allow (Assert uses claim path by default).

.EXAMPLE
  .\scripts\ledger\Invoke-ExecutionModeGate.ps1 -Mode serial -Intent parallel-spawn -PlanPath features\x\PLAN\PLAN_x.md -Step 3 -SessionsRoot $env:TEMP\adt-mode -RepoPath .
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Mode,

    [Parameter(Mandatory = $true)]
    [ValidateSet('serial-spawn', 'parallel-spawn', 'manual-handoff')]
    [string] $Intent,

    [string] $PlanPath,

    [ValidateRange(1, 9999)]
    [int] $Step = 0,

    [string] $Holder,

    [string] $RepoPath,

    [string] $SessionsRoot,

    [string] $SddRoot,

    [switch] $SkipClaim
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

$exitOk = [int]$script:ToolkitConstant.ExecutionModeExitOk
$exitRejected = [int]$script:ToolkitConstant.ExecutionModeExitRejected
$exitUsage = [int]$script:ToolkitConstant.ExecutionModeExitUsage
$ledgerDirName = [string]$script:ToolkitConstant.PlanLedgerDirectoryName
$sessionsFolder = [string]$script:ToolkitConstant.PlanLedgerSessionsFolderName
$auditFileName = [string]$script:ToolkitConstant.ExecutionModeAuditFileName
$eventRejected = [string]$script:ToolkitConstant.ExecutionModeEventRejected
$reasonUnknown = [string]$script:ToolkitConstant.ExecutionModeReasonUnknown
$reasonParallelForbidden = [string]$script:ToolkitConstant.ExecutionModeReasonParallelForbidden
$reasonTaskForbidden = [string]$script:ToolkitConstant.ExecutionModeReasonTaskSpawnForbidden
$reasonClaimRequired = [string]$script:ToolkitConstant.ExecutionModeReasonClaimRequired
$allowedModes = @($script:ToolkitConstant.ExecutionModeAllowedIds)

function Get-NormalizedRepoPath {
    param([string] $Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-ToolkitRepoRoot -FromPath $scriptDir
    }
    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', '/').TrimEnd('/')
}

function Get-RepoHash {
    param([string] $NormalizedRepo)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($NormalizedRepo)
        $hash = $sha.ComputeHash($bytes)
        return ([BitConverter]::ToString($hash) -replace '-', '').Substring(0, 16).ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Resolve-SessionsRoot {
    if (-not [string]::IsNullOrWhiteSpace($SessionsRoot)) {
        return [System.IO.Path]::GetFullPath($SessionsRoot)
    }
    if (-not [string]::IsNullOrWhiteSpace($SddRoot)) {
        return Join-Path ([System.IO.Path]::GetFullPath($SddRoot)) $sessionsFolder
    }
    Write-Error $script:ToolkitConstant.PlanLedgerSessionsRootRequired
    exit $exitUsage
}

function Write-ModeAudit {
    param(
        [string] $AuditPath,
        [string] $Reason,
        [string] $ResolvedMode,
        [string] $ResolvedIntent,
        [string] $PortablePlan,
        [int] $StepNumber
    )

    $dir = Split-Path -Parent $AuditPath
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $lineObj = [ordered]@{
        at        = [DateTime]::UtcNow.ToString('o')
        event     = $eventRejected
        reason    = $Reason
        mode      = $ResolvedMode
        intent    = $ResolvedIntent
        plan_path = $PortablePlan
        step      = $StepNumber
    }
    $json = ($lineObj | ConvertTo-Json -Compress)
    Add-Content -LiteralPath $AuditPath -Value $json -Encoding UTF8
}

function Get-PortablePlanPath {
    param(
        [string] $AbsolutePlan,
        [string] $NormalizedRepo
    )
    $normPlan = ($AbsolutePlan -replace '\\', '/')
    $prefix = $NormalizedRepo + '/'
    if ($normPlan.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $normPlan.Substring($prefix.Length)
    }
    return $normPlan
}

$modeNorm = $Mode.Trim().ToLowerInvariant()
$intentNorm = $Intent.Trim().ToLowerInvariant()

$repoNormalized = Get-NormalizedRepoPath -Path $RepoPath
$sessionsResolved = Resolve-SessionsRoot
$repoHash = Get-RepoHash -NormalizedRepo $repoNormalized
$ledgerDir = Join-Path (Join-Path $sessionsResolved $repoHash) $ledgerDirName
$auditPath = Join-Path $ledgerDir $auditFileName

$portablePlan = ''
$stepNumber = 0
if (-not [string]::IsNullOrWhiteSpace($PlanPath)) {
    if (-not (Test-Path -LiteralPath $PlanPath)) {
        $candidate = Join-Path $repoNormalized ($PlanPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $candidate) {
            $PlanPath = $candidate
        }
    }
    if (-not (Test-Path -LiteralPath $PlanPath)) {
        Write-Error ($script:ToolkitConstant.PlanLedgerPlanPathMissing -f $PlanPath)
        exit $exitUsage
    }
    $PlanPath = [System.IO.Path]::GetFullPath($PlanPath)
    $portablePlan = Get-PortablePlanPath -AbsolutePlan $PlanPath -NormalizedRepo $repoNormalized
    $stepNumber = $Step
}

if ($allowedModes -notcontains $modeNorm) {
    Write-ModeAudit -AuditPath $auditPath -Reason $reasonUnknown -ResolvedMode $modeNorm -ResolvedIntent $intentNorm -PortablePlan $portablePlan -StepNumber $stepNumber
    $human = ($script:ToolkitConstant.ExecutionModeRejectFormat -f $reasonUnknown, $modeNorm, $intentNorm)
    Write-Output $human
    [Console]::Error.WriteLine($human)
    exit $exitRejected
}

$allowed = $false
$rejectReason = $null

switch ($modeNorm) {
    'serial' {
        if ($intentNorm -eq 'serial-spawn' -or $intentNorm -eq 'manual-handoff') {
            $allowed = $true
        }
        elseif ($intentNorm -eq 'parallel-spawn') {
            $rejectReason = $reasonParallelForbidden
        }
    }
    'parallel' {
        if ($intentNorm -eq 'parallel-spawn' -or $intentNorm -eq 'serial-spawn' -or $intentNorm -eq 'manual-handoff') {
            $allowed = $true
        }
    }
    'manual' {
        if ($intentNorm -eq 'manual-handoff') {
            $allowed = $true
        }
        elseif ($intentNorm -eq 'serial-spawn' -or $intentNorm -eq 'parallel-spawn') {
            $rejectReason = $reasonTaskForbidden
        }
    }
}

if (-not $allowed) {
    if ([string]::IsNullOrWhiteSpace($rejectReason)) {
        $rejectReason = $reasonUnknown
    }
    Write-ModeAudit -AuditPath $auditPath -Reason $rejectReason -ResolvedMode $modeNorm -ResolvedIntent $intentNorm -PortablePlan $portablePlan -StepNumber $stepNumber
    $human = ($script:ToolkitConstant.ExecutionModeRejectFormat -f $rejectReason, $modeNorm, $intentNorm)
    Write-Output $human
    [Console]::Error.WriteLine($human)
    exit $exitRejected
}

$needsClaim = ($intentNorm -eq 'serial-spawn' -or $intentNorm -eq 'parallel-spawn') -and -not $SkipClaim
if ($needsClaim) {
    if ([string]::IsNullOrWhiteSpace($PlanPath) -or $Step -lt 1 -or [string]::IsNullOrWhiteSpace($Holder)) {
        Write-ModeAudit -AuditPath $auditPath -Reason $reasonClaimRequired -ResolvedMode $modeNorm -ResolvedIntent $intentNorm -PortablePlan $portablePlan -StepNumber $stepNumber
        $human = ($script:ToolkitConstant.ExecutionModeRejectFormat -f $reasonClaimRequired, $modeNorm, $intentNorm)
        Write-Output $human
        [Console]::Error.WriteLine($human)
        exit $exitRejected
    }

    $claimScript = Join-Path $scriptDir 'Invoke-PlanLedgerClaim.ps1'
    if (-not (Test-Path -LiteralPath $claimScript)) {
        Write-Output ("missing PLAN-LEDGER claim script: {0}" -f $claimScript)
        [Console]::Error.WriteLine(("missing PLAN-LEDGER claim script: {0}" -f $claimScript))
        exit $exitUsage
    }

    $claimOut = & $claimScript -Action claim -PlanPath $PlanPath -Step $Step -Holder $Holder -RepoPath $repoNormalized -SessionsRoot $sessionsResolved 2>&1 | Out-String
    $claimCode = $LASTEXITCODE
    if ($null -eq $claimCode) { $claimCode = 0 }
    if ($claimCode -ne [int]$script:ToolkitConstant.PlanLedgerExitClaimOk) {
        Write-ModeAudit -AuditPath $auditPath -Reason $reasonClaimRequired -ResolvedMode $modeNorm -ResolvedIntent $intentNorm -PortablePlan $portablePlan -StepNumber $Step
        $human = ($script:ToolkitConstant.ExecutionModeRejectFormat -f $reasonClaimRequired, $modeNorm, $intentNorm)
        Write-Output ($human + ' ' + $claimOut)
        [Console]::Error.WriteLine($human)
        exit $exitRejected
    }
}

$result = [ordered]@{
    schema = [string]$script:ToolkitConstant.ExecutionModeGateSchemaId
    mode   = $modeNorm
    intent = $intentNorm
    status = 'allowed'
    reason = [string]$script:ToolkitConstant.ExecutionModeReasonOk
}
$result | ConvertTo-Json -Compress
exit $exitOk
