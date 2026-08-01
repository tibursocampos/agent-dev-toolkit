#Requires -Version 5.1
<#
.SYNOPSIS
  Path and placeholder constants for the Claude Code adapter.

.DESCRIPTION
  Kept inside adapters/claude so parallel US waves do not mutate scripts/_lib.
#>

$script:ClaudePathConstant = @{
    CoreDirectoryName              = 'core'
    SkillsDirectoryName            = 'skills'
    PolicyDirectoryName            = 'policy'
    RouterDirectoryName            = 'router'
    RulesDirectoryName             = 'rules'
    HooksDirectoryName             = 'hooks'
    AssetsDirectoryName            = 'assets'
    SddDirectoryName               = 'sdd'
    GuardrailsFileName             = 'guardrails.md'
    SkillManifestFileName          = 'SKILL.md'
    SharedSkillsDirectoryName      = '_shared'
    RouterSourceFileName           = 'AGENTS.md'
    ClaudeMdFileName               = 'CLAUDE.md'
    SettingsFileName               = 'settings.json'
    SettingsBackupSuffix           = '.bak'
    SettingsBackupTimestampFormat  = 'yyyyMMddHHmmss'
    SettingsTimestampedBackupPathFormat = '{0}{1}.{2}'
    CursorRuleExtension            = '.mdc'
    MarkdownExtension              = '.md'
    PlaceholderToolkitRoot         = '{{TOOLKIT_ROOT}}'
    PlaceholderSddRoot             = '{{SDD_ROOT}}'
    PlaceholderGuardrailsPath      = '{{GUARDRAILS_PATH}}'
    TextFileExtensionPattern       = '\.(md|mdc|json|ps1|yml|yaml|txt)$'
    PathSeparatorForwardSlash      = '/'
    FixtureRelativePath            = 'scripts/validation/fixtures/claude'
    SmokeTe01Code                  = 'TE01'
    SmokeTe05Code                  = 'TE05'
}

$script:ClaudeSettingsJsonConstant = @{
    HooksPropertyName              = 'hooks'
    PermissionsPropertyName        = 'permissions'
    AllowPropertyName              = 'allow'
    HookHandlerTypePropertyName    = 'type'
    HookHandlerCommandPropertyName = 'command'
    HookHandlersPropertyName       = 'hooks'
    HookMatcherPropertyName        = 'matcher'
    HookCommandTypeValue           = 'command'
    HookCommandTemplate            = 'pwsh -NoProfile -File "{0}"'
    PermissionsAllowBashFormat     = 'Bash({0})'
    JsonConvertDepth               = 30
    HookEventUserPromptSubmit      = 'UserPromptSubmit'
    HookEventPreCompact            = 'PreCompact'
    HookEventPostToolUse           = 'PostToolUse'
    HookScriptUserPromptSubmit     = 'context-before-prompt.ps1'
    HookScriptPreCompact           = 'context-pre-compact.ps1'
    HookScriptPostToolUse          = 'plan-after-edit.ps1'
    HookMatcherPostToolUse         = 'Write|Edit'
}

# Legacy broad allow entries (uninstall + re-sync strip only; never re-added by default).
$script:ClaudeLegacyBroadPermissionsAllow = @(
    'Bash(pwsh *)',
    'Bash(powershell *)'
)

$script:ClaudePublishMessage = @{
    CoreSkillsMissing       = 'Claude Publish-Skills: core skills source is missing: {0}'
    PublishedOk             = 'Claude Publish-Skills: published {0} file(s) from core/skills to {1}'
    WhatIfOk                = 'Claude Publish-Skills: WhatIf - would publish core/skills to {0}'
    CorePolicyMissing       = 'Claude Publish-Policy: core policy source is missing: {0}'
    PolicyPublishedOk       = 'Claude Publish-Policy: published {0} file(s) from core/policy to {1}'
    PolicyWhatIfOk          = 'Claude Publish-Policy: WhatIf - would publish core/policy to {0}'
    CoreRouterMissing       = 'Claude Publish-Router: core router source is missing: {0}'
    RouterPublishedOk       = 'Claude Publish-Router: wrote CLAUDE.md from core/router to {0}'
    RouterWhatIfOk          = 'Claude Publish-Router: WhatIf - would write CLAUDE.md to {0}'
    HooksAssetsMissing      = 'Claude Publish-Hooks: hook script assets are missing: {0}'
    HooksPublishedOk        = 'Claude Publish-Hooks: published {0} file(s) from adapter assets/hooks to {1}'
    HooksWhatIfOk           = 'Claude Publish-Hooks: WhatIf - would publish hook scripts to {0}'
    SettingsMergedOk        = 'Claude settings merge: wrote {0} (backup={1})'
    SettingsWhatIfOk        = 'Claude settings merge: WhatIf - would merge settings at {0}'
    SettingsInvalidJson     = 'Claude settings merge: invalid JSON at {0}: {1}. Fix manually; file was not overwritten.'
    SettingsHooksNotObject       = 'Claude settings merge: hooks must be a JSON object; non-object hooks were left unchanged. Fix manually; file was not overwritten.'
    SettingsPermissionsNotObject = 'Claude settings merge: permissions must be a JSON object; non-object permissions were left unchanged. Fix manually; file was not overwritten.'
    SettingsBackupFailed         = 'Claude settings merge: backup failed for {0} -> {1}: {2}. settings.json was not modified.'
    SettingsWriteFailed     = 'Claude settings merge: write failed for {0}: {1}'
    InstallRootRequired     = 'InstallRoot is required.'
    PlaceholderUnresolved   = 'Claude publish: unresolved placeholder {0} remains under {1}'
}

$script:ClaudeUninstallMessage = @{
    InstallRootRequired      = 'InstallRoot is required.'
    RemovedOk                = 'Claude Uninstall-Toolkit: removed {0} managed path(s) under {1} (keyed only; alien files and unrelated settings keys preserved)'
    WhatIfOk                 = 'Claude Uninstall-Toolkit: WhatIf - would remove {0} managed path(s) under {1} (keyed only)'
    SettingsCleanedOk        = 'settings reverse-merge wrote {0} (managed hook handlers + allow entries removed; alien keys and co-located handlers kept)'
    SettingsWhatIfOk         = 'settings reverse-merge WhatIf - would clean managed entries at {0}'
    SettingsAbsentOk         = 'settings.json absent; nothing to reverse-merge'
    SettingsNoManagedEntries = 'settings.json had no managed toolkit entries to remove'
}
