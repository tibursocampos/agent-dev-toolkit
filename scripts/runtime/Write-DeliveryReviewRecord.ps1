[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('save')][string]$Action,
    [Parameter(Mandatory)][string]$RepoPath,
    [Parameter(Mandatory)][string]$TargetPath,
    [string]$SnapshotPath,
    [Parameter(Mandatory)][ValidateSet('REFINEMENT.md', 'PLAN.md')][string]$TargetKind,
    [Parameter(Mandatory)][ValidateSet('delivery_refinement_review', 'delivery_unit_plan_review')][string]$Stage,
    [Parameter(Mandatory)][string]$ArtifactText,
    [Parameter(Mandatory)][string]$RecordPath,
    [Parameter(Mandatory)][string]$RecordJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Reparse-point path is not allowed: $cursor" }
        }
        if ($cursor -eq $root) { return }
        $cursor = Split-Path -Parent $cursor
        if ([string]::IsNullOrEmpty($cursor)) { break }
    }
    throw 'Path is not contained by the expected boundary.'
}

function Get-NormativeContent([string]$Text) {
    if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) { $Text = $Text.Substring(1) }
    $Text = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    $marker = '<!-- DELIVERY:(PROGRESS|CHECKPOINT|APPROVAL|STEP:[A-Za-z0-9][A-Za-z0-9._-]*):(BEGIN|END) -->'
    foreach ($candidate in [regex]::Matches($Text, '<!-- DELIVERY:[^>]*-->')) {
        if (-not [regex]::IsMatch($candidate.Value, '^' + $marker + '$')) { throw "Unknown or malformed DELIVERY marker: $($candidate.Value)" }
        $before = $candidate.Index -gt 0 -and $Text[$candidate.Index - 1] -ne "`n"
        $afterIndex = $candidate.Index + $candidate.Length
        $after = $afterIndex -lt $Text.Length -and $Text[$afterIndex] -ne "`n"
        if ($before -or $after) { throw 'DELIVERY markers must occupy a complete line.' }
    }
    $matches = [regex]::Matches($Text, $marker)
    $counts = @{}
    $open = $null
    foreach ($match in $matches) {
        $name = $match.Groups[1].Value
        $edge = $match.Groups[2].Value
        if ($edge -eq 'BEGIN') {
            if ($null -ne $open) { throw 'Nested or overlapping DELIVERY operational blocks are invalid.' }
            if ($counts.ContainsKey($name)) { throw "Duplicate DELIVERY operational block: $name" }
            $counts[$name] = 0
            $open = $name
        } else {
            if ($null -eq $open -or $open -ne $name) { throw "Unmatched DELIVERY operational block end: $name" }
            $counts[$name] = 1
            $open = $null
        }
    }
    if ($null -ne $open) { throw "Unclosed DELIVERY operational block: $open" }
    foreach ($required in @('PROGRESS', 'CHECKPOINT', 'APPROVAL')) {
        if (-not $counts.ContainsKey($required)) { throw "Missing DELIVERY operational block: $required" }
    }
    if (-not ($counts.Keys | Where-Object { $_ -like 'STEP:*' })) { throw 'At least one DELIVERY STEP block is required.' }
    $withoutOperational = [regex]::Replace($Text, '(?ms)^<!-- DELIVERY:(?:PROGRESS|CHECKPOINT|APPROVAL|STEP:[A-Za-z0-9][A-Za-z0-9._-]*):BEGIN -->\n.*?^<!-- DELIVERY:(?:PROGRESS|CHECKPOINT|APPROVAL|STEP:[A-Za-z0-9][A-Za-z0-9._-]*):END -->\n?', '')
    return $withoutOperational
}

function Assert-Record([object]$Value) {
    if ($Value.schema -ne 'delivery-review-record/v1') { throw 'Record schema must be delivery-review-record/v1.' }
    if ($Value.state -notin @('reviewed', 'bypassed', 'not_run')) { throw 'Invalid review state.' }
    if ($null -eq $Value.reviewers -or $null -eq $Value.dispositions -or $null -eq $Value.inputs) { throw 'Record requires reviewers, dispositions, and inputs.' }
    $allFindingIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $severityById = @{}
    if ($Value.state -eq 'reviewed') {
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
                if ($finding.severity -notin @('B', 'I', 'MINOR')) { throw "Finding $($finding.id) has invalid severity." }
                if (-not $allFindingIds.Add([string]$finding.id)) { throw "Duplicate finding ID: $($finding.id)" }
                $severityById[[string]$finding.id] = [string]$finding.severity
            }
        }
        $dispositionIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    }
    foreach ($finding in $Value.dispositions) {
        if ([string]::IsNullOrWhiteSpace([string]$finding.id) -or -not $dispositionIds.Add([string]$finding.id)) { throw 'Every disposition requires a unique finding ID.' }
        if ($finding.severity -notin @('B', 'I', 'MINOR')) { throw "Disposition $($finding.id) has invalid severity." }
        if ($severityById.ContainsKey([string]$finding.id) -and $severityById[[string]$finding.id] -ne $finding.severity) { throw "Disposition severity does not match finding $($finding.id)." }
        if ($finding.severity -in @('B', 'I') -and $finding.disposition -notin @('resolved', 'contested')) { throw "Blocking finding $($finding.id) is not resolved or contested." }
        if ($finding.severity -in @('B', 'I') -and [string]::IsNullOrWhiteSpace([string]$finding.evidence)) { throw "Blocking finding $($finding.id) disposition requires evidence." }
        if ($finding.severity -eq 'MINOR' -and ($finding.disposition -notin @('accepted_minor', 'resolved', 'contested') -or [string]::IsNullOrWhiteSpace([string]$finding.reason))) { throw "MINOR finding $($finding.id) requires a reasoned disposition." }
    }
    if ($Value.state -eq 'reviewed') {
        foreach ($id in $allFindingIds) { if (-not $dispositionIds.Contains($id)) { throw "Finding $id has no disposition." } }
        foreach ($id in $dispositionIds) { if (-not $allFindingIds.Contains($id)) { throw "Disposition references unknown finding $id." } }
    }
    $choice = $Value.PSObject.Properties['operator_choice']
    if ($Value.state -eq 'bypassed' -and ($null -eq $choice -or $choice.Value.choice -ne 'bypass' -or [string]::IsNullOrWhiteSpace([string]$choice.Value.evidence))) { throw 'Bypass requires explicit operator_choice evidence.' }
    if ($Value.state -eq 'not_run' -and [string]::IsNullOrWhiteSpace([string]$Value.reason)) { throw 'not_run requires a reason.' }
    $approval = $Value.PSObject.Properties['approval']
    if ($null -ne $approval -and $approval.Value.status -eq 'approved' -and ($null -eq $choice -or $choice.Value.choice -ne 'content_approval' -or [string]::IsNullOrWhiteSpace([string]$choice.Value.evidence))) { throw 'Content approval requires explicit operator_choice evidence.' }
}

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

# A cold review may precede the approval-authorized write of the canonical artifact.
# In that case, bind the review to a controlled feature-local scratch snapshot, never to
# an unbound caller string. Existing canonical-target callers retain the same snapshot check.
$snapshotFull = $targetFull
if (-not [string]::IsNullOrWhiteSpace($SnapshotPath)) {
    $snapshotParts = $SnapshotPath -split '[\\/]'
    if ($snapshotParts.Count -lt 5 -or $snapshotParts[0] -cne 'features' -or
        $snapshotParts[1] -cne $targetParts[1] -or $snapshotParts[2] -cne 'scratch' -or
        $snapshotParts[3] -cne 'delivery-review' -or $snapshotParts -contains '' -or
        $snapshotParts -contains '.' -or $snapshotParts -contains '..') {
        throw 'SnapshotPath must be under the selected feature scratch/delivery-review directory.'
    }
    $snapshotFull = Get-SafeFullPath $repoFull $SnapshotPath
    $snapshotRoot = [System.IO.Path]::GetFullPath((Join-Path $featureFull 'scratch\delivery-review')).TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $snapshotFull.StartsWith($snapshotRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'SnapshotPath escapes the controlled feature review-snapshot directory.' }
    Assert-NoReparseAncestors $snapshotFull $featureFull
} elseif (-not (Test-Path -LiteralPath $targetFull -PathType Leaf)) {
    throw 'Canonical target is missing; a controlled SnapshotPath is required for a draft review.'
}
if (-not (Test-Path -LiteralPath $snapshotFull -PathType Leaf)) { throw 'The designated review snapshot does not exist.' }
$diskText = [System.IO.File]::ReadAllText($snapshotFull)
$artifactComparable = $ArtifactText
if ($artifactComparable.Length -gt 0 -and $artifactComparable[0] -eq [char]0xFEFF) { $artifactComparable = $artifactComparable.Substring(1) }
if ($diskText.Length -gt 0 -and $diskText[0] -eq [char]0xFEFF) { $diskText = $diskText.Substring(1) }
$artifactComparable = $artifactComparable.Replace("`r`n", "`n").Replace("`r", "`n")
$diskText = $diskText.Replace("`r`n", "`n").Replace("`r", "`n")
if ($diskText -cne $artifactComparable) { throw 'ArtifactText does not match the designated on-disk snapshot.' }
$recordFull = [System.IO.Path]::GetFullPath($RecordPath)
$recordsRoot = [System.IO.Path]::GetFullPath((Join-Path $featureFull 'delivery-reviews')).TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if (-not $recordFull.StartsWith($recordsRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'RecordPath must be inside the feature delivery-reviews directory.' }
Assert-NoReparseAncestors $recordFull $featureFull

$provided = $RecordJson | ConvertFrom-Json -Depth 50
Assert-Record $provided
$normative = Get-NormativeContent $ArtifactText
$inputIdentity = [System.Collections.Generic.List[object]]::new()
foreach ($input in $provided.inputs) {
    if ([string]::IsNullOrWhiteSpace([string]$input.path) -or [string]::IsNullOrWhiteSpace([string]$input.id) -or [string]::IsNullOrWhiteSpace([string]$input.role)) { throw 'Each material input requires id, path, and role.' }
    $inputFull = Get-SafeFullPath $repoFull ([string]$input.path)
    Assert-NoReparseAncestors $inputFull $repoFull
    if (-not (Test-Path -LiteralPath $inputFull -PathType Leaf)) { throw "Material input is missing: $($input.path)" }
    $inputIdentity.Add([ordered]@{
        id = [string]$input.id
        path = ([string]$input.path).Replace('\', '/')
        sha256 = (Get-FileHash -LiteralPath $inputFull -Algorithm SHA256).Hash
        role = [string]$input.role
        impacted_ids = @($input.impacted_ids)
    })
}
$identityPayload = [ordered]@{
    target_kind = $TargetKind
    stage = $Stage
    target_path = $TargetPath.Replace('\', '/')
    normative_content_sha256 = (Get-Sha256Text $normative)
    inputs = @($inputIdentity)
}
$identityJson = $identityPayload | ConvertTo-Json -Depth 20 -Compress
$reviewIdentity = Get-Sha256Text $identityJson
$provided | Add-Member -NotePropertyName target -NotePropertyValue ([ordered]@{
    path = $TargetPath.Replace('\', '/')
    kind = $TargetKind
    stage = $Stage
    content_sha256 = $identityPayload.normative_content_sha256
    review_identity = $reviewIdentity
}) -Force
$provided.inputs = @($inputIdentity)
$provided.provenance = if ($null -eq $provided.provenance) { [ordered]@{} } else { $provided.provenance }
if ($provided.provenance -is [System.Collections.IDictionary]) {
    $provided.provenance['generated_at'] = [DateTime]::UtcNow.ToString('o')
    $provided.provenance['identity_rule'] = 'utf8-lf-no-bom; balanced DELIVERY operational blocks excluded; inputs rehashed'
} else {
    $provided.provenance | Add-Member -NotePropertyName generated_at -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
    $provided.provenance | Add-Member -NotePropertyName identity_rule -NotePropertyValue 'utf8-lf-no-bom; balanced DELIVERY operational blocks excluded; inputs rehashed' -Force
}

$parent = Split-Path -Parent $recordFull
New-Item -ItemType Directory -Path $parent -Force | Out-Null
Assert-NoReparseAncestors $recordFull $featureFull
$temp = Join-Path $parent ('.delivery-review-' + [guid]::NewGuid().ToString('N') + '.tmp')
try {
    $json = $provided | ConvertTo-Json -Depth 50
    [System.IO.File]::WriteAllText($temp, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::Move($temp, $recordFull, $true)
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
}
[pscustomobject]@{ status = 'saved'; state = $provided.state; review_identity = $reviewIdentity; record_path = $recordFull } | ConvertTo-Json -Compress
