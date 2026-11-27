function Resolve-ToolkitPhysicalPath {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $pathRoot = [System.IO.Path]::GetPathRoot($fullPath)
    $segments = $fullPath.Substring($pathRoot.Length) -split '[\\/]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $currentPath = $pathRoot
    foreach ($segment in $segments) {
        $componentPath = [System.IO.Path]::GetFullPath((Join-Path $currentPath $segment))
        $item = Get-Item -LiteralPath $componentPath -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $resolveLinkTarget = [System.IO.FileSystemInfo].GetMethod('ResolveLinkTarget', [type[]]@([bool]))
            if ($null -eq $resolveLinkTarget) {
                throw ("Cannot safely resolve reparse point on this runtime: {0}" -f $componentPath)
            }
            $target = $resolveLinkTarget.Invoke($item, @($true))
            if ($null -eq $target) {
                throw ("Cannot resolve reparse point target: {0}" -f $componentPath)
            }
            $currentPath = [System.IO.Path]::GetFullPath($target.FullName)
        }
        else {
            $currentPath = $componentPath
        }
    }

    return [System.IO.Path]::GetFullPath($currentPath)
}

function Test-ToolkitPathWithinRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RootPath,
        [Parameter(Mandatory = $true)][string] $CandidatePath,
        [scriptblock] $PhysicalResolver
    )

    if ($PhysicalResolver) {
        $resolvedRoot = [string](& $PhysicalResolver $RootPath)
        $resolvedCandidate = [string](& $PhysicalResolver $CandidatePath)
    }
    else {
        $resolvedRoot = Resolve-ToolkitPhysicalPath -Path $RootPath
        $resolvedCandidate = Resolve-ToolkitPhysicalPath -Path $CandidatePath
    }

    $resolvedRoot = [System.IO.Path]::GetFullPath($resolvedRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $resolvedCandidate = [System.IO.Path]::GetFullPath($resolvedCandidate)
    $rootPrefix = $resolvedRoot + [System.IO.Path]::DirectorySeparatorChar
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    return $resolvedCandidate.Equals($resolvedRoot, $comparison) -or $resolvedCandidate.StartsWith($rootPrefix, $comparison)
}

function Get-ToolkitSafeRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RootPath,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )

    if ([System.IO.Path]::IsPathRooted($RelativePath) -or $RelativePath -match '^[A-Za-z]:' -or $RelativePath -match '^[\\/]') {
        throw 'absolute paths are not allowed for repository contract fields'
    }
    if (@($RelativePath -split '[\\/]+' | Where-Object { $_ -eq '..' }).Count -gt 0) {
        throw 'path traversal segment is not allowed for repository contract fields'
    }

    $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $RootPath $RelativePath))
    $rootFullPath = [System.IO.Path]::GetFullPath($RootPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $rootPrefix = $rootFullPath + [System.IO.Path]::DirectorySeparatorChar
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    if (-not ($candidatePath.Equals($rootFullPath, $comparison) -or $candidatePath.StartsWith($rootPrefix, $comparison))) {
        throw 'path escapes its lexical root'
    }
    return $candidatePath
}

function Resolve-ToolkitContainedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RootPath,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )

    $candidatePath = Get-ToolkitSafeRelativePath -RootPath $RootPath -RelativePath $RelativePath
    if (-not (Test-ToolkitPathWithinRoot -RootPath $RootPath -CandidatePath $candidatePath)) {
        throw 'resolved path escapes its physical root'
    }
    return Resolve-ToolkitPhysicalPath -Path $candidatePath
}

function Test-ToolkitForbiddenPathEntryExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RootPath,
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [scriptblock] $EntryInspector
    )

    $currentPath = Get-ToolkitSafeRelativePath -RootPath $RootPath -RelativePath $RelativePath
    if ($EntryInspector) {
        $entry = & $EntryInspector $currentPath
        return [bool]$entry.exists -or [bool]$entry.reparsePoint
    }

    # Inspect the directory entry itself. Test-Path follows links and can report
    # false for dangling links, which must still count as an existing forbidden path.
    try {
        $item = Get-Item -LiteralPath $currentPath -Force -ErrorAction Stop
        return $null -ne $item
    }
    catch {
        if ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound) {
            return $false
        }
        throw
    }
}
