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

function New-AuthorizationRecord {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('step', 'continuous')][string] $Kind,
        [Parameter(Mandatory = $true)][string] $PlanIdentity,
        [object[]] $StepIds = $null
    )

    $scope = 'continuous'
    if ($Kind -ceq 'step') { $scope = 'step_by_step' }
    $record = @{ kind = $Kind; scope = $scope; granted_utc = '2026-11-11T12:00:00Z'; plan_identity = $PlanIdentity }
    if ($null -ne $StepIds) { $record['step_ids'] = @($StepIds) }
    return $record
}

function New-PlanBody {
    param(
        [string] $Cadence = 'continuous',
        [string] $Step1Status = 'PENDING',
        [string] $Step2Status = 'PENDING',
        [string] $ActiveStep = '',
        [string] $Identity = 'PENDING-IDENTITY',
        [hashtable] $Step2Extra = @{},
        [hashtable] $ProgressExtra = @{},
        [switch] $OmitDependsOn
    )

    $activeStepValue = $null
    if (-not [string]::IsNullOrEmpty($ActiveStep)) { $activeStepValue = $ActiveStep }
    $checkpoint = ConvertTo-CompactJson @{ schema = 'delivery-checkpoint/v1'; run_id = 'run-1'; branch = 'codex/test'; head = 'abc123'; active_step = $activeStepValue }
    $approval = ConvertTo-CompactJson @{ schema = 'delivery-approval/v1'; state = 'approved'; identity = $Identity; input_identity = 'INPUT-1'; review_state = 'reviewed'; blocking_findings = @(); unresolved_decisions = @() }
    $progressFields = @{ schema = 'delivery-progress/v1'; cadence = $Cadence }
    foreach ($key in $ProgressExtra.Keys) { $progressFields[$key] = $ProgressExtra[$key] }
    $progress = ConvertTo-CompactJson $progressFields
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

function New-Fixture {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [string] $Cadence = 'continuous',
        [string] $Step1Status = 'PENDING',
        [string] $Step2Status = 'PENDING',
        [string] $ActiveStep = '',
        [hashtable] $Step2Extra = @{},
        [hashtable] $Authorization = $null,
        [switch] $NoAuthorization,
        [switch] $OmitDependsOn
    )

    # Block payloads are outside the normative projection, so the identity can be computed from the canonical body.
    $reference = New-PlanBody -Cadence $Cadence -Step1Status $Step1Status -Step2Status $Step2Status -ActiveStep $ActiveStep -OmitDependsOn:$OmitDependsOn
    $identity = Get-DeliveryNormativeIdentity -Text $reference
    $record = $Authorization
    if (($null -eq $record) -and -not $NoAuthorization) {
        $defaultKind = 'continuous'
        if ($Cadence -ceq 'step_by_step') { $defaultKind = 'step' }
        $defaultStepIds = $null
        if ($defaultKind -ceq 'step') { $defaultStepIds = @('US01-S1', 'US01-S2') }
        $record = New-AuthorizationRecord -Kind $defaultKind -PlanIdentity $identity -StepIds $defaultStepIds
    }
    $progressExtra = @{}
    if ($null -ne $record) { $progressExtra['authorization'] = $record }
    $body = New-PlanBody -Cadence $Cadence -Step1Status $Step1Status -Step2Status $Step2Status -ActiveStep $ActiveStep -Identity $identity -Step2Extra $Step2Extra -ProgressExtra $progressExtra -OmitDependsOn:$OmitDependsOn
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

    $step1 = '{"schema":"delivery-step/v1","id":"US01-S1","status":"' + $Step1Status + '","depends_on":[]' + $refsJson + '}'
    $step2 = '{"schema":"delivery-step/v1","id":"US01-S2","status":"PENDING","depends_on":["US01-S1"]}'

    $buildBody = {
        param([string]$Identity)
        $approval = '{"schema":"delivery-approval/v1","state":"approved","identity":"' + $Identity + '","input_identity":"INPUT-1","review_state":"reviewed","blocking_findings":[],"unresolved_decisions":[]}'
        $progress = '{"schema":"delivery-progress/v1","cadence":"continuous","authorization":{"kind":"continuous","scope":"continuous","granted_utc":"2026-11-11T12:00:00Z","plan_identity":"' + $Identity + '"}}'
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
    $canonicalIdentity = Get-DeliveryNormativeIdentity -Text (New-PlanBody)

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

    $noAuthContinuous = New-Fixture 'auth-record-missing-continuous' -NoAuthorization
    $r = Invoke-Decision $noAuthContinuous -ContinuousAuth
    Assert-Equal 'authorization_record_missing' ([string]$r.Result.reason) 'continuous switch without authorization record is denied'
    $noAuthStep = New-Fixture 'auth-record-missing-step' -Cadence step_by_step -NoAuthorization
    $r = Invoke-Decision $noAuthStep -Cadence step_by_step -StepAuth
    Assert-Equal 'authorization_record_missing' ([string]$r.Result.reason) 'step switch without authorization record is denied'

    $continuousKindOnStep = New-Fixture 'kind-continuous-on-step' -Cadence step_by_step -Authorization (New-AuthorizationRecord -Kind continuous -PlanIdentity $canonicalIdentity -StepIds @('US01-S1', 'US01-S2'))
    $r = Invoke-Decision $continuousKindOnStep -Cadence step_by_step -StepAuth
    Assert-Equal 'authorization_kind_mismatch' ([string]$r.Result.reason) 'step_by_step with kind continuous is denied'
    $stepKindOnContinuous = New-Fixture 'kind-step-on-continuous' -Authorization (New-AuthorizationRecord -Kind step -PlanIdentity $canonicalIdentity -StepIds @('US01-S1'))
    $r = Invoke-Decision $stepKindOnContinuous -ContinuousAuth
    Assert-Equal 'authorization_kind_mismatch' ([string]$r.Result.reason) 'continuous with kind step is denied'
    $upperKindOnStep = New-Fixture 'kind-upper-on-step' -Cadence step_by_step -Authorization (New-AuthorizationRecord -Kind step -PlanIdentity $canonicalIdentity -StepIds @('US01-S1'))
    $upperKindText = [System.IO.File]::ReadAllText($upperKindOnStep).Replace('"kind":"step"', '"kind":"STEP"')
    [System.IO.File]::WriteAllText($upperKindOnStep, $upperKindText, $utf8)
    $r = Invoke-Decision $upperKindOnStep -Cadence step_by_step -StepAuth
    Assert-Equal 'authorization_kind_mismatch' ([string]$r.Result.reason) 'authorization kind is case-sensitive'

    $otherPlanIdentity = New-Fixture 'identity-other-plan' -Authorization (New-AuthorizationRecord -Kind continuous -PlanIdentity ('0' * 64))
    $r = Invoke-Decision $otherPlanIdentity -ContinuousAuth
    Assert-Equal 'authorization_identity_mismatch' ([string]$r.Result.reason) 'continuous authorization bound to another plan is denied'
    $lowerIdentity = New-Fixture 'identity-lowercase' -Authorization (New-AuthorizationRecord -Kind continuous -PlanIdentity $canonicalIdentity.ToLowerInvariant())
    $r = Invoke-Decision $lowerIdentity -ContinuousAuth
    Assert-Equal 'authorization_identity_mismatch' ([string]$r.Result.reason) 'plan identity comparison is case-sensitive'

    $staleAuth = New-Fixture 'auth-stale-normative'
    $staleText = [System.IO.File]::ReadAllText($staleAuth)
    $staleOldIdentity = Get-DeliveryNormativeIdentity -Text $staleText
    $staleEdited = $staleText.Replace('Normative body: feature behavior.', 'Normative body: changed feature behavior.')
    $staleNewIdentity = Get-DeliveryNormativeIdentity -Text $staleEdited
    $staleEdited = $staleEdited.Replace('"identity":"' + $staleOldIdentity + '"', '"identity":"' + $staleNewIdentity + '"')
    [System.IO.File]::WriteAllText($staleAuth, $staleEdited, $utf8)
    $r = Invoke-Decision $staleAuth -ContinuousAuth
    Assert-Equal 'authorization_identity_mismatch' ([string]$r.Result.reason) 'authorization recorded before a normative edit is denied after re-approval'

    $stepOnlyFirst = New-Fixture 'scope-step-other-step' -Cadence step_by_step -Authorization (New-AuthorizationRecord -Kind step -PlanIdentity $canonicalIdentity -StepIds @('US01-S2'))
    $r = Invoke-Decision $stepOnlyFirst -Cadence step_by_step -StepAuth
    Assert-Equal 'authorization_scope_excludes_step' ([string]$r.Result.reason) 'step authorization that excludes the candidate is denied'
    $stepEmptyScope = New-Fixture 'scope-step-empty' -Cadence step_by_step -Authorization (New-AuthorizationRecord -Kind step -PlanIdentity $canonicalIdentity -StepIds @())
    $r = Invoke-Decision $stepEmptyScope -Cadence step_by_step -StepAuth
    Assert-Equal 'authorization_scope_excludes_step' ([string]$r.Result.reason) 'step authorization with empty step_ids is denied'
    $stepScalarScope = New-Fixture 'scope-step-scalar' -Cadence step_by_step -Authorization @{ kind = 'step'; scope = 'step_by_step'; granted_utc = '2026-11-11T12:00:00Z'; plan_identity = $canonicalIdentity; step_ids = 'US01-S1' }
    $r = Invoke-Decision $stepScalarScope -Cadence step_by_step -StepAuth
    Assert-Equal 'grammar_invalid' ([string]$r.Result.reason) 'step_ids given as a string is rejected by the block grammar'
    $stepOneElement = New-Fixture 'scope-step-single' -Cadence step_by_step -Authorization (New-AuthorizationRecord -Kind step -PlanIdentity $canonicalIdentity -StepIds @('US01-S1'))
    $r = Invoke-Decision $stepOneElement -Cadence step_by_step -StepAuth
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'one-element step_ids array covers the candidate'
    $stepOneElementResume = New-Fixture 'scope-step-single-resume' -Cadence step_by_step -Step1Status COMPLETED -Authorization (New-AuthorizationRecord -Kind step -PlanIdentity $canonicalIdentity -StepIds @('US01-S2'))
    $r = Invoke-Decision $stepOneElementResume -Cadence step_by_step -Resume -StepAuth
    Assert-Equal 'US01-S2' ([string]$r.Result.step) 'one-element step_ids array covers the resumed candidate'

    $continuousScopeMiss = New-Fixture 'scope-continuous-other-step' -Authorization (New-AuthorizationRecord -Kind continuous -PlanIdentity $canonicalIdentity -StepIds @('US01-S2'))
    $r = Invoke-Decision $continuousScopeMiss -ContinuousAuth
    Assert-Equal 'authorization_scope_excludes_step' ([string]$r.Result.reason) 'continuous step_ids that exclude the candidate are denied'
    $continuousScopeEmpty = New-Fixture 'scope-continuous-empty' -Authorization (New-AuthorizationRecord -Kind continuous -PlanIdentity $canonicalIdentity -StepIds @())
    $r = Invoke-Decision $continuousScopeEmpty -ContinuousAuth
    Assert-Equal 'authorization_scope_excludes_step' ([string]$r.Result.reason) 'continuous empty step_ids are denied'
    $continuousNoScope = New-Fixture 'scope-continuous-absent' -Authorization (New-AuthorizationRecord -Kind continuous -PlanIdentity $canonicalIdentity)
    $r = Invoke-Decision $continuousNoScope -ContinuousAuth
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'continuous authorization without step_ids covers every eligible step'

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
    $opPayload = ConvertTo-CompactJson @{ schema = 'delivery-progress/v1'; cadence = 'continuous'; current_stage = 'implementation'; completed = 1; total = 2; authorization = (New-AuthorizationRecord -Kind continuous -PlanIdentity $opIdentityBefore) }
    $opWrite = Invoke-Writer $opRepo $opPlan 'PROGRESS' $opHash $opPayload
    Assert-Equal 'written_and_verified' ([string]$opWrite.Result.code) 'operational PROGRESS edit written'
    Assert-Equal $opIdentityBefore (Get-DeliveryNormativeIdentity -Text ([System.IO.File]::ReadAllText($opPlan))) 'operational edit keeps approval identity'
    $r = Invoke-Decision $opPlan -ContinuousAuth
    Assert-Equal 'True' ([string]$r.Result.allowed) 'operational edit keeps plan eligible'
    Assert-Equal 'US01-S1' ([string]$r.Result.step) 'operational edit selects the same step'

    $dropRepo = Join-Path $tempRoot 'drop-repo'
    $dropDir = Join-Path $dropRepo 'features/unit'
    New-Item -ItemType Directory -Path $dropDir -Force | Out-Null
    $dropPlan = Join-Path $dropDir 'PLAN.md'
    Copy-Item -LiteralPath (New-Fixture 'operational-drop') -Destination $dropPlan
    $dropHash = Get-BlockHashFromFile $dropPlan 'PROGRESS'
    $dropWrite = Invoke-Writer $dropRepo $dropPlan 'PROGRESS' $dropHash '{"schema":"delivery-progress/v1","cadence":"continuous","current_stage":"implementation"}'
    Assert-Equal 'written_and_verified' ([string]$dropWrite.Result.code) 'operational PROGRESS edit without authorization written'
    $r = Invoke-Decision $dropPlan -ContinuousAuth
    Assert-Equal 'authorization_record_missing' ([string]$r.Result.reason) 'operational edit that drops the authorization is denied'

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

    # Plan-to-plan dependencies

    function New-UnitPlanText {
        param(
            [Parameter(Mandatory = $true)][string] $Unit,
            [string[]] $DependencyLines = @(),
            [string] $Body = 'Normative body: unit plan for the dependency self-test.',
            [string] $StepOneStatus = 'PENDING',
            [string] $StepOneEvidence = '',
            [string] $ApprovalState = 'approved',
            [string] $StepTwoStatus = 'PENDING'
        )

        $progress = '{"schema":"delivery-progress/v1","cadence":"continuous","authorization":{"kind":"continuous","scope":"continuous","granted_utc":"2026-11-11T12:00:00Z","plan_identity":"@@IDENTITY@@"}}'
        $checkpoint = '{"schema":"delivery-checkpoint/v1","branch":"codex/test","head":"abc123","active_step":null}'
        $stepOne = '{"schema":"delivery-step/v1","id":"' + $Unit + '-S1","status":"' + $StepOneStatus + '","depends_on":[]' + $StepOneEvidence + '}'
        $stepTwo = '{"schema":"delivery-step/v1","id":"' + $Unit + '-S2","status":"' + $StepTwoStatus + '","depends_on":["' + $Unit + '-S1"]}'
        if ($ApprovalState -ceq 'pending') {
            $approval = '{"schema":"delivery-approval/v1","state":"pending"}'
        }
        else {
            $approval = '{"schema":"delivery-approval/v1","state":"approved","identity":"@@IDENTITY@@","input_identity":"INPUT-1","review_state":"reviewed","blocking_findings":[],"unresolved_decisions":[]}'
        }

        $lines = @('# Unit plan', '', $Body, '')
        if ($DependencyLines.Count -gt 0) { $lines += @('## Plan dependencies', '') + $DependencyLines + '' }
        $lines += @('## Steps', '', ('### {0}-S1 First step' -f $Unit), 'Depends on: none', 'Validation: run-tests', '', ('### {0}-S2 Second step' -f $Unit), ('Depends on: {0}-S1' -f $Unit), 'Validation: run-tests', '')
        $lines += @(
            '<!-- DELIVERY:PROGRESS:BEGIN -->', $progress, '<!-- DELIVERY:PROGRESS:END -->',
            '<!-- DELIVERY:CHECKPOINT:BEGIN -->', $checkpoint, '<!-- DELIVERY:CHECKPOINT:END -->',
            '<!-- DELIVERY:APPROVAL:BEGIN -->', $approval, '<!-- DELIVERY:APPROVAL:END -->',
            ('<!-- DELIVERY:STEP:{0}-S1:BEGIN -->' -f $Unit), $stepOne, ('<!-- DELIVERY:STEP:{0}-S1:END -->' -f $Unit),
            ('<!-- DELIVERY:STEP:{0}-S2:BEGIN -->' -f $Unit), $stepTwo, ('<!-- DELIVERY:STEP:{0}-S2:END -->' -f $Unit))
        return (($lines -join "`n") + "`n")
    }

    function Complete-UnitPlanText([string]$Text) {
        return $Text.Replace('@@IDENTITY@@', (Get-DeliveryNormativeIdentity -Text $Text))
    }

    function New-DependencyRepo {
        param(
            [Parameter(Mandatory = $true)][string] $Name,
            [Parameter(Mandatory = $true)][string] $PredecessorText,
            [Parameter(Mandatory = $true)][string] $DependentText
        )

        $repo = Join-Path $tempRoot $Name
        $predecessorPath = Join-Path $repo 'features/001-demo/US01/PLAN.md'
        $dependentPath = Join-Path $repo 'features/001-demo/US02/PLAN.md'
        New-Item -ItemType Directory -Path (Split-Path -Parent $predecessorPath) -Force | Out-Null
        New-Item -ItemType Directory -Path (Split-Path -Parent $dependentPath) -Force | Out-Null
        [System.IO.File]::WriteAllText($predecessorPath, $PredecessorText, $utf8)
        [System.IO.File]::WriteAllText($dependentPath, $DependentText, $utf8)
        return [pscustomobject]@{ Predecessor = $predecessorPath; Dependent = $dependentPath }
    }

    $depPredecessorPath = 'features/001-demo/US01/PLAN.md'
    $depEvidence = ',"acceptance_evidence":["synthetic acceptance recorded"]'
    $depPredecessorDone = Complete-UnitPlanText (New-UnitPlanText -Unit 'US01' -StepOneStatus 'COMPLETED' -StepOneEvidence $depEvidence)
    $depIdentity = Get-DeliveryNormativeIdentity -Text $depPredecessorDone
    $depRequires = 'Requires plan: ' + $depPredecessorPath + ' identity=' + $depIdentity + ' steps=US01-S1'
    $depDependentText = Complete-UnitPlanText (New-UnitPlanText -Unit 'US02' -DependencyLines @($depRequires))

    $depEligible = New-DependencyRepo 'dep-complete' $depPredecessorDone $depDependentText
    $r = Invoke-Decision $depEligible.Dependent -ContinuousAuth
    Assert-Equal 'True' ([string]$r.Result.allowed) 'Should_AllowDependent_When_PredecessorStepCompleteWithEvidence'
    Assert-Equal 'US02-S1' ([string]$r.Result.step) 'Should_SelectOwnFirstStep_When_DependencyMet'

    $depPending = New-DependencyRepo 'dep-step-pending' (Complete-UnitPlanText (New-UnitPlanText -Unit 'US01')) $depDependentText
    $r = Invoke-Decision $depPending.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_step_incomplete' ([string]$r.Result.reason) 'Should_DenyDependent_When_PredecessorStepPending'
    Assert-Equal $depPredecessorPath ([string]$r.Result.dependency) 'Should_NameDependency_When_PredecessorStepPending'

    $depNoEvidence = New-DependencyRepo 'dep-evidence-missing' (Complete-UnitPlanText (New-UnitPlanText -Unit 'US01' -StepOneStatus 'COMPLETED')) $depDependentText
    $r = Invoke-Decision $depNoEvidence.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_evidence_missing' ([string]$r.Result.reason) 'Should_DenyDependent_When_CompletedStepHasNoAcceptanceEvidence'
    Assert-Equal $depPredecessorPath ([string]$r.Result.dependency) 'Should_NameDependency_When_EvidenceMissing'

    $depBlankEvidence = New-DependencyRepo 'dep-evidence-blank' (Complete-UnitPlanText (New-UnitPlanText -Unit 'US01' -StepOneStatus 'COMPLETED' -StepOneEvidence ',"acceptance_evidence":"   "')) $depDependentText
    $r = Invoke-Decision $depBlankEvidence.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_evidence_missing' ([string]$r.Result.reason) 'Should_DenyDependent_When_AcceptanceEvidenceIsBlank'

    $depNormativeEdit = New-DependencyRepo 'dep-normative-edit' ($depPredecessorDone.Replace('Normative body: unit plan for the dependency self-test.', 'Normative body changed after approval.')) $depDependentText
    $r = Invoke-Decision $depNormativeEdit.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_identity_changed' ([string]$r.Result.reason) 'Should_DenyDependent_When_PredecessorNormativeTextEdited'
    Assert-Equal $depPredecessorPath ([string]$r.Result.dependency) 'Should_NameDependency_When_PredecessorIdentityChanged'

    $depOperationalText = $depPredecessorDone.Replace('"cadence":"continuous"', '"cadence":"continuous","current_stage":"implementation"').Replace('"id":"US01-S2","status":"PENDING"', '"id":"US01-S2","status":"COMPLETED"')
    Assert-Equal 'False' ([string]($depOperationalText -ceq $depPredecessorDone)) 'Should_ChangeFixture_When_PredecessorOperationalBlocksEdited'
    $depOperational = New-DependencyRepo 'dep-operational-edit' $depOperationalText $depDependentText
    Assert-Equal $depIdentity (Get-DeliveryNormativeIdentity -Text ([System.IO.File]::ReadAllText($depOperational.Predecessor))) 'Should_KeepPredecessorIdentity_When_OperationalBlocksEdited'
    Assert-Equal (Get-DeliveryNormativeIdentity -Text $depDependentText) (Get-DeliveryNormativeIdentity -Text ([System.IO.File]::ReadAllText($depOperational.Dependent))) 'Should_KeepDependentIdentity_When_PredecessorOperationalBlocksEdited'
    $r = Invoke-Decision $depOperational.Dependent -ContinuousAuth
    Assert-Equal 'True' ([string]$r.Result.allowed) 'Should_AllowDependent_When_PredecessorOperationalBlocksEdited'
    Assert-Equal 'US02-S1' ([string]$r.Result.step) 'Should_SelectSameStep_When_PredecessorOperationalBlocksEdited'

    $depApprovalPending = New-DependencyRepo 'dep-approval-pending' (Complete-UnitPlanText (New-UnitPlanText -Unit 'US01' -StepOneStatus 'COMPLETED' -StepOneEvidence $depEvidence -ApprovalState 'pending')) $depDependentText
    $r = Invoke-Decision $depApprovalPending.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_not_approved' ([string]$r.Result.reason) 'Should_DenyDependent_When_PredecessorApprovalPending'
    Assert-Equal $depPredecessorPath ([string]$r.Result.dependency) 'Should_NameDependency_When_PredecessorNotApproved'

    $depStaleApproval = $depPredecessorDone.Replace('"identity":"' + $depIdentity + '"', '"identity":"' + ('F' * 64) + '"')
    Assert-Equal 'False' ([string]($depStaleApproval -ceq $depPredecessorDone)) 'Should_ChangeFixture_When_PredecessorApprovalIdentityReplaced'
    $depStale = New-DependencyRepo 'dep-approval-stale' $depStaleApproval $depDependentText
    $r = Invoke-Decision $depStale.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_not_approved' ([string]$r.Result.reason) 'Should_DenyDependent_When_PredecessorApprovalIdentityIsStale'

    $depMissing = New-DependencyRepo 'dep-missing' $depPredecessorDone $depDependentText
    Remove-Item -LiteralPath $depMissing.Predecessor -Force
    $r = Invoke-Decision $depMissing.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_missing' ([string]$r.Result.reason) 'Should_DenyDependent_When_PredecessorFileMissing'
    Assert-Equal $depPredecessorPath ([string]$r.Result.dependency) 'Should_NameDependency_When_PredecessorMissing'

    $depMalformedRequires = 'Requires plan: ' + $depPredecessorPath + ' identity=' + $depIdentity.ToLowerInvariant() + ' steps=US01-S1'
    $depMalformed = New-DependencyRepo 'dep-malformed-line' $depPredecessorDone (Complete-UnitPlanText (New-UnitPlanText -Unit 'US02' -DependencyLines @($depMalformedRequires)))
    $r = Invoke-Decision $depMalformed.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_invalid' ([string]$r.Result.reason) 'Should_DenyDependent_When_RequiresLineMalformed'

    $depSelfRequires = 'Requires plan: features/001-demo/US02/PLAN.md identity=' + ('E' * 64) + ' steps=US02-S1'
    $depSelf = New-DependencyRepo 'dep-self' $depPredecessorDone (Complete-UnitPlanText (New-UnitPlanText -Unit 'US02' -DependencyLines @($depSelfRequires)))
    $r = Invoke-Decision $depSelf.Dependent -ContinuousAuth
    Assert-Equal 'False' ([string]$r.Result.allowed) 'Should_DenyDependent_When_DependencyPointsAtItself'
    Assert-Equal 'features/001-demo/US02/PLAN.md' ([string]$r.Result.dependency) 'Should_NameSelfDependency_When_DependencyPointsAtItself'

    $depStrayText = (New-UnitPlanText -Unit 'US02').Replace('## Steps' + "`n", 'Requires plan: ' + $depPredecessorPath + ' identity=' + $depIdentity + ' steps=US01-S1' + "`n`n" + '## Steps' + "`n")
    $depStray = New-DependencyRepo 'dep-stray-line' $depPredecessorDone (Complete-UnitPlanText $depStrayText)
    $r = Invoke-Decision $depStray.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_invalid' ([string]$r.Result.reason) 'Should_DenyDependent_When_RequiresLineOutsideHeading'

    $depTwoSteps = 'Requires plan: ' + $depPredecessorPath + ' identity=' + $depIdentity + ' steps=US01-S1,US01-S2'
    $depMulti = New-DependencyRepo 'dep-multi-step' $depPredecessorDone (Complete-UnitPlanText (New-UnitPlanText -Unit 'US02' -DependencyLines @($depTwoSteps)))
    $r = Invoke-Decision $depMulti.Dependent -ContinuousAuth
    Assert-Equal 'plan_dependency_step_incomplete' ([string]$r.Result.reason) 'Should_DenyDependent_When_AnyListedStepIncomplete'

    Write-Output ('PASS: {0} focused execution and resume assertions on PowerShell {1}.' -f $passed, $PSVersionTable.PSVersion)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
