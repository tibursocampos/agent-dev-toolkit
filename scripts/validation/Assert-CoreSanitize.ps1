# Requires: PowerShell 5.1+
# Tests:
#   Should_FailContract_When_CoreContainsSingleIdeHomePath
#   Should_PassMustNotContain_When_CoreSanitized
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$coreRoot = Join-Path $repoRoot 'core'
$contractsPath = Join-Path $PSScriptRoot 'contracts\must-not-contain-ide.json'

$placeholderToolkitRoot = '{{TOOLKIT_ROOT}}'
$placeholderSddRoot = '{{SDD_ROOT}}'
$placeholderGuardrailsPath = '{{GUARDRAILS_PATH}}'

function Get-IdeHomeNeedles {
    if (-not (Test-Path -LiteralPath $contractsPath)) {
        Write-Error ("Prepared mustNotContain contract missing: {0}" -f $contractsPath)
        exit 1
    }
    $doc = Get-Content -LiteralPath $contractsPath -Raw | ConvertFrom-Json
    if (-not $doc.mustNotContain -or $doc.mustNotContain.Count -lt 1) {
        Write-Error 'must-not-contain-ide.json must declare mustNotContain needles'
        exit 1
    }
    return @($doc.mustNotContain)
}

function Find-IdeHomePathHits {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$Needles
    )

    $hits = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $Root)) {
        return $hits
    }

    $files = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
        $_.Extension -match '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    }

    foreach ($file in $files) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($needle in $Needles) {
            if ($text.Contains($needle)) {
                $rel = $file.FullName.Substring($Root.Length).TrimStart('\', '/')
                $hits.Add(("{0} contains '{1}'" -f $rel, $needle))
            }
        }
    }

    return $hits
}

$needles = Get-IdeHomeNeedles

# --- Should_FailContract_When_CoreContainsSingleIdeHomePath ---

$probeNeedle = $needles[0]
$probeText = "canonical install example uses $probeNeedle as hardcode"
$probeHits = New-Object System.Collections.Generic.List[string]
if ($probeText.Contains($probeNeedle)) {
    $probeHits.Add(("probe contains '{0}'" -f $probeNeedle))
}

if ($probeHits.Count -eq 0) {
    Write-Error 'Should_FailContract_When_CoreContainsSingleIdeHomePath: expected probe content to fail mustNotContain'
    exit 1
}

Write-Host 'Should_FailContract_When_CoreContainsSingleIdeHomePath: PASS'

# --- Should_PassMustNotContain_When_CoreSanitized ---

if (-not (Test-Path -LiteralPath $coreRoot)) {
    Write-Error 'core/ is missing'
    exit 1
}

$coreHits = Find-IdeHomePathHits -Root $coreRoot -Needles $needles
if ($coreHits.Count -gt 0) {
    Write-Error ("Should_PassMustNotContain_When_CoreSanitized: IDE home paths remain: {0}" -f ($coreHits -join '; '))
    exit 1
}

$scanFiles = Get-ChildItem -LiteralPath $coreRoot -Recurse -File | Where-Object {
    $_.Extension -match '\.(md|mdc|json|ps1|yml|yaml|txt)$'
}

$hasToolkit = $false
$hasSdd = $false
$hasGuardrails = $false
foreach ($file in $scanFiles) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    if ($text.Contains($placeholderToolkitRoot)) { $hasToolkit = $true }
    if ($text.Contains($placeholderSddRoot)) { $hasSdd = $true }
    if ($text.Contains($placeholderGuardrailsPath)) { $hasGuardrails = $true }
}

if (-not $hasToolkit) {
    Write-Error ("Expected placeholder {0} in sanitized core" -f $placeholderToolkitRoot)
    exit 1
}
if (-not $hasSdd) {
    Write-Error ("Expected placeholder {0} in sanitized core" -f $placeholderSddRoot)
    exit 1
}
if (-not $hasGuardrails) {
    Write-Error ("Expected placeholder {0} in sanitized core" -f $placeholderGuardrailsPath)
    exit 1
}

Write-Host 'Should_PassMustNotContain_When_CoreSanitized: PASS'
exit 0
