#Requires -Version 5.1
# Tests:
#   Should_Pass_When_SkillAndCatalogPresent (RNF-003)
#   Should_ReturnEnvelope_When_CanonicalPrdPlanFeatureStory (CT2 / REQ-004)
#   Should_Reject_When_PathTraversalOrOutsideFeatures (CT3 / REQ-005 / RNF-001)
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
$script:GlobalSddPrefixPattern = '(?i)^sdd/[^/]+/'

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

function Get-SddPortableFeaturesSuffix {
    param([Parameter(Mandatory = $true)][string] $NormalizedPath)
    $path = $NormalizedPath
    if ($path -match $script:GlobalSddPrefixPattern) {
        $path = $path -replace $script:GlobalSddPrefixPattern, ''
    }
    # Require path-segment boundary (^|/)features/ — reject myfeatures/, nonfeatures/, etc.
    $match = [regex]::Match($path, '(?i)(^|/)features/')
    if (-not $match.Success) {
        return $null
    }
    $idx = $match.Index
    if ($match.Groups[1].Length -gt 0) {
        $idx = $match.Index + $match.Groups[1].Length
    }
    return $path.Substring($idx)
}

function Resolve-SddSourceContext {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $PortablePath,
        [Parameter(Mandatory = $true)][string] $RepoRoot
    )

    $trimmed = if ($null -eq $PortablePath) { '' } else { $PortablePath.Trim() }
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return [PSCustomObject]@{
            Ok      = $false
            Reason  = $script:ReasonEmptyPath
            Message = 'Path is empty.'
            Envelope = $null
        }
    }

    $normalized = ConvertTo-ForwardSlashPath -PathText $trimmed

    if ($normalized -match '^[A-Za-z]:/' -or $normalized.StartsWith('//') -or $normalized -match '(?i)(/Users/|/home/|\\\\Users\\\\)') {
        return [PSCustomObject]@{
            Ok      = $false
            Reason  = $script:ReasonAbsoluteForbidden
            Message = 'OS absolute or user-home path is forbidden; use a portable features/ path.'
            Envelope = $null
        }
    }

    $segments = @($normalized.Split('/') | Where-Object { $_ -ne '' })
    if ($segments -contains '..') {
        return [PSCustomObject]@{
            Ok      = $false
            Reason  = $script:ReasonPathTraversal
            Message = 'Path contains ".."; traversal is rejected.'
            Envelope = $null
        }
    }

    $featuresSuffix = Get-SddPortableFeaturesSuffix -NormalizedPath $normalized
    if ([string]::IsNullOrWhiteSpace($featuresSuffix)) {
        return [PSCustomObject]@{
            Ok      = $false
            Reason  = $script:ReasonOutsideFeatures
            Message = 'Path must include a features/<NNN-slug>/ segment.'
            Envelope = $null
        }
    }

    $kind = $null
    $featureSlug = $null
    $storyId = $null
    $fileName = $null

    if ($featuresSuffix -match '^(?i)features/([^/]+)/FEATURE\.md$') {
        $kind = $script:KindFeature
        $featureSlug = $Matches[1]
        $fileName = 'FEATURE.md'
        $storyId = $null
    }
    elseif ($featuresSuffix -match '^(?i)features/([^/]+)/((?:US|TS)\d{2})/STORY\.md$') {
        $kind = $script:KindStory
        $featureSlug = $Matches[1]
        $storyId = $Matches[2].ToUpperInvariant()
        $fileName = 'STORY.md'
    }
    elseif ($featuresSuffix -match '^(?i)features/([^/]+)/((?:US|TS)\d{2})/PRD/([^/]+\.md)$') {
        $kind = $script:KindPrd
        $featureSlug = $Matches[1]
        $storyId = $Matches[2].ToUpperInvariant()
        $fileName = $Matches[3]
    }
    elseif ($featuresSuffix -match '^(?i)features/([^/]+)/((?:US|TS)\d{2})/PLAN/(PLAN_[^/]+\.md)$') {
        $kind = $script:KindPlan
        $featureSlug = $Matches[1]
        $storyId = $Matches[2].ToUpperInvariant()
        $fileName = $Matches[3]
    }
    else {
        return [PSCustomObject]@{
            Ok      = $false
            Reason  = $script:ReasonUnsupportedKind
            Message = 'Path is not a canonical FEATURE/STORY/PRD/PLAN under features/.'
            Envelope = $null
        }
    }

    if ($featureSlug -notmatch '^\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*$') {
        return [PSCustomObject]@{
            Ok      = $false
            Reason  = $script:ReasonInvalidPortable
            Message = 'Feature folder must match NNN-slug.'
            Envelope = $null
        }
    }

    $relativeFs = ($featuresSuffix -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $absolute = Join-Path $RepoRoot $relativeFs
    if (-not (Test-Path -LiteralPath $absolute)) {
        return [PSCustomObject]@{
            Ok      = $false
            Reason  = $script:ReasonNotFound
            Message = ("File not found at portable path '{0}'." -f $featuresSuffix)
            Envelope = $null
        }
    }

    $identity = [ordered]@{
        feature_slug = $featureSlug
        story_id     = $storyId
        file_name    = $fileName
    }

    $envelope = [ordered]@{
        schema         = $script:SchemaId
        artifact_kind  = $kind
        portable_path  = $featuresSuffix
        identity       = [PSCustomObject]$identity
    }

    return [PSCustomObject]@{
        Ok       = $true
        Reason   = $null
        Message  = $null
        Envelope = [PSCustomObject]$envelope
    }
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
    $result = Resolve-SddSourceContext -PortablePath $case.Path -RepoRoot $repoRoot
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
    $result = Resolve-SddSourceContext -PortablePath $case.Path -RepoRoot $repoRoot
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

# --- Should_Document_SkipReread_When_SourceContextPresent ---
if ($skillText -notmatch '(?i)source_context' -or $skillText -notmatch '(?i)(must not|skip).{0,80}(re-?read|Read)') {
    Write-Fail -TestName 'Should_Document_SkipReread_When_SourceContextPresent' -Reason 'SKILL.md must forbid opaque re-read when source_context present'
}
$invocationRel = 'core/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md'
$invocationPath = Join-Path $repoRoot ($invocationRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $invocationPath) {
    $invocationText = Get-Content -LiteralPath $invocationPath -Raw -Encoding UTF8
    if ($invocationText -notmatch 'source_context') {
        Write-Fail -TestName 'Should_Document_SkipReread_When_SourceContextPresent' -Reason 'INVOCATION-CONTEXTS.md must mention source_context'
    }
}
Write-Pass -TestName 'Should_Document_SkipReread_When_SourceContextPresent'

Write-Host 'Assert-ReadSddArtifact: ALL PASS' -ForegroundColor Green
exit 0
