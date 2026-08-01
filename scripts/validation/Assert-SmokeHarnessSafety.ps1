#Requires -Version 5.1
# Tests:
#   Should_UseFixtureInstallRoot_When_SmokeHarnessRuns
#   Should_NotWriteUserCursorProfile_When_SmokeHarnessRuns
#   Should_Fail_When_InstallRootIsUserProfileWithoutAllow
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$harnessScript = Join-Path $scriptDir 'Invoke-SmokeHarness.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'

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

    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 0
    }

    return [PSCustomObject]@{
        ExitCode = [int]$code
        Output   = $output
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

foreach ($required in @($harnessScript, $constantsScript, $repoRootScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-SmokeHarnessSafetyPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$fixtureInstallRoot = Join-Path $repoRoot ($script:ToolkitConstant.DefaultFixtureInstallRootRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixtureReadme = Join-Path $fixtureInstallRoot 'README.md'

if (-not (Test-Path -LiteralPath $fixtureReadme)) {
    Write-Fail -TestName 'Assert-SmokeHarnessSafetyPreconditions' -Reason ("fixture seed missing: {0}" -f $fixtureReadme)
}

$userProfile = [Environment]::GetEnvironmentVariable($script:ToolkitConstant.UserProfileEnvironmentName)
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-SmokeHarnessSafetyPreconditions' -Reason 'USERPROFILE is not set'
}

$cursorProfilePath = Join-Path $userProfile $script:ToolkitConstant.UserCursorProfileRelativePath

# --- Should_UseFixtureInstallRoot_When_SmokeHarnessRuns ---
$useFixtureName = 'Should_UseFixtureInstallRoot_When_SmokeHarnessRuns'
$useFixture = Invoke-ScriptCapture -ScriptPath $harnessScript
if ($useFixture.ExitCode -ne 0) {
    Write-Fail -TestName $useFixtureName -Reason ("harness exit {0}: {1}" -f $useFixture.ExitCode, $useFixture.Output.Trim())
}

$expectedFixtureFull = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
if ($useFixture.Output -notmatch [regex]::Escape($expectedFixtureFull) -and $useFixture.Output -notmatch [regex]::Escape($fixtureInstallRoot)) {
    Write-Fail -TestName $useFixtureName -Reason ("expected fixture InstallRoot in output: {0}" -f $useFixture.Output.Trim())
}

$markerPath = Join-Path $fixtureInstallRoot $script:ToolkitConstant.SmokeHarnessMarkerFileName
if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Fail -TestName $useFixtureName -Reason ("expected smoke marker under fixture: {0}" -f $markerPath)
}

Write-Pass -TestName $useFixtureName

# --- Should_NotWriteUserCursorProfile_When_SmokeHarnessRuns ---
$noHomeName = 'Should_NotWriteUserCursorProfile_When_SmokeHarnessRuns'
$cursorBefore = Get-DirectorySnapshotFingerprint -Path $cursorProfilePath
$noHome = Invoke-ScriptCapture -ScriptPath $harnessScript
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

# --- Should_Fail_When_InstallRootIsUserProfileWithoutAllow ---
$failHomeName = 'Should_Fail_When_InstallRootIsUserProfileWithoutAllow'
$userProfileInstallRoot = Join-Path $userProfile '.agent-dev-toolkit-step11-test-install'
$failHome = Invoke-ScriptCapture -ScriptPath $harnessScript -ArgumentList @('-InstallRoot', $userProfileInstallRoot)
if ($failHome.ExitCode -eq 0) {
    Write-Fail -TestName $failHomeName -Reason 'expected non-zero exit for USERPROFILE InstallRoot without -AllowUserHome'
}

if ($failHome.Output -notmatch 'AllowUserHome' -or $failHome.Output -notmatch 'USERPROFILE') {
    Write-Fail -TestName $failHomeName -Reason ("expected AllowUserHome/USERPROFILE guard message, got: {0}" -f $failHome.Output.Trim())
}

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $failHomeName -Reason 'harness must not create InstallRoot under USERPROFILE when blocked'
}

Write-Pass -TestName $failHomeName

Write-Host 'Assert-SmokeHarnessSafety: ALL PASS'
exit 0
