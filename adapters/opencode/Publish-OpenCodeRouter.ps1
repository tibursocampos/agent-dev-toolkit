#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for OpenCode Publish-Router (core/router/AGENTS.md -> InstallRoot/AGENTS.md).

.DESCRIPTION
  Maps the neutral core router to the OpenCode config-root AGENTS.md surface
  (fixture models ~/.config/opencode/AGENTS.md). Resolves {{TOOLKIT_ROOT}},
  {{SDD_ROOT}}, and {{GUARDRAILS_PATH}} under InstallRoot. Does not publish a
  Cursor-style rules/*.mdc tree (rules capability is false; use Publish-Policy no-op).
  Strips dangling rules/orchestrator-session.mdc and rules/guardrails.md(c) file
  pointers so Parallel specialists is the always-on surface. Uses Resolve-InstallRoot
  (USERPROFILE guard).
#>

$script:OpenCodeRouterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenCodeRouterModuleDirectory)) {
    $script:OpenCodeRouterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-OpenCodeRouterRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-OpenCodeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-OpenCodeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:OpenCodeRouterModuleDirectory))
}

function Get-OpenCodeRouterPublishContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenCodeRouterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterRoot = Join-Path (Join-Path $repoRoot $script:OpenCodePathConstant.CoreDirectoryName) $script:OpenCodePathConstant.RouterDirectoryName
    $sourceAgentsPath = Join-Path $sourceRouterRoot $script:OpenCodePathConstant.AgentsFileName
    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:OpenCodePublishMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    $raw = [System.IO.File]::ReadAllText($sourceAgentsPath)
    $placeholderMap = Get-OpenCodePlaceholderMap -InstallRoot $resolvedInstallRoot
    $updated = $raw
    foreach ($key in $placeholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$placeholderMap[$key])
        }
    }

    return (Convert-OpenCodeRouterDanglingRulesPointers -Text $updated)
}

function Convert-OpenCodeRouterDanglingRulesPointers {
    <#
    .SYNOPSIS
      Strip rules/*.mdc (and guardrails.md) file-to-open pointers. OpenCode is rules=false;
      Parallel specialists is the always-on surface.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $sep = $script:OpenCodePathConstant.PathSeparatorForwardSlash
    $rulesDir = $script:OpenCodePathConstant.RulesDirectoryName
    $orchestratorToken = $rulesDir + $sep + $script:OpenCodePathConstant.OrchestratorSessionMdcFileName
    $orchestratorMdToken = $rulesDir + $sep + $script:OpenCodePathConstant.OrchestratorSessionMdFileName
    $guardrailsMdcToken = $rulesDir + $sep + $script:OpenCodePathConstant.GuardrailsMdcFileName
    $guardrailsMdToken = $rulesDir + $sep + $script:OpenCodePathConstant.GuardrailsFileName
    $pointer = $script:OpenCodePathConstant.RulesFalseAlwaysOnPointer
    $heading = $script:OpenCodePathConstant.RulesAlwaysOnHeading
    $replacement = $script:OpenCodePathConstant.RulesFalseAlwaysOnSection

    $updated = $Text
    if (-not [string]::IsNullOrEmpty($heading) -and $updated.Contains($heading)) {
        $headingPattern = '(?ms)^' + [regex]::Escape($heading) + '.*?(?=^## )'
        $updated = [regex]::Replace($updated, $headingPattern, $replacement)
    }

    $danglingTokens = @(
        $orchestratorToken,
        $guardrailsMdcToken,
        $orchestratorMdToken,
        $guardrailsMdToken
    )

    $lines = $updated -split '\r?\n', -1
    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $isTableRow = $line.TrimStart().StartsWith('|')
        $hit = $false
        foreach ($token in $danglingTokens) {
            if (-not [string]::IsNullOrEmpty($token) -and $line.Contains($token)) {
                $hit = $true
                break
            }
        }
        if ($isTableRow -and $hit) {
            continue
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
        $kept.Add($line)
    }

    return ($kept -join "`n")
}

function Invoke-OpenCodePublishRouter {
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
        throw $script:OpenCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-OpenCodeRouterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterRoot = Join-Path (Join-Path $repoRoot $script:OpenCodePathConstant.CoreDirectoryName) $script:OpenCodePathConstant.RouterDirectoryName
    $sourceAgentsPath = Join-Path $sourceRouterRoot $script:OpenCodePathConstant.AgentsFileName
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.AgentsFileName

    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:OpenCodePublishMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success            = $true
            Implemented        = $true
            CommandName        = 'Publish-Router'
            WhatIf             = $true
            InstallRoot        = $resolvedInstallRoot
            AgentsPath         = $destinationAgentsPath
            SourcePath         = $sourceAgentsPath
            FilesCopied        = 0
            PublishesCursorMdc = $false
            PolicyNote         = $script:OpenCodePublishMessage.PolicyNoOp
            Message            = ($script:OpenCodePublishMessage.RouterWhatIfOk -f $destinationAgentsPath)
            ExitCode           = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:OpenCodePathConstant.AgentsFileName

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    }
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $updated = Get-OpenCodeRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome

    foreach ($placeholder in @(
            $script:OpenCodePathConstant.PlaceholderToolkitRoot,
            $script:OpenCodePathConstant.PlaceholderSddRoot,
            $script:OpenCodePathConstant.PlaceholderGuardrailsPath
        )) {
        if ($updated.Contains($placeholder)) {
            throw ($script:OpenCodePublishMessage.PlaceholderUnresolved -f $placeholder, $destinationAgentsPath)
        }
    }

    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationAgentsPath, $updated, $utf8NoBom)

    . (Join-Path $libDir 'ToolkitManagedPublishInventory.ps1')
    Set-ToolkitManagedPublishInventoryEntryFromContent `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:OpenCodePathConstant.AgentsFileName `
        -PublishedContent $updated

    return [PSCustomObject]@{
        Success            = $true
        Implemented        = $true
        CommandName        = 'Publish-Router'
        WhatIf             = $false
        InstallRoot        = $resolvedInstallRoot
        AgentsPath         = $destinationAgentsPath
        SourcePath         = $sourceAgentsPath
        FilesCopied        = 1
        PublishesCursorMdc = $false
        PolicyNote         = $script:OpenCodePublishMessage.PolicyNoOp
        Message            = ($script:OpenCodePublishMessage.RouterPublishedOk -f $destinationAgentsPath)
        ExitCode           = 0
    }
}
