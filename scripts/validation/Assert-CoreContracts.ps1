#Requires -Version 5.1
<#
.SYNOPSIS
  Single-process text/contract assertions for core/ (router, spawn, orchestration, SDD contracts).
.DESCRIPTION
  Each section keeps the assertions of the former standalone Assert-* script it replaced.
  Sections run in isolation (own function scope); a failing section is reported by name
  and does not stop later sections. Exit code is non-zero when any section fails.
.PARAMETER Quiet
  Suppress per-check PASS lines; print failures and the summary only.
#>
[CmdletBinding()]
param([switch] $Quiet)

$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$physicalPathScript = Join-Path $scriptDir '_lib\ToolkitPhysicalPath.ps1'
foreach ($required in @($repoRootScript, $constantsScript, $physicalPathScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Error ("Assert-CoreContracts: missing {0}" -f $required)
        exit 1
    }
}
. $repoRootScript
. $constantsScript
. $physicalPathScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$script:PassCount = 0
$script:QuietMode = [bool]$Quiet

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    $script:PassCount++
    if (-not $script:QuietMode) { Write-Host ("{0}: PASS" -f $TestName) }
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    throw ("{0}: FAIL - {1}" -f $TestName, $Reason)
}

$sections = [ordered]@{}
$sections['RouterDocLinks'] = {
# Tests:
#   Should_Pass_When_RouterLinksExist
#   Should_FailValidateCore_When_RouterPointsToMissingDocsPath
#   Should_NotReferenceMissingGuides10to12_When_RouterRead


$forbiddenGuideRelatives = @(
    'docs/guides/10-forma-c-orquestracao.md',
    'docs/guides/11-forma-c-caso-nuget-extract.md',
    'docs/guides/12-forma-c-caso-mobile-app.md'
)



function Get-RouterPathLiterals {
    param(
        [Parameter(Mandatory = $true)][string] $RouterText,
        [Parameter(Mandatory = $true)][string] $Pattern
    )
    $found = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($match in [regex]::Matches($RouterText, $Pattern)) {
        $prefix = $match.Groups[1].Value
        $rest = $match.Groups[2].Value.Trim().TrimEnd(',', '.', ';', ')', ']')
        $rel = if ([string]::IsNullOrWhiteSpace($rest)) {
            '{0}/' -f $prefix
        }
        else {
            '{0}/{1}' -f $prefix, $rest
        }
        if ($seen.Add($rel)) {
            $found.Add($rel)
        }
    }
    return $found.ToArray()
}

function Test-RouterRelativePathExists {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )
    $normalized = $RelativePath.TrimEnd('/')
    $candidate = Join-Path $RepoRoot ($normalized -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ($RelativePath.EndsWith('/')) {
        return Test-Path -LiteralPath $candidate
    }
    return (Test-Path -LiteralPath $candidate)
}

function Get-MissingRouterTargets {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $RelativePaths
    )
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($rel in $RelativePaths) {
        if (-not (Test-RouterRelativePathExists -RepoRoot $RepoRoot -RelativePath $rel)) {
            $missing.Add($rel)
        }
    }
    return $missing.ToArray()
}

function Format-RouterDocLinkTe01 {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    return ($script:ToolkitMessage.RouterDocLinkDoesNotExist -f $RelativePath)
}




$routerRelativePath = $script:ToolkitConstant.RouterAgentsRelativePath
$routerPath = Join-Path $repoRoot ($routerRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $routerPath)) {
    Write-Fail -TestName 'Assert-RouterDocLinksPreconditions' -Reason (Format-RouterDocLinkTe01 -RelativePath $routerRelativePath)
}

$routerText = Get-Content -LiteralPath $routerPath -Raw
$pathLiteralPattern = $script:ToolkitConstant.RouterPathLiteralPattern

# --- Should_FailValidateCore_When_RouterPointsToMissingDocsPath ---
$failName = 'Should_FailValidateCore_When_RouterPointsToMissingDocsPath'
$inventedRel = $script:ToolkitConstant.InventedMissingRouterDocRel
$inventedMissing = @(Get-MissingRouterTargets -RepoRoot $repoRoot -RelativePaths @($inventedRel))
if ($inventedMissing.Count -ne 1) {
    Write-Fail -TestName $failName -Reason ($script:ToolkitMessage.RouterDocLinksNegativeExpectedFail -f $inventedRel)
}

$te01Message = Format-RouterDocLinkTe01 -RelativePath $inventedRel
if ($te01Message -notlike ("*{0}*" -f $inventedRel) -or $te01Message -notlike '*does not exist under repo root*') {
    Write-Fail -TestName $failName -Reason ("TE01 message malformed: {0}" -f $te01Message)
}

Write-Pass -TestName $failName

# --- Should_Pass_When_RouterLinksExist ---
$passName = 'Should_Pass_When_RouterLinksExist'
$pathLiterals = @(Get-RouterPathLiterals -RouterText $routerText -Pattern $pathLiteralPattern)
if ($pathLiterals.Count -eq 0) {
    Write-Fail -TestName $passName -Reason $script:ToolkitMessage.RouterDocLinksNoLiterals
}

$missing = @(Get-MissingRouterTargets -RepoRoot $repoRoot -RelativePaths $pathLiterals)
if ($missing.Count -gt 0) {
    $details = @($missing | ForEach-Object { Format-RouterDocLinkTe01 -RelativePath ([string]$_) })
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.RouterDocLinksMissingTargets -f ($details -join ', '))
}

Write-Pass -TestName $passName

# --- Should_NotReferenceMissingGuides10to12_When_RouterRead ---
$guidesName = 'Should_NotReferenceMissingGuides10to12_When_RouterRead'
$stillReferenced = [System.Collections.Generic.List[string]]::new()
foreach ($forbidden in $forbiddenGuideRelatives) {
    if ($routerText -like ("*{0}*" -f $forbidden)) {
        $stillReferenced.Add($forbidden)
    }
}

if ($stillReferenced.Count -gt 0) {
    Write-Fail -TestName $guidesName -Reason ($script:ToolkitMessage.RouterDocLinksForbiddenGuides -f ($stillReferenced.ToArray() -join ', '))
}

Write-Pass -TestName $guidesName
}

$sections['SpawnContract'] = {
# Tests:
#   Should_Fail_When_SpawnMdMissing
#   Should_Fail_When_LanguageMdMissing
#   Should_Pass_When_SpawnAndSubagentsPresent
#   Should_Pass_When_LanguageMdAndEnUsSpawnPresent
#   Should_Fail_When_RegistryMissingSubagents
#   Should_Pass_When_AllRegisteredAdaptersDocumentSpawnLifecycle
#   Should_Pass_When_SpecialistInputAndOutputContractsAreExplicit
#   Should_Fail_When_SpecialistAssignmentOmitsExpectedResult




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

function Get-MissingContractMarkers {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string[]] $Markers
    )

    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($marker in $Markers) {
        if ($Text.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $missing.Add($marker)
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
            $hasFreshAssignment = $section -match '(?is)fresh\s+(?:child|subagent|agent|handle)'
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
$spawnMdPath = Join-Path $repoRoot ($spawnRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$rosterRel = 'core/skills/_shared/agents/ROSTER.md'
$receiptRel = 'core/skills/_shared/agents/RECEIPT.md'
$rosterPath = Join-Path $repoRoot ($rosterRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$receiptPath = Join-Path $repoRoot ($receiptRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $rosterPath)) {
    Write-Fail -TestName 'Assert-SpawnContractPreconditions' -Reason ("missing {0}" -f $rosterRel)
}
if (-not (Test-Path -LiteralPath $receiptPath)) {
    Write-Fail -TestName 'Assert-SpawnContractPreconditions' -Reason ("missing {0}" -f $receiptRel)
}
$rosterText = [System.IO.File]::ReadAllText($rosterPath)
$receiptText = [System.IO.File]::ReadAllText($receiptPath)

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
$spawnText = [System.IO.File]::ReadAllText($spawnMdPath)

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

# --- Should_Pass_When_SpecialistInputAndOutputContractsAreExplicit ---
$specialistIoName = 'Should_Pass_When_SpecialistInputAndOutputContractsAreExplicit'
$spawnInputMarkers = @(
    '**Role**',
    '**Objective**',
    '**Scoped paths**',
    '**Relevant references**',
    '**Expected result**',
    '**Receipt**'
)
$missingSpawnInput = @(Get-MissingContractMarkers -Text $spawnText -Markers $spawnInputMarkers)
$missingRosterInput = @(Get-MissingContractMarkers -Text $rosterText -Markers @(
    'Minimum assignment input',
    'Question and affected repository paths',
    'Approved task/PLAN excerpt'
))
$missingRoleOutputs = @(Get-MissingContractMarkers -Text $receiptText -Markers @(
    'Role-specific contracts',
    'consumer-specific output contracts',
    'Markdown/text',
    'JSON',
    'concrete consumer',
    'compatibility rules'
))
if ($missingSpawnInput.Count -gt 0 -or $missingRosterInput.Count -gt 0 -or $missingRoleOutputs.Count -gt 0) {
    $problems = @()
    if ($missingSpawnInput.Count -gt 0) { $problems += ('SPAWN.md missing ' + ($missingSpawnInput -join ', ')) }
    if ($missingRosterInput.Count -gt 0) { $problems += ('ROSTER.md missing ' + ($missingRosterInput -join ', ')) }
    if ($missingRoleOutputs.Count -gt 0) { $problems += ('RECEIPT.md missing ' + ($missingRoleOutputs -join ', ')) }
    Write-Fail -TestName $specialistIoName -Reason ($problems -join '; ')
}
Write-Pass -TestName $specialistIoName

# --- Should_Fail_When_SpecialistAssignmentOmitsExpectedResult ---
$missingExpectedResultName = 'Should_Fail_When_SpecialistAssignmentOmitsExpectedResult'
$syntheticIncompleteAssignment = '**Role** repo_analyst; **Objective** inspect impact; **Scoped paths** core/; **Relevant references** README; **Receipt** findings per RECEIPT.md.'
$missingExpectedResult = @(Get-MissingContractMarkers -Text $syntheticIncompleteAssignment -Markers @('**Expected result**'))
if ($missingExpectedResult.Count -ne 1) {
    Write-Fail -TestName $missingExpectedResultName -Reason 'an assignment without the expected result must be detected as incomplete'
}
Write-Pass -TestName $missingExpectedResultName

}

$sections['OrchestrateSpawnFallback'] = {
# Tests:
#   Should_Fail_When_OrchestrateCitesTaskWithoutFallback
#   Should_MentionSpawnAndFallback_When_OrchestrateCitesTask
#   Should_DegradeMultiAngle_When_SubagentsNotNative
#   Should_PassValidateCore_When_SpawnContractsHold




function Test-BodyMeetsTaskSpawnFallbackContract {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Body,
        [Parameter(Mandatory = $true)][string] $TaskMarker,
        [Parameter(Mandatory = $true)][string] $SpawnMarker,
        [Parameter(Mandatory = $true)][string] $FallbackMarker
    )
    if ($Body.IndexOf($TaskMarker, [System.StringComparison]::Ordinal) -lt 0) {
        return $true
    }

    $hasSpawn = $Body.IndexOf($SpawnMarker, [System.StringComparison]::Ordinal) -ge 0
    $hasFallback = $Body.IndexOf($FallbackMarker, [System.StringComparison]::Ordinal) -ge 0
    return ($hasSpawn -and $hasFallback)
}

function Get-OrchestrateSkillBodies {
    param(
        [Parameter(Mandatory = $true)][string] $SkillsRoot,
        [Parameter(Mandatory = $true)][string] $NamePrefix,
        [Parameter(Mandatory = $true)][string] $SkillFileName,
        [Parameter(Mandatory = $true)][string] $ReferenceFileName
    )
    $bodies = [System.Collections.Generic.List[object]]::new()
    if (-not (Test-Path -LiteralPath $SkillsRoot)) {
        return $bodies.ToArray()
    }

    $dirs = @(Get-ChildItem -LiteralPath $SkillsRoot -Directory | Where-Object { $_.Name.StartsWith($NamePrefix, [System.StringComparison]::Ordinal) })
    foreach ($dir in $dirs) {
        $skillPath = Join-Path $dir.FullName $SkillFileName
        if (-not (Test-Path -LiteralPath $skillPath)) {
            continue
        }

        $parts = [System.Collections.Generic.List[string]]::new()
        $parts.Add((Get-Content -LiteralPath $skillPath -Raw))
        $referencePath = Join-Path $dir.FullName $ReferenceFileName
        if (Test-Path -LiteralPath $referencePath) {
            $parts.Add((Get-Content -LiteralPath $referencePath -Raw))
        }

        $bodies.Add([pscustomobject]@{
                SkillName = $dir.Name
                Body      = ($parts -join "`n")
            })
    }

    return $bodies.ToArray()
}

function Get-OrchestrateSkillsMissingSpawnFallback {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $SkillBodies,
        [Parameter(Mandatory = $true)][string] $TaskMarker,
        [Parameter(Mandatory = $true)][string] $SpawnMarker,
        [Parameter(Mandatory = $true)][string] $FallbackMarker
    )
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $SkillBodies) {
        if (-not (Test-BodyMeetsTaskSpawnFallbackContract -Body ([string]$item.Body) -TaskMarker $TaskMarker -SpawnMarker $SpawnMarker -FallbackMarker $FallbackMarker)) {
            $missing.Add([string]$item.SkillName)
        }
    }
    return $missing.ToArray()
}

function Test-CodeReviewMultiAngleSpawnFallback {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Body,
        [Parameter(Mandatory = $true)][string] $SpawnMarker,
        [Parameter(Mandatory = $true)][string] $FallbackMarker,
        [Parameter(Mandatory = $true)][string] $InParentMarker
    )
    $hasSpawn = $Body.IndexOf($SpawnMarker, [System.StringComparison]::Ordinal) -ge 0
    $hasFallback = $Body.IndexOf($FallbackMarker, [System.StringComparison]::Ordinal) -ge 0
    $hasInParent = $Body.IndexOf($InParentMarker, [System.StringComparison]::Ordinal) -ge 0
    return ($hasSpawn -and $hasFallback -and $hasInParent)
}




$taskMarker = $script:ToolkitConstant.SpawnTaskCitationMarker
$spawnMarker = $script:ToolkitConstant.SpawnContractMarker
$fallbackMarker = $script:ToolkitConstant.SpawnFallbackMarker
$inParentMarker = $script:ToolkitConstant.SpawnInParentMarker
$skillsRoot = Join-Path $repoRoot ((Join-Path $script:ToolkitConstant.CoreSkillsDirectoryName $script:ToolkitConstant.SkillsDirectoryName) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$namePrefix = $script:ToolkitConstant.OrchestrateSkillNamePrefix
$skillFileName = $script:ToolkitConstant.OrchestrateSkillFileName
$referenceFileName = $script:ToolkitConstant.OrchestrateReferenceFileName
$codeReviewDirName = $script:ToolkitConstant.CodeReviewSkillDirectoryName

# --- Should_Fail_When_OrchestrateCitesTaskWithoutFallback ---
$failName = 'Should_Fail_When_OrchestrateCitesTaskWithoutFallback'
$syntheticBad = "Spawn a $taskMarker child when ready."
if (Test-BodyMeetsTaskSpawnFallbackContract -Body $syntheticBad -TaskMarker $taskMarker -SpawnMarker $spawnMarker -FallbackMarker $fallbackMarker) {
    Write-Fail -TestName $failName -Reason $script:ToolkitMessage.OrchestrateTaskWithoutFallbackExpectedFail
}

Write-Pass -TestName $failName

# --- Should_MentionSpawnAndFallback_When_OrchestrateCitesTask ---
$mentionName = 'Should_MentionSpawnAndFallback_When_OrchestrateCitesTask'
if (-not (Test-Path -LiteralPath $skillsRoot)) {
    Write-Fail -TestName $mentionName -Reason $script:ToolkitMessage.OrchestrateSkillsDirMissing
}

$skillBodies = @(Get-OrchestrateSkillBodies -SkillsRoot $skillsRoot -NamePrefix $namePrefix -SkillFileName $skillFileName -ReferenceFileName $referenceFileName)
$missingSpawnFallback = @(Get-OrchestrateSkillsMissingSpawnFallback -SkillBodies $skillBodies -TaskMarker $taskMarker -SpawnMarker $spawnMarker -FallbackMarker $fallbackMarker)
if ($missingSpawnFallback.Count -gt 0) {
    Write-Fail -TestName $mentionName -Reason ($script:ToolkitMessage.OrchestrateTaskWithoutSpawnFallback -f ($missingSpawnFallback -join ', '))
}

Write-Pass -TestName $mentionName

# --- Should_DegradeMultiAngle_When_SubagentsNotNative ---
$multiAngleName = 'Should_DegradeMultiAngle_When_SubagentsNotNative'
$codeReviewSkillPath = Join-Path $skillsRoot ((Join-Path $codeReviewDirName $skillFileName) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $codeReviewSkillPath)) {
    Write-Fail -TestName $multiAngleName -Reason ($script:ToolkitMessage.CodeReviewSkillMissing -f $codeReviewSkillPath)
}

$codeReviewBody = Get-Content -LiteralPath $codeReviewSkillPath -Raw
$codeReviewRefPath = Join-Path $skillsRoot ((Join-Path $codeReviewDirName $referenceFileName) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $codeReviewRefPath) {
    $codeReviewBody = $codeReviewBody + "`n" + (Get-Content -LiteralPath $codeReviewRefPath -Raw)
}

if (-not (Test-CodeReviewMultiAngleSpawnFallback -Body $codeReviewBody -SpawnMarker $spawnMarker -FallbackMarker $fallbackMarker -InParentMarker $inParentMarker)) {
    Write-Fail -TestName $multiAngleName -Reason $script:ToolkitMessage.CodeReviewMissingSpawnFallback
}

Write-Pass -TestName $multiAngleName

# --- Should_PassValidateCore_When_SpawnContractsHold ---
$passValidateName = 'Should_PassValidateCore_When_SpawnContractsHold'
if ($skillBodies.Count -eq 0) {
    Write-Fail -TestName $passValidateName -Reason $script:ToolkitMessage.OrchestrateSkillsDirMissing
}

Write-Pass -TestName $passValidateName

}

$sections['OrchestratorCharterPublished'] = {
# Tests:
#   Should_Pass_When_OrchestratorCharterPublishedInPolicyAndRouter






$testName = 'Should_Pass_When_OrchestratorCharterPublishedInPolicyAndRouter'
$paths = @(
    $script:ToolkitConstant.OrchestratorSessionPolicyRelativePath,
    $script:ToolkitConstant.RouterAgentsRelativePath
)
$markers = @($script:ToolkitConstant.OrchestratorCharterHeadingMarker) + @($script:ToolkitConstant.OrchestratorCharterRuleMarkers)

foreach ($rel in $paths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $testName -Reason ("missing {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    foreach ($marker in $markers) {
        if ($text -notmatch [regex]::Escape($marker)) {
            Write-Fail -TestName $testName -Reason ("{0} missing marker: {1}" -f $rel, $marker)
        }
    }
}

$startupPolicy = Get-Content -LiteralPath (Join-Path $repoRoot 'core/policy/orchestrator-session.md') -Raw -Encoding UTF8
$router = Get-Content -LiteralPath (Join-Path $repoRoot 'core/router/AGENTS.md') -Raw -Encoding UTF8
foreach ($marker in @('Startup is capability-first', 'effective `subagents` capability', 'preferences.json` before loading any spawn contract', 'subagents=none', 'only `always` and `adaptive`')) {
    if ($startupPolicy -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName $testName -Reason ("orchestrator-session is missing capability-first startup marker: {0}" -f $marker)
    }
}
if ($startupPolicy -match 'unconditionally: \*\*Read\*\*.*SPAWN-DIGEST' -or $router -match 'Read\*\*.*SPAWN-DIGEST.*unconditionally') {
    Write-Fail -TestName $testName -Reason 'the digest must not be mandated before capability/preferences are checked'
}
if ($router -notmatch [regex]::Escape('If capability is `none`/unknown, skip spawn/model-choice contracts and questions')) {
    Write-Fail -TestName $testName -Reason 'router must gate spawn-contract reads and questions on effective native capability'
}

Write-Pass -TestName $testName
}

$sections['OrchestratorCommands'] = {
# Tests:
#   Should_Pass_When_OrchestratorCommandsDocumented






$testName = 'Should_Pass_When_OrchestratorCommandsDocumented'
$rel = $script:ToolkitConstant.OrchestratorSessionPolicyRelativePath
$full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $full)) {
    Write-Fail -TestName $testName -Reason ("missing {0}" -f $rel)
}

$text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
$required = @($script:ToolkitConstant.OrchestratorCommandMarkers)
foreach ($marker in $required) {
    if ($text -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName $testName -Reason ("orchestrator-session missing: {0}" -f $marker)
    }
}

Write-Pass -TestName $testName
}

$sections['InvocationAxes'] = {
# Tests:
#   Should_Pass_When_AxesNormativeProsePresentInContracts (CT5 / REQ-007 / CA4)
#   Should_Pass_When_AxisASpawnChoicePreserved (CT5 / RN01)
#   Should_Pass_When_AxisBCModelLockPresent (CT5 / RN02)
#
# Prose smoke: A≠B≠C normative markers across SUBAGENT-MODEL / SPAWN / router / orchestrator-session.


$script:AxesMarkerPattern = 'A\s*[\u2260!=]+\s*B\s*[\u2260!=]+\s*C'
$script:ThinTrivialMarker = 'Thin trivial'
$script:InParentMarker = 'in-parent'
$script:OmitModelMarker = 'omit'
$script:InheritOrSameMarkerPattern = '(?i)(inherit|same model as (the )?parent|same as parent)'
$script:SilenceNotApprovalPattern = '(?i)[Ss]ilence\s*[\u2260!=]+\s*approval'
$script:NoPinChildPattern = '(?i)(does\s+\*{0,2}not\*{0,2}\s+pin|pinning child model|child model\s*[\u2260!=]+\s*parent|filho\s*[\u2260!=]+\s*pai)'
$script:DoesNotDecideSpawnPattern = '(?i)does not decide spawn'
$script:AxisAPreservePattern = '(?i)(never remove spawn choice|Thin trivial exception intact)'
$script:AxisTokenPattern = '(?i)(Axis\s+\*{{0,2}}{0}\*{{0,2}}|\|\s*\*\*{0}\*\*\s*\|)'
$script:Utf8 = New-Object System.Text.UTF8Encoding $false

$script:RelativePaths = @(
    'core/skills/_shared/agents/SUBAGENT-MODEL.md',
    'core/skills/_shared/agents/SPAWN.md',
    'core/router/AGENTS.md',
    'core/policy/orchestrator-session.md'
)



function Get-ContractText {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )
    $path = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Fail -TestName 'Assert-InvocationAxesPreconditions' -Reason ("missing {0}" -f $RelativePath)
    }
    return [System.IO.File]::ReadAllText($path, $script:Utf8)
}

function Test-AxisTokenPresent {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $AxisLetter
    )
    $pattern = ($script:AxisTokenPattern -f $AxisLetter)
    return ($Text -match $pattern)
}



$texts = @{}
foreach ($rel in $script:RelativePaths) {
    $texts[$rel] = Get-ContractText -RepoRoot $repoRoot -RelativePath $rel
}

# --- Should_Pass_When_AxesNormativeProsePresentInContracts ---
$proseName = 'Should_Pass_When_AxesNormativeProsePresentInContracts'
foreach ($rel in $script:RelativePaths) {
    $text = $texts[$rel]
    if ($text -notmatch $script:AxesMarkerPattern) {
        Write-Fail -TestName $proseName -Reason ("{0} missing marker A!=B!=C / A≠B≠C" -f $rel)
    }
    if (-not (Test-AxisTokenPresent -Text $text -AxisLetter 'A')) {
        Write-Fail -TestName $proseName -Reason ("{0} missing Axis A token" -f $rel)
    }
    if (-not (Test-AxisTokenPresent -Text $text -AxisLetter 'B')) {
        Write-Fail -TestName $proseName -Reason ("{0} missing Axis B token" -f $rel)
    }
    if (-not (Test-AxisTokenPresent -Text $text -AxisLetter 'C')) {
        Write-Fail -TestName $proseName -Reason ("{0} missing Axis C token" -f $rel)
    }
}
Write-Pass -TestName $proseName

# --- Should_Pass_When_AxisASpawnChoicePreserved ---
$axisAName = 'Should_Pass_When_AxisASpawnChoicePreserved'
$spawnText = $texts['core/skills/_shared/agents/SPAWN.md']
$subagentText = $texts['core/skills/_shared/agents/SUBAGENT-MODEL.md']
if ($spawnText -notmatch [regex]::Escape($script:ThinTrivialMarker)) {
    Write-Fail -TestName $axisAName -Reason 'SPAWN.md missing Thin trivial exception (Axis A choice)'
}
if ($spawnText -notmatch [regex]::Escape($script:InParentMarker)) {
    Write-Fail -TestName $axisAName -Reason 'SPAWN.md missing in-parent path (Axis A choice)'
}
if ($spawnText -notmatch $script:AxisAPreservePattern) {
    Write-Fail -TestName $axisAName -Reason 'SPAWN.md missing explicit Axis A preservation wording'
}
if ($subagentText -notmatch $script:DoesNotDecideSpawnPattern) {
    Write-Fail -TestName $axisAName -Reason 'SUBAGENT-MODEL.md must state it does not decide spawn (A≠B)'
}
Write-Pass -TestName $axisAName

# --- Should_Pass_When_AxisBCModelLockPresent ---
$axisBCName = 'Should_Pass_When_AxisBCModelLockPresent'
if ($subagentText -notmatch [regex]::Escape($script:OmitModelMarker)) {
    Write-Fail -TestName $axisBCName -Reason 'SUBAGENT-MODEL.md missing omit model default (Axis B)'
}
if ($subagentText -notmatch $script:InheritOrSameMarkerPattern) {
    Write-Fail -TestName $axisBCName -Reason 'SUBAGENT-MODEL.md missing inherit/same-as-parent wording (Axis B)'
}
if ($subagentText -notmatch $script:SilenceNotApprovalPattern) {
    Write-Fail -TestName $axisBCName -Reason 'SUBAGENT-MODEL.md missing silence≠approval (Axis C)'
}
$policyText = $texts['core/policy/orchestrator-session.md']
if ($policyText -notmatch [regex]::Escape($script:OmitModelMarker)) {
    Write-Fail -TestName $axisBCName -Reason 'orchestrator-session.md missing omit model default (Axis B)'
}
if ($spawnText -notmatch $script:NoPinChildPattern) {
    Write-Fail -TestName $axisBCName -Reason 'SPAWN.md must forbid pin child≠parent (Axis B/C boundary)'
}
Write-Pass -TestName $axisBCName

# --- Should_Pass_When_SessionChoiceContractPresent ---
$sessionChoiceName = 'Should_Pass_When_SessionChoiceContractPresent'
foreach ($phrase in @(
    'Session choice (once per session)',
    'Native-session gate:',
    'They do not select `inherit` for the operator',
    'wait for an explicit answer',
    'The session choice is a blocking startup gate',
    'The default invocation rule below is not an implicit answer',
    'once per session',
    'not a question about whether to delegate',
    'At session start, before the active skill/task is processed',
    'Only the parent asks',
    'Extract and enumerate every literal value',
    '`SESSION_SCHEMA` / requestable',
    'never their assumed Cartesian product',
    'unconstrained string with no enum',
    'Disclose available model choices immediately before the model question',
    'disclose only its documented or observed support among',
    'If no model choice or no eligible effort can be discovered for the active surface',
    'Keep inheritance available',
    'a clarification does not reset its state',
    'do not replace it with a yes/no question',
    'never persisted',
    'SUBAGENT-OPTIONS.md',
    'live read-only model/effort choices',
    'ask for the model first using only choices exposed by the active adapter and surface',
    'show only the supported values among `low`, `medium`, and `high`',
    'Do not show a cartesian list of model/effort combinations or infer compatibility',
    'skip the effort question and continue by inheriting the parent''s model and effort',
    'subagents=none',
    'omit both',
    'one inheritance attempt',
    'compaction',
    'effort=unverified',
    'Requested, sent, and effective',
    'never contains preferences'
)) {
    if ($subagentText -notmatch [regex]::Escape($phrase)) {
        Write-Fail -TestName $sessionChoiceName -Reason ("SUBAGENT-MODEL.md missing session-choice contract phrase: {0}" -f $phrase)
    }
}
foreach ($phrase in @('alternate slug', 'extremely necessary', 'Different model', 'premium', 'inherit parent / Auto')) {
    if ($subagentText -match [regex]::Escape($phrase)) {
        Write-Fail -TestName $sessionChoiceName -Reason ("SUBAGENT-MODEL.md contains obsolete contract phrase: {0}" -f $phrase)
    }
}
if ($subagentText -match '(?i)\b(claude|gpt|gemini|grok|composer)-\S+') {
    Write-Fail -TestName $sessionChoiceName -Reason 'SUBAGENT-MODEL.md must not contain a model identifier'
}
Write-Pass -TestName $sessionChoiceName

}

$sections['SubagentSessionChoice'] = {
# Tests:
#   Should_Pass_When_SessionChoiceTextSatisfiesContract
#   Should_Fail_When_ModelCatalogWrittenInContract
#   Should_Fail_When_OmitBothSentenceRemoved
#   Should_Fail_When_ChildPromptProtectionRemoved
#   Should_Pass_When_ReceiptContractHasNoSessionFields
#   Should_Pass_When_PublishedAgentsInheritParentModel

function Test-SessionChoiceText {
    param([Parameter(Mandatory = $true)][string] $Text)
    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($phrase in @(
        'Session choice (once per session)',
        'three outcomes: `inherit`, `reuse_saved`, or `choose_model`',
        'revalidate the complete saved pair against the exact supported choices and encoding for the active adapter and surface',
        'Label a legacy value as a saved configuration',
        'The initial menu choice is never persisted',
        'After the parent has used the complete active pair',
        'An explicit confirmation that it worked is sufficient',
        'Only confirmation for the pair actually used authorizes a preference update',
        'Update only the existing `subagent_models.default` field',
        'do not request logs, captures, or another artifact',
        'restore the prior content',
        'Do not call it proven or previously confirmed',
        'Do not put an extended model/effort combination list in the initial question',
        'ask for the model first using only choices exposed by the active adapter and surface',
        'show only the supported values among `low`, `medium`, and `high`',
        'Do not show a cartesian list of model/effort combinations or infer compatibility',
        'skip the effort question and continue by inheriting the parent''s model and effort',
        'The operator confirms usable question components for Codex, Claude, Cursor, Hermes, and Copilot',
        'once per session',
        'not a question about whether to delegate',
        'At session start, before the active skill/task is processed',
        'Only the parent asks',
        'Extract and enumerate every literal value',
        '`SESSION_SCHEMA` / requestable',
        'never their assumed Cartesian product',
        'unconstrained string with no enum',
        'a clarification does not reset its state',
        'do not replace it with a yes/no question',
        'never persisted',
        'SUBAGENT-OPTIONS.md',
        'live read-only model/effort choices',
        'subagents=none',
        'omit both',
        'one inheritance attempt',
        'compaction',
        'effort=unverified',
        'Requested, sent, and effective',
        'never contains preferences',
        'Refusal and fallback',
        'refused context',
        'Non-interactive sessions'
    )) {
        if ($Text -notmatch [regex]::Escape($phrase)) {
            $failures.Add(("missing required phrase: {0}" -f $phrase))
        }
    }
    foreach ($phrase in @('alternate slug', 'extremely necessary', 'Different model', 'premium', 'inherit parent / Auto')) {
        if ($Text -match [regex]::Escape($phrase)) {
            $failures.Add(("contains obsolete phrase: {0}" -f $phrase))
        }
    }
    if ($Text -match '(?i)\b(claude|gpt|gemini|grok|composer)-\S+') {
        $failures.Add('contains a model identifier')
    }
    return $failures.ToArray()
}

$sessionChoicePath = Join-Path $repoRoot 'core/skills/_shared/agents/SUBAGENT-MODEL.md'
if (-not (Test-Path -LiteralPath $sessionChoicePath -PathType Leaf)) {
    Write-Fail -TestName 'Assert-SubagentSessionChoicePreconditions' -Reason 'SUBAGENT-MODEL.md is missing'
}
$sessionChoiceText = [System.IO.File]::ReadAllText($sessionChoicePath, [System.Text.UTF8Encoding]::new($false))

# --- US03 S1 initial-choice cases ---
$initialChoiceFixtureName = 'Should_Pass_When_Us03InitialChoiceFixturesMatchOracle'
$initialChoiceFixturePath = Join-Path $repoRoot 'scripts/validation/fixtures/subagent-session-choice/us03-initial-choice-cases.json'
if (-not (Test-Path -LiteralPath $initialChoiceFixturePath -PathType Leaf)) {
    Write-Fail -TestName $initialChoiceFixtureName -Reason 'US03 initial-choice fixture is missing'
}
$initialChoiceFixture = Get-Content -LiteralPath $initialChoiceFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
if ($initialChoiceFixture.schemaVersion -ne 1 -or @($initialChoiceFixture.cases).Count -ne 9) {
    Write-Fail -TestName $initialChoiceFixtureName -Reason 'US03 initial-choice fixture must have schemaVersion 1 and exactly nine cases'
}

function Resolve-Us03InitialChoice {
    param([Parameter(Mandatory = $true)][PSCustomObject] $Given)

    $optionIds = [System.Collections.Generic.List[string]]::new()
    $optionIds.Add('inherit')
    $hasReusablePair = $Given.savedPairState -eq 'complete' -and [bool]$Given.savedPairCompatible
    if ($hasReusablePair) { $optionIds.Add('reuse_saved') }
    $optionIds.Add('choose_model')

    $presentation = 'numbered'
    if ([bool]$Given.operatorReportedComponent -and [bool]$Given.answerObservable) { $presentation = 'component' }

    return [PSCustomObject]@{
        optionIds = @($optionIds.ToArray())
        savedLabel = if ($hasReusablePair) { 'saved configuration' } else { $null }
        savedCalledProven = $false
        presentation = $presentation
    }
}

foreach ($initialChoiceCase in $initialChoiceFixture.cases) {
    $caseName = 'Should_Pass_When_Us03InitialChoice_{0}' -f $initialChoiceCase.id
    $actualChoice = Resolve-Us03InitialChoice -Given $initialChoiceCase.given
    foreach ($field in $initialChoiceCase.expect.PSObject.Properties.Name) {
        if (-not $actualChoice.PSObject.Properties[$field]) {
            Write-Fail -TestName $caseName -Reason ('oracle omitted field: {0}' -f $field)
        }
        $expectedValue = ConvertTo-Json -InputObject $initialChoiceCase.expect.$field -Depth 8 -Compress
        $actualValue = ConvertTo-Json -InputObject $actualChoice.$field -Depth 8 -Compress
        if ($expectedValue -cne $actualValue) {
            Write-Fail -TestName $caseName -Reason ('{0}: expected {1}, got {2}' -f $field, $expectedValue, $actualValue)
        }
    }
    Write-Pass -TestName $caseName
}

$questionContractPath = Join-Path $repoRoot 'core/skills/_shared/agents/QUESTIONS.md'
$questionContractText = [System.IO.File]::ReadAllText($questionContractPath, [System.Text.UTF8Encoding]::new($false))
$questionMechanismName = 'Should_Pass_When_Us03QuestionComponentsAndFallbackAreScoped'
$questionMechanisms = @{
    codex = '`request_user_input_async`'
    claude = '`AskUserQuestion`'
    cursor = '`cursor/ask_question`'
    hermes = '`ask_user`'
}
foreach ($hostId in $questionMechanisms.Keys) {
    $mechanism = $questionMechanisms[$hostId]
    if ($questionContractText -notmatch ('\| `' + [regex]::Escape($hostId) + '` \| `' + [regex]::Escape($mechanism.Trim('`')) + '` \|')) {
        Write-Fail -TestName $questionMechanismName -Reason ('missing named question mechanism for {0}' -f $hostId)
    }
}
if ($questionContractText -notmatch '(?s)\| `copilot` \| `operator-confirmed component` \|.*?operator confirms the component is usable for US03 and its answer reaches the agent.*?Do not invent a tool name') {
    Write-Fail -TestName $questionMechanismName -Reason 'Copilot must use the operator-confirmed component without inventing its mechanism name'
}
if ($questionContractText -notmatch 'none` means no question component is confirmed') {
    Write-Fail -TestName $questionMechanismName -Reason 'missing unconfirmed-host numbered-text fallback rule'
}
if ($questionContractText -notmatch 'For US03, the operator confirms usable components on Codex, Claude, Cursor, Hermes, and Copilot. This does not extend to other hosts.') {
    Write-Fail -TestName $questionMechanismName -Reason 'operator-confirmed component scope is missing or extends beyond the five confirmed hosts'
}
foreach ($hostId in @('antigravity', 'opencode', 'openhands')) {
    if ($questionContractText -notmatch ('\| `' + [regex]::Escape($hostId) + '` \| `none` \|')) {
        Write-Fail -TestName $questionMechanismName -Reason ('unverified host must retain numbered-text fallback: {0}' -f $hostId)
    }
}
Write-Pass -TestName $questionMechanismName

# --- US03 S2 effort-filter cases ---
$effortFilterFixtureName = 'Should_Pass_When_Us03EffortFilterFixturesMatchOracle'
$effortFilterFixturePath = Join-Path $repoRoot 'scripts/validation/fixtures/subagent-session-choice/us03-effort-filter-cases.json'
if (-not (Test-Path -LiteralPath $effortFilterFixturePath -PathType Leaf)) {
    Write-Fail -TestName $effortFilterFixtureName -Reason 'US03 effort-filter fixture is missing'
}
$effortFilterFixture = Get-Content -LiteralPath $effortFilterFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
if ($effortFilterFixture.schemaVersion -ne 1 -or @($effortFilterFixture.cases).Count -ne 3) {
    Write-Fail -TestName $effortFilterFixtureName -Reason 'US03 effort-filter fixture must have schemaVersion 1 and exactly three cases'
}

function Resolve-Us03EffortChoices {
    param([Parameter(Mandatory = $true)][PSCustomObject] $Given)

    $supportedEfforts = @($Given.supportedEfforts | ForEach-Object { [string]$_ })
    $allowedEfforts = @('low', 'medium', 'high')
    $effortOptions = @($allowedEfforts | Where-Object { $_ -in $supportedEfforts })
    return [PSCustomObject]@{
        effortOptions = @($effortOptions)
        nextAction = if ($effortOptions.Count -gt 0) { 'ask_effort' } else { 'inherit' }
    }
}

foreach ($effortFilterCase in $effortFilterFixture.cases) {
    $caseName = 'Should_Pass_When_Us03EffortFilter_{0}' -f $effortFilterCase.id
    $actualEffortChoices = Resolve-Us03EffortChoices -Given $effortFilterCase.given
    foreach ($field in $effortFilterCase.expect.PSObject.Properties.Name) {
        $expectedValue = ConvertTo-Json -InputObject $effortFilterCase.expect.$field -Depth 8 -Compress
        $actualValue = ConvertTo-Json -InputObject $actualEffortChoices.$field -Depth 8 -Compress
        if ($expectedValue -cne $actualValue) {
            Write-Fail -TestName $caseName -Reason ('{0}: expected {1}, got {2}' -f $field, $expectedValue, $actualValue)
        }
    }
    Write-Pass -TestName $caseName
}

$effortOptionsContract = "ask for the model first using only choices exposed by the active adapter and surface`n" +
    'show only the supported values among `low`, `medium`, and `high`' + "`n" +
    'Do not show a cartesian list of model/effort combinations or infer compatibility' + "`n" +
    'skip the effort question and continue by inheriting the parent''s model and effort'
if (-not $sessionChoiceText.Contains($effortOptionsContract.Split("`n")[0]) -or
    -not $sessionChoiceText.Contains($effortOptionsContract.Split("`n")[1]) -or
    -not $sessionChoiceText.Contains($effortOptionsContract.Split("`n")[2]) -or
    -not $sessionChoiceText.Contains($effortOptionsContract.Split("`n")[3])) {
    Write-Fail -TestName 'Should_Pass_When_Us03EffortPromptIsModelSpecificAndFiltered' -Reason 'session-choice contract must specify model-first filtering and inheritance on an empty result'
}
Write-Pass -TestName 'Should_Pass_When_Us03EffortPromptIsModelSpecificAndFiltered'

# --- US03 S3 saved-pair reuse cases ---
$savedPairFixtureName = 'Should_Pass_When_Us03SavedPairFixturesMatchOracle'
$savedPairFixturePath = Join-Path $repoRoot 'scripts/validation/fixtures/subagent-session-choice/us03-saved-pair-reuse-cases.json'
if (-not (Test-Path -LiteralPath $savedPairFixturePath -PathType Leaf)) {
    Write-Fail -TestName $savedPairFixtureName -Reason 'US03 saved-pair reuse fixture is missing'
}
$savedPairFixture = Get-Content -LiteralPath $savedPairFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
if ($savedPairFixture.schemaVersion -ne 1 -or @($savedPairFixture.cases).Count -ne 6) {
    Write-Fail -TestName $savedPairFixtureName -Reason 'US03 saved-pair fixture must have schemaVersion 1 and exactly six cases'
}

function Resolve-Us03SavedPairReuse {
    param([Parameter(Mandatory = $true)][PSCustomObject] $Given)

    $savedModelProperty = if ($Given.savedPair) { $Given.savedPair.PSObject.Properties['model'] } else { $null }
    $savedEffortProperty = if ($Given.savedPair) { $Given.savedPair.PSObject.Properties['effort'] } else { $null }
    $savedModel = if ($savedModelProperty) { [string]$savedModelProperty.Value } else { '' }
    $savedEffort = if ($savedEffortProperty) { [string]$savedEffortProperty.Value } else { '' }
    $isCompletePair = -not [string]::IsNullOrWhiteSpace($savedModel) -and -not [string]::IsNullOrWhiteSpace($savedEffort)
    $supportedPair = @($Given.supportedPairs | Where-Object {
        [string]$_.model -ceq $savedModel -and [string]$_.effort -ceq $savedEffort
    })
    $canReuse = [bool]$Given.preferenceReadable -and $isCompletePair -and $supportedPair.Count -gt 0

    $optionIds = [System.Collections.Generic.List[string]]::new()
    $optionIds.Add('inherit')
    if ($canReuse) { $optionIds.Add('reuse_saved') }
    $optionIds.Add('choose_model')

    $route = 'inherit'
    $appliedPair = $null
    $inheritanceRetryCount = 0
    $fallbackUsed = $false
    $nextAction = 'continue'
    if ([string]$Given.selection -eq 'reuse_saved' -and $canReuse) {
        $route = 'reuse_saved'
        $appliedPair = [PSCustomObject]@{ model = $savedModel; effort = $savedEffort }
        if ([bool]$Given.hostRefusesSavedPair) {
            $route = 'inherit_fallback'
            $appliedPair = $null
            $inheritanceRetryCount = 1
            $fallbackUsed = $true
            if ([bool]$Given.hostRefusesInheritance) { $nextAction = 'blocked' }
        }
    }

    return [PSCustomObject]@{
        optionIds = @($optionIds.ToArray())
        route = $route
        appliedPair = $appliedPair
        inheritanceRetryCount = $inheritanceRetryCount
        fallbackUsed = $fallbackUsed
        preferencePreserved = $true
        preferenceWrites = 0
        nextAction = $nextAction
    }
}

foreach ($savedPairCase in $savedPairFixture.cases) {
    $caseName = 'Should_Pass_When_Us03SavedPairReuse_{0}' -f $savedPairCase.id
    $actualReuse = Resolve-Us03SavedPairReuse -Given $savedPairCase.given
    foreach ($field in $savedPairCase.expect.PSObject.Properties.Name) {
        if (-not $actualReuse.PSObject.Properties[$field]) {
            Write-Fail -TestName $caseName -Reason ('oracle omitted field: {0}' -f $field)
        }
        $expectedValue = ConvertTo-Json -InputObject $savedPairCase.expect.$field -Depth 8 -Compress
        $actualValue = ConvertTo-Json -InputObject $actualReuse.$field -Depth 8 -Compress
        if ($expectedValue -cne $actualValue) {
            Write-Fail -TestName $caseName -Reason ('{0}: expected {1}, got {2}' -f $field, $expectedValue, $actualValue)
        }
    }
    Write-Pass -TestName $caseName
}

$savedPairOptionsPath = Join-Path $repoRoot 'core/skills/_shared/agents/SUBAGENT-OPTIONS.md'
$savedPairOptionsText = [System.IO.File]::ReadAllText($savedPairOptionsPath, [System.Text.UTF8Encoding]::new($false))
$savedPairContract = @(
    'Before showing `reuse_saved`, revalidate the complete saved pair against the exact supported choices and encoding for the active adapter and surface',
    'If the preference is unreadable, incomplete, or incompatible, omit `reuse_saved`, preserve the saved content',
    'If the host refuses a reused pair, make one inheritance attempt that omits both parameters',
    'the preference has no stored adapter/surface provenance'
)
foreach ($phrase in $savedPairContract[0..2]) {
    if (-not $sessionChoiceText.Contains($phrase)) {
        Write-Fail -TestName 'Should_Pass_When_SavedPairReuseIsRevalidatedAndPreserved' -Reason ('missing reuse safety rule: {0}' -f $phrase)
    }
}
if (-not $savedPairOptionsText.Contains($savedPairContract[3])) {
    Write-Fail -TestName 'Should_Pass_When_SavedPairReuseIsRevalidatedAndPreserved' -Reason 'preference provenance limitation is missing'
}
Write-Pass -TestName 'Should_Pass_When_SavedPairReuseIsRevalidatedAndPreserved'

# --- US03 S4 confirmed-use write cases ---
$confirmedUseFixtureName = 'Should_Pass_When_Us03PreferenceWriteRequiresConfirmedUse'
$confirmedUseFixturePath = Join-Path $repoRoot 'scripts/validation/fixtures/subagent-session-choice/us03-confirmed-use-save-cases.json'
if (-not (Test-Path -LiteralPath $confirmedUseFixturePath -PathType Leaf)) {
    Write-Fail -TestName $confirmedUseFixtureName -Reason 'US03 confirmed-use fixture is missing'
}
$confirmedUseFixture = Get-Content -LiteralPath $confirmedUseFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
if ($confirmedUseFixture.schemaVersion -ne 1 -or @($confirmedUseFixture.cases).Count -ne 4) {
    Write-Fail -TestName $confirmedUseFixtureName -Reason 'US03 confirmed-use fixture must have schemaVersion 1 and exactly four cases'
}

function Resolve-Us03ConfirmedUseWrite {
    param([Parameter(Mandatory = $true)][PSCustomObject] $Given)
    $saveRequested = [bool]$Given.pairWasUsed -and [bool]$Given.explicitConfirmation
    $result = if (-not $saveRequested) { 'not-confirmed-use' } elseif ([bool]$Given.simulateWriteFailure) { 'reread-mismatch' } else { 'saved' }
    return [PSCustomObject]@{
        saveRequested = $saveRequested
        field = if ($saveRequested) { 'subagent_models.default' } else { $null }
        historyWritten = $false
        priorPreferencePreserved = -not $saveRequested -or [bool]$Given.simulateWriteFailure
        result = $result
        restored = [bool]$Given.simulateWriteFailure
    }
}

foreach ($confirmedUseCase in $confirmedUseFixture.cases) {
    $caseName = 'Should_Pass_When_Us03ConfirmedUse_{0}' -f $confirmedUseCase.id
    $actualUpdate = Resolve-Us03ConfirmedUseWrite -Given $confirmedUseCase.given
    foreach ($field in $confirmedUseCase.expect.PSObject.Properties.Name) {
        if (-not $actualUpdate.PSObject.Properties[$field]) {
            Write-Fail -TestName $caseName -Reason ('oracle omitted field: {0}' -f $field)
        }
        $expectedValue = ConvertTo-Json -InputObject $confirmedUseCase.expect.$field -Depth 8 -Compress
        $actualValue = ConvertTo-Json -InputObject $actualUpdate.$field -Depth 8 -Compress
        if ($expectedValue -cne $actualValue) {
            Write-Fail -TestName $caseName -Reason ('{0}: expected {1}, got {2}' -f $field, $expectedValue, $actualValue)
        }
    }
    Write-Pass -TestName $caseName
}
$preferencesSkillPath = Join-Path $repoRoot 'core/skills/adt-settings/SKILL.md'
$preferencesSkillText = [System.IO.File]::ReadAllText($preferencesSkillPath, [System.Text.UTF8Encoding]::new($false))
if ($preferencesSkillText -notmatch 'US03 session flow may update the same field only after the parent used the complete active pair') {
    Write-Fail -TestName $confirmedUseFixtureName -Reason 'adt-settings compatibility with the US03 confirmed-use update is missing'
}
Write-Pass -TestName $confirmedUseFixtureName

# --- US03 S5 published contract parity ---
$us03PublicationName = 'Should_Pass_When_Us03PublishedContractsMatchCurrentFlow'
$publishHonestyPath = Join-Path $repoRoot 'adapters/_shared/spawn-publish-honesty.md'
$adapterReadmePath = Join-Path $repoRoot 'adapters/README.md'
foreach ($requiredPath in @($publishHonestyPath, $adapterReadmePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail -TestName $us03PublicationName -Reason ('publication contract is missing: {0}' -f $requiredPath)
    }
}
$publishHonestyText = [System.IO.File]::ReadAllText($publishHonestyPath, [System.Text.UTF8Encoding]::new($false))
$adapterReadmeText = [System.IO.File]::ReadAllText($adapterReadmePath, [System.Text.UTF8Encoding]::new($false))
foreach ($phrase in @(
    'Session configuration choice (US03)',
    'reuse the saved configuration when its complete pair is eligible',
    'ask for the model first',
    'supported values among `low`, `medium`, and `high`',
    'never list model/effort combinations',
    'Other hosts remain unverified and retain numbered-text fallback'
)) {
    if (-not $publishHonestyText.Contains($phrase)) {
        Write-Fail -TestName $us03PublicationName -Reason ('publish honesty contract is missing: {0}' -f $phrase)
    }
}
if ($publishHonestyText.Contains('initial question lists concrete complete pairs') -or $publishHonestyText.Contains('Session pair choice (US01)')) {
    Write-Fail -TestName $us03PublicationName -Reason 'stale US01 pair-list publication rule remains'
}
foreach ($phrase in @(
    '| Cursor | `cursor/ask_question` for US03',
    '| Claude Code | `AskUserQuestion` when its selected answer returns to the agent; the operator confirms a usable component for US03.',
    '| Codex | `request_user_input_async`',
    '| GitHub Copilot | Operator confirms a usable question component for US03',
    '| Hermes | `ask_user` when its selected answer returns to the agent; the operator confirms a usable component for US03.'
)) {
    if (-not $adapterReadmeText.Contains($phrase)) {
        Write-Fail -TestName $us03PublicationName -Reason ('adapter question publication is missing: {0}' -f $phrase)
    }
}
foreach ($hostId in @('antigravity', 'opencode', 'openhands')) {
    if ($questionContractText -notmatch ('\| `' + [regex]::Escape($hostId) + '` \| `none` \|')) {
        Write-Fail -TestName $us03PublicationName -Reason ('unconfirmed host lost numbered-text fallback: {0}' -f $hostId)
    }
}
Write-Pass -TestName $us03PublicationName

# --- Should_Pass_When_SessionChoiceTextSatisfiesContract ---
$positiveName = 'Should_Pass_When_SessionChoiceTextSatisfiesContract'
$positiveFailures = @(Test-SessionChoiceText -Text $sessionChoiceText)
if ($positiveFailures.Count -gt 0) {
    Write-Fail -TestName $positiveName -Reason ($positiveFailures -join '; ')
}
Write-Pass -TestName $positiveName

# --- Should_Pass_When_AllAdapterDiscoveryPathsHaveHonestFallbacks ---
$adapterDiscoveryName = 'Should_Pass_When_AllAdapterDiscoveryPathsHaveHonestFallbacks'
$adapterOptionsPath = Join-Path $repoRoot 'core/skills/_shared/agents/SUBAGENT-OPTIONS.md'
$adapterOptionsText = [System.IO.File]::ReadAllText($adapterOptionsPath, [System.Text.UTF8Encoding]::new($false))
$adapterRequirements = @(
    @{ id = 'ADP-CLAUDE'; markers = @('/model', '/effort', 'Agent` invocation schema', 'offer `inherit` only') },
    @{ id = 'ADP-CODEX'; markers = @('collaboration.spawn_agent', 'reasoning_effort', 'DOCUMENTED` / requestable', 'runtime UNKNOWN') },
    @{ id = 'ADP-CURSOR'; markers = @('Cursor.models.list()', 'model-id[param=value]', 'offer `inherit` only') },
    @{ id = 'ADP-HERMES'; markers = @('delegate_task', 'model_map', 'option`', 'inherit only') },
    @{ id = 'ADP-COPILOT'; markers = @('/model', '/subagents', 'reasoningEffort', 'IDE/cloud inherit-only') }
)
foreach ($adapterRequirement in $adapterRequirements) {
    $adapterRow = @($adapterOptionsText -split "`r?`n" | Where-Object { $_.StartsWith('| ' + $adapterRequirement.id + ' |') })
    if ($adapterRow.Count -ne 1) {
        Write-Fail -TestName $adapterDiscoveryName -Reason ('expected one matrix row for {0}' -f $adapterRequirement.id)
        continue
    }
    foreach ($marker in $adapterRequirement.markers) {
        if ($adapterRow[0] -notmatch [regex]::Escape($marker)) {
            Write-Fail -TestName $adapterDiscoveryName -Reason ('{0} is missing discovery/fallback marker: {1}' -f $adapterRequirement.id, $marker)
        }
    }
}
Write-Pass -TestName $adapterDiscoveryName

# --- Should_Fail_When_ModelCatalogWrittenInContract ---
$n1Name = 'Should_Fail_When_ModelCatalogWrittenInContract'
$n1Text = $sessionChoiceText + "`n| claude-opus-x | high |"
$n1Failures = @(Test-SessionChoiceText -Text $n1Text)
if (@($n1Failures | Where-Object { $_ -eq 'contains a model identifier' }).Count -eq 0) {
    Write-Fail -TestName $n1Name -Reason 'expected a model-identifier failure for the in-memory duplicate catalog'
}
Write-Pass -TestName $n1Name

# --- Should_Fail_When_OmitBothSentenceRemoved ---
$n2Name = 'Should_Fail_When_OmitBothSentenceRemoved'
$n2Text = $sessionChoiceText.Replace('omit both', 'omit one')
$n2Failures = @(Test-SessionChoiceText -Text $n2Text)
if ($n2Text -ceq $sessionChoiceText -or @($n2Failures | Where-Object { $_ -eq 'missing required phrase: omit both' }).Count -eq 0) {
    Write-Fail -TestName $n2Name -Reason 'expected the missing omit-both phrase failure for the in-memory partial-argument mutation'
}
Write-Pass -TestName $n2Name

# --- Should_Fail_When_ChildPromptProtectionRemoved ---
$n3Name = 'Should_Fail_When_ChildPromptProtectionRemoved'
$n3Text = $sessionChoiceText.Replace('never contains preferences', 'may contain preferences')
$n3Failures = @(Test-SessionChoiceText -Text $n3Text)
if ($n3Text -ceq $sessionChoiceText -or @($n3Failures | Where-Object { $_ -eq 'missing required phrase: never contains preferences' }).Count -eq 0) {
    Write-Fail -TestName $n3Name -Reason 'expected the missing protected-data phrase failure for the in-memory prompt mutation'
}
Write-Pass -TestName $n3Name

# --- Should_Pass_When_ReceiptContractHasNoSessionFields ---
$receiptName = 'Should_Pass_When_ReceiptContractHasNoSessionFields'
$receiptPath = Join-Path $repoRoot 'core/skills/_shared/agents/RECEIPT.md'
$receiptValidatorPath = Join-Path $repoRoot 'scripts/validation/Invoke-O3ReceiptValidation.ps1'
if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf) -or -not (Test-Path -LiteralPath $receiptValidatorPath -PathType Leaf)) {
    Write-Fail -TestName $receiptName -Reason 'receipt contract or validator is missing'
}
$receiptText = [System.IO.File]::ReadAllText($receiptPath, [System.Text.UTF8Encoding]::new($false))
if ($receiptText -match '(?i)\b(session choice|subagent_models)\b') {
    Write-Fail -TestName $receiptName -Reason 'RECEIPT.md must not add a session-choice or preference field'
}
$receiptValidatorText = [System.IO.File]::ReadAllText($receiptValidatorPath, [System.Text.UTF8Encoding]::new($false))
$requiredAllowlistLine = "`$required = @('planPath','step','status','files','testsSummary')"
if (-not $receiptValidatorText.Contains($requiredAllowlistLine)) {
    Write-Fail -TestName $receiptName -Reason 'O3 receipt validator allowlist changed'
}
Write-Pass -TestName $receiptName

# --- Should_Pass_When_PublishedAgentsInheritParentModel ---
$inheritanceName = 'Should_Pass_When_PublishedAgentsInheritParentModel'
$agentsPath = Join-Path $repoRoot 'core/agents'
if (-not (Test-Path -LiteralPath $agentsPath -PathType Container)) {
    Write-Fail -TestName $inheritanceName -Reason 'core/agents directory is missing'
}
$agentFiles = @(Get-ChildItem -LiteralPath $agentsPath -Filter '*.md' -File)
if ($agentFiles.Count -eq 0) {
    Write-Fail -TestName $inheritanceName -Reason 'core/agents contains no markdown agents'
}
foreach ($agentFile in $agentFiles) {
    $agentText = [System.IO.File]::ReadAllText($agentFile.FullName, [System.Text.UTF8Encoding]::new($false))
    if ($agentText -match '(?m)^model:\s*(?!inherit\s*$)\S') {
        Write-Fail -TestName $inheritanceName -Reason ("{0} pins a model outside inherit" -f $agentFile.Name)
    }
    if ($agentText -match '(?m)^effort:') {
        Write-Fail -TestName $inheritanceName -Reason ("{0} pins an effort value" -f $agentFile.Name)
    }
}
Write-Pass -TestName $inheritanceName

# --- Should_Pass_When_DecisionCase_DCxx ---
$decisionFixtureName = 'Should_Pass_When_SessionDecisionFixturesMatchOracle'
$decisionFixturePath = Join-Path $repoRoot 'scripts/validation/fixtures/subagent-session-choice/decision-cases.json'
if (-not (Test-Path -LiteralPath $decisionFixturePath -PathType Leaf)) {
    Write-Fail -TestName $decisionFixtureName -Reason 'decision fixture JSON is missing'
}
$decisionFixture = Get-Content -LiteralPath $decisionFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
if ($decisionFixture.schemaVersion -ne 1 -or @($decisionFixture.cases).Count -ne 21) {
    Write-Fail -TestName $decisionFixtureName -Reason 'decision fixture must have schemaVersion 1 and exactly 21 cases'
}

function Resolve-SessionDecision {
    param([Parameter(Mandatory = $true)][PSCustomObject] $Given)

    $questionsAsked = 0
    $warnings = 0
    $inheritanceAttempts = 0
    $workflowFallbackUsed = $false
    $spawnsBlockedUntilAnswer = $false
    $paramsSentPerSpawn = [System.Collections.Generic.List[string]]::new()
    $taskComplete = [System.Collections.Generic.List[bool]]::new()
    $sessionChoice = 'inherit'
    $pairRefusedInContext = $false
    $retryPending = $false
    $postRefusalHandled = $false

    $availablePairs = @()
    if ($Given.PSObject.Properties['availablePairs']) {
        $availablePairs = @($Given.availablePairs | ForEach-Object { [string]$_ })
    }
    $schemaDiscovery = $null
    $schemaDisclosure = $null
    if ($Given.PSObject.Properties['codexSchema']) {
        $modelEnum = @($Given.codexSchema.modelEnum | ForEach-Object { [string]$_ })
        $effortEnum = @($Given.codexSchema.reasoningEffortEnum | ForEach-Object { [string]$_ })
        $schemaPairs = [System.Collections.Generic.List[string]]::new()
        $compatiblePairs = @()
        if ($Given.codexSchema.PSObject.Properties['compatiblePairs']) {
            $compatiblePairs = @($Given.codexSchema.compatiblePairs)
        }
        foreach ($candidate in $compatiblePairs) {
            $model = [string]$candidate.model
            $effort = [string]$candidate.reasoning_effort
            if ($model -in $modelEnum -and $effort -in $effortEnum) {
                $schemaPairs.Add(($model + '|' + $effort))
            }
        }
        $documentedEffortsByModel = [ordered]@{}
        if ($Given.codexSchema.PSObject.Properties['documentedEffortsByModel']) {
            foreach ($modelProperty in $Given.codexSchema.documentedEffortsByModel.PSObject.Properties) {
                $model = [string]$modelProperty.Name
                if ($model -notin $modelEnum) { continue }
                foreach ($effort in @($modelProperty.Value | ForEach-Object { [string]$_ })) {
                    if ($effortEnum.Count -eq 0 -or $effort -in $effortEnum) {
                        $candidatePair = $model + '|' + $effort
                        if ($candidatePair -notin $schemaPairs) { $schemaPairs.Add($candidatePair) }
                    }
                }
                $documentedEffortsByModel[$model] = @($modelProperty.Value | ForEach-Object { [string]$_ })
            }
        }
        $availablePairs = @($schemaPairs.ToArray())
        $schemaDiscovery = [ordered]@{
            modelEnum = @($modelEnum)
            reasoningEffortEnum = @($effortEnum)
            documentedEffortsByModel = [PSCustomObject]$documentedEffortsByModel
            candidatePairs = @($availablePairs)
            candidatePairCount = $availablePairs.Count
            evidence = 'SESSION_SCHEMA/requestable'
            modelEvidence = 'SESSION_SCHEMA/requestable'
            effortEvidence = 'DOCUMENTED/requestable; runtime-unverified'
        }
        $modelValuesText = if ($modelEnum.Count -gt 0) { $modelEnum -join ', ' } else { 'none exposed' }
        $effortValuesText = if ($effortEnum.Count -gt 0) { $effortEnum -join ', ' } else { 'none exposed' }
        $pairValuesText = if ($availablePairs.Count -gt 0) { $availablePairs -join ', ' } else { 'none established' }
        if ($effortEnum.Count -gt 0) {
            $schemaDisclosure = ('model enum: {0}; reasoning_effort enum: {1}; compatible pairs: {2}; evidence: SESSION_SCHEMA/requestable, not runtime-verified' -f $modelValuesText, $effortValuesText, $pairValuesText)
        } else {
            $schemaDisclosure = ('model enum: {0}; reasoning_effort enum: {1}; documented compatible pairs: {2}; evidence: model SESSION_SCHEMA/requestable; effort DOCUMENTED/requestable; runtime-unverified' -f $modelValuesText, $effortValuesText, $pairValuesText)
        }
    }
    $observedPairs = @($availablePairs)
    $pairSupported = $true
    if ($Given.PSObject.Properties['pairSupported']) { $pairSupported = [bool]$Given.pairSupported }
    $referenceAvailable = [bool]$Given.referenceReadable -and $availablePairs.Count -gt 0
    if (-not $referenceAvailable -or -not $pairSupported) { $availablePairs = @() }
    $questionOptions = @('inherit') + $availablePairs
    if ($availablePairs.Count -gt 4) { $questionOptions = @('inherit', 'pair') }
    $verifiedQuestionHosts = @('claude', 'grok', 'zcode', 'hermes')
    $hasVerifiedQuestionComponent = $false
    if ($Given.PSObject.Properties['host'] -and [string]$Given.host -in $verifiedQuestionHosts) {
        $hasVerifiedQuestionComponent = $true
    }
    if ($Given.PSObject.Properties['answerComponent'] -and -not [bool]$Given.answerComponent) {
        $hasVerifiedQuestionComponent = $false
    }
    $questionPresentation = if ($hasVerifiedQuestionComponent) { 'question-component' } else { 'numbered-text' }
    $questionText = $null
    $candidateSelectionOptions = @()
    $candidateListDisplayed = $false
    $pendingAfterPairChoice = $false
    $candidateSelectionPresentation = 'none'
    $candidateSelectionText = $null
    $followupQuestionEmissions = 0
    if ($availablePairs.Count -gt 4) {
        $candidateListDisplayed = $Given.answer -eq 'pair' -and $availablePairs.Count -gt 0
        if (-not $hasVerifiedQuestionComponent) {
            $questionText = "Subagent model and effort choice:`n1. Inherit the parent session model and effort`n2. Choose an alternate model and effort pair"
        }
        if ($candidateListDisplayed) {
            $candidateSelectionOptions = @($availablePairs)
            $candidateSelectionPresentation = 'numbered-text'
            $pendingAfterPairChoice = $availablePairs.Count -gt 0
            $followupQuestionEmissions = 1
            $candidateLines = for ($candidateIndex = 0; $candidateIndex -lt $candidateSelectionOptions.Count; $candidateIndex++) {
                '{0}. {1}' -f ($candidateIndex + 1), $candidateSelectionOptions[$candidateIndex]
            }
            $candidateSelectionText = "Choose a documented model-effort pair (runtime unverified):`n" + ($candidateLines -join "`n")
        }
    }

    if ($Given.subagents -eq 'none') {
        $workflowFallbackUsed = $true
        $result = [ordered]@{
            questionsAsked = 0
            spawnsBlockedUntilAnswer = $false
            paramsSentPerSpawn = @()
            warnings = 0
            inheritanceAttempts = 0
            preferencesWritten = $false
            taskComplete = @()
            workflowFallbackUsed = $true
            questionOptions = @()
            questionEmissions = 0
            followupQuestionEmissions = 0
            pendingAfterClarification = $false
        }
        return [PSCustomObject]$result
    }

    $validExplicitPair = $false
    if ($Given.request -eq 'invalid-pair' -or $Given.request -eq 'partial-pair') {
        $warnings++
    } elseif ($Given.request -eq 'valid-pair') {
        $requestedPairId = ''
        if ($Given.PSObject.Properties['requestedPairId']) { $requestedPairId = [string]$Given.requestedPairId }
        $validExplicitPair = $referenceAvailable -and $pairSupported -and $requestedPairId -and ($requestedPairId -in $availablePairs)
        if ($validExplicitPair) {
            $sessionChoice = 'pair'
        } else {
            $warnings++
        }
    }

    if (-not $validExplicitPair) {
        if ($Given.interactive) { $questionsAsked = 1 }
        if ($Given.answer -in $availablePairs) {
            $sessionChoice = 'pair'
        } elseif ($Given.answer -eq 'pair' -and $pendingAfterPairChoice) {
            $spawnsBlockedUntilAnswer = $true
        } elseif ($Given.answer -eq 'pair' -or $Given.answer -in $observedPairs) {
            $warnings++
            $sessionChoice = 'inherit'
        } else {
            $sessionChoice = 'inherit'
        }
    }

    $pendingAfterClarification = $Given.answer -eq 'clarification' -and $Given.interactive
    if (($Given.answer -eq 'silence' -or $pendingAfterClarification) -and $Given.interactive) {
        $spawnsBlockedUntilAnswer = $true
    }

    $promptMode = 'none'
    if ($questionsAsked -gt 0) {
        if ($hasVerifiedQuestionComponent) { $promptMode = 'native' }
        else { $promptMode = 'numbered' }
    }

    if (-not $spawnsBlockedUntilAnswer) {
        foreach ($outcome in @($Given.hostOutcomes)) {
            $parameterChoice = if ($sessionChoice -eq 'pair' -and -not $pairRefusedInContext) { 'pair' } else { 'none' }
            $paramsSentPerSpawn.Add($parameterChoice)

            if ($outcome -eq 'refuse-pair' -and $parameterChoice -eq 'pair') {
                $inheritanceAttempts++
                $pairRefusedInContext = $true
                $retryPending = $true
                continue
            }
            if ($outcome -eq 'refuse-inherit' -and $parameterChoice -eq 'none') {
                $workflowFallbackUsed = $true
                $taskComplete.Add($false)
                $retryPending = $false
                continue
            }
            if ($outcome -eq 'ok') {
                $taskComplete.Add($true)
                if ($retryPending) {
                    $retryPending = $false
                    if (-not $postRefusalHandled -and $Given.PSObject.Properties['postRefusalRequest'] -and $Given.postRefusalRequest -eq 'same-pair') {
                        $postRefusalHandled = $true
                        if ($Given.contextChange) {
                            $pairRefusedInContext = $false
                        } else {
                            $warnings++
                        }
                    }
                }
            }
        }
    }

    $result = [ordered]@{
        questionsAsked = $questionsAsked
        spawnsBlockedUntilAnswer = $spawnsBlockedUntilAnswer
        paramsSentPerSpawn = @($paramsSentPerSpawn.ToArray())
        warnings = $warnings
        inheritanceAttempts = $inheritanceAttempts
        preferencesWritten = $false
        taskComplete = @($taskComplete.ToArray())
        workflowFallbackUsed = $workflowFallbackUsed
        questionEmissions = $questionsAsked + $followupQuestionEmissions
        followupQuestionEmissions = $followupQuestionEmissions
        pendingAfterClarification = $pendingAfterClarification
        questionPresentation = $questionPresentation
        questionOptionsCount = $questionOptions.Count
        candidateListDisplayed = $candidateListDisplayed
        candidateSelectionOptions = @($candidateSelectionOptions)
        candidateSelectionOptionsCount = $candidateSelectionOptions.Count
        candidateSelectionPresentation = $candidateSelectionPresentation
        pendingAfterPairChoice = $pendingAfterPairChoice
        candidateSelectionTextLineCount = if ($null -ne $candidateSelectionText) { @($candidateSelectionText -split "`r?`n").Count } else { 0 }
    }
    if ($questionsAsked -gt 0) { $result['promptMode'] = $promptMode }
    if ($Given.PSObject.Properties['availablePairs'] -or $Given.PSObject.Properties['codexSchema']) { $result['questionOptions'] = @($questionOptions) }
    if ($null -ne $questionText) { $result['questionText'] = $questionText }
    if ($null -ne $candidateSelectionText) { $result['candidateSelectionText'] = $candidateSelectionText }
    if ($null -ne $schemaDiscovery) {
        $result['schemaDiscovery'] = [PSCustomObject]$schemaDiscovery
        $result['schemaDisclosure'] = $schemaDisclosure
    }
    return [PSCustomObject]$result
}

$expectedDecisionIds = @(1..21 | ForEach-Object { 'DC-{0:D2}' -f $_ })
$actualDecisionIds = @($decisionFixture.cases | ForEach-Object { [string]$_.id })
if (($actualDecisionIds -join '|') -cne ($expectedDecisionIds -join '|')) {
    Write-Fail -TestName $decisionFixtureName -Reason 'decision fixture ids are missing, duplicated, or out of order'
}
foreach ($decisionCase in $decisionFixture.cases) {
    $caseName = 'Should_Pass_When_DecisionCase_{0}' -f $decisionCase.id
    $requiredGivenFields = @('subagents', 'interactive', 'savedDefault', 'request', 'answer', 'referenceReadable', 'hostOutcomes', 'spawnsBeforeAnswer', 'compaction', 'contextChange')
    foreach ($field in $requiredGivenFields) {
        if (-not $decisionCase.given.PSObject.Properties[$field]) {
            Write-Fail -TestName $caseName -Reason ('missing given field: {0}' -f $field)
        }
    }
    if ($decisionCase.given.PSObject.Properties['roles']) {
        $roles = @($decisionCase.given.roles | ForEach-Object { [string]$_ })
        $distinctRoles = @($roles | Sort-Object -Unique)
        if ($roles.Count -ne @($decisionCase.given.hostOutcomes).Count -or $distinctRoles.Count -ne $roles.Count) {
            Write-Fail -TestName $caseName -Reason 'roles must be distinct and align with the modeled spawn sequence'
        }
    }
    try {
        $actualDecision = Resolve-SessionDecision -Given $decisionCase.given
    } catch {
        Write-Fail -TestName $caseName -Reason ('oracle error: {0}' -f $_.Exception.Message)
    }
    foreach ($field in $decisionCase.expect.PSObject.Properties.Name) {
        if ($field -eq 'candidateSelectionTextStartsWith') {
            if (-not [string]$actualDecision.candidateSelectionText.StartsWith([string]$decisionCase.expect.$field, [System.StringComparison]::Ordinal)) {
                Write-Fail -TestName $caseName -Reason ('candidateSelectionText did not start with expected numbered-list header')
            }
            continue
        }
        if ($field -eq 'candidateSelectionTextEndsWith') {
            if (-not [string]$actualDecision.candidateSelectionText.EndsWith([string]$decisionCase.expect.$field, [System.StringComparison]::Ordinal)) {
                Write-Fail -TestName $caseName -Reason ('candidateSelectionText did not end with the last expected numbered pair')
            }
            continue
        }
        if ($field -eq 'questionOptionsInclude') {
            foreach ($option in @($decisionCase.expect.$field)) {
                if ($option -notin @($actualDecision.questionOptions)) {
                    Write-Fail -TestName $caseName -Reason ('questionOptions did not include expected candidate: {0}' -f $option)
                }
            }
            continue
        }
        if ($field -eq 'questionOptionsExclude') {
            foreach ($option in @($decisionCase.expect.$field)) {
                if ($option -in @($actualDecision.questionOptions)) {
                    Write-Fail -TestName $caseName -Reason ('questionOptions included unsupported candidate: {0}' -f $option)
                }
            }
            continue
        }
        if ($field -eq 'candidateSelectionOptionsInclude') {
            foreach ($option in @($decisionCase.expect.$field)) {
                if ($option -notin @($actualDecision.candidateSelectionOptions)) {
                    Write-Fail -TestName $caseName -Reason ('candidate selection list did not include expected pair: {0}' -f $option)
                }
            }
            continue
        }
        if ($field -eq 'candidateSelectionOptionsExclude') {
            foreach ($option in @($decisionCase.expect.$field)) {
                if ($option -in @($actualDecision.candidateSelectionOptions)) {
                    Write-Fail -TestName $caseName -Reason ('candidate selection list included unsupported pair: {0}' -f $option)
                }
            }
            continue
        }
        if ($field -eq 'schemaDiscovery') {
            foreach ($schemaField in $decisionCase.expect.$field.PSObject.Properties.Name) {
                if (-not $actualDecision.schemaDiscovery.PSObject.Properties[$schemaField]) {
                    Write-Fail -TestName $caseName -Reason ('schemaDiscovery omitted field: {0}' -f $schemaField)
                }
                $expectedSchemaValue = ConvertTo-Json -InputObject $decisionCase.expect.$field.$schemaField -Depth 8 -Compress
                $actualSchemaValue = ConvertTo-Json -InputObject $actualDecision.schemaDiscovery.$schemaField -Depth 8 -Compress
                if ($expectedSchemaValue -cne $actualSchemaValue) {
                    Write-Fail -TestName $caseName -Reason ('schemaDiscovery.{0}: expected {1}, got {2}' -f $schemaField, $expectedSchemaValue, $actualSchemaValue)
                }
            }
            continue
        }
        if (-not $actualDecision.PSObject.Properties[$field]) {
            Write-Fail -TestName $caseName -Reason ('oracle omitted field: {0}' -f $field)
        }
        $expectedValue = ConvertTo-Json -InputObject $decisionCase.expect.$field -Depth 8 -Compress
        $actualValue = ConvertTo-Json -InputObject $actualDecision.$field -Depth 8 -Compress
        if ($expectedValue -cne $actualValue) {
            Write-Fail -TestName $caseName -Reason ('{0}: expected {1}, got {2}' -f $field, $expectedValue, $actualValue)
        }
    }
    Write-Pass -TestName $caseName
}

}

$sections['PreferencesSchema'] = {
# Tests:
#   Should_Pass_When_PreferencesSchemaDocumented





$preferencesInitializer = Join-Path $libDir 'Initialize-SddPreferences.ps1'
$rootLayoutInitializer = Join-Path $libDir 'Initialize-SddRootLayout.ps1'
if (-not (Test-Path -LiteralPath $preferencesInitializer) -or -not (Test-Path -LiteralPath $rootLayoutInitializer)) {
    Write-Fail -TestName 'Assert-PreferencesSchemaPreconditions' -Reason 'preference initializer dependencies are missing'
}
. $rootLayoutInitializer
. $preferencesInitializer

$testName = 'Should_Pass_When_PreferencesSchemaDocumented'
$paths = @($script:ToolkitConstant.PreferencesSchemaDocRelativePaths)
$keys = @($script:ToolkitConstant.PreferencesSchemaKeyMarkers)

foreach ($rel in $paths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $testName -Reason ("missing {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    foreach ($key in $keys) {
        if ($text -notmatch [regex]::Escape($key)) {
            Write-Fail -TestName $testName -Reason ("{0} missing preferences key: {1}" -f $rel, $key)
        }
    }
}
$storageDoc = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\_shared\sdd-artifacts\STORAGE-RESOLUTION.md') -Raw -Encoding UTF8
$cavemanPolicy = Get-Content -LiteralPath (Join-Path $repoRoot 'core\policy\caveman-mode.md') -Raw -Encoding UTF8
if ($storageDoc -notmatch '"caveman_mode": true' -or $cavemanPolicy -notmatch 'caveman_mode": true') {
    Write-Fail -TestName 'Should_DocumentCavemanOnAsDefault' -Reason 'storage and Caveman policy must document the on default'
}
Write-Pass -TestName 'Should_DocumentCavemanOnAsDefault'

$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-preferences-' + [Guid]::NewGuid().ToString('N'))
$script:PreferenceTestAnswers = [System.Collections.Queue]::new()
$script:PreferenceTestPromptCount = 0
function Read-Host {
    param([string] $Prompt)
    $script:PreferenceTestPromptCount++
    if ($script:PreferenceTestAnswers.Count -gt 0) { return [string]$script:PreferenceTestAnswers.Dequeue() }
    return ''
}
function Set-PreferenceTestAnswers {
    param([string[]] $Answers)
    $script:PreferenceTestAnswers.Clear()
    foreach ($answer in $Answers) { $script:PreferenceTestAnswers.Enqueue($answer) }
    $script:PreferenceTestPromptCount = 0
}

try {
    $interactiveRoot = Join-Path $fixtureRoot 'interactive'
    Set-PreferenceTestAnswers -Answers @('1', '2')
    $interactiveOutput = Invoke-ToolkitEnsurePreferences -SddRoot $interactiveRoot -Interactive *>&1 | Out-String
    $interactivePath = Join-Path $interactiveRoot 'preferences.json'
    $interactivePreferences = Get-Content -LiteralPath $interactivePath -Raw | ConvertFrom-Json
    if ($interactivePreferences.orchestrator_mode -ne 'adaptive' -or $interactivePreferences.caveman_mode -ne $false -or $script:PreferenceTestPromptCount -ne 2) {
        Write-Fail -TestName 'Should_PersistInteractivePreferenceChoices' -Reason 'interactive first sync must ask twice and persist adaptive / Caveman off'
    }
    if ($interactiveOutput -notmatch 'disables response compression' -or $interactiveOutput -notmatch 'recommended' -or $interactiveOutput -notmatch 'Adaptive' -or $interactiveOutput -notmatch 'Always orchestrate' -or $interactiveOutput -notmatch 'On \(recommended default\)') {
        Write-Fail -TestName 'Should_ExplainCavemanInstallChoice' -Reason 'interactive flow must display both choices, recommend Caveman on, and explain that off disables response compression'
    }
    Write-Pass -TestName 'Should_PersistInteractivePreferenceChoices'
    Write-Pass -TestName 'Should_ExplainCavemanInstallChoice'

    $nonInteractiveRoot = Join-Path $fixtureRoot 'non-interactive'
    Set-PreferenceTestAnswers -Answers @()
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $nonInteractiveRoot
    $nonInteractivePreferences = Get-Content -LiteralPath (Join-Path $nonInteractiveRoot 'preferences.json') -Raw | ConvertFrom-Json
    if ($nonInteractivePreferences.orchestrator_mode -ne 'adaptive' -or $nonInteractivePreferences.caveman_mode -ne $true -or $script:PreferenceTestPromptCount -ne 0) {
        Write-Fail -TestName 'Should_UseDefaults_When_NonInteractiveFirstSync' -Reason 'non-interactive first sync must default to adaptive / Caveman on without prompting'
    }
    Write-Pass -TestName 'Should_UseDefaults_When_NonInteractiveFirstSync'

    $interactiveDefaultRoot = Join-Path $fixtureRoot 'interactive-defaults'
    Set-PreferenceTestAnswers -Answers @('', '')
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $interactiveDefaultRoot -Interactive
    $interactiveDefaults = Get-Content -LiteralPath (Join-Path $interactiveDefaultRoot 'preferences.json') -Raw | ConvertFrom-Json
    if ($interactiveDefaults.orchestrator_mode -ne 'adaptive' -or $interactiveDefaults.caveman_mode -ne $true -or $script:PreferenceTestPromptCount -ne 2) {
        Write-Fail -TestName 'Should_UseRecommendedChoices_When_InteractiveInputIsBlank' -Reason 'blank interactive choices must select adaptive / Caveman on'
    }
    Write-Pass -TestName 'Should_UseRecommendedChoices_When_InteractiveInputIsBlank'

    $existingRoot = Join-Path $fixtureRoot 'existing'
    $null = New-Item -ItemType Directory -Path $existingRoot -Force
    $existingPath = Join-Path $existingRoot 'preferences.json'
    $existingJson = '{"caveman_mode":false,"caveman_level":"lite","orchestrator_mode":"adaptive","artifact_language":"pt-BR","verify_mode":true}'
    [System.IO.File]::WriteAllText($existingPath, $existingJson, (New-Object System.Text.UTF8Encoding $false))
    Set-PreferenceTestAnswers -Answers @()
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $existingRoot -Interactive
    $afterExisting = Get-Content -LiteralPath $existingPath -Raw
    if ($afterExisting -ne $existingJson -or $script:PreferenceTestPromptCount -ne 0) {
        Write-Fail -TestName 'Should_PreserveExistingPreferences' -Reason 'existing preferences, including explicit Caveman false, must remain byte-for-byte unchanged'
    }
    Write-Pass -TestName 'Should_PreserveExistingPreferences'

    $whatIfRoot = Join-Path $fixtureRoot 'what-if'
    Set-PreferenceTestAnswers -Answers @()
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $whatIfRoot -Interactive -WhatIf
    if ((Test-Path -LiteralPath $whatIfRoot) -or $script:PreferenceTestPromptCount -ne 0) {
        Write-Fail -TestName 'Should_NotPromptOrWrite_When_WhatIf' -Reason 'WhatIf must not prompt or create the root/preferences file'
    }
    Write-Pass -TestName 'Should_NotPromptOrWrite_When_WhatIf'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

Write-Pass -TestName $testName
}

$sections['PlanExecutionPolicy'] = {
# Tests:
#   Should_Pass_When_SddSkillsWireExecutionPolicy






$skillPaths = @($script:ToolkitConstant.ExecutionPolicySkillWiringRelativePaths)

$skillTest = 'Should_Pass_When_SddSkillsWireExecutionPolicy'
foreach ($rel in $skillPaths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $skillTest -Reason ("missing skill {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    if ($text -notmatch '(?i)PIPELINE\.md|shared SDD pipeline|shared approval, progress') {
        Write-Fail -TestName $skillTest -Reason ("{0} must reference the shared pipeline contract" -f $rel)
    }
}
Write-Pass -TestName $skillTest

}

$sections['SkillLazyLoad'] = {
# Tests:
#   Should_Pass_When_SkillReferenceRetrievalContractPresent
#   Should_Fail_When_MonolithicReferenceWithoutSplit
#   Should_Pass_When_OrchestrateReferencesSplitPresent
#   Should_Fail_When_MonolithicReferenceWithoutSplit
#
# Reference structure: large monolithic reference.md files must be split;
# keep the check independent of per-skill routing-table ceremony.




function Test-HasReferenceSplit {
    param([Parameter(Mandatory = $true)][string] $SkillDir)
    $referencesDir = Join-Path $SkillDir 'references'
    $referenceDir = Join-Path $SkillDir 'reference'
    return ((Test-Path -LiteralPath $referencesDir) -or (Test-Path -LiteralPath $referenceDir))
}

function Get-ReferenceSplitDir {
    param([Parameter(Mandatory = $true)][string] $SkillDir)
    $referencesDir = Join-Path $SkillDir 'references'
    if (Test-Path -LiteralPath $referencesDir) {
        return $referencesDir
    }
    $referenceDir = Join-Path $SkillDir 'reference'
    if (Test-Path -LiteralPath $referenceDir) {
        return $referenceDir
    }
    return $null
}




$guideRel = $script:ToolkitConstant.SkillReferenceRetrievalGuideRelativePath
$guidePath = Join-Path $repoRoot $guideRel
$ruleId = $script:ToolkitConstant.SkillReferenceRetrievalRuleId
$skillsRootRel = $script:ToolkitConstant.CoreSkillsRootRelativePath
$skillsRoot = Join-Path $repoRoot $skillsRootRel
$sharedDirName = $script:ToolkitConstant.SharedSkillsDirectoryName
$referenceLineThreshold = $script:ToolkitConstant.SkillLazyLoadReferenceLineThreshold
$referenceIndexLineThreshold = $script:ToolkitConstant.SkillLazyLoadReferenceIndexLineThreshold

if (-not (Test-Path -LiteralPath $guidePath)) {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason ("missing guide {0}" -f $guideRel)
}

$guideText = Get-Content -LiteralPath $guidePath -Raw -Encoding UTF8
if ($guideText -notmatch [regex]::Escape($ruleId)) {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason ("guide missing rule id {0}" -f $ruleId)
}
if ($guideText -notmatch 'Assert-CoreContracts') {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason 'guide must name Assert-CoreContracts.ps1 as enforcement'
}
if ($guideText -notmatch '(?i)## Lazy-load' -or $guideText -notmatch '(?i)\*\*Never by default:\*\*') {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason 'guide must document mandatory Lazy-load + Never by default sections'
}
if (($guideText -notmatch '(?i)all invocable') -and ($guideText -notmatch '(?i)every invocable')) {
    Write-Fail -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent' -Reason 'guide must state contract applies to all/every invocable skills'
}
Write-Pass -TestName 'Should_Pass_When_SkillReferenceRetrievalContractPresent'

$monolithicFailures = [System.Collections.Generic.List[string]]::new()
$indexSoftWarnings = [System.Collections.Generic.List[string]]::new()

$skillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Where-Object {
        $_.Name -ne $sharedDirName
    })

foreach ($dir in $skillDirs) {
    $skillPath = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillPath)) {
        continue
    }

    $text = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
    if ($text -notmatch '(?m)^name:\s*\S+') {
        continue
    }

    $referencePath = Join-Path $dir.FullName 'reference.md'
    if (-not (Test-Path -LiteralPath $referencePath)) {
        continue
    }

    $referenceLines = @(Get-Content -LiteralPath $referencePath -Encoding UTF8).Count
    $hasSplit = Test-HasReferenceSplit -SkillDir $dir.FullName
    $splitDir = Get-ReferenceSplitDir -SkillDir $dir.FullName

    if ($hasSplit) {
        $refFiles = @(Get-ChildItem -LiteralPath $splitDir -File -Filter '*.md')
        if ($refFiles.Count -eq 0) {
            $monolithicFailures.Add(("{0}: {1}/ exists but is empty" -f $dir.Name, (Split-Path -Leaf $splitDir)))
        }
        if ($referenceLines -gt $referenceIndexLineThreshold) {
            $indexSoftWarnings.Add(("{0}: reference.md index has {1} lines (soft target ≤{2})" -f $dir.Name, $referenceLines, $referenceIndexLineThreshold))
        }
    }
    elseif ($referenceLines -gt $referenceLineThreshold) {
        $monolithicFailures.Add(("{0}: reference.md has {1} lines without references/ or reference/ split (threshold {2})" -f $dir.Name, $referenceLines, $referenceLineThreshold))
    }
}

$orchestrateSkills = @('orchestrate-analyze', 'orchestrate-deliver', 'orchestrate-develop')
foreach ($skillName in $orchestrateSkills) {
    $refsDir = Join-Path (Join-Path $skillsRoot $skillName) 'references'
    if (-not (Test-Path -LiteralPath $refsDir)) {
        Write-Fail -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent' -Reason ("missing {0}/references/" -f $skillName)
    }
    $refIndex = Join-Path (Join-Path $skillsRoot $skillName) 'reference.md'
    if (-not (Test-Path -LiteralPath $refIndex)) {
        Write-Fail -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent' -Reason ("missing {0}/reference.md index" -f $skillName)
    }
    $indexLines = @(Get-Content -LiteralPath $refIndex -Encoding UTF8).Count
    if ($indexLines -gt $referenceIndexLineThreshold) {
        Write-Fail -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent' -Reason ("{0}/reference.md index has {1} lines (max {2})" -f $skillName, $indexLines, $referenceIndexLineThreshold)
    }
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateReferencesSplitPresent'

if ($monolithicFailures.Count -gt 0) {
    Write-Fail -TestName 'Should_Fail_When_MonolithicReferenceWithoutSplit' -Reason ($monolithicFailures -join '; ')
}
Write-Pass -TestName 'Should_Fail_When_MonolithicReferenceWithoutSplit'

if ($indexSoftWarnings.Count -gt 0) {
    foreach ($warn in $indexSoftWarnings) {
        Write-Warning ("SkillLazyLoad WARN: {0}" -f $warn)
    }
}

}

$sections['StorySizingContract'] = {
# Tests:
#   Should_Pass_When_StorySizingContractPresent
#   Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing
#   Should_Pass_When_RefineStoryScorecardHasStoryScope
#   Should_Pass_When_TemplatesRepresentBehaviorAndSingleProgressTable
#
# Story-sizing guidance remains optional context for concrete sizing questions;
# O1 always synthesizes stories around distinct, understandable outcomes.







$contractRel = $script:ToolkitConstant.StorySizingContractRelativePath
$contractPath = Join-Path $repoRoot $contractRel
$o1SkillRel = 'core/skills/orchestrate-analyze/SKILL.md'
$o1RefRel = 'core/skills/orchestrate-analyze/reference.md'
$o1SynthesisRel = 'core/skills/orchestrate-analyze/references/story-synthesis.md'
$refineRefRel = 'core/skills/refine-story/reference.md'

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason ("missing contract {0}" -f $contractRel)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
if ($contractText -notmatch 'Assert-CoreContracts') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must name Assert-CoreContracts.ps1 as enforcement'
}
if ($contractText -notmatch '(?i)one verifiable') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must define minimum story as one verifiable outcome'
}
if ($contractText -notmatch '(?i)anti-pattern') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must document anti-patterns'
}
if ($contractText -notmatch '(?i)NuGet') {
    Write-Fail -TestName 'Should_Pass_When_StorySizingContractPresent' -Reason 'story-sizing.md must reference NuGet example'
}
Write-Pass -TestName 'Should_Pass_When_StorySizingContractPresent'

$o1SkillPath = Join-Path $repoRoot $o1SkillRel
$o1RefPath = Join-Path $repoRoot $o1RefRel
$o1SynthesisPath = Join-Path $repoRoot $o1SynthesisRel
if (-not (Test-Path -LiteralPath $o1SkillPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason ("missing {0}" -f $o1SkillRel)
}
if (-not (Test-Path -LiteralPath $o1RefPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason ("missing {0}" -f $o1RefRel)
}
if (-not (Test-Path -LiteralPath $o1SynthesisPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason ("missing {0}" -f $o1SynthesisRel)
}

$o1SkillText = Get-Content -LiteralPath $o1SkillPath -Raw -Encoding UTF8
$o1RefText = Get-Content -LiteralPath $o1RefPath -Raw -Encoding UTF8
$o1SynthesisText = Get-Content -LiteralPath $o1SynthesisPath -Raw -Encoding UTF8
$o1DetailText = ($o1RefText + "`n" + $o1SynthesisText)

if ($o1SkillText -notmatch 'story-synthesis\.md' -or $o1DetailText -notmatch 'story-sizing\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason 'O1 must route story synthesis to its guide, which may load story-sizing guidance when a concrete sizing question needs it'
}
if ($o1DetailText -notmatch '(?i)concrete sizing question' -or $o1DetailText -notmatch '(?i)distinct, understandable outcome') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing' -Reason 'O1 story synthesis must use outcome-shaped stories and make sizing guidance conditional'
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesStorySizing'

$refineRefPath = Join-Path $repoRoot $refineRefRel
if (-not (Test-Path -LiteralPath $refineRefPath)) {
    Write-Fail -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope' -Reason ("missing {0}" -f $refineRefRel)
}

$refineRefText = Get-Content -LiteralPath $refineRefPath -Raw -Encoding UTF8
if ($refineRefText -notmatch '(?i)Story scope') {
    Write-Fail -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope' -Reason 'refine-story/reference.md must include Story scope scorecard criterion'
}
if ($refineRefText -notmatch 'story-sizing\.md') {
    Write-Fail -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope' -Reason 'refine-story/reference.md must reference story-sizing.md'
}
Write-Pass -TestName 'Should_Pass_When_RefineStoryScorecardHasStoryScope'

# --- Template and story-sizing assertions ---
$prdTemplatePath = Join-Path $repoRoot 'core/skills/_shared/templates/sdd/PRD.md'
$planTemplatePath = Join-Path $repoRoot 'core/skills/_shared/templates/sdd/PLAN.md'
foreach ($path in @($prdTemplatePath, $planTemplatePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Fail -TestName 'Should_Pass_When_TemplatesRepresentBehaviorAndSingleProgressTable' -Reason ("missing {0}" -f $path)
    }
}

foreach ($marker in @('value', 'consumer', 'delivery independence', 'Endpoint count is never sufficient')) {
    if ($contractText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_S5PlanningContractsCoverSeededCases' -Reason ("story-sizing.md missing '{0}'" -f $marker)
    }
}
$prdTemplateText = Get-Content -LiteralPath $prdTemplatePath -Raw -Encoding UTF8
$planTemplateText = Get-Content -LiteralPath $planTemplatePath -Raw -Encoding UTF8
foreach ($marker in @('Resultado esperado', 'Comportamento e aceite', 'Impacto brownfield (quando aplicável)', 'Decisões e perguntas materiais')) {
    if ($prdTemplateText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_TemplatesRepresentBehaviorAndSingleProgressTable' -Reason ("PRD template missing useful behavior section '{0}'" -f $marker)
    }
}
foreach ($marker in @('single persisted source of implementation progress', 'única tabela canônica de execução', 'Dependências', 'Estado', 'Evidência e validação', 'Bloqueio ou próxima ação')) {
    if ($planTemplateText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_TemplatesRepresentBehaviorAndSingleProgressTable' -Reason ("PLAN template missing canonical progress information '{0}'" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_TemplatesRepresentBehaviorAndSingleProgressTable'

}

$sections['IntentClassification'] = {
# Tests:
#   Should_Pass_When_IntentClassificationContractPresent
#   Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification
#   Should_Pass_When_TriageCrossReferencesIntentClassification
#
# Frente E: intent-classification contract exists and is wired into O1 Step 1 triage entry.







$contractRel = 'core/skills/orchestrate-analyze/references/intent-classification.md'
$contractPath = Join-Path $repoRoot $contractRel
$o1SkillRel = 'core/skills/orchestrate-analyze/SKILL.md'
$o1RefRel = 'core/skills/orchestrate-analyze/reference.md'
$o1TriageRel = 'core/skills/orchestrate-analyze/references/triage.md'

if (-not (Test-Path -LiteralPath $contractPath)) {
    Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason ("missing contract {0}" -f $contractRel)
}

$contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
foreach ($intentLabel in @('Existing feature', 'New feature', 'Product initiative', 'Problem or need', 'Idea')) {
    if ($contractText -notmatch [regex]::Escape($intentLabel)) {
        Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason ("intent-classification.md must define intent {0}" -f $intentLabel)
    }
}
if ($contractText -notmatch '(?i)Classic SDD' -or $contractText -notmatch '(?i)Refine' -or $contractText -notmatch '(?i)O1') {
    Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason 'intent-classification.md must map intents to Classic SDD, refinement, or O1 when useful'
}
if ($contractText -notmatch '(?i)materially unclear' -or $contractText -notmatch '(?is)Reuse prior\s+context') {
    Write-Fail -TestName 'Should_Pass_When_IntentClassificationContractPresent' -Reason 'intent classification must reuse prior context and ask only when the route is materially unclear'
}
Write-Pass -TestName 'Should_Pass_When_IntentClassificationContractPresent'

$o1SkillPath = Join-Path $repoRoot $o1SkillRel
$o1RefPath = Join-Path $repoRoot $o1RefRel
if (-not (Test-Path -LiteralPath $o1SkillPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason ("missing {0}" -f $o1SkillRel)
}
if (-not (Test-Path -LiteralPath $o1RefPath)) {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason ("missing {0}" -f $o1RefRel)
}

$o1SkillText = Get-Content -LiteralPath $o1SkillPath -Raw -Encoding UTF8
$o1RefText = Get-Content -LiteralPath $o1RefPath -Raw -Encoding UTF8

if ($o1SkillText -notmatch 'intent-classification\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason 'orchestrate-analyze/SKILL.md must reference intent-classification.md'
}
if ($o1SkillText -notmatch '(?i)Classify intent') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason 'orchestrate-analyze/SKILL.md must include the intent classification process step'
}
if ($o1RefText -notmatch 'intent-classification\.md') {
    Write-Fail -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification' -Reason 'orchestrate-analyze/reference.md must index intent-classification.md'
}
Write-Pass -TestName 'Should_Pass_When_OrchestrateAnalyzeReferencesIntentClassification'

$o1TriagePath = Join-Path $repoRoot $o1TriageRel
if (-not (Test-Path -LiteralPath $o1TriagePath)) {
    Write-Fail -TestName 'Should_Pass_When_TriageCrossReferencesIntentClassification' -Reason ("missing {0}" -f $o1TriageRel)
}

$o1TriageText = Get-Content -LiteralPath $o1TriagePath -Raw -Encoding UTF8
if ($o1TriageText -notmatch '(?i)Prefer Classic SDD' -or $o1TriageText -notmatch '(?i)Backlog Refine' -or $o1TriageText -notmatch '(?i)O1 for justified multi-story') {
    Write-Fail -TestName 'Should_Pass_When_TriageCrossReferencesIntentClassification' -Reason 'triage.md must retain proportionate Classic, Refine, and O1 routes'
}
Write-Pass -TestName 'Should_Pass_When_TriageCrossReferencesIntentClassification'

}

$sections['JavaDeveloperRouting'] = {
# Tests:
#   Should_FailValidateCore_When_JavaDeveloperMissingFromDisk
#   Should_FailValidateCore_When_JavaMissingFromCatalogOrRoutes
#   Should_PassValidateCore_When_JavaPresentAndRouted




function Test-JavaDeveloperSkillOnDisk {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativeSkillPath
    )
    $candidate = Join-Path $RepoRoot ($RelativeSkillPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $candidate)) {
        return $false
    }
    $item = Get-Item -LiteralPath $candidate
    return ($item.Length -gt 0)
}

function Get-JavaRoutingSurfaceGaps {
    param(
        [Parameter(Mandatory = $true)][hashtable] $SurfaceTexts,
        [Parameter(Mandatory = $true)][string] $CatalogToken,
        [Parameter(Mandatory = $true)][string] $RouteToken,
        [Parameter(Mandatory = $true)][string] $MavenPomFileName,
        [Parameter(Mandatory = $true)][string] $GradleBuildFileName
    )
    $gaps = [System.Collections.Generic.List[string]]::new()
    foreach ($name in @($SurfaceTexts.Keys | Sort-Object)) {
        $body = [string]$SurfaceTexts[$name]
        if ($body.IndexOf($CatalogToken, [System.StringComparison]::Ordinal) -lt 0) {
            $gap = '{0}:missing-token:{1}' -f $name, $CatalogToken
            $gaps.Add($gap)
        }
    }

    $routingBody = [string]$SurfaceTexts['routing']
    if ($routingBody.IndexOf($RouteToken, [System.StringComparison]::Ordinal) -lt 0) {
        $gap = 'routing:missing-route:{0}' -f $RouteToken
        $gaps.Add($gap)
    }

    $developerBody = [string]$SurfaceTexts['developer']
    if ($developerBody.IndexOf($MavenPomFileName, [System.StringComparison]::Ordinal) -lt 0) {
        $gap = 'developer:missing-signal:{0}' -f $MavenPomFileName
        $gaps.Add($gap)
    }
    if ($developerBody.IndexOf($GradleBuildFileName, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $gap = 'developer:missing-signal:{0}' -f $GradleBuildFileName
        $gaps.Add($gap)
    }

    return $gaps.ToArray()
}

function Read-RequiredSurfaceText {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [Parameter(Mandatory = $true)][string] $TestName
    )
    $fullPath = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Write-Fail -TestName $TestName -Reason ($script:ToolkitMessage.JavaRoutingSurfaceMissing -f $RelativePath)
    }
    return (Get-Content -LiteralPath $fullPath -Raw)
}




$skillDirName = $script:ToolkitConstant.JavaDeveloperSkillDirectoryName
$skillFileName = $script:ToolkitConstant.JavaDeveloperSkillFileName
$catalogToken = $script:ToolkitConstant.JavaDeveloperCatalogToken
$routeToken = $script:ToolkitConstant.JavaDeveloperRouteToken
$mavenPom = $script:ToolkitConstant.JavaMavenPomFileName
$gradleBuild = $script:ToolkitConstant.JavaGradleBuildFileName
$inventedMissingRel = $script:ToolkitConstant.InventedMissingJavaSkillRel
$javaSkillRel = ('{0}/{1}/{2}/{3}' -f $script:ToolkitConstant.CoreSkillsDirectoryName, $script:ToolkitConstant.SkillsDirectoryName, $skillDirName, $skillFileName)

# --- Should_FailValidateCore_When_JavaDeveloperMissingFromDisk ---
$failDiskName = 'Should_FailValidateCore_When_JavaDeveloperMissingFromDisk'
if (Test-JavaDeveloperSkillOnDisk -RepoRoot $repoRoot -RelativeSkillPath $inventedMissingRel) {
    Write-Fail -TestName $failDiskName -Reason ($script:ToolkitMessage.JavaDeveloperMissingFromDiskExpectedFail -f $inventedMissingRel)
}

Write-Pass -TestName $failDiskName

# --- Should_FailValidateCore_When_JavaMissingFromCatalogOrRoutes ---
$failCatalogName = 'Should_FailValidateCore_When_JavaMissingFromCatalogOrRoutes'
$syntheticSurfaces = @{
    routing   = 'Python | /python-developer'
    developer = 'Detect .csproj and package.json only'
    catalog   = 'dotnet-developer and python-developer'
    agents    = 'Stack developers without JVM specialist'
}
$syntheticGaps = @(Get-JavaRoutingSurfaceGaps -SurfaceTexts $syntheticSurfaces -CatalogToken $catalogToken -RouteToken $routeToken -MavenPomFileName $mavenPom -GradleBuildFileName $gradleBuild)
if ($syntheticGaps.Count -eq 0) {
    Write-Fail -TestName $failCatalogName -Reason $script:ToolkitMessage.JavaMissingFromCatalogOrRoutesExpectedFail
}

Write-Pass -TestName $failCatalogName

# --- Should_PassValidateCore_When_JavaPresentAndRouted ---
$passName = 'Should_PassValidateCore_When_JavaPresentAndRouted'
if (-not (Test-JavaDeveloperSkillOnDisk -RepoRoot $repoRoot -RelativeSkillPath $javaSkillRel)) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.JavaDeveloperMissingFromDisk -f $javaSkillRel)
}

$surfaceTexts = @{
    routing   = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.RoutingMdRelativePath -TestName $passName)
    developer = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.DeveloperSkillRelativePath -TestName $passName)
    catalog   = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.SkillsCatalogRelativePath -TestName $passName)
    agents    = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.RouterAgentsRelativePath -TestName $passName)
}

$realGaps = @(Get-JavaRoutingSurfaceGaps -SurfaceTexts $surfaceTexts -CatalogToken $catalogToken -RouteToken $routeToken -MavenPomFileName $mavenPom -GradleBuildFileName $gradleBuild)
if ($realGaps.Count -gt 0) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.JavaMissingFromCatalogOrRoutes -f ($realGaps -join ', '))
}

Write-Pass -TestName $passName

}

$sections['NoFormaAlias'] = {
# Tests:
#   Should_Fail_When_SyntheticFormaAliasPresent
#   Should_Pass_When_ScopeHasNoFormaAliases
#
# Work-track rename (Frente 0): canonical docs must not retain Forma A/B/C aliases.

. (Join-Path $libDir 'ToolkitValidationFileSystem.ps1')



function Get-NoFormaAliasHits {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text,
        [Parameter(Mandatory = $true)][string[]] $Patterns
    )
    $hits = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($pattern in $Patterns) {
        foreach ($match in [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $value = $match.Value
            if ($seen.Add($value)) {
                $hits.Add($value)
            }
        }
    }
    return $hits.ToArray()
}

function Get-NoFormaAliasScanTargets {
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $targets = [System.Collections.Generic.List[string]]::new()
    foreach ($dirName in @('core', 'docs', 'docs-site', 'memory-bank')) {
        $dirPath = Join-Path $RepoRoot $dirName
        if (-not (Test-Path -LiteralPath $dirPath)) {
            continue
        }
        Get-ToolkitValidationFiles -Root $dirPath -Recurse -Extensions @('.md', '.mdc') | ForEach-Object {
            $targets.Add($_.FullName)
        }
    }

    foreach ($rootName in @('README.md', 'PRODUCT.md')) {
        $rootPath = Join-Path $RepoRoot $rootName
        if (Test-Path -LiteralPath $rootPath) {
            $targets.Add($rootPath)
        }
    }

    return $targets.ToArray()
}




$forbiddenPatterns = @(
    $script:ToolkitConstant.NoFormaAliasFormaLetterPattern,
    $script:ToolkitConstant.NoFormaAliasFormerlyPattern,
    $script:ToolkitConstant.NoFormaAliasFormerlyTrackAliasPattern,
    $script:ToolkitConstant.NoFormaAliasWorkflowsHeadingPattern,
    $script:ToolkitConstant.NoFormaAliasSlashPattern,
    $script:ToolkitConstant.NoFormaAliasPipePattern
)

# --- Should_Fail_When_SyntheticFormaAliasPresent ---
$negativeName = 'Should_Fail_When_SyntheticFormaAliasPresent'
$syntheticBody = $script:ToolkitConstant.NoFormaAliasSyntheticForbiddenSample
$syntheticHits = @(Get-NoFormaAliasHits -Text $syntheticBody -Patterns $forbiddenPatterns)
if ($syntheticHits.Count -eq 0) {
    Write-Fail -TestName $negativeName -Reason $script:ToolkitMessage.NoFormaAliasNegativeExpectedFail
}

Write-Pass -TestName $negativeName

# --- Should_Pass_When_ScopeHasNoFormaAliases ---
$passName = 'Should_Pass_When_ScopeHasNoFormaAliases'
$scanTargets = @(Get-NoFormaAliasScanTargets -RepoRoot $repoRoot)
if ($scanTargets.Count -eq 0) {
    Write-Fail -TestName $passName -Reason $script:ToolkitMessage.NoFormaAliasNoScanTargets
}

$violations = [System.Collections.Generic.List[string]]::new()
foreach ($path in $scanTargets) {
    $text = Read-ToolkitValidationText -Path $path
    $hits = @(Get-NoFormaAliasHits -Text $text -Patterns $forbiddenPatterns)
    if ($hits.Count -eq 0) {
        continue
    }

    $rel = $path
    if ($path.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $path.Substring($repoRoot.Length).TrimStart('\', '/')
    }
    $rel = $rel -replace '\\', '/'
    $violations.Add(('{0}: {1}' -f $rel, ($hits -join ', ')))
}

if ($violations.Count -gt 0) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.NoFormaAliasViolations -f ($violations.ToArray() -join '; '))
}

Write-Pass -TestName $passName
}

$sections['CanonicalCloneUrl'] = {
# Tests:
#   Should_UseCanonicalCloneUrl_When_EntrypointsRead
#   Should_NotContainClonePlaceholder_When_EntrypointsGreped


$canonicalCloneUrl = 'https://github.com/tibursocampos/agent-dev-toolkit.git'
$clonePlaceholder = '<this-repo-url>'
$entrypointRels = @(
    'README.md',
    'docs/INSTALL.md',
    'docs/guides/01-getting-started.md'
)





# --- Should_UseCanonicalCloneUrl_When_EntrypointsRead ---
$urlName = 'Should_UseCanonicalCloneUrl_When_EntrypointsRead'
$missingUrl = @()
foreach ($rel in $entrypointRels) {
    $path = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Fail -TestName $urlName -Reason ("missing entrypoint: {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -notlike ("*{0}*" -f $canonicalCloneUrl)) {
        $missingUrl += $rel
    }
}

if ($missingUrl.Count -gt 0) {
    Write-Fail -TestName $urlName -Reason ("canonical clone URL missing in: {0}" -f ($missingUrl -join ', '))
}

Write-Pass -TestName $urlName

# --- Should_NotContainClonePlaceholder_When_EntrypointsGreped ---
$placeholderName = 'Should_NotContainClonePlaceholder_When_EntrypointsGreped'
$withPlaceholder = @()
foreach ($rel in $entrypointRels) {
    $path = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -like ("*{0}*" -f $clonePlaceholder)) {
        $withPlaceholder += $rel
    }
}

if ($withPlaceholder.Count -gt 0) {
    Write-Fail -TestName $placeholderName -Reason ("clone placeholder still present in: {0}" -f ($withPlaceholder -join ', '))
}

Write-Pass -TestName $placeholderName
}

$sections['Tier1AdapterReadmes'] = {
# Tests:
#   Should_HaveReadmePerAdapter_When_AdaptersInspected
#   Should_LinkAdaptersDoc_When_StubRead


$adaptersDocMarker = 'docs/ADAPTERS.md'
$adaptersDocRelativeLink = '../../docs/ADAPTERS.md'
$syncFixtureMarker = 'scripts/validation/fixtures/'






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
}

$sections['AuthorizationPolicy'] = {
# Requires: PowerShell 5.1+
# Tests:
#   Should_Allow_When_EffectAndScopeAreAuthorized
#   Should_Deny_When_EffectOrScopeIsOutsideAuthorization
#   Should_Deny_When_RequestOrAuthorizationIsInvalid
. (Join-Path $PSScriptRoot '..\..\core\policy\authorization.ps1')

$authorizations = @(
    [PSCustomObject]@{ Effect = 'file.write'; Scope = 'workspace:alpha' },
    [PSCustomObject]@{ Effect = 'git.commit'; Scope = 'repository:beta' }
)

$allowed = Test-ActionAuthorization -Effect 'file.write' -Scope 'workspace:alpha' -Authorizations $authorizations
if (-not $allowed.Allowed -or $allowed.Reason -ne 'authorized') {
    Write-Error 'Should_Allow_When_EffectAndScopeAreAuthorized: expected an exact authorized pair to pass'
    throw 'section failed'
}
Write-Host 'Should_Allow_When_EffectAndScopeAreAuthorized: PASS'

$crossPair = Test-ActionAuthorization -Effect 'file.write' -Scope 'repository:beta' -Authorizations $authorizations
$unknownEffect = Test-ActionAuthorization -Effect 'shell.execute' -Scope 'workspace:alpha' -Authorizations $authorizations
if ($crossPair.Allowed -or $unknownEffect.Allowed) {
    Write-Error 'Should_Deny_When_EffectOrScopeIsOutsideAuthorization: expected unmatched and cross-paired requests to be denied'
    throw 'section failed'
}
Write-Host 'Should_Deny_When_EffectOrScopeIsOutsideAuthorization: PASS'

$emptyRequest = Test-ActionAuthorization -Effect '' -Scope 'workspace:alpha' -Authorizations $authorizations
$invalidAuthorization = Test-ActionAuthorization -Effect 'file.write' -Scope 'workspace:alpha' -Authorizations @([PSCustomObject]@{ Effect = 'file.write'; Scope = '' })
if ($emptyRequest.Allowed -or $emptyRequest.Reason -ne 'invalid_request' -or
    $invalidAuthorization.Allowed -or $invalidAuthorization.Reason -ne 'invalid_authorization') {
    Write-Error 'Should_Deny_When_RequestOrAuthorizationIsInvalid: expected invalid input to be denied explicitly'
    throw 'section failed'
}
Write-Host 'Should_Deny_When_RequestOrAuthorizationIsInvalid: PASS'

. (Join-Path $PSScriptRoot '..\..\adapters\_shared\GuardCommon.ps1')
$workspace = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-auth-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workspace -Force | Out-Null
try {
    $temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) 'toolkit-allowed.txt'
    $temporary = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{ path = $temporaryPath; content = 'safe' }) -WorkspaceRoot $workspace
    $unknown = Get-ToolkitPathSecretsGuardVerdict -ToolName 'NewProviderTool' -ToolInput ([pscustomobject]@{ payload = 'opaque' }) -WorkspaceRoot $workspace
    $secret = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{ path = (Join-Path $workspace 'sample.txt'); content = 'api_key = ghp_12345678901234567890' }) -WorkspaceRoot $workspace
    if ($temporary.Decision -ne 'allow' -or $unknown.Decision -ne 'allow') {
        Write-Error 'Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization: paths and tools must not be vetoed by Toolkit classification'
        throw 'section failed'
    }
    if ($secret.Decision -ne 'allow' -or $secret.UserMessage -match 'ghp_' -or $secret.AgentMessage -match 'ghp_' -or $secret.SecretType) {
        Write-Error 'Should_NotExposeSecretValue_When_HeuristicPatternMatches: no Toolkit denial or captured value may be emitted'
        throw 'section failed'
    }
    Write-Host 'Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization: PASS'
    Write-Host 'Should_NotExposeSecretValue_When_HeuristicPatternMatches: PASS'
}
finally {
    Remove-Item -LiteralPath $workspace -Recurse -Force -ErrorAction SilentlyContinue
}
}

$sections['ClassicExternalAccessContract'] = {
<##
.SYNOPSIS
  Checks the Classic SDD external-access contract is wired end to end.
.DESCRIPTION
  Structural contract check only. It does not prove provider/runtime I/O enforcement.
#>

Set-StrictMode -Version Latest


function Read-Contract {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    $path = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ("Missing contract file: {0}" -f $RelativePath) }
    return [System.IO.File]::ReadAllText($path)
}

function ConvertTo-ContractConceptText {
    param([Parameter(Mandatory = $true)][string] $Text)

    # Markdown markers, punctuation, casing, and layout are presentation. Keep
    # word boundaries while normalizing them so assertions test concepts.
    $normalized = $Text.ToLowerInvariant() -replace '[^\p{L}\p{N}]+', ' '
    return (($normalized -split '\s+' | Where-Object { $_ }) -join ' ')
}

function Assert-ContractConcepts {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string[]] $RequiredConcepts,
        [Parameter()][string[]] $ForbiddenConcepts = @()
    )

    $normalized = ConvertTo-ContractConceptText $Text
    $tokens = @($normalized -split ' ' | Where-Object { $_ })
    foreach ($concept in $RequiredConcepts) {
        $conceptTokens = @((ConvertTo-ContractConceptText $concept) -split ' ' | Where-Object { $_ })
        foreach ($token in $conceptTokens) {
            if ($tokens -notcontains $token) {
                throw ("{0}: required concept missing: {1}" -f $Name, $concept)
            }
        }
    }
    foreach ($concept in $ForbiddenConcepts) {
        $conceptTokens = @((ConvertTo-ContractConceptText $concept) -split ' ' | Where-Object { $_ })
        if (@($conceptTokens | Where-Object { $tokens -contains $_ }).Count -eq $conceptTokens.Count) {
            throw ("{0}: forbidden concept present: {1}" -f $Name, $concept)
        }
    }
}

# Production-caller candidates: every runtime-manifest source (explicit) plus the
# adapters/core/scripts trees. Only the broker's own fixture directory is excluded.
function Get-ProductionCallerCandidates {
    param([Parameter(Mandatory = $true)][string] $Root)

    $scanExtensions = @('.ps1', '.psm1', '.sh', '.md', '.json', '.mdc')
    $fixtureDirectory = [System.IO.Path]::GetFullPath((Join-Path $Root 'scripts/validation/fixtures')).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $candidates = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $manifestPath = Join-Path $Root 'scripts/runtime/runtime-manifest.json'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($entry in @($manifest.files)) {
            $sourcePath = Join-Path $Root ([string]$entry.source -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            if (Test-Path -LiteralPath $sourcePath -PathType Leaf) { [void]$candidates.Add([System.IO.Path]::GetFullPath($sourcePath)) }
        }
    }

    foreach ($scanRoot in @('adapters', 'core', 'scripts')) {
        $scanPath = Join-Path $Root $scanRoot
        if (-not (Test-Path -LiteralPath $scanPath)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $scanPath -Recurse -File)) {
            [void]$candidates.Add([System.IO.Path]::GetFullPath($file.FullName))
        }
    }

    return @($candidates | Where-Object {
            -not $_.StartsWith($fixtureDirectory, [System.StringComparison]::OrdinalIgnoreCase) -and
            ([System.IO.Path]::GetExtension($_) -in $scanExtensions)
        })
}

function Find-ProductionBrokerCallers {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string] $InvocationPattern
    )

    $rootPrefix = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    return @(Get-ProductionCallerCandidates -Root $Root |
            Where-Object { [System.IO.File]::ReadAllText($_) -match $InvocationPattern } |
            ForEach-Object {
                if ($_.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { $_.Substring($rootPrefix.Length) } else { $_ }
            })
}

try {
    $contract = Read-Contract 'core/skills/_shared/sdd-artifacts/CLASSIC-EXTERNAL-ACCESS.md'
    $spec = Read-Contract 'core/skills/sdd-spec/SKILL.md'
    $plan = Read-Contract 'core/skills/sdd-plan/SKILL.md'
    $develop = Read-Contract 'core/skills/sdd-develop/SKILL.md'
    $acquisition = Read-Contract 'core/skills/sdd-develop/references/plan-acquisition.md'
    $storage = Read-Contract 'core/skills/_shared/sdd-artifacts/STORAGE.md'

    Assert-ContractConcepts -Name 'portable-scope' -Text $contract -RequiredConcepts @(
        'CLASSIC-EXT-SCOPE',
        'external alias relative path',
        'inválido fora raiz workspace',
        'referências internas existentes aceitas',
        'CLASSIC-EXT-NO-ROOT',
        'não registre raiz física drive unc caminho absoluto',
        'CLASSIC-EXT-OPS',
        'read write operações'
    )

    Assert-ContractConcepts -Name 'spec-capture' -Text $spec -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'external read write target',
        'exact authorized operations',
        'never place physical roots or absolute paths in the PRD'
    )

    Assert-ContractConcepts -Name 'plan-approval-and-access-scope' -Text ($plan + "`n" + $acquisition) -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'one explicit approval before implementation',
        'approval covers this outcome scope access and implementation decision',
        'do not require a status token hash session flag claim separate per step confirmation'
    )

    Assert-ContractConcepts -Name 'develop-trusted-handoff' -Text ($develop + "`n" + $acquisition + "`n" + $contract) -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'mapeamento explícito separado',
        'mapeamento artefatos recibos',
        'boundary de I O efetivo',
        'block before any external I O'
    )

    Assert-ContractConcepts -Name 'plan-acquisition-scope' -Text $acquisition -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'external access target and operation limits',
        'block if the required access boundary is unavailable',
        'receipt does not grant filesystem authority'
    )

    Assert-ContractConcepts -Name 'evidence-separation' -Text $contract -RequiredConcepts @(
        'CLASSIC-EXT-O3-EVIDENCE',
        'somente referência evidência',
        'nunca autorizam leitura escrita Classic'
    )
    Assert-ContractConcepts -Name 'storage-separation' -Text $storage -RequiredConcepts @(
        'Classic SDD implementation access is a separate contract',
        'does not grant Classic read write access'
    )

    # No production path may invoke the validation-only broker or its runtime assertion.
    # Broker names are split so this scanned harness file carries no literal invocation of them.
    $invocationPattern = '(?im)(^\s*\.\s+|&\s*|-File\s+|Start-Process\s+|\bpwsh\s+|\bpowershell\s+|\bInvoke-Expression\s+)[^\r\n]*(Invoke-Classic' + 'ExternalAccessFixture|Assert-Classic' + 'ExternalAccessRuntime)'
    $productionCallers = @(Find-ProductionBrokerCallers -Root $repoRoot -InvocationPattern $invocationPattern)
    if ($productionCallers.Count -gt 0) {
        throw ("production-no-fixture-caller: validation-only broker invoked outside validation: {0}" -f ($productionCallers -join ', '))
    }

    # Caller-scan regression: a planted caller in a shipped validation script (listed in the
    # runtime manifest) must be found; a caller inside the broker's fixture directory must not.
    $plantRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-classic-caller-plant-' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path (Join-Path $plantRoot 'scripts/runtime'), (Join-Path $plantRoot 'scripts/validation/fixtures') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/runtime/runtime-manifest.json') -Destination (Join-Path $plantRoot 'scripts/runtime/runtime-manifest.json')
        $shippedFiles = @(
            'scripts/validation/validate-plan.ps1',
            'scripts/validation/fixtures/planted-broker-caller.ps1'
        )
        # The broker name is split so this harness does not itself contain a literal invocation.
        $brokerName = 'Invoke-Classic' + 'ExternalAccessFixture'
        $plantedCaller = '& pwsh -NoProfile -File "scripts/validation/fixtures/' + $brokerName + '.ps1" -Operation read'
        Set-Content -LiteralPath (Join-Path $plantRoot $shippedFiles[0]) -Value $plantedCaller -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $plantRoot $shippedFiles[1]) -Value $plantedCaller -Encoding UTF8
        $plantHits = @(Find-ProductionBrokerCallers -Root $plantRoot -InvocationPattern $invocationPattern)
        if ($plantHits.Count -ne 1 -or (([string]$plantHits[0]) -replace '\\', '/') -ne 'scripts/validation/validate-plan.ps1') {
            throw ("production-no-fixture-caller: planted caller in a shipped validation script was not detected (hits: {0})" -f ($plantHits -join ', '))
        }
    }
    finally {
        if (Test-Path -LiteralPath $plantRoot) { Remove-Item -LiteralPath $plantRoot -Recurse -Force }
    }

    # Detector regression: the scan must catch a real invocation and ignore prohibition prose.
    if (-not ('& "scripts/validation/fixtures/' + $brokerName + '.ps1" -Operation read' -match $invocationPattern)) {
        throw 'production-no-fixture-caller: detector missed a direct invocation'
    }
    if (('The validation-only fixture `scripts/validation/fixtures/' + $brokerName + '.ps1` is never a production boundary.' -match $invocationPattern)) {
        throw 'production-no-fixture-caller: detector flagged prohibition prose as an invocation'
    }

    # Normalization regression: prose formatting and capitalization may vary.
    Assert-ContractConcepts -Name 'normalization-regression' -Text '**EXTERNAL:** Alias / Relative-Path — READ, WRITE' -RequiredConcepts @(
        'external alias relative path', 'read write'
    )

    Write-Host 'Assert-ClassicExternalAccessContract: PASS (portable scope, propagation, reapproval, trusted mapping, O3 evidence separation)' -ForegroundColor Green
}
catch {
    Write-Host ('Assert-ClassicExternalAccessContract: FAIL - {0}' -f $_.Exception.Message) -ForegroundColor Red
    throw
}
}

$sections['DeliveryFlowSimplificationContract'] = {
function Read-Contract([string] $RelativePath) {
    $path = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing contract: $RelativePath" }
    return [System.IO.File]::ReadAllText($path)
}
function Assert-Has([string] $Name, [string] $Text, [string[]] $Markers) {
    foreach ($marker in $Markers) {
        if ($Text.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "$Name missing '$marker'." }
    }
}
$o1 = Read-Contract 'core/skills/orchestrate-analyze/SKILL.md'
$o2 = Read-Contract 'core/skills/orchestrate-deliver/SKILL.md'
$o3 = Read-Contract 'core/skills/orchestrate-develop/SKILL.md'
$table = Read-Contract 'core/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md'
$receipt = Read-Contract 'core/skills/_shared/agents/RECEIPT.md'
Assert-Has 'O1ProportionalAnalysis' $o1 @('proportionally', 'Suggestions do not enter scope without an operator decision', 'Do not create `ANALYSIS/`, `ARCH/`, or `SEC/` solely because')
Assert-Has 'O2SingleApproval' $o2 @('one explicit approval', 'Structural validators and cross-artifact tools may help diagnose', 'not authorization or release gates', 'Minor questions do not block unrelated work')
Assert-Has 'O3SerialPlanProgress' $o3 @('Implementation is always serial', 'The PLAN is the sole persisted implementation-progress source', 'One live progress table is owned by O3')
Assert-Has 'SingleTableOwnership' $table @('Only the owner below renders the contextual progress table', 'Internal skills and delegated children return their result to that owner', 'O2 (`orchestrate-deliver`) with internal spec/plan | O2', 'O3 (`orchestrate-develop`) with internal develop | O3')
Assert-Has 'ReceiptProjectionAndPathSafety' $receipt @('Additional', 'ignored and omitted from the canonical projection', 'including reparse points', 'focused')
foreach ($text in @($o1, $o2, $o3)) {
    foreach ($retired in @('Invoke-O2BrownfieldPreflight.ps1', 'Invoke-PrdPlanChangePreflight.ps1', 'Invoke-O3ArtifactPreflight.ps1', 'Invoke-PlanLedgerClaim.ps1', 'Invoke-ExecutionModeGate.ps1')) {
        if ($text -match [regex]::Escape($retired)) { throw "Active delivery contract still references retired helper $retired." }
    }
}
Write-Host 'DeliveryFlowSimplificationContract: PASS (proportional O1, one O2 approval, serial PLAN-led O3, additive receipt projection)'
}
$sections['ImplementationReadinessContracts'] = {
function Read-Contract([string] $RelativePath) {
    $path = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing contract: $RelativePath" }
    return [System.IO.File]::ReadAllText($path)
}
function Assert-ContractMarkers([string] $Name, [string] $Text, [string[]] $Markers) {
    foreach ($marker in $Markers) {
        if ($Text.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "$Name missing '$marker'." }
    }
}
$direct = Read-Contract 'core/skills/sdd-develop/references/plan-contract.md'
$classic = Read-Contract 'core/skills/sdd-develop/SKILL.md'
$o3 = Read-Contract 'core/skills/orchestrate-develop/SKILL.md'
$table = Read-Contract 'core/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md'
Assert-ContractMarkers 'ClassicPlanReadiness' ($direct + "`n" + $classic) @(
    'one explicit approval covers',
    'dependencies are complete',
    'acceptance is clear enough to evaluate',
    'A checklist or sidecar is optional',
    '`step_by_step` stops after one completed step',
    '`continuous` may advance to the next eligible step',
    'No separate progress header, counter, checkpoint, SESSION flag, task-state table, or claim is required'
)
Assert-ContractMarkers 'O3SerialReadiness' $o3 @(
    'Implementation is always serial',
    'at most one child runs at a time',
    'The PLAN is the sole persisted implementation-progress source',
    'The parent reconciles each result into the PLAN',
    'Two conversations must not implement the same PLAN concurrently'
)
Assert-ContractMarkers 'SingleTableOwnership' $table @(
    'Only the owner below renders the contextual progress table',
    'O2 (`orchestrate-deliver`) with internal spec/plan | O2',
    'O3 (`orchestrate-develop`) with internal develop | O3',
    'do not display a second closeout progress table'
)
foreach ($text in @($classic, $o3)) {
    foreach ($retired in @('Invoke-PlanLedgerClaim.ps1', 'Invoke-ExecutionModeGate.ps1', 'Invoke-O3ArtifactPreflight.ps1')) {
        if ($text -match [regex]::Escape($retired)) { throw "Active Classic/O3 implementation contract still references retired helper $retired." }
    }
}
Write-Host 'ImplementationReadinessContracts: PASS (single PLAN approval, semantic readiness, selected cadence, serial O3, one table owner)'
}
$sections['ChangeContract'] = {
$guidePath = Join-Path $repoRoot 'core/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md'
$templatePath = Join-Path $repoRoot 'core/skills/_shared/templates/features/CHANGE.md'
if (-not (Test-Path -LiteralPath $guidePath -PathType Leaf)) { Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason 'missing optional CHANGE guidance' }
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) { Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason 'missing optional CHANGE template' }
$guide = Get-Content -LiteralPath $guidePath -Raw -Encoding UTF8
$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
foreach ($marker in @('optional context artifacts', 'do not require', 'current behavior', 'intended change', 'concrete risks', 'Existing task lists may be consulted when useful')) {
    if ($guide -notmatch [regex]::Escape($marker)) { Write-Fail -TestName 'Should_Pass_When_ChangeContractPresent' -Reason "CHANGE guidance missing '$marker'" }
}
foreach ($marker in @('Optional change context', 'not required for brownfield work', 'Current behavior', 'Intended change', 'Affected areas and risks')) {
    if ($template -notmatch [regex]::Escape($marker)) { Write-Fail -TestName 'Should_Pass_When_ChangeTemplateIsOptionalContext' -Reason "CHANGE template missing '$marker'" }
}
foreach ($text in @($guide, $template)) {
    if ($text -match '(?im)^\s*(?:you\s+)?must\s+(?:create|write|validate)\b|^\s*(?:CHANGE\.md|TASKS?)\s+(?:is|are)\s+required\b|^\s*required at.*CHANGE\.md') {
        Write-Fail -TestName 'Should_NotRequireChangeOrTasksArtifacts' -Reason 'optional CHANGE guidance contains an active artifact gate'
    }
}
Write-Pass -TestName 'Should_Pass_When_ChangeContractPresent'
Write-Pass -TestName 'Should_Pass_When_ChangeTemplateIsOptionalContext'
Write-Pass -TestName 'Should_NotRequireChangeOrTasksArtifacts'
}
$sections['SelectiveRetrieval'] = {
# Tests:
#   Should_Pass_When_SelectiveRetrievalContractPresent
#   Should_Fail_When_FullDumpPrescriptionPresent
#   Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills
#
# CT5 / REQ-002: selective retrieval must be documented and enforceable.
# Scans in-scope SDD skills/templates for full memory-bank / PRD dump prescriptions.







$selectiveRetrievalRel = $script:ToolkitConstant.SelectiveRetrievalGuideRelativePath
$selectiveRetrievalPath = Join-Path $repoRoot $selectiveRetrievalRel
$ruleId = $script:ToolkitConstant.SelectiveRetrievalRuleId
$inScopeRelativePaths = $script:ToolkitConstant.SelectiveRetrievalInScopeRelativePaths

if (-not (Test-Path -LiteralPath $selectiveRetrievalPath)) {
    Write-Fail -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent' -Reason ("missing guide {0}" -f $selectiveRetrievalRel)
}

$guideText = Get-Content -LiteralPath $selectiveRetrievalPath -Raw -Encoding UTF8
if ($guideText -notmatch [regex]::Escape($ruleId)) {
    Write-Fail -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent' -Reason ("guide missing rule id {0}" -f $ruleId)
}
if ($guideText -notmatch 'Assert-CoreContracts') {
    Write-Fail -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent' -Reason 'guide must name Assert-CoreContracts.ps1 as enforcement'
}
if ($guideText -notmatch 'Compare-SelectiveRetrieval\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent' -Reason 'guide must point to bounded retrieval comparison'
}
$decisionMarkers = @(
    '### Evidence decisions',
    'Select relevant evidence',
    'Establish a gap before returning',
    'Surface contradictions',
    'Stop at sufficient evidence'
)
foreach ($marker in $decisionMarkers) {
    if ($guideText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_EvidenceDecisionGuidancePresent' -Reason ("guide is missing operational decision marker: {0}" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_EvidenceDecisionGuidancePresent'
$evaluationRoot = Join-Path $scriptDir 'fixtures/selective-retrieval-evaluation'
foreach ($evaluationFile in @(
    (Join-Path $scriptDir 'Compare-SelectiveRetrieval.ps1'),
    (Join-Path $evaluationRoot 'cases.json'),
    (Join-Path $evaluationRoot 'report.template.json'),
    (Join-Path $evaluationRoot 'reference-report.json'),
    (Join-Path $evaluationRoot 'case-01/webhook-delivery.md'),
    (Join-Path $evaluationRoot 'case-01/retry-decoy.md'),
    (Join-Path $evaluationRoot 'case-02/audit-export.md'),
    (Join-Path $evaluationRoot 'case-03/billing-runbook.md'),
    (Join-Path $evaluationRoot 'case-03/worker-config.md')
)) {
    if (-not (Test-Path -LiteralPath $evaluationFile -PathType Leaf)) {
        Write-Fail -TestName 'Should_Pass_When_RetrievalEvaluationFixturesPresent' -Reason ("missing evaluation input {0}" -f (Split-Path -Leaf $evaluationFile))
    }
}
Write-Pass -TestName 'Should_Pass_When_SelectiveRetrievalContractPresent'
Write-Pass -TestName 'Should_Pass_When_RetrievalEvaluationFixturesPresent'

# Prescriptions that order a full dump (positive instruction). Lines that only forbid dumps are allowed.
$dumpPrescriptionPatterns = @(
    '(?i)\b(dump|paste|load|include|colar|despejar)\b.{0,80}\b(entire|full|all|integral|completo|inteiro)\b.{0,80}\bmemory-bank\b',
    '(?i)\b(dump|paste|load|include|colar|despejar)\b.{0,80}\bmemory-bank\b.{0,40}\b(entire|full|all|integral|completo|inteiro)\b',
    '(?i)\b(dump|paste|include|colar)\b.{0,80}\b(entire|full|all|integral|completo|inteiro)\b.{0,80}\bPRD\b',
    '(?i)\b(dump|paste|include|colar)\b.{0,80}\bPRD\b.{0,40}\b(entire|full|all|integral|completo|body|inteiro)\b',
    '(?i)\bread\s+all\s+files\s+under\s+memory-bank',
    '(?i)\bload\s+every\s+file\s+(under|in)\s+memory-bank',
    '(?i)\bdump\s+integral\s+(do|de)\s+memory-bank',
    '(?i)\bcolar\s+o\s+PRD\s+completo\b'
)

$antiDumpRequiredPattern = '(?i)(SR-NO-FULL-DUMP|SELECTIVE-RETRIEVAL|selective retrieval|selective read|never dump|must not dump|do not dump|no full dump|sem dump integral|não.*dump integral)'

$forbidNegationPattern = '(?i)(\bnever\b|\bdo\s+\*{0,2}not\*{0,2}\b|\bmust\s+\*{0,2}not\*{0,2}\b|\bprohibit|\bforbid|\bnão\b|\bnao\b|\bproibido\b|\bsem\b)'

$dumpHits = [System.Collections.Generic.List[string]]::new()
$missingAntiDump = [System.Collections.Generic.List[string]]::new()

foreach ($rel in $inScopeRelativePaths) {
    $full = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills' -Reason ("missing in-scope file {0}" -f $rel)
    }

    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8

    if ($rel -match 'SELECTIVE-RETRIEVAL\.md$') {
        # Contract lists forbidden dump phrases as examples; do not treat as prescriptions.
        if ($text -notmatch $antiDumpRequiredPattern) {
            $missingAntiDump.Add($rel)
        }
        continue
    }

    $lines = $text -split "`r?`n"
    $lineNum = 0
    $inMustNotSection = $false
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match '(?i)^#{1,6}\s+Must not\b') {
            $inMustNotSection = $true
            continue
        }
        if ($line -match '^#{1,6}\s+') {
            $inMustNotSection = $false
        }
        foreach ($pattern in $dumpPrescriptionPatterns) {
            if ($line -match $pattern) {
                if ($inMustNotSection -or $line -match $forbidNegationPattern) {
                    continue
                }
                $dumpHits.Add(("{0}:{1}: {2}" -f $rel, $lineNum, $line.Trim()))
            }
        }
    }

    if ($rel -match 'templates/sdd/') {
        continue
    }
    if ($text -notmatch $antiDumpRequiredPattern) {
        $missingAntiDump.Add($rel)
    }
}

if ($dumpHits.Count -gt 0) {
    $sample = ($dumpHits | Select-Object -First 5) -join '; '
    Write-Fail -TestName 'Should_Fail_When_FullDumpPrescriptionPresent' -Reason ("dump prescription(s) found: {0}" -f $sample)
}
Write-Pass -TestName 'Should_Fail_When_FullDumpPrescriptionPresent'

if ($missingAntiDump.Count -gt 0) {
    Write-Fail -TestName 'Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills' -Reason ("missing selective/anti-dump marker in: {0}" -f ($missingAntiDump -join ', '))
}
Write-Pass -TestName 'Should_Pass_When_AntiDumpMarkersPresentInTouchedSkills'

# Templates must represent behavior and acceptance without fixed IDs or section gates.
$prdTemplateRel = 'core/skills/_shared/templates/sdd/PRD.md'
$planTemplateRel = 'core/skills/_shared/templates/sdd/PLAN.md'
$prdTemplate = Get-Content -LiteralPath (Join-Path $repoRoot $prdTemplateRel) -Raw -Encoding UTF8
$planTemplate = Get-Content -LiteralPath (Join-Path $repoRoot $planTemplateRel) -Raw -Encoding UTF8

if ($prdTemplate -notmatch '(?i)Resultado esperado' -or $prdTemplate -notmatch '(?i)Comportamento e aceite' -or $prdTemplate -notmatch '(?i)Impacto brownfield \(quando aplicável\)') {
    Write-Fail -TestName 'Should_Pass_When_PrdTemplateHasReqAcOos' -Reason 'PRD template missing outcome, acceptance, or conditional brownfield context'
}
if ($prdTemplate -notmatch '(?i)não exija uma nomenclatura' -or $prdTemplate -notmatch '(?i)formato BDD' -or $prdTemplate -notmatch '(?i)quantidade fixa') {
    Write-Fail -TestName 'Should_Pass_When_PrdTemplateHasReqAcOos' -Reason 'PRD template must avoid fixed IDs, BDD format, and criterion-count gates'
}
Write-Pass -TestName 'Should_Pass_When_PrdTemplateHasReqAcOos'

if ($planTemplate -notmatch '(?i)single persisted source of implementation progress' -or $planTemplate -notmatch '(?i)Dependências' -or $planTemplate -notmatch '(?i)Evidência e validação') {
    Write-Fail -TestName 'Should_Pass_When_PlanTemplateHasSingleProgressLedger' -Reason 'PLAN template missing its single canonical execution table and dependencies/evidence columns'
}
Write-Pass -TestName 'Should_Pass_When_PlanTemplateHasSingleProgressLedger'

}


$sections['DocumentPlanIgnoreContract'] = {
# Tests:
#   Should_Pass_When_DocumentPlanIsIgnoredAndUntracked
#   Should_Pass_When_DocumentPlanNeverStagesPlanContent

$skillPath = Join-Path $repoRoot 'core/skills/document-plan/SKILL.md'
$skillText = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
foreach ($requiredText in @(
    'ls-files --error-unmatch -- docs/documentation-plan/plan.md',
    'check-ignore --no-index --quiet -- docs/documentation-plan/plan.md',
    'rm --cached -- docs/documentation-plan/plan.md',
    'repository''s root `.gitignore`'
)) {
    if ($skillText -notmatch [regex]::Escape($requiredText)) {
        Write-Fail -TestName 'Should_Pass_When_DocumentPlanIsIgnoredAndUntracked' -Reason ("document-plan contract is missing: {0}" -f $requiredText)
    }
}

if ($skillText -match 'Create `docs/documentation-plan/` inside \*\*this toolkit repo\*\*') {
    Write-Fail -TestName 'Should_Pass_When_DocumentPlanIsIgnoredAndUntracked' -Reason 'skill still forbids the explicitly selected toolkit repository as target'
}

$ignoreRule = @(& git -C $repoRoot check-ignore -v --no-index -- docs/documentation-plan/plan.md 2>$null)
if ($LASTEXITCODE -ne 0 -or ($ignoreRule -join "`n") -notmatch '(^|[/\\])\.gitignore:') {
    Write-Fail -TestName 'Should_Pass_When_DocumentPlanIsIgnoredAndUntracked' -Reason 'documentation plan must be ignored by the repository .gitignore, not only global excludes'
}

$trackedPlan = @(& git -C $repoRoot ls-files --error-unmatch -- docs/documentation-plan/plan.md 2>$null)
if ($LASTEXITCODE -eq 0) {
    Write-Fail -TestName 'Should_Pass_When_DocumentPlanIsIgnoredAndUntracked' -Reason 'documentation plan must not be tracked'
}
Write-Pass -TestName 'Should_Pass_When_DocumentPlanIsIgnoredAndUntracked'

if ($skillText -notmatch '(?i)never stage plan contents or commit the plan' -or
    $skillText -notmatch '(?i)only permitted index mutation is an explicitly confirmed `git rm --cached`') {
    Write-Fail -TestName 'Should_Pass_When_DocumentPlanNeverStagesPlanContent' -Reason 'skill must explicitly forbid staging/committing plan content'
}
Write-Pass -TestName 'Should_Pass_When_DocumentPlanNeverStagesPlanContent'
}

$sections['DocumentPlanHandoffContract'] = {
# Tests:
#   Should_Pass_When_DocumentPlanDefinesActionableIncompleteAndCompleteHandoffs
# This checks the skill's written contract only; it cannot validate model-generated final prose.

$skillPath = Join-Path $repoRoot 'core/skills/document-plan/SKILL.md'
$skillText = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
foreach ($requiredText in @(
    'canonical plan path',
    'document language',
    'progress (`completed/total` steps)',
    'first pending STEP id and title',
    'concise scope and acceptance summary',
    'exact next command `/document-implement`',
    'explicitly state that there is no next step',
    'Do not end with a generic plan-created summary without the applicable handoff above.'
)) {
    if ($skillText -notmatch [regex]::Escape($requiredText)) {
        Write-Fail -TestName 'Should_Pass_When_DocumentPlanDefinesActionableIncompleteAndCompleteHandoffs' -Reason ("document-plan handoff contract is missing: {0}" -f $requiredText)
    }
}
Write-Pass -TestName 'Should_Pass_When_DocumentPlanDefinesActionableIncompleteAndCompleteHandoffs'
}

$sections['WorkflowHardening'] = {
# Tests:
#   Should_Pass_When_WorkflowActionsPinnedAndPermissionsDeclared

$workflowDir = Join-Path $repoRoot '.github/workflows'
foreach ($workflowFile in @(Get-ChildItem -LiteralPath $workflowDir -Filter '*.yml' -File)) {
    $name = $workflowFile.Name
    $lines = @(Get-Content -LiteralPath $workflowFile.FullName -Encoding UTF8)

    foreach ($line in $lines) {
        if ($line -match '^\s*(?:-\s*)?uses:\s*(\S+)') {
            $target = $Matches[1].Trim('"', "'")
            if ($target.StartsWith('./')) { continue }
            if ($target -notmatch '@[0-9a-f]{40}$') {
                Write-Fail -TestName 'Should_Pass_When_WorkflowActionsPinnedAndPermissionsDeclared' -Reason ("{0}: action not pinned to a full commit SHA: {1}" -f $name, $target)
            }
        }
    }

    $jobs = [ordered]@{}
    $currentJob = $null
    $inJobs = $false
    $hasTopPermissions = $false
    foreach ($line in $lines) {
        if ($line -match '^permissions:') { $hasTopPermissions = $true }
        if ($line -match '^jobs:\s*$') { $inJobs = $true; continue }
        if ($inJobs -and $line -match '^[A-Za-z_-]+:') { $inJobs = $false; $currentJob = $null }
        if ($inJobs -and $line -match '^  ([A-Za-z0-9_-]+):\s*$') {
            $currentJob = $Matches[1]
            $jobs[$currentJob] = [System.Collections.Generic.List[string]]::new()
            continue
        }
        if ($null -ne $currentJob) { $jobs[$currentJob].Add($line) }
    }

    if (-not $hasTopPermissions) {
        foreach ($jobName in $jobs.Keys) {
            if (@($jobs[$jobName] | Where-Object { $_ -match '^    permissions:' }).Count -eq 0) {
                Write-Fail -TestName 'Should_Pass_When_WorkflowActionsPinnedAndPermissionsDeclared' -Reason ("{0}: job '{1}' has no permissions and the workflow declares none" -f $name, $jobName)
            }
        }
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch '^(\s*)(?:-\s*)?run:\s*(.*)$') { continue }
        $indent = $Matches[1].Length
        $block = $Matches[2]
        for ($j = $i + 1; $j -lt $lines.Count; $j++) {
            $candidate = $lines[$j]
            if ($candidate.Trim().Length -gt 0 -and ($candidate.Length - $candidate.TrimStart().Length) -le $indent) { break }
            $block += "`n" + $candidate
        }
        if ($block -match '\$\{\{\s*(github\.event\.|inputs\.)') {
            Write-Fail -TestName 'Should_Pass_When_WorkflowActionsPinnedAndPermissionsDeclared' -Reason ("{0}: untrusted expression interpolated in a run block near line {1}" -f $name, ($i + 1))
        }
    }

    if ($jobs.Contains('ci-ok')) {
        $needed = [System.Collections.Generic.List[string]]::new()
        $inNeeds = $false
        foreach ($line in $jobs['ci-ok']) {
            if ($line -match '^    needs:\s*\[(.*)\]\s*$') {
                foreach ($item in $Matches[1].Split(',')) { if ($item.Trim()) { $needed.Add($item.Trim()) } }
                $inNeeds = $false
            }
            elseif ($line -match '^    needs:\s*(\S+)\s*$') { $needed.Add($Matches[1]); $inNeeds = $false }
            elseif ($line -match '^    needs:\s*$') { $inNeeds = $true }
            elseif ($inNeeds -and $line -match '^      -\s*(\S+)') { $needed.Add($Matches[1]) }
            elseif ($inNeeds) { $inNeeds = $false }
        }
        foreach ($jobName in $jobs.Keys) {
            if ($jobName -ne 'ci-ok' -and $needed -notcontains $jobName) {
                Write-Fail -TestName 'Should_Pass_When_WorkflowActionsPinnedAndPermissionsDeclared' -Reason ("{0}: ci-ok does not list job '{1}' in needs" -f $name, $jobName)
            }
        }
    }
}
Write-Pass -TestName 'Should_Pass_When_WorkflowActionsPinnedAndPermissionsDeclared'

}

$sections['SpawnChecklistAudit'] = {
# Tests:
#   Should_Classify_When_ThresholdsAreInclusive
#   Should_Delegate_When_AnyDimensionExceedsOrExclusionApplies
#   Should_ReopenCountsAndReclassifyWhenScopeGrows
#   Should_AcceptAndRejectSpawnAuditLineShapes
#   Should_ContinueOnlyWithinReceiptScopeAndCount
#   Should_Pass_When_CanonicalSpawnChecklistAndModesArePresent
#   Should_Pass_When_UpdatedConsumersPointToCanonicalSpawnWithoutRTrivialFingerprint
#   Should_Fail_When_RTrivialFingerprintIsCopiedToStackSkillConsumer
#   Should_Fail_When_RTrivialFingerprintIsCopiedToOrchestratorConsumer
#   Should_Fail_When_RTrivialFingerprintIsCopiedToSddPlanConsumer
#   Should_Fail_When_RTrivialFingerprintIsCopiedToMemoryBankReference

function Test-SpawnClassification {
    param([int] $Edited, [int] $Read, [int] $Lines, [string] $Exclusion = '')
    if ($Edited -lt 0 -or $Read -lt 0 -or $Lines -lt 0) { return 'delegate' }
    if ($Edited -le 3 -and $Read -le 6 -and $Lines -le 150 -and [string]::IsNullOrWhiteSpace($Exclusion)) { return 'trivial' }
    return 'delegate'
}

function Test-SpawnAuditLine {
    param([string] $Line)
    $pattern = '^\[Spawn\] (trivial|delegate|continue|new-child) mode=(adaptive|always) edited=\d+ read=\d+ lines=\d+ criterion=(files-edited|files-read|lines|long-command|shared-contract|security|search-count|topic|scope|count-limit|no-record|doubt|none)$'
    if ($Line -cnotmatch $pattern) { return $false }
    if ($Matches[1] -eq 'trivial' -and ($Matches[2] -cne 'adaptive' -or $Matches[3] -cne 'none')) { return $false }
    if ($Matches[1] -eq 'continue' -and $Matches[3] -cne 'none') { return $false }
    return $true
}

function Get-SpawnContinuationDecision {
    param(
        [string] $ReceiptStatus,
        [bool] $SameScope,
        [bool] $InScopePaths,
        [bool] $Edits,
        [int] $Count,
        [bool] $HasRecord,
        [bool] $TopicClear
    )
    if (-not $HasRecord) { return 'new-child:no-record' }
    if (-not $TopicClear) { return 'new-child:doubt' }
    if ($ReceiptStatus -cne 'done' -or -not $SameScope -or -not $InScopePaths -or $Edits) { return 'new-child:scope' }
    if ($Count -ge 2) { return 'new-child:count-limit' }
    return 'continue'
}

$classificationName = 'Should_Classify_When_ThresholdsAreInclusive'
if ((Test-SpawnClassification -Edited 3 -Read 6 -Lines 150) -cne 'trivial' -or
    (Test-SpawnClassification -Edited 0 -Read 0 -Lines 0) -cne 'trivial') {
    Write-Fail -TestName $classificationName -Reason 'inclusive limits and a zero-sized task must be trivial'
}
Write-Pass -TestName $classificationName

$delegateName = 'Should_Delegate_When_AnyDimensionExceedsOrExclusionApplies'
foreach ($case in @(
    @{ Edited = 4; Read = 0; Lines = 0; Exclusion = '' },
    @{ Edited = 0; Read = 7; Lines = 0; Exclusion = '' },
    @{ Edited = 0; Read = 0; Lines = 151; Exclusion = '' },
    @{ Edited = 3; Read = 6; Lines = 150; Exclusion = 'security' }
)) {
    if ((Test-SpawnClassification @case) -cne 'delegate') {
        Write-Fail -TestName $delegateName -Reason 'a value over one threshold or an exclusion must delegate'
    }
}
Write-Pass -TestName $delegateName

$reopenName = 'Should_ReopenCountsAndReclassifyWhenScopeGrows'
$openedFiles = @('a', 'b', 'a', 'c')
$distinctReadCount = @($openedFiles | Select-Object -Unique).Count
if ($distinctReadCount -ne 3 -or (Test-SpawnClassification -Edited 2 -Read $distinctReadCount -Lines 80) -cne 'trivial') {
    Write-Fail -TestName $reopenName -Reason 'reopening a file must not increase distinct reads'
}
$initialClass = Test-SpawnClassification -Edited 2 -Read 3 -Lines 80
$grownClass = Test-SpawnClassification -Edited 2 -Read 3 -Lines 160
if ($initialClass -cne 'trivial' -or $grownClass -cne 'delegate') {
    Write-Fail -TestName $reopenName -Reason 'scope growth must be reclassified before continuing'
}
Write-Pass -TestName $reopenName

$auditName = 'Should_AcceptAndRejectSpawnAuditLineShapes'
$validAuditLines = @(
    '[Spawn] trivial mode=adaptive edited=1 read=2 lines=20 criterion=none',
    '[Spawn] delegate mode=always edited=1 read=1 lines=5 criterion=none',
    '[Spawn] delegate mode=adaptive edited=4 read=2 lines=30 criterion=files-edited',
    '[Spawn] continue mode=adaptive edited=0 read=1 lines=0 criterion=none',
    '[Spawn] new-child mode=adaptive edited=1 read=1 lines=10 criterion=scope'
)
foreach ($line in $validAuditLines) {
    if (-not (Test-SpawnAuditLine -Line $line)) { Write-Fail -TestName $auditName -Reason ("valid audit line rejected: {0}" -f $line) }
}
$invalidAuditLines = @(
    '[Spawn] trivial mode=adaptive edited=1 read=2 lines=20 criterion=none extra text',
    '[Spawn] delegate mode=adaptive edited=x read=2 lines=30 criterion=files-edited',
    '[Spawn] delegate mode=adaptive edited=4 read=2 lines=30 criterion=model',
    '[Spawn] delegate mode=auto edited=4 read=2 lines=30 criterion=files-edited',
    '[Spawn] trivial mode=always edited=1 read=1 lines=5 criterion=none',
    '[Spawn] continue mode=adaptive edited=0 read=1 lines=0 criterion=none count=1',
    '[Spawn] continue mode=adaptive edited=0 read=1 lines=0 criterion=none path=core/a.md'
)
foreach ($line in $invalidAuditLines) {
    if (Test-SpawnAuditLine -Line $line) { Write-Fail -TestName $auditName -Reason ("invalid audit line accepted: {0}" -f $line) }
}
Write-Pass -TestName $auditName

$continuationName = 'Should_ContinueOnlyWithinReceiptScopeAndCount'
$continuationCases = @(
    @{ Status = 'done'; SameScope = $true; InScope = $true; Edits = $false; Count = 0; HasRecord = $true; TopicClear = $true; Expected = 'continue' },
    @{ Status = 'done'; SameScope = $true; InScope = $true; Edits = $false; Count = 1; HasRecord = $true; TopicClear = $true; Expected = 'continue' },
    @{ Status = 'done'; SameScope = $true; InScope = $true; Edits = $false; Count = 2; HasRecord = $true; TopicClear = $true; Expected = 'new-child:count-limit' },
    @{ Status = 'done'; SameScope = $true; InScope = $true; Edits = $true; Count = 0; HasRecord = $true; TopicClear = $true; Expected = 'new-child:scope' },
    @{ Status = 'blocked'; SameScope = $true; InScope = $true; Edits = $false; Count = 0; HasRecord = $true; TopicClear = $true; Expected = 'new-child:scope' },
    @{ Status = 'failed'; SameScope = $true; InScope = $true; Edits = $false; Count = 0; HasRecord = $true; TopicClear = $true; Expected = 'new-child:scope' },
    @{ Status = ''; SameScope = $true; InScope = $true; Edits = $false; Count = 0; HasRecord = $true; TopicClear = $true; Expected = 'new-child:scope' },
    @{ Status = 'done'; SameScope = $false; InScope = $true; Edits = $false; Count = 0; HasRecord = $true; TopicClear = $true; Expected = 'new-child:scope' },
    @{ Status = 'done'; SameScope = $true; InScope = $false; Edits = $false; Count = 0; HasRecord = $true; TopicClear = $true; Expected = 'new-child:scope' },
    @{ Status = 'done'; SameScope = $true; InScope = $true; Edits = $false; Count = 0; HasRecord = $false; TopicClear = $true; Expected = 'new-child:no-record' },
    @{ Status = 'done'; SameScope = $true; InScope = $true; Edits = $false; Count = 0; HasRecord = $true; TopicClear = $false; Expected = 'new-child:doubt' }
)
foreach ($case in $continuationCases) {
    $decision = Get-SpawnContinuationDecision -ReceiptStatus $case.Status -SameScope $case.SameScope -InScopePaths $case.InScope -Edits $case.Edits -Count $case.Count -HasRecord $case.HasRecord -TopicClear $case.TopicClear
    if ($decision -cne $case.Expected) {
        Write-Fail -TestName $continuationName -Reason ("expected {0}, got {1}" -f $case.Expected, $decision)
    }
}
Write-Pass -TestName $continuationName

$spawnText = Get-Content -LiteralPath (Join-Path $repoRoot 'core/skills/_shared/agents/SPAWN.md') -Raw -Encoding UTF8
$digestText = Get-Content -LiteralPath (Join-Path $repoRoot 'core/skills/_shared/agents/SPAWN-DIGEST.md') -Raw -Encoding UTF8
$policyPath = 'core/policy/orchestrator-session.md'
$policyText = Get-Content -LiteralPath (Join-Path $repoRoot $policyPath) -Raw -Encoding UTF8
$contentName = 'Should_Pass_When_CanonicalSpawnChecklistAndModesArePresent'
foreach ($marker in @('## Delegation checklist', '## Audit line', 'edited <= 3', 'read <= 6', 'lines <= 150', '4, 7 or 151', 'at most 2 times', 'no-record', 'doubt')) {
    if ($spawnText -notmatch [regex]::Escape($marker)) { Write-Fail -TestName $contentName -Reason ("SPAWN.md is missing: {0}" -f $marker) }
}
foreach ($marker in @('edited <= 3', 'read <= 6', 'lines <= 150', '[Spawn]', 'ROSTER.md', '*-developer` 2', 'orchestrate-*` 4')) {
    if ($digestText -notmatch [regex]::Escape($marker)) { Write-Fail -TestName $contentName -Reason ("SPAWN-DIGEST.md is missing: {0}" -f $marker) }
}
if ($policyText -notmatch '(?m)^## Modes\s*$') {
    Write-Fail -TestName $contentName -Reason 'orchestrator-session.md is missing the canonical Modes section'
}
$modeHeader = '| Mode | Trivial task (checklist in `SPAWN.md`) | Other tasks | `qa_checklist` | Agent unavailable |'
$canonicalModeHeaders = @()
foreach ($root in @('core', 'docs')) {
    $rootPath = Join-Path $repoRoot $root
    foreach ($file in @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.md' -or $_.Extension -eq '.mdx' })) {
        $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        if ($text.Contains($modeHeader)) { $canonicalModeHeaders += $file.FullName }
    }
}
$expectedPolicyPath = Join-Path $repoRoot $policyPath
if ($canonicalModeHeaders.Count -ne 1 -or $canonicalModeHeaders[0] -ne $expectedPolicyPath) {
    Write-Fail -TestName $contentName -Reason 'the canonical spawn Modes table must appear once, in orchestrator-session.md'
}
Write-Pass -TestName $contentName

function Get-SpawnConsumerDuplicateViolations {
    param([hashtable] $Documents, [hashtable[]] $Rules)
    $violations = [System.Collections.Generic.List[string]]::new()
    foreach ($rule in $Rules) {
        $allowed = @($rule.AllowedFiles) + @($rule.OwnerFile)
        foreach ($path in $Documents.Keys) {
            if ($Documents[$path].Contains($rule.Fingerprint) -and $path -notin $allowed) {
                $violations.Add(("{0}:{1}" -f $path, $rule.RuleId))
            }
        }
    }
    return $violations.ToArray()
}

$consumerFingerprint = 'The task is trivial only when edited <= 3, read <= 6, lines <= 150 and no exclusion applies.'
$consumerRule = @{
    RuleId = 'R-TRIVIAL'
    OwnerFile = 'core/skills/_shared/agents/SPAWN.md'
    Fingerprint = $consumerFingerprint
    AllowedFiles = @()
}
$consumerPaths = @('core/skills/_shared/skills-catalog/OPERATOR.md')
$consumerDocuments = @{}
foreach ($consumerPath in $consumerPaths) {
    $consumerFullPath = Join-Path $repoRoot $consumerPath
    if (-not (Test-Path -LiteralPath $consumerFullPath -PathType Leaf)) {
        Write-Fail -TestName 'Should_Pass_When_UpdatedConsumersPointToCanonicalSpawnWithoutRTrivialFingerprint' -Reason ("missing S4 consumer: {0}" -f $consumerPath)
    }
    $consumerText = Get-Content -LiteralPath $consumerFullPath -Raw -Encoding UTF8
    if (-not $consumerText.Contains('SPAWN.md')) {
        Write-Fail -TestName 'Should_Pass_When_UpdatedConsumersPointToCanonicalSpawnWithoutRTrivialFingerprint' -Reason ("consumer lacks SPAWN.md pointer: {0}" -f $consumerPath)
    }
    $consumerDocuments[$consumerPath] = $consumerText
}
$consumerViolations = @(Get-SpawnConsumerDuplicateViolations -Documents $consumerDocuments -Rules @($consumerRule))
if ($consumerViolations.Count -gt 0) {
    Write-Fail -TestName 'Should_Pass_When_UpdatedConsumersPointToCanonicalSpawnWithoutRTrivialFingerprint' -Reason ("consumer repeats normative R-TRIVIAL text: {0}" -f $consumerViolations[0])
}
Write-Pass -TestName 'Should_Pass_When_UpdatedConsumersPointToCanonicalSpawnWithoutRTrivialFingerprint'

$syntheticConsumerCases = @(
    @{ Name = 'Should_Fail_When_RTrivialFingerprintIsCopiedToStackSkillConsumer'; Path = 'core/skills/react-developer/SKILL.md' },
    @{ Name = 'Should_Fail_When_RTrivialFingerprintIsCopiedToOrchestratorConsumer'; Path = 'core/skills/orchestrate-develop/SKILL.md' },
    @{ Name = 'Should_Fail_When_RTrivialFingerprintIsCopiedToSddPlanConsumer'; Path = 'core/skills/sdd-plan/SKILL.md' },
    @{ Name = 'Should_Fail_When_RTrivialFingerprintIsCopiedToMemoryBankReference'; Path = 'core/skills/memory-bank-init/references/inventory-specialist-synthesis.md' }
)
foreach ($case in $syntheticConsumerCases) {
    $syntheticDocuments = @{ $case.Path = $consumerFingerprint }
    $syntheticViolations = @(Get-SpawnConsumerDuplicateViolations -Documents $syntheticDocuments -Rules @($consumerRule))
    $expectedViolation = "{0}:R-TRIVIAL" -f $case.Path
    if ($syntheticViolations -notcontains $expectedViolation) {
        Write-Fail -TestName $case.Name -Reason ("synthetic consumer did not report {0}" -f $expectedViolation)
    }
    Write-Pass -TestName $case.Name
}
}

$sections['SpawnSizeBudget'] = {
# Tests:
#   Should_Fail_When_SpawnDigestExceeds2500BytesLf
#   Should_Warn_When_SpawnExceeds14000BytesLf
#   Should_Fail_When_NormativeFingerprintIsDuplicatedOutsideOwner
#   Should_Fail_When_ChecklistLimitsContradictOwner
#   Should_Fail_When_ChecklistLimitsContradictOwner

function Get-LfUtf8ByteCount {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'File')][string] $Path,
        [Parameter(Mandatory = $true, ParameterSetName = 'Text')][AllowEmptyString()][string] $Text
    )
    if ($PSCmdlet.ParameterSetName -eq 'File') {
        $Text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    }
    $normalized = $Text -replace "`r`n", "`n" -replace "`r", "`n"
    return [System.Text.Encoding]::UTF8.GetByteCount($normalized)
}

function Get-SpawnDuplicateViolations {
    param([hashtable] $Documents, [hashtable[]] $Rules)
    $violations = [System.Collections.Generic.List[string]]::new()
    foreach ($rule in $Rules) {
        $allowed = @($rule.AllowedFiles) + @($rule.OwnerFile)
        foreach ($path in $Documents.Keys) {
            if ($Documents[$path].Contains($rule.Fingerprint) -and $path -notin $allowed) {
                $violations.Add(("{0}:{1}" -f $path, $rule.RuleId))
            }
        }
    }
    return $violations.ToArray()
}

function Test-SpawnChecklistContradiction {
    param([string] $Text)
    return ($Text -match '(?i)edited\s*<=\s*4' -or
        $Text -match '(?i)read\s*<=\s*7' -or
        $Text -match '(?i)lines\s*<=\s*151' -or
        $Text -match '(?is)always.{0,120}trivial\s+in\s+the\s+parent')
}

$sizeName = 'Should_Fail_When_SpawnDigestExceeds2500BytesLf'
$overBudget = Get-LfUtf8ByteCount -Text ('a' * 2501)
$atBudget = Get-LfUtf8ByteCount -Text ('a' * 2500)
$crlfText = ('x' * 2480) + (("`r`n") * 20)
$rawCrlfBytes = [System.Text.Encoding]::UTF8.GetByteCount($crlfText)
$normalizedCrlf = Get-LfUtf8ByteCount -Text $crlfText
$accentBytes = Get-LfUtf8ByteCount -Text 'é'
if ($overBudget -ne 2501 -or $overBudget -le 2500 -or $atBudget -ne 2500 -or $rawCrlfBytes -ne 2520 -or $normalizedCrlf -ne 2500 -or $accentBytes -ne 2) {
    Write-Fail -TestName $sizeName -Reason 'UTF-8/LF byte-count boundary or normalization failed'
}
$digestPath = Join-Path $repoRoot 'core/skills/_shared/agents/SPAWN-DIGEST.md'
$digestBytes = Get-LfUtf8ByteCount -Path $digestPath
if ($digestBytes -gt 2500) {
    Write-Fail -TestName $sizeName -Reason ("SPAWN-DIGEST.md is {0} bytes (UTF-8, LF); ceiling is 2500" -f $digestBytes)
}
Write-Pass -TestName $sizeName

$spawnBytes = Get-LfUtf8ByteCount -Path (Join-Path $repoRoot 'core/skills/_shared/agents/SPAWN.md')
if ($spawnBytes -gt 14000) {
    Write-Warning ("SPAWN.md is {0} bytes (UTF-8, LF); reference is 14000 (warning only)" -f $spawnBytes)
}
Write-Pass -TestName 'Should_Warn_When_SpawnExceeds14000BytesLf'

$duplicateName = 'Should_Fail_When_NormativeFingerprintIsDuplicatedOutsideOwner'
$fingerprint = 'Each dispatched task is one child assignment: once that child ' + 'returns any result'
$syntheticDocuments = @{
    'core/x.md' = $fingerprint
    'docs/y.md' = $fingerprint
}
$syntheticRule = @{
    RuleId = 'R-LIFECYCLE'
    OwnerFile = 'core/x.md'
    Fingerprint = $fingerprint
    AllowedFiles = @()
}
$syntheticViolations = @(Get-SpawnDuplicateViolations -Documents $syntheticDocuments -Rules @($syntheticRule))
if ($syntheticViolations -notcontains 'docs/y.md:R-LIFECYCLE') {
    Write-Fail -TestName $duplicateName -Reason 'synthetic duplicate did not report file:rule'
}

$roots = @('core', 'docs', 'docs-site', 'adapters', 'scripts')
$documents = @{}
foreach ($root in $roots) {
    $rootPath = Join-Path $repoRoot $root
    foreach ($file in @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.md' -or $_.Extension -eq '.mdx' -or $_.Extension -eq '.ps1' })) {
        $relative = $file.FullName.Substring($repoRoot.TrimEnd('\', '/').Length).TrimStart('\', '/').Replace('\', '/')
        $documents[$relative] = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    }
}
$rules = @(
    @{
        RuleId = 'R-LIFECYCLE'
        OwnerFile = 'core/skills/_shared/agents/SPAWN.md'
        Fingerprint = $fingerprint
        AllowedFiles = @(
            'adapters/antigravity/README.md', 'adapters/claude/README.md', 'adapters/codex/README.md',
            'adapters/copilot/README.md', 'adapters/cursor/README.md', 'adapters/grok/README.md',
            'adapters/hermes/README.md', 'adapters/opencode/README.md', 'adapters/openhands/README.md',
            'adapters/zcode/README.md'
        )
    }
)
$actualViolations = @(Get-SpawnDuplicateViolations -Documents $documents -Rules $rules)
if ($actualViolations.Count -gt 0) {
    Write-Fail -TestName $duplicateName -Reason ("duplicate normative rule {0}" -f $actualViolations[0])
}
Write-Pass -TestName $duplicateName

$contradictionName = 'Should_Fail_When_ChecklistLimitsContradictOwner'
$contradictoryText = 'edited <= 4; read <= 7; lines <= 151; always trivial in the parent'
$spawnText = Get-Content -LiteralPath (Join-Path $repoRoot 'core/skills/_shared/agents/SPAWN.md') -Raw -Encoding UTF8
if (-not (Test-SpawnChecklistContradiction -Text $contradictoryText)) {
    Write-Fail -TestName $contradictionName -Reason 'synthetic contradictory checklist limits were accepted'
}
if (Test-SpawnChecklistContradiction -Text $spawnText) {
    Write-Fail -TestName $contradictionName -Reason 'the canonical SPAWN checklist contradicts its owner'
}
Write-Pass -TestName $contradictionName
}

$sections['SpawnHostMatrix'] = {
# Tests:
#   Should_Pass_When_SpawnHostMatrixMatchesRegistry
#   Should_Fail_When_SpawnHostMatrixOmitsRegisteredAgent
#   Should_Fail_When_OfficialEvidenceHasNoUrl

function Get-SpawnHostMatrixViolations {
    param([string] $MatrixText, [object[]] $Agents)
    $rows = @{}
    $inMatrix = $false
    foreach ($line in ($MatrixText -split "`r?`n")) {
        if ($line -eq '## Nesting matrix') { $inMatrix = $true; continue }
        if ($inMatrix -and $line -match '^## ') { break }
        if (-not $inMatrix -or $line -notmatch '^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$') { continue }
        $id = $Matches[1].Trim()
        if ($id -eq 'Agent id' -or $id -match '^-+$') { continue }
        $rows[$id] = @{
            child = $Matches[2].Trim(); source = $Matches[3].Trim(); evidence = $Matches[4].Trim()
            checked = $Matches[5].Trim(); restriction = $Matches[6].Trim()
        }
    }

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($agent in $Agents) {
        $id = [string]$agent.id
        if (-not $rows.ContainsKey($id)) { $issues.Add(("docs/SPAWN.md:{0} missing matrix row" -f $id)); continue }
        $row = $rows[$id]
        $capability = [string]$agent.capabilities.subagents
        if ($capability -eq 'none') {
            if ($id -ne 'openhands' -or $row.child -ne 'n/a' -or $row.source -ne 'n/a' -or $row.evidence -ne 'none' -or $row.checked -notmatch '^\d{4}-\d{2}-\d{2}$' -or $row.restriction -ne 'n/a') {
                $issues.Add(("docs/SPAWN.md:{0} must mirror subagents=none as n/a/n/a/none/date/n/a" -f $id))
            }
            continue
        }
        if ($capability -ne 'native') { $issues.Add(("docs/SPAWN.md:{0} has unsupported registry capability {1}" -f $id, $capability)); continue }
        if ($row.child -notin @('yes','no','unknown')) { $issues.Add(("docs/SPAWN.md:{0} invalid Child can spawn child '{1}'" -f $id, $row.child)) }
        if ($row.evidence -notin @('official','local','unknown')) { $issues.Add(("docs/SPAWN.md:{0} invalid Evidence level '{1}'" -f $id, $row.evidence)) }
        if ($row.restriction -notin @('host-enforced','prompt-only','unknown')) { $issues.Add(("docs/SPAWN.md:{0} invalid Restriction type '{1}'" -f $id, $row.restriction)) }
        if ($row.evidence -eq 'unknown' -and ($row.child -ne 'unknown' -or $row.source -ne 'unknown' -or $row.checked -ne '-' -or $row.restriction -ne 'unknown')) { $issues.Add(("docs/SPAWN.md:{0} unknown evidence requires unknown/unknown/-/unknown" -f $id)) }
        if ($row.evidence -eq 'official' -and $row.source -notmatch '^https?://\S+$') { $issues.Add(("docs/SPAWN.md:{0} official evidence requires a URL" -f $id)) }
        if ($row.evidence -eq 'local' -and ($row.source -notmatch '^adapters/[^|]+$' -or -not (Test-Path -LiteralPath (Join-Path $repoRoot $row.source)))) { $issues.Add(("docs/SPAWN.md:{0} local evidence requires an existing adapters path" -f $id)) }
        if ($row.evidence -in @('official','local') -and $row.checked -notmatch '^\d{4}-\d{2}-\d{2}$') { $issues.Add(("docs/SPAWN.md:{0} checked date is invalid" -f $id)) }
    }
    foreach ($id in $rows.Keys) { if (@($Agents | Where-Object { $_.id -eq $id }).Count -eq 0) { $issues.Add(("docs/SPAWN.md:{0} is not registered" -f $id)) } }
    return @($issues)
}

$docsPath = Join-Path $repoRoot 'docs/SPAWN.md'
$docsText = Get-Content -LiteralPath $docsPath -Raw -Encoding UTF8
$registry = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters/registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$agents = @($registry.agents)
if (@($agents | Where-Object { $_.capabilities.subagents -eq 'native' }).Count -ne 9 -or @($agents | Where-Object { $_.capabilities.subagents -eq 'none' }).Count -ne 1) {
    Write-Fail -TestName 'Should_Pass_When_SpawnHostMatrixMatchesRegistry' -Reason 'registry must contain nine native agents and one none agent'
}
$requiredNote = 'A prompt instruction is not a host block.'
if ($docsText -notmatch [regex]::Escape($requiredNote)) { Write-Fail -TestName 'Should_Pass_When_SpawnHostMatrixMatchesRegistry' -Reason ('docs/SPAWN.md missing note: {0}' -f $requiredNote) }
$violations = @(Get-SpawnHostMatrixViolations -MatrixText $docsText -Agents $agents)
if ($violations.Count -gt 0) { Write-Fail -TestName 'Should_Pass_When_SpawnHostMatrixMatchesRegistry' -Reason $violations[0] }
Write-Pass -TestName 'Should_Pass_When_SpawnHostMatrixMatchesRegistry'

$missingRowText = $docsText -replace '(?m)^\| hermes \|[^\r\n]*\r?\n',''
$missingRowIssues = @(Get-SpawnHostMatrixViolations -MatrixText $missingRowText -Agents $agents)
if (-not (@($missingRowIssues | Where-Object { $_ -eq 'docs/SPAWN.md:hermes missing matrix row' }).Count -gt 0)) { Write-Fail -TestName 'Should_Fail_When_SpawnHostMatrixOmitsRegisteredAgent' -Reason 'synthetic matrix without hermes did not report docs/SPAWN.md:hermes' }
Write-Pass -TestName 'Should_Fail_When_SpawnHostMatrixOmitsRegisteredAgent'

$badOfficialText = $docsText.Replace('| antigravity | unknown | unknown | unknown | - | unknown |','| antigravity | yes | adapters/antigravity/README.md | official | 2026-11-06 | prompt-only |')
$officialIssues = @(Get-SpawnHostMatrixViolations -MatrixText $badOfficialText -Agents $agents)
if (-not (@($officialIssues | Where-Object { $_ -eq 'docs/SPAWN.md:antigravity official evidence requires a URL' }).Count -gt 0)) { Write-Fail -TestName 'Should_Fail_When_OfficialEvidenceHasNoUrl' -Reason 'synthetic official row without URL was accepted' }
Write-Pass -TestName 'Should_Fail_When_OfficialEvidenceHasNoUrl'
}

$sections['SkillReferenceRouteContracts'] = {
# Tests:
#   Should_Pass_When_SkillReferenceRouteContractIsValid
#   Should_Fail_When_SkillRoutePathIsMissing
#   Should_Fail_When_SkillRoutePathEscapesItsRoot
#   Should_Fail_When_ResolvedRouteTargetEscapesPhysicalRoot
#   Should_Fail_When_SkillRouteJunctionEscapesItsRoot (when junction creation is available)
#   Should_Fail_When_SkillRoutePathIsBothRequiredAndExcluded
#   Should_Fail_When_ContextualComplexitySourceIsWrong

$validator = Join-Path $repoRoot 'scripts/validation/validate-skill-contracts.ps1'
$basePath = Join-Path $repoRoot 'scripts/validation/contracts/skill-contracts.json'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $tempRoot)
try {
    $baseJson = Get-Content -LiteralPath $basePath -Raw -Encoding UTF8
    function Invoke-SkillRouteFixture {
        param([string] $Name, [scriptblock] $Mutate, [int] $ExpectedExit, [string] $ExpectedFailureMarker)
        $fixture = $baseJson | ConvertFrom-Json
        if ($Mutate) { & $Mutate $fixture }
        $fixturePath = Join-Path $tempRoot ($Name + '.json')
        $fixture | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $fixturePath -Encoding UTF8
        $output = @(& pwsh -NoProfile -File $validator -RepoRoot $repoRoot -ContractPath $fixturePath 2>&1)
        $actualExit = $LASTEXITCODE
        if ($actualExit -ne $ExpectedExit) {
            Write-Fail -TestName $Name -Reason ("expected exit {0}, got {1}: {2}" -f $ExpectedExit, $actualExit, (($output | Select-Object -Last 4) -join ' '))
        }
        if ($ExpectedExit -ne 0 -and ($output -join "`n") -notmatch 'referenceRoutes|complexitySources|rule=file-path') {
            Write-Fail -TestName $Name -Reason 'diagnostic omitted skill route or contextual complexity rule'
        }
        if ($ExpectedFailureMarker -and ($output -join "`n") -notmatch [regex]::Escape($ExpectedFailureMarker)) {
            Write-Fail -TestName $Name -Reason ("diagnostic did not identify {0}" -f $ExpectedFailureMarker)
        }
        Write-Pass -TestName $Name
    }
    Invoke-SkillRouteFixture -Name 'Should_Pass_When_SkillReferenceRouteContractIsValid' -Mutate $null -ExpectedExit 0
    $danglingLinkInspector = {
        param($path)
        # Simulate a directory entry that exists as a reparse point while its
        # target is absent, the case where Test-Path alone returns false.
        return @{ exists = $false; reparsePoint = $true }
    }
    if (-not (Test-ToolkitForbiddenPathEntryExists -RootPath $tempRoot -RelativePath 'dangling-skill-link' -EntryInspector $danglingLinkInspector)) {
        Write-Fail -TestName 'Should_Treat_DanglingForbiddenSkillLinkAsExisting' -Reason 'dangling reparse entry was treated as absent'
    }
    Write-Pass -TestName 'Should_Treat_DanglingForbiddenSkillLinkAsExisting'
    Invoke-SkillRouteFixture -Name 'Should_Fail_When_SkillRoutePathIsMissing' -Mutate {
        param($fixture) $fixture.referenceRoutes[0].routes[0].required += 'references/missing-s4-fixture.md'
    } -ExpectedExit 1
    Invoke-SkillRouteFixture -Name 'Should_Fail_When_SkillRoutePathEscapesItsRoot' -Mutate {
        param($fixture) $fixture.referenceRoutes[0].routes[0].required += 'references/../../outside-s4-fixture.md'
    } -ExpectedExit 1 -ExpectedFailureMarker 'rule=path-traversal'
    Invoke-SkillRouteFixture -Name 'Should_Fail_When_SkillRouteOwnerEscapesSkillsRoot' -Mutate {
        param($fixture) $fixture.referenceRoutes[0].owner = '../outside-s4-fixture.md'
    } -ExpectedExit 1 -ExpectedFailureMarker 'rule=owner-path'
    Invoke-SkillRouteFixture -Name 'Should_Fail_When_SharedRuleOwnerEscapesSkillsRoot' -Mutate {
        param($fixture) $fixture.referenceRoutes[0].sharedRules[0].owner = '../outside-s4-fixture.md'
    } -ExpectedExit 1 -ExpectedFailureMarker 'rule=shared-owner-path'
    Invoke-SkillRouteFixture -Name 'Should_Fail_When_ContractFileEscapesSkillRoot' -Mutate {
        param($fixture) $fixture.contracts[0].files[0] = '../outside-s4-fixture.md'
    } -ExpectedExit 1 -ExpectedFailureMarker 'rule=file-path'
    $syntheticResolver = {
        param($path)
        if ($path -eq 'fixture-root') { return (Join-Path $tempRoot 'physical-root') }
        return (Join-Path $tempRoot 'outside/route.md')
    }.GetNewClosure()
    if (Test-ToolkitPathWithinRoot -RootPath 'fixture-root' -CandidatePath 'fixture-root/references/route.md' -PhysicalResolver $syntheticResolver) {
        Write-Fail -TestName 'Should_Fail_When_ResolvedRouteTargetEscapesPhysicalRoot' -Reason 'injected physical target outside root was accepted'
    }
    Write-Pass -TestName 'Should_Fail_When_ResolvedRouteTargetEscapesPhysicalRoot'

    $junctionRepo = Join-Path $tempRoot 'junction-repo'
    $junctionSkill = Join-Path $junctionRepo 'core/skills/route-fixture'
    $junctionOutside = Join-Path $tempRoot 'junction-target'
    [void](New-Item -ItemType Directory -Path $junctionSkill -Force)
    [void](New-Item -ItemType Directory -Path $junctionOutside -Force)
    Set-Content -LiteralPath (Join-Path $junctionSkill 'SKILL.md') -Value 'fixture' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $junctionOutside 'route.md') -Value 'outside' -Encoding UTF8
    $junctionContract = @{
        skillsRoot = 'core/skills'
        referenceRoutes = @(@{
            skill = 'route-fixture'; owner = 'core/skills/route-fixture/SKILL.md'
            routes = @(@{ mode = 'fixture'; condition = 'junction escape case'; required = @('references/route.md'); conditional = @(); excluded = @() })
            sharedRules = @()
        })
        contracts = @()
    }
    $junctionContractPath = Join-Path $tempRoot 'junction-contract.json'
    $junctionContract | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $junctionContractPath -Encoding UTF8
    $junctionCreated = $false
    try {
        [void](New-Item -ItemType Junction -Path (Join-Path $junctionSkill 'references') -Target $junctionOutside -ErrorAction Stop)
        $junctionCreated = $true
    }
    catch {
        Write-Host 'INFO: junction integration fixture unavailable; deterministic injected-resolver containment fixture passed.'
    }
    if ($junctionCreated) {
        $junctionOutput = @(& pwsh -NoProfile -File $validator -RepoRoot $junctionRepo -ContractPath $junctionContractPath 2>&1)
        if ($LASTEXITCODE -ne 1 -or ($junctionOutput -join "`n") -notmatch 'referenceRoutes/route-fixture/mode=fixture/rule=path-outside-root') {
            Write-Fail -TestName 'Should_Fail_When_SkillRouteJunctionEscapesItsRoot' -Reason ('junction escape accepted or diagnostic missing: {0}' -f (($junctionOutput | Select-Object -Last 4) -join ' '))
        }
        Write-Pass -TestName 'Should_Fail_When_SkillRouteJunctionEscapesItsRoot'
    }
    Invoke-SkillRouteFixture -Name 'Should_Fail_When_SkillRoutePathIsBothRequiredAndExcluded' -Mutate {
        param($fixture) $fixture.referenceRoutes[0].routes[0].excluded += $fixture.referenceRoutes[0].routes[0].required[0]
    } -ExpectedExit 1
    Invoke-SkillRouteFixture -Name 'Should_Fail_When_ContextualComplexitySourceIsWrong' -Mutate {
        param($fixture) $fixture.complexitySources[0].source = 'FEATURE'
    } -ExpectedExit 1
}
finally { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

$failures = [System.Collections.Generic.List[string]]::new()
$sw = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($name in $sections.Keys) {
    $before = $script:PassCount
    try {
        & $sections[$name] *>&1 | ForEach-Object { if (-not $script:QuietMode) { $_ } }
        if (-not $script:QuietMode) { Write-Host ("[{0}] ok" -f $name) }
    }
    catch {
        $failures.Add(("[{0}] {1}" -f $name, $_.Exception.Message))
        Write-Host ("[{0}] FAIL - {1}" -f $name, $_.Exception.Message) -ForegroundColor Red
    }
}
$sw.Stop()
Write-Host ("Assert-CoreContracts: sections={0} passMarkers={1} failed={2} elapsed={3:N1}s" -f $sections.Count, $script:PassCount, $failures.Count, $sw.Elapsed.TotalSeconds)
if ($failures.Count -gt 0) {
    foreach ($f in $failures) { Write-Host ("  FAILED {0}" -f $f) -ForegroundColor Red }
    exit 1
}
Write-Host 'Assert-CoreContracts: ALL PASS'
exit 0
