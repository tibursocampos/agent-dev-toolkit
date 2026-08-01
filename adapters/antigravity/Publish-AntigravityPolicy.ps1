#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Antigravity Publish-Policy (core/policy -> GUARDRAILS.md).

.DESCRIPTION
  Generates InstallRoot/config/plugins/agent-dev-toolkit/GUARDRAILS.md from
  core/policy/guardrails.md plus other alwaysApply policy files. Resolves
  {{TOOLKIT_ROOT}}, {{SDD_ROOT}}, {{GUARDRAILS_PATH}}. Strips forbidden
  "use underscore folder names" mandate phrasing. Does not copy external sibling-repo plugin files.
#>

function Get-AntigravityNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:AntigravityPathConstant.PathSeparatorForwardSlash)
}

function Get-AntigravityPlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $toolkitRoot = Get-AntigravityNormalizedForwardSlashPath -Path (
        Join-Path $InstallRoot $script:AntigravityPathConstant.ConfigDirectoryName
    )
    $sddRoot = Get-AntigravityNormalizedForwardSlashPath -Path (
        Join-Path $InstallRoot $script:AntigravityPathConstant.SddDirectoryName
    )
    $guardrailsPath = Get-AntigravityNormalizedForwardSlashPath -Path (
        Join-Path $InstallRoot ($script:AntigravityPathConstant.OfficialGuardrailsRelativePath -replace '/', $sep)
    )

    return [ordered]@{
        ($script:AntigravityPathConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:AntigravityPathConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:AntigravityPathConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Resolve-AntigravityPlaceholdersInText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    $updated = $Text
    foreach ($key in $PlaceholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$PlaceholderMap[$key])
        }
    }

    return $updated
}

function Assert-AntigravityPlaceholdersResolvedInText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    foreach ($placeholder in @(
            $script:AntigravityPathConstant.PlaceholderToolkitRoot,
            $script:AntigravityPathConstant.PlaceholderSddRoot,
            $script:AntigravityPathConstant.PlaceholderGuardrailsPath
        )) {
        if ($Text.Contains($placeholder)) {
            throw ($script:AntigravityPublishMessage.PlaceholderUnresolved -f $placeholder, $TargetPath)
        }
    }
}

function Remove-AntigravityForbiddenUnderscoreMandate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text
    )

    $phrase = $script:AntigravityPathConstant.ForbiddenUnderscoreMandatePhrase
    if ([string]::IsNullOrEmpty($Text) -or -not $Text.ToLowerInvariant().Contains($phrase.ToLowerInvariant())) {
        return $Text
    }

    $lines = $Text -split "`r?`n"
    $kept = foreach ($line in $lines) {
        if ($line.ToLowerInvariant().Contains($phrase.ToLowerInvariant())) {
            continue
        }
        $line
    }

    return ($kept -join [Environment]::NewLine)
}

function Assert-AntigravityForbiddenPhraseAbsent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $phrase = $script:AntigravityPathConstant.ForbiddenUnderscoreMandatePhrase
    if ($Text.ToLowerInvariant().Contains($phrase.ToLowerInvariant())) {
        throw ($script:AntigravityPublishMessage.ForbiddenPhrasePresent -f $TargetPath)
    }
}

function Test-AntigravityPolicyFileAlwaysApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath
    )

    $raw = [System.IO.File]::ReadAllText($FilePath)
    if (-not $raw.StartsWith('---')) {
        return $false
    }

    $endIndex = $raw.IndexOf("`n---", 3)
    if ($endIndex -lt 0) {
        return $false
    }

    $frontmatter = $raw.Substring(0, $endIndex + 4)
    return $frontmatter.Contains($script:AntigravityPathConstant.AlwaysApplyFrontmatterToken)
}

function Get-AntigravityGuardrailsSourceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot
    )

    $primaryName = $script:AntigravityPathConstant.GuardrailsSourceFileName
    $primaryPath = Join-Path $SourcePolicyRoot $primaryName
    if (-not (Test-Path -LiteralPath $primaryPath)) {
        throw ($script:AntigravityPublishMessage.CoreGuardrailsMissing -f $primaryPath)
    }

    $ordered = @([System.IO.FileInfo]$primaryPath)
    $others = @(
        Get-ChildItem -LiteralPath $SourcePolicyRoot -File -Filter '*.md' |
            Where-Object { $_.Name -ne $primaryName -and (Test-AntigravityPolicyFileAlwaysApply -FilePath $_.FullName) } |
            Sort-Object -Property Name
    )
    foreach ($other in $others) {
        $ordered += $other
    }

    return $ordered
}

function New-AntigravityGuardrailsContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]] $SourceFiles,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap,

        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add($script:AntigravityPathConstant.GuardrailsGeneratedBanner.TrimEnd())

    foreach ($file in $SourceFiles) {
        $raw = [System.IO.File]::ReadAllText($file.FullName)
        $sanitized = Remove-AntigravityForbiddenUnderscoreMandate -Text $raw
        $resolved = Resolve-AntigravityPlaceholdersInText -Text $sanitized -PlaceholderMap $PlaceholderMap
        $parts.Add($resolved.TrimEnd())
    }

    $combined = ($parts -join ([Environment]::NewLine + [Environment]::NewLine)) + [Environment]::NewLine
    Assert-AntigravityPlaceholdersResolvedInText -Text $combined -TargetPath $TargetPath
    Assert-AntigravityForbiddenPhraseAbsent -Text $combined -TargetPath $TargetPath
    return $combined
}

function Invoke-AntigravityPublishPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AntigravityPublishMessage.InstallRootRequired
    }

    $repoRoot = Get-AntigravityAdapterRepoRoot
    $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:AntigravityPathConstant.CoreDirectoryName) $script:AntigravityPathConstant.PolicyDirectoryName
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $destinationGuardrailsPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialGuardrailsRelativePath -replace '/', $sep)

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:AntigravityPublishMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    $sourceFiles = @(Get-AntigravityGuardrailsSourceFiles -SourcePolicyRoot $sourcePolicyRoot)

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Policy'
            WhatIf           = $true
            InstallRoot      = $resolvedInstallRoot
            GuardrailsPath   = $destinationGuardrailsPath
            SourcePolicyRoot = $sourcePolicyRoot
            SourceFileCount  = $sourceFiles.Count
            Message          = ($script:AntigravityPublishMessage.PolicyWhatIfOk -f $destinationGuardrailsPath)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-AntigravityInstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $destinationGuardrailsPath = Join-Path $resolvedInstallRoot ($script:AntigravityPathConstant.OfficialGuardrailsRelativePath -replace '/', $sep)

    $placeholderMap = Get-AntigravityPlaceholderMap -InstallRoot $resolvedInstallRoot
    $content = New-AntigravityGuardrailsContent -SourceFiles $sourceFiles -PlaceholderMap $placeholderMap -TargetPath $destinationGuardrailsPath

    $destinationDir = Split-Path -Parent $destinationGuardrailsPath
    if (-not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationGuardrailsPath, $content, $utf8NoBom)

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Policy'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        GuardrailsPath   = $destinationGuardrailsPath
        SourcePolicyRoot = $sourcePolicyRoot
        SourceFileCount  = $sourceFiles.Count
        Message          = ($script:AntigravityPublishMessage.PolicyPublishedOk -f $destinationGuardrailsPath, $sourceFiles.Count)
        ExitCode         = 0
    }
}
