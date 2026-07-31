#Requires -Version 5.1
<#
.SYNOPSIS
  Validates skill graph edges, forbid rules, and optional catalog parity.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$graphFileName = 'skill-graph.json'
$contractsRelativeDir = 'contracts'
$sharedFolderName = '_shared'
$skillFileName = 'SKILL.md'
$catalogProps = @('readme', 'skillsMd', 'guidesReadme')

if (-not $RepoRoot) {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) '_lib\Get-ToolkitRepoRoot.ps1')
    $RepoRoot = Get-ToolkitRepoRoot -FromPath $PSScriptRoot
}

$graphPath = Join-Path $PSScriptRoot (Join-Path $contractsRelativeDir $graphFileName)
if (-not (Test-Path -LiteralPath $graphPath)) {
    Write-Host "Missing graph file: $graphPath" -ForegroundColor Red
    exit 1
}

$doc = Get-Content -LiteralPath $graphPath -Raw | ConvertFrom-Json
$skillsRoot = Join-Path $RepoRoot $doc.skillsRoot
$failures = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $skillsRoot)) {
    Write-Host "Missing skills root: $skillsRoot" -ForegroundColor Red
    exit 1
}

$skillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Where-Object { $_.Name -ne $sharedFolderName } | ForEach-Object { $_.Name })

foreach ($edge in $doc.edges) {
    if ($skillDirs -notcontains $edge.from) {
        $failures.Add("edge: missing from skill folder '$($edge.from)'")
    }
    if ($skillDirs -notcontains $edge.to) {
        $failures.Add("edge: missing to skill folder '$($edge.to)'")
    }
    $fromSkill = Join-Path (Join-Path $skillsRoot $edge.from) $skillFileName
    if (Test-Path -LiteralPath $fromSkill) {
        $text = Get-Content -LiteralPath $fromSkill -Raw
        if ($text -notmatch [regex]::Escape($edge.to)) {
            $failures.Add("edge $($edge.from)->$($edge.to) ($($edge.kind)): '$($edge.to)' not mentioned in $($edge.from)/$skillFileName")
        }
    }
}

foreach ($rule in $doc.forbids) {
    $path = Join-Path (Join-Path $skillsRoot $rule.skill) $rule.file
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("forbid $($rule.id): missing $path")
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -notmatch [regex]::Escape($rule.mustMatch)) {
        $failures.Add("forbid $($rule.id): missing section marker '$($rule.mustMatch)'")
        continue
    }
    $anyHit = $false
    foreach ($needle in $rule.mustAlsoMatchAny) {
        if ($text -match [regex]::Escape($needle)) { $anyHit = $true; break }
    }
    if (-not $anyHit) {
        $failures.Add("forbid $($rule.id): expected one of: $($rule.mustAlsoMatchAny -join ' | ')")
    }
}

if (($doc.PSObject.Properties.Name -contains 'catalogParity') -and ($null -ne $doc.catalogParity)) {
    $diskCount = $skillDirs.Count
    $parityNames = @($doc.catalogParity.PSObject.Properties | ForEach-Object { $_.Name })
    foreach ($prop in $catalogProps) {
        if ($parityNames -notcontains $prop) { continue }
        $rel = $doc.catalogParity.$prop
        if ([string]::IsNullOrWhiteSpace([string]$rel)) { continue }
        $path = Join-Path $RepoRoot $rel
        if (-not (Test-Path -LiteralPath $path)) {
            $failures.Add("catalogParity: missing $rel")
            continue
        }
        $text = Get-Content -LiteralPath $path -Raw
        foreach ($name in $skillDirs) {
            if ($prop -eq 'guidesReadme') {
                continue
            }
            if ($text -notmatch [regex]::Escape("``$name``") -and $text -notmatch [regex]::Escape($name)) {
                if ($prop -eq 'readme' -or $prop -eq 'skillsMd') {
                    $failures.Add("catalogParity ($rel): skill '$name' not listed")
                }
            }
        }
        if ($text -match '(?i)(\d+)\s+skills') {
            $claimed = [int]$Matches[1]
            if ($claimed -ne $diskCount) {
                $failures.Add("catalogParity ($rel): claims $claimed skills but disk has $diskCount")
            }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'Skill graph validation FAILED:' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Skill graph validation passed ($($skillDirs.Count) skills on disk)." -ForegroundColor Green
exit 0
