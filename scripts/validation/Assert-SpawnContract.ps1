#Requires -Version 5.1
# Tests:
#   Should_Fail_When_SpawnMdMissing
#   Should_Fail_When_LanguageMdMissing
#   Should_Pass_When_SpawnAndSubagentsPresent
#   Should_Pass_When_LanguageMdAndEnUsSpawnPresent
#   Should_Fail_When_RegistryMissingSubagents
#   Should_Pass_When_AllRegisteredAdaptersDocumentSpawnLifecycle
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

function Get-SpawnSection {
    param([Parameter(Mandatory = $true)][string] $Text)

    $match = [regex]::Match($Text, '(?ims)^##\s+Spawn\s*/\s*subagents[^\r\n]*\r?\n(.*?)(?=^##\s|\z)')
    if (-not $match.Success) { return '' }
    return $match.Groups[1].Value
}

function Test-RegisteredAdapterSpawnGuidance {
    param(
        [Parameter(Mandatory = $true)][object[]] $Agents,
        [Parameter(Mandatory = $true)][string] $RepoRoot
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    foreach ($agent in $Agents) {
        $id = [string]$agent.id
        $readmePath = Join-Path (Join-Path $RepoRoot 'adapters') (Join-Path $id 'README.md')
        if (-not (Test-Path -LiteralPath $readmePath)) {
            $problems.Add("${id}: missing adapters/$id/README.md")
            continue
        }

        $section = Get-SpawnSection -Text ([System.IO.File]::ReadAllText($readmePath))
        if ([string]::IsNullOrWhiteSpace($section)) {
            $problems.Add("${id}: missing 'Spawn / subagents' section")
            continue
        }
        if ($section -notmatch '(?i)SPAWN\.md') {
            $problems.Add("${id}: Spawn section must point to canonical SPAWN.md")
        }

        $capability = [string]$agent.capabilities.subagents
        if ($capability -eq 'native') {
            $hasFreshAssignment = $section -match '(?is)fresh\s+(?:child|subagent|agent|handle)' -and $section -match '(?is)new\s+(?:task|assignment|review|correction)'
            $hasNoCompletedReuse = $section -match '(?is)(?:never|do\s+not|must\s+not).{0,240}reuse' -and $section -match '(?is)(?:child\s+returns|returned\s+(?:child|work|result)|completed\s+(?:child|subagent|agent)|after\s+(?:the\s+)?child\s+returns)'
            $hasHostTeardownBoundary = $section -match '(?is)host.{0,120}(?:control|manage|provides?.{0,30}(?:close|kill|terminat|teardown)|close|kill|terminat|teardown).{0,80}(?:close|kill|terminat|teardown|lifecycle|control|manage)?|(?:close|kill|terminat|teardown).{0,80}host.{0,40}(?:control|manage)'
            if (-not $hasFreshAssignment) { $problems.Add("${id}: native Spawn section must require a fresh child/handle for each new task") }
            if (-not $hasNoCompletedReuse) { $problems.Add("${id}: native Spawn section must forbid reuse of a completed child") }
            if (-not $hasHostTeardownBoundary) { $problems.Add("${id}: native Spawn section must describe host-managed teardown limits") }
        }
        elseif ($capability -eq 'none') {
            if ($section -notmatch '(?i)subagents\s*=\s*none|subagents.{0,30}\bnone\b|Registry.{0,80}\bnone\b') {
                $problems.Add("${id}: subagents=none must remain explicit in Spawn section")
            }
            if ($section -notmatch '(?is)fallback.{0,100}in-parent|in-parent.{0,100}fallback') {
                $problems.Add("${id}: subagents=none must retain the in-parent fallback")
            }
        }
        else {
            $problems.Add("${id}: unsupported registry subagents value '$capability'")
        }
    }
    return $problems.ToArray()
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

# --- Should_Pass_When_AllRegisteredAdaptersDocumentSpawnLifecycle ---
$adapterLifecycleName = 'Should_Pass_When_AllRegisteredAdaptersDocumentSpawnLifecycle'
$spawnLifecycleProblems = @(Test-RegisteredAdapterSpawnGuidance -Agents $agents -RepoRoot $repoRoot)
if ($spawnLifecycleProblems.Count -gt 0) {
    Write-Fail -TestName $adapterLifecycleName -Reason ($spawnLifecycleProblems -join '; ')
}

$spawnText = [System.IO.File]::ReadAllText($spawnMdPath)
$canonicalHasLifecycle = $spawnText -match '(?is)fresh\s+(?:child|subagent|agent|handle)' -and
    $spawnText -match '(?is)(?:never|do\s+not|must\s+not).{0,240}reuse' -and
    $spawnText -match '(?is)(?:child\s+returns|returned\s+(?:child|work|result)|completed\s+(?:child|subagent|agent)|after\s+(?:the\s+)?child\s+returns)' -and
    $spawnText -match '(?is)host.{0,160}(?:control|manage|provides?.{0,30}(?:close|kill|terminat|teardown)|close|kill|terminat|teardown)'
if (-not $canonicalHasLifecycle) {
    Write-Fail -TestName $adapterLifecycleName -Reason 'canonical SPAWN.md must define fresh assignment, no completed-child reuse, and host-managed teardown boundary'
}

Write-Pass -TestName $adapterLifecycleName

Write-Host 'Assert-SpawnContract: ALL PASS'
exit 0
