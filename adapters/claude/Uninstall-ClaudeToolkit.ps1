#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Claude Code adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot:
  - skills/<id> folders matching core/skills
  - rules/<file> matching core/policy
  - CLAUDE.md (Publish-Router target)
  - hooks/<script> matching adapters/claude/assets/hooks

  Settings reverse-merge: remove only toolkit-managed hook handlers (by the
  same command identity as merge) and managed permissions.allow entries.
  Preserves alien co-located handlers on the same event, alien event keys
  (Notification), operatorCustomKey, user allows, deny, env. Does not wipe
  settings.json.

  Uses Resolve-InstallRoot (USERPROFILE guard). Supports -WhatIf.
#>

$script:ClaudeUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeUninstallModuleDirectory)) {
    $script:ClaudeUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Script-scope load so Remove-* helpers can call Assert-PathUnderInstallRootForDelete
# (dotsource inside Invoke-* only defines commands in that function's local scope).
$_claudeUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:ClaudeUninstallModuleDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_claudeUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _claudeUninstallLibDir -ErrorAction SilentlyContinue

function Get-ClaudeUninstallRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-ClaudeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-ClaudeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:ClaudeUninstallModuleDirectory))
}

function Get-ClaudeManagedSkillIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $coreSkillsRoot = Join-Path (
        Join-Path $RepoRoot $script:ClaudePathConstant.CoreDirectoryName
    ) $script:ClaudePathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force |
            Select-Object -ExpandProperty Name
    )
}

function Get-ClaudeManagedRuleRelativePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $corePolicyRoot = Join-Path (
        Join-Path $RepoRoot $script:ClaudePathConstant.CoreDirectoryName
    ) $script:ClaudePathConstant.PolicyDirectoryName

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

function Get-ClaudeManagedHookRelativePaths {
    [CmdletBinding()]
    param()

    $assetsHooksRoot = Join-Path (
        Join-Path $script:ClaudeUninstallModuleDirectory $script:ClaudePathConstant.AssetsDirectoryName
    ) $script:ClaudePathConstant.HooksDirectoryName

    if (-not (Test-Path -LiteralPath $assetsHooksRoot)) {
        return @()
    }

    $paths = New-Object System.Collections.Generic.List[string]
    $files = Get-ChildItem -LiteralPath $assetsHooksRoot -Recurse -File -Force
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($assetsHooksRoot.Length).TrimStart('\', '/')
        $paths.Add($relative) | Out-Null
    }

    return @($paths.ToArray())
}

function Get-ClaudeManagedHookEventNames {
    [CmdletBinding()]
    param()

    $c = $script:ClaudeSettingsJsonConstant
    return @(
        $c.HookEventUserPromptSubmit,
        $c.HookEventPreCompact,
        $c.HookEventPostToolUse
    )
}

function Remove-ClaudeManagedPathIfPresent {
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

function Remove-ClaudeToolkitSettingsEntries {
    <#
    .SYNOPSIS
      Reverse-merge: drop managed hook handlers + managed allow entries; keep aliens.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter()]
        [switch] $WhatIf
    )

    $settingsPath = Get-ClaudeSettingsFilePath -InstallRoot $ResolvedInstallRoot
    $backupPath = Get-ClaudeSettingsBackupPath -SettingsPath $settingsPath

    if (-not (Test-Path -LiteralPath $settingsPath)) {
        return [PSCustomObject]@{
            Success         = $true
            SettingsTouched = $false
            SettingsPath    = $settingsPath
            BackupTaken     = $false
            Message         = $script:ClaudeUninstallMessage.SettingsAbsentOk
        }
    }

    try {
        $settings = Read-ClaudeSettingsObject -SettingsPath $settingsPath
    }
    catch {
        return [PSCustomObject]@{
            Success         = $false
            SettingsTouched = $false
            SettingsPath    = $settingsPath
            BackupTaken     = $false
            Message         = $_.Exception.Message
        }
    }

    $hooksChanged = Remove-ClaudeManagedHooksKeyed -Settings $settings
    $allowToRemove = @(Get-ClaudePermissionsAllowEntriesForRemoval -InstallRoot $ResolvedInstallRoot)
    $allowChanged = Remove-ClaudePermissionsAllowEntriesByEquality -Settings $settings -EntriesToRemove $allowToRemove
    $changed = [bool]($hooksChanged -or $allowChanged)

    if (-not $changed) {
        return [PSCustomObject]@{
            Success         = $true
            SettingsTouched = $false
            SettingsPath    = $settingsPath
            BackupTaken     = $false
            Message         = $script:ClaudeUninstallMessage.SettingsNoManagedEntries
        }
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success         = $true
            SettingsTouched = $true
            SettingsPath    = $settingsPath
            BackupTaken     = $false
            WhatIf          = $true
            Message         = ($script:ClaudeUninstallMessage.SettingsWhatIfOk -f $settingsPath)
        }
    }

    try {
        Backup-ClaudeSettingsFile -SettingsPath $settingsPath -BackupPath $backupPath
    }
    catch {
        return [PSCustomObject]@{
            Success         = $false
            SettingsTouched = $false
            SettingsPath    = $settingsPath
            BackupTaken     = $false
            Message         = $_.Exception.Message
        }
    }

    try {
        Write-ClaudeSettingsUtf8NoBom -SettingsPath $settingsPath -Settings $settings
    }
    catch {
        return [PSCustomObject]@{
            Success         = $false
            SettingsTouched = $false
            SettingsPath    = $settingsPath
            BackupTaken     = $true
            Message         = ($script:ClaudePublishMessage.SettingsWriteFailed -f $settingsPath, $_.Exception.Message)
        }
    }

    return [PSCustomObject]@{
        Success         = $true
        SettingsTouched = $true
        SettingsPath    = $settingsPath
        BackupTaken     = $true
        Message         = ($script:ClaudeUninstallMessage.SettingsCleanedOk -f $settingsPath)
    }
}

function Invoke-ClaudeUninstallToolkit {
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
        throw $script:ClaudeUninstallMessage.InstallRootRequired
    }

    $repoRoot = Get-ClaudeUninstallRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $removedPaths = New-Object System.Collections.Generic.List[string]
    $wouldRemovePaths = New-Object System.Collections.Generic.List[string]

    $skillsRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.SkillsDirectoryName
    foreach ($skillId in (Get-ClaudeManagedSkillIds -RepoRoot $repoRoot)) {
        $skillPath = Join-Path $skillsRoot $skillId
        $hit = Remove-ClaudeManagedPathIfPresent -Path $skillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
        if ($hit) {
            $wouldRemovePaths.Add($skillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($skillPath) | Out-Null
            }
        }
    }

    $rulesRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.RulesDirectoryName
    foreach ($ruleRelative in (Get-ClaudeManagedRuleRelativePaths -RepoRoot $repoRoot)) {
        $rulePath = Join-Path $rulesRoot ($ruleRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $hit = Remove-ClaudeManagedPathIfPresent -Path $rulePath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($hit) {
            $wouldRemovePaths.Add($rulePath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($rulePath) | Out-Null
            }
        }
    }

    $claudeMdPath = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.ClaudeMdFileName
    $hitClaudeMd = Remove-ClaudeManagedPathIfPresent -Path $claudeMdPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    if ($hitClaudeMd) {
        $wouldRemovePaths.Add($claudeMdPath) | Out-Null
        if (-not $WhatIf.IsPresent) {
            $removedPaths.Add($claudeMdPath) | Out-Null
        }
    }

    $hooksRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.HooksDirectoryName
    foreach ($hookRelative in (Get-ClaudeManagedHookRelativePaths)) {
        $hookPath = Join-Path $hooksRoot ($hookRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $hit = Remove-ClaudeManagedPathIfPresent -Path $hookPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($hit) {
            $wouldRemovePaths.Add($hookPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($hookPath) | Out-Null
            }
        }
    }

    $settingsResult = Remove-ClaudeToolkitSettingsEntries -ResolvedInstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    if ($null -eq $settingsResult -or $settingsResult.Success -ne $true) {
        $detail = if ($null -ne $settingsResult -and $settingsResult.PSObject.Properties.Name -contains 'Message') {
            [string]$settingsResult.Message
        }
        else {
            'settings reverse-merge failed'
        }
        return [PSCustomObject]@{
            Success          = $false
            Implemented      = $true
            CommandName      = 'Uninstall-Toolkit'
            WhatIf           = [bool]$WhatIf.IsPresent
            InstallRoot      = $resolvedInstallRoot
            RemovedCount     = $(if ($WhatIf.IsPresent) { $wouldRemovePaths.Count } else { $removedPaths.Count })
            RemovedPaths     = $(if ($WhatIf.IsPresent) { @($wouldRemovePaths.ToArray()) } else { @($removedPaths.ToArray()) })
            SettingsTouched  = $false
            SettingsPath     = $(if ($null -ne $settingsResult) { $settingsResult.SettingsPath } else { $null })
            KeyedOnly        = $true
            WholesaleWipe    = $false
            Message          = $detail
            ExitCode         = 1
        }
    }

    $pathCount = if ($WhatIf.IsPresent) { $wouldRemovePaths.Count } else { $removedPaths.Count }
    $message = if ($WhatIf.IsPresent) {
        ('{0}; {1}' -f ($script:ClaudeUninstallMessage.WhatIfOk -f $pathCount, $resolvedInstallRoot), $settingsResult.Message)
    }
    else {
        ('{0}; {1}' -f ($script:ClaudeUninstallMessage.RemovedOk -f $pathCount, $resolvedInstallRoot), $settingsResult.Message)
    }

    return [PSCustomObject]@{
        Success         = $true
        Implemented     = $true
        CommandName     = 'Uninstall-Toolkit'
        WhatIf          = [bool]$WhatIf.IsPresent
        InstallRoot     = $resolvedInstallRoot
        RemovedCount    = $pathCount
        RemovedPaths    = $(if ($WhatIf.IsPresent) { @($wouldRemovePaths.ToArray()) } else { @($removedPaths.ToArray()) })
        SettingsTouched = [bool]$settingsResult.SettingsTouched
        SettingsPath    = $settingsResult.SettingsPath
        KeyedOnly       = $true
        WholesaleWipe   = $false
        Message         = $message
        ExitCode        = 0
    }
}
