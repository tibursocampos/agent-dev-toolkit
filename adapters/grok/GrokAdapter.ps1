#Requires -Version 5.1
<#
.SYNOPSIS
  Grok Build adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `grok`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Policy /
  Publish-Router / Publish-Hooks are implemented (optional InstallRoot maps
  user ~/.grok and project .grok/skills|rules|hooks under the fixture).
  Publish-Skills copies core/skills into .grok/skills; Publish-Policy copies
  core/policy into .grok/rules/*.md; Publish-Router writes AGENTS.md from
  core/router; Publish-Hooks writes native JSON under .grok/hooks (never
  trusted_folders.toml). Invoke-SmokeValidate asserts native `.grok`
  filesystem layout (TE01-TE05). Uninstall-Toolkit removes only known toolkit
  artifacts under InstallRoot (keyed; never wipes ~/.grok / config.toml).
  Does not write under USERPROFILE without -AllowUserHome.
  Packaging target is native `.grok/skills|rules|hooks` (docs.x.ai/build).
  Claude/Cursor compat is not the sole publish destination. Hooks trust
  (`/hooks-trust` / `--trust`) is a human step; smoke is filesystem-only.

.NOTES
  Initial capabilities (Step 1 decision):
  - skills = true (Agent Skills under .grok/skills)
  - rules = true (.grok/rules/*.md from core/policy)
  - hooks = true (.grok/hooks JSON; trust UI manual)
  - router = true (AGENTS.md / project-rules surface)
  - sdd = false
  - plugin = false (marketplace/plugins out of MVP CI green)
#>

$script:GrokAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:GrokAdapterDirectory)) {
    $script:GrokAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

. (Join-Path $script:GrokAdapterDirectory 'GrokPathConstants.ps1')
. (Join-Path $script:GrokAdapterDirectory 'Publish-GrokSkills.ps1')
. (Join-Path $script:GrokAdapterDirectory 'Publish-GrokPolicy.ps1')
. (Join-Path $script:GrokAdapterDirectory 'Publish-GrokRouter.ps1')
. (Join-Path $script:GrokAdapterDirectory 'Publish-GrokHooks.ps1')
. (Join-Path $script:GrokAdapterDirectory 'Invoke-GrokSmokeValidate.ps1')
. (Join-Path $script:GrokAdapterDirectory 'Uninstall-GrokToolkit.ps1')

$script:GrokAdapterAgentId = 'grok'

$script:GrokAdapterCommandNames = @(
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

$script:GrokAdapterSubagentsNative = 'native'

$script:GrokAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $true
    router    = $true
    sdd       = $false
    plugin    = $false
    subagents = $script:GrokAdapterSubagentsNative
}

function New-GrokAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:GrokAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-GrokAdapterCommandNames {
    return @($script:GrokAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Grok adapter capability flags (skills/rules/hooks/router).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:GrokAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:GrokAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:GrokAdapterCapabilityFlags
        Message      = $script:GrokAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official Grok Build install roots and map them under an optional InstallRoot fixture.
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
        throw $script:GrokAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:GrokAdapterConstant.OfficialUserRootRelativePath
    }

    $resolvedInstallRoot = $null
    $mapped = $null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        Initialize-GrokInstallRootResolver
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
        $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    }

    return [PSCustomObject]@{
        Success                         = $true
        Implemented                     = $true
        AgentId                         = $AgentId.Trim()
        OfficialUserRootRelativePath    = $script:GrokAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription     = $script:GrokAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath            = $officialFull
        OfficialProjectRootRelativePath = $script:GrokAdapterConstant.OfficialProjectRootRelativePath
        OfficialProjectRootDescription  = $script:GrokAdapterConstant.OfficialProjectRootDescription
        OfficialSkillsRelativePath      = $script:GrokAdapterConstant.OfficialSkillsRelativePath
        OfficialSkillsDescription       = $script:GrokAdapterConstant.OfficialSkillsDescription
        OfficialRulesRelativePath       = $script:GrokAdapterConstant.OfficialRulesRelativePath
        OfficialRulesDescription        = $script:GrokAdapterConstant.OfficialRulesDescription
        OfficialHooksRelativePath       = $script:GrokAdapterConstant.OfficialHooksRelativePath
        OfficialHooksDescription        = $script:GrokAdapterConstant.OfficialHooksDescription
        OfficialAgentsFileName          = $script:GrokAdapterConstant.OfficialAgentsFileName
        OfficialAgentsDescription       = $script:GrokAdapterConstant.OfficialAgentsDescription
        FixtureRelativePath             = $script:GrokAdapterConstant.FixtureRelativePath
        OverrideParameter               = $script:GrokAdapterConstant.InstallRootOverrideParameter
        OverrideDescription             = $script:GrokAdapterConstant.InstallRootOverrideDescription
        HooksTrustNote                  = $script:GrokAdapterConstant.HooksTrustNote
        ResolvedInstallRoot             = $resolvedInstallRoot
        FixtureUserRootPath             = $(if ($null -ne $mapped) { $mapped.FixtureUserRootPath } else { $null })
        FixtureProjectRootPath          = $(if ($null -ne $mapped) { $mapped.FixtureProjectRootPath } else { $null })
        FixtureSkillsPath               = $(if ($null -ne $mapped) { $mapped.FixtureSkillsPath } else { $null })
        FixtureRulesPath                = $(if ($null -ne $mapped) { $mapped.FixtureRulesPath } else { $null })
        FixtureHooksPath                = $(if ($null -ne $mapped) { $mapped.FixtureHooksPath } else { $null })
        FixtureProjectAgentsPath        = $(if ($null -ne $mapped) { $mapped.FixtureProjectAgentsPath } else { $null })
        Message                         = ('{0} {1} {2}' -f $script:GrokAdapterConstant.OfficialUserRootDescription, $script:GrokAdapterConstant.OfficialProjectRootDescription, $script:GrokAdapterConstant.InstallRootOverrideDescription)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills into InstallRoot/.grok/skills (kebab folders) with placeholder resolution.
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    return Invoke-GrokPublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Publish core/policy into InstallRoot/.grok/rules as .md (native Grok rules).
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    return Invoke-GrokPublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md as InstallRoot/AGENTS.md (Grok project-rules surface).
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    return Invoke-GrokPublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish native Grok hooks JSON under InstallRoot/.grok/hooks (docs.x.ai/build/features/hooks).
      Trust via /hooks-trust or --trust is manual; never writes trusted_folders.toml.
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    return Invoke-GrokPublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Get-SddRoot {
    <#
    .SYNOPSIS
      Resolve the published SDD root under InstallRoot. Stub - sdd capability is false for Grok MVP.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    return New-GrokAdapterNotImplementedResult -CommandName 'Get-SddRoot'
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run Grok filesystem smoke against a fixture InstallRoot (skills/rules/hooks/AGENTS.md).
      Does not invoke or require /hooks-trust (TE05 files only).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    return Invoke-GrokSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts published under InstallRoot (.grok skills/rules/hooks + AGENTS.md).
      Does not wipe .grok wholesale or touch config.toml (RN07 / CU03).
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    return Invoke-GrokUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
