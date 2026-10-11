#Requires -Version 5.1
<#
.SYNOPSIS
  Fixture contracts for catalog republish, mixed-router uninstall, hash classification, and adapter coverage.

.DESCRIPTION
  Covers CT1, CA3, CT2, CT3, CT4, and CT5 from the publication-ownership plan.
  Writes only under scripts/validation/fixtures. Does not create or modify a real user-home path.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CatalogSkillId = 'sample-skill'
$PlaceholderToken = '{{ROOT}}'
$ResolvedRootToken = 'resolved-root'
$OperatorPreface = 'operator preface'
$OperatorAfter = 'operator after'
$ToolkitSection = 'toolkit section'
$IdenticalCatalogBody = "catalog-rule-body`n"
$IdenticalCatalogRelativePath = 'rules/catalog-rule.md'
$CatalogOnlyRelativePath = 'CATALOG.md'
$CatalogOnlyBody = "catalog router`n"
$EditedCatalogOnlyBody = "catalog router edited`n"
$NonCatalogFileName = 'operator-secret.txt'
$NonCatalogBody = "do not touch secret`n"
$MarkedRouterRelativePath = 'MARKED.md'
$AgentsRelativePath = 'AGENTS.md'
$ClaudeRelativePath = 'CLAUDE.md'
$InventoryRelativePath = 'features/012-multiprovider-toolkit-corrections/US06/ANALYSIS/adapter-publish-uninstall-inventory.md'
$InventoryRootsHeading = '**Raízes declaradas**'
$InventoryCapabilitiesHeading = '**Capacidades**'
$InventoryActiveCapabilityMark = 'atingida'
$HomeSentinelPrefix = 'adt-publish-ownership-ct5-'
$UpstreamSentinelRelativePath = 'install-root/independent-upstream-sentinel.txt'
$UpstreamSentinelBody = "upstream-independent-content-must-remain-identical`n"
$StaleCatalogBody = 'stale-catalog'
$PriorWriteAgeDays = -2

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRoot = (Resolve-Path (Join-Path $scriptsRoot '..')).Path
$libDir = Join-Path $scriptsRoot '_lib'
$managedTreeScript = Join-Path $libDir 'Copy-ToolkitManagedTree.ps1'
$inventoryScript = Join-Path $libDir 'ToolkitManagedPublishInventory.ps1'

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

foreach ($required in @($managedTreeScript, $inventoryScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-PublishOwnershipContractsPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $managedTreeScript
. $inventoryScript

$fixtureBase = [System.IO.Path]::GetFullPath((Join-Path $scriptDir 'fixtures')).TrimEnd('\', '/')
$probeRoot = Join-Path $fixtureBase ('.publish-ownership-' + [guid]::NewGuid().ToString('N'))
$fullProbeRoot = [System.IO.Path]::GetFullPath($probeRoot).TrimEnd('\', '/')
$fixturePrefix = $fixtureBase + [System.IO.Path]::DirectorySeparatorChar
if (-not $fullProbeRoot.StartsWith($fixturePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName 'Assert-PublishOwnershipContractsPreconditions' -Reason ("refusing probe outside validation fixtures: {0}" -f $fullProbeRoot)
}

$userHome = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
if ([string]::IsNullOrWhiteSpace($userHome)) {
    Write-Fail -TestName 'Assert-PublishOwnershipContractsPreconditions' -Reason 'user home is not set'
}
$userHomeFull = [System.IO.Path]::GetFullPath($userHome).TrimEnd('\', '/')
$homeSentinel = Join-Path $userHomeFull ($HomeSentinelPrefix + [guid]::NewGuid().ToString('N'))
if ($fullProbeRoot.StartsWith($userHomeFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName 'Assert-PublishOwnershipContractsPreconditions' -Reason 'fixture probe resolves under the real user home'
}
if (Test-Path -LiteralPath $homeSentinel) {
    Write-Fail -TestName 'Assert-PublishOwnershipContractsPreconditions' -Reason 'home sentinel already exists before the fixture run'
}

$writtenPaths = New-Object System.Collections.Generic.List[string]
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Add-WrittenPath {
    param([Parameter(Mandatory = $true)][string] $Path)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $writtenPaths.Add($fullPath) | Out-Null
}

function Assert-OutsideUserHome {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $TestName
    )
    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $homePrefix = $userHomeFull + [System.IO.Path]::DirectorySeparatorChar
    if ($fullPath.StartsWith($homePrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($fullPath, $userHomeFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail -TestName $TestName -Reason ("path is under the real user home: {0}" -f $fullPath)
    }
}

function Get-NormalizedFullPath {
    param([Parameter(Mandatory = $true)][string] $Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Assert-OutsideIndependentFixture {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string[]] $Paths,
        [Parameter(Mandatory = $true)][string] $IndependentRoot
    )

    $independentFull = Get-NormalizedFullPath -Path $IndependentRoot
    $independentPrefix = $independentFull + [System.IO.Path]::DirectorySeparatorChar
    foreach ($path in $Paths) {
        $candidateFull = Get-NormalizedFullPath -Path $path
        $candidatePrefix = $candidateFull + [System.IO.Path]::DirectorySeparatorChar
        $candidateIsInside = $candidateFull.StartsWith($independentPrefix, [System.StringComparison]::OrdinalIgnoreCase)
        $independentIsInside = $independentFull.StartsWith($candidatePrefix, [System.StringComparison]::OrdinalIgnoreCase)
        $samePath = [string]::Equals($candidateFull, $independentFull, [System.StringComparison]::OrdinalIgnoreCase)
        if ($candidateIsInside -or $independentIsInside -or $samePath) {
            Write-Fail -TestName $TestName -Reason ("helper root or target overlaps independent fixture: {0}" -f $candidateFull)
        }
    }
}

function Get-ToolkitFixtureMetadataTargets {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $SkillsDestination
    )

    $inventoryPath = Get-ToolkitManagedPublishInventoryPath -InstallRoot $InstallRoot
    return @(
        $inventoryPath
        ($inventoryPath + $script:ToolkitConstant.ManagedPublishInventoryAtomicWriteTempSuffix)
        (Get-ToolkitManagedSkillsManifestPath -DestinationSkillsRoot $SkillsDestination)
    )
}

function Get-IndependentFixtureSnapshot {
    param([Parameter(Mandatory = $true)][string] $Root)

    $fullRoot = Get-NormalizedFullPath -Path $Root
    $prefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    $files = @(Get-ChildItem -LiteralPath $fullRoot -File -Recurse -Force | Sort-Object FullName)
    $snapshot = New-Object System.Collections.Generic.List[string]
    foreach ($file in $files) {
        $fullFile = Get-NormalizedFullPath -Path $file.FullName
        if (-not $fullFile.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Fail -TestName 'CT5_IndependentFixtureSnapshot' -Reason ("snapshot file escaped fixture root: {0}" -f $fullFile)
        }
        $relativePath = $fullFile.Substring($prefix.Length).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $fullFile -Algorithm SHA256).Hash.ToLowerInvariant()
        $snapshot.Add(('{0}|{1}' -f $relativePath, $hash)) | Out-Null
    }
    return ,@($snapshot.ToArray())
}

function Assert-IndependentFixtureSnapshotUnchanged {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string[]] $Baseline
    )

    $after = @(Get-IndependentFixtureSnapshot -Root $Root)
    $differences = @(Compare-Object -ReferenceObject $Baseline -DifferenceObject $after)
    if ($differences.Count -gt 0) {
        Write-Fail -TestName 'CT5_IndependentFixtureSnapshot' -Reason ("paths or SHA-256 bytes changed: {0}" -f (@($differences | ForEach-Object { $_.InputObject }) -join ', '))
    }
    Write-Pass -TestName 'CT5_IndependentFixtureSnapshot'
}

function New-MarkedRouterContent {
    param(
        [Parameter(Mandatory = $true)][string] $BeginMarker,
        [Parameter(Mandatory = $true)][string] $EndMarker
    )
    return ("{0}`n{1}`n{2}`n{3}`n{4}`n" -f $OperatorPreface, $BeginMarker, $ToolkitSection, $EndMarker, $OperatorAfter)
}

function Remove-ProbeRoot {
    if (-not (Test-Path -LiteralPath $fullProbeRoot)) {
        return
    }
    $resolvedCleanup = [System.IO.Path]::GetFullPath($fullProbeRoot).TrimEnd('\', '/')
    if (-not $resolvedCleanup.StartsWith($fixturePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ("Refusing cleanup outside validation fixtures: {0}" -f $resolvedCleanup)
    }
    Write-Pass -TestName 'CT5_FinalProbeCleanup_ConfinedToValidationFixtures'
    Remove-Item -LiteralPath $resolvedCleanup -Recurse -Force -ErrorAction Stop
}

function Invoke-RepublishAlignmentContract {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][string] $SkillsDestination
    )

    $testName = 'Should_AlignDifferingCatalogFileToSourceAndNativeTransform_When_Republishing'
    $sourceSkillDir = Join-Path $SourceRoot $CatalogSkillId
    $null = New-Item -ItemType Directory -Path $sourceSkillDir -Force
    $sourceBody = ('toolkit {0}' -f $PlaceholderToken)
    $sourceFile = Join-Path $sourceSkillDir 'SKILL.md'
    [System.IO.File]::WriteAllText($sourceFile, $sourceBody, $utf8NoBom)

    $destinationSkillDir = Join-Path $SkillsDestination $CatalogSkillId
    $null = New-Item -ItemType Directory -Path $destinationSkillDir -Force
    $destinationFile = Join-Path $destinationSkillDir 'SKILL.md'
    [System.IO.File]::WriteAllText($destinationFile, $StaleCatalogBody, $utf8NoBom)
    Add-WrittenPath -Path $destinationFile

    $metadataTargets = @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)
    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_CopyToolkitManagedTree' -Paths (@($SourceRoot, $sourceSkillDir, $sourceFile, $SkillsDestination, $destinationSkillDir, $destinationFile, $InstallRoot) + $metadataTargets) -IndependentRoot $script:independentInstallRoot
    $null = Copy-ToolkitManagedTree -SourceRoot $SourceRoot -DestinationRoot $SkillsDestination -InstallRoot $InstallRoot
    Write-Pass -TestName 'CT5_TargetIsolation_CopyToolkitManagedTree'
    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_ResolvePlaceholders' -Paths (@($SkillsDestination, $destinationSkillDir, $destinationFile) + $metadataTargets) -IndependentRoot $script:independentInstallRoot
    $null = Resolve-ToolkitPlaceholdersInTree -RootPath $SkillsDestination -PlaceholderMap @{ $PlaceholderToken = $ResolvedRootToken }
    Write-Pass -TestName 'CT5_TargetIsolation_ResolvePlaceholders'
    $aligned = [System.IO.File]::ReadAllText($destinationFile)
    $expected = ('toolkit {0}' -f $ResolvedRootToken)
    if ($aligned -ne $expected) {
        Write-Fail -TestName $testName -Reason ("catalog file must match source after the documented placeholder transform; got '{0}'" -f $aligned)
    }
    if ($aligned -eq $sourceBody -or $aligned -eq $StaleCatalogBody) {
        Write-Fail -TestName $testName -Reason 'catalog file must show the native placeholder transform, not the raw source or the stale copy'
    }

    $profile = Get-ToolkitAdapterContentCompareProfile -AdapterId $script:ToolkitConstant.ContentHashAdapterIdCursor
    $transformProperty = $script:ToolkitConstant.ContentHashProfileNativeTransformProperty
    $expectsProperty = $script:ToolkitConstant.ContentHashProfileExpectsSameBytesProperty
    if ($null -eq $profile -or [string]::IsNullOrWhiteSpace([string]$profile[$transformProperty])) {
        Write-Fail -TestName $testName -Reason 'cursor compare profile must declare a native transform'
    }
    if ([string]$profile[$transformProperty] -ne $script:ToolkitConstant.ContentHashNativeTransformCursor) {
        Write-Fail -TestName $testName -Reason 'documented cursor native transform token changed'
    }
    if ([bool]$profile[$expectsProperty]) {
        Write-Fail -TestName $testName -Reason 'cursor native transform must not expect raw source bytes'
    }

    Write-Pass -TestName $testName
    return $destinationFile
}

function Invoke-IdenticalCatalogReplaceContract {
    param([Parameter(Mandatory = $true)][string] $InstallRoot)

    $testName = 'Should_KeepIdenticalCatalogFileAlignedAndStillReplace_When_Republishing'
    $copyCommand = Get-Command -Name Copy-ToolkitFileIfAbsent -CommandType Function
    $definition = $copyCommand.Definition
    if ($definition -notmatch 'Catalog republish always replaces') {
        Write-Fail -TestName $testName -Reason 'catalog republish must keep the always-replace contract'
    }
    if ($definition -match 'Get-FileHash|Compare-Object') {
        Write-Fail -TestName $testName -Reason 'catalog republish must not add a content compare; skip-on-equal is out of contract until a compare is not slower than replace'
    }

    $sourceFile = Join-Path $fullProbeRoot 'identical-source.md'
    $destinationFile = Join-Path $InstallRoot $IdenticalCatalogRelativePath
    $destinationParent = Split-Path -Parent $destinationFile
    $null = New-Item -ItemType Directory -Path $destinationParent -Force
    [System.IO.File]::WriteAllText($sourceFile, $IdenticalCatalogBody, $utf8NoBom)
    [System.IO.File]::WriteAllText($destinationFile, $IdenticalCatalogBody, $utf8NoBom)
    $priorStamp = (Get-Date).ToUniversalTime().AddDays($PriorWriteAgeDays)
    (Get-Item -LiteralPath $destinationFile).LastWriteTimeUtc = $priorStamp
    Add-WrittenPath -Path $destinationFile

    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_CopyToolkitFileIfAbsent' -Paths (@($sourceFile, $destinationFile, (Split-Path -Parent $destinationFile), $InstallRoot) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination (Join-Path $InstallRoot 'skills'))) -IndependentRoot $script:independentInstallRoot
    $replaced = Copy-ToolkitFileIfAbsent -SourcePath $sourceFile -DestinationPath $destinationFile -InstallRoot $InstallRoot -RelativePath $IdenticalCatalogRelativePath
    Write-Pass -TestName 'CT5_TargetIsolation_CopyToolkitFileIfAbsent'
    $currentStamp = (Get-Item -LiteralPath $destinationFile).LastWriteTimeUtc
    $currentBody = [System.IO.File]::ReadAllText($destinationFile)
    if ($currentBody -ne $IdenticalCatalogBody) {
        Write-Fail -TestName $testName -Reason 'identical catalog file must stay aligned to source'
    }
    if (-not $replaced -or $currentStamp -le $priorStamp) {
        Write-Fail -TestName $testName -Reason 'identical catalog file must still be replaced; the current publisher does not skip the write'
    }

    Write-Pass -TestName $testName
}

function Invoke-EditedCatalogUninstallContract {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $SkillsDestination,
        [Parameter(Mandatory = $true)][string] $CatalogSkillFile
    )

    $testName = 'Should_RemoveOnlyHashOwnedFilesAndPreserveConflicts_When_Uninstalling'
    $catalogSkillContentBeforeEdit = [System.IO.File]::ReadAllText($CatalogSkillFile)
    [System.IO.File]::AppendAllText($CatalogSkillFile, "operator-edit-marker`n", $utf8NoBom)
    $ownedSkillRelativePath = 'skills/sample-skill/owned-file.md'
    $ownedSkillFile = Join-Path $SkillsDestination 'sample-skill/owned-file.md'
    $ownedSkillContent = 'toolkit-owned-file'
    [System.IO.File]::WriteAllText($ownedSkillFile, $ownedSkillContent, $utf8NoBom)
    $null = Set-ToolkitManagedPublishInventoryEntry `
        -InstallRoot $InstallRoot `
        -RelativePath $ownedSkillRelativePath `
        -Sha256 (Get-ToolkitManagedContentSha256Hex -Content $ownedSkillContent) `
        -Kind 'skill'
    Add-WrittenPath -Path $ownedSkillFile

    $unlistedSkillRelativePath = 'skills/sample-skill/unlisted-file.md'
    $unlistedSkillFile = Join-Path $SkillsDestination 'sample-skill/unlisted-file.md'
    $unlistedSkillContent = 'operator-sidecar'
    [System.IO.File]::WriteAllText($unlistedSkillFile, $unlistedSkillContent, $utf8NoBom)
    Add-WrittenPath -Path $unlistedSkillFile

    $nonCatalogFile = Join-Path $InstallRoot $NonCatalogFileName
    [System.IO.File]::WriteAllText($nonCatalogFile, $NonCatalogBody, $utf8NoBom)
    Add-WrittenPath -Path $nonCatalogFile

    $beginMarker = $script:ToolkitConstant.ManagedBlockBeginMarker
    $endMarker = $script:ToolkitConstant.ManagedBlockEndMarker
    $routerPaths = @($AgentsRelativePath, $ClaudeRelativePath, $MarkedRouterRelativePath)
    foreach ($relativePath in $routerPaths) {
        $routerPath = Join-Path $InstallRoot $relativePath
        $routerContent = New-MarkedRouterContent -BeginMarker $beginMarker -EndMarker $endMarker
        [System.IO.File]::WriteAllText($routerPath, $routerContent, $utf8NoBom)
        $null = Set-ToolkitManagedPublishInventoryEntryFromContent -InstallRoot $InstallRoot -RelativePath $relativePath -PublishedContent $routerContent -Kind 'router'
        Add-WrittenPath -Path $routerPath
    }

    $divergentMarkedRouterCases = @(
        @{ RelativePath = 'marked-inside-edited.md'; Edit = { param($content) $content.Replace($ToolkitSection, 'operator changed toolkit section') } },
        @{ RelativePath = 'marked-outside-edited.md'; Edit = { param($content) $content + "operator appended content`n" } }
    )
    foreach ($case in $divergentMarkedRouterCases) {
        $relativePath = [string]$case.RelativePath
        $routerPath = Join-Path $InstallRoot $relativePath
        $originalContent = New-MarkedRouterContent -BeginMarker $beginMarker -EndMarker $endMarker
        [System.IO.File]::WriteAllText($routerPath, $originalContent, $utf8NoBom)
        $null = Set-ToolkitManagedPublishInventoryEntryFromContent -InstallRoot $InstallRoot -RelativePath $relativePath -PublishedContent $originalContent -Kind 'router'
        $editedContent = & $case.Edit $originalContent
        [System.IO.File]::WriteAllText($routerPath, $editedContent, $utf8NoBom)
        Add-WrittenPath -Path $routerPath
    }

    $catalogOnlyPath = Join-Path $InstallRoot $CatalogOnlyRelativePath
    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_WriteToolkitFileIfAbsent_Catalog' -Paths (@($catalogOnlyPath, (Split-Path -Parent $catalogOnlyPath), $InstallRoot) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
    $null = Write-ToolkitFileIfAbsent -Path $catalogOnlyPath -Content $CatalogOnlyBody -InstallRoot $InstallRoot -RelativePath $CatalogOnlyRelativePath
    Write-Pass -TestName 'CT5_TargetIsolation_WriteToolkitFileIfAbsent_Catalog'
    [System.IO.File]::WriteAllText($catalogOnlyPath, $EditedCatalogOnlyBody, $utf8NoBom)
    Add-WrittenPath -Path $catalogOnlyPath

    $matchingRouterRelativePath = 'catalog-owned.md'
    $matchingRouterPath = Join-Path $InstallRoot $matchingRouterRelativePath
    $matchingRouterContent = 'catalog router owned by toolkit'
    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_WriteToolkitFileIfAbsent_Router' -Paths (@($matchingRouterPath, (Split-Path -Parent $matchingRouterPath), $InstallRoot) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
    $null = Write-ToolkitFileIfAbsent -Path $matchingRouterPath -Content $matchingRouterContent -InstallRoot $InstallRoot -RelativePath $matchingRouterRelativePath
    Write-Pass -TestName 'CT5_TargetIsolation_WriteToolkitFileIfAbsent_Router'
    Add-WrittenPath -Path $matchingRouterPath

    $unregisteredRouterRelativePath = 'unregistered-router.md'
    $unregisteredRouterPath = Join-Path $InstallRoot $unregisteredRouterRelativePath
    $unregisteredRouterContent = 'unregistered operator content'
    [System.IO.File]::WriteAllText($unregisteredRouterPath, $unregisteredRouterContent, $utf8NoBom)
    Add-WrittenPath -Path $unregisteredRouterPath

    $skillWarnings = @()
    $skillsRemovalTargets = @($InstallRoot, $SkillsDestination, (Join-Path $SkillsDestination $CatalogSkillId), $CatalogSkillFile, $ownedSkillFile, $unlistedSkillFile) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)
    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_RemoveToolkitManagedSkillsByInventory' -Paths $skillsRemovalTargets -IndependentRoot $script:independentInstallRoot
    $skillRemoval = Remove-ToolkitManagedSkillsByInventory `
        -InstallRoot $InstallRoot `
        -DestinationSkillsRoots @($SkillsDestination) `
        -SkillIds @($CatalogSkillId) `
        -WarningVariable skillWarnings
    Write-Pass -TestName 'CT5_TargetIsolation_RemoveToolkitManagedSkillsByInventory'
    if (Test-Path -LiteralPath $CatalogSkillFile) {
        Write-Fail -TestName 'Should_RemoveEditedSkillTree_When_Uninstalling' -Reason 'edited catalog skill must be removed with its toolkit skill tree'
    }
    if (Test-Path -LiteralPath $ownedSkillFile) {
        Write-Fail -TestName 'Should_RemoveSkill_When_PathAndCurrentHashMatch' -Reason 'matching path/hash skill file must be removed'
    }
    if (Test-Path -LiteralPath $unlistedSkillFile) {
        Write-Fail -TestName 'Should_RemoveUnlistedFilesInsideToolkitSkillTree_When_Uninstalling' -Reason 'all files inside a toolkit skill tree must be removed'
    }
    if (-not (Test-Path -LiteralPath $nonCatalogFile) -or [System.IO.File]::ReadAllText($nonCatalogFile) -ne $NonCatalogBody) {
        Write-Fail -TestName $testName -Reason 'non-catalog file must stay'
    }
    if (@($skillRemoval.PreservedPaths).Count -ne 0 -or @($skillWarnings).Count -ne 0) {
        Write-Fail -TestName $testName -Reason 'toolkit skill removal must not preserve or warn for files inside a listed skill tree'
    }
    Write-Pass -TestName 'Should_RemoveSkill_When_PathAndCurrentHashMatch'
    Write-Pass -TestName 'Should_RemoveEditedSkillTree_When_Uninstalling'
    Write-Pass -TestName 'Should_RemoveUnlistedFilesInsideToolkitSkillTree_When_Uninstalling'

    foreach ($relativePath in $routerPaths) {
        $routerPath = Join-Path $InstallRoot $relativePath
        if (-not (Test-Path -LiteralPath $routerPath)) {
            Write-Fail -TestName $testName -Reason ("mixed router must stay: {0}" -f $relativePath)
        }
        Assert-OutsideIndependentFixture -TestName ("CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_{0}" -f $relativePath) -Paths (@($InstallRoot, $routerPath) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
        $removal = Remove-ToolkitManagedWholeFileRouterIfOwned `
            -InstallRoot $InstallRoot `
            -RelativePath $relativePath `
            -CurrentFilePath $routerPath `
            -ResolveExpectedPublishContent { 'unused' }
        Write-Pass -TestName ("CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_{0}" -f $relativePath)
        $after = [System.IO.File]::ReadAllText($routerPath)
        if ($removal.Removed -or $after.Contains($beginMarker) -or $after.Contains($ToolkitSection) -or -not $after.Contains($OperatorPreface) -or -not $after.Contains($OperatorAfter)) {
            Write-Fail -TestName $testName -Reason ("operator text outside toolkit markers must stay in {0}" -f $relativePath)
        }
    }

    foreach ($case in $divergentMarkedRouterCases) {
        $relativePath = [string]$case.RelativePath
        $routerPath = Join-Path $InstallRoot $relativePath
        $beforeBytes = [System.IO.File]::ReadAllBytes($routerPath)
        $beforeHash = Get-ToolkitFileContentSha256 -Path $routerPath
        $recordedHash = (Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot)[$relativePath].sha256
        $routerWarnings = @()
        $removal = Remove-ToolkitManagedWholeFileRouterIfOwned `
            -InstallRoot $InstallRoot `
            -RelativePath $relativePath `
            -CurrentFilePath $routerPath `
            -ResolveExpectedPublishContent { 'unused' } `
            -WarningVariable routerWarnings
        $afterBytes = [System.IO.File]::ReadAllBytes($routerPath)
        $afterHash = Get-ToolkitFileContentSha256 -Path $routerPath
        $warningText = @($routerWarnings) -join "`n"
        if ($removal.Removed -or -not $removal.Preserved -or
            $removal.Reason -ne 'current-sha256-does-not-match-recorded-ownership' -or
            $removal.Message -notmatch [regex]::Escape($relativePath) -or
            $warningText -notmatch [regex]::Escape($relativePath) -or
            $beforeHash -ne $afterHash -or
            [System.Convert]::ToBase64String($beforeBytes) -ne [System.Convert]::ToBase64String($afterBytes) -or
            (Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot)[$relativePath].sha256 -ne $recordedHash) {
            Write-Fail -TestName 'Should_PreserveAndReportMarkedRouter_When_CurrentHashDiffers' -Reason ("divergent marked router must remain byte-identical with unchanged ownership and path/reason report: {0}" -f $relativePath)
        }
    }
    Write-Pass -TestName 'Should_PreserveAndReportMarkedRouter_When_CurrentHashDiffers'

    $unregisteredMarkedRelativePath = 'marked-unregistered.md'
    $unregisteredMarkedPath = Join-Path $InstallRoot $unregisteredMarkedRelativePath
    $unregisteredMarkedContent = New-MarkedRouterContent -BeginMarker $beginMarker -EndMarker $endMarker
    [System.IO.File]::WriteAllText($unregisteredMarkedPath, $unregisteredMarkedContent, $utf8NoBom)
    Add-WrittenPath -Path $unregisteredMarkedPath
    $unregisteredMarkedBytesBefore = [System.IO.File]::ReadAllBytes($unregisteredMarkedPath)
    $unregisteredMarkedWarnings = @()
    $unregisteredMarkedRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $InstallRoot `
        -RelativePath $unregisteredMarkedRelativePath `
        -CurrentFilePath $unregisteredMarkedPath `
        -ResolveExpectedPublishContent { 'unused' } `
        -WarningVariable unregisteredMarkedWarnings
    $unregisteredMarkedBytesAfter = [System.IO.File]::ReadAllBytes($unregisteredMarkedPath)
    if ($unregisteredMarkedRemoval.Removed -or -not $unregisteredMarkedRemoval.Preserved -or
        $unregisteredMarkedRemoval.Reason -ne 'ownership-entry-not-found' -or
        $unregisteredMarkedRemoval.Message -notmatch [regex]::Escape($unregisteredMarkedRelativePath) -or
        (@($unregisteredMarkedWarnings) -join "`n") -notmatch [regex]::Escape('ownership-entry-not-found') -or
        [System.Convert]::ToBase64String($unregisteredMarkedBytesBefore) -ne [System.Convert]::ToBase64String($unregisteredMarkedBytesAfter)) {
        Write-Fail -TestName 'Should_PreserveAndReportMarkedRouter_When_OwnershipEntryIsMissing' -Reason 'unregistered marked router must remain byte-identical and report its path and ownership reason'
    }
    Write-Pass -TestName 'Should_PreserveAndReportMarkedRouter_When_OwnershipEntryIsMissing'

    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_Catalog' -Paths (@($InstallRoot, $catalogOnlyPath) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
    $catalogOnlyRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $InstallRoot `
        -RelativePath $CatalogOnlyRelativePath `
        -CurrentFilePath $catalogOnlyPath `
        -ResolveExpectedPublishContent { $CatalogOnlyBody.TrimEnd() }
    Write-Pass -TestName 'CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_Catalog'
    if ($catalogOnlyRemoval.Removed -or -not $catalogOnlyRemoval.Preserved -or (Test-Path -LiteralPath $catalogOnlyPath) -eq $false -or
        [System.IO.File]::ReadAllText($catalogOnlyPath) -ne $EditedCatalogOnlyBody -or
        $catalogOnlyRemoval.Reason -ne 'current-sha256-does-not-match-recorded-ownership' -or
        $catalogOnlyRemoval.Message -notmatch [regex]::Escape($CatalogOnlyRelativePath)) {
        Write-Fail -TestName 'Should_PreserveAndReportCatalogRouter_When_CurrentHashDiffers' -Reason 'edited catalog-only router must remain byte-identical with a path and reason report'
    }

    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_Matching' -Paths (@($InstallRoot, $matchingRouterPath) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
    $matchingRouterRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $InstallRoot `
        -RelativePath $matchingRouterRelativePath `
        -CurrentFilePath $matchingRouterPath `
        -ResolveExpectedPublishContent { 'different source content must not replace recorded ownership' }
    Write-Pass -TestName 'CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_Matching'
    if (-not $matchingRouterRemoval.Removed -or (Test-Path -LiteralPath $matchingRouterPath)) {
        Write-Fail -TestName 'Should_RemoveRouter_When_PathAndCurrentHashMatch' -Reason 'matching path/hash router file must be removed'
    }

    Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_Unregistered' -Paths (@($InstallRoot, $unregisteredRouterPath) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
    $unregisteredRouterRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $InstallRoot `
        -RelativePath $unregisteredRouterRelativePath `
        -CurrentFilePath $unregisteredRouterPath `
        -ResolveExpectedPublishContent { $unregisteredRouterContent }
    Write-Pass -TestName 'CT5_TargetIsolation_RemoveToolkitManagedWholeFileRouter_Unregistered'
    if ($unregisteredRouterRemoval.Removed -or -not $unregisteredRouterRemoval.Preserved -or
        [System.IO.File]::ReadAllText($unregisteredRouterPath) -ne $unregisteredRouterContent -or
        $unregisteredRouterRemoval.Reason -ne 'ownership-entry-not-found') {
        Write-Fail -TestName 'Should_PreserveAndReportRouter_When_OwnershipEntryIsMissing' -Reason 'router with no ownership entry must remain byte-identical and report the missing entry'
    }

    Write-Pass -TestName 'Should_PreserveAndReportCatalogRouter_When_CurrentHashDiffers'
    Write-Pass -TestName 'Should_RemoveRouter_When_PathAndCurrentHashMatch'
    Write-Pass -TestName 'Should_PreserveAndReportRouter_When_OwnershipEntryIsMissing'

    $raceRelativePath = 'race-marked-router.md'
    $raceRouterPath = Join-Path $InstallRoot $raceRelativePath
    $raceOwnedContent = New-MarkedRouterContent -BeginMarker $beginMarker -EndMarker $endMarker
    $raceOperatorContent = "operator edit while toolkit mutation is queued`n"
    [System.IO.File]::WriteAllText($raceRouterPath, $raceOwnedContent, $utf8NoBom)
    $null = Set-ToolkitManagedPublishInventoryEntryFromContent -InstallRoot $InstallRoot -RelativePath $raceRelativePath -PublishedContent $raceOwnedContent -Kind 'router'
    $mutationJob = Start-Job -ArgumentList $inventoryScript, $raceRouterPath, $raceOperatorContent -ScriptBlock {
        param($helperPath, $destinationPath, $operatorContent)
        . $helperPath
        Invoke-ToolkitManagedPublishDestinationLock -DestinationPath $destinationPath -Action {
            Write-Output 'destination-lock-held'
            Start-Sleep -Milliseconds 900
            [System.IO.File]::WriteAllText($destinationPath, $operatorContent, (New-Object System.Text.UTF8Encoding $false))
        }
    }
    $lockAcquired = $false
    for ($attempt = 0; $attempt -lt 40 -and -not $lockAcquired; $attempt++) {
        $jobOutput = @(Receive-Job -Job $mutationJob -Keep -ErrorAction SilentlyContinue)
        $lockAcquired = @($jobOutput | Where-Object { [string]$_ -eq 'destination-lock-held' }).Count -gt 0
        if (-not $lockAcquired) { Start-Sleep -Milliseconds 50 }
    }
    if (-not $lockAcquired) {
        Stop-Job -Job $mutationJob -ErrorAction SilentlyContinue
        Remove-Job -Job $mutationJob -Force -ErrorAction SilentlyContinue
        Write-Fail -TestName 'Should_SerializePublishAndRemoval_ForSameDestination' -Reason 'concurrent publisher fixture did not acquire its destination lock'
    }
    $raceRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $InstallRoot `
        -RelativePath $raceRelativePath `
        -CurrentFilePath $raceRouterPath `
        -ResolveExpectedPublishContent { 'unused' }
    $null = Receive-Job -Job $mutationJob -Wait -ErrorAction Stop
    Remove-Job -Job $mutationJob -Force -ErrorAction SilentlyContinue
    if ($raceRemoval.Removed -or -not $raceRemoval.Preserved -or
        $raceRemoval.Reason -ne 'current-sha256-does-not-match-recorded-ownership' -or
        [System.IO.File]::ReadAllText($raceRouterPath) -ne $raceOperatorContent) {
        Write-Fail -TestName 'Should_SerializePublishAndRemoval_ForSameDestination' -Reason 'removal must wait for a same-destination publish mutation and preserve its resulting divergent bytes'
    }
    Write-Pass -TestName 'Should_SerializePublishAndRemoval_ForSameDestination'

    # Exercise the public skill-publish entry point against inventory-backed
    # removal. The job pauses only after the public wrapper has entered its
    # core (and therefore acquired the install-root gate), then performs the
    # real copy. Removal must wait for that publish and remove its final bytes.
    $publicRaceSourceRoot = Join-Path $fullProbeRoot 'public-skill-publish-source'
    $publicRaceSkillId = 'public-publish-race-skill'
    $publicRaceSourceSkill = Join-Path $publicRaceSourceRoot $publicRaceSkillId
    $publicRaceDestination = Join-Path $skillsDestination $publicRaceSkillId
    $publicRaceSourceFile = Join-Path $publicRaceSourceSkill 'SKILL.md'
    $publicRaceDestinationFile = Join-Path $publicRaceDestination 'SKILL.md'
    $publicRaceSignalPath = Join-Path $fullProbeRoot 'public-publish-entered.txt'
    $null = New-Item -ItemType Directory -Path $publicRaceSourceSkill -Force
    [System.IO.File]::WriteAllText($publicRaceSourceFile, "initial skill bytes`n", $utf8NoBom)
    $null = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $publicRaceSourceRoot `
        -DestinationSkillsRoot $skillsDestination `
        -InstallRoot $InstallRoot `
        -SkipPlaceholderResolve
    Add-WrittenPath -Path $publicRaceDestinationFile
    [System.IO.File]::WriteAllText($publicRaceSourceFile, "public publisher final bytes`n", $utf8NoBom)
    $publicPublishJob = Start-Job -ArgumentList $managedTreeScript, $publicRaceSourceRoot, $skillsDestination, $InstallRoot, $publicRaceSignalPath -ScriptBlock {
        param($managedTreePath, $sourceSkillsRoot, $destinationSkillsRoot, $installRootPath, $signalPath)
        . $managedTreePath
        $originalCore = (Get-Command -Name Invoke-ToolkitManagedSkillsPublishCore -CommandType Function).Definition
        Set-Item -Path Function:\Invoke-ToolkitManagedSkillsPublishCoreOriginal -Value ([scriptblock]::Create($originalCore))
        $script:publishSignalPath = $signalPath
        function Invoke-ToolkitManagedSkillsPublishCore {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)][string] $SourceSkillsRoot,
                [Parameter(Mandatory = $true)][string] $DestinationSkillsRoot,
                [Parameter()][System.Collections.IDictionary] $PlaceholderMap,
                [Parameter()][string] $TextFileExtensionPattern = $script:ToolkitConstant.DefaultTextFileExtensionPattern,
                [Parameter()][string[]] $UnresolvedTokens,
                [Parameter()][string] $UnresolvedMessageFormat = $script:ToolkitMessage.PlaceholderUnresolved,
                [Parameter()][switch] $SkipPlaceholderResolve,
                [Parameter()][string] $InstallRoot
            )

            [System.IO.File]::WriteAllText($script:publishSignalPath, 'public-publish-entered')
            Start-Sleep -Milliseconds 1200
            return Invoke-ToolkitManagedSkillsPublishCoreOriginal @PSBoundParameters
        }
        $null = Invoke-ToolkitManagedSkillsPublish `
            -SourceSkillsRoot $sourceSkillsRoot `
            -DestinationSkillsRoot $destinationSkillsRoot `
            -InstallRoot $installRootPath `
            -SkipPlaceholderResolve
    }
    $publicPublishEntered = $false
    for ($attempt = 0; $attempt -lt 100 -and -not $publicPublishEntered; $attempt++) {
        $publicPublishEntered = Test-Path -LiteralPath $publicRaceSignalPath -PathType Leaf
        if (-not $publicPublishEntered) { Start-Sleep -Milliseconds 25 }
    }
    if (-not $publicPublishEntered) {
        Stop-Job -Job $publicPublishJob -ErrorAction SilentlyContinue
        Remove-Job -Job $publicPublishJob -Force -ErrorAction SilentlyContinue
        Write-Fail -TestName 'Should_SerializePublicSkillPublishAndInventoryRemoval' -Reason 'public publish fixture did not reach its gated publish core'
    }
    $publicRaceRemoval = Remove-ToolkitManagedSkillsByInventory `
        -InstallRoot $InstallRoot `
        -DestinationSkillsRoots @($skillsDestination) `
        -SkillIds @($publicRaceSkillId)
    $null = Receive-Job -Job $publicPublishJob -Wait -ErrorAction Stop
    Remove-Job -Job $publicPublishJob -Force -ErrorAction SilentlyContinue
    if (@($publicRaceRemoval.RemovedPaths | Where-Object { $_ -eq $publicRaceDestinationFile }).Count -ne 1 -or
        (Test-Path -LiteralPath $publicRaceDestinationFile) -or
        $publicRaceRemoval.PreservedPaths.Count -ne 0) {
        Write-Fail -TestName 'Should_SerializePublicSkillPublishAndInventoryRemoval' -Reason 'inventory removal must wait for the public publish and remove its final owned file'
    }
    Write-Pass -TestName 'Should_SerializePublicSkillPublishAndInventoryRemoval'

    # Independent publishers sharing one InstallRoot must merge against the
    # latest inventory snapshot instead of replacing each other's entries.
    $inventoryRacePaths = @('concurrent-a/router.md', 'concurrent-b/router.md')
    $inventoryRaceJobs = @()
    foreach ($index in 0..1) {
        $inventoryRaceJobs += Start-Job -ArgumentList $inventoryScript, $InstallRoot, $inventoryRacePaths[$index], ('A' * 64) -ScriptBlock {
            param($helperPath, $installRootPath, $relativePath, $sha256)
            . $helperPath
            Set-ToolkitManagedPublishInventoryEntry -InstallRoot $installRootPath -RelativePath $relativePath -Sha256 $sha256 -Kind 'router'
        }
    }
    $inventoryRaceFailures = @()
    foreach ($job in $inventoryRaceJobs) {
        $null = Receive-Job -Job $job -Wait -ErrorAction SilentlyContinue
        if ($job.State -ne 'Completed') { $inventoryRaceFailures += $job.ChildJobs[0].JobStateInfo.Reason }
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    }
    $inventoryRaceEntries = Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot
    if ($inventoryRaceFailures.Count -gt 0 -or
        -not $inventoryRaceEntries.ContainsKey($inventoryRacePaths[0]) -or
        -not $inventoryRaceEntries.ContainsKey($inventoryRacePaths[1])) {
        Write-Fail -TestName 'Should_PreserveConcurrentIndependentInventoryUpdates' -Reason 'concurrent independent ownership updates must both remain in the shared inventory'
    }
    Write-Pass -TestName 'Should_PreserveConcurrentIndependentInventoryUpdates'

    $inventoryPath = Get-ToolkitManagedPublishInventoryPath -InstallRoot $InstallRoot
    $invalidInventory = @{
        schemaVersion = $script:ToolkitConstant.ManagedPublishInventorySchemaVersion
        files = @{
            'skills/sample-skill/SKILL.md' = @{ kind = 'skill' }
        }
    } | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($inventoryPath, $invalidInventory, $utf8NoBom)
    $invalidInventoryThrew = $false
    try {
        Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_RemoveToolkitManagedSkillsByInventory_InvalidInventory' -Paths (@($InstallRoot, $SkillsDestination, $CatalogSkillFile) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
        Write-Pass -TestName 'CT5_TargetIsolation_RemoveToolkitManagedSkillsByInventory_InvalidInventory'
        $null = Remove-ToolkitManagedSkillsByInventory -InstallRoot $InstallRoot -DestinationSkillsRoots @($SkillsDestination) -SkillIds @($CatalogSkillId)
    }
    catch {
        $invalidInventoryThrew = $_.Exception.Message -match [regex]::Escape('skills/sample-skill/SKILL.md')
    }
    if (-not $invalidInventoryThrew) {
        Write-Fail -TestName 'Should_FailClosed_When_OwnershipHashIsMissing' -Reason 'missing ownership hash must block cleanup'
    }
    Write-Pass -TestName 'Should_FailClosedAndPreserve_When_OwnershipHashIsMissing'

    $ambiguousInventoryPath = Get-ToolkitManagedPublishInventoryPath -InstallRoot $InstallRoot
    $ambiguousInventory = '{"schemaVersion":1,"files":{"skills/sample-skill/SKILL.md":{"kind":"skill","sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},"skills/sample-skill/SKILL.md":{"kind":"skill","sha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}}}'
    [System.IO.File]::WriteAllText($ambiguousInventoryPath, $ambiguousInventory, $utf8NoBom)
    $ambiguousInventoryError = $null
    try {
        Assert-OutsideIndependentFixture -TestName 'CT5_TargetIsolation_RemoveToolkitManagedSkillsByInventory_AmbiguousInventory' -Paths (@($InstallRoot, $SkillsDestination, $CatalogSkillFile) + @(Get-ToolkitFixtureMetadataTargets -InstallRoot $InstallRoot -SkillsDestination $SkillsDestination)) -IndependentRoot $script:independentInstallRoot
        Write-Pass -TestName 'CT5_TargetIsolation_RemoveToolkitManagedSkillsByInventory_AmbiguousInventory'
        $null = Remove-ToolkitManagedSkillsByInventory -InstallRoot $InstallRoot -DestinationSkillsRoots @($SkillsDestination) -SkillIds @($CatalogSkillId)
    }
    catch {
        $ambiguousInventoryError = $_.Exception.Message
    }
    if ($ambiguousInventoryError -notmatch [regex]::Escape('skills/sample-skill/SKILL.md') -or
        $ambiguousInventoryError -notmatch 'ambiguous') {
        Write-Fail -TestName 'Should_FailClosed_When_OwnershipPathIsAmbiguous' -Reason 'duplicate ownership paths must block cleanup'
    }
    Write-Pass -TestName 'Should_FailClosedAndPreserve_When_OwnershipPathIsAmbiguous'

}

function Invoke-HashWithoutRevisionContract {
    $testName = 'Should_NotCloseDefect_When_HashDiffersWithoutSourceRevision'
    $installedHash = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    $sourceHash = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    $classification = Get-ToolkitContentHashDifferenceClassification `
        -InstalledContentHash $installedHash `
        -SourceContentHash $sourceHash `
        -SourceRevision '' `
        -AdapterId $script:ToolkitConstant.ContentHashAdapterIdCursor
    if ($classification.IsClosedDefect -or $classification.Outcome -eq $script:ToolkitConstant.ContentHashClassificationClosedDefect) {
        Write-Fail -TestName $testName -Reason 'a hash difference without a recorded source revision must not be a closed defect'
    }
    if ($classification.Outcome -ne $script:ToolkitConstant.ContentHashClassificationPendingRevision -or $classification.SourceRevisionKnown) {
        Write-Fail -TestName $testName -Reason 'missing source revision must stay a pending classification'
    }

    Write-Pass -TestName $testName
}

function Invoke-AdapterCoverageContract {
    $testName = 'Should_ListDeclaredDestinationsAndActiveCapabilities_When_ReadingRegistry'
    $registryPath = Join-Path $repoRoot 'adapters/registry.json'
    $inventoryPath = Join-Path $repoRoot $InventoryRelativePath
    if (-not (Test-Path -LiteralPath $registryPath) -or -not (Test-Path -LiteralPath $inventoryPath)) {
        Write-Fail -TestName $testName -Reason 'registry or S1 inventory is missing'
    }

    $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $inventoryText = Get-Content -LiteralPath $inventoryPath -Raw -Encoding UTF8
    $registryIds = @($registry.agents | ForEach-Object { [string]$_.id })
    $profileIds = @($script:ToolkitConstant.ContentHashAdapterCompareProfiles.Keys | ForEach-Object { [string]$_ })
    if ($registryIds.Count -eq 0 -or $registryIds.Count -ne $profileIds.Count) {
        Write-Fail -TestName $testName -Reason 'registry adapter ids must match the declared compare profiles'
    }

    foreach ($agent in @($registry.agents)) {
        $adapterId = [string]$agent.id
        if ([string]::IsNullOrWhiteSpace($adapterId) -or $profileIds -notcontains $adapterId) {
            Write-Fail -TestName $testName -Reason ("adapter '{0}' has no compare profile" -f $adapterId)
        }
        if ($null -eq $agent.publishSurface) {
            Write-Fail -TestName $testName -Reason ("adapter '{0}' has no declared publish surface" -f $adapterId)
        }

        $activeCapabilities = @($agent.capabilities.PSObject.Properties | Where-Object { $_.Value -eq $true })
        if ($activeCapabilities.Count -lt 1) {
            Write-Fail -TestName $testName -Reason ("adapter '{0}' has no active capability" -f $adapterId)
        }

        $sectionPattern = '(?ms)^## ' + [regex]::Escape($adapterId) + '\r?\n(.*?)(?=^## |\z)'
        $sectionMatch = [regex]::Match($inventoryText, $sectionPattern)
        if (-not $sectionMatch.Success) {
            Write-Fail -TestName $testName -Reason ("S1 inventory has no section for '{0}'" -f $adapterId)
        }
        $section = $sectionMatch.Groups[1].Value
        $rootsIndex = $section.IndexOf($InventoryRootsHeading, [System.StringComparison]::Ordinal)
        $capabilitiesIndex = $section.IndexOf($InventoryCapabilitiesHeading, [System.StringComparison]::Ordinal)
        if ($rootsIndex -lt 0 -or $capabilitiesIndex -le $rootsIndex) {
            Write-Fail -TestName $testName -Reason ("adapter '{0}' inventory is missing declared roots or capabilities" -f $adapterId)
        }
        $rootsBlock = $section.Substring($rootsIndex, $capabilitiesIndex - $rootsIndex)
        if ($rootsBlock -notmatch '`[^`]+`') {
            Write-Fail -TestName $testName -Reason ("adapter '{0}' has no declared destination" -f $adapterId)
        }
        if ($section.IndexOf($InventoryActiveCapabilityMark, [System.StringComparison]::Ordinal) -lt 0) {
            Write-Fail -TestName $testName -Reason ("adapter '{0}' has no active capability mark in the inventory" -f $adapterId)
        }
    }

    Write-Pass -TestName $testName
}

function Invoke-RealHomeUntouchedContract {
    $testName = 'Should_LeaveRealHomeUntouched_When_PublishingOrUninstallingFixture'
    Assert-OutsideUserHome -Path $fullProbeRoot -TestName $testName
    foreach ($writtenPath in @($writtenPaths)) {
        Assert-OutsideUserHome -Path $writtenPath -TestName $testName
    }
    if ($null -ne $script:ToolkitLastManagedCopyPaths) {
        foreach ($managedPath in @($script:ToolkitLastManagedCopyPaths)) {
            Assert-OutsideUserHome -Path ([string]$managedPath) -TestName $testName
        }
    }
    if (Test-Path -LiteralPath $homeSentinel) {
        Write-Fail -TestName $testName -Reason 'fixture publish or uninstall created a path under the real user home'
    }

    Write-Pass -TestName $testName
}

try {
    $installRoot = Join-Path $fullProbeRoot 'install-root'
    $sourceRoot = Join-Path $fullProbeRoot 'source-root'
    $skillsDestination = Join-Path $installRoot 'skills'
    $script:independentInstallRoot = Join-Path $fullProbeRoot 'upstream-independent/install-root'
    $null = New-Item -ItemType Directory -Path $installRoot -Force
    $null = New-Item -ItemType Directory -Path $sourceRoot -Force
    $null = New-Item -ItemType Directory -Path $script:independentInstallRoot -Force
    Assert-OutsideUserHome -Path $installRoot -TestName 'Assert-PublishOwnershipContractsPreconditions'
    Assert-OutsideUserHome -Path $script:independentInstallRoot -TestName 'Assert-PublishOwnershipContractsPreconditions'

    $upstreamSentinelPath = Join-Path (Join-Path $fullProbeRoot 'upstream-independent') ($UpstreamSentinelRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    [System.IO.File]::WriteAllText($upstreamSentinelPath, $UpstreamSentinelBody, $utf8NoBom)
    Add-WrittenPath -Path $upstreamSentinelPath
    $independentSnapshotBefore = @(Get-IndependentFixtureSnapshot -Root (Join-Path $fullProbeRoot 'upstream-independent'))
    if ($independentSnapshotBefore.Count -ne 1 -or $independentSnapshotBefore[0] -notmatch '^install-root/independent-upstream-sentinel\.txt\|[0-9a-f]{64}$') {
        Write-Fail -TestName 'CT5_IndependentFixtureBaseline' -Reason 'independent fixture must contain the distinctive sentinel before any helper call'
    }
    Write-Pass -TestName 'CT5_IndependentFixtureBaseline'

    $catalogSkillFile = Invoke-RepublishAlignmentContract -InstallRoot $installRoot -SourceRoot $sourceRoot -SkillsDestination $skillsDestination
    Invoke-IdenticalCatalogReplaceContract -InstallRoot $installRoot
    Invoke-EditedCatalogUninstallContract -InstallRoot $installRoot -SkillsDestination $skillsDestination -CatalogSkillFile $catalogSkillFile
    Invoke-HashWithoutRevisionContract
    Invoke-AdapterCoverageContract
    Assert-IndependentFixtureSnapshotUnchanged -Root (Join-Path $fullProbeRoot 'upstream-independent') -Baseline $independentSnapshotBefore
    Invoke-RealHomeUntouchedContract
}
finally {
    Remove-ProbeRoot
}

Write-Host 'Assert-PublishOwnershipContracts: ALL PASS'
exit 0
