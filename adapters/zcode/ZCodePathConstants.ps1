#Requires -Version 5.1
<#
.SYNOPSIS
  Path constants for the ZCode ADE adapter.

.DESCRIPTION
  Kept inside adapters/zcode so parallel US waves do not mutate scripts/_lib.
#>

$script:ZCodePathConstant = @{
    CoreDirectoryName         = 'core'
    SkillsDirectoryName       = 'skills'
    RouterDirectoryName       = 'router'
    AgentsFileName            = 'AGENTS.md'
    CursorRulesDirectoryName  = 'rules'
    CursorMdcExtension        = '.mdc'
    SddDirectoryName          = 'sdd'
    GuardrailsFileName        = 'guardrails.mdc'
    SkillManifestFileName     = 'SKILL.md'
    SharedSkillsDirectoryName = '_shared'
    FixtureInstallRootRel     = 'scripts/validation/fixtures/zcode-install-root'
    CliDirectoryName          = 'cli'
    CliConfigFileName         = 'config.json'
    HooksDirectoryName        = 'hooks'
    HooksJsonFileName         = 'hooks.json'
    ToolkitHooksMarker        = 'agent-dev-toolkit-zcode-hooks'
    ToolkitSessionStartMarker = 'agent-dev-toolkit-zcode-session-start'
    PlaceholderToolkitRoot    = '{{TOOLKIT_ROOT}}'
    PlaceholderSddRoot        = '{{SDD_ROOT}}'
    PlaceholderGuardrailsPath = '{{GUARDRAILS_PATH}}'
    TextFileExtensionPattern  = '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    PathSeparatorForwardSlash = '/'
}

$script:ZCodePublishMessage = @{
    CoreSkillsMissing     = 'ZCode Publish-Skills: core skills source is missing: {0}'
    PublishedOk           = 'ZCode Publish-Skills: published {0} file(s) from core/skills to {1}'
    WhatIfOk              = 'ZCode Publish-Skills: WhatIf - would publish core/skills to {0}'
    CoreRouterMissing     = 'ZCode Publish-Router: core router source is missing: {0}'
    RouterPublishedOk     = 'ZCode Publish-Router: published AGENTS.md to {0}'
    RouterWhatIfOk        = 'ZCode Publish-Router: WhatIf - would publish AGENTS.md to {0}'
    NoCursorMdcRules      = 'ZCode ADE does not publish Cursor-style rules/*.mdc; router surface is AGENTS.md only.'
    HooksSourceMissing    = 'ZCode Publish-Hooks: toolkit hooks/config source is missing: {0}'
    HooksJsonMissing      = 'ZCode Publish-Hooks: JSON file is missing: {0}'
    HooksJsonInvalid      = 'ZCode Publish-Hooks: invalid JSON at {0}: {1}'
    HooksPublishedOk      = 'ZCode Publish-Hooks: merged cli/config.json at {0} and hooks/hooks.json at {1}'
    HooksWhatIfOk         = 'ZCode Publish-Hooks: WhatIf - would merge hooks/config under {0}'
    SyncSkillsFailed      = 'ZCode publish sync failed during Publish-Skills.'
    SyncRouterFailed      = 'ZCode publish sync failed during Publish-Router.'
    SyncHooksFailed       = 'ZCode publish sync failed during Publish-Hooks.'
    SyncOk                = 'ZCode publish sync completed for InstallRoot {0} (skills + AGENTS.md + hooks/config; no rules/*.mdc).'
    InstallRootRequired   = 'InstallRoot is required.'
    PlaceholderUnresolved = 'ZCode publish: unresolved placeholder {0} remains under {1}'
    SmokePass             = 'ZCode smoke: layout OK under InstallRoot {0} (skills/*/SKILL.md, AGENTS.md, hooks/config).'
    SmokeFailGaps         = 'ZCode smoke: required layout incomplete under InstallRoot {0}. Missing: {1}'
    SmokeSkillsMissing    = 'skills/<id>/SKILL.md'
    SmokeAgentsMissing    = 'AGENTS.md'
    SmokeCliConfigMissing = 'cli/config.json'
    SmokeHooksJsonMissing = 'hooks/hooks.json'
    SmokeHooksEnabledOff  = 'cli/config.json (hooks.enabled must be true)'
    SmokeHooksSurfaceGap  = 'hooks surface (cli/config.json with hooks.enabled:true and/or hooks/hooks.json)'
    SmokeRelativeSep      = '; '
    PolicyNoOp            = 'ZCode ADE has no Cursor-style rules/*.mdc policy surface; Publish-Policy is a documented no-op (rules=false). Router guidance is AGENTS.md via Publish-Router.'
}
