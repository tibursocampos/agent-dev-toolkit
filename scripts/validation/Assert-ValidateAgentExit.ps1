#Requires -Version 5.1
# Tests:
#   Should_ExitZeroWithoutLastExitCodeError_When_ValidateAgentRunsAgainstTempRoot (claude, codex)
#
# Probe location: each agent gets a fresh GUID root under [IO.Path]::GetTempPath(),
# synced in a child pwsh and removed in finally. -AllowUserHome is passed only for
# these temp roots because the temp directory sits under USERPROFILE.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$syncAgentScript = Join-Path $scriptsRoot 'sync-agent.ps1'
$validateAgentScript = Join-Path $scriptsRoot 'validate-agent.ps1'
$pwshPath = (Get-Process -Id $PID).Path
$testName = 'Should_ExitZeroWithoutLastExitCodeError_When_ValidateAgentRunsAgainstTempRoot'
$agentIds = @('claude', 'codex')

foreach ($required in @($syncAgentScript, $validateAgentScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Error ("{0}: FAIL - missing {1}" -f $testName, $required)
        exit 1
    }
}

$failures = New-Object System.Collections.Generic.List[string]
foreach ($agentId in $agentIds) {
    $probeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-validate-agent-exit-{0}-{1}' -f $agentId, [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $probeRoot -Force | Out-Null

        $syncOutput = @(& $pwshPath -NoProfile -File $syncAgentScript -Agent $agentId -InstallRoot $probeRoot -AllowUserHome *>&1 | ForEach-Object { "$_" })
        $syncExit = $LASTEXITCODE
        if ($syncExit -ne 0) {
            $failures.Add(("{0}: sync-agent {1} into temp root exited {2}: {3}" -f $testName, $agentId, $syncExit, ($syncOutput -join ' ').Trim()))
            continue
        }

        $validateOutput = @(& $pwshPath -NoProfile -File $validateAgentScript -Agent $agentId -InstallRoot $probeRoot -AllowUserHome *>&1 | ForEach-Object { "$_" })
        $validateExit = $LASTEXITCODE
        $validateText = $validateOutput -join "`n"
        if ($validateExit -ne 0) {
            $failures.Add(("{0}: validate-agent {1} exited {2}: {3}" -f $testName, $agentId, $validateExit, $validateText.Trim()))
            continue
        }
        if ($validateText -match 'LASTEXITCODE') {
            $failures.Add(("{0}: validate-agent {1} reported an unset LASTEXITCODE: {2}" -f $testName, $agentId, $validateText.Trim()))
            continue
        }
        if ($validateText -notmatch 'Validate agent completed\.') {
            $failures.Add(("{0}: validate-agent {1} did not reach completion: {2}" -f $testName, $agentId, $validateText.Trim()))
            continue
        }

        Write-Host ("{0} ({1}): PASS" -f $testName, $agentId)
    }
    finally {
        if (Test-Path -LiteralPath $probeRoot) {
            Remove-Item -LiteralPath $probeRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error ("{0} - FAIL" -f $failure)
    }
    exit 1
}

Write-Host 'Assert-ValidateAgentExit: ALL PASS'
exit 0
