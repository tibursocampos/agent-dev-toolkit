# Requires: PowerShell 5.1+
# Tests the S4 contract for local instructions and observable quality/security evidence.
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$paths = @{
    Precommit = Join-Path $repoRoot 'core\skills\_shared\developer-common\step-3.5-precommit-validation.md'
    Review    = Join-Path $repoRoot 'core\skills\code-review\references\verification.md'
    Security  = Join-Path $repoRoot 'core\agents\security.md'
}

foreach ($entry in $paths.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $entry.Value)) {
        throw "Missing S4 contract file: $($entry.Value)"
    }
}

$precommit = Get-Content -LiteralPath $paths.Precommit -Raw
$review = Get-Content -LiteralPath $paths.Review -Raw
$security = Get-Content -LiteralPath $paths.Security -Raw

foreach ($text in @($precommit, $review)) {
    foreach ($required in @('AGENTS\.md', 'closest\s+applicable', 'higher-authority', 'sibling')) {
        if ($text -notmatch $required) {
            throw "Local-instruction precedence contract is missing '$required'."
        }
    }
}

foreach ($text in @($precommit, $review, $security)) {
    foreach ($required in @('PASS', 'FOUND', 'SKIPPED', 'Scope', 'Evidence', 'Severity', 'new', 'pre-existing', 'unavailable')) {
        if ($text -notmatch [regex]::Escape($required)) {
            throw "Observable finding contract is missing '$required'."
        }
    }

    if ($text -notmatch 'SKIPPED.{0,180}PASS|PASS.{0,180}SKIPPED') {
        throw 'Unavailable tooling must be explicitly forbidden from reporting PASS.'
    }
}

foreach ($forbiddenAutoRemediation in @('--fix', 'package update', 'suppress', 'cleanup')) {
    if ($precommit -notmatch [regex]::Escape($forbiddenAutoRemediation) -and
        $review -notmatch [regex]::Escape($forbiddenAutoRemediation) -and
        $security -notmatch [regex]::Escape($forbiddenAutoRemediation)) {
        throw "Automatic-remediation prohibition is missing '$forbiddenAutoRemediation'."
    }
}

Write-Host 'Assert-LocalInstructionEvidenceContract: ALL PASS'
exit 0
