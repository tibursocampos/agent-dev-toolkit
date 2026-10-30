#Requires -Version 5.1
<#
.SYNOPSIS
  Ensures exhaustive human and agent skill catalogs match the invocable skill folders.
.DESCRIPTION
  Compares core/skills/*/SKILL.md ids against CATALOG.md, docs/SKILLS.md, and both
  docs-site first-use catalogs. README's skills section is an explicitly partial preview.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$skillRoot = Join-Path $repoRoot 'core/skills'

function Get-CatalogIds {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [switch] $AgentCatalog,
        [switch] $HumanCatalog
    )

    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    if ($AgentCatalog -or $HumanCatalog) {
        $content = [System.IO.File]::ReadAllText($Path)
        $startHeading = if ($AgentCatalog) { '## Classic SDD' } else { '## Orchestrated Delivery' }
        $endHeading = if ($AgentCatalog) { '## Activation contract' } else { '## Operator expectations' }
        $start = $content.IndexOf($startHeading, [System.StringComparison]::Ordinal)
        $end = $content.IndexOf($endHeading, [System.StringComparison]::Ordinal)
        if ($start -lt 0 -or $end -le $start) {
            throw "Could not find the skill-list boundaries in '$Path'."
        }
        $lines = @($content.Substring($start, $end - $start) -split "`r?`n")
    }

    $ids = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        if ($line -match '^\|\s*`(?<id>[a-z0-9][a-z0-9-]*)`\s*\|') {
            $ids.Add($Matches.id)
        }
    }
    return @($ids.ToArray())
}

function Compare-Catalog {
    param(
        [Parameter(Mandatory = $true)][string] $Label,
        [Parameter(Mandatory = $true)][string[]] $Expected,
        [Parameter(Mandatory = $true)][string[]] $Actual
    )

    $duplicates = @($Actual | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
    $missing = @($Expected | Where-Object { $_ -notin $Actual })
    $extra = @($Actual | Where-Object { $_ -notin $Expected })
    if ($duplicates.Count -gt 0 -or $missing.Count -gt 0 -or $extra.Count -gt 0) {
        $details = @(
            if ($duplicates.Count -gt 0) { 'duplicate=' + ($duplicates -join ',') }
            if ($missing.Count -gt 0) { 'missing=' + ($missing -join ',') }
            if ($extra.Count -gt 0) { 'extra=' + ($extra -join ',') }
        ) -join '; '
        throw ("{0} differs from core/skills: {1}" -f $Label, $details)
    }
    Write-Host ("PASS {0}: {1} skill ids" -f $Label, $Expected.Count)
}

$sourceIds = @(
    Get-ChildItem -LiteralPath $skillRoot -Directory |
        Where-Object { $_.Name -ne '_shared' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')) } |
        ForEach-Object Name |
        Sort-Object
)
if ($sourceIds.Count -eq 0) {
    throw "No invocable skill directories found under '$skillRoot'."
}

$catalogs = @(
    @{ Label = 'agent catalog'; Path = (Join-Path $skillRoot '_shared/skills-catalog/CATALOG.md'); AgentCatalog = $true },
    @{ Label = 'docs/SKILLS.md'; Path = (Join-Path $repoRoot 'docs/SKILLS.md'); HumanCatalog = $true },
    @{ Label = 'docs-site/first-use.md'; Path = (Join-Path $repoRoot 'docs-site/first-use.md') },
    @{ Label = 'docs-site/first-use.pt.md'; Path = (Join-Path $repoRoot 'docs-site/first-use.pt.md') }
)

foreach ($catalog in $catalogs) {
    if (-not (Test-Path -LiteralPath $catalog.Path -PathType Leaf)) {
        throw "Required catalog not found: $($catalog.Path)"
    }
    $isAgentCatalog = $catalog.ContainsKey('AgentCatalog') -and [bool]$catalog.AgentCatalog
    $isHumanCatalog = $catalog.ContainsKey('HumanCatalog') -and [bool]$catalog.HumanCatalog
    $actualIds = Get-CatalogIds -Path $catalog.Path -AgentCatalog:$isAgentCatalog -HumanCatalog:$isHumanCatalog
    Compare-Catalog -Label $catalog.Label -Expected $sourceIds -Actual $actualIds
}
