#Requires -Version 5.1
<#
.SYNOPSIS
  Stable adapter surface contract for agent-dev-toolkit.

.DESCRIPTION
  Dot-source this module to expose the public adapter command names.
  Publish / smoke / uninstall stubs fail closed with an explicit not-implemented result.
  Per-agent modules live under adapters/<agent>; do not publish to user home from the contract stubs.
#>

$script:AdapterContractCommandNames = @(
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

$script:AdapterCapabilityNames = @(
    'skills',
    'rules',
    'hooks',
    'router',
    'sdd',
    'plugin',
    'subagents'
)

# String enum for spawn capability (not boolean) — honesty matrix: native | none.
$script:AdapterSubagentsCapabilityNative = 'native'
$script:AdapterSubagentsCapabilityNone = 'none'

$script:AdapterContractMessage = @{
    NotImplemented = '{0} is not implemented. Adapter stubs must not publish or mutate InstallRoot until a concrete adapter module exists.'
    AgentIdRequired = 'AgentId is required.'
    InstallRootRequired = 'InstallRoot is required.'
}

function New-AdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success      = $false
        Implemented  = $false
        CommandName  = $CommandName
        Message      = ($script:AdapterContractMessage.NotImplemented -f $CommandName)
        ExitCode     = 1
    }
}

function Get-AdapterContractCommandNames {
    return @($script:AdapterContractCommandNames)
}

function Get-AdapterCapabilityNames {
    return @($script:AdapterCapabilityNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report which publish/smoke surfaces this adapter supports.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId
    )

    $flags = [ordered]@{}
    foreach ($name in $script:AdapterCapabilityNames) {
        if ($name -eq 'subagents') {
            # Stub defaults to none — never mint native without a concrete adapter.
            $flags[$name] = $script:AdapterSubagentsCapabilityNone
        }
        else {
            $flags[$name] = $false
        }
    }

    return [PSCustomObject]@{
        AgentId     = $AgentId
        Implemented = $false
        Capabilities = [PSCustomObject]$flags
        Message     = ($script:AdapterContractMessage.NotImplemented -f 'Get-Capabilities')
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Resolve official install roots for the agent (user/project). Stub only.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:AdapterContractMessage.AgentIdRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Get-InstallRoots'
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core skills into the agent InstallRoot. Stub - no filesystem writes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AdapterContractMessage.InstallRootRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Publish-Skills'
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Publish core policy into the agent InstallRoot. Stub - no filesystem writes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AdapterContractMessage.InstallRootRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Publish-Policy'
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core router material into the agent InstallRoot. Stub - no filesystem writes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AdapterContractMessage.InstallRootRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Publish-Router'
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish hooks into the agent InstallRoot. Stub - no filesystem writes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AdapterContractMessage.InstallRootRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Publish-Hooks'
}

function Get-SddRoot {
    <#
    .SYNOPSIS
      Resolve the published SDD contracts root for the agent. Stub only.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AdapterContractMessage.InstallRootRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Get-SddRoot'
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run adapter smoke against a fixture InstallRoot. Stub - no home publish.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AdapterContractMessage.InstallRootRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Invoke-SmokeValidate'
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove published toolkit files from InstallRoot. Stub - no filesystem writes.
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
        throw $script:AdapterContractMessage.InstallRootRequired
    }

    return New-AdapterNotImplementedResult -CommandName 'Uninstall-Toolkit'
}
