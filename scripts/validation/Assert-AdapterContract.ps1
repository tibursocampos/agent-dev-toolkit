#Requires -Version 5.1
# Tests:
#   Should_ValidateRegistrySchema_When_RegistryLoaded
#   Should_KeepPublishSurfacePathsSafe_When_RegistryLoaded
#   Should_ExposeRequiredAdapterCommands_When_ContractDotSourced
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }

$registryPath = Join-Path $repoRoot 'adapters\registry.json'
$contractPath = Join-Path $repoRoot 'adapters\_contract\AdapterContract.ps1'
foreach ($p in @($registryPath, $contractPath)) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Fail 'Assert-AdapterContractPreconditions' "missing $p" }
}

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$subagentsName = $script:ToolkitConstant.SubagentsCapabilityName
$allowedSubagents = @($script:ToolkitConstant.SubagentsNativeValue, $script:ToolkitConstant.SubagentsNoneValue)
$booleanCapabilities = @('skills', 'rules', 'hooks', 'router', 'plugin', 'agents')

# --- registry schema ---
$n = 'Should_ValidateRegistrySchema_When_RegistryLoaded'
if ($null -eq $registry.agents -or @($registry.agents).Count -lt 1) { Write-Fail $n 'registry.agents is missing or empty' }
$seen = @{}
foreach ($agent in $registry.agents) {
    $id = [string]$agent.id
    if ([string]::IsNullOrWhiteSpace($id) -or $seen.ContainsKey($id)) { Write-Fail $n "missing or duplicate agent id '$id'" }
    $seen[$id] = $true
    if ([string]::IsNullOrWhiteSpace([string]$agent.module) -or -not (Test-Path -LiteralPath (Join-Path (Join-Path $repoRoot 'adapters') ([string]$agent.module)))) {
        Write-Fail $n "agent $id module missing"
    }
    if ($null -eq $agent.capabilities) { Write-Fail $n "agent $id missing capabilities" }
    $props = @($agent.capabilities.PSObject.Properties.Name)
    foreach ($c in $booleanCapabilities) {
        if ($props -notcontains $c) { Write-Fail $n "agent $id missing capabilities.$c" }
    }
    if ($props -notcontains $subagentsName -or $allowedSubagents -notcontains [string]$agent.capabilities.$subagentsName) {
        Write-Fail $n "agent $id capabilities.$subagentsName must be one of: $($allowedSubagents -join ', ')"
    }
}
Write-Pass $n

# --- publishSurface: wholeFileRouter entries are bare file names (no traversal, no rooted paths) ---
$n = 'Should_KeepPublishSurfacePathsSafe_When_RegistryLoaded'
$surfaceProp = $script:ToolkitConstant.RegistryPublishSurfacePropertyName
$routerProp = $script:ToolkitConstant.RegistryPublishSurfaceWholeFileRouterPropertyName
foreach ($agent in $registry.agents) {
    $id = [string]$agent.id
    $surface = $agent.$surfaceProp
    if ($null -eq $surface -or @($surface.PSObject.Properties.Name) -notcontains $routerProp) { Write-Fail $n "agent $id missing $surfaceProp.$routerProp" }
    $value = $surface.$routerProp
    if ($null -eq $value -or $value -isnot [System.Array]) { Write-Fail $n "agent $id $routerProp must be an array" }
    foreach ($rel in @($value)) {
        $t = [string]$rel
        if ([string]::IsNullOrWhiteSpace($t) -or [System.IO.Path]::IsPathRooted($t) -or $t.Contains('..') -or $t.Contains('\') -or $t.Contains('/')) {
            Write-Fail $n ("agent {0}: unsafe publishSurface path '{1}'" -f $id, $t)
        }
    }
}
Write-Pass $n

# --- contract exposes the commands adapters implement, and splat-safe switches ---
$n = 'Should_ExposeRequiredAdapterCommands_When_ContractDotSourced'
. $contractPath
$exposed = @(Get-AdapterContractCommandNames)
foreach ($name in @('Get-Capabilities', 'Get-InstallRoots', 'Publish-Skills', 'Publish-Policy', 'Publish-Router', 'Publish-Agents', 'Publish-Hooks', 'Get-SddRoot', 'Invoke-SmokeValidate', 'Uninstall-Toolkit')) {
    if ($exposed -notcontains $name -or $null -eq (Get-Command -Name $name -ErrorAction SilentlyContinue)) { Write-Fail $n "contract missing $name" }
}
foreach ($pair in @(@('Uninstall-Toolkit', @('AllowUserHome', 'WhatIf')), @('Get-SddRoot', @('Prepare', 'AllowUserHome', 'WhatIf')))) {
    $cmd = Get-Command -Name $pair[0]
    foreach ($param in $pair[1]) {
        if (-not $cmd.Parameters.ContainsKey($param)) { Write-Fail $n "$($pair[0]) missing parameter $param" }
    }
}
$caps = Get-Capabilities -AgentId 'cursor'
if ($null -eq $caps -or $caps.Implemented -ne $false -or [string]$caps.Capabilities.$subagentsName -ne $script:ToolkitConstant.SubagentsNoneValue) {
    Write-Fail $n 'Get-Capabilities stub must report Implemented = false and never mint native subagents'
}
Write-Pass $n

Write-Host 'Assert-AdapterContract: ALL PASS'
exit 0
