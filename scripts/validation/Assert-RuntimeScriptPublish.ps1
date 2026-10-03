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
$syncSource = Get-Content -LiteralPath $syncPath -Raw -Encoding UTF8
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$entries = @($manifest.files)
if ($entries.Count -eq 0) { throw 'Runtime manifest contains no files.' }

$runtimeFunctionStart = $syncSource.IndexOf('function Publish-RuntimeScripts {', [System.StringComparison]::Ordinal)
$runtimeFunctionEnd = $syncSource.IndexOf("`ntry {", $runtimeFunctionStart + 1, [System.StringComparison]::Ordinal)
if ($runtimeFunctionStart -lt 0 -or $runtimeFunctionEnd -lt 0) {
    throw 'Could not locate Publish-RuntimeScripts function for pre-copy safety assertion.'
}
$runtimeFunction = $syncSource.Substring($runtimeFunctionStart, $runtimeFunctionEnd - $runtimeFunctionStart)
$copyIndex = $runtimeFunction.IndexOf('Copy-Item -LiteralPath $source -Destination $confirmedDestination -Force', [System.StringComparison]::Ordinal)
foreach ($requiredCheck in @(
    'Confirm-InstallRootAllowsWrite -InstallRoot $InstallRoot',
    'Confirm-InstallRootAllowsWrite -InstallRoot $toolkitRoot',
    'Confirm-InstallRootAllowsWrite -InstallRoot $destinationDirectory'
)) {
    $checkIndex = $runtimeFunction.IndexOf($requiredCheck, [System.StringComparison]::Ordinal)
    if ($checkIndex -lt 0 -or $copyIndex -lt 0 -or $checkIndex -ge $copyIndex) {
        throw "Runtime publication must revalidate '$requiredCheck' before Copy-Item."
    }
}
$confirmBeforeRuntimeCall = $syncSource.IndexOf('$resolvedInstallRoot = Confirm-InstallRootAllowsWrite -InstallRoot $resolvedInstallRoot', [System.StringComparison]::Ordinal)
$runtimeCall = $syncSource.IndexOf('Publish-RuntimeScripts -RepoRoot $repoRoot', [System.StringComparison]::Ordinal)
if ($confirmBeforeRuntimeCall -lt 0 -or $runtimeCall -lt 0 -or $confirmBeforeRuntimeCall -ge $runtimeCall) {
    throw 'sync-agent must revalidate the resolved InstallRoot immediately before runtime publication.'
}

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

    $publishedFiles = @(Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File -ErrorAction Stop)
    foreach ($publishedFile in $publishedFiles) {
        $relative = $publishedFile.FullName.Substring($runtimeRoot.Length).TrimStart('\', '/')
        if ($relative -match '(^|[\\/])(adapters|core)([\\/]|$)' -or $relative -match '(^|[\\/])sync-agent\.ps1$') {
            throw "Internal checkout path leaked into runtime root '$runtimeRoot': $relative"
        }
    }
}

function Assert-AdapterCapabilityBoundary {
    param(
        [Parameter(Mandatory = $true)]$Adapter,
        [Parameter(Mandatory = $true)][string]$InstallRoot
    )

    if ($Adapter.capabilities.skills -ne $true) {
        throw "Adapter '$($Adapter.id)' was selected without declaring skills capability."
    }
    if ([string]::IsNullOrWhiteSpace([string]$Adapter.capabilities.subagents)) {
        throw "Adapter '$($Adapter.id)' has no declared subagents capability."
    }

    # Filesystem publication is static evidence only. A fixture cannot prove
    # that a real host loaded the files or delivered a prompt/message.
    Write-Host ("Adapter={0}; Surface=isolated-install; Evidence=static; HostExecution=SKIPPED; Reason=host/credentials not exercised" -f $Adapter.id)
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
        # Keep Codex on the disposable InstallRoot fixture. Passing UserScope
        # opts into the real profile and would invalidate isolated-install
        # evidence (and may require host credentials).
        Invoke-FixtureSync @syncArgs

        $expectedRoots = New-Object System.Collections.Generic.List[string]
        [void]$expectedRoots.Add($installRoot)
        if ($agent.id -eq 'codex') {
            [void]$expectedRoots.Add((Join-Path $installRoot 'plugin'))
        }
        elseif ($agent.id -eq 'openhands') {
            [void]$expectedRoots.Add((Join-Path $installRoot '.agents'))
        }
        foreach ($root in $expectedRoots) { Assert-RuntimeRoot -Root $root }
        Assert-AdapterCapabilityBoundary -Adapter $agent -InstallRoot $installRoot
    }

    $openHandsUserRoot = Join-Path $fullTestRoot 'openhands-user/.agents'
    Invoke-FixtureSync -Agent 'openhands' -InstallRoot $openHandsUserRoot
    Assert-RuntimeRoot -Root $openHandsUserRoot
    Assert-AdapterCapabilityBoundary -Adapter ($registry.agents | Where-Object id -eq 'openhands') -InstallRoot $openHandsUserRoot
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
