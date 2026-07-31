#Requires -Version 5.1
# Tests:
#   Should_RunBothModes_When_CiSmokeSuiteExecutes
#   Should_BlockUserProfileInstallRoot_When_AllowUserHomeAbsent
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
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

function Get-DirectoryFingerprint {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return 'MISSING'
    }

    $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Sort-Object -Property FullName)
    if ($files.Count -eq 0) {
        return 'EMPTY'
    }

    $parts = foreach ($file in $files) {
        ('{0}|{1}' -f $file.FullName.ToLowerInvariant(), $file.Length)
    }
    return ($parts -join ';')
}

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CopilotModesPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript
. $constantsScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$suiteScriptName = 'Invoke-CopilotCiSmokeSuite.ps1'
$suiteScriptPath = Join-Path $scriptDir $suiteScriptName
$syncAgentPath = Join-Path $repoRoot ($script:ToolkitConstant.SyncAgentRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$workflowPath = Join-Path $repoRoot ($script:ToolkitConstant.CiWorkflowRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixtureUserRoot = Join-Path $repoRoot ($script:ToolkitConstant.CopilotFixtureUserRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixtureRepoRoot = Join-Path $repoRoot ($script:ToolkitConstant.CopilotFixtureRepoRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$agentId = $script:ToolkitConstant.CopilotAgentId
$modeUser = $script:ToolkitConstant.CopilotModeUser
$modeRepo = $script:ToolkitConstant.CopilotModeRepo
$userProfile = $env:USERPROFILE
$homeCopilotRelative = '.copilot'
$homeProbeRelative = '.agent-dev-toolkit-copilot-home-guard-test'
$suitePassMarker = 'Copilot CI smoke suite PASSED'
$comparison = [System.StringComparison]::OrdinalIgnoreCase
$skillsProbeName = 'commit'

foreach ($required in @($suiteScriptPath, $syncAgentPath, $workflowPath, $fixtureUserRoot, $fixtureRepoRoot)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CopilotModesPreconditions' -Reason ("missing {0}" -f $required)
    }
}

if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-CopilotModesPreconditions' -Reason 'USERPROFILE is not set'
}

# --- Should_RunBothModes_When_CiSmokeSuiteExecutes ---
$suiteName = 'Should_RunBothModes_When_CiSmokeSuiteExecutes'

$workflowText = Get-Content -LiteralPath $workflowPath -Raw
$requiredWorkflowMarkers = @(
    $suiteScriptName,
    'validate-core.ps1',
    'actions/checkout',
    'pwsh',
    'permissions:',
    'contents: read'
)
foreach ($marker in $requiredWorkflowMarkers) {
    if ($workflowText -notlike ("*{0}*" -f $marker)) {
        Write-Fail -TestName $suiteName -Reason ("CI workflow missing marker '{0}'" -f $marker)
    }
}

$forbiddenWorkflowMarkers = @(
    'AllowUserHome',
    'secrets.'
)
foreach ($marker in $forbiddenWorkflowMarkers) {
    if ($workflowText -like ("*{0}*" -f $marker)) {
        Write-Fail -TestName $suiteName -Reason ("CI workflow must not contain '{0}'" -f $marker)
    }
}

$userCopilotHome = Join-Path $userProfile $homeCopilotRelative
$beforeHomeFingerprint = Get-DirectoryFingerprint -Path $userCopilotHome
$homeExistedBefore = Test-Path -LiteralPath $userCopilotHome

$suiteOut = & pwsh -NoProfile -File $suiteScriptPath -Quiet 2>&1
$suiteExit = $LASTEXITCODE
if ($null -eq $suiteExit) { $suiteExit = 0 }
$suiteText = ($suiteOut | Out-String)
if ($suiteExit -ne 0) {
    Write-Fail -TestName $suiteName -Reason ("CI smoke suite exit {0}: {1}" -f $suiteExit, $suiteText.Trim())
}
if ($suiteText -notmatch [regex]::Escape($suitePassMarker)) {
    Write-Fail -TestName $suiteName -Reason ("suite output must include '{0}'; got: {1}" -f $suitePassMarker, $suiteText.Trim())
}

$userSkillProbe = Join-Path (Join-Path $fixtureUserRoot $script:ToolkitConstant.SkillsDirectoryName) $skillsProbeName
$repoSkillProbe = Join-Path (Join-Path $fixtureRepoRoot $script:ToolkitConstant.SkillsDirectoryName) $skillsProbeName
if (-not (Test-Path -LiteralPath $userSkillProbe)) {
    Write-Fail -TestName $suiteName -Reason ("Mode user fixture missing skill probe after suite: {0}" -f $userSkillProbe)
}
if (-not (Test-Path -LiteralPath $repoSkillProbe)) {
    Write-Fail -TestName $suiteName -Reason ("Mode repo fixture missing skill probe after suite: {0}" -f $repoSkillProbe)
}

$afterHomeFingerprint = Get-DirectoryFingerprint -Path $userCopilotHome
$homeExistsAfter = Test-Path -LiteralPath $userCopilotHome
if ($homeExistedBefore -ne $homeExistsAfter) {
    Write-Fail -TestName $suiteName -Reason 'suite must not create or remove USERPROFILE/.copilot'
}
if (-not [string]::Equals($beforeHomeFingerprint, $afterHomeFingerprint, $comparison)) {
    Write-Fail -TestName $suiteName -Reason 'suite must not mutate USERPROFILE/.copilot (CI green without Copilot profile)'
}

Write-Pass -TestName $suiteName

# --- Should_BlockUserProfileInstallRoot_When_AllowUserHomeAbsent ---
$homeGuardName = 'Should_BlockUserProfileInstallRoot_When_AllowUserHomeAbsent'

$userProbeRoot = Join-Path $userProfile $homeProbeRelative
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$syncBlockedOut = & pwsh -NoProfile -File $syncAgentPath -Agent $agentId -Mode $modeUser -InstallRoot $userProbeRoot 2>&1
$syncBlockedExit = $LASTEXITCODE
if ($null -eq $syncBlockedExit) { $syncBlockedExit = 0 }
$syncBlockedText = ($syncBlockedOut | Out-String)
if ($syncBlockedExit -eq 0) {
    Write-Fail -TestName $homeGuardName -Reason 'sync-agent against USERPROFILE without -AllowUserHome must exit non-zero'
}
if ($syncBlockedText -notmatch '(?i)AllowUserHome' -or $syncBlockedText -notmatch '(?i)USERPROFILE') {
    Write-Fail -TestName $homeGuardName -Reason ("blocked sync must mention AllowUserHome/USERPROFILE; got: {0}" -f $syncBlockedText.Trim())
}
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Fail -TestName $homeGuardName -Reason 'sync-agent must not create USERPROFILE probe InstallRoot without -AllowUserHome'
}

$syncBlockedRepoOut = & pwsh -NoProfile -File $syncAgentPath -Agent $agentId -Mode $modeRepo -InstallRoot $userProbeRoot 2>&1
$syncBlockedRepoExit = $LASTEXITCODE
if ($null -eq $syncBlockedRepoExit) { $syncBlockedRepoExit = 0 }
if ($syncBlockedRepoExit -eq 0) {
    Write-Fail -TestName $homeGuardName -Reason 'sync-agent Mode repo against USERPROFILE without -AllowUserHome must exit non-zero'
}
if (Test-Path -LiteralPath $userProbeRoot) {
    Remove-Item -LiteralPath $userProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Fail -TestName $homeGuardName -Reason 'Mode repo sync must not create USERPROFILE probe without -AllowUserHome'
}

# Green path still works without home flag (fixture under repo)
$fixtureSyncOut = & pwsh -NoProfile -File $syncAgentPath -Agent $agentId -Mode $modeUser -InstallRoot $fixtureUserRoot 2>&1
$fixtureSyncExit = $LASTEXITCODE
if ($null -eq $fixtureSyncExit) { $fixtureSyncExit = 0 }
if ($fixtureSyncExit -ne 0) {
    Write-Fail -TestName $homeGuardName -Reason ("fixture sync without AllowUserHome must succeed; exit {0}: {1}" -f $fixtureSyncExit, (($fixtureSyncOut | Out-String).Trim()))
}

Write-Pass -TestName $homeGuardName

Write-Host 'Assert-CopilotModes: ALL PASS'
exit 0
