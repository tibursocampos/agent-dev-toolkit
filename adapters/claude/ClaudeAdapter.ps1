#Requires -Version 5.1
<#
.SYNOPSIS
  Claude Code adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `claude`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Policy /
  Publish-Router / Publish-Hooks (scripts + settings.json merge) /
  Get-SddRoot (-Prepare) / Invoke-SmokeValidate / Uninstall-Toolkit (keyed)
  are implemented.
  Does not write under USERPROFILE without -AllowUserHome.
  Smoke is filesystem-only (Claude hooks trust UI out of scope).
  SDD runtime is prepared by sync via Get-SddRoot -Prepare (not a capability flag).
#>

$script:ClaudeAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeAdapterDirectory)) {
    $script:ClaudeAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:ClaudeAdapterLibDir = Join-Path $script:ClaudeAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:ClaudeAdapterLibDir 'Initialize-SddRootLayout.ps1')

. (Join-Path $script:ClaudeAdapterDirectory 'ClaudePathConstants.ps1')
. (Join-Path $script:ClaudeAdapterDirectory 'Publish-ClaudeSkills.ps1')
. (Join-Path $script:ClaudeAdapterDirectory 'Publish-ClaudePolicy.ps1')
. (Join-Path $script:ClaudeAdapterDirectory 'Publish-ClaudeRouter.ps1')
. (Join-Path $script:ClaudeAdapterDirectory 'Merge-ClaudeSettings.ps1')
. (Join-Path $script:ClaudeAdapterDirectory 'Publish-ClaudeHooks.ps1')
. (Join-Path $script:ClaudeAdapterDirectory 'Invoke-ClaudeSmokeValidate.ps1')
. (Join-Path $script:ClaudeAdapterDirectory 'Uninstall-ClaudeToolkit.ps1')

$script:ClaudeAdapterAgentId = 'claude'

$script:ClaudeAdapterCommandNames = @(
    'Get-Capabilities',
    'Get-InstallRoots',
    'Publish-Skills',
    'Publish-Policy',
    'Publish-Router',
    'Publish-Hooks',
    'Get-SddRoot',
    'Invoke-SmokeValidate',
    'Uninstall-Toolkit'
)

$script:ClaudeAdapterSubagentsNative = 'native'

$script:ClaudeAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $true
    router    = $true
    plugin    = $false
    subagents = $script:ClaudeAdapterSubagentsNative
}

$script:ClaudeAdapterConstant = @{
    OfficialUserRootRelativePath     = '.claude'
    OfficialUserRootDescription      = 'Official Claude Code user install root is under the user home as .claude (equivalent to ~/.claude).'
    OfficialProjectRootRelativePath  = '.claude'
    OfficialProjectRootDescription   = 'Official Claude Code project scope uses .claude under the repository root (for example .claude/settings.json).'
    InstallRootOverrideParameter     = 'InstallRoot'
    InstallRootOverrideDescription   = 'Pass -InstallRoot to target an in-repo fixture or an explicit path. Paths under USERPROFILE require -AllowUserHome.'
    FixtureRelativePath              = 'scripts/validation/fixtures/claude'
    SettingsFileName                 = 'settings.json'
    ClaudeMdFileName                 = 'CLAUDE.md'
}

$script:ClaudeAdapterMessage = @{
    NotImplemented      = '{0} is not implemented yet for the Claude adapter. Stubs must not mutate InstallRoot.'
    AgentIdRequired     = 'AgentId is required.'
    InstallRootRequired = 'InstallRoot is required.'
    CapabilitiesReady   = 'Claude adapter capabilities reported (skills/rules/hooks/router via CLAUDE.md). Publish + Invoke-SmokeValidate + keyed Uninstall-Toolkit ready (filesystem-only; hooks trust UI out of scope). SDD runtime prepared on sync.'
    SddRootResolved     = 'Claude SDD root resolved at {0}.'
    SddRootPrepared     = 'Prepared Claude SDD root at {0} (sessions={1}; manifestCreated={2}).'
    SddRootWouldPrepare = 'WhatIf: would prepare Claude SDD root at {0} (sessions + seed manifest.json if missing).'
}

function New-ClaudeAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:ClaudeAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-ClaudeAdapterCommandNames {
    return @($script:ClaudeAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Claude adapter capability flags (skills/rules/hooks/router).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:ClaudeAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:ClaudeAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:ClaudeAdapterCapabilityFlags
        Message      = $script:ClaudeAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official Claude Code install roots and InstallRoot override semantics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:ClaudeAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:ClaudeAdapterConstant.OfficialUserRootRelativePath
    }

    return [PSCustomObject]@{
        Success                         = $true
        Implemented                     = $true
        AgentId                         = $AgentId.Trim()
        OfficialUserRootRelativePath    = $script:ClaudeAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription     = $script:ClaudeAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath            = $officialFull
        OfficialProjectRootRelativePath = $script:ClaudeAdapterConstant.OfficialProjectRootRelativePath
        OfficialProjectRootDescription  = $script:ClaudeAdapterConstant.OfficialProjectRootDescription
        FixtureRelativePath             = $script:ClaudeAdapterConstant.FixtureRelativePath
        OverrideParameter               = $script:ClaudeAdapterConstant.InstallRootOverrideParameter
        OverrideDescription             = $script:ClaudeAdapterConstant.InstallRootOverrideDescription
        SettingsFileName                = $script:ClaudeAdapterConstant.SettingsFileName
        ClaudeMdFileName                = $script:ClaudeAdapterConstant.ClaudeMdFileName
        Message                         = ('{0} {1} {2}' -f $script:ClaudeAdapterConstant.OfficialUserRootDescription, $script:ClaudeAdapterConstant.OfficialProjectRootDescription, $script:ClaudeAdapterConstant.InstallRootOverrideDescription)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills into InstallRoot/skills (kebab folders) with placeholder resolution.
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
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    return Invoke-ClaudePublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
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
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    return Invoke-ClaudePublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md as InstallRoot/CLAUDE.md.
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
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    return Invoke-ClaudePublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish toolkit hook scripts under InstallRoot/hooks and merge settings.json.
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
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    return Invoke-ClaudePublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
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
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-ClaudeAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:ClaudeAdapterMessage.SddRootResolved `
        -MessagePrepared $script:ClaudeAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:ClaudeAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run Claude filesystem smoke against a fixture InstallRoot (skills/rules/hooks/CLAUDE.md/settings).
      Does not invoke Claude runtime or require hooks trust UI (TE05 files only).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    return Invoke-ClaudeSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts under InstallRoot (skills/rules/hooks/CLAUDE.md)
      and reverse-merge managed settings entries. Does not wipe alien keys or InstallRoot.
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
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    return Invoke-ClaudeUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
