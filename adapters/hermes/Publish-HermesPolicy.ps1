#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Hermes Publish-Policy (core/policy folded into InstallRoot/AGENTS.md).
#>

function Convert-HermesMdcReferencesToMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text
    )

    $mdcExtension = $script:HermesAdapterConstant.CursorRuleExtension
    $mdExtension = $script:HermesAdapterConstant.MarkdownExtension
    if ([string]::IsNullOrEmpty($mdcExtension) -or [string]::IsNullOrEmpty($mdExtension)) {
        return $Text
    }

    return $Text.Replace($mdcExtension, $mdExtension)
}

function Convert-HermesRulesPathReferencesToAgentsMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $ToolkitRootForwardSlash
    )

    $sep = $script:HermesAdapterConstant.PathSeparatorForwardSlash
    $rulesPrefix = $ToolkitRootForwardSlash + $sep + $script:HermesAdapterConstant.CursorRulesDirectoryName + $sep
    $agentsPath = $ToolkitRootForwardSlash + $sep + $script:HermesAdapterConstant.OfficialAgentsFileName
    if (-not $Text.Contains($rulesPrefix)) {
        return $Text
    }

    $pattern = [regex]::Escape($rulesPrefix) + '[^\s)\]`"]+'
    return [regex]::Replace($Text, $pattern, [string]$agentsPath)
}

function Resolve-HermesPlaceholdersInText {
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

function Assert-HermesPlaceholdersResolvedInText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    foreach ($placeholder in @(Get-HermesSupportedPlaceholderTokens)) {
        if ($Text.Contains($placeholder)) {
            throw ($script:HermesAdapterMessage.PlaceholderUnresolved -f $placeholder, $TargetPath)
        }
    }
}

function Get-HermesPolicySourceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot
    )

    $extension = $script:HermesAdapterConstant.MarkdownExtension
    $guardrailsName = $script:HermesAdapterConstant.GuardrailsFileName
    $filter = '*' + $extension
    $allFiles = @(Get-ChildItem -LiteralPath $SourcePolicyRoot -File -Filter $filter | Sort-Object -Property Name)
    $ordered = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $primary = $allFiles | Where-Object { $_.Name -eq $guardrailsName } | Select-Object -First 1
    if ($null -ne $primary) {
        $ordered.Add($primary)
    }

    foreach ($file in $allFiles) {
        if ($file.Name -eq $guardrailsName) {
            continue
        }
        $ordered.Add($file)
    }

    return @($ordered.ToArray())
}

function Get-HermesFoldedPolicyMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap,

        [Parameter(Mandatory = $true)]
        [string] $ToolkitRootForwardSlash
    )

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add($script:HermesAdapterConstant.PolicyFoldSectionHeading)
    $parts.Add($script:HermesAdapterConstant.PolicyFoldIntro)

    $sourceFiles = @(Get-HermesPolicySourceFiles -SourcePolicyRoot $SourcePolicyRoot)
    foreach ($file in $sourceFiles) {
        $heading = $script:HermesAdapterConstant.PolicyFileHeadingPrefix + [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $raw = [System.IO.File]::ReadAllText($file.FullName)
        $resolved = Resolve-HermesPlaceholdersInText -Text $raw -PlaceholderMap $PlaceholderMap
        $converted = Convert-HermesMdcReferencesToMd -Text $resolved
        $rewritten = Convert-HermesRulesPathReferencesToAgentsMd -Text $converted -ToolkitRootForwardSlash $ToolkitRootForwardSlash
        $parts.Add($heading)
        $parts.Add($rewritten.TrimEnd())
    }

    return (($parts.ToArray()) -join ([Environment]::NewLine + [Environment]::NewLine))
}

function Get-HermesAgentsMdPublishContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-HermesAdapterRepoRoot
    Initialize-HermesInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.RouterDirectoryName
    ) $script:HermesAdapterConstant.RouterSourceFileName
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.PolicyDirectoryName

    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:HermesAdapterMessage.CoreRouterMissing -f $sourceRouterFile)
    }
    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:HermesAdapterMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    $placeholderMap = Get-HermesPlaceholderMap -InstallRoot $resolvedInstallRoot
    $toolkitRoot = [string]$placeholderMap[$script:HermesAdapterConstant.PlaceholderToolkitRoot]
    $routerRaw = [System.IO.File]::ReadAllText($sourceRouterFile)
    $routerResolved = Resolve-HermesPlaceholdersInText -Text $routerRaw -PlaceholderMap $placeholderMap
    $routerConverted = Convert-HermesMdcReferencesToMd -Text $routerResolved
    $routerRewritten = Convert-HermesRulesPathReferencesToAgentsMd -Text $routerConverted -ToolkitRootForwardSlash $toolkitRoot
    $foldedPolicy = Get-HermesFoldedPolicyMarkdown -SourcePolicyRoot $sourcePolicyRoot -PlaceholderMap $placeholderMap -ToolkitRootForwardSlash $toolkitRoot

    return ($routerRewritten.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $foldedPolicy.TrimEnd() + [Environment]::NewLine)
}

function Write-HermesManagedAgentsMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $ResolvedInstallRoot
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath
    $updated = Get-HermesAgentsMdPublishContent -InstallRoot $ResolvedInstallRoot -AllowUserHome:$AllowUserHome
    Assert-HermesPlaceholdersResolvedInText -Text $updated -TargetPath $destinationAgentsMd

    $destinationDir = Split-Path -Parent $destinationAgentsMd
    if (-not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    Write-HermesUtf8NoBomFile -Path $destinationAgentsMd -Content $updated

    $repoRoot = Get-HermesAdapterRepoRoot
    . (Join-Path (Join-Path $repoRoot 'scripts\_lib') 'ToolkitManagedPublishInventory.ps1')
    $null = Set-ToolkitManagedPublishInventoryEntryFromContent `
        -InstallRoot $ResolvedInstallRoot `
        -RelativePath $script:HermesAdapterConstant.OfficialAgentsFileName `
        -PublishedContent $updated

    $null = Initialize-HermesMemoryFileIfMissing -ResolvedInstallRoot $ResolvedInstallRoot

    return [PSCustomObject]@{
        AgentsMdPath = $destinationAgentsMd
        Content      = $updated
        PolicyFiles  = @(Get-HermesPolicySourceFiles -SourcePolicyRoot (Join-Path (Join-Path $repoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.PolicyDirectoryName)).Count
    }
}

function Invoke-HermesPublishPolicy {
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-HermesAdapterRepoRoot
    Initialize-HermesInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.PolicyDirectoryName
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:HermesAdapterMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Policy'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            AgentsMdPath = $destinationAgentsMd
            SourceRoot   = $sourcePolicyRoot
            FilesCopied  = 0
            Message      = ($script:HermesAdapterMessage.PolicyWhatIfOk -f $destinationAgentsMd)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath
    $written = Write-HermesManagedAgentsMd -ResolvedInstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome

    return [PSCustomObject]@{
        Success      = $true
        Implemented  = $true
        CommandName  = 'Publish-Policy'
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        AgentsMdPath = $destinationAgentsMd
        SourceRoot   = $sourcePolicyRoot
        FilesCopied  = $written.PolicyFiles
        Message      = ($script:HermesAdapterMessage.PolicyPublishedOk -f $written.PolicyFiles, $destinationAgentsMd)
        ExitCode     = 0
    }
}
