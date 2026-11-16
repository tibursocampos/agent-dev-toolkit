#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only start gate for the ADT delivery flow.

.DESCRIPTION
  Checks that preferences.json exists and parses, and that native subagents have a model choice.
  Prints exactly one JSON line: {"ok":true|false,"stage":"start","failures":["..."]}. Exit code 0 when ok, 1 otherwise.
  Never writes. Stage ledger checks (refine, plan, implement) are made in prose by the ADT skills.

.PARAMETER Stage
  Stage to check. Only start is supported.

.PARAMETER Subagents
  Subagents mode for the run: native or none. Required.

.PARAMETER ModelChoice
  Model choice for the run: inherit, reuse_saved, choose_model or n/a. Required.

.PARAMETER SddRoot
  Optional SDD runtime root. Defaults to the root resolved the same way as Invoke-DevelopSessionGate.ps1.

.EXAMPLE
  pwsh -NoProfile -File scripts/runtime/Test-AdtDeliveryPreflight.ps1 -Stage start -Subagents native -ModelChoice inherit
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('start')]
    [string] $Stage,

    [ValidateSet('native', 'none')]
    [string] $Subagents,

    [ValidateSet('inherit', 'reuse_saved', 'choose_model', 'n/a')]
    [string] $ModelChoice,

    [string] $SddRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
. (Join-Path (Join-Path (Split-Path -Parent $scriptDir) '_lib') 'Resolve-EffectiveSddRoot.ps1')

$failures = New-Object System.Collections.Generic.List[string]

function Test-StartGate {
    if ([string]::IsNullOrWhiteSpace($Subagents)) { $failures.Add('Subagents is required for stage start') }
    if ([string]::IsNullOrWhiteSpace($ModelChoice)) { $failures.Add('ModelChoice is required for stage start') }

    $root = Resolve-EffectiveSddRoot -ScriptDirectory $scriptDir -ExplicitSddRoot $SddRoot
    $preferences = Join-Path $root 'preferences.json'
    if (-not (Test-Path -LiteralPath $preferences -PathType Leaf)) {
        $failures.Add("preferences.json missing: $preferences")
    }
    else {
        try {
            $raw = [System.IO.File]::ReadAllText($preferences, [System.Text.Encoding]::UTF8)
            if ([string]::IsNullOrWhiteSpace($raw)) { throw 'empty preferences file' }
            $null = $raw | ConvertFrom-Json
        }
        catch {
            $failures.Add("preferences.json does not parse as JSON: $preferences")
        }
    }

    if ($Subagents -eq 'native' -and $ModelChoice -eq 'n/a') {
        $failures.Add('Subagents native requires a model choice other than n/a')
    }
}

try {
    Test-StartGate
}
catch {
    $failures.Add("unexpected error: $($_.Exception.Message)")
}

$ok = ($failures.Count -eq 0)
$payload = [ordered]@{ ok = $ok; stage = $Stage; failures = @($failures) }
Write-Output ($payload | ConvertTo-Json -Compress)
if ($ok) { exit 0 }
exit 1
