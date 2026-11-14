#Requires -Version 5.1
<#
.SYNOPSIS
  Static integrity contract for scripts/runtime/runtime-manifest.json.

.DESCRIPTION
  Read-only. Checks that:
    (c) every manifest source file exists on disk;
    (d) every _lib script dot-sourced by a runtime-class manifest script, transitively, has its own manifest entry.
  Each failing path is reported by name and the script exits 1. Negative self-checks prove that both
  detectors fire: a bogus manifest source, and a dot-sourced lib missing from an in-memory manifest.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$manifestPath = Join-Path $repoRoot 'scripts/runtime/runtime-manifest.json'
$dotSourcePattern = '^\s*\.\s+\S'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string[]] $Reasons
    )
    foreach ($reason in $Reasons) {
        Write-Host ("{0}: FAIL - {1}" -f $TestName, $reason)
    }
    exit 1
}

function Get-ManifestEntries {
    param([Parameter(Mandatory = $true)][string] $ManifestPath)
    $manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    return @($manifest.files)
}

function Get-MissingManifestSources {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Entries
    )
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $Entries) {
        $source = [string]$entry.source
        if (-not (Test-Path -LiteralPath (Join-Path $Root $source) -PathType Leaf)) {
            $missing.Add($source)
        }
    }
    return $missing.ToArray()
}

function Get-DotSourcedLibNames {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][bool] $InLibDirectory
    )
    $names = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -notmatch $dotSourcePattern) { continue }
        $found = $false
        foreach ($match in [regex]::Matches($line, '_lib[\\/]([A-Za-z0-9_.-]+\.ps1)')) {
            $names.Add($match.Groups[1].Value)
            $found = $true
        }
        foreach ($match in [regex]::Matches($line, "_lib['""]\s*,?\s*['""]([A-Za-z0-9_.-]+\.ps1)['""]")) {
            $names.Add($match.Groups[1].Value)
            $found = $true
        }
        if (-not $found -and $InLibDirectory -and $line -match 'PSScriptRoot') {
            foreach ($match in [regex]::Matches($line, "['""]([A-Za-z0-9_.-]+\.ps1)['""]")) {
                $names.Add($match.Groups[1].Value)
            }
        }
    }
    return $names.ToArray()
}

function Get-UnregisteredLibDependencies {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Entries
    )
    $registered = @($Entries | ForEach-Object { [string]$_.source })
    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($entry in @($Entries | Where-Object { ([string]$_.class) -eq 'runtime' })) {
        $queue.Enqueue([string]$entry.source)
    }
    $seen = @{}
    $problems = [System.Collections.Generic.List[string]]::new()
    while ($queue.Count -gt 0) {
        $source = $queue.Dequeue()
        if ($seen.ContainsKey($source)) { continue }
        $seen[$source] = $true
        $path = Join-Path $Root $source
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $inLibDirectory = ($source -like 'scripts/_lib/*')
        $text = [System.IO.File]::ReadAllText($path)
        foreach ($name in @(Get-DotSourcedLibNames -Text $text -InLibDirectory $inLibDirectory)) {
            $libSource = "scripts/_lib/$name"
            if (-not ($registered -ccontains $libSource)) {
                $problems.Add(("{0} (required by {1})" -f $libSource, $source))
            }
            $queue.Enqueue($libSource)
        }
    }
    return $problems.ToArray()
}

$testSource = 'Should_FindEverySource_When_RuntimeManifestRead'
$testLib = 'Should_RegisterEveryDotSourcedLib_When_RuntimeScriptsRead'
$testSourceMissing = 'Should_Fail_When_SourceMissing'
$testLibUnregistered = 'Should_Fail_When_LibUnregistered'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Fail -TestName $testSource -Reasons @("runtime manifest missing: $manifestPath")
}
$entries = @(Get-ManifestEntries -ManifestPath $manifestPath)
if ($entries.Count -eq 0) {
    Write-Fail -TestName $testSource -Reasons @('runtime-manifest.json lists no files')
}
$missingSources = @(Get-MissingManifestSources -Root $repoRoot -Entries $entries)
if ($missingSources.Count -gt 0) {
    Write-Fail -TestName $testSource -Reasons @($missingSources | ForEach-Object { "manifest source missing: $_" })
}
Write-Pass -TestName $testSource

$unregisteredLibs = @(Get-UnregisteredLibDependencies -Root $repoRoot -Entries $entries)
if ($unregisteredLibs.Count -gt 0) {
    Write-Fail -TestName $testLib -Reasons @($unregisteredLibs | ForEach-Object { "dot-sourced _lib script not registered in runtime-manifest.json: $_" })
}
Write-Pass -TestName $testLib

$fixtureBase = Join-Path ([System.IO.Path]::GetTempPath()) ('runtime-manifest-integrity-' + [guid]::NewGuid().ToString('N'))
try {
    $bogusSource = 'scripts/runtime/Bogus-Missing-Source.ps1'
    $bogusEntries = @([pscustomobject]@{ source = $bogusSource; class = 'runtime' })
    $detectedMissing = @(Get-MissingManifestSources -Root $repoRoot -Entries $bogusEntries)
    if ($detectedMissing -notcontains $bogusSource) {
        Write-Fail -TestName $testSourceMissing -Reasons @("bogus manifest source was not detected: $bogusSource")
    }
    Write-Pass -TestName $testSourceMissing

    $fixtureRuntime = Join-Path $fixtureBase 'scripts/runtime/Probe.ps1'
    $fixtureLib = Join-Path $fixtureBase 'scripts/_lib/Probe-Lib.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $fixtureRuntime) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $fixtureLib) -Force | Out-Null
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($fixtureLib, "# fixture lib`n", $utf8NoBom)
    [System.IO.File]::WriteAllText($fixtureRuntime, '. (Join-Path $PSScriptRoot ''..\_lib\Probe-Lib.ps1'')' + "`n", $utf8NoBom)

    $runtimeOnly = @([pscustomobject]@{ source = 'scripts/runtime/Probe.ps1'; class = 'runtime' })
    $libUnregistered = @(Get-UnregisteredLibDependencies -Root $fixtureBase -Entries $runtimeOnly)
    if (@($libUnregistered | Where-Object { $_ -like 'scripts/_lib/Probe-Lib.ps1*' }).Count -eq 0) {
        Write-Fail -TestName $testLibUnregistered -Reasons @('dot-sourced lib missing from the in-memory manifest was not detected')
    }
    $withLib = @($runtimeOnly + [pscustomobject]@{ source = 'scripts/_lib/Probe-Lib.ps1'; class = 'support' })
    $libRegistered = @(Get-UnregisteredLibDependencies -Root $fixtureBase -Entries $withLib)
    if ($libRegistered.Count -ne 0) {
        Write-Fail -TestName $testLibUnregistered -Reasons @("registered lib was reported: $($libRegistered -join '; ')")
    }
    Write-Pass -TestName $testLibUnregistered
}
finally {
    if (Test-Path -LiteralPath $fixtureBase) {
        Remove-Item -LiteralPath $fixtureBase -Recurse -Force
    }
}

Write-Host 'Assert-RuntimeManifestIntegrity: ALL PASS'
exit 0
