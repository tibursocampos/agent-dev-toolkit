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
    $hasNativeRouter = Test-Path -LiteralPath $mapped.FixtureProjectAgentsPath
    $hasForbiddenRulesTree = Test-HermesForbiddenRulesTreePublished -InstallRoot $resolvedInstallRoot -RepoRoot $repoRoot
    $hasForbiddenHooks = Test-HermesForbiddenHooksPublished -HooksRoot $mapped.FixtureHooksPath
    $hasCompatArtifacts = Test-HermesCompatArtifactsPresent -InstallRoot $resolvedInstallRoot
    $hasMemory = Test-Path -LiteralPath $mapped.FixtureMemoryPath

    $sddMissing = [System.Collections.Generic.List[string]]::new()
    $hasSddLayout = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $sddMissing

    $checks = [ordered]@{
        SkillsPresent        = $hasNativeSkills
        PolicyFoldPresent    = $hasPolicyFold
        RouterPresent        = $hasNativeRouter
        ForbiddenRulesTree   = $hasForbiddenRulesTree
        ForbiddenHooks       = $hasForbiddenHooks
        CompatPresent        = $hasCompatArtifacts
        MemoryPresent        = $hasMemory
        SddLayoutPresent     = $hasSddLayout
        SkillsTrustNote      = $script:HermesAdapterConstant.SkillsTrustNote
    }

    $skillsCapable = [bool]$capabilityFlags.skills
    $rulesCapable = [bool]$capabilityFlags.rules
    $routerCapable = [bool]$capabilityFlags.router

    $nativeRequiredMissing = $false
    if ($skillsCapable -and -not $hasNativeSkills) { $nativeRequiredMissing = $true }
    if ($rulesCapable -and -not $hasPolicyFold) { $nativeRequiredMissing = $true }
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

    if ($rulesCapable -and -not $hasPolicyFold) {
        return New-HermesSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:HermesAdapterMessage.SmokeTe03PolicyFoldMissing -f $mapped.FixtureProjectAgentsPath
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
