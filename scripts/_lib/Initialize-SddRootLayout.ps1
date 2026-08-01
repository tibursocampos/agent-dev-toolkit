#Requires -Version 5.1
<#
.SYNOPSIS
  Shared SDD runtime layout prepare for all Tier-1 adapters.

.DESCRIPTION
  Creates <InstallRoot>/sdd and sdd/sessions when missing; seeds manifest.json
  only when absent. Never overwrites an existing manifest. Never deletes or
  clears session files under sessions/.

  Dot-source from adapter modules. Requires Resolve-InstallRoot.ps1 helpers
  (Assert-ToolkitManaged* come from Copy-ToolkitManagedTree.ps1).
#>

if (-not (Get-Variable -Scope Script -Name ToolkitConstant -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'ToolkitConstants.ps1')
}

if (-not (Get-Command -Name Assert-ToolkitManagedDestinationUnderInstallRoot -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Copy-ToolkitManagedTree.ps1')
}

if (-not (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Resolve-InstallRoot.ps1')
}

$script:ToolkitSddConstant = @{
    DirectoryName           = 'sdd'
    SessionsDirectoryName   = 'sessions'
    ManifestFileName        = 'manifest.json'
    ManifestSchemaVersion   = 2
    JsonConvertDepth        = 6
    AtomicWriteTempSuffix   = '.tmp'
    AtomicWriteMaxAttempts  = 3
    AtomicWriteRetryDelayMs = 50
}

$script:ToolkitSddMessage = @{
    InstallRootRequired = 'InstallRoot is required.'
    RepoRootRequired    = 'RepoRoot is required.'
    RootResolved        = 'SDD root resolved at {0}.'
    RootPrepared        = 'Prepared SDD root at {0} (sessionsCreated={1}; manifestCreated={2}).'
    RootWouldPrepare    = 'WhatIf: would prepare SDD root at {0} (sessions + seed manifest.json if missing).'
    AtomicWriteFailed   = 'Failed to write {0} after {1} attempt(s): {2}'
}

function New-ToolkitSddManifestSeedObject {
    [CmdletBinding()]
    param()

    return [ordered]@{
        schema_version = [int]$script:ToolkitSddConstant.ManifestSchemaVersion
        repositories   = [ordered]@{}
    }
}

function ConvertTo-ToolkitSddCleanJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter()]
        [int] $Depth = 0
    )

    if ($Depth -le 0) {
        $Depth = [int]$script:ToolkitSddConstant.JsonConvertDepth
    }

    $raw = $Object | ConvertTo-Json -Depth $Depth
    $raw = [regex]::Replace($raw, '\\u([0-9a-fA-F]{4})', {
            param($m)
            $cp = [Convert]::ToInt32($m.Groups[1].Value, 16)
            if ($cp -ge 0x20 -and $cp -ne 0x22 -and $cp -ne 0x5C) {
                [char]$cp
            }
            else {
                $m.Value
            }
        })
    $lines = $raw -split "`n"
    return ($lines | ForEach-Object {
            if ($_ -match '^( {4,})') {
                $indentDepth = [math]::Floor($Matches[1].Length / 4)
                ('  ' * $indentDepth) + $_.TrimStart()
            }
            else {
                $_
            }
        }) -join "`n"
}

function Write-ToolkitSddUtf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Content,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    Assert-ToolkitManagedPathContained `
        -CandidatePath $Path `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tempPath = $Path + $script:ToolkitSddConstant.AtomicWriteTempSuffix
    $maxAttempts = [int]$script:ToolkitSddConstant.AtomicWriteMaxAttempts
    $delayMs = [int]$script:ToolkitSddConstant.AtomicWriteRetryDelayMs
    $lastError = $null

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            Assert-ToolkitManagedPathContained `
                -CandidatePath $tempPath `
                -RootPath $InstallRoot `
                -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
                -RequireStrictChild
            [System.IO.File]::WriteAllText($tempPath, $Content, $utf8NoBom)
            Move-Item -LiteralPath $tempPath -Destination $Path -Force
            return
        }
        catch {
            $lastError = $_
            if (Test-Path -LiteralPath $tempPath) {
                $null = Assert-PathUnderInstallRootForDelete -CandidatePath $tempPath -InstallRoot $InstallRoot
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            }
            if ($attempt -lt $maxAttempts) {
                Start-Sleep -Milliseconds $delayMs
            }
        }
    }

    $detail = if ($null -ne $lastError) { [string]$lastError.Exception.Message } else { 'unknown error' }
    throw ($script:ToolkitSddMessage.AtomicWriteFailed -f $Path, $maxAttempts, $detail)
}

function Initialize-SddRootLayout {
    <#
    .SYNOPSIS
      Ensure sdd/ + sessions/ exist; seed manifest.json only when absent.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SddRoot,

        [Parameter(Mandatory = $true)]
        [string] $SessionsPath,

        [Parameter(Mandatory = $true)]
        [string] $ManifestPath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf
    )

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
        $seed = New-ToolkitSddManifestSeedObject
        $json = ConvertTo-ToolkitSddCleanJson -Object $seed
        Write-ToolkitSddUtf8NoBom -Path $ManifestPath -Content $json -InstallRoot $InstallRoot
        $manifestCreated = $true
    }

    return [PSCustomObject]@{
        SessionsCreated = $sessionsCreated
        ManifestCreated = $manifestCreated
    }
}

function Invoke-ToolkitGetSddRoot {
    <#
    .SYNOPSIS
      Resolve or prepare <InstallRoot>/sdd for any Tier-1 adapter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter()]
        [switch] $Prepare,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf,

        [Parameter()]
        [string] $MessageResolved,

        [Parameter()]
        [string] $MessagePrepared,

        [Parameter()]
        [string] $MessageWouldPrepare
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ToolkitSddMessage.InstallRootRequired
    }
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        throw $script:ToolkitSddMessage.RepoRootRequired
    }

    $msgResolved = if ([string]::IsNullOrWhiteSpace($MessageResolved)) {
        $script:ToolkitSddMessage.RootResolved
    }
    else {
        $MessageResolved
    }
    $msgPrepared = if ([string]::IsNullOrWhiteSpace($MessagePrepared)) {
        $script:ToolkitSddMessage.RootPrepared
    }
    else {
        $MessagePrepared
    }
    $msgWouldPrepare = if ([string]::IsNullOrWhiteSpace($MessageWouldPrepare)) {
        $script:ToolkitSddMessage.RootWouldPrepare
    }
    else {
        $MessageWouldPrepare
    }

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $RepoRoot

    $sddRoot = Join-Path $resolvedInstallRoot $script:ToolkitSddConstant.DirectoryName
    $sessionsPath = Join-Path $sddRoot $script:ToolkitSddConstant.SessionsDirectoryName
    $manifestPath = Join-Path $sddRoot $script:ToolkitSddConstant.ManifestFileName

    if (-not $Prepare.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Get-SddRoot'
            InstallRoot  = $resolvedInstallRoot
            SddRoot      = $sddRoot
            SessionsPath = $sessionsPath
            ManifestPath = $manifestPath
            Prepared     = $false
            WhatIf       = $false
            Message      = ($msgResolved -f $sddRoot)
            ExitCode     = 0
        }
    }

    if ($WhatIf.IsPresent) {
        $layout = Initialize-SddRootLayout `
            -SddRoot $sddRoot `
            -SessionsPath $sessionsPath `
            -ManifestPath $manifestPath `
            -InstallRoot $resolvedInstallRoot `
            -WhatIf

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
            Message         = ($msgWouldPrepare -f $sddRoot)
            ExitCode        = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $RepoRoot
    $sddRoot = Join-Path $resolvedInstallRoot $script:ToolkitSddConstant.DirectoryName
    $sessionsPath = Join-Path $sddRoot $script:ToolkitSddConstant.SessionsDirectoryName
    $manifestPath = Join-Path $sddRoot $script:ToolkitSddConstant.ManifestFileName
    $layout = Initialize-SddRootLayout `
        -SddRoot $sddRoot `
        -SessionsPath $sessionsPath `
        -ManifestPath $manifestPath `
        -InstallRoot $resolvedInstallRoot

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
        Message         = ($msgPrepared -f $sddRoot, $layout.SessionsCreated, $layout.ManifestCreated)
        ExitCode        = 0
    }
}

function Test-ToolkitSddLayoutPresent {
    <#
    .SYNOPSIS
      Assert InstallRoot/sdd has sessions/ directory and manifest.json (smoke helper).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [System.Collections.Generic.List[string]] $MissingRelative
    )

    $sddDir = $script:ToolkitSddConstant.DirectoryName
    $sessionsRel = $sddDir + '/' + $script:ToolkitSddConstant.SessionsDirectoryName
    $manifestRel = $sddDir + '/' + $script:ToolkitSddConstant.ManifestFileName
    $sddRoot = Join-Path $InstallRoot $sddDir
    $complete = $true

    if (-not (Test-Path -LiteralPath $sddRoot -PathType Container)) {
        if ($null -ne $MissingRelative) {
            $MissingRelative.Add($sessionsRel)
            $MissingRelative.Add($manifestRel)
        }
        return $false
    }

    $sessionsPath = Join-Path $sddRoot $script:ToolkitSddConstant.SessionsDirectoryName
    if (-not (Test-Path -LiteralPath $sessionsPath -PathType Container)) {
        if ($null -ne $MissingRelative) {
            $MissingRelative.Add($sessionsRel)
        }
        $complete = $false
    }

    $manifestPath = Join-Path $sddRoot $script:ToolkitSddConstant.ManifestFileName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        if ($null -ne $MissingRelative) {
            $MissingRelative.Add($manifestRel)
        }
        $complete = $false
    }
    else {
        $manifestValid = $false
        try {
            $manifestRaw = Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop
            $manifestObject = $manifestRaw | ConvertFrom-Json -ErrorAction Stop
            $schemaVersion = $manifestObject.schema_version
            if ($null -ne $schemaVersion) {
                $manifestValid = ([int]$schemaVersion -eq [int]$script:ToolkitSddConstant.ManifestSchemaVersion)
            }
        }
        catch {
            $manifestValid = $false
        }

        if (-not $manifestValid) {
            if ($null -ne $MissingRelative) {
                $MissingRelative.Add($manifestRel)
            }
            $complete = $false
        }
    }

    return $complete
}
