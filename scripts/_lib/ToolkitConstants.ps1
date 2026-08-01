#Requires -Version 5.1
<#
.SYNOPSIS
  Named constants for toolkit scripts (_lib).

.DESCRIPTION
  Avoid magic strings in InstallRoot resolution and related guards.
#>

$script:ToolkitConstant = @{
    AllowUserHomeParameterName     = 'AllowUserHome'
    WhatIfParameterName            = 'WhatIf'
    UserProfileEnvironmentName     = 'USERPROFILE'
    CoreSkillsDirectoryName        = 'core'
    SkillsDirectoryName            = 'skills'
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
    AssertAntigravityOfficialLayoutScriptName = 'Assert-AntigravityOfficialLayout.ps1'
    AssertJavaDeveloperRoutingScriptName = 'Assert-JavaDeveloperRouting.ps1'
    SpawnContractCheckName         = 'spawn-contract'
    AdapterContractCheckName       = 'adapter-contract'
    OrchestrateSpawnFallbackCheckName = 'orchestrate-spawn-fallback'
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
    AssertCanonicalCloneUrlScriptName = 'Assert-CanonicalCloneUrl.ps1'
    CanonicalCloneUrlCheckName     = 'canonical-clone-url'
    AssertTier1AdapterReadmesScriptName = 'Assert-Tier1AdapterReadmes.ps1'
    Tier1AdapterReadmesCheckName   = 'tier1-adapter-readmes'
    AssertSyncAllowUserHomeForwardScriptName = 'Assert-SyncAllowUserHomeForward.ps1'
    SyncAllowUserHomeForwardCheckName = 'sync-allow-user-home-forward'
    AssertCiWorkflowScriptName         = 'Assert-CiWorkflow.ps1'
    CiWorkflowCheckName                = 'ci-workflow'
    AssertNoFeaturesDocLinksScriptName = 'Assert-NoFeaturesDocLinks.ps1'
    NoFeaturesDocLinksCheckName        = 'no-features-doc-links'
    NoFeaturesDocLinksSpawnMatrixPattern = 'SPAWN_MATRIX'
    NoFeaturesDocLinksFeatureFolderPattern = 'features/\d{3}-'
    NoFeaturesDocLinksSyntheticForbiddenSample = 'See features/002-example/US02/ARCH/SPAWN_MATRIX.md'
    AssertManagedSkillsPathSafetyScriptName = 'Assert-ManagedSkillsPathSafety.ps1'
    ManagedSkillsPathSafetyCheckName   = 'managed-skills-path-safety'
    AssertUninstallPathSafetyScriptName = 'Assert-UninstallPathSafety.ps1'
    UninstallPathSafetyCheckName       = 'uninstall-path-safety'
    # Fixture-local keyed uninstall asserts (no live-home write). Kept out of
    # validate-core because they call validate-agent which re-enters validate-core.
    # CI runs them via a dedicated workflow step (inline loop over this list).
    KeyedUninstallCiAsserts            = @(
        @{ CheckName = 'claude-keyed-uninstall'; ScriptName = 'Assert-ClaudeKeyedUninstall.ps1' },
        @{ CheckName = 'copilot-keyed-uninstall'; ScriptName = 'Assert-CopilotKeyedUninstall.ps1' },
        @{ CheckName = 'codex-keyed-uninstall'; ScriptName = 'Assert-CodexKeyedUninstall.ps1' },
        @{ CheckName = 'opencode-keyed-uninstall'; ScriptName = 'Assert-OpenCodeKeyedUninstall.ps1' },
        @{ CheckName = 'antigravity-keyed-uninstall'; ScriptName = 'Assert-AntigravityKeyedUninstall.ps1' },
        @{ CheckName = 'grok-keyed-uninstall'; ScriptName = 'Assert-GrokKeyedUninstall.ps1' }
    )
    AllowUserHomeProbeNamePrefix       = '.agent-dev-toolkit-allowuserhome-probe-'
    RelativeParentPathSegment          = '..'
    CurrentDirectoryPathSegment        = '.'
    SkipCoreParameterName              = 'SkipCore'
    ForceStubParameterName             = 'ForceStub'
    SpawnMdRelativePath            = 'core/skills/_shared/agents/SPAWN.md'
    InventedMissingSpawnMdRel      = 'core/skills/_shared/agents/__invented_missing_SPAWN__.md'
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
    ToolkitLabMenuChoices          = @('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
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
        @{ Id = '8'; Label = 'ZCode CI smoke'; RelativePath = 'scripts/validation/Invoke-ZCodeCiSmoke.ps1' }
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
    ManagedSkillNameInvalid            = 'Managed skill name is invalid (empty, rooted, current/parent segment, or path separator): {0}'
    ManagedSkillPathEscapesDestination = 'Managed skill path escapes DestinationSkillsRoot. Skill: {0}; Path: {1}; Root: {2}'
    ManagedCopyRelativePathInvalid     = 'Managed copy relative path is invalid (contains parent segment): {0}'
    ManagedCopyPathEscapesRoot         = 'Managed copy path escapes root. Path: {0}; Root: {1}'
    SourceSkillsRootRequired           = 'SourceSkillsRoot is required.'
    DestinationSkillsRootRequired      = 'DestinationSkillsRoot is required.'
    ValidateCoreMissing                = 'validate-core entry not found: {0}'
    RouterDocLinkDoesNotExist          = '{0} does not exist under repo root'
    RouterDocLinksMissingTargets       = 'missing targets: {0}'
    RouterDocLinksNoLiterals           = 'no docs/ or core/ path literals found in router'
    RouterDocLinksForbiddenGuides      = 'forbidden guide refs still present: {0}'
    RouterDocLinksNegativeExpectedFail = 'invented missing path did not fail existence check: {0}'
    NoFeaturesDocLinksNegativeExpectedFail = 'synthetic features story path / SPAWN_MATRIX sample did not match forbidden patterns'
    NoFeaturesDocLinksNoScanTargets    = 'no versioned markdown scan targets found (docs/, root README/CONTRIBUTING/SECURITY, adapters/*/README.md)'
    NoFeaturesDocLinksViolations       = 'published docs must not reference gitignored features/ story artifacts (use docs/SPAWN.md or core SPAWN.md): {0}'
    SpawnMdMissing                     = 'SPAWN contract missing or empty: {0}'
    SpawnMdNegativeExpectedFail        = 'invented missing SPAWN path did not fail existence check: {0}'
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
    ToolkitMenuUninstallLine           = '[6] Uninstall agent       Keyed toolkit removal (Cursor/ZCode: not implemented)'
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
    Publishes core skills/policy/router/hooks into an agent InstallRoot via sync-agent.ps1.
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
    Removes keyed toolkit artifacts from InstallRoot where implemented (not a wholesale wipe).
    Cursor and ZCode: Uninstall-Toolkit is not implemented (fail-closed stub).

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

Uninstall (fixture; Claude etc. — not Cursor/ZCode):
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
