#Requires -Version 5.1
# Tests:
#   Should_ForbidDelegateTask_When_OutsideSpawnAllowlist
#   Should_AllowDelegateTask_OnlyInSpawnMapAndUseOwnRow
#   Should_PublishSpawnBridge_When_HermesAgentsMdBuilt
#   Should_OmitDelegateTask_When_GrokAgentsAndRulesPublished
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
        Write-Fail -TestName 'Assert-HermesSpawnIsolationPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $repoRootScript
. $constantsScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$delegateTaskNeedle = $script:ToolkitConstant.HermesDelegateTaskNeedle
$spawnMdRel = $script:ToolkitConstant.SpawnMdRelativePath
$spawnBridgeHeading = $script:ToolkitConstant.HermesSpawnBridgeSectionHeading
$useOwnRowHeading = $script:ToolkitConstant.SpawnUseOwnHostRowHeading

$hermesModulePath = Join-Path $repoRoot 'adapters\hermes\HermesAdapter.ps1'
$grokModulePath = Join-Path $repoRoot 'adapters\grok\GrokAdapter.ps1'
$hermesSeedFixture = Join-Path $repoRoot 'scripts\validation\fixtures\hermes'
$grokSeedFixture = Join-Path $repoRoot 'scripts\validation\fixtures\grok'
$hermesWorkRoot = Join-Path $repoRoot 'scripts\validation\fixtures\hermes-spawn-isolation-work'
$grokWorkRoot = Join-Path $repoRoot 'scripts\validation\fixtures\grok-spawn-isolation-work'

if (-not (Test-Path -LiteralPath $hermesModulePath)) {
    Write-Fail -TestName 'Assert-HermesSpawnIsolationPreconditions' -Reason ("missing Hermes module: {0}" -f $hermesModulePath)
}
if (-not (Test-Path -LiteralPath $grokModulePath)) {
    Write-Fail -TestName 'Assert-HermesSpawnIsolationPreconditions' -Reason ("missing Grok module: {0}" -f $grokModulePath)
}
if (-not (Test-Path -LiteralPath $hermesSeedFixture)) {
    Write-Fail -TestName 'Assert-HermesSpawnIsolationPreconditions' -Reason ("missing Hermes fixture: {0}" -f $hermesSeedFixture)
}
if (-not (Test-Path -LiteralPath $grokSeedFixture)) {
    Write-Fail -TestName 'Assert-HermesSpawnIsolationPreconditions' -Reason ("missing Grok fixture: {0}" -f $grokSeedFixture)
}

function Get-MarkdownFilesUnder {
    param(
        [Parameter(Mandatory = $true)][string] $RootPath
    )
    if (-not (Test-Path -LiteralPath $RootPath)) {
        return @()
    }
    return @(Get-ChildItem -LiteralPath $RootPath -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue)
}

function Test-PathIsSpawnMd {
    param(
        [Parameter(Mandatory = $true)][string] $FullPath,
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $SpawnMdRelativePath
    )
    $expected = Join-Path $RepoRoot ($SpawnMdRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    return ([string]::Equals($FullPath, $expected, [System.StringComparison]::OrdinalIgnoreCase))
}

function Get-ForbiddenDelegateTaskHits {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $Needle,
        [Parameter(Mandatory = $true)][string] $SpawnMdRelativePath
    )
    $hits = [System.Collections.Generic.List[string]]::new()
    $scanRoots = @(
        (Join-Path $RepoRoot 'core\skills'),
        (Join-Path $RepoRoot 'core\policy'),
        (Join-Path $RepoRoot 'core\router'),
        (Join-Path $RepoRoot 'core\sdd')
    )
    foreach ($root in $scanRoots) {
        foreach ($file in @(Get-MarkdownFilesUnder -RootPath $root)) {
            if (Test-PathIsSpawnMd -FullPath $file.FullName -RepoRoot $RepoRoot -SpawnMdRelativePath $SpawnMdRelativePath) {
                continue
            }
            $text = [System.IO.File]::ReadAllText($file.FullName)
            if ($text.IndexOf($Needle, [System.StringComparison]::Ordinal) -ge 0) {
                $rel = $file.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')
                $hits.Add($rel)
            }
        }
    }
    return $hits.ToArray()
}

function Test-SpawnMdDelegateTaskAllowlist {
    param(
        [Parameter(Mandatory = $true)][string] $SpawnMdPath,
        [Parameter(Mandatory = $true)][string] $Needle,
        [Parameter(Mandatory = $true)][string] $UseOwnRowHeading
    )
    $lines = [System.IO.File]::ReadAllLines($SpawnMdPath)
    $inUseOwnRow = $false
    $badLines = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line.StartsWith('### ', [System.StringComparison]::Ordinal)) {
            $inUseOwnRow = $line.Contains($UseOwnRowHeading)
        }
        elseif ($line.StartsWith('## ', [System.StringComparison]::Ordinal)) {
            $inUseOwnRow = $false
        }

        if ($line.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) {
            continue
        }

        $isHermesTableRow = ($line -match '(?i)\|\s*`hermes`\s*\|') -and ($line.IndexOf($Needle, [System.StringComparison]::Ordinal) -ge 0)
        if ($isHermesTableRow -or $inUseOwnRow) {
            continue
        }

        $badLines.Add(('{0}:{1}' -f ($i + 1), $line.Trim()))
    }
    return $badLines.ToArray()
}

function Initialize-IsolationWorkRoot {
    param(
        [Parameter(Mandatory = $true)][string] $SeedRoot,
        [Parameter(Mandatory = $true)][string] $WorkRoot
    )
    if (Test-Path -LiteralPath $WorkRoot) {
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force
    }
    Copy-Item -LiteralPath $SeedRoot -Destination $WorkRoot -Recurse -Force
}

# --- Core isolation (outside SPAWN.md) ---
$coreHits = @(Get-ForbiddenDelegateTaskHits -RepoRoot $repoRoot -Needle $delegateTaskNeedle -SpawnMdRelativePath $spawnMdRel)
$coreIsolationName = 'Should_ForbidDelegateTask_When_OutsideSpawnAllowlist'
if ($coreHits.Count -gt 0) {
    Write-Fail -TestName $coreIsolationName -Reason ("delegate_task leaked outside SPAWN.md allowlist: {0}" -f ($coreHits -join ', '))
}
Write-Pass -TestName $coreIsolationName

# --- SPAWN.md allowlist ---
$spawnMdPath = Join-Path $repoRoot ($spawnMdRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $spawnMdPath)) {
    Write-Fail -TestName 'Should_AllowDelegateTask_OnlyInSpawnMapAndUseOwnRow' -Reason ("missing SPAWN.md: {0}" -f $spawnMdPath)
}
$spawnText = [System.IO.File]::ReadAllText($spawnMdPath)
if ($spawnText.IndexOf($delegateTaskNeedle, [System.StringComparison]::Ordinal) -lt 0) {
    Write-Fail -TestName 'Should_AllowDelegateTask_OnlyInSpawnMapAndUseOwnRow' -Reason 'SPAWN.md must mention delegate_task on the hermes host row'
}
if ($spawnText.IndexOf($useOwnRowHeading, [System.StringComparison]::Ordinal) -lt 0) {
    Write-Fail -TestName 'Should_AllowDelegateTask_OnlyInSpawnMapAndUseOwnRow' -Reason ("SPAWN.md missing use-own-row heading containing: {0}" -f $useOwnRowHeading)
}
$badSpawnLines = @(Test-SpawnMdDelegateTaskAllowlist -SpawnMdPath $spawnMdPath -Needle $delegateTaskNeedle -UseOwnRowHeading $useOwnRowHeading)
$spawnAllowName = 'Should_AllowDelegateTask_OnlyInSpawnMapAndUseOwnRow'
if ($badSpawnLines.Count -gt 0) {
    Write-Fail -TestName $spawnAllowName -Reason ("delegate_task outside hermes row / use-own-row section: {0}" -f ($badSpawnLines -join ' | '))
}
Write-Pass -TestName $spawnAllowName

# --- Hermes publish bridge ---
Initialize-IsolationWorkRoot -SeedRoot $hermesSeedFixture -WorkRoot $hermesWorkRoot
. $hermesModulePath
$null = Publish-Policy -InstallRoot $hermesWorkRoot
$hermesAgentsPath = Join-Path $hermesWorkRoot 'AGENTS.md'
$hermesPublishName = 'Should_PublishSpawnBridge_When_HermesAgentsMdBuilt'
if (-not (Test-Path -LiteralPath $hermesAgentsPath)) {
    Write-Fail -TestName $hermesPublishName -Reason ("Hermes AGENTS.md missing after Publish-Policy: {0}" -f $hermesAgentsPath)
}
$hermesAgentsText = [System.IO.File]::ReadAllText($hermesAgentsPath)
if ($hermesAgentsText.IndexOf($spawnBridgeHeading, [System.StringComparison]::Ordinal) -lt 0) {
    Write-Fail -TestName $hermesPublishName -Reason ("spawn bridge heading missing in {0}" -f $hermesAgentsPath)
}
if ($hermesAgentsText.IndexOf($delegateTaskNeedle, [System.StringComparison]::Ordinal) -lt 0) {
    Write-Fail -TestName $hermesPublishName -Reason ("delegate_task missing in Hermes AGENTS.md bridge at {0}" -f $hermesAgentsPath)
}
Write-Pass -TestName $hermesPublishName

# --- Cross-adapter: Grok AGENTS + rules must not get Hermes bridge ---
Initialize-IsolationWorkRoot -SeedRoot $grokSeedFixture -WorkRoot $grokWorkRoot
. $grokModulePath
$null = Publish-Router -InstallRoot $grokWorkRoot
$null = Publish-Policy -InstallRoot $grokWorkRoot
$grokAgentsPath = Join-Path $grokWorkRoot 'AGENTS.md'
$grokRulesRoot = Join-Path $grokWorkRoot 'rules'
$crossName = 'Should_OmitDelegateTask_When_GrokAgentsAndRulesPublished'
if (-not (Test-Path -LiteralPath $grokAgentsPath)) {
    Write-Fail -TestName $crossName -Reason ("Grok AGENTS.md missing after Publish-Router: {0}" -f $grokAgentsPath)
}
$grokAgentsText = [System.IO.File]::ReadAllText($grokAgentsPath)
if ($grokAgentsText.IndexOf($delegateTaskNeedle, [System.StringComparison]::Ordinal) -ge 0) {
    Write-Fail -TestName $crossName -Reason ("delegate_task leaked into Grok AGENTS.md at {0}" -f $grokAgentsPath)
}
if ($grokAgentsText.IndexOf($spawnBridgeHeading, [System.StringComparison]::Ordinal) -ge 0) {
    Write-Fail -TestName $crossName -Reason ("Hermes spawn bridge heading leaked into Grok AGENTS.md at {0}" -f $grokAgentsPath)
}
if (Test-Path -LiteralPath $grokRulesRoot) {
    foreach ($ruleFile in @(Get-ChildItem -LiteralPath $grokRulesRoot -Recurse -File -ErrorAction SilentlyContinue)) {
        $ruleText = [System.IO.File]::ReadAllText($ruleFile.FullName)
        if ($ruleText.IndexOf($delegateTaskNeedle, [System.StringComparison]::Ordinal) -ge 0) {
            Write-Fail -TestName $crossName -Reason ("delegate_task leaked into Grok rules file {0}" -f $ruleFile.FullName)
        }
    }
}
Write-Pass -TestName $crossName

# Cleanup work roots (keep seed fixtures intact)
foreach ($work in @($hermesWorkRoot, $grokWorkRoot)) {
    if (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force
    }
}

Write-Host 'Assert-HermesSpawnIsolation: ALL PASS'
