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
    [Parameter(Mandatory)][string]$RecordJson,
    [string]$AliasCatalogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\DeliveryGrammar.ps1')
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')

$target = Assert-DeliveryReviewTarget -RepoPath $RepoPath -TargetPath $TargetPath -TargetKind $TargetKind -Stage $Stage
$repoFull = $target.RepoFull
$targetFull = $target.TargetFull
$targetParts = $target.TargetParts
$featureFull = $target.FeatureFull

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
$recordFull = Resolve-DeliveryReviewRecordPath -RecordPath $RecordPath -FeatureFull $featureFull

$provided = $RecordJson | ConvertFrom-Json -Depth 50
Assert-DeliveryReviewRecordShape -Value $provided
$targetBlocks = Read-DeliveryBlocks -Text $ArtifactText
if (-not $targetBlocks.Ok) {
    $blockCodes = @($targetBlocks.Errors | ForEach-Object { [string]$_.code } | Select-Object -Unique)
    throw ('Target contains invalid DELIVERY blocks: {0}' -f ($blockCodes -join ', '))
}
$normativeIdentity = Get-DeliveryNormativeIdentity -Text $ArtifactText
$inputIdentity = [System.Collections.Generic.List[object]]::new()
foreach ($input in $provided.inputs) {
    if ([string]::IsNullOrWhiteSpace([string]$input.path) -or [string]::IsNullOrWhiteSpace([string]$input.id) -or [string]::IsNullOrWhiteSpace([string]$input.role)) { throw 'Each material input requires id, path, and role.' }
    if ($null -eq $input.PSObject.Properties['impacted_ids'] -or $input.impacted_ids -isnot [System.Array]) { throw 'Each material input requires impacted_ids as an array of strings.' }
    $usesSource = Test-DeliveryReviewInputUsesSource -InputEntry $input
    if (-not $usesSource) {
        try {
            Assert-DeliveryInputPathSegments -RelativePath ([string]$input.path)
        }
        catch {
            throw ("Input '{0}': {1}" -f $input.id, $_.Exception.Message)
        }
        $inputFull = Get-SafeFullPath $repoFull ([string]$input.path)
        Assert-NoReparseAncestors $inputFull $repoFull
        if (-not (Test-Path -LiteralPath $inputFull -PathType Leaf)) { throw "Material input is missing: $($input.path)" }
    }
    try {
        if ($usesSource) {
            $inputSha = Get-DeliveryInputSourceIdentity -RepoRoot $repoFull -InputSource $input -AliasCatalogPath $AliasCatalogPath
        }
        else {
            $inputSha = Get-DeliveryInputIdentity -RepoRoot $repoFull -RelativePath ([string]$input.path)
        }
    }
    catch {
        throw ("Input '{0}': {1}" -f $input.id, $_.Exception.Message)
    }
    $inputEntry = [ordered]@{
        id = [string]$input.id
        path = ([string]$input.path).Replace('\', '/')
        sha256 = $inputSha
        role = [string]$input.role
        impacted_ids = @($input.impacted_ids)
    }
    $sourceProperty = Get-DeliveryReviewRecordExactProperty -Object $input -Name 'source'
    if ($null -ne $sourceProperty) {
        $sourceValue = $sourceProperty.Value
        $sourceEcho = [ordered]@{ kind = [string]$sourceValue.kind }
        if ([string]$sourceValue.kind -ceq 'fileset') { $sourceEcho['files'] = @($sourceValue.files | ForEach-Object { [string]$_ }) }
        if ([string]$sourceValue.kind -ceq 'revision') { $sourceEcho['revision'] = [string]$sourceValue.revision }
        $inputEntry['source'] = [pscustomobject]$sourceEcho
    }
    $inputIdentity.Add([pscustomobject]$inputEntry)
}
$provided.schema = 'delivery-review-record/v2'
$materialInputIdentity = Get-DeliveryMaterialInputIdentity -Inputs $inputIdentity.ToArray()
$provided | Add-Member -NotePropertyName material_input_identity -NotePropertyValue $materialInputIdentity -Force
$targetBlock = [pscustomobject]@{
    path = $TargetPath.Replace('\', '/')
    kind = $TargetKind
    stage = $Stage
    content_sha256 = $normativeIdentity
    review_identity = ('0' * 64)
}
$provided | Add-Member -NotePropertyName target -NotePropertyValue $targetBlock -Force
$provided.inputs = @($inputIdentity.ToArray())
$targetBlock.review_identity = Get-DeliveryReviewRecordBindingIdentity -Record $provided -MaterialInputIdentity $materialInputIdentity
Assert-DeliveryReviewRecordShape -Value $provided
$provided.provenance = if ($null -eq $provided.provenance) { [ordered]@{} } else { $provided.provenance }
if ($provided.provenance -is [System.Collections.IDictionary]) {
    $provided.provenance['generated_at'] = [DateTime]::UtcNow.ToString('o')
    $provided.provenance['identity_rule'] = 'utf8-lf-no-bom; balanced DELIVERY operational blocks excluded; inputs rehashed'
} else {
    $provided.provenance | Add-Member -NotePropertyName generated_at -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
    $provided.provenance | Add-Member -NotePropertyName identity_rule -NotePropertyValue 'utf8-lf-no-bom; balanced DELIVERY operational blocks excluded; inputs rehashed' -Force
}

$parent = Split-Path -Parent $recordFull
Assert-NoReparseAncestors $recordFull $featureFull
New-Item -ItemType Directory -Path $parent -Force | Out-Null
$temp = Join-Path $parent ('.delivery-review-' + [guid]::NewGuid().ToString('N') + '.tmp')
try {
    $json = $provided | ConvertTo-Json -Depth 50
    [System.IO.File]::WriteAllText($temp, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::Move($temp, $recordFull, $true)
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
}
[pscustomobject]@{ status = 'saved'; state = $provided.state; review_identity = $targetBlock.review_identity; material_input_identity = $materialInputIdentity; record_path = $recordFull } | ConvertTo-Json -Compress
