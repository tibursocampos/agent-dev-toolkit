#Requires -Version 5.1
<#
.SYNOPSIS
  OpenHands filesystem smoke validate (project tree; TE01-TE05 files only).
#>

function Test-OpenHandsPathHasSkillManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot)) {
        return $false
    }

    $manifestName = $script:OpenHandsAdapterConstant.SkillManifestFileName
    $manifests = @(Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter $manifestName -ErrorAction SilentlyContinue)
    return ($manifests.Count -gt 0)
}

function Test-OpenHandsPolicyFoldedIntoAgentsMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentsMdPath
    )

    if (-not (Test-Path -LiteralPath $AgentsMdPath)) {
        return $false
    }

    $text = [System.IO.File]::ReadAllText($AgentsMdPath)
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $false
    }

    $hasHeading = $text.Contains($script:OpenHandsAdapterConstant.RulesAlwaysOnHeading)
    $hasFoldIntro = $text.Contains($script:OpenHandsAdapterConstant.RulesFoldIntro.Trim().Substring(0, [Math]::Min(40, $script:OpenHandsAdapterConstant.RulesFoldIntro.Trim().Length)))
    $hasGuardrails = $text.Contains($script:OpenHandsAdapterConstant.KnownPolicyGuardrailsBaseName)
    return ($hasHeading -and $hasFoldIntro -and $hasGuardrails)
}

function Test-OpenHandsCursorRulesTreePresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $rulesRoot = Join-Path $InstallRoot $script:OpenHandsAdapterConstant.RulesDirectoryName
    if (-not (Test-Path -LiteralPath $rulesRoot)) {
        return $false
    }

    $mdc = $script:OpenHandsAdapterConstant.CursorRuleExtension
    $files = @(Get-ChildItem -LiteralPath $rulesRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
            [string]::Equals($_.Extension, $mdc, [System.StringComparison]::OrdinalIgnoreCase)
        })
    return ($files.Count -gt 0)
}

function Test-OpenHandsNativeHooksPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksRoot,

        [Parameter(Mandatory = $true)]
        [string] $HooksScriptsRoot
    )

    $hooksJsonPath = Join-Path $HooksRoot $script:OpenHandsAdapterConstant.HooksJsonFileName
    $hooksScriptPath = Join-Path $HooksScriptsRoot $script:OpenHandsAdapterConstant.HooksSessionStartScriptName
    if (-not ((Test-Path -LiteralPath $hooksJsonPath) -and (Test-Path -LiteralPath $hooksScriptPath))) {
        return $false
    }

    try {
        $hooksJson = Get-Content -LiteralPath $hooksJsonPath -Raw | ConvertFrom-Json
        $eventName = $script:OpenHandsAdapterConstant.HooksSessionStartEventSnake
        $eventValue = $hooksJson.$eventName
        if ($null -eq $eventValue) {
            return $false
        }
        return $true
    }
    catch {
        return $false
    }
}

function Test-OpenHandsPluginManifestPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        return $false
    }

    try {
        $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        if ([string]::IsNullOrWhiteSpace([string]$manifest.name)) {
            return $false
        }
        if ([string]::IsNullOrWhiteSpace([string]$manifest.version)) {
            return $false
        }
        if ([string]::IsNullOrWhiteSpace([string]$manifest.description)) {
            return $false
        }
        return $true
    }
    catch {
        return $false
    }
}

function Test-OpenHandsCustomAgentsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentsRoot
    )

    if (-not (Test-Path -LiteralPath $AgentsRoot)) {
        return $false
    }

    $extension = $script:OpenHandsAdapterConstant.MarkdownExtension
    $files = @(Get-ChildItem -LiteralPath $AgentsRoot -File -ErrorAction SilentlyContinue | Where-Object {
            [string]::Equals($_.Extension, $extension, [System.StringComparison]::OrdinalIgnoreCase)
        })
    return ($files.Count -gt 0)
}

function Test-OpenHandsCompatArtifactsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $claudeRoot = Join-Path $InstallRoot (Convert-OpenHandsRelativeToOsPath -RelativePath $script:OpenHandsAdapterConstant.CompatClaudeRootRelativePath)
    $cursorRoot = Join-Path $InstallRoot (Convert-OpenHandsRelativeToOsPath -RelativePath $script:OpenHandsAdapterConstant.CompatCursorRootRelativePath)
    $skillsName = $script:OpenHandsAdapterConstant.CompatSkillsDirectoryName
    $rulesName = $script:OpenHandsAdapterConstant.CompatRulesDirectoryName

    $candidates = @(
        (Join-Path $claudeRoot $skillsName),
        (Join-Path $cursorRoot $skillsName),
        (Join-Path $claudeRoot $rulesName),
        (Join-Path $cursorRoot $rulesName)
    )

    foreach ($candidate in $candidates) {
        if (-not (Test-Path -LiteralPath $candidate)) {
            continue
        }
        $files = @(Get-ChildItem -LiteralPath $candidate -Recurse -File -ErrorAction SilentlyContinue)
        if ($files.Count -gt 0) {
            return $true
        }
    }

    return $false
}

function New-OpenHandsSmokeValidateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Success,
        [Parameter(Mandatory = $true)]
        [string] $Message,
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [hashtable] $Checks = @{}
    )

    $exitCode = if ($Success) {
        $script:OpenHandsAdapterConstant.SmokeExitCodeSuccess
    }
    else {
        $script:OpenHandsAdapterConstant.SmokeExitCodeFailure
    }

    return [PSCustomObject]@{
        Success        = $Success
        Implemented    = $true
        CommandName    = 'Invoke-SmokeValidate'
        InstallRoot    = $InstallRoot
        Checks         = [PSCustomObject]$Checks
        HooksTrustNote = $script:OpenHandsAdapterConstant.HooksFilesystemOnlyNote
        Te05Note       = $script:OpenHandsAdapterMessage.SmokeFilesystemOnlyNote
        Message        = $Message
        ExitCode       = $exitCode
    }
}

function Invoke-OpenHandsSmokeValidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    $repoRoot = Get-OpenHandsAdapterRepoRoot
    Initialize-OpenHandsInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $caps = Get-Capabilities -AgentId $script:OpenHandsAdapterAgentId
    $capabilityFlags = $caps.Capabilities

    $hasNativeSkills = Test-OpenHandsPathHasSkillManifest -SkillsRoot $mapped.FixtureSkillsPath
    $hasFoldedPolicy = Test-OpenHandsPolicyFoldedIntoAgentsMd -AgentsMdPath $mapped.FixtureProjectAgentsPath
    $hasRulesTree = Test-OpenHandsCursorRulesTreePresent -InstallRoot $resolvedInstallRoot
    $hasNativeHooks = Test-OpenHandsNativeHooksPresent -HooksRoot $mapped.FixtureHooksPath -HooksScriptsRoot $mapped.FixtureHooksScriptsPath
    $hasNativeRouter = Test-Path -LiteralPath $mapped.FixtureProjectAgentsPath
    $hasPlugin = Test-OpenHandsPluginManifestPresent -ManifestPath $mapped.FixturePluginManifestPath
    $hasCustomAgents = Test-OpenHandsCustomAgentsPresent -AgentsRoot $mapped.FixtureCustomAgentsPath
    $hasCompatArtifacts = Test-OpenHandsCompatArtifactsPresent -InstallRoot $resolvedInstallRoot

    $sddMissing = [System.Collections.Generic.List[string]]::new()
    $hasSddLayout = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $sddMissing

    $checks = [ordered]@{
        SkillsPresent     = $hasNativeSkills
        PolicyFolded      = $hasFoldedPolicy
        RulesTreePresent  = $hasRulesTree
        HooksPresent      = $hasNativeHooks
        RouterPresent     = $hasNativeRouter
        PluginPresent     = $hasPlugin
        AgentsPresent     = $hasCustomAgents
        CompatPresent     = $hasCompatArtifacts
        SddLayoutPresent  = $hasSddLayout
        HooksTrustNote    = $script:OpenHandsAdapterConstant.HooksFilesystemOnlyNote
    }

    $skillsCapable = [bool]$capabilityFlags.skills
    $rulesCapable = [bool]$capabilityFlags.rules
    $hooksCapable = [bool]$capabilityFlags.hooks
    $routerCapable = [bool]$capabilityFlags.router
    $pluginCapable = [bool]$capabilityFlags.plugin
    $agentsCapable = [bool]$capabilityFlags.agents

    $nativeRequiredMissing = $false
    if ($skillsCapable -and -not $hasNativeSkills) { $nativeRequiredMissing = $true }
    if ($rulesCapable -and -not $hasFoldedPolicy) { $nativeRequiredMissing = $true }
    if ($hooksCapable -and -not $hasNativeHooks) { $nativeRequiredMissing = $true }
    if ($routerCapable -and -not $hasNativeRouter) { $nativeRequiredMissing = $true }

    if ($hasCompatArtifacts -and $nativeRequiredMissing) {
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe04CompatOnly -f $resolvedInstallRoot
        )
    }

    if ($skillsCapable -and -not $hasNativeSkills) {
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe02SkillsMissing -f $mapped.FixtureSkillsPath
        )
    }

    if ($rulesCapable -and $hasRulesTree) {
        $rulesRoot = Join-Path $resolvedInstallRoot $script:OpenHandsAdapterConstant.RulesDirectoryName
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe03RulesTreePresent -f $rulesRoot
        )
    }

    if ($rulesCapable -and -not $hasFoldedPolicy) {
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe03PolicyNotFolded -f $mapped.FixtureProjectAgentsPath
        )
    }

    if ($hooksCapable -and -not $hasNativeHooks) {
        $expectedJson = Join-Path $mapped.FixtureHooksPath $script:OpenHandsAdapterConstant.HooksJsonFileName
        $expectedScript = Join-Path $mapped.FixtureHooksScriptsPath $script:OpenHandsAdapterConstant.HooksSessionStartScriptName
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe03HooksMissing -f $expectedJson, $expectedScript
        )
    }

    if ($routerCapable -and -not $hasNativeRouter) {
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe03RouterMissing -f $mapped.FixtureProjectAgentsPath
        )
    }

    if ($pluginCapable -and -not $hasPlugin) {
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe03PluginMissing -f $mapped.FixturePluginManifestPath
        )
    }

    if ($agentsCapable -and -not $hasCustomAgents) {
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe03AgentsMissing -f $mapped.FixtureCustomAgentsPath
        )
    }

    if (-not $hasSddLayout) {
        $listText = ($sddMissing.ToArray() -join ', ')
        return New-OpenHandsSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:OpenHandsAdapterMessage.SmokeTe05SddLayoutMissing -f $resolvedInstallRoot, $listText
        )
    }

    return New-OpenHandsSmokeValidateResult -Success $true -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
        $script:OpenHandsAdapterMessage.SmokePassed -f $resolvedInstallRoot
    )
}
