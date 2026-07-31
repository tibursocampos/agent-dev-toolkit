#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Copilot Publish-Skills (copy core/skills + resolve placeholders).

.DESCRIPTION
  Mode user: InstallRoot models ~/.copilot; skills land under InstallRoot/skills.
  Mode repo: InstallRoot models .github; skills land under InstallRoot/skills.
  Placeholders resolved after copy. Does not write the toolkit working-tree .github -
  callers must pass a fixture InstallRoot (or explicit path) for Mode repo.
#>

$script:CopilotPublishModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CopilotPublishModuleDirectory)) {
    $script:CopilotPublishModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_copilotToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CopilotPublishModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_copilotToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _copilotToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-CopilotPublishAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:CopilotPublishModuleDirectory))
}

function Get-CopilotNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:CopilotPathConstant.PathSeparatorForwardSlash)
}

function Get-CopilotPublishNormalizedMode {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Mode
    )

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        throw $script:CopilotPublishMessage.ModeRequired
    }

    $normalized = $Mode.Trim().ToLowerInvariant()
    $valid = @(
        $script:CopilotPathConstant.ModeUser,
        $script:CopilotPathConstant.ModeRepo
    )
    if ($valid -notcontains $normalized) {
        throw ($script:CopilotPublishMessage.ModeInvalid -f $Mode)
    }

    return $normalized
}

function Get-CopilotPlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-CopilotNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-CopilotNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:CopilotPathConstant.SddDirectoryName)
    $guardrailsPath = Get-CopilotNormalizedForwardSlashPath -Path (
        Join-Path (Join-Path $InstallRoot $script:CopilotPathConstant.InstructionsDirectoryName) $script:CopilotPathConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:CopilotPathConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:CopilotPathConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:CopilotPathConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Initialize-CopilotToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-CopilotPublishAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ("Copilot Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Get-CopilotUnresolvedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:CopilotPathConstant.PlaceholderToolkitRoot,
        $script:CopilotPathConstant.PlaceholderSddRoot,
        $script:CopilotPathConstant.PlaceholderGuardrailsPath
    )
}

function Copy-CopilotCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-CopilotToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Resolve-CopilotPlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-CopilotToolkitManagedTreeLib
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:CopilotPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CopilotUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CopilotPublishMessage.PlaceholderUnresolved
}

function Assert-CopilotPlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Initialize-CopilotToolkitManagedTreeLib
    $identityMap = [ordered]@{}
    foreach ($token in (Get-CopilotUnresolvedPlaceholderTokens)) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:CopilotPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CopilotUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CopilotPublishMessage.PlaceholderUnresolved
}

function Invoke-CopilotPublishSkills {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [string] $Mode,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotPublishMessage.InstallRootRequired
    }

    $normalizedMode = Get-CopilotPublishNormalizedMode -Mode $Mode

    $repoRoot = Get-CopilotPublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:CopilotPathConstant.CoreDirectoryName) $script:CopilotPathConstant.SkillsDirectoryName
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:CopilotPublishMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Skills'
            WhatIf       = $true
            Mode         = $normalizedMode
            InstallRoot  = $resolvedInstallRoot
            SkillsRoot   = $destinationSkillsRoot
            SourceRoot   = $sourceSkillsRoot
            FilesCopied  = 0
            Message      = ($script:CopilotPublishMessage.WhatIfOk -f $destinationSkillsRoot, $normalizedMode)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.SkillsDirectoryName

    Initialize-CopilotToolkitManagedTreeLib
    $placeholderMap = Get-CopilotPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:CopilotPathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-CopilotUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:CopilotPublishMessage.PlaceholderUnresolved

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Skills'
        WhatIf      = $false
        Mode        = $normalizedMode
        InstallRoot = $resolvedInstallRoot
        SkillsRoot  = $destinationSkillsRoot
        SourceRoot  = $sourceSkillsRoot
        FilesCopied = $publishResult.FilesCopied
        Message     = ($script:CopilotPublishMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot, $normalizedMode)
        ExitCode    = 0
    }
}
