#Requires -Version 5.1
# Tests:
#   Should_Pass_When_StartNativeInherit
#   Should_Fail_When_StartNativeModelNotChosen
#   Should_Fail_When_StartPreferencesMissing
#   Should_Fail_When_StartSubagentsMissing
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$preflight = Join-Path $repoRoot 'scripts/runtime/Test-AdtDeliveryPreflight.ps1'
$failureCount = 0

$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-preflight-' + [guid]::NewGuid().ToString('N'))
$sddRoot = Join-Path $workRoot 'sdd'
$sddEmpty = Join-Path $workRoot 'sdd-empty'

function Write-Text {
    param([string] $Path, [string] $Text)
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

function Invoke-Preflight {
    param([string[]] $CliArgs)
    $global:LASTEXITCODE = 0
    $raw = & pwsh -NoProfile -File $preflight @CliArgs 2>$null
    $code = $LASTEXITCODE
    $lines = @($raw | ForEach-Object { [string]$_ } | Where-Object { $_.Trim().Length -gt 0 })
    $json = $null
    if ($lines.Count -eq 1) {
        try { $json = $lines[0] | ConvertFrom-Json } catch { $json = $null }
    }
    return [pscustomobject]@{ Code = $code; Lines = $lines.Count; Json = $json; Raw = ($lines -join ' / ') }
}

function Test-Case {
    param([string] $Name, [string[]] $CliArgs, [bool] $ExpectOk, [string] $FailureText = '')
    $run = Invoke-Preflight -CliArgs $CliArgs
    $problems = New-Object System.Collections.Generic.List[string]
    if ($run.Lines -ne 1 -or $null -eq $run.Json) {
        $problems.Add("expected exactly one JSON line, got $($run.Lines): $($run.Raw)")
    }
    else {
        $expectedCode = 1
        if ($ExpectOk) { $expectedCode = 0 }
        if ([bool]$run.Json.ok -ne $ExpectOk) { $problems.Add("ok=$($run.Json.ok), expected $ExpectOk") }
        if ($run.Code -ne $expectedCode) { $problems.Add("exit $($run.Code), expected $expectedCode") }
        $reported = @($run.Json.failures | Where-Object { $_ })
        if ($FailureText -and @($reported | Where-Object { ([string]$_).Contains($FailureText) }).Count -eq 0) {
            $problems.Add("no failure contains '$FailureText': $($reported -join ' | ')")
        }
    }
    if ($problems.Count -eq 0) {
        Write-Host ("{0}: PASS" -f $Name)
    }
    else {
        $script:failureCount++
        Write-Host ("{0}: FAIL - {1}" -f $Name, ($problems -join '; '))
    }
}

try {
    New-Item -ItemType Directory -Path $sddEmpty -Force | Out-Null
    Write-Text (Join-Path $sddRoot 'preferences.json') '{ "caveman_mode": true, "orchestrator_mode": "adaptive" }'

    $startNative = @('-Stage', 'start', '-Subagents', 'native', '-SddRoot', $sddRoot)
    Test-Case -Name 'Should_Pass_When_StartNativeInherit' -CliArgs ($startNative + @('-ModelChoice', 'inherit')) -ExpectOk $true
    Test-Case -Name 'Should_Fail_When_StartNativeModelNotChosen' -CliArgs ($startNative + @('-ModelChoice', 'n/a')) -ExpectOk $false -FailureText 'other than n/a'
    Test-Case -Name 'Should_Fail_When_StartPreferencesMissing' -CliArgs @('-Stage', 'start', '-Subagents', 'native', '-ModelChoice', 'inherit', '-SddRoot', $sddEmpty) -ExpectOk $false -FailureText 'preferences.json missing'
    Test-Case -Name 'Should_Fail_When_StartSubagentsMissing' -CliArgs @('-Stage', 'start', '-ModelChoice', 'inherit', '-SddRoot', $sddRoot) -ExpectOk $false -FailureText 'Subagents is required'
}
finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failureCount -gt 0) {
    Write-Host ('Assert-AdtDeliveryPreflight: FAILED with {0} problem(s)' -f $failureCount)
    exit 1
}
Write-Host 'Assert-AdtDeliveryPreflight: ALL PASS'
exit 0
