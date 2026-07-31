#Requires -Version 5.1
<#
.SYNOPSIS
  Path, layout, and message constants for the Cursor adapter.

.DESCRIPTION
  Kept inside adapters/cursor so parallel US waves do not mutate scripts/_lib.
  Script-scoped hashtables are required by Publish-*/Smoke/Uninstall siblings.
#>

$script:CursorAdapterConstant = @{
    OfficialUserRootRelativePath   = '.cursor'
    OfficialUserRootDescription    = 'Official Cursor user install root is under the user home as .cursor (equivalent to ~/.cursor).'
    InstallRootOverrideParameter   = 'InstallRoot'
    InstallRootOverrideDescription = 'Pass -InstallRoot to target an in-repo fixture or an explicit path. Paths under USERPROFILE require -AllowUserHome.'
    SddDirectoryName               = 'sdd'
    CoreDirectoryName              = 'core'
    SkillsDirectoryName            = 'skills'
    PolicyDirectoryName            = 'policy'
    RulesDirectoryName             = 'rules'
    PolicySourceExtension          = '.md'
    PolicyDestExtension            = '.mdc'
    RouterDirectoryName            = 'router'
    AgentsMarkdownFileName         = 'AGENTS.md'
    HooksDirectoryName             = 'hooks'
    HooksJsonFileName              = 'hooks.json'
    HooksAssetsRelativePath        = 'assets\hooks'
    HooksJsonVersionDefault        = 1
    CursorFixtureInstallRootRel    = 'scripts/validation/fixtures/cursor-install-root'
    FixtureRelativePath            = 'scripts/validation/fixtures/cursor-install-root'
    SkillMarkdownFileName          = 'SKILL.md'
    SessionsDirectoryName          = 'sessions'
    ManifestFileName               = 'manifest.json'
    ManifestSchemaVersion          = 2
    GuardrailsFileName             = 'guardrails.mdc'
    PlaceholderToolkitRoot         = '{{TOOLKIT_ROOT}}'
    PlaceholderSddRoot             = '{{SDD_ROOT}}'
    PlaceholderGuardrailsPath      = '{{GUARDRAILS_PATH}}'
    TextFileExtensionPattern       = '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    PathSeparatorForwardSlash      = '/'
    SmokeTe01Code                  = 'TE01'
    SmokeTe04Code                  = 'TE04'
    ManagedHookScriptNames         = @(
        '_hook-common.ps1',
        'context-before-prompt.ps1',
        'context-pre-compact.ps1',
        'plan-after-edit.ps1'
    )
    AtomicWriteTempSuffix          = '.tmp'
    AtomicWriteMaxAttempts         = 3
    AtomicWriteRetryDelayMilliseconds = 50
}

$script:CursorAdapterMessage = @{
    NotImplemented       = '{0} is not implemented yet for the Cursor adapter. Publish/smoke land in later adapter PLAN steps; stubs must not mutate InstallRoot.'
    AgentIdRequired      = 'AgentId is required.'
    InstallRootRequired  = 'InstallRoot is required.'
    CapabilitiesReady       = 'Cursor adapter capabilities reported (skills/rules/hooks/router/sdd). Publish + Invoke-SmokeValidate ready (filesystem-only; hooks trust UI out of scope).'
    CoreSkillsMissing       = 'Core skills source is missing: {0}'
    SkillsPublished         = 'Published {0} skill folder(s) from core/skills to {1}.'
    SkillsWouldPublish      = 'WhatIf: would publish {0} skill folder(s) from core/skills to {1}.'
    CorePolicyMissing       = 'Core policy source is missing: {0}'
    PolicyPublished         = 'Published {0} rule file(s) from core/policy to {1} as .mdc.'
    PolicyWouldPublish      = 'WhatIf: would publish {0} rule file(s) from core/policy to {1} as .mdc.'
    CoreRouterMissing       = 'Core router source is missing: {0}'
    RouterPublished         = 'Published router AGENTS.md from {0} to {1}.'
    RouterWouldPublish      = 'WhatIf: would publish router AGENTS.md from {0} to {1}.'
    HooksSourceMissing      = 'Cursor hooks source is missing: {0}'
    HooksJsonInvalid        = 'Invalid hooks.json at {0}: {1}'
    HooksPublished          = 'Published {0} hook script(s) to {1}; merged hooks.json at {2}.'
    HooksWouldPublish       = 'WhatIf: would publish {0} hook script(s) to {1} and merge hooks.json at {2}.'
    SddRootResolved         = 'Cursor SDD root resolved at {0}.'
    SddRootPrepared         = 'Prepared Cursor SDD root at {0} (sessions={1}; manifestCreated={2}).'
    SddRootWouldPrepare     = 'WhatIf: would prepare Cursor SDD root at {0} (sessions + seed manifest.json if missing).'
    PlaceholderUnresolved   = 'Cursor publish: unresolved placeholder {0} remains under {1}'
    SmokePassed             = 'Cursor Invoke-SmokeValidate PASS under {0} (filesystem checks only; hooks trust UI out of scope - TE04 files only).'
    SmokeTe01InvalidRoot    = 'Cursor Invoke-SmokeValidate TE01: InstallRoot rejected ({0}). Use an in-repo fixture or pass -AllowUserHome for USERPROFILE paths.'
    SmokeTe04Missing        = 'Cursor Invoke-SmokeValidate TE04: required artifact(s) missing or incomplete under InstallRoot: {0}'
    SmokeFilesystemOnlyNote = 'Smoke validates published files only; do not expect Cursor IDE hooks trust UI to be granted by CI.'
    AtomicWriteFailed       = 'Failed to write {0} after {1} attempt(s): {2}'
}

