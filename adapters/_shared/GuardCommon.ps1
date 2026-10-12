#Requires -Version 5.1
<#
.SYNOPSIS
  Shared path-allow / path-deny / secret-pattern helpers for adapter pre-tool hooks.

.DESCRIPTION
  Dot-source from adapter hook scripts (or from Cursor _hook-common.ps1).
  Host-agnostic: callers map host tool names and input shapes before calling these helpers.
  Contract reference: adapters/_shared/guard-rules.md
#>

Set-StrictMode -Version Latest

function Test-ActionAuthorization {
    [CmdletBinding()]
    param(
        [AllowNull()][AllowEmptyString()][string] $Effect,
        [AllowNull()][AllowEmptyString()][string] $Scope,
        [AllowNull()][object[]] $Authorizations = @()
    )

    if ([string]::IsNullOrWhiteSpace($Effect) -or [string]::IsNullOrWhiteSpace($Scope)) {
        return [PSCustomObject]@{ Allowed = $false; Reason = 'invalid_request'; Effect = $Effect; Scope = $Scope }
    }
    if ($null -eq $Authorizations) {
        return [PSCustomObject]@{ Allowed = $false; Reason = 'invalid_authorization'; Effect = $Effect; Scope = $Scope }
    }
    foreach ($authorization in $Authorizations) {
        if ($null -eq $authorization -or
            $null -eq $authorization.PSObject.Properties['Effect'] -or
            $null -eq $authorization.PSObject.Properties['Scope'] -or
            [string]::IsNullOrWhiteSpace([string]$authorization.Effect) -or
            [string]::IsNullOrWhiteSpace([string]$authorization.Scope)) {
            return [PSCustomObject]@{ Allowed = $false; Reason = 'invalid_authorization'; Effect = $Effect; Scope = $Scope }
        }
    }
    foreach ($authorization in $Authorizations) {
        if ([string]::Equals([string]$authorization.Effect, $Effect, [StringComparison]::Ordinal) -and
            [string]::Equals([string]$authorization.Scope, $Scope, [StringComparison]::Ordinal)) {
            return [PSCustomObject]@{ Allowed = $true; Reason = 'authorized'; Effect = $Effect; Scope = $Scope }
        }
    }
    return [PSCustomObject]@{ Allowed = $false; Reason = 'effect_or_scope_not_authorized'; Effect = $Effect; Scope = $Scope }
}

function Get-ToolkitAuthorizationContract {
    $contractPath = Join-Path $PSScriptRoot 'authorization-contract.json'
    if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
        throw "Authorization contract is missing beside GuardCommon.ps1: $contractPath"
    }

    try {
        $contract = Get-Content -LiteralPath $contractPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Authorization contract is invalid JSON beside GuardCommon.ps1: $contractPath. $($_.Exception.Message)"
    }

    if ($null -eq $contract -or $contract.schemaVersion -ne 1 -or $null -eq $contract.authorizations) {
        throw "Authorization contract is invalid beside GuardCommon.ps1: expected schemaVersion 1 and authorizations: $contractPath"
    }

    $authorizations = @($contract.authorizations)
    if ($authorizations.Count -eq 0) {
        throw "Authorization contract is invalid beside GuardCommon.ps1: authorizations cannot be empty: $contractPath"
    }

    foreach ($authorization in $authorizations) {
        if ($null -eq $authorization -or
            $null -eq $authorization.PSObject.Properties['effect'] -or
            $null -eq $authorization.PSObject.Properties['scope'] -or
            [string]::IsNullOrWhiteSpace([string]$authorization.effect) -or
            [string]::IsNullOrWhiteSpace([string]$authorization.scope)) {
            throw "Authorization contract is invalid beside GuardCommon.ps1: every authorization needs effect and scope: $contractPath"
        }
    }

    return $contract
}

function Test-ToolkitIsWindows {
    $isWindowsVariable = Get-Variable -Name IsWindows -Scope Global -ErrorAction SilentlyContinue
    if ($null -ne $isWindowsVariable) {
        return [bool]$isWindowsVariable.Value
    }
    return ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)
}

if ((Test-ToolkitIsWindows) -and -not ('Toolkit.GuardPathNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace Toolkit {
    public static class GuardPathNative {
        private const uint OpenExisting = 3;
        private const uint FileFlagBackupSemantics = 0x02000000;
        private static readonly IntPtr InvalidHandleValue = new IntPtr(-1);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr CreateFile(
            string fileName, uint desiredAccess, FileShare share, IntPtr securityAttributes,
            uint creationDisposition, uint flagsAndAttributes, IntPtr templateFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr handle);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern uint GetFinalPathNameByHandle(
            IntPtr file, StringBuilder filePath, uint filePathLength, uint flags);

        public static string ResolveExistingPath(string path) {
            var handle = CreateFile(path, 0, FileShare.ReadWrite | FileShare.Delete,
                IntPtr.Zero, OpenExisting, FileFlagBackupSemantics, IntPtr.Zero);
            if (handle == InvalidHandleValue) {
                throw new IOException("CreateFile failed for path resolution: " + path,
                    Marshal.GetLastWin32Error());
            }

            try {
                var buffer = new StringBuilder(32768);
                var length = GetFinalPathNameByHandle(handle, buffer, (uint)buffer.Capacity, 0);
                if (length == 0 || length >= buffer.Capacity) {
                    throw new IOException("GetFinalPathNameByHandle failed for path resolution: " + path,
                        Marshal.GetLastWin32Error());
                }
                return buffer.ToString();
            }
            finally {
                CloseHandle(handle);
            }
        }
    }
}
'@
}

if (-not (Test-ToolkitIsWindows) -and -not ('Toolkit.GuardPathPosixNative' -as [type])) {
    try {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Toolkit {
    public static class GuardPathPosixNative {
        [DllImport("libc", CharSet = CharSet.Ansi, SetLastError = true)]
        private static extern IntPtr realpath(string path, IntPtr resolvedPath);

        [DllImport("libc", SetLastError = true)]
        private static extern void free(IntPtr pointer);

        public static string ResolveExistingPath(string path) {
            var pointer = realpath(path, IntPtr.Zero);
            if (pointer == IntPtr.Zero) {
                return null;
            }

            try {
                return Marshal.PtrToStringAnsi(pointer);
            }
            finally {
                free(pointer);
            }
        }
    }
}
'@
    }
    catch {
        # An unavailable native API is handled as an unverifiable path below.
    }
}

function Resolve-ToolkitExistingPath {
    param(
        [Parameter(Mandatory = $true)][string] $Path
    )

    if (Test-ToolkitIsWindows) {
        if (-not ('Toolkit.GuardPathNative' -as [type])) {
            return $null
        }
        return [Toolkit.GuardPathNative]::ResolveExistingPath($Path)
    }

    # POSIX hosts do not have kernel32.dll. Call libc directly so attacker-
    # controlled PATH entries cannot select the resolver executable.
    if (-not ('Toolkit.GuardPathPosixNative' -as [type])) {
        return $null
    }
    try {
        $resolved = [Toolkit.GuardPathPosixNative]::ResolveExistingPath($Path)
    }
    catch {
        # A native resolver failure must never fall back to lexical containment.
        return $null
    }
    if ([string]::IsNullOrWhiteSpace([string]$resolved)) {
        return $null
    }
    return [System.IO.Path]::GetFullPath([string]$resolved)
}

function Get-ToolkitHookEventName {
    param($HookInput)

    if ($null -eq $HookInput) {
        return ''
    }
    foreach ($name in @('hook_event_name', 'hookEventName', 'event_name', 'eventName', 'event')) {
        $prop = $HookInput.PSObject.Properties[$name]
        if ($prop -and $null -ne $prop.Value) {
            return ([string]$prop.Value).Trim()
        }
    }
    return ''
}

function Test-ToolkitHookEventIdentity {
    param(
        $HookInput,
        [Parameter(Mandatory = $true)][string[]] $ExpectedEventNames
    )

    $actual = Get-ToolkitHookEventName -HookInput $HookInput
    if ([string]::IsNullOrWhiteSpace($actual)) {
        return $false
    }
    foreach ($expected in $ExpectedEventNames) {
        if ($actual.Equals($expected, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-ToolkitHookInputSchema {
    param($HookInput)

    if ($null -eq $HookInput -or $HookInput -is [System.Array]) {
        return $false
    }
    if ($HookInput -isnot [pscustomobject]) {
        return $false
    }

    return (@($HookInput.PSObject.Properties).Count -gt 0)
}

function Get-ToolkitCanonicalPathForGuard {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $WorkspaceRoot
    )

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
        $rootFull = [System.IO.Path]::GetFullPath($WorkspaceRoot)
    }
    catch {
        return $null
    }

    # Resolve the deepest existing ancestor. This covers both existing links and
    # a not-yet-created child below a junction/symlink.
    $probe = $fullPath
    while (-not ([System.IO.File]::Exists($probe) -or [System.IO.Directory]::Exists($probe))) {
        $parent = [System.IO.Directory]::GetParent($probe)
        if ($null -eq $parent -or $parent.FullName -eq $probe) {
            return $null
        }
        $probe = $parent.FullName
    }

    # POSIX writes through symlinks/reparse points are not safe to authorize
    # without an atomic handle-relative operation. Deny the existing ancestor
    # itself so a missing child below an escaping link cannot be written through.
    if (-not (Test-ToolkitIsWindows)) {
        try {
            $probeItem = Get-Item -LiteralPath $probe -Force -ErrorAction Stop
            if (($probeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
                -not [string]::IsNullOrWhiteSpace([string]$probeItem.LinkType)) {
                return $null
            }
        }
        catch {
            return $null
        }
    }

    try {
        $resolvedProbe = Resolve-ToolkitExistingPath -Path $probe
        if ([string]::IsNullOrWhiteSpace($resolvedProbe)) {
            return $null
        }
        if ($resolvedProbe.StartsWith('\\?\UNC\', [System.StringComparison]::OrdinalIgnoreCase)) {
            $resolvedProbe = '\\' + $resolvedProbe.Substring(8)
        }
        elseif ($resolvedProbe.StartsWith('\\?\', [System.StringComparison]::OrdinalIgnoreCase)) {
            $resolvedProbe = $resolvedProbe.Substring(4)
        }
        $resolvedProbe = [System.IO.Path]::GetFullPath($resolvedProbe)
        $suffix = $fullPath.Substring($probe.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($suffix)) {
            return $resolvedProbe
        }
        return [System.IO.Path]::GetFullPath((Join-Path $resolvedProbe $suffix))
    }
    catch {
        # Existing paths must never fall back to lexical containment.
        return $null
    }
}

function Test-ToolkitPathIsUnderWorkspaceRoot {
    param(
        [string] $FullPath,
        [string] $RootFull
    )

    if ([string]::IsNullOrWhiteSpace($FullPath) -or [string]::IsNullOrWhiteSpace($RootFull)) {
        return $false
    }

    $full = $FullPath.TrimEnd('\', '/')
    $root = $RootFull.TrimEnd('\', '/')
    if ($full.Equals($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $alt = [System.IO.Path]::AltDirectorySeparatorChar
    $rootPrefix = $root + $sep
    $rootPrefixAlt = $root + $alt
    if ($FullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    if ($sep -ne $alt -and $FullPath.StartsWith($rootPrefixAlt, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $false
}

$script:ToolkitUserAdapterRootNames = @(
    '.cursor',
    '.codex',
    '.claude',
    '.copilot',
    '.grok',
    '.hermes',
    '.opencode',
    '.zcode',
    '.antigravity',
    '.gemini',
    '.agents'
)

function Get-ToolkitUserHomeForGuard {
    $userHome = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($userHome)) {
        $userHome = $env:HOME
    }
    if ([string]::IsNullOrWhiteSpace($userHome)) {
        return ''
    }
    try {
        return [System.IO.Path]::GetFullPath($userHome)
    }
    catch {
        return ''
    }
}

function Test-ToolkitPathIsUnderUserAdapterRoot {
    param([string] $FilePath)

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        return $false
    }

    $userHome = Get-ToolkitUserHomeForGuard
    if ([string]::IsNullOrWhiteSpace($userHome)) {
        return $false
    }

    $full = Get-ToolkitCanonicalPathForGuard -Path $FilePath -WorkspaceRoot (Get-Location).Path
    if ([string]::IsNullOrWhiteSpace($full)) { return $false }

    foreach ($name in $script:ToolkitUserAdapterRootNames) {
        $lexicalRoot = [System.IO.Path]::GetFullPath((Join-Path $userHome $name))
        $root = Get-ToolkitCanonicalPathForGuard -Path $lexicalRoot -WorkspaceRoot (Get-Location).Path
        if ([string]::IsNullOrWhiteSpace($root) -or -not $root.Equals($lexicalRoot, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if (Test-ToolkitPathIsUnderWorkspaceRoot -FullPath $full -RootFull $root) {
            return $true
        }
    }

    return $false
}

function Test-ToolkitPathIsUnderLocalSddRoot {
    param([string] $FilePath)
    if ([string]::IsNullOrWhiteSpace($FilePath)) { return $false }
    $userHome = Get-ToolkitUserHomeForGuard
    if ([string]::IsNullOrWhiteSpace($userHome)) { return $false }
    $roots = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $script:ToolkitUserAdapterRootNames) {
        $roots.Add((Join-Path (Join-Path $userHome $name) 'sdd'))
    }
    # OpenCode and Hermes have provider-specific roots that are not in the generic list.
    $roots.Add((Join-Path (Join-Path $userHome '.config\opencode') 'sdd'))
    if (-not [string]::IsNullOrWhiteSpace($env:HERMES_HOME)) { $roots.Add((Join-Path $env:HERMES_HOME 'sdd')) }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { $roots.Add((Join-Path (Join-Path $env:LOCALAPPDATA 'hermes') 'sdd')) }
    try { $full = Get-ToolkitCanonicalPathForGuard -Path $FilePath -WorkspaceRoot (Get-Location).Path } catch { return $false }
    if ([string]::IsNullOrWhiteSpace($full)) { return $false }
    foreach ($candidate in $roots) {
        try { $lexicalRoot = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
        try { $root = Get-ToolkitCanonicalPathForGuard -Path $candidate -WorkspaceRoot (Get-Location).Path } catch { continue }
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        # The trust boundary itself must not be redirected by a link/reparse point.
        if (-not $root.Equals($lexicalRoot, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if (Test-ToolkitPathIsUnderWorkspaceRoot -FullPath $full -RootFull $root) { return $true }
    }
    return $false
}

function Get-ToolkitNormalizedRelativePath {
    <#
    .SYNOPSIS
      Map a file path to a workspace-relative `/` path.
    .OUTPUTS
      Relative path string when inside workspace; empty string for blank input;
      $null when the path resolves outside the workspace root (or is absolute with no root).
    #>
    param(
        [string] $FilePath,
        [string] $WorkspaceRoot
    )

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        return ''
    }

    $fullPath = $FilePath
    if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
        if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
            $fullPath = Join-Path $WorkspaceRoot $FilePath
        }
        else {
            # Relative with no workspace: keep as normalized relative candidate.
            return (($FilePath -replace '\\', '/').TrimStart('/'))
        }
    }

    $rootFull = ''
    if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($WorkspaceRoot)
        }
        catch {
            $rootFull = ''
        }
    }

    if ([string]::IsNullOrWhiteSpace($rootFull)) {
        # Absolute path without a workspace root cannot be validated as in-repo.
        return $null
    }

    $canonicalRoot = Get-ToolkitCanonicalPathForGuard -Path $rootFull -WorkspaceRoot $rootFull
    $canonicalPath = Get-ToolkitCanonicalPathForGuard -Path $fullPath -WorkspaceRoot $rootFull
    if ([string]::IsNullOrWhiteSpace($canonicalRoot) -or [string]::IsNullOrWhiteSpace($canonicalPath)) {
        return $null
    }

    if (Test-ToolkitPathIsUnderWorkspaceRoot -FullPath $canonicalPath -RootFull $canonicalRoot) {
        $relative = $canonicalPath.Substring($canonicalRoot.TrimEnd('\', '/').Length).TrimStart('\', '/')
        return ($relative -replace '\\', '/')
    }

    # Outside workspace (includes sibling-prefix cases like agent-dev-toolkit-evil).
    return $null
}

function Test-ToolkitForbiddenSddPath {
    param([string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    $norm = ($RelativePath -replace '\\', '/').TrimStart('/')
    if ($norm -match '^(PRD|PLAN)/') {
        return $true
    }
    if ($norm -match '^docs/(PRD|PLAN|backlog)/') {
        return $true
    }
    if ($norm -match '(^|/)\.cursor/plans/') {
        return $true
    }
    return $false
}

function Test-ToolkitDeniedPathSegment {
    param([string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    $norm = '/' + (($RelativePath -replace '\\', '/').Trim('/')) + '/'
    $denied = @(
        '/.git/'
    )
    foreach ($segment in $denied) {
        if ($norm -match [regex]::Escape($segment)) {
            return $true
        }
    }
    return $false
}

function Test-ToolkitAllowedWritePath {
    param([string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    # Workspace-relative paths are allowed unless a protected tree matches.
    $asFsPath = ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ([System.IO.Path]::IsPathRooted($asFsPath)) {
        return $false
    }

    if (Test-ToolkitForbiddenSddPath -RelativePath $RelativePath) {
        return $false
    }
    if (Test-ToolkitDeniedPathSegment -RelativePath $RelativePath) {
        return $false
    }

    return $true
}

# Friendly alias used by shared docs / future adapters.
function Test-AllowedPath {
    param([string] $RelativePath)
    return (Test-ToolkitAllowedWritePath -RelativePath $RelativePath)
}

function Test-ToolkitSecretFalsePositive {
    param([string] $Line)

    # Kept as a compatibility helper for callers that only have a line. A line
    # containing documentation context is never sufficient to suppress a
    # secret finding; matching is performed against the individual candidate.
    # This overload therefore cannot produce a false-positive exemption.
    return $false
}

function Test-ToolkitSecretCandidateFalsePositive {
    param([string] $Candidate)

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return $false
    }

    # Only suppress an exact, explicit placeholder value. Do not inspect or
    # suppress the rest of the source line: a real secret can share that line.
    $value = ($Candidate -replace '(?is)^.*?=\s*', '').Trim().Trim('''').Trim('"')
    return $value -match '(?i)^(YOUR_[A-Z0-9_]+|<TOKEN>|x{3,}|placeholder(?:[_-][A-Z0-9_-]+)?)$'
}

function Get-ToolkitSecretFindings {
    param([string] $Content)

    $findings = [System.Collections.ArrayList]::new()
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return @()
    }

    $patterns = @(
        @{ Name = 'aws_access_key'; Pattern = 'AKIA[0-9A-Z]{16}' },
        @{ Name = 'api_key_literal'; Pattern = '(?i)api[_-]?key\s*=\s*[''"]?[a-z0-9_\-]{8,}' },
        @{ Name = 'github_token'; Pattern = 'gh[pousr]_[A-Za-z0-9_]{20,}' },
        @{ Name = 'jwt'; Pattern = 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' },
        @{ Name = 'password_conn'; Pattern = '(?i)password\s*=\s*[^;\s''"]{4,}' },
        @{ Name = 'private_key'; Pattern = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' },
        @{ Name = 'azure_account_key'; Pattern = '(?i)AccountKey\s*=\s*[A-Za-z0-9+/=]{20,}' }
    )

    $lineNo = 0
    foreach ($line in ($Content -split "`r?`n")) {
        $lineNo++
        foreach ($entry in $patterns) {
            foreach ($match in [regex]::Matches($line, $entry.Pattern)) {
                if (-not (Test-ToolkitSecretCandidateFalsePositive -Candidate $match.Value)) {
                    [void]$findings.Add([PSCustomObject]@{
                            Type = $entry.Name
                            Line = $lineNo
                        })
                    break
                }
            }
            if ($findings.Count -gt 0 -and $findings[$findings.Count - 1].Line -eq $lineNo) { break }
        }
    }

    return @($findings)
}

# Friendly alias: returns $true when any secret pattern matches.
function Test-SecretPatterns {
    param([string] $Content)
    $findings = @(Get-ToolkitSecretFindings -Content $Content)
    return ($findings.Count -gt 0)
}

function Get-WriteToolPathFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }
    foreach ($name in @('path', 'file_path', 'filePath', 'target_file', 'TargetFile', 'AbsolutePath')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            return [string]$prop.Value
        }
    }
    return ''
}

function Get-WriteToolContentFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }

    $parts = [System.Collections.ArrayList]::new()
    foreach ($name in @('contents', 'content', 'new_string', 'newText', 'text', 'CodeContent', 'ReplacementContent')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            [void]$parts.Add([string]$prop.Value)
        }
    }

    $editsProp = $ToolInput.PSObject.Properties['edits']
    if ($editsProp -and $null -ne $editsProp.Value) {
        foreach ($edit in @($editsProp.Value)) {
            $newProp = $edit.PSObject.Properties['new_string']
            if ($newProp -and -not [string]::IsNullOrWhiteSpace([string]$newProp.Value)) {
                [void]$parts.Add([string]$newProp.Value)
            }
        }
    }

    $chunksProp = $ToolInput.PSObject.Properties['ReplacementChunks']
    if ($chunksProp -and $null -ne $chunksProp.Value) {
        foreach ($chunk in @($chunksProp.Value)) {
            foreach ($chunkField in @('ReplacementContent', 'new_string', 'content')) {
                $chunkProp = $chunk.PSObject.Properties[$chunkField]
                if ($chunkProp -and -not [string]::IsNullOrWhiteSpace([string]$chunkProp.Value)) {
                    [void]$parts.Add([string]$chunkProp.Value)
                    break
                }
            }
        }
    }

    return ($parts -join "`n")
}

function Test-ToolkitWriteToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)(Write|StrReplace|search_replace|Edit|MultiEdit)$'
}

function Test-ToolkitShellToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)(Shell|Bash|PowerShell)$'
}

function Test-ToolkitDeleteToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)Delete$'
}

function Test-ToolkitApplyPatchToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)(apply_patch)$'
}

function Test-ToolkitReadOnlyToolName {
    param(
        [Parameter(Mandatory = $true)][string] $ProviderId,
        [string] $ToolName
    )

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }

    $readOnlyTools = @{
        cursor      = @('Read', 'Grep', 'Glob', 'LS')
        antigravity = @('read_file', 'read_many_files', 'list_directory', 'glob', 'grep_search', 'google_web_search', 'web_fetch', 'get_internal_docs')
        claude      = @('Read', 'Grep', 'Glob', 'WebFetch', 'WebSearch', 'AskUserQuestion', 'TodoRead')
        codex       = @('Read', 'Grep', 'Glob', 'WebFetch', 'WebSearch')
        copilot     = @('view', 'grep', 'glob')
        grok        = @('Read', 'Grep', 'Glob', 'WebFetch', 'WebSearch', 'AskUserQuestion', 'TodoRead')
        zcode       = @('Read', 'Grep', 'Glob', 'WebFetch', 'WebSearch', 'AskUserQuestion', 'TodoRead')
        hermes      = @('read_file', 'read_many_files', 'list_directory', 'search_files', 'find_files', 'web_search', 'web_fetch', 'memory_search', 'ask_user')
        openhands   = @('read', 'browse', 'search', 'list_files', 'find_files', 'grep', 'glob', 'view')
    }
    if (-not $readOnlyTools.ContainsKey($ProviderId)) {
        return $false
    }
    return $readOnlyTools[$ProviderId] -contains $ToolName
}

function Get-ShellCommandFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }
    foreach ($name in @('command', 'cmd', 'shell_command', 'script', 'CommandLine')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop) {
            if ($prop.Value -isnot [string]) { return '' }
            if (-not [string]::IsNullOrWhiteSpace($prop.Value)) { return $prop.Value }
        }
    }
    return ''
}

function Get-DeleteToolPathFromInput {
    param($ToolInput)
    return (Get-WriteToolPathFromInput -ToolInput $ToolInput)
}

function Get-ApplyPatchContentFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }

    $fromWrite = Get-WriteToolContentFromInput -ToolInput $ToolInput
    if (-not [string]::IsNullOrWhiteSpace($fromWrite)) {
        return $fromWrite
    }

    foreach ($name in @('command', 'patch', 'input')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            return [string]$prop.Value
        }
    }
    return ''
}

function Get-ApplyPatchPathsFromContent {
    param([string] $PatchContent)

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ([string]::IsNullOrWhiteSpace($PatchContent)) {
        return @()
    }

    foreach ($line in ($PatchContent -split "`r?`n")) {
        if ($line -match '(?i)^\*\*\*\s+(?:Add|Update|Delete)\s+File:\s+(.+)$') {
            [void]$paths.Add($Matches[1].Trim().Trim('"').Trim("'"))
        }
        elseif ($line -match '(?i)^diff --git a/(.+?) b/(.+)$') {
            [void]$paths.Add($Matches[1].Trim())
            [void]$paths.Add($Matches[2].Trim())
        }
        elseif ($line -match '(?i)^(?:\+\+\+|---)\s+[ab]/(.+)$') {
            $p = $Matches[1].Trim()
            if ($p -ne '/dev/null') {
                [void]$paths.Add($p)
            }
        }
    }
    return @($paths)
}

function Test-ToolkitShellTokenIsPath {
    param([string] $Candidate)

    if ([string]::IsNullOrWhiteSpace($Candidate) -or $Candidate.StartsWith('-')) {
        return $false
    }
    if ($Candidate -match '^(?i)https?://') {
        return $false
    }
    return ($Candidate -match '[\\/]' -or $Candidate -match '\.(cs|ts|js|json|md|ps1|sh|yml|yaml|toml|xml|txt)$')
}

function Add-ToolkitShellPathCandidate {
    param(
        $Paths,
        [string] $Candidate
    )

    $value = $Candidate.Trim().Trim('"').Trim("'")
    if (Test-ToolkitShellTokenIsPath -Candidate $value) {
        [void]$Paths.Add($value)
    }
}

function Test-ToolkitShellLiteralSitsUnderFeatures {
    param(
        [string] $Command,
        [int] $Index,
        [string] $Literal
    )

    if ($Literal -ne 'PRD/' -and $Literal -ne 'PLAN/') {
        return $false
    }
    $before = $Command.Substring(0, $Index)
    return $before -match '(?i)features[\\/][^\s"'']*$'
}

function Test-ToolkitShellOutsidePathIsCanonicalRuntime {
    param(
        [string] $Command,
        [string] $FilePath
    )

    if ($Command -notmatch '(?i)(?:^|[\s;&|])(?:pwsh|powershell)(?:\.exe)?\b') {
        return $false
    }
    if ($Command -match '(?i)\b(Set-Content|Add-Content|Out-File|Remove-Item|Move-Item|Copy-Item|New-Item|Clear-Content)\b') {
        return $false
    }
    $norm = ($FilePath -replace '\\', '/').TrimEnd('/')
    if ($norm -match '(?i)(^|/)\.cursor/scripts/(validation|session|ledger)/[^/]+\.ps1$') {
        return $true
    }
    return $norm -match '(?i)(^|/)\.cursor/sdd$'
}

function Test-ToolkitShellCommandMutatesPaths {
    param([string] $Command)

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $false
    }

    if ($Command.Trim() -match '(?i)^python(?:3)?\s+-c\s+(["''])(?:print\(-?\d+(?:\.\d+)?\)|print\(["''][^"'']*["'']\))\1$') {
        return $false
    }

    if ($Command -match '(?i)(?:\d?>|&>|\|\s*tee\b)') {
        return $true
    }

    return $Command -match '(?i)(?:^|[\s;&|])(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|Rename-Item|Clear-Content|\bri\b|\brm\b|\bdel\b|\berase\b|\btee\b|rmdir|unlink|\bmv\b|\bcp\b|touch|mkdir|install|truncate|dd|chmod|chown|sed\s+-[^\r\n]*i\b|perl\s+-[^\r\n]*i\b|git\s+(?:add|apply|checkout|clean|commit|merge|mv|reset|restore|rebase|rm)\b|npm\s+(?:install|ci|uninstall|publish)\b|dotnet\s+(?:build|publish|restore)\b|python(?:3)?\s+-c\b|node\s+-e\b)\b'
}

function Test-ToolkitShellCommandIsReadOnly {
    param([string] $Command)

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $false
    }

    foreach ($segment in @($Command -split '(?:;|&&|\|\||\|)')) {
        $text = $segment.Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }
        if ($text -match '(?i)^python(?:3)?\s+-c\s+(["''])(?:print\(-?\d+(?:\.\d+)?\)|print\(["''][^"'']*["'']\))\1$') {
            continue
        }
        if ($text -match '(?i)^sed\s+(?:-[nE]\s+)*["'']s/[^/]+/[^/]+/g?["'']\s+(?:[A-Za-z0-9_.-]+[\\/])*[A-Za-z0-9_.-]+$') {
            continue
        }
        if ($text -match '(?i)^(?:pwsh|powershell)(?:\.exe)?\s+-[^\r\n]*\s+-File\s+["'']?.*\.cursor/scripts/(?:validation|session|ledger)/[^"'']+\.ps1(?:["'']?\s|$)') {
            continue
        }
        if ($text -notmatch '^(?i)(?:Get-Date|Get-Location|Get-Content|Get-ChildItem|Get-Item|Test-Path|Resolve-Path|Write-Output|Write-Host|echo|printf|cat|head|tail|grep|rg|find|ls|dir|pwd|whoami|where|which|git\s+(?:status|diff|log|show|branch|rev-parse|ls-files))(?=\s|$)') {
            return $false
        }
    }
    return $true
}

function Get-PathsReferencedInShellCommand {
    param([string] $Command)

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ([string]::IsNullOrWhiteSpace($Command)) {
        return @()
    }

    $patterns = @(
        '(?i)(?:^|[\s;&|])(?:>{1,2})\s*["'']?([^\s"'';|&;]+)',
        '(?i)(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|\bri\b|\brm\b|\bdel\b|\berase\b|\btee\b)\s+(?:-[A-Za-z]+\s+[^\s]+\s+)*["'']?([^\s"'';|&;]+)',
        '(?i)(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|Get-Content|Get-ChildItem)\s+[^\r\n]{0,400}?-(?:LiteralPath|FilePath|Path)\s+["'']?([^\s"'';|&;]+)',
        '(?i)-(?:LiteralPath|FilePath|Path)\s+["'']?([^\s"'';|&;]+)',
        '(?i)(?:rm|rmdir|unlink|mv|cp|install)\s+(?:-[a-zA-Z0-9\-]+\s+)*["'']?([^\s"'';|&;]+)',
        '(?i)(?:^|[\s;&|])(?:cat|echo|printf)\s+[^\r\n]{0,200}(?:>{1,2})\s*["'']?([^\s"'';|&;]+)',
        '["'']([^"'']+)["'']',
        '(?i)(?:^|[\s;&|])((?:[A-Za-z0-9_.-]+[\\/])+[A-Za-z0-9_.-]+)'
    )
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Command, $pattern)) {
            if ($match.Groups.Count -gt 1) {
                Add-ToolkitShellPathCandidate -Paths $paths -Candidate $match.Groups[1].Value
            }
        }
    }

    # Legacy root trees stay forbidden. A canonical features/**/PLAN|PRD path is not that tree.
    foreach ($literal in @('PRD/', 'PLAN/', 'docs/PRD/', 'docs/PLAN/', 'docs/backlog/', '.cursor/plans/', 'node_modules/', '.git/')) {
        $searchFrom = 0
        while ($searchFrom -lt $Command.Length) {
            $found = $Command.IndexOf($literal, $searchFrom, [System.StringComparison]::OrdinalIgnoreCase)
            if ($found -lt 0) {
                break
            }
            if (-not (Test-ToolkitShellLiteralSitsUnderFeatures -Command $Command -Index $found -Literal $literal)) {
                [void]$paths.Add($literal.TrimEnd('/'))
                break
            }
            $searchFrom = $found + $literal.Length
        }
    }

    return @($paths)
}

function Resolve-ToolkitGuardPathExpression {
    <#
    .SYNOPSIS
      Expand only the environment-variable forms supported by the guard.

    .DESCRIPTION
      Path input is data, not PowerShell source.  Do not invoke a parser or
      evaluate arbitrary expressions here.  The accepted forms are
      $env:NAME, ${env:NAME}, and %NAME%.  Missing variables and every other
      variable/expression form are rejected so an unresolved expression cannot
      be mistaken for a workspace-relative path.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $Path
    )

    $result = [PSCustomObject]@{
        Supported  = $true
        ExpandedPath = $Path
        Reason     = ''
    }

    if ($Path.IndexOf('$', [System.StringComparison]::Ordinal) -lt 0 -and
        $Path.IndexOf('%', [System.StringComparison]::Ordinal) -lt 0) {
        return $result
    }

    $expanded = $Path
    $envPattern = '\$\{env:([A-Za-z_][A-Za-z0-9_]*)\}|\$env:([A-Za-z_][A-Za-z0-9_]*)'
    $envMatches = [regex]::Matches($expanded, $envPattern)
    foreach ($match in $envMatches) {
        $name = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
        $value = [Environment]::GetEnvironmentVariable($name)
        if ([string]::IsNullOrEmpty($value)) {
            $result.Supported = $false
            $result.Reason = "environment_variable_unset:$name"
            return $result
        }
        $expanded = $expanded.Replace($match.Value, $value)
    }

    $percentPattern = '%([A-Za-z_][A-Za-z0-9_]*)%'
    $percentMatches = [regex]::Matches($expanded, $percentPattern)
    foreach ($match in $percentMatches) {
        $name = $match.Groups[1].Value
        $value = [Environment]::GetEnvironmentVariable($name)
        if ([string]::IsNullOrEmpty($value)) {
            $result.Supported = $false
            $result.Reason = "environment_variable_unset:$name"
            return $result
        }
        $expanded = $expanded.Replace($match.Value, $value)
    }

    if ($expanded -match '\$|%') {
        $result.Supported = $false
        $result.Reason = 'unsupported_path_expression'
        return $result
    }

    $result.ExpandedPath = $expanded
    return $result
}

function Get-ToolkitPathSecretsGuardVerdict {
    <#
    .SYNOPSIS
      Host-agnostic allow/deny for write, delete, shell, and apply_patch tool calls.
    #>
    param(
        [string] $ToolName,
        [object] $ToolInput,
        [string] $WorkspaceRoot,
        [string] $DirectShellCommand = ''
    )

    $allow = [PSCustomObject]@{
        Decision     = 'allow'
        Reason       = ''
        UserMessage  = ''
        AgentMessage = ''
        RelativePath = ''
        SecretType   = ''
    }

    $isWrite = Test-ToolkitWriteToolName -ToolName $ToolName
    $isDelete = Test-ToolkitDeleteToolName -ToolName $ToolName
    $isShell = Test-ToolkitShellToolName -ToolName $ToolName
    $isPatch = Test-ToolkitApplyPatchToolName -ToolName $ToolName

    if (-not ($isWrite -or $isDelete -or $isShell -or $isPatch)) {
        return $allow
    }

    $pathsToCheck = [System.Collections.Generic.List[string]]::new()
    $contentToScan = ''
    $shellCmd = ''

    if ($isWrite) {
        $filePath = Get-WriteToolPathFromInput -ToolInput $ToolInput
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'missing_path'
                UserMessage  = 'Blocked: write/edit tool missing file path.'
                AgentMessage = 'Hook denied write/edit because tool_input has no path/file_path. Fail-closed: path is required.'
                RelativePath = ''
                SecretType   = ''
            }
        }
        $pathsToCheck.Add($filePath) | Out-Null
        $writePathExpression = Resolve-ToolkitGuardPathExpression -Path $filePath
        if (-not $writePathExpression.Supported) {
            return [PSCustomObject]@{ Decision = 'deny'; Reason = $writePathExpression.Reason; UserMessage = 'Blocked: path expression is unsupported or unresolved.'; AgentMessage = 'Hook denied the write because path expansion is limited to supported environment-variable forms and must resolve before authorization.'; RelativePath = $filePath; SecretType = '' }
        }
        $filePath = $writePathExpression.ExpandedPath
        $pathsToCheck.Clear()
        $pathsToCheck.Add($filePath) | Out-Null
        $resolvedWritePath = Get-ToolkitCanonicalPathForGuard -Path $filePath -WorkspaceRoot $WorkspaceRoot
        $resolvedWorkspace = Get-ToolkitCanonicalPathForGuard -Path $WorkspaceRoot -WorkspaceRoot $WorkspaceRoot
        if ([string]::IsNullOrWhiteSpace($resolvedWritePath) -or [string]::IsNullOrWhiteSpace($resolvedWorkspace) -or
            (-not (Test-ToolkitPathIsUnderWorkspaceRoot -FullPath $resolvedWritePath -RootFull $resolvedWorkspace) -and
             -not (Test-ToolkitPathIsUnderLocalSddRoot -FilePath $filePath) -and
             -not (Test-ToolkitPathIsUnderUserAdapterRoot -FilePath $filePath))) {
            return [PSCustomObject]@{ Decision = 'deny'; Reason = 'outside_workspace'; UserMessage = 'Blocked: resolved destination escapes authorized scopes.'; AgentMessage = 'Hook denied the write because the resolved target is outside workspace and local SDD roots.'; RelativePath = $filePath; SecretType = '' }
        }
        $contentToScan = Get-WriteToolContentFromInput -ToolInput $ToolInput
    }
    elseif ($isDelete) {
        $filePath = Get-DeleteToolPathFromInput -ToolInput $ToolInput
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'missing_path'
                UserMessage  = 'Blocked: delete tool missing file path.'
                AgentMessage = 'Hook denied Delete because tool_input has no path. Fail-closed: path is required.'
                RelativePath = ''
                SecretType   = ''
            }
        }
        $pathsToCheck.Add($filePath) | Out-Null
    }
    elseif ($isPatch) {
        $patchBody = Get-ApplyPatchContentFromInput -ToolInput $ToolInput
        $contentToScan = $patchBody
        foreach ($p in @(Get-ApplyPatchPathsFromContent -PatchContent $patchBody)) {
            $pathsToCheck.Add($p) | Out-Null
        }
    }
    elseif ($isShell) {
        $shellCmd = $DirectShellCommand
        if ([string]::IsNullOrWhiteSpace($shellCmd)) {
            $shellCmd = Get-ShellCommandFromInput -ToolInput $ToolInput
        }
        if ([string]::IsNullOrWhiteSpace($shellCmd)) {
            return [PSCustomObject]@{ Decision = 'deny'; Reason = 'invalid_shell_payload'; UserMessage = 'Blocked: shell tool requires a non-empty command string.'; AgentMessage = 'Hook denied shell execution because the command is missing, empty, or malformed.'; RelativePath = ''; SecretType = '' }
        }
        $contentToScan = $shellCmd
        $shellMutates = Test-ToolkitShellCommandMutatesPaths -Command $shellCmd
        if ($shellMutates) {
            foreach ($p in @(Get-PathsReferencedInShellCommand -Command $shellCmd)) {
                $pathsToCheck.Add($p) | Out-Null
            }
            if ($pathsToCheck.Count -eq 0) {
                return [PSCustomObject]@{ Decision = 'deny'; Reason = 'unclassified_shell_mutation'; UserMessage = 'Blocked: shell command appears write-capable but its target could not be classified.'; AgentMessage = 'Hook denied shell execution because a write-capable command had no safely classified target path.'; RelativePath = ''; SecretType = '' }
            }
        }
        elseif (-not (Test-ToolkitShellCommandIsReadOnly -Command $shellCmd)) {
            return [PSCustomObject]@{ Decision = 'deny'; Reason = 'unclassified_shell_effect'; UserMessage = 'Blocked: shell command effect could not be classified as read-only.'; AgentMessage = 'Hook denied shell execution because an unclassified command cannot be proven free of write effects.'; RelativePath = ''; SecretType = '' }
        }
    }

    $authorizationEffect = if ($isDelete) { 'file.delete' } elseif ($isPatch) { 'file.patch' } elseif ($isShell) { 'shell.mutate' } else { 'file.write' }
    $contract = Get-ToolkitAuthorizationContract
    $authorizationPairs = @($contract.authorizations)

    foreach ($rawPath in $pathsToCheck) {
        $pathExpression = Resolve-ToolkitGuardPathExpression -Path $rawPath
        if (-not $pathExpression.Supported) {
            return [PSCustomObject]@{ Decision = 'deny'; Reason = $pathExpression.Reason; UserMessage = 'Blocked: path expression is unsupported or unresolved.'; AgentMessage = 'Hook denied the path because only supported environment-variable forms may be expanded before authorization.'; RelativePath = $rawPath; SecretType = '' }
        }
        $rawPath = $pathExpression.ExpandedPath
        $canonicalRawPath = Get-ToolkitCanonicalPathForGuard -Path $rawPath -WorkspaceRoot $WorkspaceRoot
        $canonicalWorkspaceRoot = Get-ToolkitCanonicalPathForGuard -Path $WorkspaceRoot -WorkspaceRoot $WorkspaceRoot
        if ([string]::IsNullOrWhiteSpace($canonicalRawPath) -or [string]::IsNullOrWhiteSpace($canonicalWorkspaceRoot)) {
            return [PSCustomObject]@{ Decision = 'deny'; Reason = 'unresolvable_path'; UserMessage = 'Blocked: destination path could not be safely resolved.'; AgentMessage = 'Hook denied the path because its existing path components could not be resolved.'; RelativePath = $rawPath; SecretType = '' }
        }
        if (-not (Test-ToolkitPathIsUnderWorkspaceRoot -FullPath $canonicalRawPath -RootFull $canonicalWorkspaceRoot) -and
            -not (Test-ToolkitPathIsUnderLocalSddRoot -FilePath $rawPath) -and
            -not (Test-ToolkitPathIsUnderUserAdapterRoot -FilePath $rawPath)) {
            return [PSCustomObject]@{ Decision = 'deny'; Reason = 'outside_workspace'; UserMessage = ("Blocked: path outside allowed scopes ({0})." -f $rawPath); AgentMessage = ("Hook denied tool targeting '{0}'. Resolved target escapes every authorized scope." -f $rawPath); RelativePath = $rawPath; SecretType = '' }
        }
        $relativePath = Get-ToolkitNormalizedRelativePath -FilePath $rawPath -WorkspaceRoot $WorkspaceRoot
        if ($null -eq $relativePath) {
            if ($isShell -and (Test-ToolkitShellOutsidePathIsCanonicalRuntime -Command $shellCmd -FilePath $rawPath)) {
                continue
            }
            $scope = if (Test-ToolkitPathIsUnderLocalSddRoot -FilePath $rawPath) { 'local_sdd' }
                     elseif (Test-ToolkitPathIsUnderUserAdapterRoot -FilePath $rawPath) { 'provider_home' }
                     else { '' }
            $authorization = Test-ActionAuthorization -Effect $authorizationEffect -Scope $scope -Authorizations $authorizationPairs
            if (-not $authorization.Allowed) {
                return [PSCustomObject]@{
                    Decision     = 'deny'
                    Reason       = 'outside_workspace'
                    UserMessage  = ("Blocked: path outside allowed scopes ({0})." -f $rawPath)
                    AgentMessage = ("Hook denied tool targeting '{0}'. Mutating effects require an authorized workspace, local SDD, or provider scope." -f $rawPath)
                    RelativePath = $rawPath
                    SecretType   = ''
                }
            }
            if ($scope -eq 'local_sdd' -or $scope -eq 'provider_home') {
                if (Test-ToolkitDeniedPathSegment -RelativePath $rawPath) {
                    return [PSCustomObject]@{
                        Decision     = 'deny'
                        Reason       = 'forbidden_path'
                        UserMessage  = ("Blocked: path outside allowed scopes ({0})." -f $rawPath)
                        AgentMessage = ("Hook denied tool targeting '{0}'. .git stays protected inside adapter homes." -f $rawPath)
                        RelativePath = $rawPath
                        SecretType   = ''
                    }
                }
                continue
            }
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'outside_workspace'
                UserMessage  = ("Blocked: path outside workspace ({0})." -f $rawPath)
                AgentMessage = ("Hook denied tool targeting '{0}'. Writes must stay in the workspace or in a user adapter home (.cursor, .codex, and the other toolkit homes)." -f $rawPath)
                RelativePath = $rawPath
                SecretType   = ''
            }
        }
        $authorization = Test-ActionAuthorization -Effect $authorizationEffect -Scope 'workspace' -Authorizations $authorizationPairs
        if (-not $authorization.Allowed) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'unauthorized_effect_or_scope'
                UserMessage  = 'Blocked: mutating effect is not authorized for the workspace scope.'
                AgentMessage = 'Hook denied mutating effect because the shared effect/scope contract rejected it.'
                RelativePath = $relativePath
                SecretType   = ''
            }
        }

        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            # Bare forbidden tokens from shell scan (e.g. "PRD").
            if ((Test-ToolkitForbiddenSddPath -RelativePath $rawPath) -or (Test-ToolkitDeniedPathSegment -RelativePath $rawPath)) {
                return [PSCustomObject]@{
                    Decision     = 'deny'
                    Reason       = 'forbidden_path'
                    UserMessage  = ("Blocked: path outside allowed scopes ({0})." -f $rawPath)
                    AgentMessage = ("Hook denied tool targeting '{0}'. SDD artifacts belong under features/; avoid legacy PRD/PLAN trees and denied segments." -f $rawPath)
                    RelativePath = $rawPath
                    SecretType   = ''
                }
            }
            continue
        }

        if (-not (Test-ToolkitAllowedWritePath -RelativePath $relativePath)) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'forbidden_path'
                UserMessage  = ("Blocked: path outside allowed scopes ({0})." -f $relativePath)
                AgentMessage = ("Hook denied tool targeting '{0}'. Paths must stay inside the workspace and outside .git and legacy PRD/PLAN trees." -f $relativePath)
                RelativePath = $relativePath
                SecretType   = ''
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($contentToScan)) {
        $secretFindings = @(Get-ToolkitSecretFindings -Content $contentToScan)
        if ($secretFindings.Count -gt 0) {
            $first = $secretFindings[0]
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'secret_pattern'
                UserMessage  = ("Blocked: possible secret ({0}) near line {1}." -f $first.Type, $first.Line)
                AgentMessage = ("Hook denied tool because content matches secret pattern '{0}'. Use env var names or placeholders. Never commit API keys, tokens, passwords, or private keys." -f $first.Type)
                RelativePath = ''
                SecretType   = [string]$first.Type
            }
        }
    }

    return $allow
}

function Resolve-ToolkitGuardCommonPath {
    <#
    .SYNOPSIS
      Locate adapters/_shared/GuardCommon.ps1 from a hook script directory.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string] $FromDirectory
    )

    $candidates = @(
        (Join-Path $FromDirectory 'GuardCommon.ps1'),
        (Join-Path $FromDirectory '..\..\..\_shared\GuardCommon.ps1'),
        (Join-Path $FromDirectory '..\..\..\..\_shared\GuardCommon.ps1')
    )
    foreach ($candidate in $candidates) {
        try {
            $full = [System.IO.Path]::GetFullPath($candidate)
        }
        catch {
            continue
        }
        if (Test-Path -LiteralPath $full) {
            return $full
        }
    }
    return $null
}
