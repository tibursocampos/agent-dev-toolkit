# Requires: PowerShell 5.1+
# Tests:
#   Should_ReferManifestJsonOnly_When_SddDocsScanned
#   Should_KeepSddContractsUnderCore_When_PortComplete
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$sddRoot = Join-Path $repoRoot 'core\sdd'
$docsRoot = Join-Path $repoRoot 'docs'
$manifestFileName = 'manifest.json'
$forbiddenManifestBrandPattern = 'manifest\s*v2|manifest\.v2'

$requiredContracts = @(
    'PIPELINE.md',
    'STORAGE.md',
    'SESSION.md',
    'MEMORY-BANK.md'
)

# --- Should_KeepSddContractsUnderCore_When_PortComplete ---

if (-not (Test-Path -LiteralPath $sddRoot)) {
    Write-Error 'core/sdd is missing'
    exit 1
}

$sddItem = Get-Item -LiteralPath $sddRoot
if ($sddItem.LinkType) {
    Write-Error ("core/sdd must be a real directory copy, not a {0}" -f $sddItem.LinkType)
    exit 1
}

foreach ($name in $requiredContracts) {
    $path = Join-Path $sddRoot $name
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Error ("Missing SDD contract under core/sdd: {0}" -f $name)
        exit 1
    }
    $item = Get-Item -LiteralPath $path
    if ($item.LinkType) {
        Write-Error ("{0} must be a real file copy, not a {1}" -f $name, $item.LinkType)
        exit 1
    }
    if ($item.Length -le 0) {
        Write-Error ("Empty SDD contract: {0}" -f $name)
        exit 1
    }
}

$readmePath = Join-Path $sddRoot 'README.md'
if (-not (Test-Path -LiteralPath $readmePath)) {
    Write-Error 'core/sdd/README.md is missing (constants / Get-SddRoot note)'
    exit 1
}
$readme = Get-Content -LiteralPath $readmePath -Raw
if ($readme -notmatch [regex]::Escape($manifestFileName)) {
    Write-Error ("core/sdd/README.md must declare public name {0}" -f $manifestFileName)
    exit 1
}
if ($readme -notmatch 'Get-SddRoot') {
    Write-Error 'core/sdd/README.md must mention Get-SddRoot for adapters'
    exit 1
}

Write-Host 'Should_KeepSddContractsUnderCore_When_PortComplete: PASS'

# --- Should_ReferManifestJsonOnly_When_SddDocsScanned ---

$scanRoots = @(
    (Join-Path $docsRoot 'ARCHITECTURE.md'),
    (Join-Path $docsRoot 'ADAPTERS.md'),
    $readmePath
)

$missingManifestRef = @()
$brandHits = @()

foreach ($path in $scanRoots) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Error ("Expected doc missing: {0}" -f $path)
        exit 1
    }
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -notmatch [regex]::Escape($manifestFileName)) {
        $missingManifestRef += $path
    }
    $matches = [regex]::Matches($text, $forbiddenManifestBrandPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $brandHits += ("{0}: {1}" -f $path, $m.Value)
    }
}

if ($missingManifestRef.Count -gt 0) {
    Write-Error ("Docs must refer to {0}: {1}" -f $manifestFileName, ($missingManifestRef -join ', '))
    exit 1
}

if ($brandHits.Count -gt 0) {
    Write-Error ("Forbidden manifest v2 branding found: {0}" -f ($brandHits -join '; '))
    exit 1
}

# Also scan core/sdd contracts for public-file branding "manifest v2" (schema_version numeric OK)
$contractFiles = @(Get-ChildItem -LiteralPath $sddRoot -File -Filter '*.md')
foreach ($file in $contractFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $matches = [regex]::Matches($text, $forbiddenManifestBrandPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $brandHits += ("{0}: {1}" -f $file.FullName, $m.Value)
    }
}

if ($brandHits.Count -gt 0) {
    Write-Error ("Forbidden manifest v2 branding in core/sdd: {0}" -f ($brandHits -join '; '))
    exit 1
}

Write-Host 'Should_ReferManifestJsonOnly_When_SddDocsScanned: PASS'
exit 0
