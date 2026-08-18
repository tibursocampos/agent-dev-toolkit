#Requires -Version 5.1
# Tests:
#   Should_RemoveToolkitArtifacts_When_UninstallCopilotUserFixture
#   Should_RemoveToolkitArtifacts_When_UninstallCopilotRepoFixture
#   Should_KeepUnrelatedFiles_When_UninstallCopilotFixture
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'

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

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-CopilotKeyedUninstallPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$copilotModulePath = Join-Path $repoRoot 'adapters\copilot\CopilotAdapter.ps1'
$uninstallHelperPath = Join-Path $repoRoot 'adapters\copilot\Uninstall-CopilotToolkit.ps1'
$syncAgentPath = Join-Path $repoRoot 'scripts\sync-agent.ps1'
$validateAgentPath = Join-Path $repoRoot 'scripts\validate-agent.ps1'
$fixtureUserRoot = Join-Path $repoRoot 'scripts\validation\fixtures\copilot\user'
$fixtureRepoRoot = Join-Path $repoRoot 'scripts\validation\fixtures\copilot\repo'
$modeUser = 'user'
$modeRepo = 'repo'
$skillsDirName = 'skills'
$instructionsDirName = 'instructions'
$hooksDirName = 'hooks'
$copilotInstructionsName = 'copilot-instructions.md'
$gitkeepName = '.gitkeep'
$alienSkillFolderName = 'alien-user-skill'
$alienSkillManifestName = 'SKILL.md'
$alienInstructionName = 'user-custom.instructions.md'
$alienHookName = 'user-custom-hook.json'
$alienRootFileName = 'alien-notes.md'
$expectedSkillProbe = 'commit'
$expectedInstructionProbe = 'guardrails.instructions.md'
$expectedHookProbe = 'hooks.json'

foreach ($required in @(
        $copilotModulePath,
        $uninstallHelperPath,
        $syncAgentPath,
        $validateAgentPath,
        $fixtureUserRoot,
        $fixtureRepoRoot
    )) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CopilotKeyedUninstallPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $copilotModulePath

function Clear-CopilotFixturePublishedTree {
    param([Parameter(Mandatory = $true)][string] $FixtureRoot)

    foreach ($dirName in @($skillsDirName, $instructionsDirName, $hooksDirName)) {
        $target = Join-Path $FixtureRoot $dirName
        if (-not (Test-Path -LiteralPath $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $target $gitkeepName) -Force | Out-Null
            continue
        }

        Get-ChildItem -LiteralPath $target -Force | Where-Object {
            $_.Name -ne $gitkeepName
        } | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }

        if (-not (Test-Path -LiteralPath (Join-Path $target $gitkeepName))) {
            New-Item -ItemType File -Path (Join-Path $target $gitkeepName) -Force | Out-Null
        }
    }

    $instructionsFile = Join-Path $FixtureRoot $copilotInstructionsName
    if (Test-Path -LiteralPath $instructionsFile) {
        Remove-Item -LiteralPath $instructionsFile -Force
    }

    $alienRoot = Join-Path $FixtureRoot $alienRootFileName
    if (Test-Path -LiteralPath $alienRoot) {
        Remove-Item -LiteralPath $alienRoot -Force
    }
}

function Invoke-CopilotFixtureSync {
    param(
        [Parameter(Mandatory = $true)][string] $FixtureRoot,
        [Parameter(Mandatory = $true)][string] $Mode,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    $syncOut = & pwsh -NoProfile -File $syncAgentPath -Agent copilot -Mode $Mode -InstallRoot $FixtureRoot 2>&1
    $syncExit = $LASTEXITCODE
    $syncText = ($syncOut | Out-String)
    if ($syncExit -ne 0) {
        Write-Fail -TestName $TestName -Reason ("sync-agent Mode={0} exit {1}: {2}" -f $Mode, $syncExit, $syncText.Trim())
    }
}

function Invoke-CopilotSyncValidate {
    param(
        [Parameter(Mandatory = $true)][string] $FixtureRoot,
        [Parameter(Mandatory = $true)][string] $Mode,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    Invoke-CopilotFixtureSync -FixtureRoot $FixtureRoot -Mode $Mode -TestName $TestName

    $validateOut = & pwsh -NoProfile -File $validateAgentPath -Agent copilot -Mode $Mode -InstallRoot $FixtureRoot -Quiet -SkipCore 2>&1
    $validateExit = $LASTEXITCODE
    $validateText = ($validateOut | Out-String)
    if ($validateExit -ne 0) {
        Write-Fail -TestName $TestName -Reason ("validate-agent -SkipCore Mode={0} exit {1}: {2}" -f $Mode, $validateExit, $validateText.Trim())
    }
    if ($validateText -notmatch 'Adapter smoke: PASS') {
        Write-Fail -TestName $TestName -Reason ("validate-agent -SkipCore must PASS before uninstall; got: {0}" -f $validateText.Trim())
    }
}

function Assert-ToolkitArtifactsAbsent {
    param(
        [Parameter(Mandatory = $true)][string] $FixtureRoot,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    $skillProbe = Join-Path (Join-Path $FixtureRoot $skillsDirName) $expectedSkillProbe
    if (Test-Path -LiteralPath $skillProbe) {
        Write-Fail -TestName $TestName -Reason ("toolkit skill still present: {0}" -f $skillProbe)
    }

    $instructionProbe = Join-Path (Join-Path $FixtureRoot $instructionsDirName) $expectedInstructionProbe
    if (Test-Path -LiteralPath $instructionProbe) {
        Write-Fail -TestName $TestName -Reason ("toolkit instruction still present: {0}" -f $instructionProbe)
    }

    $copilotInstructions = Join-Path $FixtureRoot $copilotInstructionsName
    if (Test-Path -LiteralPath $copilotInstructions) {
        Write-Fail -TestName $TestName -Reason ("copilot-instructions.md still present: {0}" -f $copilotInstructions)
    }

    $hookProbe = Join-Path (Join-Path $FixtureRoot $hooksDirName) $expectedHookProbe
    if (Test-Path -LiteralPath $hookProbe) {
        Write-Fail -TestName $TestName -Reason ("toolkit hook still present: {0}" -f $hookProbe)
    }
}

function Assert-ToolkitArtifactsPresent {
    param(
        [Parameter(Mandatory = $true)][string] $FixtureRoot,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    $skillProbe = Join-Path (Join-Path $FixtureRoot $skillsDirName) $expectedSkillProbe
    if (-not (Test-Path -LiteralPath $skillProbe)) {
        Write-Fail -TestName $TestName -Reason ("precondition: toolkit skill missing after sync: {0}" -f $skillProbe)
    }

    $instructionProbe = Join-Path (Join-Path $FixtureRoot $instructionsDirName) $expectedInstructionProbe
    if (-not (Test-Path -LiteralPath $instructionProbe)) {
        Write-Fail -TestName $TestName -Reason ("precondition: toolkit instruction missing after sync: {0}" -f $instructionProbe)
    }

    $copilotInstructions = Join-Path $FixtureRoot $copilotInstructionsName
    if (-not (Test-Path -LiteralPath $copilotInstructions)) {
        Write-Fail -TestName $TestName -Reason ("precondition: copilot-instructions.md missing after sync: {0}" -f $copilotInstructions)
    }

    $hookProbe = Join-Path (Join-Path $FixtureRoot $hooksDirName) $expectedHookProbe
    if (-not (Test-Path -LiteralPath $hookProbe)) {
        Write-Fail -TestName $TestName -Reason ("precondition: toolkit hook missing after sync: {0}" -f $hookProbe)
    }
}

function Add-AlienFilesUnderFixture {
    param([Parameter(Mandatory = $true)][string] $FixtureRoot)

    $alienSkillDir = Join-Path (Join-Path $FixtureRoot $skillsDirName) $alienSkillFolderName
    New-Item -ItemType Directory -Path $alienSkillDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $alienSkillDir $alienSkillManifestName) -Value "# Alien skill`n" -Encoding UTF8

    $alienInstruction = Join-Path (Join-Path $FixtureRoot $instructionsDirName) $alienInstructionName
    Set-Content -LiteralPath $alienInstruction -Value "# Alien instruction`n" -Encoding UTF8

    $alienHook = Join-Path (Join-Path $FixtureRoot $hooksDirName) $alienHookName
    Set-Content -LiteralPath $alienHook -Value "{`"alien`": true}`n" -Encoding UTF8

    $alienRoot = Join-Path $FixtureRoot $alienRootFileName
    Set-Content -LiteralPath $alienRoot -Value "keep me`n" -Encoding UTF8
}

function Assert-AlienFilesPresent {
    param(
        [Parameter(Mandatory = $true)][string] $FixtureRoot,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    $paths = @(
        (Join-Path (Join-Path (Join-Path $FixtureRoot $skillsDirName) $alienSkillFolderName) $alienSkillManifestName),
        (Join-Path (Join-Path $FixtureRoot $instructionsDirName) $alienInstructionName),
        (Join-Path (Join-Path $FixtureRoot $hooksDirName) $alienHookName),
        (Join-Path $FixtureRoot $alienRootFileName)
    )

    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Fail -TestName $TestName -Reason ("alien file must survive uninstall: {0}" -f $path)
        }
    }
}

# --- Should_RemoveToolkitArtifacts_When_UninstallCopilotUserFixture ---
$userName = 'Should_RemoveToolkitArtifacts_When_UninstallCopilotUserFixture'

Clear-CopilotFixturePublishedTree -FixtureRoot $fixtureUserRoot
Invoke-CopilotSyncValidate -FixtureRoot $fixtureUserRoot -Mode $modeUser -TestName $userName
Assert-ToolkitArtifactsPresent -FixtureRoot $fixtureUserRoot -TestName $userName
Add-AlienFilesUnderFixture -FixtureRoot $fixtureUserRoot

$uninstallUser = Uninstall-Toolkit -InstallRoot $fixtureUserRoot -Mode $modeUser
if ($null -eq $uninstallUser) {
    Write-Fail -TestName $userName -Reason 'Uninstall-Toolkit returned null'
}
if ($uninstallUser.Implemented -ne $true -or $uninstallUser.Success -ne $true) {
    Write-Fail -TestName $userName -Reason ("uninstall must Succeed+Implemented; got: {0}" -f $uninstallUser.Message)
}
if ($uninstallUser.ExitCode -ne 0) {
    Write-Fail -TestName $userName -Reason ("ExitCode must be 0, got {0}" -f $uninstallUser.ExitCode)
}
if ($uninstallUser.KeyedOnly -ne $true) {
    Write-Fail -TestName $userName -Reason 'KeyedOnly must be true'
}
if ([int]$uninstallUser.RemovedCount -lt 1) {
    Write-Fail -TestName $userName -Reason ("RemovedCount must be >= 1, got {0}" -f $uninstallUser.RemovedCount)
}
if ([string]$uninstallUser.Mode -ne $modeUser) {
    Write-Fail -TestName $userName -Reason ("Mode must be user, got: {0}" -f $uninstallUser.Mode)
}

Assert-ToolkitArtifactsAbsent -FixtureRoot $fixtureUserRoot -TestName $userName

$smokeAfterUser = Invoke-SmokeValidate -InstallRoot $fixtureUserRoot -Mode $modeUser
if ($null -eq $smokeAfterUser -or $smokeAfterUser.Success -eq $true) {
    Write-Fail -TestName $userName -Reason 'smoke must FAIL after uninstall (toolkit artifacts removed)'
}

Write-Pass -TestName $userName

$keepName = 'Should_KeepUnrelatedFiles_When_UninstallCopilotFixture'
Assert-AlienFilesPresent -FixtureRoot $fixtureUserRoot -TestName $keepName
$skillsGitkeep = Join-Path (Join-Path $fixtureUserRoot $skillsDirName) $gitkeepName
if (-not (Test-Path -LiteralPath $skillsGitkeep)) {
    Write-Fail -TestName $keepName -Reason 'fixture .gitkeep under skills/ must remain'
}
Write-Pass -TestName $keepName

# --- Should_RemoveToolkitArtifacts_When_UninstallCopilotRepoFixture ---
$repoName = 'Should_RemoveToolkitArtifacts_When_UninstallCopilotRepoFixture'

Clear-CopilotFixturePublishedTree -FixtureRoot $fixtureRepoRoot
Invoke-CopilotSyncValidate -FixtureRoot $fixtureRepoRoot -Mode $modeRepo -TestName $repoName
Assert-ToolkitArtifactsPresent -FixtureRoot $fixtureRepoRoot -TestName $repoName

$uninstallRepo = Uninstall-Toolkit -InstallRoot $fixtureRepoRoot -Mode $modeRepo
if ($null -eq $uninstallRepo -or $uninstallRepo.Success -ne $true -or $uninstallRepo.Implemented -ne $true) {
    Write-Fail -TestName $repoName -Reason ("uninstall must Succeed+Implemented; got: {0}" -f $(if ($null -eq $uninstallRepo) { 'null' } else { $uninstallRepo.Message }))
}
if ([string]$uninstallRepo.Mode -ne $modeRepo) {
    Write-Fail -TestName $repoName -Reason ("Mode must be repo, got: {0}" -f $uninstallRepo.Mode)
}

Assert-ToolkitArtifactsAbsent -FixtureRoot $fixtureRepoRoot -TestName $repoName

$smokeAfterRepo = Invoke-SmokeValidate -InstallRoot $fixtureRepoRoot -Mode $modeRepo
if ($null -eq $smokeAfterRepo -or $smokeAfterRepo.Success -eq $true) {
    Write-Fail -TestName $repoName -Reason 'smoke must FAIL after uninstall (toolkit artifacts removed)'
}

Write-Pass -TestName $repoName

Write-Host 'Assert-CopilotKeyedUninstall: all tests PASS'
exit 0
