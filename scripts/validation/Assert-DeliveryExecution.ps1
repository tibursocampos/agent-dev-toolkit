#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptsRoot = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $scriptsRoot 'ledger/Resolve-DeliveryExecution.ps1'
$writer = Join-Path $scriptsRoot 'ledger/Set-DeliveryExecutionBlock.ps1'
. (Join-Path $scriptsRoot '_lib/DeliveryGrammar.ps1')

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-execution-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0
$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function ConvertTo-CompactJson([hashtable]$Value) {
    return ($Value | ConvertTo-Json -Compress -Depth 10)
}

function New-PlanBody {
    param(
        [string] $Cadence = 'continuous',
        [string] $Step1Status = 'PENDING',
        [string] $Step2Status = 'PENDING',
        [string] $ActiveStep = '',
        [string] $Identity = 'PENDING-IDENTITY',
        [hashtable] $Step2Extra = @{},
        [switch] $OmitDependsOn
    )

    $activeStepValue = $null
    if (-not [string]::IsNullOrEmpty($ActiveStep)) { $activeStepValue = $ActiveStep }
    $checkpoint = ConvertTo-CompactJson @{ schema = 'delivery-checkpoint/v1'; run_id = 'run-1'; branch = 'codex/test'; head = 'abc123'; active_step = $activeStepValue }
    $approval = ConvertTo-CompactJson @{ schema = 'delivery-approval/v1'; state = 'approved'; identity = $Identity; input_identity = 'INPUT-1'; review_state = 'reviewed'; blocking_findings = @(); unresolved_decisions = @() }
    $progress = ConvertTo-CompactJson @{ schema = 'delivery-progress/v1'; cadence = $Cadence }
    $step1Fields = @{ schema = 'delivery-step/v1'; id = 'US01-S1'; status = $Step1Status; depends_on = @() }
    $step2Fields = @{ schema = 'delivery-step/v1'; id = 'US01-S2'; status = $Step2Status; depends_on = @('US01-S1') }
    if ($OmitDependsOn) {
        $step1Fields.Remove('depends_on')
        $step2Fields.Remove('depends_on')
    }
    $step1 = ConvertTo-CompactJson $step1Fields
    foreach ($key in $Step2Extra.Keys) { $step2Fields[$key] = $Step2Extra[$key] }
    $step2 = ConvertTo-CompactJson $step2Fields

    $lines = @(
        '# Test plan',
        '',
        'Normative body: feature behavior.',
        '',
        '<!-- DELIVERY:PROGRESS:BEGIN -->',
        $progress,
        '<!-- DELIVERY:PROGRESS:END -->',
        '<!-- DELIVERY:CHECKPOINT:BEGIN -->',
        $checkpoint,
        '<!-- DELIVERY:CHECKPOINT:END -->',
        '<!-- DELIVERY:APPROVAL:BEGIN -->',
        $approval,
        '<!-- DELIVERY:APPROVAL:END -->',
        '<!-- DELIVERY:STEP:US01-S1:BEGIN -->',
        $step1,
        '<!-- DELIVERY:STEP:US01-S1:END -->',
        '<!-- DELIVERY:STEP:US01-S2:BEGIN -->',
        $step2,
        '<!-- DELIVERY:STEP:US01-S2:END -->'
    )
    return (($lines -join "`n") + "`n")
}

function New-Fixture([string]$Name, [string]$Cadence = 'continuous', [string]$Step1Status = 'PENDING', [string]$Step2Status = 'PENDING', [string]$ActiveStep = '', [hashtable]$Step2Extra = @{}, [switch]$OmitDependsOn) {
    # Block payloads are outside the normative projection, so the identity can be computed from the canonical body.
    $reference = New-PlanBody -Cadence $Cadence -Step1Status $Step1Status -Step2Status $Step2Status -ActiveStep $ActiveStep -OmitDependsOn:$OmitDependsOn
    $identity = Get-DeliveryNormativeIdentity -Text $reference
    $body = New-PlanBody -Cadence $Cadence -Step1Status $Step1Status -Step2Status $Step2Status -ActiveStep $ActiveStep -Identity $identity -Step2Extra $Step2Extra -OmitDependsOn:$OmitDependsOn
    $path = Join-Path $tempRoot ($Name + '.md')
    [System.IO.File]::WriteAllText($path, $body, $utf8)
    return $path
}

function Get-BlockHashFromFile([string]$Path, [string]$Type, [string]$Id = '') {
    $parsed = Read-DeliveryBlocks -Text ([System.IO.File]::ReadAllText($Path))
    $block = @($parsed.Blocks | Where-Object { ($_.Type -ceq $Type) -and (([string]$_.Id) -ceq $Id) })[0]
    return (Get-DeliveryBlockHash -Payload $block.Payload)
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-ChildScript([string[]]$Arguments) {
    # Explicit quoting keeps JSON arguments intact under both Windows PowerShell and PowerShell 7 parents.
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $childHost
    $startInfo.Arguments = (@($Arguments | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = ($stdoutTask.Result + $stderrText) }
}

function Invoke-Decision([string]$Plan, [string]$Cadence = 'continuous', [string]$InputIdentity = 'INPUT-1', [string]$Branch = 'codex/test', [string]$Head = 'abc123', [switch]$Resume, [switch]$StepAuth, [switch]$ContinuousAuth) {
    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $helper, '-PlanPath', $Plan, '-Cadence', $Cadence, '-CurrentInputIdentity', $InputIdentity, '-CurrentBranch', $Branch, '-CurrentHead', $Head)
    if ($Resume) { $argsList += '-Resume' }
    if ($StepAuth) { $argsList += '-StepAuthorization' }
    if ($ContinuousAuth) { $argsList += '-ContinuousAuthorization' }
    $run = Invoke-ChildScript $argsList
    return [pscustomobject]@{ ExitCode = $run.ExitCode; Result = ($run.Output.Trim() | ConvertFrom-Json) }
}

function Invoke-Writer([string]$RepoPath, [string]$PlanPath, [string]$Block, [string]$Hash, [string]$Payload) {
    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $writer, '-RepoPath', $RepoPath, '-PlanPath', $PlanPath, '-Block', $Block, '-ExpectedBlockHash', $Hash, '-PayloadJson', $Payload)
    $run = Invoke-ChildScript $argsList
    $parsed = $null
    try { $parsed = $run.Output.Trim() | ConvertFrom-Json } catch { $parsed = $null }
    return [pscustomobject]@{ ExitCode = $run.ExitCode; Result = $parsed; Output = $run.Output }
}

function Get-FileBase64([string]$Path) {
    return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

function Get-FileSha256Hex([string]$Path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($Path)))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function New-EvidencePlan {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [string] $Step1Status = 'PENDING',
        [switch] $OmitRefs,
        [string] $RefPath = 'features/001-demo/US01/evidence/US01-S1--plan-snapshot.md',
        [string] $Step2Needs = 'US01-S1/plan-snapshot',
        [string] $Step1Extra = '',
        [string] $Step2Extra = '',
        [switch] $DuplicateRefs,
        [string] $Checkpoint = '{"schema":"delivery-checkpoint/v1","branch":"codex/test","head":"abc123","active_step":null}'
    )

    $repo = Join-Path $tempRoot $Name
    $unitDir = Join-Path $repo 'features/001-demo/US01'
    $evidenceDir = Join-Path $unitDir 'evidence'
    New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
    $evidenceFile = Join-Path $evidenceDir 'US01-S1--plan-snapshot.md'
    [System.IO.File]::WriteAllText($evidenceFile, ('Snapshot of the normative body for {0}.' -f $Name), $utf8)
    $sha = Get-FileSha256Hex $evidenceFile

    $refEntry = '{"name":"plan-snapshot","path":"' + $RefPath + '","sha256":"' + $sha + '"}'
    if ($DuplicateRefs) { $refEntry = $refEntry + ',' + $refEntry }
    $refsJson = ''
    if (-not $OmitRefs) {
        $refsJson = ',"evidence_refs":[' + $refEntry + ']'
    }
    $needsLine = ''
    if (-not [string]::IsNullOrEmpty($Step2Needs)) { $needsLine = 'Needs evidence: ' + $Step2Needs }

    $headings = @('# Evidence plan', '', 'Normative body: feature behavior.', '', '## Steps', '',
        '### US01-S1 Produce snapshot', 'Depends on: none', 'Evidence: plan-snapshot')
    if ($Step1Extra.Length -gt 0) { $headings += $Step1Extra }
    $headings += @('Validation: run-tests', '', '### US01-S2 Consume snapshot', 'Depends on: US01-S1')
    if ($needsLine.Length -gt 0) { $headings += $needsLine }
    if ($Step2Extra.Length -gt 0) { $headings += $Step2Extra }
    $headings += @('Validation: run-tests', '')

    $progress = '{"schema":"delivery-progress/v1","cadence":"continuous"}'
    $step1 = '{"schema":"delivery-step/v1","id":"US01-S1","status":"' + $Step1Status + '","depends_on":[]' + $refsJson + '}'
    $step2 = '{"schema":"delivery-step/v1","id":"US01-S2","status":"PENDING","depends_on":["US01-S1"]}'

    $buildBody = {
        param([string]$Identity)
        $approval = '{"schema":"delivery-approval/v1","state":"approved","identity":"' + $Identity + '","input_identity":"INPUT-1","review_state":"reviewed","blocking_findings":[],"unresolved_decisions":[]}'
        $lines = @($headings + @(
            '<!-- DELIVERY:PROGRESS:BEGIN -->', $progress, '<!-- DELIVERY:PROGRESS:END -->',
            '<!-- DELIVERY:CHECKPOINT:BEGIN -->', $Checkpoint, '<!-- DELIVERY:CHECKPOINT:END -->',
            '<!-- DELIVERY:APPROVAL:BEGIN -->', $approval, '<!-- DELIVERY:APPROVAL:END -->',
            '<!-- DELIVERY:STEP:US01-S1:BEGIN -->', $step1, '<!-- DELIVERY:STEP:US01-S1:END -->',
            '<!-- DELIVERY:STEP:US01-S2:BEGIN -->', $step2, '<!-- DELIVERY:STEP:US01-S2:END -->'))
        return (($lines -join "`n") + "`n")
    }

    $probe = & $buildBody 'PENDING-IDENTITY'
    $identity = Get-DeliveryNormativeIdentity -Text $probe
    $planPath = Join-Path $unitDir 'PLAN.md'
    [System.IO.File]::WriteAllText($planPath, (& $buildBody $identity), $utf8)
    return $planPath
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
    [System.IO.File]::WriteAllText($bypass, $bypassText, $utf8)
    $r = Invoke-Decision $bypass -ContinuousAuth
    Assert-Equal 'review_bypass_evidence_missing' ([string]$r.Result.reason) 'review bypass requires operator evidence'
    $bypassText = [regex]::Replace($bypassText, '(?s)(<!-- DELIVERY:APPROVAL:BEGIN -->\r?\n)(.*?)(\r?\n<!-- DELIVERY:APPROVAL:END -->)', {
        param($match)
        $record = $match.Groups[2].Value | ConvertFrom-Json
        $record | Add-Member -NotePropertyName review_bypass_reason -NotePropertyValue 'Cold review unavailable'
        $record | Add-Member -NotePropertyName review_bypass_operator_choice -NotePropertyValue 'bypass'
        return ($match.Groups[1].Value + ($record | ConvertTo-Json -Compress) + $match.Groups[3].Value)
    })
    [System.IO.File]::WriteAllText($bypass, $bypassText, $utf8)
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

    $legacy = New-Fixture 'legacy-step-marker'
    $legacyText = [System.IO.File]::ReadAllText($legacy).Replace('<!-- DELIVERY:STEP:', '<!-- DELIVERY:STEP-')
    [System.IO.File]::WriteAllText($legacy, $legacyText, $utf8)
    $r = Invoke-Decision $legacy -ContinuousAuth
    Assert-Equal 'False' ([string]$r.Result.allowed) 'legacy STEP- block is not eligible'
    Assert-Equal 'legacy_marker' ([string]$r.Result.reason) 'legacy STEP- block reports legacy_marker'

    $noDependsOn = New-Fixture 'no-depends-on' -OmitDependsOn
    $r = Invoke-Decision $noDependsOn -ContinuousAuth
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'STEP payloads without depends_on are eligible for the first step'

    $unknownProperty = New-Fixture 'unknown-property' -Step2Extra @{ extra_note = 'not in allowlist' }
    $r = Invoke-Decision $unknownProperty -ContinuousAuth
    Assert-Equal 'grammar_invalid' ([string]$r.Result.reason) 'unknown block property reports grammar_invalid'
    Assert-Equal 'True' ([string](@($r.Result.errors) -contains 'unknown_property')) 'grammar_invalid lists unknown_property'

    $writerRepo = Join-Path $tempRoot 'writer-repo'
    $writerDir = Join-Path $writerRepo 'features/unit'
    New-Item -ItemType Directory -Path $writerDir -Force | Out-Null
    $writerPlan = Join-Path $writerDir 'PLAN.md'
    $nl = [string][char]10
    $writerOldPayload = '{"schema":"delivery-progress/v1","cadence":"step_by_step"}'
    $writerText = @('# Plan', '', '<!-- DELIVERY:PROGRESS:BEGIN -->', $writerOldPayload, '<!-- DELIVERY:PROGRESS:END -->', '', 'Approved body.', '') -join $nl
    [System.IO.File]::WriteAllText($writerPlan, $writerText, $utf8)
    $writerIdentity = Get-DeliveryNormativeIdentity -Text $writerText
    $oldHash = Get-DeliveryBlockHash -Payload $writerOldPayload
    $payload = ConvertTo-CompactJson @{
        schema        = 'delivery-progress/v1'
        cadence       = 'continuous'
        authorization = @{ kind = 'finite'; scope = 'continuous'; granted_utc = '2026-11-11T12:00:00Z'; plan_identity = $writerIdentity; step_ids = @('US01-S1') }
    }
    $identityBeforeWrite = Get-DeliveryNormativeIdentity -Text ([System.IO.File]::ReadAllText($writerPlan))
    $writerResult = Invoke-Writer $writerRepo $writerPlan 'PROGRESS' $oldHash $payload
    Assert-Equal 'written_and_verified' ([string]$writerResult.Result.code) 'operational block atomic write'
    $writtenText = [System.IO.File]::ReadAllText($writerPlan)
    Assert-Equal 'True' ([string]$writtenText.Contains('Approved body.')) 'operational write preserves normative content'
    Assert-Equal $identityBeforeWrite (Get-DeliveryNormativeIdentity -Text $writtenText) 'operational write keeps plan identity'
    $staleResult = Invoke-Writer $writerRepo $writerPlan 'PROGRESS' $oldHash $writerOldPayload
    Assert-Equal 'state_conflict' ([string]$staleResult.Result.code) 'stale writer cannot overwrite newer state'
    $withBom = [System.IO.File]::ReadAllBytes($writerPlan)
    $bom = [byte[]]@(0xEF, 0xBB, 0xBF)
    $bomBytes = $bom + $withBom
    [System.IO.File]::WriteAllBytes($writerPlan, $bomBytes)
    $currentHash = Get-BlockHashFromFile $writerPlan 'PROGRESS'
    $nextPayload = ConvertTo-CompactJson @{ schema = 'delivery-progress/v1'; cadence = 'continuous'; current_stage = 'implementation' }
    $bomResult = Invoke-Writer $writerRepo $writerPlan 'PROGRESS' $currentHash $nextPayload
    Assert-Equal 'written_and_verified' ([string]$bomResult.Result.code) 'BOM plan state write'
    $afterBom = [System.IO.File]::ReadAllBytes($writerPlan)
    Assert-Equal '239' ([string]$afterBom[0]) 'BOM preserved once'
    Assert-Equal '35' ([string]$afterBom[3]) 'BOM is not duplicated'

    $beforeUnknownKey = Get-FileBase64 $writerPlan
    $unknownHash = Get-BlockHashFromFile $writerPlan 'PROGRESS'
    $unknownKeyResult = Invoke-Writer $writerRepo $writerPlan 'PROGRESS' $unknownHash '{"schema":"delivery-progress/v1","cadence":"continuous","bogus":"x"}'
    Assert-Equal 'invalid_payload' ([string]$unknownKeyResult.Result.code) 'setter refuses payload with unknown key'
    Assert-Equal 'True' ([string]((Get-FileBase64 $writerPlan) -ceq $beforeUnknownKey)) 'refused payload leaves plan file unchanged'

    $stepWriterPlan = Join-Path $writerDir 'STEP-PLAN.md'
    $stepWriterText = @('# Steps', '', '<!-- DELIVERY:STEP:US01-S1:BEGIN -->', '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[]}', '<!-- DELIVERY:STEP:US01-S1:END -->', '') -join $nl
    [System.IO.File]::WriteAllText($stepWriterPlan, $stepWriterText, $utf8)
    $stepIdentityBefore = Get-DeliveryNormativeIdentity -Text $stepWriterText
    $stepHash = Get-BlockHashFromFile $stepWriterPlan 'STEP' 'US01-S1'
    $stepWrite = Invoke-Writer $writerRepo $stepWriterPlan 'STEP:US01-S1' $stepHash '{"schema":"delivery-step/v1","id":"US01-S1","status":"IN_PROGRESS","depends_on":[],"started_utc":"2026-11-11T12:00:00Z"}'
    Assert-Equal 'written_and_verified' ([string]$stepWrite.Result.code) 'canonical STEP block write'
    Assert-Equal $stepIdentityBefore (Get-DeliveryNormativeIdentity -Text ([System.IO.File]::ReadAllText($stepWriterPlan))) 'STEP write keeps plan identity'

    $beforeStaleStep = Get-FileBase64 $stepWriterPlan
    $staleStep = Invoke-Writer $writerRepo $stepWriterPlan 'STEP:US01-S1' ('0' * 64) '{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","depends_on":[]}'
    Assert-Equal 'state_conflict' ([string]$staleStep.Result.code) 'setter refuses stale expected hash on STEP block'
    Assert-Equal 'True' ([string]((Get-FileBase64 $stepWriterPlan) -ceq $beforeStaleStep)) 'stale STEP write leaves plan file unchanged'

    $absentStep = Invoke-Writer $writerRepo $stepWriterPlan 'STEP:US01-S9' ('0' * 64) '{"schema":"delivery-step/v1","id":"US01-S9","status":"PENDING","depends_on":[]}'
    Assert-Equal 'block_missing' ([string]$absentStep.Result.code) 'setter reports absent STEP block'

    $legacyBlockName = Invoke-Writer $writerRepo $stepWriterPlan 'STEP-US01-S1' $stepHash '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[]}'
    Assert-Equal 'True' ([string]($legacyBlockName.ExitCode -ne 0)) 'setter rejects legacy STEP- block name'

    $stepEmbeddedNewline = Get-FileBase64 $stepWriterPlan
    $newlineHash = Get-BlockHashFromFile $stepWriterPlan 'STEP' 'US01-S1'
    $newlinePayload = "{`n""schema"":""delivery-step/v1"",""id"":""US01-S1"",""status"":""PENDING"",""depends_on"":[]}"
    $newlineResult = Invoke-Writer $writerRepo $stepWriterPlan 'STEP:US01-S1' $newlineHash $newlinePayload
    Assert-Equal 'invalid_payload' ([string]$newlineResult.Result.code) 'setter refuses payload with embedded newline'
    Assert-Equal 'True' ([string]((Get-FileBase64 $stepWriterPlan) -ceq $stepEmbeddedNewline)) 'newline payload leaves plan file unchanged'

    $tsRepo = Join-Path $tempRoot 'timestamp-repo'
    $tsDir = Join-Path $tsRepo 'features/unit'
    New-Item -ItemType Directory -Path $tsDir -Force | Out-Null
    $tsPlan = Join-Path $tsDir 'PLAN.md'
    Copy-Item -LiteralPath (New-Fixture 'timestamp-step') -Destination $tsPlan
    $tsHash = Get-BlockHashFromFile $tsPlan 'STEP' 'US01-S1'
    $tsPayload = '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[],"started_utc":"2026-11-11T12:00:00Z"}'
    $tsWrite = Invoke-Writer $tsRepo $tsPlan 'STEP:US01-S1' $tsHash $tsPayload
    Assert-Equal 'written_and_verified' ([string]$tsWrite.Result.code) 'STEP payload with timestamp written'
    Assert-Equal 'True' ([string]([System.IO.File]::ReadAllText($tsPlan).Contains('"started_utc":"2026-11-11T12:00:00Z"'))) 'timestamp text kept byte for byte'
    $r = Invoke-Decision $tsPlan -ContinuousAuth
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'plan with timestamped STEP stays eligible'

    $opRepo = Join-Path $tempRoot 'op-repo'
    $opDir = Join-Path $opRepo 'features/unit'
    New-Item -ItemType Directory -Path $opDir -Force | Out-Null
    $opPlan = Join-Path $opDir 'PLAN.md'
    Copy-Item -LiteralPath (New-Fixture 'operational-edit') -Destination $opPlan
    $opIdentityBefore = Get-DeliveryNormativeIdentity -Text ([System.IO.File]::ReadAllText($opPlan))
    $opHash = Get-BlockHashFromFile $opPlan 'PROGRESS'
    $opPayload = ConvertTo-CompactJson @{ schema = 'delivery-progress/v1'; cadence = 'continuous'; current_stage = 'implementation'; completed = 1; total = 2 }
    $opWrite = Invoke-Writer $opRepo $opPlan 'PROGRESS' $opHash $opPayload
    Assert-Equal 'written_and_verified' ([string]$opWrite.Result.code) 'operational PROGRESS edit written'
    Assert-Equal $opIdentityBefore (Get-DeliveryNormativeIdentity -Text ([System.IO.File]::ReadAllText($opPlan))) 'operational edit keeps approval identity'
    $r = Invoke-Decision $opPlan -ContinuousAuth
    Assert-Equal 'True' ([string]$r.Result.allowed) 'operational edit keeps plan eligible'
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'operational edit selects the same step'

    $evidenceFileName = 'US01-S1--plan-snapshot.md'
    $evSatisfied = New-EvidencePlan 'ev-satisfied' -Step1Status COMPLETED
    $r = Invoke-Decision $evSatisfied -ContinuousAuth -Resume
    Assert-Equal 'True' ([string]$r.Result.allowed) 'satisfied Needs evidence allows the step'
    Assert-Equal 'US01-S2' ([string]$r.Result.step) 'step with satisfied Needs evidence is eligible (one-element evidence_refs)'

    $evNoRef = New-EvidencePlan 'ev-no-ref' -Step1Status COMPLETED -OmitRefs
    $r = Invoke-Decision $evNoRef -ContinuousAuth -Resume
    Assert-Equal 'evidence_missing' ([string]$r.Result.reason) 'evidence ref absent from producer block blocks'
    Assert-Equal 'US01-S1/plan-snapshot' ([string]$r.Result.evidence) 'evidence denial names the offending reference'

    $evDeleted = New-EvidencePlan 'ev-deleted' -Step1Status COMPLETED
    Remove-Item -LiteralPath (Join-Path $tempRoot ('ev-deleted/features/001-demo/US01/evidence/' + $evidenceFileName))
    $r = Invoke-Decision $evDeleted -ContinuousAuth -Resume
    Assert-Equal 'evidence_missing' ([string]$r.Result.reason) 'deleted evidence file blocks'

    $evChanged = New-EvidencePlan 'ev-changed' -Step1Status COMPLETED
    [System.IO.File]::AppendAllText((Join-Path $tempRoot ('ev-changed/features/001-demo/US01/evidence/' + $evidenceFileName)), ' edited', $utf8)
    $r = Invoke-Decision $evChanged -ContinuousAuth -Resume
    Assert-Equal 'evidence_changed' ([string]$r.Result.reason) 'evidence file edited after hashing blocks'
    Assert-Equal 'US01-S1/plan-snapshot' ([string]$r.Result.evidence) 'evidence_changed names the offending reference'

    $evTraversal = New-EvidencePlan 'ev-traversal' -Step1Status COMPLETED -RefPath 'features/001-demo/US01/evidence/../../../escape/US01-S1--plan-snapshot.md'
    $r = Invoke-Decision $evTraversal -ContinuousAuth -Resume
    Assert-Equal 'evidence_ref_invalid' ([string]$r.Result.reason) 'evidence ref with traversal is invalid'

    $evOutside = New-EvidencePlan 'ev-outside' -Step1Status COMPLETED -RefPath 'features/001-demo/US01/notes/US01-S1--plan-snapshot.md'
    $r = Invoke-Decision $evOutside -ContinuousAuth -Resume
    Assert-Equal 'evidence_ref_invalid' ([string]$r.Result.reason) 'evidence ref outside the evidence directory is invalid'

    $evOtherUnit = New-EvidencePlan 'ev-other-unit' -Step1Status COMPLETED -RefPath 'features/001-demo/US02/evidence/US01-S1--plan-snapshot.md'
    $r = Invoke-Decision $evOtherUnit -ContinuousAuth -Resume
    Assert-Equal 'evidence_ref_invalid' ([string]$r.Result.reason) 'evidence ref in another unit is invalid'

    $dirCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S1/plan-snapshot"}'
    $evDir = New-EvidencePlan 'ev-directory' -Checkpoint $dirCheckpoint
    $r = Invoke-Decision $evDir -ContinuousAuth -Resume -Branch 'elsewhere' -Head 'ffff'
    Assert-Equal 'True' ([string]$r.Result.allowed) 'directory checkpoint with valid baseline ignores branch and head on resume'
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'directory checkpoint selects the pending step'
    $r = Invoke-Decision $evDir -ContinuousAuth -Branch 'elsewhere' -Head 'ffff'
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'directory checkpoint with valid baseline is eligible without resume'

    $evDirChanged = New-EvidencePlan 'ev-directory-changed' -Checkpoint $dirCheckpoint
    [System.IO.File]::AppendAllText((Join-Path $tempRoot ('ev-directory-changed/features/001-demo/US01/evidence/' + $evidenceFileName)), ' edited', $utf8)
    $r = Invoke-Decision $evDirChanged -ContinuousAuth
    Assert-Equal 'baseline_changed' ([string]$r.Result.reason) 'directory baseline edited after hashing blocks'
    Assert-Equal 'US01-S1/plan-snapshot' ([string]$r.Result.evidence) 'baseline_changed names the baseline reference'

    $evDirNoRef = New-EvidencePlan 'ev-directory-no-ref' -Checkpoint $dirCheckpoint -OmitRefs
    $r = Invoke-Decision $evDirNoRef -ContinuousAuth
    Assert-Equal 'baseline_missing' ([string]$r.Result.reason) 'directory baseline without producer ref blocks'

    $evDirDeleted = New-EvidencePlan 'ev-directory-deleted' -Checkpoint $dirCheckpoint
    Remove-Item -LiteralPath (Join-Path $tempRoot ('ev-directory-deleted/features/001-demo/US01/evidence/' + $evidenceFileName))
    $r = Invoke-Decision $evDirDeleted -ContinuousAuth
    Assert-Equal 'baseline_missing' ([string]$r.Result.reason) 'directory baseline with deleted file blocks'

    $evDirTraversal = New-EvidencePlan 'ev-directory-traversal' -Checkpoint $dirCheckpoint -RefPath 'features/001-demo/US01/evidence/../../../escape/US01-S1--plan-snapshot.md'
    $r = Invoke-Decision $evDirTraversal -ContinuousAuth
    Assert-Equal 'baseline_ref_invalid' ([string]$r.Result.reason) 'directory baseline with traversal is invalid'

    $evGit = New-EvidencePlan 'ev-git-branch' -Step1Status COMPLETED
    $r = Invoke-Decision $evGit -ContinuousAuth -Resume -Branch 'codex/other'
    Assert-Equal 'branch_mismatch' ([string]$r.Result.reason) 'git checkpoint still blocks on branch mismatch'

    $evMalformedCandidate = New-EvidencePlan 'ev-malformed-candidate' -Step1Status COMPLETED -Step2Needs '' -Step2Extra 'Needs evidence: US01-S1-plan-snapshot'
    $r = Invoke-Decision $evMalformedCandidate -ContinuousAuth -Resume
    Assert-Equal 'evidence_ref_invalid' ([string]$r.Result.reason) 'malformed Needs line on the candidate fails closed'
    Assert-Equal 'US01-S2' ([string]$r.Result.evidence) 'candidate declaration denial names the candidate step'

    $evDuplicate = New-EvidencePlan 'ev-duplicate-name' -Step1Status COMPLETED -DuplicateRefs
    $r = Invoke-Decision $evDuplicate -ContinuousAuth -Resume
    Assert-Equal 'evidence_ref_invalid' ([string]$r.Result.reason) 'two evidence_refs entries with the same name are ambiguous'
    Assert-Equal 'US01-S1/plan-snapshot' ([string]$r.Result.evidence) 'duplicate name denial names the reference'

    $evUnrelated = New-EvidencePlan 'ev-unrelated-malformed' -Step1Status COMPLETED -Step1Extra 'Needs evidence: US01-S9' -Step2Needs ''
    $r = Invoke-Decision $evUnrelated -ContinuousAuth -Resume
    Assert-Equal 'True' ([string]$r.Result.allowed) 'malformed Needs on another step does not block an unrelated candidate'
    Assert-Equal 'US01-S2' ([string]$r.Result.step) 'unrelated candidate remains eligible'

    $r = Invoke-Decision $evDir -ContinuousAuth -Resume -Branch '' -Head ''
    Assert-Equal 'True' ([string]$r.Result.allowed) 'directory-kind plan accepts empty current branch and head through the CLI'
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'directory-kind empty branch and head select the pending step'

    $evGitEmpty = New-EvidencePlan 'ev-git-empty-branch' -Step1Status COMPLETED
    $r = Invoke-Decision $evGitEmpty -ContinuousAuth -Resume -Branch ''
    Assert-Equal 'branch_mismatch' ([string]$r.Result.reason) 'git-kind plan denies empty current branch as a mismatch'

    Write-Output ('PASS: {0} focused execution and resume assertions on PowerShell {1}.' -f $passed, $PSVersionTable.PSVersion)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
