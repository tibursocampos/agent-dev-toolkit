#Requires -Version 5.1
<#
.SYNOPSIS
  Evaluates eligibility and safe resumption for an integrated-delivery PLAN.
.DESCRIPTION
  Read-only decision helper. It never edits the PLAN or repository. Operational
  blocks are JSON between the exact DELIVERY markers in EXECUTION.md.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [Parameter(Mandatory = $true)][ValidateSet('step_by_step', 'continuous')][string] $Cadence,
    [Parameter(Mandatory = $true)][string] $CurrentInputIdentity,
    [Parameter(Mandatory = $true)][string] $CurrentBranch,
    [Parameter(Mandatory = $true)][string] $CurrentHead,
    [switch] $Resume,
    [switch] $StepAuthorization,
    [switch] $ContinuousAuthorization
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Decision([bool]$Allowed, [string]$Reason, [string]$Step = '') {
    [pscustomobject]@{ allowed = $Allowed; reason = $Reason; step = $Step }
}

function Get-Block([string]$Text, [string]$Name) {
    $escaped = [regex]::Escape($Name)
    $pattern = '(?ms)^<!-- DELIVERY:' + $escaped + ':BEGIN -->\r?\n(.*?)\r?\n<!-- DELIVERY:' + $escaped + ':END -->$'
    $matches = [regex]::Matches($Text, $pattern)
    if ($matches.Count -ne 1) { throw ('block_{0}_missing_or_duplicate' -f $Name) }
    try { return ($matches[0].Groups[1].Value | ConvertFrom-Json -ErrorAction Stop) }
    catch { throw ('block_{0}_invalid_json' -f $Name) }
}

function Get-PlanIdentity([string]$Text) {
    $pattern = '(?ms)^<!-- DELIVERY:[A-Z0-9-]+:BEGIN -->\r?\n.*?\r?\n<!-- DELIVERY:[A-Z0-9-]+:END -->\r?\n?'
    $projection = [regex]::Replace($Text, $pattern, '')
    $projection = $projection.TrimStart([char]0xFEFF).Replace([string][char]13 + [char]10, [string][char]10).Replace([string][char]13, [string][char]10)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($projection)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally { $sha.Dispose() }
}

function Test-Field($Object, [string]$Name) {
    return ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name])
}

try {
    if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) { throw 'plan_missing' }
    $resolved = (Resolve-Path -LiteralPath $PlanPath).Path
    $text = [System.IO.File]::ReadAllText($resolved, [System.Text.Encoding]::UTF8)
    if ($text.Contains([string][char]0xFFFD)) { throw 'plan_invalid_utf8' }

    # Unknown, duplicate, nested, or unbalanced marker blocks fail closed.
    $all = [regex]::Matches($text, '(?m)^<!-- DELIVERY:([A-Z0-9-]+):(BEGIN|END) -->$')
    $markerState = @{}
    $openMarker = ''
    foreach ($m in $all) {
        $name = $m.Groups[1].Value
        if ($name -notin @('PROGRESS', 'CHECKPOINT', 'APPROVAL') -and $name -notmatch '^STEP-[A-Za-z0-9-]+$') { throw 'marker_unknown' }
        $key = $name + ':' + $m.Groups[2].Value
        if ($markerState.ContainsKey($key)) { throw 'marker_duplicate' }
        $markerState[$key] = $true
        if ($m.Groups[2].Value -ceq 'BEGIN') {
            if (-not [string]::IsNullOrEmpty($openMarker)) { throw 'marker_nested' }
            $openMarker = $name
        }
        else {
            if ($openMarker -cne $name) { throw 'marker_unbalanced' }
            $openMarker = ''
        }
    }
    if (-not [string]::IsNullOrEmpty($openMarker)) { throw 'marker_unbalanced' }
    foreach ($name in @('PROGRESS', 'CHECKPOINT', 'APPROVAL')) {
        if (-not $markerState.ContainsKey(($name + ':BEGIN')) -or -not $markerState.ContainsKey(($name + ':END'))) { throw 'marker_unbalanced' }
    }

    $progress = Get-Block $text 'PROGRESS'
    $checkpoint = Get-Block $text 'CHECKPOINT'
    $approval = Get-Block $text 'APPROVAL'
    if (-not (Test-Field $approval 'state') -or $approval.state -cne 'approved') { throw 'plan_not_approved' }
    if (-not (Test-Field $approval 'identity') -or $approval.identity -cne (Get-PlanIdentity $text)) { throw 'approval_identity_stale' }
    if (-not (Test-Field $approval 'input_identity') -or $approval.input_identity -cne $CurrentInputIdentity) { throw 'material_input_identity_stale' }
    if (-not (Test-Field $approval 'review_state') -or $approval.review_state -notin @('reviewed', 'bypassed')) { throw 'review_required' }
    if ($approval.review_state -ceq 'bypassed' -and
        ((-not (Test-Field $approval 'review_bypass_reason')) -or [string]::IsNullOrWhiteSpace([string]$approval.review_bypass_reason) -or
         (-not (Test-Field $approval 'review_bypass_operator_choice')) -or [string]$approval.review_bypass_operator_choice -cne 'bypass')) {
        throw 'review_bypass_evidence_missing'
    }
    if ((Test-Field $approval 'blocking_findings') -and @($approval.blocking_findings).Count -gt 0) { throw 'blocking_review_findings' }
    if ((Test-Field $approval 'unresolved_decisions') -and @($approval.unresolved_decisions).Count -gt 0) { throw 'material_decision_unresolved' }
    if (-not (Test-Field $progress 'cadence')) { throw 'cadence_missing' }
    if ($progress.cadence -cne $Cadence) { throw 'cadence_mismatch' }

    if ($Resume) {
        if (-not (Test-Field $checkpoint 'branch') -or $checkpoint.branch -cne $CurrentBranch) { throw 'branch_mismatch' }
        if (-not (Test-Field $checkpoint 'head') -or $checkpoint.head -cne $CurrentHead) { throw 'head_mismatch' }
    }

    $stepMatches = [regex]::Matches($text, '(?ms)^<!-- DELIVERY:STEP-([A-Za-z0-9-]+):BEGIN -->\r?\n(.*?)\r?\n<!-- DELIVERY:STEP-\1:END -->$')
    if ($stepMatches.Count -eq 0) { throw 'step_blocks_missing' }
    $steps = @{}
    $stepOrder = [System.Collections.Generic.List[string]]::new()
    foreach ($m in $stepMatches) {
        $id = $m.Groups[1].Value
        if ($steps.ContainsKey($id)) { throw 'step_block_duplicate' }
        try { $step = $m.Groups[2].Value | ConvertFrom-Json -ErrorAction Stop } catch { throw 'step_block_invalid_json' }
        if (-not (Test-Field $step 'id') -or $step.id -cne $id -or -not (Test-Field $step 'status') -or -not (Test-Field $step 'depends_on')) { throw 'step_block_invalid_shape' }
        if ($step.status -cnotin @('PENDING', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED')) { throw 'step_status_invalid' }
        $steps[$id] = $step
        $stepOrder.Add($id)
    }
    if ((Test-Field $checkpoint 'active_step') -and -not [string]::IsNullOrWhiteSpace([string]$checkpoint.active_step)) {
        $activeId = [string]$checkpoint.active_step
        if (-not $steps.ContainsKey($activeId)) { throw 'checkpoint_active_step_missing' }
        if ($steps[$activeId].status -ceq 'IN_PROGRESS') { throw 'orphaned_in_progress_reconcile_required' }
        throw 'checkpoint_active_step_inconsistent'
    }
    foreach ($step in $steps.Values) {
        if ($step.status -ceq 'BLOCKED') { throw 'blocked_step_requires_resolution' }
        if ($step.status -ceq 'IN_PROGRESS') { throw 'orphaned_in_progress_reconcile_required' }
        foreach ($dependency in @($step.depends_on)) {
            if (-not $steps.ContainsKey([string]$dependency) -or [string]$dependency -ceq [string]$step.id) { throw 'dependency_invalid' }
        }
    }
    $eligibleId = ''
    foreach ($id in $stepOrder) {
        $candidate = $steps[$id]
        if ($candidate.status -cne 'PENDING') { continue }
        $dependenciesReady = $true
        foreach ($dependency in @($candidate.depends_on)) {
            if ($steps[[string]$dependency].status -cne 'COMPLETED') { $dependenciesReady = $false; break }
        }
        if ($dependenciesReady) { $eligibleId = $id; break }
    }
    if ([string]::IsNullOrWhiteSpace($eligibleId)) { throw 'no_eligible_step' }
    if ($Cadence -eq 'step_by_step' -and -not $StepAuthorization) { throw 'step_authorization_required' }
    if ($Cadence -eq 'continuous' -and -not $ContinuousAuthorization) { throw 'continuous_authorization_required' }
    return (New-Decision $true 'next_step_eligible' $eligibleId) | ConvertTo-Json -Compress
}
catch {
    $reason = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($reason)) { $reason = 'execution_state_invalid' }
    New-Decision $false $reason '' | ConvertTo-Json -Compress
    exit 1
}
