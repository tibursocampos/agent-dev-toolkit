#Requires -Version 7.0

. (Join-Path $PSScriptRoot 'DeliveryGrammar.ps1')

function Get-Sha256Text([string]$Text) {
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return [Convert]::ToHexString($hash)
}

function Get-SafeFullPath([string]$Base, [string]$Relative) {
    if ([System.IO.Path]::IsPathRooted($Relative)) { throw "Expected repository-relative path: $Relative" }
    $baseFull = [System.IO.Path]::GetFullPath($Base).TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar, [char] [System.IO.Path]::AltDirectorySeparatorChar)
    $candidate = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($baseFull, $Relative))
    $prefix = $baseFull + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes repository root: $Relative" }
    return $candidate
}

function Assert-NoReparseAncestors([string]$Path, [string]$Boundary) {
    $full = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetFullPath($Boundary).TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar, [char] [System.IO.Path]::AltDirectorySeparatorChar)
    $cursor = $full
    while ($cursor.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        # Dangling junctions and symlinks fail Test-Path, so probe the item itself.
        $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)) { throw "Reparse-point path is not allowed: $cursor" }
        if ($cursor -eq $root) { return }
        $cursor = Split-Path -Parent $cursor
        if ([string]::IsNullOrEmpty($cursor)) { break }
    }
    throw 'Path is not contained by the expected boundary.'
}

function Get-DeliveryReviewRecordField {
    param(
        [AllowNull()][object] $Object,
        [Parameter(Mandatory = $true)][string] $Name
    )

    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-DeliveryReviewEnum {
    param(
        [AllowNull()][object] $Value,
        [Parameter(Mandatory = $true)][string[]] $Allowed
    )

    return (($Value -is [string]) -and ($Allowed -ccontains $Value))
}

function Assert-DeliveryReviewRecordShape {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object] $Value
    )

    if (-not (Test-DeliveryReviewEnum -Value $Value.schema -Allowed @('delivery-review-record/v1'))) { throw 'Record schema must be delivery-review-record/v1.' }
    $state = $Value.state
    if (-not (Test-DeliveryReviewEnum -Value $state -Allowed @('reviewed', 'bypassed', 'not_run'))) { throw 'Invalid review state.' }
    if ($null -eq $Value.reviewers -or $null -eq $Value.dispositions -or $null -eq $Value.inputs) { throw 'Record requires reviewers, dispositions, and inputs.' }

    foreach ($input in @($Value.inputs)) {
        foreach ($field in @('id', 'path', 'role')) {
            if ([string]::IsNullOrWhiteSpace([string](Get-DeliveryReviewRecordField -Object $input -Name $field))) { throw 'Each material input requires id, path, and role.' }
        }
        $impactedProperty = $input.PSObject.Properties['impacted_ids']
        if ($null -eq $impactedProperty -or $impactedProperty.Value -isnot [System.Array]) { throw 'Each material input requires impacted_ids as an array of strings.' }
        $impactedIds = $impactedProperty.Value
        foreach ($impactedId in $impactedIds) {
            if ($impactedId -isnot [string]) { throw 'Each material input requires impacted_ids as an array of strings.' }
        }
    }

    $allFindingIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $severityById = @{}
    $dispositionIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    if (Test-DeliveryReviewEnum -Value $state -Allowed @('bypassed', 'not_run')) {
        $reviewerEntries = @($Value.reviewers.PSObject.Properties)
        if ($reviewerEntries.Count -gt 0 -or @($Value.dispositions).Count -gt 0) {
            throw 'A bypassed or not_run record cannot carry reviewer findings or dispositions.'
        }
    }
    if (Test-DeliveryReviewEnum -Value $state -Allowed @('reviewed')) {
        foreach ($role in @('reader', 'critic')) {
            if ($null -eq $Value.reviewers.$role -or $null -eq $Value.reviewers.$role.result) { throw "Reviewed state requires a structured $role result." }
            if ([string]::IsNullOrWhiteSpace([string]$Value.reviewers.$role.host) -or [string]::IsNullOrWhiteSpace([string]$Value.reviewers.$role.observed_isolation)) { throw "$role result requires host and observed isolation metadata." }
            if ($null -eq $Value.reviewers.$role.result.lenses -or $Value.reviewers.$role.result.lenses.Count -lt 1) { throw "$role result must declare at least one covered lens." }
            if ($null -eq $Value.reviewers.$role.result.findings) { throw "$role result must include its complete findings array, including an empty array when there are no findings." }
        }
        if ([string]::IsNullOrWhiteSpace([string]$Value.reviewers.reader.result.paraphrases.proposal) -or [string]::IsNullOrWhiteSpace([string]$Value.reviewers.reader.result.paraphrases.current_system)) { throw 'Reader result requires both independent paraphrases.' }
        foreach ($role in @('reader', 'critic')) {
            foreach ($finding in $Value.reviewers.$role.result.findings) {
                foreach ($field in @('id', 'severity', 'category', 'section', 'evidence', 'recommendation')) {
                    if ([string]::IsNullOrWhiteSpace([string]$finding.$field)) { throw "$role finding is missing $field." }
                }
                if (-not (Test-DeliveryReviewEnum -Value $finding.severity -Allowed @('B', 'I', 'MINOR'))) { throw "Finding $($finding.id) has invalid severity." }
                if (-not $allFindingIds.Add([string]$finding.id)) { throw "Duplicate finding ID: $($finding.id)" }
                $severityById[[string]$finding.id] = [string]$finding.severity
            }
        }
    }
    foreach ($finding in @($Value.dispositions)) {
        $dispositionSeverity = Get-DeliveryReviewRecordField -Object $finding -Name 'severity'
        $dispositionState = Get-DeliveryReviewRecordField -Object $finding -Name 'disposition'
        $dispositionEvidence = Get-DeliveryReviewRecordField -Object $finding -Name 'evidence'
        $dispositionReason = Get-DeliveryReviewRecordField -Object $finding -Name 'reason'
        if ([string]::IsNullOrWhiteSpace([string]$finding.id) -or -not $dispositionIds.Add([string]$finding.id)) { throw 'Every disposition requires a unique finding ID.' }
        if (-not (Test-DeliveryReviewEnum -Value $dispositionSeverity -Allowed @('B', 'I', 'MINOR'))) { throw "Disposition $($finding.id) has invalid severity." }
        if ($severityById.ContainsKey([string]$finding.id) -and $severityById[[string]$finding.id] -cne $dispositionSeverity) { throw "Disposition severity does not match finding $($finding.id)." }
        $isBlocking = Test-DeliveryReviewEnum -Value $dispositionSeverity -Allowed @('B', 'I')
        if ($isBlocking -and -not (Test-DeliveryReviewEnum -Value $dispositionState -Allowed @('resolved', 'contested'))) { throw "Blocking finding $($finding.id) is not resolved or contested." }
        if ($isBlocking -and [string]::IsNullOrWhiteSpace([string]$dispositionEvidence)) { throw "Blocking finding $($finding.id) disposition requires evidence." }
        if ((Test-DeliveryReviewEnum -Value $dispositionSeverity -Allowed @('MINOR')) -and (-not (Test-DeliveryReviewEnum -Value $dispositionState -Allowed @('accepted_minor', 'resolved', 'contested')) -or [string]::IsNullOrWhiteSpace([string]$dispositionReason))) { throw "MINOR finding $($finding.id) requires a reasoned disposition." }
    }
    if (Test-DeliveryReviewEnum -Value $state -Allowed @('reviewed')) {
        foreach ($id in $allFindingIds) { if (-not $dispositionIds.Contains($id)) { throw "Finding $id has no disposition." } }
        foreach ($id in $dispositionIds) { if (-not $allFindingIds.Contains($id)) { throw "Disposition references unknown finding $id." } }
    }
    $choice = Get-DeliveryReviewRecordField -Object $Value -Name 'operator_choice'
    if (Test-DeliveryReviewEnum -Value $state -Allowed @('bypassed')) {
        $choiceValue = Get-DeliveryReviewRecordField -Object $choice -Name 'choice'
        $choiceEvidence = Get-DeliveryReviewRecordField -Object $choice -Name 'evidence'
        if ($null -eq $choice -or -not (Test-DeliveryReviewEnum -Value $choiceValue -Allowed @('bypass')) -or [string]::IsNullOrWhiteSpace([string]$choiceEvidence)) { throw 'Bypass requires explicit operator_choice evidence.' }
        if ([string]::IsNullOrWhiteSpace([string](Get-DeliveryReviewRecordField -Object $Value -Name 'reason'))) { throw 'Bypass requires a reason.' }
    }
    if ((Test-DeliveryReviewEnum -Value $state -Allowed @('not_run')) -and [string]::IsNullOrWhiteSpace([string](Get-DeliveryReviewRecordField -Object $Value -Name 'reason'))) { throw 'not_run requires a reason.' }
    $approval = Get-DeliveryReviewRecordField -Object $Value -Name 'approval'
    $approvalStatus = Get-DeliveryReviewRecordField -Object $approval -Name 'status'
    if ($null -ne $approval -and $approvalStatus -is [string] -and $approvalStatus -ieq 'approved') {
        if ($approvalStatus -cne 'approved') { throw "Approval status must be exactly 'approved'." }
        $approvalChoice = Get-DeliveryReviewRecordField -Object $approval -Name 'operator_choice'
        $approvalChoiceValue = Get-DeliveryReviewRecordField -Object $approvalChoice -Name 'choice'
        $approvalEvidence = Get-DeliveryReviewRecordField -Object $approvalChoice -Name 'evidence'
        if ($null -eq $approvalChoice -or -not (Test-DeliveryReviewEnum -Value $approvalChoiceValue -Allowed @('content_approval')) -or [string]::IsNullOrWhiteSpace([string]$approvalEvidence)) { throw 'Content approval requires approval.operator_choice with content_approval evidence.' }
    }
}

function Assert-DeliveryReviewTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RepoPath,
        [Parameter(Mandatory = $true)][string] $TargetPath,
        [Parameter(Mandatory = $true)][ValidateSet('REFINEMENT.md', 'PLAN.md')][string] $TargetKind,
        [Parameter(Mandatory = $true)][ValidateSet('delivery_refinement_review', 'delivery_unit_plan_review')][string] $Stage
    )

    if ($TargetKind -eq 'REFINEMENT.md' -and $Stage -ne 'delivery_refinement_review') { throw 'Target kind and stage do not match.' }
    if ($TargetKind -eq 'PLAN.md' -and $Stage -ne 'delivery_unit_plan_review') { throw 'Target kind and stage do not match.' }
    $repoFull = [System.IO.Path]::GetFullPath($RepoPath)
    Assert-NoReparseAncestors $repoFull $repoFull
    $targetFull = Get-SafeFullPath $repoFull $TargetPath
    Assert-NoReparseAncestors $targetFull $repoFull
    $targetLeaf = Split-Path -Leaf $TargetPath
    if ($targetLeaf -cne $TargetKind) { throw 'Canonical target filename does not match target kind.' }
    $targetParts = $TargetPath -split '[\\/]'
    if ($targetParts.Count -lt 2 -or $targetParts -contains '' -or $targetParts -contains '.' -or $targetParts -contains '..' -or
        $targetParts[0] -cne 'features' -or $targetParts[1] -notmatch '^\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*$') {
        throw 'Target must use a canonical features/NNN-slug path.'
    }
    if ($TargetKind -eq 'REFINEMENT.md' -and ($targetParts.Count -ne 3 -or $targetParts[2] -cne 'REFINEMENT.md')) {
        throw 'A feature refinement target must be features/NNN-slug/REFINEMENT.md.'
    }
    if ($TargetKind -eq 'PLAN.md' -and ($targetParts.Count -ne 4 -or $targetParts[2] -notmatch '^(?:US|TS)\d{2}$' -or $targetParts[3] -cne 'PLAN.md')) {
        throw 'A unit plan target must be features/NNN-slug/(USnn|TSnn)/PLAN.md.'
    }
    $featureRelative = $targetParts[0] + '/' + $targetParts[1]
    $featureFull = Get-SafeFullPath $repoFull $featureRelative

    return [pscustomobject]@{
        RepoFull    = $repoFull
        TargetFull  = $targetFull
        TargetParts = $targetParts
        FeatureFull = $featureFull
    }
}

function Resolve-DeliveryReviewRecordPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RecordPath,
        [Parameter(Mandatory = $true)][string] $FeatureFull
    )

    $recordFull = [System.IO.Path]::GetFullPath($RecordPath)
    $recordsRoot = [System.IO.Path]::GetFullPath((Join-Path $FeatureFull 'delivery-reviews')).TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $recordFull.StartsWith($recordsRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'RecordPath must be inside the feature delivery-reviews directory.' }
    Assert-NoReparseAncestors $recordFull $FeatureFull
    return $recordFull
}

function Get-DeliveryReviewIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $TargetKind,
        [Parameter(Mandatory = $true)][string] $Stage,
        [Parameter(Mandatory = $true)][string] $TargetPath,
        [Parameter(Mandatory = $true)][string] $NormativeSha,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Inputs
    )

    $inputIdentity = [System.Collections.Generic.List[object]]::new()
    foreach ($input in $Inputs) {
        $inputIdentity.Add([ordered]@{
            id = [string]$input.id
            path = ([string]$input.path).Replace('\', '/')
            sha256 = [string]$input.sha256
            role = [string]$input.role
            impacted_ids = @($input.impacted_ids)
        })
    }
    $identityPayload = [ordered]@{
        target_kind = $TargetKind
        stage = $Stage
        target_path = $TargetPath.Replace('\', '/')
        normative_content_sha256 = $NormativeSha
        inputs = @($inputIdentity)
    }
    $identityJson = $identityPayload | ConvertTo-Json -Depth 20 -Compress
    return Get-Sha256Text $identityJson
}
