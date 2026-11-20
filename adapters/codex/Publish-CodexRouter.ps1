#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Codex Publish-Router (core/router -> InstallRoot/AGENTS.md).

.DESCRIPTION
  Materializes {{TOOLKIT_ROOT}}, {{SDD_ROOT}}, and {{GUARDRAILS_PATH}} into
  InstallRoot-absolute forward-slash paths. Codex is dual-root: plugin skills
  live under InstallRoot/plugins/agent-dev-toolkit/skills (TOOLKIT_ROOT for skills paths), while
  Publish-Policy writes rules under InstallRoot/rules. Router materialization
  rewrites {{TOOLKIT_ROOT}}/rules/ to the InstallRoot rules tree first, then
  remaining {{TOOLKIT_ROOT}} to the plugin root. Converts .mdc rule refs to .md
  (Codex policy layout). Strips repo docs/ hub links from published content.
#>

$script:CodexRouterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CodexRouterModuleDirectory)) {
    $script:CodexRouterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-CodexRouterAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:CodexRouterModuleDirectory))
}

function Get-CodexRouterPluginRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    return [System.IO.Path]::GetFullPath(
        (Join-Path $InstallRoot $script:CodexPathConstant.PluginRootDirectoryName)
    )
}

function Get-CodexRouterRulesRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    return [System.IO.Path]::GetFullPath(
        (Join-Path $InstallRoot $script:CodexPathConstant.RulesDirectoryName)
    )
}

function Get-CodexRouterSkillsCatalogPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    $sharedRoot = Join-Path $skillsRoot $script:CodexPathConstant.SharedSkillsDirectoryName
    $catalogDir = Join-Path $sharedRoot $script:CodexPathConstant.SkillsCatalogDirectoryName
    return [System.IO.Path]::GetFullPath(
        (Join-Path $catalogDir $script:CodexPathConstant.SkillsCatalogFileName)
    )
}

function Convert-CodexRouterMdcReferencesToMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $mdcExtension = $script:CodexPathConstant.CursorRuleExtension
    $mdExtension = $script:CodexPathConstant.MarkdownExtension
    if ([string]::IsNullOrEmpty($mdcExtension) -or [string]::IsNullOrEmpty($mdExtension)) {
        return $Text
    }

    return $Text.Replace($mdcExtension, $mdExtension)
}

function Remove-CodexRouterRepoDocsLinks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    # Defense-in-depth: strip any remaining repo docs path refs from published AGENTS.
    return [regex]::Replace($Text, '`docs/[A-Za-z0-9._/-]+`', '`(repo docs — not installed)`')
}

function Add-CodexRouterDualRootCallout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $InstallRootAbsolute,

        [Parameter(Mandatory = $true)]
        [string] $PluginRootAbsolute,

        [Parameter(Mandatory = $true)]
        [string] $LocalSkillsRootAbsolute,

        [Parameter(Mandatory = $true)]
        [string] $RulesRootAbsolute,

        [Parameter(Mandatory = $true)]
        [string] $CatalogPathAbsolute,

        [Parameter(Mandatory = $true)]
        [string] $GuardrailsPathAbsolute,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Both', 'Local', 'Plugin')]
        [string] $Distribution,

        [Parameter(Mandatory = $true)]
        [string] $SelectedSkillsRootAbsolute
    )

    $skillRootRows = @()
    if ($Distribution -in @('Both', 'Local')) {
        $skillRootRows += ("| Local skills (picker) | `{0}` |" -f $LocalSkillsRootAbsolute)
    }
    if ($Distribution -in @('Both', 'Plugin')) {
        $skillRootRows += ("| Plugin skills | `{0}` |" -f (Join-Path $PluginRootAbsolute $script:CodexPathConstant.SkillsDirectoryName))
    }

    $calloutHeader = @(
        '',
        $script:CodexPathConstant.RouterDualRootHeading,
        '',
        ($script:CodexPublishMessage.RouterDualRootIntro -f $InstallRootAbsolute),
        '',
        '| Surface | Absolute path |',
        '|---------|---------------|',
        ("| InstallRoot (product / AGENTS / rules parent) | `{0}` |" -f $InstallRootAbsolute),
        ("| Skill distribution | `{0}` |" -f $Distribution),
        ("| Plugin root (marketplace and hooks) | `{0}` |" -f $PluginRootAbsolute)
    )
    $calloutFooter = @(
        ("| Selected skills TOOLKIT_ROOT | `{0}` |" -f $SelectedSkillsRootAbsolute),
        ("| Rules (Publish-Policy) | `{0}` |" -f $RulesRootAbsolute),
        ("| Guardrails | `{0}` |" -f $GuardrailsPathAbsolute),
        ("| Skills catalog | `{0}` |" -f $CatalogPathAbsolute),
        '',
        $script:CodexPublishMessage.RouterDualRootNote,
        ''
    )
    $callout = ($calloutHeader + $skillRootRows + $calloutFooter) -join "`n"

    if ($Text -match '(?m)^## Language\s*$') {
        return ($Text -replace '(?m)^## Language\s*$', ($callout.TrimEnd() + "`n`n## Language"))
    }

    return ($callout + $Text)
}

function Resolve-CodexRouterPlaceholdersInText {
    <#
    .SYNOPSIS
      Dual-root placeholder materialization for published AGENTS.md.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [ValidateSet('Both', 'Local', 'Plugin')]
        [string] $CodexSkillDistribution
    )

    if (-not (Get-Command -Name Get-CodexNormalizedForwardSlashPath -ErrorAction SilentlyContinue)) {
        throw $script:CodexPublishMessage.RouterSkillsHelpersMissing
    }

    $installAbsolute = Get-CodexNormalizedForwardSlashPath -Path $InstallRoot
    $distribution = Resolve-CodexSkillDistribution -InstallRoot $InstallRoot -Distribution $CodexSkillDistribution
    $pluginRoot = Get-CodexRouterPluginRoot -InstallRoot $InstallRoot
    $pluginAbsolute = Get-CodexNormalizedForwardSlashPath -Path $pluginRoot
    $homeSkillsRoot = Join-Path $InstallRoot $script:CodexPathConstant.HomeSkillsRelativePath
    $homeSkillsAbsolute = Get-CodexNormalizedForwardSlashPath -Path $homeSkillsRoot
    $selectedToolkitRoot = if ($distribution -eq 'Local') { $InstallRoot } else { $pluginRoot }
    $selectedToolkitRootAbsolute = Get-CodexNormalizedForwardSlashPath -Path $selectedToolkitRoot
    $selectedSkillsRoot = Join-Path $selectedToolkitRoot $script:CodexPathConstant.SkillsDirectoryName
    $rulesRoot = Get-CodexRouterRulesRoot -InstallRoot $InstallRoot
    $rulesAbsolute = Get-CodexNormalizedForwardSlashPath -Path $rulesRoot
    $sddAbsolute = Get-CodexNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:CodexPathConstant.SddDirectoryName)
    $guardrailsAbsolute = Get-CodexNormalizedForwardSlashPath -Path (
        Join-Path $rulesRoot $script:CodexPathConstant.GuardrailsFileName
    )
    $catalogAbsolute = Get-CodexNormalizedForwardSlashPath -Path (Get-CodexRouterSkillsCatalogPath -SkillsRoot $selectedSkillsRoot)

    $toolkitToken = $script:CodexPathConstant.PlaceholderToolkitRoot
    $rulesPrefix = $toolkitToken + $script:CodexPathConstant.PathSeparatorForwardSlash + $script:CodexPathConstant.RulesDirectoryName + $script:CodexPathConstant.PathSeparatorForwardSlash
    $rulesRootToken = $toolkitToken + $script:CodexPathConstant.PathSeparatorForwardSlash + $script:CodexPathConstant.RulesDirectoryName

    $updated = $Text
    # Rules under InstallRoot — rewrite before remaining TOOLKIT_ROOT → selected skill root.
    if ($updated.Contains($rulesPrefix)) {
        $updated = $updated.Replace($rulesPrefix, ($rulesAbsolute + $script:CodexPathConstant.PathSeparatorForwardSlash))
    }
    if ($updated.Contains($rulesRootToken)) {
        $updated = $updated.Replace($rulesRootToken, $rulesAbsolute)
    }
    if ($updated.Contains($script:CodexPathConstant.PlaceholderGuardrailsPath)) {
        $updated = $updated.Replace($script:CodexPathConstant.PlaceholderGuardrailsPath, $guardrailsAbsolute)
    }
    if ($updated.Contains($script:CodexPathConstant.PlaceholderSddRoot)) {
        $updated = $updated.Replace($script:CodexPathConstant.PlaceholderSddRoot, $sddAbsolute)
    }
    if ($updated.Contains($toolkitToken)) {
        $toolkitRoot = if ($distribution -eq 'Local') { $homeSkillsRoot } else { $pluginRoot }
        $updated = $updated.Replace($toolkitToken, (Get-CodexNormalizedForwardSlashPath -Path $toolkitRoot))
    }

    $updated = Convert-CodexRouterMdcReferencesToMd -Text $updated
    $updated = Remove-CodexRouterRepoDocsLinks -Text $updated
    $updated = Add-CodexRouterDualRootCallout `
        -Text $updated `
        -InstallRootAbsolute $installAbsolute `
        -PluginRootAbsolute $pluginAbsolute `
        -LocalSkillsRootAbsolute $homeSkillsAbsolute `
        -RulesRootAbsolute $rulesAbsolute `
        -CatalogPathAbsolute $catalogAbsolute `
        -GuardrailsPathAbsolute $guardrailsAbsolute `
        -Distribution $distribution `
        -SelectedSkillsRootAbsolute $selectedToolkitRootAbsolute

    return $updated
}

function Assert-CodexRouterPlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $DestinationPath
    )

    foreach ($placeholder in @(
            $script:CodexPathConstant.PlaceholderToolkitRoot,
            $script:CodexPathConstant.PlaceholderSddRoot,
            $script:CodexPathConstant.PlaceholderGuardrailsPath
        )) {
        if ($Text.Contains($placeholder)) {
            throw ($script:CodexPublishMessage.PlaceholderUnresolved -f $placeholder, $DestinationPath)
        }
    }

    if ($Text -match '(?m)`docs/[A-Za-z0-9._/-]+`') {
        throw ($script:CodexPublishMessage.RouterRepoDocsLinkForbidden -f $DestinationPath)
    }
}

function Get-CodexRouterPublishContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [ValidateSet('Both', 'Local', 'Plugin')]
        [string] $CodexSkillDistribution
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexPublishMessage.InstallRootRequired
    }

    $repoRoot = Get-CodexRouterAdapterRepoRoot
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsPath = Join-Path (
        Join-Path (Join-Path $repoRoot $script:CodexPathConstant.CoreDirectoryName) $script:CodexPathConstant.RouterDirectoryName
    ) $script:CodexPathConstant.AgentsFileName
    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:CodexPublishMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    $raw = [System.IO.File]::ReadAllText($sourceAgentsPath)
    return (Resolve-CodexRouterPlaceholdersInText `
        -Text $raw `
        -InstallRoot $resolvedInstallRoot `
        -CodexSkillDistribution $CodexSkillDistribution)
}

function Invoke-CodexPublishRouter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf,

        [Parameter()]
        [ValidateSet('Both', 'Local', 'Plugin')]
        [string] $CodexSkillDistribution
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CodexPublishMessage.InstallRootRequired
    }

    $repoRoot = Get-CodexRouterAdapterRepoRoot
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceAgentsPath = Join-Path (
        Join-Path (Join-Path $repoRoot $script:CodexPathConstant.CoreDirectoryName) $script:CodexPathConstant.RouterDirectoryName
    ) $script:CodexPathConstant.AgentsFileName
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:CodexPathConstant.AgentsFileName

    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:CodexPublishMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success     = $true
            Implemented = $true
            CommandName = 'Publish-Router'
            WhatIf      = $true
            InstallRoot = $resolvedInstallRoot
            SourcePath  = $sourceAgentsPath
            AgentsPath  = $destinationAgentsPath
            Message     = ($script:CodexPublishMessage.RouterWhatIfOk -f $destinationAgentsPath)
            ExitCode    = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:CodexPathConstant.AgentsFileName

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    }
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $publishedContent = Get-CodexRouterPublishContent `
        -InstallRoot $resolvedInstallRoot `
        -AllowUserHome:$AllowUserHome `
        -CodexSkillDistribution $CodexSkillDistribution
    Assert-CodexRouterPlaceholdersResolved -Text $publishedContent -DestinationPath $destinationAgentsPath

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $null = Write-ToolkitFileIfAbsent -Path $destinationAgentsPath -Content $publishedContent -Encoding $utf8NoBom -InstallRoot $resolvedInstallRoot -RelativePath $script:CodexPathConstant.AgentsFileName
    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Router'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        SourcePath  = $sourceAgentsPath
        AgentsPath  = $destinationAgentsPath
        Message     = ($script:CodexPublishMessage.RouterPublishedOk -f $destinationAgentsPath)
        ExitCode    = 0
    }
}
