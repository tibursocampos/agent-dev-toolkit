#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Codex adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot:
  - plugin/.codex-plugin/plugin.json (and empty .codex-plugin dir)
  - plugin/skills/<id> matching core/skills
  - InstallRoot/skills/<id> matching core/skills (Codex $ discovery home mirror)
  - plugin/hooks/hooks.json + session_start.ps1
  - marketplace entry named agent-dev-toolkit (rewrite or remove catalog)
  - USER-scope skills/<id> matching core/skills (fixture InstallRoot/.agents/skills,
    or live $HOME/.agents/skills when InstallRoot is ~/.codex with -AllowUserHome)
  - rules/<file> matching core/policy (Publish-Policy)
  - InstallRoot/AGENTS.md (Publish-Router target) when provenance confirms toolkit ownership
    (.toolkit-managed-publish.json sha256, or legacy hash match to core/router publish)

  Operator-edited or drifted AGENTS.md is preserved.

  Does not wipe InstallRoot, plugin/, .agents/, skills/, or alien files (RN07 / CU03).
  Live ~/.codex requires -AllowUserHome. Uses Resolve-InstallRoot (USERPROFILE guard).
#>

$script:CodexUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CodexUninstallModuleDirectory)) {
    $script:CodexUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_codexUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CodexUninstallModuleDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_codexUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _codexUninstallLibDir -ErrorAction SilentlyContinue

function Get-CodexUninstallRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-CodexAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-CodexAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:CodexUninstallModuleDirectory))
}

function Get-CodexManagedSkillIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $coreSkillsRoot = Join-Path (
        Join-Path $RepoRoot $script:CodexPathConstant.CoreDirectoryName
    ) $script:CodexPathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force |
            Select-Object -ExpandProperty Name
    )
}

function Get-CodexManagedRuleRelativePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $corePolicyRoot = Join-Path (
        Join-Path $RepoRoot $script:CodexPathConstant.CoreDirectoryName
    ) $script:CodexPathConstant.PolicyDirectoryName

    if (-not (Test-Path -LiteralPath $corePolicyRoot)) {
        return @()
    }

    $paths = New-Object System.Collections.Generic.List[string]
    $files = Get-ChildItem -LiteralPath $corePolicyRoot -Recurse -File -Force
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($corePolicyRoot.Length).TrimStart('\', '/')
        $paths.Add($relative) | Out-Null
    }

    return @($paths.ToArray())
}

function Remove-CodexPathIfPresent {
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

function Remove-CodexEmptyDirectoryIfPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $remaining = @(Get-ChildItem -LiteralPath $Path -Force)
    if ($remaining.Count -gt 0) {
        return $false
    }

    return (Remove-CodexPathIfPresent -Path $Path -InstallRoot $InstallRoot -WhatIf:$WhatIf)
}

function Update-CodexMarketplaceRemoveToolkitEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $MarketplacePath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf
    )

    if (-not (Test-Path -LiteralPath $MarketplacePath)) {
        return $false
    }

    $raw = [System.IO.File]::ReadAllText($MarketplacePath)
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return (Remove-CodexPathIfPresent -Path $MarketplacePath -InstallRoot $InstallRoot -WhatIf:$WhatIf)
    }

    try {
        $catalog = $raw | ConvertFrom-Json
    }
    catch {
        # Unknown / corrupt catalog authored outside toolkit - leave untouched (RN07).
        return $false
    }

    $plugins = @()
    if ($null -ne $catalog.plugins) {
        $plugins = @($catalog.plugins)
    }

    $toolkitName = $script:CodexPathConstant.PluginName
    $remaining = @(
        $plugins | Where-Object {
            -not (
                $null -ne $_.name -and
                [string]::Equals([string]$_.name, $toolkitName, [System.StringComparison]::OrdinalIgnoreCase)
            )
        }
    )

    if ($remaining.Count -eq $plugins.Count) {
        return $false
    }

    if ($WhatIf.IsPresent) {
        return $true
    }

    if ($remaining.Count -eq 0) {
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $MarketplacePath -InstallRoot $InstallRoot
        Remove-Item -LiteralPath $MarketplacePath -Force
        return $true
    }

    $catalog | Add-Member -MemberType NoteProperty -Name plugins -Value $remaining -Force
    $json = ($catalog | ConvertTo-Json -Depth 8)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($MarketplacePath, $json, $utf8NoBom)
    return $true
}

function Invoke-CodexUninstallToolkit {
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
        throw $script:CodexUninstallMessage.InstallRootRequired
    }

    $repoRoot = Get-CodexUninstallRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    . (Join-Path $libDir 'ToolkitManagedPublishInventory.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $removedPaths = New-Object System.Collections.Generic.List[string]
    $wouldRemovePaths = New-Object System.Collections.Generic.List[string]
    $routerNotes = New-Object System.Collections.Generic.List[string]
    $managedSkillIds = Get-CodexManagedSkillIds -RepoRoot $repoRoot

    $pluginRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.PluginRootDirectoryName
    $pluginSkillsRoot = Join-Path $pluginRoot $script:CodexPathConstant.SkillsDirectoryName
    $homeSkillsRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.HomeSkillsRelativePath
    $pluginHooksRoot = Join-Path $pluginRoot $script:CodexPathConstant.HooksDirectoryName
    $pluginManifestDir = Join-Path $pluginRoot $script:CodexPathConstant.PluginManifestDirectoryName
    $pluginManifestPath = Join-Path $pluginManifestDir $script:CodexPathConstant.PluginManifestFileName
    $userSkillsRoot = Resolve-CodexUserSkillsRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $userSkillsContainmentRoot = Resolve-CodexUserSkillsContainmentRoot -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $rulesRoot = Join-Path $resolvedInstallRoot $script:CodexPathConstant.RulesDirectoryName
    $agentsPath = Join-Path $resolvedInstallRoot $script:CodexPathConstant.AgentsFileName
    $marketplacePath = Join-Path (
        Join-Path (
            Join-Path $resolvedInstallRoot $script:CodexPathConstant.AgentsDirectoryName
        ) $script:CodexPathConstant.PluginsDirectoryName
    ) $script:CodexPathConstant.MarketplaceFileName

    $wouldRemoveMarketplace = Update-CodexMarketplaceRemoveToolkitEntry -MarketplacePath $marketplacePath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    if ($wouldRemoveMarketplace) {
        $wouldRemovePaths.Add($marketplacePath) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add($marketplacePath) | Out-Null
        }
    }

    foreach ($rawSkillId in $managedSkillIds) {
        try {
            $skillId = Assert-ToolkitManagedSkillName -SkillName $rawSkillId
        }
        catch {
            continue
        }
        $pluginSkillPath = Join-Path $pluginSkillsRoot $skillId
        $wouldRemove = Remove-CodexPathIfPresent -Path $pluginSkillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
        if ($wouldRemove) {
            $wouldRemovePaths.Add($pluginSkillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($pluginSkillPath) | Out-Null
            }
        }

        $homeSkillPath = Join-Path $homeSkillsRoot $skillId
        $wouldRemoveHome = Remove-CodexPathIfPresent -Path $homeSkillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
        if ($wouldRemoveHome) {
            $wouldRemovePaths.Add($homeSkillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($homeSkillPath) | Out-Null
            }
        }

        $userSkillPath = Join-Path $userSkillsRoot $skillId
        $wouldRemoveUser = Remove-CodexPathIfPresent -Path $userSkillPath -InstallRoot $userSkillsContainmentRoot -WhatIf:$WhatIf -Recurse
        if ($wouldRemoveUser) {
            $wouldRemovePaths.Add($userSkillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($userSkillPath) | Out-Null
            }
        }
    }

    foreach ($ruleRelative in (Get-CodexManagedRuleRelativePaths -RepoRoot $repoRoot)) {
        $rulePath = Join-Path $rulesRoot ($ruleRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $wouldRemoveRule = Remove-CodexPathIfPresent -Path $rulePath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($wouldRemoveRule) {
            $wouldRemovePaths.Add($rulePath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($rulePath) | Out-Null
            }
        }
    }

    $hooksJsonPath = Join-Path $pluginHooksRoot $script:CodexPathConstant.HooksFileName
    $hooksScriptPath = Join-Path $pluginHooksRoot $script:CodexPathConstant.HooksSessionStartScriptName
    foreach ($hooksPath in @($hooksJsonPath, $hooksScriptPath)) {
        $wouldRemoveHooks = Remove-CodexPathIfPresent -Path $hooksPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($wouldRemoveHooks) {
            $wouldRemovePaths.Add($hooksPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($hooksPath) | Out-Null
            }
        }
    }

    $wouldRemoveManifest = Remove-CodexPathIfPresent -Path $pluginManifestPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    if ($wouldRemoveManifest) {
        $wouldRemovePaths.Add($pluginManifestPath) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add($pluginManifestPath) | Out-Null
        }
    }

    $wouldRemoveManifestDir = Remove-CodexEmptyDirectoryIfPresent -Path $pluginManifestDir -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    if ($wouldRemoveManifestDir) {
        $wouldRemovePaths.Add($pluginManifestDir) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add($pluginManifestDir) | Out-Null
        }
    }

    $routerRemoveResult = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:CodexPathConstant.AgentsFileName `
        -CurrentFilePath $agentsPath `
        -ResolveExpectedPublishContent { Get-CodexRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome } `
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

    $count = if ($WhatIf.IsPresent) { $wouldRemovePaths.Count } else { $removedPaths.Count }
    $message = if ($WhatIf.IsPresent) {
        if ($count -eq 0) {
            $script:CodexUninstallMessage.NothingFound -f $resolvedInstallRoot
        }
        else {
            $script:CodexUninstallMessage.WhatIfOk -f $count, $resolvedInstallRoot
        }
    }
    elseif ($count -eq 0) {
        $script:CodexUninstallMessage.NothingFound -f $resolvedInstallRoot
    }
    else {
        $script:CodexUninstallMessage.RemovedOk -f $count, $resolvedInstallRoot
    }
    if ($routerNotes.Count -gt 0) {
        $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
    }

    return [PSCustomObject]@{
        Success         = $true
        Implemented     = $true
        CommandName     = 'Uninstall-Toolkit'
        WhatIf          = [bool]$WhatIf.IsPresent
        InstallRoot     = $resolvedInstallRoot
        RemovedCount    = $count
        RemovedPaths    = $(if ($WhatIf.IsPresent) { @($wouldRemovePaths.ToArray()) } else { @($removedPaths.ToArray()) })
        ManagedSkillIds = @($managedSkillIds)
        KeyedOnly       = $true
        WholesaleWipe   = $false
        Message         = $message
        ExitCode        = 0
    }
}
