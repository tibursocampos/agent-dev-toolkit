#Requires -Version 5.1
<#
.SYNOPSIS
  Fixture contract for the Integrated Delivery publication preflight and Codex/Claude sync.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$preflight = Join-Path $PSScriptRoot 'Assert-DeliveryPublishCollision.ps1'
$sync = Join-Path $repoRoot 'scripts/sync-agent.ps1'
$fixtureParent = Join-Path $repoRoot 'features/030-parallel-delivery-flow/ANALYSIS/fixtures'
$fixtureBase = Join-Path $fixtureParent ("stage6-{0}" -f [guid]::NewGuid().ToString('N'))
$pwsh = (Get-Process -Id $PID).Path
$skills = @(
    'integrated-delivery',
    'integrated-delivery-refine',
    'integrated-delivery-plan',
    'integrated-delivery-review',
    'integrated-delivery-implement'
)
$roots = @('codex', 'claude')

$null = New-Item -ItemType Directory -Path $fixtureBase -Force

try {
    # A foreign ID in either Codex destination must fail before sync-agent can write.
    $collisionRoot = Join-Path $fixtureBase 'collision-codex'
    $null = New-Item -ItemType Directory -Path (Join-Path $collisionRoot 'skills/integrated-delivery') -Force
    $sentinelPath = Join-Path $collisionRoot 'skills/integrated-delivery/SENTINEL.txt'
    [System.IO.File]::WriteAllText($sentinelPath, 'preserve')
    $beforeCollision = @(Get-ChildItem -LiteralPath $collisionRoot -Force -Recurse | ForEach-Object FullName | Sort-Object)
    $collisionOutput = @(& $pwsh -NoProfile -File $preflight -Agent codex -InstallRoot $collisionRoot 2>&1)
    $collisionExit = $LASTEXITCODE
    if ($collisionExit -eq 0) { throw 'Expected Codex foreign-ID collision to fail.' }
    if (-not (Test-Path -LiteralPath $sentinelPath -PathType Leaf)) { throw 'Collision preflight modified/deleted the existing sentinel.' }
    $afterCollision = @(Get-ChildItem -LiteralPath $collisionRoot -Force -Recurse | ForEach-Object FullName | Sort-Object)
    if (Compare-Object -ReferenceObject $beforeCollision -DifferenceObject $afterCollision) {
        throw 'Collision preflight wrote files before rejecting the collision.'
    }
    Write-Host 'PASS foreign Codex skill ID rejected before any publication writes.'

    foreach ($agent in $roots) {
        $installRoot = Join-Path $fixtureBase ("publish-{0}" -f $agent)
        if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
        $null = New-Item -ItemType Directory -Path $installRoot -Force
        $preflightOutput = @(& $pwsh -NoProfile -File $preflight -Agent $agent -InstallRoot $installRoot 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Collision preflight failed for clean $agent fixture: $($preflightOutput -join ' ')" }
        $syncOutput = @(& $pwsh -NoProfile -File $sync -Agent $agent -InstallRoot $installRoot 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "sync-agent failed for isolated $agent fixture: $($syncOutput -join ' ')" }

        $skillRoots = if ($agent -eq 'codex') {
            @((Join-Path $installRoot 'skills'), (Join-Path $installRoot 'plugin/skills'))
        } else {
            @((Join-Path $installRoot 'skills'))
        }
        foreach ($skillsRoot in $skillRoots) {
            foreach ($skill in $skills) {
                $skillPath = Join-Path (Join-Path $skillsRoot $skill) 'SKILL.md'
                if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
                    throw "Published $agent fixture is missing '$skillPath'."
                }
            }
        }
        $sddRoot = Join-Path $installRoot 'sdd'
        if (-not (Test-Path -LiteralPath (Join-Path $sddRoot 'manifest.json') -PathType Leaf)) {
            throw "sync-agent did not prepare isolated SDD state at '$sddRoot'."
        }
        Write-Host ("PASS isolated {0} publish: all experimental IDs and SDD state present." -f $agent)
    }
}
finally {
    Remove-Item -LiteralPath $fixtureBase -Recurse -Force
}
