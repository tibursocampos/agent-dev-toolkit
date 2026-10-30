#Requires -Version 5.1
# Tests:
#   Should_NotReferenceMdcOrCorePaths_When_ClaudePublished
#
# Published Claude skills, agents, rules, and CLAUDE.md must not point at Cursor `.mdc` files or at
# toolkit source trees (`core/<dir>/`). Those paths do not exist in a live ~/.claude install.
#
# Speed: a full publish takes about 25 seconds (Invoke-AdapterCiSmoke covers that path). This check
# applies the same publish-time text helpers the publishers call (Convert-ClaudeMdcReferencesToMd and
# Convert-ClaudeRepoSourcePathReferences) to the core sources, so it reads the same text the publish
# writes without copying the tree. The rewrites per target match the adapter:
#   skills, agents -> .mdc rewrite + repo-source path rewrite
#   rules, CLAUDE.md -> .mdc rewrite only
#
# The allowlist names prose that describes the toolkit source layout on purpose. Each entry is the
# exact number of matching lines expected in that published file. Any change in that count fails
# until the entry is reviewed.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
. (Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1')

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }

$forbiddenPattern = '(?<![\w.-])core[/\\](skills|policy|router|agents|sdd|adapters|scripts)[/\\]|\.mdc\b'

$allowedProseHits = [ordered]@{
    'CLAUDE.md'                                                 = 1
    'skills/_shared/agents/LANGUAGE.md'                         = 1
    'skills/_shared/agents/ROSTER.md'                           = 1
    'skills/_shared/agents/SPAWN.md'                            = 2
    'skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md' = 1
    'skills/code-review/references/policy.md'                   = 2
    'skills/memory-bank-init/references/inventory-fallback.md'  = 1
}

$n = 'Should_NotReferenceMdcOrCorePaths_When_ClaudePublished'
$placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $repoRoot
$coreRoot = Join-Path $repoRoot 'core'

# Each entry: published relative path, core source file, and the rewrites the publisher applies.
$targets = New-Object System.Collections.Generic.List[object]
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $coreRoot 'skills') -Recurse -File | Where-Object { $_.Extension -in '.md', '.json', '.ps1' })) {
    $rel = $file.FullName.Substring((Join-Path $coreRoot 'skills').Length + 1)
    $targets.Add([PSCustomObject]@{ Published = ('skills/' + ($rel -replace '\\', '/')); Source = $file.FullName; Mdc = ($file.Extension -eq '.md'); SourcePaths = $true })
}
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $coreRoot 'agents') -File -Filter '*.md')) {
    $targets.Add([PSCustomObject]@{ Published = ('agents/' + $file.Name); Source = $file.FullName; Mdc = $true; SourcePaths = $true })
}
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $coreRoot 'policy') -File -Filter '*.md' | Where-Object { $script:ClaudeUnpublishedPolicyFileNames -notcontains $_.Name })) {
    $targets.Add([PSCustomObject]@{ Published = ('rules/' + $file.Name); Source = $file.FullName; Mdc = $true; SourcePaths = $false })
}
$routerSource = Join-Path (Join-Path $coreRoot 'router') 'AGENTS.md'
if (-not (Test-Path -LiteralPath $routerSource -PathType Leaf)) { Write-Fail $n 'core router source is missing' }
$targets.Add([PSCustomObject]@{ Published = 'CLAUDE.md'; Source = $routerSource; Mdc = $true; SourcePaths = $false })

if ($targets.Count -eq 0) { Write-Fail $n 'no published skills, agents, rules, or CLAUDE.md to scan' }

$hitsByFile = [ordered]@{}
foreach ($target in $targets) {
    $text = [System.IO.File]::ReadAllText($target.Source)
    if ($target.Mdc) { $text = Convert-ClaudeMdcReferencesToMd -Text $text }
    if ($target.SourcePaths) {
        $text = Convert-ClaudeRepoSourcePathReferences -Text $text -RepoRoot $repoRoot -PlaceholderMap $placeholderMap
    }
    $lines = $text -split '\r?\n'
    $count = 0
    $firstLine = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ([regex]::IsMatch($lines[$i], $forbiddenPattern)) {
            $count++
            if ($null -eq $firstLine) { $firstLine = ('{0}:{1}' -f $target.Published, ($i + 1)) }
        }
    }
    if ($count -gt 0) { $hitsByFile[$target.Published] = [PSCustomObject]@{ Count = $count; First = $firstLine } }
}

foreach ($relative in @($hitsByFile.Keys)) {
    $hit = $hitsByFile[$relative]
    if (-not $allowedProseHits.Contains($relative)) {
        Write-Fail $n ("unexpected .mdc or core/ reference at {0} ({1} line(s))" -f $hit.First, $hit.Count)
    }
    if ($hit.Count -ne [int]$allowedProseHits[$relative]) {
        Write-Fail $n ("{0}: expected {1} allowlisted line(s), found {2}; review the prose and update the allowlist" -f $relative, $allowedProseHits[$relative], $hit.Count)
    }
}
foreach ($relative in @($allowedProseHits.Keys)) {
    if (-not $hitsByFile.Contains($relative)) {
        Write-Fail $n ("allowlist entry has no matching lines; remove it: {0}" -f $relative)
    }
}
Write-Pass $n

Write-Host 'Assert-ClaudePublishedContent: ALL PASS'
exit 0
