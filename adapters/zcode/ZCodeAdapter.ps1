#Requires -Version 5.1
<#
.SYNOPSIS
  ZCode (Z.ai ADE) adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `zcode`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Router / Publish-Hooks /
  Get-SddRoot (-Prepare) / Invoke-SmokeValidate / Uninstall-Toolkit (keyed) are implemented.
  Publish-Policy is a documented no-op (rules=false).
  Does not write under USERPROFILE without -AllowUserHome.
  Official user root is ~/.zcode (skills/, AGENTS.md, hooks/config, sdd/). This surface is
  ZCode ADE - not GLM Coding Plan (endpoint/Base URL/MCP only; Tier 3 / out of scope).
  ZCode does not use Cursor rules/*.mdc; sync-agent publish skills, AGENTS.md, hooks/config,
  and prepares sdd/sessions + manifest. Uninstall preserves sdd sessions/manifest.

.NOTES
  Capabilities:
  - skills = true (Agent Skills under skills/<id>/SKILL.md)
  - router = true (AGENTS.md at InstallRoot from core/router)
  - hooks = true (cli/config.json and/or hooks/hooks.json)
  - rules = false (no Cursor-style rules/*.mdc tree; router via AGENTS.md)
  - plugin = false (marketplace .zcode-plugin optional / out of MVP BDD)
#>

$script:ZCodeAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ZCodeAdapterDirectory)) {
    $script:ZCodeAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:ZCodeAdapterLibDir = Join-Path $script:ZCodeAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:ZCodeAdapterLibDir 'Initialize-SddRootLayout.ps1')

. (Join-Path $script:ZCodeAdapterDirectory 'ZCodePathConstants.ps1')
. (Join-Path $script:ZCodeAdapterDirectory 'Publish-ZCodeSkills.ps1')
. (Join-Path $script:ZCodeAdapterDirectory 'Publish-ZCodeRouter.ps1')
. (Join-Path $script:ZCodeAdapterDirectory 'Publish-ZCodeAgents.ps1')
. (Join-Path $script:ZCodeAdapterDirectory 'Publish-ZCodeHooks.ps1')
. (Join-Path $script:ZCodeAdapterDirectory 'Invoke-ZCodeSmokeValidate.ps1')
. (Join-Path $script:ZCodeAdapterDirectory 'Uninstall-ZCodeToolkit.ps1')

$script:ZCodeAdapterAgentId = 'zcode'

$script:ZCodeAdapterCommandNames = @(
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

$script:ZCodeAdapterSubagentsNative = 'native'

$script:ZCodeAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $false
    hooks     = $true
    router    = $true
    plugin    = $false
    agents    = $true
    subagents = $script:ZCodeAdapterSubagentsNative
}

$script:ZCodeAdapterConstant = @{
    OfficialUserRootRelativePath     = '.zcode'
    OfficialUserRootDescription      = 'Official ZCode ADE user root is under the user home as .zcode (equivalent to ~/.zcode).'
    OfficialSkillsRelativePath       = 'skills'
    OfficialSkillsDescription        = 'ZCode skills publish under skills/<kebab-id>/SKILL.md relative to InstallRoot (and user ~/.zcode/skills when mirrored).'
    OfficialAgentsFileName           = 'AGENTS.md'
    OfficialAgentsDescription        = 'ZCode router surface is AGENTS.md at the InstallRoot / ~/.zcode scope.'
    OfficialHooksRelativePath        = 'hooks'
    OfficialHooksDescription         = 'ZCode hooks publish under hooks/hooks.json (and related scripts) relative to InstallRoot.'
    OfficialConfigRelativePath       = 'cli/config.json'
    OfficialConfigDescription        = 'ZCode hooks config may include cli/config.json with hooks.enabled when applicable.'
    FixtureRelativePath              = 'scripts/validation/fixtures/zcode-install-root'
    InstallRootOverrideParameter     = 'InstallRoot'
    InstallRootOverrideDescription   = 'Pass -InstallRoot to target an in-repo fixture or an explicit path. Paths under USERPROFILE require -AllowUserHome.'
    GlmCodingPlanExclusionNote       = 'GLM Coding Plan (endpoint/Base URL/MCP only) is not this adapter; it remains Tier 3 / out of scope. Use ZCode ADE for skills/AGENTS.md/hooks filesystem surfaces.'
}

$script:ZCodeAdapterMessage = @{
    NotImplemented      = '{0} is not implemented yet for the ZCode adapter. Publish/smoke land in later adapter PLAN steps; stubs must not mutate InstallRoot.'
    AgentIdRequired     = 'AgentId is required.'
    InstallRootRequired = 'InstallRoot is required.'
    CapabilitiesReady   = 'ZCode ADE adapter capabilities reported (skills/router/hooks). Publish, Get-SddRoot (-Prepare), and filesystem smoke are available; GLM Coding Plan is not this surface. SDD runtime prepared on sync.'
    SddRootResolved     = 'ZCode SDD root resolved at {0}.'
    SddRootPrepared     = 'Prepared ZCode SDD root at {0} (sessionsCreated={1}; manifestCreated={2}).'
    SddRootWouldPrepare = 'WhatIf: would prepare ZCode SDD root at {0} (sessions + seed manifest.json if missing).'
}

function New-ZCodeAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:ZCodeAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-ZCodeAdapterCommandNames {
    return @($script:ZCodeAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report ZCode adapter capability flags (skills/router/hooks).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:ZCodeAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:ZCodeAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:ZCodeAdapterCapabilityFlags
        Message      = $script:ZCodeAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official ZCode ADE install roots and InstallRoot override semantics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:ZCodeAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:ZCodeAdapterConstant.OfficialUserRootRelativePath
    }

    return [PSCustomObject]@{
        Success                         = $true
        Implemented                     = $true
        AgentId                         = $AgentId.Trim()
        OfficialUserRootRelativePath    = $script:ZCodeAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription     = $script:ZCodeAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath            = $officialFull
        OfficialSkillsRelativePath      = $script:ZCodeAdapterConstant.OfficialSkillsRelativePath
        OfficialSkillsDescription       = $script:ZCodeAdapterConstant.OfficialSkillsDescription
        OfficialAgentsFileName          = $script:ZCodeAdapterConstant.OfficialAgentsFileName
        OfficialAgentsDescription       = $script:ZCodeAdapterConstant.OfficialAgentsDescription
        OfficialHooksRelativePath       = $script:ZCodeAdapterConstant.OfficialHooksRelativePath
        OfficialHooksDescription        = $script:ZCodeAdapterConstant.OfficialHooksDescription
        OfficialConfigRelativePath      = $script:ZCodeAdapterConstant.OfficialConfigRelativePath
        OfficialConfigDescription       = $script:ZCodeAdapterConstant.OfficialConfigDescription
        FixtureRelativePath             = $script:ZCodeAdapterConstant.FixtureRelativePath
        OverrideParameter               = $script:ZCodeAdapterConstant.InstallRootOverrideParameter
        OverrideDescription             = $script:ZCodeAdapterConstant.InstallRootOverrideDescription
        GlmCodingPlanExclusionNote      = $script:ZCodeAdapterConstant.GlmCodingPlanExclusionNote
        Message                         = ('{0} {1} {2}' -f $script:ZCodeAdapterConstant.OfficialUserRootDescription, $script:ZCodeAdapterConstant.InstallRootOverrideDescription, $script:ZCodeAdapterConstant.GlmCodingPlanExclusionNote)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills into InstallRoot/skills (kebab folders) with destination-only placeholder resolution.
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
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ZCodePublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Documented no-op - ZCode ADE MVP has no Cursor-style rules/*.mdc policy surface (rules=false).
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
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return [PSCustomObject]@{
        Success       = $true
        Implemented   = $true
        CommandName   = 'Publish-Policy'
        NoOp          = $true
        WhatIf        = [bool]$WhatIf.IsPresent
        AllowUserHome = [bool]$AllowUserHome.IsPresent
        InstallRoot   = $InstallRoot.Trim()
        FilesCopied   = 0
        Message       = $script:ZCodePublishMessage.PolicyNoOp
        ExitCode      = 0
    }
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md to InstallRoot/AGENTS.md (no Cursor rules/*.mdc).
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
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ZCodePublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Agents {
    <#
    .SYNOPSIS
      Publish core/agents/*.md into InstallRoot/agents (live ~/.zcode/agents/).
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
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ZCodePublishAgents -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish ZCode hooks/config (cli/config.json + hooks/hooks.json) with non-destructive merge.
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
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ZCodePublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
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
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-ZCodeAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:ZCodeAdapterMessage.SddRootResolved `
        -MessagePrepared $script:ZCodeAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:ZCodeAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run ZCode filesystem smoke against a fixture InstallRoot (skills, AGENTS.md, hooks/config).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ZCodeSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts (skills, AGENTS.md, hooks/config reverse-merge).
      Preserves sdd/sessions and sdd/manifest.json.
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
        throw $script:ZCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ZCodeUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
