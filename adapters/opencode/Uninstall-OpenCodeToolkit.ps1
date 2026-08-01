#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for OpenCode adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot:
  - skills/<id> folders that match core/skills (including _shared)
  - AGENTS.md at InstallRoot root (Publish-Router target) when provenance confirms toolkit ownership
    (.toolkit-managed-publish.json sha256, or legacy hash match to core/router publish)
  - plugins/agent-dev-toolkit-marker.js (Decision A Publish-Hooks)

  Operator-edited or drifted AGENTS.md is preserved.

  Does not wipe InstallRoot, skills/, plugins/, or alien files (RN07 / CU03).
  Uses Resolve-InstallRoot (USERPROFILE guard; -AllowUserHome opt-in).
#>

$script:OpenCodeUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenCodeUninstallModuleDirectory)) {
    $script:OpenCodeUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_opencodeUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:OpenCodeUninstallModuleDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_opencodeUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _opencodeUninstallLibDir -ErrorAction SilentlyContinue

function Get-OpenCodeUninstallRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-OpenCodeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-OpenCodeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:OpenCodeUninstallModuleDirectory))
}

function Get-OpenCodeManagedSkillIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $coreSkillsRoot = Join-Path (
        Join-Path $RepoRoot $script:OpenCodePathConstant.CoreDirectoryName
    ) $script:OpenCodePathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force |
            Select-Object -ExpandProperty Name
    )
}

function Remove-OpenCodePathIfPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf,

        [Parameter()]
        [switch] $Recurse
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $Path -InstallRoot $InstallRoot

    if ($WhatIf.IsPresent) {
        return $true
    }

    if ($Recurse.IsPresent) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    else {
        Remove-Item -LiteralPath $Path -Force
    }

    return $true
}

function Invoke-OpenCodeUninstallToolkit {
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
        throw $script:OpenCodeUninstallMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenCodeUninstallRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    . (Join-Path $libDir 'ToolkitManagedPublishInventory.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $removedPaths = New-Object System.Collections.Generic.List[string]
    $wouldRemovePaths = New-Object System.Collections.Generic.List[string]
    $routerNotes = New-Object System.Collections.Generic.List[string]

    $skillsRoot = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.SkillsDirectoryName
    $managedSkillIds = Get-OpenCodeManagedSkillIds -RepoRoot $repoRoot
    foreach ($rawSkillId in $managedSkillIds) {
        try {
            $skillId = Assert-ToolkitManagedSkillName -SkillName $rawSkillId
        }
        catch {
            continue
        }
        $skillPath = Join-Path $skillsRoot $skillId
        $wouldRemove = Remove-OpenCodePathIfPresent -Path $skillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
        if ($wouldRemove) {
            $wouldRemovePaths.Add($skillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($skillPath) | Out-Null
            }
        }
    }

    $agentsPath = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.AgentsFileName
    $routerRemoveResult = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:OpenCodePathConstant.AgentsFileName `
        -CurrentFilePath $agentsPath `
        -ResolveExpectedPublishContent { Get-OpenCodeRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome } `
        -WhatIf:$WhatIf
    if ($routerRemoveResult.Removed -or $routerRemoveResult.WouldRemove) {
        $wouldRemovePaths.Add($agentsPath) | Out-Null
        if ($routerRemoveResult.Removed) {
            $removedPaths.Add($agentsPath) | Out-Null
        }
    }
    elseif ($routerRemoveResult.Preserved -and -not [string]::IsNullOrWhiteSpace($routerRemoveResult.Message)) {
        $routerNotes.Add([string]$routerRemoveResult.Message) | Out-Null
    }

    $pluginMarkerPath = Join-Path (
        Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.PluginsDirectoryName
    ) $script:OpenCodePathConstant.PluginMarkerFileName
    $wouldRemovePlugin = Remove-OpenCodePathIfPresent -Path $pluginMarkerPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    if ($wouldRemovePlugin) {
        $wouldRemovePaths.Add($pluginMarkerPath) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add($pluginMarkerPath) | Out-Null
        }
    }

    $message = if ($WhatIf.IsPresent) {
        $script:OpenCodeUninstallMessage.WhatIfOk -f $wouldRemovePaths.Count, $resolvedInstallRoot
    }
    else {
        $script:OpenCodeUninstallMessage.RemovedOk -f $removedPaths.Count, $resolvedInstallRoot
    }
    if ($routerNotes.Count -gt 0) {
        $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
    }

    return [PSCustomObject]@{
        Success             = $true
        Implemented         = $true
        CommandName         = 'Uninstall-Toolkit'
        WhatIf              = [bool]$WhatIf.IsPresent
        InstallRoot         = $resolvedInstallRoot
        RemovedCount        = $(if ($WhatIf.IsPresent) { $wouldRemovePaths.Count } else { $removedPaths.Count })
        RemovedPaths        = $(if ($WhatIf.IsPresent) { @($wouldRemovePaths.ToArray()) } else { @($removedPaths.ToArray()) })
        ManagedSkillIds     = @($managedSkillIds)
        KeyedOnly           = $true
        WholesaleWipe       = $false
        Message             = $message
        ExitCode            = 0
    }
}
