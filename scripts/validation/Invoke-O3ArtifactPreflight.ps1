#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $FeatureRoot,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [string] $RepoPath = (Get-Location).Path,
    [string] $SddRoot
)

$ErrorActionPreference = 'Stop'
$script:StorageSummary = 'features_versioned=unknown'
. (Join-Path $PSScriptRoot '..\_lib\Get-ToolkitRelativePath.ps1')

function Stop-Preflight([string]$Reason) {
    Write-Output "preflight: BLOCK - $Reason; $script:StorageSummary"
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
        if (-not (Test-Path -LiteralPath $path)) { Stop-Preflight "required_artifact_missing:$((Get-ToolkitRelativePath -BasePath $repo -TargetPath $path).Replace('\','/'))" }
    }
    if ($prds.Count -ne 1) { Stop-Preflight 'expected_exactly_one_story_prd' }
    $prd = $prds[0].FullName
    $planText = Get-Content -LiteralPath $plan -Raw -Encoding UTF8
    $status = [regex]::Match($planText,'(?im)^\|\s*\*\*Status\*\*\s*\|\s*([^|]+)\|').Groups[1].Value.Trim()
    if ($status -cne 'approved') { Stop-Preflight 'plan_not_explicitly_approved' }

    $featureText = Get-Content -LiteralPath $featureDoc -Raw -Encoding UTF8
    $storyText = Get-Content -LiteralPath $story -Raw -Encoding UTF8
    $prdText = Get-Content -LiteralPath $prd -Raw -Encoding UTF8
    $refineText = Get-Content -LiteralPath $refine -Raw -Encoding UTF8
    $continuityText = Get-Content -LiteralPath $continuity -Raw -Encoding UTF8
    $featureId = [regex]::Match($featureText,'(?im)^\|\s*\*\*Id\*\*\s*\|\s*`?([^`|]+)').Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($featureId) -or $relativeFeature -notmatch (('^{0}-' -f [regex]::Escape($featureId)))) { Stop-Preflight 'feature_identity_unverifiable' }
    $featureSequence = [regex]::Match($featureId,'^\d{3}$')
    $planSequence = [regex]::Match((Split-Path $plan -Leaf),'^PLAN_(\d{3})_').Groups[1].Value
    $prdSequence = [regex]::Match((Split-Path $prd -Leaf),'^(\d{3})_').Groups[1].Value
    if (-not $featureSequence.Success -or $planSequence -ne $featureId -or $prdSequence -ne $featureId) { Stop-Preflight ("feature_plan_prd_identity_mismatch:feature={0};plan={1};prd={2}" -f $featureId,$planSequence,$prdSequence) }
    $storyId = Split-Path $storyRoot -Leaf
    if ($storyId -notmatch '^US\d{2}$' -or $storyText -notmatch [regex]::Escape($storyId) -or $storyText -notmatch [regex]::Escape($relativeFeature)) { Stop-Preflight 'story_identity_or_feature_scope_mismatch' }
    foreach ($pair in @(@($storyText,'STORY'),@($prdText,'PRD'),@($refineText,'REFINE'),@($continuityText,'CONTINUITY'))) {
        if ($pair[0] -notmatch [regex]::Escape($featureId)) { Stop-Preflight "feature_identity_mismatch:$($pair[1])" }
    }

    $steps = @([regex]::Matches($planText,'(?m)^###\s+[✅☐☑]*\s*STEP\s+(\d+)\s+—\s+(S\d+)\s*:\s*(.+)$') | ForEach-Object {
        [PSCustomObject]@{ Number=[int]$_.Groups[1].Value; Id=$_.Groups[2].Value; Name=$_.Groups[3].Value.Trim() }
    })
    if ($steps.Count -eq 0) { Stop-Preflight 'plan_steps_missing' }
    $progressSectionMatch = [regex]::Match($planText,'(?ms)^## Progresso da implementação\s*\r?\n(?<section>.*?)(?=^## |\z)')
    if (-not $progressSectionMatch.Success) { Stop-Preflight 'plan_progress_section_missing' }
    $progressSection = $progressSectionMatch.Groups['section'].Value
    $refineGroups = @([regex]::Matches($refineText,'(?m)^###\s+[✅☐☑]*\s*STEP\s+\d+\s+—\s+(.+)$'))
    $planStates = @{}
    $dependenciesByStep = @{}
    foreach ($step in $steps) {
        if ($refineText -notmatch ('(?<![A-Za-z0-9]){0}(?!\d)' -f [regex]::Escape($step.Id))) { Stop-Preflight "plan_refine_step_mismatch:$($step.Id)" }
        $row = [regex]::Match($progressSection, ('(?m)^\|\s*{0}\s*\|[^\r\n]*$' -f [regex]::Escape($step.Id)))
        if (-not $row.Success) { Stop-Preflight "plan_step_ledger_missing:$($step.Id)" }
        $cells = @($row.Value.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 5) { Stop-Preflight "plan_step_ledger_invalid:$($step.Id)" }
        $state = $cells[4].Trim('`')
        if ($state -notin @('COMPLETED','PENDING','IN_PROGRESS','BLOCKED','FAILED')) { Stop-Preflight "plan_step_state_invalid:$($step.Id)" }
        $planStates[$step.Id] = $state
        $planDependencies = @([regex]::Matches($cells[2],'S\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique)
        $dependenciesByStep[$step.Id] = $planDependencies
        $refineHeading = $null
        foreach ($group in $refineGroups) {
            if ($group.Groups[1].Value -match ('(?<![A-Za-z0-9]){0}(?!\d)' -f [regex]::Escape($step.Id))) { $refineHeading = $group; break }
        }
        if ($null -eq $refineHeading) { Stop-Preflight "refine_step_heading_mismatch:$($step.Id)" }
        $refineStart = $refineHeading.Index
        $refineEndMatch = [regex]::Match($refineText.Substring($refineStart + $refineHeading.Length),'(?m)^###\s+[✅☐☑]*\s*STEP\s+')
        $refineBlockLength = if ($refineEndMatch.Success) { $refineHeading.Length + $refineEndMatch.Index } else { $refineText.Length - $refineStart }
        $refineBlock = $refineText.Substring($refineStart,$refineBlockLength)
        $refineDependencyMatch = [regex]::Match($refineBlock,'(?im)Depends on:\*\*?\s*([^|\r\n]+)')
        $refineDependencies = if ($refineDependencyMatch.Success) { @([regex]::Matches($refineDependencyMatch.Groups[1].Value,'S\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique) } else { @() }
        if (($planDependencies -join ',') -ne ($refineDependencies -join ',')) { Stop-Preflight ("plan_refine_dependency_mismatch:{0}:plan={1};refine={2}" -f $step.Id,($planDependencies -join ','),($refineDependencies -join ',')) }
        if (($state -eq 'COMPLETED') -and $refineBlock -notmatch '(?m)^☑\s*`?COMPLETED') { Stop-Preflight "refine_step_state_mismatch:$($step.Id)" }
        if (($state -eq 'PENDING') -and $refineBlock -notmatch '(?m)^☐\s*`?PENDING') { Stop-Preflight "refine_step_state_mismatch:$($step.Id)" }
    }
    for ($index = 0; $index -lt $steps.Count; $index++) {
        foreach ($dependency in $dependenciesByStep[$steps[$index].Id]) {
            $dependencyIndex = -1
            for ($candidateIndex = 0; $candidateIndex -lt $steps.Count; $candidateIndex++) {
                if ($steps[$candidateIndex].Id -eq $dependency) { $dependencyIndex = $candidateIndex; break }
            }
            if ($dependencyIndex -lt 0 -or $dependencyIndex -ge $index) { Stop-Preflight "plan_dependency_order_invalid:$($steps[$index].Id):$dependency" }
        }
        if ($index -gt 0 -and $planStates[$steps[$index].Id] -eq 'COMPLETED' -and $planStates[$steps[$index - 1].Id] -ne 'COMPLETED') { Stop-Preflight "plan_completion_order_invalid:$($steps[$index].Id)" }
    }
    if ($storyText -notmatch [regex]::Escape((Split-Path $plan -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $plan -Leaf))) { Stop-Preflight 'story_prd_plan_navigation_mismatch' }
    if ($storyText -notmatch [regex]::Escape((Split-Path $featureDoc -Leaf)) -or $storyText -notmatch [regex]::Escape((Split-Path $continuity -Leaf))) { Stop-Preflight 'story_feature_navigation_mismatch' }
    if ($prdText -notmatch [regex]::Escape((Split-Path $featureDoc -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $story -Leaf)) -or $prdText -notmatch [regex]::Escape((Split-Path $continuity -Leaf))) { Stop-Preflight 'prd_navigation_mismatch' }
    $progress = [regex]::Match($planText,'(?im)^\|\s*\*\*Progresso\*\*\s*\|\s*(\d+)\s*/\s*(\d+)\s*\|')
    if (-not $progress.Success -or [int]$progress.Groups[2].Value -ne $steps.Count) { Stop-Preflight 'plan_progress_total_mismatch' }
    $completedIds = @($steps | Where-Object { $planStates[$_.Id] -eq 'COMPLETED' } | ForEach-Object { $_.Id })
    $completed = $completedIds.Count
    if ([int]$progress.Groups[1].Value -ne $completed) { Stop-Preflight 'plan_progress_completed_mismatch' }
    $prdStatus = [regex]::Match($prdText,'(?im)^\|\s*\*\*Status\*\*\s*\|\s*([^|]+)\|').Groups[1].Value.Trim()
    if ($completed -eq $steps.Count -and $prdStatus -notin @('Implementado','Implemented')) { Stop-Preflight "completed_plan_prd_status_mismatch:$prdStatus" }
    # The completed count alone is insufficient when execution stopped on a
    # blocked/failed step: later steps remain ineligible even if they are the
    # next ordinal after the completed prefix.
    $next = @()
    foreach ($candidate in $steps) {
        $candidateState = $planStates[$candidate.Id]
        if ($candidateState -eq 'COMPLETED') { continue }
        if ($candidateState -in @('BLOCKED','FAILED')) { break }
        $dependenciesReady = $true
        foreach ($dependency in $dependenciesByStep[$candidate.Id]) {
            if ($planStates[$dependency] -ne 'COMPLETED') { $dependenciesReady = $false; break }
        }
        if ($dependenciesReady) { $next = @($candidate); break }
        break
    }
    $continuityState = [regex]::Match($continuityText,'(?ms)^## Estado atual do O3\s*\r?\n(?<state>.*?)(?=^## |\z)').Groups['state'].Value
    if ([string]::IsNullOrWhiteSpace($continuityState)) { Stop-Preflight 'continuity_o3_state_missing' }
    $continuityPlanPath = [regex]::Match($continuityState,'(?im)^- PLAN:\s*`?([^`\r\n]+)').Groups[1].Value.Trim()
    $continuityProgressMatch = [regex]::Match($continuityState,'(?im)^- Progresso:\s*(\d+)\s*/\s*(\d+)')
    $continuityProgress = $continuityProgressMatch.Groups
    # Read the two remaining fields by their stable position in the required
    # four-line O3 state block. This avoids PowerShell 5.1 source-encoding
    # differences in the accented Portuguese labels.
    $continuityStateLines = @($continuityState -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $continuityCompleted = if ($continuityStateLines.Count -ge 3) { ($continuityStateLines[2] -split ':',2)[-1].Trim() } else { '' }
    $continuityNext = if ($continuityStateLines.Count -ge 4) { ($continuityStateLines[3] -split ':',2)[-1].Trim() } else { '' }
    $expectedNext = if ($next.Count -gt 0) { "$($next[0].Id) — $($next[0].Name)" } else { 'none' }
    $expectedCompleted = if ($completedIds.Count -gt 0) { $completedIds -join ', ' } else { 'none' }
    $continuityPlanMatches = [string]::Equals($continuityPlanPath, $relativePlan, [StringComparison]::Ordinal)
    $continuityCompletedMatches = [string]::Equals($continuityCompleted, $expectedCompleted, [StringComparison]::Ordinal)
    $continuityNextMatches = [string]::Equals($continuityNext, $expectedNext, [StringComparison]::Ordinal)
    if (-not $continuityPlanMatches -or -not $continuityProgressMatch.Success -or [int]$continuityProgress[1].Value -ne [int]$progress.Groups[1].Value -or [int]$continuityProgress[2].Value -ne [int]$progress.Groups[2].Value -or -not $continuityCompletedMatches -or -not $continuityNextMatches) {
        $mismatch = [string]::Format('continuity_plan_reconciliation_mismatch:plan={0}/{1};progress={2}/{3};completed={4}/{5};next={6}/{7}', @($continuityPlanPath,$relativePlan,$continuityProgressMatch.Value,$progress.Value,$continuityCompleted,$expectedCompleted,$continuityNext,$expectedNext))
        Stop-Preflight $mismatch
    }
    $git = & git -C $repo status --short --untracked-files=no -- $relativeFeature 2>$null
    Write-Output "preflight: ALLOW - plan=$relativePlan; status=approved; steps=$($steps.Count); completed=$completed; $script:StorageSummary; git_feature_status=$([string]::Join('',@($git)))"
    exit 0
}
catch {
    Write-Output "preflight: BLOCK - validation_error:$($_.Exception.Message); $script:StorageSummary"
    exit 2
}
