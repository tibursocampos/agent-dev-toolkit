#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo InstallRoot smoke harness (no USERPROFILE deploy).

.DESCRIPTION
  Resolves InstallRoot to the repo fixture by default, optionally invokes the
  adapter contract Invoke-SmokeValidate stub, writes a marker only under the
  fixture, and asserts %USERPROFILE%\.cursor was not modified.

.PARAMETER InstallRoot
  Target InstallRoot. Defaults to scripts/validation/fixtures/install-root.

.PARAMETER AllowUserHome
  Opt-in when InstallRoot resolves under USERPROFILE.

.PARAMETER SkipAdapterSmoke
  Skip loading AdapterContract Invoke-SmokeValidate.

.PARAMETER AgentModulePath
  Optional adapter module path. Defaults to adapters/_contract/AdapterContract.ps1.

.EXAMPLE
  .\scripts\validation\Invoke-SmokeHarness.ps1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $InstallRoot,

    [Parameter()]
    [switch] $AllowUserHome,

    [Parameter()]
    [switch] $SkipAdapterSmoke,

    [Parameter()]
    [string] $AgentModulePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'Resolve-InstallRoot.ps1')

function Get-DirectorySnapshotFingerprint {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return 'missing'
    }

    $items = @(
        Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            ForEach-Object {
                $size = 0
                if (-not $_.PSIsContainer) {
                    $size = $_.Length
                }
                # Path + type + size only - ignore LastWriteTimeUtc so a live Cursor IDE
                # touching ~/.cursor does not false-fail the in-repo harness.
                '{0}|{1}|{2}' -f $_.FullName, $_.PSIsContainer, $size
            }
    )

    if ($items.Count -eq 0) {
        return 'empty'
    }

    return ($items -join "`n")
}

function Write-HarnessError {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host $Message -ForegroundColor Red
}

try {
    $repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        $InstallRoot = Join-Path $repoRoot ($script:ToolkitConstant.DefaultFixtureInstallRootRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    }

    Write-Host $script:ToolkitMessage.SmokeHarnessTitle -ForegroundColor Cyan

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    if (-not (Test-Path -LiteralPath $resolvedInstallRoot)) {
        Write-HarnessError -Message ($script:ToolkitMessage.SmokeHarnessFixtureMissing -f $resolvedInstallRoot)
        exit 1
    }

    Write-Host ($script:ToolkitMessage.SmokeHarnessInstallRootOk -f $resolvedInstallRoot) -ForegroundColor Cyan

    $userProfile = [Environment]::GetEnvironmentVariable($script:ToolkitConstant.UserProfileEnvironmentName)
    $cursorProfilePath = ''
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        $cursorProfilePath = Join-Path $userProfile $script:ToolkitConstant.UserCursorProfileRelativePath
    }

    $cursorBefore = Get-DirectorySnapshotFingerprint -Path $cursorProfilePath

    $markerPath = Join-Path $resolvedInstallRoot $script:ToolkitConstant.SmokeHarnessMarkerFileName
    $markerPayload = "smoke-harness|{0:o}" -f [DateTimeOffset]::UtcNow
    Set-Content -LiteralPath $markerPath -Value $markerPayload -Encoding UTF8
    Write-Host ($script:ToolkitMessage.SmokeHarnessMarkerWritten -f $markerPath) -ForegroundColor Green

    if (-not $SkipAdapterSmoke.IsPresent) {
        if ([string]::IsNullOrWhiteSpace($AgentModulePath)) {
            $AgentModulePath = Join-Path $repoRoot 'adapters\_contract\AdapterContract.ps1'
        }

        if (-not (Test-Path -LiteralPath $AgentModulePath)) {
            Write-HarnessError -Message ($script:ToolkitMessage.AdapterModuleMissing -f 'contract', $AgentModulePath)
            exit 1
        }

        . $AgentModulePath
        $smoke = Invoke-SmokeValidate -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
        if ($null -eq $smoke) {
            Write-HarnessError -Message ($script:ToolkitMessage.SmokeFailed -f 'contract', 'Invoke-SmokeValidate returned no result')
            exit 1
        }

        if ($smoke.PSObject.Properties.Name -contains 'Implemented' -and $smoke.Implemented -eq $false) {
            Write-Host $script:ToolkitMessage.SmokeHarnessAdapterNoOp -ForegroundColor Yellow
        }
        elseif ($smoke.PSObject.Properties.Name -contains 'Success' -and $smoke.Success -eq $false) {
            $detail = if ($smoke.PSObject.Properties.Name -contains 'Message') { [string]$smoke.Message } else { 'smoke failed' }
            Write-HarnessError -Message ($script:ToolkitMessage.SmokeFailed -f 'contract', $detail)
            exit 1
        }
    }

    $cursorAfter = Get-DirectorySnapshotFingerprint -Path $cursorProfilePath
    if (-not [string]::Equals($cursorBefore, $cursorAfter, [System.StringComparison]::Ordinal)) {
        Write-HarnessError -Message ($script:ToolkitMessage.SmokeHarnessCursorChanged -f $cursorBefore.Length, $cursorAfter.Length)
        exit 1
    }

    Write-Host $script:ToolkitMessage.SmokeHarnessCursorUnchanged -ForegroundColor Green
    Write-Host $script:ToolkitMessage.SmokeHarnessPassed -ForegroundColor Green
    exit 0
}
catch {
    Write-HarnessError -Message $_.Exception.Message
    Write-Host $script:ToolkitMessage.SmokeHarnessFailed -ForegroundColor Red
    exit 1
}
