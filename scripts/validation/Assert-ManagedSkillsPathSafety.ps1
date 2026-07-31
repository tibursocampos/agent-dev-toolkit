#Requires -Version 5.1
# Tests:
#   Should_ThrowAndNotDelete_When_PoisonManifestSkillName
#   Should_Throw_When_WriteManagedSkillsManifestGetsBadName
#   Should_Throw_When_CopyRelativeWouldEscapeViaParentSegment
#   Should_NotPruneUnknownDirs_When_PreviousManifestEmptyOrMissing
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

    Write-Pass -TestName $emptyManifestTest
}
finally {
    Remove-ProbeRoot
}

Write-Host 'Assert-ManagedSkillsPathSafety: ALL PASS'
exit 0
