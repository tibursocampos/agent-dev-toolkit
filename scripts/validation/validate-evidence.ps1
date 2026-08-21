#Requires -Version 5.1
<#
.SYNOPSIS
  Structural validation for feature EVD/ + STATE.md (REQ-005 / CA4).

.DESCRIPTION
  Deterministic evidence-or-zero checks - no LLM.
  Levels: off | cheap | standard | strict.

.PARAMETER FeatureRoot
  Absolute or relative path to features/NNN-slug/.

.PARAMETER Level
  Optional override. When omitted, reads Evidence level from STATE.md
  (defaults to cheap if STATE is missing and a gate is evaluated).

.EXAMPLE
  .\scripts\validation\validate-evidence.ps1 -FeatureRoot features\005-x -Level cheap
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $FeatureRoot,

    [Parameter(Mandatory = $false)]
    [ValidateSet('off', 'cheap', 'standard', 'strict')]
    [string] $Level = ''
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
    Write-Host ("validate-evidence: FAIL - {0}" -f $Message) -ForegroundColor Red
}

function Write-ValidatePass {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-evidence: PASS - {0}" -f $Message) -ForegroundColor Green
}

function Resolve-FeatureRootPath {
    param([Parameter(Mandatory = $true)][string] $Path)
    $resolved = $Path
    if (-not [System.IO.Path]::IsPathRooted($resolved)) {
        $resolved = Join-Path (Get-Location).Path $Path
    }
    return $resolved
}

function Get-EvidenceLevelFromState {
    param([Parameter(Mandatory = $true)][string] $StateText)
    $m = [regex]::Match($StateText, $script:ToolkitConstant.SddArtifactEvidenceLevelFieldPattern)
    if (-not $m.Success) {
        return ''
    }
    return $m.Groups[1].Value.ToLowerInvariant()
}

function Get-MatrixRows {
    param([Parameter(Mandatory = $true)][string] $StateText)

    $matrixRows = New-Object System.Collections.ArrayList
    $inMatrix = $false
    $headerSeen = $false
    $evidenceIdx = -1
    $resultIdx = -1

    foreach ($line in ($StateText -split "`r?`n")) {
        if ($line -match $script:ToolkitConstant.SddArtifactEvidenceMatrixHeadingPattern) {
            $inMatrix = $true
            $headerSeen = $false
            continue
        }
        if (-not $inMatrix) {
            continue
        }
        if ($line -match '^#{1,3}\s+') {
            break
        }
        if ($line -notmatch '^\|') {
            continue
        }
        $cells = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 2) {
            continue
        }
        $joined = ($cells -join ' ').ToLowerInvariant()
        if ($joined -match '^[\s|:\-]+$') {
            continue
        }
        if (-not $headerSeen) {
            for ($i = 0; $i -lt $cells.Count; $i++) {
                $h = $cells[$i].ToLowerInvariant()
                if ($h -match 'evidence|evidencia') {
                    $evidenceIdx = $i
                }
                if ($h -match 'result|resultado') {
                    $resultIdx = $i
                }
            }
            if ($evidenceIdx -lt 0) {
                $evidenceIdx = [Math]::Min(2, $cells.Count - 1)
            }
            $headerSeen = $true
            continue
        }
        if ($cells[0] -match '^[\-:]+$') {
            continue
        }
        $evidenceCell = ''
        if ($evidenceIdx -ge 0 -and $evidenceIdx -lt $cells.Count) {
            $evidenceCell = $cells[$evidenceIdx]
        }
        $resultCell = ''
        if ($resultIdx -ge 0 -and $resultIdx -lt $cells.Count) {
            $resultCell = $cells[$resultIdx]
        }
        [void]$matrixRows.Add([PSCustomObject]@{
                Ac       = $cells[0]
                Evidence = ($evidenceCell -replace '^`+|`+$', '').Trim()
                Result   = $resultCell.Trim().ToLowerInvariant()
            })
    }

    # Pipeline-enumerate rows; caller wraps with @(). Avoid unary-comma wrap
    # (that nests Object[] and breaks multi-row matrices via member enumeration).
    return [object[]]$matrixRows.ToArray()
}

function Test-NonEmptyEvidenceFile {
    param(
        [Parameter(Mandatory = $true)][string] $FeatureRootPath,
        [Parameter(Mandatory = $true)][string] $EvidencePath
    )
    if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
        return $false
    }
    $normalized = $EvidencePath -replace '\\', '/'
    $normalized = $normalized -replace '^features/[^/]+/', ''
    if ($normalized -notmatch '(?i)^EVD/') {
        if ($normalized -notmatch '(?i)^EVD\b') {
            $normalized = ('EVD/{0}' -f ($normalized.TrimStart('/')))
        }
    }
    $full = Join-Path $FeatureRootPath ($normalized -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        return $false
    }
    $item = Get-Item -LiteralPath $full
    if ($item.PSIsContainer) {
        return $false
    }
    if ($item.Length -le 0) {
        return $false
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    return -not [string]::IsNullOrWhiteSpace($text)
}

$resolvedRoot = Resolve-FeatureRootPath -Path $FeatureRoot
if (-not (Test-Path -LiteralPath $resolvedRoot)) {
    Write-ValidateFail -Message ("feature root not found: {0}" -f $FeatureRoot)
    exit 1
}

$statePath = Join-Path $resolvedRoot $script:ToolkitConstant.SddArtifactStateFileName
$evdDir = Join-Path $resolvedRoot $script:ToolkitConstant.SddArtifactEvdDirectoryName

$effectiveLevel = $Level
$stateText = ''
if (Test-Path -LiteralPath $statePath) {
    $stateText = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($effectiveLevel)) {
        $fromState = Get-EvidenceLevelFromState -StateText $stateText
        if (-not [string]::IsNullOrWhiteSpace($fromState)) {
            $effectiveLevel = $fromState
        }
    }
}

if ([string]::IsNullOrWhiteSpace($effectiveLevel)) {
    $effectiveLevel = $script:ToolkitConstant.SddArtifactEvidenceLevelDefault
}

$effectiveLevel = $effectiveLevel.ToLowerInvariant()
$allowed = @('off', 'cheap', 'standard', 'strict')
if ($allowed -notcontains $effectiveLevel) {
    Write-ValidateFail -Message ("invalid evidence level '{0}' (use off|cheap|standard|strict)" -f $effectiveLevel)
    exit 1
}

if ($effectiveLevel -eq 'off') {
    Write-ValidatePass -Message 'level=off - evidence gate skipped'
    exit 0
}

$failures = New-Object System.Collections.ArrayList

if (-not (Test-Path -LiteralPath $statePath)) {
    [void]$failures.Add(('missing {0} (required when level >= cheap)' -f $script:ToolkitConstant.SddArtifactStateFileName))
}
if (-not (Test-Path -LiteralPath $evdDir) -or -not (Get-Item -LiteralPath $evdDir).PSIsContainer) {
    [void]$failures.Add(('missing {0}/ directory (required when level >= cheap)' -f $script:ToolkitConstant.SddArtifactEvdDirectoryName))
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-ValidateFail -Message $f
    }
    exit 1
}

if ([string]::IsNullOrWhiteSpace($stateText)) {
    Write-ValidateFail -Message ('empty {0}' -f $script:ToolkitConstant.SddArtifactStateFileName)
    exit 1
}

if ($stateText -notmatch $script:ToolkitConstant.SddArtifactEvidenceMatrixHeadingPattern) {
    Write-ValidateFail -Message 'STATE.md missing AC evidence matrix heading'
    exit 1
}

$matrixRows = @(Get-MatrixRows -StateText $stateText)
if ($matrixRows.Count -eq 0) {
    Write-ValidateFail -Message 'AC evidence matrix has zero data rows (evidence-or-zero)'
    exit 1
}

$nonEmptyCount = 0
foreach ($row in $matrixRows) {
    if (Test-NonEmptyEvidenceFile -FeatureRootPath $resolvedRoot -EvidencePath $row.Evidence) {
        $nonEmptyCount++
    }
}

if ($nonEmptyCount -eq 0) {
    Write-ValidateFail -Message 'level >= cheap requires at least one non-empty EVD evidence file cited by the matrix'
    exit 1
}

if ($effectiveLevel -eq 'standard' -or $effectiveLevel -eq 'strict') {
    foreach ($row in $matrixRows) {
        if (-not (Test-NonEmptyEvidenceFile -FeatureRootPath $resolvedRoot -EvidencePath $row.Evidence)) {
            [void]$failures.Add(("standard/strict: missing or empty evidence for AC '{0}' path '{1}'" -f $row.Ac, $row.Evidence))
        }
    }
}

if ($effectiveLevel -eq 'strict') {
    foreach ($row in $matrixRows) {
        if ($row.Result -ne 'pass') {
            [void]$failures.Add(("strict: AC '{0}' Result must be pass (got '{1}')" -f $row.Ac, $row.Result))
        }
    }
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-ValidateFail -Message $f
    }
    exit 1
}

Write-ValidatePass -Message ("level={0}; matrix rows={1}; non-empty evidence={2}" -f $effectiveLevel, $matrixRows.Count, $nonEmptyCount)
exit 0
