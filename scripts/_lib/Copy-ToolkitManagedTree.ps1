#Requires -Version 5.1
<#
.SYNOPSIS
  Shared copy + placeholder resolve/assert + managed-skills prune for adapter publish.

.DESCRIPTION
  Copy-ToolkitManagedTree mirrors a source tree into a destination.
  Resolve-ToolkitPlaceholdersInTree replaces placeholders and asserts none remain
  in a single read/write pass per text file.
  Sync-ToolkitManagedSkillFolders prunes dest skill dirs that were toolkit-managed
  on a previous publish (via .toolkit-managed-skills.json) but are absent from the
  current source skill set — alien user folders never listed in the manifest are kept.

  Empty / missing previous manifest (RN07 alien-safe bootstrap): when
  .toolkit-managed-skills.json is absent, unreadable-as-empty, or lists no skills,
  Sync-ToolkitManagedSkillFolders performs NO prune. It does not delete unknown
  kebab-case skill directories under DestinationSkillsRoot. Only names recorded
  on a prior successful publish are eligible for removal when absent from the
  current source set; then the manifest is rewritten to the current skill names.

  Path safety: managed skill names are sanitized (no empty/rooted/separators/parent
  segments); prune destinations must stay under DestinationSkillsRoot; copy helpers
  assert source/dest containment and reject relative parent segments.

  Optional -InstallRoot (post Confirm/Initialize): re-asserts DestinationRoot /
  DestinationSkillsRoot is a strict child of InstallRoot before copy/prune, and
  gates Sync Remove-Item with Assert-PathUnderInstallRootForDelete (child TOCTOU).
#>

if (-not (Get-Variable -Scope Script -Name ToolkitConstant -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'ToolkitConstants.ps1')
}

if (-not (Get-Command -Name Test-IsPathUnderOrEqual -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Resolve-InstallRoot.ps1')
}

# These values are shared by the copy/publish helpers below. Initialize them
# when this file is dot-sourced so callers using StrictMode can safely inspect
# them before the first copy operation.
if (-not (Get-Variable -Scope Script -Name ToolkitLastManagedCopyPaths -ErrorAction SilentlyContinue)) {
    $script:ToolkitLastManagedCopyPaths = New-Object System.Collections.Generic.List[string]
}
if (-not (Get-Variable -Scope Script -Name ToolkitLastManagedCopyConflicts -ErrorAction SilentlyContinue)) {
    $script:ToolkitLastManagedCopyConflicts = New-Object System.Collections.Generic.List[string]
}
if (-not (Get-Variable -Scope Script -Name ToolkitLastPreservedStaleSkillNames -ErrorAction SilentlyContinue)) {
    $script:ToolkitLastPreservedStaleSkillNames = @()
}

function Test-ToolkitManagedRelativeHasParentSegment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    $parentSegment = $script:ToolkitConstant.RelativeParentPathSegment
    $parts = $RelativePath -split '[\\/]'
    foreach ($part in $parts) {
        if ([string]::Equals($part, $parentSegment, [System.StringComparison]::Ordinal)) {
            return $true
        }
    }

    return $false
}

function Assert-ToolkitManagedSkillName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $SkillName
    )

    $trimmed = if ($null -eq $SkillName) { '' } else { $SkillName.Trim() }
    $parentSegment = $script:ToolkitConstant.RelativeParentPathSegment
    $currentSegment = $script:ToolkitConstant.CurrentDirectoryPathSegment

    $isInvalid = [string]::IsNullOrWhiteSpace($trimmed) -or
        [string]::Equals($trimmed, $parentSegment, [System.StringComparison]::Ordinal) -or
        [string]::Equals($trimmed, $currentSegment, [System.StringComparison]::Ordinal) -or
        $trimmed.Contains('\') -or
        $trimmed.Contains('/') -or
        $trimmed.Contains($parentSegment) -or
        [System.IO.Path]::IsPathRooted($trimmed)

    if ($isInvalid) {
        throw ($script:ToolkitMessage.ManagedSkillNameInvalid -f $SkillName)
    }

    return $trimmed
}

function Assert-ToolkitManagedPathContained {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CandidatePath,

        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [string] $EscapeMessageFormat,

        [Parameter()]
        [switch] $RequireStrictChild
    )

    $underOrEqual = Test-IsPathUnderOrEqual -ChildPath $CandidatePath -ParentPath $RootPath
    if (-not $underOrEqual) {
        throw ($EscapeMessageFormat -f $CandidatePath, $RootPath)
    }

    if ($RequireStrictChild.IsPresent) {
        $candidateFull = Get-NormalizedFullPath -Path $CandidatePath
        $rootFull = Get-NormalizedFullPath -Path $RootPath
        if ([string]::Equals($candidateFull, $rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw ($EscapeMessageFormat -f $CandidatePath, $RootPath)
        }
    }
}

function Assert-ToolkitManagedSkillDestinationPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillName,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    $safeName = Assert-ToolkitManagedSkillName -SkillName $SkillName
    $candidatePath = Join-Path $DestinationSkillsRoot $safeName

    $underOrEqual = Test-IsPathUnderOrEqual -ChildPath $candidatePath -ParentPath $DestinationSkillsRoot
    $candidateFull = Get-NormalizedFullPath -Path $candidatePath
    $rootFull = Get-NormalizedFullPath -Path $DestinationSkillsRoot
    $isStrictChild = $underOrEqual -and -not [string]::Equals($candidateFull, $rootFull, [System.StringComparison]::OrdinalIgnoreCase)

    if (-not $isStrictChild) {
        throw ($script:ToolkitMessage.ManagedSkillPathEscapesDestination -f $SkillName, $candidatePath, $DestinationSkillsRoot)
    }

    return [PSCustomObject]@{
        SkillName = $safeName
        Path      = $candidatePath
    }
}

function Copy-ToolkitFileIfAbsent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $SourcePath,
        [Parameter(Mandatory = $true)][string] $DestinationPath,
        [Parameter()][string] $InstallRoot,
        [Parameter()][string] $RelativePath
    )

    if ($null -eq $script:ToolkitLastManagedCopyPaths) {
        $script:ToolkitLastManagedCopyPaths = New-Object System.Collections.Generic.List[string]
    }
    $destinationFull = [System.IO.Path]::GetFullPath($DestinationPath)
    if (Test-Path -LiteralPath $DestinationPath) {
        if (-not [string]::IsNullOrWhiteSpace($InstallRoot) -and -not [string]::IsNullOrWhiteSpace($RelativePath)) {
            . (Join-Path $PSScriptRoot 'ToolkitManagedPublishInventory.ps1')
            if (Test-ToolkitManagedPublishInventoryOwnsFile -InstallRoot $InstallRoot -RelativePath $RelativePath -CurrentFilePath $DestinationPath) {
                Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
                $sha = Get-ToolkitFileContentSha256 -Path $DestinationPath
                $null = Set-ToolkitManagedPublishInventoryEntry -InstallRoot $InstallRoot -RelativePath $RelativePath -Sha256 $sha -Kind 'managed-file'
                $script:ToolkitLastManagedCopyPaths.Add($destinationFull) | Out-Null
                return $true
            }
        }
        for ($index = $script:ToolkitLastManagedCopyPaths.Count - 1; $index -ge 0; $index--) {
            if ([string]::Equals($script:ToolkitLastManagedCopyPaths[$index], $destinationFull, [StringComparison]::OrdinalIgnoreCase)) {
                $script:ToolkitLastManagedCopyPaths.RemoveAt($index)
            }
        }
        Write-Warning ("Preserved existing destination file because ownership is not proven: {0}" -f $DestinationPath)
        return $false
    }

    $parent = Split-Path -Parent $DestinationPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -ErrorAction Stop
    $script:ToolkitLastManagedCopyPaths.Add($destinationFull) | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot) -and -not [string]::IsNullOrWhiteSpace($RelativePath)) {
        . (Join-Path $PSScriptRoot 'ToolkitManagedPublishInventory.ps1')
        $sha = Get-ToolkitFileContentSha256 -Path $DestinationPath
        $null = Set-ToolkitManagedPublishInventoryEntry -InstallRoot $InstallRoot -RelativePath $RelativePath -Sha256 $sha -Kind 'managed-file'
    }
    return $true
}

function Write-ToolkitFileIfAbsent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Content,
        [Parameter()][System.Text.Encoding] $Encoding = (New-Object System.Text.UTF8Encoding $false),
        [Parameter()][string] $InstallRoot,
        [Parameter()][string] $RelativePath,
        [Parameter()][switch] $AllowExistingMerge
    )

    if (Test-Path -LiteralPath $Path) {
        if ($AllowExistingMerge.IsPresent) {
            [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
            return $true
        }
        $owned = $false
        if (-not [string]::IsNullOrWhiteSpace($InstallRoot) -and -not [string]::IsNullOrWhiteSpace($RelativePath)) {
            . (Join-Path $PSScriptRoot 'ToolkitManagedPublishInventory.ps1')
            $owned = Test-ToolkitManagedPublishInventoryOwnsFile -InstallRoot $InstallRoot -RelativePath $RelativePath -CurrentFilePath $Path
        }
        if (-not $owned) {
            Write-Warning ("Preserved existing destination file because ownership is not proven: {0}" -f $Path)
            return $false
        }
    }

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
    $destinationFull = [System.IO.Path]::GetFullPath($Path)
    if ($null -eq $script:ToolkitLastManagedCopyPaths) {
        $script:ToolkitLastManagedCopyPaths = New-Object System.Collections.Generic.List[string]
    }
    $script:ToolkitLastManagedCopyPaths.Add($destinationFull) | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot) -and -not [string]::IsNullOrWhiteSpace($RelativePath)) {
        . (Join-Path $PSScriptRoot 'ToolkitManagedPublishInventory.ps1')
        $sha = Get-ToolkitFileContentSha256 -Path $Path
        $null = Set-ToolkitManagedPublishInventoryEntry -InstallRoot $InstallRoot -RelativePath $RelativePath -Sha256 $sha -Kind 'managed-file'
    }
    return $true
}

function Assert-ToolkitManagedDestinationUnderInstallRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DestinationPath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    Assert-ToolkitManagedPathContained `
        -CandidatePath $DestinationPath `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
}

function Update-ToolkitManagedCopyInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter()][string[]] $Paths,
        [Parameter()][hashtable] $InventoryEntries
    )

    . (Join-Path $PSScriptRoot 'ToolkitManagedPublishInventory.ps1')
    $inventoryRoot = (Get-NormalizedFullPath -Path $InstallRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $pathsToRecord = if ($null -eq $Paths) { $script:ToolkitLastManagedCopyPaths } else { $Paths }
    $updates = @{}
    foreach ($managedPath in $pathsToRecord) {
        if (-not (Test-Path -LiteralPath $managedPath -PathType Leaf)) { continue }
        $relativeInventoryPath = $managedPath.Substring($inventoryRoot.Length)
        $entry = @{}
        $entry[$script:ToolkitConstant.ManagedPublishInventoryKindProperty] = 'tree-file'
        $entry[$script:ToolkitConstant.ManagedPublishInventorySha256Property] = Get-ToolkitFileContentSha256 -Path $managedPath
        $updates[$relativeInventoryPath] = $entry
    }
    if ($updates.Count -gt 0) {
        $null = Set-ToolkitManagedPublishInventoryEntries -InstallRoot $InstallRoot -Updates $updates -InventoryEntries $InventoryEntries
    }
}

function Copy-ToolkitManagedTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationRoot,

        [Parameter()]
        [string] $InstallRoot
    )

    if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
        throw $script:ToolkitMessage.SourceSkillsRootRequired
    }

    if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
        throw $script:ToolkitMessage.DestinationSkillsRootRequired
    }

    $sourceRootFull = Get-NormalizedFullPath -Path $SourceRoot
    $destinationRootFull = Get-NormalizedFullPath -Path $DestinationRoot
    $hasInstallRoot = -not [string]::IsNullOrWhiteSpace($InstallRoot)
    if ($hasInstallRoot) {
        . (Join-Path $PSScriptRoot 'ToolkitManagedPublishInventory.ps1')
        Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destinationRootFull -InstallRoot $InstallRoot
    }

    if (-not (Test-Path -LiteralPath $destinationRootFull)) {
        New-Item -ItemType Directory -Path $destinationRootFull -Force | Out-Null
    }

    # Re-assert after create / when dest already existed as a reparse child.
    $destinationRootFull = Get-NormalizedFullPath -Path $destinationRootFull
    if ($hasInstallRoot) {
        Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destinationRootFull -InstallRoot $InstallRoot
    }

    $filesCopied = 0
    $script:ToolkitLastManagedCopyPaths = New-Object System.Collections.Generic.List[string]
    $script:ToolkitLastManagedCopyConflicts = New-Object System.Collections.Generic.List[string]
    $sourceFiles = Get-ChildItem -LiteralPath $sourceRootFull -Recurse -File -ErrorAction Stop
    $inventoryEntries = if ($hasInstallRoot) {
        Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    } else {
        $null
    }
    foreach ($file in $sourceFiles) {
        Assert-ToolkitManagedPathContained `
            -CandidatePath $file.FullName `
            -RootPath $sourceRootFull `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot

        $relative = $file.FullName.Substring($sourceRootFull.Length).TrimStart('\', '/')
        if (Test-ToolkitManagedRelativeHasParentSegment -RelativePath $relative) {
            throw ($script:ToolkitMessage.ManagedCopyRelativePathInvalid -f $relative)
        }

        $destinationPath = Join-Path $destinationRootFull $relative
        Assert-ToolkitManagedPathContained `
            -CandidatePath $destinationPath `
            -RootPath $destinationRootFull `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot
        if ($hasInstallRoot) {
            Assert-ToolkitManagedPathContained `
                -CandidatePath $destinationPath `
                -RootPath $InstallRoot `
                -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
                -RequireStrictChild
        }

        if (Test-Path -LiteralPath $destinationPath) {
            $owned = $false
            if ($hasInstallRoot) {
                $inventoryRoot = (Get-NormalizedFullPath -Path $InstallRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
                $relativeInventoryPath = $destinationPath.Substring($inventoryRoot.Length)
                $owned = Test-ToolkitManagedPublishInventoryOwnsFile -InstallRoot $InstallRoot -RelativePath $relativeInventoryPath -CurrentFilePath $destinationPath -InventoryEntries $inventoryEntries
            }
            if (-not $owned) {
                $script:ToolkitLastManagedCopyConflicts.Add($destinationPath) | Out-Null
                continue
            }
        }

        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath
        $script:ToolkitLastManagedCopyPaths.Add([System.IO.Path]::GetFullPath($destinationPath)) | Out-Null
        $filesCopied++
    }

    if ($script:ToolkitLastManagedCopyConflicts.Count -gt 0) {
        Write-Warning ('Preserved {0} existing managed-tree file(s) because file ownership is not recorded: {1}' -f `
            $script:ToolkitLastManagedCopyConflicts.Count, ($script:ToolkitLastManagedCopyConflicts.ToArray() -join ', '))
    }

    if ($hasInstallRoot) { Update-ToolkitManagedCopyInventory -InstallRoot $InstallRoot -InventoryEntries $inventoryEntries }

    return $filesCopied
}

function Get-ToolkitSourceSkillNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SourceSkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $SourceSkillsRoot -Directory -ErrorAction Stop |
            ForEach-Object { $_.Name }
    )
}

function Get-ToolkitManagedSkillsManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    return (Join-Path $DestinationSkillsRoot $script:ToolkitConstant.ManagedSkillsManifestFileName)
}

function Read-ToolkitManagedSkillsManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    $manifestPath = Get-ToolkitManagedSkillsManifestPath -DestinationSkillsRoot $DestinationSkillsRoot
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        return @()
    }

    try {
        $raw = [System.IO.File]::ReadAllText($manifestPath)
        $parsed = $raw | ConvertFrom-Json
    }
    catch {
        throw ($script:ToolkitMessage.ManagedSkillsManifestInvalid -f $manifestPath, $_.Exception.Message)
    }

    $skillsProperty = $script:ToolkitConstant.ManagedSkillsManifestSkillsProperty
    if ($null -eq $parsed -or $parsed.PSObject.Properties.Name -notcontains $skillsProperty) {
        return @()
    }

    $unique = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($rawName in @($parsed.$skillsProperty)) {
        if ($null -eq $rawName) {
            continue
        }

        $safeName = Assert-ToolkitManagedSkillName -SkillName ([string]$rawName)
        $null = Assert-ToolkitManagedSkillDestinationPath -SkillName $safeName -DestinationSkillsRoot $DestinationSkillsRoot
        [void]$unique.Add($safeName)
    }

    return @($unique)
}

function Get-ToolkitManagedSkillsUninstallAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $DestinationSkillsRoots
    )

    $skillIds = New-Object System.Collections.Generic.List[string]
    $preservedPaths = New-Object System.Collections.Generic.List[string]
    $notes = New-Object System.Collections.Generic.List[string]
    foreach ($skillsRoot in $DestinationSkillsRoots) {
        if ([string]::IsNullOrWhiteSpace($skillsRoot)) { continue }
        $manifestPath = Get-ToolkitManagedSkillsManifestPath -DestinationSkillsRoot $skillsRoot
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            $notes.Add("No ownership manifest at '$manifestPath'; skill folders were preserved.") | Out-Null
            continue
        }

        try {
            $ids = @(Read-ToolkitManagedSkillsManifest -DestinationSkillsRoot $skillsRoot)
        }
        catch {
            $notes.Add("Could not validate ownership manifest '$manifestPath'; skill folders were preserved.") | Out-Null
            continue
        }

        foreach ($id in $ids) {
            $path = Join-Path $skillsRoot $id
            if (-not (Test-Path -LiteralPath $path -PathType Container)) { continue }
            $skillIds.Add([string]$id) | Out-Null
            $preservedPaths.Add($path) | Out-Null
        }
    }

    return [PSCustomObject]@{
        SkillIds       = @($skillIds.ToArray() | Select-Object -Unique)
        PreservedPaths = @($preservedPaths.ToArray() | Select-Object -Unique)
        Notes          = @($notes.ToArray())
    }
}

function Write-ToolkitManagedSkillsManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SkillNames
    )

    if (-not (Test-Path -LiteralPath $DestinationSkillsRoot)) {
        New-Item -ItemType Directory -Path $DestinationSkillsRoot -Force | Out-Null
    }

    $unique = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($rawName in @($SkillNames)) {
        $safeName = Assert-ToolkitManagedSkillName -SkillName $rawName
        $null = Assert-ToolkitManagedSkillDestinationPath -SkillName $safeName -DestinationSkillsRoot $DestinationSkillsRoot
        [void]$unique.Add($safeName)
    }

    $manifestPath = Get-ToolkitManagedSkillsManifestPath -DestinationSkillsRoot $DestinationSkillsRoot
    $payload = [ordered]@{
        ($script:ToolkitConstant.ManagedSkillsManifestSchemaProperty) = $script:ToolkitConstant.ManagedSkillsManifestSchemaVersion
        ($script:ToolkitConstant.ManagedSkillsManifestSkillsProperty) = @($unique | Sort-Object)
    }

    $json = $payload | ConvertTo-Json -Depth $script:ToolkitConstant.JsonConvertDepthShallow
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($manifestPath, $json, $utf8NoBom)
    return $manifestPath
}

function Sync-ToolkitManagedSkillFolders {
    <#
    .SYNOPSIS
      Prune toolkit-managed skill folders that disappeared from the current source set.

    .DESCRIPTION
      Compares DestinationSkillsRoot/.toolkit-managed-skills.json (previous publish)
      to CurrentSkillNames. Removes only directories named in the previous manifest
      that are absent from CurrentSkillNames, then writes the current manifest.

      Empty / missing previous manifest (RN07 alien-safe — no bootstrap reconcile):
      If the manifest file is missing, invalid-as-empty (no skills property), or
      lists zero skills, $previous is empty and this function deletes nothing.
      Unknown kebab-case skill dirs under DestinationSkillsRoot are never pruned
      without a prior manifest entry — alien / first-publish folders stay intact.
      After the (possibly empty) prune pass, the manifest is always rewritten to
      CurrentSkillNames so the next publish can prune retired toolkit skills.

      When -InstallRoot is set, DestinationSkillsRoot and each prune candidate are
      re-asserted under InstallRoot immediately before Remove-Item (child TOCTOU).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $CurrentSkillNames,

        [Parameter()]
        [string] $InstallRoot
    )

    $hasInstallRoot = -not [string]::IsNullOrWhiteSpace($InstallRoot)
    if ($hasInstallRoot) {
        Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $DestinationSkillsRoot -InstallRoot $InstallRoot
    }

    # No prior ownership list => no prune (keep current "no prune" / alien-safe bootstrap).
    $previous = @(Read-ToolkitManagedSkillsManifest -DestinationSkillsRoot $DestinationSkillsRoot)
    $currentSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $CurrentSkillNames) {
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        $safeCurrent = Assert-ToolkitManagedSkillName -SkillName $name
        [void]$currentSet.Add($safeCurrent)
    }

    $pruned = New-Object System.Collections.Generic.List[string]
    $preservedStale = New-Object System.Collections.Generic.List[string]
    foreach ($managedName in $previous) {
        if ($currentSet.Contains($managedName)) {
            continue
        }

        $resolved = Assert-ToolkitManagedSkillDestinationPath -SkillName $managedName -DestinationSkillsRoot $DestinationSkillsRoot
        if (Test-Path -LiteralPath $resolved.Path) {
            if (-not (Test-Path -LiteralPath $resolved.Path -PathType Container)) {
                $preservedStale.Add($resolved.SkillName) | Out-Null
                continue
            }
            $children = @(Get-ChildItem -LiteralPath $resolved.Path -Force -ErrorAction Stop)
            if ($children.Count -gt 0) {
                $preservedStale.Add($resolved.SkillName) | Out-Null
                continue
            }
            if ($hasInstallRoot) {
                $null = Assert-PathUnderInstallRootForDelete -CandidatePath $resolved.Path -InstallRoot $InstallRoot
            }
            Remove-Item -LiteralPath $resolved.Path -Force -ErrorAction Stop
            $pruned.Add($resolved.SkillName)
        }
    }

    $manifestNames = @($CurrentSkillNames) + @($preservedStale.ToArray())
    $null = Write-ToolkitManagedSkillsManifest -DestinationSkillsRoot $DestinationSkillsRoot -SkillNames $manifestNames
    $script:ToolkitLastPreservedStaleSkillNames = @($preservedStale.ToArray())
    if ($preservedStale.Count -gt 0) {
        Write-Warning ('Preserved stale skill folder(s) because the names-only manifest cannot prove file ownership: {0}' -f ($preservedStale.ToArray() -join ', '))
    }
    return @($pruned.ToArray())
}

function Resolve-ToolkitPlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap,

        [Parameter()]
        [string] $TextFileExtensionPattern = $script:ToolkitConstant.DefaultTextFileExtensionPattern,

        [Parameter()]
        [string[]] $UnresolvedTokens,

        [Parameter()]
        [string] $UnresolvedMessageFormat = $script:ToolkitMessage.PlaceholderUnresolved
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        return @()
    }

    $tokensToAssert = @()
    if ($null -ne $UnresolvedTokens -and $UnresolvedTokens.Count -gt 0) {
        $tokensToAssert = @($UnresolvedTokens)
    }
    else {
        $tokensToAssert = @($PlaceholderMap.Keys | ForEach-Object { [string]$_ })
    }

    if ($null -eq $script:ToolkitLastManagedCopyPaths) { return @() }
    $newManagedPaths = @($script:ToolkitLastManagedCopyPaths.ToArray())
    if ($newManagedPaths.Count -eq 0) { return @() }
    $newManagedSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($path in $newManagedPaths) { [void]$newManagedSet.Add([System.IO.Path]::GetFullPath($path)) }

    $files = Get-ChildItem -LiteralPath $RootPath -Recurse -File | Where-Object {
        $newManagedSet.Contains([System.IO.Path]::GetFullPath($_.FullName)) -and
        $_.Extension -match $TextFileExtensionPattern
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $changedPaths = New-Object System.Collections.Generic.List[string]
    foreach ($file in $files) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        $updated = $text
        foreach ($key in $PlaceholderMap.Keys) {
            $token = [string]$key
            if ($updated.Contains($token)) {
                $updated = $updated.Replace($token, [string]$PlaceholderMap[$key])
            }
        }

        foreach ($placeholder in $tokensToAssert) {
            if ($updated.Contains([string]$placeholder)) {
                throw ($UnresolvedMessageFormat -f $placeholder, $file.FullName)
            }
        }

        if (-not [string]::Equals($updated, $text, [System.StringComparison]::Ordinal)) {
            [System.IO.File]::WriteAllText($file.FullName, $updated, $utf8NoBom)
            $changedPaths.Add([System.IO.Path]::GetFullPath($file.FullName)) | Out-Null
        }
    }

    return @($changedPaths.ToArray())
}

function Invoke-ToolkitManagedSkillsPublish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot,

        [Parameter()]
        [System.Collections.IDictionary] $PlaceholderMap,

        [Parameter()]
        [string] $TextFileExtensionPattern = $script:ToolkitConstant.DefaultTextFileExtensionPattern,

        [Parameter()]
        [string[]] $UnresolvedTokens,

        [Parameter()]
        [string] $UnresolvedMessageFormat = $script:ToolkitMessage.PlaceholderUnresolved,

        [Parameter()]
        [switch] $SkipPlaceholderResolve,

        [Parameter()]
        [string] $InstallRoot
    )

    $currentSkillNames = @(Get-ToolkitSourceSkillNames -SourceSkillsRoot $SourceSkillsRoot)
    $copyParams = @{
        SourceRoot      = $SourceSkillsRoot
        DestinationRoot = $DestinationSkillsRoot
    }
    $syncParams = @{
        DestinationSkillsRoot = $DestinationSkillsRoot
        CurrentSkillNames     = $currentSkillNames
    }
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        $copyParams['InstallRoot'] = $InstallRoot
        $syncParams['InstallRoot'] = $InstallRoot
    }

    $filesCopied = Copy-ToolkitManagedTree @copyParams
    $prunedSkillNames = @(Sync-ToolkitManagedSkillFolders @syncParams)

    if (-not $SkipPlaceholderResolve.IsPresent) {
        if ($null -eq $PlaceholderMap) {
            throw $script:ToolkitMessage.PlaceholderMapRequired
        }

        $changedPaths = @(Resolve-ToolkitPlaceholdersInTree `
            -RootPath $DestinationSkillsRoot `
            -PlaceholderMap $PlaceholderMap `
            -TextFileExtensionPattern $TextFileExtensionPattern `
            -UnresolvedTokens $UnresolvedTokens `
            -UnresolvedMessageFormat $UnresolvedMessageFormat)

        if (-not [string]::IsNullOrWhiteSpace($InstallRoot) -and $changedPaths.Count -gt 0) {
            Update-ToolkitManagedCopyInventory -InstallRoot $InstallRoot -Paths $changedPaths
        }
    }

    return [PSCustomObject]@{
        FilesCopied       = $filesCopied
        PreservedPaths    = @($script:ToolkitLastManagedCopyConflicts.ToArray())
        PreservedStaleSkillNames = @($script:ToolkitLastPreservedStaleSkillNames)
        SkillFolderCount  = $currentSkillNames.Count
        CurrentSkillNames = $currentSkillNames
        PrunedSkillNames  = $prunedSkillNames
    }
}

function Get-ToolkitCoreAgentsRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    return (Join-Path (Join-Path $RepoRoot $script:ToolkitConstant.CoreSkillsDirectoryName) $script:ToolkitConstant.AgentsDirectoryName)
}

function Get-ToolkitManagedAgentFileNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceAgentsRoot
    )

    if (-not (Test-Path -LiteralPath $SourceAgentsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $SourceAgentsRoot -File -ErrorAction Stop |
            Where-Object { $_.Extension -eq '.md' } |
            ForEach-Object { $_.Name }
    )
}

function Invoke-ToolkitManagedAgentsPublish {
    <#
    .SYNOPSIS
      Copy core/agents markdown into InstallRoot/agents and resolve placeholders.

    .DESCRIPTION
      Overwrites toolkit-managed agent files. Does not prune alien files under
      DestinationAgentsRoot (user custom subagents stay).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceAgentsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationAgentsRoot,

        [Parameter()]
        [System.Collections.IDictionary] $PlaceholderMap,

        [Parameter()]
        [string] $TextFileExtensionPattern = $script:ToolkitConstant.DefaultTextFileExtensionPattern,

        [Parameter()]
        [string[]] $UnresolvedTokens,

        [Parameter()]
        [string] $UnresolvedMessageFormat = $script:ToolkitMessage.PlaceholderUnresolved,

        [Parameter()]
        [switch] $SkipPlaceholderResolve,

        [Parameter()]
        [string] $InstallRoot
    )

    if ([string]::IsNullOrWhiteSpace($SourceAgentsRoot)) {
        throw $script:ToolkitMessage.SourceAgentsRootRequired
    }

    if ([string]::IsNullOrWhiteSpace($DestinationAgentsRoot)) {
        throw $script:ToolkitMessage.DestinationAgentsRootRequired
    }

    if (-not (Test-Path -LiteralPath $SourceAgentsRoot)) {
        throw ($script:ToolkitMessage.CoreAgentsMissing -f $SourceAgentsRoot)
    }

    $copyParams = @{
        SourceRoot      = $SourceAgentsRoot
        DestinationRoot = $DestinationAgentsRoot
    }
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        $copyParams['InstallRoot'] = $InstallRoot
    }

    $filesCopied = Copy-ToolkitManagedTree @copyParams
    $agentFileNames = @(Get-ToolkitManagedAgentFileNames -SourceAgentsRoot $SourceAgentsRoot)

    if (-not $SkipPlaceholderResolve.IsPresent) {
        if ($null -eq $PlaceholderMap) {
            throw $script:ToolkitMessage.PlaceholderMapRequired
        }

        $changedPaths = @(Resolve-ToolkitPlaceholdersInTree `
            -RootPath $DestinationAgentsRoot `
            -PlaceholderMap $PlaceholderMap `
            -TextFileExtensionPattern $TextFileExtensionPattern `
            -UnresolvedTokens $UnresolvedTokens `
            -UnresolvedMessageFormat $UnresolvedMessageFormat)

        if (-not [string]::IsNullOrWhiteSpace($InstallRoot) -and $changedPaths.Count -gt 0) {
            Update-ToolkitManagedCopyInventory -InstallRoot $InstallRoot -Paths $changedPaths
        }
    }

    return [PSCustomObject]@{
        FilesCopied    = $filesCopied
        AgentFileCount = $agentFileNames.Count
        AgentFileNames = $agentFileNames
    }
}
