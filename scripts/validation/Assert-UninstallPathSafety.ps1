#Requires -Version 5.1
# Tests:
#   Should_AcceptStrictChild_When_PathUnderInstallRoot
#   Should_Throw_When_CandidateEqualsInstallRoot
#   Should_ThrowAndNotDelete_When_PoisonRelativeEscapes
#   Should_ThrowAndNotDelete_When_JunctionPointsOutsideInstallRoot
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
$resolveScript = Join-Path $libDir 'Resolve-InstallRoot.ps1'
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

foreach ($required in @($resolveScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-UninstallPathSafetyPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $resolveScript

$probeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("adt-uninstall-path-safety-" + [Guid]::NewGuid().ToString('N'))
$installRoot = Join-Path $probeRoot 'install-root'
$safeChild = Join-Path $installRoot 'skills\commit'
$outsideCanaryDir = Join-Path $probeRoot 'outside-canary'
$outsideCanaryFile = Join-Path $outsideCanaryDir 'keep-me.txt'
$poisonCandidate = Join-Path $installRoot '..\outside-canary'
$junctionLink = Join-Path $installRoot 'skills\poison-junction'

function Remove-ProbeRoot {
    # Best-effort only: Windows PowerShell 5.1 Remove-Item on junctions can throw
    # NullReferenceException even with -ErrorAction SilentlyContinue under Stop.
    # Delete the junction link first (rmdir / Directory.Delete does not follow the target),
    # then remove the temp tree. Never let cleanup fail the assert after PASS.
    try {
        if (-not [string]::IsNullOrWhiteSpace($junctionLink) -and (Test-Path -LiteralPath $junctionLink)) {
            try {
                [System.IO.Directory]::Delete($junctionLink)
            }
            catch {
                & cmd.exe /c "rmdir `"$junctionLink`"" 2>$null | Out-Null
            }
        }
    }
    catch {
        # ignore junction cleanup failures
    }

    try {
        if (-not [string]::IsNullOrWhiteSpace($probeRoot) -and (Test-Path -LiteralPath $probeRoot)) {
            Remove-Item -LiteralPath $probeRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # ignore temp-tree cleanup failures
    }
}

Remove-ProbeRoot

try {
    $null = New-Item -ItemType Directory -Path $safeChild -Force
    $null = New-Item -ItemType Directory -Path $outsideCanaryDir -Force
    [System.IO.File]::WriteAllText($outsideCanaryFile, 'canary')
    [System.IO.File]::WriteAllText((Join-Path $safeChild 'marker.txt'), 'safe')

    # --- Should_AcceptStrictChild_When_PathUnderInstallRoot ---
    $acceptName = 'Should_AcceptStrictChild_When_PathUnderInstallRoot'
    $accepted = Assert-PathUnderInstallRootForDelete -CandidatePath $safeChild -InstallRoot $installRoot
    $expectedSafe = Get-NormalizedFullPath -Path $safeChild
    if (-not [string]::Equals($accepted, $expectedSafe, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail -TestName $acceptName -Reason ("expected {0}, got {1}" -f $expectedSafe, $accepted)
    }
    Write-Pass -TestName $acceptName

    # --- Should_Throw_When_CandidateEqualsInstallRoot ---
    $equalName = 'Should_Throw_When_CandidateEqualsInstallRoot'
    $equalThrew = $false
    $equalMessage = $null
    try {
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $installRoot -InstallRoot $installRoot
    }
    catch {
        $equalThrew = $true
        $equalMessage = $_.Exception.Message
    }
    if (-not $equalThrew) {
        Write-Fail -TestName $equalName -Reason 'expected throw when candidate equals InstallRoot'
    }
    if ($equalMessage -notmatch 'wholesale wipe' -and $equalMessage -notmatch 'InstallRoot itself') {
        Write-Fail -TestName $equalName -Reason ("unexpected message: {0}" -f $equalMessage)
    }
    Write-Pass -TestName $equalName

    # --- Should_ThrowAndNotDelete_When_PoisonRelativeEscapes ---
    $poisonName = 'Should_ThrowAndNotDelete_When_PoisonRelativeEscapes'
    $poisonThrew = $false
    $poisonMessage = $null
    try {
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $poisonCandidate -InstallRoot $installRoot
    }
    catch {
        $poisonThrew = $true
        $poisonMessage = $_.Exception.Message
    }
    if (-not $poisonThrew) {
        Write-Fail -TestName $poisonName -Reason 'expected throw for .. escape candidate'
    }
    if ($poisonMessage -notmatch 'outside InstallRoot' -and $poisonMessage -notmatch 'Refuse delete') {
        Write-Fail -TestName $poisonName -Reason ("unexpected message: {0}" -f $poisonMessage)
    }
    if (-not (Test-Path -LiteralPath $outsideCanaryFile)) {
        Write-Fail -TestName $poisonName -Reason 'poison assert must not delete outside canary'
    }
    Write-Pass -TestName $poisonName

    # --- Should_ThrowAndNotDelete_When_JunctionPointsOutsideInstallRoot ---
    $junctionName = 'Should_ThrowAndNotDelete_When_JunctionPointsOutsideInstallRoot'
    $skillsDir = Join-Path $installRoot 'skills'
    if (-not (Test-Path -LiteralPath $skillsDir)) {
        $null = New-Item -ItemType Directory -Path $skillsDir -Force
    }
    $null = New-Item -ItemType Junction -Path $junctionLink -Target $outsideCanaryDir

    $junctionThrew = $false
    $junctionMessage = $null
    try {
        $null = Assert-PathUnderInstallRootForDelete -CandidatePath $junctionLink -InstallRoot $installRoot
    }
    catch {
        $junctionThrew = $true
        $junctionMessage = $_.Exception.Message
    }

    if (-not $junctionThrew) {
        Write-Fail -TestName $junctionName -Reason 'expected throw when junction final path escapes InstallRoot'
    }
    if ($junctionMessage -notmatch 'outside InstallRoot' -and $junctionMessage -notmatch 'Refuse delete') {
        Write-Fail -TestName $junctionName -Reason ("unexpected message: {0}" -f $junctionMessage)
    }
    if (-not (Test-Path -LiteralPath $outsideCanaryFile)) {
        Write-Fail -TestName $junctionName -Reason 'escaping junction must not delete outside canary'
    }
    if (-not (Test-Path -LiteralPath $junctionLink)) {
        Write-Fail -TestName $junctionName -Reason 'assert must not remove the junction link itself'
    }
    Write-Pass -TestName $junctionName
}
finally {
    Remove-ProbeRoot
}

Write-Host 'Assert-UninstallPathSafety: ALL PASS'
exit 0
