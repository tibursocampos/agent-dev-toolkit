#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for ZCode Publish-Router (core/router/AGENTS.md -> InstallRoot/AGENTS.md).

.DESCRIPTION
  Copies the neutral router markdown to the InstallRoot root as AGENTS.md and
  resolves {{TOOLKIT_ROOT}}, {{SDD_ROOT}}, and {{GUARDRAILS_PATH}} at the
  destination only (core/router stays placeholder-bearing). ZCode ADE does not
  publish a Cursor-style rules/*.mdc tree; router material stays AGENTS.md only.
  Uses Resolve-InstallRoot (USERPROFILE guard).
#>

$script:ZCodeRouterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ZCodeRouterModuleDirectory)) {
    $script:ZCodeRouterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-ZCodeRouterRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-ZCodeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-ZCodeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:ZCodeRouterModuleDirectory))
}

function Invoke-ZCodePublishRouter {
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
        throw $script:ZCodePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ZCodeRouterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceRouterRoot = Join-Path (Join-Path $repoRoot $script:ZCodePathConstant.CoreDirectoryName) $script:ZCodePathConstant.RouterDirectoryName
    $sourceAgentsPath = Join-Path $sourceRouterRoot $script:ZCodePathConstant.AgentsFileName
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:ZCodePathConstant.AgentsFileName

    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:ZCodePublishMessage.CoreRouterMissing -f $sourceAgentsPath)
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
            CursorMdcNote      = $script:ZCodePublishMessage.NoCursorMdcRules
            Message            = ($script:ZCodePublishMessage.RouterWhatIfOk -f $destinationAgentsPath)
            ExitCode           = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationAgentsPath = Join-Path $resolvedInstallRoot $script:ZCodePathConstant.AgentsFileName

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    }
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $raw = [System.IO.File]::ReadAllText($sourceAgentsPath)
    $placeholderMap = Get-ZCodePlaceholderMap -InstallRoot $resolvedInstallRoot
    $updated = Resolve-ZCodePlaceholdersInText -Text $raw -PlaceholderMap $placeholderMap
    Assert-ZCodePlaceholdersResolvedInFile -FilePath $destinationAgentsPath -Text $updated

    Assert-ToolkitManagedPathContained `
        -CandidatePath $destinationAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($destinationAgentsPath, $updated, $utf8NoBom)

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
        CursorMdcNote      = $script:ZCodePublishMessage.NoCursorMdcRules
        Message            = ($script:ZCodePublishMessage.RouterPublishedOk -f $destinationAgentsPath)
        ExitCode           = 0
    }
}

function Invoke-ZCodePublishSync {
    <#
    .SYNOPSIS
      Orchestrated ZCode publish for surfaces available through Step 4 (skills + router + hooks).
    #>
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
        throw $script:ZCodePublishMessage.InstallRootRequired
    }

    $skillsResult = Invoke-ZCodePublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
    if ($null -eq $skillsResult -or $skillsResult.Success -ne $true) {
        return [PSCustomObject]@{
            Success       = $false
            Implemented   = $true
            CommandName   = 'Invoke-ZCodePublishSync'
            SkillsResult  = $skillsResult
            RouterResult  = $null
            HooksResult   = $null
            Message       = $script:ZCodePublishMessage.SyncSkillsFailed
            ExitCode      = 1
        }
    }

    $routerResult = Invoke-ZCodePublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
    if ($null -eq $routerResult -or $routerResult.Success -ne $true) {
        return [PSCustomObject]@{
            Success       = $false
            Implemented   = $true
            CommandName   = 'Invoke-ZCodePublishSync'
            SkillsResult  = $skillsResult
            RouterResult  = $routerResult
            HooksResult   = $null
            Message       = $script:ZCodePublishMessage.SyncRouterFailed
            ExitCode      = 1
        }
    }

    $hooksResult = Invoke-ZCodePublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
    if ($null -eq $hooksResult -or $hooksResult.Success -ne $true) {
        return [PSCustomObject]@{
            Success       = $false
            Implemented   = $true
            CommandName   = 'Invoke-ZCodePublishSync'
            SkillsResult  = $skillsResult
            RouterResult  = $routerResult
            HooksResult   = $hooksResult
            Message       = $script:ZCodePublishMessage.SyncHooksFailed
            ExitCode      = 1
        }
    }

    return [PSCustomObject]@{
        Success            = $true
        Implemented        = $true
        CommandName        = 'Invoke-ZCodePublishSync'
        SkillsResult       = $skillsResult
        RouterResult       = $routerResult
        HooksResult        = $hooksResult
        InstallRoot        = $hooksResult.InstallRoot
        AgentsPath         = $routerResult.AgentsPath
        CliConfigPath      = $hooksResult.CliConfigPath
        HooksJsonPath      = $hooksResult.HooksJsonPath
        PublishesCursorMdc = $false
        CursorMdcNote      = $script:ZCodePublishMessage.NoCursorMdcRules
        Message            = ($script:ZCodePublishMessage.SyncOk -f $hooksResult.InstallRoot)
        ExitCode           = 0
    }
}
