#Requires -Version 5.1
<#
.SYNOPSIS
  Creates disposable work directories under one ignored location inside the repository.

.DESCRIPTION
  Resolve-InstallRoot refuses an InstallRoot under USERPROFILE except inside the repository,
  and the Windows temp directory lives under USERPROFILE. Validation work therefore happens in
  <repo>/.adt-work/<guid>/ (or $env:ADT_WORK_ROOT/<guid>/ when CI overrides the base).
  Each call sweeps guid-named sibling directories idle for over one day, only when the base
  carries a .adt-work-marker file. Links are removed without being followed.
  Callers remove their directory in try/finally with Remove-ToolkitWorkRoot.
#>

function Get-ToolkitWorkBase {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $repoFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
    if ([string]::IsNullOrWhiteSpace($env:ADT_WORK_ROOT)) {
        return [System.IO.Path]::GetFullPath((Join-Path $repoFull '.adt-work')).TrimEnd('\', '/')
    }

    $override = [System.IO.Path]::GetFullPath($env:ADT_WORK_ROOT)
    if ($override -eq [System.IO.Path]::GetPathRoot($override)) {
        throw "ADT_WORK_ROOT must not be a drive root: $override"
    }
    $override = $override.TrimEnd('\', '/')
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $cmp = [System.StringComparison]::OrdinalIgnoreCase
    $insideRepo = $override.StartsWith($repoFull + $sep, $cmp)
    if (-not $insideRepo) {
        if (($repoFull + $sep).StartsWith($override + $sep, $cmp)) {
            throw "ADT_WORK_ROOT must not be an ancestor of the repository: $override"
        }
        $profileRoot = [Environment]::GetFolderPath('UserProfile')
        if (-not [string]::IsNullOrWhiteSpace($profileRoot)) {
            $profileFull = [System.IO.Path]::GetFullPath($profileRoot).TrimEnd('\', '/')
            if ($override.StartsWith($profileFull + $sep, $cmp) -or $override -ieq $profileFull) {
                throw "ADT_WORK_ROOT must not be under the user profile unless inside the repository: $override"
            }
        }
    }
    return $override
}

function New-ToolkitWorkRoot {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $base = Get-ToolkitWorkBase -RepoRoot $RepoRoot
    New-Item -ItemType Directory -Path $base -Force | Out-Null

    $markerPath = Join-Path $base '.adt-work-marker'
    if (-not (Test-Path -LiteralPath $markerPath)) {
        [System.IO.File]::WriteAllText($markerPath, 'agent-dev-toolkit work base')
    }

    $cutoff = (Get-Date).AddDays(-1)
    foreach ($stale in @(Get-ChildItem -LiteralPath $base -Directory -Force -ErrorAction SilentlyContinue)) {
        if ($stale.Name -cnotmatch '^[0-9a-f]{32}$') { continue }
        if ($stale.LastWriteTime -ge $cutoff) { continue }
        if (($stale.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            [System.IO.Directory]::Delete($stale.FullName, $false)
            continue
        }
        $newest = $stale.LastWriteTime
        foreach ($item in @(Get-ChildItem -LiteralPath $stale.FullName -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            if ($item.LastWriteTime -gt $newest) { $newest = $item.LastWriteTime }
        }
        if ($newest -ge $cutoff) { continue }
        # Links inside the tree are unlinked first so the recursive delete never follows them.
        foreach ($link in @(Get-ChildItem -LiteralPath $stale.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                    Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 })) {
            try {
                if ($link.PSIsContainer) { [System.IO.Directory]::Delete($link.FullName, $false) }
                else { [System.IO.File]::Delete($link.FullName) }
            }
            catch { }
        }
        Remove-Item -LiteralPath $stale.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

    $root = Join-Path $base ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

function Remove-ToolkitWorkRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $base = (Get-ToolkitWorkBase -RepoRoot $RepoRoot) + [System.IO.Path]::DirectorySeparatorChar
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a path outside the toolkit work base: $full"
    }
    if (Test-Path -LiteralPath $full) {
        Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Drop the work base once no run directories remain, so a finished run leaves nothing behind.
    $baseRoot = Get-ToolkitWorkBase -RepoRoot $RepoRoot
    $runs = @(Get-ChildItem -LiteralPath $baseRoot -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -cmatch '^[0-9a-f]{32}$' })
    $marker = Join-Path $baseRoot '.adt-work-marker'
    if ($runs.Count -eq 0 -and (Test-Path -LiteralPath $marker)) {
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        if (@(Get-ChildItem -LiteralPath $baseRoot -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -LiteralPath $baseRoot -Force -ErrorAction SilentlyContinue
        }
    }
}
