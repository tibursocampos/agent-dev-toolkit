#Requires -Version 5.1
# Tests:
#   Should_Pass_When_SkillAndCatalogPresent (RNF-003)
#   Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory (CT2 / REQ-004)
#   Should_Reject_When_PathTraversalOrOutsideFeatures (CT3 / REQ-005 / RNF-001)
#   Should_ResolveManifestStorageModesAndIgnoredFiles (CT13 / REQ-012)
#   Should_SelectGlobalClassicPathAndRejectLocalDecoys (CT13 / REQ-012)
#   Should_KeepInvocationContextDespiteSiblingDecoys (CT19 / REQ-013)
#   Should_Document_SkipReread_When_SourceContextPresent (REQ-005)
#
# Deterministic path guard + source_context envelope for read-sdd-artifact.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

$script:ReasonEmptyPath = 'empty_path'
$script:ReasonAbsoluteForbidden = 'absolute_path_forbidden'
$script:ReasonPathTraversal = 'path_traversal'
$script:ReasonOutsideFeatures = 'outside_features'
$script:ReasonUnsupportedKind = 'unsupported_kind'
$script:ReasonNotFound = 'not_found'
$script:ReasonInvalidPortable = 'invalid_portable_path'

$script:SchemaId = 'RSA-SOURCE-CONTEXT/v1'
$script:RuleId = 'RSA-SOURCE-CONTEXT'
$script:SkillId = 'read-sdd-artifact'
$script:FeaturesSegment = 'features/'
$script:KindFeature = 'FEATURE'
$script:KindStory = 'STORY'
$script:KindPrd = 'PRD'
$script:KindPlan = 'PLAN'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

function ConvertTo-ForwardSlashPath {
    param([Parameter(Mandatory = $true)][string] $PathText)
    return (($PathText -replace '\\', '/').Trim())
}

function Resolve-ClassicStorageContext {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $SddRoot,
        [Parameter(Mandatory = $true)][string] $ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return [PSCustomObject]@{ Ok = $false; Reason = 'storage_manifest_missing'; Message = 'The effective SDD manifest is missing.' }
    }

    try {
        $manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        return [PSCustomObject]@{ Ok = $false; Reason = 'storage_manifest_invalid'; Message = 'The effective SDD manifest is invalid JSON.' }
    }

    if ($manifest.schema_version -ne 2 -or $null -eq $manifest.repositories) {
        return [PSCustomObject]@{ Ok = $false; Reason = 'storage_manifest_invalid'; Message = 'The manifest must use schema_version 2.' }
    }

    $repoKey = (ConvertTo-ForwardSlashPath -PathText ([IO.Path]::GetFullPath($RepoRoot))).TrimEnd('/')
    $repositoryEntry = $null
    foreach ($property in $manifest.repositories.PSObject.Properties) {
        $candidate = (ConvertTo-ForwardSlashPath -PathText ([string]$property.Name)).TrimEnd('/')
        if ([string]::Equals($candidate, $repoKey, [StringComparison]::OrdinalIgnoreCase)) {
            $repositoryEntry = $property.Value
            break
        }
    }
    if ($null -eq $repositoryEntry -or $null -eq $repositoryEntry.classic) {
        return [PSCustomObject]@{ Ok = $false; Reason = 'storage_entry_missing'; Message = 'No classic manifest entry exists for the active repository.' }
    }

    $classic = $repositoryEntry.classic
    $mode = [string]$classic.storage_mode
    if ($null -ne $classic.features_versioned -and $classic.features_versioned -isnot [bool]) {
        return [PSCustomObject]@{ Ok = $false; Reason = 'storage_manifest_invalid'; Message = 'classic.features_versioned must be a boolean when present.' }
    }
    $featuresVersioned = if ($null -eq $classic.features_versioned) { $false } else { [bool]$classic.features_versioned }
    $sddRootFull = [IO.Path]::GetFullPath($SddRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)

    if ($mode -eq 'repository') {
        $repoRootFull = [IO.Path]::GetFullPath($RepoRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        if (-not [string]::IsNullOrWhiteSpace([string]$classic.path)) {
            $configuredRepoPath = [IO.Path]::GetFullPath([string]$classic.path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
            if (-not [string]::Equals($configuredRepoPath, $repoRootFull, [StringComparison]::OrdinalIgnoreCase)) {
                return [PSCustomObject]@{ Ok = $false; Reason = 'storage_path_mismatch'; Message = 'Repository classic.path does not match the active repository.' }
            }
        }
        $featureRoot = Join-Path $repoRootFull 'features'
        $portablePrefix = 'features/'
    }
    elseif ($mode -eq 'global') {
        $configuredPath = [string]$classic.path
        if ([string]::IsNullOrWhiteSpace($configuredPath)) {
            return [PSCustomObject]@{ Ok = $false; Reason = 'storage_path_invalid'; Message = 'Global classic.path is required.' }
        }
        if ($configuredPath.Contains('{{SDD_ROOT}}')) {
            $configuredPath = $configuredPath.Replace('{{SDD_ROOT}}', $sddRootFull)
        }
        if (-not [IO.Path]::IsPathRooted($configuredPath)) {
            $configuredPath = Join-Path $sddRootFull $configuredPath
        }
        $classicRoot = [IO.Path]::GetFullPath($configuredPath).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $sddRootPrefix = $sddRootFull + [IO.Path]::DirectorySeparatorChar
        if (-not $classicRoot.StartsWith($sddRootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            return [PSCustomObject]@{ Ok = $false; Reason = 'storage_path_outside_sdd_root'; Message = 'Global classic.path must resolve below effective_SDD_ROOT.' }
        }
        $relativeClassicRoot = $classicRoot.Substring($sddRootPrefix.Length).Replace([IO.Path]::DirectorySeparatorChar, '/').Replace([IO.Path]::AltDirectorySeparatorChar, '/')
        $featureRoot = Join-Path $classicRoot 'features'
        $portablePrefix = 'sdd/' + $relativeClassicRoot + '/features/'
    }
    else {
        return [PSCustomObject]@{ Ok = $false; Reason = 'storage_mode_unsupported'; Message = 'classic.storage_mode must be repository or global.' }
    }

    return [PSCustomObject]@{
        Ok                 = $true
        Reason             = $null
        Message            = $null
        StorageMode        = $mode
        FeaturesVersioned  = $featuresVersioned
        FeatureRoot        = $featureRoot
        PortablePrefix     = $portablePrefix
    }
}

function Resolve-SddSourceContext {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $PortablePath,
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $SddRoot,
        [Parameter(Mandatory = $true)][string] $ManifestPath
    )

    $trimmed = if ($null -eq $PortablePath) { '' } else { $PortablePath.Trim() }
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return [PSCustomObject]@{ Ok = $false; Reason = $script:ReasonEmptyPath; Message = 'Path is empty.'; Envelope = $null }
    }

    $normalized = ConvertTo-ForwardSlashPath -PathText $trimmed
    if ($normalized -match '^[A-Za-z]:/' -or $normalized.StartsWith('//') -or $normalized -match '(?i)(/Users/|/home/|\\\\Users\\\\)') {
        return [PSCustomObject]@{ Ok = $false; Reason = $script:ReasonAbsoluteForbidden; Message = 'OS absolute or user-home path is forbidden; use a portable path.'; Envelope = $null }
    }
    if (@($normalized.Split('/') | Where-Object { $_ -ne '' }) -contains '..') {
        return [PSCustomObject]@{ Ok = $false; Reason = $script:ReasonPathTraversal; Message = 'Path contains ".."; traversal is rejected.'; Envelope = $null }
    }

    $storage = Resolve-ClassicStorageContext -RepoRoot $RepoRoot -SddRoot $SddRoot -ManifestPath $ManifestPath
    if (-not $storage.Ok) {
        return [PSCustomObject]@{ Ok = $false; Reason = $storage.Reason; Message = $storage.Message; Envelope = $null }
    }
    if (-not $normalized.StartsWith($storage.PortablePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        return [PSCustomObject]@{ Ok = $false; Reason = $script:ReasonOutsideFeatures; Message = 'Path prefix does not match the manifest-selected feature root.'; Envelope = $null }
    }

    $featuresSuffix = 'features/' + $normalized.Substring($storage.PortablePrefix.Length)
    $kind = $null
    $featureSlug = $null
    $storyId = $null
    $fileName = $null

    if ($featuresSuffix -match '^(?i)features/([^/]+)/FEATURE\.md$') {
        $kind = $script:KindFeature; $featureSlug = $Matches[1]; $fileName = 'FEATURE.md'
    }
    elseif ($featuresSuffix -match '^(?i)features/([^/]+)/((?:US|TS)\d{2})/STORY\.md$') {
        $kind = $script:KindStory; $featureSlug = $Matches[1]; $storyId = $Matches[2].ToUpperInvariant(); $fileName = 'STORY.md'
    }
    elseif ($featuresSuffix -match '^(?i)features/([^/]+)/((?:US|TS)\d{2})/PRD/([^/]+\.md)$') {
        $kind = $script:KindPrd; $featureSlug = $Matches[1]; $storyId = $Matches[2].ToUpperInvariant(); $fileName = $Matches[3]
    }
    elseif ($featuresSuffix -match '^(?i)features/([^/]+)/((?:US|TS)\d{2})/PLAN/(PLAN_[^/]+\.md)$') {
        $kind = $script:KindPlan; $featureSlug = $Matches[1]; $storyId = $Matches[2].ToUpperInvariant(); $fileName = $Matches[3]
    }
    else {
        return [PSCustomObject]@{ Ok = $false; Reason = $script:ReasonUnsupportedKind; Message = 'Path is not a canonical FEATURE/STORY/PRD/PLAN under features/.'; Envelope = $null }
    }

    if ($featureSlug -notmatch '^\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*$') {
        return [PSCustomObject]@{ Ok = $false; Reason = $script:ReasonInvalidPortable; Message = 'Feature folder must match NNN-slug.'; Envelope = $null }
    }

    $relativeFs = ($featuresSuffix.Substring('features/'.Length) -replace '/', [IO.Path]::DirectorySeparatorChar)
    $absolute = Join-Path $storage.FeatureRoot $relativeFs
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        return [PSCustomObject]@{ Ok = $false; Reason = $script:ReasonNotFound; Message = ("File not found at manifest-selected portable path '{0}'." -f $normalized); Envelope = $null }
    }

    $identity = [ordered]@{ feature_slug = $featureSlug; story_id = $storyId; file_name = $fileName }
    $envelope = [ordered]@{ schema = $script:SchemaId; artifact_kind = $kind; portable_path = $normalized; identity = [PSCustomObject]$identity }
    return [PSCustomObject]@{ Ok = $true; Reason = $null; Message = $null; Envelope = [PSCustomObject]$envelope; AbsolutePath = $absolute; Storage = $storage }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-ReadSddArtifactPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-ReadSddArtifactPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('Assert-ReadSddArtifact-' + [guid]::NewGuid().ToString('N'))
$fixtureRepoRoot = Join-Path $fixtureRoot 'repo'
$fixtureSddRoot = Join-Path $fixtureRoot 'install/sdd'
$fixtureManifestPath = Join-Path $fixtureSddRoot 'manifest.json'
New-Item -ItemType Directory -Path $fixtureRepoRoot -Force | Out-Null
New-Item -ItemType Directory -Path $fixtureSddRoot -Force | Out-Null

function Write-FixtureManifest {
    param(
        [Parameter(Mandatory = $true)][string] $RepoPath,
        [Parameter(Mandatory = $true)][string] $StorageMode,
        [Parameter(Mandatory = $true)][bool] $FeaturesVersioned,
        [string] $ClassicPath
    )
    $repoKey = (ConvertTo-ForwardSlashPath -PathText ([IO.Path]::GetFullPath($RepoPath))).TrimEnd('/')
    $classic = [ordered]@{ storage_mode = $StorageMode; features_versioned = $FeaturesVersioned }
    if ($ClassicPath) { $classic.path = $ClassicPath }
    $manifest = [ordered]@{ schema_version = 2; repositories = [ordered]@{} }
    $manifest.repositories[$repoKey] = [ordered]@{ classic = $classic }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $fixtureManifestPath -Encoding UTF8
}

function Resolve-FixtureInvocationContext {
    param([string] $ExplicitContext, [string] $ExecutionSource)
    if ($ExplicitContext -in @('direct', 'orchestrated')) { return $ExplicitContext }
    if ($ExecutionSource -in @('orchestrate-skill', 'orchestrated-task-child')) { return 'orchestrated' }
    return 'direct'
}

function Assert-FixtureRead {
    param([string] $Path, [string] $ExpectedBody, [string] $TestName)
    $result = Resolve-SddSourceContext -PortablePath $Path -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -ManifestPath $fixtureManifestPath
    if (-not $result.Ok -or -not (Test-Path -LiteralPath $result.AbsolutePath -PathType Leaf)) {
        Write-Fail -TestName $TestName -Reason ("resolution failed for {0}: {1}" -f $Path, $result.Reason)
    }
    $body = Get-Content -LiteralPath $result.AbsolutePath -Raw -Encoding UTF8
    if ($body -ne $ExpectedBody) {
        Write-Fail -TestName $TestName -Reason ("unexpected source body for {0}" -f $Path)
    }
    return $result
}

$fixturePaths = @(
    @{ Path = 'features/006-skills-maturity-parity/FEATURE.md'; Body = 'repository feature' },
    @{ Path = 'features/006-skills-maturity-parity/US01/STORY.md'; Body = 'repository story' },
    @{ Path = 'features/006-skills-maturity-parity/US01/PRD/006_sdd_invocation_contracts.md'; Body = 'repository PRD' },
    @{ Path = 'features/006-skills-maturity-parity/US01/PLAN/PLAN_006_sdd_invocation_contracts.md'; Body = 'repository PLAN' }
)
foreach ($fixture in $fixturePaths) {
    $fixtureFile = Join-Path $fixtureRepoRoot ($fixture.Path -replace '/', [IO.Path]::DirectorySeparatorChar)
    New-Item -ItemType Directory -Path (Split-Path -Parent $fixtureFile) -Force | Out-Null
    Set-Content -LiteralPath $fixtureFile -Value $fixture.Body -NoNewline -Encoding UTF8
}
$fixtureGitIgnore = Join-Path $fixtureRepoRoot '.gitignore'
Set-Content -LiteralPath $fixtureGitIgnore -Value '/features/' -Encoding UTF8
& git -C $fixtureRepoRoot init --quiet
if ($LASTEXITCODE -ne 0) { Write-Fail -TestName 'Assert-ReadSddArtifactStorageFixtures' -Reason 'Could not initialize temporary repository fixture.' }
Write-FixtureManifest -RepoPath $fixtureRepoRoot -StorageMode 'repository' -FeaturesVersioned $false -ClassicPath $fixtureRepoRoot

$skillRel = "core/skills/$($script:SkillId)/SKILL.md"
$skillPath = Join-Path $repoRoot ($skillRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$catalogRel = 'core/skills/_shared/skills-catalog/CATALOG.md'
$catalogPath = Join-Path $repoRoot ($catalogRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$skillsMdRel = 'docs/SKILLS.md'
$skillsMdPath = Join-Path $repoRoot ($skillsMdRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

# --- Should_Pass_When_SkillAndCatalogPresent ---
if (-not (Test-Path -LiteralPath $skillPath)) {
    Write-Fail -TestName 'Should_Pass_When_SkillAndCatalogPresent' -Reason ("missing {0}" -f $skillRel)
}
$skillText = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
$requiredSkillMarkers = @(
    $script:RuleId,
    'source_context',
    'path_traversal',
    'outside_features',
    '## Lazy-load',
    '**Never by default:**'
)
foreach ($marker in $requiredSkillMarkers) {
    if ($skillText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_SkillAndCatalogPresent' -Reason ("SKILL.md missing marker '{0}'" -f $marker)
    }
}
if ($skillText -notmatch '(?i)skip') {
    Write-Fail -TestName 'Should_Pass_When_SkillAndCatalogPresent' -Reason 'SKILL.md must document skip re-read consumption'
}

if (-not (Test-Path -LiteralPath $catalogPath)) {
    Write-Fail -TestName 'Should_Pass_When_SkillAndCatalogPresent' -Reason ("missing {0}" -f $catalogRel)
}
$catalogText = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8
if ($catalogText -notmatch [regex]::Escape("``$($script:SkillId)``") -and $catalogText -notmatch [regex]::Escape($script:SkillId)) {
    Write-Fail -TestName 'Should_Pass_When_SkillAndCatalogPresent' -Reason ("CATALOG.md must list {0}" -f $script:SkillId)
}
if (-not (Test-Path -LiteralPath $skillsMdPath)) {
    Write-Fail -TestName 'Should_Pass_When_SkillAndCatalogPresent' -Reason ("missing {0}" -f $skillsMdRel)
}
$skillsMdText = Get-Content -LiteralPath $skillsMdPath -Raw -Encoding UTF8
if ($skillsMdText -notmatch [regex]::Escape("``$($script:SkillId)``") -and $skillsMdText -notmatch [regex]::Escape($script:SkillId)) {
    Write-Fail -TestName 'Should_Pass_When_SkillAndCatalogPresent' -Reason ("docs/SKILLS.md must list {0}" -f $script:SkillId)
}
Write-Pass -TestName 'Should_Pass_When_SkillAndCatalogPresent'

# --- Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory (CT2) ---
$happyPaths = @(
    @{ Path = 'features/006-skills-maturity-parity/FEATURE.md'; Kind = $script:KindFeature; Story = $null },
    @{ Path = 'features/006-skills-maturity-parity/US01/STORY.md'; Kind = $script:KindStory; Story = 'US01' },
    @{ Path = 'features/006-skills-maturity-parity/US01/PRD/006_sdd_invocation_contracts.md'; Kind = $script:KindPrd; Story = 'US01' },
    @{ Path = 'features/006-skills-maturity-parity/US01/PLAN/PLAN_006_sdd_invocation_contracts.md'; Kind = $script:KindPlan; Story = 'US01' }
)

foreach ($case in $happyPaths) {
    $result = Resolve-SddSourceContext -PortablePath $case.Path -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -ManifestPath $fixtureManifestPath
    if (-not $result.Ok) {
        Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason ("expected ok for {0}: {1}" -f $case.Path, $result.Reason)
    }
    if ($null -eq $result.Envelope) {
        Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason ("missing envelope for {0}" -f $case.Path)
    }
    if ($result.Envelope.schema -ne $script:SchemaId) {
        Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason 'schema mismatch'
    }
    if ($result.Envelope.artifact_kind -ne $case.Kind) {
        Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason ("kind for {0}: got {1}" -f $case.Path, $result.Envelope.artifact_kind)
    }
    if ($result.Envelope.portable_path -ne $case.Path) {
        Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason ("portable_path drift for {0}" -f $case.Path)
    }
    if ($result.Envelope.identity.feature_slug -ne '006-skills-maturity-parity') {
        Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason 'feature_slug mismatch'
    }
    $actualStory = $result.Envelope.identity.story_id
    if ($case.Story) {
        if ($actualStory -ne $case.Story) {
            Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason ("story_id for {0}" -f $case.Path)
        }
    }
    else {
        if ($null -ne $actualStory -and $actualStory -ne '') {
            Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason 'FEATURE story_id must be null'
        }
    }
    if ([string]::IsNullOrWhiteSpace([string]$result.Envelope.identity.file_name)) {
        Write-Fail -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory' -Reason 'file_name required'
    }
}
Write-Pass -TestName 'Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory'

# --- Should_Reject_When_PathTraversalOrOutsideFeatures (CT3) ---
$failCases = @(
    @{ Path = 'features/006-skills-maturity-parity/../US01/PRD/x.md'; Reason = $script:ReasonPathTraversal },
    @{ Path = 'features/006-skills-maturity-parity/US01/PRD/../../SECRET.md'; Reason = $script:ReasonPathTraversal },
    @{ Path = 'memory-bank/architecture.md'; Reason = $script:ReasonOutsideFeatures },
    @{ Path = 'core/skills/sdd-spec/SKILL.md'; Reason = $script:ReasonOutsideFeatures },
    @{ Path = 'myfeatures/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonOutsideFeatures },
    @{ Path = 'nonfeatures/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonOutsideFeatures },
    @{ Path = 'E:/Nextcloud/Repos/agent-dev-toolkit/features/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonAbsoluteForbidden },
    @{ Path = 'features/006-skills-maturity-parity/US01/ANALYSIS/impact.md'; Reason = $script:ReasonUnsupportedKind },
    @{ Path = ''; Reason = $script:ReasonEmptyPath },
    @{ Path = 'features/006-skills-maturity-parity/US01/PRD/__missing_fixture__.md'; Reason = $script:ReasonNotFound }
)

foreach ($case in $failCases) {
    $result = Resolve-SddSourceContext -PortablePath $case.Path -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -ManifestPath $fixtureManifestPath
    if ($result.Ok) {
        Write-Fail -TestName 'Should_Reject_When_PathTraversalOrOutsideFeatures' -Reason ("expected fail for '{0}'" -f $case.Path)
    }
    if ($null -ne $result.Envelope) {
        Write-Fail -TestName 'Should_Reject_When_PathTraversalOrOutsideFeatures' -Reason ("partial envelope on fail for '{0}'" -f $case.Path)
    }
    if ($result.Reason -ne $case.Reason) {
        Write-Fail -TestName 'Should_Reject_When_PathTraversalOrOutsideFeatures' -Reason ("path '{0}' expected {1} got {2}" -f $case.Path, $case.Reason, $result.Reason)
    }
    if ([string]::IsNullOrWhiteSpace([string]$result.Message)) {
        Write-Fail -TestName 'Should_Reject_When_PathTraversalOrOutsideFeatures' -Reason ("missing precise message for {0}" -f $case.Reason)
    }
}
Write-Pass -TestName 'Should_Reject_When_PathTraversalOrOutsideFeatures'

# --- Should_ResolveManifestStorageModesAndIgnoredFiles (CT13) ---
$ignoredPath = 'features/006-skills-maturity-parity/US01/PRD/006_sdd_invocation_contracts.md'
& git -C $fixtureRepoRoot check-ignore -q -- ($ignoredPath -replace '/', [IO.Path]::DirectorySeparatorChar)
if ($LASTEXITCODE -ne 0) {
    Write-Fail -TestName 'Should_ResolveManifestStorageModesAndIgnoredFiles' -Reason 'repository fixture PRD is expected to be Git-ignored when features_versioned=false'
}
$unversionedRead = Assert-FixtureRead -Path $ignoredPath -ExpectedBody 'repository PRD' -TestName 'Should_ResolveManifestStorageModesAndIgnoredFiles'
if ($unversionedRead.Storage.StorageMode -ne 'repository' -or $unversionedRead.Storage.FeaturesVersioned -ne $false) {
    Write-Fail -TestName 'Should_ResolveManifestStorageModesAndIgnoredFiles' -Reason 'repository false manifest state was not retained'
}
$versionedFeatureRoot = $unversionedRead.Storage.FeatureRoot
Set-Content -LiteralPath $fixtureGitIgnore -Value '# no features ignore rule' -Encoding UTF8
Write-FixtureManifest -RepoPath $fixtureRepoRoot -StorageMode 'repository' -FeaturesVersioned $true -ClassicPath $fixtureRepoRoot
$versionedRead = Assert-FixtureRead -Path $ignoredPath -ExpectedBody 'repository PRD' -TestName 'Should_ResolveManifestStorageModesAndIgnoredFiles'
if ($versionedRead.Storage.FeatureRoot -ne $versionedFeatureRoot) {
    Write-Fail -TestName 'Should_ResolveManifestStorageModesAndIgnoredFiles' -Reason 'features_versioned changed the repository feature root'
}
if ((Get-Content -LiteralPath $fixtureGitIgnore -Raw) -match '(?m)^/?(?:docs/)?features/?$') {
    Write-Fail -TestName 'Should_ResolveManifestStorageModesAndIgnoredFiles' -Reason 'features_versioned=true fixture still ignores the features tree'
}
Write-Pass -TestName 'Should_ResolveManifestStorageModesAndIgnoredFiles'

# --- Should_SelectGlobalClassicPathAndRejectLocalDecoys (CT13) ---
$globalClassicRoot = Join-Path $fixtureSddRoot 'RepoFixture'
$globalRelativePath = 'features/006-skills-maturity-parity/US01/PRD/006_sdd_invocation_contracts.md'
$globalFile = Join-Path $globalClassicRoot ($globalRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
New-Item -ItemType Directory -Path (Split-Path -Parent $globalFile) -Force | Out-Null
Set-Content -LiteralPath $globalFile -Value 'global authority' -NoNewline -Encoding UTF8
$localDecoy = Join-Path $fixtureRepoRoot ($globalRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
Set-Content -LiteralPath $localDecoy -Value 'local decoy' -NoNewline -Encoding UTF8
Write-FixtureManifest -RepoPath $fixtureRepoRoot -StorageMode 'global' -FeaturesVersioned $false -ClassicPath $globalClassicRoot
$ignoreHashBefore = (Get-FileHash -LiteralPath $fixtureGitIgnore -Algorithm SHA256).Hash
$globalPortablePath = 'sdd/RepoFixture/' + $globalRelativePath
$globalRead = Assert-FixtureRead -Path $globalPortablePath -ExpectedBody 'global authority' -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys'
if ($globalRead.Storage.FeatureRoot -ne (Join-Path $globalClassicRoot 'features')) {
    Write-Fail -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys' -Reason 'global feature root did not follow classic.path'
}
if ((Get-FileHash -LiteralPath $fixtureGitIgnore -Algorithm SHA256).Hash -ne $ignoreHashBefore) {
    Write-Fail -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys' -Reason 'global resolution changed the consumer .gitignore'
}
$wrongGlobalPrefix = Resolve-SddSourceContext -PortablePath ('sdd/OtherRepo/' + $globalRelativePath) -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -ManifestPath $fixtureManifestPath
if ($wrongGlobalPrefix.Ok -or $wrongGlobalPrefix.Reason -ne $script:ReasonOutsideFeatures) {
    Write-Fail -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys' -Reason 'global path prefix for a different manifest root was accepted'
}
$escapedManifestPath = Join-Path $fixtureRoot 'outside'
Write-FixtureManifest -RepoPath $fixtureRepoRoot -StorageMode 'global' -FeaturesVersioned $false -ClassicPath $escapedManifestPath
$escapedPathResult = Resolve-SddSourceContext -PortablePath $globalPortablePath -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -ManifestPath $fixtureManifestPath
if ($escapedPathResult.Ok -or $escapedPathResult.Reason -ne 'storage_path_outside_sdd_root') {
    Write-Fail -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys' -Reason 'global classic.path outside effective_SDD_ROOT was accepted'
}
Write-FixtureManifest -RepoPath $fixtureRepoRoot -StorageMode 'global' -FeaturesVersioned $false -ClassicPath $globalClassicRoot
Write-Pass -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys'

# --- Should_KeepInvocationContextDespiteSiblingDecoys (CT19) ---
$siblingDecoys = @(
    (Join-Path $fixtureRepoRoot 'features/006-skills-maturity-parity/FEATURE.md'),
    (Join-Path $fixtureRepoRoot 'features/006-skills-maturity-parity/US01/STORY.md'),
    (Join-Path $fixtureRepoRoot 'features/006-skills-maturity-parity/CONTINUITY.md'),
    (Join-Path $fixtureRepoRoot 'features/006-skills-maturity-parity/US01/REFINE/tasks.md'),
    (Join-Path $fixtureRepoRoot 'memory-bank/architecture.md')
)
foreach ($decoy in $siblingDecoys) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $decoy) -Force | Out-Null
    if (-not (Test-Path -LiteralPath $decoy)) { Set-Content -LiteralPath $decoy -Value 'decoy only' -Encoding UTF8 }
}
$invocationRel = 'core/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md'
$invocationPath = Join-Path $repoRoot ($invocationRel -replace '/', [IO.Path]::DirectorySeparatorChar)
$invocationText = Get-Content -LiteralPath $invocationPath -Raw -Encoding UTF8
foreach ($marker in @('current invocation', 'Do not infer or change the resolved context', 'REFINE/tasks', 'Memory Bank')) {
    if ($invocationText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_KeepInvocationContextDespiteSiblingDecoys' -Reason ("INVOCATION-CONTEXTS.md missing precedence marker '{0}'" -f $marker)
    }
}
if ((Resolve-FixtureInvocationContext -ExplicitContext 'direct' -ExecutionSource 'classic-coordinator') -ne 'direct' -or
    (Resolve-FixtureInvocationContext -ExplicitContext 'orchestrated' -ExecutionSource 'classic-coordinator') -ne 'orchestrated' -or
    (Resolve-FixtureInvocationContext -ExecutionSource 'orchestrated-task-child') -ne 'orchestrated' -or
    (Resolve-FixtureInvocationContext -ExecutionSource 'classic-coordinator') -ne 'direct') {
    Write-Fail -TestName 'Should_KeepInvocationContextDespiteSiblingDecoys' -Reason 'context precedence fixture result did not match the normative decision table'
}
Write-Pass -TestName 'Should_KeepInvocationContextDespiteSiblingDecoys'

# --- Should_Document_SkipReread_When_SourceContextPresent ---
if ($skillText -notmatch '(?i)source_context' -or $skillText -notmatch '(?i)(must not|skip).{0,80}(re-?read|Read)') {
    Write-Fail -TestName 'Should_Document_SkipReread_When_SourceContextPresent' -Reason 'SKILL.md must forbid opaque re-read when source_context present'
}
if ($invocationText -notmatch 'source_context') {
    Write-Fail -TestName 'Should_Document_SkipReread_When_SourceContextPresent' -Reason 'INVOCATION-CONTEXTS.md must mention source_context'
}
Write-Pass -TestName 'Should_Document_SkipReread_When_SourceContextPresent'

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
Write-Host 'Assert-ReadSddArtifact: ALL PASS' -ForegroundColor Green
exit 0
