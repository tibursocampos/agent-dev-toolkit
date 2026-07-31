# Requires: PowerShell 5.1+
# Test: Should_ShowLayoutSections_When_ReadmeOpened
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$requiredPaths = @(
    'core',
    'adapters',
    'scripts',
    'docs',
    'docs/ARCHITECTURE.md',
    'docs/ADAPTERS.md',
    'README.md'
)

$missing = @()
foreach ($rel in $requiredPaths) {
    $full = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) {
        $missing += $rel
    }
}

$readme = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw
$requiredSections = @(
    'Repository layout',
    'core/',
    'adapters/',
    'scripts/',
    'docs/'
)

$missingSections = @()
foreach ($section in $requiredSections) {
    if ($readme -notlike "*$section*") {
        $missingSections += $section
    }
}

if ($missing.Count -gt 0 -or $missingSections.Count -gt 0) {
    if ($missing.Count -gt 0) {
        Write-Error ("Missing paths: {0}" -f ($missing -join ', '))
    }
    if ($missingSections.Count -gt 0) {
        Write-Error ("README missing sections/markers: {0}" -f ($missingSections -join ', '))
    }
    exit 1
}

Write-Host 'Should_ShowLayoutSections_When_ReadmeOpened: PASS'
exit 0
