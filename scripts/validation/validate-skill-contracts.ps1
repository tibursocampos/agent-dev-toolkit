#Requires -Version 5.1
<#
.SYNOPSIS
  Validates skill contract markers declared in skill-contracts.json.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$contractsFileName = 'skill-contracts.json'
$contractsRelativeDir = 'contracts'
$fileExtensionsPattern = '\.(md|mdc|json|ps1|yml|yaml|txt)$'

if (-not $RepoRoot) {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) '_lib\Get-ToolkitRepoRoot.ps1')
    $RepoRoot = Get-ToolkitRepoRoot -FromPath $PSScriptRoot
}

$contractsPath = Join-Path $PSScriptRoot (Join-Path $contractsRelativeDir $contractsFileName)
if (-not (Test-Path -LiteralPath $contractsPath)) {
    Write-Host "Missing contracts file: $contractsPath" -ForegroundColor Red
    exit 1
}

$doc = Get-Content -LiteralPath $contractsPath -Raw | ConvertFrom-Json
$skillsRoot = Join-Path $RepoRoot $doc.skillsRoot
$failures = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $skillsRoot)) {
    Write-Host "Missing skills root: $skillsRoot" -ForegroundColor Red
    exit 1
}

if ($doc.PSObject.Properties.Name -contains 'mustNotExistSkills' -and $doc.mustNotExistSkills) {
    foreach ($entry in @($doc.mustNotExistSkills)) {
        $forbiddenPath = Join-Path $skillsRoot $entry.skill
        if (Test-Path -LiteralPath $forbiddenPath) {
            $failures.Add("$($entry.id): forbidden skill folder exists at $forbiddenPath")
        }
        else {
            Write-Host ("{0}: PASS (no {1}/)" -f $entry.id, $entry.skill)
        }
    }
}

if ($doc.PSObject.Properties.Name -contains 'mustExistPaths' -and $doc.mustExistPaths) {
    foreach ($entry in @($doc.mustExistPaths)) {
        $requiredPath = Join-Path $RepoRoot $entry.path
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            $failures.Add("$($entry.id): required path missing at $requiredPath")
        }
        else {
            Write-Host ("{0}: PASS (exists {1})" -f $entry.id, $entry.path)
        }
    }
}

foreach ($c in $doc.contracts) {
    foreach ($fileName in $c.files) {
        $path = Join-Path (Join-Path $skillsRoot $c.skill) $fileName
        if (-not (Test-Path -LiteralPath $path)) {
            $failures.Add("$($c.id): missing file $path")
            continue
        }
        $text = Get-Content -LiteralPath $path -Raw
        if ($c.PSObject.Properties.Name -contains 'mustContain' -and $c.mustContain) {
            foreach ($needle in $c.mustContain) {
                if ($text -notmatch [regex]::Escape($needle)) {
                    $failures.Add("$($c.id): $($c.skill)/$fileName missing required marker '$needle'")
                }
            }
        }
        if ($c.PSObject.Properties.Name -contains 'mustContainAny' -and $c.mustContainAny) {
            $anyHit = $false
            foreach ($needle in $c.mustContainAny) {
                if ($text -match [regex]::Escape($needle)) { $anyHit = $true; break }
            }
            if (-not $anyHit) {
                $failures.Add("$($c.id): $($c.skill)/$fileName missing any of: $($c.mustContainAny -join ' | ')")
            }
        }
        if ($c.PSObject.Properties.Name -contains 'mustNotContain' -and $c.mustNotContain) {
            foreach ($needle in $c.mustNotContain) {
                if ($text.Contains($needle)) {
                    $failures.Add("$($c.id): $($c.skill)/$fileName contains forbidden '$needle'")
                }
            }
        }
    }
}

if ($doc.PSObject.Properties.Name -contains 'mustNotContain' -and $doc.mustNotContain) {
    # Scan all skill files under skillsRoot (incl. _shared) for IDE home-path needles.
    $files = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -File | Where-Object {
            $_.Extension -match $fileExtensionsPattern
        })
    foreach ($file in $files) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($needle in @($doc.mustNotContain)) {
            if ($text.Contains($needle)) {
                $rel = $file.FullName.Substring($skillsRoot.Length).TrimStart('\', '/')
                $failures.Add("global-mustNotContain: $rel contains forbidden '$needle'")
            }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'Skill contracts validation FAILED:' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Skill contracts validation passed.' -ForegroundColor Green
exit 0
