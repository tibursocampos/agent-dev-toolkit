#Requires -Version 5.1
<#
.SYNOPSIS
  Detects runtime script copies that differ from their manifest source (stale installed copy).

.DESCRIPTION
  Compares each runtime-manifest source with the copy at
  <InstallRoot>/<destinationRoot>/<destination> by SHA-256. A missing or differing copy is
  reported as DRIFT. Equal hashes prove only byte equality of the copy; they do not prove
  activation or live execution.

  Without -InstallRoot the script runs a self-contained regression on a disposable fixture
  copy (identical copy passes, stale and missing copies are detected, a short manifest and
  a traversal destination are refused). It never writes to any installed root.

  Every manifest destination must resolve under <runtime root> before any copy, write or
  comparison; a destination that escapes the runtime root fails the run.

.PARAMETER InstallRoot
  Optional. Read-only comparison target (for example the installed toolkit root). Reported
  per file; the exit code is 1 when any file drifts, so a stale copy cannot pass silently.

.PARAMETER ManifestPath
  Optional manifest override used by the self-test's negative cases. Defaults to the
  repository runtime manifest.
#>
[CmdletBinding()]
param(
    [string] $InstallRoot,
    [string] $ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $repoRoot 'scripts/runtime/runtime-manifest.json'
}
$manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$entries = @($manifest.files)
if ($entries.Count -eq 0) { throw 'Runtime manifest contains no files.' }

# Fixture entries are selected by source name, never by position.
$requiredDriftSources = @(
    'scripts/inventory/Invoke-MemoryBankInventory.ps1',
    'scripts/session/Invoke-DevelopSessionGate.ps1',
    'scripts/ledger/Invoke-PlanLedgerClaim.ps1'
)

function Get-CopyState {
    param(
        [Parameter(Mandatory = $true)][string] $SourcePath,
        [Parameter(Mandatory = $true)][string] $CopyPath
    )
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) { return 'SOURCE_MISSING' }
    if (-not (Test-Path -LiteralPath $CopyPath -PathType Leaf)) { return 'COPY_MISSING' }
    $sourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
    $copyHash = (Get-FileHash -LiteralPath $CopyPath -Algorithm SHA256).Hash
    if ($sourceHash -eq $copyHash) { return 'SAME' }
    return 'DRIFT'
}

function Resolve-ContainedCopyPath {
    param(
        [Parameter(Mandatory = $true)][string] $RuntimeRoot,
        [Parameter(Mandatory = $true)][string] $Destination
    )
    $rootFull = [System.IO.Path]::GetFullPath($RuntimeRoot).TrimEnd('\', '/')
    $relative = $Destination -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $candidate = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $relative))
    if (-not $candidate.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ("Runtime manifest destination escapes runtime root: '{0}' resolves outside '{1}'" -f $Destination, $rootFull)
    }
    return $candidate
}

function Get-ManifestEntryBySource {
    param(
        [Parameter(Mandatory = $true)][object[]] $ManifestEntries,
        [Parameter(Mandatory = $true)][string] $Source
    )
    $match = @($ManifestEntries | Where-Object { [string]$_.source -eq $Source })
    if ($match.Count -ne 1) {
        throw ("Runtime manifest must list drift fixture entry '{0}' exactly once (found {1})." -f $Source, $match.Count)
    }
    return $match[0]
}

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $fixtureBase = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ('adt-runtime-copy-drift-' + [guid]::NewGuid().ToString('N')))).TrimEnd([char]92, [char]47)
    $testRoot = Join-Path $fixtureBase 'copies'
    $fullTestRoot = [System.IO.Path]::GetFullPath($testRoot).TrimEnd('\', '/')
    $fixturePrefix = $fixtureBase + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullTestRoot.StartsWith($fixturePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing test root outside the temp fixture base: $fullTestRoot"
    }
    $runtimeRoot = Join-Path $fullTestRoot $manifest.destinationRoot

    # Validate the whole manifest before the first copy or write.
    if ($entries.Count -lt $requiredDriftSources.Count) {
        throw ("Runtime manifest has {0} entr(y/ies); the drift self-test needs at least {1} manifest entries." -f $entries.Count, $requiredDriftSources.Count)
    }
    $copyTargets = @{}
    foreach ($entry in $entries) {
        $copyTargets[[string]$entry.source] = Resolve-ContainedCopyPath -RuntimeRoot $runtimeRoot -Destination ([string]$entry.destination)
    }
    $first = Get-ManifestEntryBySource -ManifestEntries $entries -Source $requiredDriftSources[0]
    $second = Get-ManifestEntryBySource -ManifestEntries $entries -Source $requiredDriftSources[1]
    $third = Get-ManifestEntryBySource -ManifestEntries $entries -Source $requiredDriftSources[2]

    try {
        foreach ($entry in $entries) {
            $copy = $copyTargets[[string]$entry.source]
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $copy) | Out-Null
            Copy-Item -LiteralPath (Join-Path $repoRoot $entry.source) -Destination $copy -Force
        }
        $firstSource = Join-Path $repoRoot $first.source
        $firstCopy = $copyTargets[[string]$first.source]
        $secondCopy = $copyTargets[[string]$second.source]
        $thirdCopy = $copyTargets[[string]$third.source]

        $identical = @($entries | ForEach-Object { Get-CopyState -SourcePath (Join-Path $repoRoot $_.source) -CopyPath $copyTargets[[string]$_.source] } | Where-Object { $_ -ne 'SAME' }).Count
        if ($identical -ne 0) { throw "Identical fixture copies were not reported SAME ($identical non-SAME)." }

        Add-Content -LiteralPath $firstCopy -Value '# stale fixture edit'
        if ((Get-CopyState -SourcePath $firstSource -CopyPath $firstCopy) -ne 'DRIFT') {
            throw 'Stale fixture copy was not reported DRIFT.'
        }

        Remove-Item -LiteralPath $thirdCopy -Force
        if ((Get-CopyState -SourcePath (Join-Path $repoRoot $third.source) -CopyPath $thirdCopy) -ne 'COPY_MISSING') {
            throw 'Missing fixture copy was not reported COPY_MISSING.'
        }

        if ((Get-CopyState -SourcePath (Join-Path $repoRoot $second.source) -CopyPath $secondCopy) -ne 'SAME') {
            throw 'Untouched fixture copy changed state unexpectedly.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $fullTestRoot) {
            Remove-Item -LiteralPath $fullTestRoot -Recurse -Force
        }
    }

    if ([string]::IsNullOrWhiteSpace($PSBoundParameters['ManifestPath'])) {
        # Negative cases run in child processes against disposable manifests; they must fail before any copy.
        $negativeRoot = Join-Path $fixtureBase 'manifests'
        try {
            New-Item -ItemType Directory -Path $negativeRoot -Force | Out-Null
            $namedEntries = @(
                foreach ($source in $requiredDriftSources) {
                    $real = Get-ManifestEntryBySource -ManifestEntries $entries -Source $source
                    [ordered]@{ source = $source; destination = [string]$real.destination; class = 'runtime' }
                }
            )
            $shortPath = Join-Path $negativeRoot 'short-manifest.json'
            ([ordered]@{ schemaVersion = 1; destinationRoot = 'scripts'; files = @($namedEntries[0]) } | ConvertTo-Json -Depth 6) |
                Set-Content -LiteralPath $shortPath -Encoding UTF8
            $traversalEntries = @($namedEntries | ForEach-Object { $_ })
            $traversalEntries[0] = [ordered]@{ source = $requiredDriftSources[0]; destination = '../../escape-probe.txt'; class = 'runtime' }
            $traversalPath = Join-Path $negativeRoot 'traversal-manifest.json'
            ([ordered]@{ schemaVersion = 1; destinationRoot = 'scripts'; files = $traversalEntries } | ConvertTo-Json -Depth 6) |
                Set-Content -LiteralPath $traversalPath -Encoding UTF8

            $shortOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -ManifestPath $shortPath 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -or $shortOut -notmatch 'needs at least 3 manifest entries') {
                throw ("Short manifest was not refused with a clear entry-count message: {0}" -f $shortOut)
            }

            $probePath = Join-Path $fixtureBase 'escape-probe.txt'
            if (Test-Path -LiteralPath $probePath) { Remove-Item -LiteralPath $probePath -Force }
            $traversalOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -ManifestPath $traversalPath 2>&1 | Out-String
            $traversalCode = $LASTEXITCODE
            $probeWritten = Test-Path -LiteralPath $probePath
            if (Test-Path -LiteralPath $probePath) { Remove-Item -LiteralPath $probePath -Force }
            if ($traversalCode -eq 0 -or $traversalOut -notmatch 'escapes runtime root' -or $probeWritten) {
                throw ("Traversal destination was not refused before any write: exit {0}, probe {1}: {2}" -f $traversalCode, $probeWritten, $traversalOut)
            }
        }
        finally {
            if (Test-Path -LiteralPath $negativeRoot) { Remove-Item -LiteralPath $negativeRoot -Recurse -Force }
        }
    }

    if (Test-Path -LiteralPath $fixtureBase) { Remove-Item -LiteralPath $fixtureBase -Recurse -Force }

    Write-Output 'Assert-RuntimeCopyDrift: PASS (fixture regression: identical=SAME, stale=DRIFT, missing=COPY_MISSING; short manifest and traversal destination refused)'
    exit 0
}

$resolvedInstall = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
$runtimeRoot = Join-Path $resolvedInstall $manifest.destinationRoot
$copyTargets = @{}
foreach ($entry in $entries) {
    $copyTargets[[string]$entry.source] = Resolve-ContainedCopyPath -RuntimeRoot $runtimeRoot -Destination ([string]$entry.destination)
}
$driftCount = 0
foreach ($entry in $entries) {
    $state = Get-CopyState -SourcePath (Join-Path $repoRoot $entry.source) -CopyPath $copyTargets[[string]$entry.source]
    if ($state -ne 'SAME') { $driftCount++ }
    Write-Output ("{0} | {1}" -f $state, $entry.destination)
}
if ($driftCount -gt 0) {
    Write-Output ("Assert-RuntimeCopyDrift: DRIFT ({0} of {1} copies not equal to source) under {2}" -f $driftCount, $entries.Count, $resolvedInstall)
    exit 1
}
Write-Output ("Assert-RuntimeCopyDrift: PASS ({0} copies equal source) under {1}" -f $entries.Count, $resolvedInstall)
exit 0
