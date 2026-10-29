#Requires -Version 5.1
# Tests:
#   Should_Set_And_BeIdempotent_When_StepConfirmedEnsured
#   Should_Read_When_ValidatorSeesGate
#   Should_Block_When_GateMissing_OrTestsRunBeforeStepConfirmed
#   Should_Reset_And_BeIdempotent
#   Should_Exit3_When_SessionWriteOrReadbackFails
#   Should_Reject_When_PersistedIdentityMismatches
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'New-ToolkitWorkRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

function Write-Pass { param([string] $Name) Write-Host ("{0}: PASS" -f $Name) }
function Write-Fail { param([string] $Name, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $Name, $Reason); exit 1 }
function Get-Sha([string] $Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Invoke-Tool {
    $tool = $args[0]
    $rest = @($args | Select-Object -Skip 1)
    $global:LASTEXITCODE = 0
    try { $out = & $tool @rest 2>&1 | Out-String; $code = $LASTEXITCODE }
    catch { $out = [string]$_.Exception.Message; $code = 1 }
    if ($null -eq $code) { $code = 0 }
    return [pscustomobject]@{ Code = $code; Out = $out }
}

$helper = Join-Path $repoRoot ($script:ToolkitConstant.InvokeDevelopSessionGateScriptRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validate = Join-Path $repoRoot ($script:ToolkitConstant.ValidateSessionGatesScriptRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
foreach ($p in @($helper, $validate)) { if (-not (Test-Path -LiteralPath $p)) { Write-Fail 'DevelopSessionGate' "missing $p" } }

$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $plan = Join-Path $work 'features/999-fixture/US01/PLAN/PLAN_999_fixture.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $plan) -Force | Out-Null
    [System.IO.File]::WriteAllText($plan, "# PLAN: Session gate fixture`n", (New-Object System.Text.UTF8Encoding $false))
    $sessions = Join-Path $work 'sessions'
    New-Item -ItemType Directory -Path $sessions -Force | Out-Null

    # --- set + idempotent second run ---
    $n = 'Should_Set_And_BeIdempotent_When_StepConfirmedEnsured'
    $r = Invoke-Tool $helper -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $sessions -CurrentStep 4
    if ($r.Code -ne 0 -or $r.Out -notmatch 'step_confirmed') { Write-Fail $n "first ensure exit $($r.Code): $($r.Out)" }
    $sf = Get-ChildItem -LiteralPath $sessions -Recurse -Filter 'plan-*.json' -File | Select-Object -First 1
    if ($null -eq $sf -or -not [bool]((Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).gates.step_confirmed)) { Write-Fail $n 'gate not persisted' }
    $h1 = Get-Sha $sf.FullName
    $r = Invoke-Tool $helper -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $sessions -CurrentStep 4
    if ($r.Code -ne 0 -or $h1 -ne (Get-Sha $sf.FullName)) { Write-Fail $n 'second ensure rewrote session or failed' }
    Write-Pass $n

    # --- read: validator sees the gate; tests-run recorded after step_confirmed ---
    $n = 'Should_Read_When_ValidatorSeesGate'
    $r = Invoke-Tool $validate -RepoPath $repoRoot -PlanPath $plan -SessionsRoot $sessions -RequiredGate step_confirmed
    if ($r.Code -ne 0) { Write-Fail $n "validator exit $($r.Code): $($r.Out)" }
    $r = Invoke-Tool $helper -Action tests-run -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $sessions
    if ($r.Code -ne 0 -or $r.Out -notmatch '"tests_run":\s*true') { Write-Fail $n "tests-run exit $($r.Code): $($r.Out)" }
    $r = Invoke-Tool $validate -RepoPath $repoRoot -PlanPath $plan -SessionsRoot $sessions -RequiredGate tests_run
    if ($r.Code -ne 0) { Write-Fail $n "tests_run validator exit $($r.Code)" }
    Write-Pass $n

    # --- block: no session -> blocked exit; tests-run without step_confirmed refused ---
    $n = 'Should_Block_When_GateMissing_OrTestsRunBeforeStepConfirmed'
    $empty = Join-Path $work 'sessions-empty'
    New-Item -ItemType Directory -Path $empty -Force | Out-Null
    $r = Invoke-Tool $validate -RepoPath $repoRoot -PlanPath $plan -SessionsRoot $empty -RequiredGate step_confirmed
    if ($r.Code -ne [int]$script:ToolkitConstant.SessionGateValidateExitBlocked) { Write-Fail $n "expected blocked exit, got $($r.Code)" }
    $pre = Join-Path $work 'sessions-pre'
    $null = Invoke-Tool $helper -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $pre
    $ps = Get-ChildItem -LiteralPath $pre -Recurse -Filter 'plan-*.json' -File | Select-Object -First 1
    $o = Get-Content -LiteralPath $ps.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $o.gates.step_confirmed = $false
    $o | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ps.FullName -Encoding UTF8
    $r = Invoke-Tool $helper -Action tests-run -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $pre
    if ($r.Code -eq 0) { Write-Fail $n 'tests-run allowed without step_confirmed' }
    Write-Pass $n

    # --- reset: clears both gates, persists next step, idempotent ---
    $n = 'Should_Reset_And_BeIdempotent'
    $r = Invoke-Tool $helper -Action reset -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $sessions -CurrentStep 5
    $obj = Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($r.Code -ne 0 -or $obj.phase -ne 'idle' -or $obj.current_step -ne 5 -or [bool]$obj.gates.step_confirmed -or [bool]$obj.gates.tests_run) { Write-Fail $n "reset exit $($r.Code): $($r.Out)" }
    $h = Get-Sha $sf.FullName
    $r = Invoke-Tool $helper -Action reset -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $sessions -CurrentStep 5
    if ($r.Code -ne 0 -or $r.Out -notmatch '"skipped":\s*true' -or $h -ne (Get-Sha $sf.FullName)) { Write-Fail $n 'repeated reset not idempotent' }
    Write-Pass $n

    # --- write failure (file held without write share) -> structured error, exit 3 ---
    $n = 'Should_Exit3_When_SessionWriteOrReadbackFails'
    $lockRoot = Join-Path $work 'sessions-lock'
    $null = Invoke-Tool $helper -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $lockRoot
    $ls = Get-ChildItem -LiteralPath $lockRoot -Recurse -Filter 'plan-*.json' -File | Select-Object -First 1
    $before = Get-Sha $ls.FullName
    $handle = [System.IO.File]::Open($ls.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try { $r = Invoke-Tool $helper -Action reset -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $lockRoot -CurrentStep 2 }
    finally { $handle.Dispose() }
    if ($r.Code -ne 3 -or $r.Out -notmatch '"ok":\s*false' -or $before -ne (Get-Sha $ls.FullName)) { Write-Fail $n "expected exit 3 and unchanged file, got $($r.Code): $($r.Out)" }
    Write-Pass $n

    # --- persisted identity mismatch fails without mutation ---
    $n = 'Should_Reject_When_PersistedIdentityMismatches'
    $idRoot = Join-Path $work 'sessions-identity'
    $null = Invoke-Tool $helper -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $idRoot
    $is = Get-ChildItem -LiteralPath $idRoot -Recurse -Filter 'plan-*.json' -File | Select-Object -First 1
    $io = Get-Content -LiteralPath $is.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $io.repo = Join-Path $repoRoot 'mismatch-repo'
    $io | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $is.FullName -Encoding UTF8
    $bytes = Get-Sha $is.FullName
    $r = Invoke-Tool $helper -PlanPath $plan -RepoPath $repoRoot -SessionsRoot $idRoot
    if ($r.Code -eq 0 -or $r.Out -notmatch 'session_identity_mismatch' -or $bytes -ne (Get-Sha $is.FullName)) { Write-Fail $n "exit $($r.Code): $($r.Out)" }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-DevelopSessionGate: ALL PASS'
exit 0
