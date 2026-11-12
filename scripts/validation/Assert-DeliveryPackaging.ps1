#Requires -Version 7.0
<#
.SYNOPSIS
  Static packaging contract for the integrated-delivery skills and runtime scripts.

.DESCRIPTION
  Read-only. Checks that:
    (a) each integrated-delivery skill directory has a SKILL.md;
    (b) every scripts/(runtime|ledger|session|_lib)/<name>.ps1 referenced by the integrated-delivery
        skill docs exists on disk and has a runtime-manifest.json entry (class runtime or support);
    (c) every runtime-manifest.json source file exists;
    (d) every _lib script dot-sourced by a runtime-class manifest script, transitively, has its own entry;
    (e) core/skills/_shared/integrated-delivery/STARTUP.md exists and names Invoke-StartupPreflight;
    (f) docs/INSTALL.md contains the 'Integrated delivery requirements' section.
  A self-test builds fixtures under the system temp directory, asserts the detections, and removes them.
  A failing assertion throws (exit 1).

.PARAMETER Root
  Repository root. Defaults to the repository root derived from this script location.
#>
[CmdletBinding()]
param(
    [string] $Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:passed = 0
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$skillNames = @(
    'integrated-delivery',
    'integrated-delivery-refine',
    'integrated-delivery-plan',
    'integrated-delivery-implement',
    'integrated-delivery-review'
)
$scriptReferencePattern = 'scripts/(?:runtime|ledger|session|_lib)/[A-Za-z0-9_.-]+\.ps1'
$dotSourcePattern = '^\s*\.\s+\S'

function Assert-Packaging {
    param(
        [Parameter(Mandatory = $true)][bool] $Condition,
        [Parameter(Mandatory = $true)][string] $Message
    )
    if (-not $Condition) {
        throw ("FAIL: {0}" -f $Message)
    }
    $script:passed++
}

function Assert-Throws {
    param(
        [Parameter(Mandatory = $true)][scriptblock] $Action,
        [Parameter(Mandatory = $true)][string] $Expected,
        [Parameter(Mandatory = $true)][string] $Name
    )
    $thrown = $null
    try {
        & $Action
    }
    catch {
        $thrown = [string]$_.Exception.Message
    }
    if ($null -eq $thrown) {
        throw ("FAIL: {0}: detection did not fail" -f $Name)
    }
    if (-not $thrown.Contains($Expected)) {
        throw ("FAIL: {0}: expected message containing '{1}', got '{2}'" -f $Name, $Expected, $thrown)
    }
    $script:passed++
}

function Read-PackagingManifest {
    param([Parameter(Mandatory = $true)][string] $Root)
    $path = Join-Path $Root 'scripts/runtime/runtime-manifest.json'
    Assert-Packaging -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message ("runtime manifest missing: {0}" -f $path)
    $manifest = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    return @($manifest.files)
}

function Get-SkillDocumentFiles {
    param([Parameter(Mandatory = $true)][string] $Root)
    $skillsRoot = Join-Path $Root 'core/skills'
    $directories = @(Get-ChildItem -LiteralPath $skillsRoot -Directory -Filter 'integrated-delivery*' | ForEach-Object { $_.FullName })
    $directories += (Join-Path $skillsRoot '_shared/integrated-delivery')
    $files = @()
    foreach ($directory in $directories) {
        if (Test-Path -LiteralPath $directory -PathType Container) {
            $files += @(Get-ChildItem -LiteralPath $directory -Recurse -File)
        }
    }
    return $files
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
    return $names
}

function Test-SkillEntryPoints {
    param([Parameter(Mandatory = $true)][string] $Root)
    foreach ($skill in $skillNames) {
        $relative = "core/skills/$skill/SKILL.md"
        Assert-Packaging -Condition (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf) -Message ("missing skill entry point {0}" -f $relative)
    }
}

function Test-ScriptReferences {
    param([Parameter(Mandatory = $true)][string] $Root)
    $entries = @(Read-PackagingManifest -Root $Root)
    $references = @{}
    foreach ($file in @(Get-SkillDocumentFiles -Root $Root)) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($match in [regex]::Matches($text, $scriptReferencePattern)) {
            if (-not $references.ContainsKey($match.Value)) {
                $references[$match.Value] = $file.FullName
            }
        }
    }
    foreach ($reference in @($references.Keys | Sort-Object)) {
        Assert-Packaging -Condition (Test-Path -LiteralPath (Join-Path $Root $reference) -PathType Leaf) -Message ("referenced script missing on disk: {0} (referenced in {1})" -f $reference, $references[$reference])
        $registered = @($entries | Where-Object { ([string]$_.source) -ceq $reference -and ([string]$_.class) -in @('runtime', 'support') })
        Assert-Packaging -Condition ($registered.Count -gt 0) -Message ("referenced script not registered in runtime-manifest.json: {0} (referenced in {1})" -f $reference, $references[$reference])
    }
}

function Test-ManifestSourcesExist {
    param([Parameter(Mandatory = $true)][string] $Root)
    $entries = @(Read-PackagingManifest -Root $Root)
    Assert-Packaging -Condition ($entries.Count -gt 0) -Message 'runtime-manifest.json lists no files'
    foreach ($entry in $entries) {
        $source = [string]$entry.source
        Assert-Packaging -Condition (Test-Path -LiteralPath (Join-Path $Root $source) -PathType Leaf) -Message ("manifest source missing: {0}" -f $source)
    }
}

function Test-LibDependencies {
    param([Parameter(Mandatory = $true)][string] $Root)
    $entries = @(Read-PackagingManifest -Root $Root)
    $registered = @($entries | ForEach-Object { [string]$_.source })
    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($entry in @($entries | Where-Object { ([string]$_.class) -eq 'runtime' })) {
        $queue.Enqueue([string]$entry.source)
    }
    $seen = @{}
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
            Assert-Packaging -Condition ($registered -ccontains $libSource) -Message ("dot-sourced _lib script not registered in runtime-manifest.json: {0} (required by {1})" -f $libSource, $source)
            $queue.Enqueue($libSource)
        }
    }
}

function Test-StartupContract {
    param([Parameter(Mandatory = $true)][string] $Root)
    $path = Join-Path $Root 'core/skills/_shared/integrated-delivery/STARTUP.md'
    Assert-Packaging -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message 'STARTUP.md is missing'
    $text = [System.IO.File]::ReadAllText($path)
    Assert-Packaging -Condition ($text.Contains('Invoke-StartupPreflight')) -Message 'STARTUP.md does not mention Invoke-StartupPreflight'
}

function Test-InstallRequirements {
    param([Parameter(Mandatory = $true)][string] $Root)
    $path = Join-Path $Root 'docs/INSTALL.md'
    Assert-Packaging -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message 'docs/INSTALL.md is missing'
    $text = [System.IO.File]::ReadAllText($path)
    Assert-Packaging -Condition ($text.Contains('Integrated delivery requirements')) -Message 'docs/INSTALL.md lacks the Integrated delivery requirements section'
}

function Write-FixtureFile {
    param([string] $Root, [string] $Relative, [string] $Content)
    $path = Join-Path $Root $Relative
    $directory = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($path, $Content, $utf8NoBom)
}

function New-FixtureEntry {
    param([string] $Source, [string] $Class)
    return [pscustomobject]@{
        source      = $Source
        destination = ($Source -replace '^scripts/', '')
        class       = $Class
        caller      = 'fixture'
    }
}

function Write-FixtureManifest {
    param([string] $Root, [object[]] $Entries)
    $manifest = [ordered]@{
        schemaVersion   = 1
        destinationRoot = 'scripts'
        files           = @($Entries)
    }
    Write-FixtureFile -Root $Root -Relative 'scripts/runtime/runtime-manifest.json' -Content (ConvertTo-Json -InputObject $manifest -Depth 6)
}

function New-FixtureBase {
    param([string] $Root)
    $dotSourceHelper = '. (Join-Path $PSScriptRoot ''..\_lib\Helper.ps1'')'
    Write-FixtureFile -Root $Root -Relative 'scripts/runtime/Registered.ps1' -Content ($dotSourceHelper + "`n")
    Write-FixtureFile -Root $Root -Relative 'scripts/_lib/Helper.ps1' -Content "# fixture helper`n"
    Write-FixtureManifest -Root $Root -Entries @(
        (New-FixtureEntry -Source 'scripts/runtime/Registered.ps1' -Class 'runtime'),
        (New-FixtureEntry -Source 'scripts/_lib/Helper.ps1' -Class 'support')
    )
    Write-FixtureFile -Root $Root -Relative 'core/skills/integrated-delivery/SKILL.md' -Content "Run {{TOOLKIT_ROOT}}/scripts/runtime/Registered.ps1 and {{TOOLKIT_ROOT}}/scripts/_lib/Helper.ps1.`n"
}

function Invoke-SelfTest {
    param([Parameter(Mandatory = $true)][string] $FixtureBase)

    $positive = Join-Path $FixtureBase 'positive'
    New-FixtureBase -Root $positive
    Test-ScriptReferences -Root $positive
    Test-ManifestSourcesExist -Root $positive
    Test-LibDependencies -Root $positive
    $script:passed += 3

    $unregisteredRef = Join-Path $FixtureBase 'unregistered-reference'
    New-FixtureBase -Root $unregisteredRef
    Write-FixtureFile -Root $unregisteredRef -Relative 'scripts/runtime/Unregistered.ps1' -Content "# fixture`n"
    Write-FixtureFile -Root $unregisteredRef -Relative 'core/skills/integrated-delivery/SKILL.md' -Content "Run scripts/runtime/Unregistered.ps1 -Action write.`n"
    Assert-Throws -Name 'Should_Fail_When_SkillReferencesUnregisteredScript' -Expected 'Unregistered.ps1' -Action {
        Test-ScriptReferences -Root $unregisteredRef
    }

    $missingOnDisk = Join-Path $FixtureBase 'missing-on-disk'
    New-FixtureBase -Root $missingOnDisk
    Write-FixtureManifest -Root $missingOnDisk -Entries @(
        (New-FixtureEntry -Source 'scripts/runtime/Registered.ps1' -Class 'runtime'),
        (New-FixtureEntry -Source 'scripts/_lib/Helper.ps1' -Class 'support'),
        (New-FixtureEntry -Source 'scripts/runtime/Ghost.ps1' -Class 'runtime')
    )
    Write-FixtureFile -Root $missingOnDisk -Relative 'core/skills/integrated-delivery/SKILL.md' -Content "Run scripts/runtime/Ghost.ps1.`n"
    Assert-Throws -Name 'Should_Fail_When_ReferencedScriptMissingOnDisk' -Expected 'Ghost.ps1' -Action {
        Test-ScriptReferences -Root $missingOnDisk
    }

    $missingSource = Join-Path $FixtureBase 'missing-source'
    New-FixtureBase -Root $missingSource
    Write-FixtureManifest -Root $missingSource -Entries @(
        (New-FixtureEntry -Source 'scripts/runtime/Registered.ps1' -Class 'runtime'),
        (New-FixtureEntry -Source 'scripts/_lib/Helper.ps1' -Class 'support'),
        (New-FixtureEntry -Source 'scripts/runtime/Absent.ps1' -Class 'runtime')
    )
    Assert-Throws -Name 'Should_Fail_When_ManifestSourceMissing' -Expected 'Absent.ps1' -Action {
        Test-ManifestSourcesExist -Root $missingSource
    }

    $unregisteredLib = Join-Path $FixtureBase 'unregistered-lib'
    New-FixtureBase -Root $unregisteredLib
    Write-FixtureFile -Root $unregisteredLib -Relative 'scripts/_lib/Hidden.ps1' -Content "# fixture`n"
    Write-FixtureFile -Root $unregisteredLib -Relative 'scripts/runtime/Registered.ps1' -Content ('. (Join-Path $PSScriptRoot ''..\_lib\Hidden.ps1'')' + "`n")
    Assert-Throws -Name 'Should_Fail_When_DotSourcedLibUnregistered' -Expected 'Hidden.ps1' -Action {
        Test-LibDependencies -Root $unregisteredLib
    }

    $transitiveLib = Join-Path $FixtureBase 'transitive-lib'
    New-FixtureBase -Root $transitiveLib
    Write-FixtureFile -Root $transitiveLib -Relative 'scripts/_lib/Deep.ps1' -Content "# fixture`n"
    Write-FixtureFile -Root $transitiveLib -Relative 'scripts/_lib/Helper.ps1' -Content ('. (Join-Path $PSScriptRoot ''Deep.ps1'')' + "`n")
    Assert-Throws -Name 'Should_Fail_When_TransitiveLibUnregistered' -Expected 'Deep.ps1' -Action {
        Test-LibDependencies -Root $transitiveLib
    }
}

$fixtureBase = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-packaging-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureBase -Force | Out-Null
try {
    Invoke-SelfTest -FixtureBase $fixtureBase
}
finally {
    Remove-Item -LiteralPath $fixtureBase -Recurse -Force -ErrorAction SilentlyContinue
}

$repoRoot = (Resolve-Path -LiteralPath $Root).Path
Test-SkillEntryPoints -Root $repoRoot
Test-ScriptReferences -Root $repoRoot
Test-ManifestSourcesExist -Root $repoRoot
Test-LibDependencies -Root $repoRoot
Test-StartupContract -Root $repoRoot
Test-InstallRequirements -Root $repoRoot

Write-Host ("PASS: {0} delivery packaging assertions." -f $script:passed)
exit 0
