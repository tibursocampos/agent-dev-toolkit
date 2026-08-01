#Requires -Version 5.1
<#
.SYNOPSIS
  Grok filesystem smoke validate (native .grok layout; TE01-TE05 files only).
#>

function Test-GrokPathHasSkillManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot)) {
        return $false
    }

    $manifestName = $script:GrokAdapterConstant.SkillManifestFileName
    $manifests = @(Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter $manifestName -ErrorAction SilentlyContinue)
    return ($manifests.Count -gt 0)
}

function Test-GrokPathHasMarkdownFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DirectoryPath
    )

    if (-not (Test-Path -LiteralPath $DirectoryPath)) {
        return $false
    }

    $extension = $script:GrokAdapterConstant.MarkdownExtension
    $files = @(Get-ChildItem -LiteralPath $DirectoryPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
            [string]::Equals($_.Extension, $extension, [System.StringComparison]::OrdinalIgnoreCase)
        })
    return ($files.Count -gt 0)
}

function Test-GrokNativeHooksPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksRoot
    )

    if (-not (Test-Path -LiteralPath $HooksRoot)) {
        return $false
    }

    $hooksJsonPath = Join-Path $HooksRoot $script:GrokAdapterConstant.HooksJsonFileName
    if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
        return $false
    }

    try {
        $hooksJson = Get-Content -LiteralPath $hooksJsonPath -Raw | ConvertFrom-Json
        if ($null -eq $hooksJson.hooks) {
            return $false
        }
        if ($null -eq $hooksJson.hooks.SessionStart) {
            return $false
        }
        return $true
    }
    catch {
        return $false
    }
}

function Test-GrokCompatArtifactsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $claudeRoot = Join-Path $InstallRoot ($script:GrokAdapterConstant.CompatClaudeRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $cursorRoot = Join-Path $InstallRoot ($script:GrokAdapterConstant.CompatCursorRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $skillsName = $script:GrokAdapterConstant.CompatSkillsDirectoryName
    $rulesName = $script:GrokAdapterConstant.CompatRulesDirectoryName

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

function New-GrokSmokeValidateResult {
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
        $script:GrokAdapterConstant.SmokeExitCodeSuccess
    }
    else {
        $script:GrokAdapterConstant.SmokeExitCodeFailure
    }

    return [PSCustomObject]@{
        Success        = $Success
        Implemented    = $true
        CommandName    = 'Invoke-SmokeValidate'
        InstallRoot    = $InstallRoot
        Checks         = [PSCustomObject]$Checks
        HooksTrustNote = $script:GrokAdapterConstant.HooksTrustNote
        Te05Note       = $script:GrokAdapterMessage.SmokeTe05FilesOnlyNote
        Message        = $Message
        ExitCode       = $exitCode
    }
}

function Invoke-GrokSmokeValidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    # TE01: invalid / USERPROFILE InstallRoot without -AllowUserHome fails inside Resolve-InstallRoot.
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $caps = Get-Capabilities -AgentId $script:GrokAdapterAgentId
    $capabilityFlags = $caps.Capabilities

    $hasNativeSkills = Test-GrokPathHasSkillManifest -SkillsRoot $mapped.FixtureSkillsPath
    $hasNativeRules = Test-GrokPathHasMarkdownFiles -DirectoryPath $mapped.FixtureRulesPath
    $hasNativeHooks = Test-GrokNativeHooksPresent -HooksRoot $mapped.FixtureHooksPath
    $hasNativeRouter = Test-Path -LiteralPath $mapped.FixtureProjectAgentsPath
    $hasCompatArtifacts = Test-GrokCompatArtifactsPresent -InstallRoot $resolvedInstallRoot

    $sddMissing = [System.Collections.Generic.List[string]]::new()
    $hasSddLayout = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $sddMissing

    $checks = [ordered]@{
        SkillsPresent    = $hasNativeSkills
        RulesPresent     = $hasNativeRules
        HooksPresent     = $hasNativeHooks
        RouterPresent    = $hasNativeRouter
        CompatPresent    = $hasCompatArtifacts
        SddLayoutPresent = $hasSddLayout
        HooksTrustNote   = $script:GrokAdapterConstant.HooksTrustNote
    }

    $skillsCapable = [bool]$capabilityFlags.skills
    $rulesCapable = [bool]$capabilityFlags.rules
    $hooksCapable = [bool]$capabilityFlags.hooks
    $routerCapable = [bool]$capabilityFlags.router

    $nativeRequiredMissing = $false
    if ($skillsCapable -and -not $hasNativeSkills) { $nativeRequiredMissing = $true }
    if ($rulesCapable -and -not $hasNativeRules) { $nativeRequiredMissing = $true }
    if ($hooksCapable -and -not $hasNativeHooks) { $nativeRequiredMissing = $true }
    if ($routerCapable -and -not $hasNativeRouter) { $nativeRequiredMissing = $true }

    # TE04: compat-only layout (RN02) - Claude/Cursor present without required native .grok.
    if ($hasCompatArtifacts -and $nativeRequiredMissing) {
        return New-GrokSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:GrokAdapterMessage.SmokeTe04CompatOnly -f $resolvedInstallRoot
        )
    }

    if ($skillsCapable -and -not $hasNativeSkills) {
        return New-GrokSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:GrokAdapterMessage.SmokeTe02SkillsMissing -f $mapped.FixtureSkillsPath
        )
    }

    if ($rulesCapable -and -not $hasNativeRules) {
        return New-GrokSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:GrokAdapterMessage.SmokeTe03RulesMissing -f $mapped.FixtureRulesPath
        )
    }

    if ($hooksCapable -and -not $hasNativeHooks) {
        $expectedJson = Join-Path $mapped.FixtureHooksPath $script:GrokAdapterConstant.HooksJsonFileName
        return New-GrokSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:GrokAdapterMessage.SmokeTe03HooksMissing -f $mapped.FixtureHooksPath, $expectedJson
        )
    }

    if ($routerCapable -and -not $hasNativeRouter) {
        return New-GrokSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:GrokAdapterMessage.SmokeTe03RouterMissing -f $mapped.FixtureProjectAgentsPath
        )
    }

    if (-not $hasSddLayout) {
        $listText = ($sddMissing.ToArray() -join ', ')
        return New-GrokSmokeValidateResult -Success $false -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
            $script:GrokAdapterMessage.SmokeTe05SddLayoutMissing -f $resolvedInstallRoot, $listText
        )
    }

    return New-GrokSmokeValidateResult -Success $true -InstallRoot $resolvedInstallRoot -Checks $checks -Message (
        $script:GrokAdapterMessage.SmokePassed -f $resolvedInstallRoot
    )
}

