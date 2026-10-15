#Requires -Version 5.1
# Static contract checks for CT1-CT12. Does not run a live host, write a home, or publish defaults.
# Tests:
#   Should_NotAskMemoryBankRefresh_When_CommitMessageUnconfirmed
#   Should_SeedOrchestratorModeAlways_When_FirstSync
#   Should_KeepOpenQuestion_When_NoOperatorAnswer
#   Should_BlockInText_When_HostHasNoInteractiveQuestion
#   Should_ShowNarrativeAndShortResult_When_StepCloses
#   Should_AnalyzeOnce_When_IntermediateStepStarts
#   Should_BlockStep_When_ReceiptStatusIsCompleted
#   Should_ResumeOrBlock_When_QuestionOrIntermediateSkillEnds
#   Should_StayOnCurrentBranch_When_SpecPlanAnalyzeDeliver
#   Should_ShowBranchGate_When_SddDevelopChangesCode
#   Should_ReadRedirectedStdin_When_PublishedPowerShellHook
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path (Join-Path $scriptsRoot '_lib') 'Get-ToolkitRepoRoot.ps1'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

function Assert-Includes {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Needle,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    if ($Text.IndexOf($Needle, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        Write-Fail -TestName $TestName -Reason ("{0} Missing: {1}" -f $Reason, $Needle)
    }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-SkillsAndFlowsContractsPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$commitSkillRelative = 'core/skills/commit/SKILL.md'
$preferencesRelative = 'scripts/_lib/Initialize-SddPreferences.ps1'
$guardrailsRelative = 'core/policy/guardrails.md'
$executionDisplayRelative = 'core/skills/sdd-develop/references/execution-display.md'
$orchestrateDevelopRelative = 'core/skills/orchestrate-develop/SKILL.md'
$orchestrateMustNotRelative = 'core/skills/orchestrate-develop/references/must-not.md'
$sddDevelopRelative = 'core/skills/sdd-develop/SKILL.md'
$sddSpecRelative = 'core/skills/sdd-spec/SKILL.md'
$sddPlanRelative = 'core/skills/sdd-plan/SKILL.md'
$orchestrateAnalyzeRelative = 'core/skills/orchestrate-analyze/SKILL.md'
$orchestrateDeliverRelative = 'core/skills/orchestrate-deliver/SKILL.md'
$checklistAcquisitionRelative = 'core/skills/sdd-plan/references/checklist-acquisition.md'
$splitChecklistRelative = 'core/skills/split-story-checklist/SKILL.md'
$changeContractRelative = 'core/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md'
$spawnContractRelative = 'core/skills/_shared/agents/SPAWN.md'
$perStoryContractsRelative = 'core/skills/orchestrate-deliver/references/per-story-contracts.md'
$receiptAllowPhrase = 'outside `done`, `blocked`, and `failed`'
$allowedReceiptStatuses = @('done', 'blocked', 'failed')
$completedReceiptStatus = 'COMPLETED'
$publishedHookReaders = @(
    'adapters/cursor/assets/hooks/_hook-common.ps1',
    'adapters/claude/assets/hooks/_hook-common.ps1',
    'adapters/codex/assets/hooks/_hook-common.ps1',
    'adapters/copilot/assets/hooks/_hook-common.ps1',
    'adapters/antigravity/assets/hooks/_hook-common.ps1',
    'adapters/grok/assets/hooks/guard-pre-tool.ps1',
    'adapters/zcode/hooks/guard-pre-tool.ps1',
    'adapters/hermes/assets/agent-hooks/guard-pre-tool.ps1',
    'adapters/openhands/assets/hooks/guard_pre_tool.ps1'
)
$primaryStdinToken = '[Console]::OpenStandardInput()'
$fallbackStdinToken = '[Console]::In'
$openCodeAdapterRelative = 'adapters/opencode'

function Get-RepoText {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    $fullPath = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Write-Fail -TestName 'Assert-SkillsAndFlowsContractsPreconditions' -Reason ("missing {0}" -f $RelativePath)
    }
    return [System.IO.File]::ReadAllText($fullPath)
}

$commitSkill = Get-RepoText -RelativePath $commitSkillRelative
$preferences = Get-RepoText -RelativePath $preferencesRelative
$constants = Get-RepoText -RelativePath 'scripts/_lib/ToolkitConstants.ps1'
$toolkit = Get-RepoText -RelativePath 'scripts/toolkit.ps1'
$syncAgent = Get-RepoText -RelativePath 'scripts/sync-agent.ps1'
$guardrails = Get-RepoText -RelativePath $guardrailsRelative
$executionDisplay = Get-RepoText -RelativePath $executionDisplayRelative
$orchestrateDevelop = Get-RepoText -RelativePath $orchestrateDevelopRelative
$orchestrateMustNot = Get-RepoText -RelativePath $orchestrateMustNotRelative
$sddDevelop = Get-RepoText -RelativePath $sddDevelopRelative
$sddSpec = Get-RepoText -RelativePath $sddSpecRelative
$sddPlan = Get-RepoText -RelativePath $sddPlanRelative
$orchestrateAnalyze = Get-RepoText -RelativePath $orchestrateAnalyzeRelative
$orchestrateDeliver = Get-RepoText -RelativePath $orchestrateDeliverRelative
$checklistAcquisition = Get-RepoText -RelativePath $checklistAcquisitionRelative
$splitChecklist = Get-RepoText -RelativePath $splitChecklistRelative
$changeContract = Get-RepoText -RelativePath $changeContractRelative
$spawnContract = Get-RepoText -RelativePath $spawnContractRelative
$perStoryContracts = Get-RepoText -RelativePath $perStoryContractsRelative

# --- Should_CoordinateAndValidateMissingChecklist_BeforeResumingPlan (CT13 / REQ-010 / CA10) ---
$ct13Name = 'Should_CoordinateAndValidateMissingChecklist_BeforeResumingPlan'
Assert-Includes -TestName $ct13Name -Text $sddPlan -Needle 'references/checklist-acquisition.md' -Reason 'sdd-plan routes missing-checklist behavior through its contract'
Assert-Includes -TestName $ct13Name -Text $sddPlan -Needle 'validate the completed artifact' -Reason 'sdd-plan validates owner output before resuming'
Assert-Includes -TestName $ct13Name -Text $sddPlan -Needle 'resume this same `sdd-plan` invocation' -Reason 'valid checklist output resumes the existing plan flow'
Assert-Includes -TestName $ct13Name -Text $sddPlan -Needle 'For missing-checklist behavior, follow `references/checklist-acquisition.md`' -Reason 'Must not delegates missing-checklist handling to the acquisition contract'
if ($sddPlan.Contains('stop and hand off `/split-story-checklist`')) {
    throw "[$ct13Name] Obsolete manual checklist handoff remains in sdd-plan Must not."
}
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'When the host exposes effective `subagents=native`' -Reason 'missing checklist uses a specialist when native capability exists'
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'execute the `split-story-checklist` workflow in the current flow' -Reason 'no-subagent/unavailable capability uses inline owner workflow'
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'sole author of `REFINE/tasks.md`' -Reason 'checklist authorship remains with its owner'
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'stop with `step_blocked`' -Reason 'failure or invalid output blocks plan resumption'
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'stop with `open_question`' -Reason 'unanswered checklist questions block resumption'
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'IDs are unique, positive, ordered as declared' -Reason 'returned IDs are validated before use'
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'do not add, remove, or renumber an ID' -Reason 'sdd-plan preserves checklist identifiers'
Assert-Includes -TestName $ct13Name -Text $checklistAcquisition -Needle 'Normal PRD review, open-question gates, confirm-before-write, structural validation' -Reason 'normal review and approval gates remain active after resumption'
Assert-Includes -TestName $ct13Name -Text $splitChecklist -Needle 'this skill remains the sole author' -Reason 'the owner skill remains sole checklist author'
Assert-Includes -TestName $ct13Name -Text $splitChecklist -Needle 'preserve all applicable session/write gates and open questions' -Reason 'owner gates and questions remain active'
Assert-Includes -TestName $ct13Name -Text $changeContract -Needle 'validates the canonical output, and resumes only on success' -Reason 'shared TASKS policy agrees on validated recovery'
Assert-Includes -TestName $ct13Name -Text $spawnContract -Needle 'sdd-plan` required-checklist acquisition' -Reason 'spawn contract documents native and fallback routes'
Assert-Includes -TestName $ct13Name -Text $spawnContract -Needle 'Execute the owner skill workflow in the current flow' -Reason 'spawn fallback does not hard-fail'
Assert-Includes -TestName $ct13Name -Text $perStoryContracts -Needle 'validates the canonical output, then resumes this same plan' -Reason 'O2 per-story contract permits validated same-plan recovery'
Assert-Includes -TestName $ct13Name -Text $perStoryContracts -Needle 'sole writer of `REFINE/tasks.md`' -Reason 'O2 preserves checklist ownership'
Write-Pass -TestName $ct13Name

# --- Should_NotAskMemoryBankRefresh_When_CommitMessageUnconfirmed (CT1) ---
$ct1Name = 'Should_NotAskMemoryBankRefresh_When_CommitMessageUnconfirmed'
Assert-Includes -TestName $ct1Name -Text $commitSkill -Needle 'Do not ask about memory bank' -Reason 'commit must not ask for a memory-bank refresh'
Assert-Includes -TestName $ct1Name -Text $commitSkill -Needle 'Do not start a memory-bank refresh' -Reason 'commit must not start a memory-bank refresh'
Assert-Includes -TestName $ct1Name -Text $commitSkill -Needle 'wait for user confirmation' -Reason 'commit waits for message confirmation'
Assert-Includes -TestName $ct1Name -Text $commitSkill -Needle 'Create the commit only after the operator confirms the message' -Reason 'commit is created only after message confirmation'
Write-Pass -TestName $ct1Name

# --- Should_AskPreferencesOnly_OnInteractiveFirstSync (CT2) ---
$ct2Name = 'Should_AskPreferencesOnly_OnInteractiveFirstSync'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle "DefaultOrchestratorMode  = 'always'" -Reason 'non-interactive first sync defaults to always'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle 'DefaultCavemanMode       = $true' -Reason 'first sync defaults Caveman on'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle 'if ($Interactive.IsPresent)' -Reason 'interactive preference prompt is scoped to toolkit interactive flow'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle 'if ($WhatIf.IsPresent)' -Reason 'WhatIf exits before interactive prompts'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle 'ToolkitCavemanInstallPromptOffLine' -Reason 'Caveman off option is shown'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle 'ToolkitOrchestratorInstallPromptAdaptiveLine' -Reason 'adaptive option is shown'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle 'Test-Path -LiteralPath $preferencesPath' -Reason 'existing preferences are preserved before prompting'
Assert-Includes -TestName $ct2Name -Text $preferences -Needle 'Read-Host $Prompt' -Reason 'interactive choices are read from the console'
Assert-Includes -TestName $ct2Name -Text $constants -Needle 'Off (disables response compression)' -Reason 'Caveman off explains the response-compression effect'
Assert-Includes -TestName $ct2Name -Text $toolkit -Needle '-Interactive:$PromptInstallPreferences.IsPresent' -Reason 'toolkit interactive sync passes the install-preferences signal after publication'
Assert-Includes -TestName $ct2Name -Text $toolkit -Needle '-PromptInstallPreferences' -Reason 'the interactive toolkit sync opts in to preference prompts'
Assert-Includes -TestName $ct2Name -Text $toolkit -Needle "`$syncTable['DeferPreferences'] = `$true" -Reason 'toolkit defers direct-sync defaults until the interactive post-publish flow'
Assert-Includes -TestName $ct2Name -Text $syncAgent -Needle '[switch] $DeferPreferences' -Reason 'direct sync remains non-interactive unless toolkit defers preference initialization'
Assert-Includes -TestName $ct2Name -Text $syncAgent -Needle 'Invoke-ToolkitEnsurePreferences -SddRoot $sddResult.SddRoot' -Reason 'direct non-interactive sync persists default preferences'
Write-Pass -TestName $ct2Name

# --- Should_KeepOpenQuestion_When_NoOperatorAnswer (CT3) ---
$ct3Name = 'Should_KeepOpenQuestion_When_NoOperatorAnswer'
Assert-Includes -TestName $ct3Name -Text $guardrails -Needle 'stays open until the operator answers every pending question' -Reason 'a question with no deadline stays open'
Assert-Includes -TestName $ct3Name -Text $guardrails -Needle 'send no further agent message until those answers arrive' -Reason 'no following agent message before the answer'
Assert-Includes -TestName $ct3Name -Text $guardrails -Needle 'Silence, a timeout, and the end of the turn are not answers.' -Reason 'silence, timeout, and end of turn are not answers'
Write-Pass -TestName $ct3Name

# --- Should_BlockInText_When_HostHasNoInteractiveQuestion (CT4) ---
$ct4Name = 'Should_BlockInText_When_HostHasNoInteractiveQuestion'
Assert-Includes -TestName $ct4Name -Text $guardrails -Needle 'A host that offers an interactive question uses that mechanism.' -Reason 'interactive host uses that mechanism'
Assert-Includes -TestName $ct4Name -Text $guardrails -Needle 'Every other host asks in text.' -Reason 'other hosts ask in text'
Assert-Includes -TestName $ct4Name -Text $guardrails -Needle 'Both block the flow.' -Reason 'both mechanisms block'
Write-Pass -TestName $ct4Name

# --- Should_ShowNarrativeAndShortResult_When_StepCloses (CT5) ---
$ct5Name = 'Should_ShowNarrativeAndShortResult_When_StepCloses'
Assert-Includes -TestName $ct5Name -Text $executionDisplay -Needle 'A narrative summary of the step.' -Reason 'operator chat requires the narrative summary'
Assert-Includes -TestName $ct5Name -Text $executionDisplay -Needle 'What the PLAN says to do for that step.' -Reason 'operator chat requires the PLAN instruction'
Assert-Includes -TestName $ct5Name -Text $executionDisplay -Needle 'The blocking question.' -Reason 'operator chat requires the blocking question'
Assert-Includes -TestName $ct5Name -Text $executionDisplay -Needle 'Name the step, the status (`done`, `blocked`, or `failed`), and the tests.' -Reason 'short result names step, status, and tests'
$leaveIndex = $executionDisplay.IndexOf('These leave the operator chat', [System.StringComparison]::Ordinal)
if ($leaveIndex -lt 0) {
    Write-Fail -TestName $ct5Name -Reason 'execution display must say what leaves the operator chat'
}
$leaveWindow = $executionDisplay.Substring($leaveIndex, [Math]::Min(500, $executionDisplay.Length - $leaveIndex))
Assert-Includes -TestName $ct5Name -Text $leaveWindow -Needle 'stage-weight table' -Reason 'the stage-weight table is not the operator close'
Assert-Includes -TestName $ct5Name -Text $leaveWindow -Needle 'Develop:' -Reason 'the Develop: heartbeat is not the operator close'
Assert-Includes -TestName $ct5Name -Text $executionDisplay -Needle 'The progress table inside the PLAN file stays.' -Reason 'the PLAN progress table remains'
Write-Pass -TestName $ct5Name

# --- Should_AnalyzeOnce_When_IntermediateStepStarts (CT6) ---
$ct6Name = 'Should_AnalyzeOnce_When_IntermediateStepStarts'
$analysisIndex = $orchestrateDevelop.IndexOf('once before the first PLAN step', [System.StringComparison]::Ordinal)
if ($analysisIndex -lt 0) {
    Write-Fail -TestName $ct6Name -Reason 'analysis must run once before the first step'
}
$analysisWindow = $orchestrateDevelop.Substring($analysisIndex, [Math]::Min(450, $orchestrateDevelop.Length - $analysisIndex))
Assert-Includes -TestName $ct6Name -Text $analysisWindow -Needle 'impact, architecture, and persistence' -Reason 'the pass covers impact, architecture, and persistence'
Assert-Includes -TestName $ct6Name -Text $analysisWindow -Needle 'before an intermediate step' -Reason 'the pass does not run before every intermediate step'
Assert-Includes -TestName $ct6Name -Text $analysisWindow -Needle 'when code review is requested against that PLAN' -Reason 'the pass runs again at code review against the PLAN'
Write-Pass -TestName $ct6Name

# --- Should_BlockStep_When_ReceiptStatusIsCompleted (CT7) ---
$ct7Name = 'Should_BlockStep_When_ReceiptStatusIsCompleted'
foreach ($receiptSurface in @($executionDisplay, $orchestrateDevelop)) {
    $receiptIndex = $receiptSurface.IndexOf($receiptAllowPhrase, [System.StringComparison]::Ordinal)
    if ($receiptIndex -lt 0) {
        Write-Fail -TestName $ct7Name -Reason 'receipt allow list must be done, blocked, and failed'
    }
    $receiptWindow = $receiptSurface.Substring($receiptIndex, [Math]::Min(700, $receiptSurface.Length - $receiptIndex))
    Assert-Includes -TestName $ct7Name -Text $receiptWindow -Needle 'do not delegate the next step' -Reason 'a status outside the allow list does not delegate the next step'
    Assert-Includes -TestName $ct7Name -Text $receiptWindow -Needle $completedReceiptStatus -Reason 'COMPLETED must be named as outside the receipt allow list'
    $allowListEnd = $receiptWindow.IndexOf('failed', [System.StringComparison]::Ordinal)
    if ($allowListEnd -lt 0) {
        Write-Fail -TestName $ct7Name -Reason 'receipt allow list must name failed'
    }
    $allowListText = $receiptWindow.Substring(0, $allowListEnd)
    if ($allowListText.IndexOf($completedReceiptStatus, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Fail -TestName $ct7Name -Reason 'COMPLETED must stay outside the receipt allow list'
    }
}
Write-Pass -TestName $ct7Name

# --- Should_ResumeOrBlock_When_QuestionOrIntermediateSkillEnds (CT8) ---
$ct8Name = 'Should_ResumeOrBlock_When_QuestionOrIntermediateSkillEnds'
Assert-Includes -TestName $ct8Name -Text $guardrails -Needle 'After the question, or after an intermediate skill the operator already authorized, the skill that was in progress resumes.' -Reason 'the original skill resumes'
Assert-Includes -TestName $ct8Name -Text $guardrails -Needle 'declares a blocker and states the cause.' -Reason 'the original skill declares a blocker with the cause'
Write-Pass -TestName $ct8Name

# --- Should_StayOnCurrentBranch_When_SpecPlanAnalyzeDeliver (CT10) ---
$ct10Name = 'Should_StayOnCurrentBranch_When_SpecPlanAnalyzeDeliver'
Assert-Includes -TestName $ct10Name -Text $guardrails -Needle 'sdd-spec' -Reason 'guardrails names sdd-spec'
Assert-Includes -TestName $ct10Name -Text $guardrails -Needle 'sdd-plan' -Reason 'guardrails names sdd-plan'
Assert-Includes -TestName $ct10Name -Text $guardrails -Needle 'orchestrate-analyze' -Reason 'guardrails names orchestrate-analyze'
Assert-Includes -TestName $ct10Name -Text $guardrails -Needle 'orchestrate-deliver' -Reason 'guardrails names orchestrate-deliver'
Assert-Includes -TestName $ct10Name -Text $guardrails -Needle 'stay on the current branch. They do not show the branch and do not ask for a branch switch.' -Reason 'guardrails keeps those skills on the current branch'
$branchSwitchNeedles = @(
    'Propose `feature/',
    'not a work branch',
    'git checkout -b'
)
foreach ($skillText in @($sddSpec, $sddPlan, $orchestrateAnalyze, $orchestrateDeliver)) {
    Assert-Includes -TestName $ct10Name -Text $skillText -Needle 'Stay on the current branch' -Reason 'skill stays on the current branch'
    Assert-Includes -TestName $ct10Name -Text $skillText -Needle 'do not ask for a branch switch' -Reason 'skill does not ask to create a branch'
}
foreach ($skillText in @($sddSpec, $sddPlan)) {
    foreach ($branchSwitchNeedle in $branchSwitchNeedles) {
        if ($skillText.IndexOf($branchSwitchNeedle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Write-Fail -TestName $ct10Name -Reason ("sdd-spec and sdd-plan must not ask for a branch switch. Found: {0}" -f $branchSwitchNeedle)
        }
    }
}
Write-Pass -TestName $ct10Name

# --- Should_ShowBranchGate_When_SddDevelopChangesCode (CT11) ---
$ct11Name = 'Should_ShowBranchGate_When_SddDevelopChangesCode'
$branchSectionIndex = $guardrails.IndexOf('### Working branch', [System.StringComparison]::Ordinal)
if ($branchSectionIndex -lt 0) {
    Write-Fail -TestName $ct11Name -Reason 'guardrails working-branch section is missing'
}
$branchSection = $guardrails.Substring($branchSectionIndex, [Math]::Min(900, $guardrails.Length - $branchSectionIndex))
Assert-Includes -TestName $ct11Name -Text $branchSection -Needle 'integration-branch stop' -Reason 'sdd-develop keeps the integration-branch gate'
Assert-Includes -TestName $ct11Name -Text $branchSection -Needle 'sdd-develop' -Reason 'the gate still applies to sdd-develop'
Assert-Includes -TestName $ct11Name -Text $branchSection -Needle 'Before those skills change code' -Reason 'the gate runs before code changes'
Assert-Includes -TestName $ct11Name -Text $branchSection -Needle 'show the branch name' -Reason 'sdd-develop still shows the branch'
$gitStepIndex = $sddDevelop.IndexOf('### 2. Git', [System.StringComparison]::Ordinal)
$implementStepIndex = $sddDevelop.IndexOf('### 3-4. Analyze and implement', [System.StringComparison]::Ordinal)
if ($gitStepIndex -lt 0 -or $implementStepIndex -lt 0 -or $gitStepIndex -ge $implementStepIndex) {
    Write-Fail -TestName $ct11Name -Reason 'sdd-develop applies the branch step before changing code'
}
Assert-Includes -TestName $ct11Name -Text $sddDevelop -Needle 'Feature branch' -Reason 'sdd-develop still requires the feature-branch check'
Write-Pass -TestName $ct11Name

# --- Should_ReadRedirectedStdin_When_PublishedPowerShellHook (CT12) ---
$ct12Name = 'Should_ReadRedirectedStdin_When_PublishedPowerShellHook'
foreach ($hookRelative in $publishedHookReaders) {
    $hookText = Get-RepoText -RelativePath $hookRelative
    $primaryIndex = $hookText.IndexOf($primaryStdinToken, [System.StringComparison]::Ordinal)
    $fallbackIndex = $hookText.IndexOf($fallbackStdinToken, [System.StringComparison]::Ordinal)
    if ($primaryIndex -lt 0 -or $fallbackIndex -lt 0 -or $fallbackIndex -le $primaryIndex) {
        Write-Fail -TestName $ct12Name -Reason ("{0} must read OpenStandardInput first and [Console]::In only as fallback" -f $hookRelative)
    }
    $readerGap = $hookText.Substring($primaryIndex, $fallbackIndex - $primaryIndex)
    if ($readerGap.IndexOf('catch', [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        Write-Fail -TestName $ct12Name -Reason ("{0} must use [Console]::In only in the fallback catch" -f $hookRelative)
    }
    if ($readerGap.IndexOf('IsNullOrWhiteSpace', [System.StringComparison]::Ordinal) -lt 0) {
        Write-Fail -TestName $ct12Name -Reason ("{0} must try [Console]::In when the primary read is empty" -f $hookRelative)
    }
    if ($hookText.IndexOf('ConvertFrom-Json', [System.StringComparison]::Ordinal) -lt 0) {
        Write-Fail -TestName $ct12Name -Reason ("{0} must parse the redirected JSON object" -f $hookRelative)
    }
}
$openCodeRoot = Join-Path $repoRoot ($openCodeAdapterRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $openCodeRoot)) {
    Write-Fail -TestName $ct12Name -Reason 'OpenCode adapter folder is missing'
}
$openCodePipe = @(Get-ChildItem -LiteralPath $openCodeRoot -Recurse -File -Filter '*.ps1' | Where-Object {
    $openCodeText = [System.IO.File]::ReadAllText($_.FullName)
    ($openCodeText.IndexOf($primaryStdinToken, [System.StringComparison]::Ordinal) -ge 0) -or ($openCodeText.IndexOf($fallbackStdinToken, [System.StringComparison]::Ordinal) -ge 0)
})
if ($openCodePipe.Count -gt 0) {
    Write-Fail -TestName $ct12Name -Reason 'OpenCode has no PowerShell hook pipe'
}
Write-Pass -TestName $ct12Name

Write-Host 'Assert-SkillsAndFlowsContracts: static files only; no live host'
Write-Host 'Assert-SkillsAndFlowsContracts: ALL PASS'
exit 0
