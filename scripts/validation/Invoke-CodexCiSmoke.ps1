#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo Codex CI smoke (sync + validate against fixture seed).

.DESCRIPTION
  Copies the versioned Codex fixture into an ephemeral work InstallRoot, then
  runs sync-agent + validate-agent for -Agent codex. Does not require a Codex
  profile, /hooks trust UI, or USERPROFILE writes. Never passes -AllowUserHome.
  The ephemeral work InstallRoot is removed after evaluation (pass or fail)
  unless -KeepWorkRoot is set.

.PARAMETER Quiet
  Suppress banners; print summary only.

.PARAMETER KeepWorkRoot
  Skip deleting the ephemeral work InstallRoot after evaluation (debugging aid).

.EXAMPLE
  pwsh -NoProfile -File .\scripts\validation\Invoke-CodexCiSmoke.ps1
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

$suiteTitle = 'agent-dev-toolkit Codex CI smoke'
$agentId = 'codex'
$seedFixtureRel = 'scripts\validation\fixtures\codex'
$workFixtureRel = 'scripts\validation\fixtures\codex-ci-smoke'
$suitePassMarker = 'Invoke-CodexCiSmoke: PASS'

function Write-SuiteBanner {
    param([Parameter(Mandatory = $true)][string] $Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

Write-SuiteBanner $suiteTitle

$result = Invoke-EphemeralFixtureSmoke `
    -RepoRoot $repoRoot `
    -SeedFixtureRel $seedFixtureRel `
    -WorkFixtureRel $workFixtureRel `
    -AgentId $agentId `
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
