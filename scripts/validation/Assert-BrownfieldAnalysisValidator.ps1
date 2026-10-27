$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$validator = Join-Path $PSScriptRoot 'validate-brownfield-analysis.ps1'
$fixtures = Join-Path $PSScriptRoot 'fixtures\brownfield'

function Assert-Result([string]$Name, [string]$Path, [bool]$ExpectedPass) {
    & $validator -Path $Path
    $passed = ($LASTEXITCODE -eq 0)
    if ($passed -ne $ExpectedPass) {
        throw ("{0}: expected {1}, exit={2}" -f $Name, $(if ($ExpectedPass) { 'PASS' } else { 'FAIL' }), $LASTEXITCODE)
    }
}

foreach ($name in @('valid-en.md', 'valid-pt.md', 'valid-mixed.md', 'valid-equal-duplicate-columns.md')) {
    Assert-Result $name (Join-Path $fixtures $name) $true
}
foreach ($name in @('invalid-execution-status.md', 'invalid-missing-evidence.md', 'invalid-classification-conflict.md', 'invalid-conflicting-evidence-columns.md', 'invalid-conflicting-limitation-columns.md')) {
    Assert-Result $name (Join-Path $fixtures $name) $false
}

Write-Host 'BrownfieldAnalysisValidator: PASS (PT/EN/mixed and equal aliases accepted; invalid classifications, missing evidence, and conflicting semantic columns rejected)'
# The invalid fixtures above intentionally make the child validator return
# nonzero. Clear that stale native-process status only after every assertion passed.
$global:LASTEXITCODE = 0
