#Requires -Version 5.1

function Invoke-PathSecretsGuardHook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $HookScriptPath,
        [Parameter(Mandatory = $true)][hashtable] $Payload
    )

    $json = $Payload | ConvertTo-Json -Compress -Depth 6
    $hostCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($null -eq $hostCommand) {
        $hostCommand = Get-Command powershell -ErrorAction SilentlyContinue
    }
    if ($null -eq $hostCommand) {
        throw 'Unable to locate a PowerShell host for the path/secrets guard fixture.'
    }

    $output = $json | & $hostCommand.Source -NoProfile -File $HookScriptPath 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 0
    }

    $parsed = $null
    try {
        $parsed = $output.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $parsed = $null
    }

    return [PSCustomObject]@{
        ExitCode = [int]$code
        Output   = $output
        Payload  = $parsed
    }
}

function Invoke-GuardHook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $HookScriptPath,
        [Parameter(Mandatory = $true)][hashtable] $Payload
    )

    Invoke-PathSecretsGuardHook -HookScriptPath $HookScriptPath -Payload $Payload
}

function Invoke-PathSecretsGuardHarness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $AdapterName,
        [Parameter(Mandatory = $true)][string] $HookScriptPath,
        [Parameter(Mandatory = $true)][object[]] $Cases,
        [Parameter(Mandatory = $true)][scriptblock] $GetDecision
    )

    foreach ($case in $Cases) {
        $result = Invoke-PathSecretsGuardHook -HookScriptPath $HookScriptPath -Payload $case.Payload
        $decision = [string](& $GetDecision $result.Payload)
        $expectedDecisionValue = if ($case.PSObject.Properties['ExpectedDecision']) { $case.ExpectedDecision } else { @() }
        $expectedDecisions = @($expectedDecisionValue)
        $decisionMatches = @($expectedDecisions).Count -gt 0 -and @($expectedDecisions) -contains $decision
        $expectedExitProperty = $case.PSObject.Properties | Where-Object { $_.Name -eq 'ExpectedExitCodes' }
        $expectedExitCodes = if ($null -ne $expectedExitProperty) { @($expectedExitProperty.Value) } else { @() }
        $exitMatches = @($expectedExitCodes).Count -gt 0 -and @($expectedExitCodes) -contains $result.ExitCode
        $acceptanceValue = if ($case.PSObject.Properties['Acceptance']) { $case.Acceptance } else { $null }
        $acceptance = if ($acceptanceValue) { [string]$acceptanceValue } else { 'Decision' }

        $passed = switch ($acceptance) {
            'Decision' { $decisionMatches }
            'ExitCode' { $exitMatches }
            'ExitCodeOrDecision' { $decisionMatches -or $exitMatches }
            default { throw ("{0}: unsupported guard acceptance mode '{1}'" -f $case.TestName, $acceptance) }
        }

        if (-not $passed) {
            $failureReasonValue = if ($case.PSObject.Properties['FailureReason']) { $case.FailureReason } else { $null }
            $reason = if ($failureReasonValue) { [string]$failureReasonValue } else { 'guard result did not match the expected decision/exit contract' }
            $diagnostic = "adapter={0}; exit={1}; decision='{2}'; output={3}" -f $AdapterName, $result.ExitCode, $decision, $result.Output.Trim()
            Write-Error ("{0}: FAIL - {1}; {2}" -f $case.TestName, $reason, $diagnostic)
            exit 1
        }

        Write-Host ("{0}: PASS" -f $case.TestName)
    }
}
