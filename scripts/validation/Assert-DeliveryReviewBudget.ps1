#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptsRoot = Split-Path -Parent $PSScriptRoot
$budgetScript = Join-Path $scriptsRoot 'runtime/Test-DeliveryReviewBudget.ps1'

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-review-budget-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0
$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-Budget {
    param([Parameter(Mandatory = $true)][string[]] $CliArgs)

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $budgetScript) + $CliArgs
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $childHost
    $startInfo.Arguments = (@($argList | ForEach-Object { ConvertTo-ProcessArgument ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $stdoutText = $stdoutTask.Result

    $parsed = $null
    if ($stdoutText.Trim().Length -gt 0) {
        try { $parsed = $stdoutText.Trim() | ConvertFrom-Json } catch { $parsed = $null }
    }
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Result = $parsed; Stdout = $stdoutText; Stderr = $stderrText }
}

function Assert-ExitCode([int]$Expected, $Run, [string]$Name) {
    Assert-Equal ([string]$Expected) ([string]$Run.ExitCode) $Name
}

function Get-ReasonsText($Run) {
    return (@($Run.Result.reasons) -join ',')
}

function Get-BlockingText($Run) {
    return (@($Run.Result.blocking_open_by_round) -join ',')
}

function New-SummaryFile {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Json
    )

    $path = Join-Path $tempRoot ($Name + '.json')
    [System.IO.File]::WriteAllText($path, $Json, $utf8)
    return $path
}

function New-RoundJson {
    param($Round = 1, $Blocking = 0, $Tokens = 'null', $Bytes = 'null')

    return ('{{"round":{0},"blocking_open":{1},"reported_tokens":{2},"input_bytes":{3}}}' -f $Round, $Blocking, $Tokens, $Bytes)
}

function New-SummaryText {
    param([string[]] $Rounds)

    return ('{{"rounds":[{0}]}}' -f ($Rounds -join ','))
}

function New-SummaryJson {
    param(
        [Parameter(Mandatory = $true)][int[]] $Blocking,
        [object[]] $Tokens = @(),
        [object[]] $Bytes = @()
    )

    $rounds = @(for ($i = 0; $i -lt $Blocking.Count; $i++) {
        $tokenValue = 'null'
        if (($i -lt $Tokens.Count) -and ($null -ne $Tokens[$i])) { $tokenValue = [string]$Tokens[$i] }
        $byteValue = 'null'
        if (($i -lt $Bytes.Count) -and ($null -ne $Bytes[$i])) { $byteValue = [string]$Bytes[$i] }
        New-RoundJson -Round ($i + 1) -Blocking $Blocking[$i] -Tokens $tokenValue -Bytes $byteValue
    })
    return New-SummaryText -Rounds $rounds
}

function Get-TreeSnapshot {
    return (@(Get-ChildItem -LiteralPath $tempRoot -Recurse -Force | Sort-Object FullName | ForEach-Object {
        '{0}|{1}|{2}' -f $_.FullName, $_.Length, $_.LastWriteTimeUtc.Ticks
    }) -join "`n")
}

try {
    Assert-True (Test-Path -LiteralPath $budgetScript -PathType Leaf) 'Should_HaveRuntimeScript_When_Asserted'

    $converging = New-SummaryFile -Name 'converging' -Json (New-SummaryJson -Blocking @(5, 3, 1))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $converging)
    Assert-ExitCode 0 $run 'Should_ExitZero_When_BlockingDecreases'
    Assert-True ($run.Result.escalate -eq $false) 'Should_NotEscalate_When_BlockingDecreases'
    Assert-Equal '' (Get-ReasonsText $run) 'Should_ReturnNoReasons_When_BlockingDecreases'
    Assert-Equal '5,3,1' (Get-BlockingText $run) 'Should_ReturnBlockingByRound_When_BlockingDecreases'
    Assert-True ($run.Stdout.Contains('"reasons":[]')) 'Should_SerializeEmptyReasonsArray_When_NoEscalation'
    Assert-True ($null -eq $run.Result.total_tokens) 'Should_ReturnNullTotal_When_NoRoundReportsTokens'

    $stalled = New-SummaryFile -Name 'stalled' -Json (New-SummaryJson -Blocking @(3, 3, 3))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $stalled, '-StallRounds', '2')
    Assert-ExitCode 3 $run 'Should_ExitThree_When_BlockingStalls'
    Assert-True ($run.Result.escalate -eq $true) 'Should_Escalate_When_BlockingStalls'
    Assert-Equal 'no_convergence' (Get-ReasonsText $run) 'Should_ReturnNoConvergence_When_BlockingStalls'

    $tooFew = New-SummaryFile -Name 'too-few' -Json (New-SummaryJson -Blocking @(3, 3))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $tooFew, '-StallRounds', '2')
    Assert-ExitCode 0 $run 'Should_ExitZero_When_TooFewRoundsForStall'
    Assert-Equal '' (Get-ReasonsText $run) 'Should_ReturnNoReasons_When_TooFewRoundsForStall'

    $rising = New-SummaryFile -Name 'rising' -Json (New-SummaryJson -Blocking @(4, 5, 6))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $rising, '-StallRounds', '2')
    Assert-ExitCode 3 $run 'Should_ExitThree_When_BlockingRises'
    Assert-Equal 'no_convergence' (Get-ReasonsText $run) 'Should_ReturnNoConvergence_When_BlockingRises'

    $stallThenZero = New-SummaryFile -Name 'stall-then-zero' -Json (New-SummaryJson -Blocking @(3, 3, 3, 0))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $stallThenZero, '-StallRounds', '2')
    Assert-ExitCode 0 $run 'Should_ExitZero_When_LastBlockingIsZero'
    Assert-Equal '' (Get-ReasonsText $run) 'Should_ReturnNoReasons_When_LastBlockingIsZero'

    $stallOne = New-SummaryFile -Name 'stall-one' -Json (New-SummaryJson -Blocking @(2, 2))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $stallOne, '-StallRounds', '1')
    Assert-ExitCode 3 $run 'Should_ExitThree_When_StallRoundsIsOne'
    Assert-Equal 'no_convergence' (Get-ReasonsText $run) 'Should_ReturnNoConvergence_When_StallRoundsIsOne'

    $allZero = New-SummaryFile -Name 'all-zero' -Json (New-SummaryJson -Blocking @(0, 0, 0))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $allZero)
    Assert-ExitCode 0 $run 'Should_ExitZero_When_AllBlockingZero'
    Assert-Equal '' (Get-ReasonsText $run) 'Should_ReturnNoReasons_When_AllBlockingZero'

    $tokensWithin = New-SummaryFile -Name 'tokens-within' -Json (New-SummaryJson -Blocking @(5, 3) -Tokens @(100, 150))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $tokensWithin, '-MaxTokens', '250')
    Assert-ExitCode 0 $run 'Should_ExitZero_When_TokensWithinBudget'
    Assert-Equal '250' ([string]$run.Result.total_tokens) 'Should_SumTokens_When_TokensWithinBudget'

    $tokensOver = New-SummaryFile -Name 'tokens-over' -Json (New-SummaryJson -Blocking @(5, 3) -Tokens @(100, 150))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $tokensOver, '-MaxTokens', '200')
    Assert-ExitCode 3 $run 'Should_ExitThree_When_TokenBudgetExceeded'
    Assert-Equal 'token_budget_exceeded' (Get-ReasonsText $run) 'Should_ReturnTokenBudgetExceeded_When_TokensOverBudget'
    Assert-Equal '250' ([string]$run.Result.total_tokens) 'Should_ReportTotal_When_TokenBudgetExceeded'

    $tokensWithNulls = New-SummaryFile -Name 'tokens-nulls' -Json (New-SummaryJson -Blocking @(5, 4, 3) -Tokens @(100, $null, 50))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $tokensWithNulls, '-MaxTokens', '150')
    Assert-ExitCode 0 $run 'Should_ExitZero_When_NullTokensIgnoredAndSumWithinBudget'
    Assert-Equal '150' ([string]$run.Result.total_tokens) 'Should_IgnoreNullTokens_When_SummingTokens'
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $tokensWithNulls, '-MaxTokens', '120')
    Assert-ExitCode 3 $run 'Should_ExitThree_When_NullTokensIgnoredAndSumOverBudget'
    Assert-Equal 'token_budget_exceeded' (Get-ReasonsText $run) 'Should_ReturnTokenBudgetExceeded_When_NullTokensIgnoredAndSumOverBudget'

    $tokensAllNull = New-SummaryFile -Name 'tokens-all-null' -Json (New-SummaryJson -Blocking @(5, 3))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $tokensAllNull, '-MaxTokens', '1')
    Assert-ExitCode 0 $run 'Should_ExitZero_When_AllTokensUnknown'
    Assert-True ($null -eq $run.Result.total_tokens) 'Should_ReturnNullTotal_When_AllTokensUnknown'
    Assert-True ($run.Stdout.Contains('"total_tokens":null')) 'Should_SerializeNullTotal_When_AllTokensUnknown'

    $inputOver = New-SummaryFile -Name 'input-over' -Json (New-SummaryJson -Blocking @(5, 3, 2) -Bytes @(100, 201, 150))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $inputOver, '-MaxInputBytes', '200')
    Assert-ExitCode 3 $run 'Should_ExitThree_When_InputBudgetExceededByOneRound'
    Assert-Equal 'input_budget_exceeded' (Get-ReasonsText $run) 'Should_ReturnInputBudgetExceeded_When_OneRoundOver'

    $inputEqual = New-SummaryFile -Name 'input-equal' -Json (New-SummaryJson -Blocking @(5, 3, 2) -Bytes @(100, 200, 150))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $inputEqual, '-MaxInputBytes', '200')
    Assert-ExitCode 0 $run 'Should_ExitZero_When_InputEqualsBudget'

    $allReasons = New-SummaryFile -Name 'all-reasons' -Json (New-SummaryJson -Blocking @(3, 3, 3) -Tokens @(300, 300, 300) -Bytes @(500, 500, 500))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $allReasons, '-StallRounds', '2', '-MaxTokens', '100', '-MaxInputBytes', '100')
    Assert-ExitCode 3 $run 'Should_ExitThree_When_SeveralReasonsApply'
    Assert-Equal 'no_convergence,token_budget_exceeded,input_budget_exceeded' (Get-ReasonsText $run) 'Should_ListReasonsInDocumentedOrder_When_SeveralReasonsApply'

    $oneRound = New-SummaryFile -Name 'one-round' -Json (New-SummaryJson -Blocking @(0) -Tokens @(10))
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $oneRound)
    Assert-ExitCode 0 $run 'Should_ExitZero_When_SingleRoundArray'
    Assert-True ($run.Result.blocking_open_by_round -is [System.Array]) 'Should_ReadSingleRoundAsArray_When_OneElementRounds'
    Assert-True ($run.Stdout.Contains('"blocking_open_by_round":[0]')) 'Should_SerializeSingleRoundAsArray_When_OneElementRounds'
    Assert-Equal '10' ([string]$run.Result.total_tokens) 'Should_SumSingleRoundTokens_When_OneElementRounds'

    $emptyRounds = New-SummaryFile -Name 'empty-rounds' -Json '{"rounds":[]}'
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $emptyRounds)
    Assert-ExitCode 1 $run 'Should_ExitOne_When_RoundsArrayEmpty'
    Assert-True ($run.Stderr.Contains('rounds must contain at least one round')) 'Should_NameEmptyRounds_When_RoundsArrayEmpty'

    $invalidCases = @(
        @{ Id = 'non_consecutive'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 3), (New-RoundJson 3 2))) },
        @{ Id = 'starts_at_two'; Json = (New-SummaryText -Rounds @((New-RoundJson 2 3), (New-RoundJson 3 2))) },
        @{ Id = 'descending'; Json = (New-SummaryText -Rounds @((New-RoundJson 2 3), (New-RoundJson 1 2))) },
        @{ Id = 'negative_blocking'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 -1))) },
        @{ Id = 'negative_tokens'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 3 -5))) },
        @{ Id = 'negative_bytes'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 3 'null' -1))) },
        @{ Id = 'string_number'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 '"3"'))) },
        @{ Id = 'string_tokens'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 1 '"100"'))) },
        @{ Id = 'non_integer'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 2.5))) },
        @{ Id = 'boolean_blocking'; Json = (New-SummaryText -Rounds @((New-RoundJson 1 'true'))) },
        @{ Id = 'missing_blocking_key'; Json = '{"rounds":[{"round":1,"reported_tokens":null,"input_bytes":null}]}' },
        @{ Id = 'missing_tokens_key'; Json = '{"rounds":[{"round":1,"blocking_open":1,"input_bytes":null}]}' },
        @{ Id = 'missing_round_key'; Json = '{"rounds":[{"blocking_open":1,"reported_tokens":null,"input_bytes":null}]}' },
        @{ Id = 'null_round_element'; Json = '{"rounds":[null]}' },
        @{ Id = 'rounds_not_array'; Json = '{"rounds":{"round":1,"blocking_open":0,"reported_tokens":null,"input_bytes":null}}' },
        @{ Id = 'missing_rounds_key'; Json = '{"items":[]}' },
        @{ Id = 'invalid_json'; Json = '{"rounds":[' },
        @{ Id = 'empty_file'; Json = '   ' }
    )
    foreach ($case in $invalidCases) {
        $path = New-SummaryFile -Name ('invalid-' + $case.Id) -Json $case.Json
        $run = Invoke-Budget -CliArgs @('-SummaryPath', $path)
        Assert-ExitCode 1 $run ('Should_ExitOne_When_{0}' -f $case.Id)
        Assert-True ($run.Stderr.Trim().Length -gt 0) ('Should_WriteMessageToStderr_When_{0}' -f $case.Id)
    }

    $missingPath = Join-Path $tempRoot 'absent.json'
    $run = Invoke-Budget -CliArgs @('-SummaryPath', $missingPath)
    Assert-ExitCode 1 $run 'Should_ExitOne_When_SummaryFileMissing'

    $zeroStall = Invoke-Budget -CliArgs @('-SummaryPath', $converging, '-StallRounds', '0')
    Assert-ExitCode 1 $zeroStall 'Should_ExitOne_When_StallRoundsIsZero'

    $negativeStall = Invoke-Budget -CliArgs @('-SummaryPath', $converging, '-StallRounds', '-1')
    Assert-ExitCode 1 $negativeStall 'Should_ExitOne_When_StallRoundsIsNegative'

    $negativeMaxTokens = Invoke-Budget -CliArgs @('-SummaryPath', $converging, '-MaxTokens', '-1')
    Assert-ExitCode 1 $negativeMaxTokens 'Should_ExitOne_When_MaxTokensIsNegative'

    $negativeMaxInput = Invoke-Budget -CliArgs @('-SummaryPath', $converging, '-MaxInputBytes', '-1')
    Assert-ExitCode 1 $negativeMaxInput 'Should_ExitOne_When_MaxInputBytesIsNegative'

    $readOnlyFile = New-SummaryFile -Name 'read-only-check' -Json (New-SummaryJson -Blocking @(3, 3, 3) -Tokens @(10, 10, 10))
    $beforeSnapshot = Get-TreeSnapshot
    $null = Invoke-Budget -CliArgs @('-SummaryPath', $readOnlyFile, '-MaxTokens', '5')
    $null = Invoke-Budget -CliArgs @('-SummaryPath', $converging)
    $null = Invoke-Budget -CliArgs @('-SummaryPath', $missingPath)
    $afterSnapshot = Get-TreeSnapshot
    Assert-Equal $beforeSnapshot $afterSnapshot 'Should_WriteNoFiles_When_BudgetEvaluated'

    Write-Output ('PASS: {0} delivery review budget assertions.' -f $passed)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
