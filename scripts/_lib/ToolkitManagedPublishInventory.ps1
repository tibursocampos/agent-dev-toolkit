#Requires -Version 5.1
<#
.SYNOPSIS
  Managed publish inventory for whole-file router targets under InstallRoot.

.DESCRIPTION
  Tracks SHA-256 hashes of toolkit-published files at
  InstallRoot/.toolkit-managed-publish.json. A listed catalog path is removed
  on uninstall even when the installed bytes were edited. AGENTS.md, CLAUDE.md,
  and the same marked-block pattern lose only the toolkit section; operator
  text outside the markers stays. Declared publish surfaces live in
  adapters/registry.json publishSurface.

  Catalog republish does not keep a differing catalog file when that ownership
  check fails. Get-ToolkitCatalogRepublishContent returns the incoming catalog
  bytes. When the destination already has one well-formed managed marker pair,
  only that toolkit section is refreshed.
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

function Set-ToolkitManagedPublishInventoryEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][hashtable] $Updates,
        [Parameter()][hashtable] $InventoryEntries
    )

    if ($null -eq $InventoryEntries) {
        $InventoryEntries = Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    }

    $kindProperty = $script:ToolkitConstant.ManagedPublishInventoryKindProperty
    $sha256Property = $script:ToolkitConstant.ManagedPublishInventorySha256Property
    foreach ($key in $Updates.Keys) {
        $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath ([string]$key)
        $entry = $Updates[$key]
        $kind = [string]$entry[$kindProperty]
        $sha256 = [string]$entry[$sha256Property]
        if ([string]::IsNullOrWhiteSpace($kind)) {
            throw ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingKind -f $relativePath)
        }
        if ([string]::IsNullOrWhiteSpace($sha256)) {
            throw ($script:ToolkitMessage.ManagedPublishInventoryEntryMissingSha256 -f $relativePath)
        }

        $candidatePath = Join-Path (Assert-ToolkitManagedPublishInstallRoot -InstallRoot $InstallRoot) $relativePath
        Assert-ToolkitManagedPublishPathUnderInstallRoot -CandidatePath $candidatePath -InstallRoot $InstallRoot
        $InventoryEntries[$relativePath] = [ordered]@{
            $kindProperty   = $kind
            $sha256Property = $sha256.ToUpperInvariant()
        }
    }

    return (Write-ToolkitManagedPublishInventory -InstallRoot $InstallRoot -Entries $InventoryEntries)
}

function Get-ToolkitAdapterContentCompareProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AdapterId
    )

    $profiles = $script:ToolkitConstant.ContentHashAdapterCompareProfiles
    if ($null -eq $profiles -or -not $profiles.ContainsKey($AdapterId)) {
        return $null
    }

    return $profiles[$AdapterId]
}

function New-ToolkitContentHashClassificationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Outcome,

        [Parameter(Mandatory = $true)]
        [bool] $IsClosedDefect,

        [Parameter()]
        [AllowEmptyString()]
        [string] $NativeTransform,

        [Parameter(Mandatory = $true)]
        [bool] $SourceRevisionKnown,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Message
    )

    return [PSCustomObject]@{
        Outcome              = $Outcome
        IsClosedDefect       = $IsClosedDefect
        NativeTransform      = $NativeTransform
        SourceRevisionKnown  = $SourceRevisionKnown
        Message              = $Message
    }
}

function Resolve-ToolkitContentHashCompareFacts {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string] $AdapterId,

        [Parameter()]
        [AllowEmptyString()]
        [string] $SourceRevision,

        [Parameter()]
        [AllowEmptyString()]
        [string] $NativeTransform,

        [Parameter()]
        [bool] $NativeTransformExpectsSameBytes,

        [Parameter()]
        [bool] $NativeTransformExpectsSameBytesSpecified
    )

    $transform = $NativeTransform
    $expectsSameBytes = $NativeTransformExpectsSameBytes
    if (-not [string]::IsNullOrWhiteSpace($AdapterId)) {
        $profile = Get-ToolkitAdapterContentCompareProfile -AdapterId $AdapterId
        if ($null -ne $profile) {
            $transformProperty = $script:ToolkitConstant.ContentHashProfileNativeTransformProperty
            $expectsProperty = $script:ToolkitConstant.ContentHashProfileExpectsSameBytesProperty
            if ([string]::IsNullOrWhiteSpace($transform)) {
                $transform = [string]$profile[$transformProperty]
            }
            if (-not $NativeTransformExpectsSameBytesSpecified) {
                $expectsSameBytes = [bool]$profile[$expectsProperty]
            }
        }
    }

    $identityTransform = $script:ToolkitConstant.ContentHashNativeTransformNone
    if ([string]::Equals($transform, $identityTransform, [System.StringComparison]::Ordinal)) {
        $expectsSameBytes = $true
    }

    return [PSCustomObject]@{
        SourceRevision     = $SourceRevision
        NativeTransform    = $transform
        ExpectsSameBytes   = $expectsSameBytes
    }
}

function Get-ToolkitContentHashDifferenceClassification {
    <#
    .SYNOPSIS
      Classify an installed-versus-source hash difference.
    .DESCRIPTION
      A difference is a closed defect only when the source revision and the native
      transform are both known and those two should produce the same bytes.
      A known native delta is documented. A missing revision or transform stays pending.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $InstalledContentHash,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $SourceContentHash,

        [Parameter()]
        [AllowEmptyString()]
        [string] $SourceRevision,

        [Parameter()]
        [AllowEmptyString()]
        [string] $NativeTransform,

        [Parameter()]
        [bool] $NativeTransformExpectsSameBytes,

        [Parameter()]
        [bool] $NativeTransformExpectsSameBytesSpecified,

        [Parameter()]
        [AllowEmptyString()]
        [string] $AdapterId
    )

    $facts = Resolve-ToolkitContentHashCompareFacts `
        -AdapterId $AdapterId `
        -SourceRevision $SourceRevision `
        -NativeTransform $NativeTransform `
        -NativeTransformExpectsSameBytes $NativeTransformExpectsSameBytes `
        -NativeTransformExpectsSameBytesSpecified $NativeTransformExpectsSameBytesSpecified

    $revisionKnown = -not [string]::IsNullOrWhiteSpace($facts.SourceRevision)
    $transformKnown = -not [string]::IsNullOrWhiteSpace($facts.NativeTransform)
    $transformLabel = $facts.NativeTransform
    if ([string]::IsNullOrWhiteSpace($transformLabel)) {
        $transformLabel = $script:ToolkitConstant.ContentHashNativeTransformUnrecorded
    }

    $hashesComparable = -not [string]::IsNullOrWhiteSpace($InstalledContentHash) -and
        -not [string]::IsNullOrWhiteSpace($SourceContentHash)
    $hashesEqual = $hashesComparable -and
        [string]::Equals($InstalledContentHash, $SourceContentHash, [System.StringComparison]::OrdinalIgnoreCase)

    if ($hashesEqual) {
        return (New-ToolkitContentHashClassificationResult `
            -Outcome $script:ToolkitConstant.ContentHashClassificationMatch `
            -IsClosedDefect $false `
            -NativeTransform $facts.NativeTransform `
            -SourceRevisionKnown $revisionKnown `
            -Message $script:ToolkitMessage.ContentHashDifferenceMatch)
    }

    if (-not $hashesComparable -or -not $revisionKnown -or -not $transformKnown) {
        return (New-ToolkitContentHashClassificationResult `
            -Outcome $script:ToolkitConstant.ContentHashClassificationPendingRevision `
            -IsClosedDefect $false `
            -NativeTransform $facts.NativeTransform `
            -SourceRevisionKnown $revisionKnown `
            -Message ($script:ToolkitMessage.ContentHashDifferencePendingRevision -f $transformLabel))
    }

    if (-not $facts.ExpectsSameBytes) {
        return (New-ToolkitContentHashClassificationResult `
            -Outcome $script:ToolkitConstant.ContentHashClassificationNativeDelta `
            -IsClosedDefect $false `
            -NativeTransform $facts.NativeTransform `
            -SourceRevisionKnown $revisionKnown `
            -Message ($script:ToolkitMessage.ContentHashDifferenceNativeDelta -f $transformLabel))
    }

    return (New-ToolkitContentHashClassificationResult `
        -Outcome $script:ToolkitConstant.ContentHashClassificationClosedDefect `
        -IsClosedDefect $true `
        -NativeTransform $facts.NativeTransform `
        -SourceRevisionKnown $revisionKnown `
        -Message ($script:ToolkitMessage.ContentHashDifferenceClosedDefect -f $facts.SourceRevision, $transformLabel))
}

function Set-ToolkitLastContentHashDifferenceClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $InstalledContentHash,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $SourceContentHash,

        [Parameter()]
        [AllowEmptyString()]
        [string] $SourceRevision,

        [Parameter()]
        [AllowEmptyString()]
        [string] $NativeTransform,

        [Parameter()]
        [bool] $NativeTransformExpectsSameBytes,

        [Parameter()]
        [bool] $NativeTransformExpectsSameBytesSpecified,

        [Parameter()]
        [AllowEmptyString()]
        [string] $AdapterId
    )

    $script:ToolkitLastContentHashDifferenceClassification = Get-ToolkitContentHashDifferenceClassification `
        -InstalledContentHash $InstalledContentHash `
        -SourceContentHash $SourceContentHash `
        -SourceRevision $SourceRevision `
        -NativeTransform $NativeTransform `
        -NativeTransformExpectsSameBytes $NativeTransformExpectsSameBytes `
        -NativeTransformExpectsSameBytesSpecified $NativeTransformExpectsSameBytesSpecified `
        -AdapterId $AdapterId
    return $script:ToolkitLastContentHashDifferenceClassification
}

function Get-ToolkitCatalogRepublishContent {
    <#
    .SYNOPSIS
      Catalog bytes to write on republish. A failed ownership check does not keep the old catalog file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $ExistingContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $IncomingContent
    )

    $markerPairs = @(
        @($script:ToolkitConstant.ManagedBlockBeginMarker, $script:ToolkitConstant.ManagedBlockEndMarker),
        @($script:ToolkitConstant.HermesManagedAgentsBeginMarker, $script:ToolkitConstant.HermesManagedAgentsEndMarker)
    )

    foreach ($pair in $markerPairs) {
        $begin = [string]$pair[0]
        $end = [string]$pair[1]
        $beginMatches = [regex]::Matches($ExistingContent, [regex]::Escape($begin))
        $endMatches = [regex]::Matches($ExistingContent, [regex]::Escape($end))
        if ($beginMatches.Count -ne 1 -or $endMatches.Count -ne 1) {
            continue
        }

        if ($endMatches[0].Index -lt $beginMatches[0].Index) {
            continue
        }

        $pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
        $existingMatch = [regex]::Match($ExistingContent, $pattern)
        if (-not $existingMatch.Success) {
            continue
        }

        $incomingMatch = [regex]::Match($IncomingContent, $pattern)
        $replacementBlock = if ($incomingMatch.Success) {
            $incomingMatch.Value
        }
        else {
            $begin + [Environment]::NewLine + $IncomingContent.TrimEnd() + [Environment]::NewLine + $end
        }

        $prefix = $ExistingContent.Substring(0, $existingMatch.Index)
        $suffix = $ExistingContent.Substring($existingMatch.Index + $existingMatch.Length)
        return ($prefix + $replacementBlock + $suffix)
    }

    return $IncomingContent
}

function Test-ToolkitManagedPublishInventoryListsFile {
    <#
    .SYNOPSIS
      True when the publish inventory lists this relative path as a catalog file.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter()]
        [hashtable] $InventoryEntries
    )

    $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $RelativePath
    $entries = if ($null -eq $InventoryEntries) {
        Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    }
    else {
        $InventoryEntries
    }

    return $entries.ContainsKey($relativePath)
}

function Get-ToolkitManagedMarkedRouterRemainder {
    <#
    .SYNOPSIS
      Operator text left after removing one toolkit marked section.
    .DESCRIPTION
      Returns $null when the file has no single well-formed marker pair.
      Remaining may be empty when the file was only the toolkit section.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Content
    )

    $markerPairs = @(
        @($script:ToolkitConstant.ManagedBlockBeginMarker, $script:ToolkitConstant.ManagedBlockEndMarker),
        @($script:ToolkitConstant.HermesManagedAgentsBeginMarker, $script:ToolkitConstant.HermesManagedAgentsEndMarker)
    )

    foreach ($pair in $markerPairs) {
        $begin = [string]$pair[0]
        $end = [string]$pair[1]
        $beginMatches = [regex]::Matches($Content, [regex]::Escape($begin))
        $endMatches = [regex]::Matches($Content, [regex]::Escape($end))
        if ($beginMatches.Count -ne 1 -or $endMatches.Count -ne 1) {
            continue
        }

        if ($endMatches[0].Index -lt $beginMatches[0].Index) {
            continue
        }

        $pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end) + '\r?\n?'
        $existingMatch = [regex]::Match($Content, $pattern)
        if (-not $existingMatch.Success) {
            continue
        }

        return $Content.Remove($existingMatch.Index, $existingMatch.Length)
    }

    return $null
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
        [scriptblock] $ResolveExpectedPublishContent,

        [Parameter()]
        [hashtable] $InventoryEntries,

        [Parameter()]
        [AllowEmptyString()]
        [string] $SourceRevision,

        [Parameter()]
        [AllowEmptyString()]
        [string] $NativeTransform,

        [Parameter()]
        [bool] $NativeTransformExpectsSameBytes,

        [Parameter()]
        [AllowEmptyString()]
        [string] $AdapterId
    )

    $expectsSameBytesSpecified = $PSBoundParameters.ContainsKey('NativeTransformExpectsSameBytes')
    $script:ToolkitLastContentHashDifferenceClassification = $null
    $relativePath = Assert-ToolkitManagedPublishRelativePath -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $CurrentFilePath)) {
        return $false
    }

    $currentHash = Get-ToolkitFileContentSha256 -Path $CurrentFilePath
    $entries = if ($null -eq $InventoryEntries) {
        Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    } else {
        $InventoryEntries
    }
    $sha256Property = $script:ToolkitConstant.ManagedPublishInventorySha256Property

    if ($entries.ContainsKey($relativePath)) {
        $recorded = [string]$entries[$relativePath][$sha256Property]
        if (-not [string]::IsNullOrWhiteSpace($recorded)) {
            $matchesRecorded = [string]::Equals($currentHash, $recorded, [System.StringComparison]::OrdinalIgnoreCase)
            if (-not $matchesRecorded) {
                $null = Set-ToolkitLastContentHashDifferenceClassification `
                    -InstalledContentHash $currentHash `
                    -SourceContentHash '' `
                    -SourceRevision $SourceRevision `
                    -NativeTransform $NativeTransform `
                    -NativeTransformExpectsSameBytes $NativeTransformExpectsSameBytes `
                    -NativeTransformExpectsSameBytesSpecified $expectsSameBytesSpecified `
                    -AdapterId $AdapterId
            }
            return $matchesRecorded
        }
    }

    if ($null -eq $ResolveExpectedPublishContent) {
        $null = Set-ToolkitLastContentHashDifferenceClassification `
            -InstalledContentHash $currentHash `
            -SourceContentHash '' `
            -SourceRevision $SourceRevision `
            -NativeTransform $NativeTransform `
            -NativeTransformExpectsSameBytes $NativeTransformExpectsSameBytes `
            -NativeTransformExpectsSameBytesSpecified $expectsSameBytesSpecified `
            -AdapterId $AdapterId
        return $false
    }

    $expectedContent = & $ResolveExpectedPublishContent
    if ($null -eq $expectedContent) {
        $expectedContent = ''
    }

    $expectedHash = Get-ToolkitManagedContentSha256Hex -Content ([string]$expectedContent)
    $matchesExpected = [string]::Equals($currentHash, $expectedHash, [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $matchesExpected) {
        $null = Set-ToolkitLastContentHashDifferenceClassification `
            -InstalledContentHash $currentHash `
            -SourceContentHash $expectedHash `
            -SourceRevision $SourceRevision `
            -NativeTransform $NativeTransform `
            -NativeTransformExpectsSameBytes $NativeTransformExpectsSameBytes `
            -NativeTransformExpectsSameBytesSpecified $expectsSameBytesSpecified `
            -AdapterId $AdapterId
    }
    return $matchesExpected
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
      Remove a catalog router file, or only its toolkit marked section.
    .DESCRIPTION
      A single well-formed marker pair loses only the toolkit section. Operator
      text outside the markers stays. A catalog-only file, including an edited
      copy listed in the publish inventory, is removed as a whole file. A path
      outside InstallRoot or equal to InstallRoot is not deleted.
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

    $existingContent = [System.IO.File]::ReadAllText($CurrentFilePath)
    $markedRemainder = Get-ToolkitManagedMarkedRouterRemainder -Content $existingContent
    $catalogOnlyFile = $false
    if ($null -ne $markedRemainder) {
        $catalogOnlyFile = [string]::IsNullOrWhiteSpace($markedRemainder)
    }
    else {
        $listed = Test-ToolkitManagedPublishInventoryListsFile `
            -InstallRoot $InstallRoot `
            -RelativePath $relativePath
        if (-not $listed) {
            return [PSCustomObject]@{
                Removed           = $false
                WouldRemove       = $false
                Preserved         = $true
                RelativePath      = $relativePath
                CurrentFilePath   = $CurrentFilePath
                Message           = ($script:ToolkitConstant.RouterFilePreservedNoteFormat -f $relativePath)
            }
        }

        $catalogOnlyFile = $true
    }

    if (-not $catalogOnlyFile) {
        if ($WhatIf.IsPresent) {
            return [PSCustomObject]@{
                Removed           = $false
                WouldRemove       = $false
                Preserved         = $true
                RelativePath      = $relativePath
                CurrentFilePath   = $CurrentFilePath
                Message           = $null
            }
        }

        if (-not (Get-Command -Name Assert-ToolkitManagedDestinationUnderInstallRoot -ErrorAction SilentlyContinue)) {
            . (Join-Path $PSScriptRoot 'Copy-ToolkitManagedTree.ps1')
        }

        Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $CurrentFilePath -InstallRoot $InstallRoot
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($CurrentFilePath, $markedRemainder, $utf8NoBom)
        $null = Remove-ToolkitManagedPublishInventoryEntry -InstallRoot $InstallRoot -RelativePath $relativePath
        return [PSCustomObject]@{
            Removed           = $false
            WouldRemove       = $false
            Preserved         = $true
            RelativePath      = $relativePath
            CurrentFilePath   = $CurrentFilePath
            Message           = $null
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
