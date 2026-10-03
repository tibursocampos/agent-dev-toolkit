#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Hermes adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot (core skill ids).
  Removes only the marked toolkit guidance section from AGENTS.md, preserving
  unrelated operator content. Legacy whole-file installs still require hash proof.
  Also removes plugins/agent-dev-toolkit-guard and agent-hooks toolkit files,
  and reverse-merges keyed plugins.enabled / hooks.pre_tool_call entries in
  config.yaml without touching other keys (gateway/tokens preserved).
  Preserves alien skills, config.yaml secrets, MEMORY.md, SOUL.md, sdd/sessions,
  and sdd/manifest.json. Never wipes InstallRoot.
#>

$script:HermesUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:HermesUninstallModuleDirectory)) {
    $script:HermesUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_hermesUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:HermesUninstallModuleDirectory)
) (Join-Path 'scripts' '_lib')
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_hermesUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _hermesUninstallLibDir -ErrorAction SilentlyContinue

function Get-HermesKnownToolkitArtifactPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $MappedPaths
    )

    $paths = New-Object System.Collections.Generic.List[string]

    $sourceSkillsRoot = Join-Path (Join-Path $RepoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.SkillsDirectoryName
    if (Test-Path -LiteralPath $sourceSkillsRoot) {
        Get-ChildItem -LiteralPath $sourceSkillsRoot -Directory | ForEach-Object {
            try {
                $safeName = Assert-ToolkitManagedSkillName -SkillName $_.Name
            }
            catch {
                return
            }
            $candidate = Join-Path $MappedPaths.FixtureSkillsPath $safeName
            # Names-only manifests cannot authorize recursive deletion of skill contents.
        }
    }

    $pluginRoot = Join-Path $MappedPaths.FixturePluginsPath $script:HermesAdapterConstant.GuardPluginDirectoryName
    if (Test-Path -LiteralPath $pluginRoot) {
        $paths.Add([System.IO.Path]::GetFullPath($pluginRoot))
    }

    foreach ($hookFile in @($script:HermesAdapterConstant.SmokeExpectedAgentHookFileNames)) {
        $candidate = Join-Path $MappedPaths.FixtureAgentHooksPath $hookFile
        if (Test-Path -LiteralPath $candidate) {
            $paths.Add([System.IO.Path]::GetFullPath($candidate))
        }
    }

    return @($paths.ToArray())
}

function Remove-HermesToolkitConfigYamlKeys {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $ConfigPath,
        [Parameter(Mandatory = $true)][string] $PluginName,
        [Parameter()][switch] $WhatIf
    )

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return $false
    }

    $text = [System.IO.File]::ReadAllText($ConfigPath)
    $original = $text
    $escaped = [regex]::Escape($PluginName)
    $text = [regex]::Replace($text, ("(?m)^\s*-\s*{0}\s*\r?\n?" -f $escaped), '')

    if (Get-Command -Name Remove-HermesToolkitPreToolCallEntries -ErrorAction SilentlyContinue) {
        $text = Remove-HermesToolkitPreToolCallEntries -YamlText $text
    }
    else {
        $pattern = '(?ms)^\s*-\s*matcher:\s*["'']?terminal\|write_file\|patch["'']?\s*\r?\n(?:\s+[^\r\n]*\r?\n)*?\s*command:\s*[^\r\n]*guard-pre-tool[^\r\n]*\r?\n(?:\s+[^\r\n]*\r?\n)*?'
        $text = [regex]::Replace($text, $pattern, '')
    }

    if ($text -eq $original) {
        return $false
    }

    if ($WhatIf.IsPresent) {
        return $true
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($ConfigPath, $text, $utf8)
    return $true
}

function Invoke-HermesUninstallToolkit {
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
    $resolveScript = Join-Path $repoRoot ($script:HermesAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:HermesAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    . (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')
    . (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') '_lib') 'ToolkitManagedPublishInventory.ps1')
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $knownPaths = @(Get-HermesKnownToolkitArtifactPaths -RepoRoot $repoRoot -MappedPaths $mapped)
    $skillAudit = Get-ToolkitManagedSkillsUninstallAudit -DestinationSkillsRoots @($mapped.FixtureSkillsPath)
    $managedSkillResult = Remove-ToolkitManagedSkillsByInventory `
        -InstallRoot $resolvedInstallRoot `
        -DestinationSkillsRoots @($mapped.FixtureSkillsPath) `
        -SkillIds @($skillAudit.SkillIds) `
        -WhatIf:$WhatIf
    $preservedSkillPaths = @($managedSkillResult.PreservedPaths)
    $routerNotes = New-Object System.Collections.Generic.List[string]

    $configTouched = Remove-HermesToolkitConfigYamlKeys `
        -ConfigPath $mapped.FixtureConfigYamlPath `
        -PluginName $script:HermesAdapterConstant.GuardPluginDirectoryName `
        -WhatIf:$WhatIf
    if ($configTouched) {
        $routerNotes.Add(('config.yaml keyed plugins.enabled / hooks.pre_tool_call reverse-merge ({0})' -f $mapped.FixtureConfigYamlPath)) | Out-Null
    }

    $agentsPath = $mapped.FixtureProjectAgentsPath
    $routerRemoveResult = $null
    if (Test-Path -LiteralPath $agentsPath) {
        $agentsText = [System.IO.File]::ReadAllText($agentsPath)
        $beginMarker = [string]$script:HermesAdapterConstant.ManagedAgentsBeginMarker
        $endMarker = [string]$script:HermesAdapterConstant.ManagedAgentsEndMarker
        $beginCount = ([regex]::Matches($agentsText, [regex]::Escape($beginMarker))).Count
        $endCount = ([regex]::Matches($agentsText, [regex]::Escape($endMarker))).Count
        if ($beginCount -ne $endCount -or $beginCount -gt 1) {
            throw 'Hermes AGENTS.md contains ambiguous managed guidance markers; refusing to uninstall.'
        }
        if ($beginCount -eq 1) {
            $pattern = '(?ms)(?:\r?\n)?' + [regex]::Escape($beginMarker) + '.*?' + [regex]::Escape($endMarker) + '\r?\n?'
            $remaining = [regex]::Replace($agentsText, $pattern, '', 1)
            if (-not $WhatIf.IsPresent) {
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                if ([string]::IsNullOrWhiteSpace($remaining)) {
                    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $agentsPath -InstallRoot $resolvedInstallRoot
                    Remove-Item -LiteralPath $agentsPath -Force
                    $null = Remove-ToolkitManagedPublishInventoryEntry -InstallRoot $resolvedInstallRoot -RelativePath $script:HermesAdapterConstant.OfficialAgentsFileName
                    $removedAgents = $true
                }
                else {
                    $null = Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $agentsPath -InstallRoot $resolvedInstallRoot
                    $tempPath = $agentsPath + '.adt-tmp-' + [Guid]::NewGuid().ToString('N')
                    try {
                        Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $tempPath -InstallRoot $resolvedInstallRoot
                        [System.IO.File]::WriteAllText($tempPath, $remaining, $utf8NoBom)
                        Move-Item -LiteralPath $tempPath -Destination $agentsPath -Force -ErrorAction Stop
                    }
                    finally {
                        if (Test-Path -LiteralPath $tempPath) {
                            $null = Assert-PathUnderInstallRootForDelete -CandidatePath $tempPath -InstallRoot $resolvedInstallRoot
                            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
                        }
                    }
                    $null = Remove-ToolkitManagedPublishInventoryEntry -InstallRoot $resolvedInstallRoot -RelativePath $script:HermesAdapterConstant.OfficialAgentsFileName
                    $removedAgents = $false
                }
            }
            else { $removedAgents = [string]::IsNullOrWhiteSpace($remaining) }
            $routerRemoveResult = [PSCustomObject]@{ Removed=$removedAgents; WouldRemove=($WhatIf.IsPresent -and $removedAgents); Preserved=$false; RelativePath=$script:HermesAdapterConstant.OfficialAgentsFileName; CurrentFilePath=$agentsPath; Message=$null }
        }
    }
    if ($null -eq $routerRemoveResult) {
        # Compatibility for prior versions that published AGENTS.md as a whole file.
        $routerRemoveResult = Remove-ToolkitManagedWholeFileRouterIfOwned `
            -InstallRoot $resolvedInstallRoot `
            -RelativePath $script:HermesAdapterConstant.OfficialAgentsFileName `
            -CurrentFilePath $agentsPath `
            -ResolveExpectedPublishContent { Get-HermesAgentsMdPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome } `
            -WhatIf:$WhatIf
    }
    if ($routerRemoveResult.Removed) {
        $knownPaths = @($knownPaths | Where-Object { -not [string]::Equals($_, [System.IO.Path]::GetFullPath($agentsPath), [System.StringComparison]::OrdinalIgnoreCase) })
    }
    elseif ($routerRemoveResult.WouldRemove) {
        # WhatIf: include AGENTS.md in would-remove set via separate flag below
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
        $wouldRemoveCount = $knownPaths.Count + $managedSkillResult.RemovedPaths.Count
        if ($routerRemoveResult.WouldRemove) {
            $wouldRemoveCount += 1
        }
        $message = if ($wouldRemoveCount -eq 0 -and $routerNotes.Count -eq 0) {
            ($script:HermesAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
        }
        else {
            ($script:HermesAdapterMessage.UninstallWhatIfOk -f $wouldRemoveCount, $resolvedInstallRoot)
        }
        if ($routerNotes.Count -gt 0) {
            $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
        }
        if ($preservedSkillPaths.Count -gt 0) { $message = '{0}; skill paths preserved: {1}' -f $message, ($preservedSkillPaths -join ', ') }
        if ($skillAudit.Notes.Count -gt 0) { $message = '{0}; {1}' -f $message, ($skillAudit.Notes -join '; ') }

        $whatIfPaths = @($knownPaths) + @($managedSkillResult.RemovedPaths)
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
            PreservedPaths = @($preservedSkillPaths)
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

    $removedArray = @($removed.ToArray()) + @($managedSkillResult.RemovedPaths)
    if ($routerRemoveResult.Removed) {
        $removedArray += @([System.IO.Path]::GetFullPath($agentsPath))
    }
    $message = if ($removedArray.Count -eq 0 -and $routerNotes.Count -eq 0) {
        ($script:HermesAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
    }
    else {
        ($script:HermesAdapterMessage.UninstallOk -f $removedArray.Count, $resolvedInstallRoot)
    }
    if ($routerNotes.Count -gt 0) {
        $message = '{0}; {1}' -f $message, ($routerNotes -join '; ')
    }
    if ($preservedSkillPaths.Count -gt 0) { $message = '{0}; skill paths preserved: {1}' -f $message, ($preservedSkillPaths -join ', ') }
    if ($skillAudit.Notes.Count -gt 0) { $message = '{0}; {1}' -f $message, ($skillAudit.Notes -join '; ') }

    return [PSCustomObject]@{
        Success      = $true
        Implemented  = $true
        CommandName  = 'Uninstall-Toolkit'
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        RemovedPaths = $removedArray
        PreservedPaths = @($preservedSkillPaths)
        RemovedCount = $removedArray.Count
        Message      = $message
        ExitCode     = 0
    }
}
