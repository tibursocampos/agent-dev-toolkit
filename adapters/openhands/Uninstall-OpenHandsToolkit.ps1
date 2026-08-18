#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for OpenHands adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot (core skill ids
  under .agents/skills, toolkit .openhands hooks JSON/script, .plugin/plugin.json,
  core/agents roster markdown). AGENTS.md is removed only when provenance confirms
  toolkit ownership. Operator-edited AGENTS.md is preserved. Preserves alien
  skills/hooks/plugin/agents files. Does not wipe InstallRoot or sdd/.
#>

$script:OpenHandsUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenHandsUninstallModuleDirectory)) {
    $script:OpenHandsUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_openHandsUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:OpenHandsUninstallModuleDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_openHandsUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _openHandsUninstallLibDir -ErrorAction SilentlyContinue

function Get-OpenHandsKnownToolkitArtifactPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $MappedPaths
    )

    $paths = New-Object System.Collections.Generic.List[string]

    $sourceSkillsRoot = Join-Path (Join-Path $RepoRoot $script:OpenHandsAdapterConstant.CoreDirectoryName) $script:OpenHandsAdapterConstant.SkillsDirectoryName
    if (Test-Path -LiteralPath $sourceSkillsRoot) {
        Get-ChildItem -LiteralPath $sourceSkillsRoot -Directory | ForEach-Object {
            try {
                $safeName = Assert-ToolkitManagedSkillName -SkillName $_.Name
            }
            catch {
                return
            }
            $candidate = Join-Path $MappedPaths.FixtureSkillsPath $safeName
            if (Test-Path -LiteralPath $candidate) {
                $paths.Add([System.IO.Path]::GetFullPath($candidate))
            }
        }
    }

    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $RepoRoot
    if (Test-Path -LiteralPath $sourceAgentsRoot) {
        Get-ChildItem -LiteralPath $sourceAgentsRoot -File | ForEach-Object {
            $candidate = Join-Path $MappedPaths.FixtureCustomAgentsPath $_.Name
            if (Test-Path -LiteralPath $candidate) {
                $paths.Add([System.IO.Path]::GetFullPath($candidate))
            }
        }
    }

    $hooksJson = Join-Path $MappedPaths.FixtureHooksPath $script:OpenHandsAdapterConstant.HooksJsonFileName
    if (Test-Path -LiteralPath $hooksJson) {
        $paths.Add([System.IO.Path]::GetFullPath($hooksJson))
    }

    $hooksScript = Join-Path $MappedPaths.FixtureHooksScriptsPath $script:OpenHandsAdapterConstant.HooksSessionStartScriptName
    if (Test-Path -LiteralPath $hooksScript) {
        $paths.Add([System.IO.Path]::GetFullPath($hooksScript))
    }

    $pluginManifest = $MappedPaths.FixturePluginManifestPath
    if (Test-Path -LiteralPath $pluginManifest) {
        $paths.Add([System.IO.Path]::GetFullPath($pluginManifest))
    }

    return @($paths.ToArray())
}

function Invoke-OpenHandsUninstallToolkit {
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

    $repoRoot = Get-OpenHandsAdapterRepoRoot
    Initialize-OpenHandsInstallRootResolver
    . (Join-Path $repoRoot 'scripts\_lib\Copy-ToolkitManagedTree.ps1')
    . (Join-Path $repoRoot 'scripts\_lib\ToolkitManagedPublishInventory.ps1')
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $knownPaths = @(Get-OpenHandsKnownToolkitArtifactPaths -RepoRoot $repoRoot -MappedPaths $mapped)
    $routerNotes = New-Object System.Collections.Generic.List[string]

    $agentsPath = $mapped.FixtureProjectAgentsPath
    $routerRemoveResult = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:OpenHandsAdapterConstant.OfficialAgentsFileName `
        -CurrentFilePath $agentsPath `
        -ResolveExpectedPublishContent { Get-OpenHandsAgentsMdPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome } `
        -WhatIf:$WhatIf
    if ($routerRemoveResult.Removed) {
        $knownPaths = @($knownPaths | Where-Object { -not [string]::Equals($_, [System.IO.Path]::GetFullPath($agentsPath), [System.StringComparison]::OrdinalIgnoreCase) })
    }
    elseif ($routerRemoveResult.Preserved -and -not [string]::IsNullOrWhiteSpace($routerRemoveResult.Message)) {
        $routerNotes.Add([string]$routerRemoveResult.Message) | Out-Null
    }

    foreach ($path in $knownPaths) {
        if (Test-Path -LiteralPath $path) {
            $null = Assert-PathUnderInstallRootForDelete -CandidatePath $path -InstallRoot $resolvedInstallRoot
        }
    }

    if ($WhatIf.IsPresent) {
        $wouldRemoveCount = $knownPaths.Count
        if ($routerRemoveResult.WouldRemove) {
            $wouldRemoveCount += 1
        }
        $message = if ($wouldRemoveCount -eq 0 -and $routerNotes.Count -eq 0) {
            ($script:OpenHandsAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
        }
        else {
            ($script:OpenHandsAdapterMessage.UninstallWhatIfOk -f $wouldRemoveCount, $resolvedInstallRoot)
        }
        if ($routerNotes.Count -gt 0) {
            $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
        }

        $whatIfPaths = @($knownPaths)
        if ($routerRemoveResult.WouldRemove) {
            $whatIfPaths += @([System.IO.Path]::GetFullPath($agentsPath))
        }

        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Uninstall-Toolkit'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            RemovedPaths = @($whatIfPaths)
            RemovedCount = $wouldRemoveCount
            Message      = $message
            ExitCode     = 0
        }
    }

    $removed = New-Object System.Collections.Generic.List[string]
    foreach ($path in $knownPaths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $path -InstallRoot $resolvedInstallRoot
        Remove-Item -LiteralPath $path -Recurse -Force
        $removed.Add($path)
    }

    $removedArray = @($removed.ToArray())
    if ($routerRemoveResult.Removed) {
        $removedArray += @([System.IO.Path]::GetFullPath($agentsPath))
    }
    $message = if ($removedArray.Count -eq 0 -and $routerNotes.Count -eq 0) {
        ($script:OpenHandsAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
    }
    else {
        ($script:OpenHandsAdapterMessage.UninstallOk -f $removedArray.Count, $resolvedInstallRoot)
    }
    if ($routerNotes.Count -gt 0) {
        $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
    }

    return [PSCustomObject]@{
        Success      = $true
        Implemented  = $true
        CommandName  = 'Uninstall-Toolkit'
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        RemovedPaths = $removedArray
        RemovedCount = $removedArray.Count
        Message      = $message
        ExitCode     = 0
    }
}
