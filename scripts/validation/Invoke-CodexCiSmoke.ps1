#Requires -Version 5.1
[CmdletBinding()]
param([switch] $Quiet, [switch] $KeepWorkRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptDir = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $PSScriptRoot }
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'Invoke-EphemeralFixtureSmoke.ps1')
$result = Invoke-ManifestAdapterFixtureSmoke -RepoRoot (Get-ToolkitRepoRoot -FromPath $scriptDir) -AdapterId 'codex' -Quiet:$Quiet -KeepWorkRoot:$KeepWorkRoot
if ($result.Status -ne 'PASS') { exit [int]$result.ExitCode }
exit 0
