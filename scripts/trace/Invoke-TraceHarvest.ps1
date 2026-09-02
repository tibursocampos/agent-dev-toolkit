#Requires -Version 5.1
<#
.SYNOPSIS
  Feature-scoped TRACE harvest: summarize what ran from features/NNN-slug/TRACE.jsonl.

.DESCRIPTION
  Reads ONLY the feature TRACE.jsonl (REQ-007 / CA7). Never dumps sdd/sessions or
  other roots (SEC harvest exfil; RNF-003 / RNF-004). Includes tokens / duration /
  spawn on each event when those keys are present. Failures outside feature scope
  are explicit (TE05).

.PARAMETER FeatureRoot
  Absolute or relative path to features/NNN-slug/ (must contain TRACE.jsonl for a
  non-empty harvest). Must resolve under -RepoPath and match features/NNN-slug.

.PARAMETER RepoPath
  Consumer / toolkit repository root used as the path-escape boundary.
  Defaults to the parent of the features/ segment when FeatureRoot is rooted under features/.

.EXAMPLE
  .\scripts\trace\Invoke-TraceHarvest.ps1 -FeatureRoot features\006-skills-maturity-parity

.EXAMPLE
  .\scripts\trace\Invoke-TraceHarvest.ps1 -FeatureRoot E:\repo\features\000-fixture-trace -RepoPath E:\repo
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $FeatureRoot,

    [Parameter(Mandatory = $false)]
    [string] $RepoPath
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
if (-not (Get-Command -Name Test-IsPathUnderOrEqual -ErrorAction SilentlyContinue)) {
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
}

$c = $script:ToolkitConstant
$script:HarvestExitOk = $c.TraceHarvestExitOk
$script:HarvestExitFail = $c.TraceHarvestExitFail
$script:HarvestTraceFileName = $c.SddArtifactTraceFileName
$script:HarvestStatusOk = $c.TraceHarvestStatusOk
$script:HarvestStatusError = $c.TraceHarvestStatusError
$script:HarvestReasonOk = $c.TraceHarvestReasonOk
$script:HarvestReasonTraceAbsent = $c.TraceHarvestReasonTraceAbsent
$script:HarvestReasonTraceEmpty = $c.TraceHarvestReasonTraceEmpty
$script:HarvestReasonInvalidJson = $c.TraceHarvestReasonInvalidJson
$script:HarvestReasonFeatureMissing = $c.TraceHarvestReasonFeatureMissing
$script:HarvestReasonInvalidScope = $c.TraceHarvestReasonInvalidScope
$script:HarvestReasonPathEscape = $c.TraceHarvestReasonPathEscape
$script:HarvestReasonSessionsDenied = $c.TraceHarvestReasonSessionsDenied
$script:HarvestReasonNotDirectory = $c.TraceHarvestReasonNotDirectory
$script:HarvestFeatureLeafPattern = $c.TraceHarvestFeatureLeafPattern
$script:HarvestSessionsSegmentPattern = $c.TraceHarvestSessionsSegmentPattern

$traceEmitCommonPath = Join-Path (Get-ToolkitRepoRoot -FromPath $scriptDir) ($c.TraceEmitCommonRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $traceEmitCommonPath)) {
    throw ("TraceEmitCommon missing for harvest redaction: {0}" -f $traceEmitCommonPath)
}
. $traceEmitCommonPath

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Convert-ToPortableRelativePath {
    param(
        [Parameter(Mandatory = $true)][string] $FullPath,
        [Parameter(Mandatory = $true)][string] $RootPath
    )

    if (-not (Test-IsPathUnderOrEqual -ChildPath $FullPath -ParentPath $RootPath)) {
        throw ("Path escapes repo root: {0}" -f $FullPath)
    }

    $root = (Get-NormalizedFullPath -Path $RootPath).TrimEnd('\', '/')
    $full = Get-NormalizedFullPath -Path $FullPath
    $relative = $full.Substring($root.Length).TrimStart('\', '/')
    return ($relative -replace '\\', '/')
}

function Test-PathUnderOrEqual {
    param(
        [Parameter(Mandatory = $true)][string] $CandidatePath,
        [Parameter(Mandatory = $true)][string] $RootPath
    )

    return (Test-IsPathUnderOrEqual -ChildPath $CandidatePath -ParentPath $RootPath)
}

function Resolve-HarvestAbsolutePath {
    param([Parameter(Mandatory = $true)][string] $Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Write-HarvestResult {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Result,
        [Parameter(Mandatory = $true)][int] $ExitCode
    )

    $json = ($Result | ConvertTo-Json -Depth 8 -Compress)
    Write-Output $json
    exit $ExitCode
}

function New-HarvestErrorResult {
    param(
        [Parameter(Mandatory = $true)][string] $Reason,
        [Parameter(Mandatory = $false)][string] $Feature = '',
        [Parameter(Mandatory = $false)][string] $TracePath = ''
    )

    return @{
        status             = $script:HarvestStatusError
        status_reason      = $Reason
        feature            = $Feature
        trace_path         = $TracePath
        event_count        = 0
        events             = @()
        metrics_present    = @{
            tokens   = $false
            duration = $false
            spawn    = $false
        }
        sessions_read      = $false
        harvest_scope      = 'feature'
    }
}

function Get-OptionalPropertyValue {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)][string] $Name
    )

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        return $null
    }

    return $prop.Value
}

function Convert-TraceEventToSummary {
    param([Parameter(Mandatory = $true)] $Object)

    $summary = [ordered]@{
        ts      = [string](Get-OptionalPropertyValue -Object $Object -Name 'ts')
        event   = [string](Get-OptionalPropertyValue -Object $Object -Name 'event')
        feature = [string](Get-OptionalPropertyValue -Object $Object -Name 'feature')
    }

    $textSummary = Get-OptionalPropertyValue -Object $Object -Name 'summary'
    if ($null -ne $textSummary -and -not [string]::IsNullOrWhiteSpace([string]$textSummary)) {
        $summary['summary'] = Get-TraceEmitterRedactedSummary -Text ([string]$textSummary)
    }

    $role = Get-OptionalPropertyValue -Object $Object -Name 'role'
    if ($null -ne $role -and -not [string]::IsNullOrWhiteSpace([string]$role)) {
        $summary['role'] = [string]$role
    }

    $outcome = Get-OptionalPropertyValue -Object $Object -Name 'outcome'
    if ($null -ne $outcome -and -not [string]::IsNullOrWhiteSpace([string]$outcome)) {
        $summary['outcome'] = [string]$outcome
    }

    $tokens = Get-OptionalPropertyValue -Object $Object -Name 'tokens'
    if ($null -ne $tokens) {
        $summary['tokens'] = $tokens
    }

    $duration = Get-OptionalPropertyValue -Object $Object -Name 'duration'
    if ($null -ne $duration) {
        $summary['duration'] = $duration
    }

    $spawn = Get-OptionalPropertyValue -Object $Object -Name 'spawn'
    if ($null -ne $spawn) {
        $redactedSpawn = Convert-TraceEmitterExtraValue -Value $spawn
        if ($null -ne $redactedSpawn) {
            $summary['spawn'] = $redactedSpawn
        }
    }

    return [PSCustomObject]$summary
}

# --- resolve inputs ---
$featureInput = [string]$FeatureRoot
if ([string]::IsNullOrWhiteSpace($featureInput)) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonInvalidScope) -ExitCode $script:HarvestExitFail
}

if ($featureInput -match $script:HarvestSessionsSegmentPattern) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonSessionsDenied) -ExitCode $script:HarvestExitFail
}

$resolvedFeature = Resolve-HarvestAbsolutePath -Path $featureInput

if ($resolvedFeature -match $script:HarvestSessionsSegmentPattern) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonSessionsDenied) -ExitCode $script:HarvestExitFail
}

if (-not (Test-Path -LiteralPath $resolvedFeature)) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonFeatureMissing) -ExitCode $script:HarvestExitFail
}

if (-not (Test-Path -LiteralPath $resolvedFeature -PathType Container)) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonNotDirectory) -ExitCode $script:HarvestExitFail
}

$resolvedRepo = $null
if (-not [string]::IsNullOrWhiteSpace($RepoPath)) {
    $resolvedRepo = Resolve-HarvestAbsolutePath -Path $RepoPath
}
else {
    try {
        $resolvedRepo = Get-ToolkitRepoRoot -FromPath $scriptDir
    }
    catch {
        $resolvedRepo = (Get-Location).Path
    }
}

if (-not (Test-Path -LiteralPath $resolvedRepo -PathType Container)) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonInvalidScope) -ExitCode $script:HarvestExitFail
}

if (-not (Test-PathUnderOrEqual -CandidatePath $resolvedFeature -RootPath $resolvedRepo)) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonPathEscape) -ExitCode $script:HarvestExitFail
}

$portableFeatureRoot = $null
try {
    $portableFeatureRoot = Convert-ToPortableRelativePath -FullPath $resolvedFeature -RootPath $resolvedRepo
}
catch {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonPathEscape) -ExitCode $script:HarvestExitFail
}

$portableNormalized = ($portableFeatureRoot -replace '\\', '/').TrimEnd('/')
if ($portableNormalized -notmatch '(?i)^features/') {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonInvalidScope -Feature $portableNormalized) -ExitCode $script:HarvestExitFail
}

$leafName = Split-Path -Leaf $portableNormalized
if ($leafName -notmatch $script:HarvestFeatureLeafPattern) {
    # Allow story/TS nested roots under features/NNN-slug/... when the NNN-slug segment is present.
    $segments = @($portableNormalized -split '/')
    $slugSegment = $null
    if ($segments.Count -ge 2) {
        $slugSegment = $segments[1]
    }
    if ($null -eq $slugSegment -or $slugSegment -notmatch $script:HarvestFeatureLeafPattern) {
        Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonInvalidScope -Feature $portableNormalized) -ExitCode $script:HarvestExitFail
    }
}

$tracePath = Join-Path $resolvedFeature $script:HarvestTraceFileName
$portableTracePath = ($portableNormalized.TrimEnd('/') + '/' + $script:HarvestTraceFileName)

if (-not (Test-Path -LiteralPath $tracePath -PathType Leaf)) {
    $absent = New-HarvestErrorResult -Reason $script:HarvestReasonTraceAbsent -Feature $portableNormalized -TracePath $portableTracePath
    # Absent trail is a successful empty harvest for operators (trail optional until archive).
    $absent.status = $script:HarvestStatusOk
    Write-HarvestResult -Result $absent -ExitCode $script:HarvestExitOk
}

$raw = Get-Content -LiteralPath $tracePath -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonTraceEmpty -Feature $portableNormalized -TracePath $portableTracePath) -ExitCode $script:HarvestExitFail
}

$lines = @($raw -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($lines.Count -eq 0) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonTraceEmpty -Feature $portableNormalized -TracePath $portableTracePath) -ExitCode $script:HarvestExitFail
}

$eventSummaries = New-Object System.Collections.ArrayList
$hasTokens = $false
$hasDuration = $false
$hasSpawn = $false
$parseFailures = 0

foreach ($line in $lines) {
    $obj = $null
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $parseFailures++
        continue
    }

    if ($null -eq $obj) {
        $parseFailures++
        continue
    }

    $summaryObj = Convert-TraceEventToSummary -Object $obj
    [void]$eventSummaries.Add($summaryObj)

    if ($null -ne (Get-OptionalPropertyValue -Object $obj -Name 'tokens')) {
        $hasTokens = $true
    }
    if ($null -ne (Get-OptionalPropertyValue -Object $obj -Name 'duration')) {
        $hasDuration = $true
    }
    if ($null -ne (Get-OptionalPropertyValue -Object $obj -Name 'spawn')) {
        $hasSpawn = $true
    }
}

if ($parseFailures -gt 0 -and $eventSummaries.Count -eq 0) {
    Write-HarvestResult -Result (New-HarvestErrorResult -Reason $script:HarvestReasonInvalidJson -Feature $portableNormalized -TracePath $portableTracePath) -ExitCode $script:HarvestExitFail
}

$okReason = $script:HarvestReasonOk
if ($parseFailures -gt 0) {
    $okReason = ("{0}; skipped_invalid_lines={1}" -f $script:HarvestReasonOk, $parseFailures)
}

$result = @{
    status          = $script:HarvestStatusOk
    status_reason   = $okReason
    feature         = $portableNormalized
    trace_path      = $portableTracePath
    event_count     = $eventSummaries.Count
    events          = @($eventSummaries)
    metrics_present = @{
        tokens   = $hasTokens
        duration = $hasDuration
        spawn    = $hasSpawn
    }
    sessions_read   = $false
    harvest_scope   = 'feature'
}

Write-HarvestResult -Result $result -ExitCode $script:HarvestExitOk
