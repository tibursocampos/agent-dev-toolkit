#Requires -Version 5.1
<#
.SYNOPSIS
  Resolves and validates an InstallRoot for publish/smoke (fail-closed).

.DESCRIPTION
  Rejects InstallRoot paths under USERPROFILE unless -AllowUserHome is set,
  except when the path is under the toolkit repo root (in-repo fixtures).

  Paths are resolved to their final reparse-point target (junction/symlink)
  before the USERPROFILE / repo-root checks, so an in-repo junction pointing
  at USERPROFILE cannot bypass -AllowUserHome. Resolution requires the path
  to already exist on disk (opening a handle is how reparse points are
  followed); a not-yet-created path is only lexically normalized via
  [System.IO.Path]::GetFullPath, since there is no target to open yet.

  Extended-length (\\?\ / \\?\UNC\) and device (\\.\ / \\.\UNC\) prefixes are
  stripped for both missing and existing paths before USERPROFILE / repo-root
  policy compares, so a missing \\?\C:\Users\... or \\.\C:\Users\... path
  cannot bypass -AllowUserHome.

  When the path exists, reparse resolution is fail-closed: GetFinalPathNameByHandle
  failure throws (never returns the lexical path). Call Confirm-InstallRootAllowsWrite
  immediately before mutation after creating directories (TOCTOU).

  Assert-PathUnderInstallRootForDelete gates uninstall/prune Remove-Item targets:
  the final reparse-resolved path must be a strict child of InstallRoot (fail-closed
  on escape or InstallRoot-equal wipe).
#>

$toolkitLibDir = $PSScriptRoot
. (Join-Path $toolkitLibDir 'ToolkitConstants.ps1')
. (Join-Path $toolkitLibDir 'Get-ToolkitRepoRoot.ps1')

$script:ToolkitReparsePointResolverSource = @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

public static class ToolkitReparsePointResolver
{
    private const uint GenericRead = 0x80000000;
    private const uint FileShareReadWrite = 0x1 | 0x2;
    private const uint OpenExisting = 3;
    private const uint FileFlagBackupSemantics = 0x02000000;

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern SafeFileHandle CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern uint GetFinalPathNameByHandle(
        SafeFileHandle hFile,
        StringBuilder lpszFilePath,
        uint cchFilePath,
        uint dwFlags);

    public static string GetFinalPath(string path)
    {
        using (SafeFileHandle handle = CreateFile(path, GenericRead, FileShareReadWrite, IntPtr.Zero, OpenExisting, FileFlagBackupSemantics, IntPtr.Zero))
        {
            if (handle.IsInvalid)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            StringBuilder buffer = new StringBuilder(1024);
            uint length = GetFinalPathNameByHandle(handle, buffer, (uint)buffer.Capacity, 0);
            if (length == 0 || length >= buffer.Capacity)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            return buffer.ToString(0, (int)length);
        }
    }
}
'@

function Register-ToolkitReparsePointResolverType {
    [CmdletBinding()]
    param()

    $typeName = $script:ToolkitConstant.ReparsePointResolverTypeName
    if (-not ($typeName -as [type])) {
        Add-Type -TypeDefinition $script:ToolkitReparsePointResolverSource
    }
}

function Get-PathWithoutExtendedLengthPrefix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $extendedUncPrefix = $script:ToolkitConstant.ExtendedLengthUncPrefix
    $extendedPrefix = $script:ToolkitConstant.ExtendedLengthPathPrefix
    $deviceUncPrefix = $script:ToolkitConstant.DeviceUncPrefix
    $devicePrefix = $script:ToolkitConstant.DevicePathPrefix
    $uncPathPrefix = $script:ToolkitConstant.UncPathPrefix
    $comparison = [System.StringComparison]::OrdinalIgnoreCase

    # Strip longest/specific UNC forms before the short drive forms.
    if ($Path.StartsWith($extendedUncPrefix, $comparison)) {
        return $uncPathPrefix + $Path.Substring($extendedUncPrefix.Length)
    }

    if ($Path.StartsWith($extendedPrefix, $comparison)) {
        return $Path.Substring($extendedPrefix.Length)
    }

    if ($Path.StartsWith($deviceUncPrefix, $comparison)) {
        return $uncPathPrefix + $Path.Substring($deviceUncPrefix.Length)
    }

    if ($Path.StartsWith($devicePrefix, $comparison)) {
        return $Path.Substring($devicePrefix.Length)
    }

    return $Path
}

function Resolve-ReparsePointTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    # Lexical path is allowed only when the target does not exist yet (no handle to open).
    # Still strip \\?\ / \\?\UNC\ / \\.\ / \\.\UNC\ so missing prefixed USERPROFILE
    # paths cannot bypass -AllowUserHome via prefix mismatch against a non-prefixed profile.
    if (-not (Test-Path -LiteralPath $Path)) {
        return (Get-PathWithoutExtendedLengthPrefix -Path $Path)
    }

    try {
        Register-ToolkitReparsePointResolverType
        $finalPath = ([type]$script:ToolkitConstant.ReparsePointResolverTypeName)::GetFinalPath($Path).Trim()
    }
    catch {
        $detail = $_.Exception.Message
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = $_.ToString()
        }

        throw ($script:ToolkitMessage.InstallRootReparseResolveFailed -f $Path, $detail)
    }

    if ([string]::IsNullOrWhiteSpace($finalPath)) {
        throw ($script:ToolkitMessage.InstallRootReparseResolveFailed -f $Path, $script:ToolkitMessage.InstallRootReparseEmptyFinalPath)
    }

    return (Get-PathWithoutExtendedLengthPrefix -Path $finalPath)
}

function Get-NormalizedFullPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim())
    if ([string]::IsNullOrWhiteSpace($expanded)) {
        throw ($script:ToolkitMessage.InstallRootRequired)
    }

    # Strip before GetFullPath / reparse so USERPROFILE policy never compares a
    # \\?\- or \\.\-prefixed missing path against a non-prefixed profile root.
    $expanded = Get-PathWithoutExtendedLengthPrefix -Path $expanded

    if (-not [System.IO.Path]::IsPathRooted($expanded)) {
        $expanded = Join-Path (Get-Location).Path $expanded
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath($expanded)
    }
    catch {
        throw ($script:ToolkitMessage.InstallRootResolveFailed -f $Path)
    }

    return Resolve-ReparsePointTarget -Path $fullPath
}

function Test-IsPathUnderOrEqual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $ChildPath,
        [Parameter(Mandatory = $true)][string] $ParentPath
    )

    $child = Get-NormalizedFullPath -Path $ChildPath
    $parent = Get-NormalizedFullPath -Path $ParentPath
    $comparison = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($child, $parent, $comparison)) {
        return $true
    }

    $parentWithSep = $parent.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    return $child.StartsWith($parentWithSep, $comparison)
}

function Resolve-InstallRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [switch] $AllowUserHome,

        [string] $UserProfilePath = $env:USERPROFILE,

        [string] $RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw ($script:ToolkitMessage.InstallRootRequired)
    }

    $resolved = Get-NormalizedFullPath -Path $InstallRoot

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        $RepoRoot = Get-ToolkitRepoRoot -FromPath $toolkitLibDir
    }

    $repoRootResolved = Get-NormalizedFullPath -Path $RepoRoot
    $underRepo = Test-IsPathUnderOrEqual -ChildPath $resolved -ParentPath $repoRootResolved

    if (-not $underRepo) {
        if ([string]::IsNullOrWhiteSpace($UserProfilePath)) {
            throw ($script:ToolkitMessage.UserProfileUnavailable)
        }

        $userProfileResolved = Get-NormalizedFullPath -Path $UserProfilePath
        $underUserProfile = Test-IsPathUnderOrEqual -ChildPath $resolved -ParentPath $userProfileResolved

        if ($underUserProfile -and -not $AllowUserHome.IsPresent) {
            throw ($script:ToolkitMessage.InstallRootUnderUserProfileBlocked -f $userProfileResolved, $resolved)
        }
    }

    # TOCTOU: when the path exists, re-follow reparse fail-closed before returning.
    # If the final target changed, re-run full InstallRoot policy on the followed path.
    if (Test-Path -LiteralPath $resolved) {
        $followed = Resolve-ReparsePointTarget -Path $resolved
        $comparison = [System.StringComparison]::OrdinalIgnoreCase
        if (-not [string]::Equals($followed, $resolved, $comparison)) {
            return Resolve-InstallRoot -InstallRoot $followed -AllowUserHome:$AllowUserHome -UserProfilePath $UserProfilePath -RepoRoot $repoRootResolved
        }
    }

    return $resolved
}

function Confirm-InstallRootAllowsWrite {
    <#
    .SYNOPSIS
      Re-validates InstallRoot immediately before write/mutation (TOCTOU).

    .DESCRIPTION
      Call after creating directories and before publishing. Re-runs Resolve-InstallRoot
      so existing paths are reparse-followed fail-closed and under-repo / AllowUserHome
      rules are reapplied. Sync/publish callers should invoke this before mutation when
      InstallRoot may have been created after an earlier resolve.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [switch] $AllowUserHome,

        [string] $UserProfilePath = $env:USERPROFILE,

        [string] $RepoRoot
    )

    return Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -UserProfilePath $UserProfilePath -RepoRoot $RepoRoot
}

function Initialize-InstallRootForWrite {
    <#
    .SYNOPSIS
      Resolve InstallRoot policy, ensure directory exists, then Confirm before mutation.

    .DESCRIPTION
  Shared Publish pattern: Resolve-InstallRoot (lexical policy) first so blocked
  USERPROFILE paths never get created; create when missing; Confirm so post-create
  junction escapes are fail-closed (TOCTOU). If this call created the directory and
  Confirm throws, best-effort remove that orphan only (never delete a pre-existing path).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [switch] $AllowUserHome,

        [string] $UserProfilePath = $env:USERPROFILE,

        [string] $RepoRoot
    )

    $resolved = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -UserProfilePath $UserProfilePath -RepoRoot $RepoRoot

    $createdByThisCall = $false
    if (-not (Test-Path -LiteralPath $resolved)) {
        New-Item -ItemType Directory -Path $resolved -Force | Out-Null
        $createdByThisCall = $true
    }

    try {
        return Confirm-InstallRootAllowsWrite -InstallRoot $resolved -AllowUserHome:$AllowUserHome -UserProfilePath $UserProfilePath -RepoRoot $RepoRoot
    }
    catch {
        # Best-effort: remove only the directory this call created (fail closed; still rethrow).
        if ($createdByThisCall -and (Test-Path -LiteralPath $resolved)) {
            try {
                Remove-Item -LiteralPath $resolved -Force -Recurse -ErrorAction Stop
            }
            catch {
                # Ignore cleanup failure; original Confirm/Resolve error is authoritative.
            }
        }

        throw
    }
}

function Assert-PathUnderInstallRootForDelete {
    <#
    .SYNOPSIS
      Asserts a delete candidate's final path is a strict child of InstallRoot.

    .DESCRIPTION
      Call immediately before Remove-Item on toolkit uninstall/prune paths.
      Resolves reparse points (junction/symlink) fail-closed via Get-NormalizedFullPath;
      refuses candidates whose final target escapes InstallRoot or equals InstallRoot
      (no wholesale wipe of the install root).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CandidatePath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if ([string]::IsNullOrWhiteSpace($CandidatePath)) {
        throw $script:ToolkitMessage.DeletePathRequired
    }

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ToolkitMessage.InstallRootRequired
    }

    $candidateFinal = Get-NormalizedFullPath -Path $CandidatePath
    $rootFinal = Get-NormalizedFullPath -Path $InstallRoot
    $comparison = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($candidateFinal, $rootFinal, $comparison)) {
        throw ($script:ToolkitMessage.DeletePathIsInstallRoot -f $candidateFinal)
    }

    if (-not (Test-IsPathUnderOrEqual -ChildPath $candidateFinal -ParentPath $rootFinal)) {
        throw ($script:ToolkitMessage.DeletePathEscapesInstallRoot -f $CandidatePath, $candidateFinal, $rootFinal)
    }

    return $candidateFinal
}
