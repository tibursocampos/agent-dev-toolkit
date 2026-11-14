#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only stage preflight for the ADT delivery flow over one feature PLAN.md.

.DESCRIPTION
  Checks the gate of one stage (start, refine, plan or implement) and prints exactly one JSON line:
  {"ok":true|false,"stage":"<stage>","failures":["..."]}. Exit code 0 when ok, 1 otherwise.
  Collects every failure before answering and never writes. A relative -PlanPath resolves from the
  current directory.

.PARAMETER Stage
  Stage to check: start, refine, plan or implement.

.PARAMETER PlanPath
  Feature PLAN.md path. Required for refine, plan and implement.

.PARAMETER Subagents
  Subagents mode chosen for the run: native or none.

.PARAMETER ModelChoice
  Model choice for the run: inherit, reuse_saved, choose_model or n/a.

.PARAMETER SddRoot
  Optional SDD runtime root. Defaults to the root resolved the same way as Invoke-DevelopSessionGate.ps1.

.EXAMPLE
  pwsh -NoProfile -File scripts/runtime/Test-AdtDeliveryPreflight.ps1 -Stage plan -PlanPath features/001-x/PLAN.md -Subagents native -ModelChoice inherit
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('start', 'refine', 'plan', 'implement')]
    [string] $Stage,

    [string] $PlanPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('native', 'none')]
    [string] $Subagents,

    [Parameter(Mandatory = $true)]
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
$backtick = [string][char]96
$allowedResult = '^(specialist spawned: \S.*|in-parent fallback: \S.*|not applicable|declined by operator)$'
$triageFlags = @('needs_api', 'needs_domain', 'needs_database', 'needs_frontend', 'needs_security', 'needs_devops')
$rosterFlags = @('needs_api', 'needs_domain', 'needs_database', 'needs_security')

function Get-OperationalRecord {
    param([string] $Text)
    $body = New-Object System.Collections.Generic.List[string]
    $inside = $false
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^##\s+Operational record\s*$') { $inside = $true; continue }
        if ($inside -and $line -match '^##\s') { break }
        if ($inside) { $body.Add($line) }
    }
    if (-not $inside) { return $null }
    return ($body -join "`n")
}

function Get-Field {
    param([string] $Record, [string] $Label)
    $match = [regex]::Match($Record, '(?m)^\s*(?:-\s*)?' + [regex]::Escape($Label) + ':[ \t]*(.*?)[ \t]*$')
    if ($match.Success) { return $match.Groups[1].Value }
    return $null
}

function Resolve-PlanFile {
    if ([string]::IsNullOrWhiteSpace($PlanPath)) {
        $failures.Add("PlanPath is required for stage $Stage")
        return $null
    }
    if ($PlanPath -match '(^|[\\/])\.\.([\\/]|$)') {
        $failures.Add('PlanPath must not contain .. segments')
        return $null
    }
    $candidate = $PlanPath
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $base = (Get-Location).ProviderPath
        $candidate = Join-Path $base $candidate
    }
    $full = [System.IO.Path]::GetFullPath($candidate)
    if (-not [string]::Equals([System.IO.Path]::GetFileName($full), 'PLAN.md', [System.StringComparison]::OrdinalIgnoreCase)) {
        $failures.Add('PlanPath must point to a file named PLAN.md')
        return $null
    }
    $directories = [System.IO.Path]::GetDirectoryName($full).Split([char[]]@([char]92, [char]47), [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($directories -notcontains 'features') {
        $failures.Add('PLAN.md must sit under a features directory')
        return $null
    }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        $failures.Add("PLAN.md not found: $full")
        return $null
    }
    return $full
}

function Test-StartGate {
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

function Test-RefineGate {
    $file = Resolve-PlanFile
    if ($null -eq $file) { return $null }
    $text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8).Replace($backtick, '')
    $record = Get-OperationalRecord -Text $text
    if ($null -eq $record) {
        $failures.Add('Operational record section is missing')
        $record = ''
    }

    $mode = Get-Field -Record $record -Label 'Mode'
    if ($null -eq $mode) { $failures.Add('Operational record has no Mode line') }
    elseif ($mode -cnotmatch '^(full|analysis)$') { $failures.Add("Mode must be full or analysis, found '$mode'") }

    $planSubagents = Get-Field -Record $record -Label 'Subagents'
    if ($null -eq $planSubagents) { $failures.Add('Operational record has no Subagents line') }
    elseif ($planSubagents -cnotmatch '^(native|none)$') { $failures.Add("Subagents must be native or none, found '$planSubagents'") }
    elseif ($planSubagents -cne $Subagents) { $failures.Add("Subagents in PLAN is '$planSubagents' but -Subagents is '$Subagents'") }

    $planModel = Get-Field -Record $record -Label 'Model choice'
    if ($null -eq $planModel) { $failures.Add('Operational record has no Model choice line') }
    elseif ($planModel -cnotmatch '^(inherit|reuse_saved|choose_model|n/a)$') { $failures.Add("Model choice must be inherit, reuse_saved, choose_model or n/a, found '$planModel'") }
    elseif ($planModel -cne $ModelChoice) { $failures.Add("Model choice in PLAN is '$planModel' but -ModelChoice is '$ModelChoice'") }

    if (($Subagents -eq 'native' -and $ModelChoice -eq 'n/a') -or ($planSubagents -ceq 'native' -and $planModel -ceq 'n/a')) {
        $failures.Add('Subagents native requires a model choice other than n/a')
    }

    $ledgerLine = Get-Field -Record $record -Label 'Stage ledger'
    $ledger = $null
    if ($null -eq $ledgerLine) {
        $failures.Add('Operational record has no Stage ledger line')
    }
    else {
        $parts = [regex]::Match($ledgerLine, '^refine=(pending|done),\s*plan=(pending|approved),\s*implement=(pending|in_progress|done)$')
        if ($parts.Success) {
            $ledger = @{ refine = $parts.Groups[1].Value; plan = $parts.Groups[2].Value; implement = $parts.Groups[3].Value }
        }
        else {
            $failures.Add("Stage ledger is malformed: '$ledgerLine'")
        }
    }

    return [pscustomobject]@{ Text = $text; Record = $record; Mode = $mode; Ledger = $ledger }
}

function Test-TriageTable {
    param([string] $Text)
    $nature = [regex]::Match($Text, '(?m)^\s*(?:-\s*)?Nature:\s*(greenfield|brownfield|operational)\s*$')
    $natureValue = $null
    if ($nature.Success) { $natureValue = $nature.Groups[1].Value }
    else { $failures.Add('Nature line missing or not greenfield, brownfield or operational') }

    $rows = @{}
    foreach ($line in ($Text -split '\r?\n')) {
        $trimmed = $line.Trim()
        if (-not $trimmed.StartsWith('|')) { continue }
        $cells = @($trimmed.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 4) { continue }
        if ($cells[0] -ceq 'Flag' -or $cells[0] -match '^[-: ]*$') { continue }
        if ($rows.ContainsKey($cells[0])) {
            $failures.Add("triage row '$($cells[0])' appears more than once")
            continue
        }
        $rows[$cells[0]] = [pscustomobject]@{ Value = $cells[1]; Result = $cells[3] }
    }

    foreach ($flag in $triageFlags) {
        if (-not $rows.ContainsKey($flag)) { $failures.Add("triage row missing: $flag"); continue }
        if ($rows[$flag].Value -cnotmatch '^(true|false)$') { $failures.Add("triage $flag Value must be true or false") }
    }

    if ($natureValue -ceq 'brownfield' -or $natureValue -ceq 'greenfield') {
        $natureKey = "nature: $natureValue"
        if (-not $rows.ContainsKey($natureKey)) {
            $failures.Add("triage row missing: $natureKey")
        }
        elseif ($rows[$natureKey].Result -ceq 'not applicable') {
            $failures.Add("triage $natureKey must name a specialist, not 'not applicable'")
        }
    }

    foreach ($key in $rows.Keys) {
        $result = $rows[$key].Result
        if ($result -cnotmatch $allowedResult) {
            $failures.Add("triage $key Result is not allowed: '$result'")
        }
        elseif ($Subagents -eq 'native' -and $result -clike 'in-parent fallback*') {
            $failures.Add("triage $key uses in-parent fallback but spawn was available (Subagents native)")
        }
    }

    foreach ($flag in $rosterFlags) {
        if ($rows.ContainsKey($flag) -and $rows[$flag].Value -ceq 'true' -and $rows[$flag].Result -ceq 'not applicable') {
            $failures.Add("triage $flag is true but its Result is not applicable")
        }
    }
}

function Test-PlanGate {
    param([object] $State)
    if ($State.Mode -ceq 'analysis') { $failures.Add('Mode analysis stops after refine') }
    if ($null -ne $State.Ledger -and $State.Ledger.refine -cne 'done') {
        $failures.Add('Stage ledger refine must be done before plan')
    }
    Test-TriageTable -Text $State.Text
}

function Test-ImplementGate {
    param([object] $State)
    Test-PlanGate -State $State
    if ($null -ne $State.Ledger -and $State.Ledger.plan -cne 'approved') {
        $failures.Add('Stage ledger plan must be approved before implement')
    }
    if ($State.Record -cnotmatch '(?m)^\s*(?:-\s*)?Approval:\s*approved\s+\d{4}-\d{2}-\d{2}\b') {
        $failures.Add('Operational record has no Approval line that reads approved <YYYY-MM-DD>')
    }
}

try {
    switch ($Stage) {
        'start' { Test-StartGate }
        'refine' { $null = Test-RefineGate }
        'plan' {
            $state = Test-RefineGate
            if ($null -ne $state) { Test-PlanGate -State $state }
        }
        'implement' {
            $state = Test-RefineGate
            if ($null -ne $state) { Test-ImplementGate -State $state }
        }
    }
}
catch {
    $failures.Add("unexpected error: $($_.Exception.Message)")
}

$ok = ($failures.Count -eq 0)
$payload = [ordered]@{ ok = $ok; stage = $Stage; failures = @($failures) }
Write-Output ($payload | ConvertTo-Json -Compress)
if ($ok) { exit 0 }
exit 1
