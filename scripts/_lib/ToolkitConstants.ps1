#Requires -Version 5.1
<#
.SYNOPSIS
  Named constants for toolkit scripts (_lib).

.DESCRIPTION
  Avoid magic strings in InstallRoot resolution and related guards.
#>

$script:ToolkitConstant = @{
    AllowUserHomeParameterName     = 'AllowUserHome'
    UserScopeParameterName         = 'UserScope'
    WhatIfParameterName            = 'WhatIf'
    CodexAgentId                   = 'codex'
    HermesAgentId                  = 'hermes'
    OpenHandsAgentId               = 'openhands'
    UserProfileEnvironmentName     = 'USERPROFILE'
    CoreSkillsDirectoryName        = 'core'
    SkillsDirectoryName            = 'skills'
    AgentsDirectoryName            = 'agents'
    ExpectedCustomAgentFileNames   = @(
        'repo-analyst.md',
        'architect.md',
        'database.md',
        'security.md',
        'shell-runner.md'
    )
    ReadmeFileName                 = 'README.md'
    PathSeparator                  = [System.IO.Path]::DirectorySeparatorChar
    AdaptersDirectoryName          = 'adapters'
    RegistryFileName               = 'registry.json'
    DefaultFixtureInstallRootRel   = 'scripts/validation/fixtures/install-root'
    InstallRootFixtureDirectoryName = 'install-root'
    SmokeHarnessScriptName         = 'Invoke-SmokeHarness.ps1'
    SmokeHarnessMarkerFileName     = '.smoke-harness-marker'
    UserCursorProfileRelativePath  = '.cursor'
    SkillFixtureMarkersFileName    = 'expected-markers.txt'
    ValidateCoreRelativePath       = 'scripts/validation/validate-core.ps1'
    AssertRouterDocLinksScriptName = 'Assert-RouterDocLinks.ps1'
    RouterAgentsRelativePath       = 'core/router/AGENTS.md'
    RouterDocLinksCheckName        = 'router-doc-links'
    RouterPathLiteralPattern       = '`(docs|core)/([^`]+)`'
    InventedMissingRouterDocRel    = 'docs/__invented_missing_router_target__.md'
    AssertSpawnContractScriptName  = 'Assert-SpawnContract.ps1'
    AssertAdapterContractScriptName = 'Assert-AdapterContract.ps1'
    AssertOrchestrateSpawnFallbackScriptName = 'Assert-OrchestrateSpawnFallback.ps1'
    AssertHermesSpawnIsolationScriptName = 'Assert-HermesSpawnIsolation.ps1'
    AssertAntigravityOfficialLayoutScriptName = 'Assert-AntigravityOfficialLayout.ps1'
    AssertJavaDeveloperRoutingScriptName = 'Assert-JavaDeveloperRouting.ps1'
    SpawnContractCheckName         = 'spawn-contract'
    AdapterContractCheckName       = 'adapter-contract'
    OrchestrateSpawnFallbackCheckName = 'orchestrate-spawn-fallback'
    HermesSpawnIsolationCheckName  = 'hermes-spawn-isolation'
    AntigravitySubagentsProbeCheckName = 'antigravity-subagents-probe'
    JavaDeveloperRoutingCheckName  = 'java-developer-routing'
    AssertInstallRootSafetyScriptName = 'Assert-InstallRootSafety.ps1'
    InstallRootSafetyCheckName     = 'install-root-safety'
    AssertSmokeHarnessSafetyScriptName = 'Assert-SmokeHarnessSafety.ps1'
    SmokeHarnessSafetyCheckName    = 'smoke-harness-safety'
    AssertClaudeSettingsMergeScriptName = 'Assert-ClaudeSettingsMerge.ps1'
    ClaudeSettingsMergeCheckName   = 'claude-settings-merge'
    AssertCursorHooksMergeScriptName = 'Assert-CursorHooksMerge.ps1'
    CursorHooksMergeCheckName      = 'cursor-hooks-merge'
    AssertCursorPathSecretsGuardScriptName = 'Assert-CursorPathSecretsGuard.ps1'
    CursorPathSecretsGuardCheckName = 'cursor-path-secrets-guard'
    AssertClaudePathSecretsGuardScriptName = 'Assert-ClaudePathSecretsGuard.ps1'
    ClaudePathSecretsGuardCheckName = 'claude-path-secrets-guard'
    AssertCodexPathSecretsGuardScriptName = 'Assert-CodexPathSecretsGuard.ps1'
    CodexPathSecretsGuardCheckName = 'codex-path-secrets-guard'
    AssertCopilotPathSecretsGuardScriptName = 'Assert-CopilotPathSecretsGuard.ps1'
    CopilotPathSecretsGuardCheckName = 'copilot-path-secrets-guard'
    AssertOpenHandsPathSecretsGuardScriptName = 'Assert-OpenHandsPathSecretsGuard.ps1'
    OpenHandsPathSecretsGuardCheckName = 'openhands-path-secrets-guard'
    AssertZcodePathSecretsGuardScriptName = 'Assert-ZcodePathSecretsGuard.ps1'
    ZcodePathSecretsGuardCheckName = 'zcode-path-secrets-guard'
    AssertGrokPathSecretsGuardScriptName = 'Assert-GrokPathSecretsGuard.ps1'
    GrokPathSecretsGuardCheckName = 'grok-path-secrets-guard'
    AssertOpenCodePathSecretsGuardScriptName = 'Assert-OpenCodePathSecretsGuard.ps1'
    OpenCodePathSecretsGuardCheckName = 'opencode-path-secrets-guard'
    AssertAntigravityPathSecretsGuardScriptName = 'Assert-AntigravityPathSecretsGuard.ps1'
    AntigravityPathSecretsGuardCheckName = 'antigravity-path-secrets-guard'
    AssertHermesPathSecretsGuardScriptName = 'Assert-HermesPathSecretsGuard.ps1'
    HermesPathSecretsGuardCheckName = 'hermes-path-secrets-guard'
    CursorHooksAssetsRelativePath  = 'adapters/cursor/assets/hooks'
    AssertCanonicalCloneUrlScriptName = 'Assert-CanonicalCloneUrl.ps1'
    CanonicalCloneUrlCheckName     = 'canonical-clone-url'
    AssertTier1AdapterReadmesScriptName = 'Assert-Tier1AdapterReadmes.ps1'
    Tier1AdapterReadmesCheckName   = 'adapter-readmes'
    AssertSyncAllowUserHomeForwardScriptName = 'Assert-SyncAllowUserHomeForward.ps1'
    SyncAllowUserHomeForwardCheckName = 'sync-allow-user-home-forward'
    AssertCiWorkflowScriptName         = 'Assert-CiWorkflow.ps1'
    CiWorkflowCheckName                = 'ci-workflow'
    AssertNoFeaturesDocLinksScriptName = 'Assert-NoFeaturesDocLinks.ps1'
    NoFeaturesDocLinksCheckName        = 'no-features-doc-links'
    NoFeaturesDocLinksSpawnMatrixPattern = 'SPAWN_MATRIX'
    NoFeaturesDocLinksFeatureFolderPattern = 'features/\d{3}-'
    NoFeaturesDocLinksSyntheticForbiddenSample = 'See features/002-example/US02/ARCH/SPAWN_MATRIX.md'
    AssertNoFormaAliasScriptName       = 'Assert-NoFormaAlias.ps1'
    NoFormaAliasCheckName              = 'no-forma-alias'
    NoFormaAliasFormaLetterPattern    = '\bForma [ABC]\b'
    NoFormaAliasFormerlyPattern        = 'formerly Forma'
    NoFormaAliasFormerlyTrackAliasPattern = 'formerly Classic SDD/B/C'
    NoFormaAliasWorkflowsHeadingPattern = 'Formas \(workflows\)'
    NoFormaAliasSlashPattern           = 'Forma A/B/C'
    NoFormaAliasPipePattern            = 'Forma A\|B\|C'
    NoFormaAliasSyntheticForbiddenSample = 'Classic SDD (Forma A) and Orchestrated Delivery *(formerly Forma C)*; Formas (workflows); Forma A/B/C; Forma A|B|C; formerly Classic SDD/B/C'
    AssertManagedSkillsPathSafetyScriptName = 'Assert-ManagedSkillsPathSafety.ps1'
    ManagedSkillsPathSafetyCheckName   = 'managed-skills-path-safety'
    AssertUninstallPathSafetyScriptName = 'Assert-UninstallPathSafety.ps1'
    UninstallPathSafetyCheckName       = 'uninstall-path-safety'
    AssertSddRootPrepareIdempotentScriptName = 'Assert-SddRootPrepareIdempotent.ps1'
    SddRootPrepareIdempotentCheckName  = 'sdd-root-prepare-idempotent'
    AssertSelectiveRetrievalScriptName = 'Assert-SelectiveRetrieval.ps1'
    SelectiveRetrievalCheckName        = 'selective-retrieval'
    SelectiveRetrievalRuleId           = 'SR-NO-FULL-DUMP'
    SelectiveRetrievalGuideRelativePath = 'core/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md'
    SelectiveRetrievalInScopeRelativePaths = @(
        'core/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md',
        'core/skills/_shared/templates/sdd/PRD.md',
        'core/skills/_shared/templates/sdd/PLAN.md',
        'core/skills/sdd-spec/SKILL.md',
        'core/skills/sdd-spec/reference.md',
        'core/skills/sdd-plan/SKILL.md',
        'core/skills/sdd-plan/reference.md',
        'core/skills/refine-story/SKILL.md',
        'core/skills/refine-story/references/boundary.md',
        'core/skills/refine-story/references/guardrails.md'
    )
    AssertSkillLazyLoadScriptName      = 'Assert-SkillLazyLoad.ps1'
    SkillLazyLoadCheckName             = 'skill-lazy-load'
    SkillReferenceRetrievalRuleId      = 'SR-LAZY-REFERENCE'
    SkillReferenceRetrievalGuideRelativePath = 'core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md'
    CoreSkillsRootRelativePath         = 'core/skills'
    SharedSkillsDirectoryName          = '_shared'
    SkillLazyLoadHeadingPattern        = '(?im)^## Lazy-load'
    SkillLazyLoadNeverByDefaultPattern = '(?i)\*\*Never by default:\*\*'
    SkillLazyLoadReferenceLineThreshold = 150
    SkillLazyLoadReferenceIndexLineThreshold = 50
    ValidatePrdScriptName              = 'validate-prd.ps1'
    ValidatePlanScriptName             = 'validate-plan.ps1'
    AssertValidatePrdPlanScriptName    = 'Assert-ValidatePrdPlan.ps1'
    ValidatePrdPlanCheckName           = 'validate-prd-plan'
    SddArtifactFixturesRelativeDir     = 'scripts/validation/fixtures/sdd-artifacts'
    SddArtifactReqIdPattern            = '(?i)\bREQ-(\d{3})\b'
    SddArtifactAcceptancePattern       = '(?im)^#{2,3}\s*CA\d+\b'
    SddArtifactPrdHeaderPattern        = '(?im)^\|\s*\*{0,2}PRD\*{0,2}\s*\|\s*`?([^|`]+?)`?\s*\|'
    SddArtifactReqMapSectionPattern    = '(?i)Mapa\s+REQ|REQ\s*(→|->)\s*passo|REQ\s*->\s*step'
    ValidatePrdPlanSkillWiringRelativePaths = @(
        'core/skills/sdd-spec/SKILL.md',
        'core/skills/sdd-spec/reference.md',
        'core/skills/sdd-plan/SKILL.md',
        'core/skills/sdd-plan/reference.md'
    )
    ValidatePrdFixtureValidRelativePath = 'prd/valid.md'
    ValidatePrdFixtureInvalidNoReqRelativePath = 'prd/invalid-no-req.md'
    ValidatePrdFixtureInvalidNoAcRelativePath = 'prd/invalid-no-ac.md'
    ValidatePrdFixtureInvalidNoSectionsRelativePath = 'prd/invalid-no-sections.md'
    ValidatePlanFixtureValidRelativePath = 'plan/valid.md'
    ValidatePlanFixtureInvalidNoSectionsRelativePath = 'plan/invalid-no-sections.md'
    ValidatePlanFixtureInvalidMissingReqRelativePath = 'plan/invalid-missing-req.md'
    ValidatePlanFixtureCompanionPrdRelativePath = 'plan/companion-prd.md'
    ValidateChangeScriptName           = 'validate-change.ps1'
    AssertChangeContractScriptName     = 'Assert-ChangeContract.ps1'
    ChangeContractCheckName            = 'change-contract'
    ChangeContractGuideRelativePath    = 'core/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md'
    ChangeTemplateRelativePath         = 'core/skills/_shared/templates/features/CHANGE.md'
    SddArtifactChangeSectionPattern    = '(?im)^#{1,3}\s*(ADDED|MODIFIED|REMOVED)\b'
    SddArtifactChangeForbiddenCurrentPattern = '(?i)\b(openspec/|\.specs/|\.specify/)\b'
    ValidateChangeFixtureValidRelativePath = 'change/valid.md'
    ValidateChangeFixtureInvalidNoSectionsRelativePath = 'change/invalid-no-sections.md'
    ChangeContractSkillWiringRelativePaths = @(
        'core/skills/sdd-spec/SKILL.md',
        'core/skills/sdd-spec/reference.md',
        'core/skills/orchestrate-deliver/SKILL.md',
        'core/skills/orchestrate-deliver/reference.md',
        'core/skills/orchestrate-analyze/SKILL.md',
        'core/skills/orchestrate-develop/SKILL.md',
        'core/skills/_shared/sdd-artifacts/STORAGE.md',
        'core/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md'
    )
    ChangeContractTasksPolicyRelativePaths = @(
        'core/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md',
        'core/skills/split-story-checklist/SKILL.md',
        'core/skills/split-story-checklist/reference.md'
    )
    ValidateEvidenceScriptName         = 'validate-evidence.ps1'
    AssertEvidenceContractScriptName   = 'Assert-EvidenceContract.ps1'
    EvidenceContractCheckName          = 'evidence-contract'
    EvidenceContractGuideRelativePath  = 'core/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md'
    StateTemplateRelativePath          = 'core/skills/_shared/templates/features/STATE.md'
    EvdTemplateReadmeRelativePath      = 'core/skills/_shared/templates/features/EVD/README.md'
    SddArtifactStateFileName           = 'STATE.md'
    SddArtifactEvdDirectoryName        = 'EVD'
    SddArtifactEvidenceLevelDefault    = 'cheap'
    SddArtifactEvidenceLevelFieldPattern = '(?im)\|\s*\*{0,2}Evidence level\*{0,2}\s*\|\s*`?(off|cheap|standard|strict)`?\s*\|'
    SddArtifactEvidenceMatrixHeadingPattern = '(?im)^#{1,3}\s*AC\s*(.|->)\s*evidence matrix\b'
    ValidateEvidenceFixtureValidRelativeDir = 'evidence/valid'
    ValidateEvidenceFixtureInvalidZeroRelativeDir = 'evidence/invalid-zero'
    EvidenceContractSkillWiringRelativePaths = @(
        'core/skills/sdd-develop/SKILL.md',
        'core/skills/sdd-develop/reference.md',
        'core/skills/orchestrate-develop/SKILL.md',
        'core/skills/orchestrate-develop/reference.md',
        'core/skills/_shared/sdd-artifacts/STORAGE.md',
        'core/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md'
    )
    EvidenceVerifierNoO3RelativePaths = @(
        'core/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md',
        'core/skills/sdd-develop/SKILL.md',
        'core/skills/orchestrate-develop/SKILL.md'
    )
    ValidateTraceScriptName            = 'validate-trace.ps1'
    AssertTraceArchiveContractScriptName = 'Assert-TraceArchiveContract.ps1'
    TraceArchiveContractCheckName      = 'trace-archive-contract'
    TraceArchiveContractGuideRelativePath = 'core/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md'
    TraceTemplateRelativePath          = 'core/skills/_shared/templates/features/TRACE.jsonl'
    SddArtifactTraceFileName           = 'TRACE.jsonl'
    SddArtifactTraceEventConverge      = 'converge'
    SddArtifactTraceEventSyncCurrent   = 'sync_current'
    SddArtifactTraceEventArchive       = 'archive'
    SddArtifactTraceEventRetrieval     = 'retrieval'
    SddArtifactTraceEventGate          = 'gate'
    SddArtifactTraceEventSpawn         = 'spawn'
    SddArtifactTraceEventSpecialistComplete = 'specialist_complete'
    SddArtifactTraceNormativeOptionalEvents = @(
        'develop_start'
        'step_done'
        'evidence'
        'validate'
        'note'
        'retrieval'
        'gate'
        'spawn'
        'specialist_complete'
    )
    SddArtifactTraceArchiveStatusAllowed = @('archived', 'closed')
    SddArtifactTracePortablePathPattern  = '(?i)^[A-Za-z]:[/\\]|^~[/\\]|\\Users\\|\\\.cursor\\|\\\.claude\\'
    SddArtifactTraceFeaturePathPattern = '(?i)^features/[0-9]{3}-[a-z0-9][a-z0-9\-]*$'
    SddArtifactTraceAllowedTargetPattern = '(?i)^(memory-bank/|docs/)'
    SddArtifactTraceForbiddenTargetPattern = '(?i)\b(openspec/|\.specs/|\.specify/)\b'
    ValidateTraceFixtureValidRelativeDir = 'trace/valid'
    ValidateTraceFixtureInvalidIncompleteRelativeDir = 'trace/invalid-incomplete'
    ValidateTraceFixtureInvalidBadJsonRelativeDir = 'trace/invalid-bad-json'
    ValidateTraceFixtureInvalidOrchestrationRelativeDir = 'trace/invalid-orchestration'
    ValidateTraceFixtureArchiveSmokeRelativeDir = 'trace/archive-smoke'
    TraceArchiveContractSkillWiringRelativePaths = @(
        'core/skills/sdd-develop/SKILL.md',
        'core/skills/sdd-develop/reference.md',
        'core/skills/orchestrate-develop/SKILL.md',
        'core/skills/orchestrate-develop/reference.md',
        'core/skills/_shared/sdd-artifacts/STORAGE.md',
        'core/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md'
    )
    AssertOrchestratorCharterPublishedScriptName = 'Assert-OrchestratorCharterPublished.ps1'
    OrchestratorCharterPublishedCheckName        = 'orchestrator-charter-published'
    AssertOrchestratorCommandsScriptName         = 'Assert-OrchestratorCommands.ps1'
    OrchestratorCommandsCheckName                = 'orchestrator-commands'
    AssertPreferencesSchemaScriptName            = 'Assert-PreferencesSchema.ps1'
    PreferencesSchemaCheckName                   = 'preferences-schema'
    AssertPlanExecutionPolicyScriptName          = 'Assert-PlanExecutionPolicy.ps1'
    PlanExecutionPolicyCheckName                 = 'plan-execution-policy'
    AssertPrdStructureScriptName                 = 'Assert-PrdStructure.ps1'
    PrdStructureCheckName                        = 'prd-structure'
    AssertPlanStructureScriptName                = 'Assert-PlanStructure.ps1'
    PlanStructureCheckName                       = 'plan-structure'
    PrdStructureTemplateRelativePath             = 'core/skills/_shared/templates/sdd/PRD.md'
    PlanStructureTemplateRelativePath            = 'core/skills/_shared/templates/sdd/PLAN.md'
    PrdRequiredSectionMarkers                    = @(
        '## Execution policy',
        '## 2. Critérios de aceite',
        '## 4. Requisitos (REQ-IDs)',
        '## 5. Fora de escopo (OOS)'
    )
    PlanRequiredSectionMarkers                   = @(
        '## Execution policy',
        '## Mapa REQ → passo',
        '## Passos de implementação'
    )
    PrdStructureSkillWiringRelativePaths         = @(
        'core/skills/sdd-spec/SKILL.md',
        'core/skills/sdd-spec/reference.md'
    )
    PlanStructureSkillWiringRelativePaths        = @(
        'core/skills/sdd-plan/SKILL.md',
        'core/skills/sdd-plan/reference.md'
    )
    SddArtifactPrdExecutionPolicyPattern         = '(?im)^##\s+Execution policy\s*$'
    SddArtifactPrdAcceptanceSectionPattern       = '(?im)^##\s+2\.\s+(Critérios de aceite|Acceptance criteria)\s*$'
    SddArtifactPrdRequirementsSectionPattern     = '(?im)^##\s+4\.\s+(Requisitos \(REQ-IDs\)|Requirements \(REQ-IDs\))\s*$'
    SddArtifactPrdOosSectionPattern              = '(?im)^##\s+5\.\s+(Fora de escopo|Out of scope)\b'
    SddArtifactPlanExecutionPolicyPattern        = '(?im)^##\s+Execution policy\s*$'
    SddArtifactPlanStepHeadingPattern            = '(?im)^#{2,3}\s*(⏳|🔄|✅|❌)?\s*(PASSO|STEP)\s+\d+'
    AssertStorySizingContractScriptName          = 'Assert-StorySizingContract.ps1'
    StorySizingContractCheckName                 = 'story-sizing-contract'
    StorySizingContractRelativePath              = 'core/skills/_shared/backlog-item-types/story-sizing.md'
    AssertProductArtifactQualityScriptName       = 'Assert-ProductArtifactQuality.ps1'
    ProductArtifactQualityCheckName              = 'product-artifact-quality'
    ProductArtifactQualityFixturesRelativeDir    = 'scripts/validation/fixtures/product-artifact-quality'
    ProductArtifactQualityCt1RelativeDir         = 'ct1-feature-incomplete'
    ProductArtifactQualityCt2RelativeDir         = 'ct2-task-shaped'
    ProductArtifactQualityCt3RelativeDir         = 'ct3-story-ac-budget-ok'
    ProductArtifactQualityCt4RelativeDir         = 'ct4-cap-exceeded'
    ProductArtifactQualityCt6RelativeDir         = 'ct6-evidence-omitted'
    ProductArtifactQualityMaturityCap            = 4
    ProductArtifactQualityMinProductDepthBand    = 3
    ProductArtifactQualityEvidenceOmittedMarker  = 'omitted — none yet'
    ProductArtifactQualityTaskShapedTitlePattern = '(?i)^(Create|Add|Update|Implement|Write|Fix)\s+[`'']?[A-Za-z0-9_.\-]+\.(ps1|cs|ts|tsx|js|py|md)[`'']?\b'
    ProductArtifactQualityCapRationalePattern    = '(?i)(Cap exception rationale|justifies (?:the )?extra split|RN03 exception|split beyond (?:the )?cap)'
    ProductArtifactQualityCt2TaskTitle           = 'Create Assert-Foo.ps1'
    ProductArtifactQualityCt2OutcomeTitle        = 'Operators export archives by date range'
    ProductArtifactQualityStorySynthesisRelativePath = 'core/skills/orchestrate-analyze/references/story-synthesis.md'
    AssertIntentClassificationScriptName         = 'Assert-IntentClassification.ps1'
    IntentClassificationCheckName                = 'intent-classification'
    IntentClassificationContractRelativePath   = 'core/skills/orchestrate-analyze/references/intent-classification.md'
    InvokeMemoryBankInventoryScriptRelativePath  = 'scripts/inventory/Invoke-MemoryBankInventory.ps1'
    AssertMemoryBankInventoryScriptName          = 'Assert-MemoryBankInventory.ps1'
    MemoryBankInventoryCheckName                 = 'memory-bank-inventory'
    MemoryBankInventoryFixtureRelativeDir        = 'scripts/validation/fixtures/memory-bank-inventory-work'
    PlanLedgerContractRelativePath               = 'core/skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md'
    PlanLedgerSddPlanReferenceRelativePath       = 'core/skills/sdd-plan/references/plan-ledger.md'
    PlanLedgerSddPlanIndexRelativePath           = 'core/skills/sdd-plan/reference.md'
    PlanLedgerSddPlanSkillRelativePath           = 'core/skills/sdd-plan/SKILL.md'
    InvokePlanLedgerClaimScriptRelativePath      = 'scripts/ledger/Invoke-PlanLedgerClaim.ps1'
    AssertPlanLedgerContractScriptName           = 'Assert-PlanLedgerContract.ps1'
    PlanLedgerContractCheckName                  = 'plan-ledger-contract'
    TraceEmitCommonRelativePath                  = 'adapters/_shared/TraceEmitCommon.ps1'
    TraceEmitCommonAssetRelativePaths            = @(
        'adapters/cursor/assets/hooks/TraceEmitCommon.ps1'
        'adapters/claude/assets/hooks/TraceEmitCommon.ps1'
        'adapters/codex/assets/hooks/TraceEmitCommon.ps1'
    )
    TraceEmitterHonestyRelativePath              = 'adapters/_shared/trace-emitter-honesty.md'
    AssertTraceEmitterFailOpenScriptName         = 'Assert-TraceEmitterFailOpen.ps1'
    TraceEmitterFailOpenCheckName                = 'trace-emitter-fail-open'
    TraceEmitterFixtureRelativeDir               = 'scripts/validation/fixtures/trace-emitter-work'
    CursorTraceEmitScriptRelativePath            = 'adapters/cursor/assets/hooks/emit-trace.ps1'
    ClaudeTraceEmitScriptRelativePath            = 'adapters/claude/assets/hooks/emit-trace.ps1'
    CodexTraceEmitScriptRelativePath             = 'adapters/codex/assets/hooks/emit-trace.ps1'
    CursorHooksJsonRelativePath                  = 'adapters/cursor/assets/hooks/hooks.json'
    InvokeTraceHarvestScriptRelativePath         = 'scripts/trace/Invoke-TraceHarvest.ps1'
    AssertTraceHarvestScriptName                 = 'Assert-TraceHarvest.ps1'
    TraceHarvestCheckName                        = 'trace-harvest'
    TraceHarvestValidFixtureRelativeDir          = 'scripts/validation/fixtures/sdd-artifacts/trace/valid'
    TraceHarvestFixtureFeatureSlug               = '000-fixture-trace'
    TraceHarvestExitOk                           = 0
    TraceHarvestExitFail                         = 2
    TraceHarvestStatusOk                         = 'ok'
    TraceHarvestStatusError                      = 'error'
    TraceHarvestReasonOk                         = 'feature TRACE harvested'
    TraceHarvestReasonTraceAbsent                = 'trace_absent: TRACE.jsonl not present under feature root'
    TraceHarvestReasonTraceEmpty                 = 'trace_empty: TRACE.jsonl has no non-empty lines'
    TraceHarvestReasonInvalidJson                = 'invalid_json: TRACE.jsonl contains unparsable lines'
    TraceHarvestReasonFeatureMissing             = 'feature_missing: feature root not found'
    TraceHarvestReasonInvalidScope               = 'invalid_scope: feature root must be features/NNN-slug under repo'
    TraceHarvestReasonPathEscape                 = 'path_escape: feature root escapes repo root'
    TraceHarvestReasonSessionsDenied             = 'sessions_denied: harvest must not read sdd/sessions'
    TraceHarvestReasonNotDirectory               = 'invalid_root: feature root is not a directory'
    TraceHarvestFeatureLeafPattern               = '(?i)^[0-9]{3}-[a-z0-9][a-z0-9\-]*$'
    TraceHarvestSessionsSegmentPattern           = '(?i)(^|[/\\])sdd[/\\]sessions([/\\]|$)'
    SpawnPublishKnobsRelativePath                = 'adapters/_shared/SpawnPublishKnobs.ps1'
    SpawnPublishHonestyRelativePath              = 'adapters/_shared/spawn-publish-honesty.md'
    SpawnPublishCoreAgentsRelativeDir            = 'core/agents'
    AssertPublishSpawnKnobsScriptName            = 'Assert-PublishSpawnKnobs.ps1'
    PublishSpawnKnobsCheckName                   = 'publish-spawn-knobs'
    PlanLedgerClaimSchemaId                      = 'plan-ledger-claim/v1'
    PlanLedgerStatusClaimed                      = 'claimed'
    PlanLedgerStatusReleased                     = 'released'
    PlanLedgerDirectoryName                      = 'ledger'
    PlanLedgerSessionsFolderName                 = 'sessions'
    PlanLedgerExitClaimOk                        = 0
    PlanLedgerExitClaimRejected                  = 2
    PlanLedgerExitUsage                          = 1
    PlanLedgerReasonStepAlreadyClaimed           = 'step_already_claimed'
    PlanLedgerReasonHolderRequired               = 'holder_required'
    PlanLedgerReasonReleaseForbidden             = 'release_forbidden'
    PlanLedgerReasonNotClaimed                   = 'step_not_claimed'
    PlanLedgerEventClaimRejected                 = 'claim_rejected'
    PlanLedgerFixturePlanRelativePath            = 'scripts/validation/fixtures/sdd-artifacts/plan/valid.md'
    PlanLedgerFixtureHolderA                     = 'holder-A'
    PlanLedgerFixtureHolderB                     = 'holder-B'
    PlanLedgerFixtureStep                        = 2
    PlanLedgerSessionsRootRequired               = 'SessionsRoot is required (or pass -SddRoot so sessions = <SddRoot>/sessions).'
    PlanLedgerRepoPathMissing                    = 'RepoPath not found: {0}'
    PlanLedgerPlanPathMissing                    = 'PlanPath not found: {0}'
    PlanLedgerDoubleClaimFormat                  = 'PLAN-LEDGER reject: step {0} already claimed by holder={1}; attempted_holder={2}; reason=step_already_claimed'
    PlanLedgerReleaseDeniedFormat                = 'PLAN-LEDGER release denied: attempted_holder={0}; existing_holder={1}; reason=release_forbidden'
    PlanLedgerUnknownAction                      = 'Unknown PLAN-LEDGER action.'
    ExecutionModesReferenceRelativePath          = 'core/skills/orchestrate-develop/references/execution-modes.md'
    ExecutionModesSkillIndexRelativePath         = 'core/skills/orchestrate-develop/reference.md'
    ExecutionModesSkillBodyRelativePath          = 'core/skills/orchestrate-develop/SKILL.md'
    InvokeExecutionModeGateScriptRelativePath    = 'scripts/ledger/Invoke-ExecutionModeGate.ps1'
    AssertExecutionModesScriptName               = 'Assert-ExecutionModes.ps1'
    ExecutionModesCheckName                      = 'execution-modes'
    ExecutionModeGateSchemaId                    = 'execution-mode-gate/v1'
    ExecutionModeAllowedIds                      = @('serial', 'parallel', 'manual')
    ExecutionModeAuditFileName                   = 'execution-mode.audit.jsonl'
    ExecutionModeEventRejected                   = 'mode_rejected'
    ExecutionModeReasonOk                        = 'mode_ok'
    ExecutionModeReasonUnknown                   = 'mode_unknown'
    ExecutionModeReasonParallelForbidden         = 'mode_parallel_forbidden'
    ExecutionModeReasonTaskSpawnForbidden        = 'mode_task_spawn_forbidden'
    ExecutionModeReasonClaimRequired             = 'mode_claim_required'
    ExecutionModeExitOk                          = 0
    ExecutionModeExitUsage                       = 1
    ExecutionModeExitRejected                    = 2
    ExecutionModeRejectFormat                    = 'EXECUTION-MODE reject: reason={0}; mode={1}; intent={2}'
    InvokePrdPlanChangePreflightScriptRelativePath = 'scripts/validation/Invoke-PrdPlanChangePreflight.ps1'
    AssertPrdPlanChangePreflightScriptName       = 'Assert-PrdPlanChangePreflight.ps1'
    PrdPlanChangePreflightCheckName              = 'prd-plan-change-preflight'
    PrdPlanChangePreflightDeliverRefRelativePath = 'core/skills/orchestrate-deliver/references/preflight-prd-plan-change.md'
    PrdPlanChangePreflightDeliverIndexRelativePath = 'core/skills/orchestrate-deliver/reference.md'
    PrdPlanChangePreflightDeliverSkillRelativePath = 'core/skills/orchestrate-deliver/SKILL.md'
    PrdPlanChangePreflightExitAllow              = 0
    PrdPlanChangePreflightExitUsage              = 1
    PrdPlanChangePreflightExitBlock              = 2
    PrdPlanChangePreflightReasonOrphanReq        = 'orphan_req'
    PrdPlanChangePreflightReasonNnnMismatch      = 'nnn_mismatch'
    PrdPlanChangePreflightReasonChangeInvalid    = 'change_brownfield_invalid'
    PrdPlanChangePreflightReasonValidatePrd      = 'validate_prd_failed'
    PrdPlanChangePreflightReasonValidatePlan     = 'validate_plan_failed'
    PrdPlanChangePreflightReasonValidateChange   = 'validate_change_failed'
    PrdPlanChangePreflightReasonFeatureMissing   = 'feature_root_missing'
    PrdPlanChangePreflightReasonPlanMissing      = 'plan_path_missing'
    PrdPlanChangePreflightReasonPrdMissing       = 'prd_path_missing'
    PrdPlanChangePreflightReasonPrdPathEscape    = 'prd_path_escape'
    PrdPlanChangePreflightReasonChangeMissing    = 'change_missing_brownfield'
    PrdPlanChangePreflightNatureBrownfield       = 'brownfield'
    PrdPlanChangePreflightNatureGreenfield       = 'greenfield'
    PrdPlanChangePreflightFeatureNaturePattern   = '(?im)\|\s*\*{0,2}Nature\*{0,2}\s*\|\s*`?([^|`]+?)`?\s*\|'
    PrdPlanChangePreflightPrdFileNnnPattern      = '(?i)^(\d{3})_'
    PrdPlanChangePreflightPlanFileNnnPattern     = '(?i)^PLAN_(\d{3})_'
    PrdPlanChangePreflightFeatureFolderNnnPattern = '(?i)(?:^|[/\\])(\d{3})-[^/\\]+$'
    PrdPlanChangePreflightChangeFileName         = 'CHANGE.md'
    PrdPlanChangePreflightFeatureFileName        = 'FEATURE.md'
    PrdPlanChangePreflightFixtureValidRelativeDir = 'preflight/valid'
    PrdPlanChangePreflightFixtureOrphanRelativeDir = 'preflight/orphan-req'
    PrdPlanChangePreflightFixtureNnnRelativeDir  = 'preflight/nnn-mismatch'
    PrdPlanChangePreflightFixtureChangeRelativeDir = 'preflight/change-invalid'
    PrdPlanChangePreflightBlockFormat            = 'preflight: BLOCK reason={0}; detail={1}'
    PrdPlanChangePreflightAllowFormat            = 'preflight: ALLOW paths={{ plan={0}; prd={1}; change={2} }}'
    PrdPlanChangePreflightMutatingCmdPattern     = '(?i)\b(Set-Content|Add-Content|Out-File|New-Item\s+-ItemType\s+File|Remove-Item|Move-Item|Copy-Item)\b'
    OrchestratorSessionPolicyRelativePath        = 'core/policy/orchestrator-session.md'
    OrchestratorCharterHeadingMarker             = 'ORCHESTRATOR CHARTER'
    OrchestratorCharterRuleMarkers               = @(
        'Parent orchestrator-only',
        'Delegate in parallel',
        'Post-change validation'
    )
    OrchestratorCommandMarkers                   = @(
        'orchestrator always',
        'orchestrator adaptive',
        'orchestrator status',
        'orchestrate always',
        'parent adaptive',
        'orchestrate status'
    )
    PreferencesSchemaDocRelativePaths            = @(
        'core/policy/caveman-mode.md',
        'core/skills/_shared/caveman/CAVEMAN.md',
        'core/sdd/STORAGE.md',
        'core/skills/_shared/sdd-artifacts/STORAGE.md'
    )
    PreferencesSchemaKeyMarkers                  = @(
        'caveman_mode',
        'caveman_level',
        'orchestrator_mode',
        'artifact_language',
        'verify_mode'
    )
    ExecutionPolicyHeadingMarker                 = '## Execution policy'
    ExecutionPolicyTemplateRelativePaths         = @(
        'core/skills/_shared/templates/sdd/PLAN.md',
        'core/skills/_shared/templates/sdd/PRD.md'
    )
    ExecutionPolicySkillWiringRelativePaths      = @(
        'core/skills/sdd-plan/SKILL.md',
        'core/skills/sdd-spec/SKILL.md',
        'core/skills/sdd-develop/SKILL.md'
    )
    ToolkitOrchestratorInstallMenuChoices        = @('1', '2')
    PreferencesFileName                          = 'preferences.json'
    # Fixture-local keyed uninstall asserts (no live-home write). Kept out of
    # validate-core because they call validate-agent which re-enters validate-core.
    # CI runs them via a dedicated workflow step (inline loop over this list).
    KeyedUninstallCiAsserts            = @(
        @{ CheckName = 'claude-keyed-uninstall'; ScriptName = 'Assert-ClaudeKeyedUninstall.ps1' },
        @{ CheckName = 'copilot-keyed-uninstall'; ScriptName = 'Assert-CopilotKeyedUninstall.ps1' },
        @{ CheckName = 'codex-keyed-uninstall'; ScriptName = 'Assert-CodexKeyedUninstall.ps1' },
        @{ CheckName = 'opencode-keyed-uninstall'; ScriptName = 'Assert-OpenCodeKeyedUninstall.ps1' },
        @{ CheckName = 'antigravity-keyed-uninstall'; ScriptName = 'Assert-AntigravityKeyedUninstall.ps1' },
        @{ CheckName = 'grok-keyed-uninstall'; ScriptName = 'Assert-GrokKeyedUninstall.ps1' },
        @{ CheckName = 'cursor-keyed-uninstall'; ScriptName = 'Assert-CursorKeyedUninstall.ps1' },
        @{ CheckName = 'zcode-keyed-uninstall'; ScriptName = 'Assert-ZcodeKeyedUninstall.ps1' },
        @{ CheckName = 'hermes-keyed-uninstall'; ScriptName = 'Assert-HermesKeyedUninstall.ps1' },
        @{ CheckName = 'openhands-keyed-uninstall'; ScriptName = 'Assert-OpenHandsKeyedUninstall.ps1' }
    )
    AllowUserHomeProbeNamePrefix       = '.agent-dev-toolkit-allowuserhome-probe-'
    RelativeParentPathSegment          = '..'
    CurrentDirectoryPathSegment        = '.'
    SkipCoreParameterName              = 'SkipCore'
    ForceStubParameterName             = 'ForceStub'
    SpawnMdRelativePath            = 'core/skills/_shared/agents/SPAWN.md'
    InventedMissingSpawnMdRel      = 'core/skills/_shared/agents/__invented_missing_SPAWN__.md'
    LanguageMdRelativePath         = 'core/skills/_shared/agents/LANGUAGE.md'
    InventedMissingLanguageMdRel   = 'core/skills/_shared/agents/__invented_missing_LANGUAGE__.md'
    LanguageEnUsSpawnMarker        = 'en-US'
    JavaDeveloperSkillDirectoryName = 'java-developer'
    JavaDeveloperSkillFileName     = 'SKILL.md'
    JavaDeveloperRouteToken        = '/java-developer'
    JavaDeveloperCatalogToken      = 'java-developer'
    JavaMavenPomFileName           = 'pom.xml'
    JavaGradleBuildFileName        = 'build.gradle'
    RoutingMdRelativePath          = 'core/skills/_shared/agents/ROUTING.md'
    DeveloperSkillRelativePath     = 'core/skills/developer/SKILL.md'
    SkillsCatalogRelativePath      = 'docs/SKILLS.md'
    InventedMissingJavaSkillRel    = 'core/skills/__invented_missing_java_developer__/SKILL.md'
    OrchestrateSkillNamePrefix     = 'orchestrate-'
    OrchestrateSkillFileName       = 'SKILL.md'
    OrchestrateReferenceFileName   = 'reference.md'
    CodeReviewSkillDirectoryName   = 'code-review'
    SpawnTaskCitationMarker        = 'Task'
    SpawnContractMarker            = 'SPAWN'
    HermesDelegateTaskNeedle       = 'delegate_task'
    HermesSpawnBridgeSectionHeading = '## Hermes spawn bridge (this host only)'
    SpawnUseOwnHostRowHeading      = 'Use only the current host row'
    SpawnFallbackMarker            = 'fallback'
    SpawnInParentMarker            = 'in-parent'
    SubagentsCapabilityName        = 'subagents'
    SubagentsNativeValue           = 'native'
    SubagentsNoneValue             = 'none'
    RegistryAgentsPropertyName     = 'agents'
    RegistryCapabilitiesPropertyName = 'capabilities'
    CiWorkflowRelativePath         = '.github/workflows/validate-toolkit.yml'
    SyncAgentRelativePath          = 'scripts/sync-agent.ps1'
    ValidateAgentRelativePath      = 'scripts/validate-agent.ps1'
    ToolkitActionSync              = 'Sync'
    ToolkitActionValidate          = 'Validate'
    ToolkitActionSyncAndValidate   = 'SyncAndValidate'
    ToolkitActionValidateCore      = 'ValidateCore'
    ToolkitActionListAgents        = 'ListAgents'
    ToolkitActionUninstall         = 'Uninstall'
    ToolkitActionBackup            = 'Backup'
    PublishCommandNames            = @(
        'Publish-Skills',
        'Publish-Policy',
        'Publish-Router',
        'Publish-Agents',
        'Publish-Hooks'
    )
    CopilotAgentId                 = 'copilot'
    CopilotModeUser                = 'user'
    CopilotModeRepo                = 'repo'
    CopilotValidModes              = @('user', 'repo')
    CopilotFixtureUserRel          = 'scripts/validation/fixtures/copilot/user'
    CopilotFixtureRepoRel          = 'scripts/validation/fixtures/copilot/repo'
    CopilotWorkFixtureUserRel      = 'scripts/validation/fixtures/copilot-user-ci-smoke'
    CopilotWorkFixtureRepoRel      = 'scripts/validation/fixtures/copilot-repo-ci-smoke'
    ModeParameterName              = 'Mode'
    ReparsePointResolverTypeName   = 'ToolkitReparsePointResolver'
    ExtendedLengthPathPrefix       = '\\?\'
    ExtendedLengthUncPrefix        = '\\?\UNC\'
    DevicePathPrefix               = '\\.\'
    DeviceUncPrefix                = '\\.\UNC\'
    UncPathPrefix                  = '\\'
    AdapterSmokePassMarker         = 'Adapter smoke: PASS'
    ManagedSkillsManifestFileName  = '.toolkit-managed-skills.json'
    ManagedSkillsManifestSchemaVersion = 1
    ManagedSkillsManifestSkillsProperty = 'skills'
    ManagedSkillsManifestSchemaProperty = 'schemaVersion'
    ManagedPublishInventoryFileName  = '.toolkit-managed-publish.json'
    ManagedPublishInventorySchemaVersion = 1
    ManagedPublishInventoryFilesProperty = 'files'
    ManagedPublishInventorySchemaProperty = 'schemaVersion'
    ManagedPublishInventoryKindProperty = 'kind'
    ManagedPublishInventorySha256Property = 'sha256'
    ManagedPublishInventoryKindRouter = 'router'
    ManagedPublishInventoryAtomicWriteTempSuffix = '.tmp'
    ManagedPublishInventoryAtomicWriteMaxAttempts = 3
    ManagedPublishInventoryAtomicWriteRetryDelayMs = 50
    RouterFilePreservedNoteFormat      = '{0} preserved (operator edit or content drift; not toolkit-owned).'
    RegistryPublishSurfacePropertyName = 'publishSurface'
    RegistryPublishSurfaceWholeFileRouterPropertyName = 'wholeFileRouter'
    DefaultTextFileExtensionPattern = '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    JsonConvertDepthShallow        = 5
    JsonConvertDepthDeep           = 8
    ToolkitMenuRule                = '========================================='
    ToolkitChoiceBack              = '0'
    ToolkitChoiceYes               = 'y'
    ToolkitChoiceNo                = 'n'
    ToolkitChoiceYesShort          = 'yes'
    ToolkitChoiceNoShort           = 'no'
    ToolkitMainMenuChoices         = @('0', '1', '2', '3', '4', '5', '6', '7')
    ToolkitTargetMenuChoices       = @('0', '1', '2', '3')
    ToolkitLabMenuChoices          = @('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')
    ExpectedCiSmokeScriptCount     = 10
    ToolkitHelpMenuChoices         = @('0', '1', '2', '3')
    ToolkitCopilotModeMenuChoices  = @('0', '1', '2')
    ToolkitConfirmRunChoices       = @('0', 'y', 'n', 'yes', 'no')
    OfficialUserRootPathProperty   = 'OfficialUserRootPath'
    OfficialUserRootRelativeProperty = 'OfficialUserRootRelativePath'
    CiSmokeScripts                 = @(
        @{ Id = '1'; Label = 'Cursor CI smoke'; RelativePath = 'scripts/validation/Invoke-CursorCiSmoke.ps1' },
        @{ Id = '2'; Label = 'Antigravity CI smoke'; RelativePath = 'scripts/validation/Invoke-AntigravityCiSmoke.ps1' },
        @{ Id = '3'; Label = 'Claude CI smoke'; RelativePath = 'scripts/validation/Invoke-ClaudeCiSmoke.ps1' },
        @{ Id = '4'; Label = 'Codex CI smoke'; RelativePath = 'scripts/validation/Invoke-CodexCiSmoke.ps1' },
        @{ Id = '5'; Label = 'Copilot CI smoke suite'; RelativePath = 'scripts/validation/Invoke-CopilotCiSmokeSuite.ps1' },
        @{ Id = '6'; Label = 'OpenCode CI smoke'; RelativePath = 'scripts/validation/Invoke-OpenCodeCiSmoke.ps1' },
        @{ Id = '7'; Label = 'Grok CI smoke'; RelativePath = 'scripts/validation/Invoke-GrokCiSmoke.ps1' },
        @{ Id = '8'; Label = 'ZCode CI smoke'; RelativePath = 'scripts/validation/Invoke-ZCodeCiSmoke.ps1' },
        @{ Id = '9'; Label = 'Hermes CI smoke'; RelativePath = 'scripts/validation/Invoke-HermesCiSmoke.ps1' },
        @{ Id = '10'; Label = 'OpenHands CI smoke'; RelativePath = 'scripts/validation/Invoke-OpenHandsCiSmoke.ps1' }
    )
}

$script:ToolkitMessage = @{
    InstallRootRequired                = 'InstallRoot is required.'
    UserProfileUnavailable             = 'USERPROFILE is not set; cannot validate InstallRoot safety.'
    InstallRootUnderUserProfileBlocked = 'InstallRoot resolves under USERPROFILE ({0}). Refuse write/smoke targets in the user profile unless -AllowUserHome is set. Path: {1}'
    InstallRootResolveFailed           = 'InstallRoot path could not be resolved: {0}'
    InstallRootReparseResolveFailed    = 'InstallRoot reparse-point resolution failed for existing path ({0}): {1}. Refuse fail-open lexical fallback.'
    InstallRootReparseEmptyFinalPath   = 'GetFinalPathNameByHandle returned an empty path.'
    DeletePathRequired                 = 'Delete candidate path is required.'
    DeletePathIsInstallRoot            = 'Refuse delete of InstallRoot itself (wholesale wipe blocked): {0}'
    DeletePathEscapesInstallRoot       = 'Refuse delete: path resolves outside InstallRoot. Path: {0}; Final: {1}; InstallRoot: {2}'
    FromPathRequired                   = 'FromPath is required.'
    ToolkitRepoRootNotFound            = 'Toolkit repo root not found from path: {0}'
    ToolkitPathLibNotFound             = 'Toolkit path lib not found: {0}'
    AgentRequired                      = 'Agent is required. Pass -Agent <id>. Available agents: {0}'
    AgentUnknown                       = 'Unknown agent ''{0}''. Available agents: {1}'
    RegistryMissing                    = 'Adapter registry not found: {0}'
    RegistryAgentsMissing              = 'Adapter registry has no agents array: {0}'
    AdapterModuleMissing               = 'Adapter module missing for agent ''{0}'': {1}'
    AdapterModuleEscapesAdaptersRoot   = 'Adapter module for agent ''{0}'' resolves outside adapters/ root: {1} (expected under {2})'
    AdapterNotImplemented              = 'Adapter for agent ''{0}'' is not implemented. Publish-* refused. Implement the adapter before syncing. Detail: {1}'
    SyncPublishFailed                  = 'Sync publish step failed for agent ''{0}'': {1}'
    AdapterFixtureRootsFailed          = 'Get-InstallRoots failed for agent ''{0}'' while resolving default fixture InstallRoot: {1}'
    AdapterFixturePathMissing          = 'Get-InstallRoots for agent ''{0}'' did not return FixtureRelativePath; refuse Cursor-shaped DefaultFixtureInstallRootRel fallback.'
    AdapterFixtureCommandMissing       = 'Adapter module is loaded for agent ''{0}'' but Get-InstallRoots is missing; refuse DefaultFixtureInstallRootRel fallback.'
    PlaceholderUnresolved              = 'Unresolved placeholder {0} remains under {1}'
    PlaceholderMapRequired             = 'PlaceholderMap is required unless -SkipPlaceholderResolve is set.'
    ManagedSkillsManifestInvalid       = 'Managed skills manifest is invalid at {0}: {1}'
    ManagedPublishInventoryInvalid     = 'Managed publish inventory is invalid at {0}: {1}'
    ManagedPublishRelativePathInvalid  = 'Managed publish relative path is invalid (empty, rooted, current/parent segment, or path separator): {0}'
    ManagedPublishInventoryPathEscapesInstallRoot = 'Managed publish inventory path escapes InstallRoot. Path: {0}; InstallRoot: {1}'
    ManagedPublishInventoryEntryMissingSha256 = 'Managed publish inventory entry for ''{0}'' is missing sha256.'
    ManagedPublishInventoryEntryMissingKind = 'Managed publish inventory entry for ''{0}'' is missing kind.'
    ManagedPublishInventoryAtomicWriteFailed = 'Failed to write managed publish inventory at {0} after {1} attempt(s): {2}'
    InstallRootRequiredForPublishInventory = 'InstallRoot is required for managed publish inventory operations.'
    RelativePathRequiredForPublishInventory = 'RelativePath is required for managed publish inventory operations.'
    FilePathRequiredForContentHash     = 'Path is required for file content hash.'
    FileNotFoundForContentHash         = 'File not found for content hash: {0}'
    RegistryPublishSurfaceMissing      = 'registry agent ''{0}'' missing publishSurface'
    RegistryPublishSurfaceWholeFileRouterMissing = 'registry agent ''{0}'' missing publishSurface.wholeFileRouter'
    RegistryPublishSurfaceWholeFileRouterInvalid = 'registry agent ''{0}'' publishSurface.wholeFileRouter must be an array'
    RegistryPublishSurfacePathInvalid  = 'registry agent ''{0}'' publishSurface.wholeFileRouter path invalid: {1}'
    RegistryPublishSurfaceMismatch     = 'registry agent ''{0}'' publishSurface.wholeFileRouter expected [{1}], got [{2}]'
    ManagedSkillNameInvalid            = 'Managed skill name is invalid (empty, rooted, current/parent segment, or path separator): {0}'
    ManagedSkillPathEscapesDestination = 'Managed skill path escapes DestinationSkillsRoot. Skill: {0}; Path: {1}; Root: {2}'
    ManagedCopyRelativePathInvalid     = 'Managed copy relative path is invalid (contains parent segment): {0}'
    ManagedCopyPathEscapesRoot         = 'Managed copy path escapes root. Path: {0}; Root: {1}'
    SourceSkillsRootRequired           = 'SourceSkillsRoot is required.'
    DestinationSkillsRootRequired      = 'DestinationSkillsRoot is required.'
    SourceAgentsRootRequired           = 'SourceAgentsRoot is required.'
    DestinationAgentsRootRequired      = 'DestinationAgentsRoot is required.'
    CoreAgentsMissing                  = 'Core agents source is missing: {0}'
    ValidateCoreMissing                = 'validate-core entry not found: {0}'
    RouterDocLinkDoesNotExist          = '{0} does not exist under repo root'
    RouterDocLinksMissingTargets       = 'missing targets: {0}'
    RouterDocLinksNoLiterals           = 'no docs/ or core/ path literals found in router'
    RouterDocLinksForbiddenGuides      = 'forbidden guide refs still present: {0}'
    RouterDocLinksNegativeExpectedFail = 'invented missing path did not fail existence check: {0}'
    NoFeaturesDocLinksNegativeExpectedFail = 'synthetic features story path / SPAWN_MATRIX sample did not match forbidden patterns'
    NoFeaturesDocLinksNoScanTargets    = 'no versioned markdown scan targets found (docs/, root README/CONTRIBUTING/SECURITY, adapters/*/README.md)'
    NoFeaturesDocLinksViolations       = 'published docs must not reference gitignored features/ story artifacts (use docs/SPAWN.md or core SPAWN.md): {0}'
    NoFormaAliasNegativeExpectedFail   = 'synthetic Forma alias sample did not match forbidden patterns'
    NoFormaAliasNoScanTargets          = 'no markdown scan targets found (core/, docs/, docs-site/, memory-bank/, README.md, PRODUCT.md)'
    NoFormaAliasViolations             = 'Forma A/B/C aliases must use work-track names only: {0}'
    OrchestratorCharterMissingMarker   = '{0} missing orchestrator charter marker: {1}'
    OrchestratorCommandMissingMarker   = 'orchestrator-session missing command marker: {0}'
    PreferencesSchemaMissingKey        = '{0} missing preferences key: {1}'
    ExecutionPolicyMissingHeading      = '{0} missing ## Execution policy'
    ExecutionPolicySkillMissingRef     = '{0} must reference Execution policy'
    ToolkitOrchestratorInstallPromptHeader = 'Orchestrator mode (preferences.json missing)'
    ToolkitOrchestratorInstallPromptAlwaysLine = '  [1] Always orchestrate (default)'
    ToolkitOrchestratorInstallPromptAdaptiveLine = '  [2] Adaptive'
    ToolkitOrchestratorInstallPromptMenu = 'Choice'
    ToolkitOrchestratorInstallDefaultChoice = '1'
    ToolkitOrchestratorPreferencesCreated = 'Created preferences.json at {0} (orchestrator_mode={1}).'
    SpawnMdMissing                     = 'SPAWN contract missing or empty: {0}'
    SpawnMdNegativeExpectedFail        = 'invented missing SPAWN path did not fail existence check: {0}'
    LanguageMdMissing                  = 'LANGUAGE contract missing or empty: {0}'
    LanguageMdNegativeExpectedFail     = 'invented missing LANGUAGE path did not fail existence check: {0}'
    SpawnMissingEnUsLanguageMarker     = 'SPAWN.md missing LANGUAGE.md pointer or en-US spawn marker'
    RegistrySubagentsMissing           = 'registry agent(s) missing capabilities.subagents: {0}'
    RegistrySubagentsNegativeExpectedFail = 'synthetic agent missing subagents did not fail presence check'
    RegistryAgentsMissingForSpawn      = 'Adapter registry has no agents array: {0}'
    OrchestrateTaskWithoutFallbackExpectedFail = 'synthetic Task citation without SPAWN/fallback did not fail contract check'
    OrchestrateTaskWithoutSpawnFallback = 'orchestrate skill cites Task without SPAWN and fallback markers: {0}'
    OrchestrateSkillsDirMissing        = 'orchestrate skills directory missing under core/skills'
    CodeReviewMissingSpawnFallback     = 'code-review multi-angle missing SPAWN/fallback/in-parent markers'
    CodeReviewSkillMissing             = 'code-review SKILL.md missing: {0}'
    JavaDeveloperMissingFromDiskExpectedFail = 'invented missing java-developer skill did not fail presence check: {0}'
    JavaDeveloperMissingFromDisk       = 'java-developer skill missing on disk: {0}'
    JavaMissingFromCatalogOrRoutesExpectedFail = 'synthetic surfaces without java-developer did not fail catalog/routes check'
    JavaMissingFromCatalogOrRoutes     = 'java-developer missing from catalog or routes: {0}'
    JavaRoutingSurfaceMissing          = 'routing surface file missing: {0}'
    JavaDeveloperNotRouted             = 'java-developer present on disk but not fully routed across catalog/routes'
    SmokeSkippedNotImplemented         = 'Invoke-SmokeValidate skipped (adapter not implemented / no-op). Core validation still applies.'
    SmokeFailed                        = 'Invoke-SmokeValidate failed for agent ''{0}'': {1}'
    SmokeHarnessTitle                  = 'agent-dev-toolkit smoke harness'
    SmokeHarnessFixtureMissing         = 'Smoke fixture InstallRoot is missing: {0}'
    SmokeHarnessInstallRootOk          = 'InstallRoot (fixture): {0}'
    SmokeHarnessMarkerWritten          = 'Smoke marker written under fixture: {0}'
    SmokeHarnessCursorUnchanged        = 'USERPROFILE .cursor snapshot unchanged (no home writes).'
    SmokeHarnessCursorChanged          = 'USERPROFILE .cursor changed during smoke harness. Refuse home writes. Before={0} After={1}'
    SmokeHarnessAdapterNoOp            = 'Adapter Invoke-SmokeValidate: not-implemented no-op (expected when adapter is stubbed).'
    SmokeHarnessPassed                 = 'Smoke harness PASSED.'
    SmokeHarnessFailed                 = 'Smoke harness FAILED.'
    ToolkitBannerTitle                 = 'Agent Dev Toolkit - Smart Manager'
    ToolkitAvailableAgentsHeader       = 'Available agents (registry):'
    ToolkitAgentListLine               = '  [{0}] {1} ({2})'
    ToolkitAgentPrompt                 = 'Select agent id or number (0 = Back)'
    ToolkitAgentBackLine               = '  [0] Back'
    ToolkitInvalidAgentSelection       = 'Invalid agent selection.'
    ToolkitInvalidMenuOption           = 'Invalid option.'
    ToolkitInvalidMenuOptionRetry      = 'Invalid option. Enter a listed number (or 0 to go back).'
    ToolkitInvalidAction               = 'Unknown -Action ''{0}''. Valid: {1}'
    ToolkitActionRequiresAgent         = 'Action ''{0}'' requires -Agent <id> (or interactive selection). Available agents: {1}'
    ToolkitStubComingSoon              = '{0} is not available yet (coming with adapters).'
    ToolkitBackupStubRefused           = 'Backup is not implemented. Refusing success exit. Pass -ForceStub only for tooling tests that explicitly acknowledge the stub.'
    ToolkitBackupStubForced            = 'Backup stub acknowledged via -ForceStub (not a real backup).'
    ToolkitUninstallFailed             = 'Uninstall failed for agent ''{0}'': {1}'
    ToolkitUninstallCompleted          = 'Uninstall completed.'
    ToolkitUninstallCommandMissing     = 'Adapter module for agent ''{0}'' does not export Uninstall-Toolkit.'
    ToolkitCoreSkipped                 = 'Core validation skipped (-SkipCore).'
    ToolkitExiting                     = 'Exiting...'
    ToolkitPressEnter                  = 'Press Enter to continue...'
    ToolkitMenuPrompt                  = 'Choose an option'
    ToolkitYesNoHintDefaultYes         = '[Y/n]'
    ToolkitYesNoHintDefaultNo          = '[y/N]'
    ToolkitMenuSyncLine                = '[1] Sync agent            Publish skills/policy/hooks (opens agent + target wizard)'
    ToolkitMenuValidateLine            = '[2] Validate agent        validate-core + adapter smoke for one agent'
    ToolkitMenuSyncValidateLine        = '[3] Sync then validate    Sync, then smoke that agent'
    ToolkitMenuValidateCoreLine        = '[4] Validate core only    Repo contracts; no agent home write'
    ToolkitMenuValidationLabLine       = '[5] Validation lab        Run core or a CI smoke script'
    ToolkitMenuUninstallLine           = '[6] Uninstall agent       Keyed toolkit removal (preserves SDD sessions/manifest)'
    ToolkitMenuHelpLine                = '[7] Help and docs         What each action does + equivalent flags'
    ToolkitMenuExitLine                = '[0] Exit'
    ToolkitMenuWhatHint                = 'What do you want to do?'
    ToolkitAgentWizardTitle            = 'Select agent'
    ToolkitTargetWizardTitle           = 'Select InstallRoot target'
    ToolkitTargetLiveLine              = '[1] Live agent home ({0}) - recommended default'
    ToolkitTargetFixtureLine           = '[2] In-repo fixture (CI / learn the CLI - no profile write)'
    ToolkitTargetCustomLine            = '[3] Custom path'
    ToolkitTargetBackLine              = '[0] Back'
    ToolkitTargetLiveUnknown           = 'official user root'
    ToolkitTargetLiveCodexDualLine     = '    Codex note: config/AGENTS under ~/.codex; USER skills also at ~/.agents/skills; default sync writes plugin/ under InstallRoot'
    ToolkitTargetMenuDefaultChoice     = '1'
    ToolkitTargetMenuPromptWithDefault = 'Select option [0-3] (Enter = live home)'
    ToolkitCustomPathPrompt            = 'Enter InstallRoot path'
    ToolkitCustomPathRequired          = 'InstallRoot path is required.'
    ToolkitAllowUserHomeConfirm        = 'This path is under USERPROFILE. Allow live-home write (-AllowUserHome)?'
    ToolkitLiveHomeConfirm             = 'Deploy to live agent home? This writes under your user profile.'
    ToolkitCopilotModeTitle            = 'Copilot Mode'
    ToolkitCopilotModeUserLine         = '[1] user  — personal Copilot root (~/.copilot)'
    ToolkitCopilotModeRepoLine         = '[2] repo  — consumer app .github layout'
    ToolkitCopilotModeBackLine         = '[0] Back'
    ToolkitSummaryTitle                = 'Plan summary'
    ToolkitSummaryAgent                = '  Agent:        {0}'
    ToolkitSummaryMode                 = '  Mode:         {0}'
    ToolkitSummaryInstallRoot          = '  InstallRoot:  {0}'
    ToolkitSummaryAllowUserHome        = '  AllowUserHome:{0}'
    ToolkitSummaryTargetKind           = '  Target:       {0}'
    ToolkitConfirmRunPrompt            = 'Run this plan? (y = run, n = cancel, 0 = back)'
    ToolkitCancelled                   = 'Cancelled.'
    ToolkitSkippingValidateAfterSync   = 'Skipping validate because sync failed.'
    ToolkitLabTitle                    = 'Validation lab'
    ToolkitLabCoreLine                 = '[1] Validate core (validate-core.ps1)'
    ToolkitLabBackLine                 = '[0] Back'
    ToolkitLabSmokeLine                = '[{0}] {1}'
    ToolkitHelpTitle                   = 'Help and docs'
    ToolkitHelpActionsLine             = '[1] Menu actions explained'
    ToolkitHelpCoreVsAgentLine         = '[2] Validate core vs Validate agent'
    ToolkitHelpFlagsLine               = '[3] Equivalent CLI flags / commands'
    ToolkitHelpBackLine                = '[0] Back'
    ToolkitHelpActionsBody             = @"
Menu actions
------------
[1] Sync agent
    Publishes core skills/policy/router/agents/hooks into an agent InstallRoot via sync-agent.ps1.
    Wizard: pick agent -> fixture | live home | custom path -> confirm.

[2] Validate agent
    Runs validate-core (unless -SkipCore) then the adapter smoke for one agent.

[3] Sync then validate
    Runs Sync, then Validate for the same agent/target.

[4] Validate core only
    Repo contract suite only. Never writes to your agent home.

[5] Validation lab
    Run validate-core or an ephemeral CI smoke (Invoke-*CiSmoke).

[6] Uninstall agent
    Removes keyed toolkit artifacts from InstallRoot (not a wholesale wipe).
    Preserves sdd/sessions and sdd/manifest.json (operator runtime state).

[7] Help and docs
    This help. Full install flags: docs/INSTALL.md
"@
    ToolkitHelpCoreVsAgentBody         = @"
Validate core vs Validate agent
-------------------------------
Validate core
  scripts/validation/validate-core.ps1
  Checks skill contracts, registry, InstallRoot safety, Claude merge, CI workflow
  markers, etc. Safe: no live home deploy.

Validate agent
  scripts/validate-agent.ps1 -Agent <id>
  Runs core (unless -SkipCore) plus adapter Invoke-SmokeValidate against a fixture
  or the InstallRoot you choose. Proves that agent publish layout works.
"@
    ToolkitHelpFlagsBody               = @"
Equivalent non-interactive commands
-----------------------------------
Interactive:
  pwsh -NoProfile -File .\scripts\toolkit.ps1

List agents:
  pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents

Sync fixture (safe):
  pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor

Sync live Cursor home:
  pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor ``
    -InstallRoot `"`$env:USERPROFILE\.cursor`" -AllowUserHome

Validate agent:
  pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet

Validate core:
  pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore

Uninstall (fixture; all registry agents; preserves SDD sessions/manifest):
  pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude

Copilot requires -Mode user|repo.
Direct scripts: docs/INSTALL.md and docs/VALIDATION.md
Backup (-Action Backup) is not implemented (fail-closed unless -ForceStub).
"@
    ToolkitTargetKindFixture           = 'in-repo fixture'
    ToolkitTargetKindLive              = 'live agent home'
    ToolkitTargetKindCustom            = 'custom path'
    ToolkitLiveHomeUnavailable         = 'Could not resolve official live home for agent ''{0}''. Use custom path or fixture.'
    CopilotModeRequired                = 'Agent ''{0}'' requires -Mode. Valid modes: {1}. Example: .\scripts\sync-agent.ps1 -Agent {2} -Mode user'
    CopilotModeInvalid                 = 'Invalid -Mode ''{0}'' for agent ''{1}''. Valid modes: {2}. Example: .\scripts\sync-agent.ps1 -Agent {3} -Mode user'
    EphemeralSmokePreconditionMissing  = 'FAIL preconditions: missing {0}'
    EphemeralSmokeRunning              = 'Running: {0} sync+validate (InstallRoot={1})'
    EphemeralSmokeSyncFailed           = 'FAIL sync exit {0}: {1}'
    EphemeralSmokeValidateFailed       = 'FAIL validate exit {0}: {1}'
    EphemeralSmokeMarkerMissing        = 'FAIL validate output missing marker ''{0}'''
}
