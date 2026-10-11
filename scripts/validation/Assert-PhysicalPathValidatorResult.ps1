#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-StructuredValidator {
    param([Parameter(Mandatory = $true)][string] $Path)

    $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Path 2>&1)
    $exitCode = [int]$LASTEXITCODE
    $line = @($output | ForEach-Object { [string]$_ } | Where-Object { $_ -match '^VALIDATOR_RESULT\s+\{.*\}$' } | Select-Object -Last 1)
    Assert-True ($line.Count -eq 1) "Validator did not emit exactly one structured result: $Path"
    $json = ($line[0] -replace '^VALIDATOR_RESULT\s+', '') | ConvertFrom-Json
    Assert-True ([string]$json.Status -in @('PASS', 'SKIPPED', 'FAIL')) "Validator emitted an invalid status: $Path"
    Assert-True ([int]$json.ExitCode -eq $exitCode) "Structured exit code disagrees with process exit code: $Path"
    if ($json.Status -eq 'FAIL') {
        Assert-True ($exitCode -ne 0) "FAIL result must have a nonzero process exit code: $Path"
    }
    else {
        Assert-True ($exitCode -eq 0) "PASS/SKIPPED result must have a zero process exit code: $Path"
    }
    return [pscustomobject]@{ Path = $Path; Status = [string]$json.Status; ExitCode = $exitCode; PhysicalStatus = [string]$json.PhysicalStatus }
}

$failureFixture = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-dev-toolkit-physical-validator-fail-{0}.ps1" -f ([guid]::NewGuid().ToString('N')))
try {
    @'
Write-Output 'VALIDATOR_RESULT {"Status":"FAIL","ExitCode":1,"PhysicalStatus":"FAIL"}'
exit 1
'@ | Set-Content -LiteralPath $failureFixture -Encoding UTF8

    $failureResult = Invoke-StructuredValidator -Path $failureFixture
    Assert-True ($failureResult.Status -eq 'FAIL') 'Deterministic failure fixture must emit a structured FAIL result.'
    Assert-True ($failureResult.ExitCode -ne 0) 'Deterministic structured FAIL result must preserve a nonzero process exit code.'
    Write-Host ("{0}: FAIL (structured result verified; exit={1})" -f (Split-Path -Leaf $failureFixture), $failureResult.ExitCode)
}
finally {
    Remove-Item -LiteralPath $failureFixture -Force -ErrorAction SilentlyContinue
}

$results = @(
    Invoke-StructuredValidator -Path (Join-Path $scriptDir 'Assert-CodexPathSecretsGuard.ps1')
    Invoke-StructuredValidator -Path (Join-Path $scriptDir 'Assert-OpenCodePathSecretsGuard.ps1')
)

foreach ($result in $results) {
    Assert-True ($result.PhysicalStatus -in @('PASS', 'SKIPPED')) "Physical status was not normalized: $($result.Path)"
    Write-Host ("{0}: {1} (physical={2}, exit={3})" -f (Split-Path -Leaf $result.Path), $result.Status, $result.PhysicalStatus, $result.ExitCode)
}

$negativeFixture = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-dev-toolkit-physical-validator-fail-{0}.ps1" -f ([guid]::NewGuid().ToString('N')))
try {
    @'
Write-Host 'VALIDATOR_RESULT {"Status":"FAIL","ExitCode":1,"PhysicalStatus":"FAIL"}'
exit 1
'@ | Set-Content -LiteralPath $negativeFixture -Encoding UTF8

    $negativeOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $negativeFixture 2>&1)
    $negativeExitCode = [int]$LASTEXITCODE
    $negativeLine = @($negativeOutput | ForEach-Object { [string]$_ } | Where-Object { $_ -match '^VALIDATOR_RESULT\s+\{.*\}$' } | Select-Object -Last 1)
    Assert-True ($negativeLine.Count -eq 1) 'Negative validator fixture did not emit exactly one structured result.'
    $negativeJson = ($negativeLine[0] -replace '^VALIDATOR_RESULT\s+', '') | ConvertFrom-Json
    Assert-True ([string]$negativeJson.Status -eq 'FAIL') 'Negative validator fixture did not emit FAIL.'
    Assert-True ([int]$negativeJson.ExitCode -eq 1) 'Negative validator fixture did not report exit code 1.'
    Assert-True ($negativeExitCode -ne 0) 'Negative validator fixture returned zero for FAIL.'
    Write-Host 'Should_Fail_WithStructuredFailAndNonzeroExit: PASS'
}
finally {
    Remove-Item -LiteralPath $negativeFixture -Force -ErrorAction SilentlyContinue
}

Write-Host 'Assert-PhysicalPathValidatorResult: ALL PASS'
exit 0
