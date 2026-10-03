#Requires -Version 5.1
<#
.SYNOPSIS
  Selective clarification readiness gate (B/I → NEEDS_CLARIFICATION).

.DESCRIPTION
  Deterministic machine check for REQ-006 / CA2 / CT3. Scans markdown under a
  feature/story root for stable markers only (Status: READY|NEEDS_CLARIFICATION;
  open-question table severity cells; -[B]/-[I] list rows). Does not parse free-form
  prose. No Jarvis / ADO / Python. Read-only.

.PARAMETER FeatureRoot
  Absolute or repo-relative root containing STORY/FEATURE/REFINE markdown fixtures.

.PARAMETER RepoPath
  Optional repository root (path existence only; not required for fixture CTs).

.EXAMPLE
  .\scripts\validation\Invoke-SiblingReadinessGate.ps1 `
    -FeatureRoot scripts\validation\fixtures\sdd-artifacts\readiness\ready
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $FeatureRoot,

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

$exitReady = [int]$script:ToolkitConstant.SiblingReadinessExitReady
$exitUsage = [int]$script:ToolkitConstant.SiblingReadinessExitUsage
$exitNeeds = [int]$script:ToolkitConstant.SiblingReadinessExitNeeds
$statusReady = [string]$script:ToolkitConstant.SiblingReadinessStatusReady
$statusNeeds = [string]$script:ToolkitConstant.SiblingReadinessStatusNeeds
$statusLinePattern = [string]$script:ToolkitConstant.SiblingReadinessStatusLinePattern
$listSeverityPattern = [string]$script:ToolkitConstant.SiblingReadinessListSeverityPattern
$tableRowPattern = [string]$script:ToolkitConstant.SiblingReadinessTableRowPattern
$separatorPattern = [string]$script:ToolkitConstant.SiblingReadinessTableSeparatorPattern
$headerSkipPattern = [string]$script:ToolkitConstant.SiblingReadinessTableHeaderSkipPattern
$blockingCanonical = @([string[]]$script:ToolkitConstant.SiblingReadinessBlockingCanonicalSeverities)
$blockingLegacy = @([string[]]$script:ToolkitConstant.SiblingReadinessBlockingLegacySeverities)
$minorCanonical = @([string[]]$script:ToolkitConstant.SiblingReadinessMinorCanonicalSeverities)
$minorLegacy = @([string[]]$script:ToolkitConstant.SiblingReadinessMinorLegacySeverities)

function Write-UsageAndExit {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Output ("USAGE: {0}" -f $Message)
    exit $exitUsage
}

function Resolve-FeatureRootPath {
    param([Parameter(Mandatory = $true)][string] $Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) {
        Write-UsageAndExit -Message 'FeatureRoot is required.'
    }
    if ([System.IO.Path]::IsPathRooted($Raw)) {
        return [System.IO.Path]::GetFullPath($Raw)
    }
    $base = if (-not [string]::IsNullOrWhiteSpace($RepoPath) -and (Test-Path -LiteralPath $RepoPath)) {
        [System.IO.Path]::GetFullPath($RepoPath)
    }
    else {
        (Get-Location).Path
    }
    return [System.IO.Path]::GetFullPath((Join-Path $base $Raw))
}

function Get-CanonicalSeverity {
    param([Parameter(Mandatory = $true)][string] $Token)
    $t = $Token.Trim()
    if ($blockingCanonical -contains $t) { return $t }
    if ($blockingLegacy -contains $t.ToLowerInvariant()) {
        if ($t.ToLowerInvariant() -eq 'blocker') { return 'B' }
        return 'I'
    }
    if ($minorCanonical -contains $t) { return 'MINOR' }
    if ($minorLegacy -contains $t.ToLowerInvariant()) { return 'MINOR' }
    return $null
}

function Get-TableSeverityCells {
    param([Parameter(Mandatory = $true)][string] $Line)
    if ($Line -notmatch $tableRowPattern) { return @() }
    if ($Line -match $separatorPattern) { return @() }
    if ($Line -match $headerSkipPattern) { return @() }
    $cells = @($Line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
    $hits = @()
    foreach ($cell in $cells) {
        if ([string]::IsNullOrWhiteSpace($cell)) { continue }
        # Single-token severity cells only (stable machine marker).
        if ($cell -notmatch '^(?i)(B|I|MINOR|blocker|high|medium|low)$') { continue }
        $canon = Get-CanonicalSeverity -Token $cell
        if ($null -ne $canon) { $hits += $canon }
    }
    return $hits
}

$rootPath = Resolve-FeatureRootPath -Raw $FeatureRoot
if (-not (Test-Path -LiteralPath $rootPath)) {
    Write-UsageAndExit -Message ("FeatureRoot not found: {0}" -f $FeatureRoot)
}
if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
    Write-UsageAndExit -Message 'FeatureRoot must be a directory.'
}

$mdFiles = @(Get-ChildItem -LiteralPath $rootPath -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue)
if ($mdFiles.Count -lt 1) {
    Write-UsageAndExit -Message 'No markdown files under FeatureRoot.'
}

$explicitStatus = $null
$openBlocking = New-Object System.Collections.Generic.List[string]

foreach ($file in $mdFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($text)) { continue }

    $statusMatches = [regex]::Matches($text, $statusLinePattern)
    foreach ($m in $statusMatches) {
        $token = $m.Groups['status'].Value.ToUpperInvariant()
        if ($token -eq $statusNeeds) {
            $explicitStatus = $statusNeeds
        }
        elseif ($token -eq $statusReady -and $explicitStatus -ne $statusNeeds) {
            $explicitStatus = $statusReady
        }
    }

    $listMatches = [regex]::Matches($text, $listSeverityPattern)
    foreach ($m in $listMatches) {
        $canon = Get-CanonicalSeverity -Token $m.Groups['sev'].Value
        if ($canon -eq 'B' -or $canon -eq 'I') {
            $openBlocking.Add(('{0}:{1}' -f $canon, $m.Groups['q'].Value.Trim())) | Out-Null
        }
    }

    foreach ($line in ($text -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        foreach ($sev in (Get-TableSeverityCells -Line $line)) {
            if ($sev -eq 'B' -or $sev -eq 'I') {
                $openBlocking.Add(('{0}:table' -f $sev)) | Out-Null
            }
        }
    }
}

$hasBlocking = ($openBlocking.Count -gt 0)
$isNeeds = ($explicitStatus -eq $statusNeeds) -or $hasBlocking

if ($isNeeds) {
    Write-Output ("Status: {0}" -f $statusNeeds)
    if ($hasBlocking) {
        Write-Output 'Open (B/I):'
        $seen = @{}
        foreach ($item in $openBlocking) {
            if ($seen.ContainsKey($item)) { continue }
            $seen[$item] = $true
            Write-Output ("- {0}" -f $item)
        }
    }
    exit $exitNeeds
}

Write-Output ("Status: {0}" -f $statusReady)
exit $exitReady
