#Requires -Version 5.1
<#
.SYNOPSIS
  Fail-closed preflight for publishing the experimental Integrated Delivery skills.
.DESCRIPTION
  Run this immediately before sync-agent. It checks every skill destination used by
  the Codex and Claude adapters and rejects a matching directory unless the current
  toolkit managed-skills manifest already owns that skill id. It performs no writes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('codex', 'claude')]
    [string] $Agent,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $InstallRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillIds = @(
    'integrated-delivery',
    'integrated-delivery-refine',
    'integrated-delivery-plan',
    'integrated-delivery-review',
    'integrated-delivery-implement'
)
$root = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd([char[]]@('\', '/'))
if ([string]::IsNullOrWhiteSpace($root)) { throw 'InstallRoot must resolve to a non-root directory.' }

$skillsRoots = if ($Agent -eq 'codex') {
    @((Join-Path $root 'skills'), (Join-Path (Join-Path $root 'plugin') 'skills'))
} else {
    @((Join-Path $root 'skills'))
}

$collisions = [System.Collections.Generic.List[string]]::new()
foreach ($skillsRoot in $skillsRoots) {
    $manifestPath = Join-Path $skillsRoot '.toolkit-managed-skills.json'
    $managedIds = @()
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        try {
            $manifest = [System.IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        } catch {
            throw "Cannot safely check existing managed-skills manifest '$manifestPath': $($_.Exception.Message)"
        }
        if ($null -eq $manifest -or $manifest.PSObject.Properties.Name -notcontains 'skills') {
            throw "Cannot safely check existing managed-skills manifest '$manifestPath': missing skills array."
        }
        $managedIds = @($manifest.skills | ForEach-Object { [string]$_ })
    }

    foreach ($skillId in $skillIds) {
        $candidate = Join-Path $skillsRoot $skillId
        if ((Test-Path -LiteralPath $candidate) -and $skillId -notin $managedIds) {
            $collisions.Add($candidate)
        }
    }
}

if ($collisions.Count -gt 0) {
    throw ("Publication blocked before sync-agent: destination skill id is already present and is not listed as toolkit-managed:`n - " + ($collisions -join "`n - "))
}

Write-Host ("PASS delivery skill collision preflight ({0}, {1} roots): no foreign destination IDs." -f $Agent, @($skillsRoots).Count)
