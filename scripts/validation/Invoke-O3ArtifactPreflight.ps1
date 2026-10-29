#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $FeatureRoot,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [string] $RepoPath = (Get-Location).Path,
    [string] $SddRoot,
    [switch] $AuthorizeCompletedPlanPrdTransition,
    [switch] $EmitStepTable,
    [string] $StepStateOverridesPath
)

$ErrorActionPreference = 'Stop'
$script:StorageSummary = 'features_versioned=unknown'
$script:PreflightIssues = [System.Collections.Generic.List[object]]::new()
$script:PlanSteps = @()
$script:PlanProgressRows = @()
$script:PlanStates = @{}
. (Join-Path $PSScriptRoot '..\_lib\Get-ToolkitRelativePath.ps1')
. (Join-Path $PSScriptRoot '..\_lib\ToolkitConstants.ps1')
. (Join-Path $PSScriptRoot '..\_lib\Format-O3PlanProgressTable.ps1')

function Format-PreflightValue([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return 'unknown' }
    return ($Value -replace '[\r\n]+',' ' -replace ';',',').Trim()
}

function Test-PositiveContentApproval([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '[\[\]]') { return $false }
    return $Value -match '(?i)^\s*(?:Approved by operator(?: in this conversation)? on \d{4}-\d{2}-\d{2}|Aprovad[oa] pelo operador(?: nesta conversa)? em \d{4}-\d{2}-\d{2})\s*$'
}

# Artifact prose is intentionally flexible. Normalize labels by meaning rather
# than requiring a specific Markdown emphasis, emoji, whitespace, or casing.
function ConvertTo-PreflightLabel([string]$Value) {
    return ConvertTo-SddArtifactAliasKey $Value
}

function Remove-PreflightDecoration([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    # PowerShell 5.1/.NET Framework sees many emoji as UTF-16 surrogate pairs,
    # so remove those code units explicitly along with Unicode symbols.
    $clean = [regex]::Replace($Value,'[\p{S}\p{Cf}\uD800-\uDFFF]','')
    $clean = [regex]::Replace($clean,'(?<![\p{L}\p{N}])[*_~`]+|[*_~`]+(?![\p{L}\p{N}])','')
    return $clean.Trim()
}

function Get-PreflightTableCells([string]$Line) {
    if ([string]::IsNullOrWhiteSpace($Line) -or $Line.IndexOf('|') -lt 0) { return @() }
    $cells = @($Line.Trim().Trim('|').Split('|') | ForEach-Object { (Remove-PreflightDecoration $_).Trim() })
    return $cells
}

function Get-PreflightFieldValue([string]$Text,[string[]]$AcceptedLabels,[switch]$TopLevelOnly) {
    $accepted = @($AcceptedLabels | ForEach-Object { ConvertTo-PreflightLabel $_ })
    foreach ($line in [regex]::Split($Text,'\r?\n')) {
        if ($TopLevelOnly -and $line -match '^\s*#{2,}\s+') { break }
        $cells = @(Get-PreflightTableCells $line)
        if ($cells.Count -ge 2 -and (ConvertTo-PreflightLabel $cells[0]) -in $accepted) {
            return $cells[1].Trim()
        }
        $field = [regex]::Match($line,'^\s*(?:[-*+]\s*)?(?<label>[^:|]+?)\s*:\s*(?<value>.*?)\s*$')
        if ($field.Success -and (ConvertTo-PreflightLabel $field.Groups['label'].Value) -in $accepted) {
            return (Remove-PreflightDecoration $field.Groups['value'].Value)
        }
    }
    return ''
}

function Get-PreflightSection([string]$Text,[string[]]$AcceptedHeadings) {
    $accepted = @($AcceptedHeadings | ForEach-Object { ConvertTo-PreflightLabel $_ })
    $lines = [regex]::Split($Text,'\r?\n')
    $start = -1
    $end = $lines.Count
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $heading = [regex]::Match($lines[$lineIndex],'^\s*#{2}\s*(?<label>.*?)\s*#*\s*$')
        if (-not $heading.Success) { continue }
        $normalized = ConvertTo-PreflightLabel $heading.Groups['label'].Value
        if ($start -lt 0 -and $normalized -in $accepted) { $start = $lineIndex + 1; continue }
        if ($start -ge 0) { $end = $lineIndex; break }
    }
    if ($start -lt 0) { return '' }
    if ($end -le $start) { return '' }
    return ($lines[$start..($end - 1)] -join "`n")
}

# One O3 block per PLAN: every "## Estado atual do O3" heading opens a block that
# ends at the next level-1/2 heading. Level-3 sub-headings stay inside the block.
function Get-PreflightO3Blocks([string]$Text) {
    $lines = [regex]::Split($Text,'\r?\n')
    $accepted = @('Estado atual do O3','Current O3 state','O3 current state') | ForEach-Object { ConvertTo-PreflightLabel $_ }
    $blocks = [System.Collections.Generic.List[object]]::new()
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $heading = [regex]::Match($lines[$lineIndex],'^\s*##(?!#)\s*(?<label>.*?)\s*#*\s*$')
        if (-not $heading.Success -or (ConvertTo-PreflightLabel $heading.Groups['label'].Value) -notin $accepted) { continue }
        $end = $lineIndex + 1
        while ($end -lt $lines.Count -and -not [regex]::IsMatch($lines[$end],'^\s*#{1,2}(?!#)\s')) { $end++ }
        $blockText = if ($end -gt ($lineIndex + 1)) { $lines[($lineIndex + 1)..($end - 1)] -join "`n" } else { '' }
        $blocks.Add([PSCustomObject]@{ Line = $lineIndex + 1; PlanValue = (Get-PreflightFieldValue $blockText @('PLAN') -TopLevelOnly); Text = $blockText })
        $lineIndex = $end - 1
    }
    return @($blocks.ToArray())
}

function Get-PreflightStepHeadings([string]$Text) {
    return Get-SddArtifactPlanStepHeadings -Text $Text
}

function Get-PreflightDependencyIds([string]$Value) {
    $value = Remove-PreflightDecoration $Value
    if ([string]::IsNullOrWhiteSpace($value) -or (ConvertTo-PreflightLabel $value) -in @('none','nenhum','nenhuma','naoaplicavel','notapplicable')) {
        return [PSCustomObject]@{ Ids=@(); Invalid=@() }
    }
    $ids = [System.Collections.Generic.List[string]]::new()
    $invalid = [System.Collections.Generic.List[string]]::new()
    foreach ($token in [regex]::Split($value,'\s*(?:,|;|/|&|\+|\b(?:and|e)\b)\s*')) {
        $clean = ($token.Trim() -replace '^[\s`*_~:()\[\]{}]+|[\s`*_~:()\[\]{}.!]+$','')
        if ([string]::IsNullOrWhiteSpace($clean)) { continue }
        $normalized = ConvertTo-PreflightLabel $clean
        if ($normalized -in @('none','nenhum','nenhuma','naoaplicavel','notapplicable')) { continue }
        # Story references are not PLAN step IDs. In particular, US01 must
        # never be partially interpreted as S01 by dependency validation.
        if ($clean -match '^(?i)(?:US|TS)\d{2}$') { continue }
        if ($clean -match '^(?i)S\d+$') { $ids.Add($clean.ToUpperInvariant()) }
        else { $invalid.Add($clean) }
    }
    return [PSCustomObject]@{ Ids=@($ids.ToArray() | Sort-Object -Unique); Invalid=@($invalid.ToArray()) }
}

function Get-PreflightReferencedStepIds([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or (ConvertTo-PreflightLabel $Value) -in @('none','nenhum','nenhuma','naoaplicavel','notapplicable')) { return @() }
    $ids = @([regex]::Matches($Value,'(?i)(?<![A-Za-z0-9])S\d+(?![A-Za-z0-9])') | ForEach-Object { $_.Value.ToUpperInvariant() })
    return @($ids | Sort-Object { [int]$_.Substring(1) })
}

function Test-PreflightStepState([string]$Block,[string]$ExpectedState) {
    foreach ($line in [regex]::Split($Block,'\r?\n')) {
        $clean = Remove-PreflightDecoration $line
        $clean = $clean -replace '^\s*[-*+]\s*',''
        $match = [regex]::Match($clean,'^(?<state>[^\s|]+)\b')
        if ($match.Success) {
            $alias = Resolve-SddArtifactAlias -Domain 'execution-status' -Value $match.Groups['state'].Value
            if ($alias.Recognized -and $alias.Canonical -in @('COMPLETED','PENDING')) {
                return [string]::Equals($alias.Canonical,$ExpectedState,[StringComparison]::OrdinalIgnoreCase)
            }
        }
    }
    return $false
}

function Get-PreflightStepTableRow([string]$Section,[string]$StepId) {
    $lines = [regex]::Split($Section,'\r?\n')
    $header = $null
    $index = @{}
    foreach ($line in $lines) {
        $cells = @(Get-PreflightTableCells $line)
        if ($cells.Count -lt 2) { continue }
        $labels = @($cells | ForEach-Object { ConvertTo-PreflightLabel $_ })
        $stepColumn = -1; $dependencyColumn = -1; $statusColumn = -1
        for ($i = 0; $i -lt $labels.Count; $i++) {
            $alias = Resolve-SddArtifactAlias -Domain 'table-column' -Value $cells[$i]
            if (-not $alias.Recognized) { continue }
            if ($alias.Canonical -eq 'STEP_ID') { $stepColumn = $i }
            if ($alias.Canonical -eq 'DEPENDENCIES') { $dependencyColumn = $i }
            if ($alias.Canonical -eq 'STATUS') { $statusColumn = $i }
        }
        if ($stepColumn -ge 0 -and $dependencyColumn -ge 0 -and $statusColumn -ge 0) {
            $header = $cells; $index = @{ Step=$stepColumn; Dependencies=$dependencyColumn; Status=$statusColumn }; break
        }
    }
    if ($null -eq $header) { return $null }
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $cells = @(Get-PreflightTableCells $lines[$lineIndex])
        if ($cells.Count -le $index.Step -or $cells.Count -le $index.Dependencies -or $cells.Count -le $index.Status) { continue }
        if ((Remove-PreflightDecoration $cells[$index.Step]).Trim().ToUpperInvariant() -eq $StepId.ToUpperInvariant()) {
            return [PSCustomObject]@{ Cells=$cells; Dependencies=$cells[$index.Dependencies]; Status=$cells[$index.Status]; Line=$lines[$lineIndex] }
        }
    }
    return $null
}

function Get-PreflightStepTableRows([string]$Section) {
    $lines = [regex]::Split($Section,'\r?\n')
    $columnIndex = $null
    $headerLine = -1
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $cells = @(Get-PreflightTableCells $lines[$lineIndex])
        if ($cells.Count -lt 2) { continue }
        $labels = @($cells | ForEach-Object { ConvertTo-PreflightLabel $_ })
        $columns = @{
            STEP_ID = [System.Collections.Generic.List[int]]::new()
            STEP_NAME = [System.Collections.Generic.List[int]]::new()
            DEPENDENCIES = [System.Collections.Generic.List[int]]::new()
            STATUS = [System.Collections.Generic.List[int]]::new()
            EVIDENCE = [System.Collections.Generic.List[int]]::new()
        }
        for ($cellIndex = 0; $cellIndex -lt $labels.Count; $cellIndex++) {
            $alias = Resolve-SddArtifactAlias -Domain 'table-column' -Value $cells[$cellIndex]
            if ($alias.Recognized -and $columns.ContainsKey($alias.Canonical)) { $columns[$alias.Canonical].Add($cellIndex) }
        }
        if ($columns.STEP_ID.Count -gt 0 -and $columns.DEPENDENCIES.Count -gt 0 -and $columns.STATUS.Count -gt 0) {
            $columnIndex = [PSCustomObject]@{
                Step = $columns.STEP_ID[0]
                Name = if ($columns.STEP_NAME.Count -gt 0) { $columns.STEP_NAME[0] } else { -1 }
                Dependencies = $columns.DEPENDENCIES[0]
                Status = $columns.STATUS[0]
                Evidence = if ($columns.EVIDENCE.Count -gt 0) { $columns.EVIDENCE[0] } else { -1 }
                Columns = $columns
            }
            $headerLine = $lineIndex
            break
        }
    }
    if ($null -eq $columnIndex) { return @() }

    $rows = [System.Collections.Generic.List[object]]::new()
    for ($lineIndex = $headerLine + 1; $lineIndex -lt $lines.Count; $lineIndex++) {
        $line = $lines[$lineIndex]
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        if ($line.IndexOf('|') -lt 0) { break }
        $cells = @(Get-PreflightTableCells $line)
        if ($cells.Count -le $columnIndex.Step) { continue }
        $stepId = (Remove-PreflightDecoration $cells[$columnIndex.Step]).Trim().ToUpperInvariant()
        if ([string]::IsNullOrWhiteSpace($stepId) -or $stepId -match '^:?-+:?$') { continue }
        $name = if ($columnIndex.Name -ge 0 -and $cells.Count -gt $columnIndex.Name) { $cells[$columnIndex.Name] } else { '' }
        $evidence = if ($columnIndex.Evidence -ge 0 -and $cells.Count -gt $columnIndex.Evidence) { $cells[$columnIndex.Evidence] } else { '' }
        $dependencyValue = if ($cells.Count -gt $columnIndex.Dependencies) { [string]$cells[$columnIndex.Dependencies] } else { '' }
        $statusValue = if ($cells.Count -gt $columnIndex.Status) { [string]$cells[$columnIndex.Status] } else { '' }
        $conflicts = [System.Collections.Generic.List[string]]::new()
        foreach ($field in @('STEP_ID','DEPENDENCIES','STATUS')) {
            $fieldIndexes = @($columnIndex.Columns[$field])
            if ($fieldIndexes.Count -lt 2) { continue }
            $canonicalValues = [System.Collections.Generic.List[string]]::new()
            foreach ($fieldIndex in $fieldIndexes) {
                if ($cells.Count -le $fieldIndex) { $canonicalValues.Add('<missing>'); continue }
                $rawValue = (Remove-PreflightDecoration $cells[$fieldIndex]).Trim()
                if ($field -eq 'STATUS') {
                    $fieldAlias = Resolve-SddArtifactAlias -Domain 'execution-status' -Value $rawValue
                    $canonicalValues.Add($(if ($fieldAlias.Recognized) { $fieldAlias.Canonical } else { '<unknown:' + $rawValue + '>' }))
                } elseif ($field -eq 'STEP_ID') {
                    $canonicalValues.Add($rawValue.ToUpperInvariant())
                } else {
                    $dependencyResult = Get-PreflightDependencyIds $rawValue
                    $canonicalValues.Add(($dependencyResult.Ids -join ','))
                }
            }
            if (@($canonicalValues | Select-Object -Unique).Count -gt 1) {
                $conflicts.Add(("{0}: {1}" -f $field, ($canonicalValues -join ' vs ')))
            }
        }
        $statusAlias = Resolve-SddArtifactAlias -Domain 'execution-status' -Value $statusValue
        $rows.Add([PSCustomObject]@{
            Id = $stepId
            Name = [string]$name
            Dependencies = $dependencyValue
            Status = $statusValue
            StatusCanonical = if ($statusAlias.Recognized) { $statusAlias.Canonical } else { '' }
            Conflicts = @($conflicts.ToArray())
            LineNumber = $lineIndex + 1
            Evidence = [string]$evidence
            Cells = $cells
            Line = $line
        })
    }
    return @($rows.ToArray())
}

function Write-PreflightStepTable {
    if ($script:PlanSteps.Count -eq 0) {
        Write-Output 'O3 progress table unavailable: no canonical PLAN step headings were parsed.'
        return
    }
    $renderRows = [System.Collections.Generic.List[object]]::new()
    $overrideRows = @()
    $useOverrides = -not [string]::IsNullOrWhiteSpace($StepStateOverridesPath)
    if ($useOverrides) {
        if (-not (Test-Path -LiteralPath $StepStateOverridesPath -PathType Leaf)) { throw 'O3 step-state override file does not exist.' }
        $overrideRows = @(Get-Content -LiteralPath $StepStateOverridesPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    foreach ($step in $script:PlanSteps) {
        $matches = @($script:PlanProgressRows | Where-Object { [string]::Equals([string]$_.Id,[string]$step.Id,[StringComparison]::OrdinalIgnoreCase) })
        if ($matches.Count -ne 1 -or -not $script:PlanStates.ContainsKey($step.Id)) {
            $renderRows.Add([PSCustomObject]@{ Id=$step.Id; Status='UNVERIFIED'; Dependencies='unknown'; Evidence='PLAN row missing or duplicated' })
            continue
        }
        $stepStatus = $script:PlanStates[$step.Id]
        $stepEvidence = $matches[0].Evidence
        if ($useOverrides) {
            $statusOverrides = @($overrideRows | Where-Object { [string]::Equals([string]$_.Id,[string]$step.Id,[StringComparison]::OrdinalIgnoreCase) })
            if ($statusOverrides.Count -ne 1) { throw "Expected exactly one status projection for PLAN step $($step.Id)." }
            $stepStatus = ([string]$statusOverrides[0].Status).Trim().ToUpperInvariant()
            if (-not [string]::IsNullOrWhiteSpace([string]$statusOverrides[0].Evidence)) { $stepEvidence = [string]$statusOverrides[0].Evidence }
        }
        $renderRows.Add([PSCustomObject]@{
            Id = $step.Id
            Status = $stepStatus
            Dependencies = $matches[0].Dependencies
            Evidence = $stepEvidence
        })
    }
    if ($useOverrides -and $overrideRows.Count -ne $script:PlanSteps.Count) { throw 'O3 status projection must contain exactly one row for every PLAN step.' }
    try {
        Write-Output (Format-O3PlanProgressTable -PlanSteps $script:PlanSteps -StepRows @($renderRows.ToArray()))
    } catch {
        Write-Output ("O3 progress table unavailable: {0}" -f (Format-PreflightValue $_.Exception.Message))
    }
}

function Get-PreflightPlanReferenceCandidates([string]$Text) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [regex]::Split($Text,'\r?\n')) {
        $candidateValues = [System.Collections.Generic.List[string]]::new()
        $cells = @(Get-PreflightTableCells $line)
        if ($cells.Count -ge 2 -and (ConvertTo-PreflightLabel $cells[0]) -in @('plan','relatedplan','planpath','canonicalplan','relatedplanpath')) { $candidateValues.Add($cells[1]) }
        $field = [regex]::Match($line,'^\s*(?:[-*+]\s*)?(?<label>[^:|]+?)\s*:\s*(?<value>.*?)\s*$')
        if ($field.Success -and (ConvertTo-PreflightLabel $field.Groups['label'].Value) -in @('plan','relatedplan','planpath','canonicalplan','relatedplanpath')) { $candidateValues.Add($field.Groups['value'].Value) }
        foreach ($value in $candidateValues) {
            foreach ($match in [regex]::Matches($value,'\[[^\]]*\]\((?<path>[^)\s]+)(?:\s+[^)]*)?\)|`(?<path>[^`]+)`')) {
                $candidates.Add($match.Groups['path'].Value)
            }
            foreach ($match in [regex]::Matches($value,'(?i)(?:\.{1,2}/|features/|sdd/)[^\s|<>`]+\.md')) { $candidates.Add($match.Value.TrimEnd('.',',',';',')')) }
        }
    }
    return @($candidates.ToArray())
}

function Test-CanonicalPlanReference([string]$Text,[string]$SourcePath,[string]$CanonicalPlanPath,[string]$CanonicalPortablePath,[string]$RepositoryRoot) {
    $target = [IO.Path]::GetFullPath($CanonicalPlanPath)
    foreach ($candidateValue in (Get-PreflightPlanReferenceCandidates $Text)) {
        $candidate = $candidateValue.Trim().Trim('<','>','`').Replace('\','/')
        $candidate = $candidate -replace '[?#].*$',''
        if ([string]::IsNullOrWhiteSpace($candidate) -or [IO.Path]::IsPathRooted($candidate)) { continue }
        # Compare portable repository-relative form only after removing exact
        # current-directory prefixes. TrimStart('./') is unsafe: it treats the
        # argument as a character set and can erase a leading ../../ traversal.
        $portableCandidate = $candidate -replace '^(?:\./)+',''
        if ([string]::Equals($portableCandidate,$CanonicalPortablePath,[StringComparison]::OrdinalIgnoreCase)) { return $true }
        try {
            $base = Split-Path -Parent $SourcePath
            if ($portableCandidate.StartsWith('features/',[StringComparison]::OrdinalIgnoreCase)) { $base = $RepositoryRoot }
            $resolved = [IO.Path]::GetFullPath((Join-Path $base ($portableCandidate.Replace('/',[IO.Path]::DirectorySeparatorChar))))
            if ([string]::Equals($resolved,$target,[StringComparison]::OrdinalIgnoreCase)) { return $true }
        } catch { }
    }
    return $false
}

function Add-PreflightIssue([string]$Code,[string]$Artifact,[string]$Field,[string]$Observed,[string]$Expected,[string]$Owner,[string]$NextAction) {
    $script:PreflightIssues.Add([PSCustomObject]@{
        Code = (($Code -replace '[\r\n]+',' ').Trim())
        Artifact = Format-PreflightValue $Artifact
        Field = Format-PreflightValue $Field
        Observed = Format-PreflightValue $Observed
        Expected = Format-PreflightValue $Expected
        Owner = Format-PreflightValue $Owner
        NextAction = Format-PreflightValue $NextAction
    })
}

function Get-PreflightArtifactRef([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return 'repository-or-manifest' }
    try { return (Get-ToolkitRelativePath -BasePath $repo -TargetPath $Path).Replace('\','/') }
    catch { return (Split-Path -Leaf $Path) }
}

function Write-PreflightBlock {
    Write-Output "preflight: BLOCK - errors=$($script:PreflightIssues.Count); $script:StorageSummary"
    for ($issueIndex = 0; $issueIndex -lt $script:PreflightIssues.Count; $issueIndex++) {
        $issue = $script:PreflightIssues[$issueIndex]
        Write-Output ("  [{0}] code={1}; artifact={2}; field={3}; observed={4}; expected={5}; owner={6}; next={7}" -f ($issueIndex + 1),$issue.Code,$issue.Artifact,$issue.Field,$issue.Observed,$issue.Expected,$issue.Owner,$issue.NextAction)
    }
    if ($EmitStepTable) {
        try { Write-PreflightStepTable }
        catch { Write-Output ("O3 progress table unavailable: {0}" -f (Format-PreflightValue $_.Exception.Message)) }
    }
}

function Stop-Preflight([string]$Reason) {
    if ($script:PreflightIssues.Count -eq 0) {
        Add-PreflightIssue $Reason 'repository-or-manifest' 'validation' 'invalid' 'valid preflight input' 'repository owner' 'Correct the reported repository, manifest, or path input and rerun preflight.'
    }
    Write-PreflightBlock
    exit 2
}

try {
    $repo = (Resolve-Path -LiteralPath $RepoPath).Path
    if ([string]::IsNullOrWhiteSpace($SddRoot)) { $SddRoot = Join-Path $env:USERPROFILE '.codex/sdd' }
    $manifest = Join-Path $SddRoot 'manifest.json'
    $versioning = 'unknown'
    $storageMode = ''
    $featureStorageRoot = ''
    $portablePrefix = ''
    if (Test-Path -LiteralPath $manifest) {
        $manifestValue = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
        if ($null -ne $manifestValue.repositories) {
            $repoKey = $repo.Replace('\','/').TrimEnd('/')
            $repoEntry = $manifestValue.repositories.PSObject.Properties | Where-Object { $_.Name.Replace('\','/').TrimEnd('/').Equals($repoKey,[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
            if ($null -ne $repoEntry) {
                $classic = $repoEntry.Value.classic
                if ($null -ne $classic.storage_mode) { $storageMode = [string]$classic.storage_mode }
                if ($null -ne $classic.features_versioned) { $versioning = [string]$classic.features_versioned }
                if ($storageMode -eq 'repository') { $featureStorageRoot = Join-Path $repo 'features' }
                elseif ($storageMode -eq 'global' -and -not [string]::IsNullOrWhiteSpace([string]$classic.path)) {
                    $configuredRoot = [IO.Path]::GetFullPath([string]$classic.path)
                    $sddAbsolute = [IO.Path]::GetFullPath($SddRoot).TrimEnd('\','/')
                    if ($configuredRoot.StartsWith($sddAbsolute + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
                        $featureStorageRoot = Join-Path $configuredRoot 'features'
                        $repoId = (Get-ToolkitRelativePath -BasePath $sddAbsolute -TargetPath $configuredRoot).Replace('\','/')
                        $portablePrefix = 'sdd/' + $repoId + '/'
                    }
                }
            }
        }
    }
    $script:StorageSummary = if ($versioning -eq 'false') { 'features_versioned=false; SDD artifacts are local/unversioned and may not accompany commits or clones' } else { "features_versioned=$versioning" }
    $feature = (Resolve-Path -LiteralPath $FeatureRoot).Path
    $plan = (Resolve-Path -LiteralPath $PlanPath).Path
    if ([string]::IsNullOrWhiteSpace($featureStorageRoot)) { Stop-Preflight 'feature_storage_location_unverifiable' }
    $featureStorageAbsolute = [IO.Path]::GetFullPath($featureStorageRoot).TrimEnd('\','/')
    $relativeFeature = (Get-ToolkitRelativePath -BasePath $featureStorageAbsolute -TargetPath $feature).Replace('\','/')
    $relativePlanInStorage = (Get-ToolkitRelativePath -BasePath $featureStorageAbsolute -TargetPath $plan).Replace('\','/')
    $relativePlan = $portablePrefix + 'features/' + $relativePlanInStorage
    $planFeatureSegment = ($relativePlanInStorage -split '/')[0]
    if ($relativeFeature.StartsWith('../') -or $relativeFeature -match '^\.\.' -or $relativePlanInStorage -notmatch '^[^/]+/(?:US|TS)\d{2}/PLAN/PLAN_\d{3}_[^/]+\.md$' -or $relativeFeature -ne $planFeatureSegment) {
        Stop-Preflight 'non_canonical_feature_or_plan_path'
    }
    $storyRoot = Split-Path -Parent (Split-Path -Parent $plan)
    $story = Join-Path $storyRoot 'STORY.md'
    $prdDir = Join-Path $storyRoot 'PRD'
    $refine = Join-Path $storyRoot 'REFINE/tasks.md'
    $continuity = Join-Path $feature 'CONTINUITY.md'
    $featureDoc = Join-Path $feature 'FEATURE.md'
    $prds = @(Get-ChildItem -LiteralPath $prdDir -Filter '*.md' -File -ErrorAction SilentlyContinue)
    foreach ($path in @($featureDoc,$story,$refine,$continuity)) {
        if (-not (Test-Path -LiteralPath $path)) {
            Add-PreflightIssue 'required_artifact_missing' (Get-PreflightArtifactRef $path) 'file' 'missing' 'present canonical artifact' 'story/feature owner' 'Create or restore the cited artifact, then rerun preflight.'
        }
    }
    if ($prds.Count -ne 1) {
        Add-PreflightIssue 'expected_exactly_one_story_prd' (Get-PreflightArtifactRef $prdDir) 'PRD count' ([string]$prds.Count) 'exactly one PRD markdown file' 'story owner' 'Resolve duplicate or missing PRD files, then rerun preflight.'
    }
    if ($script:PreflightIssues.Count -gt 0) { Stop-Preflight 'required_artifact_set_invalid' }
    $prd = $prds[0].FullName
    $planText = Get-Content -LiteralPath $plan -Raw -Encoding UTF8
    $status = Get-PreflightFieldValue $planText @('Status') -TopLevelOnly
    if (-not [string]::Equals($status,'approved',[StringComparison]::OrdinalIgnoreCase)) {
        Add-PreflightIssue 'plan_not_explicitly_approved' (Get-PreflightArtifactRef $plan) 'Status' $status 'approved' 'PLAN owner' 'Obtain and persist PLAN approval before O3 effects.'
    }

    $featureText = Get-Content -LiteralPath $featureDoc -Raw -Encoding UTF8
    $storyText = Get-Content -LiteralPath $story -Raw -Encoding UTF8
    $prdText = Get-Content -LiteralPath $prd -Raw -Encoding UTF8
    $refineText = Get-Content -LiteralPath $refine -Raw -Encoding UTF8
    $continuityText = Get-Content -LiteralPath $continuity -Raw -Encoding UTF8
    $featureId = Get-PreflightFieldValue $featureText @('Id','Feature Id') -TopLevelOnly
    $folderIdentity = [regex]::Match($relativeFeature,'^(?<sequence>\d{3})-(?<slug>[a-z0-9]+(?:-[a-z0-9]+)*)$')
    $featureIdentity = [regex]::Match($featureId,'^(?<sequence>\d{3})(?:-(?<slug>[a-z0-9]+(?:-[a-z0-9]+)*))?$')
    if (-not $folderIdentity.Success -or -not $featureIdentity.Success) {
        Add-PreflightIssue 'feature_identity_unverifiable' (Get-PreflightArtifactRef $featureDoc) 'Id' $featureId "NNN or matching NNN-slug for $relativeFeature" 'feature owner' 'Align FEATURE Id with the canonical feature folder.'
    }
    elseif ($featureIdentity.Groups['slug'].Success -and -not [string]::Equals($featureId,$relativeFeature,[StringComparison]::Ordinal)) {
        Add-PreflightIssue 'feature_identity_unverifiable' (Get-PreflightArtifactRef $featureDoc) 'Id' $featureId $relativeFeature 'feature owner' 'Align FEATURE Id with the canonical feature folder.'
    }
    elseif ($featureIdentity.Groups['sequence'].Value -ne $folderIdentity.Groups['sequence'].Value) {
        Add-PreflightIssue 'feature_identity_unverifiable' (Get-PreflightArtifactRef $featureDoc) 'Id' $featureId $relativeFeature 'feature owner' 'Align FEATURE Id with the canonical feature folder.'
    }
    $planSequence = [regex]::Match((Split-Path $plan -Leaf),'^PLAN_(\d{3})_').Groups[1].Value
    $prdSequence = [regex]::Match((Split-Path $prd -Leaf),'^(\d{3})_').Groups[1].Value
    if ($folderIdentity.Success -and ($planSequence -ne $folderIdentity.Groups['sequence'].Value -or $prdSequence -ne $folderIdentity.Groups['sequence'].Value)) {
        $identityCode = 'feature_plan_prd_identity_mismatch:feature={0};plan={1};prd={2}' -f $folderIdentity.Groups['sequence'].Value,$planSequence,$prdSequence
        Add-PreflightIssue $identityCode (Get-PreflightArtifactRef $plan) 'feature/PLAN/PRD sequence' "feature=$($folderIdentity.Groups['sequence'].Value), plan=$planSequence, prd=$prdSequence" 'all three sequence values match' 'PLAN/PRD owner' 'Align PLAN and PRD filename sequences with the canonical feature folder, then rerun preflight.'
    }
    $storyId = Split-Path $storyRoot -Leaf
    if ($storyId -notmatch '^(?:US|TS)\d{2}$' -or $storyText -notmatch [regex]::Escape($storyId) -or $storyText -notmatch [regex]::Escape($relativeFeature)) {
        Add-PreflightIssue 'story_identity_or_feature_scope_mismatch' (Get-PreflightArtifactRef $story) 'Feature/story identity' $storyId 'canonical USnn or TSnn and matching feature path' 'story owner' 'Align the STORY identity and feature path with its folder.'
    }
    foreach ($pair in @(@($storyText,'STORY'),@($prdText,'PRD'),@($refineText,'REFINE'),@($continuityText,'CONTINUITY'))) {
        if (-not [string]::IsNullOrWhiteSpace($featureId) -and $pair[0] -notmatch [regex]::Escape($featureId)) {
            $artifactPath = switch ($pair[1]) { 'STORY' { $story } 'PRD' { $prd } 'REFINE' { $refine } 'CONTINUITY' { $continuity } }
            Add-PreflightIssue "feature_identity_mismatch:$($pair[1])" (Get-PreflightArtifactRef $artifactPath) 'Feature Id' 'missing or different feature identity' $featureId "$($pair[1]) owner" "Align the $($pair[1]) feature identity with FEATURE.md."
        }
    }

    $stepParse = Get-PreflightStepHeadings $planText
    $steps = @($stepParse.Valid)
    $script:PlanSteps = $steps
    if ($steps.Count -eq 0) {
        Add-PreflightIssue 'plan_steps_missing' (Get-PreflightArtifactRef $plan) 'step headings' 'none recognized' 'at least one canonical STEP/PASSO heading' 'PLAN owner' 'Restore valid PLAN step headings, then rerun preflight.'
    }
    if ($stepParse.Invalid.Count -gt 0) {
        Add-PreflightIssue 'plan_step_heading_invalid' (Get-PreflightArtifactRef $plan) 'step headings' ($stepParse.Invalid -join ' / ') 'valid STEP/PASSO heading with ordinal, step ID, and title' 'PLAN owner' 'Normalize the malformed step heading(s) without changing their semantic IDs, then rerun preflight.'
    }
    $progressSection = Get-PreflightSection $planText @('Progresso da implementação','Progresso de implementação','Implementation progress')
    if ([string]::IsNullOrWhiteSpace($progressSection)) {
        Add-PreflightIssue 'plan_progress_section_missing' (Get-PreflightArtifactRef $plan) 'Implementation progress' 'section missing' 'a progress section containing one ledger row per PLAN step' 'PLAN owner' 'Restore the PLAN progress section, then rerun preflight.'
    }
    $script:PlanProgressRows = @(Get-PreflightStepTableRows $progressSection)
    $refineParse = Get-PreflightStepHeadings $refineText
    $refineGroups = @($refineParse.Valid)
    if ($refineParse.Invalid.Count -gt 0) {
        Add-PreflightIssue 'refine_step_heading_invalid' (Get-PreflightArtifactRef $refine) 'step headings' ($refineParse.Invalid -join ' / ') 'valid STEP/PASSO headings with IDs matching PLAN' 'REFINE owner' 'Normalize malformed REFINE step headings and keep their IDs aligned with PLAN.'
    }
    $refineLines = [regex]::Split($refineText,'\r?\n')
    $planStates = @{}
    $dependenciesByStep = @{}
    $planStepIdSet = @{}
    foreach ($step in $steps) { $planStepIdSet[$step.Id.ToUpperInvariant()] = $true }
    $rowCountsById = @{}
    foreach ($progressRow in $script:PlanProgressRows) {
        $rowId = ([string]$progressRow.Id).ToUpperInvariant()
        if ($rowId -notmatch '^S\d+$' -or -not $planStepIdSet.ContainsKey($rowId)) {
            Add-PreflightIssue "plan_step_ledger_extra:$rowId" (Get-PreflightArtifactRef $plan) 'Implementation progress/Step ID' $rowId 'an ID declared by a PLAN step heading' 'PLAN owner' 'Remove extra progress rows or reconcile their step headings, then rerun preflight.'
            continue
        }
        if (-not $rowCountsById.ContainsKey($rowId)) { $rowCountsById[$rowId] = 0 }
        $rowCountsById[$rowId]++
        if ($rowCountsById[$rowId] -gt 1) {
            Add-PreflightIssue "plan_step_ledger_duplicate:$rowId" (Get-PreflightArtifactRef $plan) "Implementation progress/$rowId" 'duplicate row' 'exactly one row per PLAN step' 'PLAN owner' 'Keep one progress row for this step, then rerun preflight.'
        }
    }
    foreach ($step in $steps) {
        $matchingPlanRows = @($script:PlanProgressRows | Where-Object { [string]::Equals([string]$_.Id,$step.Id,[StringComparison]::OrdinalIgnoreCase) })
        if ($matchingPlanRows.Count -eq 0) {
            Add-PreflightIssue "plan_step_ledger_missing:$($step.Id)" (Get-PreflightArtifactRef $plan) "Implementation progress/$($step.Id)" 'row missing' 'one ledger row with dependencies and status' 'PLAN owner' "Restore the progress row for $($step.Id), then rerun preflight."
        }
        if ($matchingPlanRows.Count -gt 1) { $dependenciesByStep[$step.Id] = @(); continue }
        $row = if ($matchingPlanRows.Count -eq 1) { $matchingPlanRows[0] } else { $null }
        $refineHeading = $null
        foreach ($candidateHeading in $refineGroups) {
            if ([string]::Equals($candidateHeading.Id,$step.Id,[StringComparison]::OrdinalIgnoreCase)) { $refineHeading = $candidateHeading; break }
        }
        if ($null -eq $refineHeading) {
            Add-PreflightIssue "plan_refine_step_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) 'step IDs' 'PLAN step absent from REFINE' $step.Id 'REFINE owner' "Reconcile the checklist row for $($step.Id), then rerun preflight."
        }
        $dependenciesByStep[$step.Id] = @()
        if ($null -eq $row) { $dependenciesByStep[$step.Id] = @(); continue }
        foreach ($conflict in @($row.Conflicts)) {
            Add-PreflightIssue "plan_step_ledger_alias_conflict:$($step.Id)" (Get-PreflightArtifactRef $plan) "Implementation progress/$($step.Id)" $conflict 'one unambiguous value for each semantic column' 'PLAN owner' "Remove the conflicting duplicate alias column or make its values semantically identical at ledger row $($row.LineNumber), then rerun preflight."
        }
        $stateAlias = Resolve-SddArtifactAlias -Domain 'execution-status' -Value $row.Status
        $state = if ($stateAlias.Recognized) { $stateAlias.Canonical } else { '' }
        if (-not $stateAlias.Recognized -or $state -notin @('COMPLETED','PENDING','IN_PROGRESS','BLOCKED','SKIPPED')) {
            $displayState = if ([string]::IsNullOrWhiteSpace($row.Status)) { '<empty>' } else { $row.Status }
            Add-PreflightIssue "plan_step_state_invalid:$($step.Id)" (Get-PreflightArtifactRef $plan) "Implementation progress/$($step.Id)/Status (line $($row.LineNumber))" $displayState 'COMPLETED/PENDING/IN_PROGRESS/BLOCKED/SKIPPED or explicit Portuguese equivalents' 'PLAN owner' "Use an explicit supported status alias for $($step.Id); the validator does not guess or rewrite values."
        } else {
            $planStates[$step.Id] = $state
            if ($row.Status -notmatch '^(?i)(COMPLETED|PENDING|IN_PROGRESS|BLOCKED|SKIPPED)$') {
                Write-Output ("preflight: NORMALIZED field=Implementation progress/{0}/Status input='{1}' canonical={2}" -f $step.Id, $row.Status, $state)
            }
        }
        $planDependencyResult = Get-PreflightDependencyIds $row.Dependencies
        if ($planDependencyResult.Invalid.Count -gt 0) {
            Add-PreflightIssue "plan_dependency_invalid:$($step.Id)" (Get-PreflightArtifactRef $plan) "Implementation progress/$($step.Id)/Dependencies" ($planDependencyResult.Invalid -join ', ') 'existing PLAN step IDs or none' 'PLAN owner' "Replace non-step references in the dependency cell for $($step.Id) with actual PLAN step IDs."
        }
        $planDependencies = @($planDependencyResult.Ids)
        $dependenciesByStep[$step.Id] = $planDependencies
        if ($null -eq $refineHeading) { continue }
        $refineStartLine = $refineHeading.LineNumber
        $refineEndLine = $refineLines.Count
        foreach ($candidateHeading in $refineGroups) {
            if ($candidateHeading.LineNumber -gt $refineStartLine -and $candidateHeading.LineNumber -lt $refineEndLine) { $refineEndLine = $candidateHeading.LineNumber }
        }
        $refineBlock = if ($refineEndLine -gt $refineStartLine) { $refineLines[$refineStartLine..($refineEndLine - 1)] -join "`n" } else { $refineLines[$refineStartLine] }
        $refineDependencyText = Get-PreflightFieldValue $refineBlock @('Depends on','Dependencies','Dependências','Depende de')
        $refineDependencyResult = Get-PreflightDependencyIds $refineDependencyText
        if ($refineDependencyResult.Invalid.Count -gt 0) {
            Add-PreflightIssue "refine_dependency_invalid:$($step.Id)" (Get-PreflightArtifactRef $refine) "Depends on/$($step.Id)" ($refineDependencyResult.Invalid -join ', ') 'existing PLAN step IDs or none' 'REFINE owner' "Replace non-step references in the dependency field for $($step.Id) with actual PLAN step IDs."
        }
        $refineDependencies = @($refineDependencyResult.Ids)
        if (($planDependencies -join ',') -ne ($refineDependencies -join ',')) {
            Add-PreflightIssue "plan_refine_dependency_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) "Depends on/$($step.Id)" ($refineDependencies -join ',') ($planDependencies -join ',') 'REFINE owner' "Reconcile dependencies for $($step.Id), then rerun preflight."
        }
        if (($state -eq 'COMPLETED') -and -not (Test-PreflightStepState $refineBlock 'COMPLETED')) {
            Add-PreflightIssue "refine_step_state_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) "Status/$($step.Id)" 'not COMPLETED' 'COMPLETED to match PLAN' 'REFINE owner' "Reconcile the checklist state for $($step.Id), then rerun preflight."
        }
        if (($state -eq 'PENDING') -and -not (Test-PreflightStepState $refineBlock 'PENDING')) {
            Add-PreflightIssue "refine_step_state_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) "Status/$($step.Id)" 'not PENDING' 'PENDING to match PLAN' 'REFINE owner' "Reconcile the checklist state for $($step.Id), then rerun preflight."
        }
    }
    $script:PlanStates = $planStates
    for ($index = 0; $index -lt $steps.Count; $index++) {
        foreach ($dependency in $dependenciesByStep[$steps[$index].Id]) {
            $dependencyIndex = -1
            for ($candidateIndex = 0; $candidateIndex -lt $steps.Count; $candidateIndex++) {
                if ($steps[$candidateIndex].Id -eq $dependency) { $dependencyIndex = $candidateIndex; break }
            }
            if ($dependencyIndex -lt 0 -or $dependencyIndex -ge $index) {
                Add-PreflightIssue "plan_dependency_order_invalid:$($steps[$index].Id):$dependency" (Get-PreflightArtifactRef $plan) "dependencies/$($steps[$index].Id)" $dependency 'an earlier existing step ID' 'PLAN owner' "Correct the dependency reference for $($steps[$index].Id), then rerun preflight."
            }
        }
        if ($planStates.ContainsKey($steps[$index].Id) -and $planStates[$steps[$index].Id] -eq 'COMPLETED') {
            foreach ($dependency in $dependenciesByStep[$steps[$index].Id]) {
                if (-not $planStates.ContainsKey($dependency) -or $planStates[$dependency] -ne 'COMPLETED') {
                    $dependencyState = if ($planStates.ContainsKey($dependency)) { $planStates[$dependency] } else { 'missing' }
                    Add-PreflightIssue "plan_completion_order_invalid:$($steps[$index].Id)" (Get-PreflightArtifactRef $plan) "Status/$($steps[$index].Id)" "COMPLETED while dependency $dependency is $dependencyState" 'every declared dependency COMPLETED' 'PLAN owner' "Reconcile $($steps[$index].Id) with the state of its dependency $dependency, then rerun preflight."
                    break
                }
            }
        }
    }
    $storyReferencesPlan = Test-CanonicalPlanReference $storyText $story $plan $relativePlan $repo
    $prdReferencesPlan = Test-CanonicalPlanReference $prdText $prd $plan $relativePlan $repo
    if (-not $storyReferencesPlan -or -not $prdReferencesPlan) {
        Add-PreflightIssue 'story_prd_plan_navigation_mismatch' (Get-PreflightArtifactRef $story) 'Related PLAN path' 'missing or different from canonical PLAN' (Split-Path $plan -Leaf) 'story/PRD owner' 'Align STORY and PRD navigation with the canonical PLAN.'
    }
    if ($storyText -notmatch [regex]::Escape((Split-Path $featureDoc -Leaf)) -or $storyText -notmatch [regex]::Escape((Split-Path $continuity -Leaf))) {
        Add-PreflightIssue 'story_feature_navigation_mismatch' (Get-PreflightArtifactRef $story) 'Related feature paths' 'missing or different sibling paths' 'canonical FEATURE and CONTINUITY paths' 'story owner' 'Align STORY navigation with FEATURE and CONTINUITY.'
    }
    if ($prdText -notmatch [regex]::Escape((Split-Path $featureDoc -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $story -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $continuity -Leaf))) {
        Add-PreflightIssue 'prd_navigation_mismatch' (Get-PreflightArtifactRef $prd) 'Related paths' 'missing or different sibling paths' 'canonical FEATURE, STORY, and CONTINUITY paths' 'PRD owner' 'Align PRD navigation with canonical sibling paths.'
    }
    $progressValue = Get-PreflightFieldValue $planText @('Progresso','Progress') -TopLevelOnly
    $progress = [regex]::Match((Remove-PreflightDecoration $progressValue),'(?i)^\s*(?<completed>\d+)\s*/\s*(?<total>\d+)\b')
    if ($steps.Count -gt 0 -and -not $progress.Success) {
        Add-PreflightIssue 'plan_progress_total_mismatch' (Get-PreflightArtifactRef $plan) 'Progress' 'missing or malformed' ("N/{0}" -f $steps.Count) 'PLAN owner' 'Restore the progress count and rerun preflight.'
    } elseif ($steps.Count -gt 0 -and [int]$progress.Groups['total'].Value -ne $steps.Count) {
        Add-PreflightIssue 'plan_progress_total_mismatch' (Get-PreflightArtifactRef $plan) 'Progress total' $progress.Groups['total'].Value ([string]$steps.Count) 'PLAN owner' 'Set the progress total to the number of parsed PLAN steps, then rerun preflight.'
    }
    $completedIds = @($steps | Where-Object { $planStates.ContainsKey($_.Id) -and $planStates[$_.Id] -eq 'COMPLETED' } | ForEach-Object { $_.Id })
    $completed = $completedIds.Count
    if ($progress.Success -and $planStates.Count -eq $steps.Count -and [int]$progress.Groups['completed'].Value -ne $completed) {
        Add-PreflightIssue 'plan_progress_completed_mismatch' (Get-PreflightArtifactRef $plan) 'Progress completed' $progress.Groups['completed'].Value ([string]$completed) 'PLAN owner' 'Align the completed count with the persisted step states, then rerun preflight.'
    }
    $prdStatusRaw = Get-PreflightFieldValue $prdText @('Status','Estado','Situação') -TopLevelOnly
    $planImplementationStatusRaw = Get-PreflightFieldValue $planText @('Implementation status','Status da implementação') -TopLevelOnly
    $prdStatusAlias = Resolve-SddArtifactAlias -Domain 'prd-status' -Value (Remove-PreflightDecoration $prdStatusRaw)
    $planImplementationStatusAlias = Resolve-SddArtifactAlias -Domain 'execution-status' -Value (Remove-PreflightDecoration $planImplementationStatusRaw)
    $prdStatus = if ($prdStatusAlias.Recognized) { $prdStatusAlias.Canonical } else { $prdStatusRaw }
    $planImplementationStatus = if ($planImplementationStatusAlias.Recognized) { $planImplementationStatusAlias.Canonical } else { $planImplementationStatusRaw }
    if (-not $prdStatusAlias.Recognized) {
        $shown = if ([string]::IsNullOrWhiteSpace($prdStatusRaw)) { '<missing>' } else { $prdStatusRaw }
        Add-PreflightIssue 'prd_status_invalid' (Get-PreflightArtifactRef $prd) 'Status' $shown 'DRAFT, APPROVED, READY_FOR_PLANNING, IMPLEMENTED or explicit Portuguese equivalents' 'PRD owner' 'Set a recognized PRD lifecycle status; the validator does not guess or rewrite status values.'
    }
    if (-not $planImplementationStatusAlias.Recognized) {
        $shown = if ([string]::IsNullOrWhiteSpace($planImplementationStatusRaw)) { '<missing>' } else { $planImplementationStatusRaw }
        Add-PreflightIssue 'plan_implementation_status_invalid' (Get-PreflightArtifactRef $plan) 'Implementation status' $shown 'NOT_STARTED, IN_PROGRESS, BLOCKED, COMPLETED or explicit Portuguese equivalents' 'PLAN owner' 'Set a recognized implementation status; the validator does not guess or rewrite status values.'
    } elseif ($planImplementationStatus -eq 'SKIPPED') {
        Add-PreflightIssue 'plan_implementation_status_invalid' (Get-PreflightArtifactRef $plan) 'Implementation status' $planImplementationStatusRaw 'NOT_STARTED, IN_PROGRESS, BLOCKED, or COMPLETED; SKIPPED applies to individual steps' 'PLAN owner' 'Use a plan lifecycle status; reserve SKIPPED for a step whose omission has approved evidence.'
    }
    $planIsComplete = $planStates.Count -eq $steps.Count -and $steps.Count -gt 0 -and $completed -eq $steps.Count
    $supportedTransitionSources = @('READY_FOR_PLANNING')
    if ($AuthorizeCompletedPlanPrdTransition) {
        if (-not $planIsComplete -or -not [string]::Equals($planImplementationStatus,'COMPLETED',[StringComparison]::OrdinalIgnoreCase)) {
            Add-PreflightIssue 'terminal_transition_plan_not_closed' (Get-PreflightArtifactRef $plan) 'Implementation status/steps' "$planImplementationStatusRaw; completed=$completed/$($steps.Count)" 'COMPLETED/Concluído with every PLAN step completed' 'authorized sdd-develop owner' 'Complete and validate the entire PLAN before requesting the PRD status transition.'
        }
        if ($prdStatus -notin $supportedTransitionSources) {
            Add-PreflightIssue 'terminal_transition_source_invalid' (Get-PreflightArtifactRef $prd) 'Status' $prdStatusRaw 'Pronto para planejamento or Ready for planning' 'authorized sdd-develop owner' 'Use the transition preflight only from the approved planning-ready PRD state.'
        } else {
            $approval = Get-PreflightFieldValue $prdText @('Aprovação do conteúdo','Content approval') -TopLevelOnly
            if (-not (Test-PositiveContentApproval $approval)) {
                Add-PreflightIssue 'terminal_transition_content_approval_missing' (Get-PreflightArtifactRef $prd) 'Content approval' $approval 'persisted approved content record' 'PRD owner' 'Reconcile the canonical PRD content approval metadata before closeout.'
            }
        }
    } elseif ($planIsComplete -and $prdStatus -ne 'IMPLEMENTED') {
        Add-PreflightIssue "completed_plan_prd_status_mismatch:$prdStatusRaw" (Get-PreflightArtifactRef $prd) 'Status' $prdStatusRaw 'Implementado or Implemented after all PLAN steps complete' 'PRD owner' 'Reconcile the approved implementation closeout, then rerun preflight.'
    }
    if ($planIsComplete -and $prdStatus -eq 'IMPLEMENTED') {
        $terminalApproval = Get-PreflightFieldValue $prdText @('Aprovação do conteúdo','Content approval') -TopLevelOnly
        if (-not (Test-PositiveContentApproval $terminalApproval)) {
            Add-PreflightIssue 'completed_plan_content_approval_missing' (Get-PreflightArtifactRef $prd) 'Content approval' $terminalApproval 'persisted approved content record retained through closeout' 'PRD owner' 'Restore or reconcile the canonical PRD content approval metadata, then rerun preflight.'
        }
    }
    # The completed count alone is insufficient when execution stopped on a
    # blocked/skipped step: later steps remain ineligible even if they are the
    # next ordinal after the completed prefix.
    $next = @()
    if ($planStates.Count -eq $steps.Count) {
        foreach ($candidate in $steps) {
            $candidateState = $planStates[$candidate.Id]
            if ($candidateState -eq 'COMPLETED') { continue }
            if ($candidateState -in @('BLOCKED','SKIPPED')) { break }
            $dependenciesReady = $true
            foreach ($dependency in $dependenciesByStep[$candidate.Id]) {
                if (-not $planStates.ContainsKey($dependency) -or $planStates[$dependency] -ne 'COMPLETED') { $dependenciesReady = $false; break }
            }
            if ($dependenciesReady) { $next = @($candidate); break }
            break
        }
    }
    $continuityBlocks = @(Get-PreflightO3Blocks $continuityText)
    $continuityPlanBlocks = @($continuityBlocks | Where-Object { -not [string]::IsNullOrWhiteSpace($_.PlanValue) -and (Test-CanonicalPlanReference ("PLAN: $($_.PlanValue)") $continuity $plan $relativePlan $repo) })
    $continuityState = if ($continuityPlanBlocks.Count -eq 1) { $continuityPlanBlocks[0].Text } else { '' }
    if ($continuityBlocks.Count -eq 0) {
        Add-PreflightIssue 'continuity_o3_state_missing' (Get-PreflightArtifactRef $continuity) 'Estado atual do O3' 'no O3 block in CONTINUITY' 'one Estado atual do O3 block per PLAN' 'feature owner' 'Restore the per-PLAN O3 reconciliation blocks in CONTINUITY, then rerun preflight.'
    } elseif ($continuityPlanBlocks.Count -eq 0) {
        Add-PreflightIssue 'continuity_o3_block_missing' (Get-PreflightArtifactRef $continuity) 'Estado atual do O3 PLAN' 'no block keyed by the validated PLAN path' $relativePlan 'feature owner' "Add the Estado atual do O3 block for $relativePlan to CONTINUITY, then rerun preflight."
    } elseif ($continuityPlanBlocks.Count -gt 1) {
        Add-PreflightIssue 'continuity_o3_block_duplicate' (Get-PreflightArtifactRef $continuity) 'Estado atual do O3 PLAN' 'more than one block for the validated PLAN path' $relativePlan 'feature owner' "Keep exactly one Estado atual do O3 block for $relativePlan, then rerun preflight."
    } elseif ($planStates.Count -eq $steps.Count -and $progress.Success -and [int]$progress.Groups['total'].Value -eq $steps.Count) {
        $continuityPlanPath = Get-PreflightFieldValue $continuityState @('PLAN')
        $continuityProgressValue = Get-PreflightFieldValue $continuityState @('Progresso','Progress')
        $continuityProgressMatch = [regex]::Match((Remove-PreflightDecoration $continuityProgressValue),'(?i)^\s*(?<completed>\d+)\s*/\s*(?<total>\d+)\b')
        $continuityCompletedValue = Get-PreflightFieldValue $continuityState @('Concluídos','Completed')
        $continuityNextValue = Get-PreflightFieldValue $continuityState @('Próximo','Next')
        $continuityCompletedIds = @(Get-PreflightReferencedStepIds $continuityCompletedValue)
        $continuityNextIds = @(Get-PreflightReferencedStepIds $continuityNextValue)
        $expectedNextId = if ($next.Count -gt 0) { $next[0].Id } else { 'none' }
        $expectedCompleted = if ($completedIds.Count -gt 0) { $completedIds -join ', ' } else { 'none' }
        if (-not (Test-CanonicalPlanReference ("PLAN: $continuityPlanPath") $continuity $plan $relativePlan $repo)) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:plan' (Get-PreflightArtifactRef $continuity) 'PLAN' $continuityPlanPath $relativePlan 'feature owner' 'Update CONTINUITY to reference the canonical PLAN, then rerun preflight.'
        }
        if (-not $continuityProgressMatch.Success -or [int]$continuityProgressMatch.Groups['completed'].Value -ne [int]$progress.Groups['completed'].Value -or [int]$continuityProgressMatch.Groups['total'].Value -ne [int]$progress.Groups['total'].Value) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:progress' (Get-PreflightArtifactRef $continuity) 'Progresso' $continuityProgressValue $progressValue 'feature owner' 'Reconcile CONTINUITY progress with the PLAN, then rerun preflight.'
        }
        if (($continuityCompletedIds -join ',') -ne ($completedIds -join ',')) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:completed' (Get-PreflightArtifactRef $continuity) 'Completed' $continuityCompletedValue $expectedCompleted 'feature owner' 'Reconcile the completed-step list with the PLAN, then rerun preflight.'
        }
        $actualNextId = if ($continuityNextIds.Count -gt 0) { $continuityNextIds[0] } else { 'none' }
        if (-not [string]::Equals($actualNextId,$expectedNextId,[StringComparison]::OrdinalIgnoreCase) -or $continuityNextIds.Count -gt 1) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:next' (Get-PreflightArtifactRef $continuity) 'Next' $continuityNextValue $expectedNextId 'feature owner' 'Reconcile the next eligible step with the PLAN, then rerun preflight.'
        }
    }
    if ($script:PreflightIssues.Count -gt 0) { Write-PreflightBlock; exit 2 }
    $git = & git -C $repo status --short --untracked-files=no -- $relativeFeature 2>$null
    if ($AuthorizeCompletedPlanPrdTransition) {
        $targetStatus = if ((ConvertTo-SddArtifactAliasKey $prdStatusRaw) -eq 'prontoparaplanejamento') { 'Implementado' } else { 'Implemented' }
        Write-Output "preflight: TRANSITION_READY - plan=$relativePlan; source=$prdStatusRaw; target=$targetStatus; owner=authorized sdd-develop closeout only; no files changed; rerun standard preflight after the PRD status write; $script:StorageSummary"
        if ($EmitStepTable) { Write-PreflightStepTable }
        exit 0
    }
    Write-Output "preflight: ALLOW - plan=$relativePlan; status=approved; steps=$($steps.Count); completed=$completed; $script:StorageSummary; git_feature_status=$([string]::Join('',@($git)))"
    if ($EmitStepTable) { Write-PreflightStepTable }
    exit 0
}
catch {
    Add-PreflightIssue 'validation_error' (Get-PreflightArtifactRef $plan) 'validation' $_.Exception.Message 'all independent validations completed' 'O3 parent' 'Resolve the unexpected validation error and rerun preflight.'
    Write-PreflightBlock
    exit 2
}
