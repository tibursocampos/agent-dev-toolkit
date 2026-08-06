#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Grok Publish-Policy (core/policy -> InstallRoot/rules).
#>

function Copy-GrokCorePolicyTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationRulesRoot
    )

    if (-not (Test-Path -LiteralPath $DestinationRulesRoot)) {
        New-Item -ItemType Directory -Path $DestinationRulesRoot -Force | Out-Null
    }

    $filesCopied = 0
    $sourceFiles = Get-ChildItem -LiteralPath $SourcePolicyRoot -Recurse -File
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($SourcePolicyRoot.Length).TrimStart('\', '/')
        $destinationPath = Join-Path $DestinationRulesRoot $relative
        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
        $filesCopied++
    }

    return $filesCopied
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

