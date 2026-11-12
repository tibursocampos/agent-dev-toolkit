#Requires -Version 5.1
<#
.SYNOPSIS
  Evaluates eligibility and safe resumption for an integrated-delivery PLAN.
.DESCRIPTION
  Read-only decision helper. It never edits the PLAN or repository. Operational
  blocks are JSON between the exact DELIVERY markers in EXECUTION.md. Block
  parsing, required-block rules, and the normative identity come from
  scripts/_lib/DeliveryGrammar.ps1.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [Parameter(Mandatory = $true)][ValidateSet('step_by_step', 'continuous')][string] $Cadence,
    [Parameter(Mandatory = $true)][string] $CurrentInputIdentity,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string] $CurrentBranch,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string] $CurrentHead,
    [switch] $Resume,
    [switch] $StepAuthorization,
    [switch] $ContinuousAuthorization
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libDir = Join-Path (Split-Path -Parent $PSScriptRoot) '_lib'
. (Join-Path $libDir 'DeliveryGrammar.ps1')

function New-Decision([bool]$Allowed, [string]$Reason, [string]$Step = '') {
    [pscustomobject]@{ allowed = $Allowed; reason = $Reason; step = $Step }
}

function Get-BlockJson([object[]]$Blocks, [string]$Type) {
    foreach ($block in $Blocks) {
        if ($block.Type -ceq $Type) { return $block.Json }
    }
    throw ('block_{0}_missing' -f $Type)
}

function Test-Field($Object, [string]$Name) {
    return ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name])
}

function Get-EvidenceLocation {
    param([Parameter(Mandatory = $true)][string] $PlanFullPath)

    $cursor = $PlanFullPath
    while ($true) {
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrEmpty($parent) -or ($parent -ceq $cursor)) { return $null }
        if (((Split-Path -Leaf $parent) -ceq 'features') -and ($cursor -cne $PlanFullPath)) {
            return [pscustomobject]@{
                Root    = (Split-Path -Parent $parent)
                Feature = (Split-Path -Leaf $cursor)
                Unit    = (Split-Path -Leaf (Split-Path -Parent $PlanFullPath))
            }
        }
        $cursor = $parent
    }
}

function Get-FileSha256Hex {
    param([Parameter(Mandatory = $true)][string] $Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function New-EvidenceFailure {
    param(
        [Parameter(Mandatory = $true)][string] $Reason,
        [Parameter(Mandatory = $true)][string] $Reference
    )

    return [pscustomobject]@{ Reason = $Reason; Evidence = $Reference }
}

function Get-EvidenceFailure {
    param(
        [Parameter(Mandatory = $true)][string] $Step,
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][AllowNull()][object] $Location,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Blocks,
        [Parameter(Mandatory = $true)][ValidateSet('evidence', 'baseline')][string] $Kind
    )

    $reference = $Step + '/' + $Name
    $missing = $Kind + '_missing'
    $invalid = $Kind + '_ref_invalid'
    $changed = $Kind + '_changed'

    $producer = $null
    foreach ($block in $Blocks) {
        if (($block.Type -ceq 'STEP') -and ([string]$block.Id -ceq $Step)) {
            $producer = $block.Json
            break
        }
    }

    $named = [System.Collections.Generic.List[object]]::new()
    if (Test-Field $producer 'evidence_refs') {
        foreach ($entry in @($producer.evidence_refs)) {
            if ((Test-Field $entry 'name') -and ([string]$entry.name -ceq $Name)) { $named.Add($entry) }
        }
    }
    if ($named.Count -eq 0) { return (New-EvidenceFailure -Reason $missing -Reference $reference) }
    if ($named.Count -gt 1) { return (New-EvidenceFailure -Reason $invalid -Reference $reference) }
    $ref = $named[0]
    if (($null -eq $Location) -or -not (Test-Field $ref 'path') -or -not (Test-Field $ref 'sha256')) {
        return (New-EvidenceFailure -Reason $invalid -Reference $reference)
    }

    $path = [string]$ref.path
    $pathMatch = [regex]::Match($path, '\Afeatures/([^/\\:]+)/([^/\\:]+)/evidence/([^/\\:]+)\z')
    if (-not $pathMatch.Success) { return (New-EvidenceFailure -Reason $invalid -Reference $reference) }
    $feature = $pathMatch.Groups[1].Value
    $unit = $pathMatch.Groups[2].Value
    $fileName = $pathMatch.Groups[3].Value
    if (($feature -cne [string]$Location.Feature) -or ($unit -cne [string]$Location.Unit)) {
        return (New-EvidenceFailure -Reason $invalid -Reference $reference)
    }
    $fileStem = $Step + '--' + $Name + '.'
    if (($fileName.Length -le $fileStem.Length) -or -not $fileName.StartsWith($fileStem, [System.StringComparison]::Ordinal)) {
        return (New-EvidenceFailure -Reason $invalid -Reference $reference)
    }

    $current = [string]$Location.Root
    $attributes = [System.IO.FileAttributes]::Normal
    foreach ($segment in @('features', $feature, $unit, 'evidence', $fileName)) {
        $current = [System.IO.Path]::Combine($current, $segment)
        try {
            $attributes = [System.IO.File]::GetAttributes($current)
        }
        catch {
            return (New-EvidenceFailure -Reason $missing -Reference $reference)
        }
        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            return (New-EvidenceFailure -Reason $invalid -Reference $reference)
        }
    }
    if (($attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
        return (New-EvidenceFailure -Reason $missing -Reference $reference)
    }

    if ((Get-FileSha256Hex -Path $current) -cne [string]$ref.sha256) {
        return (New-EvidenceFailure -Reason $changed -Reference $reference)
    }
    return $null
}

$grammarCodes = @()
$denialEvidence = ''

try {
    if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) { throw 'plan_missing' }
    $resolved = (Resolve-Path -LiteralPath $PlanPath).Path
    $text = [System.IO.File]::ReadAllText($resolved, [System.Text.Encoding]::UTF8)
    if ($text.Contains([string][char]0xFFFD)) { throw 'plan_invalid_utf8' }

    $parsed = Read-DeliveryBlocks -Text $text
    $stepIds = @($parsed.Blocks | Where-Object { $_.Type -ceq 'STEP' } | ForEach-Object { [string]$_.Id })
    $grammarIssues = [System.Collections.Generic.List[object]]::new()
    if (-not $parsed.Ok) {
        foreach ($issue in @($parsed.Errors)) { $grammarIssues.Add($issue) }
    }
    # Assign before enumerating: an empty result from the library is otherwise seen as one element.
    $requirementIssues = @(Test-DeliveryRequiredBlocks -Result $parsed -Kind PLAN -StepIds $stepIds)
    foreach ($issue in @($requirementIssues)) {
        $grammarIssues.Add($issue)
    }
    if ($grammarIssues.Count -gt 0) {
        $grammarCodes = @($grammarIssues | ForEach-Object { [string]$_.code } | Select-Object -Unique)
        if ($grammarCodes -contains 'legacy_step_marker') { throw 'legacy_marker' }
        throw 'grammar_invalid'
    }

    $planIdentity = Get-DeliveryNormativeIdentity -Text $text
    $progress = Get-BlockJson -Blocks @($parsed.Blocks) -Type 'PROGRESS'
    $checkpoint = Get-BlockJson -Blocks @($parsed.Blocks) -Type 'CHECKPOINT'
    $approval = Get-BlockJson -Blocks @($parsed.Blocks) -Type 'APPROVAL'
    if (-not (Test-Field $approval 'state') -or $approval.state -cne 'approved') { throw 'plan_not_approved' }
    if (-not (Test-Field $approval 'identity') -or $approval.identity -cne $planIdentity) { throw 'approval_identity_stale' }
    if (-not (Test-Field $approval 'input_identity') -or $approval.input_identity -cne $CurrentInputIdentity) { throw 'material_input_identity_stale' }
    if (-not (Test-Field $approval 'review_state') -or $approval.review_state -notin @('reviewed', 'bypassed')) { throw 'review_required' }
    if ($approval.review_state -ceq 'bypassed' -and
        ((-not (Test-Field $approval 'review_bypass_reason')) -or [string]::IsNullOrWhiteSpace([string]$approval.review_bypass_reason) -or
         (-not (Test-Field $approval 'review_bypass_operator_choice')) -or [string]$approval.review_bypass_operator_choice -cne 'bypass')) {
        throw 'review_bypass_evidence_missing'
    }
    if ((Test-Field $approval 'blocking_findings') -and @($approval.blocking_findings).Count -gt 0) { throw 'blocking_review_findings' }
    if ((Test-Field $approval 'unresolved_decisions') -and @($approval.unresolved_decisions).Count -gt 0) { throw 'material_decision_unresolved' }
    if (-not (Test-Field $progress 'cadence')) { throw 'cadence_missing' }
    if ($progress.cadence -cne $Cadence) { throw 'cadence_mismatch' }

    $declared = Get-DeliveryDeclaredSteps -Text $text
    $declaredSteps = @($declared.Steps)
    $location = Get-EvidenceLocation -PlanFullPath $resolved
    $locationKind = 'git'
    if ((Test-Field $checkpoint 'location_kind') -and ($checkpoint.location_kind -ceq 'directory')) { $locationKind = 'directory' }

    if ($locationKind -ceq 'directory') {
        $baselineText = [string]$checkpoint.baseline_evidence
        $baselineSeparator = $baselineText.IndexOf('/')
        $baselineFailure = Get-EvidenceFailure -Step $baselineText.Substring(0, $baselineSeparator) -Name $baselineText.Substring($baselineSeparator + 1) -Location $location -Blocks @($parsed.Blocks) -Kind 'baseline'
        if ($null -ne $baselineFailure) {
            $denialEvidence = [string]$baselineFailure.Evidence
            throw ([string]$baselineFailure.Reason)
        }
    }

    if ($Resume -and ($locationKind -ceq 'git')) {
        if (-not (Test-Field $checkpoint 'branch') -or $checkpoint.branch -cne $CurrentBranch) { throw 'branch_mismatch' }
        if (-not (Test-Field $checkpoint 'head') -or $checkpoint.head -cne $CurrentHead) { throw 'head_mismatch' }
    }

    $steps = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    $dependencies = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    $stepOrder = [System.Collections.Generic.List[string]]::new()
    foreach ($block in @($parsed.Blocks | Where-Object { $_.Type -ceq 'STEP' })) {
        $step = $block.Json
        $stepId = [string]$block.Id
        if (-not (Test-Field $step 'id') -or $step.id -cne $stepId -or -not (Test-Field $step 'status')) { throw 'step_block_invalid_shape' }
        $stepDependencies = [System.Collections.Generic.List[string]]::new()
        if (Test-Field $step 'depends_on') {
            if ($step.depends_on -isnot [System.Array]) { throw 'step_block_invalid_shape' }
            foreach ($dependency in @($step.depends_on)) {
                if ($dependency -isnot [string]) { throw 'step_block_invalid_shape' }
                $stepDependencies.Add($dependency)
            }
        }
        $steps[$stepId] = $step
        $dependencies[$stepId] = $stepDependencies
        $stepOrder.Add($stepId)
    }
    if ($steps.Count -eq 0) { throw 'step_blocks_missing' }
    if ((Test-Field $checkpoint 'active_step') -and -not [string]::IsNullOrWhiteSpace([string]$checkpoint.active_step)) {
        $activeId = [string]$checkpoint.active_step
        if (-not $steps.ContainsKey($activeId)) { throw 'checkpoint_active_step_missing' }
        if ($steps[$activeId].status -ceq 'IN_PROGRESS') { throw 'orphaned_in_progress_reconcile_required' }
        throw 'checkpoint_active_step_inconsistent'
    }
    foreach ($id in $stepOrder) {
        $step = $steps[$id]
        if ($step.status -ceq 'BLOCKED') { throw 'blocked_step_requires_resolution' }
        if ($step.status -ceq 'IN_PROGRESS') { throw 'orphaned_in_progress_reconcile_required' }
        foreach ($dependency in $dependencies[$id]) {
            if (-not $steps.ContainsKey($dependency) -or $dependency -ceq $id) { throw 'dependency_invalid' }
        }
    }
    $eligibleId = ''
    foreach ($id in $stepOrder) {
        $candidate = $steps[$id]
        if ($candidate.status -cne 'PENDING') { continue }
        $dependenciesReady = $true
        foreach ($dependency in $dependencies[$id]) {
            if ($steps[$dependency].status -cne 'COMPLETED') { $dependenciesReady = $false; break }
        }
        if ($dependenciesReady) { $eligibleId = $id; break }
    }
    if ([string]::IsNullOrWhiteSpace($eligibleId)) { throw 'no_eligible_step' }
    if ($Cadence -eq 'step_by_step' -and -not $StepAuthorization) { throw 'step_authorization_required' }
    if ($Cadence -eq 'continuous' -and -not $ContinuousAuthorization) { throw 'continuous_authorization_required' }

    $candidateNeeds = @()
    $candidateStartLine = 0
    $candidateEndLine = 0
    for ($declaredIndex = 0; $declaredIndex -lt $declaredSteps.Count; $declaredIndex++) {
        if ([string]$declaredSteps[$declaredIndex].Id -ceq $eligibleId) {
            $candidateNeeds = @($declaredSteps[$declaredIndex].Needs)
            $candidateStartLine = [int]$declaredSteps[$declaredIndex].Line
            $candidateEndLine = [int]::MaxValue
            if ($declaredIndex + 1 -lt $declaredSteps.Count) { $candidateEndLine = [int]$declaredSteps[$declaredIndex + 1].Line }
        }
    }
    foreach ($declaredError in @($declared.Errors)) {
        $errorLine = [int]$declaredError.line
        if (([string]$declaredError.code -ceq 'evidence_declaration_invalid') -and ($errorLine -ge $candidateStartLine) -and ($errorLine -lt $candidateEndLine)) {
            $denialEvidence = $eligibleId
            throw 'evidence_ref_invalid'
        }
    }
    foreach ($need in $candidateNeeds) {
        $needFailure = Get-EvidenceFailure -Step ([string]$need.Step) -Name ([string]$need.Name) -Location $location -Blocks @($parsed.Blocks) -Kind 'evidence'
        if ($null -ne $needFailure) {
            $denialEvidence = [string]$needFailure.Evidence
            throw ([string]$needFailure.Reason)
        }
    }

    return (New-Decision $true 'next_step_eligible' $eligibleId) | ConvertTo-Json -Compress
}
catch {
    $reason = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($reason)) { $reason = 'execution_state_invalid' }
    $decision = New-Decision $false $reason ''
    if ($grammarCodes.Count -gt 0) {
        $decision | Add-Member -NotePropertyName errors -NotePropertyValue $grammarCodes
    }
    if ($denialEvidence.Length -gt 0) {
        $decision | Add-Member -NotePropertyName evidence -NotePropertyValue $denialEvidence
    }
    $decision | ConvertTo-Json -Compress
    exit 1
}
