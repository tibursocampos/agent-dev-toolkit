#Requires -Version 5.1
<#
.SYNOPSIS
  OpenHands adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `openhands`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Policy /
  Publish-Router / Publish-Agents / Publish-Hooks are implemented.
  Default InstallRoot is a project tree (AGENTS.md, .agents/skills, .agents/agents,
  .openhands, .plugin). Live ~/.agents/skills requires -AllowUserHome.
  Publish-Policy folds core/policy into AGENTS.md (no Cursor rules/ tree).
  Publish-Hooks writes .openhands/hooks.json plus .openhands/hooks/*.sh (shell).
  Publish-Skills also writes .plugin/plugin.json; skills work without the plugin.
  Invoke-SmokeValidate asserts native filesystem layout. Uninstall-Toolkit removes
  only known toolkit artifacts (keyed). Does not write under USERPROFILE without
  -AllowUserHome. Does not emit Automation Server, sandbox, secrets, or model config.
#>

$script:OpenHandsAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenHandsAdapterDirectory)) {
    $script:OpenHandsAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:OpenHandsAdapterLibDir = Join-Path $script:OpenHandsAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:OpenHandsAdapterLibDir 'Initialize-SddRootLayout.ps1')

. (Join-Path $script:OpenHandsAdapterDirectory 'OpenHandsPathConstants.ps1')
. (Join-Path $script:OpenHandsAdapterDirectory 'Publish-OpenHandsSkills.ps1')
. (Join-Path $script:OpenHandsAdapterDirectory 'Publish-OpenHandsRouter.ps1')
. (Join-Path $script:OpenHandsAdapterDirectory 'Publish-OpenHandsPolicy.ps1')
. (Join-Path $script:OpenHandsAdapterDirectory 'Publish-OpenHandsAgents.ps1')
. (Join-Path $script:OpenHandsAdapterDirectory 'Publish-OpenHandsHooks.ps1')
. (Join-Path $script:OpenHandsAdapterDirectory 'Invoke-OpenHandsSmokeValidate.ps1')
. (Join-Path $script:OpenHandsAdapterDirectory 'Uninstall-OpenHandsToolkit.ps1')

$script:OpenHandsAdapterAgentId = 'openhands'

$script:OpenHandsAdapterCommandNames = @(
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

$script:OpenHandsAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $true
    router    = $true
    plugin    = $true
    agents    = $true
    subagents = $script:OpenHandsAdapterConstant.SubagentsNone
}

function Get-OpenHandsAdapterCommandNames {
    return @($script:OpenHandsAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report OpenHands adapter capability flags.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:OpenHandsAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:OpenHandsAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:OpenHandsAdapterCapabilityFlags
        Message      = $script:OpenHandsAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official OpenHands install roots and map them under an optional InstallRoot fixture.
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
        throw $script:OpenHandsAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:OpenHandsAdapterConstant.OfficialUserRootRelativePath
    }

    $resolvedInstallRoot = $null
    $mapped = $null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        Initialize-OpenHandsInstallRootResolver
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
        $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    }

    return [PSCustomObject]@{
        Success                            = $true
        Implemented                        = $true
        AgentId                            = $AgentId.Trim()
        OfficialUserRootRelativePath       = $script:OpenHandsAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription        = $script:OpenHandsAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath               = $officialFull
        OfficialProjectRootRelativePath    = $script:OpenHandsAdapterConstant.OfficialProjectRootRelativePath
        OfficialProjectRootDescription     = $script:OpenHandsAdapterConstant.OfficialProjectRootDescription
        OfficialSkillsRelativePath         = $script:OpenHandsAdapterConstant.OfficialSkillsRelativePath
        OfficialSkillsDescription          = $script:OpenHandsAdapterConstant.OfficialSkillsDescription
        OfficialUserSkillsRelativePath     = $script:OpenHandsAdapterConstant.OfficialUserSkillsRelativePath
        OfficialRulesRelativePath          = $script:OpenHandsAdapterConstant.OfficialRulesRelativePath
        OfficialRulesDescription           = $script:OpenHandsAdapterConstant.OfficialRulesDescription
        OfficialHooksRelativePath          = $script:OpenHandsAdapterConstant.OfficialHooksRelativePath
        OfficialHooksDescription           = $script:OpenHandsAdapterConstant.OfficialHooksDescription
        OfficialPluginRelativePath         = $script:OpenHandsAdapterConstant.OfficialPluginRelativePath
        OfficialPluginManifestRelativePath = $script:OpenHandsAdapterConstant.OfficialPluginManifestRelativePath
        OfficialPluginDescription          = $script:OpenHandsAdapterConstant.OfficialPluginDescription
        OfficialCustomAgentsRelativePath   = $script:OpenHandsAdapterConstant.OfficialCustomAgentsRelativePath
        OfficialCustomAgentsDescription    = $script:OpenHandsAdapterConstant.OfficialCustomAgentsDescription
        OfficialAgentsFileName             = $script:OpenHandsAdapterConstant.OfficialAgentsFileName
        OfficialAgentsDescription          = $script:OpenHandsAdapterConstant.OfficialAgentsDescription
        FixtureRelativePath                = $script:OpenHandsAdapterConstant.FixtureRelativePath
        OverrideParameter                  = $script:OpenHandsAdapterConstant.InstallRootOverrideParameter
        OverrideDescription                = $script:OpenHandsAdapterConstant.InstallRootOverrideDescription
        HooksTrustNote                     = $script:OpenHandsAdapterConstant.HooksFilesystemOnlyNote
        ResolvedInstallRoot                = $resolvedInstallRoot
        FixtureUserRootPath                = $(if ($null -ne $mapped) { $mapped.FixtureUserRootPath } else { $null })
        FixtureProjectRootPath             = $(if ($null -ne $mapped) { $mapped.FixtureProjectRootPath } else { $null })
        FixtureSkillsPath                  = $(if ($null -ne $mapped) { $mapped.FixtureSkillsPath } else { $null })
        FixtureRulesPath                   = $(if ($null -ne $mapped) { $mapped.FixtureRulesPath } else { $null })
        FixtureHooksPath                   = $(if ($null -ne $mapped) { $mapped.FixtureHooksPath } else { $null })
        FixtureHooksScriptsPath            = $(if ($null -ne $mapped) { $mapped.FixtureHooksScriptsPath } else { $null })
        FixturePluginPath                  = $(if ($null -ne $mapped) { $mapped.FixturePluginPath } else { $null })
        FixturePluginManifestPath          = $(if ($null -ne $mapped) { $mapped.FixturePluginManifestPath } else { $null })
        FixtureCustomAgentsPath            = $(if ($null -ne $mapped) { $mapped.FixtureCustomAgentsPath } else { $null })
        FixtureProjectAgentsPath           = $(if ($null -ne $mapped) { $mapped.FixtureProjectAgentsPath } else { $null })
        Message                            = ('{0} {1} {2}' -f $script:OpenHandsAdapterConstant.OfficialUserRootDescription, $script:OpenHandsAdapterConstant.OfficialProjectRootDescription, $script:OpenHandsAdapterConstant.InstallRootOverrideDescription)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills into InstallRoot/.agents/skills and write .plugin/plugin.json.
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenHandsPublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Fold core/policy into InstallRoot/AGENTS.md. Does not publish a rules/ tree.
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenHandsPublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md as InstallRoot/AGENTS.md with folded core/policy.
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenHandsPublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Agents {
    <#
    .SYNOPSIS
      Publish core/agents markdown into InstallRoot/.agents/agents (SDK/plugin roster).
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenHandsPublishAgents -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish .openhands/hooks.json and .openhands/hooks/*.sh (shell; filesystem only).
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenHandsPublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-OpenHandsAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:OpenHandsAdapterMessage.SddRootResolved `
        -MessagePrepared $script:OpenHandsAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:OpenHandsAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run OpenHands filesystem smoke against a fixture InstallRoot.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenHandsSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts published under InstallRoot.
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenHandsUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
