#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Grok Build adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot (core skill ids,
  core policy -> rules files, toolkit hook JSON/script). AGENTS.md is removed
  only when provenance confirms toolkit ownership (.toolkit-managed-publish.json
  sha256, or legacy hash match to core/router publish). Operator-edited AGENTS.md
  is preserved. Preserves alien skills/rules/hooks and config.toml.
#>

$script:GrokUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:GrokUninstallModuleDirectory)) {
    $script:GrokUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Script-scope load so Assert-PathUnderInstallRootForDelete is available
# (dotsource inside Invoke-* only defines commands in that function's local scope).
$_grokUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:GrokUninstallModuleDirectory)
) (Join-Path 'scripts' '_lib')
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_grokUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _grokUninstallLibDir -ErrorAction SilentlyContinue

function Get-GrokKnownToolkitArtifactPaths {
    <#
    .SYNOPSIS
      Enumerate InstallRoot paths owned by toolkit publish (keyed from core + known hooks/router).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $MappedPaths
    )

    $paths = New-Object System.Collections.Generic.List[string]

    $sourceSkillsRoot = Join-Path (Join-Path $RepoRoot $script:GrokAdapterConstant.CoreDirectoryName) $script:GrokAdapterConstant.SkillsDirectoryName
    if (Test-Path -LiteralPath $sourceSkillsRoot) {
        Get-ChildItem -LiteralPath $sourceSkillsRoot -Directory | ForEach-Object {
            try {
                $safeName = Assert-ToolkitManagedSkillName -SkillName $_.Name
            }
            catch {
                return
            }
            $candidate = Join-Path $MappedPaths.FixtureSkillsPath $safeName
            # Skill directories are intentionally not deletion candidates: the current
            # manifest records names only, not ownership of files within each directory.
        }
    }

    $sourcePolicyRoot = Join-Path (Join-Path $RepoRoot $script:GrokAdapterConstant.CoreDirectoryName) $script:GrokAdapterConstant.PolicyDirectoryName
    if (Test-Path -LiteralPath $sourcePolicyRoot) {
        Get-ChildItem -LiteralPath $sourcePolicyRoot -Recurse -File | ForEach-Object {
            $relative = $_.FullName.Substring($sourcePolicyRoot.Length).TrimStart('\', '/')
            $candidate = Join-Path $MappedPaths.FixtureRulesPath $relative
            if (Test-Path -LiteralPath $candidate) {
                $paths.Add([System.IO.Path]::GetFullPath($candidate))
            }
        }
    }

    # hooks/toolkit-session-start.json is shared host configuration. Remove only
    # the toolkit handlers below; keep operator properties and unrelated hooks.

    $hooksScript = Join-Path $MappedPaths.FixtureHooksPath $script:GrokAdapterConstant.HooksSessionStartScriptName
    if (Test-Path -LiteralPath $hooksScript) {
        $paths.Add([System.IO.Path]::GetFullPath($hooksScript))
    }

    $guardScript = Join-Path $MappedPaths.FixtureHooksPath $script:GrokAdapterConstant.HooksGuardPreToolScriptName
    if (Test-Path -LiteralPath $guardScript) {
        $paths.Add([System.IO.Path]::GetFullPath($guardScript))
    }

    $guardCommon = Join-Path $MappedPaths.FixtureHooksPath $script:GrokAdapterConstant.SharedGuardCommonFileName
    if (Test-Path -LiteralPath $guardCommon) {
        $paths.Add([System.IO.Path]::GetFullPath($guardCommon))
    }

    $authorizationContract = Join-Path $MappedPaths.FixtureHooksPath $script:GrokAdapterConstant.SharedAuthorizationContractFileName
    if (Test-Path -LiteralPath $authorizationContract) {
        $paths.Add([System.IO.Path]::GetFullPath($authorizationContract))
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

    return @($paths.ToArray())
}

function Remove-GrokToolkitHooksFromConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [switch] $WhatIf
    )

    # The shared config is retained, but its path must stay inside InstallRoot.
    # Validate before checking or reading it so a leaf/parent reparse point cannot
    # redirect either operation outside the adapter's resolved install boundary.
    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $Path -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $true }
    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $Path -InstallRoot $InstallRoot
    try { $payload = [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json }
    catch { throw "Grok hooks configuration is invalid; refusing to alter it: $Path. $($_.Exception.Message)" }
    $hookRoot = if ($payload.PSObject.Properties.Name -contains 'hooks') { $payload.hooks } else { $payload }
    $hooksDirectory = Split-Path -Parent $Path
    $managedCommandPaths = @(
        ([System.IO.Path]::GetFullPath((Join-Path $hooksDirectory $script:GrokAdapterConstant.HooksSessionStartScriptName)) -replace '\\', '/'),
        ([System.IO.Path]::GetFullPath((Join-Path $hooksDirectory $script:GrokAdapterConstant.HooksGuardPreToolScriptName)) -replace '\\', '/')
    )
    $changed = $false
    foreach ($eventName in @($hookRoot.PSObject.Properties.Name | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })) {
        $keptBlocks = New-Object System.Collections.Generic.List[object]
        foreach ($block in @($hookRoot.$eventName)) {
            if ($null -eq $block -or $block.PSObject.Properties.Name -notcontains 'hooks') { $keptBlocks.Add($block); continue }
            $entries = @($block.hooks)
            $keptEntries = @($entries | Where-Object {
                $command = [string]$_.command
                $isManagedCommand = $false
                foreach ($managedPath in $managedCommandPaths) {
                    if ($command.IndexOf($managedPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $isManagedCommand = $true; break }
                }
                -not $isManagedCommand
            })
            if ($keptEntries.Count -lt $entries.Count) { $changed = $true }
            if ($keptEntries.Count -gt 0) { $block.hooks = $keptEntries; $keptBlocks.Add($block) }
        }
        if ($keptBlocks.Count -eq 0) { $hookRoot.PSObject.Properties.Remove($eventName) }
        else { $hookRoot.PSObject.Properties[$eventName].Value = @($keptBlocks.ToArray()) }
    }
    if ($changed -and -not $WhatIf.IsPresent) {
        # Recheck immediately before writing; a shared config can be replaced after
        # the initial read by a file symlink or a junction in one of its ancestors.
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $Path -InstallRoot $InstallRoot
        $utf8 = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($Path, ($payload | ConvertTo-Json -Depth $script:GrokAdapterConstant.JsonConvertDepthDeep), $utf8)
    }
    return $true
}

function Invoke-GrokUninstallToolkit {
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

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    . (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')
    . (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') '_lib') 'ToolkitManagedPublishInventory.ps1')
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
$artifactHelper = Join-Path (Join-Path (Join-Path $repoRoot 'scripts') '_lib') 'ToolkitUninstallArtifacts.ps1'
    . $artifactHelper
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $hooksConfigPath = Join-Path $mapped.FixtureHooksPath $script:GrokAdapterConstant.HooksJsonFileName
    $null = Remove-GrokToolkitHooksFromConfig -Path $hooksConfigPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    $knownPaths = @(Get-GrokKnownToolkitArtifactPaths -RepoRoot $repoRoot -MappedPaths $mapped)
    $skillAudit = Get-ToolkitManagedSkillsUninstallAudit -DestinationSkillsRoots @($mapped.FixtureSkillsPath)
    $managedSkillResult = Remove-ToolkitManagedSkillsByInventory `
        -InstallRoot $resolvedInstallRoot `
        -DestinationSkillsRoots @($mapped.FixtureSkillsPath) `
        -SkillIds @($skillAudit.SkillIds) `
        -WhatIf:$WhatIf
    $preservedSkillPaths = @($managedSkillResult.PreservedPaths)
    $routerNotes = New-Object System.Collections.Generic.List[string]

    $agentsPath = $mapped.FixtureProjectAgentsPath
    $routerRemoveResult = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:GrokAdapterConstant.OfficialAgentsFileName `
        -CurrentFilePath $agentsPath `
        -ResolveExpectedPublishContent { Get-GrokRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome } `
        -WhatIf:$WhatIf
    if ($routerRemoveResult.Removed) {
        $knownPaths = @($knownPaths | Where-Object { -not [string]::Equals($_, [System.IO.Path]::GetFullPath($agentsPath), [System.StringComparison]::OrdinalIgnoreCase) })
    }
    elseif ($routerRemoveResult.WouldRemove) {
        # WhatIf: include AGENTS.md in would-remove set via separate flag below
    }
    elseif ($routerRemoveResult.Preserved -and -not [string]::IsNullOrWhiteSpace($routerRemoveResult.Message)) {
        $routerNotes.Add([string]$routerRemoveResult.Message) | Out-Null
    }

    # Fail-closed before WhatIf reporting or live delete (junction escape).
    foreach ($path in $knownPaths) {
        if (Test-Path -LiteralPath $path) {
            $null = Assert-PathUnderInstallRootForDelete -CandidatePath $path -InstallRoot $resolvedInstallRoot
        }
    }

    if ($WhatIf.IsPresent) {
        $artifactCleanup = Invoke-ToolkitUninstallArtifacts -Adapter 'grok' -InstallRoot $resolvedInstallRoot -RepoRoot $repoRoot -WhatIf:$WhatIf
        $wouldRemoveCount = $knownPaths.Count + $managedSkillResult.RemovedPaths.Count + $artifactCleanup.RemovedPaths.Count

        if ($routerRemoveResult.WouldRemove) {
            $wouldRemoveCount += 1
        }
        $message = if ($wouldRemoveCount -eq 0 -and $routerNotes.Count -eq 0) {
            ($script:GrokAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
        }
        else {
            ($script:GrokAdapterMessage.UninstallWhatIfOk -f $wouldRemoveCount, $resolvedInstallRoot)
        }
        if ($routerNotes.Count -gt 0) {
            $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
        }
        if ($preservedSkillPaths.Count -gt 0) { $message = '{0}; skill paths preserved: {1}' -f $message, ($preservedSkillPaths -join ', ') }
        if ($skillAudit.Notes.Count -gt 0) { $message = '{0}; {1}' -f $message, ($skillAudit.Notes -join '; ') }

        $whatIfPaths = @($knownPaths) + @($managedSkillResult.RemovedPaths)
        $whatIfPaths += @($artifactCleanup.RemovedPaths)
        if ($routerRemoveResult.WouldRemove) {
            $whatIfPaths += @([System.IO.Path]::GetFullPath($agentsPath))
        }

        return [PSCustomObject]@{
            Success         = ($artifactCleanup.Status -eq 'Complete')
            Implemented  = $true
            CommandName  = 'Uninstall-Toolkit'
        Status          = $artifactCleanup.Status
        IncompletePaths  = @($artifactCleanup.IncompletePaths)
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            RemovedPaths = @($whatIfPaths)
            PreservedPaths = @($preservedSkillPaths)
            RemovedCount = $wouldRemoveCount
            Message      = $message
            ExitCode        = $(if ($artifactCleanup.Status -eq 'Complete') { 0 } else { 1 })
        }
    }

    $removed = New-Object System.Collections.Generic.List[string]
    foreach ($path in $knownPaths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        # Re-assert immediately before delete (TOCTOU / junction escape).
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $path -InstallRoot $resolvedInstallRoot
        Remove-Item -LiteralPath $path -Recurse -Force
        $removed.Add($path)
    }

    $artifactCleanup = Invoke-ToolkitUninstallArtifacts -Adapter 'grok' -InstallRoot $resolvedInstallRoot -RepoRoot $repoRoot

    $removedArray = @($removed.ToArray()) + @($managedSkillResult.RemovedPaths) + @($artifactCleanup.RemovedPaths)
    if ($routerRemoveResult.Removed) {
        $removedArray += @([System.IO.Path]::GetFullPath($agentsPath))
    }
    $message = if ($removedArray.Count -eq 0 -and $routerNotes.Count -eq 0) {
        ($script:GrokAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
    }
    else {
        ($script:GrokAdapterMessage.UninstallOk -f $removedArray.Count, $resolvedInstallRoot)
    }
    if ($routerNotes.Count -gt 0) {
        $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
    }
    if ($preservedSkillPaths.Count -gt 0) { $message = '{0}; skill paths preserved: {1}' -f $message, ($preservedSkillPaths -join ', ') }
    if ($skillAudit.Notes.Count -gt 0) { $message = '{0}; {1}' -f $message, ($skillAudit.Notes -join '; ') }

    return [PSCustomObject]@{
        Success         = ($artifactCleanup.Status -eq 'Complete')
        Implemented  = $true
        CommandName  = 'Uninstall-Toolkit'
        Status          = $artifactCleanup.Status
        IncompletePaths  = @($artifactCleanup.IncompletePaths)
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        RemovedPaths = $removedArray
        PreservedPaths = @($preservedSkillPaths)
        RemovedCount = $removedArray.Count
        Message      = $message
        ExitCode        = $(if ($artifactCleanup.Status -eq 'Complete') { 0 } else { 1 })
    }
}
