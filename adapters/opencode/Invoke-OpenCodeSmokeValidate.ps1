#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem-only OpenCode Invoke-SmokeValidate helper.

.DESCRIPTION
  Asserts InstallRoot models ~/.config/opencode after sync:
  - skills/<kebab-id>/SKILL.md (TE02)
  - AGENTS.md at config root (TE02)
  - plugins/agent-dev-toolkit-marker.js when hooks/plugin capable (TE03)
  Resolves InstallRoot via Resolve-InstallRoot (TE01 / CA4 home guard).
  Never invokes OpenCode runtime; never requires .ps1 shell hooks (RN03).
#>

$script:OpenCodeSmokeHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenCodeSmokeHelperDirectory)) {
    $script:OpenCodeSmokeHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function New-OpenCodeSmokeResult {
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
        [int] $ExitCode = 0
    )

    if ($null -eq $Checks) {
        $Checks = @{}
    }

    return [PSCustomObject]@{
        Success              = $Success
        Implemented          = $true
        CommandName          = 'Invoke-SmokeValidate'
        AgentId              = $script:OpenCodeAdapterAgentId
        FilesystemOnly       = $true
        RequiresRuntime      = $false
        RequiresShellHooks   = $false
        ErrorCode            = $ErrorCode
        ResolvedInstallRoot  = $ResolvedInstallRoot
        Checks               = [PSCustomObject]$Checks
        Message              = $Message
        ExitCode             = $ExitCode
    }
}

function Test-OpenCodeSmokeSkillManifestPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
        return $false
    }

    $manifestName = $script:OpenCodePathConstant.SkillManifestFileName
    $skillDirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory -Force -ErrorAction SilentlyContinue
    foreach ($dir in $skillDirs) {
        if ([string]::Equals($dir.Name, $script:OpenCodePathConstant.SharedSkillsDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $manifestPath = Join-Path $dir.FullName $manifestName
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            return $true
        }
    }

    return $false
}

function Invoke-OpenCodeSmokeValidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    $resolvedInstallRoot = $null
    try {
        $repoRoot = Get-OpenCodeAdapterRepoRoot
        $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
        . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    }
    catch {
        $detail = $_.Exception.Message
        return New-OpenCodeSmokeResult `
            -Success $false `
            -ErrorCode $script:OpenCodePathConstant.SmokeTe01Code `
            -Message ($script:OpenCodeSmokeMessage.Te01InvalidInstallRoot -f $detail) `
            -ExitCode 1
    }

    $mapped = Get-OpenCodeMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $skillsPath = $mapped.FixtureSkillsPath
    $agentsPath = $mapped.FixtureAgentsPath
    $pluginsPath = $mapped.FixturePluginsPath
    $pluginMarkerPath = Join-Path $pluginsPath $script:OpenCodePathConstant.PluginMarkerFileName

    $checks = [ordered]@{
        SkillsPresent       = $false
        AgentsMdPresent     = $false
        CustomAgentsPresent = $false
        PluginMarkerPresent = $false
        PluginRequired      = $false
        ShellHooksRequired  = $false
        SddLayoutPresent    = $false
        FilesystemOnly      = $true
    }

    $skillsOk = Test-OpenCodeSmokeSkillManifestPresent -SkillsRoot $skillsPath
    $checks.SkillsPresent = $skillsOk
    if (-not $skillsOk) {
        return New-OpenCodeSmokeResult `
            -Success $false `
            -ErrorCode $script:OpenCodePathConstant.SmokeTe02Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:OpenCodeSmokeMessage.Te02SkillsMissing -f $skillsPath) `
            -ExitCode 1
    }

    $agentsOk = $false
    if (Test-Path -LiteralPath $agentsPath -PathType Leaf) {
        $agentsText = [System.IO.File]::ReadAllText($agentsPath)
        $agentsOk = -not [string]::IsNullOrWhiteSpace($agentsText)
    }

    $checks.AgentsMdPresent = $agentsOk
    if (-not $agentsOk) {
        return New-OpenCodeSmokeResult `
            -Success $false `
            -ErrorCode $script:OpenCodePathConstant.SmokeTe02Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:OpenCodeSmokeMessage.Te02AgentsMissing -f $agentsPath) `
            -ExitCode 1
    }

    $caps = Get-Capabilities
    $agentsCapable = ($null -ne $caps) -and ($null -ne $caps.Capabilities) -and ($caps.Capabilities.agents -eq $true)
    if ($agentsCapable) {
        $customAgentsRoot = $mapped.FixtureCustomAgentsPath
        $customAgentsOk = $false
        if (Test-Path -LiteralPath $customAgentsRoot) {
            $mdFiles = @(Get-ChildItem -LiteralPath $customAgentsRoot -File -Filter '*.md' -ErrorAction SilentlyContinue)
            $customAgentsOk = ($mdFiles.Count -gt 0)
        }
        $checks.CustomAgentsPresent = $customAgentsOk
        if (-not $customAgentsOk) {
            return New-OpenCodeSmokeResult `
                -Success $false `
                -ErrorCode $script:OpenCodePathConstant.SmokeTe02Code `
                -ResolvedInstallRoot $resolvedInstallRoot `
                -Checks $checks `
                -Message ($script:OpenCodeSmokeMessage.Te02CustomAgentsMissing -f $customAgentsRoot) `
                -ExitCode 1
        }
    }

    $pluginRequired = ($null -ne $caps) -and ($null -ne $caps.Capabilities) -and `
        ($caps.Capabilities.hooks -eq $true) -and ($caps.Capabilities.plugin -eq $true)
    $checks.PluginRequired = [bool]$pluginRequired

    if ($pluginRequired) {
        $pluginOk = Test-Path -LiteralPath $pluginMarkerPath -PathType Leaf
        $checks.PluginMarkerPresent = $pluginOk
        if (-not $pluginOk) {
            return New-OpenCodeSmokeResult `
                -Success $false `
                -ErrorCode $script:OpenCodePathConstant.SmokeTe03Code `
                -ResolvedInstallRoot $resolvedInstallRoot `
                -Checks $checks `
                -Message ($script:OpenCodeSmokeMessage.Te03PluginMismatch -f $pluginMarkerPath) `
                -ExitCode 1
        }
    }
    else {
        $checks.PluginMarkerPresent = Test-Path -LiteralPath $pluginMarkerPath -PathType Leaf
    }

    $sddMissing = [System.Collections.Generic.List[string]]::new()
    $sddOk = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $sddMissing
    $checks.SddLayoutPresent = $sddOk
    if (-not $sddOk) {
        $listText = ($sddMissing.ToArray() -join ', ')
        return New-OpenCodeSmokeResult `
            -Success $false `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -Message ($script:OpenCodeSmokeMessage.Te05SddLayoutMissing -f $listText) `
            -ExitCode 1
    }

    $passMessage = ($script:OpenCodeSmokeMessage.Passed -f $resolvedInstallRoot) + ' ' + $script:OpenCodeSmokeMessage.FilesystemOnlyNote
    return New-OpenCodeSmokeResult `
        -Success $true `
        -ResolvedInstallRoot $resolvedInstallRoot `
        -Checks $checks `
        -Message $passMessage `
        -ExitCode 0
}
