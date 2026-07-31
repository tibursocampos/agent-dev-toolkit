#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo Claude Code CI smoke (sync + validate against fixture seed).

.DESCRIPTION
  Copies the versioned Claude merge fixture into an ephemeral work InstallRoot,
  then runs sync-agent + validate-agent for -Agent claude. Does not require a
  Claude Code profile, trust UI, or USERPROFILE writes. The ephemeral work
  InstallRoot is removed after evaluation (pass or fail) unless -KeepWorkRoot
  is set.

.PARAMETER Quiet
  Suppress banners; print summary only.

.PARAMETER KeepWorkRoot
  Skip deleting the ephemeral work InstallRoot after evaluation (debugging aid).

.EXAMPLE
  pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
#>
[CmdletBinding()]
param(
    [switch] $Quiet,
    [switch] $KeepWorkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'Invoke-EphemeralFixtureSmoke.ps1')

$suiteTitle = 'agent-dev-toolkit Claude CI smoke'
$agentId = 'claude'
$seedFixtureRel = 'scripts\validation\fixtures\claude'
$workFixtureRel = 'scripts\validation\fixtures\claude-ci-smoke'
$settingsFileName = 'settings.json'
$suitePassMarker = 'Invoke-ClaudeCiSmoke: PASS'

function Write-SuiteBanner {
    param([Parameter(Mandatory = $true)][string] $Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

$copyClaudeSettingsJsonSeed = {
    param(
        [Parameter(Mandatory = $true)][string] $SeedFixtureRoot,
        [Parameter(Mandatory = $true)][string] $WorkInstallRoot
    )

    $seedText = [System.IO.File]::ReadAllText((Join-Path $SeedFixtureRoot $settingsFileName))
    [System.IO.File]::WriteAllText(
        (Join-Path $WorkInstallRoot $settingsFileName),
        $seedText,
        (New-Object System.Text.UTF8Encoding $false)
    )
}.GetNewClosure()

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$seedFixtureRoot = Join-Path $repoRoot $seedFixtureRel
$seedSettingsPath = Join-Path $seedFixtureRoot $settingsFileName

Write-SuiteBanner $suiteTitle

$result = Invoke-EphemeralFixtureSmoke `
    -RepoRoot $repoRoot `
    -SeedFixtureRel $seedFixtureRel `
    -WorkFixtureRel $workFixtureRel `
    -AgentId $agentId `
    -AdditionalRequiredPaths @($seedSettingsPath) `
    -SeedCopyScriptBlock $copyClaudeSettingsJsonSeed `
    -Quiet:$Quiet `
    -KeepWorkRoot:$KeepWorkRoot

if ($result.Status -ne 'PASS') {
    exit [int]$result.ExitCode
}

if (-not $Quiet) {
    Write-Host $result.Output
}
Write-Host $suitePassMarker -ForegroundColor Green
exit 0
