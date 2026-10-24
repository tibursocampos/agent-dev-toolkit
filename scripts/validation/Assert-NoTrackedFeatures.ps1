#Requires -Version 5.1
# Ensure feature artifacts remain local by checking index paths only.
[CmdletBinding()]
param(
    [string] $RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')

if (-not $RepoRoot) {
    $RepoRoot = Get-ToolkitRepoRoot -FromPath $PSScriptRoot
}

function Write-Fail {
    param([Parameter(Mandatory = $true)][string] $Reason)
    Write-Error ("Assert-NoTrackedFeatures: FAIL - {0}" -f $Reason)
    exit 1
}

$gitMetadataPath = Join-Path $RepoRoot '.git'
if (-not (Test-Path -LiteralPath $gitMetadataPath)) {
    Write-Host 'Assert-NoTrackedFeatures: PASS (no Git index is present)'
    exit 0
}

try {
    $trackedFeaturePaths = @(& git -C $RepoRoot ls-files -- features 2>&1)
    $gitExitCode = $LASTEXITCODE
} catch {
    Write-Fail -Reason ("could not inspect the Git index: {0}" -f $_.Exception.Message)
}

if ($gitExitCode -ne 0) {
    Write-Fail -Reason ("git ls-files exited with code {0}: {1}" -f $gitExitCode, ($trackedFeaturePaths -join ' '))
}

$trackedFeaturePaths = @($trackedFeaturePaths | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($trackedFeaturePaths.Count -gt 0) {
    Write-Fail -Reason ("features/ contains tracked paths: {0}" -f ($trackedFeaturePaths -join ', '))
}

Write-Host 'Assert-NoTrackedFeatures: PASS (Git index contains no features/ paths)'
exit 0
