#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('pwsh', 'powershell')]
    [string]$Shell = 'pwsh'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$childExe = if ($Shell -eq 'powershell') { 'powershell.exe' } else { 'pwsh' }
$preflightScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'session/Invoke-StartupPreflight.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('startup-preflight-' + [Guid]::NewGuid().ToString('N'))
$sessionsRoot = Join-Path $tempRoot 'sessions'
New-Item -ItemType Directory -Path $sessionsRoot -Force | Out-Null
$passed = 0
$nativeReads = @('guardrails', 'SESSION', 'SPAWN-DIGEST', 'SPAWN', 'SUBAGENT-MODEL')
$noneReads = @('guardrails', 'SESSION')

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Assert-ReadListed([object[]]$Items, [string]$Expected, [string]$Name) {
    $found = @($Items | Where-Object { [System.IO.Path]::GetFileNameWithoutExtension([string]$_) -ieq $Expected })
    if ($found.Count -eq 0) { throw ('{0}: {1} not listed in missing' -f $Name, $Expected) }
    $script:passed++
}

function Invoke-Preflight([string[]]$Arguments) {
    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $preflightScript) + $Arguments
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $raw = @(& $childExe @argsList 2>&1)
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    $exitCode = $LASTEXITCODE
    $errorLines = @($raw | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_.Exception.Message })
    $outLines = @($raw | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ })
    $text = ($outLines -join [Environment]::NewLine).Trim()
    return [pscustomobject]@{ ExitCode = $exitCode; Text = $text; Err = ($errorLines -join [Environment]::NewLine) }
}

function Invoke-StartupRecord([string]$SessionId, [string]$HostName, [string]$Capability, [string[]]$Reads, [string]$ModelKind = '', [string]$Model = '', [string]$Effort = '') {
    $argsList = @('-Action', 'record', '-SessionId', $SessionId, '-SessionsRoot', $sessionsRoot, '-AgentHost', $HostName, '-Capability', $Capability, '-ReadsDeclared', ($Reads -join ','))
    if ($ModelKind -ne '') { $argsList += @('-ModelChoiceKind', $ModelKind) }
    if ($Model -ne '') { $argsList += @('-Model', $Model) }
    if ($Effort -ne '') { $argsList += @('-Effort', $Effort) }
    return Invoke-Preflight $argsList
}

function Invoke-StartupCheck([string]$SessionId, [string]$HostName, [string]$Gate) {
    $argsList = @('-Action', 'check', '-SessionId', $SessionId, '-SessionsRoot', $sessionsRoot, '-AgentHost', $HostName, '-Gate', $Gate)
    return Invoke-Preflight $argsList
}

function Assert-RecordOk([object]$Run, [string]$Name) {
    Assert-Equal '0' ([string]$Run.ExitCode) ($Name + ' exit')
}

function Assert-Decision([object]$Run, [string]$Allowed, [string]$Reason, [string]$ExitCode, [string]$Name) {
    Assert-Equal $ExitCode ([string]$Run.ExitCode) ($Name + ' exit')
    $json = $Run.Text | ConvertFrom-Json
    Assert-Equal $Allowed ([string]$json.allowed) ($Name + ' allowed')
    Assert-Equal $Reason ([string]$json.reason) ($Name + ' reason')
}

function Get-MarkerPath([string]$SessionId) {
    return Join-Path $sessionsRoot ('startup-' + $SessionId + '.json')
}

function Read-Marker([string]$SessionId) {
    return Get-Content -Raw -LiteralPath (Get-MarkerPath $SessionId) | ConvertFrom-Json
}

function Write-RawMarker([string]$SessionId, [string]$Content) {
    [System.IO.File]::WriteAllText((Get-MarkerPath $SessionId), $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Update-Marker([string]$SessionId, [scriptblock]$Mutate) {
    $marker = Read-Marker $SessionId
    & $Mutate $marker
    Write-RawMarker $SessionId (($marker | ConvertTo-Json -Depth 10))
}

function Get-TreeListing {
    return ((@(Get-ChildItem -LiteralPath $tempRoot -Recurse -Force | ForEach-Object { $_.FullName })) | Sort-Object) -join "`n"
}

try {
    $run = Invoke-StartupCheck 'no-marker' 'codex' 'spawn'
    Assert-Decision $run 'False' 'marker_missing' '3' 'Should_BlockSpawn_When_MarkerMissing'

    $run = Invoke-StartupRecord 'no-model' 'codex' 'native' $nativeReads
    Assert-RecordOk $run 'native record without model choice'
    $run = Invoke-StartupCheck 'no-model' 'codex' 'spawn'
    Assert-Decision $run 'False' 'model_choice_missing' '3' 'Should_BlockSpawn_When_NativeLacksModelChoice'

    $run = Invoke-StartupRecord 'inherit-case' 'codex' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'native inherit record'
    $run = Invoke-StartupCheck 'inherit-case' 'codex' 'spawn'
    Assert-Decision $run 'True' 'ok' '0' 'Should_AllowSpawn_When_NativeCompleteWithInherit'
    $marker = Read-Marker 'inherit-case'
    Assert-Equal 'inherit' ([string]$marker.model_choice.kind) 'inherit marker model_choice kind'
    Assert-Equal 'inherit-case' ([string]$marker.session_id) 'inherit marker session_id equals requested SessionId'
    Assert-Equal 'delivery-startup/v1' ([string]$marker.schema) 'Should_WriteStartupSchema_When_RecordSucceeds'

    $run = Invoke-StartupRecord 'saved' 'codex' 'native' $nativeReads 'saved_confirmed' 'claude-test-model' 'high'
    Assert-RecordOk $run 'native saved_confirmed record'
    $run = Invoke-StartupCheck 'saved' 'codex' 'spawn'
    Assert-Decision $run 'True' 'ok' '0' 'Should_AllowSpawn_When_NativeWithSavedConfirmed'

    $partialReads = @('guardrails', 'SESSION', 'SPAWN-DIGEST', 'SUBAGENT-MODEL')
    $run = Invoke-StartupRecord 'reads-gap' 'codex' 'native' $partialReads 'inherit'
    Assert-RecordOk $run 'native partial reads record'
    $run = Invoke-StartupCheck 'reads-gap' 'codex' 'spawn'
    Assert-Decision $run 'False' 'reads_missing' '3' 'Should_BlockSpawn_When_ReadsMissing'
    $json = $run.Text | ConvertFrom-Json
    Assert-ReadListed @($json.missing) 'SPAWN' 'Should_BlockSpawn_When_ReadsMissing missing list'

    $run = Invoke-StartupRecord 'none-cap' 'codex' 'none' $noneReads
    Assert-RecordOk $run 'none capability record'
    $run = Invoke-StartupCheck 'none-cap' 'codex' 'spawn'
    Assert-Decision $run 'True' 'spawn_not_applicable' '0' 'Should_AllowSpawnNotApplicable_When_CapabilityNone'

    $run = Invoke-StartupRecord 'unknown-cap' 'codex' 'unknown' $noneReads
    Assert-RecordOk $run 'unknown capability record'
    $run = Invoke-StartupCheck 'unknown-cap' 'codex' 'spawn'
    Assert-Decision $run 'True' 'spawn_not_applicable' '0' 'Should_TreatUnknownLikeNone_When_CapabilityUnknown'

    $run = Invoke-StartupRecord 'none-no-guard' 'codex' 'none' @('SESSION')
    Assert-RecordOk $run 'none capability without guardrails record'
    $run = Invoke-StartupCheck 'none-no-guard' 'codex' 'spawn'
    Assert-Decision $run 'False' 'reads_missing' '3' 'Should_BlockNone_When_GuardrailsMissing'
    $json = $run.Text | ConvertFrom-Json
    Assert-ReadListed @($json.missing) 'guardrails' 'Should_BlockNone_When_GuardrailsMissing missing list'

    $run = Invoke-StartupRecord 'host-bound' 'hostA' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'host-bound record'
    $run = Invoke-StartupCheck 'host-bound' 'hostB' 'spawn'
    Assert-Decision $run 'False' 'host_mismatch' '3' 'Should_RejectMarker_When_MarkerFromAnotherHost'

    $run = Invoke-StartupRecord 'host-case' 'claude' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'host-case record'
    $run = Invoke-StartupCheck 'host-case' 'Claude' 'spawn'
    Assert-Decision $run 'False' 'host_mismatch' '3' 'Should_RejectMarker_When_HostDiffersByCase'

    $run = Invoke-StartupRecord 'session-alpha' 'codex' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'session-alpha record'
    $run = Invoke-StartupCheck 'session-alpha' 'codex' 'spawn'
    Assert-Decision $run 'True' 'ok' '0' 'Should_UseMarker_When_SessionIdMatches'
    $run = Invoke-StartupCheck 'session-beta' 'codex' 'spawn'
    Assert-Decision $run 'False' 'marker_missing' '3' 'Should_NotUseMarker_When_SessionIdDiffers'

    $run = Invoke-StartupRecord 'copy-source' 'codex' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'copy-source record'
    Copy-Item -LiteralPath (Get-MarkerPath 'copy-source') -Destination (Get-MarkerPath 'copy-target') -Force
    $run = Invoke-StartupCheck 'copy-target' 'codex' 'spawn'
    Assert-Decision $run 'False' 'host_mismatch' '3' 'Should_RejectMarker_When_InternalSessionIdDiffers'

    $listingBefore = Get-TreeListing
    foreach ($badId in @('bad/id', '../escape')) {
        $run = Invoke-StartupRecord $badId 'codex' 'native' $nativeReads 'inherit'
        Assert-Equal '1' ([string]$run.ExitCode) ('Should_Exit1_When_SessionIdInvalid record ' + $badId)
        Assert-Equal 'True' ([string]$run.Err.Contains('outside [A-Za-z0-9._-]')) ('Should_Exit1_When_SessionIdInvalid record stderr ' + $badId)
        $run = Invoke-StartupCheck $badId 'codex' 'spawn'
        Assert-Equal '1' ([string]$run.ExitCode) ('Should_Exit1_When_SessionIdInvalid check ' + $badId)
        Assert-Equal 'True' ([string]$run.Err.Contains('outside [A-Za-z0-9._-]')) ('Should_Exit1_When_SessionIdInvalid check stderr ' + $badId)
    }
    Assert-Equal $listingBefore (Get-TreeListing) 'Should_Exit1_When_SessionIdInvalid writes nothing under temp root'

    $listingBefore = Get-TreeListing
    $trailingLfId = "ok`n"
    $run = Invoke-StartupRecord $trailingLfId 'codex' 'native' $nativeReads 'inherit'
    Assert-Equal '1' ([string]$run.ExitCode) 'Should_Exit1_When_SessionIdHasTrailingLf record'
    $run = Invoke-StartupCheck $trailingLfId 'codex' 'spawn'
    Assert-Equal '1' ([string]$run.ExitCode) 'Should_Exit1_When_SessionIdHasTrailingLf check'
    Assert-Equal $listingBefore (Get-TreeListing) 'Should_Exit1_When_SessionIdHasTrailingLf writes nothing under temp root'

    $run = Invoke-StartupRecord 'bad-schema' 'codex' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'bad-schema record'
    Update-Marker 'bad-schema' { param($m) $m.schema = 'delivery-startup/v0' }
    $run = Invoke-StartupCheck 'bad-schema' 'codex' 'spawn'
    Assert-Decision $run 'False' 'marker_invalid' '3' 'Should_RejectMarker_When_SchemaWrong'

    Write-RawMarker 'empty-marker' ''
    $run = Invoke-StartupCheck 'empty-marker' 'codex' 'spawn'
    Assert-Decision $run 'False' 'marker_invalid' '3' 'Should_RejectMarker_When_MarkerEmpty'

    Write-RawMarker 'bad-json' '{"schema": "delivery-startup/v1", "session_id": '
    $run = Invoke-StartupCheck 'bad-json' 'codex' 'spawn'
    Assert-Decision $run 'False' 'marker_invalid' '3' 'Should_RejectMarker_When_JsonInvalid'

    $run = Invoke-StartupRecord 'no-cap-field' 'codex' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'no-cap-field record'
    Update-Marker 'no-cap-field' { param($m) [void]$m.PSObject.Properties.Remove('subagents_capability') }
    $run = Invoke-StartupCheck 'no-cap-field' 'codex' 'spawn'
    Assert-Decision $run 'False' 'marker_invalid' '3' 'Should_RejectMarker_When_CapabilityFieldMissing'

    $run = Invoke-StartupRecord 'bogus-cap' 'codex' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'bogus-cap record'
    Update-Marker 'bogus-cap' { param($m) $m.subagents_capability = 'bogus' }
    $run = Invoke-StartupCheck 'bogus-cap' 'codex' 'spawn'
    Assert-Decision $run 'False' 'marker_invalid' '3' 'Should_RejectMarker_When_CapabilityUnknownValue'

    $run = Invoke-StartupCheck 'no-model' 'codex' 'review-record'
    Assert-Decision $run 'False' 'model_choice_missing' '3' 'Should_BlockReviewRecord_When_NativeLacksModelChoice'

    $run = Invoke-StartupCheck 'none-cap' 'codex' 'review-record'
    Assert-Decision $run 'True' 'ok' '0' 'Should_AllowReviewRecord_When_NoneWithGuardrailsAndSession'

    $run = Invoke-StartupRecord 'overwrite' 'codex' 'native' $nativeReads 'inherit'
    Assert-RecordOk $run 'overwrite first record'
    $run = Invoke-StartupRecord 'overwrite' 'codex' 'native' $nativeReads 'saved_confirmed' 'model-second' 'low'
    Assert-RecordOk $run 'overwrite second record'
    $run = Invoke-StartupCheck 'overwrite' 'codex' 'spawn'
    Assert-Decision $run 'True' 'ok' '0' 'Should_OverwriteMarker_When_RecordRepeated'
    $marker = Read-Marker 'overwrite'
    Assert-Equal 'model-second' ([string]$marker.model_choice.model) 'Should_OverwriteMarker_When_RecordRepeated second record wins'
    $leftovers = @(Get-ChildItem -LiteralPath $sessionsRoot -Force | Where-Object { $_.Name -notlike 'startup-*.json' })
    Assert-Equal '0' ([string]$leftovers.Count) 'Should_OverwriteMarker_When_RecordRepeated no temp leftovers'

    $run = Invoke-StartupRecord 'case-reads' 'codex' 'native' @('guardrails.md', 'session.MD', 'spawn-digest', 'SPAWN.md', 'Subagent-Model.md') 'inherit'
    Assert-RecordOk $run 'case-insensitive reads record'
    $run = Invoke-StartupCheck 'case-reads' 'codex' 'spawn'
    Assert-Decision $run 'True' 'ok' '0' 'Should_MatchReadsCaseInsensitively_When_ExtensionOrCaseDiffers'

    foreach ($spawnVariant in @(@{ Id = 'reads-spawn-md'; Name = 'SPAWN.md' }, @{ Id = 'reads-spawn-bare'; Name = 'spawn' })) {
        $reads = @('guardrails', 'SESSION', 'SPAWN-DIGEST', $spawnVariant.Name, 'SUBAGENT-MODEL')
        $run = Invoke-StartupRecord $spawnVariant.Id 'codex' 'native' $reads 'inherit'
        Assert-RecordOk $run ('spawn variant record ' + $spawnVariant.Name)
        $run = Invoke-StartupCheck $spawnVariant.Id 'codex' 'spawn'
        Assert-Decision $run 'True' 'ok' '0' ('Should_MatchReads_When_SpawnEntryIs ' + $spawnVariant.Name)
    }

    foreach ($pathVariant in @(@{ Id = 'reads-path-slash'; Name = 'x/SPAWN.txt' }, @{ Id = 'reads-path-backslash'; Name = 'x\SPAWN.txt' })) {
        $pathVariantName = $pathVariant.Name
        $reads = @('guardrails', 'SESSION', 'SPAWN-DIGEST', $pathVariantName, 'SUBAGENT-MODEL')
        $id = $pathVariant.Id
        $run = Invoke-StartupRecord $id 'codex' 'native' $reads 'inherit'
        Assert-RecordOk $run ('path variant record ' + $pathVariant)
        $run = Invoke-StartupCheck $id 'codex' 'spawn'
        Assert-Decision $run 'False' 'reads_missing' '3' ('Should_IgnoreReadsEntry_When_PathContainsSeparator ' + $pathVariant)
        $json = $run.Text | ConvertFrom-Json
        Assert-ReadListed @($json.missing) 'SPAWN' ('Should_IgnoreReadsEntry_When_PathContainsSeparator missing ' + $pathVariant)
    }

    Write-Output ('PASS: {0} startup preflight assertions on {1}.' -f $passed, $childExe)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
