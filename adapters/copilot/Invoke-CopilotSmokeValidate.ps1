#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem-only smoke checks for the Copilot adapter.

.DESCRIPTION
  Validates skills, instructions, and hooks under InstallRoot for -Mode user|repo. Hooks are hooks.json only; no guard files are shipped.
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
        EvidenceType            = 'static'
        HostExecutionStatus     = 'SKIPPED'
        HostSurface             = 'filesystem-fixture'
        FailureCode             = 'static-check-failed'
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
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
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
        $instructionText = [System.IO.File]::ReadAllText($instructionPath)
        if (-not $instructionText.Contains($script:CopilotPathConstant.ApplyToAllFrontmatterToken)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.InstructionApplyToMissing -f $normalizedMode, $instructionPath)
        }
        $completed.Add(('instruction:{0}' -f $baseName))
    }

    foreach ($instructionFile in @(Get-ChildItem -LiteralPath $instructionsRoot -File -Filter ('*' + $script:CopilotPathConstant.InstructionsFileExtension))) {
        $instructionText = [System.IO.File]::ReadAllText($instructionFile.FullName)
        if ($instructionText -match ('(?m)^' + [regex]::Escape($script:CopilotPathConstant.SmokeAlwaysApplyFrontmatterKey))) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.InstructionAlwaysApplyLeft -f $normalizedMode, $instructionFile.FullName)
        }
    }
    $completed.Add('instructions:applyTo-mapped')

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
        if ($null -eq $hooksObj.hooks) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.HooksJsonInvalid -f $normalizedMode, ('{0} (missing hooks object)' -f $hooksJsonPath))
        }
        if (@($hooksObj.hooks.PSObject.Properties | ForEach-Object { $_.Name }) -contains 'preToolUse') {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.HooksJsonInvalid -f $normalizedMode, ('{0} (preToolUse must not be registered)' -f $hooksJsonPath))
        }
        $completed.Add('hooks-json-schema')
    }

    $customAgentsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CustomAgentsDirectoryName
    foreach ($sourceAgentFileName in @($script:ToolkitConstant.ExpectedCustomAgentFileNames)) {
        $agentFileName = [System.IO.Path]::GetFileNameWithoutExtension($sourceAgentFileName) + $script:CopilotPathConstant.CustomAgentProfileExtension
        $agentPath = Join-Path $customAgentsRoot $agentFileName
        if (-not (Test-Path -LiteralPath $agentPath -PathType Leaf)) {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.CustomAgentsMissing -f $normalizedMode, $agentPath)
        }
        $completed.Add(('custom-agent:{0}' -f $agentFileName))

        $agentContent = [System.IO.File]::ReadAllText($agentPath)
        if ($agentContent -notmatch '(?s)^---\r?\n.*?\r?\n---') {
            return New-CopilotSmokeFailureResult -Mode $normalizedMode -InstallRoot $resolvedInstallRoot -Checks $checks -Message ($script:CopilotSmokeMessage.CustomAgentsMissing -f $normalizedMode, ($agentPath + ' (invalid frontmatter)'))
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
        EvidenceType            = 'static'
        HostExecutionStatus     = 'SKIPPED'
        HostSurface             = 'filesystem-fixture'
        FailureCode             = $null
        SmokeFilesystemOnlyNote = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        Checks                  = [PSCustomObject]$checks
        CompletedArtifacts      = @($completed)
    }
}
