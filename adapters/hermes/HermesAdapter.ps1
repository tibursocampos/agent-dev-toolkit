#Requires -Version 5.1
<#
.SYNOPSIS
  Hermes adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `hermes`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Policy /
  Publish-Router are implemented (optional InstallRoot maps the Hermes home:
  live ~/.hermes, fixture modeling the same layout).
  Publish-Skills copies core/skills into InstallRoot/skills.
  Publish-Policy and Publish-Router write the same managed AGENTS.md
  (router body + folded core/policy). Publish-Hooks and Publish-Agents are
  no-ops. Invoke-SmokeValidate asserts native skills/AGENTS.md layout.
  Uninstall-Toolkit removes only known toolkit artifacts under InstallRoot
  (keyed; never wipes InstallRoot / config.yaml / MEMORY.md / SOUL.md).
  Does not write under USERPROFILE without -AllowUserHome.
  MEMORY.md is seeded only when missing. SOUL.md is never created or overwritten.
#>

$script:HermesAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:HermesAdapterDirectory)) {
    $script:HermesAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:HermesAdapterLibDir = Join-Path $script:HermesAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:HermesAdapterLibDir 'Initialize-SddRootLayout.ps1')

. (Join-Path $script:HermesAdapterDirectory 'HermesPathConstants.ps1')
. (Join-Path $script:HermesAdapterDirectory 'Publish-HermesSkills.ps1')
. (Join-Path $script:HermesAdapterDirectory 'Publish-HermesPolicy.ps1')
. (Join-Path $script:HermesAdapterDirectory 'Publish-HermesRouter.ps1')
. (Join-Path $script:HermesAdapterDirectory 'Publish-HermesHooks.ps1')
. (Join-Path $script:HermesAdapterDirectory 'Invoke-HermesSmokeValidate.ps1')
. (Join-Path $script:HermesAdapterDirectory 'Uninstall-HermesToolkit.ps1')

$script:HermesAdapterAgentId = 'hermes'

$script:HermesAdapterCommandNames = @(
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

$script:HermesAdapterSubagentsNative = 'native'

$script:HermesAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $false
    router    = $true
    plugin    = $false
    agents    = $false
    subagents = $script:HermesAdapterSubagentsNative
}

function New-HermesAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:HermesAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-HermesAdapterCommandNames {
    return @($script:HermesAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Hermes adapter capability flags (skills/rules folded into AGENTS.md/router).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:HermesAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:HermesAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:HermesAdapterCapabilityFlags
        Message      = $script:HermesAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official Hermes install roots and map them under an optional InstallRoot fixture.
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
        throw $script:HermesAdapterMessage.AgentIdRequired
    }

    $officialFull = Resolve-HermesOfficialUserRoot

    $resolvedInstallRoot = $null
    $mapped = $null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        Initialize-HermesInstallRootResolver
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
        $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    }

    return [PSCustomObject]@{
        Success                         = $true
        Implemented                     = $true
        AgentId                         = $AgentId.Trim()
        OfficialUserRootRelativePath    = $script:HermesAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription     = $script:HermesAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath            = $officialFull
        OfficialProjectRootRelativePath = $script:HermesAdapterConstant.OfficialProjectRootRelativePath
        OfficialProjectRootDescription  = $script:HermesAdapterConstant.OfficialProjectRootDescription
        OfficialSkillsRelativePath      = $script:HermesAdapterConstant.OfficialSkillsRelativePath
        OfficialSkillsDescription       = $script:HermesAdapterConstant.OfficialSkillsDescription
        OfficialRulesRelativePath       = $script:HermesAdapterConstant.OfficialRulesRelativePath
        OfficialRulesDescription        = $script:HermesAdapterConstant.OfficialRulesDescription
        OfficialHooksRelativePath       = $script:HermesAdapterConstant.OfficialHooksRelativePath
        OfficialHooksDescription        = $script:HermesAdapterConstant.OfficialHooksDescription
        OfficialAgentsFileName          = $script:HermesAdapterConstant.OfficialAgentsFileName
        OfficialAgentsDescription       = $script:HermesAdapterConstant.OfficialAgentsDescription
        FixtureRelativePath             = $script:HermesAdapterConstant.FixtureRelativePath
        OverrideParameter               = $script:HermesAdapterConstant.InstallRootOverrideParameter
        OverrideDescription             = $script:HermesAdapterConstant.InstallRootOverrideDescription
        SkillsTrustNote                 = $script:HermesAdapterConstant.SkillsTrustNote
        ResolvedInstallRoot             = $resolvedInstallRoot
        FixtureUserRootPath             = $(if ($null -ne $mapped) { $mapped.FixtureUserRootPath } else { $null })
        FixtureProjectRootPath          = $(if ($null -ne $mapped) { $mapped.FixtureProjectRootPath } else { $null })
        FixtureSkillsPath               = $(if ($null -ne $mapped) { $mapped.FixtureSkillsPath } else { $null })
        FixtureRulesPath                = $(if ($null -ne $mapped) { $mapped.FixtureRulesPath } else { $null })
        FixtureHooksPath                = $(if ($null -ne $mapped) { $mapped.FixtureHooksPath } else { $null })
        FixtureProjectAgentsPath        = $(if ($null -ne $mapped) { $mapped.FixtureProjectAgentsPath } else { $null })
        Message                         = ('{0} {1} {2}' -f $script:HermesAdapterConstant.OfficialUserRootDescription, $script:HermesAdapterConstant.OfficialProjectRootDescription, $script:HermesAdapterConstant.InstallRootOverrideDescription)
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return Invoke-HermesPublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Fold core/policy into InstallRoot/AGENTS.md (no rules/ tree).
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return Invoke-HermesPublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md combined with folded policy as InstallRoot/AGENTS.md.
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return Invoke-HermesPublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Agents {
    <#
    .SYNOPSIS
      Documented no-op - Hermes has no agents/*.md roster. Host spawn is delegate_task.
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Agents'
        NoOp        = $true
        WhatIf      = [bool]$WhatIf.IsPresent
        InstallRoot = $InstallRoot.Trim()
        FilesCopied = 0
        Message     = $script:HermesAdapterMessage.AgentsNoOp
        ExitCode    = 0
    }
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Documented no-op - Hermes hooks capability is false.
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return Invoke-HermesPublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-HermesAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:HermesAdapterMessage.SddRootResolved `
        -MessagePrepared $script:HermesAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:HermesAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run Hermes filesystem smoke against a fixture InstallRoot (skills + AGENTS.md).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return Invoke-HermesSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts published under InstallRoot (skills + managed AGENTS.md).
      Does not wipe InstallRoot wholesale or touch config.yaml / MEMORY.md / SOUL.md.
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    return Invoke-HermesUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
