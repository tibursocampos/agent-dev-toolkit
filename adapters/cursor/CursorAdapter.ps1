#Requires -Version 5.1
<#
.SYNOPSIS
  Cursor adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `cursor`.
  Get-Capabilities / Get-InstallRoots / Publish-* / Get-SddRoot (-Prepare) /
  Invoke-SmokeValidate / Uninstall-Toolkit (keyed) are implemented.
  Does not write under USERPROFILE unless -AllowUserHome is set.
  Smoke is filesystem-only (Cursor hooks trust UI out of scope).
  Uninstall preserves sdd/sessions and sdd/manifest.json (operator state).
#>

$script:CursorAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CursorAdapterDirectory)) {
    $script:CursorAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:CursorAdapterLibDir = Join-Path $script:CursorAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:CursorAdapterLibDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $script:CursorAdapterLibDir 'Resolve-InstallRoot.ps1')
. (Join-Path $script:CursorAdapterLibDir 'Copy-ToolkitManagedTree.ps1')
. (Join-Path $script:CursorAdapterLibDir 'Initialize-SddRootLayout.ps1')

. (Join-Path $script:CursorAdapterDirectory 'CursorPathConstants.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorSkills.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorPolicy.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorRouter.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorHooks.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Invoke-CursorSmokeValidate.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Uninstall-CursorToolkit.ps1')

$script:CursorAdapterAgentId = 'cursor'

$script:CursorAdapterCommandNames = @(
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

$script:CursorAdapterSubagentsNative = 'native'

$script:CursorAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $true
    router    = $true
    plugin    = $false
    subagents = $script:CursorAdapterSubagentsNative
}

function New-CursorAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:CursorAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-CursorAdapterCommandNames {
    return @($script:CursorAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Cursor adapter capability flags (skills/rules/hooks/router/plugin/subagents).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:CursorAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:CursorAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:CursorAdapterCapabilityFlags
        Message      = $script:CursorAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe the official Cursor install root and InstallRoot override semantics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:CursorAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:CursorAdapterConstant.OfficialUserRootRelativePath
    }

    return [PSCustomObject]@{
        Success                      = $true
        Implemented                  = $true
        AgentId                      = $AgentId.Trim()
        OfficialUserRootRelativePath = $script:CursorAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription  = $script:CursorAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath         = $officialFull
        FixtureRelativePath          = $script:CursorAdapterConstant.FixtureRelativePath
        OverrideParameter            = $script:CursorAdapterConstant.InstallRootOverrideParameter
        OverrideDescription          = $script:CursorAdapterConstant.InstallRootOverrideDescription
        SddDirectoryName             = $script:CursorAdapterConstant.SddDirectoryName
        Message                      = ('{0} {1}' -f $script:CursorAdapterConstant.OfficialUserRootDescription, $script:CursorAdapterConstant.InstallRootOverrideDescription)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills (kebab folders) into InstallRoot/skills.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Publish core/policy/*.md into InstallRoot/rules as Cursor *.mdc rules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md into InstallRoot/AGENTS.md.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish hook scripts under InstallRoot/hooks and merge hooks.json at InstallRoot root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
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
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-CursorAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:CursorAdapterMessage.SddRootResolved `
        -MessagePrepared $script:CursorAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:CursorAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run filesystem-only Cursor smoke against a fixture InstallRoot (TE01/TE04).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts from InstallRoot (skills/rules/hooks/AGENTS.md + hooks.json reverse-merge).
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
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
