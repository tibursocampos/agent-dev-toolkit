#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Hermes Publish-Hooks (documented no-op; hooks=false).
#>

function Invoke-HermesPublishHooks {
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

    $repoRoot = Get-HermesAdapterRepoRoot
    Initialize-HermesInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $hooksDirectory = $mapped.FixtureHooksPath

    $message = if ($WhatIf.IsPresent) {
        ($script:HermesAdapterMessage.HooksWhatIfOk -f $hooksDirectory)
    }
    else {
        ($script:HermesAdapterMessage.HooksNoOp -f $resolvedInstallRoot)
    }

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        Skipped     = $true
        NoOp        = $true
        CommandName = 'Publish-Hooks'
        WhatIf      = [bool]$WhatIf.IsPresent
        InstallRoot = $resolvedInstallRoot
        HooksRoot   = $hooksDirectory
        HooksPath   = $null
        Message     = $message
        ExitCode    = 0
    }
}
