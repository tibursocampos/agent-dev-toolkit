# Requires: PowerShell 5.1+
# Tests:
#   Should_ExposePolicyFiles_When_CorePolicyPorted
#   Should_ExposeRouterMaterial_When_CoreRouterPorted
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$policyRoot = Join-Path $repoRoot 'core\policy'
$routerRoot = Join-Path $repoRoot 'core\router'

if (-not (Test-Path -LiteralPath $policyRoot)) {
    Write-Error 'core/policy is missing'
    exit 1
}

$policyItem = Get-Item -LiteralPath $policyRoot
if ($policyItem.LinkType) {
    Write-Error ("core/policy must be a real directory copy, not a {0}" -f $policyItem.LinkType)
    exit 1
}

$policyFiles = @(Get-ChildItem -LiteralPath $policyRoot -File | Where-Object { $_.Name -ne '.gitkeep' })
if ($policyFiles.Count -lt 1) {
    Write-Error 'core/policy has no policy files'
    exit 1
}

$expectedPolicyNames = @(
    'ai-stealth.md',
    'branch-validation.md',
    'caveman-mode.md',
    'context-management.md',
    'conventional-commits.md',
    'guardrails.md',
    'sdd-artifact-language-pt-br.md',
    'sdd-pipeline-guards.md',
    'user-language-pt-br.md'
)

$policyNames = @($policyFiles | ForEach-Object { $_.Name } | Sort-Object)
foreach ($expected in $expectedPolicyNames) {
    if ($policyNames -notcontains $expected) {
        Write-Error ("Missing policy file: {0}" -f $expected)
        exit 1
    }
}

$emptyPolicy = @($policyFiles | Where-Object { $_.Length -le 0 })
if ($emptyPolicy.Count -gt 0) {
    Write-Error ("Empty policy files: {0}" -f (($emptyPolicy | ForEach-Object { $_.Name }) -join ', '))
    exit 1
}

Write-Host 'Should_ExposePolicyFiles_When_CorePolicyPorted: PASS'

if (-not (Test-Path -LiteralPath $routerRoot)) {
    Write-Error 'core/router is missing'
    exit 1
}

$routerItem = Get-Item -LiteralPath $routerRoot
if ($routerItem.LinkType) {
    Write-Error ("core/router must be a real directory copy, not a {0}" -f $routerItem.LinkType)
    exit 1
}

$agentsPath = Join-Path $routerRoot 'AGENTS.md'
if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Error 'core/router/AGENTS.md is missing'
    exit 1
}

$agentsItem = Get-Item -LiteralPath $agentsPath
if ($agentsItem.LinkType) {
    Write-Error ("core/router/AGENTS.md must be a real file copy, not a {0}" -f $agentsItem.LinkType)
    exit 1
}

if ($agentsItem.Length -le 0) {
    Write-Error 'core/router/AGENTS.md is empty'
    exit 1
}

$agentsHead = Get-Content -LiteralPath $agentsPath -TotalCount 5 -ErrorAction Stop
$hasRouterSignal = $false
foreach ($line in $agentsHead) {
    if ($line -match 'router|Workflows|Forma|sdd-spec|Language') {
        $hasRouterSignal = $true
        break
    }
}
if (-not $hasRouterSignal) {
    # Fall back: full file must mention at least one Forma / skill invoke
    $body = Get-Content -LiteralPath $agentsPath -Raw
    if ($body -notmatch 'sdd-spec|orchestrate-develop|Forma') {
        Write-Error 'core/router/AGENTS.md does not look like router material'
        exit 1
    }
}

Write-Host 'Should_ExposeRouterMaterial_When_CoreRouterPorted: PASS'
exit 0
