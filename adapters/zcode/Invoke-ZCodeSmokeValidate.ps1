#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem smoke checks for a ZCode ADE InstallRoot.

.DESCRIPTION
  Verifies minimum published layout: skills/*/SKILL.md, AGENTS.md, and
  hooks/config (cli/config.json with hooks.enabled and/or hooks/hooks.json).
  Does not require ZCode UI, plugin enable, or live sessions (RN09).
#>

$script:ZCodeSmokeModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ZCodeSmokeModuleDirectory)) {
    $script:ZCodeSmokeModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-ZCodeSmokeRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-ZCodeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-ZCodeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:ZCodeSmokeModuleDirectory))
}

function Test-ZCodeSmokeHooksEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CliConfigPath
    )

    try {
        $raw = [System.IO.File]::ReadAllText($CliConfigPath)
        $parsed = $raw | ConvertFrom-Json
    }
    catch {
        return $false
    }

    if ($null -eq $parsed -or $null -eq $parsed.hooks) {
        return $false
    }

    $enabledProp = $parsed.hooks.PSObject.Properties['enabled']
    if ($null -eq $enabledProp) {
        return $false
    }

    return [bool]$enabledProp.Value
}

function Get-ZCodeSmokeLayoutGaps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $gaps = New-Object System.Collections.Generic.List[string]

    $skillsRoot = Join-Path $InstallRoot $script:ZCodePathConstant.SkillsDirectoryName
    $skillManifests = @()
    if (Test-Path -LiteralPath $skillsRoot) {
        $skillManifests = @(Get-ChildItem -LiteralPath $skillsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $manifest = Join-Path $_.FullName $script:ZCodePathConstant.SkillManifestFileName
                if (Test-Path -LiteralPath $manifest -PathType Leaf) {
                    $manifest
                }
            })
    }

    if ($skillManifests.Count -lt 1) {
        $gaps.Add($script:ZCodePublishMessage.SmokeSkillsMissing) | Out-Null
    }

    $agentsPath = Join-Path $InstallRoot $script:ZCodePathConstant.AgentsFileName
    if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
        $gaps.Add($script:ZCodePublishMessage.SmokeAgentsMissing) | Out-Null
    }

    $cliConfigPath = Join-Path (Join-Path $InstallRoot $script:ZCodePathConstant.CliDirectoryName) $script:ZCodePathConstant.CliConfigFileName
    $hooksJsonPath = Join-Path (Join-Path $InstallRoot $script:ZCodePathConstant.HooksDirectoryName) $script:ZCodePathConstant.HooksJsonFileName

    $cliPresent = Test-Path -LiteralPath $cliConfigPath -PathType Leaf
    $hooksJsonPresent = Test-Path -LiteralPath $hooksJsonPath -PathType Leaf
    $cliHooksEnabled = $false
    if ($cliPresent) {
        $cliHooksEnabled = Test-ZCodeSmokeHooksEnabled -CliConfigPath $cliConfigPath
    }

    # PRD: at least one official hooks surface - config with hooks.enabled and/or hooks.json
    $hooksSurfaceOk = ($cliPresent -and $cliHooksEnabled) -or $hooksJsonPresent
    if (-not $hooksSurfaceOk) {
        if ($cliPresent -and -not $cliHooksEnabled -and -not $hooksJsonPresent) {
            $gaps.Add($script:ZCodePublishMessage.SmokeHooksEnabledOff) | Out-Null
        }
        elseif (-not $cliPresent -and -not $hooksJsonPresent) {
            $gaps.Add($script:ZCodePublishMessage.SmokeHooksSurfaceGap) | Out-Null
        }
        else {
            if (-not $cliPresent) {
                $gaps.Add($script:ZCodePublishMessage.SmokeCliConfigMissing) | Out-Null
            }
            elseif (-not $cliHooksEnabled) {
                $gaps.Add($script:ZCodePublishMessage.SmokeHooksEnabledOff) | Out-Null
            }
            if (-not $hooksJsonPresent) {
                $gaps.Add($script:ZCodePublishMessage.SmokeHooksJsonMissing) | Out-Null
            }
        }
    }

    return [PSCustomObject]@{
        Gaps             = @($gaps)
        SkillManifests   = @($skillManifests)
        AgentsPath       = $agentsPath
        CliConfigPath    = $cliConfigPath
        HooksJsonPath    = $hooksJsonPath
        CliPresent       = $cliPresent
        HooksJsonPresent = $hooksJsonPresent
        CliHooksEnabled  = $cliHooksEnabled
    }
}

function Invoke-ZCodeSmokeValidate {
    <#
    .SYNOPSIS
      Validate minimum ZCode ADE filesystem layout under InstallRoot.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ZCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ZCodeSmokeRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $layout = Get-ZCodeSmokeLayoutGaps -InstallRoot $resolvedInstallRoot
    $gaps = @($layout.Gaps)

    if ($gaps.Count -gt 0) {
        $gapList = [string]::Join($script:ZCodePublishMessage.SmokeRelativeSep, $gaps)
        return [PSCustomObject]@{
            Success            = $false
            Implemented        = $true
            CommandName        = 'Invoke-SmokeValidate'
            InstallRoot        = $resolvedInstallRoot
            Missing            = $gaps
            SkillManifestCount = $layout.SkillManifests.Count
            AgentsPath         = $layout.AgentsPath
            CliConfigPath      = $layout.CliConfigPath
            HooksJsonPath      = $layout.HooksJsonPath
            Message            = ($script:ZCodePublishMessage.SmokeFailGaps -f $resolvedInstallRoot, $gapList)
            ExitCode           = 1
        }
    }

    return [PSCustomObject]@{
        Success            = $true
        Implemented        = $true
        CommandName        = 'Invoke-SmokeValidate'
        InstallRoot        = $resolvedInstallRoot
        Missing            = @()
        SkillManifestCount = $layout.SkillManifests.Count
        AgentsPath         = $layout.AgentsPath
        CliConfigPath      = $layout.CliConfigPath
        HooksJsonPath      = $layout.HooksJsonPath
        Message            = ($script:ZCodePublishMessage.SmokePass -f $resolvedInstallRoot)
        ExitCode           = 0
    }
}
