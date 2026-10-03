#Requires -Version 5.1
# Tests:
#   Should_ThrowAndNotDelete_When_PoisonManifestSkillName
#   Should_Throw_When_WriteManagedSkillsManifestGetsBadName
#   Should_Throw_When_CopyRelativeWouldEscapeViaParentSegment
#   Should_NotPruneUnknownDirs_When_PreviousManifestEmptyOrMissing
#   Should_PreserveCollidingFilesAndStaleSkills_When_CopyingManagedTree
#   Should_PreserveExistingHookAndRuleFiles_When_PublishingUnownedTargets
#   Should_PreserveExistingGeneratedConfigAndRouter_When_PublishingUnownedTargets
#   Should_NotDeleteAmbiguousPublisherTargets_When_PublishingAdapters
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$managedTreeScript = Join-Path $libDir 'Copy-ToolkitManagedTree.ps1'
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

foreach ($required in @($managedTreeScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-ManagedSkillsPathSafetyPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $managedTreeScript

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

    # --- Should_PreserveCollidingFilesAndStaleSkills_When_CopyingManagedTree ---
    $preserveTest = 'Should_PreserveCollidingFilesAndStaleSkills_When_CopyingManagedTree'
    $copySource = Join-Path $probeRoot 'copy-source'
    $copyDestination = Join-Path $probeRoot 'copy-destination'
    $sourceSkill = Join-Path $copySource 'same-name-skill'
    $destinationSkill = Join-Path $copyDestination 'same-name-skill'
    New-Item -ItemType Directory -Path $sourceSkill,$destinationSkill -Force | Out-Null
    $sourceCollision = Join-Path $sourceSkill 'SKILL.md'
    $destinationCollision = Join-Path $destinationSkill 'SKILL.md'
    [System.IO.File]::WriteAllText($sourceCollision, 'Toolkit {{ROOT}}')
    [System.IO.File]::WriteAllText($destinationCollision, 'Operator content {{ROOT}}')
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
    if ($destinationCollisionText -ne 'Operator content {{ROOT}}') {
        Write-Fail -TestName $preserveTest -Reason 'existing same-name user skill file or its placeholder token was changed'
    }
    if ($newFileText -ne 'Toolkit path resolved-root') {
        Write-Fail -TestName $preserveTest -Reason ("new toolkit file must still receive placeholder resolution; got '{0}'; tracked='{1}'" -f $newFileText, (@($script:ToolkitLastManagedCopyPaths) -join '|'))
    }
    if (-not (Test-Path -LiteralPath $staleFile) -or $copiedStale.Count -ne 0 -or $updatedManifest -notcontains $staleId) {
        Write-Fail -TestName $preserveTest -Reason 'non-empty stale skill directory and manifest key must be preserved'
    }

    Write-Pass -TestName $emptyManifestTest
    Write-Pass -TestName $preserveTest

    # --- Should_PreserveExistingHookAndRuleFiles_When_PublishingUnownedTargets ---
    $hookRuleTest = 'Should_PreserveExistingHookAndRuleFiles_When_PublishingUnownedTargets'
    $publishSource = Join-Path $probeRoot 'publish-source'
    $publishRoot = Join-Path $probeRoot 'publish-root'
    $hookSource = Join-Path $publishSource 'hooks.json'
    $hookTarget = Join-Path (Join-Path $publishRoot 'hooks') 'hooks.json'
    $ruleSource = Join-Path $publishSource 'rtk.md'
    $ruleTarget = Join-Path (Join-Path $publishRoot 'rules') 'rtk.md'
    $configTarget = Join-Path (Join-Path $publishRoot 'config') 'settings.json'
    $routerTarget = Join-Path $publishRoot 'AGENTS.md'
    New-Item -ItemType Directory -Path $publishSource,(Split-Path -Parent $hookTarget),(Split-Path -Parent $ruleTarget),(Split-Path -Parent $configTarget),(Split-Path -Parent $routerTarget) -Force | Out-Null
    [System.IO.File]::WriteAllText($hookSource, '{"hooks":{"RTK":"operator-hook"}}')
    [System.IO.File]::WriteAllText($hookTarget, '{"hooks":{"RTK":"keep-this-hook"}}')
    [System.IO.File]::WriteAllText($ruleSource, 'toolkit rule')
    [System.IO.File]::WriteAllText($ruleTarget, 'operator RTK rule')
    [System.IO.File]::WriteAllText($configTarget, '{"settings":{"RTK":"keep-this-setting"}}')
    [System.IO.File]::WriteAllText($routerTarget, 'operator router content')

    $hookCopied = Copy-ToolkitFileIfAbsent -SourcePath $hookSource -DestinationPath $hookTarget
    $ruleCopied = Copy-ToolkitFileIfAbsent -SourcePath $ruleSource -DestinationPath $ruleTarget
    if ($hookCopied -or $ruleCopied) {
        Write-Fail -TestName $hookRuleTest -Reason 'unowned hook/rule destinations must be preserved'
    }
    if ([System.IO.File]::ReadAllText($hookTarget) -ne '{"hooks":{"RTK":"keep-this-hook"}}' -or
        [System.IO.File]::ReadAllText($ruleTarget) -ne 'operator RTK rule') {
        Write-Fail -TestName $hookRuleTest -Reason 'existing RTK-like hook or unrelated rule content changed'
    }
    Write-Pass -TestName $hookRuleTest

    $generatedCollisionTest = 'Should_PreserveExistingGeneratedConfigAndRouter_When_PublishingUnownedTargets'
    $configWritten = Write-ToolkitFileIfAbsent -Path $configTarget -Content '{"settings":{"toolkit":true}}'
    $routerWritten = Write-ToolkitFileIfAbsent -Path $routerTarget -Content 'toolkit router content'
    if ($configWritten -or $routerWritten -or
        [System.IO.File]::ReadAllText($configTarget) -ne '{"settings":{"RTK":"keep-this-setting"}}' -or
        [System.IO.File]::ReadAllText($routerTarget) -ne 'operator router content') {
        Write-Fail -TestName $generatedCollisionTest -Reason 'existing generated settings or router content changed'
    }
    Write-Pass -TestName $generatedCollisionTest

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
