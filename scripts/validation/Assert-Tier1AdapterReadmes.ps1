#Requires -Version 5.1
# Tests:
#   Should_HaveReadmePerAdapter_When_AdaptersInspected
#   Should_LinkAdaptersDoc_When_StubRead
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

$adaptersDocMarker = 'docs/ADAPTERS.md'
$adaptersDocRelativeLink = '../../docs/ADAPTERS.md'
$syncFixtureMarker = 'scripts/validation/fixtures/'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-AdapterReadmesPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-AdapterReadmesPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$adaptersDir = Join-Path $repoRoot $script:ToolkitConstant.AdaptersDirectoryName
$registryPath = Join-Path $adaptersDir $script:ToolkitConstant.RegistryFileName
$readmeFileName = $script:ToolkitConstant.ReadmeFileName

if (-not (Test-Path -LiteralPath $registryPath)) {
    Write-Fail -TestName 'Assert-AdapterReadmesPreconditions' -Reason ("missing {0}" -f $registryPath)
}

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$registryAgents = @($registry.agents)
if ($registryAgents.Count -eq 0) {
    Write-Fail -TestName 'Assert-AdapterReadmesPreconditions' -Reason 'registry has no agents'
}

# --- Should_HaveReadmePerAdapter_When_AdaptersInspected ---
$existenceName = 'Should_HaveReadmePerAdapter_When_AdaptersInspected'
$missingReadmes = @()
foreach ($agent in $registryAgents) {
    $readmePath = Join-Path (Join-Path $adaptersDir $agent.id) $readmeFileName
    if (-not (Test-Path -LiteralPath $readmePath)) {
        $missingReadmes += $agent.id
    }
}

if ($missingReadmes.Count -gt 0) {
    Write-Fail -TestName $existenceName -Reason ("missing README for: {0}" -f ($missingReadmes -join ', '))
}

Write-Pass -TestName $existenceName

# --- Should_LinkAdaptersDoc_When_StubRead ---
$linkName = 'Should_LinkAdaptersDoc_When_StubRead'
$missingLinks = @()
$missingFixtures = @()
foreach ($agent in $registryAgents) {
    $readmePath = Join-Path (Join-Path $adaptersDir $agent.id) $readmeFileName
    $text = Get-Content -LiteralPath $readmePath -Raw
    $hasAdaptersDoc = ($text -like ("*{0}*" -f $adaptersDocMarker)) -or ($text -like ("*{0}*" -f $adaptersDocRelativeLink))
    if (-not $hasAdaptersDoc) {
        $missingLinks += $agent.id
    }
    if ($text -notlike ("*{0}*" -f $syncFixtureMarker)) {
        $missingFixtures += $agent.id
    }
}

if ($missingLinks.Count -gt 0) {
    Write-Fail -TestName $linkName -Reason ("ADAPTERS.md link missing in: {0}" -f ($missingLinks -join ', '))
}

if ($missingFixtures.Count -gt 0) {
    Write-Fail -TestName $linkName -Reason ("sync fixture pointer missing in: {0}" -f ($missingFixtures -join ', '))
}

Write-Pass -TestName $linkName
exit 0
