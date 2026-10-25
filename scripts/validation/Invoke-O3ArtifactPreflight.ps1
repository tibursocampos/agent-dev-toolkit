#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $FeatureRoot,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [string] $RepoPath = (Get-Location).Path,
    [string] $SddRoot,
    [switch] $AuthorizeCompletedPlanPrdTransition
)

$ErrorActionPreference = 'Stop'
$script:StorageSummary = 'features_versioned=unknown'
$script:PreflightIssues = [System.Collections.Generic.List[object]]::new()
. (Join-Path $PSScriptRoot '..\_lib\Get-ToolkitRelativePath.ps1')

function Format-PreflightValue([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return 'unknown' }
    return ($Value -replace '[\r\n]+',' ' -replace ';',',').Trim()
}

function Test-PositiveContentApproval([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '[\[\]]') { return $false }
    return $Value -match '(?i)^\s*(?:Approved by operator(?: in this conversation)? on \d{4}-\d{2}-\d{2}|Aprovad[oa] pelo operador(?: nesta conversa)? em \d{4}-\d{2}-\d{2})\s*$'
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
    if ($relativeFeature.StartsWith('../') -or $relativeFeature -match '^\.\.' -or $relativePlanInStorage -notmatch '^[^/]+/US\d{2}/PLAN/PLAN_\d{3}_[^/]+\.md$' -or $relativeFeature -ne $planFeatureSegment) {
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
    $status = [regex]::Match($planText,'(?im)^\|\s*(?:\*\*Status\*\*|Status)\s*\|\s*([^|]+)\|').Groups[1].Value.Trim()
    if ($status -cne 'approved') {
        Add-PreflightIssue 'plan_not_explicitly_approved' (Get-PreflightArtifactRef $plan) 'Status' $status 'approved' 'PLAN owner' 'Obtain and persist PLAN approval before O3 effects.'
    }

    $featureText = Get-Content -LiteralPath $featureDoc -Raw -Encoding UTF8
    $storyText = Get-Content -LiteralPath $story -Raw -Encoding UTF8
    $prdText = Get-Content -LiteralPath $prd -Raw -Encoding UTF8
    $refineText = Get-Content -LiteralPath $refine -Raw -Encoding UTF8
    $continuityText = Get-Content -LiteralPath $continuity -Raw -Encoding UTF8
    $featureId = [regex]::Match($featureText,'(?im)^\|\s*\*\*Id\*\*\s*\|\s*`?([^`|]+)').Groups[1].Value.Trim()
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
    if ($storyId -notmatch '^US\d{2}$' -or $storyText -notmatch [regex]::Escape($storyId) -or $storyText -notmatch [regex]::Escape($relativeFeature)) {
        Add-PreflightIssue 'story_identity_or_feature_scope_mismatch' (Get-PreflightArtifactRef $story) 'Feature/story identity' $storyId 'canonical USnn and matching feature path' 'story owner' 'Align the STORY identity and feature path with its folder.'
    }
    foreach ($pair in @(@($storyText,'STORY'),@($prdText,'PRD'),@($refineText,'REFINE'),@($continuityText,'CONTINUITY'))) {
        if (-not [string]::IsNullOrWhiteSpace($featureId) -and $pair[0] -notmatch [regex]::Escape($featureId)) {
            $artifactPath = switch ($pair[1]) { 'STORY' { $story } 'PRD' { $prd } 'REFINE' { $refine } 'CONTINUITY' { $continuity } }
            Add-PreflightIssue "feature_identity_mismatch:$($pair[1])" (Get-PreflightArtifactRef $artifactPath) 'Feature Id' 'missing or different feature identity' $featureId "$($pair[1]) owner" "Align the $($pair[1]) feature identity with FEATURE.md."
        }
    }

    $steps = @([regex]::Matches($planText,'(?m)^###\s+[✅☐☑]*\s*(?:STEP|PASSO)\s+(\d+)\s+—\s+(S\d+)\s*:\s*(.+)$') | ForEach-Object {
        [PSCustomObject]@{ Number=[int]$_.Groups[1].Value; Id=$_.Groups[2].Value; Name=$_.Groups[3].Value.Trim() }
    })
    if ($steps.Count -eq 0) {
        Add-PreflightIssue 'plan_steps_missing' (Get-PreflightArtifactRef $plan) 'step headings' 'none recognized' 'at least one canonical STEP/PASSO heading' 'PLAN owner' 'Restore valid PLAN step headings, then rerun preflight.'
    }
    $progressSectionMatch = [regex]::Match($planText,'(?ms)^## (?:Progresso da implementação|Implementation progress)\s*\r?\n(?<section>.*?)(?=^## |\z)')
    if (-not $progressSectionMatch.Success) {
        Add-PreflightIssue 'plan_progress_section_missing' (Get-PreflightArtifactRef $plan) 'Implementation progress' 'section missing' 'a progress section containing one ledger row per PLAN step' 'PLAN owner' 'Restore the PLAN progress section, then rerun preflight.'
        $progressSection = ''
    } else { $progressSection = $progressSectionMatch.Groups['section'].Value }
    $refineGroups = @([regex]::Matches($refineText,'(?m)^###\s+[✅☐☑]*\s*(?:STEP|PASSO)\s+\d+\s+—\s+(.+)$'))
    $planStates = @{}
    $dependenciesByStep = @{}
    foreach ($step in $steps) {
        $row = [regex]::Match($progressSection, ('(?m)^\|\s*{0}\s*\|[^\r\n]*\r?$' -f [regex]::Escape($step.Id)))
        if (-not $row.Success) {
            Add-PreflightIssue "plan_step_ledger_missing:$($step.Id)" (Get-PreflightArtifactRef $plan) "Implementation progress/$($step.Id)" 'row missing' 'one ledger row with dependencies and status' 'PLAN owner' "Restore the progress row for $($step.Id), then rerun preflight."
        }
        $refineContainsStep = $refineText -match ('(?<![A-Za-z0-9]){0}(?!\d)' -f [regex]::Escape($step.Id))
        if (-not $refineContainsStep) {
            Add-PreflightIssue "plan_refine_step_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) 'step IDs' 'PLAN step absent from REFINE' $step.Id 'REFINE owner' "Reconcile the checklist row for $($step.Id), then rerun preflight."
        }
        if (-not $row.Success) { continue }
        $cells = @($row.Value.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 5) {
            Add-PreflightIssue "plan_step_ledger_invalid:$($step.Id)" (Get-PreflightArtifactRef $plan) "Implementation progress/$($step.Id)" ([string]$cells.Count) 'at least five ledger columns' 'PLAN owner' "Restore the required ledger columns for $($step.Id), then rerun preflight."
            continue
        }
        $state = $cells[4].Trim('`')
        if ($state -notin @('COMPLETED','PENDING','IN_PROGRESS','BLOCKED','SKIPPED')) {
            Add-PreflightIssue "plan_step_state_invalid:$($step.Id)" (Get-PreflightArtifactRef $plan) "Implementation progress/$($step.Id)/Status" $state 'COMPLETED, PENDING, IN_PROGRESS, BLOCKED, or SKIPPED' 'PLAN owner' "Set a supported state for $($step.Id), then rerun preflight."
        } else { $planStates[$step.Id] = $state }
        $planDependencies = @([regex]::Matches($cells[2],'S\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique)
        $dependenciesByStep[$step.Id] = $planDependencies
        $refineHeading = $null
        foreach ($group in $refineGroups) {
            if ($group.Groups[1].Value -match ('(?<![A-Za-z0-9]){0}(?!\d)' -f [regex]::Escape($step.Id))) { $refineHeading = $group; break }
        }
        if ($null -eq $refineHeading) {
            Add-PreflightIssue "refine_step_heading_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) "step heading/$($step.Id)" 'missing' 'one matching step heading' 'REFINE owner' "Restore the heading for $($step.Id), then rerun preflight."
            continue
        }
        $refineStart = $refineHeading.Index
        $refineEndMatch = [regex]::Match($refineText.Substring($refineStart + $refineHeading.Length),'(?m)^###\s+[✅☐☑]*\s*(?:STEP|PASSO)\s+')
        $refineBlockLength = if ($refineEndMatch.Success) { $refineHeading.Length + $refineEndMatch.Index } else { $refineText.Length - $refineStart }
        $refineBlock = $refineText.Substring($refineStart,$refineBlockLength)
        $refineDependencyMatch = [regex]::Match($refineBlock,'(?im)Depends on:\*\*?\s*([^|\r\n]+)')
        $refineDependencies = if ($refineDependencyMatch.Success) { @([regex]::Matches($refineDependencyMatch.Groups[1].Value,'S\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique) } else { @() }
        if (($planDependencies -join ',') -ne ($refineDependencies -join ',')) {
            Add-PreflightIssue "plan_refine_dependency_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) "Depends on/$($step.Id)" ($refineDependencies -join ',') ($planDependencies -join ',') 'REFINE owner' "Reconcile dependencies for $($step.Id), then rerun preflight."
        }
        if (($state -eq 'COMPLETED') -and $refineBlock -notmatch '(?m)^☑\s*`?COMPLETED') {
            Add-PreflightIssue "refine_step_state_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) "Status/$($step.Id)" 'not COMPLETED' 'COMPLETED to match PLAN' 'REFINE owner' "Reconcile the checklist state for $($step.Id), then rerun preflight."
        }
        if (($state -eq 'PENDING') -and $refineBlock -notmatch '(?m)^☐\s*`?PENDING') {
            Add-PreflightIssue "refine_step_state_mismatch:$($step.Id)" (Get-PreflightArtifactRef $refine) "Status/$($step.Id)" 'not PENDING' 'PENDING to match PLAN' 'REFINE owner' "Reconcile the checklist state for $($step.Id), then rerun preflight."
        }
    }
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
        if ($planStates.ContainsKey($steps[$index].Id) -and $index -gt 0 -and $planStates[$steps[$index].Id] -eq 'COMPLETED' -and $planStates.ContainsKey($steps[$index - 1].Id) -and $planStates[$steps[$index - 1].Id] -ne 'COMPLETED') {
            Add-PreflightIssue "plan_completion_order_invalid:$($steps[$index].Id)" (Get-PreflightArtifactRef $plan) "Status/$($steps[$index].Id)" 'COMPLETED before previous step' 'completed prefix follows PLAN order' 'PLAN owner' 'Reconcile step statuses to the completed prefix, then rerun preflight.'
        }
    }
    if ($storyText -notmatch [regex]::Escape((Split-Path $plan -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $plan -Leaf))) {
        Add-PreflightIssue 'story_prd_plan_navigation_mismatch' (Get-PreflightArtifactRef $story) 'Related PLAN path' 'missing or different from canonical PLAN' (Split-Path $plan -Leaf) 'story/PRD owner' 'Align STORY and PRD navigation with the canonical PLAN.'
    }
    if ($storyText -notmatch [regex]::Escape((Split-Path $featureDoc -Leaf)) -or $storyText -notmatch [regex]::Escape((Split-Path $continuity -Leaf))) {
        Add-PreflightIssue 'story_feature_navigation_mismatch' (Get-PreflightArtifactRef $story) 'Related feature paths' 'missing or different sibling paths' 'canonical FEATURE and CONTINUITY paths' 'story owner' 'Align STORY navigation with FEATURE and CONTINUITY.'
    }
    if ($prdText -notmatch [regex]::Escape((Split-Path $featureDoc -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $story -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $continuity -Leaf))) {
        Add-PreflightIssue 'prd_navigation_mismatch' (Get-PreflightArtifactRef $prd) 'Related paths' 'missing or different sibling paths' 'canonical FEATURE, STORY, and CONTINUITY paths' 'PRD owner' 'Align PRD navigation with canonical sibling paths.'
    }
    $progress = [regex]::Match($planText,'(?im)^\|\s*\*\*(?:Progresso|Progress)\*\*\s*\|\s*(\d+)\s*/\s*(\d+)\s*\|')
    if ($steps.Count -gt 0 -and -not $progress.Success) {
        Add-PreflightIssue 'plan_progress_total_mismatch' (Get-PreflightArtifactRef $plan) 'Progress' 'missing or malformed' ("N/{0}" -f $steps.Count) 'PLAN owner' 'Restore the progress count and rerun preflight.'
    } elseif ($steps.Count -gt 0 -and [int]$progress.Groups[2].Value -ne $steps.Count) {
        Add-PreflightIssue 'plan_progress_total_mismatch' (Get-PreflightArtifactRef $plan) 'Progress total' $progress.Groups[2].Value ([string]$steps.Count) 'PLAN owner' 'Set the progress total to the number of parsed PLAN steps, then rerun preflight.'
    }
    $completedIds = @($steps | Where-Object { $planStates.ContainsKey($_.Id) -and $planStates[$_.Id] -eq 'COMPLETED' } | ForEach-Object { $_.Id })
    $completed = $completedIds.Count
    if ($progress.Success -and $planStates.Count -eq $steps.Count -and [int]$progress.Groups[1].Value -ne $completed) {
        Add-PreflightIssue 'plan_progress_completed_mismatch' (Get-PreflightArtifactRef $plan) 'Progress completed' $progress.Groups[1].Value ([string]$completed) 'PLAN owner' 'Align the completed count with the persisted step states, then rerun preflight.'
    }
    $prdStatus = [regex]::Match($prdText,'(?im)^\|\s*\*\*Status\*\*\s*\|\s*([^|]+)\|').Groups[1].Value.Trim()
    $planImplementationStatus = [regex]::Match($planText,'(?im)^\|\s*(?:\*\*Implementation status\*\*|\*\*Status da implementação\*\*)\s*\|\s*([^|]+)\|').Groups[1].Value.Trim()
    $planIsComplete = $planStates.Count -eq $steps.Count -and $steps.Count -gt 0 -and $completed -eq $steps.Count
    $supportedTransitionSources = @('Pronto para planejamento','Ready for planning')
    if ($AuthorizeCompletedPlanPrdTransition) {
        if (-not $planIsComplete -or $planImplementationStatus -cne 'COMPLETED') {
            Add-PreflightIssue 'terminal_transition_plan_not_closed' (Get-PreflightArtifactRef $plan) 'Implementation status/steps' "$planImplementationStatus; completed=$completed/$($steps.Count)" 'COMPLETED with every PLAN step COMPLETED' 'authorized sdd-develop owner' 'Complete and validate the entire PLAN before requesting the PRD status transition.'
        }
        if ($prdStatus -notin $supportedTransitionSources) {
            Add-PreflightIssue 'terminal_transition_source_invalid' (Get-PreflightArtifactRef $prd) 'Status' $prdStatus 'Pronto para planejamento or Ready for planning' 'authorized sdd-develop owner' 'Use the transition preflight only from the approved planning-ready PRD state.'
        } else {
            $approval = [regex]::Match($prdText,'(?im)^\|\s*(?:\*\*Aprovação do conteúdo\*\*|\*\*Content approval\*\*)\s*\|\s*([^|]+)\|').Groups[1].Value.Trim()
            if (-not (Test-PositiveContentApproval $approval)) {
                Add-PreflightIssue 'terminal_transition_content_approval_missing' (Get-PreflightArtifactRef $prd) 'Content approval' $approval 'persisted approved content record' 'PRD owner' 'Reconcile the canonical PRD content approval metadata before closeout.'
            }
        }
    } elseif ($planIsComplete -and $prdStatus -notin @('Implementado','Implemented')) {
        Add-PreflightIssue "completed_plan_prd_status_mismatch:$prdStatus" (Get-PreflightArtifactRef $prd) 'Status' $prdStatus 'Implementado or Implemented after all PLAN steps complete' 'PRD owner' 'Reconcile the approved implementation closeout, then rerun preflight.'
    }
    if ($planIsComplete -and $prdStatus -in @('Implementado','Implemented')) {
        $terminalApproval = [regex]::Match($prdText,'(?im)^\|\s*(?:\*\*Aprovação do conteúdo\*\*|\*\*Content approval\*\*)\s*\|\s*([^|]+)\|').Groups[1].Value.Trim()
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
    $continuityState = [regex]::Match($continuityText,'(?ms)^## (?:Estado atual do O3|Current O3 state|O3 current state)\s*\r?\n(?<state>.*?)(?=^## |\z)').Groups['state'].Value
    if ([string]::IsNullOrWhiteSpace($continuityState)) {
        Add-PreflightIssue 'continuity_o3_state_missing' (Get-PreflightArtifactRef $continuity) 'Estado atual do O3' 'section missing or empty' 'PLAN, progress, completed steps, and next eligible step' 'feature owner' 'Restore the O3 reconciliation section in CONTINUITY, then rerun preflight.'
    } elseif ($planStates.Count -eq $steps.Count -and $progress.Success -and [int]$progress.Groups[2].Value -eq $steps.Count) {
        $continuityPlanPath = [regex]::Match($continuityState,'(?im)^- PLAN:\s*`?([^`\r\n]+)').Groups[1].Value.Trim()
        $continuityProgressMatch = [regex]::Match($continuityState,'(?im)^- (?:Progresso|Progress):\s*(\d+)\s*/\s*(\d+)')
        $continuityCompleted = [regex]::Match($continuityState,'(?im)^- (?:Concluídos|Completed):\s*(.*)$').Groups[1].Value.Trim()
        $continuityNext = [regex]::Match($continuityState,'(?im)^- (?:Próximo|Next):\s*(.*)$').Groups[1].Value.Trim()
        $expectedNext = if ($next.Count -gt 0) { "$($next[0].Id) — $($next[0].Name)" } else { 'none' }
        $expectedCompleted = if ($completedIds.Count -gt 0) { $completedIds -join ', ' } else { 'none' }
        if (-not [string]::Equals($continuityPlanPath, $relativePlan, [StringComparison]::Ordinal)) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:plan' (Get-PreflightArtifactRef $continuity) 'PLAN' $continuityPlanPath $relativePlan 'feature owner' 'Update CONTINUITY to reference the canonical PLAN, then rerun preflight.'
        }
        if (-not $continuityProgressMatch.Success -or [int]$continuityProgressMatch.Groups[1].Value -ne [int]$progress.Groups[1].Value -or [int]$continuityProgressMatch.Groups[2].Value -ne [int]$progress.Groups[2].Value) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:progress' (Get-PreflightArtifactRef $continuity) 'Progresso' $continuityProgressMatch.Value $progress.Value 'feature owner' 'Reconcile CONTINUITY progress with the PLAN, then rerun preflight.'
        }
        if (-not [string]::Equals($continuityCompleted, $expectedCompleted, [StringComparison]::Ordinal)) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:completed' (Get-PreflightArtifactRef $continuity) 'Completed' $continuityCompleted $expectedCompleted 'feature owner' 'Reconcile the completed-step list with the PLAN, then rerun preflight.'
        }
        if (-not [string]::Equals($continuityNext, $expectedNext, [StringComparison]::Ordinal)) {
            Add-PreflightIssue 'continuity_plan_reconciliation_mismatch:next' (Get-PreflightArtifactRef $continuity) 'Next' $continuityNext $expectedNext 'feature owner' 'Reconcile the next eligible step with the PLAN, then rerun preflight.'
        }
    }
    if ($script:PreflightIssues.Count -gt 0) { Write-PreflightBlock; exit 2 }
    $git = & git -C $repo status --short --untracked-files=no -- $relativeFeature 2>$null
    if ($AuthorizeCompletedPlanPrdTransition) {
        $targetStatus = if ($prdStatus -ceq 'Pronto para planejamento') { 'Implementado' } else { 'Implemented' }
        Write-Output "preflight: TRANSITION_READY - plan=$relativePlan; source=$prdStatus; target=$targetStatus; owner=authorized sdd-develop closeout only; no files changed; rerun standard preflight after the PRD status write; $script:StorageSummary"
        exit 0
    }
    Write-Output "preflight: ALLOW - plan=$relativePlan; status=approved; steps=$($steps.Count); completed=$completed; $script:StorageSummary; git_feature_status=$([string]::Join('',@($git)))"
    exit 0
}
catch {
    Add-PreflightIssue 'validation_error' (Get-PreflightArtifactRef $plan) 'validation' $_.Exception.Message 'all independent validations completed' 'O3 parent' 'Resolve the unexpected validation error and rerun preflight.'
    Write-PreflightBlock
    exit 2
}
