#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string] $ReceiptJson,
    [Parameter(Mandatory = $false)][string] $ReceiptJsonBase64,
    [Parameter(Mandatory = $true)][string] $RepoRoot,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [Parameter(Mandatory = $true)][ValidateRange(1, 2147483647)][int] $Step,
    [Parameter(Mandatory = $true)][string] $AllowedPathPrefixesPath,
    [Parameter(Mandatory = $true)][string] $AuthorizedRootsPath,
    [Parameter(Mandatory = $false)][switch] $TestCaseSensitiveScope,
    [Parameter(Mandatory = $false)][switch] $TestContainmentOnly,
    [Parameter(Mandatory = $false)][string] $TestContainmentRoot,
    [Parameter(Mandatory = $false)][string] $TestContainmentTarget,
    [Parameter(Mandatory = $false)][switch] $TestFinalPathOnly,
    [Parameter(Mandatory = $false)][string] $TestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -eq 'Windows_NT' -and -not ('O3ReceiptPathResolver' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
public static class O3ReceiptPathResolver {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateFileW(string name, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetFinalPathNameByHandleW(IntPtr handle, StringBuilder path, uint length, uint flags);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);
    [StructLayout(LayoutKind.Sequential)]
    private struct FileCaseSensitiveInfo { public uint Flags; }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool GetFileInformationByHandleEx(IntPtr handle, int informationClass, out FileCaseSensitiveInfo information, uint size);
    public static string Resolve(string path) {
        IntPtr handle = CreateFileW(path, 0, 7, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero);
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
    public static bool IsCaseSensitiveDirectory(string path) {
        IntPtr handle = CreateFileW(path, 0x80, 7, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero);
        if (handle == new IntPtr(-1)) throw new Win32Exception(Marshal.GetLastWin32Error());
        try {
            FileCaseSensitiveInfo information;
            if (!GetFileInformationByHandleEx(handle, 23, out information, (uint)Marshal.SizeOf(typeof(FileCaseSensitiveInfo))))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            return (information.Flags & 1) != 0;
        } finally { CloseHandle(handle); }
    }
}
'@
}

function Fail([string] $Reason) { throw "receipt_invalid: $Reason" }
function Assert-RedactedText([string] $Value, [string] $Label) {
    $sensitivePattern = '(?i)(\b[A-Z]:[\\/]|\\\\[^\\]+\\|(?<![A-Z0-9._:/-])/(?:[^/\s]+/)*[^/\s]*|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(?:api[_-]?key|access[_-]?token|refresh[_-]?token|token|secret|password|credential)\s*[:=]\s*\S|\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b|\b\+?\d[\d ()-]{8,}\d\b)'
    if ($Value -match $sensitivePattern) { Fail "$Label contains a local path, secret, or PII-like value" }
}

function Assert-PortableFilePathRedacted([string] $Value) {
    Assert-RedactedText $Value 'file path'
    foreach ($segment in $Value.Split('/')) {
        if ($segment -match '^(?i:logs?|transcripts?)(?:[-_.].*)?$' -or
            $segment -match '^(?i:transcript)(?:[-_.].*)?$' -or
            $segment -match '(?i)\.(?:log|transcript)(?:\.[^.]+)*$') {
            Fail 'file path identifies a transcript or log artifact'
        }
    }
}

function Normalize-PortablePath([string] $Value, [string] $Label) {
    if ([string]::IsNullOrWhiteSpace($Value)) { Fail "$Label is empty" }
    if ($Value -match '[\x00-\x1f\x7f?%#:]') { Fail "$Label contains a forbidden or ambiguous character" }
    if ($Value -match '[\p{Cc}]' -or $Value.Normalize([Text.NormalizationForm]::FormC) -cne $Value) { Fail "$Label is not canonical Unicode text" }
    if ($Value.Contains('/') -and $Value.Contains('\')) { Fail "$Label mixes path separators" }
    $normalized = $Value.Replace('\', '/')
    if ($normalized.StartsWith('/')) { Fail "$Label must be relative" }
    $segments = $normalized.Split('/')
    if ($segments.Count -lt 1) { Fail "$Label has no path segments" }
    foreach ($segment in $segments) {
        if ([string]::IsNullOrEmpty($segment) -or $segment -eq '.' -or $segment -eq '..' -or $segment.EndsWith('.') -or $segment.EndsWith(' ')) {
            Fail "$Label contains an empty, traversal, or ambiguous segment"
        }
    }
    return $normalized
}

function Get-FinalPath([string] $Path) {
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    if ($env:OS -eq 'Windows_NT') { $full = [O3ReceiptPathResolver]::Resolve($resolved.ProviderPath) }
    else { $full = $resolved.ProviderPath }
    $canonical = [IO.Path]::GetFullPath($full)
    $pathRoot = [IO.Path]::GetPathRoot($canonical)
    if ($canonical.Length -gt $pathRoot.Length) {
        $canonical = $canonical.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    }
    return $canonical
}

function Normalize-ScopePrefix([string] $Value) {
    if ($Value.StartsWith('external:', [StringComparison]::Ordinal)) {
        if ($Value -notmatch '^external:([A-Za-z][A-Za-z0-9_-]*)(?:/(.+))?$') { Fail 'external scope prefix must use external:<alias>[/<relative-path>]' }
        if ([string]::IsNullOrEmpty($Matches[2])) { return ('external:{0}' -f $Matches[1]) }
        return ('external:{0}/{1}' -f $Matches[1], (Normalize-PortablePath $Matches[2] 'external scope prefix'))
    }
    return Normalize-PortablePath $Value 'allowed path prefix'
}

function Test-Within([string] $Root, [string] $Target) {
    $rootCanonical = [IO.Path]::GetFullPath($Root)
    $targetCanonical = [IO.Path]::GetFullPath($Target)
    $rootVolume = [IO.Path]::GetPathRoot($rootCanonical)
    $targetVolume = [IO.Path]::GetPathRoot($targetCanonical)
    $volumeComparison = if ($env:OS -eq 'Windows_NT') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $rootVolume.Equals($targetVolume, $volumeComparison)) { return $false }

    $separators = [char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $rootRemainder = $rootCanonical.Substring($rootVolume.Length)
    $targetRemainder = $targetCanonical.Substring($targetVolume.Length)
    $rootSegments = @($rootRemainder.Split($separators, [StringSplitOptions]::RemoveEmptyEntries))
    $targetSegments = @($targetRemainder.Split($separators, [StringSplitOptions]::RemoveEmptyEntries))
    if ($rootSegments.Count -gt $targetSegments.Count) { return $false }

    # Compare each path component using the case rules of its parent directory.
    # This protects both normal paths and the final targets returned after
    # resolving symlinks/junctions; a Windows host can contain case-sensitive
    # directories even when the rest of its filesystem is case-insensitive.
    $current = $rootVolume
    for ($index = 0; $index -lt $rootSegments.Count; $index++) {
        $comparison = if (Test-DirectoryCaseSensitive $current) { [StringComparison]::Ordinal } else { [StringComparison]::OrdinalIgnoreCase }
        if (-not $rootSegments[$index].Equals($targetSegments[$index], $comparison)) { return $false }
        $current = Join-Path $current $rootSegments[$index]
    }
    return $true
}

function Test-DirectoryCaseSensitive([string] $Path) {
    if ($TestCaseSensitiveScope) { return $true }
    if ($env:OS -ne 'Windows_NT') { return $true }
    try { return [O3ReceiptPathResolver]::IsCaseSensitiveDirectory((Get-FinalPath $Path)) }
    catch {
        # If the filesystem cannot report its mode, use the stricter comparison.
        return $true
    }
}

function Test-ScopePrefix([string] $Canonical, [string] $Prefix, [string] $RootPath, [string] $RelativePath) {
    $canonicalExternal = $Canonical.StartsWith('external:', [StringComparison]::Ordinal)
    $prefixExternal = $Prefix.StartsWith('external:', [StringComparison]::Ordinal)
    if ($canonicalExternal -ne $prefixExternal) { return $false }

    $canonicalRelative = $RelativePath
    $prefixRelative = $Prefix
    if ($canonicalExternal) {
        $canonicalAlias = $Canonical.Substring(9).Split('/')[0]
        $prefixAlias = $Prefix.Substring(9).Split('/')[0]
        if (-not $canonicalAlias.Equals($prefixAlias, [StringComparison]::OrdinalIgnoreCase)) { return $false }
        if ($Prefix.Substring(9).Contains('/')) { $prefixRelative = $Prefix.Substring(9).Substring($Prefix.Substring(9).IndexOf('/') + 1) }
        else { return $true }
    }

    $pathSegments = $canonicalRelative.Split('/')
    $prefixSegments = $prefixRelative.Split('/')
    if ($prefixSegments.Count -gt $pathSegments.Count) { return $false }
    $current = Get-FinalPath $RootPath
    for ($index = 0; $index -lt $prefixSegments.Count; $index++) {
        $comparison = if (Test-DirectoryCaseSensitive $current) { [StringComparison]::Ordinal } else { [StringComparison]::OrdinalIgnoreCase }
        if (-not $pathSegments[$index].Equals($prefixSegments[$index], $comparison)) { return $false }
        if ($index -lt ($pathSegments.Count - 1)) {
            $next = Join-Path $current $pathSegments[$index]
            if (Test-Path -LiteralPath $next -PathType Container) { $current = Get-FinalPath $next }
        }
    }
    return $true
}

function Test-FullyQualifiedPath([string] $Value) {
    if ($env:OS -eq 'Windows_NT') {
        if ($Value -match '^[A-Za-z]:[\\/]') { return $true }
        if ($Value -match '^\\\\[^\\]+\\[^\\]+(?:\\|$)' -and $Value -notmatch '^\\\\[?.]\\') { return $true }
        return $false
    }
    return [IO.Path]::IsPathRooted($Value)
}

function Resolve-CheckedFile([string] $RootPath, [string] $RelativePath) {
    $root = Get-FinalPath $RootPath
    $current = $root
    $segments = $RelativePath.Split('/')
    for ($index = 0; $index -lt $segments.Count; $index++) {
        $current = Join-Path $current $segments[$index]
        if (-not (Test-Path -LiteralPath $current)) { Fail "file does not exist: $RelativePath" }
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        $final = Get-FinalPath $current
        if (-not (Test-Within $root $final)) { Fail "path escapes its authorized root: $RelativePath" }
        if ($index -lt ($segments.Count - 1) -and -not $item.PSIsContainer) { Fail "intermediate path component is not a directory: $RelativePath" }
        if ($index -eq ($segments.Count - 1) -and $item.PSIsContainer) { Fail "receipt path must identify a file: $RelativePath" }
        # Resolve-Path follows reparse points on the host filesystem. Check each
        # component so a junction/symlink cannot hide in an intermediate path.
    }
    return $current
}

if ($TestContainmentOnly) {
    if (-not $TestCaseSensitiveScope -or [string]::IsNullOrWhiteSpace($TestContainmentRoot) -or [string]::IsNullOrWhiteSpace($TestContainmentTarget)) {
        Fail 'containment test mode requires forced case sensitivity and both test paths'
    }
    if (Test-Within $TestContainmentRoot $TestContainmentTarget) {
        Write-Output 'containment: within'
        exit 0
    }
    Write-Output 'containment: outside'
    exit 3
}

if ($TestFinalPathOnly) {
    if ([string]::IsNullOrWhiteSpace($TestPath)) { Fail 'final path test mode requires a test path' }
    Write-Output ("final_path: {0}" -f (Get-FinalPath $TestPath))
    exit 0
}

try {
    $hasReceiptJson = $PSBoundParameters.ContainsKey('ReceiptJson')
    $hasReceiptJsonBase64 = $PSBoundParameters.ContainsKey('ReceiptJsonBase64')
    if ($hasReceiptJson -eq $hasReceiptJsonBase64) { Fail 'provide exactly one of ReceiptJson or ReceiptJsonBase64' }
    if ($hasReceiptJsonBase64) {
        try { $ReceiptJson = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($ReceiptJsonBase64)) }
        catch { Fail 'ReceiptJsonBase64 is not valid UTF-8 Base64 JSON input' }
    }
    $rootObject = Get-Content -LiteralPath $AuthorizedRootsPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $rootObject -or $rootObject -is [Array] -or $rootObject -is [string]) { Fail 'authorized roots must be a JSON object' }
    $AuthorizedExternalRoots = @{}
    foreach ($property in $rootObject.PSObject.Properties) {
        $authorizedRoot = [string]$property.Value
        if (-not (Test-FullyQualifiedPath $authorizedRoot)) { Fail "authorized root for alias '$($property.Name)' must be fully qualified" }
        $AuthorizedExternalRoots[$property.Name] = $authorizedRoot
    }
    $scopeJson = Get-Content -LiteralPath $AllowedPathPrefixesPath -Raw -Encoding UTF8
    $scopeValues = ConvertFrom-Json -InputObject $scopeJson -ErrorAction Stop
    $AllowedPathPrefixes = @()
    foreach ($scopeValue in $scopeValues) { $AllowedPathPrefixes += [string]$scopeValue }
    if ($AllowedPathPrefixes.Count -eq 0) { Fail 'coordinator scope must include at least one allowed path prefix' }
    $receipt = $ReceiptJson | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $receipt -or $receipt -is [Array] -or $receipt -is [string]) { Fail 'receipt must be a JSON object' }
    $keys = @($receipt.PSObject.Properties.Name)
    $required = @('planPath','step','status','files','testsSummary')
    $optional = @('nextStep','blockedReason')
    foreach ($key in $required) { if ($keys -notcontains $key) { Fail "missing field: $key" } }
    foreach ($key in $keys) { if (($required + $optional) -notcontains $key) { Fail "unknown field: $key" } }

    $repo = Get-FinalPath $RepoRoot
    $expectedPlan = Get-FinalPath $PlanPath
    if (-not (Test-Within $repo $expectedPlan)) { Fail 'expected PLAN is outside repository root' }
    $portablePlan = $expectedPlan.Substring($repo.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar).Replace('\','/')
    $receivedPlan = Normalize-PortablePath ([string]$receipt.planPath) 'planPath'
    if (-not $receivedPlan.Equals($portablePlan, [StringComparison]::OrdinalIgnoreCase)) { Fail 'planPath does not match the expected PLAN' }

    $receivedStep = $receipt.step
    if ($receivedStep -is [string] -and $receivedStep -match '^S([1-9][0-9]*)$') { $receivedStep = [int]$Matches[1] }
    if (($receivedStep -isnot [int] -and $receivedStep -isnot [long]) -or $receivedStep -ne $Step) { Fail 'step does not match the expected positive integer' }
    $receivedStatus = ([string]$receipt.status).Trim().ToLowerInvariant()
    switch ($receivedStatus) {
        { $_ -in @('done','complete','completed') } { $canonicalStatus = 'done'; break }
        'blocked' { $canonicalStatus = 'blocked'; break }
        'failed' { $canonicalStatus = 'failed'; break }
        default { Fail 'status is outside the relay allowlist' }
    }
    # PLAN rows use COMPLETED, while the relay outcome is done. Accept only the
    # two common semantic aliases at this boundary, then expose one canonical
    # vocabulary to downstream O3 reconciliation.
    $receipt.status = $canonicalStatus
    if ($receipt.files -isnot [Array]) { Fail 'files must be an array' }
    if ($receipt.testsSummary -isnot [string] -or $receipt.testsSummary.Length -gt 500 -or $receipt.testsSummary -match '[\r\n]') { Fail 'testsSummary must be one line of at most 500 characters' }
    if ($receipt.status -in @('blocked','failed')) {
        if (-not ($keys -contains 'blockedReason') -or [string]::IsNullOrWhiteSpace([string]$receipt.blockedReason) -or ([string]$receipt.blockedReason).Length -gt 300 -or ([string]$receipt.blockedReason) -match '[\r\n]') { Fail 'blocked/failed requires a bounded one-line blockedReason' }
    } elseif ($keys -contains 'blockedReason') { Fail 'done must omit blockedReason' }
    if ($receipt.status -eq 'done' -and [string]$receipt.testsSummary -notmatch '(?i)\bPASS\b|\b(deferred|skipped)\b') { Fail 'done requires PASS or an explicit deferred/skipped test summary' }
    if ($keys -contains 'nextStep' -and $receipt.nextStep -isnot [int] -and [string]$receipt.nextStep -notmatch '^[1-9][0-9]*$') { Fail 'nextStep must be a positive integer' }

    # Receipt text is data, never trusted instructions or a place for local paths,
    # credentials, or common PII forms.
    $textFields = @([string]$receipt.testsSummary)
    if ($keys -contains 'blockedReason') { $textFields += [string]$receipt.blockedReason }
    foreach ($text in $textFields) {
        Assert-RedactedText $text 'text field'
    }

    $prefixes = @($AllowedPathPrefixes | ForEach-Object { Normalize-ScopePrefix $_ })
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($raw in $receipt.files) {
        if ($raw -isnot [string]) { Fail 'files entries must be strings' }
        $path = [string]$raw
        # Check the raw entry before alias/path parsing so absolute POSIX paths
        # are rejected as local paths even when they are embedded in a receipt.
        Assert-RedactedText $path 'file path'
        $external = $false
        $alias = $null
        $relative = $null
        if ($path.StartsWith('external:', [StringComparison]::Ordinal)) {
            if ($path -notmatch '^external:([A-Za-z][A-Za-z0-9_-]*)/(.+)$') { Fail 'external path must use external:<alias>/<relative-path>' }
            $alias = $Matches[1]
            $relative = Normalize-PortablePath $Matches[2] 'external relative path'
            if (-not $AuthorizedExternalRoots.ContainsKey($alias)) { Fail "external alias is not authorized: $alias" }
            $external = $true
            $canonical = "external:$alias/$relative"
        } else {
            $relative = Normalize-PortablePath $path 'repository path'
            $canonical = $relative
        }
        Assert-PortableFilePathRedacted $canonical
        if (-not $seen.Add($canonical)) { Fail "duplicate file path: $canonical" }
        if ($external) { $rootPath = [string]$AuthorizedExternalRoots[$alias] } else { $rootPath = $repo }
        $inScope = $false
        foreach ($prefix in $prefixes) {
            if (Test-ScopePrefix -Canonical $canonical -Prefix $prefix -RootPath $rootPath -RelativePath $relative) { $inScope = $true; break }
        }
        if (-not $inScope) { Fail "file is outside coordinator scope: $canonical" }
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) { Fail "authorized root does not exist or is not a directory: $alias" }
        [void](Resolve-CheckedFile -RootPath $rootPath -RelativePath $relative)
    }
    $canonicalReceiptJson = ConvertTo-Json -InputObject $receipt -Depth 8 -Compress
    Write-Output 'receipt_validation: PASS'
    Write-Output ("canonical_receipt: {0}" -f $canonicalReceiptJson)
    exit 0
} catch {
    Write-Output $_.Exception.Message
    exit 2
}
