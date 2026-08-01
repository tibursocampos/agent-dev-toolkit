#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo Copilot CI smoke matrix (Mode user + Mode repo).

.DESCRIPTION
  Copies the versioned Copilot fixture seed for each mode into its own ephemeral
  work InstallRoot, then chains sync-agent + validate-agent for both Copilot
  modes. Does not require a GitHub Copilot profile, IDE extension, or login.
  Does not write under USERPROFILE. Each ephemeral work InstallRoot is removed
  after evaluation (pass or fail) unless -KeepWorkRoot is set.

.PARAMETER Quiet
  Suppress per-mode banners; print summary only.

.PARAMETER KeepWorkRoot
  Skip deleting the ephemeral work InstallRoots after evaluation (debugging aid).

.EXAMPLE
  pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
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
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'Invoke-EphemeralFixtureSmoke.ps1')

$suiteTitle = 'agent-dev-toolkit Copilot CI smoke suite'
$agentId = $script:ToolkitConstant.CopilotAgentId
$suiteModes = @(
    @{
        Mode           = $script:ToolkitConstant.CopilotModeUser
        SeedFixtureRel = $script:ToolkitConstant.CopilotFixtureUserRel
        WorkFixtureRel = $script:ToolkitConstant.CopilotWorkFixtureUserRel
    },
    @{
        Mode           = $script:ToolkitConstant.CopilotModeRepo
        SeedFixtureRel = $script:ToolkitConstant.CopilotFixtureRepoRel
        WorkFixtureRel = $script:ToolkitConstant.CopilotWorkFixtureRepoRel
    }
)

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

if (-not $Quiet) {
    Write-Host ''
    Write-Host $suiteTitle -ForegroundColor Cyan
    Write-Host ('=' * $suiteTitle.Length) -ForegroundColor Cyan
    Write-Host 'Filesystem-only; no Copilot profile / IDE extension required.' -ForegroundColor DarkGray
    Write-Host ''
}

$results = @()
foreach ($entry in $suiteModes) {
    $seedFixtureRoot = Join-Path $repoRoot ($entry.SeedFixtureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
        Write-Host ("Missing fixture InstallRoot: {0}" -f $seedFixtureRoot) -ForegroundColor Red
        exit 1
    }

    $result = Invoke-EphemeralFixtureSmoke `
        -RepoRoot $repoRoot `
        -SeedFixtureRel $entry.SeedFixtureRel `
        -WorkFixtureRel $entry.WorkFixtureRel `
        -AgentId $agentId `
        -Mode $entry.Mode `
        -Quiet:$Quiet `
        -KeepWorkRoot:$KeepWorkRoot

    $results += [PSCustomObject]@{
        Mode     = $entry.Mode
        Status   = $result.Status
        ExitCode = $result.ExitCode
    }

    if ($result.Status -eq 'FAIL') {
        break
    }
}

Write-Host ''
Write-Host 'Copilot CI smoke summary' -ForegroundColor Cyan
Write-Host '------------------------' -ForegroundColor Cyan
foreach ($result in $results) {
    $color = if ($result.Status -eq 'PASS') { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    Write-Host ("  Mode={0}: {1}" -f $result.Mode, $result.Status) -ForegroundColor $color
}

$failed = @($results | Where-Object { $_.Status -ne 'PASS' })
if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host 'Copilot CI smoke suite FAILED.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Copilot CI smoke suite PASSED (user + repo; no home deploy).' -ForegroundColor Green
exit 0
