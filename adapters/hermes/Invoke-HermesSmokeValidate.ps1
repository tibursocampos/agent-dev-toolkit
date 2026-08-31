#Requires -Version 5.1
<#
.SYNOPSIS
  Hermes filesystem smoke validate (InstallRoot = ~/.hermes layout; TE01-TE05 files only).
#>

function Test-HermesPathHasSkillManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot)) {
        return $false
    }

    $manifestName = $script:HermesAdapterConstant.SkillManifestFileName
    $manifests = @(Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter $manifestName -ErrorAction SilentlyContinue)
    return ($manifests.Count -gt 0)
}

function Test-HermesAgentsMdContainsPolicyFold {
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

    return $text.Contains($script:HermesAdapterConstant.PolicyFoldSectionHeading)
}

function Test-HermesAgentsMdContainsSpawnBridge {
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

    return $text.Contains($script:HermesAdapterConstant.SpawnBridgeSectionHeading)
}

function Test-HermesForbiddenRulesTreePublished {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $rulesRoot = Join-Path $InstallRoot $script:HermesAdapterConstant.CursorRulesDirectoryName
    if (-not (Test-Path -LiteralPath $rulesRoot)) {
        return $false
    }

    $sourcePolicyRoot = Join-Path (Join-Path $RepoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.PolicyDirectoryName
    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        return $false
    }

    $policyFiles = Get-ChildItem -LiteralPath $sourcePolicyRoot -File
    foreach ($file in $policyFiles) {
        $candidate = Join-Path $rulesRoot $file.Name
        if (Test-Path -LiteralPath $candidate) {
            return $true
        }
    }

    return $false
}

function Test-HermesForbiddenHooksPublished {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksRoot
    )

    if (-not (Test-Path -LiteralPath $HooksRoot)) {
        return $false
    }

    $hooksJsonName = $script:HermesAdapterConstant.ForbiddenToolkitHooksJsonFileName
    $hooksJsonPath = Join-Path $HooksRoot $hooksJsonName
    return (Test-Path -LiteralPath $hooksJsonPath)
}

function Test-HermesRequiredPluginHooksPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $MappedPaths
    )

    $missing = [System.Collections.Generic.List[string]]::new()
    $pluginRoot = Join-Path $MappedPaths.FixturePluginsPath $script:HermesAdapterConstant.GuardPluginDirectoryName
    foreach ($name in @($script:HermesAdapterConstant.SmokeExpectedPluginFileNames)) {
        $candidate = Join-Path $pluginRoot $name
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $missing.Add(('plugins/{0}/{1}' -f $script:HermesAdapterConstant.GuardPluginDirectoryName, $name))
        }
    }

    foreach ($name in @($script:HermesAdapterConstant.SmokeExpectedAgentHookFileNames)) {
        $candidate = Join-Path $MappedPaths.FixtureAgentHooksPath $name
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $missing.Add(('agent-hooks/{0}' -f $name))
        }
    }

    $configOk = $false
    if (Test-Path -LiteralPath $MappedPaths.FixtureConfigYamlPath -PathType Leaf) {
        $yaml = [System.IO.File]::ReadAllText($MappedPaths.FixtureConfigYamlPath)
        $pluginName = $script:HermesAdapterConstant.GuardPluginDirectoryName
        $hasPlugin = $yaml -match ("(?m)^\s*-\s*{0}\s*$" -f [regex]::Escape($pluginName))
        $hasMatcher = $yaml -match [regex]::Escape($script:HermesAdapterConstant.HooksPreToolCallMatcher)
        $configOk = $hasPlugin -and $hasMatcher
    }
    if (-not $configOk) {
        $missing.Add('config.yaml (plugins.enabled + hooks.pre_tool_call)')
    }

    return [PSCustomObject]@{
        Ok      = ($missing.Count -eq 0)
        Missing = @($missing.ToArray())
    }
}

function Test-HermesCompatArtifactsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $claudeRoot = Join-Path $InstallRoot ($script:HermesAdapterConstant.CompatClaudeRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $cursorRoot = Join-Path $InstallRoot ($script:HermesAdapterConstant.CompatCursorRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $skillsName = $script:HermesAdapterConstant.CompatSkillsDirectoryName
    $rulesName = $script:HermesAdapterConstant.CompatRulesDirectoryName

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

function New-HermesSmokeValidateResult {
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
        $script:HermesAdapterConstant.SmokeExitCodeSuccess
    }
    else {
        $script:HermesAdapterConstant.SmokeExitCodeFailure
    }

    return [PSCustomObject]@{
        Success     = $Success
        Implemented = $true
        CommandName = 'Invoke-SmokeValidate'
        InstallRoot = $InstallRoot
        Checks      = [PSCustomObject]$Checks
        Message     = $Message
        ExitCode    = $exitCode
    }
}

function Invoke-HermesSmokeValidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    $repoRoot = Get-HermesAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:HermesAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:HermesAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $caps = Get-Capabilities -AgentId $script:HermesAdapterAgentId
    $capabilityFlags = $caps.Capabilities

    $hasNativeSkills = Test-HermesPathHasSkillManifest -SkillsRoot $mapped.FixtureSkillsPath
    $hasPolicyFold = Test-HermesAgentsMdContainsPolicyFold -AgentsMdPath $mapped.FixtureProjectAgentsPath
    $hasSpawnBridge = Test-HermesAgentsMdContainsSpawnBridge -AgentsMdPath $mapped.FixtureProjectAgentsPath
    $hasNativeRouter = Test-Path -LiteralPath $mapped.FixtureProjectAgentsPath
    $hasForbiddenRulesTree = Test-HermesForbiddenRulesTreePublished -InstallRoot $resolvedInstallRoot -RepoRoot $repoRoot
    $hasForbiddenHooks = Test-HermesForbiddenHooksPublished -HooksRoot $mapped.FixtureHooksPath
    $requiredHooks = Test-HermesRequiredPluginHooksPresent -MappedPaths $mapped
    $hasCompatArtifacts = Test-HermesCompatArtifactsPresent -InstallRoot $resolvedInstallRoot
    $hasMemory = Test-Path -LiteralPath $mapped.FixtureMemoryPath

    $sddMissing = [System.Collections.Generic.List[string]]::new()
    $hasSddLayout = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $sddMissing

    $checks = [ordered]@{
        SkillsPresent        = $hasNativeSkills
        PolicyFoldPresent    = $hasPolicyFold
        SpawnBridgePresent   = $hasSpawnBridge
        RouterPresent        = $hasNativeRouter
        ForbiddenRulesTree   = $hasForbiddenRulesTree
        ForbiddenHooks       = $hasForbiddenHooks
        PluginHooksPresent   = $requiredHooks.Ok
        CompatPresent        = $hasCompatArtifacts
        MemoryPresent        = $hasMemory
        SddLayoutPresent     = $hasSddLayout
        SkillsTrustNote      = $script:HermesAdapterConstant.SkillsTrustNote
    }

    $skillsCapable = [bool]$capabilityFlags.skills
    $rulesCapable = [bool]$capabilityFlags.rules
    $routerCapable = [bool]$capabilityFlags.router
    $hooksCapable = [bool]$capabilityFlags.hooks
    $pluginCapable = [bool]$capabilityFlags.plugin

    $nativeRequiredMissing = $false
    if ($skillsCapable -and -not $hasNativeSkills) { $nativeRequiredMissing = $true }
    if ($rulesCapable -and -not $hasPolicyFold) { $nativeRequiredMissing = $true }
    if ($rulesCapable -and -not $hasSpawnBridge) { $nativeRequiredMissing = $true }
    if ($routerCapable -and -not $hasNativeRouter) { $nativeRequiredMissing = $true }

    if ($hasCompatArtifacts -and $nativeRequiredMissing) {
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe04CompatOnly -f $resolvedInstallRoot
        )
    }

    if ($skillsCapable -and -not $hasNativeSkills) {
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe02SkillsMissing -f $mapped.FixtureSkillsPath
        )
    }

    if ($hasForbiddenRulesTree) {
        $rulesRoot = Join-Path $resolvedInstallRoot $script:HermesAdapterConstant.CursorRulesDirectoryName
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe03ForbiddenRulesTree -f $rulesRoot
        )
    }

    if ($hasForbiddenHooks) {
        $hooksJsonPath = Join-Path $mapped.FixtureHooksPath $script:HermesAdapterConstant.ForbiddenToolkitHooksJsonFileName
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe03ForbiddenHooks -f $hooksJsonPath
        )
    }

    if (($hooksCapable -or $pluginCapable) -and -not $requiredHooks.Ok) {
        $missingText = ($requiredHooks.Missing -join ', ')
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe03HooksMissing -f $resolvedInstallRoot, $missingText
        )
    }

    if ($rulesCapable -and -not $hasPolicyFold) {
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe03PolicyFoldMissing -f $mapped.FixtureProjectAgentsPath
        )
    }

    if ($rulesCapable -and -not $hasSpawnBridge) {
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe03SpawnBridgeMissing -f $mapped.FixtureProjectAgentsPath
        )
    }

    if ($routerCapable -and -not $hasNativeRouter) {
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe03RouterMissing -f $mapped.FixtureProjectAgentsPath
        )
    }

    if (-not $hasMemory) {
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeMemoryMissing -f $mapped.FixtureMemoryPath
        )
    }

    if (-not $hasSddLayout) {
        $listText = ($sddMissing.ToArray() -join ', ')
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe05SddLayoutMissing -f $resolvedInstallRoot, $listText
        )
    }

    return New-HermesSmokeValidateResult -Success $true -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
        $script:HermesAdapterMessage.SmokePassed -f $resolvedInstallRoot
    )
}
