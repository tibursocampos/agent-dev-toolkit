#Requires -Version 5.1
<#
.SYNOPSIS
  Resolve default fixture InstallRoot from adapter Get-InstallRoots (fail-closed).

.DESCRIPTION
  When Get-InstallRoots is present after the adapter module is loaded, any failure
  or missing FixtureRelativePath throws — never falls back to the Cursor-shaped
  DefaultFixtureInstallRootRel. Missing Get-InstallRoots after module load also throws.
#>

if (-not (Get-Variable -Scope Script -Name ToolkitConstant -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'ToolkitConstants.ps1')
}

function Resolve-AdapterFixtureInstallRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        throw $script:ToolkitMessage.FromPathRequired
    }

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw ($script:ToolkitMessage.AgentRequired -f '(none)')
    }

    $getInstallRoots = Get-Command -Name Get-InstallRoots -ErrorAction SilentlyContinue
    if ($null -eq $getInstallRoots) {
        throw ($script:ToolkitMessage.AdapterFixtureCommandMissing -f $AgentId)
    }

    $installRootsInfo = $null
    try {
        $installRootsInfo = Get-InstallRoots -AgentId $AgentId
    }
    catch {
        throw ($script:ToolkitMessage.AdapterFixtureRootsFailed -f $AgentId, $_.Exception.Message)
    }

    $fixtureRelative = $null
    if ($null -ne $installRootsInfo -and
        $installRootsInfo.PSObject.Properties.Name -contains 'FixtureRelativePath' -and
        -not [string]::IsNullOrWhiteSpace([string]$installRootsInfo.FixtureRelativePath)) {
        $fixtureRelative = [string]$installRootsInfo.FixtureRelativePath
    }

    if ([string]::IsNullOrWhiteSpace($fixtureRelative)) {
        throw ($script:ToolkitMessage.AdapterFixturePathMissing -f $AgentId)
    }

    return (Join-Path $RepoRoot ($fixtureRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar))
}
