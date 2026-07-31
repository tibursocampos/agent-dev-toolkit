# Requires: PowerShell 5.1+
# Tests:
#   Should_RejectUserProfileInstallRoot_When_AllowUserHomeMissing
#   Should_AcceptRepoFixtureInstallRoot_When_PathUnderRepo
#   Should_RejectRepoJunctionToUserProfile_When_AllowUserHomeMissing
#   Should_AcceptRepoJunctionToUserProfile_When_AllowUserHomeSet
#   Should_Throw_When_ReparseResolveFails_ForExistingPath
#   Should_RejectExtendedLengthUserProfileInstallRoot_When_AllowUserHomeMissing
#   Should_RejectDevicePathUserProfileInstallRoot_When_AllowUserHomeMissing
#   Should_RejectMissingChildUnderRepoJunction_When_ConfirmAfterCreate_WithoutAllowUserHome
#   Should_RejectInitializeForWrite_When_UserProfileWithoutAllowUserHome
#   Should_RejectInitializeForWrite_When_DevicePathUserProfileWithoutAllowUserHome_LeavesNoOrphan
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
$resolveScript = Join-Path $libDir 'Resolve-InstallRoot.ps1'
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

foreach ($required in @($resolveScript, $constantsScript, $repoRootScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-InstallRootSafetyPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $resolveScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\install-root'
$userProfile = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-InstallRootSafetyPreconditions' -Reason 'USERPROFILE is not set'
}

$userProfileInstallRoot = Join-Path $userProfile '.agent-dev-toolkit-step7-test-install'

# --- Should_RejectUserProfileInstallRoot_When_AllowUserHomeMissing ---
$rejectName = 'Should_RejectUserProfileInstallRoot_When_AllowUserHomeMissing'
$rejected = $false
try {
    $null = Resolve-InstallRoot -InstallRoot $userProfileInstallRoot
}
catch {
    $rejected = $true
    $message = $_.Exception.Message
    if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
        Write-Fail -TestName $rejectName -Reason ("unexpected message: {0}" -f $message)
    }
}

if (-not $rejected) {
    Write-Fail -TestName $rejectName -Reason 'expected throw for USERPROFILE InstallRoot without -AllowUserHome'
}

$allowed = Resolve-InstallRoot -InstallRoot $userProfileInstallRoot -AllowUserHome
$expectedAllowed = [System.IO.Path]::GetFullPath($userProfileInstallRoot)
if (-not [string]::Equals($allowed, $expectedAllowed, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $rejectName -Reason ("AllowUserHome path mismatch: got {0}" -f $allowed)
}

Write-Pass -TestName $rejectName

# --- Should_AcceptRepoFixtureInstallRoot_When_PathUnderRepo ---
$acceptName = 'Should_AcceptRepoFixtureInstallRoot_When_PathUnderRepo'
$accepted = Resolve-InstallRoot -InstallRoot $fixtureInstallRoot
$expectedFixture = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
if (-not [string]::Equals($accepted, $expectedFixture, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $acceptName -Reason ("fixture path mismatch: got {0}" -f $accepted)
}

if (-not (Test-IsPathUnderOrEqual -ChildPath $accepted -ParentPath $repoRoot)) {
    Write-Fail -TestName $acceptName -Reason 'resolved InstallRoot is not under repo root'
}

Write-Pass -TestName $acceptName

# --- Junction-escape tests: an in-repo junction pointing at USERPROFILE must
# --- be caught on its resolved *final* target, not on the junction's own
# --- (in-repo) lexical path. See Resolve-ReparsePointTarget in Resolve-InstallRoot.ps1.
$junctionLinkPath = Join-Path $repoRoot 'scripts\validation\fixtures\install-root-junction'
$junctionTargetPath = Join-Path $userProfile '.agent-dev-toolkit-junction-target-test'

function Remove-JunctionTestFixtures {
    if (Test-Path -LiteralPath $junctionLinkPath) {
        Remove-Item -LiteralPath $junctionLinkPath -Force
    }

    if (Test-Path -LiteralPath $junctionTargetPath) {
        Remove-Item -LiteralPath $junctionTargetPath -Force -Recurse
    }
}

Remove-JunctionTestFixtures

try {
    $null = New-Item -ItemType Directory -Path $junctionTargetPath -Force
    $null = New-Item -ItemType Junction -Path $junctionLinkPath -Target $junctionTargetPath

    # --- Should_RejectRepoJunctionToUserProfile_When_AllowUserHomeMissing ---
    $junctionRejectName = 'Should_RejectRepoJunctionToUserProfile_When_AllowUserHomeMissing'
    $junctionRejected = $false
    try {
        $null = Resolve-InstallRoot -InstallRoot $junctionLinkPath
    }
    catch {
        $junctionRejected = $true
        $message = $_.Exception.Message
        if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
            Write-Fail -TestName $junctionRejectName -Reason ("unexpected message: {0}" -f $message)
        }
    }

    if (-not $junctionRejected) {
        Write-Fail -TestName $junctionRejectName -Reason 'expected throw for in-repo junction resolving under USERPROFILE without -AllowUserHome'
    }

    Write-Pass -TestName $junctionRejectName

    # --- Should_AcceptRepoJunctionToUserProfile_When_AllowUserHomeSet ---
    $junctionAcceptName = 'Should_AcceptRepoJunctionToUserProfile_When_AllowUserHomeSet'
    $junctionAllowed = Resolve-InstallRoot -InstallRoot $junctionLinkPath -AllowUserHome
    $expectedJunctionTarget = Get-NormalizedFullPath -Path $junctionTargetPath
    if (-not [string]::Equals($junctionAllowed, $expectedJunctionTarget, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail -TestName $junctionAcceptName -Reason ("expected resolution to junction target {0}, got {1}" -f $expectedJunctionTarget, $junctionAllowed)
    }

    Write-Pass -TestName $junctionAcceptName
}
finally {
    Remove-JunctionTestFixtures
}

# --- Should_Throw_When_ReparseResolveFails_ForExistingPath ---
# Simulate GetFinalPathNameByHandle failure via a mock resolver type. An existing
# in-repo path must throw (fail-closed), never silently accept the lexical path.
$reparseFailName = 'Should_Throw_When_ReparseResolveFails_ForExistingPath'
$reparseFailFixture = Join-Path $repoRoot 'scripts\validation\fixtures\install-root-reparse-fail'
$failResolverTypeName = 'ToolkitReparsePointResolverFailClosedTest'
$previousResolverTypeName = $script:ToolkitConstant.ReparsePointResolverTypeName

function Remove-ReparseFailFixture {
    if (Test-Path -LiteralPath $reparseFailFixture) {
        Remove-Item -LiteralPath $reparseFailFixture -Force -Recurse
    }
}

Remove-ReparseFailFixture

try {
    # Arrange
    $null = New-Item -ItemType Directory -Path $reparseFailFixture -Force

    if (-not ($failResolverTypeName -as [type])) {
        Add-Type -TypeDefinition @"
using System;
public static class $failResolverTypeName
{
    public static string GetFinalPath(string path)
    {
        throw new InvalidOperationException("simulated reparse resolve failure");
    }
}
"@
    }

    $script:ToolkitConstant.ReparsePointResolverTypeName = $failResolverTypeName

    # Act
    $reparseFailed = $false
    $reparseFailMessage = $null
    try {
        $null = Resolve-InstallRoot -InstallRoot $reparseFailFixture
    }
    catch {
        $reparseFailed = $true
        $reparseFailMessage = $_.Exception.Message
    }

    # Assert
    if (-not $reparseFailed) {
        Write-Fail -TestName $reparseFailName -Reason 'expected throw when reparse resolve fails for existing path; lexical under-repo accept is fail-open'
    }

    if ($reparseFailMessage -notmatch 'reparse-point resolution failed' -or $reparseFailMessage -notmatch 'Refuse fail-open') {
        Write-Fail -TestName $reparseFailName -Reason ("unexpected message: {0}" -f $reparseFailMessage)
    }

    Write-Pass -TestName $reparseFailName
}
finally {
    $script:ToolkitConstant.ReparsePointResolverTypeName = $previousResolverTypeName
    Remove-ReparseFailFixture
}

# --- Should_RejectExtendedLengthUserProfileInstallRoot_When_AllowUserHomeMissing ---
# Missing \\?\C:\Users\... must not bypass -AllowUserHome via prefix mismatch.
$extendedRejectName = 'Should_RejectExtendedLengthUserProfileInstallRoot_When_AllowUserHomeMissing'
$extendedUserProfileInstallRoot = $script:ToolkitConstant.ExtendedLengthPathPrefix + $userProfileInstallRoot

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $extendedRejectName -Reason ("fixture path must be missing for lexical bypass test: {0}" -f $userProfileInstallRoot)
}

# Arrange / Act — without AllowUserHome must throw
$extendedRejected = $false
try {
    $null = Resolve-InstallRoot -InstallRoot $extendedUserProfileInstallRoot
}
catch {
    $extendedRejected = $true
    $message = $_.Exception.Message
    if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
        Write-Fail -TestName $extendedRejectName -Reason ("unexpected message: {0}" -f $message)
    }
}

# Assert
if (-not $extendedRejected) {
    Write-Fail -TestName $extendedRejectName -Reason 'expected throw for missing \\?\ USERPROFILE InstallRoot without -AllowUserHome'
}

# With AllowUserHome, policy may pass (path still under USERPROFILE after prefix strip).
$extendedAllowed = Resolve-InstallRoot -InstallRoot $extendedUserProfileInstallRoot -AllowUserHome
$expectedExtendedAllowed = [System.IO.Path]::GetFullPath($userProfileInstallRoot)
if (-not [string]::Equals($extendedAllowed, $expectedExtendedAllowed, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $extendedRejectName -Reason ("AllowUserHome extended-length path mismatch: got {0}" -f $extendedAllowed)
}

Write-Pass -TestName $extendedRejectName

# --- Should_RejectDevicePathUserProfileInstallRoot_When_AllowUserHomeMissing ---
# Missing \\.\C:\Users\... must not bypass -AllowUserHome via prefix mismatch (sibling of \\?\).
$deviceRejectName = 'Should_RejectDevicePathUserProfileInstallRoot_When_AllowUserHomeMissing'
$deviceUserProfileInstallRoot = $script:ToolkitConstant.DevicePathPrefix + $userProfileInstallRoot

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $deviceRejectName -Reason ("fixture path must be missing for lexical bypass test: {0}" -f $userProfileInstallRoot)
}

# Arrange / Act — without AllowUserHome must throw
$deviceRejected = $false
try {
    $null = Resolve-InstallRoot -InstallRoot $deviceUserProfileInstallRoot
}
catch {
    $deviceRejected = $true
    $message = $_.Exception.Message
    if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
        Write-Fail -TestName $deviceRejectName -Reason ("unexpected message: {0}" -f $message)
    }
}

# Assert
if (-not $deviceRejected) {
    Write-Fail -TestName $deviceRejectName -Reason 'expected throw for missing \\.\ USERPROFILE InstallRoot without -AllowUserHome'
}

# With AllowUserHome, policy may pass (path still under USERPROFILE after prefix strip).
$deviceAllowed = Resolve-InstallRoot -InstallRoot $deviceUserProfileInstallRoot -AllowUserHome
$expectedDeviceAllowed = [System.IO.Path]::GetFullPath($userProfileInstallRoot)
if (-not [string]::Equals($deviceAllowed, $expectedDeviceAllowed, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $deviceRejectName -Reason ("AllowUserHome device-path mismatch: got {0}" -f $deviceAllowed)
}

Write-Pass -TestName $deviceRejectName

# --- Should_RejectMissingChildUnderRepoJunction_When_ConfirmAfterCreate_WithoutAllowUserHome ---
# Missing child under an in-repo junction is accepted lexically by Resolve; after New-Item
# the path lands under USERPROFILE and Confirm must refuse without -AllowUserHome.
$missingChildName = 'Should_RejectMissingChildUnderRepoJunction_When_ConfirmAfterCreate_WithoutAllowUserHome'
$junctionParentPath = Join-Path $repoRoot 'scripts\validation\fixtures\install-root-junction-parent'
$junctionChildMissing = Join-Path $junctionParentPath 'missing-child-publish'
$junctionParentTarget = Join-Path $userProfile '.agent-dev-toolkit-junction-parent-target-test'

function Remove-MissingChildJunctionFixtures {
    if (Test-Path -LiteralPath $junctionChildMissing) {
        Remove-Item -LiteralPath $junctionChildMissing -Force -Recurse
    }

    if (Test-Path -LiteralPath $junctionParentPath) {
        Remove-Item -LiteralPath $junctionParentPath -Force
    }

    if (Test-Path -LiteralPath $junctionParentTarget) {
        Remove-Item -LiteralPath $junctionParentTarget -Force -Recurse
    }
}

Remove-MissingChildJunctionFixtures

try {
    # Arrange
    $null = New-Item -ItemType Directory -Path $junctionParentTarget -Force
    $null = New-Item -ItemType Junction -Path $junctionParentPath -Target $junctionParentTarget

    if (Test-Path -LiteralPath $junctionChildMissing) {
        Write-Fail -TestName $missingChildName -Reason ("child must be missing before Resolve: {0}" -f $junctionChildMissing)
    }

    # Lexical Resolve allows missing path under repo junction parent.
    $lexicalChild = Resolve-InstallRoot -InstallRoot $junctionChildMissing
    $expectedLexical = [System.IO.Path]::GetFullPath($junctionChildMissing)
    if (-not [string]::Equals($lexicalChild, $expectedLexical, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail -TestName $missingChildName -Reason ("expected lexical resolve {0}, got {1}" -f $expectedLexical, $lexicalChild)
    }

    # Act — Publish pattern: create then Confirm (TOCTOU)
    $null = New-Item -ItemType Directory -Path $lexicalChild -Force
    $confirmRejected = $false
    try {
        $null = Confirm-InstallRootAllowsWrite -InstallRoot $lexicalChild
    }
    catch {
        $confirmRejected = $true
        $message = $_.Exception.Message
        if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
            Write-Fail -TestName $missingChildName -Reason ("unexpected Confirm message: {0}" -f $message)
        }
    }

    # Assert
    if (-not $confirmRejected) {
        Write-Fail -TestName $missingChildName -Reason 'expected Confirm to throw after create under junction-to-USERPROFILE without -AllowUserHome'
    }

    Write-Pass -TestName $missingChildName
}
finally {
    Remove-MissingChildJunctionFixtures
}

# --- Should_RejectInitializeForWrite_When_UserProfileWithoutAllowUserHome ---
# Shared Publish helper must refuse USERPROFILE InstallRoot without -AllowUserHome
# (same policy as Resolve; covers Publish-without-Allow blocked path).
$initWriteName = 'Should_RejectInitializeForWrite_When_UserProfileWithoutAllowUserHome'
$initWriteRejected = $false
try {
    $null = Initialize-InstallRootForWrite -InstallRoot $userProfileInstallRoot
}
catch {
    $initWriteRejected = $true
    $message = $_.Exception.Message
    if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
        Write-Fail -TestName $initWriteName -Reason ("unexpected message: {0}" -f $message)
    }
}

if (-not $initWriteRejected) {
    Write-Fail -TestName $initWriteName -Reason 'expected Initialize-InstallRootForWrite to throw for USERPROFILE without -AllowUserHome'
}

# Must not create the USERPROFILE path as a side effect of a blocked write init.
if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $initWriteName -Reason ("blocked Initialize must not create USERPROFILE path: {0}" -f $userProfileInstallRoot)
}

Write-Pass -TestName $initWriteName

# --- Should_RejectInitializeForWrite_When_DevicePathUserProfileWithoutAllowUserHome_LeavesNoOrphan ---
# \\.\ USERPROFILE without Allow must throw and must not leave a directory created mid-call.
$initDeviceName = 'Should_RejectInitializeForWrite_When_DevicePathUserProfileWithoutAllowUserHome_LeavesNoOrphan'
$initDeviceInstallRoot = $script:ToolkitConstant.DevicePathPrefix + $userProfileInstallRoot

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $initDeviceName -Reason ("fixture path must be missing before Initialize: {0}" -f $userProfileInstallRoot)
}

$initDeviceRejected = $false
try {
    $null = Initialize-InstallRootForWrite -InstallRoot $initDeviceInstallRoot
}
catch {
    $initDeviceRejected = $true
    $message = $_.Exception.Message
    if ($message -notmatch 'AllowUserHome' -or $message -notmatch 'USERPROFILE') {
        Write-Fail -TestName $initDeviceName -Reason ("unexpected message: {0}" -f $message)
    }
}

if (-not $initDeviceRejected) {
    Write-Fail -TestName $initDeviceName -Reason 'expected Initialize-InstallRootForWrite to throw for \\.\ USERPROFILE without -AllowUserHome'
}

if (Test-Path -LiteralPath $userProfileInstallRoot) {
    Write-Fail -TestName $initDeviceName -Reason ("blocked Initialize must not leave orphan USERPROFILE path: {0}" -f $userProfileInstallRoot)
}

Write-Pass -TestName $initDeviceName

Write-Host 'Assert-InstallRootSafety: ALL PASS'
exit 0
