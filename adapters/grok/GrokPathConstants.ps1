#Requires -Version 5.1
<#
.SYNOPSIS
  Path, layout, and message constants for the Grok Build adapter.

.DESCRIPTION
  Kept inside adapters/grok so parallel US waves do not mutate scripts/_lib.
  Script-scoped hashtables are required by Publish-*/Smoke/Uninstall siblings.
#>

$script:GrokAdapterConstant = @{
    OfficialUserRootRelativePath     = '.grok'
    OfficialUserRootDescription      = 'Official Grok Build user root is under the user home as .grok (equivalent to ~/.grok).'
    OfficialProjectRootRelativePath  = '.grok'
    OfficialProjectRootDescription   = 'Official Grok Build project scope uses .grok under the repository/InstallRoot (skills, rules, hooks).'
    OfficialSkillsRelativePath       = '.grok/skills'
    OfficialSkillsDescription        = 'Grok skills publish under .grok/skills/<kebab-id>/SKILL.md relative to InstallRoot (and user ~/.grok/skills when mirrored).'
    OfficialRulesRelativePath        = '.grok/rules'
    OfficialRulesDescription         = 'Grok project rules publish under .grok/rules/*.md.'
    OfficialHooksRelativePath        = '.grok/hooks'
    OfficialHooksDescription         = 'Grok hooks publish as JSON under .grok/hooks/. Trust via /hooks-trust is a human operational step.'
    OfficialAgentsFileName           = 'AGENTS.md'
    OfficialAgentsDescription        = 'Grok router / project-rules surface includes AGENTS.md at the project/InstallRoot scope.'
    FixtureRelativePath              = 'scripts/validation/fixtures/grok'
    InstallRootOverrideParameter     = 'InstallRoot'
    InstallRootOverrideDescription   = 'Pass -InstallRoot to target an in-repo fixture or an explicit path. Paths under USERPROFILE require -AllowUserHome.'
    HooksTrustNote                   = 'Hooks trust via Grok /hooks-trust or --trust is a human operational step; smoke validates files only.'
    ResolveInstallRootRelativePath   = 'scripts/_lib/Resolve-InstallRoot.ps1'
    CoreDirectoryName                = 'core'
    SkillsDirectoryName              = 'skills'
    PolicyDirectoryName              = 'policy'
    RouterDirectoryName              = 'router'
    RouterSourceFileName             = 'AGENTS.md'
    SddDirectoryName                 = 'sdd'
    GuardrailsFileName               = 'guardrails.md'
    SkillManifestFileName            = 'SKILL.md'
    CursorRuleExtension              = '.mdc'
    MarkdownExtension                = '.md'
    PlaceholderToolkitRoot           = '{{TOOLKIT_ROOT}}'
    PlaceholderSddRoot               = '{{SDD_ROOT}}'
    PlaceholderGuardrailsPath        = '{{GUARDRAILS_PATH}}'
    TextFileExtensionPattern         = '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    PathSeparatorForwardSlash        = '/'
    HooksJsonFileName                = 'toolkit-session-start.json'
    HooksSessionStartScriptName      = 'session_start.ps1'
    HooksSessionStartEventName       = 'SessionStart'
    HooksCommandType                 = 'command'
    HooksSessionStartCommandTemplate = 'powershell -NoProfile -File .grok/hooks/session_start.ps1'
    HooksSessionStartStatusMessage   = 'Grok toolkit SessionStart hook (filesystem publish; trust is manual)'
    HooksDescription                 = 'agent-dev-toolkit minimal native Grok hooks (docs.x.ai/build/features/hooks). Trust via /hooks-trust or --trust is manual; smoke never writes trusted_folders.toml.'
    TrustedFoldersFileName           = 'trusted_folders.toml'
    CompatClaudeRootRelativePath     = '.claude'
    CompatCursorRootRelativePath     = '.cursor'
    CompatSkillsDirectoryName        = 'skills'
    CompatRulesDirectoryName         = 'rules'
    SmokeExitCodeSuccess             = 0
    SmokeExitCodeFailure             = 1
    ConfigTomlFileName               = 'config.toml'
    GitKeepFileName                  = '.gitkeep'
    JsonConvertDepthDeep             = 8
}

$script:GrokAdapterMessage = @{
    NotImplemented            = '{0} is not implemented yet for the Grok adapter. Publish/smoke land in later adapter PLAN steps; stubs must not mutate InstallRoot.'
    AgentIdRequired           = 'AgentId is required.'
    InstallRootRequired       = 'InstallRoot is required.'
    CapabilitiesReady         = 'Grok adapter capabilities reported (skills/rules/hooks/router via native .grok). Publish-Skills/Policy/Router/Hooks and Invoke-SmokeValidate ready; Uninstall-Toolkit removes keyed toolkit artifacts only (no wipe of .grok / config.toml). Hooks trust UI /hooks-trust out of smoke scope.'
    ResolveInstallRootMissing = 'Resolve-InstallRoot helper not found at: {0}'
    CoreSkillsMissing         = 'Grok Publish-Skills: core skills source is missing: {0}'
    PublishedOk               = 'Grok Publish-Skills: published {0} file(s) from core/skills to {1}'
    WhatIfOk                  = 'Grok Publish-Skills: WhatIf - would publish core/skills to {0}'
    CorePolicyMissing         = 'Grok Publish-Policy: core policy source is missing: {0}'
    PolicyPublishedOk         = 'Grok Publish-Policy: published {0} file(s) from core/policy to {1}'
    PolicyWhatIfOk            = 'Grok Publish-Policy: WhatIf - would publish core/policy to {0}'
    CoreRouterMissing         = 'Grok Publish-Router: core router source is missing: {0}'
    RouterPublishedOk         = 'Grok Publish-Router: wrote AGENTS.md from core/router to {0}'
    RouterWhatIfOk            = 'Grok Publish-Router: WhatIf - would write AGENTS.md to {0}'
    PlaceholderUnresolved     = 'Grok publish: unresolved placeholder {0} remains under {1}'
    HooksPublishedOk          = 'Grok Publish-Hooks: published native JSON under {0} (filesystem only; trust /hooks-trust or --trust is manual)'
    HooksWhatIfOk             = 'Grok Publish-Hooks: WhatIf - would publish native hooks under {0}'
    HooksSkippedNotCapable    = 'Grok Publish-Hooks: skipped - hooks capability is false; no hooks files written under {0}'
    SmokePassed               = 'Grok Invoke-SmokeValidate: PASS under {0} (native .grok filesystem checks only; hooks trust /hooks-trust or --trust is manual - TE05 files only).'
    SmokeTe02SkillsMissing    = 'Grok Invoke-SmokeValidate TE02: expected native skills under {0} (at least one SKILL.md); path missing or empty after publish.'
    SmokeTe03RulesMissing     = 'Grok Invoke-SmokeValidate TE03: rules capability is true but no .md rules found under {0}.'
    SmokeTe03HooksMissing     = 'Grok Invoke-SmokeValidate TE03: hooks capability is true but native hooks JSON missing under {0} (expected {1}).'
    SmokeTe03RouterMissing    = 'Grok Invoke-SmokeValidate TE03: router capability is true but AGENTS.md missing at {0}.'
    SmokeTe04CompatOnly       = 'Grok Invoke-SmokeValidate TE04: Claude/Cursor compat paths present without native .grok artifacts under InstallRoot {0}. Native write to .grok is required (RN02).'
    SmokeTe05FilesOnlyNote    = 'Smoke validates hooks files only; do not expect /hooks-trust or --trust to be granted by CI.'
    UninstallOk               = 'Grok Uninstall-Toolkit: removed {0} toolkit artifact(s) under {1} (keyed only; config.toml and alien files preserved).'
    UninstallWhatIfOk         = 'Grok Uninstall-Toolkit: WhatIf - would remove {0} toolkit artifact(s) under {1} (keyed only; no wipe of .grok / config.toml).'
    UninstallNothingFound     = 'Grok Uninstall-Toolkit: no known toolkit artifacts found under {0} (keyed scan; nothing removed).'
}

