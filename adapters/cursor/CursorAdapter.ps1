#Requires -Version 5.1
<#
.SYNOPSIS
  Cursor adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `cursor`.
  Get-Capabilities / Get-InstallRoots / Publish-* / Get-SddRoot (-Prepare) /
  Invoke-SmokeValidate are implemented; Uninstall-Toolkit stays fail-closed (out of MVP).
  Does not write under USERPROFILE unless -AllowUserHome is set.
  Smoke is filesystem-only (Cursor hooks trust UI out of scope).
#>

$script:CursorAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CursorAdapterDirectory)) {
    $script:CursorAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:CursorAdapterLibDir = Join-Path $script:CursorAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:CursorAdapterLibDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $script:CursorAdapterLibDir 'Resolve-InstallRoot.ps1')
. (Join-Path $script:CursorAdapterLibDir 'Copy-ToolkitManagedTree.ps1')

. (Join-Path $script:CursorAdapterDirectory 'CursorPathConstants.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorSkills.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorPolicy.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorRouter.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Publish-CursorHooks.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Invoke-CursorSmokeValidate.ps1')
. (Join-Path $script:CursorAdapterDirectory 'Uninstall-CursorToolkit.ps1')

$script:CursorAdapterAgentId = 'cursor'

$script:CursorAdapterCommandNames = @(
    'Get-Capabilities',
    'Get-InstallRoots',
    'Publish-Skills',
    'Publish-Policy',
    'Publish-Router',
    'Publish-Hooks',
    'Get-SddRoot',
    'Invoke-SmokeValidate',
    'Uninstall-Toolkit'
)

$script:CursorAdapterSubagentsNative = 'native'

$script:CursorAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $true
    router    = $true
    sdd       = $true
    plugin    = $false
    subagents = $script:CursorAdapterSubagentsNative
}

function New-CursorAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:CursorAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-CursorAdapterCommandNames {
    return @($script:CursorAdapterCommandNames)
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Cursor adapter capability flags (skills/rules/hooks/router/sdd).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:CursorAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:CursorAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:CursorAdapterCapabilityFlags
        Message      = $script:CursorAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe the official Cursor install root and InstallRoot override semantics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:CursorAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:CursorAdapterConstant.OfficialUserRootRelativePath
    }

    return [PSCustomObject]@{
        Success                      = $true
        Implemented                  = $true
        AgentId                      = $AgentId.Trim()
        OfficialUserRootRelativePath = $script:CursorAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription  = $script:CursorAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath         = $officialFull
        FixtureRelativePath          = $script:CursorAdapterConstant.FixtureRelativePath
        OverrideParameter            = $script:CursorAdapterConstant.InstallRootOverrideParameter
        OverrideDescription          = $script:CursorAdapterConstant.InstallRootOverrideDescription
        SddDirectoryName             = $script:CursorAdapterConstant.SddDirectoryName
        Message                      = ('{0} {1}' -f $script:CursorAdapterConstant.OfficialUserRootDescription, $script:CursorAdapterConstant.InstallRootOverrideDescription)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills (kebab folders) into InstallRoot/skills.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Publish core/policy/*.md into InstallRoot/rules as Cursor *.mdc rules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md into InstallRoot/AGENTS.md.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish hook scripts under InstallRoot/hooks and merge hooks.json at InstallRoot root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorPublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function New-CursorSddManifestSeedObject {
    return [ordered]@{
        schema_version = [int]$script:CursorAdapterConstant.ManifestSchemaVersion
        repositories   = [ordered]@{}
    }
}

function Initialize-CursorSddRootLayout {
    param(
        [Parameter(Mandatory = $true)][string] $SddRoot,
        [Parameter(Mandatory = $true)][string] $SessionsPath,
        [Parameter(Mandatory = $true)][string] $ManifestPath,
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter()][switch] $WhatIf
    )

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:CursorAdapterLibDir 'Copy-ToolkitManagedTree.ps1')
    }

    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $SddRoot -InstallRoot $InstallRoot

    $sessionsCreated = $false
    $manifestCreated = $false

    if ($WhatIf.IsPresent) {
        $sessionsCreated = -not (Test-Path -LiteralPath $SessionsPath)
        $manifestCreated = -not (Test-Path -LiteralPath $ManifestPath)
        return [PSCustomObject]@{
            SessionsCreated = $sessionsCreated
            ManifestCreated = $manifestCreated
        }
    }

    if (-not (Test-Path -LiteralPath $SddRoot)) {
        New-Item -ItemType Directory -Path $SddRoot -Force | Out-Null
    }
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $SddRoot -InstallRoot $InstallRoot

    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $SessionsPath -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $SessionsPath)) {
        New-Item -ItemType Directory -Path $SessionsPath -Force | Out-Null
        $sessionsCreated = $true
    }
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $SessionsPath -InstallRoot $InstallRoot

    Assert-ToolkitManagedPathContained `
        -CandidatePath $ManifestPath `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        $seed = New-CursorSddManifestSeedObject
        $json = ConvertTo-CursorCleanJson -Object $seed
        Write-CursorUtf8NoBom -Path $ManifestPath -Content $json -InstallRoot $InstallRoot
        $manifestCreated = $true
    }

    return [PSCustomObject]@{
        SessionsCreated = $sessionsCreated
        ManifestCreated = $manifestCreated
    }
}

function Get-SddRoot {
    <#
    .SYNOPSIS
      Resolve `<InstallRoot>/sdd`. With -Prepare, ensure `sessions/` and seed `manifest.json` if missing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $Prepare,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-CursorAdapterRepoRoot
    $resolvedInstallRoot = if ($Prepare.IsPresent) {
        Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    }
    else {
        [System.IO.Path]::GetFullPath($InstallRoot)
    }

    $sddRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.SddDirectoryName
    $sessionsPath = Join-Path $sddRoot $script:CursorAdapterConstant.SessionsDirectoryName
    $manifestPath = Join-Path $sddRoot $script:CursorAdapterConstant.ManifestFileName

    if (-not $Prepare.IsPresent) {
        return [PSCustomObject]@{
            Success       = $true
            Implemented   = $true
            CommandName   = 'Get-SddRoot'
            InstallRoot   = $resolvedInstallRoot
            SddRoot       = $sddRoot
            SessionsPath  = $sessionsPath
            ManifestPath  = $manifestPath
            Prepared      = $false
            WhatIf        = $false
            Message       = ($script:CursorAdapterMessage.SddRootResolved -f $sddRoot)
            ExitCode      = 0
        }
    }

    if ($WhatIf.IsPresent) {
        $layout = Initialize-CursorSddRootLayout -SddRoot $sddRoot -SessionsPath $sessionsPath -ManifestPath $manifestPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        return [PSCustomObject]@{
            Success         = $true
            Implemented     = $true
            CommandName     = 'Get-SddRoot'
            InstallRoot     = $resolvedInstallRoot
            SddRoot         = $sddRoot
            SessionsPath    = $sessionsPath
            ManifestPath    = $manifestPath
            Prepared        = $true
            SessionsCreated = [bool]$layout.SessionsCreated
            ManifestCreated = [bool]$layout.ManifestCreated
            WhatIf          = $true
            Message         = ($script:CursorAdapterMessage.SddRootWouldPrepare -f $sddRoot)
            ExitCode        = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sddRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.SddDirectoryName
    $sessionsPath = Join-Path $sddRoot $script:CursorAdapterConstant.SessionsDirectoryName
    $manifestPath = Join-Path $sddRoot $script:CursorAdapterConstant.ManifestFileName
    $layout = Initialize-CursorSddRootLayout -SddRoot $sddRoot -SessionsPath $sessionsPath -ManifestPath $manifestPath -InstallRoot $resolvedInstallRoot

    return [PSCustomObject]@{
        Success         = $true
        Implemented     = $true
        CommandName     = 'Get-SddRoot'
        InstallRoot     = $resolvedInstallRoot
        SddRoot         = $sddRoot
        SessionsPath    = $sessionsPath
        ManifestPath    = $manifestPath
        Prepared        = $true
        SessionsCreated = [bool]$layout.SessionsCreated
        ManifestCreated = [bool]$layout.ManifestCreated
        WhatIf          = $false
        Message         = ($script:CursorAdapterMessage.SddRootPrepared -f $sddRoot, $layout.SessionsCreated, $layout.ManifestCreated)
        ExitCode        = 0
    }
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run filesystem-only Cursor smoke against a fixture InstallRoot (TE01/TE04).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove published toolkit files from InstallRoot. Stub - out of adapter MVP scope.
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
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    return Invoke-CursorUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
