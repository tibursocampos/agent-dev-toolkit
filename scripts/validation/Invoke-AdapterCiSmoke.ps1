#Requires -Version 5.1
<#
.SYNOPSIS
  Generic adapter CI smoke: publish into a seeded InstallRoot, then validate-agent -SkipCore.

.DESCRIPTION
  Replaces the per-adapter Invoke-*CiSmoke wrappers. The InstallRoot is seeded from
  scripts/validation/fixtures/seed-user-root/ (unrelated operator files plus a stale managed-skills
  marker), published once with sync-agent.ps1, and validated. The operator files must survive.
  Copilot is smoked in both user and repo mode.

.PARAMETER Adapter
  Registry adapter id (required).

.PARAMETER KeepWorkRoot
  Keep <repo>/.adt-work/<guid>/ for debugging.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Adapter,
    [switch] $Quiet,
    [switch] $KeepWorkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'scripts/_lib/New-ToolkitWorkRoot.ps1')
. (Join-Path $repoRoot 'scripts/_lib/ToolkitConstants.ps1')

$registry = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters/registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$agent = @($registry.agents | Where-Object { $_.id -eq $Adapter }) | Select-Object -First 1
if ($null -eq $agent) { Write-Host "Invoke-AdapterCiSmoke: FAIL - unknown adapter '$Adapter'" -ForegroundColor Red; exit 1 }

$displayNames = @{ cursor = 'Cursor'; antigravity = 'Antigravity'; claude = 'Claude'; codex = 'Codex'; copilot = 'Copilot'; opencode = 'OpenCode'; grok = 'Grok'; zcode = 'ZCode'; hermes = 'Hermes'; openhands = 'OpenHands' }
$display = if ($displayNames.ContainsKey($Adapter)) { $displayNames[$Adapter] } else { $Adapter }
$seedRoot = Join-Path $repoRoot 'scripts/validation/fixtures/seed-user-root'
$runner = (Get-Process -Id $PID).Path
$passMarker = $script:ToolkitConstant.AdapterSmokePassMarker
$modes = if ($Adapter -eq 'copilot') { @('user', 'repo') } else { @('') }

function Fail([string] $Reason) {
    Write-Host ("Invoke-{0}CiSmoke: FAIL - {1}" -f $display, $Reason) -ForegroundColor Red
    exit 1
}

if (-not $Quiet) { Write-Host ("agent-dev-toolkit {0} CI smoke" -f $display) -ForegroundColor Cyan }
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    foreach ($mode in $modes) {
        $label = if ($mode) { "$Adapter-$mode" } else { $Adapter }
        $installRoot = Join-Path $work ($label + '/install')
        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
        Copy-Item -LiteralPath @(Get-ChildItem -LiteralPath $seedRoot -Force | ForEach-Object { $_.FullName }) -Destination $installRoot -Recurse -Force
        $seedSkillsMarker = Join-Path $installRoot 'skills/.toolkit-managed-skills.json'
        if (-not (Test-Path -LiteralPath $seedSkillsMarker)) { Fail 'seed fixture is incomplete' }

        $syncArgs = @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts/sync-agent.ps1'), '-Agent', $Adapter, '-InstallRoot', $installRoot)
        $validateArgs = @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts/validate-agent.ps1'), '-Agent', $Adapter, '-InstallRoot', $installRoot, '-Quiet', '-SkipCore')
        if ($mode) { $syncArgs += @('-Mode', $mode); $validateArgs += @('-Mode', $mode) }

        Write-Host ('PUBLISH {0}' -f $label)
        $syncOutput = (& $runner @syncArgs 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { Fail ("sync-agent exit {0}: {1}" -f $LASTEXITCODE, $syncOutput.Trim()) }
        $validateOutput = (& $runner @validateArgs 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { Fail ("validate-agent exit {0}: {1}" -f $LASTEXITCODE, $validateOutput.Trim()) }
        if ($validateOutput -notlike ('*{0}*' -f $passMarker)) { Fail ("validate-agent output lacks '{0}': {1}" -f $passMarker, $validateOutput.Trim()) }

        foreach ($operatorFile in @('README.md', 'notes/operator-notes.txt', 'skills/user-own-skill/SKILL.md')) {
            if (-not (Test-Path -LiteralPath (Join-Path $installRoot $operatorFile) -PathType Leaf)) { Fail ("publishing removed the operator file '{0}'" -f $operatorFile) }
        }
    }
    Write-Host ("Invoke-{0}CiSmoke: PASS" -f $display) -ForegroundColor Green
}
finally {
    if (-not $KeepWorkRoot) { Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work }
}
exit 0
