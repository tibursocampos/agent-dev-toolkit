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
# Deterministic path guard + source_context envelope for adt-read-sdd-artifact.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$resolver = Join-Path $scriptsRoot 'runtime/Resolve-SddSourceContext.ps1'

$script:ReasonEmptyPath = 'empty_path'
$script:ReasonAbsoluteForbidden = 'absolute_path_forbidden'
$script:ReasonPathTraversal = 'path_traversal'
$script:ReasonOutsideFeatures = 'outside_features'
$script:ReasonUnsupportedKind = 'unsupported_kind'
$script:ReasonNotFound = 'not_found'
$script:ReasonInvalidPortable = 'invalid_portable_path'

$script:SchemaId = 'RSA-SOURCE-CONTEXT/v1'
$script:RuleId = 'RSA-SOURCE-CONTEXT'
$script:SkillId = 'adt-read-sdd-artifact'
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
    $result = & $resolver -PortablePath $Path -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
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
    @{ Path = 'features/006-skills-maturity-parity/Bug/STORY.md'; Body = 'repository bug story' },
    @{ Path = 'features/006-skills-maturity-parity/PLAN.md'; Body = 'Delivery primary PLAN' },
    @{ Path = 'features/006-skills-maturity-parity/plans/worker/PLAN.md'; Body = 'Delivery split PLAN' },
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
    @{ Path = 'features/006-skills-maturity-parity/Bug/STORY.md'; Kind = $script:KindStory; Story = 'Bug' },
    @{ Path = 'features/006-skills-maturity-parity/US01/PRD/006_sdd_invocation_contracts.md'; Kind = $script:KindPrd; Story = 'US01' },
    @{ Path = 'features/006-skills-maturity-parity/US01/PLAN/PLAN_006_sdd_invocation_contracts.md'; Kind = $script:KindPlan; Story = 'US01' }
)

foreach ($case in $happyPaths) {
    $result = & $resolver -PortablePath $case.Path -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
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
    @{ Path = 'core/skills/adt-sdd-spec/SKILL.md'; Reason = $script:ReasonOutsideFeatures },
    @{ Path = 'myfeatures/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonOutsideFeatures },
    @{ Path = 'nonfeatures/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonOutsideFeatures },
    @{ Path = 'E:/Nextcloud/Repos/agent-dev-toolkit/features/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonAbsoluteForbidden },
    @{ Path = '/tmp/repo/features/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonAbsoluteForbidden },
    @{ Path = 'C:features/006-skills-maturity-parity/FEATURE.md'; Reason = $script:ReasonAbsoluteForbidden },
    @{ Path = '\server\shareeatures-skills-maturity-parity\FEATURE.md'; Reason = $script:ReasonAbsoluteForbidden },
    @{ Path = 'features/006-skills-maturity-parity/./FEATURE.md'; Reason = $script:ReasonInvalidPortable },
    @{ Path = 'features/006-skills-maturity-parity/Bug/PLAN/PLAN_006_bug.md'; Reason = $script:ReasonUnsupportedKind },
    @{ Path = 'features/006-skills-maturity-parity/US01/ANALYSIS/impact.md'; Reason = $script:ReasonUnsupportedKind },
    @{ Path = ''; Reason = $script:ReasonEmptyPath },
    @{ Path = 'features/006-skills-maturity-parity/US01/PRD/__missing_fixture__.md'; Reason = $script:ReasonNotFound }
)

foreach ($case in $failCases) {
    $result = & $resolver -PortablePath $case.Path -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
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

# --- Should_UseExplicitDeliveryLayout ---
$deliveryPaths = @(
    'features/006-skills-maturity-parity/PLAN.md',
    'features/006-skills-maturity-parity/plans/worker/PLAN.md'
)
foreach ($deliveryPath in $deliveryPaths) {
    $delivery = & $resolver -PortablePath $deliveryPath -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -Layout delivery
    $wrongLayout = & $resolver -PortablePath $deliveryPath -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -Layout classic
    if (-not $delivery.Ok -or $delivery.Envelope.artifact_kind -ne 'PLAN' -or
        $null -ne $delivery.Envelope.identity.story_id -or $wrongLayout.Reason -ne 'unsupported_kind') {
        Write-Fail -TestName 'Should_UseExplicitDeliveryLayout' -Reason "Layout was not preserved for $deliveryPath."
    }
}
$classicAsDelivery = & $resolver -PortablePath $fixturePaths[-1].Path -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -Layout delivery
if ($classicAsDelivery.Reason -ne 'unsupported_kind') {
    Write-Fail -TestName 'Should_UseExplicitDeliveryLayout' -Reason 'Delivery accepted a Classic story PLAN.'
}
Write-Pass -TestName 'Should_UseExplicitDeliveryLayout'

# --- Should_RejectFeatureEscape ---
$outside = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'unrelated')
Set-Content -LiteralPath (Join-Path $outside.FullName 'FEATURE.md') -Value 'outside feature'
$linkPath = Join-Path $fixtureRepoRoot 'features/007-escape'
$linkKind = if ($env:OS -eq 'Windows_NT') { 'Junction' } else { 'SymbolicLink' }
New-Item -ItemType $linkKind -Path $linkPath -Target $outside.FullName | Out-Null
try {
    $escaped = & $resolver -PortablePath 'features/007-escape/FEATURE.md' -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
    if ($escaped.Ok -or $escaped.Reason -ne 'outside_features' -or $null -ne $escaped.Envelope) {
        Write-Fail -TestName 'Should_RejectFeatureEscape' -Reason 'An artifact linked outside the selected root was accepted.'
    }
} finally {
    Remove-Item -LiteralPath $linkPath -Force
}
$siblingFeature = Join-Path $fixtureRepoRoot 'features/006-skills-maturity-parity'
New-Item -ItemType $linkKind -Path $linkPath -Target $siblingFeature | Out-Null
try {
    $redirected = & $resolver -PortablePath 'features/007-escape/FEATURE.md' -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
    if ($redirected.Ok -or $redirected.Reason -ne 'outside_features') {
        Write-Fail -TestName 'Should_RejectFeatureEscape' -Reason 'An artifact redirected into a different feature was accepted.'
    }
} finally {
    Remove-Item -LiteralPath $linkPath -Force
}
Write-Pass -TestName 'Should_RejectFeatureEscape'

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
$localWrongMode = & $resolver -PortablePath $globalRelativePath -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
if ($localWrongMode.Ok -or $localWrongMode.Reason -ne 'outside_features') {
    Write-Fail -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys' -Reason 'The local decoy was accepted in global storage.'
}
$globalDelivery = Join-Path $globalClassicRoot $deliveryPaths[0]
Set-Content -LiteralPath $globalDelivery -Value 'global Delivery PLAN'
$globalDeliveryRead = & $resolver -PortablePath ('sdd/RepoFixture/' + $deliveryPaths[0]) -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot -Layout delivery
if (-not $globalDeliveryRead.Ok -or (Get-Content -LiteralPath $globalDeliveryRead.AbsolutePath -Raw).Trim() -ne 'global Delivery PLAN') {
    Write-Fail -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys' -Reason 'Delivery did not follow the global manifest.'
}
$wrongGlobalPrefix = & $resolver -PortablePath ('sdd/OtherRepo/' + $globalRelativePath) -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
if ($wrongGlobalPrefix.Ok -or $wrongGlobalPrefix.Reason -ne $script:ReasonOutsideFeatures) {
    Write-Fail -TestName 'Should_SelectGlobalClassicPathAndRejectLocalDecoys' -Reason 'global path prefix for a different manifest root was accepted'
}
$escapedManifestPath = Join-Path $fixtureRoot 'outside'
Write-FixtureManifest -RepoPath $fixtureRepoRoot -StorageMode 'global' -FeaturesVersioned $false -ClassicPath $escapedManifestPath
$escapedPathResult = & $resolver -PortablePath $globalPortablePath -RepoRoot $fixtureRepoRoot -SddRoot $fixtureSddRoot
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
