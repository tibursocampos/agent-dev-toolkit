#Requires -Version 5.1
# Test fixture only. This script is not a runtime authorization boundary and must
# not be used to grant Classic implementation access.
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)][string] $PortablePath,
    [Parameter(Mandatory = $true)][ValidateSet('read', 'write')][string] $Operation,
    [Parameter()][string] $AuthorizationContextJson,
    [Parameter()][string] $ApprovedScopeJson,
    [Parameter()][string] $AuthorizationContextBase64,
    [Parameter()][string] $ApprovedScopeBase64,
    [Parameter()][AllowEmptyString()][string] $Content
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -eq 'Windows_NT' -and -not ('ClassicExternalFinalPath' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
public static class ClassicExternalFinalPath {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateFileW(string name, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetFinalPathNameByHandleW(IntPtr handle, StringBuilder path, uint length, uint flags);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);
    public static string Resolve(string path, bool directory) {
        uint flags = directory ? 0x02000000u : 0u;
        IntPtr handle = CreateFileW(path, 0, 7, IntPtr.Zero, 3, flags, IntPtr.Zero);
        if (handle == new IntPtr(-1)) throw new Win32Exception(Marshal.GetLastWin32Error());
        try {
            StringBuilder buffer = new StringBuilder(32768);
            uint length = GetFinalPathNameByHandleW(handle, buffer, (uint)buffer.Capacity, 0);
            if (length == 0 || length >= buffer.Capacity) throw new Win32Exception(Marshal.GetLastWin32Error());
            string value = buffer.ToString();
            if (value.StartsWith("\\\\?\\UNC\\", StringComparison.OrdinalIgnoreCase)) return "\\\\" + value.Substring(8);
            if (value.StartsWith("\\\\?\\", StringComparison.Ordinal)) return value.Substring(4);
            return value;
        } finally { CloseHandle(handle); }
    }
}
'@
}

function Stop-Access([string] $Reason) { throw "classic_external_access_denied: $Reason" }

function ConvertTo-PortableReference([string] $Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { Stop-Access 'path is empty or contains an ambiguous character' }
    if ($Value -match '[\p{Cc}]' -or $Value.Normalize([Text.NormalizationForm]::FormC) -cne $Value) {
        Stop-Access 'path is not canonical text'
    }
    if ($Value.Contains('\')) { Stop-Access 'portable paths must use forward slashes' }
    if ($Value -notmatch '^external:([A-Za-z][A-Za-z0-9_-]*)(?:/(.+))$') {
        Stop-Access 'path must use external:<alias>/<relative-path>'
    }
    $alias = $Matches[1]
    $relative = $Matches[2]
    if ($relative -match '[\x00-\x1f\x7f?%#:]') { Stop-Access 'path contains a forbidden or ambiguous character' }
    $segments = $relative.Split('/')
    foreach ($segment in $segments) {
        if ([string]::IsNullOrEmpty($segment) -or $segment -eq '.' -or $segment -eq '..' -or
            $segment.EndsWith('.') -or $segment.EndsWith(' ') -or $segment -match '[<>"|*]') {
            Stop-Access 'path contains an empty, traversal, or ambiguous segment'
        }
    }
    return [pscustomobject]@{ Alias = $alias; Relative = ($segments -join '/'); Canonical = ('external:{0}/{1}' -f $alias, ($segments -join '/')) }
}

function Test-PathWithin([string] $Root, [string] $Candidate) {
    $comparison = if ($env:OS -eq 'Windows_NT') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $candidateFull = [IO.Path]::GetFullPath($Candidate)
    return $candidateFull.Equals($rootFull, $comparison) -or $candidateFull.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar, $comparison)
}

function Get-FinalPath([string] $Path, [bool] $IsDirectory) {
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $providerPath = $resolved.ProviderPath
    if ($env:OS -eq 'Windows_NT') { $providerPath = [ClassicExternalFinalPath]::Resolve($providerPath, $IsDirectory) }
    return [IO.Path]::GetFullPath($providerPath).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Assert-NoReparseComponents([string] $Root, [string] $RelativePath, [bool] $LeafMayBeMissing) {
    $rootItem = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
    if (-not $rootItem.PSIsContainer) { Stop-Access 'authorized root is not a directory' }
    if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Stop-Access 'authorized root is a reparse point' }

    $current = $Root
    $segments = $RelativePath.Split('/')
    for ($i = 0; $i -lt $segments.Count; $i++) {
        $current = Join-Path $current $segments[$i]
        $exists = Test-Path -LiteralPath $current
        if (-not $exists) {
            if ($LeafMayBeMissing -and $i -eq ($segments.Count - 1)) { return $current }
            Stop-Access 'target or intermediate directory does not exist'
        }
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Stop-Access 'reparse points are not allowed in the authorized path' }
        if ($i -lt ($segments.Count - 1) -and -not $item.PSIsContainer) { Stop-Access 'intermediate path component is not a directory' }
        if ($i -eq ($segments.Count - 1) -and $Operation -eq 'read' -and $item.PSIsContainer) { Stop-Access 'read target must be a file' }
        if ($i -eq ($segments.Count - 1) -and $Operation -eq 'write' -and $item.PSIsContainer) { Stop-Access 'write target must be a file' }
    }
    return $current
}

try {
    $Operation = $Operation.ToLowerInvariant()
    $reference = ConvertTo-PortableReference $PortablePath
    if ([string]::IsNullOrEmpty($AuthorizationContextJson) -and -not [string]::IsNullOrEmpty($AuthorizationContextBase64)) {
        $AuthorizationContextJson = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($AuthorizationContextBase64))
    }
    if ([string]::IsNullOrEmpty($ApprovedScopeJson) -and -not [string]::IsNullOrEmpty($ApprovedScopeBase64)) {
        $ApprovedScopeJson = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($ApprovedScopeBase64))
    }
    if ([string]::IsNullOrEmpty($AuthorizationContextJson) -or [string]::IsNullOrEmpty($ApprovedScopeJson)) {
        Stop-Access 'authorization context and approved scope are required'
    }
    $authorization = $AuthorizationContextJson | ConvertFrom-Json -ErrorAction Stop
    $scope = $ApprovedScopeJson | ConvertFrom-Json -ErrorAction Stop
    if ($authorization.schemaVersion -ne 1 -or $null -eq $authorization.aliases) { Stop-Access 'trusted authorization context has an unsupported shape' }
    if ($null -eq $scope.reference -or $null -eq $scope.operations) { Stop-Access 'approved step scope is missing reference or operations' }

    $approved = ConvertTo-PortableReference ([string]$scope.reference)
    if ($approved.Alias -ine $reference.Alias) { Stop-Access 'requested alias is outside the approved step scope' }
    $scopePrefix = $approved.Canonical.TrimEnd('/')
    if ($reference.Canonical -ine $scopePrefix -and -not $reference.Canonical.StartsWith($scopePrefix + '/', [StringComparison]::OrdinalIgnoreCase)) {
        Stop-Access 'requested path is outside the approved step scope'
    }
    if (@($scope.operations) -cnotcontains $Operation) { Stop-Access 'operation is not approved for this step' }

    $aliasProperty = $authorization.aliases.PSObject.Properties | Where-Object { $_.Name -ceq $reference.Alias } | Select-Object -First 1
    if ($null -eq $aliasProperty) { Stop-Access 'alias is absent from trusted invocation mapping' }
    $binding = $aliasProperty.Value
    if ($null -eq $binding.root -or -not [IO.Path]::IsPathRooted([string]$binding.root)) { Stop-Access 'trusted alias root must be fully qualified' }
    if (@($binding.operations) -cnotcontains $Operation) { Stop-Access 'operation is not granted by trusted invocation mapping' }

    $root = [IO.Path]::GetFullPath([string]$binding.root)
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { Stop-Access 'authorized root does not exist' }
    $rootFinal = Get-FinalPath $root $true
    $allowMissingLeaf = $Operation -eq 'write'
    $target = Assert-NoReparseComponents -Root $rootFinal -RelativePath $reference.Relative -LeafMayBeMissing $allowMissingLeaf
    if (-not (Test-PathWithin $rootFinal $target)) { Stop-Access 'resolved target is outside the authorized root' }
    if (Test-Path -LiteralPath $target) {
        $targetFinal = Get-FinalPath $target (Test-Path -LiteralPath $target -PathType Container)
        if (-not (Test-PathWithin $rootFinal $targetFinal)) { Stop-Access 'resolved target is outside the authorized root' }
    }

    if ($Operation -eq 'read') {
        $value = [IO.File]::ReadAllText($target)
        [ordered]@{ decision = 'allow'; operation = 'read'; path = $reference.Canonical; content = $value } | ConvertTo-Json -Compress
        exit 0
    }

    if (-not $PSBoundParameters.ContainsKey('Content')) { Stop-Access 'write content is required' }
    if (-not $PSCmdlet.ShouldProcess($reference.Canonical, 'write authorized external file')) {
        [ordered]@{ decision = 'not_performed'; operation = 'write'; path = $reference.Canonical } | ConvertTo-Json -Compress
        exit 3
    }
    [IO.File]::WriteAllText($target, $Content, [Text.UTF8Encoding]::new($false))
    [ordered]@{ decision = 'allow'; operation = 'write'; path = $reference.Canonical } | ConvertTo-Json -Compress
    exit 0
} catch {
    $message = [string]$_.Exception.Message
    if ($message -notmatch '^classic_external_access_denied:') { $message = 'classic_external_access_denied: request could not be safely resolved' }
    [Console]::Error.WriteLine($message)
    exit 2
}
