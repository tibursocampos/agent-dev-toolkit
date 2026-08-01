#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Antigravity adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot (models ~/.gemini):
  - config/skills/<id> folders matching core/skills
  - config/skills/dev_persona
  - config/plugins/agent-dev-toolkit (GUARDRAILS)
  - managed entry id in config/skills.json
  - managed begin/end blocks in config/AGENTS.md and config/GEMINI.md

  Does not wipe InstallRoot, config/hooks, alien skills, or the legacy
  antigravity-ide/plugins bridge. Uses Resolve-InstallRoot (USERPROFILE guard).
#>

$script:AntigravityUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:AntigravityUninstallModuleDirectory)) {
    $script:AntigravityUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_antigravityUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:AntigravityUninstallModuleDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_antigravityUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _antigravityUninstallLibDir -ErrorAction SilentlyContinue

$script:AntigravityUninstallMessage = @{
    InstallRootRequired = 'InstallRoot is required.'
    WhatIfOk            = 'Antigravity Uninstall-Toolkit: WhatIf - would remove {0} managed path(s) under {1}'
    RemovedOk           = 'Antigravity Uninstall-Toolkit: removed {0} managed path(s) under {1}'
    SkillsJsonUpdated   = 'Antigravity Uninstall-Toolkit: removed managed skills.json entry id={0}'
    ManagedBlockRemoved = 'Antigravity Uninstall-Toolkit: stripped managed block from {0}'
}

function Get-AntigravityUninstallRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-AntigravityAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-AntigravityAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:AntigravityUninstallModuleDirectory))
}

function Get-AntigravityManagedSkillIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $coreSkillsRoot = Join-Path (
        Join-Path $RepoRoot $script:AntigravityPathConstant.CoreDirectoryName
    ) $script:AntigravityPathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force |
            Select-Object -ExpandProperty Name
    )
}

function Remove-AntigravityPathIfPresent {
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

function Remove-AntigravityManagedSkillsJsonEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsJsonPath,

        [Parameter(Mandatory = $true)]
        [string] $ManagedEntryId,

        [Parameter()]
        [switch] $WhatIf
    )

    if (-not (Test-Path -LiteralPath $SkillsJsonPath)) {
        return $false
    }

    $entriesProperty = $script:AntigravityAdapterConstant.SkillsJsonEntriesPropertyName
    $idProperty = $script:AntigravityAdapterConstant.SkillsJsonIdPropertyName

    try {
        $raw = Get-Content -LiteralPath $SkillsJsonPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $false
        }
        $skillsJson = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $false
    }

    if ($null -eq $skillsJson -or $null -eq $skillsJson.$entriesProperty) {
        return $false
    }

    $entries = @($skillsJson.$entriesProperty)
    $kept = @($entries | Where-Object {
            $null -eq $_ -or
            -not ($_.PSObject.Properties.Name -contains $idProperty) -or
            -not [string]::Equals([string]$_.$idProperty, $ManagedEntryId, [System.StringComparison]::OrdinalIgnoreCase)
        })

    if ($kept.Count -eq $entries.Count) {
        return $false
    }

    if ($WhatIf.IsPresent) {
        return $true
    }

    $skillsJson.$entriesProperty = @($kept)
    $json = $skillsJson | ConvertTo-Json -Depth 8
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($SkillsJsonPath, $json + [Environment]::NewLine, $utf8)
    return $true
}

function Remove-AntigravityManagedMarkdownBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath,

        [Parameter()]
        [switch] $WhatIf
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        return $false
    }

    $existing = [System.IO.File]::ReadAllText($TargetPath)
    $begin = $script:AntigravityPathConstant.ManagedBlockBeginMarker
    $end = $script:AntigravityPathConstant.ManagedBlockEndMarker
    $pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end) + '\r?\n?'

    if ($existing -notmatch $pattern) {
        return $false
    }

    if ($WhatIf.IsPresent) {
        return $true
    }

    $newContent = [regex]::Replace($existing, $pattern, '')
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($TargetPath, $newContent, $utf8)
    return $true
}

function Invoke-AntigravityUninstallToolkit {
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
        throw $script:AntigravityUninstallMessage.InstallRootRequired
    }

    $repoRoot = Get-AntigravityUninstallRepoRoot
    $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
    $mapped = Get-AntigravityMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $removedPaths = New-Object System.Collections.Generic.List[string]
    $wouldRemovePaths = New-Object System.Collections.Generic.List[string]
    $sep = [System.IO.Path]::DirectorySeparatorChar

    $managedSkillIds = Get-AntigravityManagedSkillIds -RepoRoot $repoRoot
    foreach ($skillId in $managedSkillIds) {
        $skillPath = Join-Path $mapped.FixtureSkillsPath $skillId
        $wouldRemove = Remove-AntigravityPathIfPresent -Path $skillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
        if ($wouldRemove) {
            $wouldRemovePaths.Add($skillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($skillPath) | Out-Null
            }
        }
    }

    $devPersonaDir = $mapped.FixtureDevPersonaDir
    $wouldRemovePersona = Remove-AntigravityPathIfPresent -Path $devPersonaDir -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
    if ($wouldRemovePersona) {
        $wouldRemovePaths.Add($devPersonaDir) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add($devPersonaDir) | Out-Null
        }
    }

    $pluginDir = Join-Path $mapped.FixturePluginsPath $script:AntigravityPathConstant.ManagedPluginDirectoryName
    $wouldRemovePlugin = Remove-AntigravityPathIfPresent -Path $pluginDir -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
    if ($wouldRemovePlugin) {
        $wouldRemovePaths.Add($pluginDir) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add($pluginDir) | Out-Null
        }
    }

    $managedId = $script:AntigravityAdapterConstant.ManagedSkillsJsonEntryId
    $skillsJsonTouched = Remove-AntigravityManagedSkillsJsonEntry -SkillsJsonPath $mapped.FixtureSkillsJsonPath -ManagedEntryId $managedId -WhatIf:$WhatIf
    if ($skillsJsonTouched) {
        $wouldRemovePaths.Add($mapped.FixtureSkillsJsonPath) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add(($script:AntigravityUninstallMessage.SkillsJsonUpdated -f $managedId)) | Out-Null
        }
    }

    foreach ($mdPath in @($mapped.FixtureAgentsMdPath, $mapped.FixtureGeminiMdPath)) {
        $blockRemoved = Remove-AntigravityManagedMarkdownBlock -TargetPath $mdPath -WhatIf:$WhatIf
        if ($blockRemoved) {
            $wouldRemovePaths.Add($mdPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add(($script:AntigravityUninstallMessage.ManagedBlockRemoved -f $mdPath)) | Out-Null
            }
        }
    }

    # Explicitly never touch legacy bridge or hooks tree.
    $legacyBridgePath = Join-Path $resolvedInstallRoot ($script:AntigravityAdapterConstant.LegacyBridgeRelativePath -replace '/', $sep)
    $hooksPath = $mapped.FixtureHooksPath

    $message = if ($WhatIf.IsPresent) {
        $script:AntigravityUninstallMessage.WhatIfOk -f $wouldRemovePaths.Count, $resolvedInstallRoot
    }
    else {
        $script:AntigravityUninstallMessage.RemovedOk -f $removedPaths.Count, $resolvedInstallRoot
    }

    return [PSCustomObject]@{
        Success                  = $true
        Implemented              = $true
        CommandName              = 'Uninstall-Toolkit'
        InstallRoot              = $resolvedInstallRoot
        RemovedPathCount         = $(if ($WhatIf.IsPresent) { $wouldRemovePaths.Count } else { $removedPaths.Count })
        RemovedPaths             = $(if ($WhatIf.IsPresent) { @($wouldRemovePaths.ToArray()) } else { @($removedPaths.ToArray()) })
        WhatIf                   = [bool]$WhatIf.IsPresent
        SmokeTargetsLegacyBridge = $false
        LegacyBridgePath         = $legacyBridgePath
        OfficialHooksPath        = $hooksPath
        Message                  = $message
        ExitCode                 = 0
    }
}
