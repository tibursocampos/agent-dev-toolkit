#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$preflight = Join-Path $PSScriptRoot 'Invoke-O2BrownfieldPreflight.ps1'
$fixtures = Join-Path $PSScriptRoot 'fixtures\brownfield'

function Assert-GateResult([string]$Name, [string]$Path, [bool]$ExpectedAllow) {
    $output = & $preflight -AnalysisPath $Path 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) { $exitCode = 0 }
    $hasAllow = $output -match '(?m)^o2-brownfield-preflight: ALLOW\b'
    $hasBlock = $output -match '(?m)^o2-brownfield-preflight: BLOCK\b'
    if ($ExpectedAllow -and ([int]$exitCode -ne 0 -or -not $hasAllow -or $hasBlock)) {
        throw ("{0}: expected O2 ALLOW, exit={1}; output={2}" -f $Name, $exitCode, $output.Trim())
    }
    if (-not $ExpectedAllow -and ([int]$exitCode -eq 0 -or -not $hasBlock -or $hasAllow)) {
        throw ("{0}: expected O2 BLOCK, exit={1}; output={2}" -f $Name, $exitCode, $output.Trim())
    }
}

foreach ($name in @('valid-en.md', 'valid-pt.md', 'valid-mixed.md', 'valid-equal-duplicate-columns.md')) {
    Assert-GateResult $name (Join-Path $fixtures $name) $true
}
foreach ($name in @('invalid-execution-status.md', 'invalid-missing-evidence.md', 'invalid-classification-conflict.md', 'invalid-conflicting-evidence-columns.md', 'invalid-conflicting-limitation-columns.md')) {
    Assert-GateResult $name (Join-Path $fixtures $name) $false
}
Assert-GateResult 'missing analysis path' (Join-Path $fixtures 'missing-analysis.md') $false

$preconditions = [System.IO.File]::ReadAllText((Join-Path $repoRoot 'core/skills/orchestrate-deliver/references/preconditions.md'))
if ($preconditions -notmatch 'Invoke-O2BrownfieldPreflight\.ps1\s+-AnalysisPath') {
    throw 'O2 preconditions must invoke the deterministic brownfield preflight command.'
}

Write-Host 'O2BrownfieldPreflight: PASS (O2 gate ALLOW for PT/EN/mixed/equal-alias fixtures; BLOCK for semantic failures, conflicting duplicate columns, and missing analysis)' -ForegroundColor Green
