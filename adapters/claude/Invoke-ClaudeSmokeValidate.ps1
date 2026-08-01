#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem-only Claude Invoke-SmokeValidate helper.

.DESCRIPTION
  Asserts InstallRoot models a synced Claude Code root:
  - skills/<kebab-id>/SKILL.md (TE05)
  - rules/*.md (TE05)
  - hooks managed scripts (TE05)
  - CLAUDE.md (TE05)
  - settings.json merge completeness: managed hooks + permissions.allow (TE05)
  Resolves InstallRoot via Resolve-InstallRoot (TE01 / CA4 home guard).
  Never invokes Claude runtime; never requires hooks trust UI (TE05 files only).
#>

$script:ClaudeSmokeHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeSmokeHelperDirectory)) {
    $script:ClaudeSmokeHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:ClaudeSmokeMessage = @{
    Passed                 = 'Claude Invoke-SmokeValidate PASS under {0} (filesystem checks only; hooks trust UI is out of scope - TE05 files only).'
    Te01InvalidInstallRoot = 'Claude Invoke-SmokeValidate TE01: InstallRoot rejected ({0}). Use an in-repo fixture or pass -AllowUserHome for USERPROFILE paths.'
    Te05MissingArtifacts   = 'Claude Invoke-SmokeValidate TE05: required artifact(s) missing or incomplete under InstallRoot: {0}'
    FilesystemOnlyNote     = 'Smoke validates published files only; do not expect Claude Code hooks trust UI to be granted by CI.'
}

function New-ClaudeSmokeResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Success,

        [Parameter()]
        [string] $Message = '',

        [Parameter()]
        [string] $ErrorCode = '',

        [Parameter()]
        [string] $ResolvedInstallRoot = $null,

        [Parameter()]
        [hashtable] $Checks = $null,

        [Parameter()]
        [string[]] $MissingRelativePaths = @(),

        [Parameter()]
        [int] $ExitCode = 0
    )

    if ($null -eq $Checks) {
        $Checks = @{}
    }

    return [PSCustomObject]@{
        Success               = $Success
        Implemented           = $true
        CommandName           = 'Invoke-SmokeValidate'
        AgentId               = $script:ClaudeAdapterAgentId
        FilesystemOnly        = $true
        RequiresRuntime       = $false
        RequiresHooksTrustUi  = $false
        ErrorCode             = $ErrorCode
        ResolvedInstallRoot   = $ResolvedInstallRoot
        Checks                = [PSCustomObject]$Checks
        MissingRelativePaths  = @($MissingRelativePaths)
        Te05Note              = $script:ClaudeSmokeMessage.FilesystemOnlyNote
        Message               = $Message
        ExitCode              = $ExitCode
    }
}

function Test-ClaudeSmokeFileHasUtf8Bom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 3) {
        return $false
    }

    return ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

function Test-ClaudeSmokeSkillManifestPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
        return $false
    }

    $manifestName = $script:ClaudePathConstant.SkillManifestFileName
    $skillDirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory -Force -ErrorAction SilentlyContinue
    foreach ($dir in $skillDirs) {
        if ([string]::Equals($dir.Name, $script:ClaudePathConstant.SharedSkillsDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $manifestPath = Join-Path $dir.FullName $manifestName
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            return $true
        }
    }

    return $false
}

function Test-ClaudeSmokeRulesPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RulesRoot
    )

    if (-not (Test-Path -LiteralPath $RulesRoot -PathType Container)) {
        return $false
    }

    $ruleFiles = Get-ChildItem -LiteralPath $RulesRoot -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -eq $script:ClaudePathConstant.MarkdownExtension }

    return (@($ruleFiles).Count -gt 0)
}

function Get-ClaudeSmokeManagedHookScriptNames {
    return @(
        $script:ClaudeSettingsJsonConstant.HookScriptUserPromptSubmit,
        $script:ClaudeSettingsJsonConstant.HookScriptPreCompact,
        $script:ClaudeSettingsJsonConstant.HookScriptPostToolUse,
        '_hook-common.ps1'
    )
}

function Test-ClaudeSmokeHookScriptsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksRoot,

        [Parameter()]
        [System.Collections.Generic.List[string]] $MissingRelative
    )

    if (-not (Test-Path -LiteralPath $HooksRoot -PathType Container)) {
        foreach ($name in (Get-ClaudeSmokeManagedHookScriptNames)) {
            $MissingRelative.Add(($script:ClaudePathConstant.HooksDirectoryName + '/' + $name))
        }
        return $false
    }

    $allPresent = $true
    foreach ($name in (Get-ClaudeSmokeManagedHookScriptNames)) {
        $path = Join-Path $HooksRoot $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $MissingRelative.Add(($script:ClaudePathConstant.HooksDirectoryName + '/' + $name))
            $allPresent = $false
        }
    }

    return $allPresent
}

function Test-ClaudeSmokeSettingsMergeComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SettingsPath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [System.Collections.Generic.List[string]] $MissingRelative
    )

    $settingsRel = $script:ClaudePathConstant.SettingsFileName
    if (-not (Test-Path -LiteralPath $SettingsPath -PathType Leaf)) {
        $MissingRelative.Add($settingsRel)
        return $false
    }

    if (Test-ClaudeSmokeFileHasUtf8Bom -Path $SettingsPath) {
        $MissingRelative.Add(($settingsRel + ' (must be UTF-8 without BOM)'))
        return $false
    }

    try {
        $settings = [System.IO.File]::ReadAllText($SettingsPath) | ConvertFrom-Json
    }
    catch {
        $MissingRelative.Add(($settingsRel + ' (invalid JSON)'))
        return $false
    }

    if ($null -eq $settings) {
        $MissingRelative.Add(($settingsRel + ' (null JSON)'))
        return $false
    }

    $complete = $true
    $hooksProp = $script:ClaudeSettingsJsonConstant.HooksPropertyName
    $permProp = $script:ClaudeSettingsJsonConstant.PermissionsPropertyName
    $allowProp = $script:ClaudeSettingsJsonConstant.AllowPropertyName

    $requiredHookEvents = @(
        $script:ClaudeSettingsJsonConstant.HookEventUserPromptSubmit,
        $script:ClaudeSettingsJsonConstant.HookEventPreCompact,
        $script:ClaudeSettingsJsonConstant.HookEventPostToolUse
    )

    if ($null -eq $settings.$hooksProp) {
        $MissingRelative.Add(($settingsRel + '/hooks'))
        $complete = $false
    }
    else {
        foreach ($eventName in $requiredHookEvents) {
            if (-not ($settings.$hooksProp.PSObject.Properties.Name -contains $eventName)) {
                $MissingRelative.Add(($settingsRel + '/hooks/' + $eventName))
                $complete = $false
            }
        }
    }

    if ($null -eq $settings.$permProp -or $null -eq $settings.$permProp.$allowProp) {
        $MissingRelative.Add(($settingsRel + '/permissions/allow'))
        $complete = $false
    }
    else {
        $allow = @($settings.$permProp.$allowProp)
        $expectedAllow = @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $InstallRoot)
        foreach ($entry in $expectedAllow) {
            if (-not ($allow -contains $entry)) {
                $MissingRelative.Add(($settingsRel + '/permissions/allow/' + $entry))
                $complete = $false
            }
        }
        foreach ($legacy in @($script:ClaudeLegacyBroadPermissionsAllow)) {
            if ($allow -contains $legacy) {
                $MissingRelative.Add(($settingsRel + '/permissions/allow/' + $legacy + ' (legacy broad must not remain by default)'))
                $complete = $false
            }
        }
    }

    return $complete
}

function Invoke-ClaudeSmokeValidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ClaudeAdapterMessage.InstallRootRequired
    }

    $resolvedInstallRoot = $null
    try {
        $repoRoot = Get-ClaudeAdapterRepoRoot
        $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
        . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    }
    catch {
        $detail = $_.Exception.Message
        return New-ClaudeSmokeResult `
            -Success $false `
            -ErrorCode $script:ClaudePathConstant.SmokeTe01Code `
            -Message ($script:ClaudeSmokeMessage.Te01InvalidInstallRoot -f $detail) `
            -ExitCode 1
    }

    $skillsPath = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.SkillsDirectoryName
    $rulesPath = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.RulesDirectoryName
    $hooksPath = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.HooksDirectoryName
    $claudeMdPath = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.ClaudeMdFileName
    $settingsPath = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.SettingsFileName

    $missing = [System.Collections.Generic.List[string]]::new()
    $checks = [ordered]@{
        SkillsPresent         = $false
        RulesPresent          = $false
        HookScriptsPresent    = $false
        ClaudeMdPresent       = $false
        SettingsMergeComplete = $false
        SddLayoutPresent      = $false
        FilesystemOnly        = $true
        RequiresHooksTrustUi  = $false
    }

    $skillsOk = Test-ClaudeSmokeSkillManifestPresent -SkillsRoot $skillsPath
    $checks.SkillsPresent = $skillsOk
    if (-not $skillsOk) {
        $missing.Add(($script:ClaudePathConstant.SkillsDirectoryName + '/*/SKILL.md'))
    }

    $rulesOk = Test-ClaudeSmokeRulesPresent -RulesRoot $rulesPath
    $checks.RulesPresent = $rulesOk
    if (-not $rulesOk) {
        $missing.Add(($script:ClaudePathConstant.RulesDirectoryName + '/*.md'))
    }

    $hooksOk = Test-ClaudeSmokeHookScriptsPresent -HooksRoot $hooksPath -MissingRelative $missing
    $checks.HookScriptsPresent = $hooksOk

    $claudeMdOk = $false
    if (Test-Path -LiteralPath $claudeMdPath -PathType Leaf) {
        $claudeText = [System.IO.File]::ReadAllText($claudeMdPath)
        $claudeMdOk = -not [string]::IsNullOrWhiteSpace($claudeText)
    }
    $checks.ClaudeMdPresent = $claudeMdOk
    if (-not $claudeMdOk) {
        $missing.Add($script:ClaudePathConstant.ClaudeMdFileName)
    }

    $settingsOk = Test-ClaudeSmokeSettingsMergeComplete -SettingsPath $settingsPath -InstallRoot $resolvedInstallRoot -MissingRelative $missing
    $checks.SettingsMergeComplete = $settingsOk

    $sddOk = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $missing
    $checks.SddLayoutPresent = $sddOk

    if ($missing.Count -gt 0) {
        $listText = ($missing.ToArray() -join ', ')
        return New-ClaudeSmokeResult `
            -Success $false `
            -ErrorCode $script:ClaudePathConstant.SmokeTe05Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -MissingRelativePaths $missing.ToArray() `
            -Message ($script:ClaudeSmokeMessage.Te05MissingArtifacts -f $listText) `
            -ExitCode 1
    }

    $passMessage = ($script:ClaudeSmokeMessage.Passed -f $resolvedInstallRoot) + ' ' + $script:ClaudeSmokeMessage.FilesystemOnlyNote
    return New-ClaudeSmokeResult `
        -Success $true `
        -ResolvedInstallRoot $resolvedInstallRoot `
        -Checks $checks `
        -Message $passMessage `
        -ExitCode 0
}
