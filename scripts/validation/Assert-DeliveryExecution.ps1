#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$helper = Join-Path (Split-Path -Parent $PSScriptRoot) 'ledger/Resolve-DeliveryExecution.ps1'
$writer = Join-Path (Split-Path -Parent $PSScriptRoot) 'ledger/Set-DeliveryExecutionBlock.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-execution-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function New-Fixture([string]$Name, [string]$Cadence = 'continuous', [string]$Step1Status = 'PENDING', [string]$Step2Status = 'PENDING', [string]$ActiveStep = '') {
    $checkpoint = @{ run_id = 'run-1'; active_step = $ActiveStep; branch = 'codex/test'; head = 'abc123' } | ConvertTo-Json -Compress
    $approval = @{ state = 'approved'; identity = 'IDENTITY'; input_identity = 'INPUT-1'; review_state = 'reviewed'; blocking_findings = @(); unresolved_decisions = @() } | ConvertTo-Json -Compress
    $progress = @{ cadence = $Cadence } | ConvertTo-Json -Compress
    $step1 = @{ id = 'US01-S1'; status = $Step1Status; depends_on = @() } | ConvertTo-Json -Compress
    $step2 = @{ id = 'US01-S2'; status = $Step2Status; depends_on = @('US01-S1') } | ConvertTo-Json -Compress
    $body = @"
# Test plan

Normative body: feature behavior.

<!-- DELIVERY:PROGRESS:BEGIN -->
$progress
<!-- DELIVERY:PROGRESS:END -->
<!-- DELIVERY:CHECKPOINT:BEGIN -->
$checkpoint
<!-- DELIVERY:CHECKPOINT:END -->
<!-- DELIVERY:APPROVAL:BEGIN -->
$approval
<!-- DELIVERY:APPROVAL:END -->
<!-- DELIVERY:STEP-US01-S1:BEGIN -->
$step1
<!-- DELIVERY:STEP-US01-S1:END -->
<!-- DELIVERY:STEP-US01-S2:BEGIN -->
$step2
<!-- DELIVERY:STEP-US01-S2:END -->
"@
    $projection = [regex]::Replace($body, '(?ms)^<!-- DELIVERY:[A-Z0-9-]+:BEGIN -->\r?\n.*?\r?\n<!-- DELIVERY:[A-Z0-9-]+:END -->\r?\n?', '')
    $projection = $projection.TrimStart([char]0xFEFF).Replace([string][char]13 + [char]10, [string][char]10).Replace([string][char]13, [string][char]10)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $identity = ([BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($projection))).Replace('-', '')) }
    finally { $sha.Dispose() }
    $body = $body.Replace('"identity":"IDENTITY"', ('"identity":"' + $identity + '"'))
    $path = Join-Path $tempRoot ($Name + '.md')
    [System.IO.File]::WriteAllText($path, $body, (New-Object System.Text.UTF8Encoding -ArgumentList $false))
    return $path
}

function Invoke-Decision([string]$Plan, [string]$Cadence = 'continuous', [string]$InputIdentity = 'INPUT-1', [string]$Branch = 'codex/test', [string]$Head = 'abc123', [switch]$Resume, [switch]$StepAuth, [switch]$ContinuousAuth) {
    $argsList = @('-NoProfile', '-File', $helper, '-PlanPath', $Plan, '-Cadence', $Cadence, '-CurrentInputIdentity', $InputIdentity, '-CurrentBranch', $Branch, '-CurrentHead', $Head)
    if ($Resume) { $argsList += '-Resume' }
    if ($StepAuth) { $argsList += '-StepAuthorization' }
    if ($ContinuousAuth) { $argsList += '-ContinuousAuthorization' }
    $result = & pwsh @argsList 2>&1 | Out-String
    $exit = $LASTEXITCODE
    return [pscustomobject]@{ ExitCode = $exit; Result = ($result.Trim() | ConvertFrom-Json) }
}

try {
    $plan = New-Fixture 'eligible'
    $r = Invoke-Decision $plan -ContinuousAuth
    Assert-Equal '0' ([string]$r.ExitCode) 'continuous eligible exit'
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'first declared step selected'

    $resumed = New-Fixture 'completed-step' -Step1Status COMPLETED
    $r = Invoke-Decision $resumed -ContinuousAuth -Resume
    Assert-Equal 'US01-S2' ([string]$r.Result.step) 'continuous resume does not replay the completed step'

    $r = Invoke-Decision $plan
    Assert-Equal 'continuous_authorization_required' ([string]$r.Result.reason) 'continuous authorization required'

    $stepPlan = New-Fixture 'step-mode' -Cadence step_by_step
    $r = Invoke-Decision $stepPlan -Cadence step_by_step
    Assert-Equal 'step_authorization_required' ([string]$r.Result.reason) 'step authorization required'
    $r = Invoke-Decision $stepPlan -Cadence step_by_step -StepAuth
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'step-by-step eligible'
    $stepResume = New-Fixture 'step-resume' -Cadence step_by_step -Step1Status COMPLETED
    $r = Invoke-Decision $stepResume -Cadence step_by_step -Resume -StepAuth
    Assert-Equal 'US01-S2' ([string]$r.Result.step) 'step-by-step resumes at the next pending step'

    $bypass = New-Fixture 'bypass'
    $bypassText = [System.IO.File]::ReadAllText($bypass)
    $bypassText = $bypassText.Replace('"review_state":"reviewed"', '"review_state":"bypassed"')
    [System.IO.File]::WriteAllText($bypass, $bypassText, (New-Object System.Text.UTF8Encoding -ArgumentList $false))
    $r = Invoke-Decision $bypass -ContinuousAuth
    Assert-Equal 'review_bypass_evidence_missing' ([string]$r.Result.reason) 'review bypass requires operator evidence'
    $bypassText = [regex]::Replace($bypassText, '(?s)(<!-- DELIVERY:APPROVAL:BEGIN -->\r?\n)(.*?)(\r?\n<!-- DELIVERY:APPROVAL:END -->)', {
        param($match)
        $record = $match.Groups[2].Value | ConvertFrom-Json
        $record | Add-Member -NotePropertyName review_bypass_reason -NotePropertyValue 'Cold review unavailable'
        $record | Add-Member -NotePropertyName review_bypass_operator_choice -NotePropertyValue 'bypass'
        return ($match.Groups[1].Value + ($record | ConvertTo-Json -Compress) + $match.Groups[3].Value)
    })
    [System.IO.File]::WriteAllText($bypass, $bypassText, (New-Object System.Text.UTF8Encoding -ArgumentList $false))
    $r = Invoke-Decision $bypass -ContinuousAuth
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'documented review bypass preserves eligibility'

    $r = Invoke-Decision $plan -InputIdentity 'CHANGED'
    Assert-Equal 'material_input_identity_stale' ([string]$r.Result.reason) 'changed input blocks'

    $r = Invoke-Decision $plan -Resume -Branch 'codex/other'
    Assert-Equal 'branch_mismatch' ([string]$r.Result.reason) 'branch mismatch blocks'
    $r = Invoke-Decision $plan -Resume -Head 'deadbeef'
    Assert-Equal 'head_mismatch' ([string]$r.Result.reason) 'head mismatch blocks'

    $orphan = New-Fixture 'orphan' -Step1Status IN_PROGRESS -ActiveStep US01-S1
    $r = Invoke-Decision $orphan -Resume -ContinuousAuth
    Assert-Equal 'orphaned_in_progress_reconcile_required' ([string]$r.Result.reason) 'orphan is never replayed'

    $blockedDep = New-Fixture 'dependency' -Step1Status BLOCKED
    $r = Invoke-Decision $blockedDep -ContinuousAuth -Resume
    Assert-Equal 'blocked_step_requires_resolution' ([string]$r.Result.reason) 'blocked dependency cannot be skipped'

    $tampered = New-Fixture 'tampered'
    [System.IO.File]::AppendAllText($tampered, ([string][char]10 + 'Material scope changed.' + [char]10), [System.Text.Encoding]::UTF8)
    $r = Invoke-Decision $tampered -ContinuousAuth
    Assert-Equal 'approval_identity_stale' ([string]$r.Result.reason) 'material edit invalidates approval'

    $writerRepo = Join-Path $tempRoot 'writer-repo'
    $writerDir = Join-Path $writerRepo 'features/unit'
    New-Item -ItemType Directory -Path $writerDir -Force | Out-Null
    $writerPlan = Join-Path $writerDir 'PLAN.md'
    $nl = [string][char]10
    $writerText = @('# Plan', '', '<!-- DELIVERY:PROGRESS:BEGIN -->', '{"cadence":"step_by_step"}', '<!-- DELIVERY:PROGRESS:END -->', '', 'Approved body.', '') -join $nl
    [System.IO.File]::WriteAllText($writerPlan, $writerText, (New-Object System.Text.UTF8Encoding -ArgumentList $false))
    $oldBlock = '{"cadence":"step_by_step"}'
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $oldHash = [BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($oldBlock))).Replace('-', '') }
    finally { $sha.Dispose() }
    $payload = @{ cadence = 'continuous'; authorization = 'choice-1' } | ConvertTo-Json -Compress
    $writerResult = (& pwsh -NoProfile -File $writer -RepoPath $writerRepo -PlanPath $writerPlan -Block PROGRESS -ExpectedBlockHash $oldHash -PayloadJson $payload 2>&1 | Out-String).Trim() | ConvertFrom-Json
    Assert-Equal 'written_and_verified' ([string]$writerResult.code) 'operational block atomic write'
    $writtenText = [System.IO.File]::ReadAllText($writerPlan)
    Assert-Equal 'True' ([string]$writtenText.Contains('Approved body.')) 'operational write preserves normative content'
    $staleResult = (& pwsh -NoProfile -File $writer -RepoPath $writerRepo -PlanPath $writerPlan -Block PROGRESS -ExpectedBlockHash $oldHash -PayloadJson $oldBlock 2>&1 | Out-String).Trim() | ConvertFrom-Json
    Assert-Equal 'state_conflict' ([string]$staleResult.code) 'stale writer cannot overwrite newer state'
    $withBom = [System.IO.File]::ReadAllBytes($writerPlan)
    $bom = [byte[]]@(0xEF, 0xBB, 0xBF)
    $bomBytes = $bom + $withBom
    [System.IO.File]::WriteAllBytes($writerPlan, $bomBytes)
    $currentBlock = [regex]::Match([System.IO.File]::ReadAllText($writerPlan), '(?ms)^<!-- DELIVERY:PROGRESS:BEGIN -->\r?\n(.*?)\r?\n<!-- DELIVERY:PROGRESS:END -->$').Groups[1].Value
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $currentHash = [BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($currentBlock))).Replace('-', '') }
    finally { $sha.Dispose() }
    $nextPayload = @{ cadence = 'continuous'; authorization = 'choice-2' } | ConvertTo-Json -Compress
    $bomResult = (& pwsh -NoProfile -File $writer -RepoPath $writerRepo -PlanPath $writerPlan -Block PROGRESS -ExpectedBlockHash $currentHash -PayloadJson $nextPayload 2>&1 | Out-String).Trim() | ConvertFrom-Json
    Assert-Equal 'written_and_verified' ([string]$bomResult.code) 'BOM plan state write'
    $afterBom = [System.IO.File]::ReadAllBytes($writerPlan)
    Assert-Equal '239' ([string]$afterBom[0]) 'BOM preserved once'
    Assert-Equal '35' ([string]$afterBom[3]) 'BOM is not duplicated'

    Write-Output ('PASS: {0} focused execution and resume assertions.' -f $passed)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
