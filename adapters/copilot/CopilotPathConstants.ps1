#Requires -Version 5.1
<#
.SYNOPSIS
  Path and placeholder constants for the GitHub Copilot adapter.

.DESCRIPTION
  Kept inside adapters/copilot so parallel US waves do not mutate scripts/_lib.
#>

$script:CopilotPathConstant = @{
    CoreDirectoryName                 = 'core'
    SkillsDirectoryName               = 'skills'
    PolicyDirectoryName               = 'policy'
    RouterDirectoryName               = 'router'
    InstructionsDirectoryName         = 'instructions'
    HooksDirectoryName                = 'hooks'
    AssetsDirectoryName               = 'assets'
    SddDirectoryName                  = 'sdd'
    PolicySourceExtension             = '.md'
    InstructionsFileExtension         = '.instructions.md'
    CopilotInstructionsFileName       = 'copilot-instructions.md'
    CustomAgentsDirectoryName         = 'agents'
    RouterSourceFileName              = 'AGENTS.md'
    GuardrailsBaseName                = 'guardrails'
    GuardrailsFileName                = 'guardrails.instructions.md'
    SkillManifestFileName             = 'SKILL.md'
    SharedSkillsDirectoryName         = '_shared'
    ModeUser                          = 'user'
    ModeRepo                          = 'repo'
    CursorRuleExtension               = '.mdc'
    CursorRulesDirectoryName          = 'rules'
    AlwaysApplyFrontmatterToken       = 'alwaysApply: true'
    ApplyToAllFrontmatterToken        = 'applyTo: "**"'
    PlaceholderToolkitRoot            = '{{TOOLKIT_ROOT}}'
    PlaceholderSddRoot                = '{{SDD_ROOT}}'
    PlaceholderGuardrailsPath         = '{{GUARDRAILS_PATH}}'
    TextFileExtensionPattern          = '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    PathSeparatorForwardSlash         = '/'
    SmokeFilesystemOnlyNote           = 'Smoke validates filesystem presence only; Copilot IDE extension / login is out of scope.'
    SmokeExpectedSkillFolders         = @('commit', 'sdd-develop')
    SmokeExpectedSharedSkillsFolder   = '_shared'
    SmokeExpectedInstructionBases     = @('guardrails', 'ai-stealth', 'sdd-pipeline-guards', 'orchestrator-session')
    SmokeExpectedHookFileNames        = @('hooks.json', 'guard-pre-tool.ps1', '_hook-common.ps1', 'GuardCommon.ps1')
    SharedGuardCommonRelativePath     = 'adapters\_shared\GuardCommon.ps1'
    SharedGuardCommonFileName         = 'GuardCommon.ps1'
    ExcludedJetBrainsPathToken        = 'JetBrains'
    ExcludedEclipsePathToken          = 'Eclipse'
    GitKeepFileName                   = '.gitkeep'
}

$script:CopilotPublishMessage = @{
    CoreSkillsMissing        = 'Copilot Publish-Skills: core skills source is missing: {0}'
    PublishedOk              = 'Copilot Publish-Skills: published {0} file(s) from core/skills to {1} (Mode={2})'
    WhatIfOk                 = 'Copilot Publish-Skills: WhatIf - would publish core/skills to {0} (Mode={1})'
    CorePolicyMissing        = 'Copilot Publish-Policy: core policy source is missing: {0}'
    CoreRouterMissing        = 'Copilot Publish-Policy: core router source is missing: {0}'
    PolicyPublishedOk        = 'Copilot Publish-Policy: published {0} instruction file(s) from core policy/router to {1} (Mode={2}; smoke is filesystem-only - Copilot extension not required)'
    PolicyWhatIfOk           = 'Copilot Publish-Policy: WhatIf - would publish instructions under {0} (Mode={1})'
    HooksAssetsMissing       = 'Copilot Publish-Hooks: hook assets are missing: {0}'
    HooksPublishedOk         = 'Copilot Publish-Hooks: published {0} file(s) from adapter assets/hooks to {1} (Mode={2}; smoke is filesystem-only - Copilot extension not required)'
    HooksWhatIfOk            = 'Copilot Publish-Hooks: WhatIf - would publish hook files to {0} (Mode={1})'
    HooksNoOpNotCapable      = 'Copilot Publish-Hooks: hooks capability is false - no-op (no hook files written).'
    RouterNoOp               = 'Copilot has no dedicated router surface (router=false); Publish-Router is a documented no-op. Router guidance is folded into copilot-instructions.md via Publish-Policy.'
    CoreAgentsMissing        = 'Copilot Publish-Agents: core agents source is missing: {0}'
    AgentsPublishedOk        = 'Copilot Publish-Agents: published {0} custom subagent file(s) from core/agents to {1} (Mode={2})'
    AgentsWhatIfOk           = 'Copilot Publish-Agents: WhatIf - would publish {0} custom subagent file(s) to {1} (Mode={2})'
    AgentsUserModeNoOp       = 'Copilot Mode user has no documented agents directory; Publish-Agents is a no-op. Mode repo publishes InstallRoot/agents/ (.github/agents/).'
    InstallRootRequired      = 'InstallRoot is required.'
    ModeRequired             = 'Mode is required for Copilot publish. Use -Mode user or -Mode repo.'
    ModeInvalid              = 'Invalid Mode "{0}". Use -Mode user or -Mode repo.'
    PlaceholderUnresolved    = 'Copilot publish: unresolved placeholder {0} remains under {1}'
}

$script:CopilotSmokeMessage = @{
    ModeRequired             = 'TE02: Agent copilot requires -Mode user|repo for Invoke-SmokeValidate. Example: Invoke-SmokeValidate -InstallRoot <fixture> -Mode user'
    ModeInvalid              = 'TE02: Invalid Mode "{0}" for agent copilot. Valid modes: user, repo. Example: -Mode user'
    ArtifactMissing          = 'TE03: Agent copilot Mode={0}: expected artifact missing: {1}'
    CustomAgentsMissing      = 'TE03: Agent copilot Mode=repo: custom subagent file missing: {0}'
    HooksMissing             = 'TE04: Agent copilot Mode={0}: hooks capable but expected hook file missing: {1}'
    HooksJsonInvalid         = 'TE04: Agent copilot Mode={0}: hooks.json is missing or not valid JSON: {1}'
    SkillManifestEmpty       = 'TE03: Agent copilot Mode={0}: SKILL.md is empty: {1}'
    ExcludedIdePathFound     = 'CA7: Agent copilot Mode={0}: excluded IDE path token "{1}" found under InstallRoot: {2}'
    Passed                   = 'Copilot Invoke-SmokeValidate PASS (Mode={0}; filesystem-only; InstallRoot={1})'
    InstallRootRequired      = 'InstallRoot is required.'
}

$script:CopilotUninstallMessage = @{
    ModeRequired          = 'Mode is required for Copilot Uninstall-Toolkit. Use -Mode user or -Mode repo.'
    ModeInvalid           = 'Invalid Mode "{0}". Use -Mode user or -Mode repo.'
    InstallRootRequired   = 'InstallRoot is required.'
    CoreSkillsMissing     = 'Copilot Uninstall-Toolkit: core skills source is missing: {0}'
    CorePolicyMissing     = 'Copilot Uninstall-Toolkit: core policy source is missing: {0}'
    HooksAssetsMissing    = 'Copilot Uninstall-Toolkit: hook assets are missing: {0}'
    RemovedOk             = 'Copilot Uninstall-Toolkit: removed {0} managed path(s) under {1} (Mode={2}; keyed - alien files kept)'
    WhatIfOk              = 'Copilot Uninstall-Toolkit: WhatIf - would remove {0} managed path(s) under {1} (Mode={2})'
}
