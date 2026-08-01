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
    $sourceFiles = Get-ChildItem -LiteralPath $sourceRootFull -Recurse -File -ErrorAction Stop
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

        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
        $filesCopied++
    }

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
    foreach ($managedName in $previous) {
        if ($currentSet.Contains($managedName)) {
            continue
        }

        $resolved = Assert-ToolkitManagedSkillDestinationPath -SkillName $managedName -DestinationSkillsRoot $DestinationSkillsRoot
        if (Test-Path -LiteralPath $resolved.Path) {
            if ($hasInstallRoot) {
                $null = Assert-PathUnderInstallRootForDelete -CandidatePath $resolved.Path -InstallRoot $InstallRoot
            }
            Remove-Item -LiteralPath $resolved.Path -Recurse -Force -ErrorAction Stop
            $pruned.Add($resolved.SkillName)
        }
    }

    $null = Write-ToolkitManagedSkillsManifest -DestinationSkillsRoot $DestinationSkillsRoot -SkillNames @($CurrentSkillNames)
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
        return
    }

    $tokensToAssert = @()
    if ($null -ne $UnresolvedTokens -and $UnresolvedTokens.Count -gt 0) {
        $tokensToAssert = @($UnresolvedTokens)
    }
    else {
        $tokensToAssert = @($PlaceholderMap.Keys | ForEach-Object { [string]$_ })
    }

    $files = Get-ChildItem -LiteralPath $RootPath -Recurse -File | Where-Object {
        $_.Extension -match $TextFileExtensionPattern
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
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
        }
    }
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

        Resolve-ToolkitPlaceholdersInTree `
            -RootPath $DestinationSkillsRoot `
            -PlaceholderMap $PlaceholderMap `
            -TextFileExtensionPattern $TextFileExtensionPattern `
            -UnresolvedTokens $UnresolvedTokens `
            -UnresolvedMessageFormat $UnresolvedMessageFormat
    }

    return [PSCustomObject]@{
        FilesCopied       = $filesCopied
        SkillFolderCount  = $currentSkillNames.Count
        CurrentSkillNames = $currentSkillNames
        PrunedSkillNames  = $prunedSkillNames
    }
}
