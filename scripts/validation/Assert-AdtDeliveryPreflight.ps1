#Requires -Version 5.1
# Tests:
#   Should_Pass_When_StartNativeInherit
#   Should_Fail_When_StartNativeModelNotChosen
#   Should_Fail_When_StartPreferencesMissing
#   Should_Pass_When_RefineFixtureValid
#   Should_Fail_When_RefineLedgerMissing
#   Should_Fail_When_RefinePathOutsideFeatures
#   Should_Fail_When_RefinePathTraversal
#   Should_Fail_When_PlanLedgerRefinePending
#   Should_Pass_When_PlanTableValid
#   Should_Fail_When_PlanNativeInParentFallback
#   Should_Fail_When_PlanSecurityNotApplicable
#   Should_Fail_When_PlanModeAnalysis
#   Should_Fail_When_ImplementPlanPending
#   Should_Pass_When_ImplementPlanApproved
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$preflight = Join-Path $repoRoot 'scripts/runtime/Test-AdtDeliveryPreflight.ps1'
$backtick = [string][char]96
$failureCount = 0

$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-preflight-' + [guid]::NewGuid().ToString('N'))
$sddRoot = Join-Path $workRoot 'sdd'
$sddEmpty = Join-Path $workRoot 'sdd-empty'
$planFile = Join-Path $workRoot 'features/001-x/PLAN.md'
$outsidePlan = Join-Path $workRoot 'outside/PLAN.md'
$traversalPlan = Join-Path $workRoot 'features/001-x/../../outside/PLAN.md'

function Write-Text {
    param([string] $Path, [string] $Text)
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

function New-TriageLines {
    param([string] $Nature, [hashtable] $Override = @{})
    $rows = [ordered]@{}
    foreach ($flag in @('needs_api', 'needs_domain', 'needs_database', 'needs_frontend', 'needs_security', 'needs_devops')) {
        $rows[$flag] = 'false | not applicable'
    }
    if ($Nature -ne 'operational') { $rows["nature: $Nature"] = 'true | specialist spawned: repo-analyst' }
    foreach ($key in $Override.Keys) { $rows[$key] = [string]$Override[$key] }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Nature: $backtick$Nature$backtick")
    $lines.Add('')
    $lines.Add('| Flag | Value | Basis | Result |')
    $lines.Add('|------|-------|-------|--------|')
    foreach ($key in $rows.Keys) {
        $pair = @([string]$rows[$key] -split ' \| ')
        $lines.Add("| $backtick$key$backtick | $($pair[0]) | fixture basis | $($pair[1]) |")
    }
    $lines.Add('')
    return , $lines.ToArray()
}

function New-PlanText {
    param(
        [string] $Mode = 'full',
        [string] $Subagents = 'native',
        [string] $ModelChoice = 'inherit',
        [string] $Ledger = 'refine=done, plan=approved, implement=pending',
        [string] $Approval = 'approved 2026-11-14 - scope: fixture scope',
        [string] $Nature = 'brownfield',
        [hashtable] $Triage = @{},
        [switch] $OmitLedger
    )
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in @('# PLAN: preflight fixture', '', '## Normative content', '', '- Goal and user request: fixture', '- Evidence: fixture', '- Decisions and questions: fixture', '')) {
        $lines.Add($line)
    }
    foreach ($line in (New-TriageLines -Nature $Nature -Override $Triage)) { $lines.Add($line) }
    foreach ($line in @('## Operational record', '', "- Mode: $Mode", "- Subagents: $Subagents", "- Model choice: $ModelChoice")) {
        $lines.Add($line)
    }
    if (-not $OmitLedger) { $lines.Add("- Stage ledger: $Ledger") }
    foreach ($line in @("- Approval: $Approval", '- Choices: fixture', '- Progress: fixture', '- Closeout: fixture')) {
        $lines.Add($line)
    }
    return (($lines -join "`n") + "`n")
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

    $refineArgs = @('-Subagents', 'native', '-ModelChoice', 'inherit')
    Write-Text $planFile (New-PlanText -Ledger 'refine=pending, plan=pending, implement=pending')
    Test-Case -Name 'Should_Pass_When_RefineFixtureValid' -CliArgs (@('-Stage', 'refine', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $true

    Write-Text $planFile (New-PlanText -OmitLedger)
    Test-Case -Name 'Should_Fail_When_RefineLedgerMissing' -CliArgs (@('-Stage', 'refine', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $false -FailureText 'Stage ledger'

    Write-Text $outsidePlan (New-PlanText -Ledger 'refine=pending, plan=pending, implement=pending')
    Test-Case -Name 'Should_Fail_When_RefinePathOutsideFeatures' -CliArgs (@('-Stage', 'refine', '-PlanPath', $outsidePlan) + $refineArgs) -ExpectOk $false -FailureText 'features directory'

    Test-Case -Name 'Should_Fail_When_RefinePathTraversal' -CliArgs (@('-Stage', 'refine', '-PlanPath', $traversalPlan) + $refineArgs) -ExpectOk $false -FailureText '..'

    Write-Text $planFile (New-PlanText -Ledger 'refine=pending, plan=pending, implement=pending')
    Test-Case -Name 'Should_Fail_When_PlanLedgerRefinePending' -CliArgs (@('-Stage', 'plan', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $false -FailureText 'refine must be done'

    Write-Text $planFile (New-PlanText)
    Test-Case -Name 'Should_Pass_When_PlanTableValid' -CliArgs (@('-Stage', 'plan', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $true

    Write-Text $planFile (New-PlanText -Triage @{ 'nature: brownfield' = 'true | in-parent fallback: repo-analyst' })
    Test-Case -Name 'Should_Fail_When_PlanNativeInParentFallback' -CliArgs (@('-Stage', 'plan', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $false -FailureText 'in-parent fallback'

    Write-Text $planFile (New-PlanText -Triage @{ needs_security = 'true | not applicable' })
    Test-Case -Name 'Should_Fail_When_PlanSecurityNotApplicable' -CliArgs (@('-Stage', 'plan', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $false -FailureText 'needs_security'

    Write-Text $planFile (New-PlanText -Mode 'analysis')
    Test-Case -Name 'Should_Fail_When_PlanModeAnalysis' -CliArgs (@('-Stage', 'plan', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $false -FailureText 'Mode analysis stops after refine'

    Write-Text $planFile (New-PlanText -Ledger 'refine=done, plan=pending, implement=pending' -Approval 'pending')
    Test-Case -Name 'Should_Fail_When_ImplementPlanPending' -CliArgs (@('-Stage', 'implement', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $false -FailureText 'plan must be approved'

    Write-Text $planFile (New-PlanText)
    Test-Case -Name 'Should_Pass_When_ImplementPlanApproved' -CliArgs (@('-Stage', 'implement', '-PlanPath', $planFile) + $refineArgs) -ExpectOk $true
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
