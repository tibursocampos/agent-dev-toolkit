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
$activationCorpusName = 'skill-activation-corpus.json'

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

$activationCorpusPath = Join-Path $PSScriptRoot (Join-Path $fixturesDirName $activationCorpusName)
if (Test-Path -LiteralPath $activationCorpusPath) {
    try {
        $corpus = Get-Content -LiteralPath $activationCorpusPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$corpus.schema -ne 'skill-activation-corpus/v1') { $failures.Add("${activationCorpusName}: unsupported or missing schema") }
        $cases = @($corpus.cases)
        if ($cases.Count -eq 0) { $failures.Add("${activationCorpusName}: cases must not be empty") }
        $ids = @{}
        $nearMissSkills = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($case in $cases) {
            $id = [string]$case.id
            if ([string]::IsNullOrWhiteSpace($id)) { $failures.Add("${activationCorpusName}: every case needs an id"); continue }
            if ($ids.ContainsKey($id)) { $failures.Add("${activationCorpusName}: duplicate id '$id'") } else { $ids[$id] = $true }
            if ([string]::IsNullOrWhiteSpace([string]$case.input)) { $failures.Add("${activationCorpusName}/${id}: input must not be empty") }
            if ([string]$case.kind -notin @('positive','negative','ambiguous')) { $failures.Add("${activationCorpusName}/${id}: invalid kind '$($case.kind)'") }
            if ($null -ne $case.expected_skill) { $expectedSkill = [string]$case.expected_skill } else { $expectedSkill = '' }
            if ($case.kind -eq 'positive') {
                if ([string]::IsNullOrWhiteSpace($expectedSkill) -or -not (Test-Path -LiteralPath (Join-Path $skillsRoot $expectedSkill) -PathType Container)) {
                    $failures.Add("${activationCorpusName}/${id}: positive expected_skill must map to core/skills/<id>")
                }
            } elseif (-not [string]::IsNullOrWhiteSpace($expectedSkill)) {
                $failures.Add("${activationCorpusName}/${id}: negative and ambiguous cases must not activate an expected skill")
            }
            if ($case.kind -eq 'ambiguous' -and [string]$case.expected_action -ne 'clarify-before-mutation') {
                $failures.Add("${activationCorpusName}/${id}: ambiguous case must require clarification before mutation")
            }
            if ($id -like 'near-miss-*') {
                $evaluatedSkill = [string]$case.evaluated_skill
                if ($case.kind -ne 'negative' -or [string]$case.expected_action -ne 'no-skill' -or
                    [string]::IsNullOrWhiteSpace([string]$case.signal) -or
                    [string]::IsNullOrWhiteSpace($evaluatedSkill) -or
                    -not (Test-Path -LiteralPath (Join-Path $skillsRoot $evaluatedSkill) -PathType Container)) {
                    $failures.Add("${activationCorpusName}/${id}: near-miss must be a no-skill negative with a valid evaluated_skill and signal")
                } else { [void]$nearMissSkills.Add($evaluatedSkill) }
            }
        }
        if ($nearMissSkills.Count -lt 4) { $failures.Add("${activationCorpusName}: near-miss examples must cover at least four distinct evaluated skills") }
    } catch {
        $failures.Add("${activationCorpusName}: invalid JSON or corpus structure ($($_.Exception.Message))")
    }
} else {
    $failures.Add("${activationCorpusName}: required activation corpus is missing")
}

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
