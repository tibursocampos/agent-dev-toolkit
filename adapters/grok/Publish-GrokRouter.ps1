#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Grok Publish-Router (core/router/AGENTS.md -> InstallRoot/AGENTS.md).
#>

function Convert-GrokRouterMdcReferencesToMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $mdcExtension = $script:GrokAdapterConstant.CursorRuleExtension
    $mdExtension = $script:GrokAdapterConstant.MarkdownExtension
    if ([string]::IsNullOrEmpty($mdcExtension) -or [string]::IsNullOrEmpty($mdExtension)) {
        return $Text
    }

    return $Text.Replace($mdcExtension, $mdExtension)
}

function Invoke-GrokPublishPolicy {
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:GrokAdapterConstant.CoreDirectoryName) $script:GrokAdapterConstant.PolicyDirectoryName
    $destinationRulesRoot = $mapped.FixtureRulesPath

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:GrokAdapterMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success     = $true
            Implemented = $true
            CommandName = 'Publish-Policy'
            WhatIf      = $true
            InstallRoot = $resolvedInstallRoot
            RulesRoot   = $destinationRulesRoot
            SourceRoot  = $sourcePolicyRoot
            FilesCopied = 0
            Message     = ($script:GrokAdapterMessage.PolicyWhatIfOk -f $destinationRulesRoot)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationRulesRoot = $mapped.FixtureRulesPath

    $filesCopied = Copy-GrokCorePolicyTree -SourcePolicyRoot $sourcePolicyRoot -DestinationRulesRoot $destinationRulesRoot
    $placeholderMap = Get-GrokPlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-GrokPlaceholdersInTree -RootPath $destinationRulesRoot -PlaceholderMap $placeholderMap
    Assert-GrokPlaceholdersResolved -RootPath $destinationRulesRoot

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Policy'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        RulesRoot   = $destinationRulesRoot
        SourceRoot  = $sourcePolicyRoot
        FilesCopied = $filesCopied
        Message     = ($script:GrokAdapterMessage.PolicyPublishedOk -f $filesCopied, $destinationRulesRoot)
        ExitCode    = 0
    }
}

function Get-GrokRouterPublishContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:GrokAdapterConstant.CoreDirectoryName) $script:GrokAdapterConstant.RouterDirectoryName
    ) $script:GrokAdapterConstant.RouterSourceFileName
    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:GrokAdapterMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    $raw = [System.IO.File]::ReadAllText($sourceRouterFile)
    $placeholderMap = Get-GrokPlaceholderMap -InstallRoot $resolvedInstallRoot
    $updated = $raw
    foreach ($key in $placeholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$placeholderMap[$key])
        }
    }

    return (Convert-GrokRouterMdcReferencesToMd -Text $updated)
}

function Invoke-GrokPublishRouter {
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
        throw $script:GrokAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-GrokAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:GrokAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:GrokAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:GrokAdapterConstant.CoreDirectoryName) $script:GrokAdapterConstant.RouterDirectoryName
    ) $script:GrokAdapterConstant.RouterSourceFileName
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath

    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:GrokAdapterMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Router'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            AgentsMdPath = $destinationAgentsMd
            SourceRoot   = $sourceRouterFile
            FilesCopied  = 0
            Message      = ($script:GrokAdapterMessage.RouterWhatIfOk -f $destinationAgentsMd)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-GrokMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath

    $updated = Get-GrokRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome

    foreach ($placeholder in (Get-GrokSupportedPlaceholderTokens)) {
        if ($updated.Contains($placeholder)) {
            throw ($script:GrokAdapterMessage.PlaceholderUnresolved -f $placeholder, $destinationAgentsMd)
        }
    }

    $destinationDir = Split-Path -Parent $destinationAgentsMd
    if (-not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationAgentsMd, $updated, $utf8NoBom)

    . (Join-Path (Join-Path $repoRoot 'scripts\_lib') 'ToolkitManagedPublishInventory.ps1')
    Set-ToolkitManagedPublishInventoryEntryFromContent `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:GrokAdapterConstant.OfficialAgentsFileName `
        -PublishedContent $updated

    return [PSCustomObject]@{
        Success      = $true
        Implemented  = $true
        CommandName  = 'Publish-Router'
        WhatIf       = $false
        InstallRoot  = $resolvedInstallRoot
        AgentsMdPath = $destinationAgentsMd
        SourceRoot   = $sourceRouterFile
        FilesCopied  = 1
        Message      = ($script:GrokAdapterMessage.RouterPublishedOk -f $destinationAgentsMd)
        ExitCode     = 0
    }
}

