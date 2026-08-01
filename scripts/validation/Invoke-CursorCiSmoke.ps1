#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo Cursor CI smoke (sync + validate against fixture seed).

.DESCRIPTION
  Copies the versioned Cursor fixture seed (hooks.json custom entries) into an
  ephemeral work InstallRoot, then runs sync-agent + validate-agent for
  -Agent cursor. Does not require a Cursor profile, hooks trust UI, or
  USERPROFILE writes. The ephemeral work InstallRoot is removed after
  evaluation (pass or fail) unless -KeepWorkRoot is set.

.PARAMETER Quiet
  Suppress banners; print summary only.

.PARAMETER KeepWorkRoot
  Skip deleting the ephemeral work InstallRoot after evaluation (debugging aid).

.EXAMPLE
  pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
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

$suiteTitle = 'agent-dev-toolkit Cursor CI smoke'
$agentId = 'cursor'
$seedFixtureRel = 'scripts\validation\fixtures\cursor-install-root'
$workFixtureRel = 'scripts\validation\fixtures\cursor-ci-smoke'
$hooksJsonFileName = 'hooks.json'
$suitePassMarker = 'Invoke-CursorCiSmoke: PASS'

function Write-SuiteBanner {
    param([Parameter(Mandatory = $true)][string] $Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

$copyCursorHooksJsonSeed = {
    param(
        [Parameter(Mandatory = $true)][string] $SeedFixtureRoot,
        [Parameter(Mandatory = $true)][string] $WorkInstallRoot
    )

    $seedText = [System.IO.File]::ReadAllText((Join-Path $SeedFixtureRoot $hooksJsonFileName))
    [System.IO.File]::WriteAllText(
        (Join-Path $WorkInstallRoot $hooksJsonFileName),
        $seedText,
        (New-Object System.Text.UTF8Encoding $false)
    )
}.GetNewClosure()

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$seedFixtureRoot = Join-Path $repoRoot $seedFixtureRel
$seedHooksJsonPath = Join-Path $seedFixtureRoot $hooksJsonFileName

Write-SuiteBanner $suiteTitle

$result = Invoke-EphemeralFixtureSmoke `
    -RepoRoot $repoRoot `
    -SeedFixtureRel $seedFixtureRel `
    -WorkFixtureRel $workFixtureRel `
    -AgentId $agentId `
    -AdditionalRequiredPaths @($seedHooksJsonPath) `
    -SeedCopyScriptBlock $copyCursorHooksJsonSeed `
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
