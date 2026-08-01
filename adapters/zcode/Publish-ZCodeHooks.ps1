#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for ZCode Publish-Hooks (cli/config.json + hooks/hooks.json merge).

.DESCRIPTION
  Publishes toolkit hooks/config from adapters/zcode into InstallRoot with
  non-destructive JSON merge. Invalid JSON fails closed without truncating
  the destination. Plugin .zcode-plugin packaging is out of MVP scope.
#>

$script:ZCodeHooksModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ZCodeHooksModuleDirectory)) {
    $script:ZCodeHooksModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-ZCodeHooksRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-ZCodeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-ZCodeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:ZCodeHooksModuleDirectory))
}

function ConvertTo-ZCodeOrderedHashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $result[[string]$key] = ConvertTo-ZCodeOrderedHashtable -InputObject $InputObject[$key]
        }
        return $result
    }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $result = [ordered]@{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $result[$prop.Name] = ConvertTo-ZCodeOrderedHashtable -InputObject $prop.Value
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $list = @()
        foreach ($item in $InputObject) {
            $list += ,(ConvertTo-ZCodeOrderedHashtable -InputObject $item)
        }
        return $list
    }

    return $InputObject
}

function ConvertFrom-ZCodeJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ($script:ZCodePublishMessage.HooksJsonMissing -f $Path)
    }

    $raw = [System.IO.File]::ReadAllText($Path)
    try {
        $parsed = $raw | ConvertFrom-Json
    }
    catch {
        throw ($script:ZCodePublishMessage.HooksJsonInvalid -f $Path, $_.Exception.Message)
    }

    return ConvertTo-ZCodeOrderedHashtable -InputObject $parsed
}

function Get-ZCodeJsonFingerprint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $InputObject
    )

    return (($InputObject | ConvertTo-Json -Compress -Depth 100) -as [string])
}

function Merge-ZCodeJsonValues {
    <#
    .SYNOPSIS
      Non-destructive merge: destination (user) entries win; toolkit adds missing keys/items.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $Destination,

        [Parameter()]
        [AllowNull()]
        $Source
    )

    if ($null -eq $Destination) {
        return (ConvertTo-ZCodeOrderedHashtable -InputObject $Source)
    }
    if ($null -eq $Source) {
        return (ConvertTo-ZCodeOrderedHashtable -InputObject $Destination)
    }

    $destIsMap = ($Destination -is [System.Collections.IDictionary]) -or ($Destination -is [System.Management.Automation.PSCustomObject])
    $srcIsMap = ($Source -is [System.Collections.IDictionary]) -or ($Source -is [System.Management.Automation.PSCustomObject])
    if ($destIsMap -and $srcIsMap) {
        $destMap = ConvertTo-ZCodeOrderedHashtable -InputObject $Destination
        $srcMap = ConvertTo-ZCodeOrderedHashtable -InputObject $Source
        $merged = [ordered]@{}
        foreach ($key in $destMap.Keys) {
            $merged[$key] = $destMap[$key]
        }
        foreach ($key in $srcMap.Keys) {
            if (-not $merged.Contains($key)) {
                $merged[$key] = $srcMap[$key]
            }
            else {
                $merged[$key] = Merge-ZCodeJsonValues -Destination $merged[$key] -Source $srcMap[$key]
            }
        }
        return $merged
    }

    $destIsList = ($Destination -is [System.Collections.IEnumerable] -and $Destination -isnot [string])
    $srcIsList = ($Source -is [System.Collections.IEnumerable] -and $Source -isnot [string])
    if ($destIsList -and $srcIsList) {
        $mergedList = @()
        $seen = @{}
        foreach ($item in @($Destination)) {
            $fp = Get-ZCodeJsonFingerprint -InputObject $item
            if (-not $seen.ContainsKey($fp)) {
                $seen[$fp] = $true
                $mergedList += ,(ConvertTo-ZCodeOrderedHashtable -InputObject $item)
            }
        }
        foreach ($item in @($Source)) {
            $fp = Get-ZCodeJsonFingerprint -InputObject $item
            if (-not $seen.ContainsKey($fp)) {
                $seen[$fp] = $true
                $mergedList += ,(ConvertTo-ZCodeOrderedHashtable -InputObject $item)
            }
        }
        return $mergedList
    }

    # Scalar / type mismatch: keep destination (user) value.
    return (ConvertTo-ZCodeOrderedHashtable -InputObject $Destination)
}

function Set-ZCodeHooksEnabledTrue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $ConfigObject
    )

    if (-not $ConfigObject.Contains('hooks') -or $null -eq $ConfigObject['hooks']) {
        $ConfigObject['hooks'] = [ordered]@{}
    }

    $hooksNode = ConvertTo-ZCodeOrderedHashtable -InputObject $ConfigObject['hooks']
    if ($hooksNode -isnot [System.Collections.IDictionary]) {
        $hooksNode = [ordered]@{}
    }
    $hooksNode['enabled'] = $true
    $ConfigObject['hooks'] = $hooksNode
    return $ConfigObject
}

function Write-ZCodeJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        $repoRoot = Get-ZCodeHooksRepoRoot
        . (Join-Path (Join-Path $repoRoot 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1')
    }

    $directory = Split-Path -Parent $Path
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $directory -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $directory -InstallRoot $InstallRoot

    Assert-ToolkitManagedPathContained `
        -CandidatePath $Path `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $json = $Object | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine)
}

function Merge-ZCodeJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath,

        [Parameter(Mandatory = $true)]
        [string] $DestinationPath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $ForceHooksEnabled
    )

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        $repoRoot = Get-ZCodeHooksRepoRoot
        . (Join-Path (Join-Path $repoRoot 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1')
    }

    Assert-ToolkitManagedPathContained `
        -CandidatePath $DestinationPath `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $sourceObject = ConvertFrom-ZCodeJsonFile -Path $SourcePath

    if (Test-Path -LiteralPath $DestinationPath) {
        $destinationObject = ConvertFrom-ZCodeJsonFile -Path $DestinationPath
        $merged = Merge-ZCodeJsonValues -Destination $destinationObject -Source $sourceObject
    }
    else {
        $merged = $sourceObject
    }

    if ($ForceHooksEnabled.IsPresent -and $merged -is [System.Collections.IDictionary]) {
        $merged = Set-ZCodeHooksEnabledTrue -ConfigObject $merged
    }

    Write-ZCodeJsonFile -Path $DestinationPath -Object $merged -InstallRoot $InstallRoot
    return $merged
}

function Invoke-ZCodePublishHooks {
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

    $repoRoot = Get-ZCodeHooksRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot

    $sourceCliConfig = Join-Path $script:ZCodeHooksModuleDirectory (Join-Path $script:ZCodePathConstant.CliDirectoryName $script:ZCodePathConstant.CliConfigFileName)
    $sourceHooksJson = Join-Path $script:ZCodeHooksModuleDirectory (Join-Path $script:ZCodePathConstant.HooksDirectoryName $script:ZCodePathConstant.HooksJsonFileName)
    $destinationCliConfig = Join-Path $resolvedInstallRoot (Join-Path $script:ZCodePathConstant.CliDirectoryName $script:ZCodePathConstant.CliConfigFileName)
    $destinationHooksJson = Join-Path $resolvedInstallRoot (Join-Path $script:ZCodePathConstant.HooksDirectoryName $script:ZCodePathConstant.HooksJsonFileName)

    if (-not (Test-Path -LiteralPath $sourceCliConfig)) {
        throw ($script:ZCodePublishMessage.HooksSourceMissing -f $sourceCliConfig)
    }
    if (-not (Test-Path -LiteralPath $sourceHooksJson)) {
        throw ($script:ZCodePublishMessage.HooksSourceMissing -f $sourceHooksJson)
    }

    # Validate source JSON before any destination mutation.
    $null = ConvertFrom-ZCodeJsonFile -Path $sourceCliConfig
    $null = ConvertFrom-ZCodeJsonFile -Path $sourceHooksJson

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Hooks'
            WhatIf           = $true
            InstallRoot      = $resolvedInstallRoot
            CliConfigPath    = $destinationCliConfig
            HooksJsonPath    = $destinationHooksJson
            SourceCliConfig  = $sourceCliConfig
            SourceHooksJson  = $sourceHooksJson
            FilesWritten     = 0
            Message          = ($script:ZCodePublishMessage.HooksWhatIfOk -f $resolvedInstallRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationCliConfig = Join-Path $resolvedInstallRoot (Join-Path $script:ZCodePathConstant.CliDirectoryName $script:ZCodePathConstant.CliConfigFileName)
    $destinationHooksJson = Join-Path $resolvedInstallRoot (Join-Path $script:ZCodePathConstant.HooksDirectoryName $script:ZCodePathConstant.HooksJsonFileName)

    $null = Merge-ZCodeJsonFile -SourcePath $sourceCliConfig -DestinationPath $destinationCliConfig -InstallRoot $resolvedInstallRoot -ForceHooksEnabled
    $null = Merge-ZCodeJsonFile -SourcePath $sourceHooksJson -DestinationPath $destinationHooksJson -InstallRoot $resolvedInstallRoot

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Hooks'
        WhatIf           = $false
        InstallRoot      = $resolvedInstallRoot
        CliConfigPath    = $destinationCliConfig
        HooksJsonPath    = $destinationHooksJson
        SourceCliConfig  = $sourceCliConfig
        SourceHooksJson  = $sourceHooksJson
        FilesWritten     = 2
        Message          = ($script:ZCodePublishMessage.HooksPublishedOk -f $destinationCliConfig, $destinationHooksJson)
        ExitCode         = 0
    }
}
