#Requires -Version 5.1
<#
.SYNOPSIS
  Filesystem-only Antigravity Invoke-SmokeValidate helper.

.DESCRIPTION
  Asserts InstallRoot models the official ~/.gemini layout after sync:
  - config/skills/<kebab-id>/SKILL.md (CA3 / TE04)
  - config/skills.json managed entry (CA1)
  - config/plugins/agent-dev-toolkit/GUARDRAILS.md (CA1)
  - config/skills/dev_persona/SKILL.md (CA1)
  - managed markers in config/AGENTS.md and/or config/GEMINI.md (CA1)
  Fails on underscore-only skill trees (TE04) or missing GUARDRAILS/dev_persona (TE05).
  Hooks capability is false: smoke ignores config/hooks and the legacy bridge (CA4 N/A).
  Resolves InstallRoot via Resolve-InstallRoot (TE01). Never writes outside InstallRoot.
#>

$script:AntigravitySmokeHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:AntigravitySmokeHelperDirectory)) {
    $script:AntigravitySmokeHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:AntigravitySmokeMessage = @{
    Passed                   = 'Antigravity Invoke-SmokeValidate PASS under {0} (filesystem-only; official config/*; hooks ignored - capability false; legacy bridge not gated).'
    Te01InvalidInstallRoot   = 'Antigravity Invoke-SmokeValidate TE01: InstallRoot rejected ({0}). Use an in-repo fixture or pass -AllowUserHome for USERPROFILE paths.'
    Te04UnderscoreOnlySkills = 'Antigravity Invoke-SmokeValidate TE04: kebab skill folders missing under {0}; underscore-only or empty skill tree is not allowed (CA3).'
    Te05MissingArtifacts     = 'Antigravity Invoke-SmokeValidate TE05: required artifact(s) missing or incomplete under InstallRoot: {0}'
    FilesystemOnlyNote       = 'Smoke validates published files under InstallRoot only; hooks and antigravity-ide/plugins are out of default smoke scope.'
}

function New-AntigravitySmokeResult {
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
        Success                = $Success
        Implemented            = $true
        CommandName            = 'Invoke-SmokeValidate'
        AgentId                = $script:AntigravityAdapterAgentId
        FilesystemOnly         = $true
        RequiresRuntime        = $false
        RequiresShellHooks     = $false
        SmokeIgnoresHooks      = $true
        SmokeTargetsLegacyBridge = $false
        ErrorCode              = $ErrorCode
        ResolvedInstallRoot    = $ResolvedInstallRoot
        Checks                 = [PSCustomObject]$Checks
        MissingRelativePaths   = @($MissingRelativePaths)
        Te05Note               = $script:AntigravitySmokeMessage.FilesystemOnlyNote
        Message                = $Message
        ExitCode               = $ExitCode
    }
}

function Test-AntigravitySmokeIsKebabSkillFolderName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ([string]::Equals($Name, $script:AntigravityPathConstant.SharedSkillsDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    if ([string]::Equals($Name, $script:AntigravityPathConstant.DevPersonaSkillDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    return $Name -match $script:AntigravityPathConstant.KebabSkillFolderNamePattern
}

function Test-AntigravitySmokeIsUnderscoreSkillFolderName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ([string]::Equals($Name, $script:AntigravityPathConstant.SharedSkillsDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    if ([string]::Equals($Name, $script:AntigravityPathConstant.DevPersonaSkillDirectoryName, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    return $Name -match $script:AntigravityPathConstant.UnderscoreSkillFolderNamePattern
}

function Get-AntigravitySmokeSkillFolderStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    $kebabCount = 0
    $underscoreCount = 0
    $manifestName = $script:AntigravityPathConstant.SkillManifestFileName

    if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
        return [PSCustomObject]@{
            KebabManifestCount       = 0
            UnderscoreManifestCount  = 0
            SkillsRootPresent        = $false
        }
    }

    $skillDirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory -Force -ErrorAction SilentlyContinue
    foreach ($dir in $skillDirs) {
        $manifestPath = Join-Path $dir.FullName $manifestName
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            continue
        }

        if (Test-AntigravitySmokeIsKebabSkillFolderName -Name $dir.Name) {
            $kebabCount++
        }
        elseif (Test-AntigravitySmokeIsUnderscoreSkillFolderName -Name $dir.Name) {
            $underscoreCount++
        }
    }

    return [PSCustomObject]@{
        KebabManifestCount      = $kebabCount
        UnderscoreManifestCount = $underscoreCount
        SkillsRootPresent       = $true
    }
}

function Test-AntigravitySmokeSkillsJsonPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsJsonPath,

        [Parameter(Mandatory = $true)]
        [string] $OfficialSkillsRelativePath
    )

    if (-not (Test-Path -LiteralPath $SkillsJsonPath -PathType Leaf)) {
        return $false
    }

    try {
        $json = [System.IO.File]::ReadAllText($SkillsJsonPath) | ConvertFrom-Json
    }
    catch {
        return $false
    }

    if ($null -eq $json) {
        return $false
    }

    $entriesProp = $script:AntigravityAdapterConstant.SkillsJsonEntriesPropertyName
    $idProp = $script:AntigravityAdapterConstant.SkillsJsonIdPropertyName
    $pathProp = $script:AntigravityAdapterConstant.SkillsJsonPathPropertyName
    $managedId = $script:AntigravityAdapterConstant.ManagedSkillsJsonEntryId

    if ($null -eq $json.$entriesProp) {
        return $false
    }

    foreach ($entry in @($json.$entriesProp)) {
        if ($null -eq $entry) {
            continue
        }

        if ([string]$entry.$idProp -eq $managedId) {
            return $true
        }

        $entryPath = [string]$entry.$pathProp
        if (-not [string]::IsNullOrWhiteSpace($entryPath) -and
            ($entryPath -replace '\\', '/') -match [regex]::Escape(($OfficialSkillsRelativePath -replace '\\', '/'))) {
            return $true
        }
    }

    return $false
}

function Test-AntigravitySmokeManagedMarkdownPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return $false
    }

    $text = [System.IO.File]::ReadAllText($FilePath)
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $false
    }

    $begin = $script:AntigravityPathConstant.ManagedBlockBeginMarker
    $end = $script:AntigravityPathConstant.ManagedBlockEndMarker
    return ($text.Contains($begin) -and $text.Contains($end))
}

function Test-AntigravitySmokeFileNonEmpty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return $false
    }

    $text = [System.IO.File]::ReadAllText($FilePath)
    return -not [string]::IsNullOrWhiteSpace($text)
}

function Test-AntigravitySmokeForbiddenUnderscorePhraseAbsent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $FilePaths
    )

    $forbidden = $script:AntigravityPathConstant.ForbiddenUnderscoreMandatePhrase
    foreach ($path in $FilePaths) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        $text = [System.IO.File]::ReadAllText($path)
        if ($text.IndexOf($forbidden, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $false
        }
    }

    return $true
}

function Invoke-AntigravitySmokeValidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    $resolvedInstallRoot = $null
    try {
        $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
    }
    catch {
        $detail = $_.Exception.Message
        return New-AntigravitySmokeResult `
            -Success $false `
            -ErrorCode $script:AntigravityPathConstant.SmokeTe01Code `
            -Message ($script:AntigravitySmokeMessage.Te01InvalidInstallRoot -f $detail) `
            -ExitCode 1
    }

    $paths = Get-AntigravityMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $skillsRel = $script:AntigravityPathConstant.OfficialSkillsRelativePath
    $skillsJsonRel = $script:AntigravityPathConstant.OfficialSkillsJsonRelativePath
    $guardrailsRel = $script:AntigravityPathConstant.OfficialGuardrailsRelativePath
    $devPersonaRel = $script:AntigravityPathConstant.OfficialDevPersonaSkillRelativePath
    $agentsRel = $script:AntigravityPathConstant.OfficialAgentsMdRelativePath
    $geminiRel = $script:AntigravityPathConstant.OfficialGeminiMdRelativePath

    $missing = [System.Collections.Generic.List[string]]::new()
    $checks = [ordered]@{
        KebabSkillsPresent              = $false
        UnderscoreOnlySkillsRejected    = $false
        SkillsJsonPresent               = $false
        GuardrailsPresent               = $false
        DevPersonaPresent               = $false
        ManagedAgentsOrGeminiPresent    = $false
        ForbiddenUnderscorePhraseAbsent = $false
        SddLayoutPresent                = $false
        HooksIgnored                    = $true
        LegacyBridgeNotGated            = $true
        FilesystemOnly                  = $true
    }

    $skillStats = Get-AntigravitySmokeSkillFolderStats -SkillsRoot $paths.FixtureSkillsPath
    $kebabOk = $skillStats.KebabManifestCount -gt 0
    $checks.KebabSkillsPresent = $kebabOk

    if (-not $kebabOk) {
        $missing.Add(($skillsRel + '/<kebab-id>/SKILL.md'))
        $isUnderscoreOnly = ($skillStats.UnderscoreManifestCount -gt 0) -or (-not $skillStats.SkillsRootPresent) -or ($skillStats.KebabManifestCount -eq 0)
        if ($isUnderscoreOnly) {
            return New-AntigravitySmokeResult `
                -Success $false `
                -ErrorCode $script:AntigravityPathConstant.SmokeTe04Code `
                -ResolvedInstallRoot $resolvedInstallRoot `
                -Checks $checks `
                -MissingRelativePaths $missing.ToArray() `
                -Message ($script:AntigravitySmokeMessage.Te04UnderscoreOnlySkills -f $skillsRel) `
                -ExitCode 1
        }
    }

    $checks.UnderscoreOnlySkillsRejected = $true

    $skillsJsonOk = Test-AntigravitySmokeSkillsJsonPresent `
        -SkillsJsonPath $paths.FixtureSkillsJsonPath `
        -OfficialSkillsRelativePath $skillsRel
    $checks.SkillsJsonPresent = $skillsJsonOk
    if (-not $skillsJsonOk) {
        $missing.Add($skillsJsonRel)
    }

    $guardrailsOk = Test-AntigravitySmokeFileNonEmpty -FilePath $paths.FixtureGuardrailsPath
    $checks.GuardrailsPresent = $guardrailsOk
    if (-not $guardrailsOk) {
        $missing.Add($guardrailsRel)
    }

    $devPersonaOk = Test-AntigravitySmokeFileNonEmpty -FilePath $paths.FixtureDevPersonaPath
    $checks.DevPersonaPresent = $devPersonaOk
    if (-not $devPersonaOk) {
        $missing.Add($devPersonaRel)
    }

    $agentsOk = Test-AntigravitySmokeManagedMarkdownPresent -FilePath $paths.FixtureAgentsMdPath
    $geminiOk = Test-AntigravitySmokeManagedMarkdownPresent -FilePath $paths.FixtureGeminiMdPath
    $managedMdOk = $agentsOk -or $geminiOk
    $checks.ManagedAgentsOrGeminiPresent = $managedMdOk
    if (-not $managedMdOk) {
        $missing.Add(($agentsRel + '|' + $geminiRel + ' (managed block)'))
    }

    $phraseOk = Test-AntigravitySmokeForbiddenUnderscorePhraseAbsent -FilePaths @(
        $paths.FixtureGuardrailsPath,
        $paths.FixtureDevPersonaPath
    )
    $checks.ForbiddenUnderscorePhraseAbsent = $phraseOk
    if (-not $phraseOk) {
        $missing.Add(('forbidden phrase: ' + $script:AntigravityPathConstant.ForbiddenUnderscoreMandatePhrase))
    }

    $sddOk = Test-ToolkitSddLayoutPresent -InstallRoot $resolvedInstallRoot -MissingRelative $missing
    $checks.SddLayoutPresent = $sddOk

    if ($missing.Count -gt 0) {
        $listText = ($missing.ToArray() -join ', ')
        return New-AntigravitySmokeResult `
            -Success $false `
            -ErrorCode $script:AntigravityPathConstant.SmokeTe05Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -MissingRelativePaths $missing.ToArray() `
            -Message ($script:AntigravitySmokeMessage.Te05MissingArtifacts -f $listText) `
            -ExitCode 1
    }

    $passMessage = ($script:AntigravitySmokeMessage.Passed -f $resolvedInstallRoot) + ' ' + $script:AntigravitySmokeMessage.FilesystemOnlyNote
    return New-AntigravitySmokeResult `
        -Success $true `
        -ResolvedInstallRoot $resolvedInstallRoot `
        -Checks $checks `
        -Message $passMessage `
        -ExitCode 0
}
