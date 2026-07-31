#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem-only smoke checks for the Copilot adapter.

.DESCRIPTION
  Validates skills, instructions, and hooks under InstallRoot for -Mode user|repo.
  Does not invoke Copilot IDE, VS Code extension, or GitHub login.
  TE01 via Resolve-InstallRoot; TE02 Mode; TE03 missing artifacts; TE04 hooks capable but missing.
#>

$script:CopilotSmokeHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CopilotSmokeHelperDirectory)) {
    $script:CopilotSmokeHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-CopilotSmokeNormalizedMode {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Mode
    )

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        throw $script:CopilotSmokeMessage.ModeRequired
    }

    $normalized = $Mode.Trim().ToLowerInvariant()
    $valid = @(
        $script:CopilotPathConstant.ModeUser,
        $script:CopilotPathConstant.ModeRepo
    )
    if ($valid -notcontains $normalized) {
        throw ($script:CopilotSmokeMessage.ModeInvalid -f $Mode)
    }

    return $normalized
}

function Test-CopilotSmokeHooksCapable {
    [CmdletBinding()]
    param()

    if ($null -eq $script:CopilotAdapterCapabilityFlags) {
        return $true
    }

    $hooksFlag = $script:CopilotAdapterCapabilityFlags['hooks']
    if ($null -eq $hooksFlag) {
        return $true
    }

    return [bool]$hooksFlag
}

function New-CopilotSmokeFailureResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Mode,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter()]
        [int] $ExitCode = 1
    )

    return [PSCustomObject]@{
        Success                 = $false
        Implemented             = $true
        CommandName             = 'Invoke-SmokeValidate'
        Mode                    = $Mode
        InstallRoot             = $InstallRoot
        Message                 = $Message
        ExitCode                = $ExitCode
        SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        Checks                  = @()
    }
}

function Assert-CopilotSmokeNoExcludedIdePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $Mode
    )

    $tokens = @(
        $script:CopilotPathConstant.ExcludedJetBrainsPathToken,
        $script:CopilotPathConstant.ExcludedEclipsePathToken
    )

    $entries = @(Get-ChildItem -LiteralPath $InstallRoot -Recurse -Force -ErrorAction SilentlyContinue)
    foreach ($entry in $entries) {
        $relative = $entry.FullName.Substring($InstallRoot.Length).TrimStart('\', '/')
        foreach ($token in $tokens) {
            if ($relative -match ('(?i){0}' -f [regex]::Escape($token))) {
                throw ($script:CopilotSmokeMessage.ExcludedIdePathFound -f $Mode, $token, $entry.FullName)
            }
        }
    }
}

function Invoke-CopilotSmokeValidateCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [string] $Mode,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotSmokeMessage.InstallRootRequired
    }

    $normalizedMode = Get-CopilotSmokeNormalizedMode -Mode $Mode

    $repoRoot = Split-Path -Parent (Split-Path -Parent $script:CopilotSmokeHelperDirectory)
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $checks = New-Object System.Collections.Generic.List[string]

    $skillsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.SkillsDirectoryName
    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $skillsRoot)
    }
    $checks.Add('skills-root')

    foreach ($skillFolder in $script:CopilotPathConstant.SmokeExpectedSkillFolders) {
        $skillDir = Join-Path $skillsRoot $skillFolder
        $manifest = Join-Path $skillDir $script:CopilotPathConstant.SkillManifestFileName
        if (-not (Test-Path -LiteralPath $manifest)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $manifest)
        }
        $manifestText = [System.IO.File]::ReadAllText($manifest)
        if ([string]::IsNullOrWhiteSpace($manifestText)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.SkillManifestEmpty -f $normalizedMode, $manifest)
        }
        $checks.Add(('skill:{0}' -f $skillFolder))
    }

    $sharedSkillsDir = Join-Path $skillsRoot $script:CopilotPathConstant.SmokeExpectedSharedSkillsFolder
    if (-not (Test-Path -LiteralPath $sharedSkillsDir)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $sharedSkillsDir)
    }
    $checks.Add('skill:_shared')

    $copilotInstructions = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CopilotInstructionsFileName
    if (-not (Test-Path -LiteralPath $copilotInstructions)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $copilotInstructions)
    }
    $checks.Add('copilot-instructions.md')

    $instructionsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.InstructionsDirectoryName
    if (-not (Test-Path -LiteralPath $instructionsRoot)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $instructionsRoot)
    }

    foreach ($baseName in $script:CopilotPathConstant.SmokeExpectedInstructionBases) {
        $instructionPath = Join-Path $instructionsRoot ($baseName + $script:CopilotPathConstant.InstructionsFileExtension)
        if (-not (Test-Path -LiteralPath $instructionPath)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $instructionPath)
        }
        $checks.Add(('instruction:{0}' -f $baseName))
    }

    if (Test-CopilotSmokeHooksCapable) {
        $hooksRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.HooksDirectoryName
        if (-not (Test-Path -LiteralPath $hooksRoot)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.HooksMissing -f $normalizedMode, $hooksRoot)
        }

        foreach ($hookFileName in $script:CopilotPathConstant.SmokeExpectedHookFileNames) {
            $hookPath = Join-Path $hooksRoot $hookFileName
            if (-not (Test-Path -LiteralPath $hookPath)) {
                return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.HooksMissing -f $normalizedMode, $hookPath)
            }
            $checks.Add(('hook:{0}' -f $hookFileName))
        }

        $hooksJsonPath = Join-Path $hooksRoot 'hooks.json'
        try {
            $null = Get-Content -LiteralPath $hooksJsonPath -Raw | ConvertFrom-Json
        }
        catch {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message ($script:CopilotSmokeMessage.HooksJsonInvalid -f $normalizedMode, $hooksJsonPath)
        }
        $checks.Add('hooks-json-schema')
    }

    try {
        Assert-CopilotSmokeNoExcludedIdePaths -InstallRoot $resolvedInstallRoot -Mode $normalizedMode
        $checks.Add('no-excluded-ide-paths')
    }
    catch {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Message $_.Exception.Message
    }

    return [PSCustomObject]@{
        Success                 = $true
        Implemented             = $true
        CommandName             = 'Invoke-SmokeValidate'
        Mode                    = $normalizedMode
        InstallRoot             = $resolvedInstallRoot
        Message                 = ($script:CopilotSmokeMessage.Passed -f $normalizedMode, $resolvedInstallRoot)
        ExitCode                = 0
        SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        Checks                  = @($checks)
    }
}
