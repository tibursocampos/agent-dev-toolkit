#Requires -Version 5.1
<#
.SYNOPSIS
  Structural validation for story EVD/ + STATE.md (REQ-005 / CA4).

.DESCRIPTION
  Deterministic evidence-or-zero checks - no LLM.
  Levels: off | cheap | standard | strict.

.PARAMETER StoryRoot
  Absolute or relative path to features/NNN-slug/USnn or TSnn/.

.PARAMETER PlanPath
  Explicit PLAN path from which the story root is derived.

.PARAMETER StoryPath
  Explicit STORY.md path from which the story root is derived.

.PARAMETER RepoPath
  Repository root used for canonical path containment (defaults to the current directory).

.PARAMETER Level
  Optional override. When omitted, reads Evidence level from STATE.md
  (defaults to cheap if STATE is missing and a gate is evaluated).

.EXAMPLE
  .\scripts\validation\validate-evidence.ps1 -StoryRoot features\005-x\US01 -Level cheap

.EXAMPLE
  .\scripts\validation\validate-evidence.ps1 -PlanPath features\005-x\TS02\PLAN\PLAN_005_x.md -Level cheap
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $StoryRoot,

    [Parameter(Mandatory = $false)]
    [string] $PlanPath,

    [Parameter(Mandatory = $false)]
    [string] $StoryPath,

    [Parameter(Mandatory = $false)]
    [string] $RepoPath = '',

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

function Test-PathUnder {
    param(
        [Parameter(Mandatory = $true)][string] $ChildPath,
        [Parameter(Mandatory = $true)][string] $ParentPath
    )
    $child = [System.IO.Path]::GetFullPath($ChildPath).TrimEnd('\', '/')
    $parent = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd('\', '/')
    return $child.StartsWith($parent + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
        $child.Equals($parent, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-InputPath {
    param([Parameter(Mandatory = $true)][string] $Path)
    if ($Path -match '(^|[\\/])\.\.([\\/]|$)') {
        throw 'path traversal is not allowed'
    }
    $candidate = $Path
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $candidate = Join-Path (Get-Location).Path $candidate
    }
    if (-not (Test-Path -LiteralPath $candidate)) {
        throw ("path not found: {0}" -f $Path)
    }
    return (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path
}

function Resolve-StoryRootPath {
    $inputs = @(
        @(
            [PSCustomObject]@{ Name = 'StoryRoot'; Value = $StoryRoot },
            [PSCustomObject]@{ Name = 'PlanPath'; Value = $PlanPath },
            [PSCustomObject]@{ Name = 'StoryPath'; Value = $StoryPath }
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Value) }
    )
    if ($inputs.Count -ne 1) {
        throw 'provide exactly one of -StoryRoot, -PlanPath, or -StoryPath'
    }

    $repoCandidate = if ([string]::IsNullOrWhiteSpace($RepoPath)) { (Get-Location).Path } else { $RepoPath }
    $repoRoot = (Resolve-Path -LiteralPath $repoCandidate -ErrorAction Stop).Path
    $featuresRoot = Join-Path $repoRoot 'features'
    $inputPath = Resolve-InputPath -Path $inputs[0].Value
    $candidate = $inputPath

    if ($inputs[0].Name -eq 'PlanPath') {
        if ((Get-Item -LiteralPath $inputPath).PSIsContainer -or $inputPath -notmatch '(?i)[\\/]PLAN[\\/]PLAN_[^\\/]+\.md$') {
            throw 'PlanPath must be a PLAN_*.md file under a story PLAN directory'
        }
        $candidate = Split-Path -Parent (Split-Path -Parent $inputPath)
    }
    elseif ($inputs[0].Name -eq 'StoryPath') {
        if ((Get-Item -LiteralPath $inputPath).PSIsContainer -or (Split-Path -Leaf $inputPath) -ne 'STORY.md') {
            throw 'StoryPath must point to STORY.md'
        }
        $candidate = Split-Path -Parent $inputPath
    }
    elseif (-not (Get-Item -LiteralPath $inputPath).PSIsContainer) {
        throw 'StoryRoot must be a directory'
    }

    $storyRoot = (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path
    if (-not (Test-PathUnder -ChildPath $storyRoot -ParentPath $featuresRoot)) {
        throw 'story root must remain under the repository features directory'
    }

    $relative = $storyRoot.Substring($repoRoot.Length).TrimStart('\', '/') -replace '\\', '/'
    if ($relative -notmatch '^features/\d{3}-[^/]+/(US|TS)\d{2}$') {
        throw 'story root must match features/NNN-slug/USnn or features/NNN-slug/TSnn'
    }

    $storyItem = Get-Item -LiteralPath $storyRoot
    if (($storyItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'story root symlink/reparse point is not allowed'
    }
    return [PSCustomObject]@{
        Root = $storyRoot
        Relative = $relative
    }
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
        [Parameter(Mandatory = $true)][string] $StoryRootPath,
        [Parameter(Mandatory = $true)][string] $StoryRelativePath,
        [Parameter(Mandatory = $true)][string] $EvidencePath
    )
    if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
        return $false
    }
    $normalized = $EvidencePath -replace '\\', '/'
    if ([System.IO.Path]::IsPathRooted($EvidencePath) -or $normalized -match '(^|/)\.\.(/|$)') {
        return $false
    }
    if ($normalized -match '(?i)^features/\d{3}-[^/]+/(US|TS)\d{2}/(EVD/.+)$') {
        if ($normalized -notmatch ('(?i)^' + [regex]::Escape($StoryRelativePath) + '/')) {
            return $false
        }
        $normalized = $Matches[2]
    }
    elseif ($normalized -notmatch '(?i)^EVD/') {
        return $false
    }
    $full = Join-Path $StoryRootPath ($normalized -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $evdRoot = Join-Path $StoryRootPath 'EVD'
    if (-not (Test-PathUnder -ChildPath $full -ParentPath $evdRoot)) {
        return $false
    }
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

try {
    $story = Resolve-StoryRootPath
}
catch {
    Write-ValidateFail -Message $_.Exception.Message
    exit 1
}
$resolvedRoot = $story.Root

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
    if (Test-NonEmptyEvidenceFile -StoryRootPath $resolvedRoot -StoryRelativePath $story.Relative -EvidencePath $row.Evidence) {
        $nonEmptyCount++
    }
}

if ($nonEmptyCount -eq 0) {
    Write-ValidateFail -Message 'level >= cheap requires at least one non-empty EVD evidence file cited by the matrix'
    exit 1
}

if ($effectiveLevel -eq 'standard' -or $effectiveLevel -eq 'strict') {
    foreach ($row in $matrixRows) {
        if (-not (Test-NonEmptyEvidenceFile -StoryRootPath $resolvedRoot -StoryRelativePath $story.Relative -EvidencePath $row.Evidence)) {
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
