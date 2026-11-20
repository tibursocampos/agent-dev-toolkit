#Requires -Version 5.1
<#
.SYNOPSIS
  Resolve one canonical SDD artifact against the active repository's manifest.
.DESCRIPTION
  Read-only path resolution. SddRoot is the already resolved effective SDD
  root, which can be distinct from the packaged skills root. The result's
  AbsolutePath is local to the caller. Only Envelope may cross a handoff.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][AllowEmptyString()][string] $PortablePath,
    [Parameter(Mandatory)][string] $RepoRoot,
    [Parameter(Mandatory)][string] $SddRoot,
    [ValidateSet('classic', 'delivery')][string] $Layout = 'classic'
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) '_lib/Resolve-InstallRoot.ps1')

function Reject-ArtifactPath {
    param([string] $Reason, [string] $Message)
    [PSCustomObject]@{ Ok = $false; Reason = $Reason; Message = $Message; Envelope = $null }
}

function Test-DescendantPath {
    param([string] $Path, [string] $Root)
    $prefix = $Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    return $Path.StartsWith($prefix, $pathComparison)
}

$normalized = $PortablePath.Trim().Replace('\', '/')
if (-not $normalized) {
    return Reject-ArtifactPath 'empty_path' 'Provide a portable artifact path.'
}
if ($normalized.StartsWith('/') -or $normalized -match '^[A-Za-z]:') {
    return Reject-ArtifactPath 'absolute_path_forbidden' 'Use a portable path, without an OS root or drive.'
}
$segments = $normalized.Split('/')
if ($segments -contains '..') {
    return Reject-ArtifactPath 'path_traversal' 'Parent traversal is forbidden in portable paths.'
}
if ($segments -contains '.' -or $segments -contains '' -or
    $normalized -match '[\x00-\x1f:<>|?*"]' -or
    @($segments | Where-Object { $_ -match '[ .]$' }).Count -gt 0) {
    return Reject-ArtifactPath 'invalid_portable_path' 'Use normalized path segments with no aliases, invalid characters, or trailing spaces or dots.'
}

$pathComparison = if (Test-ToolkitIsWindowsPlatform) {
    [StringComparison]::OrdinalIgnoreCase
} else {
    [StringComparison]::Ordinal
}

try {
    $repoRootFull = [IO.Path]::GetFullPath($RepoRoot)
    $sddRootFull = [IO.Path]::GetFullPath($SddRoot)
    $manifestPath = Join-Path $sddRootFull 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        return Reject-ArtifactPath 'storage_manifest_missing' 'The effective SDD manifest is missing.'
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    return Reject-ArtifactPath 'storage_manifest_invalid' 'Could not resolve the roots or read the effective SDD manifest.'
}
if ($manifest -isnot [PSCustomObject] -or
    -not $manifest.PSObject.Properties['schema_version'] -or $manifest.schema_version -notin 1, 2 -or
    -not $manifest.PSObject.Properties['repositories'] -or $manifest.repositories -isnot [PSCustomObject]) {
    return Reject-ArtifactPath 'storage_manifest_invalid' 'The manifest needs a supported schema and a repositories object.'
}

$repoKey = $repoRootFull.Replace('\', '/').TrimEnd('/')
$repositoryEntry = @($manifest.repositories.PSObject.Properties | Where-Object {
    [string]::Equals($_.Name.Replace('\', '/').TrimEnd('/'), $repoKey, $pathComparison)
})
if ($repositoryEntry.Count -eq 0) {
    return Reject-ArtifactPath 'storage_entry_missing' 'The active repository has no manifest entry.'
}
if ($repositoryEntry.Count -ne 1) {
    return Reject-ArtifactPath 'storage_manifest_invalid' 'The active repository has duplicate manifest entries.'
}
$entry = $repositoryEntry[0].Value
if ($entry -isnot [PSCustomObject]) {
    return Reject-ArtifactPath 'storage_manifest_invalid' 'The selected repository entry must be an object.'
}
$classic = if ($entry.PSObject.Properties['classic']) { $entry.classic } else { $entry }
if ($classic -isnot [PSCustomObject]) {
    return Reject-ArtifactPath 'storage_manifest_invalid' 'The selected Classic storage entry must be an object.'
}
$featuresVersioned = $false
if ($classic.PSObject.Properties['features_versioned']) {
    if ($classic.features_versioned -isnot [bool]) {
        return Reject-ArtifactPath 'storage_manifest_invalid' 'features_versioned must be a boolean when provided.'
    }
    $featuresVersioned = $classic.features_versioned
}
if (-not $classic.PSObject.Properties['storage_mode']) {
    return Reject-ArtifactPath 'storage_manifest_invalid' 'The selected Classic storage entry is missing storage_mode.'
}

$mode = [string]$classic.storage_mode
$configuredPath = if ($classic.PSObject.Properties['path']) { [string]$classic.path } else { '' }
try {
    if ($mode -eq 'repository') {
        if ($configuredPath -and -not [string]::Equals([IO.Path]::GetFullPath($configuredPath).TrimEnd('\', '/'), $repoRootFull.TrimEnd('\', '/'), $pathComparison)) {
            return Reject-ArtifactPath 'storage_path_mismatch' 'Repository storage must match the active repository.'
        }
        $authorityRoot = $repoRootFull
        $portablePrefix = 'features/'
    } elseif ($mode -eq 'global') {
        if (-not $configuredPath.Trim()) {
            return Reject-ArtifactPath 'storage_path_invalid' 'Global storage requires classic.path.'
        }
        $configuredPath = $configuredPath.Replace('{{SDD_ROOT}}', $sddRootFull)
        if (-not [IO.Path]::IsPathRooted($configuredPath)) {
            $configuredPath = Join-Path $sddRootFull $configuredPath
        }
        $authorityRoot = [IO.Path]::GetFullPath($configuredPath).TrimEnd('\', '/')
        if (-not (Test-DescendantPath $authorityRoot $sddRootFull) -or
            -not (Test-DescendantPath (Resolve-ReparsePointTarget $authorityRoot) (Resolve-ReparsePointTarget $sddRootFull))) {
            return Reject-ArtifactPath 'storage_path_outside_sdd_root' 'Global storage must stay inside the effective SDD root.'
        }
        $relativeRoot = $authorityRoot.Substring($sddRootFull.TrimEnd('\', '/').Length + 1).Replace('\', '/')
        $portablePrefix = "sdd/$relativeRoot/features/"
    } else {
        return Reject-ArtifactPath 'storage_mode_unsupported' 'Use repository or global storage.'
    }
    $featureRoot = Join-Path $authorityRoot 'features'
} catch {
    return Reject-ArtifactPath 'storage_path_invalid' 'The manifest-selected feature root could not be resolved.'
}
if (-not $normalized.StartsWith($portablePrefix, $pathComparison)) {
    return Reject-ArtifactPath 'outside_features' 'The path does not match the manifest-selected feature root.'
}

$relativePath = $normalized.Substring($portablePrefix.Length)
$parts = $relativePath.Split('/')
$featureSlug = $parts[0]
if ($featureSlug -notmatch '^\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*$') {
    return Reject-ArtifactPath 'invalid_portable_path' 'The feature folder must match NNN-slug.'
}

$storyId = $null
$fileName = $parts[-1]
$kind = if ($Layout -eq 'delivery') {
    if ($relativePath -match '^[^/]+/(?:plans/[a-z0-9]+(?:-[a-z0-9]+)*/)?PLAN\.md$') {
        'PLAN'
    }
} elseif ($relativePath -match '^[^/]+/FEATURE\.md$') {
    'FEATURE'
} elseif ($relativePath -match '^[^/]+/((?:US|TS)\d{2}|Bug)/STORY\.md$') {
    $storyId = if ($Matches[1] -eq 'Bug') { 'Bug' } else { $Matches[1].ToUpperInvariant() }
    'STORY'
} elseif ($relativePath -match '^[^/]+/((?:US|TS)\d{2})/PRD/[^/]+\.md$') {
    $storyId = $Matches[1].ToUpperInvariant()
    'PRD'
} elseif ($relativePath -match '^[^/]+/((?:US|TS)\d{2})/PLAN/PLAN_[^/]+\.md$') {
    $storyId = $Matches[1].ToUpperInvariant()
    'PLAN'
}
if (-not $kind) {
    return Reject-ArtifactPath 'unsupported_kind' 'The path is not a canonical artifact of the selected layout.'
}

$absolute = Join-Path $featureRoot ($relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
try {
    $resolvedRoot = Resolve-ReparsePointTarget $featureRoot
    if (-not (Test-DescendantPath $resolvedRoot (Resolve-ReparsePointTarget $authorityRoot))) {
        return Reject-ArtifactPath 'outside_features' 'The feature root resolves outside the manifest-selected storage.'
    }
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        return Reject-ArtifactPath 'not_found' 'The canonical artifact is absent from the manifest-selected feature root.'
    }
    $resolvedArtifact = Resolve-ReparsePointTarget $absolute
    $selectedFeature = Join-Path $resolvedRoot $featureSlug
    if (-not (Test-DescendantPath $resolvedArtifact $selectedFeature)) {
        return Reject-ArtifactPath 'outside_features' 'The resolved artifact leaves the selected feature directory.'
    }
} catch {
    return Reject-ArtifactPath 'invalid_portable_path' 'The artifact path could not be resolved safely.'
}

[PSCustomObject]@{
    Ok = $true
    Reason = $null
    Message = $null
    Envelope = [PSCustomObject][ordered]@{
        schema = 'RSA-SOURCE-CONTEXT/v1'
        artifact_kind = $kind
        portable_path = $normalized
        identity = [PSCustomObject][ordered]@{
            feature_slug = $featureSlug
            story_id = $storyId
            file_name = $fileName
        }
    }
    AbsolutePath = $resolvedArtifact
    Storage = [PSCustomObject]@{
        StorageMode = $mode
        FeaturesVersioned = $featuresVersioned
        FeatureRoot = $featureRoot
    }
}
