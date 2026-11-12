#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $RepoPath,
    [Parameter(Mandatory = $true)][string] $TargetPath,
    [Parameter(Mandatory = $true)][string] $RecordPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')

function Exit-WithVerdict {
    param(
        [Parameter(Mandatory = $true)][bool] $Allowed,
        [Parameter(Mandatory = $true)][string] $Reason,
        [string[]] $Details = @(),
        [Parameter(Mandatory = $true)][int] $ExitCode
    )

    $verdict = [pscustomobject]@{ allowed = $Allowed; reason = $Reason; details = [string[]]@($Details) }
    [Console]::Out.WriteLine(($verdict | ConvertTo-Json -Compress))
    exit $ExitCode
}

try {
    $repoFull = [System.IO.Path]::GetFullPath($RepoPath)
    $leaf = Split-Path -Leaf $TargetPath
    if ($leaf -ceq 'REFINEMENT.md') {
        $targetKind = 'REFINEMENT.md'
        $stage = 'delivery_refinement_review'
    }
    elseif ($leaf -ceq 'PLAN.md') {
        $targetKind = 'PLAN.md'
        $stage = 'delivery_unit_plan_review'
    }
    else {
        throw 'Target must be a canonical REFINEMENT.md or PLAN.md path.'
    }
    $target = Assert-DeliveryReviewTarget -RepoPath $repoFull -TargetPath $TargetPath -TargetKind $targetKind -Stage $stage
    $targetRelative = $TargetPath.Replace('\', '/')

    $recordAbsolute = if ([System.IO.Path]::IsPathRooted($RecordPath)) { $RecordPath } else { Get-SafeFullPath $repoFull $RecordPath }
    $recordFull = Resolve-DeliveryReviewRecordPath -RecordPath $recordAbsolute -FeatureFull $target.FeatureFull

    if (-not (Test-Path -LiteralPath $recordFull -PathType Leaf)) {
        Exit-WithVerdict -Allowed $false -Reason 'record_missing' -ExitCode 3
    }

    $record = $null
    try {
        $recordText = [System.IO.File]::ReadAllText($recordFull)
        if ([string]::IsNullOrWhiteSpace($recordText)) { throw 'Record file is empty.' }
        $record = ConvertFrom-Json -InputObject $recordText -Depth 50
    }
    catch {
        Exit-WithVerdict -Allowed $false -Reason 'record_unreadable' -ExitCode 3
    }

    try {
        Assert-DeliveryReviewRecordShape -Value $record
    }
    catch {
        Exit-WithVerdict -Allowed $false -Reason 'record_schema_invalid' -Details @($_.Exception.Message) -ExitCode 3
    }

    $targetBlock = Get-DeliveryReviewRecordField -Object $record -Name 'target'
    $recordTargetPath = [string](Get-DeliveryReviewRecordField -Object $targetBlock -Name 'path')
    $recordTargetKind = [string](Get-DeliveryReviewRecordField -Object $targetBlock -Name 'kind')
    $recordTargetStage = [string](Get-DeliveryReviewRecordField -Object $targetBlock -Name 'stage')
    $recordContentSha = [string](Get-DeliveryReviewRecordField -Object $targetBlock -Name 'content_sha256')
    $recordReviewIdentity = [string](Get-DeliveryReviewRecordField -Object $targetBlock -Name 'review_identity')
    if ([string]::IsNullOrWhiteSpace($recordTargetPath) -or [string]::IsNullOrWhiteSpace($recordTargetKind) -or
        [string]::IsNullOrWhiteSpace($recordTargetStage) -or [string]::IsNullOrWhiteSpace($recordContentSha) -or
        [string]::IsNullOrWhiteSpace($recordReviewIdentity)) {
        Exit-WithVerdict -Allowed $false -Reason 'record_schema_invalid' -Details @('Record requires a target block with path, kind, stage, content_sha256, and review_identity.') -ExitCode 3
    }
    if ($recordTargetPath.Replace('\', '/') -cne $targetRelative -or $recordTargetKind -cne $targetKind -or $recordTargetStage -cne $stage) {
        Exit-WithVerdict -Allowed $false -Reason 'target_mismatch' -Details @('Record target does not match the requested target path, kind, or stage.') -ExitCode 3
    }

    $inputEntries = [System.Collections.Generic.List[object]]::new()
    foreach ($input in @(Get-DeliveryReviewRecordField -Object $record -Name 'inputs')) {
        $inputId = [string](Get-DeliveryReviewRecordField -Object $input -Name 'id')
        $inputPath = [string](Get-DeliveryReviewRecordField -Object $input -Name 'path')
        $inputRole = [string](Get-DeliveryReviewRecordField -Object $input -Name 'role')
        $inputSha = [string](Get-DeliveryReviewRecordField -Object $input -Name 'sha256')
        $inputFull = $null
        try {
            if ([string]::IsNullOrWhiteSpace($inputSha)) { throw 'Each record input requires sha256.' }
            $inputFull = Get-SafeFullPath $repoFull $inputPath
            Assert-NoReparseAncestors $inputFull $repoFull
        }
        catch {
            Exit-WithVerdict -Allowed $false -Reason 'record_schema_invalid' -Details @($_.Exception.Message) -ExitCode 3
        }
        $inputEntries.Add([pscustomobject]@{
            id           = $inputId
            path         = $inputPath
            role         = $inputRole
            recorded     = $inputSha
            full         = $inputFull
            impacted_ids = $input.impacted_ids
        })
    }

    $targetFull = $target.TargetFull
    if (-not (Test-Path -LiteralPath $targetFull -PathType Leaf)) {
        Exit-WithVerdict -Allowed $false -Reason 'identity_stale' -Details @('Target file is missing.') -ExitCode 3
    }
    $targetText = [System.IO.File]::ReadAllText($targetFull)
    $targetBlocks = Read-DeliveryBlocks -Text $targetText
    if (-not $targetBlocks.Ok) {
        $blockCodes = @($targetBlocks.Errors | ForEach-Object { [string]$_.code } | Select-Object -Unique)
        Exit-WithVerdict -Allowed $false -Reason 'grammar_invalid' -Details $blockCodes -ExitCode 3
    }
    $currentContentSha = Get-DeliveryNormativeIdentity -Text $targetText
    if ($currentContentSha -cne $recordContentSha) {
        Exit-WithVerdict -Allowed $false -Reason 'identity_stale' -ExitCode 3
    }

    $changedInputIds = [System.Collections.Generic.List[string]]::new()
    $inputRows = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in $inputEntries) {
        if (-not (Test-Path -LiteralPath $entry.full -PathType Leaf)) {
            $changedInputIds.Add($entry.id)
            continue
        }
        $currentInputSha = (Get-FileHash -LiteralPath $entry.full -Algorithm SHA256).Hash
        if ($currentInputSha -cne $entry.recorded) { $changedInputIds.Add($entry.id) }
        $inputRows.Add([pscustomobject]@{
            id           = $entry.id
            path         = $entry.path
            sha256       = $currentInputSha
            role         = $entry.role
            impacted_ids = $entry.impacted_ids
        })
    }
    if ($changedInputIds.Count -gt 0) {
        Exit-WithVerdict -Allowed $false -Reason 'inputs_changed' -Details $changedInputIds.ToArray() -ExitCode 3
    }

    $recomputedIdentity = Get-DeliveryReviewIdentity -TargetKind $recordTargetKind -Stage $recordTargetStage -TargetPath $targetRelative -NormativeSha $recordContentSha -Inputs $inputRows.ToArray()
    if ($recomputedIdentity -cne $recordReviewIdentity) {
        Exit-WithVerdict -Allowed $false -Reason 'review_identity_mismatch' -ExitCode 3
    }

    $state = [string](Get-DeliveryReviewRecordField -Object $record -Name 'state')
    $stateReason = [string](Get-DeliveryReviewRecordField -Object $record -Name 'reason')
    switch -CaseSensitive ($state) {
        'not_run' {
            Exit-WithVerdict -Allowed $false -Reason 'review_not_run' -Details @($stateReason) -ExitCode 3
        }
        'bypassed' {
            Exit-WithVerdict -Allowed $true -Reason 'bypassed' -Details @($stateReason) -ExitCode 0
        }
        'reviewed' {
            Exit-WithVerdict -Allowed $true -Reason 'reviewed' -ExitCode 0
        }
        default {
            Exit-WithVerdict -Allowed $false -Reason 'record_schema_invalid' -Details @('Unknown review state.') -ExitCode 3
        }
    }
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
