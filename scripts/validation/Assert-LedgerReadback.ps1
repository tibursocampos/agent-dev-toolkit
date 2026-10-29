#Requires -Version 5.1
# Tests:
#   Should_ReadBack_When_PlanStepWriteRoundTrips        (status token only, bytes restored)
#   Should_Reject_When_StepConflictsOrRowMissing        (exit 4 / 3, file unchanged)
#   Should_Reject_When_InvalidUtf8OrOutsideFeatures     (exit 3 / 2, file unchanged)
#   Should_Preserve_Crlf_When_StepHeadingWritten
#   Should_Claim_And_ReadBack_When_ClaimWritten
#   Should_Audit_When_ClaimReadbackMismatch             (exit 3)
#   Should_Report_ClaimUnreadable_When_ClaimFileUnparseable
# Writer and claim scripts run in-process; only the readback-mismatch case needs a stubbed copy.
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptsRoot
. (Join-Path $scriptsRoot '_lib/New-ToolkitWorkRoot.ps1')
$writer = Join-Path $scriptsRoot 'ledger/Invoke-PlanStepStateWrite.ps1'
$claim = Join-Path $scriptsRoot 'ledger/Invoke-PlanLedgerClaim.ps1'
$enc = New-Object System.Text.UTF8Encoding $false
$failures = 0

function Write-Pass { param([string] $Name) Write-Host ("{0}: PASS" -f $Name) }
function Write-Fail { param([string] $Name, [string] $Reason) Write-Host ("{0}: FAIL - {1}" -f $Name, $Reason); $script:failures++ }
function Test-Case { param([string] $Name, [bool] $Ok, [string] $Detail = '') if ($Ok) { Write-Pass $Name } else { Write-Fail $Name $Detail } }
function Get-B64([string] $Path) { [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path)) }
function Invoke-Writer {
    $out = & $writer @args 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = (($out | ForEach-Object { "$_" }) -join "`n") }
}

$emDash = [string][char]0x2014
$ok = [string][char]0x2705
$plan = (@'
# PLAN fixture

| Step ID | Step | Dependencies | Status | Evidence |
|---------|------|--------------|--------|----------|
| S1 | Map gates | none | `COMPLETED` | x |
| S2 | Reconcile | S1 | `COMPLETED` | x |
| S3 | Boundary | S2 | `PENDING` | - |

### STEP 2 @@EM@@ S2: Reconcile

@@OK@@ `COMPLETED` (2026-10-28)
'@).Replace('@@EM@@', $emDash).Replace('@@OK@@', $ok)

$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $dir = Join-Path $work 'features/fx/TS01/PLAN'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $p = Join-Path $dir 'PLAN_fixture.md'

    # --- round trip: S3 PENDING -> COMPLETED -> PENDING restores original bytes ---
    [System.IO.File]::WriteAllBytes($p, $enc.GetBytes($plan))
    $orig = Get-B64 $p
    $a = Invoke-Writer -RepoPath $work -Kind PLAN -Field Ledger -FilePath $p -StepId S3 -Status COMPLETED -ExpectedCurrent PENDING
    $mid = $enc.GetString([System.IO.File]::ReadAllBytes($p))
    $b = Invoke-Writer -RepoPath $work -Kind PLAN -Field Ledger -FilePath $p -StepId S3 -Status PENDING -ExpectedCurrent COMPLETED
    $n = 'Should_ReadBack_When_PlanStepWriteRoundTrips'
    Test-Case $n ($a.Code -eq 0 -and $b.Code -eq 0 -and $a.Out -match '"readback":\s*"match"' -and $mid.Contains('| `COMPLETED` | - |') -and (Get-B64 $p) -ceq $orig) "exit $($a.Code)/$($b.Code) $($a.Out)"

    # --- conflict (4) and missing row (3) leave file unchanged ---
    $before = Get-B64 $p
    $c = Invoke-Writer -RepoPath $work -Kind PLAN -Field Ledger -FilePath $p -StepId S2 -Status PENDING -ExpectedCurrent PENDING
    $m = Invoke-Writer -RepoPath $work -Kind PLAN -Field Ledger -FilePath $p -StepId S9 -Status COMPLETED
    Test-Case 'Should_Reject_When_StepConflictsOrRowMissing' ($c.Code -eq 4 -and $m.Code -eq 3 -and (Get-B64 $p) -ceq $before) "conflict=$($c.Code) missing=$($m.Code)"

    # --- invalid UTF-8 (3) and path outside features (2) ---
    $bad = Join-Path $dir 'PLAN_bad.md'
    [System.IO.File]::WriteAllBytes($bad, [byte[]]($enc.GetBytes($plan) + @([byte]0xFF, [byte]0xFE)))
    $badBefore = Get-B64 $bad
    $u = Invoke-Writer -RepoPath $work -Kind PLAN -Field Ledger -FilePath $bad -StepId S3 -Status COMPLETED
    $outside = Join-Path $work 'PLAN_outside.md'
    [System.IO.File]::WriteAllBytes($outside, $enc.GetBytes($plan))
    $outBefore = Get-B64 $outside
    $o = Invoke-Writer -RepoPath $work -Kind PLAN -Field Ledger -FilePath $outside -StepId S3 -Status COMPLETED -ExpectedCurrent PENDING
    Test-Case 'Should_Reject_When_InvalidUtf8OrOutsideFeatures' ($u.Code -eq 3 -and (Get-B64 $bad) -ceq $badBefore -and $o.Code -eq 2 -and $o.Out -match 'path_outside_features' -and (Get-B64 $outside) -ceq $outBefore) "utf8=$($u.Code) outside=$($o.Code)"

    # --- CRLF preserved ---
    $crlf = Join-Path $dir 'PLAN_crlf.md'
    [System.IO.File]::WriteAllBytes($crlf, $enc.GetBytes($plan.Replace("`n", "`r`n")))
    $r = Invoke-Writer -RepoPath $work -Kind PLAN -Field StepHeading -FilePath $crlf -StepId S2 -Status PENDING -ExpectedCurrent COMPLETED
    $after = $enc.GetString([System.IO.File]::ReadAllBytes($crlf))
    Test-Case 'Should_Preserve_Crlf_When_StepHeadingWritten' ($r.Code -eq 0 -and -not ($after -replace "`r`n", '').Contains("`n")) "exit $($r.Code)"

    # --- claim: live write reads back ---
    $repo = Join-Path $work 'repo'
    $pd = Join-Path $repo 'features/fx/TS01/PLAN'
    New-Item -ItemType Directory -Path $pd -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $pd 'PLAN_001_fx.md') -Value '# PLAN fixture' -Encoding UTF8
    $planRel = 'features/fx/TS01/PLAN/PLAN_001_fx.md'
    $sessions = Join-Path $work 'sessions'
    $sdd = Join-Path $work 'sdd'
    $out = (& $claim -Action claim -PlanPath $planRel -Step 1 -Holder 'fixture-holder' -RepoPath $repo -SessionsRoot $sessions -SddRoot $sdd 2>&1 | ForEach-Object { "$_" }) -join "`n"
    Test-Case 'Should_Claim_And_ReadBack_When_ClaimWritten' ($LASTEXITCODE -eq 0 -and $out -match '"claimed":\s*true') "exit $LASTEXITCODE $out"

    # --- unparseable claim file: status and release report claim_unreadable ---
    $cf = Get-ChildItem -LiteralPath $sessions -Recurse -Filter '*.claim.json' -File | Select-Object -First 1
    [System.IO.File]::WriteAllText($cf.FullName, '{"holder":', $enc)
    $st = (& $claim -Action status -PlanPath $planRel -Step 1 -RepoPath $repo -SessionsRoot $sessions -SddRoot $sdd 2>&1 | ForEach-Object { "$_" }) -join "`n"
    $stCode = $LASTEXITCODE
    $rl = (& $claim -Action release -Holder 'fixture-holder' -PlanPath $planRel -Step 1 -RepoPath $repo -SessionsRoot $sessions -SddRoot $sdd 2>&1 | ForEach-Object { "$_" }) -join "`n"
    $rlCode = $LASTEXITCODE
    Test-Case 'Should_Report_ClaimUnreadable_When_ClaimFileUnparseable' ($stCode -eq 2 -and $rlCode -eq 2 -and $st -match 'claim_unreadable' -and $rl -match 'claim_unreadable') "status $stCode release $rlCode"

    # --- readback mismatch: stubbed helper that always fails -> exit 3 + audit line, nothing claimed ---
    $stub = Join-Path $work 'stub-scripts'
    New-Item -ItemType Directory -Path (Join-Path $stub 'ledger') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $scriptsRoot '_lib') -Destination (Join-Path $stub '_lib') -Recurse -Force
    Copy-Item -LiteralPath $claim -Destination (Join-Path $stub 'ledger/Invoke-PlanLedgerClaim.ps1') -Force
    Set-Content -LiteralPath (Join-Path $stub '_lib/Test-ToolkitFileReadback.ps1') -Value 'function Test-ToolkitFileReadback { param([string] $Path, [string] $ExpectedText) return $false }' -Encoding UTF8
    $sess2 = Join-Path $work 'sessions2'
    $mo = (& (Join-Path $stub 'ledger/Invoke-PlanLedgerClaim.ps1') -Action claim -PlanPath $planRel -Step 1 -Holder 'fixture-holder' -RepoPath $repo -SessionsRoot $sess2 -SddRoot (Join-Path $work 'sdd2') 2>&1 | ForEach-Object { "$_" }) -join "`n"
    $mCode = $LASTEXITCODE
    $audit = Get-ChildItem -LiteralPath $sess2 -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'audit' -and (Select-String -LiteralPath $_.FullName -Pattern 'claim_readback_mismatch' -Quiet) } | Select-Object -First 1
    Test-Case 'Should_Audit_When_ClaimReadbackMismatch' ($mCode -eq 3 -and $mo -match 'claim_readback_mismatch' -and $mo -match '"claimed":\s*false' -and $null -ne $audit) "exit $mCode $mo"
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

if ($failures -gt 0) { Write-Host ("Assert-LedgerReadback: {0} FAIL(s)" -f $failures); exit 1 }
Write-Host 'Assert-LedgerReadback: ALL PASS'
exit 0
