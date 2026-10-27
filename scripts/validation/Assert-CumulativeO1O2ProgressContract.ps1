Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sharedPath = Join-Path $repoRoot 'core/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md'
$o1Path = Join-Path $repoRoot 'core/skills/orchestrate-analyze/references/command.md'
$o2Path = Join-Path $repoRoot 'core/skills/orchestrate-deliver/references/command.md'

foreach ($path in @($sharedPath, $o1Path, $o2Path)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required checkpoint contract file not found: $path"
    }
}

$shared = Get-Content -LiteralPath $sharedPath -Raw
$o1 = Get-Content -LiteralPath $o1Path -Raw
$o2 = Get-Content -LiteralPath $o2Path -Raw

function Assert-Contains {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $Needle
    )

    if (-not $Text.Contains($Needle)) {
        throw "FAIL $Name — missing contract text: $Needle"
    }

    Write-Output "PASS $Name"
}

Assert-Contains -Name 'SharedCheckpointSchema' -Text $shared -Needle '| Decisões / questões |'
Assert-Contains -Name 'SharedCheckpointBlockersAndNextAction' -Text $shared -Needle '| Próxima ação |'
Assert-Contains -Name 'CheckpointIsCumulative' -Text $shared -Needle 'Keep entries cumulative across the current O1/O2 run'
Assert-Contains -Name 'CheckpointDoesNotCreatePersistedLedger' -Text $shared -Needle 'do not copy this table into CONTINUITY, FEATURE, PRD, PLAN, or the O3 step ledger'
Assert-Contains -Name 'ExamplePreservesOpenWorkAcrossTransitions' -Text $shared -Needle 'Q-02 segue aberta'
Assert-Contains -Name 'O1RefreshCadence' -Text $o1 -Needle 'after each material evidence pass or decision'
Assert-Contains -Name 'O1CheckpointAlongsideStageTable' -Text $o1 -Needle 'render both the feature-research stage table and the cumulative checkpoint'
Assert-Contains -Name 'O2RefreshCadence' -Text $o2 -Needle 'after material analysis or artifact/validation milestones'
Assert-Contains -Name 'O2ReconcilesBeforeAdvancing' -Text $o2 -Needle 'Reconcile status with canonical story artifacts and CONTINUITY before advancing or resuming'
Assert-Contains -Name 'O2PreservesO3LedgerBoundary' -Text $o2 -Needle 'O3 retains its separate PLAN-step ledger'

Write-Output 'PASS Cumulative O1/O2 progress checkpoint contract (10 checks)'
