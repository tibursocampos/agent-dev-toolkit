#Requires -Version 5.1
<##
.SYNOPSIS
  Deterministic validation of the evidence-classification table in a brownfield analysis.

.DESCRIPTION
  Accepts explicit Portuguese/English column and classification aliases, maps
  them in memory, and never rewrites the source artifact.

.PARAMETER Path
  Analysis Markdown file to validate.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\ToolkitConstants.ps1')

function Write-AnalysisFail([string]$Message) {
    Write-Host ("validate-brownfield-analysis: FAIL - {0}" -f $Message) -ForegroundColor Red
}

function Get-Cells([string]$Line) {
    if ($Line.IndexOf('|') -lt 0) { return @() }
    return @($Line.Trim().Trim('|').Split('|') | ForEach-Object { (Remove-SddArtifactDecoration $_).Trim() })
}

function Test-SeparatorRow([string[]]$Cells) {
    if ($Cells.Count -eq 0) { return $false }
    foreach ($cell in $Cells) {
        if ($cell -notmatch '^:?-{3,}:?$') { return $false }
    }
    return $true
}

function Get-ConsistentColumnValue(
    [int[]]$Indexes,
    [string[]]$Cells,
    [string]$FieldName,
    [int]$LineNumber,
    [System.Collections.Generic.List[string]]$Issues
) {
    if ($Indexes.Count -eq 0) { return '' }

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($index in $Indexes) {
        $value = if ($index -lt $Cells.Count) { [string]$Cells[$index] } else { '' }
        $values.Add($value.Trim())
    }

    $distinct = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($value in $values) { [void]$distinct.Add($value) }
    if ($distinct.Count -gt 1) {
        $rendered = @($values | ForEach-Object { if ([string]::IsNullOrWhiteSpace($_)) { '<empty>' } else { $_ } }) -join ' | '
        $Issues.Add(('line {0}: duplicate {1} columns conflict ({2}); keep one column or make all aliases identical' -f $LineNumber, $FieldName, $rendered))
    }

    return $values[0]
}

$resolvedPath = $Path
if (-not [System.IO.Path]::IsPathRooted($resolvedPath)) {
    $resolvedPath = Join-Path (Get-Location).Path $Path
}
if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
    Write-AnalysisFail ("file not found: {0}" -f $Path)
    exit 1
}

$lines = @(Get-Content -LiteralPath $resolvedPath -Encoding UTF8)
$issues = [System.Collections.Generic.List[string]]::new()
$normalized = [System.Collections.Generic.List[string]]::new()
$tableCount = 0
$rowCount = 0
$lineIndex = 0

while ($lineIndex -lt $lines.Count) {
    $headerCells = @(Get-Cells $lines[$lineIndex])
    if ($headerCells.Count -eq 0 -or $lineIndex + 1 -ge $lines.Count) { $lineIndex++; continue }
    $separatorCells = @(Get-Cells $lines[$lineIndex + 1])
    if (-not (Test-SeparatorRow $separatorCells)) { $lineIndex++; continue }

    $columns = @($headerCells | ForEach-Object {
        $alias = Resolve-SddArtifactAlias -Domain 'table-column' -Value $_
        if ($alias.Recognized) { $alias.Canonical } else { '' }
    })
    $classificationIndexes = @()
    for ($columnIndex = 0; $columnIndex -lt $columns.Count; $columnIndex++) {
        if ($columns[$columnIndex] -eq 'CLASSIFICATION') { $classificationIndexes += $columnIndex }
    }
    if ($classificationIndexes.Count -eq 0) { $lineIndex += 2; continue }

    $tableCount++
    $itemIndexes = @(); $evidenceIndexes = @(); $limitationIndexes = @()
    for ($columnIndex = 0; $columnIndex -lt $columns.Count; $columnIndex++) {
        switch ($columns[$columnIndex]) {
            'ITEM' { $itemIndexes += $columnIndex }
            'EVIDENCE' { $evidenceIndexes += $columnIndex }
            'LIMITATION' { $limitationIndexes += $columnIndex }
        }
    }
    if ($itemIndexes.Count -eq 0) { $issues.Add(('line {0}: classification table is missing an Item/Achado column' -f ($lineIndex + 1))) }
    if ($evidenceIndexes.Count -eq 0) { $issues.Add(('line {0}: classification table is missing an Evidence/Evidência reference column' -f ($lineIndex + 1))) }
    if ($limitationIndexes.Count -eq 0) { $issues.Add(('line {0}: classification table is missing a Limitation/Limitação column' -f ($lineIndex + 1))) }

    $dataIndex = $lineIndex + 2
    while ($dataIndex -lt $lines.Count) {
        $cells = @(Get-Cells $lines[$dataIndex])
        if ($cells.Count -eq 0) { break }
        $rowCount++
        $item = Get-ConsistentColumnValue -Indexes $itemIndexes -Cells $cells -FieldName 'Item/Achado' -LineNumber ($dataIndex + 1) -Issues $issues
        if ([string]::IsNullOrWhiteSpace($item) -or $item -match '^(?:—|-|n/?a)$') {
            $issues.Add(('line {0}: Item/Achado is required for each classification row' -f ($dataIndex + 1)))
        }

        $classAliases = [System.Collections.Generic.List[object]]::new()
        foreach ($index in $classificationIndexes) {
            $value = if ($index -lt $cells.Count) { $cells[$index] } else { '' }
            $classAliases.Add((Resolve-SddArtifactAlias -Domain 'evidence-classification' -Value $value))
        }
        $unknown = @($classAliases | Where-Object { -not $_.Recognized })
        if ($unknown.Count -gt 0) {
            $raw = ($unknown | ForEach-Object { if ([string]::IsNullOrWhiteSpace($_.Input)) { '<empty>' } else { $_.Input } }) -join ', '
            $issues.Add(("line {0}: unsupported evidence classification '{1}'; use CONFIRMED/Confirmado, INFERRED/Inferido, GAP/Lacuna, or PROPOSAL_ONLY/Apenas proposta" -f ($dataIndex + 1), $raw))
        }
        else {
            $canonicalValues = @($classAliases | ForEach-Object { $_.Canonical } | Select-Object -Unique)
            if ($canonicalValues.Count -gt 1) {
                $issues.Add(('line {0}: duplicate classification aliases conflict ({1}); keep one value or make them semantically identical' -f ($dataIndex + 1), ($canonicalValues -join ', ')))
            }
            else {
                $classification = $canonicalValues[0]
                $normalized.Add(("line {0}: {1} -> {2}" -f ($dataIndex + 1), ($classAliases[0].Input), $classification))
                $evidence = Get-ConsistentColumnValue -Indexes $evidenceIndexes -Cells $cells -FieldName 'Evidence/Evidência' -LineNumber ($dataIndex + 1) -Issues $issues
                $limitation = Get-ConsistentColumnValue -Indexes $limitationIndexes -Cells $cells -FieldName 'Limitation/Limitação' -LineNumber ($dataIndex + 1) -Issues $issues
                $hasPortableReference = $evidence -match '^[^:\s|]+(?:/[^:\s|]+)*:[A-Za-z_][A-Za-z0-9_.$#/-]*$' -and $evidence -notmatch '^[A-Za-z]:[\\/]'
                switch ($classification) {
                    'CONFIRMED' {
                        if (-not $hasPortableReference) { $issues.Add(('line {0}: CONFIRMED requires a portable path:symbol Evidence reference' -f ($dataIndex + 1))) }
                    }
                    'INFERRED' {
                        if (-not $hasPortableReference) { $issues.Add(('line {0}: INFERRED requires a portable path:symbol Evidence reference' -f ($dataIndex + 1))) }
                        if ([string]::IsNullOrWhiteSpace($limitation) -or $limitation -match '^(?:—|-|n/?a)$') { $issues.Add(('line {0}: INFERRED requires a Limitation explaining the indirect evidence' -f ($dataIndex + 1))) }
                    }
                    'GAP' {
                        if ([string]::IsNullOrWhiteSpace($limitation) -or $limitation -match '^(?:—|-|n/?a)$') { $issues.Add(('line {0}: GAP requires a Limitation explaining what evidence is missing or unresolved' -f ($dataIndex + 1))) }
                    }
                    'PROPOSAL_ONLY' {
                        if ($hasPortableReference -and $evidence -notmatch '(?i)proposal|proposta') { $issues.Add(('line {0}: PROPOSAL_ONLY must not present an evidence reference as proof; move it to a separately classified row' -f ($dataIndex + 1))) }
                    }
                }
            }
        }
        $dataIndex++
    }
    $lineIndex = $dataIndex + 1
}

if ($tableCount -eq 0) { $issues.Add('missing evidence-classification Markdown table (Item, Classification, Evidence, Limitation)') }
if ($tableCount -gt 1) { $issues.Add(('found {0} classification tables; use one unambiguous table per analysis document' -f $tableCount)) }
if ($rowCount -eq 0) { $issues.Add('evidence-classification table contains no data rows') }
if ($issues.Count -gt 0) {
    foreach ($issue in $issues) { Write-AnalysisFail $issue }
    exit 1
}

foreach ($entry in $normalized) { Write-Output ("validate-brownfield-analysis: NORMALIZED {0}" -f $entry) }
Write-Output ("validate-brownfield-analysis: PASS - {0} classification rows normalized in memory; source artifact unchanged" -f $rowCount)
exit 0
