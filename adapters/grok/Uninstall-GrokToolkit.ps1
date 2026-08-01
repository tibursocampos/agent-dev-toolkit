#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Grok Build adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot (core skill ids,
  core policy -> rules files, toolkit hook JSON/script, AGENTS.md).
  Preserves alien skills/rules/hooks and config.toml. Does not wipe .grok.
#>

$script:GrokUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:GrokUninstallModuleDirectory)) {
    $script:GrokUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Script-scope load so Assert-PathUnderInstallRootForDelete is available
# (dotsource inside Invoke-* only defines commands in that function's local scope).
$_grokUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:GrokUninstallModuleDirectory)
) 'scripts\_lib'
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
            $candidate = Join-Path $MappedPaths.FixtureSkillsPath $_.Name
            if (Test-Path -LiteralPath $candidate) {
                $paths.Add([System.IO.Path]::GetFullPath($candidate))
            }
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

    $hooksJson = Join-Path $MappedPaths.FixtureHooksPath $script:GrokAdapterConstant.HooksJsonFileName
    if (Test-Path -LiteralPath $hooksJson) {
        $paths.Add([System.IO.Path]::GetFullPath($hooksJson))
    }

    $hooksScript = Join-Path $MappedPaths.FixtureHooksPath $script:GrokAdapterConstant.HooksSessionStartScriptName
    if (Test-Path -LiteralPath $hooksScript) {
        $paths.Add([System.IO.Path]::GetFullPath($hooksScript))
    }

    if (Test-Path -LiteralPath $MappedPaths.FixtureProjectAgentsPath) {
        $paths.Add([System.IO.Path]::GetFullPath($MappedPaths.FixtureProjectAgentsPath))
    }

    return @($paths.ToArray())
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
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $knownPaths = @(Get-GrokKnownToolkitArtifactPaths -RepoRoot $repoRoot -MappedPaths $mapped)

    # Fail-closed before WhatIf reporting or live delete (junction escape).
    foreach ($path in $knownPaths) {
        if (Test-Path -LiteralPath $path) {
            $null = Assert-PathUnderInstallRootForDelete -CandidatePath $path -InstallRoot $resolvedInstallRoot
        }
    }

    if ($WhatIf.IsPresent) {
        $message = if ($knownPaths.Count -eq 0) {
            ($script:GrokAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
        }
        else {
            ($script:GrokAdapterMessage.UninstallWhatIfOk -f $knownPaths.Count, $resolvedInstallRoot)
        }

        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Uninstall-Toolkit'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            RemovedPaths = @($knownPaths)
            RemovedCount = $knownPaths.Count
            Message      = $message
            ExitCode     = 0
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

    $removedArray = @($removed.ToArray())
    $message = if ($removedArray.Count -eq 0) {
        ($script:GrokAdapterMessage.UninstallNothingFound -f $resolvedInstallRoot)
    }
    else {
        ($script:GrokAdapterMessage.UninstallOk -f $removedArray.Count, $resolvedInstallRoot)
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

