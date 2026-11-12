#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $SummaryPath,
    [int] $StallRounds = 2,
    [long] $MaxTokens,
    [long] $MaxInputBytes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-JsonInteger {
    param($Value)
    return ($Value -is [int]) -or ($Value -is [long])
}

function Test-NonNegativeInteger {
    param($Value)
    return (Test-JsonInteger $Value) -and ($Value -ge 0)
}

function Get-RequiredProperty {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Context
    )

    if ($null -eq $Object) { throw ('{0} must be a JSON object.' -f $Context) }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { throw ('{0} is missing key {1}.' -f $Context, $Name) }
    if ($property.Value -is [System.Array]) { return , $property.Value }
    return $property.Value
}

try {
    if ($StallRounds -lt 1) { throw 'StallRounds must be an integer of at least 1.' }
    $hasMaxTokens = $PSBoundParameters.ContainsKey('MaxTokens')
    $hasMaxInputBytes = $PSBoundParameters.ContainsKey('MaxInputBytes')
    if ($hasMaxTokens -and $MaxTokens -lt 0) { throw 'MaxTokens must be a non-negative integer.' }
    if ($hasMaxInputBytes -and $MaxInputBytes -lt 0) { throw 'MaxInputBytes must be a non-negative integer.' }
    if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) { throw 'Summary file not found.' }

    $summaryText = [System.IO.File]::ReadAllText($SummaryPath)
    if ([string]::IsNullOrWhiteSpace($summaryText)) { throw 'Summary file is empty.' }
    $summary = ConvertFrom-Json -InputObject $summaryText -Depth 50
    $roundsValue = Get-RequiredProperty -Object $summary -Name 'rounds' -Context 'Summary'
    if ($roundsValue -isnot [System.Array]) { throw 'Summary rounds must be a JSON array.' }
    $rounds = @($roundsValue)
    if ($rounds.Count -eq 0) { throw 'rounds must contain at least one round.' }

    $blockingByRound = [System.Collections.Generic.List[long]]::new()
    $tokenTotal = [long]0
    $tokensReported = $false
    $inputBudgetExceeded = $false

    for ($index = 0; $index -lt $rounds.Count; $index++) {
        $context = 'Round {0}' -f ($index + 1)
        $roundValue = Get-RequiredProperty -Object $rounds[$index] -Name 'round' -Context $context
        if ((-not (Test-JsonInteger $roundValue)) -or ($roundValue -ne ($index + 1))) {
            throw ('Rounds must be consecutive integers starting at 1; position {0} holds round {1}.' -f ($index + 1), $roundValue)
        }

        $blocking = Get-RequiredProperty -Object $rounds[$index] -Name 'blocking_open' -Context $context
        if (-not (Test-NonNegativeInteger $blocking)) { throw ('{0} blocking_open must be a non-negative integer.' -f $context) }
        $blockingByRound.Add([long]$blocking)

        $tokens = Get-RequiredProperty -Object $rounds[$index] -Name 'reported_tokens' -Context $context
        if ($null -ne $tokens) {
            if (-not (Test-NonNegativeInteger $tokens)) { throw ('{0} reported_tokens must be a non-negative integer or null.' -f $context) }
            $tokenTotal += [long]$tokens
            $tokensReported = $true
        }

        $inputBytes = Get-RequiredProperty -Object $rounds[$index] -Name 'input_bytes' -Context $context
        if ($null -ne $inputBytes) {
            if (-not (Test-NonNegativeInteger $inputBytes)) { throw ('{0} input_bytes must be a non-negative integer or null.' -f $context) }
            if ($hasMaxInputBytes -and ($inputBytes -gt $MaxInputBytes)) { $inputBudgetExceeded = $true }
        }
    }

    $reasons = [System.Collections.Generic.List[string]]::new()
    $count = $blockingByRound.Count
    if (($count -gt $StallRounds) -and ($blockingByRound[$count - 1] -gt 0)) {
        $stalled = $true
        for ($i = $count - $StallRounds; $i -lt $count; $i++) {
            if ($blockingByRound[$i] -lt $blockingByRound[$i - 1]) {
                $stalled = $false
                break
            }
        }
        if ($stalled) { $reasons.Add('no_convergence') }
    }
    if ($hasMaxTokens -and ($tokenTotal -gt $MaxTokens)) { $reasons.Add('token_budget_exceeded') }
    if ($inputBudgetExceeded) { $reasons.Add('input_budget_exceeded') }

    $totalTokens = $null
    if ($tokensReported) { $totalTokens = $tokenTotal }
    $escalate = $reasons.Count -gt 0

    $result = [pscustomobject]@{
        escalate               = $escalate
        reasons                = [string[]]$reasons.ToArray()
        blocking_open_by_round = [long[]]$blockingByRound.ToArray()
        total_tokens           = $totalTokens
    }
    [Console]::Out.WriteLine(($result | ConvertTo-Json -Compress))
    if ($escalate) { exit 3 }
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
