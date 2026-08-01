#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo ZCode ADE CI smoke (sync + validate against ephemeral fixture copy).

.DESCRIPTION
  Copies the versioned ZCode fixture into an ephemeral work InstallRoot, then
  runs sync-agent + validate-agent for -Agent zcode. Does not require a ZCode
  ADE profile, plugin enable UI, or USERPROFILE writes. Never passes
  -AllowUserHome. Also snapshots USERPROFILE\.zcode before/after to prove the
  smoke never touches the real user home. The ephemeral work InstallRoot is
  removed after evaluation (pass or fail) unless -KeepWorkRoot is set.

.PARAMETER Quiet
  Suppress banners; print summary only.

.PARAMETER KeepWorkRoot
  Skip deleting the ephemeral work InstallRoot after evaluation (debugging aid).

.EXAMPLE
  pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1
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

$suiteTitle = 'agent-dev-toolkit ZCode CI smoke'
$agentId = 'zcode'
$seedFixtureRel = 'scripts\validation\fixtures\zcode-install-root'
$workFixtureRel = 'scripts\validation\fixtures\zcode-ci-smoke'
$userZcodeRelative = '.zcode'
$suitePassMarker = 'Invoke-ZCodeCiSmoke: PASS'

function Write-SuiteBanner {
    param([Parameter(Mandatory = $true)][string] $Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

function Get-DirectoryFingerprint {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return 'ABSENT'
    }

    $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue | Sort-Object FullName)
    if ($files.Count -eq 0) {
        return 'EMPTY_DIR'
    }

    $parts = foreach ($file in $files) {
        '{0}|{1}|{2}' -f $file.FullName.ToLowerInvariant(), $file.Length, $file.LastWriteTimeUtc.Ticks
    }
    return ($parts -join '`n')
}

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

Write-SuiteBanner $suiteTitle

$userProfile = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Host 'FAIL preconditions: USERPROFILE is not set' -ForegroundColor Red
    exit 1
}

$userZcodeHome = Join-Path $userProfile $userZcodeRelative
$beforeHomeFingerprint = Get-DirectoryFingerprint -Path $userZcodeHome

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

$afterHomeFingerprint = Get-DirectoryFingerprint -Path $userZcodeHome
if ($beforeHomeFingerprint -ne $afterHomeFingerprint) {
    Write-Host ("FAIL USERPROFILE .zcode changed during CI smoke. Before={0} After={1}" -f $beforeHomeFingerprint, $afterHomeFingerprint) -ForegroundColor Red
    exit 1
}

if (-not $Quiet) {
    Write-Host $result.Output
}
Write-Host $suitePassMarker -ForegroundColor Green
exit 0
