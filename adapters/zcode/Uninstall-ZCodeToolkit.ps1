#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for ZCode ADE adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot:
  - skills/<id> folders matching core/skills
  - AGENTS.md (Publish-Router target) when provenance confirms toolkit ownership
    (.toolkit-managed-publish.json sha256, or legacy hash match to core/router publish)
  - reverse-merge cli/config.json and hooks/hooks.json (drop toolkit-marked
    handlers / fingerprint-equal toolkit overlay; preserve alien keys)

  Operator-edited or drifted AGENTS.md is preserved. JSON reverse-merge runs before FS deletes.

  Does NOT remove sdd/sessions or sdd/manifest.json (operator runtime state).
  Does not wipe InstallRoot wholesale (RN07 / CU03). Plugin packaging out of scope.
  Supports -WhatIf.
#>

$script:ZCodeUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ZCodeUninstallModuleDirectory)) {
    $script:ZCodeUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_zcodeUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:ZCodeUninstallModuleDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_zcodeUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _zcodeUninstallLibDir -ErrorAction SilentlyContinue

$script:ZCodeUninstallMessage = @{
    InstallRootRequired   = 'InstallRoot is required.'
    NothingFound          = 'ZCode Uninstall-Toolkit: no keyed toolkit artifacts found under {0}.'
    WhatIfOk              = 'ZCode Uninstall-Toolkit WhatIf: would remove {0} path(s) under {1}.'
    RemovedOk             = 'ZCode Uninstall-Toolkit: removed {0} path(s) under {1}.'
    JsonAbsentOk          = '{0} absent; nothing to reverse-merge.'
    JsonNoManaged         = '{0} had no toolkit-managed overlay to remove.'
    JsonWhatIfOk          = 'WhatIf: would reverse-merge toolkit overlay out of {0}.'
    JsonCleanedOk         = 'Reverse-merged toolkit overlay out of {0}.'
    JsonInvalid           = 'Invalid JSON at {0}: {1}'
    SddPreservedNote      = 'SDD sessions/manifest preserved (operator state).'
}

function Get-ZCodeUninstallRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-ZCodeAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-ZCodeAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:ZCodeUninstallModuleDirectory))
}

function Get-ZCodeManagedSkillIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $coreSkillsRoot = Join-Path (
        Join-Path $RepoRoot $script:ZCodePathConstant.CoreDirectoryName
    ) $script:ZCodePathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force |
            Select-Object -ExpandProperty Name
    )
}

function Test-ZCodeCommandIsToolkitManaged {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [string] $Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $false
    }

    $markers = @(
        $script:ZCodePathConstant.ToolkitHooksMarker,
        $script:ZCodePathConstant.ToolkitSessionStartMarker
    )
    foreach ($marker in $markers) {
        if ($Command.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }
    return $false
}

function Test-ZCodeObjectContainsToolkitMarker {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $InputObject
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [string]) {
        return (Test-ZCodeCommandIsToolkitManaged -Command $InputObject)
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in @($InputObject.Keys)) {
            if (Test-ZCodeObjectContainsToolkitMarker -InputObject $InputObject[$key]) {
                return $true
            }
        }
        return $false
    }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $InputObject.PSObject.Properties) {
            if (Test-ZCodeObjectContainsToolkitMarker -InputObject $prop.Value) {
                return $true
            }
        }
        return $false
    }

    if ($InputObject -is [System.Collections.IEnumerable]) {
        foreach ($item in @($InputObject)) {
            if (Test-ZCodeObjectContainsToolkitMarker -InputObject $item) {
                return $true
            }
        }
    }

    return $false
}

function Remove-ZCodeToolkitOverlayFromObject {
    <#
    .SYNOPSIS
      Strip toolkit-marked list items and fingerprint-equal toolkit map leaves from dest.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $Destination,

        [Parameter()]
        [AllowNull()]
        $ToolkitSource
    )

    if ($null -eq $Destination) {
        return $null
    }
    if ($null -eq $ToolkitSource) {
        return (ConvertTo-ZCodeOrderedHashtable -InputObject $Destination)
    }

    $destMap = ($Destination -is [System.Collections.IDictionary]) -or ($Destination -is [System.Management.Automation.PSCustomObject])
    $srcMap = ($ToolkitSource -is [System.Collections.IDictionary]) -or ($ToolkitSource -is [System.Management.Automation.PSCustomObject])
    if ($destMap -and $srcMap) {
        $destOrdered = ConvertTo-ZCodeOrderedHashtable -InputObject $Destination
        $srcOrdered = ConvertTo-ZCodeOrderedHashtable -InputObject $ToolkitSource
        $result = [ordered]@{}
        foreach ($key in @($destOrdered.Keys)) {
            if (-not $srcOrdered.Contains($key)) {
                $result[$key] = $destOrdered[$key]
                continue
            }

            $destFp = Get-ZCodeJsonFingerprint -InputObject $destOrdered[$key]
            $srcFp = Get-ZCodeJsonFingerprint -InputObject $srcOrdered[$key]
            if ($destFp -eq $srcFp) {
                # Exact toolkit overlay leaf — drop.
                continue
            }

            $stripped = Remove-ZCodeToolkitOverlayFromObject -Destination $destOrdered[$key] -ToolkitSource $srcOrdered[$key]
            if ($null -eq $stripped) {
                continue
            }
            if ($stripped -is [System.Collections.IDictionary] -and $stripped.Count -eq 0) {
                continue
            }
            if ($stripped -is [System.Collections.IEnumerable] -and $stripped -isnot [string] -and @($stripped).Count -eq 0) {
                continue
            }
            $result[$key] = $stripped
        }
        return $result
    }

    $destList = ($Destination -is [System.Collections.IEnumerable] -and $Destination -isnot [string])
    $srcList = ($ToolkitSource -is [System.Collections.IEnumerable] -and $ToolkitSource -isnot [string])
    if ($destList -and $srcList) {
        $toolkitFingerprints = @{}
        foreach ($item in @($ToolkitSource)) {
            $toolkitFingerprints[(Get-ZCodeJsonFingerprint -InputObject $item)] = $true
        }

        $kept = @()
        foreach ($item in @($Destination)) {
            $fp = Get-ZCodeJsonFingerprint -InputObject $item
            if ($toolkitFingerprints.ContainsKey($fp)) {
                continue
            }
            if (Test-ZCodeObjectContainsToolkitMarker -InputObject $item) {
                continue
            }
            $kept += ,(ConvertTo-ZCodeOrderedHashtable -InputObject $item)
        }
        return $kept
    }

    # Scalar mismatch: keep destination (alien / operator value).
    return (ConvertTo-ZCodeOrderedHashtable -InputObject $Destination)
}

function Remove-ZCodeManagedPathIfPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf,

        [Parameter()]
        [switch] $Recurse
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $Path -InstallRoot $InstallRoot

    if ($WhatIf.IsPresent) {
        return $true
    }

    if ($Recurse.IsPresent) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    else {
        Remove-Item -LiteralPath $Path -Force
    }

    return $true
}

function Remove-ZCodeToolkitJsonOverlay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DestinationPath,

        [Parameter(Mandatory = $true)]
        [string] $SourcePath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf
    )

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        return [PSCustomObject]@{
            Success     = $true
            Touched     = $false
            Path        = $DestinationPath
            Message     = ($script:ZCodeUninstallMessage.JsonAbsentOk -f $DestinationPath)
        }
    }

    try {
        $destinationObject = ConvertFrom-ZCodeJsonFile -Path $DestinationPath
        $toolkitSource = ConvertFrom-ZCodeJsonFile -Path $SourcePath
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Touched = $false
            Path    = $DestinationPath
            Message = ($script:ZCodeUninstallMessage.JsonInvalid -f $DestinationPath, $_.Exception.Message)
        }
    }

    $beforeFp = Get-ZCodeJsonFingerprint -InputObject $destinationObject
    $stripped = Remove-ZCodeToolkitOverlayFromObject -Destination $destinationObject -ToolkitSource $toolkitSource
    $afterFp = Get-ZCodeJsonFingerprint -InputObject $stripped

    if ($beforeFp -eq $afterFp) {
        return [PSCustomObject]@{
            Success = $true
            Touched = $false
            Path    = $DestinationPath
            Message = ($script:ZCodeUninstallMessage.JsonNoManaged -f $DestinationPath)
        }
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success = $true
            Touched = $true
            Path    = $DestinationPath
            WhatIf  = $true
            Message = ($script:ZCodeUninstallMessage.JsonWhatIfOk -f $DestinationPath)
        }
    }

    if ($null -eq $stripped) {
        $stripped = [ordered]@{}
    }

    Write-ZCodeJsonFile -Path $DestinationPath -Object $stripped -InstallRoot $InstallRoot

    return [PSCustomObject]@{
        Success = $true
        Touched = $true
        Path    = $DestinationPath
        Message = ($script:ZCodeUninstallMessage.JsonCleanedOk -f $DestinationPath)
    }
}

function Invoke-ZCodeUninstallToolkit {
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
        throw $script:ZCodeUninstallMessage.InstallRootRequired
    }

    $repoRoot = Get-ZCodeUninstallRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    . (Join-Path $libDir 'ToolkitManagedPublishInventory.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $removedPaths = New-Object System.Collections.Generic.List[string]
    $wouldRemovePaths = New-Object System.Collections.Generic.List[string]
    $routerNotes = New-Object System.Collections.Generic.List[string]

    $sourceCliConfig = Join-Path $script:ZCodeUninstallModuleDirectory (
        Join-Path $script:ZCodePathConstant.CliDirectoryName $script:ZCodePathConstant.CliConfigFileName
    )
    $sourceHooksJson = Join-Path $script:ZCodeUninstallModuleDirectory (
        Join-Path $script:ZCodePathConstant.HooksDirectoryName $script:ZCodePathConstant.HooksJsonFileName
    )
    $destinationCliConfig = Join-Path $resolvedInstallRoot (
        Join-Path $script:ZCodePathConstant.CliDirectoryName $script:ZCodePathConstant.CliConfigFileName
    )
    $destinationHooksJson = Join-Path $resolvedInstallRoot (
        Join-Path $script:ZCodePathConstant.HooksDirectoryName $script:ZCodePathConstant.HooksJsonFileName
    )

    $cliResult = Remove-ZCodeToolkitJsonOverlay `
        -DestinationPath $destinationCliConfig `
        -SourcePath $sourceCliConfig `
        -InstallRoot $resolvedInstallRoot `
        -WhatIf:$WhatIf

    if ($null -eq $cliResult -or $cliResult.Success -ne $true) {
        $detail = if ($null -ne $cliResult) { [string]$cliResult.Message } else { 'cli/config.json reverse-merge failed' }
        return [PSCustomObject]@{
            Success       = $false
            Implemented   = $true
            CommandName   = 'Uninstall-Toolkit'
            WhatIf        = [bool]$WhatIf.IsPresent
            InstallRoot   = $resolvedInstallRoot
            RemovedCount  = 0
            RemovedPaths  = @()
            KeyedOnly     = $true
            WholesaleWipe = $false
            SddPreserved  = $true
            Message       = $detail
            ExitCode      = 1
        }
    }

    $hooksResult = Remove-ZCodeToolkitJsonOverlay `
        -DestinationPath $destinationHooksJson `
        -SourcePath $sourceHooksJson `
        -InstallRoot $resolvedInstallRoot `
        -WhatIf:$WhatIf

    if ($null -eq $hooksResult -or $hooksResult.Success -ne $true) {
        $detail = if ($null -ne $hooksResult) { [string]$hooksResult.Message } else { 'hooks/hooks.json reverse-merge failed' }
        return [PSCustomObject]@{
            Success       = $false
            Implemented   = $true
            CommandName   = 'Uninstall-Toolkit'
            WhatIf        = [bool]$WhatIf.IsPresent
            InstallRoot   = $resolvedInstallRoot
            RemovedCount  = 0
            RemovedPaths  = @()
            KeyedOnly     = $true
            WholesaleWipe = $false
            SddPreserved  = $true
            Message       = $detail
            ExitCode      = 1
        }
    }

    $skillsRoot = Join-Path $resolvedInstallRoot $script:ZCodePathConstant.SkillsDirectoryName
    foreach ($rawSkillId in (Get-ZCodeManagedSkillIds -RepoRoot $repoRoot)) {
        try {
            $skillId = Assert-ToolkitManagedSkillName -SkillName $rawSkillId
        }
        catch {
            continue
        }
        $skillPath = Join-Path $skillsRoot $skillId
        $hit = Remove-ZCodeManagedPathIfPresent -Path $skillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
        if ($hit) {
            $wouldRemovePaths.Add($skillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($skillPath) | Out-Null
            }
        }
    }

    $agentsPath = Join-Path $resolvedInstallRoot $script:ZCodePathConstant.AgentsFileName
    $routerRemoveResult = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:ZCodePathConstant.AgentsFileName `
        -CurrentFilePath $agentsPath `
        -ResolveExpectedPublishContent { Get-ZCodeRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome } `
        -WhatIf:$WhatIf
    if ($routerRemoveResult.Removed -or $routerRemoveResult.WouldRemove) {
        $wouldRemovePaths.Add($agentsPath) | Out-Null
        if ($routerRemoveResult.Removed) {
            $removedPaths.Add($agentsPath) | Out-Null
        }
    }
    elseif ($routerRemoveResult.Preserved -and -not [string]::IsNullOrWhiteSpace($routerRemoveResult.Message)) {
        $routerNotes.Add([string]$routerRemoveResult.Message) | Out-Null
    }

    $customAgentsRoot = Join-Path $resolvedInstallRoot $script:ZCodePathConstant.CustomAgentsDirectoryName
    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    foreach ($agentFileName in (Get-ToolkitManagedAgentFileNames -SourceAgentsRoot $sourceAgentsRoot)) {
        $agentFilePath = Join-Path $customAgentsRoot $agentFileName
        $hit = Remove-ZCodeManagedPathIfPresent -Path $agentFilePath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($hit) {
            $wouldRemovePaths.Add($agentFilePath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($agentFilePath) | Out-Null
            }
        }
    }

    $pathCount = if ($WhatIf.IsPresent) { $wouldRemovePaths.Count } else { $removedPaths.Count }
    $jsonTouched = [bool]($cliResult.Touched -or $hooksResult.Touched)
    $baseMessage = if ($pathCount -eq 0 -and -not $jsonTouched) {
        ($script:ZCodeUninstallMessage.NothingFound -f $resolvedInstallRoot)
    }
    elseif ($WhatIf.IsPresent) {
        ($script:ZCodeUninstallMessage.WhatIfOk -f $pathCount, $resolvedInstallRoot)
    }
    else {
        ($script:ZCodeUninstallMessage.RemovedOk -f $pathCount, $resolvedInstallRoot)
    }

    $messageParts = @($baseMessage, $cliResult.Message, $hooksResult.Message, $script:ZCodeUninstallMessage.SddPreservedNote)
    if ($routerNotes.Count -gt 0) {
        $messageParts += @($routerNotes.ToArray())
    }
    $message = ($messageParts -join '; ')

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Uninstall-Toolkit'
        WhatIf           = [bool]$WhatIf.IsPresent
        InstallRoot      = $resolvedInstallRoot
        RemovedCount     = $pathCount
        RemovedPaths     = $(if ($WhatIf.IsPresent) { @($wouldRemovePaths.ToArray()) } else { @($removedPaths.ToArray()) })
        CliConfigTouched = [bool]$cliResult.Touched
        HooksJsonTouched = [bool]$hooksResult.Touched
        KeyedOnly        = $true
        WholesaleWipe    = $false
        SddPreserved     = $true
        Message          = $message
        ExitCode         = 0
    }
}
