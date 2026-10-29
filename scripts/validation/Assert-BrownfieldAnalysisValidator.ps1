#Requires -Version 5.1
# Covers the brownfield analysis validator and the O2 preflight gate built on it:
# valid analyses are accepted/ALLOWed, semantically broken ones are rejected/BLOCKed.
$ErrorActionPreference = 'Stop'
$validator = Join-Path $PSScriptRoot 'validate-brownfield-analysis.ps1'
$preflight = Join-Path $PSScriptRoot 'Invoke-O2BrownfieldPreflight.ps1'
$fixtures = Join-Path $PSScriptRoot 'fixtures\brownfield'

function Test-Validator([string] $Path) {
    $null = & $validator -Path $Path 2>&1
    return ($LASTEXITCODE -eq 0)
}
function Get-GateVerdict([string] $Path) {
    $out = & $preflight -AnalysisPath $Path 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
    if ($code -eq 0 -and $out -match '(?m)^o2-brownfield-preflight: ALLOW\b') { return 'ALLOW' }
    if ($code -ne 0 -and $out -match '(?m)^o2-brownfield-preflight: BLOCK\b') { return 'BLOCK' }
    return "UNEXPECTED(exit=$code)"
}

foreach ($name in @('valid-en.md', 'valid-mixed.md')) {
    $p = Join-Path $fixtures $name
    if (-not (Test-Validator $p)) { throw "$name must pass the validator" }
    if ((Get-GateVerdict $p) -ne 'ALLOW') { throw "$name must be ALLOWed by the O2 preflight" }
}
foreach ($name in @('invalid-missing-evidence.md', 'invalid-classification-conflict.md')) {
    $p = Join-Path $fixtures $name
    if (Test-Validator $p) { throw "$name must fail the validator" }
    if ((Get-GateVerdict $p) -ne 'BLOCK') { throw "$name must be BLOCKed by the O2 preflight" }
}
if ((Get-GateVerdict (Join-Path $fixtures 'missing-analysis.md')) -ne 'BLOCK') { throw 'a missing analysis file must be BLOCKed' }

Write-Host 'BrownfieldAnalysisValidator: PASS (valid accepted + ALLOW; invalid rejected + BLOCK; missing analysis BLOCK)'
# Negative cases make child validators return nonzero; clear the stale native status after every assertion passed.
$global:LASTEXITCODE = 0
