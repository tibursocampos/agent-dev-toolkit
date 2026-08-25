#Requires -Version 5.1
# Tests:
#   Should_Fail_When_SpawnMdMissing
#   Should_Fail_When_LanguageMdMissing
#   Should_Pass_When_SpawnAndSubagentsPresent
#   Should_Pass_When_LanguageMdAndEnUsSpawnPresent
#   Should_Fail_When_RegistryMissingSubagents
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

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

function Test-SpawnMdPresent {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )
    $candidate = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $candidate)) {
        return $false
    }
    $item = Get-Item -LiteralPath $candidate
    return ($item.Length -gt 0)
}

function Get-AgentsMissingSubagents {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Agents,
        [Parameter(Mandatory = $true)][string] $CapabilityName
    )
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($agent in $Agents) {
        $agentId = [string]$agent.id
        if ([string]::IsNullOrWhiteSpace($agentId)) {
            $agentId = '(missing-id)'
        }

        $caps = $agent.capabilities
        if ($null -eq $caps) {
            $missing.Add($agentId)
            continue
        }

        $propNames = @($caps.PSObject.Properties.Name)
        if ($propNames -notcontains $CapabilityName) {
            $missing.Add($agentId)
            continue
        }

        $value = [string]$caps.$CapabilityName
        if ([string]::IsNullOrWhiteSpace($value)) {
            $missing.Add($agentId)
        }
    }
    return $missing.ToArray()
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-SpawnContractPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-SpawnContractPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$spawnRel = $script:ToolkitConstant.SpawnMdRelativePath
$inventedSpawnRel = $script:ToolkitConstant.InventedMissingSpawnMdRel
$subagentsCapabilityName = $script:ToolkitConstant.SubagentsCapabilityName
$registryRel = Join-Path $script:ToolkitConstant.AdaptersDirectoryName $script:ToolkitConstant.RegistryFileName
$registryPath = Join-Path $repoRoot ($registryRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $registryPath)) {
    Write-Fail -TestName 'Assert-SpawnContractPreconditions' -Reason ($script:ToolkitMessage.RegistryMissing -f $registryPath)
}

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
if ($null -eq $registry.agents) {
    Write-Fail -TestName 'Assert-SpawnContractPreconditions' -Reason ($script:ToolkitMessage.RegistryAgentsMissingForSpawn -f $registryPath)
}

$agents = @($registry.agents)

# --- Should_Fail_When_SpawnMdMissing ---
$failSpawnName = 'Should_Fail_When_SpawnMdMissing'
if (Test-SpawnMdPresent -RepoRoot $repoRoot -RelativePath $inventedSpawnRel) {
    Write-Fail -TestName $failSpawnName -Reason ($script:ToolkitMessage.SpawnMdNegativeExpectedFail -f $inventedSpawnRel)
}

Write-Pass -TestName $failSpawnName

# --- Should_Fail_When_RegistryMissingSubagents ---
$failRegistryName = 'Should_Fail_When_RegistryMissingSubagents'
$syntheticMissing = [pscustomobject]@{
    id           = 'synthetic-missing-subagents'
    capabilities = [pscustomobject]@{ skills = $true }
}
$syntheticHits = @(Get-AgentsMissingSubagents -Agents @($syntheticMissing) -CapabilityName $subagentsCapabilityName)
if ($syntheticHits.Count -ne 1) {
    Write-Fail -TestName $failRegistryName -Reason $script:ToolkitMessage.RegistrySubagentsNegativeExpectedFail
}

Write-Pass -TestName $failRegistryName

# --- Should_Pass_When_SpawnAndSubagentsPresent ---
$passName = 'Should_Pass_When_SpawnAndSubagentsPresent'
if (-not (Test-SpawnMdPresent -RepoRoot $repoRoot -RelativePath $spawnRel)) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.SpawnMdMissing -f $spawnRel)
}

$missingSubagents = @(Get-AgentsMissingSubagents -Agents $agents -CapabilityName $subagentsCapabilityName)
if ($missingSubagents.Count -gt 0) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.RegistrySubagentsMissing -f ($missingSubagents -join ', '))
}

Write-Pass -TestName $passName

# --- Should_Fail_When_LanguageMdMissing ---
$failLanguageName = 'Should_Fail_When_LanguageMdMissing'
$languageRel = $script:ToolkitConstant.LanguageMdRelativePath
$inventedLanguageRel = $script:ToolkitConstant.InventedMissingLanguageMdRel
if (Test-SpawnMdPresent -RepoRoot $repoRoot -RelativePath $inventedLanguageRel) {
    Write-Fail -TestName $failLanguageName -Reason ($script:ToolkitMessage.LanguageMdNegativeExpectedFail -f $inventedLanguageRel)
}

Write-Pass -TestName $failLanguageName

# --- Should_Pass_When_LanguageMdAndEnUsSpawnPresent ---
$passLanguageName = 'Should_Pass_When_LanguageMdAndEnUsSpawnPresent'
if (-not (Test-SpawnMdPresent -RepoRoot $repoRoot -RelativePath $languageRel)) {
    Write-Fail -TestName $passLanguageName -Reason ($script:ToolkitMessage.LanguageMdMissing -f $languageRel)
}

$spawnMdPath = Join-Path $repoRoot ($spawnRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$spawnText = [System.IO.File]::ReadAllText($spawnMdPath)
$enUsMarker = $script:ToolkitConstant.LanguageEnUsSpawnMarker
if ($spawnText -notmatch [regex]::Escape('LANGUAGE.md') -or $spawnText -notmatch [regex]::Escape($enUsMarker)) {
    Write-Fail -TestName $passLanguageName -Reason $script:ToolkitMessage.SpawnMissingEnUsLanguageMarker
}

Write-Pass -TestName $passLanguageName

Write-Host 'Assert-SpawnContract: ALL PASS'
exit 0
