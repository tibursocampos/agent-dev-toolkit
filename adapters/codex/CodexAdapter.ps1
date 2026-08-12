#Requires -Version 5.1
<#
.SYNOPSIS
  Codex adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `codex`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Policy /
  Publish-Router / Publish-Hooks / Get-SddRoot (-Prepare) are implemented
  (optional InstallRoot maps plugin/marketplace/home skills/USER skills/AGENTS.md/rules
  under the fixture; Publish-Skills writes plugin.json + plugin/skills + InstallRoot/skills
  ($ discovery) + marketplace; optional -UserScope mirrors core/skills under
  InstallRoot/.agents/skills for fixtures, or real $HOME/.agents/skills when
  InstallRoot is live ~/.codex with -AllowUserHome; Publish-Policy copies
  core/policy -> InstallRoot/rules/*.md; Publish-Router materializes core/router ->
  AGENTS.md (dual-root absolute paths); Publish-Hooks writes
  plugin/hooks/hooks.json). Invoke-SmokeValidate is filesystem-only (TE01-TE04
  plus plugin + home help-skills/CATALOG, rules/, materialized AGENTS.md, optional
  UserScope; no /hooks trust UI). Uninstall-Toolkit removes keyed toolkit artifacts
  only (plugin skills, home skills, marketplace entry, hooks files, USER-scope
  skills, rules, AGENTS.md - RN07/CU03). Does not write under USERPROFILE without
  -AllowUserHome. Trust UI /hooks is out of scope for smoke (filesystem asserts
  only - RN03).
#>

$script:CodexAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CodexAdapterDirectory)) {
    $script:CodexAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:CodexAdapterLibDir = Join-Path $script:CodexAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:CodexAdapterLibDir 'Initialize-SddRootLayout.ps1')

. (Join-Path $script:CodexAdapterDirectory 'CodexPathConstants.ps1')
. (Join-Path $script:CodexAdapterDirectory 'Publish-CodexSkills.ps1')
. (Join-Path $script:CodexAdapterDirectory 'Publish-CodexPolicy.ps1')
. (Join-Path $script:CodexAdapterDirectory 'Publish-CodexRouter.ps1')
. (Join-Path $script:CodexAdapterDirectory 'Publish-CodexAgents.ps1')
. (Join-Path $script:CodexAdapterDirectory 'Publish-CodexHooks.ps1')
. (Join-Path $script:CodexAdapterDirectory 'Invoke-CodexSmokeValidate.ps1')
. (Join-Path $script:CodexAdapterDirectory 'Uninstall-CodexToolkit.ps1')

$script:CodexAdapterAgentId = 'codex'

$script:CodexAdapterCommandNames = @(
    'Get-Capabilities',
    'Get-InstallRoots',
    'Publish-Skills',
    'Publish-Policy',
    'Publish-Router',
    'Publish-Agents',
    'Publish-Hooks',
    'Get-SddRoot',
    'Invoke-SmokeValidate',
    'Uninstall-Toolkit'
)

$script:CodexAdapterSubagentsNative = 'native'

$script:CodexAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $true
    router    = $true
    plugin    = $true
    agents    = $true
    subagents = $script:CodexAdapterSubagentsNative
}

$script:CodexAdapterConstant = @{
    OfficialUserRootRelativePath         = '.codex'
    OfficialUserRootDescription          = 'Official Codex product home is under the user home as .codex (equivalent to ~/.codex) for config.toml, AGENTS.md, hooks, and agents.'
    OfficialUserSkillsRelativePath       = '.agents/skills'
    OfficialUserSkillsDescription        = 'Official Codex USER skills discovery root is under the user home as .agents/skills (equivalent to ~/.agents/skills) — dual-root with ~/.codex.'
    OfficialHomeSkillsRelativePath       = 'skills'
    OfficialHomeSkillsDescription        = 'Codex $ skill discovery reads InstallRoot/skills (live ~/.codex/skills). Publish-Skills always mirrors core/skills here; TOOLKIT_ROOT is InstallRoot.'
    OfficialMarketplaceRelativePath      = '.agents/plugins'
    OfficialMarketplaceDescription       = 'Official Codex marketplace catalog lives under .agents/plugins (marketplace.json modeled in fixture).'
    OfficialPluginRootRelativePath       = 'plugin'
    OfficialPluginRootDescription        = 'Toolkit Codex plugin root is modeled under InstallRoot/plugin (contains .codex-plugin, skills, hooks).'
    OfficialPluginManifestRelativePath   = '.codex-plugin/plugin.json'
    OfficialPluginManifestDescription    = 'Codex plugin packaging uses .codex-plugin/plugin.json at the plugin root; skills and hooks live beside that folder.'
    OfficialPluginSkillsRelativePath     = 'skills'
    OfficialPluginHooksRelativePath      = 'hooks'
    OfficialProjectAgentsFileName        = 'AGENTS.md'
    OfficialProjectAgentsDescription     = 'Project router surface for Codex is AGENTS.md at the project/InstallRoot scope.'
    FixtureRelativePath                  = 'scripts/validation/fixtures/codex'
    InstallRootOverrideParameter         = 'InstallRoot'
    InstallRootOverrideDescription       = 'Pass -InstallRoot to target an in-repo fixture or an explicit path. Paths under USERPROFILE require -AllowUserHome. Live home models ~/.codex; Publish-Skills always writes InstallRoot/skills for $ discovery; with -UserScope on live ~/.codex, USER skills also write to real ~/.agents/skills.'
    UserScopeParameterName               = 'UserScope'
    UserScopeDescription                 = 'Optional -UserScope also mirrors core/skills to ~/.agents/skills (opt-in only). Home skills InstallRoot/skills always publish for $ discovery; do not enable UserScope by default or the $ picker lists each skill twice.'
    HooksTrustNote                       = 'Hooks trust via Codex /hooks UI is a human operational step; smoke validates files only.'
    ResolveInstallRootRelativePath       = 'scripts/_lib/Resolve-InstallRoot.ps1'
}

$script:CodexAdapterMessage = @{
    NotImplemented      = '{0} is not implemented yet for the Codex adapter. Publish/smoke land in later adapter PLAN steps; stubs must not mutate InstallRoot.'
    AgentIdRequired     = 'AgentId is required.'
    InstallRootRequired = 'InstallRoot is required.'
    CapabilitiesReady   = 'Codex adapter capabilities reported (skills/plugin/rules/router/hooks). Publish + Invoke-SmokeValidate + keyed Uninstall-Toolkit ready (filesystem-only; trust UI /hooks out of scope; RN07 no wholesale wipe). SDD runtime prepared on sync.'
    ResolveInstallRootMissing = 'Resolve-InstallRoot helper not found at: {0}'
    SddRootResolved     = 'Codex SDD root resolved at {0}.'
    SddRootPrepared     = 'Prepared Codex SDD root at {0} (sessions={1}; manifestCreated={2}).'
    SddRootWouldPrepare = 'WhatIf: would prepare Codex SDD root at {0} (sessions + seed manifest.json if missing).'
}

function New-CodexAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:CodexAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-CodexAdapterCommandNames {
    return @($script:CodexAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Codex adapter capability flags (skills/plugin/rules/router/hooks).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:CodexAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:CodexAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:CodexAdapterCapabilityFlags
        Message      = $script:CodexAdapterMessage.CapabilitiesReady
    }
}

function Get-CodexAdapterRepoRoot {
    [CmdletBinding()]
    param()

    $adapterDir = $PSScriptRoot
    $adaptersDir = Split-Path -Parent $adapterDir
    return Split-Path -Parent $adaptersDir
}

function Initialize-CodexInstallRootResolver {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue) {
        return
    }

    $repoRoot = Get-CodexAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:CodexAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:CodexAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
}

function Get-CodexMappedInstallPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $pluginRoot = Join-Path $ResolvedInstallRoot $script:CodexAdapterConstant.OfficialPluginRootRelativePath
    $pluginManifest = Join-Path $pluginRoot ($script:CodexAdapterConstant.OfficialPluginManifestRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)

    return [PSCustomObject]@{
        FixtureUserSkillsPath      = Join-Path $ResolvedInstallRoot $script:CodexAdapterConstant.OfficialUserSkillsRelativePath
        FixtureHomeSkillsPath      = Join-Path $ResolvedInstallRoot $script:CodexAdapterConstant.OfficialHomeSkillsRelativePath
        FixtureMarketplacePath     = Join-Path $ResolvedInstallRoot $script:CodexAdapterConstant.OfficialMarketplaceRelativePath
        FixturePluginRootPath      = $pluginRoot
        FixturePluginManifestPath  = $pluginManifest
        FixturePluginSkillsPath    = Join-Path $pluginRoot $script:CodexAdapterConstant.OfficialPluginSkillsRelativePath
        FixturePluginHooksPath     = Join-Path $pluginRoot $script:CodexAdapterConstant.OfficialPluginHooksRelativePath
        FixtureProjectAgentsPath   = Join-Path $ResolvedInstallRoot $script:CodexAdapterConstant.OfficialProjectAgentsFileName
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official Codex install roots and map them under an optional InstallRoot fixture.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId,

        [Parameter()]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:CodexAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    $officialUserSkillsFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:CodexAdapterConstant.OfficialUserRootRelativePath
        $officialUserSkillsFull = Join-Path $userHome $script:CodexAdapterConstant.OfficialUserSkillsRelativePath
    }

    $resolvedInstallRoot = $null
    $mapped = $null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        Initialize-CodexInstallRootResolver
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
        $mapped = Get-CodexMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    }

    return [PSCustomObject]@{
        Success                              = $true
        Implemented                          = $true
        AgentId                              = $AgentId.Trim()
        OfficialUserRootRelativePath         = $script:CodexAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription          = $script:CodexAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath                 = $officialFull
        OfficialUserSkillsRelativePath       = $script:CodexAdapterConstant.OfficialUserSkillsRelativePath
        OfficialUserSkillsDescription        = $script:CodexAdapterConstant.OfficialUserSkillsDescription
        OfficialUserSkillsPath               = $officialUserSkillsFull
        OfficialHomeSkillsRelativePath       = $script:CodexAdapterConstant.OfficialHomeSkillsRelativePath
        OfficialHomeSkillsDescription        = $script:CodexAdapterConstant.OfficialHomeSkillsDescription
        OfficialMarketplaceRelativePath      = $script:CodexAdapterConstant.OfficialMarketplaceRelativePath
        OfficialMarketplaceDescription       = $script:CodexAdapterConstant.OfficialMarketplaceDescription
        OfficialPluginRootRelativePath       = $script:CodexAdapterConstant.OfficialPluginRootRelativePath
        OfficialPluginRootDescription        = $script:CodexAdapterConstant.OfficialPluginRootDescription
        OfficialPluginManifestRelativePath   = $script:CodexAdapterConstant.OfficialPluginManifestRelativePath
        OfficialPluginManifestDescription    = $script:CodexAdapterConstant.OfficialPluginManifestDescription
        OfficialPluginSkillsRelativePath     = $script:CodexAdapterConstant.OfficialPluginSkillsRelativePath
        OfficialPluginHooksRelativePath      = $script:CodexAdapterConstant.OfficialPluginHooksRelativePath
        OfficialProjectAgentsFileName        = $script:CodexAdapterConstant.OfficialProjectAgentsFileName
        OfficialProjectAgentsDescription     = $script:CodexAdapterConstant.OfficialProjectAgentsDescription
        FixtureRelativePath                  = $script:CodexAdapterConstant.FixtureRelativePath
        OverrideParameter                    = $script:CodexAdapterConstant.InstallRootOverrideParameter
        OverrideDescription                  = $script:CodexAdapterConstant.InstallRootOverrideDescription
        HooksTrustNote                       = $script:CodexAdapterConstant.HooksTrustNote
        ResolvedInstallRoot                  = $resolvedInstallRoot
        FixtureUserSkillsPath                = $(if ($null -ne $mapped) { $mapped.FixtureUserSkillsPath } else { $null })
        FixtureHomeSkillsPath                = $(if ($null -ne $mapped) { $mapped.FixtureHomeSkillsPath } else { $null })
        FixtureMarketplacePath               = $(if ($null -ne $mapped) { $mapped.FixtureMarketplacePath } else { $null })
        FixturePluginRootPath                = $(if ($null -ne $mapped) { $mapped.FixturePluginRootPath } else { $null })
        FixturePluginManifestPath            = $(if ($null -ne $mapped) { $mapped.FixturePluginManifestPath } else { $null })
        FixturePluginSkillsPath              = $(if ($null -ne $mapped) { $mapped.FixturePluginSkillsPath } else { $null })
        FixturePluginHooksPath               = $(if ($null -ne $mapped) { $mapped.FixturePluginHooksPath } else { $null })
        FixtureProjectAgentsPath             = $(if ($null -ne $mapped) { $mapped.FixtureProjectAgentsPath } else { $null })
        Message                              = ('{0} {1} {2} {3} {4} {5} {6} {7}' -f $script:CodexAdapterConstant.OfficialUserRootDescription, $script:CodexAdapterConstant.OfficialHomeSkillsDescription, $script:CodexAdapterConstant.OfficialUserSkillsDescription, $script:CodexAdapterConstant.OfficialMarketplaceDescription, $script:CodexAdapterConstant.OfficialPluginRootDescription, $script:CodexAdapterConstant.OfficialPluginManifestDescription, $script:CodexAdapterConstant.OfficialProjectAgentsDescription, $script:CodexAdapterConstant.InstallRootOverrideDescription)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills into InstallRoot/plugin and InstallRoot/skills (Codex $ discovery).

    .DESCRIPTION
      Always: plugin-bundled skills + marketplace under InstallRoot, plus home skills
      mirror at InstallRoot/skills (live ~/.codex/skills) for Codex `$<skill-id>` discovery.
      -UserScope: also mirrors core/skills — fixture InstallRoot/.agents/skills, or
      real $HOME/.agents/skills when InstallRoot is live ~/.codex with -AllowUserHome.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $UserScope,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-CodexPublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -UserScope:$UserScope -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Publish core/policy into InstallRoot/rules as .md (Claude layout).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-CodexPublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish router material: core/router/AGENTS.md -> InstallRoot/AGENTS.md.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-CodexPublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Agents {
    <#
    .SYNOPSIS
      Publish core/agents/*.md into InstallRoot/agents (live ~/.codex/agents/).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-CodexPublishAgents -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish hooks files under InstallRoot/plugin/hooks (filesystem only; trust /hooks is manual).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-CodexPublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Get-SddRoot {
    <#
    .SYNOPSIS
      Resolve `<InstallRoot>/sdd`. With -Prepare, ensure `sessions/` and seed `manifest.json` if missing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $Prepare,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-CodexAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:CodexAdapterMessage.SddRootResolved `
        -MessagePrepared $script:CodexAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:CodexAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run Codex filesystem smoke against InstallRoot (plugin, marketplace, AGENTS.md, hooks, USER skills fixture).

    .DESCRIPTION
      TE01 InstallRoot guard; TE02 plugin.json/skills; TE03 marketplace entry; TE04 hooks files when capable.
      Never asserts Codex /hooks trust UI (RN03 / TE05 out of scope).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-CodexSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts under InstallRoot (plugin/home/marketplace/hooks/USER skills/rules/AGENTS.md).
      Does not wipe plugin/, skills/, or .agents/ wholesale or touch alien files (RN07 / CU03).
      Live ~/.codex + prior UserScope also removes managed skills under $HOME/.agents/skills.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexAdapterMessage.InstallRootRequired
    }

    return Invoke-CodexUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
