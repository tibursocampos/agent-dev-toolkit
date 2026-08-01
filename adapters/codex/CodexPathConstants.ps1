#Requires -Version 5.1
<#
.SYNOPSIS
  Path and plugin-manifest constants for the Codex adapter.

.DESCRIPTION
  Kept inside adapters/codex so parallel US waves do not mutate scripts/_lib.
#>

$script:CodexPathConstant = @{
    CoreDirectoryName              = 'core'
    SkillsDirectoryName            = 'skills'
    PluginRootDirectoryName        = 'plugin'
    PluginManifestDirectoryName    = '.codex-plugin'
    PluginManifestFileName         = 'plugin.json'
    SkillManifestFileName          = 'SKILL.md'
    SharedSkillsDirectoryName      = '_shared'
    SddDirectoryName               = 'sdd'
    RulesDirectoryName             = 'rules'
    GuardrailsFileName             = 'guardrails.md'
    AgentsDirectoryName            = '.agents'
    PluginsDirectoryName           = 'plugins'
    MarketplaceFileName            = 'marketplace.json'
    PlaceholderToolkitRoot         = '{{TOOLKIT_ROOT}}'
    PlaceholderSddRoot             = '{{SDD_ROOT}}'
    PlaceholderGuardrailsPath      = '{{GUARDRAILS_PATH}}'
    TextFileExtensionPattern       = '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    PathSeparatorForwardSlash      = '/'
    PluginSkillsManifestRelative   = './skills/'
    PluginMarketplaceSourcePath    = './plugin'
    PluginMarketplaceSourceKind    = 'local'
    PluginName                     = 'agent-dev-toolkit'
    PluginVersion                  = '0.1.0'
    PluginDescription              = 'Agent Dev Toolkit skills packaged as a Codex plugin for fixture and CI smoke.'
    PluginDisplayName              = 'Agent Dev Toolkit'
    MarketplaceName                = 'agent-dev-toolkit-local'
    MarketplaceDisplayName         = 'Agent Dev Toolkit (fixture)'
    MarketplacePluginCategory      = 'Productivity'
    MarketplacePolicyInstallation  = 'AVAILABLE'
    MarketplacePolicyAuthentication = 'ON_INSTALL'
    RouterDirectoryName            = 'router'
    AgentsFileName                 = 'AGENTS.md'
    HooksDirectoryName             = 'hooks'
    HooksFileName                  = 'hooks.json'
    HooksSessionStartScriptName    = 'session_start.ps1'
    HooksDefaultRelativePath       = './hooks/hooks.json'
    HooksSessionStartEventName     = 'SessionStart'
    HooksCommandType               = 'command'
    HooksSessionStartStatusMessage = 'Loading Agent Dev Toolkit Codex plugin context'
    HooksSessionStartCommandTemplate = 'pwsh -NoProfile -File "${PLUGIN_ROOT}/hooks/session_start.ps1"'
    HooksDescription               = 'Minimal Codex plugin lifecycle hooks for agent-dev-toolkit (files only; trust via /hooks is manual).'
    HooksTrustComment              = 'RN03: smoke asserts hooks files only - never invoke or require Codex /hooks trust UI.'
    UserScopeParameterName         = 'UserScope'
    UserSkillsRelativePath         = '.agents/skills'
    UserScopeDescription           = 'Optional -UserScope mirrors core/skills under InstallRoot/.agents/skills (fixture stand-in for ~/.agents/skills). Default publish is plugin-bundled only; never writes real $HOME/.agents/skills without -AllowUserHome + InstallRoot under USERPROFILE.'
    SmokeTe01Code                  = 'TE01'
    SmokeTe02Code                  = 'TE02'
    SmokeTe03Code                  = 'TE03'
    SmokeTe04Code                  = 'TE04'
    SmokeExitSuccess               = 0
    SmokeExitFailure               = 1
    JsonConvertDepthShallow        = 5
    JsonConvertDepthDeep           = 8
}

$script:CodexSmokeMessage = @{
    Te01InvalidInstallRoot     = 'TE01: Codex agent ''codex'' smoke aborted - InstallRoot invalid or under USERPROFILE without -AllowUserHome. Detail: {0}'
    Te02PluginManifestMissing  = 'TE02: Codex agent ''codex'' smoke failed - plugin.json missing at: {0}'
    Te02PluginManifestInvalid  = 'TE02: Codex agent ''codex'' smoke failed - plugin.json is not valid JSON or missing required fields (name, version, description, skills, interface.displayName) at: {0}'
    Te02PluginSkillsMissing    = 'TE02: Codex agent ''codex'' smoke failed - plugin skills incomplete. Expected at least one skills/<kebab-id>/SKILL.md under: {0}'
    Te03MarketplaceMissing     = 'TE03: Codex agent ''codex'' smoke failed - marketplace catalog missing at: {0}'
    Te03MarketplaceInvalid     = 'TE03: Codex agent ''codex'' smoke failed - marketplace.json invalid or has no plugins[] at: {0}'
    Te03MarketplaceEntryBroken = 'TE03: Codex agent ''codex'' smoke failed - marketplace entry ''{0}'' source.path broken (missing, not ./relative, or does not resolve). Expected path under InstallRoot; catalog: {1}; detail: {2}'
    Te04HooksMissing           = 'TE04: Codex agent ''codex'' smoke failed - hooks capable but hooks file missing at: {0} (filesystem only; trust /hooks UI is out of scope)'
    Te04HooksInvalid           = 'TE04: Codex agent ''codex'' smoke failed - hooks.json missing or not valid JSON at: {0}'
    AgentsMdMissing            = 'Codex agent ''codex'' smoke failed - AGENTS.md missing or empty at: {0}'
    UserSkillsRootMissing      = 'Codex agent ''codex'' smoke failed - USER skills fixture path missing (expected .agents/skills under InstallRoot): {0}'
    UserSkillsIncomplete       = 'Codex agent ''codex'' smoke failed - USER skills fixture has skill folder without SKILL.md: {0}'
    Passed                     = 'Codex Invoke-SmokeValidate PASS under {0} (filesystem-only; plugin + marketplace + AGENTS.md + hooks files; trust /hooks UI out of scope - RN03).'
    FilesystemOnlyNote         = 'Smoke never invokes Codex runtime or /hooks trust UI.'
}

$script:CodexPublishMessage = @{
    CoreSkillsMissing       = 'Codex Publish-Skills: core skills source is missing: {0}'
    PublishedOk             = 'Codex Publish-Skills: published plugin manifest, marketplace entry, and {0} file(s) from core/skills to {1}'
    PublishedOkWithUserScope = 'Codex Publish-Skills: published plugin + marketplace ({0} file(s) under plugin/skills) and USER-scope mirror ({1} file(s) under {2})'
    WhatIfOk                = 'Codex Publish-Skills: WhatIf - would publish plugin + marketplace + core/skills under {0}'
    WhatIfOkWithUserScope   = 'Codex Publish-Skills: WhatIf - would publish plugin + marketplace under {0} and USER-scope mirror under {1}'
    InstallRootRequired     = 'InstallRoot is required.'
    PlaceholderUnresolved   = 'Codex Publish-Skills: unresolved placeholder {0} remains under {1}'
    ManifestExtraFiles      = 'Codex Publish-Skills: .codex-plugin must contain only plugin.json; unexpected: {0}'
    MarketplaceSourceInvalid = 'Codex Publish-Skills: marketplace source.path must be ./prefixed relative path; got: {0}'
    MarketplacePluginMissing = 'Codex Publish-Skills: marketplace source.path does not resolve to an existing plugin root: {0}'
    CoreRouterMissing       = 'Codex Publish-Router: core router source is missing: {0}'
    RouterPublishedOk       = 'Codex Publish-Router: published AGENTS.md from core/router to {0}'
    RouterWhatIfOk          = 'Codex Publish-Router: WhatIf - would publish AGENTS.md under {0}'
    HooksPublishedOk        = 'Codex Publish-Hooks: published hooks/hooks.json under {0} (filesystem only; trust /hooks is manual)'
    HooksWhatIfOk           = 'Codex Publish-Hooks: WhatIf - would publish hooks under {0}'
    HooksSkippedNotCapable  = 'Codex Publish-Hooks: skipped - hooks capability is false; no hooks files written under {0}'
    PolicyNoOpOk            = 'Codex Publish-Policy: no-op - rules capability is false; Codex has no policy/rules publish surface in this MVP.'
}

$script:CodexUninstallMessage = @{
    InstallRootRequired = 'InstallRoot is required.'
    RemovedOk           = 'Codex Uninstall-Toolkit: removed {0} keyed toolkit path(s) under {1} (RN07: no wholesale wipe of Codex config / alien files).'
    WhatIfOk            = 'Codex Uninstall-Toolkit: WhatIf - would remove {0} keyed toolkit path(s) under {1} (RN07: no wholesale wipe).'
    NothingFound        = 'Codex Uninstall-Toolkit: no known toolkit artifacts found under {0} (keyed scan; nothing removed).'
}
