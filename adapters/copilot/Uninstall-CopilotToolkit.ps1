#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Copilot adapter toolkit artifacts under InstallRoot.

.DESCRIPTION
  Removes only paths the Copilot adapter publishes from core/skills, core/policy,
  core/router (copilot-instructions.md), and adapters/copilot/assets/hooks.
  Does not wipe InstallRoot, alien skill folders, alien instruction/hook files,
  or .gitkeep placeholders. Mode user|repo required; InstallRoot fail-closed via
  Resolve-InstallRoot unless -AllowUserHome.
#>

$script:CopilotUninstallHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CopilotUninstallHelperDirectory)) {
    $script:CopilotUninstallHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_copilotUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CopilotUninstallHelperDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_copilotUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _copilotUninstallLibDir -ErrorAction SilentlyContinue

function Get-CopilotUninstallAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:CopilotUninstallHelperDirectory))
}

function Get-CopilotUninstallNormalizedMode {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Mode
    )

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        throw $script:CopilotUninstallMessage.ModeRequired
    }

    $normalized = $Mode.Trim().ToLowerInvariant()
    $valid = @(
        $script:CopilotPathConstant.ModeUser,
        $script:CopilotPathConstant.ModeRepo
    )
    if ($valid -notcontains $normalized) {
        throw ($script:CopilotUninstallMessage.ModeInvalid -f $Mode)
    }

    return $normalized
}

function Get-CopilotManagedSkillNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot
    )

    $names = @(
        Get-ChildItem -LiteralPath $SourceSkillsRoot -Force |
            Where-Object { $_.PSIsContainer -and $_.Name -ne $script:CopilotPathConstant.GitKeepFileName } |
            ForEach-Object { $_.Name }
    )
    return $names
}

function Get-CopilotManagedInstructionFileNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot
    )

    $sourceExt = $script:CopilotPathConstant.PolicySourceExtension
    $names = @(
        Get-ChildItem -LiteralPath $SourcePolicyRoot -File -Filter ('*{0}' -f $sourceExt) |
            ForEach-Object {
                $_.BaseName + $script:CopilotPathConstant.InstructionsFileExtension
            }
    )
    return $names
}

function Get-CopilotManagedHookRelativePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceHooksRoot
    )

    $paths = @()
    $sourceFiles = Get-ChildItem -LiteralPath $SourceHooksRoot -Recurse -File
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($SourceHooksRoot.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($relative)) {
            continue
        }
        if ($relative -eq $script:CopilotPathConstant.GitKeepFileName) {
            continue
        }
        $paths += $relative
    }
    return $paths
}

function Remove-CopilotManagedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        return $false
    }

    $leaf = Split-Path -Leaf $TargetPath
    if ($leaf -eq $script:CopilotPathConstant.GitKeepFileName) {
        return $false
    }

    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $TargetPath -InstallRoot $InstallRoot

    if ($WhatIf.IsPresent) {
        return $true
    }

    Remove-Item -LiteralPath $TargetPath -Recurse -Force
    return $true
}

function Invoke-CopilotUninstallToolkit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [string] $Mode,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotUninstallMessage.InstallRootRequired
    }

    $normalizedMode = Get-CopilotUninstallNormalizedMode -Mode $Mode

    $repoRoot = Get-CopilotUninstallAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot

    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:CopilotPathConstant.CoreDirectoryName) $script:CopilotPathConstant.SkillsDirectoryName
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:CopilotPathConstant.CoreDirectoryName) $script:CopilotPathConstant.PolicyDirectoryName
    $sourceHooksRoot = Join-Path (
        Join-Path $script:CopilotUninstallHelperDirectory $script:CopilotPathConstant.AssetsDirectoryName
    ) $script:CopilotPathConstant.HooksDirectoryName

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:CopilotUninstallMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }
    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:CopilotUninstallMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }
    if (-not (Test-Path -LiteralPath $sourceHooksRoot)) {
        throw ($script:CopilotUninstallMessage.HooksAssetsMissing -f $sourceHooksRoot)
    }

    $removedPaths = New-Object System.Collections.Generic.List[string]

    $skillsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.SkillsDirectoryName
    foreach ($skillName in (Get-CopilotManagedSkillNames -SourceSkillsRoot $sourceSkillsRoot)) {
        $skillPath = Join-Path $skillsRoot $skillName
        if (Remove-CopilotManagedPath -TargetPath $skillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf) {
            $removedPaths.Add($skillPath) | Out-Null
        }
    }

    $instructionsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.InstructionsDirectoryName
    foreach ($instructionName in (Get-CopilotManagedInstructionFileNames -SourcePolicyRoot $sourcePolicyRoot)) {
        $instructionPath = Join-Path $instructionsRoot $instructionName
        if (Remove-CopilotManagedPath -TargetPath $instructionPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf) {
            $removedPaths.Add($instructionPath) | Out-Null
        }
    }

    $copilotInstructionsPath = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CopilotInstructionsFileName
    if (Remove-CopilotManagedPath -TargetPath $copilotInstructionsPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf) {
        $removedPaths.Add($copilotInstructionsPath) | Out-Null
    }

    $hooksRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.HooksDirectoryName
    foreach ($hookRelative in (Get-CopilotManagedHookRelativePaths -SourceHooksRoot $sourceHooksRoot)) {
        $hookPath = Join-Path $hooksRoot ($hookRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (Remove-CopilotManagedPath -TargetPath $hookPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf) {
            $removedPaths.Add($hookPath) | Out-Null
        }
    }

    $removedCount = $removedPaths.Count
    $message = if ($WhatIf.IsPresent) {
        ($script:CopilotUninstallMessage.WhatIfOk -f $removedCount, $resolvedInstallRoot, $normalizedMode)
    }
    else {
        ($script:CopilotUninstallMessage.RemovedOk -f $removedCount, $resolvedInstallRoot, $normalizedMode)
    }

    return [PSCustomObject]@{
        Success       = $true
        Implemented   = $true
        CommandName   = 'Uninstall-Toolkit'
        WhatIf        = [bool]$WhatIf.IsPresent
        Mode          = $normalizedMode
        InstallRoot   = $resolvedInstallRoot
        RemovedCount  = $removedCount
        RemovedPaths  = @($removedPaths)
        Message       = $message
        ExitCode      = 0
        KeyedOnly     = $true
    }
}
