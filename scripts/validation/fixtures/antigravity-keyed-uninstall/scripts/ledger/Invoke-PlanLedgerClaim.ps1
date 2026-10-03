#Requires -Version 5.1
<#
.SYNOPSIS
  Atomic PLAN step claim / status / release (PLAN-LEDGER).

.DESCRIPTION
  Implements REQ-002 / CA2: one active holder per PLAN step. Second claim fails
  with an auditable reason and audit.jsonl append. Does not mutate app code.

.PARAMETER Action
  claim | status | release

.PARAMETER PlanPath
  Absolute or repo-relative PLAN path.

.PARAMETER Step
  1-based PLAN step number.

.PARAMETER Holder
  Opaque holder id (required for claim and release).

.PARAMETER RepoPath
  Repository root used for repo-hash and portable plan_path.

.PARAMETER SessionsRoot
  Sessions root (testable). Defaults to <SddRoot>/sessions when -SddRoot given,
  else requires explicit -SessionsRoot.

.PARAMETER SddRoot
  Optional SDD runtime root; sessions = Join-Path SddRoot 'sessions'.

.EXAMPLE
  .\scripts\ledger\Invoke-PlanLedgerClaim.ps1 -Action claim -PlanPath features\006-x\TS01\PLAN\PLAN_006_x.md -Step 2 -Holder agent-A -RepoPath . -SessionsRoot $env:TEMP\adt-ledger
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('claim', 'status', 'release')]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $PlanPath,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 9999)]
    [int] $Step,

    [string] $Holder,

    [string] $RepoPath,

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

$exitClaimOk = [int]$script:ToolkitConstant.PlanLedgerExitClaimOk
$exitClaimRejected = [int]$script:ToolkitConstant.PlanLedgerExitClaimRejected
$exitUsage = [int]$script:ToolkitConstant.PlanLedgerExitUsage
$schemaId = [string]$script:ToolkitConstant.PlanLedgerClaimSchemaId
$statusClaimed = [string]$script:ToolkitConstant.PlanLedgerStatusClaimed
$statusReleased = [string]$script:ToolkitConstant.PlanLedgerStatusReleased
$reasonAlreadyClaimed = [string]$script:ToolkitConstant.PlanLedgerReasonStepAlreadyClaimed
$reasonHolderRequired = [string]$script:ToolkitConstant.PlanLedgerReasonHolderRequired
$reasonReleaseForbidden = [string]$script:ToolkitConstant.PlanLedgerReasonReleaseForbidden
$reasonNotClaimed = [string]$script:ToolkitConstant.PlanLedgerReasonNotClaimed
$eventClaimRejected = [string]$script:ToolkitConstant.PlanLedgerEventClaimRejected
$ledgerDirName = [string]$script:ToolkitConstant.PlanLedgerDirectoryName

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Get-NormalizedPathForHash {
    param([Parameter(Mandatory = $true)][string] $PathValue)
    $normalized = $PathValue.Replace('\', '/').TrimEnd('/')
    return $normalized
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

function Convert-ToPortablePlanPath {
    param(
        [Parameter(Mandatory = $true)][string] $FullPlanPath,
        [Parameter(Mandatory = $true)][string] $RepoRootPath
    )

    $repo = (Resolve-Path -LiteralPath $RepoRootPath).Path.TrimEnd('\', '/')
    $full = (Resolve-Path -LiteralPath $FullPlanPath).Path
    if ($full.StartsWith($repo, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $full.Substring($repo.Length).TrimStart('\', '/')
        return ($relative -replace '\\', '/')
    }

    return ($full -replace '\\', '/')
}

function Write-AuditLine {
    param(
        [Parameter(Mandatory = $true)][string] $AuditPath,
        [Parameter(Mandatory = $true)][hashtable] $Payload
    )

    $dir = Split-Path -Parent $AuditPath
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $line = ($Payload | ConvertTo-Json -Compress -Depth 6)
    $encoding = Get-Utf8NoBomEncoding
    [System.IO.File]::AppendAllText($AuditPath, ($line + [Environment]::NewLine), $encoding)
}

function Write-JsonResult {
    param([Parameter(Mandatory = $true)]$Object)
    $json = ($Object | ConvertTo-Json -Depth 6)
    Write-Output $json
}

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    $RepoPath = Get-ToolkitRepoRoot -FromPath $scriptDir
}

if (-not (Test-Path -LiteralPath $RepoPath)) {
    Write-Error ($script:ToolkitConstant.PlanLedgerRepoPathMissing -f $RepoPath)
    exit $exitUsage
}

$repoResolved = (Resolve-Path -LiteralPath $RepoPath).Path

if ([string]::IsNullOrWhiteSpace($SessionsRoot)) {
    if ([string]::IsNullOrWhiteSpace($SddRoot)) {
        Write-Error $script:ToolkitConstant.PlanLedgerSessionsRootRequired
        exit $exitUsage
    }
    $SessionsRoot = Join-Path $SddRoot $script:ToolkitConstant.PlanLedgerSessionsFolderName
}

if (-not (Test-Path -LiteralPath $SessionsRoot)) {
    New-Item -ItemType Directory -Path $SessionsRoot -Force | Out-Null
}

$sessionsResolved = (Resolve-Path -LiteralPath $SessionsRoot).Path

$planCandidate = $PlanPath
if (-not [System.IO.Path]::IsPathRooted($planCandidate)) {
    $planCandidate = Join-Path $repoResolved ($PlanPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

if (-not (Test-Path -LiteralPath $planCandidate)) {
    Write-Error ($script:ToolkitConstant.PlanLedgerPlanPathMissing -f $PlanPath)
    exit $exitUsage
}

$planResolved = (Resolve-Path -LiteralPath $planCandidate).Path
$portablePlan = Convert-ToPortablePlanPath -FullPlanPath $planResolved -RepoRootPath $repoResolved

$repoHash = Get-Sha256Hex16 -Text (Get-NormalizedPathForHash -PathValue $repoResolved)
$planHash = Get-Sha256Hex16 -Text (Get-NormalizedPathForHash -PathValue $planResolved)

$ledgerRoot = Join-Path (Join-Path $sessionsResolved $repoHash) $ledgerDirName
if (-not (Test-Path -LiteralPath $ledgerRoot)) {
    New-Item -ItemType Directory -Path $ledgerRoot -Force | Out-Null
}

$claimFileName = ('plan-{0}-step-{1}.claim.json' -f $planHash, $Step)
$auditFileName = ('plan-{0}-step-{1}.audit.jsonl' -f $planHash, $Step)
$claimPath = Join-Path $ledgerRoot $claimFileName
$auditPath = Join-Path $ledgerRoot $auditFileName

function Read-ClaimObject {
    param([Parameter(Mandatory = $true)][string] $Path)
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    return ($raw | ConvertFrom-Json)
}

switch ($Action) {
    'status' {
        if (-not (Test-Path -LiteralPath $claimPath)) {
            Write-JsonResult -Object @{
                ok        = $true
                free      = $true
                plan_path = $portablePlan
                step      = $Step
                status    = 'free'
            }
            exit $exitClaimOk
        }

        $existing = Read-ClaimObject -Path $claimPath
        Write-JsonResult -Object @{
            ok        = $true
            free      = $false
            plan_path = $portablePlan
            step      = $Step
            status    = [string]$existing.status
            holder    = [string]$existing.holder
            claimed_at = [string]$existing.claimed_at
        }
        exit $exitClaimOk
    }

    'release' {
        if ([string]::IsNullOrWhiteSpace($Holder)) {
            Write-Error $reasonHolderRequired
            exit $exitUsage
        }
        if (-not (Test-Path -LiteralPath $claimPath)) {
            Write-Error $reasonNotClaimed
            exit $exitClaimRejected
        }

        $existing = Read-ClaimObject -Path $claimPath
        if ([string]$existing.holder -ne $Holder) {
            Write-AuditLine -AuditPath $auditPath -Payload @{
                at               = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                event            = 'release_rejected'
                reason           = $reasonReleaseForbidden
                plan_path        = $portablePlan
                step             = $Step
                attempted_holder = $Holder
                existing_holder  = [string]$existing.holder
            }
            $msg = ($script:ToolkitConstant.PlanLedgerReleaseDeniedFormat -f $Holder, [string]$existing.holder)
            [Console]::Error.WriteLine($msg)
            exit $exitClaimRejected
        }

        Remove-Item -LiteralPath $claimPath -Force
        Write-JsonResult -Object @{
            ok        = $true
            released  = $true
            plan_path = $portablePlan
            step      = $Step
            holder    = $Holder
            status    = $statusReleased
        }
        exit $exitClaimOk
    }

    'claim' {
        if ([string]::IsNullOrWhiteSpace($Holder)) {
            Write-Error $reasonHolderRequired
            exit $exitUsage
        }

        $claimedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $claimObject = [ordered]@{
            schema     = $schemaId
            plan_path  = $portablePlan
            step       = $Step
            holder     = $Holder
            claimed_at = $claimedAt
            status     = $statusClaimed
        }
        $jsonBody = ($claimObject | ConvertTo-Json -Depth 6)
        $encoding = Get-Utf8NoBomEncoding
        $bytes = $encoding.GetBytes($jsonBody)

        try {
            $stream = [System.IO.File]::Open(
                $claimPath,
                [System.IO.FileMode]::CreateNew,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )
            try {
                $stream.Write($bytes, 0, $bytes.Length)
            }
            finally {
                $stream.Dispose()
            }
        }
        catch [System.IO.IOException] {
            $existingHolder = 'unknown'
            if (Test-Path -LiteralPath $claimPath) {
                try {
                    $existing = Read-ClaimObject -Path $claimPath
                    $existingHolder = [string]$existing.holder
                }
                catch {
                    $existingHolder = 'unreadable'
                }
            }

            Write-AuditLine -AuditPath $auditPath -Payload @{
                at               = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                event            = $eventClaimRejected
                reason           = $reasonAlreadyClaimed
                plan_path        = $portablePlan
                step             = $Step
                attempted_holder = $Holder
                existing_holder  = $existingHolder
            }
            $human = ($script:ToolkitConstant.PlanLedgerDoubleClaimFormat -f $Step, $existingHolder, $Holder)
            Write-Output $human
            [Console]::Error.WriteLine($human)
            exit $exitClaimRejected
        }

        Write-JsonResult -Object @{
            ok         = $true
            claimed    = $true
            plan_path  = $portablePlan
            step       = $Step
            holder     = $Holder
            claimed_at = $claimedAt
            status     = $statusClaimed
            claim_path = ($claimPath -replace '\\', '/')
        }
        exit $exitClaimOk
    }
}

Write-Error $script:ToolkitConstant.PlanLedgerUnknownAction
exit $exitUsage
