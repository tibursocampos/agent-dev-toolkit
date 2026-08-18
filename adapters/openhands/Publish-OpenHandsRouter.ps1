#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenHands Publish-Router (core/router/AGENTS.md + folded core/policy).
#>

function Convert-OpenHandsRouterMdcReferencesToMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $mdcExtension = $script:OpenHandsAdapterConstant.CursorRuleExtension
    $mdExtension = $script:OpenHandsAdapterConstant.MarkdownExtension
    if ([string]::IsNullOrEmpty($mdcExtension) -or [string]::IsNullOrEmpty($mdExtension)) {
        return $Text
    }

    return $Text.Replace($mdcExtension, $mdExtension)
}

function Convert-OpenHandsRouterDanglingRulesPointers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $sep = $script:OpenHandsAdapterConstant.PathSeparatorForwardSlash
    $rulesDir = $script:OpenHandsAdapterConstant.RulesDirectoryName
    $pointer = $script:OpenHandsAdapterConstant.RulesFoldedPointer
    $danglingTokens = @(
        ($rulesDir + $sep + $script:OpenHandsAdapterConstant.OrchestratorSessionMdcFileName),
        ($rulesDir + $sep + $script:OpenHandsAdapterConstant.OrchestratorSessionMdFileName),
        ($rulesDir + $sep + $script:OpenHandsAdapterConstant.GuardrailsMdcFileName),
        ($rulesDir + $sep + $script:OpenHandsAdapterConstant.GuardrailsFileName)
    )

    $lines = $Text -split '\r?\n', -1
    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $hit = $false
        foreach ($token in $danglingTokens) {
            if (-not [string]::IsNullOrEmpty($token) -and $line.Contains($token)) {
                $hit = $true
                break
            }
        }
        if ($hit) {
            foreach ($token in $danglingTokens) {
                if ([string]::IsNullOrEmpty($token) -or -not $line.Contains($token)) {
                    continue
                }
                $spanPattern = '`[^`]*' + [regex]::Escape($token) + '[^`]*`'
                $line = [regex]::Replace($line, $spanPattern, ('`' + $pointer + '`'))
            }
        }
        [void]$kept.Add($line)
    }

    return ($kept -join "`n")
}

function Get-OpenHandsFoldedPolicySection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot
    )

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine($script:OpenHandsAdapterConstant.RulesAlwaysOnHeading)
    [void]$builder.AppendLine()
    [void]$builder.AppendLine($script:OpenHandsAdapterConstant.RulesFoldIntro.TrimEnd())
    [void]$builder.AppendLine()

    $policyFiles = @(Get-ChildItem -LiteralPath $SourcePolicyRoot -File | Sort-Object Name)
    foreach ($file in $policyFiles) {
        [void]$builder.AppendLine(('### {0}' -f $file.BaseName))
        [void]$builder.AppendLine()
        $body = [System.IO.File]::ReadAllText($file.FullName).TrimEnd()
        [void]$builder.AppendLine($body)
        [void]$builder.AppendLine()
    }

    return $builder.ToString().TrimEnd() + "`n"
}

function Get-OpenHandsAgentsMdPublishContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenHandsAdapterRepoRoot
    Initialize-OpenHandsInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:OpenHandsAdapterConstant.CoreDirectoryName) $script:OpenHandsAdapterConstant.RouterDirectoryName
    ) $script:OpenHandsAdapterConstant.RouterSourceFileName
    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:OpenHandsAdapterMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:OpenHandsAdapterConstant.CoreDirectoryName) $script:OpenHandsAdapterConstant.PolicyDirectoryName
    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:OpenHandsAdapterMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }

    $raw = [System.IO.File]::ReadAllText($sourceRouterFile)
    $foldedSection = Get-OpenHandsFoldedPolicySection -SourcePolicyRoot $sourcePolicyRoot
    $heading = $script:OpenHandsAdapterConstant.RulesAlwaysOnHeading
    $headingPattern = '(?ms)^' + [regex]::Escape($heading) + '.*?(?=^## |\z)'
    if ($raw.Contains($heading)) {
        $raw = [regex]::Replace($raw, $headingPattern, $foldedSection)
    }
    else {
        $raw = $raw.TrimEnd() + "`n`n" + $foldedSection
    }

    $updated = Convert-OpenHandsRouterDanglingRulesPointers -Text $raw
    $updated = Convert-OpenHandsRouterMdcReferencesToMd -Text $updated

    $placeholderMap = Get-OpenHandsPlaceholderMap -InstallRoot $resolvedInstallRoot
    foreach ($key in $placeholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$placeholderMap[$key])
        }
    }

    return $updated
}

function Write-OpenHandsPublishedAgentsMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationAgentsMd,

        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    foreach ($placeholder in (Get-OpenHandsSupportedPlaceholderTokens)) {
        if ($Content.Contains($placeholder)) {
            throw ($script:OpenHandsAdapterMessage.PlaceholderUnresolved -f $placeholder, $DestinationAgentsMd)
        }
    }

    $libDir = Join-Path (Get-OpenHandsAdapterRepoRoot) 'scripts\_lib'
    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    }

    Assert-ToolkitManagedPathContained `
        -CandidatePath $DestinationAgentsMd `
        -RootPath $ResolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    Write-OpenHandsUtf8NoBomFile -Path $DestinationAgentsMd -Content $Content

    . (Join-Path $libDir 'ToolkitManagedPublishInventory.ps1')
    $null = Set-ToolkitManagedPublishInventoryEntryFromContent `
        -InstallRoot $ResolvedInstallRoot `
        -RelativePath $script:OpenHandsAdapterConstant.OfficialAgentsFileName `
        -PublishedContent $Content
}

function Invoke-OpenHandsPublishRouter {
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
        throw $script:OpenHandsAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenHandsAdapterRepoRoot
    Initialize-OpenHandsInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:OpenHandsAdapterConstant.CoreDirectoryName) $script:OpenHandsAdapterConstant.RouterDirectoryName
    ) $script:OpenHandsAdapterConstant.RouterSourceFileName
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath

    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:OpenHandsAdapterMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success            = $true
            Implemented        = $true
            CommandName        = 'Publish-Router'
            WhatIf             = $true
            InstallRoot        = $resolvedInstallRoot
            AgentsMdPath       = $destinationAgentsMd
            SourceRoot         = $sourceRouterFile
            FilesCopied        = 0
            PublishesCursorMdc = $false
            PublishesRulesTree = $false
            Message            = ($script:OpenHandsAdapterMessage.RouterWhatIfOk -f $destinationAgentsMd)
            ExitCode           = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-OpenHandsMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationAgentsMd = $mapped.FixtureProjectAgentsPath
    $updated = Get-OpenHandsAgentsMdPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    Write-OpenHandsPublishedAgentsMarkdown -ResolvedInstallRoot $resolvedInstallRoot -DestinationAgentsMd $destinationAgentsMd -Content $updated

    return [PSCustomObject]@{
        Success            = $true
        Implemented        = $true
        CommandName        = 'Publish-Router'
        WhatIf             = $false
        InstallRoot        = $resolvedInstallRoot
        AgentsMdPath       = $destinationAgentsMd
        SourceRoot         = $sourceRouterFile
        FilesCopied        = 1
        PublishesCursorMdc = $false
        PublishesRulesTree = $false
        Message            = ($script:OpenHandsAdapterMessage.RouterPublishedOk -f $destinationAgentsMd)
        ExitCode           = 0
    }
}
