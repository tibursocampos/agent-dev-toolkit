function ConvertTo-O3ProgressTableCell([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '—' }
    return (($Value -replace '[\r\n]+', ' ' -replace '\|', '\|').Trim())
}

function Format-O3PlanProgressTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object[]] $PlanSteps,
        [Parameter(Mandatory = $true)][object[]] $StepRows
    )

    $allowedStatuses = @('COMPLETED', 'IN_PROGRESS', 'PENDING', 'BLOCKED', 'SKIPPED', 'UNVERIFIED')
    $planIds = [System.Collections.Generic.List[string]]::new()
    foreach ($step in $PlanSteps) {
        $id = ([string]$step.Id).Trim().ToUpperInvariant()
        if ($id -notmatch '^S\d+$') { throw "Invalid PLAN step id: $id" }
        if ($planIds.Contains($id)) { throw "Duplicate PLAN step id: $id" }
        $planIds.Add($id)
    }
    if ($planIds.Count -eq 0) { throw 'PLAN has no steps to render.' }

    $rowsById = @{}
    foreach ($row in $StepRows) {
        $id = ([string]$row.Id).Trim().ToUpperInvariant()
        if ([string]::IsNullOrWhiteSpace($id)) { throw 'Step-state row has no step id.' }
        if ($rowsById.ContainsKey($id)) { throw "Duplicate step-state row: $id" }
        if ($id -notin $planIds) { throw "Step-state row is not present in PLAN: $id" }
        $status = ([string]$row.Status).Trim().ToUpperInvariant()
        if ($status -notin $allowedStatuses) { throw "Invalid step-state status for ${id}: $status" }
        $rowsById[$id] = [PSCustomObject]@{
            Status = $status
            Dependencies = [string]$row.Dependencies
            Evidence = [string]$row.Evidence
        }
    }
    foreach ($id in $planIds) {
        if (-not $rowsById.ContainsKey($id)) { throw "Missing step-state row for PLAN step: $id" }
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('## O3 progress table')
    $lines.Add('')
    $lines.Add('| Step ID | Step | Dependencies | Status | Checkpoint / evidence | Next action / owner |')
    $lines.Add('|---------|------|--------------|--------|----------------------|---------------------|')
    foreach ($step in $PlanSteps) {
        $id = ([string]$step.Id).Trim().ToUpperInvariant()
        $row = $rowsById[$id]
        $dependencies = ([string]$row.Dependencies).Trim()
        if ([string]::IsNullOrWhiteSpace($dependencies)) { $dependencies = 'none' }
        $nextAction = switch ($row.Status) {
            'COMPLETED' { 'Use persisted checkpoint; O3 parent reconciles' }
            'IN_PROGRESS' { 'Reconcile active child result and gates; O3 parent' }
            'PENDING' { 'Wait for dependencies and dispatch authorization; O3 parent' }
            'BLOCKED' { 'Resolve blocker before dependent dispatch; owner in blocker' }
            'SKIPPED' { 'Confirm skip rationale and dependency policy; O3 parent' }
            'UNVERIFIED' { 'Reconcile PLAN rows before dispatch; O3 parent' }
        }
        $name = ConvertTo-O3ProgressTableCell ([string]$step.Name)
        $lines.Add(('| {0} | {1} | {2} | {3} | {4} | {5} |' -f (ConvertTo-O3ProgressTableCell $id), $name, (ConvertTo-O3ProgressTableCell $dependencies), $row.Status, (ConvertTo-O3ProgressTableCell $row.Evidence), (ConvertTo-O3ProgressTableCell $nextAction)))
    }
    return ($lines -join [Environment]::NewLine)
}
