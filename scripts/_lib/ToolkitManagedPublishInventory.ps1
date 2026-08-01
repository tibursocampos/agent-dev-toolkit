#Requires -Version 5.1
<#
.SYNOPSIS
  Managed publish inventory for whole-file router targets under InstallRoot.

.DESCRIPTION
  Tracks SHA-256 hashes of toolkit-published whole-file router targets (e.g.
  AGENTS.md, CLAUDE.md) at InstallRoot/.toolkit-managed-publish.json so
  uninstall can remove only files whose on-disk content still matches the last
  sync. Declared publish surfaces live in adapters/registry.json publishSurface.

  Never deletes target files — callers remove files only after
  Test-ToolkitManagedPublishInventoryOwnsFile returns $true.
#>

if (-not (Get-Variable -Scope Script -Name ToolkitConstant -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'ToolkitConstants.ps1')
}

if (-not (Get-Command -Name Test-IsPathUnderOrEqual -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Resolve-InstallRoot.ps1')
}

if (-not (Get-Command -Name Test-ToolkitManagedRelativeHasParentSegment -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Copy-ToolkitManagedTree.ps1')
}

function Assert-ToolkitManagedPublishInstallRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $InstallRoot
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ToolkitMessage.InstallRootRequiredForPublishInventory
    }

    return (Get-NormalizedFullPath -Path $InstallRoot)
}

function Assert-ToolkitManagedPublishRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw ($script:ToolkitMessage.ManagedPublishRelativePathInvalid -f $RelativePath)
    }

    $trimmed = $RelativePath.Trim()
    $parentSegment = $script:ToolkitConstant.RelativeParentPathSegment
    $currentSegment = $script:ToolkitConstant.CurrentDirectoryPathSegment

    $isInvalid = [string]::Equals($trimmed, $parentSegment, [System.StringComparison]::Ordinal) -or
        [string]::Equals($trimmed, $currentSegment, [System.StringComparison]::Ordinal) -or
        [System.IO.Path]::IsPathRooted($trimmed) -or
        (Test-ToolkitManagedRelativeHasParentSegment -RelativePath $trimmed)

    if ($isInvalid) {
        throw ($script:ToolkitMessage.ManagedPublishRelativePathInvalid -f $RelativePath)
    }

    return ($trimmed -replace '\\', '/')
}

function Assert-ToolkitManagedPublishPathUnderInstallRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CandidatePath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $underOrEqual = Test-IsPathUnderOrEqual -ChildPath $CandidatePath -ParentPath $InstallRoot
    if (-not $underOrEqual) {
        throw ($script:ToolkitMessage.ManagedPublishInventoryPathEscapesInstallRoot -f $CandidatePath, $InstallRoot)
    }
}

function Get-ToolkitManagedPublishInventoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $installRootFull = Assert-ToolkitManagedPublishInstallRoot -InstallRoot $InstallRoot
    return (Join-Path $installRootFull $script:ToolkitConstant.ManagedPublishInventoryFileName)
}

function Get-ToolkitFileContentSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw $script:ToolkitMessage.FilePathRequiredForContentHash
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ($script:ToolkitMessage.FileNotFoundForContentHash -f $Path)
    }

    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop
    return [string]$hash.Hash
}

function Read-ToolkitManagedPublishInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $installRootFull = Assert-ToolkitManagedPublishInstallRoot -InstallRoot $InstallRoot
    $inventoryPath = Get-ToolkitManagedPublishInventoryPath -InstallRoot $installRootFull
    $entries = @{}

    if (-not (Test-Path -LiteralPath $inventoryPath)) {
        return $entries
    }

    try {
        $raw = [System.IO.File]::ReadAllText($inventoryPath)
        $parsed = $raw | ConvertFrom-Json
    }
    catch {
        throw ($script:ToolkitMessage.ManagedPublishInventoryInvalid -f $inventoryPath, $_.Exception.Message)
    }

    $filesProperty = $script:ToolkitConstant.ManagedPublishInventoryFilesProperty
    if ($null -eq $parsed -or $parsed.PSObject.Properties.Name -notcontains $filesProperty) {
        return $entries
    }

    $fileMap = $parsed.$filesProperty
    if ($null -eq $fileMap) {
        return $entries
    }

    $kindProperty = $script:ToolkitConstant.ManagedPublishInventoryKindProperty
    $sha256Property = $script:ToolkitConstant.ManagedPublishInventorySha256Property

    foreach ($prop in @($fileMap.PSObject.Properties)) {
        $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $prop.Name
        $candidatePath = Join-Path $installRootFull $relativePath
        Assert-ToolkitManagedPublishPathUnderInstallRoot -CandidatePath $candidatePath -InstallRoot $installRootFull

        $entry = $prop.Value
        if ($null -eq $entry) {
            throw ($script:ToolkitMessage.ManagedPublishInventoryInvalid -f $inventoryPath, ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingKind -f $relativePath))
        }

        $kind = [string]$entry.$kindProperty
        $sha256 = [string]$entry.$sha256Property
        if ([string]::IsNullOrWhiteSpace($kind)) {
            throw ($script:ToolkitMessage.ManagedPublishInventoryInvalid -f $inventoryPath, ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingKind -f $relativePath))
        }
        if ([string]::IsNullOrWhiteSpace($sha256)) {
            throw ($script:ToolkitMessage.ManagedPublishInventoryInvalid -f $inventoryPath, ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingSha256 -f $relativePath))
        }

        $entries[$relativePath] = [ordered]@{
            $kindProperty    = $kind
            $sha256Property  = $sha256.ToUpperInvariant()
        }
    }

    return $entries
}

function Write-ToolkitManagedPublishInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [hashtable] $Entries
    )

    $installRootFull = Assert-ToolkitManagedPublishInstallRoot -InstallRoot $InstallRoot
    $inventoryPath = Get-ToolkitManagedPublishInventoryPath -InstallRoot $installRootFull
    Assert-ToolkitManagedPublishPathUnderInstallRoot -CandidatePath $inventoryPath -InstallRoot $installRootFull

    if (-not (Test-Path -LiteralPath $installRootFull)) {
        New-Item -ItemType Directory -Path $installRootFull -Force | Out-Null
    }

    $kindProperty = $script:ToolkitConstant.ManagedPublishInventoryKindProperty
    $sha256Property = $script:ToolkitConstant.ManagedPublishInventorySha256Property
    $filesProperty = $script:ToolkitConstant.ManagedPublishInventoryFilesProperty
    $schemaProperty = $script:ToolkitConstant.ManagedPublishInventorySchemaProperty

    $filesPayload = [ordered]@{}
    foreach ($key in @($Entries.Keys | Sort-Object)) {
        $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $key
        $candidatePath = Join-Path $installRootFull $relativePath
        Assert-ToolkitManagedPublishPathUnderInstallRoot -CandidatePath $candidatePath -InstallRoot $installRootFull

        $entry = $Entries[$key]
        if ($null -eq $entry) {
            continue
        }

        $kind = [string]$entry[$kindProperty]
        if ([string]::IsNullOrWhiteSpace($kind)) {
            $kind = [string]$entry.$kindProperty
        }
        $sha256 = [string]$entry[$sha256Property]
        if ([string]::IsNullOrWhiteSpace($sha256)) {
            $sha256 = [string]$entry.$sha256Property
        }
        if ([string]::IsNullOrWhiteSpace($kind)) {
            throw ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingKind -f $relativePath)
        }
        if ([string]::IsNullOrWhiteSpace($sha256)) {
            throw ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingSha256 -f $relativePath)
        }

        $filesPayload[$relativePath] = [ordered]@{
            $kindProperty   = $kind
            $sha256Property = $sha256.ToUpperInvariant()
        }
    }

    $payload = [ordered]@{
        $schemaProperty = $script:ToolkitConstant.ManagedPublishInventorySchemaVersion
        $filesProperty  = $filesPayload
    }

    $json = $payload | ConvertTo-Json -Depth $script:ToolkitConstant.JsonConvertDepthShallow
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tempPath = $inventoryPath + $script:ToolkitConstant.ManagedPublishInventoryAtomicWriteTempSuffix
    $maxAttempts = [int]$script:ToolkitConstant.ManagedPublishInventoryAtomicWriteMaxAttempts
    $delayMs = [int]$script:ToolkitConstant.ManagedPublishInventoryAtomicWriteRetryDelayMs
    $lastError = $null

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            Assert-ToolkitManagedPublishPathUnderInstallRoot -CandidatePath $tempPath -InstallRoot $installRootFull
            [System.IO.File]::WriteAllText($tempPath, $json, $utf8NoBom)
            Move-Item -LiteralPath $tempPath -Destination $inventoryPath -Force
            return $inventoryPath
        }
        catch {
            $lastError = $_
            if (Test-Path -LiteralPath $tempPath) {
                if (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue) {
                    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $tempPath -InstallRoot $installRootFull
                }
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            }
            if ($attempt -lt $maxAttempts) {
                Start-Sleep -Milliseconds $delayMs
            }
        }
    }

    throw ($script:ToolkitMessage.ManagedPublishInventoryAtomicWriteFailed -f $inventoryPath, $maxAttempts, $lastError.Exception.Message)
}

function Set-ToolkitManagedPublishInventoryEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $true)]
        [string] $Sha256,

        [Parameter(Mandatory = $true)]
        [string] $Kind
    )

    $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $RelativePath
    if ([string]::IsNullOrWhiteSpace($Sha256)) {
        throw ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingSha256 -f $relativePath)
    }
    if ([string]::IsNullOrWhiteSpace($Kind)) {
        throw ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingKind -f $relativePath)
    }

    $entries = Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    $kindProperty = $script:ToolkitConstant.ManagedPublishInventoryKindProperty
    $sha256Property = $script:ToolkitConstant.ManagedPublishInventorySha256Property
    $entries[$relativePath] = [ordered]@{
        $kindProperty   = $Kind
        $sha256Property = $Sha256.ToUpperInvariant()
    }

    return (Write-ToolkitManagedPublishInventory -InstallRoot $InstallRoot -Entries $entries)
}

function Test-ToolkitManagedPublishInventoryOwnsFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $true)]
        [string] $CurrentFilePath,

        [Parameter()]
        [scriptblock] $ResolveExpectedPublishContent
    )

    $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $CurrentFilePath)) {
        return $false
    }

    $currentHash = Get-ToolkitFileContentSha256 -Path $CurrentFilePath
    $entries = Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    $sha256Property = $script:ToolkitConstant.ManagedPublishInventorySha256Property

    if ($entries.ContainsKey($relativePath)) {
        $recorded = [string]$entries[$relativePath][$sha256Property]
        if (-not [string]::IsNullOrWhiteSpace($recorded)) {
            return [string]::Equals($currentHash, $recorded, [System.StringComparison]::OrdinalIgnoreCase)
        }
    }

    if ($null -eq $ResolveExpectedPublishContent) {
        return $false
    }

    $expectedContent = & $ResolveExpectedPublishContent
    if ($null -eq $expectedContent) {
        $expectedContent = ''
    }

    $expectedHash = Get-ToolkitManagedContentSha256Hex -Content ([string]$expectedContent)
    return [string]::Equals($currentHash, $expectedHash, [System.StringComparison]::OrdinalIgnoreCase)
}

function Remove-ToolkitManagedPublishInventoryEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $RelativePath
    $entries = Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    if (-not $entries.ContainsKey($relativePath)) {
        return $null
    }

    $entries.Remove($relativePath) | Out-Null
    return (Write-ToolkitManagedPublishInventory -InstallRoot $InstallRoot -Entries $entries)
}

function Get-ToolkitManagedContentSha256Hex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Content
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return ([BitConverter]::ToString($hashBytes) -replace '-', '').ToUpperInvariant()
}

function Set-ToolkitManagedPublishInventoryEntryFromContent {
    <#
    .SYNOPSIS
      Record sha256 for a whole-file publish target from resolved publish bytes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $PublishedContent,

        [Parameter()]
        [string] $Kind
    )

    $kindValue = if ([string]::IsNullOrWhiteSpace($Kind)) {
        $script:ToolkitConstant.ManagedPublishInventoryKindRouter
    }
    else {
        $Kind
    }

    return Set-ToolkitManagedPublishInventoryEntry `
        -InstallRoot $InstallRoot `
        -RelativePath $RelativePath `
        -Sha256 (Get-ToolkitManagedContentSha256Hex -Content $PublishedContent) `
        -Kind $kindValue
}

function Remove-ToolkitManagedWholeFileRouterIfOwned {
    <#
    .SYNOPSIS
      Delete a whole-file router only when provenance confirms toolkit ownership.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $true)]
        [string] $CurrentFilePath,

        [Parameter(Mandatory = $true)]
        [scriptblock] $ResolveExpectedPublishContent,

        [Parameter()]
        [switch] $WhatIf
    )

    $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $RelativePath

    if (-not (Test-Path -LiteralPath $CurrentFilePath)) {
        return [PSCustomObject]@{
            Removed           = $false
            WouldRemove       = $false
            Preserved         = $false
            RelativePath      = $relativePath
            CurrentFilePath   = $CurrentFilePath
            Message           = $null
        }
    }

    $ownsFile = Test-ToolkitManagedPublishInventoryOwnsFile `
        -InstallRoot $InstallRoot `
        -RelativePath $relativePath `
        -CurrentFilePath $CurrentFilePath `
        -ResolveExpectedPublishContent $ResolveExpectedPublishContent

    if (-not $ownsFile) {
        return [PSCustomObject]@{
            Removed           = $false
            WouldRemove       = $false
            Preserved         = $true
            RelativePath      = $relativePath
            CurrentFilePath   = $CurrentFilePath
            Message           = ($script:ToolkitConstant.RouterFilePreservedNoteFormat -f $relativePath)
        }
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Removed           = $false
            WouldRemove       = $true
            Preserved         = $false
            RelativePath      = $relativePath
            CurrentFilePath   = $CurrentFilePath
            Message           = $null
        }
    }

    if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
        . (Join-Path $PSScriptRoot 'Resolve-InstallRoot.ps1')
    }

    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $CurrentFilePath -InstallRoot $InstallRoot
    Remove-Item -LiteralPath $CurrentFilePath -Force
    $null = Remove-ToolkitManagedPublishInventoryEntry -InstallRoot $InstallRoot -RelativePath $relativePath

    return [PSCustomObject]@{
        Removed           = $true
        WouldRemove       = $false
        Preserved         = $false
        RelativePath      = $relativePath
        CurrentFilePath   = $CurrentFilePath
        Message           = $null
    }
}
