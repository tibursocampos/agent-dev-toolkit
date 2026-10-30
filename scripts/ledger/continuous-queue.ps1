function Test-ContinuousQueueStepAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][bool] $ReceiptValid,
        [Parameter(Mandatory = $true)][bool] $SessionGatesValid,
        [Parameter(Mandatory = $true)][bool] $ClaimValid,
        [Parameter(Mandatory = $true)][object[]] $QueueSteps,
        [Parameter(Mandatory = $true)][int] $RequestedStep,
        [Parameter(Mandatory = $true)][bool] $CheckpointPersisted,
        [Parameter(Mandatory = $true)][bool] $CheckpointReread,
        [Parameter(Mandatory = $true)][bool] $ResultPresented
    )

    function New-Denial {
        param([string] $Reason)
        return [PSCustomObject]@{ Allowed = $false; Reason = $Reason; Step = $null }
    }

    function Has-Field {
        param([object] $Value, [string] $Name)
        return ($null -ne $Value -and $null -ne $Value.PSObject.Properties[$Name])
    }

    if (-not $ReceiptValid) {
        return (New-Denial -Reason 'receipt_invalid')
    }

    if (-not $SessionGatesValid) {
        return (New-Denial -Reason 'session_gates_invalid')
    }

    if (-not $ClaimValid) {
        return (New-Denial -Reason 'claim_invalid')
    }

    if (-not $CheckpointPersisted -or -not $CheckpointReread -or -not $ResultPresented) {
        return (New-Denial -Reason 'reconciliation_incomplete')
    }

    if ($QueueSteps.Count -eq 0 -or @($QueueSteps | Where-Object {
        $validStatus = @('PENDING', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED', 'FAILED')
        -not (Has-Field $_ 'Step') -or -not (Has-Field $_ 'Status') -or -not (Has-Field $_ 'DependsOn') -or
        $_.Step -isnot [int] -or $_.Step -lt 1 -or $_.Status -isnot [string] -or
        $_.Status -cnotin $validStatus -or $null -eq $_.DependsOn -or
        @($_.DependsOn | Where-Object { $_ -isnot [int] -or $_ -lt 1 }).Count -gt 0
    }).Count -gt 0) {
        return (New-Denial -Reason 'queue_invalid')
    }

    $orderedSteps = @($QueueSteps | Sort-Object { [int]$_.Step })
    $stepIds = @($orderedSteps | ForEach-Object { [int]$_.Step })
    if (@($stepIds | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
        return (New-Denial -Reason 'queue_invalid')
    }

    foreach ($step in $orderedSteps) {
        $dependencies = @($step.DependsOn)
        if (@($dependencies | Group-Object | Where-Object Count -gt 1).Count -gt 0 -or
            @($dependencies | Where-Object { $_ -eq $step.Step -or $_ -notin $stepIds }).Count -gt 0) {
            return (New-Denial -Reason 'queue_invalid')
        }
    }

    $eligibleSteps = @($orderedSteps | Where-Object {
        if ($_.Status -cne 'PENDING' -or $_.Step -isnot [int]) { return $false }
        foreach ($dependency in @($_.DependsOn)) {
            $dependencyStep = @($orderedSteps | Where-Object {
                $_.Step -eq [int]$dependency
            } | Select-Object -First 1)
            if ($dependencyStep.Count -ne 1 -or $dependencyStep[0].Status -cne 'COMPLETED') {
                return $false
            }
        }
        return $true
    })

    if ($eligibleSteps.Count -eq 0) {
        return (New-Denial -Reason 'no_next_step_eligible')
    }

    $nextStep = [int]$eligibleSteps[0].Step
    if ($RequestedStep -ne $nextStep) {
        return (New-Denial -Reason 'step_outside_next_eligible')
    }

    return [PSCustomObject]@{
        Allowed = $true
        Reason  = 'next_step_authorized'
        Step    = $nextStep
    }
}
