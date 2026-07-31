#Requires -Version 5.1
<#
.SYNOPSIS
  Golden markers: each fixtures/<skill>/expected-markers.txt line must appear in SKILL.md or reference.md.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fixturesDirName = 'fixtures'
$skillsRootRelative = 'core/skills'
$skillFileName = 'SKILL.md'
$referenceFileName = 'reference.md'
$commentPrefix = '#'

$libDir = Join-Path (Split-Path -Parent $PSScriptRoot) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')

$markersFileName = $script:ToolkitConstant.SkillFixtureMarkersFileName
$installRootFixtureDirName = $script:ToolkitConstant.InstallRootFixtureDirectoryName

if (-not $RepoRoot) {
    $RepoRoot = Get-ToolkitRepoRoot -FromPath $PSScriptRoot
}

$fixturesRoot = Join-Path $PSScriptRoot $fixturesDirName
$skillsRoot = Join-Path $RepoRoot $skillsRootRelative
$failures = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $fixturesRoot)) {
    Write-Host 'No fixtures directory; skipping.' -ForegroundColor Yellow
    exit 0
}

Get-ChildItem -LiteralPath $fixturesRoot -Directory | ForEach-Object {
    $skill = $_.Name
    if ([string]::Equals($skill, $installRootFixtureDirName, [System.StringComparison]::OrdinalIgnoreCase)) {
        return
    }

    # Agent InstallRoot fixtures (opencode, claude, …) live beside skill golden fixtures.
    # Skip dirs that are not a core/skills/<id> package.
    $skillDir = Join-Path $skillsRoot $skill
    if (-not (Test-Path -LiteralPath $skillDir)) {
        return
    }

    $markersFile = Join-Path $_.FullName $markersFileName
    if (-not (Test-Path -LiteralPath $markersFile)) {
        $failures.Add("fixtures/${skill}: missing $markersFileName")
        return
    }

    $blob = ''
    foreach ($name in @($skillFileName, $referenceFileName)) {
        $p = Join-Path $skillDir $name
        if (Test-Path -LiteralPath $p) {
            $blob += "`n" + (Get-Content -LiteralPath $p -Raw)
        }
    }

    Get-Content -LiteralPath $markersFile | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith($commentPrefix)) { return }
        if ($blob -notmatch [regex]::Escape($line)) {
            $failures.Add("fixtures/${skill}: missing marker '$line'")
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'Skill fixtures validation FAILED:' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Skill fixtures validation passed.' -ForegroundColor Green
exit 0
