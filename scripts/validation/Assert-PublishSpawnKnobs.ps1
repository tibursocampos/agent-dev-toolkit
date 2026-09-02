#Requires -Version 5.1
# Tests:
#   Should_Pass_When_SpawnPublishKnobsPresent
#   Should_Pass_When_SpawnPublishKnobsParsesOnWindowsPowerShell
#   Should_Pass_When_HonestyMatrixDocumentsHosts
#   Should_Pass_When_CoreAgentsUseModelInherit
#   Should_Pass_When_CapsMatchSpawn
#   Should_Pass_When_CodexTomlEmitsInheritHonesty
#   Should_Fail_When_CodexTomlPinsDivergentModel
#   Should_Pass_When_CursorFixtureAgentsInherit
#   Should_Pass_When_DivergentProbeUsesBoundedTokenMatch
#
# Dual-engine: run under both hosts so PS 5.1 UTF-8 parse regressions fail CI:
#   powershell.exe -NoProfile -File scripts/validation/Assert-PublishSpawnKnobs.ps1
#   pwsh -NoProfile -File scripts/validation/Assert-PublishSpawnKnobs.ps1
#
# REQ-008 / CA8 / RNF-002: Publish depth/threads/inherit aligned to SPAWN.
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

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-PublishSpawnKnobsPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$knobsRel = $script:ToolkitConstant.SpawnPublishKnobsRelativePath
$honestyRel = $script:ToolkitConstant.SpawnPublishHonestyRelativePath
$knobsPath = Join-Path $repoRoot ($knobsRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$honestyPath = Join-Path $repoRoot ($honestyRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $knobsPath)) {
    Write-Fail -TestName 'Should_Pass_When_SpawnPublishKnobsPresent' -Reason ("missing {0}" -f $knobsRel)
}
. $knobsPath
$knobsText = Get-Content -LiteralPath $knobsPath -Raw -Encoding UTF8
foreach ($marker in @('Get-SpawnPublishCaps', 'Assert-MarkdownAgentsSpawnKnobs', 'Assert-CodexTomlSpawnKnobs', 'DeveloperConcurrentCap', 'OrchestrateConcurrentCap', 'Test-SpawnModelMatchesDivergentProbe')) {
    if ($knobsText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_SpawnPublishKnobsPresent' -Reason ("missing marker {0}" -f $marker)
    }
}
foreach ($ch in [char[]]$knobsText) {
    if ([int][char]$ch -gt 127) {
        Write-Fail -TestName 'Should_Pass_When_SpawnPublishKnobsPresent' -Reason 'SpawnPublishKnobs.ps1 must be ASCII-only for Windows PowerShell 5.1 parse without BOM'
    }
}
Write-Pass -TestName 'Should_Pass_When_SpawnPublishKnobsPresent'

# When running under pwsh, also force-parse under Windows PowerShell 5.1 so CI that only
# invokes pwsh still catches UTF-8 non-ASCII parse failures.
$ps51ProbeName = 'Should_Pass_When_SpawnPublishKnobsParsesOnWindowsPowerShell'
$isWindowsPowerShell = $PSVersionTable.PSEdition -eq 'Desktop' -or ($null -eq $PSVersionTable.PSEdition -and $PSVersionTable.PSVersion.Major -le 5)
if ($isWindowsPowerShell) {
    Write-Pass -TestName $ps51ProbeName
}
else {
    $powershellExe = Get-Command -Name 'powershell.exe' -ErrorAction SilentlyContinue
    if (-not $powershellExe) {
        Write-Fail -TestName $ps51ProbeName -Reason 'powershell.exe not found; cannot verify Windows PowerShell 5.1 parse'
    }
    $env:SPAWN_PUBLISH_KNOBS_PATH = $knobsPath
    try {
        $probeScript = {
            $ErrorActionPreference = 'Stop'
            . $env:SPAWN_PUBLISH_KNOBS_PATH
            $caps = Get-SpawnPublishCaps
            if ($caps.DeveloperConcurrentCap -ne 2) { throw 'caps' }
        }.ToString()
        $probeOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $probeScript 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Write-Fail -TestName $ps51ProbeName -Reason ("powershell.exe parse/dot-source failed: {0}" -f $probeOut.Trim())
        }
    }
    finally {
        Remove-Item -LiteralPath Env:SPAWN_PUBLISH_KNOBS_PATH -ErrorAction SilentlyContinue
    }
    Write-Pass -TestName $ps51ProbeName
}

if (-not (Test-Path -LiteralPath $honestyPath)) {
    Write-Fail -TestName 'Should_Pass_When_HonestyMatrixDocumentsHosts' -Reason ("missing {0}" -f $honestyRel)
}
$honestyText = Get-Content -LiteralPath $honestyPath -Raw -Encoding UTF8
$le = [string][char]0x2264
foreach ($marker in @('Cursor', 'Claude', 'Codex', 'Hermes', 'REQ-008', 'inherit', ($le + '2'), ($le + '4'), 'Honesty')) {
    if ($honestyText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_HonestyMatrixDocumentsHosts' -Reason ("honesty missing {0}" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_HonestyMatrixDocumentsHosts'

$coreAgentsRel = $script:ToolkitConstant.SpawnPublishCoreAgentsRelativeDir
$coreAgentsRoot = Join-Path $repoRoot ($coreAgentsRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
try {
    Assert-MarkdownAgentsSpawnKnobs -AgentsRoot $coreAgentsRoot -Label 'core-agents'
}
catch {
    Write-Fail -TestName 'Should_Pass_When_CoreAgentsUseModelInherit' -Reason $_.Exception.Message
}
Write-Pass -TestName 'Should_Pass_When_CoreAgentsUseModelInherit'

$caps = Get-SpawnPublishCaps
if ($caps.DeveloperConcurrentCap -ne 2 -or $caps.OrchestrateConcurrentCap -ne 4) {
    Write-Fail -TestName 'Should_Pass_When_CapsMatchSpawn' -Reason ("expected 2/4 got {0}/{1}" -f $caps.DeveloperConcurrentCap, $caps.OrchestrateConcurrentCap)
}
$spawnMd = Join-Path $repoRoot ($script:ToolkitConstant.SpawnMdRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$spawnText = Get-Content -LiteralPath $spawnMd -Raw -Encoding UTF8
if ($spawnText -notmatch ($le + '\s*2') -and $spawnText -notmatch ('\*\*' + $le + ' 2\*\*')) {
    Write-Fail -TestName 'Should_Pass_When_CapsMatchSpawn' -Reason 'SPAWN.md missing developer <=2 marker'
}
if ($spawnText -notmatch ($le + '\s*4') -and $spawnText -notmatch ('\*\*' + $le + ' 4\*\*')) {
    Write-Fail -TestName 'Should_Pass_When_CapsMatchSpawn' -Reason 'SPAWN.md missing orchestrate <=4 marker'
}
Write-Pass -TestName 'Should_Pass_When_CapsMatchSpawn'

$codexAdapter = Join-Path $repoRoot 'adapters\codex\CodexAdapter.ps1'
. $codexAdapter
$sampleMd = @"
---
name: sample-agent
description: Sample for toml emit test.
model: inherit
---

# sample-agent

Do useful work.
"@
$toml = Convert-CodexAgentMarkdownToToml -MarkdownText $sampleMd -SourcePath 'sample.md'
try {
    Assert-CodexTomlSpawnKnobs -TomlText $toml
}
catch {
    Write-Fail -TestName 'Should_Pass_When_CodexTomlEmitsInheritHonesty' -Reason $_.Exception.Message
}
Write-Pass -TestName 'Should_Pass_When_CodexTomlEmitsInheritHonesty'

$divergentMd = @"
---
name: bad-agent
description: Must reject divergent model pin.
model: gpt-5.6-terra-medium
---

# bad-agent
"@
$threw = $false
try {
    [void](Convert-CodexAgentMarkdownToToml -MarkdownText $divergentMd -SourcePath 'bad.md')
}
catch {
    $threw = $true
}
if (-not $threw) {
    Write-Fail -TestName 'Should_Fail_When_CodexTomlPinsDivergentModel' -Reason 'expected reject of terra pin'
}
Write-Pass -TestName 'Should_Fail_When_CodexTomlPinsDivergentModel'

$cursorFixtureAgents = Join-Path $repoRoot 'scripts\validation\fixtures\cursor-install-root\agents'
try {
    Assert-MarkdownAgentsSpawnKnobs -AgentsRoot $cursorFixtureAgents -Label 'cursor-fixture'
}
catch {
    Write-Fail -TestName 'Should_Pass_When_CursorFixtureAgentsInherit' -Reason $_.Exception.Message
}
Write-Pass -TestName 'Should_Pass_When_CursorFixtureAgentsInherit'

$probeName = 'Should_Pass_When_DivergentProbeUsesBoundedTokenMatch'
if (-not (Test-SpawnModelMatchesDivergentProbe -NormalizedModel 'gpt-5.6-luna-medium' -Probe 'luna')) {
    Write-Fail -TestName $probeName -Reason 'expected bounded token match for luna in gpt-5.6-luna-medium'
}
if (Test-SpawnModelMatchesDivergentProbe -NormalizedModel 'lunaria-preview' -Probe 'luna') {
    Write-Fail -TestName $probeName -Reason 'substring lunaria must not match probe luna'
}
if (Test-SpawnModelMatchesDivergentProbe -NormalizedModel 'territory-fast' -Probe 'terra') {
    Write-Fail -TestName $probeName -Reason 'substring territory must not match probe terra'
}
if (-not (Test-SpawnModelMatchesDivergentProbe -NormalizedModel 'terra' -Probe 'terra')) {
    Write-Fail -TestName $probeName -Reason 'exact probe terra must match'
}
Write-Pass -TestName $probeName

Write-Host 'Assert-PublishSpawnKnobs: ALL PASS'
exit 0
