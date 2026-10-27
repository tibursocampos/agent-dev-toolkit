#Requires -Version 5.1
<##
.SYNOPSIS
  Resolve the active installation's SDD runtime root.

.DESCRIPTION
  Runtime scripts are published beneath <InstallRoot>/scripts/<area>. Unless a
  caller supplies an explicit root (primarily for isolated tests), SDD state is
  always resolved to <InstallRoot>/sdd and never to a user-profile fallback.
##>
[CmdletBinding()]
param()

function Resolve-EffectiveSddRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ScriptDirectory,

        [Parameter()]
        [string] $ExplicitSddRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitSddRoot)) {
        return [System.IO.Path]::GetFullPath($ExplicitSddRoot)
    }

    $resolvedScriptDirectory = [System.IO.Path]::GetFullPath($ScriptDirectory)
    $scriptsDirectory = [System.IO.DirectoryInfo]::new($resolvedScriptDirectory).Parent
    if ($null -eq $scriptsDirectory -or $scriptsDirectory.Name -ine 'scripts') {
        throw ("Cannot resolve effective SDD root from runtime directory '{0}'; expected <InstallRoot>/scripts/<area>." -f $resolvedScriptDirectory)
    }

    $installRoot = $scriptsDirectory.Parent
    if ($null -eq $installRoot) {
        throw ("Cannot resolve InstallRoot from runtime directory '{0}'." -f $resolvedScriptDirectory)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $installRoot.FullName 'sdd'))
}
