#Requires -Version 5.1
<#
.SYNOPSIS
  Cursor Uninstall-Toolkit (fail-closed stub — keyed uninstall out of MVP).
#>

function Invoke-CursorUninstallToolkit {
    <#
    .SYNOPSIS
      Remove published toolkit files from InstallRoot. Stub - out of adapter MVP scope.
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

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = 'Uninstall-Toolkit'
        Message     = ($script:CursorAdapterMessage.NotImplemented -f 'Uninstall-Toolkit')
        ExitCode    = 1
    }
}
