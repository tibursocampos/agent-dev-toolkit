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
$cursorPathSecretsGuardScriptName = $script:ToolkitConstant.AssertCursorPathSecretsGuardScriptName
$cursorPathSecretsGuardCheckName = $script:ToolkitConstant.CursorPathSecretsGuardCheckName
$claudePathSecretsGuardScriptName = $script:ToolkitConstant.AssertClaudePathSecretsGuardScriptName
$claudePathSecretsGuardCheckName = $script:ToolkitConstant.ClaudePathSecretsGuardCheckName
$codexPathSecretsGuardScriptName = $script:ToolkitConstant.AssertCodexPathSecretsGuardScriptName
$codexPathSecretsGuardCheckName = $script:ToolkitConstant.CodexPathSecretsGuardCheckName
$copilotPathSecretsGuardScriptName = $script:ToolkitConstant.AssertCopilotPathSecretsGuardScriptName
$copilotPathSecretsGuardCheckName = $script:ToolkitConstant.CopilotPathSecretsGuardCheckName
$openHandsPathSecretsGuardScriptName = $script:ToolkitConstant.AssertOpenHandsPathSecretsGuardScriptName
$openHandsPathSecretsGuardCheckName = $script:ToolkitConstant.OpenHandsPathSecretsGuardCheckName
$zcodePathSecretsGuardScriptName = $script:ToolkitConstant.AssertZcodePathSecretsGuardScriptName
$zcodePathSecretsGuardCheckName = $script:ToolkitConstant.ZcodePathSecretsGuardCheckName
$grokPathSecretsGuardScriptName = $script:ToolkitConstant.AssertGrokPathSecretsGuardScriptName
$grokPathSecretsGuardCheckName = $script:ToolkitConstant.GrokPathSecretsGuardCheckName
$openCodePathSecretsGuardScriptName = $script:ToolkitConstant.AssertOpenCodePathSecretsGuardScriptName
$openCodePathSecretsGuardCheckName = $script:ToolkitConstant.OpenCodePathSecretsGuardCheckName
$antigravityPathSecretsGuardScriptName = $script:ToolkitConstant.AssertAntigravityPathSecretsGuardScriptName
$antigravityPathSecretsGuardCheckName = $script:ToolkitConstant.AntigravityPathSecretsGuardCheckName
$hermesPathSecretsGuardScriptName = $script:ToolkitConstant.AssertHermesPathSecretsGuardScriptName
$hermesPathSecretsGuardCheckName = $script:ToolkitConstant.HermesPathSecretsGuardCheckName
$canonicalCloneUrlScriptName = $script:ToolkitConstant.AssertCanonicalCloneUrlScriptName
$canonicalCloneUrlCheckName = $script:ToolkitConstant.CanonicalCloneUrlCheckName
$tier1AdapterReadmesScriptName = $script:ToolkitConstant.AssertTier1AdapterReadmesScriptName
$tier1AdapterReadmesCheckName = $script:ToolkitConstant.Tier1AdapterReadmesCheckName
$ciWorkflowScriptName = $script:ToolkitConstant.AssertCiWorkflowScriptName
$ciWorkflowCheckName = $script:ToolkitConstant.CiWorkflowCheckName
$noFeaturesDocLinksScriptName = $script:ToolkitConstant.AssertNoFeaturesDocLinksScriptName
$noFeaturesDocLinksCheckName = $script:ToolkitConstant.NoFeaturesDocLinksCheckName
$noFormaAliasScriptName = $script:ToolkitConstant.AssertNoFormaAliasScriptName
$noFormaAliasCheckName = $script:ToolkitConstant.NoFormaAliasCheckName
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
$orchestratorCharterPublishedScriptName = $script:ToolkitConstant.AssertOrchestratorCharterPublishedScriptName
$orchestratorCharterPublishedCheckName = $script:ToolkitConstant.OrchestratorCharterPublishedCheckName
$orchestratorCommandsScriptName = $script:ToolkitConstant.AssertOrchestratorCommandsScriptName
$orchestratorCommandsCheckName = $script:ToolkitConstant.OrchestratorCommandsCheckName
$preferencesSchemaScriptName = $script:ToolkitConstant.AssertPreferencesSchemaScriptName
$preferencesSchemaCheckName = $script:ToolkitConstant.PreferencesSchemaCheckName
$planExecutionPolicyScriptName = $script:ToolkitConstant.AssertPlanExecutionPolicyScriptName
$planExecutionPolicyCheckName = $script:ToolkitConstant.PlanExecutionPolicyCheckName
$prdStructureScriptName = $script:ToolkitConstant.AssertPrdStructureScriptName
$prdStructureCheckName = $script:ToolkitConstant.PrdStructureCheckName
$planStructureScriptName = $script:ToolkitConstant.AssertPlanStructureScriptName
$planStructureCheckName = $script:ToolkitConstant.PlanStructureCheckName
$skillLazyLoadScriptName = $script:ToolkitConstant.AssertSkillLazyLoadScriptName
$skillLazyLoadCheckName = $script:ToolkitConstant.SkillLazyLoadCheckName
$storySizingContractScriptName = $script:ToolkitConstant.AssertStorySizingContractScriptName
$storySizingContractCheckName = $script:ToolkitConstant.StorySizingContractCheckName
$productArtifactQualityScriptName = $script:ToolkitConstant.AssertProductArtifactQualityScriptName
$productArtifactQualityCheckName = $script:ToolkitConstant.ProductArtifactQualityCheckName
$intentClassificationScriptName = $script:ToolkitConstant.AssertIntentClassificationScriptName
$intentClassificationCheckName = $script:ToolkitConstant.IntentClassificationCheckName
$memoryBankInventoryScriptName = $script:ToolkitConstant.AssertMemoryBankInventoryScriptName
$memoryBankInventoryCheckName = $script:ToolkitConstant.MemoryBankInventoryCheckName
$planLedgerContractScriptName = $script:ToolkitConstant.AssertPlanLedgerContractScriptName
$planLedgerContractCheckName = $script:ToolkitConstant.PlanLedgerContractCheckName
$traceEmitterFailOpenScriptName = $script:ToolkitConstant.AssertTraceEmitterFailOpenScriptName
$traceEmitterFailOpenCheckName = $script:ToolkitConstant.TraceEmitterFailOpenCheckName
$executionModesScriptName = $script:ToolkitConstant.AssertExecutionModesScriptName
$executionModesCheckName = $script:ToolkitConstant.ExecutionModesCheckName
$publishSpawnKnobsScriptName = $script:ToolkitConstant.AssertPublishSpawnKnobsScriptName
$publishSpawnKnobsCheckName = $script:ToolkitConstant.PublishSpawnKnobsCheckName

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
    @{ Name = $cursorPathSecretsGuardCheckName; Script = $cursorPathSecretsGuardScriptName },
    @{ Name = $claudePathSecretsGuardCheckName; Script = $claudePathSecretsGuardScriptName },
    @{ Name = $codexPathSecretsGuardCheckName; Script = $codexPathSecretsGuardScriptName },
    @{ Name = $copilotPathSecretsGuardCheckName; Script = $copilotPathSecretsGuardScriptName },
    @{ Name = $openHandsPathSecretsGuardCheckName; Script = $openHandsPathSecretsGuardScriptName },
    @{ Name = $zcodePathSecretsGuardCheckName; Script = $zcodePathSecretsGuardScriptName },
    @{ Name = $grokPathSecretsGuardCheckName; Script = $grokPathSecretsGuardScriptName },
    @{ Name = $openCodePathSecretsGuardCheckName; Script = $openCodePathSecretsGuardScriptName },
    @{ Name = $antigravityPathSecretsGuardCheckName; Script = $antigravityPathSecretsGuardScriptName },
    @{ Name = $hermesPathSecretsGuardCheckName; Script = $hermesPathSecretsGuardScriptName },
    @{ Name = $canonicalCloneUrlCheckName; Script = $canonicalCloneUrlScriptName },
    @{ Name = $tier1AdapterReadmesCheckName; Script = $tier1AdapterReadmesScriptName },
    @{ Name = $ciWorkflowCheckName; Script = $ciWorkflowScriptName },
    @{ Name = $noFeaturesDocLinksCheckName; Script = $noFeaturesDocLinksScriptName },
    @{ Name = $noFormaAliasCheckName; Script = $noFormaAliasScriptName },
    @{ Name = $managedSkillsPathSafetyCheckName; Script = $managedSkillsPathSafetyScriptName },
    @{ Name = $uninstallPathSafetyCheckName; Script = $uninstallPathSafetyScriptName },
    @{ Name = $sddRootPrepareIdempotentCheckName; Script = $sddRootPrepareIdempotentScriptName },
    @{ Name = $selectiveRetrievalCheckName; Script = $selectiveRetrievalScriptName },
    @{ Name = $validatePrdPlanCheckName; Script = $validatePrdPlanScriptName },
    @{ Name = $changeContractCheckName; Script = $changeContractScriptName },
    @{ Name = $evidenceContractCheckName; Script = $evidenceContractScriptName },
    @{ Name = $traceArchiveContractCheckName; Script = $traceArchiveContractScriptName },
    @{ Name = $orchestratorCharterPublishedCheckName; Script = $orchestratorCharterPublishedScriptName },
    @{ Name = $orchestratorCommandsCheckName; Script = $orchestratorCommandsScriptName },
    @{ Name = $preferencesSchemaCheckName; Script = $preferencesSchemaScriptName },
    @{ Name = $planExecutionPolicyCheckName; Script = $planExecutionPolicyScriptName },
    @{ Name = $prdStructureCheckName; Script = $prdStructureScriptName },
    @{ Name = $planStructureCheckName; Script = $planStructureScriptName },
    @{ Name = $storySizingContractCheckName; Script = $storySizingContractScriptName },
    @{ Name = $productArtifactQualityCheckName; Script = $productArtifactQualityScriptName },
    @{ Name = $intentClassificationCheckName; Script = $intentClassificationScriptName },
    @{ Name = $skillLazyLoadCheckName; Script = $skillLazyLoadScriptName },
    @{ Name = $memoryBankInventoryCheckName; Script = $memoryBankInventoryScriptName },
    @{ Name = $planLedgerContractCheckName; Script = $planLedgerContractScriptName },
    @{ Name = $executionModesCheckName; Script = $executionModesScriptName },
    @{ Name = $traceEmitterFailOpenCheckName; Script = $traceEmitterFailOpenScriptName },
    @{ Name = $publishSpawnKnobsCheckName; Script = $publishSpawnKnobsScriptName }
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
