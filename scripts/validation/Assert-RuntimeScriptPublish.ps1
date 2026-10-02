#Requires -Version 5.1
<#
.SYNOPSIS
  Verifies allowlisted runtime scripts publish beneath each resolved toolkit root.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$syncPath = Join-Path $repoRoot 'scripts/sync-agent.ps1'
$manifestPath = Join-Path $repoRoot 'scripts/runtime/runtime-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$entries = @($manifest.files)
if ($entries.Count -eq 0) { throw 'Runtime manifest contains no files.' }

$runner = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($runner)) { throw 'Could not resolve the current PowerShell executable.' }
$fixtureBase = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'scripts/validation/fixtures')).TrimEnd('\', '/')
$testRoot = Join-Path $fixtureBase ('.runtime-script-publish-' + [guid]::NewGuid().ToString('N'))
$fullTestRoot = [System.IO.Path]::GetFullPath($testRoot).TrimEnd('\', '/')
$fixturePrefix = $fixtureBase + [System.IO.Path]::DirectorySeparatorChar
if (-not $fullTestRoot.StartsWith($fixturePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing test root outside validation fixtures: $fullTestRoot"
}

function Assert-RuntimeRoot {
    param([Parameter(Mandatory = $true)][string] $Root)

    $runtimeRoot = Join-Path $Root $manifest.destinationRoot
    foreach ($entry in $entries) {
        $destination = Join-Path $runtimeRoot $entry.destination
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "Expected runtime file was not published: $destination"
        }
    }
    if (Test-Path -LiteralPath (Join-Path $runtimeRoot 'sync-agent.ps1')) {
        throw "Internal toolkit maintenance script leaked to runtime root: $runtimeRoot"
    }
}

function Invoke-FixtureSync {
    param(
        [Parameter(Mandatory = $true)][string] $Agent,
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [switch] $UserScope,
        [switch] $CopilotUserMode
    )

    $invokeArguments = @('-NoProfile', '-File', $syncPath, '-Agent', $Agent, '-InstallRoot', $InstallRoot)
    if ($CopilotUserMode) { $invokeArguments += @('-Mode', 'user') }
    if ($UserScope) { $invokeArguments += '-UserScope' }
    $output = @(& $runner @invokeArguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw ("sync-agent failed for adapter '{0}' at '{1}' (exit {2}): {3}" -f $Agent, $InstallRoot, $LASTEXITCODE, ($output -join [Environment]::NewLine))
    }
}

try {
    New-Item -ItemType Directory -Path $fullTestRoot -Force | Out-Null
    $registry = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters/registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($agent in @($registry.agents | Where-Object { $_.capabilities.skills -eq $true })) {
        $installRoot = Join-Path $fullTestRoot $agent.id
        $syncArgs = @{ Agent = $agent.id; InstallRoot = $installRoot }
        if ($agent.id -eq 'copilot') { $syncArgs['CopilotUserMode'] = $true }
        if ($agent.id -eq 'codex') { $syncArgs['UserScope'] = $true }
        Invoke-FixtureSync @syncArgs

        $expectedRoots = New-Object System.Collections.Generic.List[string]
        [void]$expectedRoots.Add($installRoot)
        if ($agent.id -eq 'codex') {
            [void]$expectedRoots.Add((Join-Path $installRoot 'plugin'))
            [void]$expectedRoots.Add((Join-Path $installRoot '.agents'))
        }
        elseif ($agent.id -eq 'openhands') {
            [void]$expectedRoots.Add((Join-Path $installRoot '.agents'))
        }
        foreach ($root in $expectedRoots) { Assert-RuntimeRoot -Root $root }
    }

    $openHandsUserRoot = Join-Path $fullTestRoot 'openhands-user/.agents'
    Invoke-FixtureSync -Agent 'openhands' -InstallRoot $openHandsUserRoot
    Assert-RuntimeRoot -Root $openHandsUserRoot
    if (Test-Path -LiteralPath (Join-Path $openHandsUserRoot '.agents/scripts')) {
        throw 'OpenHands user install received an accidental nested .agents/scripts copy.'
    }

    Write-Host ("Assert-RuntimeScriptPublish: PASS ({0} manifest files across registered skill adapters)" -f $entries.Count) -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $fullTestRoot) {
        $resolvedCleanup = [System.IO.Path]::GetFullPath($fullTestRoot).TrimEnd('\', '/')
        if (-not $resolvedCleanup.StartsWith($fixturePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing cleanup outside validation fixtures: $resolvedCleanup"
        }
        Remove-Item -LiteralPath $resolvedCleanup -Recurse -Force
    }
}
