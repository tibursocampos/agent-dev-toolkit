#Requires -Version 5.1
<#
.SYNOPSIS
  Owner-side write and readback of one step status field in a PLAN or REFINE file.

.DESCRIPTION
  Changes exactly one status token for one step, writes the
  file through a temporary sibling and File.Replace, rereads it and compares the
  complete text with the intended text. Missing or duplicated rows, expected-state
  conflicts, divergent readback and unrelated changes fail closed with a code. The
  target must be a non-reparse file under <RepoPath>/features. A concurrent edit seen at replace time is undone; a failed readback is reported as unverified and must be reconciled by
  the owner.

  Fields:
    Ledger       PLAN only. Status cell of the row whose Step ID equals -StepId in the
                 first table that has Step ID and Status columns.
    StepHeading  PLAN or REFINE. First non-empty line under the heading
                 "### STEP n - Sx", which must contain exactly one backticked status token.

.PARAMETER Kind
  PLAN or REFINE.

.PARAMETER Field
  Ledger or StepHeading. Ledger is valid for PLAN only.

.PARAMETER FilePath
  Path to the PLAN or REFINE file. Must resolve under <RepoPath>/features.

.PARAMETER StepId
  Step identifier such as S2.

.PARAMETER Status
  Intended canonical status.

.PARAMETER ExpectedCurrent
  Optional. When given, the write is refused unless the current status equals it.

.PARAMETER RepoPath
  Repository root that owns the features folder. Defaults via Get-ToolkitRepoRoot.

.OUTPUTS
  One JSON object on stdout with code, status_from, status_to and readback.

.EXAMPLE
  .\scripts\ledger\Invoke-PlanStepStateWrite.ps1 -Kind PLAN -Field Ledger -FilePath features\x\TS01\PLAN\PLAN_001_x.md -StepId S2 -Status COMPLETED -ExpectedCurrent PENDING
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('PLAN', 'REFINE')]
    [string] $Kind,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Ledger', 'StepHeading')]
    [string] $Field,

    [Parameter(Mandatory = $true)]
    [string] $FilePath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^S\d{1,3}$')]
    [string] $StepId,

    [Parameter(Mandatory = $true)]
    [ValidateSet('COMPLETED', 'PENDING', 'IN_PROGRESS', 'BLOCKED', 'SKIPPED')]
    [string] $Status,

    [ValidateSet('COMPLETED', 'PENDING', 'IN_PROGRESS', 'BLOCKED', 'SKIPPED')]
    [string] $ExpectedCurrent,

    [switch] $ReopenDependents,

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
. (Join-Path $libDir 'Get-ToolkitRelativePath.ps1')
. (Join-Path $libDir 'Test-ToolkitFileReadback.ps1')

$exitVerified = 0
$exitUsage = 2
$exitStructure = 3
$exitConflict = 4
$exitUnverified = 5

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}


function Get-StepStateCodePrefix {
    param([Parameter(Mandatory = $true)][string] $KindValue)
    return $KindValue.ToLowerInvariant()
}

function Test-StepStateFieldSupported {
    param(
        [Parameter(Mandatory = $true)][string] $KindValue,
        [Parameter(Mandatory = $true)][string] $FieldValue
    )
    return -not ($FieldValue -eq 'Ledger' -and $KindValue -ne 'PLAN')
}

function New-StepStateEdit {
    param(
        [bool] $Ok,
        [string] $Code,
        [string] $From = '',
        [string] $NewText = ''
    )
    return [pscustomobject]@{ Ok = $Ok; Code = $Code; From = $From; NewText = $NewText }
}

function Get-StepStateCellLabel {
    param([AllowEmptyString()][string] $Cell)
    return (($Cell -replace '[*`\s_]', '').ToUpperInvariant())
}

function Get-StepStateColumnIndex {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]] $Cells,
        [Parameter(Mandatory = $true)][string[]] $Names
    )
    for ($c = 0; $c -lt $Cells.Count; $c++) {
        if ((Get-StepStateCellLabel -Cell $Cells[$c]) -in $Names) { return $c }
    }
    return -1
}

function Get-StepStateTableColumns {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]] $Cells)
    return [pscustomobject]@{
        Step       = Get-StepStateColumnIndex -Cells $Cells -Names @('STEPID', 'ID')
        Status     = Get-StepStateColumnIndex -Cells $Cells -Names @('STATUS', 'ESTADO')
        Dependency = Get-StepStateColumnIndex -Cells $Cells -Names @('DEPENDENCIES', 'DEPENDENCY', 'DEPENDENCIAS')
    }
}

function Get-StepLedgerEdit {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Prefix,
        [Parameter(Mandatory = $true)][string] $StepId,
        [Parameter(Mandatory = $true)][string] $NewStatus,
        [string] $ExpectedCurrent
    )

    $lines = $Text.Split("`n")
    $headerIndex = -1
    $stepColumn = -1
    $statusColumn = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $content = $lines[$i].TrimEnd("`r")
        if (-not $content.StartsWith('|')) { continue }
        $columns = Get-StepStateTableColumns -Cells $content.Split('|')
        if ($columns.Step -ge 0 -and $columns.Status -ge 0) {
            $headerIndex = $i
            $stepColumn = $columns.Step
            $statusColumn = $columns.Status
            break
        }
    }
    if ($headerIndex -lt 0) {
        return New-StepStateEdit -Ok $false -Code ("{0}_progress_table_missing" -f $Prefix)
    }

    $rows = [System.Collections.Generic.List[int]]::new()
    for ($i = $headerIndex + 1; $i -lt $lines.Count; $i++) {
        $content = $lines[$i].TrimEnd("`r")
        if (-not $content.StartsWith('|')) { break }
        $cells = $content.Split('|')
        if ($cells.Count -le [Math]::Max($stepColumn, $statusColumn)) { continue }
        $rowStep = ($cells[$stepColumn] -replace '[*`\s]', '').ToUpperInvariant()
        if ($rowStep -eq $StepId.ToUpperInvariant()) { $rows.Add($i) }
    }
    if ($rows.Count -eq 0) {
        return New-StepStateEdit -Ok $false -Code ("{0}_step_row_missing" -f $Prefix)
    }
    if ($rows.Count -gt 1) {
        return New-StepStateEdit -Ok $false -Code ("{0}_step_row_duplicate" -f $Prefix)
    }

    $rowIndex = $rows[0]
    $rowContent = $lines[$rowIndex].TrimEnd("`r")
    $lineEnding = $lines[$rowIndex].Substring($rowContent.Length)
    $cells = $rowContent.Split('|')
    $statusCell = $cells[$statusColumn]
    $tokenMatches = [regex]::Matches($statusCell, '(?<![A-Za-z_])(COMPLETED|PENDING|IN_PROGRESS|BLOCKED|SKIPPED)(?![A-Za-z_])')
    if ($tokenMatches.Count -ne 1) {
        return New-StepStateEdit -Ok $false -Code ("{0}_step_status_invalid" -f $Prefix)
    }

    $token = $tokenMatches[0]
    $from = $token.Value
    if (-not [string]::IsNullOrEmpty($ExpectedCurrent) -and ($from -cne $ExpectedCurrent)) {
        return New-StepStateEdit -Ok $false -Code ("{0}_state_conflict" -f $Prefix) -From $from
    }

    $cells[$statusColumn] = $statusCell.Substring(0, $token.Index) + $NewStatus + $statusCell.Substring($token.Index + $token.Length)
    $lines[$rowIndex] = ([string]::Join('|', $cells)) + $lineEnding
    return New-StepStateEdit -Ok $true -Code 'edit_ready' -From $from -NewText ([string]::Join("`n", $lines))
}

function Get-StepHeadingEdit {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Prefix,
        [Parameter(Mandatory = $true)][string] $StepId,
        [Parameter(Mandatory = $true)][string] $NewStatus,
        [string] $ExpectedCurrent
    )

    $completedMark = [string][char]0x2705
    $pendingMark = [string][char]0x2610
    $lines = $Text.Split("`n")
    $headings = [System.Collections.Generic.List[int]]::new()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $content = $lines[$i].TrimEnd("`r")
        $dashClass = '[' + ([string][char]0x2014) + ([string][char]0x2013) + '-]'
        $match = [regex]::Match($content, ('^#{1,6}\s+STEP\s+\d+\s*' + $dashClass + '\s*(S\d{1,3})\b'))
        if ($match.Success -and ($match.Groups[1].Value.ToUpperInvariant() -eq $StepId.ToUpperInvariant())) {
            $headings.Add($i)
        }
    }
    if ($headings.Count -eq 0) {
        return New-StepStateEdit -Ok $false -Code ("{0}_step_heading_missing" -f $Prefix)
    }
    if ($headings.Count -gt 1) {
        return New-StepStateEdit -Ok $false -Code ("{0}_step_heading_duplicate" -f $Prefix)
    }

    $statusIndex = -1
    for ($j = $headings[0] + 1; $j -lt $lines.Count; $j++) {
        $candidate = $lines[$j].TrimEnd("`r").Trim()
        if ($candidate.Length -eq 0) { continue }
        if ($candidate.StartsWith('#')) { break }
        $statusIndex = $j
        break
    }
    if ($statusIndex -lt 0) {
        return New-StepStateEdit -Ok $false -Code ("{0}_step_status_invalid" -f $Prefix)
    }

    $statusContent = $lines[$statusIndex].TrimEnd("`r")
    $lineEnding = $lines[$statusIndex].Substring($statusContent.Length)
    $tokenMatches = [regex]::Matches($statusContent, '`(COMPLETED|PENDING|IN_PROGRESS|BLOCKED|SKIPPED)`')
    if ($tokenMatches.Count -ne 1) {
        return New-StepStateEdit -Ok $false -Code ("{0}_step_status_invalid" -f $Prefix)
    }

    $token = $tokenMatches[0]
    $from = $token.Groups[1].Value
    if (-not [string]::IsNullOrEmpty($ExpectedCurrent) -and ($from -cne $ExpectedCurrent)) {
        return New-StepStateEdit -Ok $false -Code ("{0}_state_conflict" -f $Prefix) -From $from
    }

    $newLine = $statusContent.Substring(0, $token.Index) + '`' + $NewStatus + '`' + $statusContent.Substring($token.Index + $token.Length)
    if ($NewStatus -eq 'COMPLETED' -and $newLine.StartsWith($pendingMark)) {
        $newLine = $completedMark + $newLine.Substring($pendingMark.Length)
    }
    elseif ($NewStatus -ne 'COMPLETED' -and $newLine.StartsWith($completedMark)) {
        $newLine = $pendingMark + $newLine.Substring($completedMark.Length)
    }
    $lines[$statusIndex] = $newLine + $lineEnding
    return New-StepStateEdit -Ok $true -Code 'edit_ready' -From $from -NewText ([string]::Join("`n", $lines))
}

function Get-StepStateEdit {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $KindValue,
        [Parameter(Mandatory = $true)][string] $FieldValue,
        [Parameter(Mandatory = $true)][string] $StepIdValue,
        [Parameter(Mandatory = $true)][string] $NewStatus,
        [string] $ExpectedCurrentValue
    )

    $prefix = Get-StepStateCodePrefix -KindValue $KindValue
    if ($FieldValue -eq 'Ledger') {
        return Get-StepLedgerEdit -Text $Text -Prefix $prefix -StepId $StepIdValue -NewStatus $NewStatus -ExpectedCurrent $ExpectedCurrentValue
    }
    return Get-StepHeadingEdit -Text $Text -Prefix $prefix -StepId $StepIdValue -NewStatus $NewStatus -ExpectedCurrent $ExpectedCurrentValue
}

function Get-StepDependencyMap {
    param([Parameter(Mandatory = $true)][string] $Text)

    $map = @{}
    $currentHeadingStep = $null
    $idColumn = -1
    $dependencyColumn = -1
    foreach ($line in ($Text -split "`r?`n")) {
        if ($line -match '^\|') {
            $cells = $line.Split('|')
            $columns = Get-StepStateTableColumns -Cells $cells
            if ($columns.Step -ge 0 -and $columns.Dependency -ge 0) {
                $idColumn = $columns.Step
                $dependencyColumn = $columns.Dependency
                continue
            }
            if ($idColumn -gt 0 -and $dependencyColumn -gt 0 -and $cells.Count -gt [Math]::Max($idColumn, $dependencyColumn)) {
                $id = $cells[$idColumn].Trim().Trim([char]96)
                if ($id -match '^S\d+$') {
                    $map[$id] = @([regex]::Matches($cells[$dependencyColumn], '\bS\d+\b') | ForEach-Object { $_.Value } | Select-Object -Unique)
                    continue
                }
            }
        }
        if ($line -match '^#+\s*STEP\s+\d+\s*\p{Pd}\s*(S\d+)') {
            $currentHeadingStep = $Matches[1]
            continue
        }
        if ($null -ne $currentHeadingStep -and $line -match '\*\*Depends on:\*\*(.*)$') {
            $map[$currentHeadingStep] = @([regex]::Matches($Matches[1], '\bS\d+\b') | ForEach-Object { $_.Value } | Select-Object -Unique)
            $currentHeadingStep = $null
        }
    }
    return $map
}

function Get-TransitiveDependents {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Map,
        [Parameter(Mandatory = $true)][string] $Root
    )

    $found = New-Object System.Collections.Generic.List[string]
    $queue = New-Object System.Collections.Generic.Queue[string]
    $queue.Enqueue($Root)
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        foreach ($candidate in $Map.Keys) {
            if ($candidate -eq $Root -or $found.Contains($candidate)) { continue }
            if (@($Map[$candidate]) -contains $current) {
                $found.Add($candidate)
                $queue.Enqueue($candidate)
            }
        }
    }
    return @($found)
}

function Test-StepStateBytesEqual {
    param([byte[]] $Left, [byte[]] $Right)
    return ([Convert]::ToBase64String($Left) -ceq [Convert]::ToBase64String($Right))
}

function Remove-StaleStepStateTempFiles {
    param([Parameter(Mandatory = $true)][string] $FullFilePath)
    $directory = Split-Path -Parent $FullFilePath
    $leaf = [regex]::Escape([System.IO.Path]::GetFileName($FullFilePath))
    $pattern = '^\.' + $leaf + '\.[0-9a-f]{32}\.tmp$'
    $cutoff = (Get-Date).AddHours(-1)
    foreach ($candidate in (Get-ChildItem -LiteralPath $directory -Force -File -ErrorAction SilentlyContinue)) {
        if ($candidate.Name -match $pattern -and $candidate.LastWriteTime -lt $cutoff) {
            Remove-Item -LiteralPath $candidate.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-StepStatePathRejection {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $FullFilePath
    )

    $relative = (Get-ToolkitRelativePath -BasePath (Join-Path $RepoRoot 'features') -TargetPath $FullFilePath).Replace('\', '/')
    if ([System.IO.Path]::IsPathRooted($relative) -or $relative -match '(^|/)\.\.(/|$)' -or $relative -notmatch '/') {
        return 'path_outside_features'
    }
    # A colon in the leaf name selects an alternate data stream on Windows, not a file.
    if ([System.IO.Path]::GetFileName($FullFilePath).Contains(':')) {
        return 'path_invalid_name'
    }

    $repoFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
    $current = $FullFilePath
    while (-not [string]::IsNullOrEmpty($current) -and $current.Length -gt $repoFull.Length) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                return 'path_reparse_point'
            }
        }
        $current = Split-Path -Parent $current
    }
    return ''
}

function Write-StepStateResult {
    param([Parameter(Mandatory = $true)]$Object)
    Write-Output ($Object | ConvertTo-Json -Compress -Depth 4)
}

$prefix = Get-StepStateCodePrefix -KindValue $Kind

if (-not (Test-StepStateFieldSupported -KindValue $Kind -FieldValue $Field)) {
    Write-StepStateResult -Object ([ordered]@{ ok = $false; code = 'field_not_supported_for_kind'; kind = $Kind; field = $Field; step = $StepId })
    exit $exitUsage
}

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    $RepoPath = Get-ToolkitRepoRoot -FromPath $scriptDir
}
$repoResolved = (Resolve-Path -LiteralPath $RepoPath).Path
$fullFilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PWD.ProviderPath, $FilePath))

$rejection = Get-StepStatePathRejection -RepoRoot $repoResolved -FullFilePath $fullFilePath
if (-not [string]::IsNullOrEmpty($rejection)) {
    Write-StepStateResult -Object ([ordered]@{ ok = $false; code = $rejection; kind = $Kind; field = $Field; step = $StepId })
    exit $exitUsage
}

if (-not (Test-Path -LiteralPath $fullFilePath -PathType Leaf)) {
    Write-StepStateResult -Object ([ordered]@{ ok = $false; code = 'file_missing'; kind = $Kind; field = $Field; step = $StepId })
    exit $exitUsage
}

if ($ReopenDependents -and ($Kind -ne 'PLAN' -or $Status -notin @('PENDING', 'IN_PROGRESS'))) {
    Write-StepStateResult -Object ([ordered]@{ ok = $false; code = 'reopen_dependents_not_applicable'; kind = $Kind; field = $Field; step = $StepId })
    exit $exitUsage
}

$originalBytes = [System.IO.File]::ReadAllBytes($fullFilePath)
$original = (Get-Utf8NoBomEncoding).GetString($originalBytes)
if ($original.Contains([string][char]0xFFFD)) {
    Write-StepStateResult -Object ([ordered]@{ ok = $false; code = ("{0}_invalid_utf8" -f $prefix); kind = $Kind; field = $Field; step = $StepId; written = $false; state = 'not_written' })
    exit $exitStructure
}
$edit = Get-StepStateEdit -Text $original -KindValue $Kind -FieldValue $Field -StepIdValue $StepId -NewStatus $Status -ExpectedCurrentValue $ExpectedCurrent

$summary = [ordered]@{ kind = $Kind; field = $Field; file = $FilePath; step = $StepId; status_to = $Status }
if (-not $edit.Ok) {
    $summary['ok'] = $false
    $summary['code'] = $edit.Code
    $summary['status_from'] = $edit.From
    $summary['written'] = $false
    $summary['state'] = 'not_written'
    Write-StepStateResult -Object $summary
    if ($edit.Code -like '*state_conflict') { exit $exitConflict }
    exit $exitStructure
}

$summary['status_from'] = $edit.From

# Reopening a completed step reopens its completed transitive dependents in the same write,
# so the PLAN never shows a completed step that depends on a reopened one.
$finalText = $edit.NewText
$reopenedDependents = @()
if ($ReopenDependents -and $Kind -eq 'PLAN' -and $Status -in @('PENDING', 'IN_PROGRESS')) {
    $dependencyMap = Get-StepDependencyMap -Text $finalText
    foreach ($dependent in (Get-TransitiveDependents -Map $dependencyMap -Root $StepId)) {
        $dependentEdit = Get-StepStateEdit -Text $finalText -KindValue $Kind -FieldValue $Field -StepIdValue $dependent -NewStatus 'PENDING' -ExpectedCurrentValue ''
        if (-not $dependentEdit.Ok) {
            # A dependent that cannot be read or located must not leave the PLAN half reopened.
            $summary['ok'] = $false
            $summary['code'] = "{0}_dependent_reopen_failed" -f $prefix
            $summary['dependent'] = $dependent
            $summary['written'] = $false
            $summary['state'] = 'not_written'
            Write-StepStateResult -Object $summary
            exit $exitStructure
        }
        if ($dependentEdit.From -ceq 'COMPLETED') {
            $finalText = $dependentEdit.NewText
            $reopenedDependents += $dependent
        }
    }
}
$summary['dependents_reopened'] = @($reopenedDependents)

# Temporary sibling + replace: a crash leaves either the old or the new complete file.
# File.Replace hands back the bytes it displaced, so a concurrent edit is detected and undone.
Remove-StaleStepStateTempFiles -FullFilePath $fullFilePath
$temporaryPath = Join-Path (Split-Path -Parent $fullFilePath) ('.{0}.{1}.tmp' -f [System.IO.Path]::GetFileName($fullFilePath), [Guid]::NewGuid().ToString('N'))
$backupPath = $temporaryPath + '.bak'
$outcome = 'written'
$keepBackup = $false
try {
    [System.IO.File]::WriteAllBytes($temporaryPath, (Get-Utf8NoBomEncoding).GetBytes($finalText))
    $recheck = Get-StepStatePathRejection -RepoRoot $repoResolved -FullFilePath $fullFilePath
    if (-not [string]::IsNullOrEmpty($recheck)) {
        $outcome = $recheck
    }
    elseif (-not (Test-StepStateBytesEqual -Left ([System.IO.File]::ReadAllBytes($fullFilePath)) -Right $originalBytes)) {
        $outcome = 'unrelated_change'
    }
    else {
        [System.IO.File]::Replace($temporaryPath, $fullFilePath, $backupPath)
        if (-not (Test-StepStateBytesEqual -Left ([System.IO.File]::ReadAllBytes($backupPath)) -Right $originalBytes)) {
            $outcome = 'unrelated_change'
            try { [System.IO.File]::Replace($backupPath, $fullFilePath, $null) }
            catch {
                $outcome = 'restore_failed'
                $keepBackup = $true
            }
        }
    }
}
catch {
    $outcome = 'write_failed'
}
finally {
    foreach ($leftover in @($temporaryPath, $backupPath)) {
        if ($keepBackup -and $leftover -eq $backupPath) { continue }
        if (Test-Path -LiteralPath $leftover) {
            Remove-Item -LiteralPath $leftover -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($outcome -ne 'written') {
    $summary['ok'] = $false
    $summary['written'] = $false
    $summary['state'] = 'not_written'
    if ($outcome -in @('path_reparse_point', 'path_outside_features', 'path_invalid_name')) {
        $summary['code'] = $outcome
        Write-StepStateResult -Object $summary
        exit $exitUsage
    }
    if ($outcome -eq 'restore_failed') {
        $summary['code'] = "{0}_restore_failed" -f $prefix
        $summary['backup'] = $backupPath
        $summary['readback'] = 'unrelated_change'
    }
    elseif ($outcome -eq 'unrelated_change') {
        $summary['code'] = "{0}_unrelated_change" -f $prefix
        $summary['readback'] = 'unrelated_change'
    }
    else {
        $summary['code'] = "{0}_write_failed" -f $prefix
    }
    Write-StepStateResult -Object $summary
    exit $exitUnverified
}
$summary['written'] = $true

if (Test-ToolkitFileReadback -Path $fullFilePath -ExpectedText $finalText) {
    $summary['ok'] = $true
    $summary['code'] = 'step_state_verified'
    $summary['readback'] = 'match'
    $summary['state'] = 'verified'
    Write-StepStateResult -Object $summary
    exit $exitVerified
}

$reread = (Get-Utf8NoBomEncoding).GetString([System.IO.File]::ReadAllBytes($fullFilePath))
$probe = Get-StepStateEdit -Text $reread -KindValue $Kind -FieldValue $Field -StepIdValue $StepId -NewStatus $Status -ExpectedCurrentValue ''
$targetReadsIntended = ($probe.Ok -and ($probe.From -ceq $Status))
$summary['ok'] = $false
$summary['readback'] = if ($targetReadsIntended) { 'unrelated_change' } else { 'mismatch' }
$summary['code'] = if ($targetReadsIntended) { "{0}_unrelated_change" -f $prefix } else { "{0}_readback_mismatch" -f $prefix }
$summary['state'] = 'unverified'
Write-StepStateResult -Object $summary
exit $exitUnverified
