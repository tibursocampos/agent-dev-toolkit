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
        [hashtable] $Checks = $null,

        [Parameter()]
        [int] $ExitCode = 1
    )

    if ($null -eq $Checks) {
        $Checks = [ordered]@{ SddLayoutPresent = $false }
    }

    return [PSCustomObject]@{
        Success                 = $false
        Implemented             = $true
        CommandName             = 'Invoke-SmokeValidate'
        Mode                    = $Mode
        InstallRoot             = $InstallRoot
        Message                 = $Message
        ExitCode                = $ExitCode
        SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        Checks                  = [PSCustomObject]$Checks
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
    $completed = New-Object System.Collections.Generic.List[string]
    $checks = [ordered]@{
        SddLayoutPresent = $false
    }

    $skillsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.SkillsDirectoryName
    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $skillsRoot)
    }
    $completed.Add('skills-root')

    foreach ($skillFolder in $script:CopilotPathConstant.SmokeExpectedSkillFolders) {
        $skillDir = Join-Path $skillsRoot $skillFolder
        $manifest = Join-Path $skillDir $script:CopilotPathConstant.SkillManifestFileName
        if (-not (Test-Path -LiteralPath $manifest)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $manifest)
        }
        $manifestText = [System.IO.File]::ReadAllText($manifest)
        if ([string]::IsNullOrWhiteSpace($manifestText)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.SkillManifestEmpty -f $normalizedMode, $manifest)
        }
        $completed.Add(('skill:{0}' -f $skillFolder))
    }

    $sharedSkillsDir = Join-Path $skillsRoot $script:CopilotPathConstant.SmokeExpectedSharedSkillsFolder
    if (-not (Test-Path -LiteralPath $sharedSkillsDir)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $sharedSkillsDir)
    }
    $completed.Add('skill:_shared')

    $copilotInstructions = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CopilotInstructionsFileName
    if (-not (Test-Path -LiteralPath $copilotInstructions)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $copilotInstructions)
    }
    $completed.Add('copilot-instructions.md')

    $instructionsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.InstructionsDirectoryName
    if (-not (Test-Path -LiteralPath $instructionsRoot)) {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $instructionsRoot)
    }

    foreach ($baseName in $script:CopilotPathConstant.SmokeExpectedInstructionBases) {
        $instructionPath = Join-Path $instructionsRoot ($baseName + $script:CopilotPathConstant.InstructionsFileExtension)
        if (-not (Test-Path -LiteralPath $instructionPath)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $instructionPath)
        }
        $completed.Add(('instruction:{0}' -f $baseName))
    }

    if (Test-CopilotSmokeHooksCapable) {
        $hooksRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.HooksDirectoryName
        if (-not (Test-Path -LiteralPath $hooksRoot)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.HooksMissing -f $normalizedMode, $hooksRoot)
        }

        foreach ($hookFileName in $script:CopilotPathConstant.SmokeExpectedHookFileNames) {
            $hookPath = Join-Path $hooksRoot $hookFileName
            if (-not (Test-Path -LiteralPath $hookPath)) {
                return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.HooksMissing -f $normalizedMode, $hookPath)
            }
            $completed.Add(('hook:{0}' -f $hookFileName))
        }

        $hooksJsonPath = Join-Path $hooksRoot 'hooks.json'
        try {
            $hooksObj = Get-Content -LiteralPath $hooksJsonPath -Raw | ConvertFrom-Json
        }
        catch {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.HooksJsonInvalid -f $normalizedMode, $hooksJsonPath)
        }
        if ($null -eq $hooksObj.version -or [int]$hooksObj.version -ne 1) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.HooksJsonInvalid -f $normalizedMode, ('{0} (expected version:1)' -f $hooksJsonPath))
        }
        if ($null -eq $hooksObj.hooks -or -not ($hooksObj.hooks.PSObject.Properties.Name -contains 'preToolUse')) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.HooksJsonInvalid -f $normalizedMode, ('{0} (missing preToolUse)' -f $hooksJsonPath))
        }
        $completed.Add('hooks-json-schema')
    }

    if ($normalizedMode -eq $script:CopilotPathConstant.ModeRepo) {
        $customAgentsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CustomAgentsDirectoryName
        foreach ($agentFileName in @($script:ToolkitConstant.ExpectedCustomAgentFileNames)) {
            $agentPath = Join-Path $customAgentsRoot $agentFileName
            if (-not (Test-Path -LiteralPath $agentPath -PathType Leaf)) {
                return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.CustomAgentsMissing -f $agentPath)
            }
            $completed.Add(('custom-agent:{0}' -f $agentFileName))
        }
    }

    try {
        Assert-CopilotSmokeNoExcludedIdePaths -InstallRoot $resolvedInstallRoot -Mode $normalizedMode
        $completed.Add('no-excluded-ide-paths')
    }
    catch {
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message $_.Exception.Message
    }

    $sddMissing = [System.Collections.Generic.List[string]]::new()
    $sddOk = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $sddMissing
    $checks.SddLayoutPresent = $sddOk
    if (-not $sddOk) {
        $listText = ($sddMissing.ToArray() -join ', ')
        return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.ArtifactMissing -f $normalizedMode, $listText)
    }
    $completed.Add('sdd-layout')

    return [PSCustomObject]@{
        Success                 = $true
        Implemented             = $true
        CommandName             = 'Invoke-SmokeValidate'
        Mode                    = $normalizedMode
        InstallRoot             = $resolvedInstallRoot
        Message                 = ($script:CopilotSmokeMessage.Passed -f $normalizedMode, $resolvedInstallRoot)
        ExitCode                = 0
        SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        Checks                  = [PSCustomObject]$checks
        CompletedArtifacts      = @($completed)
    }
}
