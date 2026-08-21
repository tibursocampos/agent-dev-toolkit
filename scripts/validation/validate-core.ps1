#Requires -Version 5.1
<#
.SYNOPSIS
  Runs the agent-dev-toolkit core validation suite (in-repo, no home deploy).

.DESCRIPTION
  Orchestrates skill contracts, graph, fixtures, and the in-repo smoke harness
  against core/skills + fixture InstallRoot.
  Does not sync or validate under USERPROFILE. No -AllowUserHome required.

.PARAMETER FailFast
  Stop on first failing check.

.PARAMETER Quiet
  Suppress per-check banners; print summary only.

.EXAMPLE
  .\scripts\validation\validate-core.ps1
#>
[CmdletBinding()]
param(
    [switch] $FailFast,
    [switch] $Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')

$suiteTitle = 'agent-dev-toolkit core validation'
$contractsScriptName = 'validate-skill-contracts.ps1'
$graphScriptName = 'validate-skill-graph.ps1'
$fixturesScriptName = 'validate-skill-fixtures.ps1'
$smokeHarnessScriptName = $script:ToolkitConstant.SmokeHarnessScriptName
$routerDocLinksScriptName = $script:ToolkitConstant.AssertRouterDocLinksScriptName
$routerDocLinksCheckName = $script:ToolkitConstant.RouterDocLinksCheckName
$spawnContractScriptName = $script:ToolkitConstant.AssertSpawnContractScriptName
$spawnContractCheckName = $script:ToolkitConstant.SpawnContractCheckName
$adapterContractScriptName = $script:ToolkitConstant.AssertAdapterContractScriptName
$adapterContractCheckName = $script:ToolkitConstant.AdapterContractCheckName
$orchestrateSpawnFallbackScriptName = $script:ToolkitConstant.AssertOrchestrateSpawnFallbackScriptName
$orchestrateSpawnFallbackCheckName = $script:ToolkitConstant.OrchestrateSpawnFallbackCheckName
$hermesSpawnIsolationScriptName = $script:ToolkitConstant.AssertHermesSpawnIsolationScriptName
$hermesSpawnIsolationCheckName = $script:ToolkitConstant.HermesSpawnIsolationCheckName
$antigravitySubagentsProbeScriptName = $script:ToolkitConstant.AssertAntigravityOfficialLayoutScriptName
$antigravitySubagentsProbeCheckName = $script:ToolkitConstant.AntigravitySubagentsProbeCheckName
$javaDeveloperRoutingScriptName = $script:ToolkitConstant.AssertJavaDeveloperRoutingScriptName
$javaDeveloperRoutingCheckName = $script:ToolkitConstant.JavaDeveloperRoutingCheckName
$installRootSafetyScriptName = $script:ToolkitConstant.AssertInstallRootSafetyScriptName
$installRootSafetyCheckName = $script:ToolkitConstant.InstallRootSafetyCheckName
$smokeHarnessSafetyScriptName = $script:ToolkitConstant.AssertSmokeHarnessSafetyScriptName
$smokeHarnessSafetyCheckName = $script:ToolkitConstant.SmokeHarnessSafetyCheckName
$claudeSettingsMergeScriptName = $script:ToolkitConstant.AssertClaudeSettingsMergeScriptName
$claudeSettingsMergeCheckName = $script:ToolkitConstant.ClaudeSettingsMergeCheckName
$cursorHooksMergeScriptName = $script:ToolkitConstant.AssertCursorHooksMergeScriptName
$cursorHooksMergeCheckName = $script:ToolkitConstant.CursorHooksMergeCheckName
$canonicalCloneUrlScriptName = $script:ToolkitConstant.AssertCanonicalCloneUrlScriptName
$canonicalCloneUrlCheckName = $script:ToolkitConstant.CanonicalCloneUrlCheckName
$tier1AdapterReadmesScriptName = $script:ToolkitConstant.AssertTier1AdapterReadmesScriptName
$tier1AdapterReadmesCheckName = $script:ToolkitConstant.Tier1AdapterReadmesCheckName
$ciWorkflowScriptName = $script:ToolkitConstant.AssertCiWorkflowScriptName
$ciWorkflowCheckName = $script:ToolkitConstant.CiWorkflowCheckName
$noFeaturesDocLinksScriptName = $script:ToolkitConstant.AssertNoFeaturesDocLinksScriptName
$noFeaturesDocLinksCheckName = $script:ToolkitConstant.NoFeaturesDocLinksCheckName
$managedSkillsPathSafetyScriptName = $script:ToolkitConstant.AssertManagedSkillsPathSafetyScriptName
$managedSkillsPathSafetyCheckName = $script:ToolkitConstant.ManagedSkillsPathSafetyCheckName
$uninstallPathSafetyScriptName = $script:ToolkitConstant.AssertUninstallPathSafetyScriptName
$uninstallPathSafetyCheckName = $script:ToolkitConstant.UninstallPathSafetyCheckName
$sddRootPrepareIdempotentScriptName = $script:ToolkitConstant.AssertSddRootPrepareIdempotentScriptName
$sddRootPrepareIdempotentCheckName = $script:ToolkitConstant.SddRootPrepareIdempotentCheckName
$selectiveRetrievalScriptName = $script:ToolkitConstant.AssertSelectiveRetrievalScriptName
$selectiveRetrievalCheckName = $script:ToolkitConstant.SelectiveRetrievalCheckName
$validatePrdPlanScriptName = $script:ToolkitConstant.AssertValidatePrdPlanScriptName
$validatePrdPlanCheckName = $script:ToolkitConstant.ValidatePrdPlanCheckName
$changeContractScriptName = $script:ToolkitConstant.AssertChangeContractScriptName
$changeContractCheckName = $script:ToolkitConstant.ChangeContractCheckName
$evidenceContractScriptName = $script:ToolkitConstant.AssertEvidenceContractScriptName
$evidenceContractCheckName = $script:ToolkitConstant.EvidenceContractCheckName
$traceArchiveContractScriptName = $script:ToolkitConstant.AssertTraceArchiveContractScriptName
$traceArchiveContractCheckName = $script:ToolkitConstant.TraceArchiveContractCheckName

function Write-Banner([string] $Message) {
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

function Invoke-ValidationCheck {
    param(
        [string] $Name,
        [string] $ScriptPath
    )

    Write-Banner "Running: $Name"
    & $ScriptPath
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }

    return [PSCustomObject]@{
        Name     = $Name
        Status   = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
        ExitCode = $exitCode
    }
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host $suiteTitle -ForegroundColor Cyan
    Write-Host ('=' * $suiteTitle.Length) -ForegroundColor Cyan
    Write-Host ''
}

$coreChecks = @(
    @{ Name = 'skill-contracts'; Script = $contractsScriptName },
    @{ Name = 'skill-graph'; Script = $graphScriptName },
    @{ Name = 'skill-fixtures'; Script = $fixturesScriptName },
    @{ Name = 'smoke-harness'; Script = $smokeHarnessScriptName },
    @{ Name = $routerDocLinksCheckName; Script = $routerDocLinksScriptName },
    @{ Name = $spawnContractCheckName; Script = $spawnContractScriptName },
    @{ Name = $adapterContractCheckName; Script = $adapterContractScriptName },
    @{ Name = $orchestrateSpawnFallbackCheckName; Script = $orchestrateSpawnFallbackScriptName },
    @{ Name = $hermesSpawnIsolationCheckName; Script = $hermesSpawnIsolationScriptName },
    @{ Name = $antigravitySubagentsProbeCheckName; Script = $antigravitySubagentsProbeScriptName },
    @{ Name = $javaDeveloperRoutingCheckName; Script = $javaDeveloperRoutingScriptName },
    @{ Name = $installRootSafetyCheckName; Script = $installRootSafetyScriptName },
    @{ Name = $smokeHarnessSafetyCheckName; Script = $smokeHarnessSafetyScriptName },
    @{ Name = $claudeSettingsMergeCheckName; Script = $claudeSettingsMergeScriptName },
    @{ Name = $cursorHooksMergeCheckName; Script = $cursorHooksMergeScriptName },
    @{ Name = $canonicalCloneUrlCheckName; Script = $canonicalCloneUrlScriptName },
    @{ Name = $tier1AdapterReadmesCheckName; Script = $tier1AdapterReadmesScriptName },
    @{ Name = $ciWorkflowCheckName; Script = $ciWorkflowScriptName },
    @{ Name = $noFeaturesDocLinksCheckName; Script = $noFeaturesDocLinksScriptName },
    @{ Name = $managedSkillsPathSafetyCheckName; Script = $managedSkillsPathSafetyScriptName },
    @{ Name = $uninstallPathSafetyCheckName; Script = $uninstallPathSafetyScriptName },
    @{ Name = $sddRootPrepareIdempotentCheckName; Script = $sddRootPrepareIdempotentScriptName },
    @{ Name = $selectiveRetrievalCheckName; Script = $selectiveRetrievalScriptName },
    @{ Name = $validatePrdPlanCheckName; Script = $validatePrdPlanScriptName },
    @{ Name = $changeContractCheckName; Script = $changeContractScriptName },
    @{ Name = $evidenceContractCheckName; Script = $evidenceContractScriptName },
    @{ Name = $traceArchiveContractCheckName; Script = $traceArchiveContractScriptName }
)

# Assert-SyncAllowUserHomeForward publishes under a disposable USERPROFILE probe.
# Keep it out of validate-core so validate-agent (and nested CI smokes with -SkipCore)
# stay fixture-only and fast. CI runs that assert once as a dedicated workflow step.
# Keyed uninstall asserts also stay out: they call validate-agent (which runs
# validate-core) and would recurse. CI runs them as a dedicated workflow step.
# Assert-ToolkitCli / Assert-Orchestrators stay out: they nest sync/validate and would
# recurse or re-run the full suite from inside validate-core.

$results = @()
foreach ($check in $coreChecks) {
    $result = Invoke-ValidationCheck -Name $check.Name -ScriptPath (Join-Path $scriptDir $check.Script)
    $results += $result

    if ($FailFast -and $result.Status -eq 'FAIL') {
        break
    }
}

Write-Host ''
Write-Host 'Core validation summary' -ForegroundColor Cyan
Write-Host '-----------------------' -ForegroundColor Cyan
foreach ($result in $results) {
    $color = switch ($result.Status) {
        'PASS' { [ConsoleColor]::Green }
        'FAIL' { [ConsoleColor]::Red }
        default { [ConsoleColor]::Gray }
    }
    Write-Host ("{0,-20} {1}" -f $result.Name, $result.Status) -ForegroundColor $color
}

$failed = @($results | Where-Object { $_.Status -eq 'FAIL' })
if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host "Core validation FAILED ($($failed.Count) check(s))." -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Core validation PASSED.' -ForegroundColor Green
exit 0
