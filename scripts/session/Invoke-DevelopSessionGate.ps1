#Requires -Version 5.1
<#
.SYNOPSIS
  Idempotent develop-session gate helper (set step_confirmed).

.DESCRIPTION
  Implements REQ-011 / CA4: resolve PLAN-scoped develop session per SESSION.md,
  create schema defaults when missing, set gates.step_confirmed = true.
  When step_confirmed is already true, exit 0 without rewriting the file (CT5).
  Does not claim or mutate PLAN-LEDGER (RN04) — use Invoke-PlanLedgerClaim.ps1.

.PARAMETER PlanPath
  Absolute or repo-relative PLAN path (or docs/documentation-plan/plan.md).

.PARAMETER RepoPath
  Repository root used for repo-hash. Defaults via Get-ToolkitRepoRoot.

.PARAMETER SessionsRoot
  Sessions root (testable). Defaults to <SddRoot>/sessions when -SddRoot given,
  else requires explicit -SessionsRoot.

.PARAMETER SddRoot
  Optional SDD runtime root; sessions = Join-Path SddRoot 'sessions'.

.PARAMETER Step
  Optional 1-based PLAN step for PLAN+step session files
  (plan-{planHash}-step-{N}.json). Required when any plan-{planHash}-step-*.json
  already exists for this PLAN.

.PARAMETER CurrentStep
  Optional value written to current_step when creating/updating (default: Step or null).

.PARAMETER Action
  ensure (default) | status

.EXAMPLE
  .\scripts\session\Invoke-DevelopSessionGate.ps1 -PlanPath features\006-x\US01\PLAN\PLAN_006_x.md -RepoPath . -SessionsRoot $env:TEMP\adt-sessions
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $PlanPath,

    [string] $RepoPath,

    [string] $SessionsRoot,

    [string] $SddRoot,

    [ValidateRange(1, 9999)]
    [int] $Step = 0,

    [ValidateRange(1, 9999)]
    [int] $CurrentStep = 0,

    [ValidateSet('ensure', 'status')]
    [string] $Action = 'ensure'
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

$exitOk = [int]$script:ToolkitConstant.DevelopSessionGateExitOk
$exitUsage = [int]$script:ToolkitConstant.DevelopSessionGateExitUsage
$sessionsFolderName = [string]$script:ToolkitConstant.PlanLedgerSessionsFolderName
$gateStepConfirmed = [string]$script:ToolkitConstant.DevelopSessionGateNameStepConfirmed
$phaseDevelop = [string]$script:ToolkitConstant.DevelopSessionGatePhaseDevelop

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

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

function Write-JsonResult {
    param([Parameter(Mandatory = $true)]$Object)
    Write-Output ($Object | ConvertTo-Json -Depth 6)
}

function Convert-ToAbsoluteForwardSlashPath {
    param([Parameter(Mandatory = $true)][string] $PathValue)
    $resolved = (Resolve-Path -LiteralPath $PathValue).Path
    return (Get-NormalizedPathForHash -PathValue $resolved)
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

function Get-DevelopSessionFilePath {
    param(
        [Parameter(Mandatory = $true)][string] $RepoSessionsDir,
        [Parameter(Mandatory = $true)][string] $PlanHash,
        [int] $StepNumber
    )

    $useStepScope = $StepNumber -gt 0
    if (-not $useStepScope -and (Test-HasPlanStepSessionFiles -RepoSessionsDir $RepoSessionsDir -PlanHash $PlanHash)) {
        Write-Error $script:ToolkitConstant.DevelopSessionGateStepRequiredWhenParallelExists
        exit $exitUsage
    }

    if ($useStepScope) {
        $fileName = ('plan-{0}-step-{1}.json' -f $PlanHash, $StepNumber)
    }
    else {
        $fileName = ('plan-{0}.json' -f $PlanHash)
    }
    return (Join-Path $RepoSessionsDir $fileName)
}

function New-DefaultDevelopSessionObject {
    param(
        [Parameter(Mandatory = $true)][string] $RepoAbsolute,
        [Parameter(Mandatory = $true)][string] $PlanAbsolute,
        [int] $StepNumber,
        [int] $CurrentStepValue
    )

    $stepField = $null
    if ($StepNumber -gt 0) {
        $stepField = $StepNumber
    }

    $current = $null
    if ($CurrentStepValue -gt 0) {
        $current = $CurrentStepValue
    }
    elseif ($StepNumber -gt 0) {
        $current = $StepNumber
    }

    return [ordered]@{
        repo          = $RepoAbsolute
        plan_path     = $PlanAbsolute
        step          = $stepField
        workflow      = 'classic'
        phase         = $phaseDevelop
        gates         = [ordered]@{
            step_confirmed = $false
            tests_run      = $false
        }
        current_step  = $current
        updated_at    = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Read-DevelopSessionObject {
    param([Parameter(Mandatory = $true)][string] $Path)
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    return ($raw | ConvertFrom-Json)
}

function Test-StepConfirmedTrue {
    param([Parameter(Mandatory = $true)]$SessionObject)
    if ($null -eq $SessionObject.gates) {
        return $false
    }
    $value = $SessionObject.gates.step_confirmed
    if ($value -is [bool]) {
        return [bool]$value
    }
    if ($null -eq $value) {
        return $false
    }
    return ([string]$value).Equals('true', [System.StringComparison]::OrdinalIgnoreCase)
}

function Write-DevelopSessionFile {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)]$SessionObject
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $json = ($SessionObject | ConvertTo-Json -Depth 6)
    $encoding = Get-Utf8NoBomEncoding
    [System.IO.File]::WriteAllText($Path, $json, $encoding)
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
    $SessionsRoot = Join-Path $SddRoot $sessionsFolderName
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
$repoAbsolute = Convert-ToAbsoluteForwardSlashPath -PathValue $repoResolved
$planAbsolute = Convert-ToAbsoluteForwardSlashPath -PathValue $planResolved

$repoHash = Get-Sha256Hex16 -Text (Get-NormalizedPathForHash -PathValue $repoResolved)
$planHash = Get-Sha256Hex16 -Text (Get-NormalizedPathForHash -PathValue $planResolved)

$repoSessionsDir = Join-Path $sessionsResolved $repoHash
if (-not (Test-Path -LiteralPath $repoSessionsDir)) {
    New-Item -ItemType Directory -Path $repoSessionsDir -Force | Out-Null
}

$sessionPath = Get-DevelopSessionFilePath -RepoSessionsDir $repoSessionsDir -PlanHash $planHash -StepNumber $Step
$sessionPathPortable = ($sessionPath -replace '\\', '/')

switch ($Action) {
    'status' {
        if (-not (Test-Path -LiteralPath $sessionPath)) {
            Write-JsonResult -Object @{
                ok              = $true
                exists          = $false
                session_path    = $sessionPathPortable
                step_confirmed  = $false
                tests_run       = $false
            }
            exit $exitOk
        }

        $existing = Read-DevelopSessionObject -Path $sessionPath
        $testsRun = $false
        if ($null -ne $existing.gates -and $null -ne $existing.gates.tests_run) {
            $testsRun = [bool]$existing.gates.tests_run
        }
        Write-JsonResult -Object @{
            ok             = $true
            exists         = $true
            session_path   = $sessionPathPortable
            step_confirmed = (Test-StepConfirmedTrue -SessionObject $existing)
            tests_run      = $testsRun
        }
        exit $exitOk
    }

    'ensure' {
        if (Test-Path -LiteralPath $sessionPath) {
            $existing = Read-DevelopSessionObject -Path $sessionPath
            if (Test-StepConfirmedTrue -SessionObject $existing) {
                Write-JsonResult -Object @{
                    ok             = $true
                    skipped        = $true
                    reason         = $script:ToolkitConstant.DevelopSessionGateSkipAlreadyTrue
                    session_path   = $sessionPathPortable
                    step_confirmed = $true
                    gate           = $gateStepConfirmed
                }
                exit $exitOk
            }

            if ($null -eq $existing.gates) {
                $existing | Add-Member -NotePropertyName gates -NotePropertyValue ([pscustomobject]@{
                        step_confirmed = $false
                        tests_run      = $false
                    }) -Force
            }
            $existing.gates.step_confirmed = $true
            $existing.updated_at = (Get-Date).ToUniversalTime().ToString('o')
            $existing.phase = $phaseDevelop
            if ($CurrentStep -gt 0) {
                $existing.current_step = $CurrentStep
            }
            elseif ($Step -gt 0 -and ($null -eq $existing.current_step -or [string]::IsNullOrWhiteSpace([string]$existing.current_step))) {
                $existing.current_step = $Step
            }
            Write-DevelopSessionFile -Path $sessionPath -SessionObject $existing
            Write-JsonResult -Object @{
                ok             = $true
                skipped        = $false
                created        = $false
                session_path   = $sessionPathPortable
                step_confirmed = $true
                gate           = $gateStepConfirmed
            }
            exit $exitOk
        }

        $created = New-DefaultDevelopSessionObject -RepoAbsolute $repoAbsolute -PlanAbsolute $planAbsolute -StepNumber $Step -CurrentStepValue $CurrentStep
        $created.gates.step_confirmed = $true
        Write-DevelopSessionFile -Path $sessionPath -SessionObject $created
        Write-JsonResult -Object @{
            ok             = $true
            skipped        = $false
            created        = $true
            session_path   = $sessionPathPortable
            step_confirmed = $true
            gate           = $gateStepConfirmed
        }
        exit $exitOk
    }
}

Write-Error $script:ToolkitConstant.DevelopSessionGateUnknownAction
exit $exitUsage
