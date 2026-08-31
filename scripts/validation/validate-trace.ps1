#Requires -Version 5.1
<#
.SYNOPSIS
  Structural validation for features/NNN-slug/TRACE.jsonl (REQ-006 / CA5).

.DESCRIPTION
  Deterministic TRACE + living-loop checks - no LLM.
  Default: missing TRACE is OK; present TRACE must be valid JSONL.
  -RequireArchiveComplete: TRACE must exist with converge -> sync_current -> archive.

.PARAMETER FeatureRoot
  Absolute or relative path to features/NNN-slug/.

.PARAMETER RequireArchiveComplete
  Require living-loop triad and sync target rules.

.EXAMPLE
  .\scripts\validation\validate-trace.ps1 -FeatureRoot features\005-x -RequireArchiveComplete
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $FeatureRoot,

    [Parameter(Mandatory = $false)]
    [switch] $RequireArchiveComplete
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
    Write-Host ("validate-trace: FAIL - {0}" -f $Message) -ForegroundColor Red
}

function Write-ValidatePass {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-trace: PASS - {0}" -f $Message) -ForegroundColor Green
}

function Resolve-FeatureRootPath {
    param([Parameter(Mandatory = $true)][string] $Path)
    $resolved = $Path
    if (-not [System.IO.Path]::IsPathRooted($resolved)) {
        $resolved = Join-Path (Get-Location).Path $Path
    }
    return $resolved
}

function Test-ForbiddenSyncTarget {
    param([Parameter(Mandatory = $true)][string] $Target)
    $normalized = ($Target -replace '\\', '/').Trim()
    return ($normalized -match $script:ToolkitConstant.SddArtifactTraceForbiddenTargetPattern)
}

function Test-AllowedSyncTarget {
    param([Parameter(Mandatory = $true)][string] $Target)
    $normalized = ($Target -replace '\\', '/').Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $false
    }
    if (Test-ForbiddenSyncTarget -Target $normalized) {
        return $false
    }
    return ($normalized -match $script:ToolkitConstant.SddArtifactTraceAllowedTargetPattern)
}

function Test-PortableTracePath {
    param([Parameter(Mandatory = $true)][string] $Path)
    $normalized = ($Path -replace '\\', '/').Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $false
    }
    return ($normalized -notmatch $script:ToolkitConstant.SddArtifactTracePortablePathPattern)
}

function Test-NonEmptyStringField {
    param([Parameter(Mandatory = $false)] $Value)
    return -not [string]::IsNullOrWhiteSpace([string]$Value)
}

function Test-NonEmptyStringArrayField {
    param([Parameter(Mandatory = $false)] $Value)
    if ($null -eq $Value) {
        return $false
    }
    $items = @($Value | ForEach-Object { [string]$_ })
    if ($items.Count -eq 0) {
        return $false
    }
    foreach ($item in $items) {
        if ([string]::IsNullOrWhiteSpace($item)) {
            return $false
        }
    }
    return $true
}

function Get-TraceFieldValue {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)][string] $Name
    )
    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        return ''
    }
    return [string]$prop.Value
}

function Add-NormativeOptionalEventFailures {
    param(
        [Parameter(Mandatory = $true)] $EventRecord,
        [Parameter(Mandatory = $true)] $FailureList
    )

    $line = $EventRecord.Line
    $obj = $EventRecord.Object
    $eventName = $EventRecord.Event

    switch ($eventName) {
        $script:ToolkitConstant.SddArtifactTraceEventRetrieval {
            $pathsValue = $null
            $pathsProp = $obj.PSObject.Properties['paths']
            if ($null -ne $pathsProp) {
                $pathsValue = $pathsProp.Value
            }
            if (-not (Test-NonEmptyStringArrayField -Value $pathsValue)) {
                [void]$FailureList.Add(("line {0}: retrieval requires non-empty paths[]" -f $line))
            }
            else {
                foreach ($p in @($pathsValue | ForEach-Object { [string]$_ })) {
                    if (-not (Test-PortableTracePath -Path $p)) {
                        [void]$FailureList.Add(("line {0}: retrieval path '{1}' must be portable (no drive letter or user-home embed)" -f $line, $p))
                    }
                }
            }
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'reason'))) {
                [void]$FailureList.Add(("line {0}: retrieval requires non-empty reason" -f $line))
            }
        }
        $script:ToolkitConstant.SddArtifactTraceEventGate {
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'gate_id'))) {
                [void]$FailureList.Add(("line {0}: gate requires non-empty gate_id" -f $line))
            }
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'response'))) {
                [void]$FailureList.Add(("line {0}: gate requires non-empty response" -f $line))
            }
        }
        $script:ToolkitConstant.SddArtifactTraceEventSpawn {
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'role'))) {
                [void]$FailureList.Add(("line {0}: spawn requires non-empty role" -f $line))
            }
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'reason'))) {
                [void]$FailureList.Add(("line {0}: spawn requires non-empty reason" -f $line))
            }
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'outcome'))) {
                [void]$FailureList.Add(("line {0}: spawn requires non-empty outcome" -f $line))
            }
        }
        $script:ToolkitConstant.SddArtifactTraceEventSpecialistComplete {
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'role'))) {
                [void]$FailureList.Add(("line {0}: specialist_complete requires non-empty role" -f $line))
            }
            if (-not (Test-NonEmptyStringField -Value (Get-TraceFieldValue -Object $obj -Name 'summary'))) {
                [void]$FailureList.Add(("line {0}: specialist_complete requires non-empty summary" -f $line))
            }
        }
    }
}

$resolvedRoot = Resolve-FeatureRootPath -Path $FeatureRoot
if (-not (Test-Path -LiteralPath $resolvedRoot)) {
    Write-ValidateFail -Message ("feature root not found: {0}" -f $FeatureRoot)
    exit 1
}

$traceFileName = $script:ToolkitConstant.SddArtifactTraceFileName
$tracePath = Join-Path $resolvedRoot $traceFileName

if (-not (Test-Path -LiteralPath $tracePath)) {
    if ($RequireArchiveComplete) {
        Write-ValidateFail -Message ("missing {0} (required with -RequireArchiveComplete)" -f $traceFileName)
        exit 1
    }
    Write-ValidatePass -Message ("{0} absent - trail optional until archive-complete" -f $traceFileName)
    exit 0
}

$raw = Get-Content -LiteralPath $tracePath -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-ValidateFail -Message ("{0} is empty" -f $traceFileName)
    exit 1
}

$lines = @($raw -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($lines.Count -eq 0) {
    Write-ValidateFail -Message ("{0} has no non-empty lines" -f $traceFileName)
    exit 1
}

$failures = New-Object System.Collections.ArrayList
$events = New-Object System.Collections.ArrayList
$lineNumber = 0

foreach ($line in $lines) {
    $lineNumber++
    $obj = $null
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        [void]$failures.Add(("line {0}: invalid JSON ({1})" -f $lineNumber, $_.Exception.Message))
        continue
    }

    if ($null -eq $obj) {
        [void]$failures.Add(("line {0}: null JSON object" -f $lineNumber))
        continue
    }

    $ts = [string]$obj.ts
    $eventName = [string]$obj.event
    $feature = [string]$obj.feature

    if ([string]::IsNullOrWhiteSpace($ts)) {
        [void]$failures.Add(("line {0}: missing ts" -f $lineNumber))
    }
    if ([string]::IsNullOrWhiteSpace($eventName)) {
        [void]$failures.Add(("line {0}: missing event" -f $lineNumber))
    }
    if ([string]::IsNullOrWhiteSpace($feature)) {
        [void]$failures.Add(("line {0}: missing feature" -f $lineNumber))
    }
    elseif ($feature -notmatch $script:ToolkitConstant.SddArtifactTraceFeaturePathPattern) {
        [void]$failures.Add(("line {0}: feature must be portable features/NNN-slug (got '{1}')" -f $lineNumber, $feature))
    }

    $normalizedEvent = $eventName.Trim().ToLowerInvariant()
    $eventRecord = [PSCustomObject]@{
        Line   = $lineNumber
        Ts     = $ts
        Event  = $normalizedEvent
        Object = $obj
    }
    Add-NormativeOptionalEventFailures -EventRecord $eventRecord -FailureList $failures
    [void]$events.Add($eventRecord)
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-ValidateFail -Message $f
    }
    exit 1
}

if ($RequireArchiveComplete) {
    $eventNames = @($events | ForEach-Object { $_.Event })
    $idxConverge = [array]::IndexOf($eventNames, $script:ToolkitConstant.SddArtifactTraceEventConverge)
    $idxSync = [array]::IndexOf($eventNames, $script:ToolkitConstant.SddArtifactTraceEventSyncCurrent)
    $idxArchive = [array]::IndexOf($eventNames, $script:ToolkitConstant.SddArtifactTraceEventArchive)

    if ($idxConverge -lt 0) {
        [void]$failures.Add(("missing living-loop event '{0}'" -f $script:ToolkitConstant.SddArtifactTraceEventConverge))
    }
    if ($idxSync -lt 0) {
        [void]$failures.Add(("missing living-loop event '{0}'" -f $script:ToolkitConstant.SddArtifactTraceEventSyncCurrent))
    }
    if ($idxArchive -lt 0) {
        [void]$failures.Add(("missing living-loop event '{0}'" -f $script:ToolkitConstant.SddArtifactTraceEventArchive))
    }

    if ($idxConverge -ge 0 -and $idxSync -ge 0 -and $idxArchive -ge 0) {
        if (-not ($idxConverge -lt $idxSync -and $idxSync -lt $idxArchive)) {
            [void]$failures.Add('living-loop order must be converge -> sync_current -> archive (first occurrences)')
        }
    }

    foreach ($ev in $events) {
        if ($ev.Event -eq $script:ToolkitConstant.SddArtifactTraceEventConverge) {
            $summary = [string]$ev.Object.summary
            if ([string]::IsNullOrWhiteSpace($summary)) {
                [void]$failures.Add(("line {0}: converge requires non-empty summary" -f $ev.Line))
            }
        }
        if ($ev.Event -eq $script:ToolkitConstant.SddArtifactTraceEventSyncCurrent) {
            $summary = [string]$ev.Object.summary
            if ([string]::IsNullOrWhiteSpace($summary)) {
                [void]$failures.Add(("line {0}: sync_current requires non-empty summary" -f $ev.Line))
            }
            $targets = @()
            if ($null -ne $ev.Object.targets) {
                $targets = @($ev.Object.targets | ForEach-Object { [string]$_ })
            }
            if ($targets.Count -eq 0) {
                [void]$failures.Add(("line {0}: sync_current requires non-empty targets[]" -f $ev.Line))
            }
            else {
                foreach ($t in $targets) {
                    if (-not (Test-AllowedSyncTarget -Target $t)) {
                        [void]$failures.Add(("line {0}: sync_current target '{1}' must be under memory-bank/ or docs/ (not openspec/.specs/.specify)" -f $ev.Line, $t))
                    }
                }
            }
        }
        if ($ev.Event -eq $script:ToolkitConstant.SddArtifactTraceEventArchive) {
            $summary = [string]$ev.Object.summary
            $status = ([string]$ev.Object.status).Trim().ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($summary)) {
                [void]$failures.Add(("line {0}: archive requires non-empty summary" -f $ev.Line))
            }
            $allowedStatus = @($script:ToolkitConstant.SddArtifactTraceArchiveStatusAllowed)
            if ($allowedStatus -notcontains $status) {
                [void]$failures.Add(("line {0}: archive status must be one of: {1} (got '{2}')" -f $ev.Line, ($allowedStatus -join ', '), $status))
            }
        }
    }

    if ($failures.Count -gt 0) {
        foreach ($f in $failures) {
            Write-ValidateFail -Message $f
        }
        exit 1
    }

    Write-ValidatePass -Message ("archive-complete; events={0}" -f $events.Count)
    exit 0
}

Write-ValidatePass -Message ("TRACE.jsonl structural OK; events={0}" -f $events.Count)
exit 0
