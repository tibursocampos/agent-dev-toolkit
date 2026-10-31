#Requires -Version 5.1
<#
.SYNOPSIS
  Runs the agent-dev-toolkit core validation suite (in-repo, no home deploy).

.DESCRIPTION
  Runs the critical in-repo checks: skill contracts and graph, core contracts, adapter contract,
  path and install-root safety, SDD runtime scripts, and publish ownership.
  Checks run in this process with per-check exit-code isolation (try/catch plus environment and
  location restore). A few checks that mutate process-wide state run in a child pwsh.
  Does not sync or validate under USERPROFILE. No -AllowUserHome required.

.PARAMETER FailFast
  Stop on first failing check.

.PARAMETER Quiet
  Print only failures and the final summary.

.PARAMETER Only
  Run only the named checks (names as printed, for example core-contracts).

.PARAMETER Skip
  Skip the named checks.

.EXAMPLE
  .\scripts\validation\validate-core.ps1

.EXAMPLE
  .\scripts\validation\validate-core.ps1 -Only core-contracts,skill-graph
#>
[CmdletBinding()]
param(
    [switch] $FailFast,
    [switch] $Quiet,
    [string[]] $Only = @(),
    [string[]] $Skip = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Invoke-ValidationTelemetry.ps1')

$validationResultsPath = Get-ValidationTelemetryPath
$validationJobName = if ([string]::IsNullOrWhiteSpace($env:VALIDATION_JOB_NAME)) {
    'validate-core'
} else {
    $env:VALIDATION_JOB_NAME
}

$suiteTitle = 'agent-dev-toolkit core validation'
$constant = $script:ToolkitConstant

# Isolated = fresh child pwsh (script mutates process environment or must not share session state).
$coreChecks = @(
    @{ Name = 'skill-contracts'; Script = 'validate-skill-contracts.ps1' },
    @{ Name = 'skill-graph'; Script = 'validate-skill-graph.ps1' },
    @{ Name = 'skill-catalog-parity'; Script = 'Assert-SkillCatalogParity.ps1' },
    @{ Name = 'toolkit-script-isolation'; Script = 'Assert-ToolkitScriptIsolation.ps1'; Isolated = $true },
    @{ Name = $constant.CoreContractsCheckName; Script = $constant.AssertCoreContractsScriptName },
    @{ Name = $constant.AdapterContractCheckName; Script = $constant.AssertAdapterContractScriptName; Isolated = $true },
    @{ Name = 'classic-external-access-runtime'; Script = 'Assert-ClassicExternalAccessRuntime.ps1'; Isolated = $true },
    @{ Name = 'o3-receipt-validation'; Script = 'Assert-O3ReceiptValidation.ps1' },
    @{ Name = $constant.InstallRootSafetyCheckName; Script = $constant.AssertInstallRootSafetyScriptName; Isolated = $true },
    @{ Name = $constant.ClaudeSettingsMergeCheckName; Script = $constant.AssertClaudeSettingsMergeScriptName },
    @{ Name = $constant.CursorHooksMergeCheckName; Script = $constant.AssertCursorHooksMergeScriptName },
    @{ Name = $constant.PowerShellDynamicPathGuardCheckName; Script = $constant.AssertPowerShellDynamicPathGuardScriptName; Isolated = $true },
    @{ Name = 'guard-shell-canonical-paths'; Script = 'Assert-GuardShellCanonicalPaths.ps1' },
    @{ Name = $constant.ManagedSkillsPathSafetyCheckName; Script = $constant.AssertManagedSkillsPathSafetyScriptName },
    @{ Name = $constant.UninstallPathSafetyCheckName; Script = $constant.AssertUninstallPathSafetyScriptName },
    @{ Name = $constant.SddRootPrepareIdempotentCheckName; Script = $constant.AssertSddRootPrepareIdempotentScriptName },
    @{ Name = $constant.ValidatePrdPlanCheckName; Script = $constant.AssertValidatePrdPlanScriptName },
    @{ Name = 'release-workflow-contracts'; Script = 'Assert-ReleaseWorkflow.ps1' },
    @{ Name = $constant.MemoryBankInventoryCheckName; Script = $constant.AssertMemoryBankInventoryScriptName },
    @{ Name = $constant.DevelopSessionGateCheckName; Script = $constant.AssertDevelopSessionGateScriptName },
    @{ Name = $constant.TraceEmitterFailOpenCheckName; Script = $constant.AssertTraceEmitterFailOpenScriptName },
    @{ Name = $constant.RuntimeCopyDriftCheckName; Script = $constant.AssertRuntimeCopyDriftScriptName },
    @{ Name = 'brownfield-analysis-validation'; Script = 'Assert-BrownfieldAnalysisValidator.ps1'; Isolated = $true },
    @{ Name = 'publish-ownership-contracts'; Script = 'Assert-PublishOwnershipContracts.ps1' },
    @{ Name = 'claude-skill-frontmatter'; Script = 'Assert-ClaudeSkillFrontmatter.ps1'; Isolated = $true },
    @{ Name = 'claude-agent-tools'; Script = 'Assert-ClaudeAgentTools.ps1'; Isolated = $true },
    @{ Name = 'claude-policy-rules'; Script = 'Assert-ClaudePolicyRules.ps1'; Isolated = $true },
    @{ Name = 'claude-hook-smoke'; Script = 'Assert-ClaudeHookSmoke.ps1'; Isolated = $true },
    @{ Name = 'claude-published-content'; Script = 'Assert-ClaudePublishedContent.ps1'; Isolated = $true },
    @{ Name = 'claude-hook-wiring'; Script = 'Assert-ClaudeHookWiring.ps1'; Isolated = $true },
    @{ Name = 'claude-skill-size'; Script = 'Assert-ClaudeSkillSize.ps1'; Isolated = $true },
    @{ Name = 'ledger-readback'; Script = 'Assert-LedgerReadback.ps1' },
    @{ Name = 'hook-activation'; Script = 'Assert-HookActivation.ps1'; Isolated = $true },
    @{ Name = $constant.AdapterPublishCheckName; Script = $constant.AssertAdapterPublishScriptName; Isolated = $true }
)

# Kept out on purpose:
#  - Assert-SyncAllowUserHomeForward publishes under a disposable USERPROFILE probe; CI runs it as its own step.
#  - Invoke-AdapterCiSmoke.ps1 calls validate-agent and would recurse.

$allCheckNames = @($coreChecks | ForEach-Object { $_.Name })
if ($Only.Count -gt 0) {
    $knownNames = @($coreChecks | ForEach-Object { $_.Name })
    $unknown = @($Only | Where-Object { $knownNames -notcontains $_ })
    if ($unknown.Count -gt 0) {
        Write-Host ("Unknown check name(s) in -Only: {0}" -f ($unknown -join ', ')) -ForegroundColor Red
        exit 2
    }
    $coreChecks = @($coreChecks | Where-Object { $Only -contains $_.Name })
}
if ($Skip.Count -gt 0) {
    $knownSkipNames = $allCheckNames
    $unknownSkip = @($Skip | Where-Object { $knownSkipNames -notcontains $_ })
    if ($unknownSkip.Count -gt 0) {
        Write-Host ("Unknown check name(s) in -Skip: {0}" -f ($unknownSkip -join ', ')) -ForegroundColor Red
        exit 2
    }
    $coreChecks = @($coreChecks | Where-Object { $Skip -notcontains $_.Name })
}

$pwshPath = (Get-Process -Id $PID).Path

function Invoke-ValidationCheck {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [switch] $Isolated
    )

    $startedAt = [DateTimeOffset]::UtcNow
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $exitCode = 1
    $captured = @()
    $savedLocation = (Get-Location).Path
    $savedDirectory = [Environment]::CurrentDirectory
    $savedEnv = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
    foreach ($entry in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
        $savedEnv[[string]$entry.Key] = [string]$entry.Value
    }

    try {
        if (-not (Test-Path -LiteralPath $ScriptPath)) {
            throw "Check script not found: $ScriptPath"
        }
        $global:LASTEXITCODE = $null
        if ($Isolated) {
            $captured = @(& $pwshPath -NoProfile -File $ScriptPath *>&1)
        }
        else {
            $captured = @(& $ScriptPath *>&1)
        }
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            # An in-process script that ends without calling exit reports nothing; that is success only
            # when it also wrote nothing to the error stream.
            if ($Isolated) { $exitCode = 1; $captured += 'Child process reported no exit code.' }
            else {
                $errorOutput = @($captured | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
                $exitCode = if ($errorOutput.Count -gt 0) { 1 } else { 0 }
            }
        }
        elseif ($exitCode -eq 0 -and -not $Isolated -and @($captured | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }).Count -gt 0) {
            $exitCode = 1
        }
    }
    catch {
        $exitCode = 1
        $captured += $_
    }
    finally {
        Set-Location -LiteralPath $savedLocation
        [Environment]::CurrentDirectory = $savedDirectory
        foreach ($key in @([Environment]::GetEnvironmentVariables('Process').Keys)) {
            if (-not $savedEnv.ContainsKey([string]$key)) {
                [Environment]::SetEnvironmentVariable([string]$key, $null, 'Process')
            }
        }
        foreach ($key in $savedEnv.Keys) {
            if ([Environment]::GetEnvironmentVariable($key, 'Process') -ne $savedEnv[$key]) {
                [Environment]::SetEnvironmentVariable($key, $savedEnv[$key], 'Process')
            }
        }
        $timer.Stop()
    }

    $status = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
    $color = if ($status -eq 'PASS') { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    if ($status -eq 'FAIL' -or -not $Quiet) {
        Write-Host ("{0,-4} {1,-38} {2,6:N1}s" -f $status, $Name, $timer.Elapsed.TotalSeconds) -ForegroundColor $color
    }
    if ($status -eq 'FAIL') {
        foreach ($item in $captured) {
            $text = ($item | Out-String).TrimEnd()
            if (-not [string]::IsNullOrWhiteSpace($text)) { Write-Host ('     ' + ($text -replace "`n", "`n     ")) }
        }
    }

    Write-ValidationTelemetryCheck `
        -Path $validationResultsPath `
        -JobName $validationJobName `
        -CheckName $Name `
        -Status $status `
        -ExitCode $exitCode `
        -DurationMs $timer.Elapsed.TotalMilliseconds `
        -StartedAtUtc $startedAt.ToString('o') `
        -FinishedAtUtc ([DateTimeOffset]::UtcNow).ToString('o') `
        -ScriptPath $ScriptPath

    return [PSCustomObject]@{ Name = $Name; Status = $status; ExitCode = $exitCode }
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host $suiteTitle -ForegroundColor Cyan
    Write-Host ('=' * $suiteTitle.Length) -ForegroundColor Cyan
}

$suiteTimer = [System.Diagnostics.Stopwatch]::StartNew()
$results = New-Object 'System.Collections.Generic.List[object]'
foreach ($check in $coreChecks) {
    $isolated = $check.ContainsKey('Isolated') -and [bool]$check.Isolated
    $result = Invoke-ValidationCheck -Name $check.Name -ScriptPath (Join-Path $scriptDir $check.Script) -Isolated:$isolated
    [void]$results.Add($result)
    if ($FailFast -and $result.Status -eq 'FAIL') { break }
}
$suiteTimer.Stop()

if ($results.Count -eq 0) {
    Write-Host 'Core validation FAILED: no checks ran.' -ForegroundColor Red
    exit 1
}

$failed = @($results | Where-Object { $_.Status -eq 'FAIL' })
Write-Host ''
if ($failed.Count -gt 0) {
    Write-Host ("Core validation FAILED: {0} of {1} check(s) in {2:N1}s ({3})." -f $failed.Count, $results.Count, $suiteTimer.Elapsed.TotalSeconds, (($failed | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Red
    exit 1
}

Write-Host ("Core validation PASSED: {0} check(s) in {1:N1}s." -f $results.Count, $suiteTimer.Elapsed.TotalSeconds) -ForegroundColor Green
exit 0
