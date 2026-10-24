#Requires -Version 5.1
# Tests:
#   Should_UseFixtureInstallRoot_When_SmokeHarnessRuns
#   Should_NotWriteUserCursorProfile_When_SmokeHarnessRuns
#   Should_Fail_When_InstallRootIsUserProfileWithoutAllow
#   Should_Fail_When_BootstrapChecksumMismatch_Te01
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$harnessScript = Join-Path $scriptDir 'Invoke-SmokeHarness.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$resolveInstallRootScript = Join-Path $libDir 'Resolve-InstallRoot.ps1'
$ephemeralSmokeScript = Join-Path $libDir 'Invoke-EphemeralFixtureSmoke.ps1'

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

function Invoke-ScriptCapture {
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter()][string[]] $ArgumentList = @()
    )

    $runner = (Get-Process -Id $PID).Path
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # PowerShell 5.1 promotes a child's expected non-zero stderr to NativeCommandError
        # when the caller uses $ErrorActionPreference=Stop. Keep that captured output non-terminating.
        $ErrorActionPreference = 'Continue'
        $output = & $runner -NoProfile -File $ScriptPath @ArgumentList 2>&1 | Out-String
        $code = $LASTEXITCODE
        if ($null -eq $code) {
            $code = 0
        }

        return [PSCustomObject]@{
            ExitCode = [int]$code
            Output   = $output
        }
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Get-DirectorySnapshotFingerprint {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return 'missing'
    }

    $items = @(
        Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            ForEach-Object {
                $size = 0
                if (-not $_.PSIsContainer) {
                    $size = $_.Length
                }
                # Path + type + size only - ignore LastWriteTimeUtc so a live Cursor IDE
                # touching ~/.cursor does not false-fail this assert (mirrors Invoke-SmokeHarness).
                '{0}|{1}|{2}' -f $_.FullName, $_.PSIsContainer, $size
            }
    )

    if ($items.Count -eq 0) {
        return 'empty'
    }

    return ($items -join "`n")
}

foreach ($required in @($harnessScript, $constantsScript, $repoRootScript, $resolveInstallRootScript, $ephemeralSmokeScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-SmokeHarnessSafetyPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
. $resolveInstallRootScript
. $ephemeralSmokeScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$fixtureInstallRoot = Join-Path $repoRoot ($script:ToolkitConstant.DefaultFixtureInstallRootRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixtureReadme = Join-Path $fixtureInstallRoot 'README.md'

if (-not (Test-Path -LiteralPath $fixtureReadme)) {
    Write-Fail -TestName 'Assert-SmokeHarnessSafetyPreconditions' -Reason ("fixture seed missing: {0}" -f $fixtureReadme)
}

# --- Should_CopyOnlyGitIndexedFiles_FromRepositoryFixtureSeeds ---
$trackedSeedName = 'Should_CopyOnlyGitIndexedFiles_FromRepositoryFixtureSeeds'
$trackedSeedRepo = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-smoke-seed-index-' + [Guid]::NewGuid().ToString('N'))
$previousSmokeRepoRoot = $script:EphemeralSmokeRepoRoot
try {
    $seedRoot = Join-Path $trackedSeedRepo 'scripts/validation/fixtures/seed'
    $externalSeedRoot = Join-Path $trackedSeedRepo 'external-seed'
    New-Item -ItemType Directory -Path $seedRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $externalSeedRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $trackedSeedRepo '.gitignore') -Value '/scripts/validation/fixtures/seed/ignored.txt' -Encoding ASCII
    [System.IO.File]::WriteAllText((Join-Path $seedRoot 'tracked.txt'), 'tracked-seed')
    [System.IO.File]::WriteAllText((Join-Path $seedRoot 'deleted-unstaged.txt'), 'deleted-seed')

    function Invoke-SmokeSafetyGit {
        param([Parameter(Mandatory = $true)][string] $Path, [Parameter(Mandatory = $true)][string[]] $GitArgs)
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & git -C $Path @GitArgs 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousPreference
        }
        if ($exitCode -ne 0) {
            throw ("git {0} failed ({1}): {2}" -f ($GitArgs -join ' '), $exitCode, $output.Trim())
        }
        return $output
    }

    $null = Invoke-SmokeSafetyGit -Path $trackedSeedRepo -GitArgs @('init', '--quiet')
    $null = Invoke-SmokeSafetyGit -Path $trackedSeedRepo -GitArgs @('add', '--', '.gitignore', 'scripts/validation/fixtures/seed/tracked.txt', 'scripts/validation/fixtures/seed/deleted-unstaged.txt')
    $null = Invoke-SmokeSafetyGit -Path $trackedSeedRepo -GitArgs @('-c', 'user.name=Smoke Safety Test', '-c', 'user.email=smoke-safety@example.invalid', 'commit', '--quiet', '-m', 'seed')
    $ignoredCheck = Invoke-SmokeSafetyGit -Path $trackedSeedRepo -GitArgs @('check-ignore', '--', 'scripts/validation/fixtures/seed/ignored.txt')
    if ($ignoredCheck -notmatch 'ignored\.txt') {
        Write-Fail -TestName $trackedSeedName -Reason 'temporary repository did not recognize the ignored seed file'
    }

    Set-Content -LiteralPath (Join-Path $seedRoot 'ignored.txt') -Value 'ignored' -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $seedRoot 'untracked.txt') -Value 'untracked' -Encoding ASCII
    Remove-Item -LiteralPath (Join-Path $seedRoot 'deleted-unstaged.txt') -Force
    $generatedOnlyDirectory = Join-Path $seedRoot 'generated-only/nested'
    New-Item -ItemType Directory -Path $generatedOnlyDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $generatedOnlyDirectory 'output.txt') -Value 'generated' -Encoding ASCII

    $script:EphemeralSmokeRepoRoot = [System.IO.Path]::GetFullPath($trackedSeedRepo)
    $seedIndex = Get-EphemeralSmokeFixtureSeedFiles -SeedFixtureRoot $seedRoot
    $indexPaths = @(Invoke-SmokeSafetyGit -Path $trackedSeedRepo -GitArgs @('ls-files', '--', 'scripts/validation/fixtures/seed')) -split "`r?`n"
    if ($indexPaths -notcontains 'scripts/validation/fixtures/seed/deleted-unstaged.txt') {
        Write-Fail -TestName $trackedSeedName -Reason 'test setup did not preserve the deleted file in the Git index'
    }
    if (-not $seedIndex.IsFixtureSeed -or @($seedIndex.Files).Count -ne 1 -or $seedIndex.Files[0].RelativePath -ne 'tracked.txt') {
        Write-Fail -TestName $trackedSeedName -Reason ("expected only existing tracked.txt from the fixture index, got: {0}" -f (@($seedIndex.Files | ForEach-Object { $_.RelativePath }) -join ', '))
    }

    $snapshotBeforeGeneratedChange = Get-EphemeralSmokeTrackedTreeState -Root $seedRoot -Role 'safety test seed' -TrackedFiles @($seedIndex.Files | ForEach-Object { $_.FullPath })
    Set-Content -LiteralPath (Join-Path $seedRoot 'ignored.txt') -Value 'ignored output changed after source snapshot' -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $generatedOnlyDirectory 'output.txt') -Value 'generated output changed after source snapshot' -Encoding ASCII
    $snapshotAfterGeneratedChange = Get-EphemeralSmokeTrackedTreeState -Root $seedRoot -Role 'safety test seed' -TrackedFiles @($seedIndex.Files | ForEach-Object { $_.FullPath })
    Assert-EphemeralSmokeTreeStateUnchanged -Before $snapshotBeforeGeneratedChange -After $snapshotAfterGeneratedChange -Role 'safety test seed'

    $snapshotBeforeTrackedChange = Get-EphemeralSmokeTrackedTreeState -Root $seedRoot -Role 'safety test seed' -TrackedFiles @($seedIndex.Files | ForEach-Object { $_.FullPath })
    [System.IO.File]::AppendAllText((Join-Path $seedRoot 'tracked.txt'), '-changed')
    $snapshotAfterTrackedChange = Get-EphemeralSmokeTrackedTreeState -Root $seedRoot -Role 'safety test seed' -TrackedFiles @($seedIndex.Files | ForEach-Object { $_.FullPath })
    $trackedMutationRejected = $false
    try {
        Assert-EphemeralSmokeTreeStateUnchanged -Before $snapshotBeforeTrackedChange -After $snapshotAfterTrackedChange -Role 'safety test seed'
    }
    catch {
        if ($_.Exception.Message -notmatch '(?i)changed|final validation') {
            throw
        }
        $trackedMutationRejected = $true
    }
    if (-not $trackedMutationRejected) {
        Write-Fail -TestName $trackedSeedName -Reason 'accepted a changed tracked source file'
    }
    [System.IO.File]::WriteAllText((Join-Path $seedRoot 'tracked.txt'), 'tracked-seed')

    $trackedWorkRoot = Join-Path $trackedSeedRepo 'tracked-work'
    New-Item -ItemType Directory -Path $trackedWorkRoot -Force | Out-Null
    Copy-EphemeralSmokeSeedTree -SeedFixtureRoot $seedRoot -WorkInstallRoot $trackedWorkRoot
    if (-not (Test-Path -LiteralPath (Join-Path $trackedWorkRoot 'tracked.txt'))) {
        Write-Fail -TestName $trackedSeedName -Reason 'tracked seed file was not copied'
    }
    foreach ($excludedPath in @(
        (Join-Path $trackedWorkRoot 'ignored.txt'),
        (Join-Path $trackedWorkRoot 'untracked.txt'),
        (Join-Path $trackedWorkRoot 'generated-only')
    )) {
        if (Test-Path -LiteralPath $excludedPath) {
            Write-Fail -TestName $trackedSeedName -Reason ("non-indexed seed content was copied: {0}" -f $excludedPath)
        }
    }

    Set-Content -LiteralPath (Join-Path $externalSeedRoot 'tracked.txt') -Value 'external tracked' -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $externalSeedRoot 'untracked.txt') -Value 'external untracked' -Encoding ASCII
    $externalWorkRoot = Join-Path $trackedSeedRepo 'external-work'
    New-Item -ItemType Directory -Path $externalWorkRoot -Force | Out-Null
    Copy-EphemeralSmokeSeedTree -SeedFixtureRoot $externalSeedRoot -WorkInstallRoot $externalWorkRoot
    if (-not (Test-Path -LiteralPath (Join-Path $externalWorkRoot 'tracked.txt')) -or
        -not (Test-Path -LiteralPath (Join-Path $externalWorkRoot 'untracked.txt'))) {
        Write-Fail -TestName $trackedSeedName -Reason 'non-fixture source did not retain full-tree copy behavior'
    }
}
catch {
    Write-Fail -TestName $trackedSeedName -Reason $_.Exception.Message
}
finally {
    $script:EphemeralSmokeRepoRoot = $previousSmokeRepoRoot
    if (Test-Path -LiteralPath $trackedSeedRepo) {
        Remove-Item -LiteralPath $trackedSeedRepo -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Pass -TestName $trackedSeedName

# --- Should_Reject_UnsafeEphemeralFixturePaths ---
$unsafePathsName = 'Should_Reject_UnsafeEphemeralFixturePaths'
$unsafePathCases = @(
    ([System.IO.Path]::GetFullPath((Join-Path $repoRoot 'scripts/validation/fixtures/install-root'))),
    '..\outside-fixture'
)
foreach ($unsafePath in $unsafePathCases) {
    try {
        Invoke-EphemeralFixtureSmoke -RepoRoot $repoRoot -SeedFixtureRel $unsafePath -WorkFixtureRel 'scripts/validation/fixtures/smoke-safety-work' -AgentId 'safety-test' | Out-Null
        Write-Fail -TestName $unsafePathsName -Reason ("accepted unsafe seed path: {0}" -f $unsafePath)
    }
    catch {
        if ($_.Exception.Message -notmatch '(?i)absolute|parent|outside|refus') {
            Write-Fail -TestName $unsafePathsName -Reason ("unexpected unsafe-path error for {0}: {1}" -f $unsafePath, $_.Exception.Message)
        }
    }
}
Write-Pass -TestName $unsafePathsName

# --- Should_FailClosed_When_EphemeralTreeChanges ---
$treeChangeName = 'Should_FailClosed_When_EphemeralTreeChanges'
$treeState = [PSCustomObject]@{
    Path = 'fixture/file.txt'
    Attributes = 0
    Length = [int64]1
    LastWriteTimeUtc = [int64]10
}
$changedTreeState = [PSCustomObject]@{
    Path = 'fixture/file.txt'
    Attributes = 0
    Length = [int64]2
    LastWriteTimeUtc = [int64]11
}
try {
    Assert-EphemeralSmokeTreeStateUnchanged -Before @($treeState) -After @($changedTreeState) -Role 'safety test'
    Write-Fail -TestName $treeChangeName -Reason 'accepted a changed deletion tree'
}
catch {
    if ($_.Exception.Message -notmatch '(?i)changed|final validation') {
        Write-Fail -TestName $treeChangeName -Reason ("unexpected tree-change error: {0}" -f $_.Exception.Message)
    }
}
Write-Pass -TestName $treeChangeName

# --- Should_Keep_EphemeralMutationGuards_InSharedRunner ---
$guardContractName = 'Should_Keep_EphemeralMutationGuards_InSharedRunner'
$ephemeralSmokeText = Get-Content -LiteralPath $ephemeralSmokeScript -Raw
foreach ($requiredMarker in @(
    'Assert-EphemeralSmokeSeedWrite',
    'Assert-EphemeralSmokeDeleteTarget',
    'Assert-EphemeralSmokeTreeStateUnchanged',
    'Enter-EphemeralSmokeFilesystemGate',
    '.toolkit-ephemeral-smoke.lock',
    'FileAttributes]::ReparsePoint',
    'residual race',
    'hostile concurrent'
)) {
    if ($ephemeralSmokeText -notmatch [regex]::Escape($requiredMarker)) {
        Write-Fail -TestName $guardContractName -Reason ("missing fail-closed guard marker: {0}" -f $requiredMarker)
    }
}
Write-Pass -TestName $guardContractName

$userProfile = Get-ToolkitUserHome
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    $userProfile = [Environment]::GetEnvironmentVariable($script:ToolkitConstant.UserProfileEnvironmentName)
}
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    $userProfile = [Environment]::GetEnvironmentVariable($script:ToolkitConstant.HomeEnvironmentName)
}
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-SmokeHarnessSafetyPreconditions' -Reason 'user home is not set (USERPROFILE / HOME)'
}

$cursorProfilePath = Join-Path $userProfile $script:ToolkitConstant.UserCursorProfileRelativePath

# Preserve a pre-existing ignored marker, and remove the marker generated by
# this test when the shared fixture was clean before the run.
$markerPath = Join-Path $fixtureInstallRoot $script:ToolkitConstant.SmokeHarnessMarkerFileName
$markerWasPresent = Test-Path -LiteralPath $markerPath
$previousMarkerBytes = if ($markerWasPresent) { [System.IO.File]::ReadAllBytes($markerPath) } else { $null }
try {
# --- Should_UseFixtureInstallRoot_When_SmokeHarnessRuns ---
$useFixtureName = 'Should_UseFixtureInstallRoot_When_SmokeHarnessRuns'
$useFixture = Invoke-ScriptCapture -ScriptPath $harnessScript -ArgumentList @('-SkipAdapterSmoke')
if ($useFixture.ExitCode -ne 0) {
    Write-Fail -TestName $useFixtureName -Reason ("harness exit {0}: {1}" -f $useFixture.ExitCode, $useFixture.Output.Trim())
}

$expectedFixtureFull = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
if ($useFixture.Output -notmatch [regex]::Escape($expectedFixtureFull) -and $useFixture.Output -notmatch [regex]::Escape($fixtureInstallRoot)) {
    Write-Fail -TestName $useFixtureName -Reason ("expected fixture InstallRoot in output: {0}" -f $useFixture.Output.Trim())
}

if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Fail -TestName $useFixtureName -Reason ("expected smoke marker under fixture: {0}" -f $markerPath)
}

Write-Pass -TestName $useFixtureName

# --- Should_NotWriteUserCursorProfile_When_SmokeHarnessRuns ---
$noHomeName = 'Should_NotWriteUserCursorProfile_When_SmokeHarnessRuns'
$cursorBefore = Get-DirectorySnapshotFingerprint -Path $cursorProfilePath
$noHome = Invoke-ScriptCapture -ScriptPath $harnessScript -ArgumentList @('-SkipAdapterSmoke')
if ($noHome.ExitCode -ne 0) {
    Write-Fail -TestName $noHomeName -Reason ("harness exit {0}: {1}" -f $noHome.ExitCode, $noHome.Output.Trim())
}

$cursorAfter = Get-DirectorySnapshotFingerprint -Path $cursorProfilePath
if (-not [string]::Equals($cursorBefore, $cursorAfter, [System.StringComparison]::Ordinal)) {
    Write-Fail -TestName $noHomeName -Reason 'USERPROFILE .cursor snapshot changed during harness'
}

if ($noHome.Output -notmatch 'unchanged' -and $noHome.Output -notmatch '\.cursor') {
    Write-Fail -TestName $noHomeName -Reason ("expected .cursor unchanged message, got: {0}" -f $noHome.Output.Trim())
}

Write-Pass -TestName $noHomeName
}
finally {
    if ($markerWasPresent) {
        [System.IO.File]::WriteAllBytes($markerPath, $previousMarkerBytes)
    }
    elseif (Test-Path -LiteralPath $markerPath) {
        Remove-Item -LiteralPath $markerPath -Force -ErrorAction SilentlyContinue
    }
}

# --- Should_Fail_When_InstallRootIsUserProfileWithoutAllow ---
$failHomeName = 'Should_Fail_When_InstallRootIsUserProfileWithoutAllow'
$userProfileInstallRoot = Join-Path $userProfile '.agent-dev-toolkit-step11-test-install'
$failHome = Invoke-ScriptCapture -ScriptPath $harnessScript -ArgumentList @('-InstallRoot', $userProfileInstallRoot)
if ($failHome.ExitCode -eq 0) {
    Write-Fail -TestName $failHomeName -Reason 'expected non-zero exit for USERPROFILE InstallRoot without -AllowUserHome'
}

if ($failHome.Output -notmatch 'AllowUserHome' -or $failHome.Output -notmatch '(?i)user home|USERPROFILE') {
    Write-Fail -TestName $failHomeName -Reason ("expected AllowUserHome/USERPROFILE guard message, got: {0}" -f $failHome.Output.Trim())
}

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $failHomeName -Reason 'harness must not create InstallRoot under USERPROFILE when blocked'
}

Write-Pass -TestName $failHomeName

# Bootstrap TE01: SHA256 mismatch aborts with no extract / no sync handoff.
$te01Name = 'Should_Fail_When_BootstrapChecksumMismatch_Te01'
$bootstrapRel = 'scripts/bootstrap/bootstrap.ps1'
$bootstrapPath = Join-Path $repoRoot ($bootstrapRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $bootstrapPath)) {
    Write-Fail -TestName $te01Name -Reason ("missing {0}" -f $bootstrapRel)
}

$te01Dir = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-bootstrap-te01-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $te01Dir -Force | Out-Null
try {
    $zipPath = Join-Path $te01Dir 'sample.zip'
    $payloadPath = Join-Path $te01Dir 'payload.txt'
    Set-Content -LiteralPath $payloadPath -Value 'bootstrap-te01-fixture' -Encoding ASCII
    Compress-Archive -LiteralPath $payloadPath -DestinationPath $zipPath -Force
    $extractDir = Join-Path $te01Dir 'extracted'
    $badHash = '00' * 32
    $te01 = Invoke-ScriptCapture -ScriptPath $bootstrapPath -ArgumentList @(
        '-LocalZipPath', $zipPath,
        '-ExpectedSha256', $badHash,
        '-SkipDownload',
        '-NoExtract',
        '-SkipSync',
        '-CacheDir', $te01Dir
    )
    if ($te01.ExitCode -eq 0) {
        Write-Fail -TestName $te01Name -Reason 'expected non-zero exit on SHA256 mismatch (TE01)'
    }
    if ($te01.Output -notmatch 'SHA256 mismatch \(TE01\)') {
        Write-Fail -TestName $te01Name -Reason ("expected TE01 mismatch message, got: {0}" -f $te01.Output.Trim())
    }
    if (Test-Path -LiteralPath $extractDir) {
        Write-Fail -TestName $te01Name -Reason 'TE01 must not extract on checksum mismatch'
    }
}
finally {
    if (Test-Path -LiteralPath $te01Dir) {
        Remove-Item -LiteralPath $te01Dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Pass -TestName $te01Name

Write-Host 'Assert-SmokeHarnessSafety: ALL PASS'
exit 0
