#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('reviewed', 'bypassed', 'not_run')][string]$State,
    [Parameter(Mandatory)][string]$RepoPath,
    [string]$ReaderResultPath,
    [string]$CriticResultPath,
    [string]$ReaderHost,
    [string]$ReaderIsolation,
    [string]$CriticHost,
    [string]$CriticIsolation,
    [string]$InputsPath,
    [string]$DispositionsPath,
    [string]$BypassEvidence,
    [string]$Reason,
    [string]$ApprovalEvidence,
    [string]$RequestedModel,
    [string]$RequestedEffort,
    [int]$Round = 1,
    [string]$PriorReviewIdentity,
    [string]$RoundsPath,
    [Parameter(Mandatory)][string]$OutPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')

$severityValues = @('B', 'I', 'MINOR')

function Assert-Required([string]$Value, [string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Value)) { throw "-$Name is required for state $State." }
}

function Get-Prop([object]$Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return , $property.Value
}

function ConvertTo-Items($Value) {
    if ($null -eq $Value) { return , @() }
    return , @($Value)
}

function Read-JsonDocument([string]$Path, [string]$Label) {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label file not found: $Path"
    }
    try {
        $parsed = [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
    }
    catch {
        throw "$Label is not valid JSON: $Path"
    }
    return , $parsed
}

function Get-Severity([object]$Value, [string]$Context) {
    $normalized = ([string]$Value).Trim().ToUpperInvariant()
    if ($normalized -notin $severityValues) { throw "$Context has invalid severity: '$Value'." }
    return $normalized
}

function ConvertTo-ReviewFindings([object]$Raw, [string]$Role) {
    if ($null -eq $Raw) { return $null }
    $items = [System.Collections.Generic.List[object]]::new()
    foreach ($source in (ConvertTo-Items $Raw)) {
        if ($source -isnot [pscustomobject]) { throw "$Role finding must be a JSON object." }
        $finding = [ordered]@{}
        foreach ($property in $source.PSObject.Properties) {
            switch -CaseSensitive ($property.Name) {
                'late' {
                    if ($property.Value -isnot [bool]) { throw "$Role finding '$($source.id)' late must be a JSON boolean." }
                }
                'repeats' {
                    if (($property.Value -isnot [string]) -or [string]::IsNullOrWhiteSpace($property.Value)) { throw "$Role finding '$($source.id)' repeats must be a non-blank string." }
                }
            }
            $finding[$property.Name] = $property.Value
        }
        if ($finding.Contains('location')) {
            if ($null -eq $finding['section']) { $finding['section'] = $finding['location'] }
            $finding.Remove('location')
        }
        $finding['severity'] = Get-Severity $finding['severity'] "$Role finding '$($finding['id'])'"
        $items.Add($finding)
    }
    return , $items.ToArray()
}

function Get-ConfinedOutPath([string]$RepoFull, [string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [System.IO.Path]::IsPathRooted($RelativePath)) {
        throw 'OutPath must be a repository-relative path.'
    }
    $parts = $RelativePath -split '[\\/]'
    if ($parts.Count -lt 5 -or $parts -contains '' -or $parts -contains '.' -or $parts -contains '..' -or
        $parts[0] -cne 'features' -or $parts[1] -notmatch '^\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*$' -or
        $parts[2] -cne 'scratch' -or $parts[3] -cne 'delivery-review' -or $parts[-1] -notmatch '\.json$') {
        throw 'OutPath must be features/NNN-slug/scratch/delivery-review/<name>.json.'
    }
    $outFull = Get-SafeFullPath $RepoFull $RelativePath
    $scratchRoot = (Get-SafeFullPath $RepoFull ($parts[0] + '/' + $parts[1] + '/scratch/delivery-review')).TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $outFull.StartsWith($scratchRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'OutPath escapes the feature scratch/delivery-review directory.'
    }
    Assert-NoReparseAncestors $outFull $RepoFull
    return $outFull
}

if ($State -eq 'reviewed') {
    Assert-Required $ReaderResultPath 'ReaderResultPath'
    Assert-Required $CriticResultPath 'CriticResultPath'
    Assert-Required $ReaderHost 'ReaderHost'
    Assert-Required $ReaderIsolation 'ReaderIsolation'
    Assert-Required $CriticHost 'CriticHost'
    Assert-Required $CriticIsolation 'CriticIsolation'
    Assert-Required $InputsPath 'InputsPath'
}
if ($State -eq 'bypassed') {
    Assert-Required $BypassEvidence 'BypassEvidence'
    Assert-Required $Reason 'Reason'
}
if ($State -eq 'not_run') {
    Assert-Required $Reason 'Reason'
}
if ([string]::IsNullOrWhiteSpace($RequestedModel) -ne [string]::IsNullOrWhiteSpace($RequestedEffort)) {
    throw '-RequestedModel and -RequestedEffort must be given together.'
}
if ($Round -lt 1) { throw '-Round must be an integer greater than or equal to 1.' }
$hasPriorIdentity = -not [string]::IsNullOrWhiteSpace($PriorReviewIdentity)
if ($Round -ge 2 -and -not $hasPriorIdentity) { throw '-PriorReviewIdentity is required when -Round is 2 or greater.' }
if ($Round -lt 2 -and $hasPriorIdentity) { throw '-PriorReviewIdentity is allowed only when -Round is 2 or greater.' }
if ($hasPriorIdentity -and $PriorReviewIdentity -cnotmatch '\A[0-9A-F]{64}\z') { throw '-PriorReviewIdentity must be 64 uppercase hexadecimal characters.' }

$repoFull = [System.IO.Path]::GetFullPath($RepoPath)
$outFull = Get-ConfinedOutPath $repoFull $OutPath
if (Test-Path -LiteralPath $outFull) { throw "Refusing to overwrite existing file: $outFull" }

$reviewers = [ordered]@{}
$dispositions = [System.Collections.Generic.List[object]]::new()
$inputs = [System.Collections.Generic.List[object]]::new()
$findingIds = [System.Collections.Generic.List[string]]::new()
$severityById = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::Ordinal)
$seenFindingIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$dispositionIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$counts = [ordered]@{ B = 0; I = 0; MINOR = 0; late = 0; repeats = 0 }

if ($State -eq 'reviewed') {
    $readerRaw = Read-JsonDocument $ReaderResultPath 'ReaderResultPath'
    $criticRaw = Read-JsonDocument $CriticResultPath 'CriticResultPath'
    if ($readerRaw -isnot [pscustomobject]) { throw 'Reader result must be a JSON object.' }
    if ($criticRaw -isnot [pscustomobject]) { throw 'Critic result must be a JSON object.' }

    $readerFindings = ConvertTo-ReviewFindings (Get-Prop $readerRaw 'findings') 'reader'
    $criticFindings = ConvertTo-ReviewFindings (Get-Prop $criticRaw 'findings') 'critic'

    $reviewers['reader'] = [ordered]@{
        host               = $ReaderHost
        observed_isolation = $ReaderIsolation
        result             = [ordered]@{
            paraphrases = Get-Prop $readerRaw 'paraphrases'
            lenses      = Get-Prop $readerRaw 'lenses'
            findings    = $readerFindings
        }
    }
    $reviewers['critic'] = [ordered]@{
        host               = $CriticHost
        observed_isolation = $CriticIsolation
        result             = [ordered]@{
            lenses   = Get-Prop $criticRaw 'lenses'
            findings = $criticFindings
        }
    }

    foreach ($finding in @((ConvertTo-Items $readerFindings) + (ConvertTo-Items $criticFindings))) {
        $id = [string]$finding['id']
        if (-not $seenFindingIds.Add($id)) { throw "Duplicate finding id: $id" }
        $severity = [string]$finding['severity']
        $severityById[$id] = $severity
        $counts[$severity] = $counts[$severity] + 1
        if (($finding.Keys -ccontains 'late') -and ($finding['late'] -eq $true)) { $counts['late'] = $counts['late'] + 1 }
        if ($finding.Keys -ccontains 'repeats') { $counts['repeats'] = $counts['repeats'] + 1 }
        $findingIds.Add($id)
    }

    if (-not [string]::IsNullOrWhiteSpace($DispositionsPath)) {
        foreach ($source in (ConvertTo-Items (Read-JsonDocument $DispositionsPath 'DispositionsPath'))) {
            if ($source -isnot [pscustomobject]) { throw 'Disposition must be a JSON object.' }
            $id = [string](Get-Prop $source 'id')
            if (-not $dispositionIds.Add($id)) { throw "Duplicate disposition id: $id" }
            $entry = [ordered]@{}
            foreach ($property in $source.PSObject.Properties) { $entry[$property.Name] = $property.Value }
            $severityValue = Get-Prop $source 'severity'
            if ($null -ne $severityValue) {
                $entry['severity'] = Get-Severity $severityValue "Disposition '$id'"
            }
            elseif ($severityById.ContainsKey($id)) {
                $entry['severity'] = $severityById[$id]
            }
            $dispositions.Add($entry)
        }
    }
}

$roundEntries = [System.Collections.Generic.List[object]]::new()
if (-not [string]::IsNullOrWhiteSpace($RoundsPath)) {
    foreach ($source in (ConvertTo-Items (Read-JsonDocument $RoundsPath 'RoundsPath'))) { $roundEntries.Add($source) }
}

if (-not [string]::IsNullOrWhiteSpace($InputsPath)) {
    foreach ($source in (ConvertTo-Items (Read-JsonDocument $InputsPath 'InputsPath'))) {
        if ($source -isnot [pscustomobject]) { throw 'Input must be a JSON object.' }
        $inputEntry = [ordered]@{
            id           = Get-Prop $source 'id'
            path         = Get-Prop $source 'path'
            role         = Get-Prop $source 'role'
            impacted_ids = ConvertTo-Items (Get-Prop $source 'impacted_ids')
        }
        $sourceProperty = Get-DeliveryReviewRecordExactProperty -Object $source -Name 'source'
        if ($null -ne $sourceProperty) { $inputEntry['source'] = $sourceProperty.Value }
        $inputs.Add($inputEntry)
    }
}

$record = [ordered]@{
    schema       = 'delivery-review-record/v1'
    state        = $State
    reviewers    = $reviewers
    dispositions = $dispositions.ToArray()
    inputs       = $inputs.ToArray()
    provenance   = [ordered]@{}
}
switch ($State) {
    'bypassed' {
        $record['reason'] = $Reason
        $record['operator_choice'] = [ordered]@{
            choice   = 'bypass'
            evidence = $BypassEvidence
            date     = [DateTime]::UtcNow.ToString('o')
        }
    }
    'not_run' {
        $record['reason'] = $Reason
    }
}
if (-not [string]::IsNullOrWhiteSpace($ApprovalEvidence)) {
    $record['approval'] = [ordered]@{
        status          = 'approved'
        operator_choice = [ordered]@{
            choice   = 'content_approval'
            evidence = $ApprovalEvidence
        }
    }
}
if (-not [string]::IsNullOrWhiteSpace($RequestedModel)) {
    $record['provenance']['requested_model'] = $RequestedModel
    $record['provenance']['requested_effort'] = $RequestedEffort
}
$record['round'] = $Round
if ($hasPriorIdentity) { $record['prior_review_identity'] = $PriorReviewIdentity }
if (-not [string]::IsNullOrWhiteSpace($RoundsPath)) { $record['rounds'] = $roundEntries.ToArray() }

$undisposed = [System.Collections.Generic.List[string]]::new()
foreach ($id in $findingIds) {
    if (-not $dispositionIds.Contains($id)) { $undisposed.Add($id) }
}

# Shape check on a JSON round trip (the library reads PSObject properties). Missing dispositions are
# covered with placeholders in this check only, so any other shape error is reported alone.
$checked = $record | ConvertTo-Json -Depth 50 | ConvertFrom-Json
if ($undisposed.Count -gt 0) {
    $checkedDispositions = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in (ConvertTo-Items $checked.dispositions)) { $checkedDispositions.Add($entry) }
    foreach ($id in $undisposed) {
        $checkedDispositions.Add([pscustomobject]@{
            id          = $id
            severity    = $severityById[$id]
            disposition = 'contested'
            evidence    = 'pending disposition'
            reason      = 'pending disposition'
        })
    }
    $checked.dispositions = $checkedDispositions.ToArray()
}
Assert-DeliveryReviewRecordShape -Value $checked

$errorList = [System.Collections.Generic.List[string]]::new()
foreach ($id in $undisposed) { $errorList.Add("Finding $id has no disposition.") }

$parent = Split-Path -Parent $outFull
New-Item -ItemType Directory -Path $parent -Force | Out-Null
$temp = Join-Path $parent ('.new-delivery-review-' + [guid]::NewGuid().ToString('N') + '.tmp')
try {
    $json = $record | ConvertTo-Json -Depth 50
    [System.IO.File]::WriteAllText($temp, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::Move($temp, $outFull, $false)
}
finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
}

$summary = [ordered]@{
    ok         = ($undisposed.Count -eq 0)
    errors     = $errorList.ToArray()
    out_path   = $outFull
    undisposed = $undisposed.ToArray()
    counts     = $counts
}
Write-Output ($summary | ConvertTo-Json -Compress -Depth 5)
