#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$cli = @{
    Preflight  = Join-Path $scriptsRoot 'runtime/Test-DeliveryPlanPreflight.ps1'
    NewRecord  = Join-Path $scriptsRoot 'runtime/New-DeliveryReviewRecord.ps1'
    SaveRecord = Join-Path $scriptsRoot 'runtime/Write-DeliveryReviewRecord.ps1'
    TestRecord = Join-Path $scriptsRoot 'runtime/Test-DeliveryReviewRecord.ps1'
    Evidence   = Join-Path $scriptsRoot 'runtime/Invoke-DeliveryEvidence.ps1'
    Resolver   = Join-Path $scriptsRoot 'ledger/Resolve-DeliveryExecution.ps1'
    Setter     = Join-Path $scriptsRoot 'ledger/Set-DeliveryExecutionBlock.ps1'
}
. (Join-Path $scriptsRoot '_lib/DeliveryGrammar.ps1')
. (Join-Path $scriptsRoot '_lib/DeliveryReviewRecord.ps1')

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-end-to-end-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$utf8 = [System.Text.UTF8Encoding]::new($false)
$passed = 0

$planRelative = 'features/900-e2e/US01/PLAN.md'
$refinementRelative = 'features/900-e2e/REFINEMENT.md'
$draftRelative = 'features/900-e2e/scratch/delivery-review/US01-plan-draft.json'
$recordRelative = 'features/900-e2e/delivery-reviews/US01-plan.json'
$baselineRelative = 'features/900-e2e/US01/evidence/US01-S1--baseline.txt'
$resultRelative = 'features/900-e2e/US01/evidence/US01-S1--result.txt'
$baselineContent = 'synthetic baseline content'
$resultContent = 'synthetic result content'
$pendingApproval = '{"schema":"delivery-approval/v1","state":"pending"}'
$gitCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null}'
$directoryCheckpoint = '{"schema":"delivery-checkpoint/v1","branch":"","head":"","active_step":null,"location_kind":"directory","baseline_evidence":"US01-S1/baseline"}'
$progressPayload = '{"schema":"delivery-progress/v1","cadence":"step_by_step"}'
$step2Pending = '{"schema":"delivery-step/v1","id":"US01-S2","status":"PENDING","depends_on":["US01-S1"]}'

$readerJson = '{"paraphrases":{"proposal":"Synthetic proposal paraphrase.","current_system":"Synthetic current system paraphrase."},"lenses":["scope","sequencing"],"findings":[{"id":"R1-001","severity":"MINOR","category":"GAP","section":"Steps","evidence":"Synthetic wording note.","recommendation":"Reword the validation line."}]}'
$criticJson = '{"lenses":["risk"],"findings":[]}'
$inputsJson = '[{"id":"refinement","path":"features/900-e2e/REFINEMENT.md","role":"normative_source","impacted_ids":["US01-S1","US01-S2"]}]'
$dispositionsJson = '[{"id":"R1-001","disposition":"accepted_minor","reason":"Synthetic minor finding accepted without change."}]'

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Assert-ExitCode([int]$Expected, $Run, [string]$Name) {
    if ([string]$Expected -cne [string]$Run.ExitCode) {
        throw ('{0}: expected exit {1}, got {2}; stdout: {3}; stderr: {4}' -f $Name, $Expected, $Run.ExitCode, $Run.Stdout.Trim(), $Run.Stderr.Trim())
    }
    $script:passed++
}

function Assert-Field($Run, [string]$Field, [string]$Expected, [string]$Name) {
    Assert-Equal $Expected ([string](Get-Prop $Run.Result $Field)) $Name
}

function Assert-Issue($Run, [string]$Code, [string]$Name) {
    $codes = Get-IssueCodes $Run
    if ($codes -cnotcontains $Code) { throw ('{0}: expected issue {1}, got [{2}]' -f $Name, $Code, ($codes -join ', ')) }
    $script:passed++
}

function Get-Prop($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-IssueCodes($Run) {
    return @(@(Get-Prop $Run.Result 'issues') | ForEach-Object { [string](Get-Prop $_ 'code') })
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-Cli {
    param(
        [Parameter(Mandatory = $true)][string] $Script,
        [string[]] $Arguments = @()
    )

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script) + $Arguments
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $childHost
    $startInfo.Arguments = (@($argList | ForEach-Object { ConvertTo-ProcessArgument ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $process.StandardInput.Close()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(5000)) {
        try { $process.Kill($true) } catch { }
        [void]$process.WaitForExit(2000)
        throw "End-to-end child script exceeded its 5-second limit: $Script"
    }
    $stdoutText = $stdoutTask.Result
    $stderrText = $stderrTask.Result

    $parsed = $null
    if (-not [string]::IsNullOrWhiteSpace($stdoutText)) {
        try { $parsed = $stdoutText.Trim() | ConvertFrom-Json } catch { $parsed = $null }
    }
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Result = $parsed; Stdout = $stdoutText; Stderr = $stderrText }
}

function Get-RepoPath([string]$Repo, [string]$Relative) {
    return [System.IO.Path]::GetFullPath((Join-Path $Repo $Relative))
}

function Write-RepoFile([string]$Repo, [string]$Relative, [string]$Text) {
    $path = Get-RepoPath $Repo $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [System.IO.File]::WriteAllText($path, $Text, $utf8)
}

function Read-RepoText([string]$Repo, [string]$Relative) {
    return [System.IO.File]::ReadAllText((Get-RepoPath $Repo $Relative))
}

function Edit-File([string]$Path, [string]$Old, [string]$New) {
    $text = [System.IO.File]::ReadAllText($Path)
    if (-not $text.Contains($Old)) { throw "Fixture edit target not found in $Path" }
    [System.IO.File]::WriteAllText($Path, $text.Replace($Old, $New), $utf8)
}

function Get-FileBase64([string]$Path) {
    return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

function Get-Sha256Upper([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Copy-State([string]$Source, [string]$Name) {
    $destination = Join-Path $tempRoot $Name
    Copy-Item -LiteralPath $Source -Destination $destination -Recurse -Force
    return $destination
}

function Get-BlockHashFromFile([string]$Path, [string]$Block) {
    $type = $Block
    $id = ''
    if ($Block.StartsWith('STEP:', [System.StringComparison]::Ordinal)) {
        $type = 'STEP'
        $id = $Block.Substring('STEP:'.Length)
    }
    $parsed = Read-DeliveryBlocks -Text ([System.IO.File]::ReadAllText($Path))
    $found = @($parsed.Blocks | Where-Object { ($_.Type -ceq $type) -and (([string]$_.Id) -ceq $id) })
    if ($found.Count -ne 1) { throw "Block $Block is not present exactly once in $Path" }
    return (Get-DeliveryBlockHash -Payload $found[0].Payload)
}

function Add-ReviewBinding([string]$Plan) {
    $text = [System.IO.File]::ReadAllText($Plan)
    $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Plan)))
    $repoPrefix = $repoRoot.TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar, [char] [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    $relative = $Plan.Substring($repoPrefix.Length).Replace('\', '/')
    $contentSha = Get-DeliveryNormativeIdentity -Text $text
    $inputs = @()
    $inputIdentity = Get-DeliveryMaterialInputIdentity -Inputs $inputs
    $record = [ordered]@{
        schema = 'delivery-review-record/v2'; state = 'reviewed'
        target = [ordered]@{ path = $relative; kind = 'PLAN.md'; stage = 'delivery_unit_plan_review'; content_sha256 = $contentSha; review_identity = ('0' * 64) }
        material_input_identity = $inputIdentity; inputs = @()
        reviewers = [ordered]@{
            reader = [ordered]@{ host = 'synthetic'; observed_isolation = 'synthetic'; result = [ordered]@{ paraphrases = [ordered]@{ proposal = 'A bounded plan.'; current_system = 'A declared baseline.' }; lenses = @('comprehension'); findings = @() } }
            critic = [ordered]@{ host = 'synthetic'; observed_isolation = 'synthetic'; result = [ordered]@{ lenses = @('scope'); findings = @() } }
        }
        dispositions = @(); provenance = [ordered]@{}; round = 1
    }
    $record.target.review_identity = Get-DeliveryReviewRecordBindingIdentity -Record ($record | ConvertTo-Json -Depth 30 | ConvertFrom-Json) -MaterialInputIdentity $inputIdentity
    Assert-DeliveryReviewRecordShape -Value ($record | ConvertTo-Json -Depth 30 | ConvertFrom-Json)
    $recordPath = Join-Path (Split-Path -Parent (Split-Path -Parent $Plan)) ('delivery-reviews/' + (Split-Path -Leaf (Split-Path -Parent $Plan)) + '-plan.json')
    New-Item -ItemType Directory -Path (Split-Path -Parent $recordPath) -Force | Out-Null
    [System.IO.File]::WriteAllText($recordPath, ($record | ConvertTo-Json -Depth 30), $utf8)
    $approvalMatch = [regex]::Match($text, '(?s)(<!-- DELIVERY:APPROVAL:BEGIN -->\r?\n)(.*?)(\r?\n<!-- DELIVERY:APPROVAL:END -->)')
    if (-not $approvalMatch.Success) { throw 'Fixture approval block missing.' }
    $approval = $approvalMatch.Groups[2].Value | ConvertFrom-Json
    $approval | Add-Member -NotePropertyName input_identity -NotePropertyValue $inputIdentity -Force
    $approval | Add-Member -NotePropertyName review_identity -NotePropertyValue $record.target.review_identity -Force
    $updated = $approvalMatch.Groups[1].Value + ($approval | ConvertTo-Json -Compress -Depth 20) + $approvalMatch.Groups[3].Value
    $text = $text.Substring(0, $approvalMatch.Index) + $updated + $text.Substring($approvalMatch.Index + $approvalMatch.Length)
    [System.IO.File]::WriteAllText($Plan, $text, $utf8)
    return $inputIdentity
}

function Invoke-Setter([string]$Repo, [string]$PlanFull, [string]$Block, [string]$Payload) {
    $hash = Get-BlockHashFromFile -Path $PlanFull -Block $Block
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $setterArguments = @{
            RepoPath = $Repo
            PlanPath = $PlanFull
            Block = $Block
            ExpectedBlockHash = $hash
            PayloadJson = $Payload
            AsLibrary = $true
        }
        try {
            $result = & $cli.Setter @setterArguments
            return [pscustomobject]@{ ExitCode = [int](-not [bool]$result.ok); Result = $result; Stdout = ($result | ConvertTo-Json -Compress); Stderr = '' }
        }
        catch {
            return [pscustomobject]@{ ExitCode = 1; Result = $null; Stdout = ''; Stderr = $_.Exception.Message }
        }
    }
    return Invoke-Cli -Script $cli.Setter -Arguments @(
        '-RepoPath', $Repo, '-PlanPath', $PlanFull, '-Block', $Block,
        '-ExpectedBlockHash', $hash, '-PayloadJson', $Payload)
}

function Invoke-Preflight([string]$Repo, [string[]]$Extra = @()) {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $arguments = @{ RepoPath = $Repo; PlanPath = $planRelative; AsLibrary = $true }
        for ($index = 0; $index -lt $Extra.Count; $index++) {
            $key = ([string]$Extra[$index]).TrimStart('-')
            if (($index + 1 -lt $Extra.Count) -and -not ([string]$Extra[$index + 1]).StartsWith('-')) {
                $arguments[$key] = $Extra[$index + 1]
                $index++
            }
            else { $arguments[$key] = $true }
        }
        $result = & $cli.Preflight @arguments
        $exitCode = if ($result.ok) { 0 } else { 3 }
        return [pscustomobject]@{ ExitCode = $exitCode; Result = $result; Stdout = ($result | ConvertTo-Json -Compress -Depth 5); Stderr = '' }
    }
    return Invoke-Cli -Script $cli.Preflight -Arguments (@('-RepoPath', $Repo, '-PlanPath', $planRelative) + $Extra)
}

function Invoke-Resolver([string]$PlanFull, [string]$InputIdentity, [string]$ReviewRecordPath = '') {
    if ([string]::IsNullOrWhiteSpace($ReviewRecordPath)) {
        $unit = Split-Path -Leaf (Split-Path -Parent $PlanFull)
        $feature = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $PlanFull))
        $ReviewRecordPath = 'features/{0}/delivery-reviews/{1}-plan.json' -f $feature, $unit
    }
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $resolverArguments = @{
            PlanPath = $PlanFull
            ReviewRecordPath = $ReviewRecordPath
            Cadence = 'step_by_step'
            CurrentInputIdentity = $InputIdentity
            CurrentBranch = ''
            CurrentHead = ''
            StepAuthorization = $true
            AsLibrary = $true
        }
        $result = & $cli.Resolver @resolverArguments
        return [pscustomobject]@{ ExitCode = $result.ExitCode; Result = $result.Result; Stdout = ($result.Result | ConvertTo-Json -Compress); Stderr = '' }
    }
    return Invoke-Cli -Script $cli.Resolver -Arguments @(
        '-PlanPath', $PlanFull, '-ReviewRecordPath', $ReviewRecordPath, '-Cadence', 'step_by_step', '-CurrentInputIdentity', $InputIdentity,
        '-CurrentBranch', '', '-CurrentHead', '', '-StepAuthorization')
}

function New-ProgressPayload([string]$PlanIdentity, [string[]]$StepIds, [string]$Stage = '') {
    $fields = @{ schema = 'delivery-progress/v1'; cadence = 'step_by_step' }
    if ($Stage.Length -gt 0) { $fields['current_stage'] = $Stage }
    $fields['authorization'] = @{
        kind          = 'step'
        scope         = 'step_by_step'
        granted_utc   = '2026-11-11T12:00:00Z'
        plan_identity = $PlanIdentity
        step_ids      = @($StepIds)
    }
    return (ConvertTo-Json -InputObject $fields -Compress -Depth 10)
}

function Set-StepAuthorization([string]$Repo, [string]$PlanFull, [string[]]$StepIds, [string]$PlanIdentity = '') {
    $bound = $PlanIdentity
    if ($bound.Length -eq 0) {
        $preflight = Invoke-Preflight $Repo
        $bound = [string](Get-Prop $preflight.Result 'identity')
    }
    $run = Invoke-Setter $Repo $PlanFull 'PROGRESS' (New-ProgressPayload $bound $StepIds)
    Assert-ExitCode 0 $run 'Should_ExitZero_When_StepAuthorizationRecorded'
    return $run
}

function Invoke-EvidenceWrite([string]$Repo, [string]$Name, [string]$Content) {
    return Invoke-Cli -Script $cli.Evidence -Arguments @(
        '-Action', 'write', '-RepoPath', $Repo, '-PlanPath', $planRelative,
        '-Step', 'US01-S1', '-Name', $Name, '-Content', $Content, '-Extension', 'txt')
}

function Invoke-EvidenceVerify([string]$Repo, [string]$Name, [string]$ExpectedSha) {
    $arguments = @('-Action', 'verify', '-RepoPath', $Repo, '-PlanPath', $planRelative,
        '-Step', 'US01-S1', '-Name', $Name)
    if ($ExpectedSha.Length -gt 0) { $arguments += @('-ExpectedSha256', $ExpectedSha) }
    return Invoke-Cli -Script $cli.Evidence -Arguments $arguments
}

function New-RefinementText {
    return (@(
        '# Refinement 900', '',
        'Normative body: synthetic refinement for the delivery end-to-end self-test.', '',
        '<!-- DELIVERY:APPROVAL:BEGIN -->', $pendingApproval, '<!-- DELIVERY:APPROVAL:END -->', ''
    ) -join "`n") + "`n"
}

function New-PlanText {
    $lines = @(
        '# US01 plan', '',
        'Normative body: synthetic unit plan for the delivery end-to-end self-test.', '',
        '## Steps', '',
        '### US01-S1 Produce evidence',
        'Depends on: none',
        'Evidence: baseline, result',
        'Validation: synthetic check one', '',
        '### US01-S2 Consume evidence',
        'Depends on: US01-S1',
        'Needs evidence: US01-S1/result',
        'Validation: synthetic check two', '',
        '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressPayload, '<!-- DELIVERY:PROGRESS:END -->',
        '<!-- DELIVERY:CHECKPOINT:BEGIN -->', $gitCheckpoint, '<!-- DELIVERY:CHECKPOINT:END -->',
        '<!-- DELIVERY:APPROVAL:BEGIN -->', $pendingApproval, '<!-- DELIVERY:APPROVAL:END -->',
        '<!-- DELIVERY:STEP:US01-S1:BEGIN -->', '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[]}', '<!-- DELIVERY:STEP:US01-S1:END -->',
        '<!-- DELIVERY:STEP:US01-S2:BEGIN -->', $step2Pending, '<!-- DELIVERY:STEP:US01-S2:END -->'
    )
    return (($lines -join "`n") + "`n")
}

function New-StepPayload([string]$Id, [string]$Status, [string]$DependsJson, [string]$RefsJson = '') {
    $refs = ''
    if ($RefsJson.Length -gt 0) { $refs = ',"evidence_refs":' + $RefsJson }
    return '{"schema":"delivery-step/v1","id":"' + $Id + '","status":"' + $Status + '","depends_on":' + $DependsJson + $refs + '}'
}

function New-CompletedEvidenceStepPayload([string]$Id, [string]$RefsJson) {
    return '{"schema":"delivery-step/v1","id":"' + $Id + '","status":"COMPLETED","depends_on":[],"evidence_refs":' + $RefsJson + ',"acceptance_evidence":["synthetic acceptance recorded"],"validation_results":[{"command":"synthetic check one","result":"passed","exit_code":0}]}'
}

function New-RefJson([string]$Name, [string]$Path, [string]$Sha) {
    return '{"name":"' + $Name + '","path":"' + $Path + '","sha256":"' + $Sha + '"}'
}

function New-ChainUnitText {
    param(
        [Parameter(Mandatory = $true)][string] $Unit,
        [string[]] $DependencyLines = @()
    )

    $lines = @('# Chained unit plan', '', 'Normative body: synthetic chained unit plan.', '')
    if ($DependencyLines.Count -gt 0) { $lines += @('## Plan dependencies', '') + $DependencyLines + '' }
    $lines += @('## Steps', '', ('### {0}-S1 First step' -f $Unit), 'Depends on: none', 'Validation: synthetic check one', '',
        ('### {0}-S2 Second step' -f $Unit), ('Depends on: {0}-S1' -f $Unit), 'Validation: synthetic check two', '')
    $stepOne = '{"schema":"delivery-step/v1","id":"' + $Unit + '-S1","status":"PENDING","depends_on":[]}'
    $stepTwo = '{"schema":"delivery-step/v1","id":"' + $Unit + '-S2","status":"PENDING","depends_on":["' + $Unit + '-S1"]}'
    $lines += @(
        '<!-- DELIVERY:PROGRESS:BEGIN -->', $progressPayload, '<!-- DELIVERY:PROGRESS:END -->',
        '<!-- DELIVERY:CHECKPOINT:BEGIN -->', $gitCheckpoint, '<!-- DELIVERY:CHECKPOINT:END -->',
        '<!-- DELIVERY:APPROVAL:BEGIN -->', '{"schema":"delivery-approval/v1","state":"approved","identity":"@@IDENTITY@@","input_identity":"INPUT-1","review_state":"reviewed"}', '<!-- DELIVERY:APPROVAL:END -->',
        ('<!-- DELIVERY:STEP:{0}-S1:BEGIN -->' -f $Unit), $stepOne, ('<!-- DELIVERY:STEP:{0}-S1:END -->' -f $Unit),
        ('<!-- DELIVERY:STEP:{0}-S2:BEGIN -->' -f $Unit), $stepTwo, ('<!-- DELIVERY:STEP:{0}-S2:END -->' -f $Unit))
    $text = (($lines -join "`n") + "`n")
    return $text.Replace('@@IDENTITY@@', (Get-DeliveryNormativeIdentity -Text $text))
}

try {
    # Scenario A: directory unit, lifecycle through the public CLIs.
    $repoA = Join-Path $tempRoot 'scenario-a'
    New-Item -ItemType Directory -Path (Get-RepoPath $repoA 'features/900-e2e/scratch/delivery-review') -Force | Out-Null
    Write-RepoFile $repoA $refinementRelative (New-RefinementText)
    Write-RepoFile $repoA $planRelative (New-PlanText)
    $planA = Get-RepoPath $repoA $planRelative
    $refinementA = Get-RepoPath $repoA $refinementRelative
    $recordA = Get-RepoPath $repoA $recordRelative

    # A2: fresh plan preflight.
    $preflightFresh = Invoke-Preflight $repoA
    Assert-ExitCode 0 $preflightFresh 'Should_ExitZero_When_FreshPlanPreflight'
    Assert-Field $preflightFresh 'ok' 'True' 'Should_ReturnOk_When_FreshPlanPreflight'
    $identity = [string](Get-Prop $preflightFresh.Result 'identity')
    Assert-True ($identity -cmatch '^[0-9A-F]{64}$') 'Should_ReturnIdentity_When_FreshPlanPreflight'

    # A3: synthetic review, record save, record check, preflight with the review gate.
    $reviewDir = Get-RepoPath $repoA 'features/900-e2e/scratch/delivery-review'
    $readerPath = Join-Path $reviewDir 'reader.json'
    $criticPath = Join-Path $reviewDir 'critic.json'
    $inputsPath = Join-Path $reviewDir 'inputs.json'
    $dispositionsPath = Join-Path $reviewDir 'dispositions.json'
    [System.IO.File]::WriteAllText($readerPath, $readerJson, $utf8)
    [System.IO.File]::WriteAllText($criticPath, $criticJson, $utf8)
    [System.IO.File]::WriteAllText($inputsPath, $inputsJson, $utf8)
    [System.IO.File]::WriteAllText($dispositionsPath, $dispositionsJson, $utf8)

    $newRun = Invoke-Cli -Script $cli.NewRecord -Arguments @(
        '-State', 'reviewed', '-RepoPath', $repoA,
        '-ReaderResultPath', $readerPath, '-CriticResultPath', $criticPath,
        '-ReaderHost', 'synthetic', '-ReaderIsolation', 'synthetic',
        '-CriticHost', 'synthetic', '-CriticIsolation', 'synthetic',
        '-InputsPath', $inputsPath, '-DispositionsPath', $dispositionsPath,
        '-OutPath', $draftRelative)
    Assert-ExitCode 0 $newRun 'Should_ExitZero_When_ReviewDraftBuilt'
    Assert-Field $newRun 'ok' 'True' 'Should_ReturnOk_When_ReviewDraftComplete'

    $draftText = Read-RepoText $repoA $draftRelative
    $saveRun = Invoke-Cli -Script $cli.SaveRecord -Arguments @(
        '-Action', 'save', '-RepoPath', $repoA, '-TargetPath', $planRelative,
        '-TargetKind', 'PLAN.md', '-Stage', 'delivery_unit_plan_review',
        '-ArtifactText', (Read-RepoText $repoA $planRelative),
        '-RecordPath', $recordA, '-RecordJson', $draftText)
    Assert-ExitCode 0 $saveRun 'Should_ExitZero_When_ReviewRecordSaved'
    Assert-Field $saveRun 'status' 'saved' 'Should_ReturnSaved_When_ReviewRecordSaved'
    $reviewIdentity = [string](Get-Prop $saveRun.Result 'review_identity')
    Assert-True ($reviewIdentity -cmatch '^[0-9A-F]{64}$') 'Should_ReturnReviewIdentity_When_ReviewRecordSaved'

    $checkRun = Invoke-Cli -Script $cli.TestRecord -Arguments @('-RepoPath', $repoA, '-TargetPath', $planRelative, '-RecordPath', $recordA)
    Assert-ExitCode 0 $checkRun 'Should_ExitZero_When_ReviewRecordAllowed'
    Assert-Field $checkRun 'allowed' 'True' 'Should_Allow_When_ReviewRecordReviewed'
    Assert-Field $checkRun 'reason' 'reviewed' 'Should_ReturnReasonReviewed_When_ReviewRecordReviewed'

    $stateReviewed = Copy-State $repoA 'state-reviewed'

    # A4: approve through the setter, then confirm the expected identity.
    $inputIdentity = [string](Get-Prop (Get-Prop $checkRun.Result 'identity') 'material_input_identity')
    $approvalPayload = '{"schema":"delivery-approval/v1","state":"approved","identity":"' + $identity +
        '","input_identity":"' + $inputIdentity + '","review_state":"reviewed","review_identity":"' + $reviewIdentity +
        '","blocking_findings":[],"unresolved_decisions":[],"approved_utc":"2026-11-11T12:00:00Z"}'
    $approveRun = Invoke-Setter $repoA $planA 'APPROVAL' $approvalPayload
    Assert-ExitCode 0 $approveRun 'Should_ExitZero_When_ApprovalWritten'
    Assert-Field $approveRun 'code' 'written_and_verified' 'Should_ReturnWrittenAndVerified_When_ApprovalWritten'

    $approvedPreflight = Invoke-Preflight $repoA @('-ExpectedIdentity', $identity)
    Assert-ExitCode 0 $approvedPreflight 'Should_ExitZero_When_ApprovedPlanMatchesExpectedIdentity'
    Assert-Field $approvedPreflight 'ok' 'True' 'Should_ReturnOk_When_ApprovedPlanMatchesExpectedIdentity'

    $gatedPreflight = Invoke-Preflight $repoA @('-ExpectedIdentity', $identity, '-ReviewRecordPath', $recordA)
    Assert-ExitCode 0 $gatedPreflight 'Should_ExitZero_When_ReviewGateAndApprovalBindingsMatch'
    Assert-Field $gatedPreflight 'ok' 'True' 'Should_ReturnOk_When_ReviewGateAndApprovalBindingsMatch'

    $stateApproved = Copy-State $repoA 'state-approved'

    # A5: two directory evidence files, step evidence references, directory checkpoint.
    $baselineRun = Invoke-EvidenceWrite $repoA 'baseline' $baselineContent
    Assert-ExitCode 0 $baselineRun 'Should_ExitZero_When_BaselineEvidenceWritten'
    Assert-Field $baselineRun 'path' $baselineRelative 'Should_ReturnBaselinePath_When_BaselineEvidenceWritten'
    $baselineSha = [string](Get-Prop $baselineRun.Result 'sha256')

    $resultRun = Invoke-EvidenceWrite $repoA 'result' $resultContent
    Assert-ExitCode 0 $resultRun 'Should_ExitZero_When_ResultEvidenceWritten'
    Assert-Field $resultRun 'path' $resultRelative 'Should_ReturnResultPath_When_ResultEvidenceWritten'
    $resultSha = [string](Get-Prop $resultRun.Result 'sha256')

    $verifyRun = Invoke-EvidenceVerify $repoA 'result' $resultSha
    Assert-ExitCode 0 $verifyRun 'Should_ExitZero_When_ResultEvidenceVerified'

    $refs = '[' + (New-RefJson 'baseline' $baselineRelative $baselineSha) + ',' + (New-RefJson 'result' $resultRelative $resultSha) + ']'
    $step1Run = Invoke-Setter $repoA $planA 'STEP:US01-S1' (New-StepPayload 'US01-S1' 'PENDING' '[]' $refs)
    Assert-ExitCode 0 $step1Run 'Should_ExitZero_When_EvidenceReferencesRecorded'
    $checkpointRun = Invoke-Setter $repoA $planA 'CHECKPOINT' $directoryCheckpoint
    Assert-ExitCode 0 $checkpointRun 'Should_ExitZero_When_DirectoryCheckpointWritten'

    $baselinePreflight = Invoke-Preflight $repoA
    Assert-ExitCode 0 $baselinePreflight 'Should_ExitZero_When_DirectoryBaselineRecorded'
    Assert-Field $baselinePreflight 'identity' $identity 'Should_KeepIdentity_When_OperationalBlocksWritten'

    $stateBaseline = Copy-State $repoA 'state-baseline'

    # A6: resolver eligibility, completion, and dependent eligibility.
    $null = Set-StepAuthorization $repoA $planA @('US01-S1')
    $firstDecision = Invoke-Resolver $planA $inputIdentity
    Assert-ExitCode 0 $firstDecision 'Should_ExitZero_When_FirstStepEligible'
    Assert-Field $firstDecision 'step' 'US01-S1' 'Should_SelectFirstStep_When_NothingCompleted'

    $completePayload = '{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","depends_on":[],"evidence_refs":' + $refs + ',"acceptance_evidence":["synthetic acceptance recorded"],"validation_results":[{"command":"synthetic check one","result":"passed","exit_code":0}]}'
    $completeRun = Invoke-Setter $repoA $planA 'STEP:US01-S1' $completePayload
    Assert-ExitCode 0 $completeRun 'Should_ExitZero_When_FirstStepCompleted'

    $null = Set-StepAuthorization $repoA $planA @('US01-S2')
    $secondDecision = Invoke-Resolver $planA $inputIdentity
    Assert-ExitCode 0 $secondDecision 'Should_ExitZero_When_DependentStepEligible'
    Assert-Field $secondDecision 'step' 'US01-S2' 'Should_SelectDependentStep_When_EvidenceSatisfied'

    $stateDone = Copy-State $repoA 'state-done'

    # Scenario B: one defect per copy of the state named in its header.
    $repoB1 = Copy-State $stateApproved 'b1-normative-edit'
    $planB1 = Get-RepoPath $repoB1 $planRelative
    $null = Set-StepAuthorization $repoB1 $planB1 @('US01-S1')
    Edit-File $planB1 'Validation: synthetic check one' 'Validation: changed check one'
    $b1Resolver = Invoke-Resolver $planB1 $inputIdentity
    Assert-ExitCode 1 $b1Resolver 'Should_ExitOne_When_NormativeTextEditedAfterApproval'
    Assert-Field $b1Resolver 'reason' 'review_gate_identity_stale' 'Should_ReturnReviewGateIdentityStale_When_NormativeTextEditedAfterApproval'
    $b1Preflight = Invoke-Preflight $repoB1 @('-ExpectedIdentity', $identity)
    Assert-ExitCode 3 $b1Preflight 'Should_ExitThree_When_NormativeTextEditedAfterApproval'
    Assert-Issue $b1Preflight 'identity_changed' 'Should_ReturnIdentityChanged_When_NormativeTextEditedAfterApproval'

    $repoB2 = Copy-State $stateApproved 'b2-legacy-marker'
    $planB2 = Get-RepoPath $repoB2 $planRelative
    $null = Set-StepAuthorization $repoB2 $planB2 @('US01-S1')
    Edit-File $planB2 '<!-- DELIVERY:STEP:US01-S1:BEGIN -->' '<!-- DELIVERY:STEP-US01-S1:BEGIN -->'
    $b2Resolver = Invoke-Resolver $planB2 $inputIdentity
    Assert-ExitCode 1 $b2Resolver 'Should_ExitOne_When_LegacyStepMarkerPresent'
    Assert-Field $b2Resolver 'reason' 'legacy_marker' 'Should_ReturnLegacyMarker_When_LegacyStepMarkerPresent'
    $b2Preflight = Invoke-Preflight $repoB2
    Assert-ExitCode 3 $b2Preflight 'Should_ExitThree_When_LegacyStepMarkerPresent'
    Assert-Issue $b2Preflight 'grammar_invalid' 'Should_ReturnGrammarInvalid_When_LegacyStepMarkerPresent'

    $repoB3 = Copy-State $stateBaseline 'b3-baseline-edit'
    $planB3 = Get-RepoPath $repoB3 $planRelative
    $null = Set-StepAuthorization $repoB3 $planB3 @('US01-S1')
    [System.IO.File]::WriteAllText((Get-RepoPath $repoB3 $baselineRelative), 'tampered baseline content', $utf8)
    $b3Resolver = Invoke-Resolver $planB3 $inputIdentity
    Assert-ExitCode 1 $b3Resolver 'Should_ExitOne_When_BaselineEvidenceEditedAfterRecording'
    Assert-Field $b3Resolver 'reason' 'baseline_changed' 'Should_ReturnBaselineChanged_When_BaselineEvidenceEditedAfterRecording'

    $repoB4 = Copy-State $stateReviewed 'b4-record-deleted'
    Remove-Item -LiteralPath (Get-RepoPath $repoB4 $recordRelative) -Force
    $b4Check = Invoke-Cli -Script $cli.TestRecord -Arguments @('-RepoPath', $repoB4, '-TargetPath', $planRelative, '-RecordPath', (Get-RepoPath $repoB4 $recordRelative))
    Assert-ExitCode 3 $b4Check 'Should_ExitThree_When_ReviewRecordDeleted'
    Assert-Field $b4Check 'reason' 'record_missing' 'Should_ReturnRecordMissing_When_ReviewRecordDeleted'

    $repoB5 = Copy-State $stateReviewed 'b5-input-edit'
    Edit-File (Get-RepoPath $repoB5 $refinementRelative) 'Normative body:' ('Changed after review.' + "`n" + 'Normative body:')
    $b5Check = Invoke-Cli -Script $cli.TestRecord -Arguments @('-RepoPath', $repoB5, '-TargetPath', $planRelative, '-RecordPath', (Get-RepoPath $repoB5 $recordRelative))
    Assert-ExitCode 3 $b5Check 'Should_ExitThree_When_DeclaredInputEditedAfterRecord'
    Assert-Field $b5Check 'reason' 'inputs_changed' 'Should_ReturnInputsChanged_When_DeclaredInputEditedAfterRecord'

    $repoB6 = Copy-State $stateApproved 'b6-unknown-key'
    $planB6 = Get-RepoPath $repoB6 $planRelative
    $beforeB6 = Get-FileBase64 $planB6
    $b6Setter = Invoke-Setter $repoB6 $planB6 'STEP:US01-S1' '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[],"bogus":"x"}'
    Assert-ExitCode 1 $b6Setter 'Should_ExitOne_When_SetterPayloadHasUnknownKey'
    Assert-Field $b6Setter 'code' 'invalid_payload' 'Should_ReturnInvalidPayload_When_SetterPayloadHasUnknownKey'
    Assert-Equal 'True' ([string]((Get-FileBase64 $planB6) -ceq $beforeB6)) 'Should_LeaveFileUnchanged_When_SetterPayloadHasUnknownKey'

    $repoB7 = Copy-State $stateApproved 'b7-depends-tampered'
    $planB7 = Get-RepoPath $repoB7 $planRelative
    $b7Setter = Invoke-Setter $repoB7 $planB7 'STEP:US01-S2' '{"schema":"delivery-step/v1","id":"US01-S2","status":"PENDING","depends_on":[]}'
    Assert-ExitCode 0 $b7Setter 'Should_ExitZero_When_OperationalDependsOnRewritten'
    $b7Preflight = Invoke-Preflight $repoB7
    Assert-ExitCode 3 $b7Preflight 'Should_ExitThree_When_StepDependsOnDiffersFromDeclared'
    Assert-Issue $b7Preflight 'depends_on_mismatch' 'Should_ReturnDependsOnMismatch_When_StepDependsOnDiffersFromDeclared'

    $repoB9 = Copy-State $stateApproved 'b9-operational-edit'
    $planB9 = Get-RepoPath $repoB9 $planRelative
    $b9Setter = Invoke-Setter $repoB9 $planB9 'PROGRESS' (New-ProgressPayload $identity @('US01-S1') 'implementation')
    Assert-ExitCode 0 $b9Setter 'Should_ExitZero_When_ProgressStageWritten'
    $b9Preflight = Invoke-Preflight $repoB9 @('-ExpectedIdentity', $identity)
    Assert-ExitCode 0 $b9Preflight 'Should_ExitZero_When_OnlyOperationalBlockChanged'
    Assert-Field $b9Preflight 'identity' $identity 'Should_KeepIdentity_When_OnlyOperationalBlockChanged'
    $b9Resolver = Invoke-Resolver $planB9 $inputIdentity
    Assert-ExitCode 0 $b9Resolver 'Should_ExitZero_When_OnlyOperationalBlockChangedResolver'
    Assert-Field $b9Resolver 'step' 'US01-S1' 'Should_KeepEligibility_When_OnlyOperationalBlockChanged'

    # B10: authorization recorded against a different plan identity is denied before candidate evidence.
    $repoB10 = Copy-State $stateApproved 'b10-authorization-other-identity'
    $planB10 = Get-RepoPath $repoB10 $planRelative
    $null = Set-StepAuthorization $repoB10 $planB10 @('US01-S1') ('0' * 64)
    $b10Resolver = Invoke-Resolver $planB10 $inputIdentity
    Assert-ExitCode 1 $b10Resolver 'Should_ExitOne_When_StepAuthorizationBoundToOtherIdentity'
    Assert-Field $b10Resolver 'reason' 'authorization_identity_mismatch' 'Should_ReturnAuthorizationIdentityMismatch_When_StepAuthorizationBoundToOtherIdentity'

    # B8: the S2 evidence reference is removed after S1 completed.
    $repoB8 = Copy-State $stateDone 'b8-result-ref-removed'
    $planB8 = Get-RepoPath $repoB8 $planRelative
    $null = Set-StepAuthorization $repoB8 $planB8 @('US01-S2')
    $refsNoResult = '[' + (New-RefJson 'baseline' $baselineRelative $baselineSha) + ']'
    $b8Setter = Invoke-Setter $repoB8 $planB8 'STEP:US01-S1' (New-CompletedEvidenceStepPayload 'US01-S1' $refsNoResult)
    Assert-ExitCode 0 $b8Setter 'Should_ExitZero_When_ResultReferenceRemoved'
    $b8Resolver = Invoke-Resolver $planB8 $inputIdentity
    Assert-ExitCode 1 $b8Resolver 'Should_ExitOne_When_ResultReferenceRemoved'
    Assert-Field $b8Resolver 'reason' 'evidence_missing' 'Should_ReturnEvidenceMissing_When_ResultReferenceRemoved'
    Assert-Field $b8Resolver 'evidence' 'US01-S1/result' 'Should_NameResultReference_When_ResultReferenceRemoved'

    # B8b: the baseline reference is removed; the unit-level precondition denies every selection.
    $repoB8b = Copy-State $stateBaseline 'b8b-baseline-ref-removed'
    $planB8b = Get-RepoPath $repoB8b $planRelative
    $null = Set-StepAuthorization $repoB8b $planB8b @('US01-S1')
    $refsNoBaseline = '[' + (New-RefJson 'result' $resultRelative $resultSha) + ']'
    $b8bSetter = Invoke-Setter $repoB8b $planB8b 'STEP:US01-S1' (New-StepPayload 'US01-S1' 'PENDING' '[]' $refsNoBaseline)
    Assert-ExitCode 0 $b8bSetter 'Should_ExitZero_When_BaselineReferenceRemoved'
    $b8bFirst = Invoke-Resolver $planB8b $inputIdentity
    Assert-ExitCode 1 $b8bFirst 'Should_ExitOne_When_BaselineReferenceRemovedBeforeFirstSelection'
    Assert-Field $b8bFirst 'reason' 'baseline_missing' 'Should_ReturnBaselineMissing_When_BaselineReferenceRemovedBeforeFirstSelection'
    $b8bCompleted = Invoke-Setter $repoB8b $planB8b 'STEP:US01-S1' (New-CompletedEvidenceStepPayload 'US01-S1' $refsNoBaseline)
    Assert-ExitCode 0 $b8bCompleted 'Should_ExitZero_When_BaselineReferenceRemovedAfterCompletion'
    $null = Set-StepAuthorization $repoB8b $planB8b @('US01-S2')
    $b8bSecond = Invoke-Resolver $planB8b $inputIdentity
    Assert-ExitCode 1 $b8bSecond 'Should_ExitOne_When_BaselineReferenceRemovedAfterCompletion'
    Assert-Field $b8bSecond 'reason' 'baseline_missing' 'Should_ReturnBaselineMissing_When_BaselineReferenceRemovedAfterCompletion'

    # B8c: the result evidence file is edited after recording; S2 must be denied.
    $repoB8c = Copy-State $stateDone 'b8c-result-file-edit'
    $planB8c = Get-RepoPath $repoB8c $planRelative
    $null = Set-StepAuthorization $repoB8c $planB8c @('US01-S2')
    [System.IO.File]::WriteAllText((Get-RepoPath $repoB8c $resultRelative), 'tampered result content', $utf8)
    $b8cResolver = Invoke-Resolver $planB8c $inputIdentity
    Assert-ExitCode 1 $b8cResolver 'Should_ExitOne_When_ResultEvidenceEditedAfterRecording'
    Assert-Field $b8cResolver 'reason' 'evidence_changed' 'Should_ReturnEvidenceChanged_When_ResultEvidenceEditedAfterRecording'
    Assert-Field $b8cResolver 'evidence' 'US01-S1/result' 'Should_NameResultReference_When_ResultEvidenceEditedAfterRecording'

    # Scenario C: US02 requires US01-S1 to be COMPLETED with acceptance evidence before its own steps are eligible.
    $repoC = Join-Path $tempRoot 'scenario-c'
    New-Item -ItemType Directory -Path (Get-RepoPath $repoC 'features/900-e2e') -Force | Out-Null
    $us01CPath = 'features/900-e2e/US01/PLAN.md'
    $us02CPath = 'features/900-e2e/US02/PLAN.md'
    $us01CText = New-ChainUnitText -Unit 'US01'
    $identityC01 = Get-DeliveryNormativeIdentity -Text $us01CText
    $requiresC = 'Requires plan: ' + $us01CPath + ' identity=' + $identityC01 + ' steps=US01-S1'
    $us02CText = New-ChainUnitText -Unit 'US02' -DependencyLines @($requiresC)
    $identityC02 = Get-DeliveryNormativeIdentity -Text $us02CText
    Write-RepoFile $repoC $us01CPath $us01CText
    Write-RepoFile $repoC $us02CPath $us02CText
    $us01CPlan = Get-RepoPath $repoC $us01CPath
    $us02CPlan = Get-RepoPath $repoC $us02CPath
    $inputIdentityC01 = Add-ReviewBinding $us01CPlan
    $inputIdentityC02 = Add-ReviewBinding $us02CPlan

    $null = Set-StepAuthorization $repoC $us02CPlan @('US02-S1') $identityC02
    $c2 = Invoke-Resolver $us02CPlan $inputIdentityC02
    Assert-ExitCode 1 $c2 'Should_ExitOne_When_PredecessorStepNotCompleted'
    Assert-Field $c2 'reason' 'plan_dependency_step_incomplete' 'Should_ReturnStepIncomplete_When_PredecessorStepPending'
    Assert-Field $c2 'dependency' $us01CPath 'Should_NameDependency_When_PredecessorStepPending'

    $completeC = Invoke-Setter $repoC $us01CPlan 'STEP:US01-S1' '{"schema":"delivery-step/v1","id":"US01-S1","status":"COMPLETED","depends_on":[],"acceptance_evidence":["synthetic acceptance recorded"],"validation_results":[{"command":"synthetic check one","result":"passed","exit_code":0}]}'
    Assert-ExitCode 0 $completeC 'Should_ExitZero_When_PredecessorStepCompletedThroughSetter'
    $stateCDone = Copy-State $repoC 'c-completed'
    $c3 = Invoke-Resolver $us02CPlan $inputIdentityC02
    Assert-ExitCode 0 $c3 'Should_ExitZero_When_PredecessorStepCompleted'
    Assert-Field $c3 'step' 'US02-S1' 'Should_SelectDependentStep_When_PredecessorStepCompleted'

    $repoC4 = Copy-State $stateCDone 'c4-normative-edit'
    Edit-File (Get-RepoPath $repoC4 $us01CPath) 'Normative body: synthetic chained unit plan.' 'Normative body changed after approval.'
    $c4Plan = Get-RepoPath $repoC4 $us02CPath
    Add-ReviewBinding $c4Plan | Out-Null
    $c4 = Invoke-Resolver $c4Plan $inputIdentityC02
    Assert-ExitCode 1 $c4 'Should_ExitOne_When_PredecessorNormativeTextEdited'
    Assert-Field $c4 'reason' 'plan_dependency_identity_changed' 'Should_ReturnIdentityChanged_When_PredecessorNormativeTextEdited'
    Assert-Field $c4 'dependency' $us01CPath 'Should_NameDependency_When_PredecessorNormativeTextEdited'

    $repoC5 = Copy-State $stateCDone 'c5-operational-edit'
    $c5Progress = Invoke-Setter $repoC5 (Get-RepoPath $repoC5 $us01CPath) 'PROGRESS' '{"schema":"delivery-progress/v1","cadence":"step_by_step","current_stage":"implementation"}'
    Assert-ExitCode 0 $c5Progress 'Should_ExitZero_When_PredecessorProgressWritten'
    $c5Second = Invoke-Setter $repoC5 (Get-RepoPath $repoC5 $us01CPath) 'STEP:US01-S2' '{"schema":"delivery-step/v1","id":"US01-S2","status":"COMPLETED","depends_on":["US01-S1"]}'
    Assert-ExitCode 0 $c5Second 'Should_ExitZero_When_PredecessorOtherStepWritten'
    Assert-Equal $identityC01 (Get-DeliveryNormativeIdentity -Text (Read-RepoText $repoC5 $us01CPath)) 'Should_KeepPredecessorIdentity_When_OperationalBlocksEdited'
    $c5Preflight = Invoke-Cli -Script $cli.Preflight -Arguments @('-RepoPath', $repoC5, '-PlanPath', $us02CPath, '-ExpectedIdentity', $identityC02)
    Assert-ExitCode 0 $c5Preflight 'Should_ExitZero_When_PredecessorOperationalBlocksEdited'
    Assert-Field $c5Preflight 'identity' $identityC02 'Should_KeepDependentIdentity_When_PredecessorOperationalBlocksEdited'
    $c5Plan = Get-RepoPath $repoC5 $us02CPath
    Add-ReviewBinding $c5Plan | Out-Null
    $c5 = Invoke-Resolver $c5Plan $inputIdentityC02
    Assert-ExitCode 0 $c5 'Should_ExitZero_When_PredecessorOperationalBlocksEdited'
    Assert-Field $c5 'step' 'US02-S1' 'Should_KeepEligibility_When_PredecessorOperationalBlocksEdited'

    Write-Output ('PASS: {0} delivery end-to-end assertions.' -f $passed)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
