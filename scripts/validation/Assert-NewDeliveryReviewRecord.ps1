#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$builder = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\runtime\New-DeliveryReviewRecord.ps1'))
$childHost = 'pwsh'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-review-builder-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$repoRoot = Join-Path $tempRoot 'repo'
$scratchDir = Join-Path $repoRoot 'features/001-demo/scratch/delivery-review'
New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null
$passed = 0
$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-ChildScript([string[]]$Arguments) {
    # Explicit quoting keeps path and text arguments intact under both Windows PowerShell and PowerShell 7 parents.
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

function Invoke-Builder([string[]]$Arguments) {
    $normalized = @($Arguments)
    for ($i = 0; $i -lt $normalized.Count - 1; $i++) {
        if ($normalized[$i] -ceq '-OutPath' -and $normalized[$i + 1].StartsWith($repoRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            $normalized[$i + 1] = $normalized[$i + 1].Substring($repoRoot.Length + 1).Replace('\', '/')
        }
    }
    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $builder) + $normalized
    return Invoke-ChildScript $argsList
}

function New-InputFile([string]$Name, [string]$Text) {
    $path = Join-Path $tempRoot $Name
    [System.IO.File]::WriteAllText($path, $Text, $utf8)
    return $path
}

function Read-Record([string]$Path) {
    return [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
}

function Get-Out([string]$Name) {
    return Join-Path $scratchDir $Name
}

$readerJson = '{"paraphrases":{"proposal":"Adds a review record builder.","current_system":"Records are hand-written."},"lenses":["comprehension","scope"],"findings":[{"id":"R1-001","severity":"b","category":"AMBIGUITY","location":"Section 2","evidence":"Step 2 names two outputs.","recommendation":"Name one output."},{"id":"R1-002","severity":"MINOR","category":"GAP","section":"Section 4","evidence":"no-evidence","recommendation":"Add an example."}]}'
$criticJson = '{"lenses":["consistency","evidence"],"findings":[{"id":"C1-001","severity":"I","category":"CONTRADICTION","section":"Section 3","evidence":"Section 3 contradicts Section 5.","recommendation":"Align Section 3."}]}'
$inputsJson = '[{"id":"IN-1","path":"features/001-demo/REFINEMENT.md","role":"source","impacted_ids":["AC-1","AC-2"],"sha256":"ignored"}]'
$dispositionsJson = '[{"id":"R1-001","disposition":"resolved","evidence":"Section 2 now names one output."},{"id":"R1-002","disposition":"accepted_minor","reason":"Example not required."},{"id":"C1-001","disposition":"resolved","evidence":"Section 3 now matches Section 5."}]'

$readerPath = New-InputFile 'reader.json' $readerJson
$criticPath = New-InputFile 'critic.json' $criticJson
$inputsPath = New-InputFile 'inputs.json' $inputsJson
$dispositionsPath = New-InputFile 'dispositions.json' $dispositionsJson
$duplicateCriticPath = New-InputFile 'critic-duplicate.json' '{"lenses":["x"],"findings":[{"id":"R1-001","severity":"I","category":"GAP","section":"S","evidence":"e","recommendation":"r"}]}'
$invalidSeverityPath = New-InputFile 'critic-invalid.json' '{"lenses":["x"],"findings":[{"id":"C1-009","severity":"X","category":"GAP","section":"S","evidence":"e","recommendation":"r"}]}'
$emptyCriticPath = New-InputFile 'critic-empty.json' '{"lenses":["x"],"findings":[]}'
$noParaphrasePath = New-InputFile 'reader-no-paraphrase.json' '{"lenses":["x"],"findings":[]}'

function Get-ReviewedArgs([string]$Out, [string]$Critic = $criticPath, [string]$ReaderIsolation = 'context-only', [string]$Reader = $readerPath) {
    return @('-State', 'reviewed', '-RepoPath', $repoRoot,
        '-ReaderResultPath', $Reader, '-CriticResultPath', $Critic,
        '-ReaderHost', 'host-reader', '-ReaderIsolation', $ReaderIsolation,
        '-CriticHost', 'host-critic', '-CriticIsolation', 'not_reported',
        '-InputsPath', $inputsPath, '-OutPath', $Out)
}

try {
    # Reviewed with both outputs and complete dispositions
    $out1 = Get-Out 'record-1.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $out1) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '0' ([string]$run.ExitCode) 'reviewed build exit'
    $summary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal 'True' ([string]$summary.ok) 'summary ok when fully disposed'
    Assert-Equal '0' ([string]@($summary.errors).Count) 'no errors when fully disposed'
    Assert-Equal '0' ([string]@($summary.undisposed).Count) 'all findings disposed'
    Assert-Equal '1' ([string]$summary.counts.B) 'B count'
    Assert-Equal '1' ([string]$summary.counts.I) 'I count'
    Assert-Equal '1' ([string]$summary.counts.MINOR) 'MINOR count'
    $record = Read-Record $out1
    Assert-Equal 'delivery-review-record/v1' ([string]$record.schema) 'schema'
    Assert-Equal 'reviewed' ([string]$record.state) 'state'
    Assert-Equal 'host-reader' ([string]$record.reviewers.reader.host) 'reader host'
    Assert-Equal 'context-only' ([string]$record.reviewers.reader.observed_isolation) 'reader isolation'
    Assert-Equal 'Adds a review record builder.' ([string]$record.reviewers.reader.result.paraphrases.proposal) 'reader paraphrase'
    Assert-Equal '2' ([string]@($record.reviewers.reader.result.lenses).Count) 'reader lenses'
    Assert-Equal '2' ([string]@($record.reviewers.reader.result.findings).Count) 'reader findings'
    Assert-Equal 'not_reported' ([string]$record.reviewers.critic.observed_isolation) 'critic isolation'
    Assert-Equal '1' ([string]@($record.reviewers.critic.result.findings).Count) 'critic findings'
    Assert-Equal '3' ([string]@($record.dispositions).Count) 'dispositions copied'
    Assert-Equal 'AC-1' ([string]$record.inputs[0].impacted_ids[0]) 'input impacted ids'
    Assert-True (-not $record.inputs[0].PSObject.Properties['sha256']) 'caller hash not carried into record'

    $firstFinding = $record.reviewers.reader.result.findings[0]
    Assert-Equal 'Section 2' ([string]$firstFinding.section) 'location mapped to section'
    Assert-True (-not $firstFinding.PSObject.Properties['location']) 'location key removed'
    Assert-Equal 'B' ([string]$firstFinding.severity) 'severity b normalized to B'
    Assert-Equal 'MINOR' ([string]$record.reviewers.reader.result.findings[1].severity) 'MINOR kept'
    Assert-Equal 'B' ([string]$record.dispositions[0].severity) 'disposition severity copied from finding'
    Assert-Equal 'MINOR' ([string]$record.dispositions[1].severity) 'MINOR disposition severity copied'

    # provenance is always present; empty unless the requested pair is given
    Assert-True ($null -ne $record.PSObject.Properties['provenance']) 'provenance present by default'
    Assert-Equal '0' ([string]@($record.provenance.PSObject.Properties).Count) 'provenance empty by default'

    $provOut = Get-Out 'provenance.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $provOut) + @('-DispositionsPath', $dispositionsPath, '-RequestedModel', 'model-x', '-RequestedEffort', 'high'))
    Assert-Equal '0' ([string]$run.ExitCode) 'requested pair build exit'
    $provRecord = Read-Record $provOut
    Assert-Equal 'model-x' ([string]$provRecord.provenance.requested_model) 'requested model recorded'
    Assert-Equal 'high' ([string]$provRecord.provenance.requested_effort) 'requested effort recorded'

    $onlyModelOut = Get-Out 'only-model.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $onlyModelOut) + @('-RequestedModel', 'model-x'))
    Assert-Equal '1' ([string]$run.ExitCode) 'requested model without effort rejected'
    Assert-True (-not (Test-Path -LiteralPath $onlyModelOut)) 'partial requested pair writes nothing'

    # missing dispositions: draft is written, ok is false, errors name each finding
    $draftOut = Get-Out 'draft.json'
    $run = Invoke-Builder (Get-ReviewedArgs $draftOut)
    Assert-Equal '0' ([string]$run.ExitCode) 'draft with undisposed findings exits 0'
    $summary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal 'False' ([string]$summary.ok) 'ok false with undisposed findings'
    Assert-Equal 'R1-001,R1-002,C1-001' (@($summary.undisposed) -join ',') 'undisposed lists all ids'
    Assert-Equal '3' ([string]@($summary.errors).Count) 'one error per undisposed finding'
    Assert-Equal 'Finding R1-001 has no disposition.' ([string]$summary.errors[0]) 'error message names finding'
    Assert-True (Test-Path -LiteralPath $draftOut) 'draft file written when only dispositions are missing'
    Assert-Equal '0' ([string]@((Read-Record $draftOut).dispositions).Count) 'draft has no dispositions'

    # partial dispositions leave the remaining ids undisposed
    $partialPath = New-InputFile 'partial.json' '[{"id":"R1-001","disposition":"contested","evidence":"Section 2 is explicit."}]'
    $out3 = Get-Out 'record-3.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $out3) + @('-DispositionsPath', $partialPath))
    $summary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal 'R1-002,C1-001' (@($summary.undisposed) -join ',') 'undisposed after partial dispositions'
    Assert-Equal 'False' ([string]$summary.ok) 'ok false after partial dispositions'

    # other shape errors: exit 1, no file
    $shapeOut = Get-Out 'shape.json'
    $run = Invoke-Builder (Get-ReviewedArgs $shapeOut $criticPath 'context-only' $noParaphrasePath)
    Assert-Equal '1' ([string]$run.ExitCode) 'missing paraphrases exits 1'
    Assert-True ($run.Output -match 'paraphrases|proposal') 'shape error message reported'
    Assert-True (-not (Test-Path -LiteralPath $shapeOut)) 'shape error writes no file'

    $run = Invoke-Builder (Get-ReviewedArgs (Get-Out 'dup.json') $duplicateCriticPath)
    Assert-Equal '1' ([string]$run.ExitCode) 'duplicate finding id across roles exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Get-Out 'dup.json'))) 'duplicate finding writes nothing'

    $run = Invoke-Builder (Get-ReviewedArgs (Get-Out 'invalid.json') $invalidSeverityPath)
    Assert-Equal '1' ([string]$run.ExitCode) 'invalid severity exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Get-Out 'invalid.json'))) 'invalid severity writes nothing'

    $dupDispPath = New-InputFile 'dup-disp.json' '[{"id":"R1-001","disposition":"resolved","evidence":"a"},{"id":"R1-001","disposition":"resolved","evidence":"b"}]'
    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'dup-disp.json')) + @('-DispositionsPath', $dupDispPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'duplicate disposition id exits 1'

    $run = Invoke-Builder (Get-ReviewedArgs (Get-Out 'no-iso.json') $criticPath ' ')
    Assert-Equal '1' ([string]$run.ExitCode) 'blank reader isolation rejected'

    $out4 = Get-Out 'record-4.json'
    $readerDispPath = New-InputFile 'reader-dispositions.json' '[{"id":"R1-001","disposition":"resolved","evidence":"Section 2 now names one output."},{"id":"R1-002","disposition":"accepted_minor","reason":"Example not required."}]'
    $run = Invoke-Builder ((Get-ReviewedArgs $out4 $emptyCriticPath) + @('-DispositionsPath', $readerDispPath))
    Assert-Equal '0' ([string]$run.ExitCode) 'empty critic findings exit'
    $summary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal 'True' ([string]$summary.ok) 'empty critic findings with reader dispositions'

    # bypassed
    $bypassOut = Get-Out 'bypass.json'
    $run = Invoke-Builder @('-State', 'bypassed', '-RepoPath', $repoRoot, '-Reason', 'Review host offline', '-OutPath', $bypassOut)
    Assert-Equal '1' ([string]$run.ExitCode) 'bypass requires BypassEvidence'
    $run = Invoke-Builder @('-State', 'bypassed', '-RepoPath', $repoRoot, '-BypassEvidence', 'Operator chose bypass in chat', '-OutPath', $bypassOut)
    Assert-Equal '1' ([string]$run.ExitCode) 'bypass requires Reason'
    $run = Invoke-Builder @('-State', 'bypassed', '-RepoPath', $repoRoot, '-BypassEvidence', 'Operator chose bypass in chat', '-Reason', 'Review host offline', '-OutPath', $bypassOut)
    Assert-Equal '0' ([string]$run.ExitCode) 'bypass with evidence and reason exit'
    $bypassRecord = Read-Record $bypassOut
    Assert-Equal 'bypassed' ([string]$bypassRecord.state) 'bypass state'
    Assert-Equal 'bypass' ([string]$bypassRecord.operator_choice.choice) 'bypass operator choice'
    Assert-Equal 'Operator chose bypass in chat' ([string]$bypassRecord.operator_choice.evidence) 'bypass evidence'
    Assert-True ([System.IO.File]::ReadAllText($bypassOut) -match '"date":\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}') 'bypass date present'
    Assert-Equal '0' ([string]@($bypassRecord.reviewers.PSObject.Properties).Count) 'bypass reviewers empty object'
    Assert-Equal '0' ([string]@($bypassRecord.dispositions).Count) 'bypass dispositions empty'

    # not_run
    $notRunOut = Get-Out 'not-run.json'
    $run = Invoke-Builder @('-State', 'not_run', '-RepoPath', $repoRoot, '-OutPath', $notRunOut)
    Assert-Equal '1' ([string]$run.ExitCode) 'not_run requires Reason'
    $run = Invoke-Builder @('-State', 'not_run', '-RepoPath', $repoRoot, '-Reason', 'Review host unavailable', '-OutPath', $notRunOut)
    Assert-Equal '0' ([string]$run.ExitCode) 'not_run with reason exit'
    $notRunRecord = Read-Record $notRunOut
    Assert-Equal 'not_run' ([string]$notRunRecord.state) 'not_run state'
    Assert-Equal 'Review host unavailable' ([string]$notRunRecord.reason) 'not_run reason'
    Assert-Equal '0' ([string]@($notRunRecord.reviewers.PSObject.Properties).Count) 'not_run reviewers empty object'
    Assert-Equal '0' ([string]@($notRunRecord.dispositions).Count) 'not_run dispositions empty'

    # refuses to overwrite an existing OutPath
    $run = Invoke-Builder @('-State', 'not_run', '-RepoPath', $repoRoot, '-Reason', 'Second attempt', '-OutPath', $notRunOut)
    Assert-Equal '1' ([string]$run.ExitCode) 'existing OutPath refused'
    Assert-Equal 'Review host unavailable' ([string](Read-Record $notRunOut).reason) 'existing file left unchanged'

    # approval evidence adds approval.operator_choice
    $approvalOut = Get-Out 'approval.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $approvalOut) + @('-DispositionsPath', $dispositionsPath, '-ApprovalEvidence', 'Operator confirmed content in chat'))
    Assert-Equal '0' ([string]$run.ExitCode) 'approval build exit'
    $approvalRecord = Read-Record $approvalOut
    Assert-Equal 'approved' ([string]$approvalRecord.approval.status) 'approval status'
    Assert-Equal 'content_approval' ([string]$approvalRecord.approval.operator_choice.choice) 'approval choice'
    Assert-Equal 'Operator confirmed content in chat' ([string]$approvalRecord.approval.operator_choice.evidence) 'approval evidence'

    # OutPath confinement
    $outsideRel = 'features/001-demo/record.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $outsideRel) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'OutPath outside scratch/delivery-review exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot $outsideRel))) 'outside OutPath writes nothing'

    $absoluteOut = Join-Path $tempRoot 'absolute.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $absoluteOut) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'absolute OutPath exits 1'
    Assert-True (-not (Test-Path -LiteralPath $absoluteOut)) 'absolute OutPath writes nothing'

    $run = Invoke-Builder ((Get-ReviewedArgs 'features/001-demo/scratch/delivery-review/note.txt') + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'non-json OutPath exits 1'

    $traversalRel = 'features/001-demo/scratch/delivery-review/../../../escape.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $traversalRel) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'traversal OutPath exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'features/escape.json'))) 'traversal writes nothing'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'escape.json'))) 'traversal writes nothing at repo root'

    $ghostRel = 'features/003-none/../../escape.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $ghostRel) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'traversal through missing feature exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'features/003-none'))) 'rejected OutPath creates no feature directory'

    # reparse point (junction) inside scratch is rejected before any write
    $elsewhere = Join-Path $tempRoot 'elsewhere'
    New-Item -ItemType Directory -Path $elsewhere -Force | Out-Null
    $junction = Join-Path $scratchDir 'linked'
    New-Item -ItemType Junction -Path $junction -Target $elsewhere | Out-Null
    $run = Invoke-Builder ((Get-ReviewedArgs 'features/001-demo/scratch/delivery-review/linked/x.json') + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'reparse point in OutPath exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $elsewhere 'x.json'))) 'reparse point writes nothing'

    # one-element arrays survive the pipeline and JSON round trips as arrays
    . (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')
    $oneReader = New-InputFile 'one-reader.json' '{"paraphrases":{"proposal":"p","current_system":"c"},"lenses":["comprehension"],"findings":[{"id":"R1-001","severity":"I","category":"GAP","section":"2","evidence":"e","recommendation":"r"}]}'
    $oneCritic = New-InputFile 'one-critic.json' '{"lenses":["consistency"],"findings":[]}'
    $oneInputs = New-InputFile 'one-inputs.json' '[{"id":"IN-1","path":"features/001-demo/REFINEMENT.md","role":"source","impacted_ids":["AC-1"]}]'
    $oneDisp = New-InputFile 'one-disp.json' '[{"id":"R1-001","disposition":"resolved","evidence":"Corrected in section 2."}]'
    $oneOut = Get-Out 'one-element.json'
    $run = Invoke-Builder @('-State', 'reviewed', '-RepoPath', $repoRoot,
        '-ReaderResultPath', $oneReader, '-CriticResultPath', $oneCritic,
        '-ReaderHost', 'host-reader', '-ReaderIsolation', 'context-only',
        '-CriticHost', 'host-critic', '-CriticIsolation', 'not_reported',
        '-InputsPath', $oneInputs, '-DispositionsPath', $oneDisp, '-OutPath', $oneOut)
    Assert-Equal '0' ([string]$run.ExitCode) 'one-element build exit'
    $oneSummary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal 'True' ([string]$oneSummary.ok) 'one-element record fully dispositioned'
    $oneText = [System.IO.File]::ReadAllText($oneOut)
    Assert-True ($oneText -match '"impacted_ids":\s*\[\s*"AC-1"\s*\]') 'one impacted id kept as array'
    Assert-True ($oneText -match '"lenses":\s*\[\s*"comprehension"\s*\]') 'one reader lens kept as array'
    Assert-True ($oneText -match '"lenses":\s*\[\s*"consistency"\s*\]') 'one critic lens kept as array'
    Assert-True ($oneText -match '"findings":\s*\[\s*\{\s*"id":\s*"R1-001"') 'one finding kept as array'
    Assert-True ($oneText -match '"dispositions":\s*\[\s*\{\s*"id":\s*"R1-001"') 'one disposition kept as array'
    Assert-True ($oneText -match '"inputs":\s*\[\s*\{\s*"id":\s*"IN-1"') 'one input kept as array'
    $oneRecord = Read-Record $oneOut
    Assert-True ($oneRecord.inputs[0].impacted_ids -is [System.Array]) 'impacted_ids is an array after reading the file'
    Assert-True (@($oneRecord.reviewers.reader.result.findings).Count -eq 1) 'one finding after reading the file'
    $shapeErrors = [System.Collections.Generic.List[string]]::new()
    try { Assert-DeliveryReviewRecordShape -Value $oneRecord } catch { $shapeErrors.Add($_.Exception.Message) }
    Assert-Equal '0' ([string]$shapeErrors.Count) ('one-element record shape errors: ' + ($shapeErrors -join '; '))

    # stdout is one compact line
    $lineRun = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'one-line.json')) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '0' ([string]$lineRun.ExitCode) 'one-line build exit'
    Assert-True (-not ($lineRun.Output.Trim() -match "`n")) 'stdout is one line'

    # re-audit rounds: linkage, rounds entries, late and repeats
    $priorIdentity = '0123456789ABCDEF' * 4
    $defaultRound = Read-Record $out1
    Assert-Equal '1' ([string]$defaultRound.round) 'round defaults to 1'
    Assert-True (-not $defaultRound.PSObject.Properties['prior_review_identity']) 'no prior identity without round 2'
    Assert-True (-not $defaultRound.PSObject.Properties['rounds']) 'no rounds without RoundsPath'

    $roundsFile = New-InputFile 'rounds-2.json' '[{"round":2,"role":"critic","inputs":[{"id":"IN-1","reason":"Section 3 changed"}],"reported_tokens":null,"reported_tool_calls":3,"duration_s":41}]'
    $roundOut = Get-Out 'round-2.json'
    $run = Invoke-Builder ((Get-ReviewedArgs $roundOut) + @('-DispositionsPath', $dispositionsPath, '-Round', '2', '-PriorReviewIdentity', $priorIdentity, '-RoundsPath', $roundsFile))
    Assert-Equal '0' ([string]$run.ExitCode) 'round 2 build exit'
    $roundSummary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal 'True' ([string]$roundSummary.ok) 'round 2 record fully dispositioned'
    $roundRecord = Read-Record $roundOut
    Assert-Equal '2' ([string]$roundRecord.round) 'round 2 recorded'
    Assert-Equal $priorIdentity ([string]$roundRecord.prior_review_identity) 'prior identity recorded'
    Assert-Equal '1' ([string]@($roundRecord.rounds).Count) 'rounds entry recorded'
    Assert-Equal 'critic' ([string]$roundRecord.rounds[0].role) 'rounds role kept'
    Assert-Equal '41' ([string]$roundRecord.rounds[0].duration_s) 'rounds duration kept'
    Assert-True ($null -eq $roundRecord.rounds[0].reported_tokens) 'null reported tokens kept as unknown'
    Assert-True ([System.IO.File]::ReadAllText($roundOut) -match '"rounds":\s*\[\s*\{\s*"round":\s*2') 'one rounds entry kept as array'
    Assert-True ([System.IO.File]::ReadAllText($roundOut) -match '"inputs":\s*\[\s*\{\s*"id":\s*"IN-1"') 'one rounds input kept as array'

    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'round-2-no-prior.json')) + @('-DispositionsPath', $dispositionsPath, '-Round', '2'))
    Assert-Equal '1' ([string]$run.ExitCode) 'round 2 without prior identity exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Get-Out 'round-2-no-prior.json'))) 'round 2 without prior writes nothing'

    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'round-1-prior.json')) + @('-DispositionsPath', $dispositionsPath, '-Round', '1', '-PriorReviewIdentity', $priorIdentity))
    Assert-Equal '1' ([string]$run.ExitCode) 'prior identity with round 1 exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Get-Out 'round-1-prior.json'))) 'round 1 with prior writes nothing'

    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'round-0.json')) + @('-DispositionsPath', $dispositionsPath, '-Round', '0'))
    Assert-Equal '1' ([string]$run.ExitCode) 'round 0 exits 1'

    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'round-lower.json')) + @('-DispositionsPath', $dispositionsPath, '-Round', '2', '-PriorReviewIdentity', $priorIdentity.ToLowerInvariant()))
    Assert-Equal '1' ([string]$run.ExitCode) 'lowercase prior identity exits 1'

    $badRoundsFile = New-InputFile 'rounds-bad.json' '[{"round":2,"role":"author","inputs":[],"reported_tokens":-1}]'
    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'rounds-bad.json')) + @('-DispositionsPath', $dispositionsPath, '-Round', '2', '-PriorReviewIdentity', $priorIdentity, '-RoundsPath', $badRoundsFile))
    Assert-Equal '1' ([string]$run.ExitCode) 'invalid rounds entry exits 1'
    Assert-True (-not (Test-Path -LiteralPath (Get-Out 'rounds-bad.json'))) 'invalid rounds entry writes nothing'

    $lateCritic = New-InputFile 'late-critic.json' '{"lenses":["consistency"],"findings":[]}'
    $lateDisp = New-InputFile 'late-disp.json' '[{"id":"R2-001","disposition":"resolved","evidence":"Corrected in section 3."},{"id":"R2-002","disposition":"resolved","evidence":"Section 4 now states the rule."}]'
    $lateReader = New-InputFile 'late-reader.json' '{"paraphrases":{"proposal":"p","current_system":"c"},"lenses":["comprehension"],"findings":[{"id":"R2-001","severity":"B","category":"GAP","section":"3","evidence":"e","recommendation":"r","late":true},{"id":"R2-002","severity":"B","category":"GAP","section":"4","evidence":"e","recommendation":"r","repeats":"R1-001"}]}'
    $lateOut = Get-Out 'late.json'
    $lateArgs = @('-State', 'reviewed', '-RepoPath', $repoRoot,
        '-ReaderResultPath', $lateReader, '-CriticResultPath', $lateCritic,
        '-ReaderHost', 'host-reader', '-ReaderIsolation', 'context-only',
        '-CriticHost', 'host-critic', '-CriticIsolation', 'not_reported',
        '-InputsPath', $inputsPath, '-Round', '2', '-PriorReviewIdentity', $priorIdentity)
    $run = Invoke-Builder ($lateArgs + @('-DispositionsPath', $lateDisp, '-OutPath', $lateOut))
    Assert-Equal '0' ([string]$run.ExitCode) 'late and repeats build exit'
    $lateSummary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal '1' ([string]$lateSummary.counts.late) 'late findings counted'
    Assert-Equal '1' ([string]$lateSummary.counts.repeats) 'repeats findings counted'
    Assert-Equal 'True' ([string]$lateSummary.ok) 'late and repeats record fully dispositioned'
    $lateRecord = Read-Record $lateOut
    Assert-Equal 'True' ([string]$lateRecord.reviewers.reader.result.findings[0].late) 'late passes through'
    Assert-Equal 'R1-001' ([string]$lateRecord.reviewers.reader.result.findings[1].repeats) 'repeats passes through'

    # insufficient correction: the later finding repeating a prior id stays undisposed until disposed
    $partialLateDisp = New-InputFile 'partial-late-disp.json' '[{"id":"R2-001","disposition":"resolved","evidence":"Corrected in section 3."}]'
    $run = Invoke-Builder ($lateArgs + @('-DispositionsPath', $partialLateDisp, '-OutPath', (Get-Out 'insufficient.json')))
    Assert-Equal '0' ([string]$run.ExitCode) 'undisposed repeat draft exits 0'
    $insufficientSummary = $run.Output.Trim() | ConvertFrom-Json
    Assert-Equal 'False' ([string]$insufficientSummary.ok) 'undisposed repeat keeps record not ok'
    Assert-Equal 'R2-002' (@($insufficientSummary.undisposed) -join ',') 'undisposed repeat is reported'

    $readerWithoutLate = New-InputFile 'reader-without-late.json' '{"paraphrases":{"proposal":"p","current_system":"c"},"lenses":["comprehension"],"findings":[{"id":"R2-010","severity":"I","category":"GAP","section":"S","evidence":"e","recommendation":"r","late":"yes"}]}'
    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'late-string.json') $lateCritic 'context-only' $readerWithoutLate) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'late as string exits 1'

    $readerBlankRepeats = New-InputFile 'reader-blank-repeats.json' '{"paraphrases":{"proposal":"p","current_system":"c"},"lenses":["comprehension"],"findings":[{"id":"R2-011","severity":"I","category":"GAP","section":"S","evidence":"e","recommendation":"r","repeats":"  "}]}'
    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'blank-repeats.json') $lateCritic 'context-only' $readerBlankRepeats) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'blank repeats exits 1'

    $readerSelfRepeat = New-InputFile 'reader-self-repeat.json' '{"paraphrases":{"proposal":"p","current_system":"c"},"lenses":["comprehension"],"findings":[{"id":"R2-012","severity":"I","category":"GAP","section":"S","evidence":"e","recommendation":"r","repeats":"R2-012"}]}'
    $run = Invoke-Builder ((Get-ReviewedArgs (Get-Out 'self-repeat.json') $lateCritic 'context-only' $readerSelfRepeat) + @('-DispositionsPath', $dispositionsPath))
    Assert-Equal '1' ([string]$run.ExitCode) 'repeats equal to own id exits 1'

    # reviewer unavailable across a later round: bypassed, reasoned, no findings
    $bypassRoundOut = Get-Out 'bypass-round-2.json'
    $run = Invoke-Builder @('-State', 'bypassed', '-RepoPath', $repoRoot, '-BypassEvidence', 'Operator chose bypass in chat', '-Reason', 'Review host offline', '-Round', '2', '-PriorReviewIdentity', $priorIdentity, '-OutPath', $bypassRoundOut)
    Assert-Equal '0' ([string]$run.ExitCode) 'bypassed round 2 exit'
    $bypassRoundRecord = Read-Record $bypassRoundOut
    Assert-Equal '2' ([string]$bypassRoundRecord.round) 'bypassed round 2 recorded'
    Assert-Equal '0' ([string]@($bypassRoundRecord.reviewers.PSObject.Properties).Count) 'bypassed round 2 carries no reviewers'

    # External input sources pass through unchanged; the builder never resolves them.
    $sourceInputsJson = '[{"id":"SRC-FILE","path":"alias:docs/brief.md","role":"source","impacted_ids":["AC-1"]},{"id":"SRC-SET","path":"alias:docs/specs","role":"source","impacted_ids":["AC-2"],"source":{"kind":"fileset","files":["b.md","a.md"]}},{"id":"SRC-REV","path":"alias:gitsrc","role":"source","impacted_ids":["AC-3"],"source":{"kind":"revision","revision":"0123456789abcdef0123456789abcdef01234567"}},{"id":"SRC-ONE","path":"features/001-demo/specs","role":"source","impacted_ids":["AC-4"],"source":{"kind":"fileset","files":["a.md"]}}]'
    $sourceInputsPath = New-InputFile 'source-inputs.json' $sourceInputsJson
    $sourceOut = Get-Out 'source-inputs-record.json'
    $run = Invoke-Builder @('-State', 'reviewed', '-RepoPath', $repoRoot,
        '-ReaderResultPath', $readerPath, '-CriticResultPath', $criticPath,
        '-ReaderHost', 'host-reader', '-ReaderIsolation', 'context-only',
        '-CriticHost', 'host-critic', '-CriticIsolation', 'not_reported',
        '-InputsPath', $sourceInputsPath, '-DispositionsPath', $dispositionsPath, '-OutPath', $sourceOut)
    Assert-Equal '0' ([string]$run.ExitCode) "source inputs build exit: $($run.Output)"
    $sourceRecord = Read-Record $sourceOut
    Assert-Equal 'alias:docs/brief.md' ([string]$sourceRecord.inputs[0].path) 'alias file path passes through'
    Assert-True (-not $sourceRecord.inputs[0].PSObject.Properties['source']) 'alias file without source stays without source'
    Assert-Equal 'alias:docs/specs' ([string]$sourceRecord.inputs[1].path) 'alias fileset path passes through'
    Assert-Equal 'fileset' ([string]$sourceRecord.inputs[1].source.kind) 'fileset source passes through'
    Assert-Equal 'b.md' ([string]$sourceRecord.inputs[1].source.files[0]) 'fileset order passes through'
    Assert-Equal '2' ([string]@($sourceRecord.inputs[1].source.files).Count) 'fileset files keep both members'
    Assert-Equal 'revision' ([string]$sourceRecord.inputs[2].source.kind) 'revision source passes through'
    Assert-Equal '0123456789abcdef0123456789abcdef01234567' ([string]$sourceRecord.inputs[2].source.revision) 'revision id passes through'
    Assert-Equal '1' ([string]@($sourceRecord.inputs[3].source.files).Count) 'one-element fileset stays an array'
    Assert-True (-not $sourceRecord.inputs[0].PSObject.Properties['sha256']) 'alias input carries no builder hash'

    $repoFileSourceInputs = New-InputFile 'repo-file-source.json' '[{"id":"BAD-1","path":"features/001-demo/REFINEMENT.md","role":"source","impacted_ids":["AC-1"],"source":{"kind":"file"}}]'
    $run = Invoke-Builder @('-State', 'reviewed', '-RepoPath', $repoRoot,
        '-ReaderResultPath', $readerPath, '-CriticResultPath', $criticPath,
        '-ReaderHost', 'host-reader', '-ReaderIsolation', 'context-only',
        '-CriticHost', 'host-critic', '-CriticIsolation', 'not_reported',
        '-InputsPath', $repoFileSourceInputs, '-OutPath', (Get-Out 'repo-file-source.json'))
    Assert-Equal '1' ([string]$run.ExitCode) 'repository file with file source exits 1'
    Assert-True ($run.Output -match 'plain repository files take no source') 'repository file with file source names the rule'
    Assert-True (-not (Test-Path -LiteralPath (Get-Out 'repo-file-source.json'))) 'rejected source input writes no record'

    $nullSourceInputs = New-InputFile 'null-source.json' '[{"id":"BAD-2","path":"alias:docs/brief.md","role":"source","impacted_ids":["AC-1"],"source":null}]'
    $run = Invoke-Builder @('-State', 'reviewed', '-RepoPath', $repoRoot,
        '-ReaderResultPath', $readerPath, '-CriticResultPath', $criticPath,
        '-ReaderHost', 'host-reader', '-ReaderIsolation', 'context-only',
        '-CriticHost', 'host-critic', '-CriticIsolation', 'not_reported',
        '-InputsPath', $nullSourceInputs, '-OutPath', (Get-Out 'null-source.json'))
    Assert-Equal '1' ([string]$run.ExitCode) 'null source exits 1'
    Assert-True ($run.Output -match 'input source must be an object') 'null source is rejected by shape, not dropped'

    Write-Output ('PASS: {0} assertions for New-DeliveryReviewRecord.' -f $passed)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
