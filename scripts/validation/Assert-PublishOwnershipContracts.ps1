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

    $null = Copy-ToolkitManagedTree -SourceRoot $SourceRoot -DestinationRoot $SkillsDestination -InstallRoot $InstallRoot
    $null = Resolve-ToolkitPlaceholdersInTree -RootPath $SkillsDestination -PlaceholderMap @{ $PlaceholderToken = $ResolvedRootToken }
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

    $replaced = Copy-ToolkitFileIfAbsent -SourcePath $sourceFile -DestinationPath $destinationFile -InstallRoot $InstallRoot -RelativePath $IdenticalCatalogRelativePath
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

    $testName = 'Should_RemoveEditedCatalogSkillAndKeepOperatorText_When_Uninstalling'
    [System.IO.File]::AppendAllText($CatalogSkillFile, "operator-edit-marker`n", $utf8NoBom)
    $nonCatalogFile = Join-Path $InstallRoot $NonCatalogFileName
    [System.IO.File]::WriteAllText($nonCatalogFile, $NonCatalogBody, $utf8NoBom)
    Add-WrittenPath -Path $nonCatalogFile

    $beginMarker = $script:ToolkitConstant.ManagedBlockBeginMarker
    $endMarker = $script:ToolkitConstant.ManagedBlockEndMarker
    $routerPaths = @($AgentsRelativePath, $ClaudeRelativePath, $MarkedRouterRelativePath)
    foreach ($relativePath in $routerPaths) {
        $routerPath = Join-Path $InstallRoot $relativePath
        [System.IO.File]::WriteAllText($routerPath, (New-MarkedRouterContent -BeginMarker $beginMarker -EndMarker $endMarker), $utf8NoBom)
        Add-WrittenPath -Path $routerPath
    }

    $catalogOnlyPath = Join-Path $InstallRoot $CatalogOnlyRelativePath
    $null = Write-ToolkitFileIfAbsent -Path $catalogOnlyPath -Content $CatalogOnlyBody -InstallRoot $InstallRoot -RelativePath $CatalogOnlyRelativePath
    [System.IO.File]::WriteAllText($catalogOnlyPath, $EditedCatalogOnlyBody, $utf8NoBom)
    Add-WrittenPath -Path $catalogOnlyPath

    $null = Remove-ToolkitManagedSkillsByInventory -InstallRoot $InstallRoot -DestinationSkillsRoots @($SkillsDestination) -SkillIds @($CatalogSkillId)
    if (Test-Path -LiteralPath $CatalogSkillFile) {
        Write-Fail -TestName $testName -Reason 'edited catalog skill must be removed'
    }
    if (-not (Test-Path -LiteralPath $nonCatalogFile) -or [System.IO.File]::ReadAllText($nonCatalogFile) -ne $NonCatalogBody) {
        Write-Fail -TestName $testName -Reason 'non-catalog file must stay'
    }

    foreach ($relativePath in $routerPaths) {
        $routerPath = Join-Path $InstallRoot $relativePath
        if (-not (Test-Path -LiteralPath $routerPath)) {
            Write-Fail -TestName $testName -Reason ("mixed router must stay: {0}" -f $relativePath)
        }
        $removal = Remove-ToolkitManagedWholeFileRouterIfOwned `
            -InstallRoot $InstallRoot `
            -RelativePath $relativePath `
            -CurrentFilePath $routerPath `
            -ResolveExpectedPublishContent { 'unused' }
        $after = [System.IO.File]::ReadAllText($routerPath)
        if ($removal.Removed -or $after.Contains($beginMarker) -or $after.Contains($ToolkitSection) -or -not $after.Contains($OperatorPreface) -or -not $after.Contains($OperatorAfter)) {
            Write-Fail -TestName $testName -Reason ("operator text outside toolkit markers must stay in {0}" -f $relativePath)
        }
    }

    $catalogOnlyRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $InstallRoot `
        -RelativePath $CatalogOnlyRelativePath `
        -CurrentFilePath $catalogOnlyPath `
        -ResolveExpectedPublishContent { $CatalogOnlyBody.TrimEnd() }
    if (-not $catalogOnlyRemoval.Removed -or (Test-Path -LiteralPath $catalogOnlyPath)) {
        Write-Fail -TestName $testName -Reason 'edited catalog-only file must be removed as a whole file'
    }

    Write-Pass -TestName $testName
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
    $null = New-Item -ItemType Directory -Path $installRoot -Force
    $null = New-Item -ItemType Directory -Path $sourceRoot -Force
    Assert-OutsideUserHome -Path $installRoot -TestName 'Assert-PublishOwnershipContractsPreconditions'

    $catalogSkillFile = Invoke-RepublishAlignmentContract -InstallRoot $installRoot -SourceRoot $sourceRoot -SkillsDestination $skillsDestination
    Invoke-IdenticalCatalogReplaceContract -InstallRoot $installRoot
    Invoke-EditedCatalogUninstallContract -InstallRoot $installRoot -SkillsDestination $skillsDestination -CatalogSkillFile $catalogSkillFile
    Invoke-HashWithoutRevisionContract
    Invoke-AdapterCoverageContract
    Invoke-RealHomeUntouchedContract
}
finally {
    Remove-ProbeRoot
}

Write-Host 'Assert-PublishOwnershipContracts: ALL PASS'
exit 0
