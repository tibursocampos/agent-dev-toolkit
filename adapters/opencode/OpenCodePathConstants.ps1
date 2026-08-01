#Requires -Version 5.1
<#
.SYNOPSIS
  Path and placeholder constants for the OpenCode adapter.

.DESCRIPTION
  Kept inside adapters/opencode so parallel US waves do not mutate scripts/_lib.
#>

$script:OpenCodePathConstant = @{
    CoreDirectoryName         = 'core'
    SkillsDirectoryName       = 'skills'
    RouterDirectoryName       = 'router'
    AgentsFileName            = 'AGENTS.md'
    RulesDirectoryName        = 'rules'
    SddDirectoryName          = 'sdd'
    GuardrailsFileName        = 'guardrails.md'
    SkillManifestFileName     = 'SKILL.md'
    SharedSkillsDirectoryName = '_shared'
    AssetsDirectoryName       = 'assets'
    PluginsDirectoryName      = 'plugins'
    PluginMarkerFileName      = 'agent-dev-toolkit-marker.js'
    FixtureInstallRootRel     = 'scripts/validation/fixtures/opencode'
    PlaceholderToolkitRoot    = '{{TOOLKIT_ROOT}}'
    PlaceholderSddRoot        = '{{SDD_ROOT}}'
    PlaceholderGuardrailsPath = '{{GUARDRAILS_PATH}}'
    TextFileExtensionPattern  = '\.(md|mdc|json|ps1|yml|yaml|txt|js)$'
    PathSeparatorForwardSlash = '/'
    MvpHooksDecisionA         = 'A'
    MvpHooksDecisionLabel     = 'plugin-js-publish'
    SmokeFilesystemOnlyNote   = 'Smoke validates filesystem plugin presence only - OpenCode runtime is not required (RN03).'
    SmokeTe01Code             = 'TE01'
    SmokeTe02Code             = 'TE02'
    SmokeTe03Code             = 'TE03'
}

$script:OpenCodePublishMessage = @{
    CoreSkillsMissing     = 'OpenCode Publish-Skills: core skills source is missing: {0}'
    PublishedOk           = 'OpenCode Publish-Skills: published {0} file(s) from core/skills to {1}'
    WhatIfOk              = 'OpenCode Publish-Skills: WhatIf - would publish core/skills to {0}'
    CoreRouterMissing     = 'OpenCode Publish-Router: core router source is missing: {0}'
    RouterPublishedOk     = 'OpenCode Publish-Router: published AGENTS.md to {0}'
    RouterWhatIfOk        = 'OpenCode Publish-Router: WhatIf - would publish AGENTS.md to {0}'
    PolicyNoOp            = 'OpenCode has no dedicated policy/rules surface; Publish-Policy is a documented no-op (rules=false). Router guidance is AGENTS.md via Publish-Router.'
    HooksAssetsMissing    = 'OpenCode Publish-Hooks: plugin assets are missing: {0}'
    HooksPublishedOk      = 'OpenCode Publish-Hooks: published {0} plugin file(s) to {1} (Decision A - JS plugin; no shell/PS1 hooks; RN03/RN04)'
    HooksWhatIfOk         = 'OpenCode Publish-Hooks: WhatIf - would publish JS plugin files to {0}'
    HooksNoOpNotCapable   = 'OpenCode Publish-Hooks: hooks capability is false - no-op (no plugin files written).'
    InstallRootRequired   = 'InstallRoot is required.'
    PlaceholderUnresolved = 'OpenCode publish: unresolved placeholder {0} remains under {1}'
}

$script:OpenCodeSmokeMessage = @{
    Passed                 = 'OpenCode smoke PASS (filesystem-only; no OpenCode runtime). skills + AGENTS.md + plugin marker ok under {0}'
    Te01InvalidInstallRoot = 'TE01: OpenCode InstallRoot is invalid or under USERPROFILE without -AllowUserHome. Use in-repo fixture scripts/validation/fixtures/opencode or pass -AllowUserHome. Detail: {0}'
    Te02SkillsMissing      = 'TE02: OpenCode agent ''opencode'' smoke failed - skills layout incomplete. Expected at least one skills/<kebab-id>/SKILL.md under: {0}'
    Te02AgentsMissing      = 'TE02: OpenCode agent ''opencode'' smoke failed - AGENTS.md missing or empty at: {0}'
    Te03PluginMismatch     = 'TE03: OpenCode hooks/plugin capable (Decision A) but plugin marker missing at: {0}. Capability vs artifacts mismatch (RN03: no shell/PS1 hooks required).'
    Te05SddLayoutMissing   = 'TE05: OpenCode smoke failed - SDD layout incomplete under InstallRoot. Missing: {0}'
    FilesystemOnlyNote     = 'OpenCode smoke is filesystem-only - does not invoke OpenCode runtime (TE04 out of scope).'
}

$script:OpenCodeUninstallMessage = @{
    InstallRootRequired = 'InstallRoot is required.'
    RemovedOk           = 'OpenCode Uninstall-Toolkit: removed {0} keyed toolkit path(s) under {1} (RN07: no wholesale wipe of OpenCode config).'
    WhatIfOk            = 'OpenCode Uninstall-Toolkit: WhatIf - would remove {0} keyed toolkit path(s) under {1} (RN07: no wholesale wipe).'
}
