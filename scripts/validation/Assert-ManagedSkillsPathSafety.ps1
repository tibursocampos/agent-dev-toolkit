#Requires -Version 5.1
# Tests:
#   Should_ThrowAndNotDelete_When_PoisonManifestSkillName
#   Should_Throw_When_WriteManagedSkillsManifestGetsBadName
#   Should_Throw_When_CopyRelativeWouldEscapeViaParentSegment
#   Should_NotPruneUnknownDirs_When_PreviousManifestEmptyOrMissing
#   Should_ReplaceCollidingCatalogFilesAndPreserveStaleSkills_When_CopyingManagedTree
#   Should_ReplaceCatalogHookAndRuleFiles_When_Republishing
#   Should_ReplaceCatalogConfigAndRefreshMarkedRouter_When_Republishing
#   Should_RemoveEditedCatalogSkillsAndOnlyMarkedRouterSection_When_Uninstalling
#   Should_NotDeleteAmbiguousPublisherTargets_When_PublishingAdapters
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$managedTreeScript = Join-Path $libDir 'Copy-ToolkitManagedTree.ps1'
$inventoryScript = Join-Path $libDir 'ToolkitManagedPublishInventory.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

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

foreach ($required in @($managedTreeScript, $inventoryScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-ManagedSkillsPathSafetyPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $managedTreeScript
. $inventoryScript

$probeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("adt-managed-skills-path-safety-" + [Guid]::NewGuid().ToString('N'))
$destinationSkillsRoot = Join-Path $probeRoot 'skills'
$outsideCanaryDir = Join-Path $probeRoot 'outside-canary'
$outsideCanaryFile = Join-Path $outsideCanaryDir 'keep-me.txt'
$staleSkillDir = Join-Path $destinationSkillsRoot 'stale-skill'
$poisonName = '..\..\outside-canary'

function Remove-ProbeRoot {
    if (Test-Path -LiteralPath $probeRoot) {
        Remove-Item -LiteralPath $probeRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Remove-ProbeRoot

try {
    $null = New-Item -ItemType Directory -Path $destinationSkillsRoot -Force
    $null = New-Item -ItemType Directory -Path $outsideCanaryDir -Force
    $null = New-Item -ItemType Directory -Path $staleSkillDir -Force
    [System.IO.File]::WriteAllText($outsideCanaryFile, 'canary')
    [System.IO.File]::WriteAllText((Join-Path $staleSkillDir 'marker.txt'), 'stale')

    # --- Should_ThrowAndNotDelete_When_PoisonManifestSkillName ---
    $poisonNameTest = 'Should_ThrowAndNotDelete_When_PoisonManifestSkillName'
    $manifestPath = Join-Path $destinationSkillsRoot $script:ToolkitConstant.ManagedSkillsManifestFileName
    $skillsProperty = $script:ToolkitConstant.ManagedSkillsManifestSkillsProperty
    $schemaProperty = $script:ToolkitConstant.ManagedSkillsManifestSchemaProperty
    $poisonPayload = [ordered]@{
        $schemaProperty = $script:ToolkitConstant.ManagedSkillsManifestSchemaVersion
        $skillsProperty = @($poisonName)
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($manifestPath, ($poisonPayload | ConvertTo-Json -Depth 5), $utf8NoBom)

    $poisonThrew = $false
    $poisonMessage = $null
    try {
        $null = Sync-ToolkitManagedSkillFolders -DestinationSkillsRoot $destinationSkillsRoot -CurrentSkillNames @('kept-skill')
    }
    catch {
        $poisonThrew = $true
        $poisonMessage = $_.Exception.Message
    }

    if (-not $poisonThrew) {
        Write-Fail -TestName $poisonNameTest -Reason 'expected Sync-ToolkitManagedSkillFolders to throw on poison manifest name'
    }

    if ($poisonMessage -notmatch 'invalid' -and $poisonMessage -notmatch 'escapes') {
        Write-Fail -TestName $poisonNameTest -Reason ("unexpected message: {0}" -f $poisonMessage)
    }

    if (-not (Test-Path -LiteralPath $outsideCanaryFile)) {
        Write-Fail -TestName $poisonNameTest -Reason 'poison prune deleted outside canary; fail-closed required before Remove-Item'
    }

    if (-not (Test-Path -LiteralPath $staleSkillDir)) {
        Write-Fail -TestName $poisonNameTest -Reason 'poison prune must not delete in-dest folders when manifest is rejected'
    }

    Write-Pass -TestName $poisonNameTest

    # --- Should_Throw_When_WriteManagedSkillsManifestGetsBadName ---
    $writeBadNameTest = 'Should_Throw_When_WriteManagedSkillsManifestGetsBadName'
    $badWriteNames = @(
        $poisonName,
        '..',
        'a/b',
        'a\b',
        '',
        'C:\Windows'
    )

    foreach ($badName in $badWriteNames) {
        $writeThrew = $false
        try {
            $null = Write-ToolkitManagedSkillsManifest -DestinationSkillsRoot $destinationSkillsRoot -SkillNames @($badName)
        }
        catch {
            $writeThrew = $true
        }

        if (-not $writeThrew) {
            $label = if ([string]::IsNullOrEmpty($badName)) { '<empty>' } else { $badName }
            Write-Fail -TestName $writeBadNameTest -Reason ("expected Write-ToolkitManagedSkillsManifest throw for '{0}'" -f $label)
        }
    }

    Write-Pass -TestName $writeBadNameTest

    # --- Should_Throw_When_CopyRelativeWouldEscapeViaParentSegment ---
    $copyEscapeTest = 'Should_Throw_When_CopyRelativeWouldEscapeViaParentSegment'
    $hasParent = Test-ToolkitManagedRelativeHasParentSegment -RelativePath ('sub\' + $script:ToolkitConstant.RelativeParentPathSegment + '\x.txt')
    if (-not $hasParent) {
        Write-Fail -TestName $copyEscapeTest -Reason 'expected parent-segment detector to flag .. in relative path'
    }

    $noParent = Test-ToolkitManagedRelativeHasParentSegment -RelativePath 'skill-a\SKILL.md'
    if ($noParent) {
        Write-Fail -TestName $copyEscapeTest -Reason 'detector false-positive on safe relative path'
    }

    $nameThrew = $false
    try {
        $null = Assert-ToolkitManagedSkillName -SkillName $poisonName
    }
    catch {
        $nameThrew = $true
    }

    if (-not $nameThrew) {
        Write-Fail -TestName $copyEscapeTest -Reason 'expected Assert-ToolkitManagedSkillName to reject poison name'
    }

    Write-Pass -TestName $copyEscapeTest

    # --- Should_NotPruneUnknownDirs_When_PreviousManifestEmptyOrMissing ---
    # RN07 alien-safe bootstrap: missing/empty previous manifest => no prune of unknown dirs.
    $emptyManifestTest = 'Should_NotPruneUnknownDirs_When_PreviousManifestEmptyOrMissing'
    $alienSkillDir = Join-Path $destinationSkillsRoot 'operator-custom-skill'
    $retiredLookingDir = Join-Path $destinationSkillsRoot 'looks-like-retired-skill'
    $null = New-Item -ItemType Directory -Path $alienSkillDir -Force
    $null = New-Item -ItemType Directory -Path $retiredLookingDir -Force
    [System.IO.File]::WriteAllText((Join-Path $alienSkillDir 'SKILL.md'), 'alien')
    [System.IO.File]::WriteAllText((Join-Path $retiredLookingDir 'SKILL.md'), 'unknown')

    if (Test-Path -LiteralPath $manifestPath) {
        Remove-Item -LiteralPath $manifestPath -Force
    }

    $prunedMissing = @(Sync-ToolkitManagedSkillFolders -DestinationSkillsRoot $destinationSkillsRoot -CurrentSkillNames @('kept-skill'))
    if ($prunedMissing.Count -ne 0) {
        Write-Fail -TestName $emptyManifestTest -Reason ("missing manifest must prune nothing; got: {0}" -f ($prunedMissing -join ','))
    }
    if (-not (Test-Path -LiteralPath $alienSkillDir) -or -not (Test-Path -LiteralPath $retiredLookingDir)) {
        Write-Fail -TestName $emptyManifestTest -Reason 'missing manifest must not delete unknown kebab skill dirs'
    }
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Write-Fail -TestName $emptyManifestTest -Reason 'sync must write current managed-skills manifest after empty bootstrap'
    }

    $emptyPayload = [ordered]@{
        $schemaProperty = $script:ToolkitConstant.ManagedSkillsManifestSchemaVersion
        $skillsProperty = @()
    }
    [System.IO.File]::WriteAllText($manifestPath, ($emptyPayload | ConvertTo-Json -Depth 5), $utf8NoBom)
    $prunedEmpty = @(Sync-ToolkitManagedSkillFolders -DestinationSkillsRoot $destinationSkillsRoot -CurrentSkillNames @('kept-skill'))
    if ($prunedEmpty.Count -ne 0) {
        Write-Fail -TestName $emptyManifestTest -Reason ("empty skills[] manifest must prune nothing; got: {0}" -f ($prunedEmpty -join ','))
    }
    if (-not (Test-Path -LiteralPath $alienSkillDir) -or -not (Test-Path -LiteralPath $retiredLookingDir)) {
        Write-Fail -TestName $emptyManifestTest -Reason 'empty skills[] manifest must not delete unknown kebab skill dirs'
    }

    # --- Should_ReplaceCollidingCatalogFilesAndPreserveStaleSkills_When_CopyingManagedTree ---
    $preserveTest = 'Should_ReplaceCollidingCatalogFilesAndPreserveStaleSkills_When_CopyingManagedTree'
    $copySource = Join-Path $probeRoot 'copy-source'
    $copyDestination = Join-Path $probeRoot 'copy-destination'
    $sourceSkill = Join-Path $copySource 'same-name-skill'
    $destinationSkill = Join-Path $copyDestination 'same-name-skill'
    New-Item -ItemType Directory -Path $sourceSkill,$destinationSkill -Force | Out-Null
    $sourceCollision = Join-Path $sourceSkill 'SKILL.md'
    $destinationCollision = Join-Path $destinationSkill 'SKILL.md'
    [System.IO.File]::WriteAllText($sourceCollision, 'Toolkit {{ROOT}}')
    [System.IO.File]::WriteAllText($destinationCollision, 'Operator content {{ROOT}}')
    $operatorSidecar = Join-Path $destinationSkill 'operator-notes.txt'
    [System.IO.File]::WriteAllText($operatorSidecar, 'keep operator sidecar')
    $newSourceFile = Join-Path $sourceSkill 'new-reference.md'
    [System.IO.File]::WriteAllText($newSourceFile, 'Toolkit path {{ROOT}}')
    $staleId = 'retired-skill'
    $staleDir = Join-Path $copyDestination $staleId
    New-Item -ItemType Directory -Path $staleDir -Force | Out-Null
    $staleFile = Join-Path $staleDir 'operator-data.txt'
    [System.IO.File]::WriteAllText($staleFile, 'preserve this')
    $null = Write-ToolkitManagedSkillsManifest -DestinationSkillsRoot $copyDestination -SkillNames @('same-name-skill', $staleId)

    $null = Copy-ToolkitManagedTree -SourceRoot $copySource -DestinationRoot $copyDestination
    Resolve-ToolkitPlaceholdersInTree -RootPath $copyDestination -PlaceholderMap @{ '{{ROOT}}' = 'resolved-root' }
    $copiedStale = @(Sync-ToolkitManagedSkillFolders -DestinationSkillsRoot $copyDestination -CurrentSkillNames @('same-name-skill'))
    $destinationCollisionText = [System.IO.File]::ReadAllText($destinationCollision)
    $newFileText = [System.IO.File]::ReadAllText((Join-Path $destinationSkill 'new-reference.md'))
    $updatedManifest = Read-ToolkitManagedSkillsManifest -DestinationSkillsRoot $copyDestination
    if ($destinationCollisionText -ne 'Toolkit resolved-root') {
        Write-Fail -TestName $preserveTest -Reason ("catalog skill file must match source after placeholder transform; got '{0}'" -f $destinationCollisionText)
    }
    if ([System.IO.File]::ReadAllText($operatorSidecar) -ne 'keep operator sidecar') {
        Write-Fail -TestName $preserveTest -Reason 'non-catalog sidecar inside a skill folder must stay untouched'
    }
    if ($newFileText -ne 'Toolkit path resolved-root') {
        Write-Fail -TestName $preserveTest -Reason ("new toolkit file must still receive placeholder resolution; got '{0}'; tracked='{1}'" -f $newFileText, (@($script:ToolkitLastManagedCopyPaths) -join '|'))
    }
    if (-not (Test-Path -LiteralPath $staleFile) -or $copiedStale.Count -ne 0 -or $updatedManifest -notcontains $staleId) {
        Write-Fail -TestName $preserveTest -Reason 'non-empty stale skill directory and manifest key must be preserved'
    }

    Write-Pass -TestName $emptyManifestTest
    Write-Pass -TestName $preserveTest

    # --- Should_ReplaceCatalogHookAndRuleFiles_When_Republishing ---
    $hookRuleTest = 'Should_ReplaceCatalogHookAndRuleFiles_When_Republishing'
    $publishSource = Join-Path $probeRoot 'publish-source'
    $publishRoot = Join-Path $probeRoot 'publish-root'
    $hookSource = Join-Path $publishSource 'hooks.json'
    $hookTarget = Join-Path (Join-Path $publishRoot 'hooks') 'hooks.json'
    $ruleSource = Join-Path $publishSource 'rtk.md'
    $ruleTarget = Join-Path (Join-Path $publishRoot 'rules') 'rtk.md'
    $configTarget = Join-Path (Join-Path $publishRoot 'config') 'settings.json'
    $routerTarget = Join-Path $publishRoot 'AGENTS.md'
    $secretTarget = Join-Path $publishRoot 'operator-secret.txt'
    New-Item -ItemType Directory -Path $publishSource,(Split-Path -Parent $hookTarget),(Split-Path -Parent $ruleTarget),(Split-Path -Parent $configTarget),(Split-Path -Parent $routerTarget) -Force | Out-Null
    [System.IO.File]::WriteAllText($hookSource, '{"hooks":{"RTK":"source-hook"}}')
    [System.IO.File]::WriteAllText($hookTarget, '{"hooks":{"RTK":"keep-this-hook"}}')
    [System.IO.File]::WriteAllText($ruleSource, 'toolkit rule')
    [System.IO.File]::WriteAllText($ruleTarget, 'operator RTK rule')
    [System.IO.File]::WriteAllText($configTarget, '{"settings":{"RTK":"keep-this-setting"}}')
    $beginMarker = $script:ToolkitConstant.ManagedBlockBeginMarker
    $endMarker = $script:ToolkitConstant.ManagedBlockEndMarker
    $routerBefore = "operator preface`n$beginMarker`nold toolkit section`n$endMarker`noperator after`n"
    [System.IO.File]::WriteAllText($routerTarget, $routerBefore)
    [System.IO.File]::WriteAllText($secretTarget, 'do not touch secret')

    $hookCopied = Copy-ToolkitFileIfAbsent -SourcePath $hookSource -DestinationPath $hookTarget
    $ruleCopied = Copy-ToolkitFileIfAbsent -SourcePath $ruleSource -DestinationPath $ruleTarget
    if (-not $hookCopied -or -not $ruleCopied) {
        Write-Fail -TestName $hookRuleTest -Reason 'catalog hook and rule destinations must be replaced'
    }
    if ([System.IO.File]::ReadAllText($hookTarget) -ne '{"hooks":{"RTK":"source-hook"}}' -or
        [System.IO.File]::ReadAllText($ruleTarget) -ne 'toolkit rule') {
        Write-Fail -TestName $hookRuleTest -Reason 'catalog hook or rule content must match the source'
    }
    if ([System.IO.File]::ReadAllText($secretTarget) -ne 'do not touch secret') {
        Write-Fail -TestName $hookRuleTest -Reason 'non-catalog secret file must stay untouched'
    }
    Write-Pass -TestName $hookRuleTest

    $generatedCollisionTest = 'Should_ReplaceCatalogConfigAndRefreshMarkedRouter_When_Republishing'
    $configWritten = Write-ToolkitFileIfAbsent -Path $configTarget -Content '{"settings":{"toolkit":true}}'
    $routerIncoming = "$beginMarker`nnew toolkit section`n$endMarker"
    $routerWritten = Write-ToolkitFileIfAbsent -Path $routerTarget -Content $routerIncoming
    $routerAfter = [System.IO.File]::ReadAllText($routerTarget)
    if (-not $configWritten -or [System.IO.File]::ReadAllText($configTarget) -ne '{"settings":{"toolkit":true}}') {
        Write-Fail -TestName $generatedCollisionTest -Reason 'catalog settings file must be replaced with the published content'
    }
    if (-not $routerWritten -or $routerAfter -notmatch 'operator preface' -or $routerAfter -notmatch 'operator after' -or $routerAfter -notmatch 'new toolkit section' -or $routerAfter -match 'old toolkit section') {
        Write-Fail -TestName $generatedCollisionTest -Reason 'marked router must refresh only the toolkit section'
    }

    $claudeTarget = Join-Path $publishRoot 'CLAUDE.md'
    $hermesBegin = $script:ToolkitConstant.HermesManagedAgentsBeginMarker
    $hermesEnd = $script:ToolkitConstant.HermesManagedAgentsEndMarker
    [System.IO.File]::WriteAllText($claudeTarget, "operator preface`n$hermesBegin`nold hermes section`n$hermesEnd`noperator after`n")
    $claudeWritten = Write-ToolkitFileIfAbsent -Path $claudeTarget -Content "$hermesBegin`nnew hermes section`n$hermesEnd"
    $claudeAfter = [System.IO.File]::ReadAllText($claudeTarget)
    if (-not $claudeWritten -or $claudeAfter -notmatch 'operator preface' -or $claudeAfter -notmatch 'operator after' -or $claudeAfter -notmatch 'new hermes section' -or $claudeAfter -match 'old hermes section') {
        Write-Fail -TestName $generatedCollisionTest -Reason 'marked CLAUDE.md must refresh only the toolkit section'
    }
    Write-Pass -TestName $generatedCollisionTest

    $uninstallTest = 'Should_RemoveEditedCatalogSkillsAndOnlyMarkedRouterSection_When_Uninstalling'
    $installRoot = Join-Path $probeRoot 'uninstall-root'
    $sourceRoot = Join-Path $probeRoot 'uninstall-source'
    $skillsDest = Join-Path $installRoot 'skills'
    $sourceSkillDir = Join-Path $sourceRoot 'sample-skill'
    New-Item -ItemType Directory -Path $sourceSkillDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $sourceSkillDir 'SKILL.md'), "catalog skill body`n")
    $null = Copy-ToolkitManagedTree -SourceRoot $sourceRoot -DestinationRoot $skillsDest -InstallRoot $installRoot
    $null = Write-ToolkitManagedSkillsManifest -DestinationSkillsRoot $skillsDest -SkillNames @('sample-skill')
    $catalogSkillFile = Join-Path (Join-Path $skillsDest 'sample-skill') 'SKILL.md'
    [System.IO.File]::AppendAllText($catalogSkillFile, "operator-edit-marker`n")
    $sidecarPath = Join-Path (Join-Path $skillsDest 'sample-skill') 'operator-note.txt'
    [System.IO.File]::WriteAllText($sidecarPath, "keep sidecar`n")
    $alienSkillDir = Join-Path $skillsDest 'alien-skill'
    New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
    $alienSkillFile = Join-Path $alienSkillDir 'SKILL.md'
    [System.IO.File]::WriteAllText($alienSkillFile, "alien skill`n")
    $secretPath = Join-Path $installRoot 'operator-secret.txt'
    [System.IO.File]::WriteAllText($secretPath, "do not touch secret`n")

    $beginMarker = $script:ToolkitConstant.ManagedBlockBeginMarker
    $endMarker = $script:ToolkitConstant.ManagedBlockEndMarker
    $agentsTarget = Join-Path $installRoot 'AGENTS.md'
    [System.IO.File]::WriteAllText($agentsTarget, "operator preface`n$beginMarker`ntoolkit section`n$endMarker`noperator after`n")
    $hermesBegin = $script:ToolkitConstant.HermesManagedAgentsBeginMarker
    $hermesEnd = $script:ToolkitConstant.HermesManagedAgentsEndMarker
    $claudeTarget = Join-Path $installRoot 'CLAUDE.md'
    [System.IO.File]::WriteAllText($claudeTarget, "operator preface`n$hermesBegin`nhermes toolkit section`n$hermesEnd`noperator after`n")
    $catalogRouterTarget = Join-Path $installRoot 'CATALOG.md'
    $null = Write-ToolkitFileIfAbsent -Path $catalogRouterTarget -Content "catalog router`n" -InstallRoot $installRoot -RelativePath 'CATALOG.md'
    [System.IO.File]::WriteAllText($catalogRouterTarget, "catalog router edited`n")

    $skillRemoval = Remove-ToolkitManagedSkillsByInventory `
        -InstallRoot $installRoot `
        -DestinationSkillsRoots @($skillsDest) `
        -SkillIds @('sample-skill')
    if (Test-Path -LiteralPath $catalogSkillFile) {
        Write-Fail -TestName $uninstallTest -Reason 'edited catalog skill file must be removed'
    }
    if (-not (Test-Path -LiteralPath $sidecarPath) -or [System.IO.File]::ReadAllText($sidecarPath) -notmatch 'keep sidecar') {
        Write-Fail -TestName $uninstallTest -Reason 'non-catalog sidecar inside a skill folder must stay'
    }
    if (-not (Test-Path -LiteralPath $alienSkillFile)) {
        Write-Fail -TestName $uninstallTest -Reason 'alien skill must stay'
    }
    if (-not (Test-Path -LiteralPath $installRoot -PathType Container)) {
        Write-Fail -TestName $uninstallTest -Reason 'InstallRoot must stay'
    }
    if (-not (Test-Path -LiteralPath $secretPath)) {
        Write-Fail -TestName $uninstallTest -Reason 'non-catalog secret must stay'
    }

    $agentsRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $installRoot `
        -RelativePath 'AGENTS.md' `
        -CurrentFilePath $agentsTarget `
        -ResolveExpectedPublishContent { 'unused' }
    $agentsAfter = [System.IO.File]::ReadAllText($agentsTarget)
    if ($agentsRemoval.Removed -or -not (Test-Path -LiteralPath $agentsTarget) -or $agentsAfter -match [regex]::Escape($beginMarker) -or $agentsAfter -notmatch 'operator preface' -or $agentsAfter -notmatch 'operator after') {
        Write-Fail -TestName $uninstallTest -Reason 'mixed AGENTS.md must lose only the toolkit section'
    }
    $claudeRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $installRoot `
        -RelativePath 'CLAUDE.md' `
        -CurrentFilePath $claudeTarget `
        -ResolveExpectedPublishContent { 'unused' }
    $claudeAfter = [System.IO.File]::ReadAllText($claudeTarget)
    if ($claudeRemoval.Removed -or -not (Test-Path -LiteralPath $claudeTarget) -or $claudeAfter -match [regex]::Escape($hermesBegin) -or $claudeAfter -notmatch 'operator preface' -or $claudeAfter -notmatch 'operator after') {
        Write-Fail -TestName $uninstallTest -Reason 'mixed CLAUDE.md must lose only the toolkit section'
    }
    $catalogRouterRemoval = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $installRoot `
        -RelativePath 'CATALOG.md' `
        -CurrentFilePath $catalogRouterTarget `
        -ResolveExpectedPublishContent { 'catalog router' }
    if (-not $catalogRouterRemoval.Removed -or (Test-Path -LiteralPath $catalogRouterTarget)) {
        Write-Fail -TestName $uninstallTest -Reason 'edited catalog-only router must be removed as a whole file'
    }

    $outsideFile = Join-Path $probeRoot 'outside-install-root.txt'
    [System.IO.File]::WriteAllText($outsideFile, "outside`n")
    $outsideThrew = $false
    try {
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $outsideFile -InstallRoot $installRoot
    }
    catch {
        $outsideThrew = $true
    }
    if (-not $outsideThrew -or -not (Test-Path -LiteralPath $outsideFile)) {
        Write-Fail -TestName $uninstallTest -Reason 'a delete candidate outside InstallRoot must not be deleted'
    }
    $rootThrew = $false
    try {
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $installRoot -InstallRoot $installRoot
    }
    catch {
        $rootThrew = $true
    }
    if (-not $rootThrew -or -not (Test-Path -LiteralPath $installRoot -PathType Container)) {
        Write-Fail -TestName $uninstallTest -Reason 'InstallRoot itself must not be deleted'
    }
    Write-Pass -TestName $uninstallTest

    $publisherDeleteTest = 'Should_NotDeleteAmbiguousPublisherTargets_When_PublishingAdapters'
    $repoRoot = Split-Path -Parent $scriptsRoot
    $cleanupChecks = @(
        [PSCustomObject]@{ Path = (Join-Path $repoRoot 'adapters/codex/Publish-CodexSkills.ps1'); Pattern = 'Remove-Item[^\r\n]*\$extra\.FullName' },
        [PSCustomObject]@{ Path = (Join-Path $repoRoot 'adapters/codex/Publish-CodexHooks.ps1'); Pattern = 'Remove-Item[^\r\n]*\$legacySession' },
        [PSCustomObject]@{ Path = (Join-Path $repoRoot 'adapters/codex/Publish-CodexAgents.ps1'); Pattern = 'Remove-Item[^\r\n]*\$staleMd' },
        [PSCustomObject]@{ Path = (Join-Path $repoRoot 'adapters/copilot/Publish-CopilotAgents.ps1'); Pattern = 'Remove-Item[^\r\n]*\$legacyPath' }
    )
    foreach ($check in $cleanupChecks) {
        $publisherText = [System.IO.File]::ReadAllText($check.Path)
        if ($publisherText -match $check.Pattern) {
            Write-Fail -TestName $publisherDeleteTest -Reason ("ambiguous cleanup remains in {0}" -f $check.Path)
        }
    }
    Write-Pass -TestName $publisherDeleteTest
}
finally {
    Remove-ProbeRoot
}

Write-Host 'Assert-ManagedSkillsPathSafety: ALL PASS'
exit 0
