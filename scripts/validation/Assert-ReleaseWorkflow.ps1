#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$workflowPath = Join-Path $repoRoot '.github/workflows/release.yml'
if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
    throw "Release workflow not found: $workflowPath"
}
$sourceWorkflowPath = Join-Path $repoRoot '.github/workflows/enforce-release-source.yml'
if (-not (Test-Path -LiteralPath $sourceWorkflowPath -PathType Leaf)) {
    throw "Release source workflow not found: $sourceWorkflowPath"
}

$workflow = Get-Content -LiteralPath $workflowPath -Raw
$sourceWorkflow = Get-Content -LiteralPath $sourceWorkflowPath -Raw
$checks = [ordered]@{
    'required-release-source-check-covers-sync-readiness-and-metadata' =
        $sourceWorkflow -match '(?s)release-source:.*?secrets\.RELEASE_SYNC_APP_ID.*?secrets\.RELEASE_SYNC_APP_PRIVATE_KEY.*?actions/create-github-app-token@[0-9a-f]{40}.*?permission-contents:\s*write.*?permission-pull-requests:\s*write.*?Validate release decision and version' -and
        $sourceWorkflow -notmatch '(?m)^\s{2}release-metadata:\s*$'
    'reconcile-only-dispatch-input' = $workflow -match '(?m)^\s{6}reconcile_only:\s*$' -and
        $workflow -match '(?m)^\s{8}type:\s*boolean\s*$' -and
        $workflow -match '(?m)^\s{8}required:\s*false\s*$'
    'release-sync-preflight-requires-credentials' = $workflow -match '(?s)release-sync-preflight:.*?secrets\.RELEASE_SYNC_APP_ID.*?secrets\.RELEASE_SYNC_APP_PRIVATE_KEY'
    'release-sync-preflight-mints-required-permission-token' = $workflow -match '(?s)release-sync-preflight:.*?actions/create-github-app-token@[0-9a-f]{40}.*?permission-contents:\s*write.*?permission-pull-requests:\s*write'
    'release-depends-on-preflight' = $workflow -match '(?s)release:\s*\r?\n\s+needs:\s+release-sync-preflight'
    'reconcile-only-skips-publication-step' = $workflow -match '(?s)Create release from the promoted commit\r?\n\s+id:\s+release\r?\n\s+if:\s+\$\{\{\s*inputs\.reconcile_only\s*!=\s*true\s*\}\}'
    'dispatch-can-run-reconciliation' = $workflow -match '(?s)reconcile-develop:.*?github\.event_name == ''workflow_dispatch'''
    'reconciliation-validates-promoted-base-ancestry' = $workflow -match 'git merge-base --is-ancestor "\$\{promoted\}" "\$\{base_tip\}"'
    'reconciliation-validates-tag-target' = $workflow -match '\[\[ "\$\{tag_commit\}" == "\$\{promoted\}" \]\]'
    'reconciliation-uses-stable-recovery-branch-key' = $workflow -match 'sync_key="manual-\$\{promoted:0:12\}"' -and
        $workflow -match 'sync_branch="automation/reconcile-release-pr-\$\{sync_key\}"'
    'reconciliation-uses-normal-auto-merge' = $workflow -match 'gh pr merge "\$\{existing_pr\}" --repo "\$\{REPOSITORY\}" --auto --merge'
}

$failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value })
foreach ($check in $checks.GetEnumerator()) {
    $status = if ($check.Value) { 'PASS' } else { 'FAIL' }
    Write-Host ("{0} {1}" -f $status, $check.Key)
}
if ($failed.Count -gt 0) {
    throw ("Release workflow contract failed: {0}" -f (($failed | ForEach-Object { $_.Key }) -join ', '))
}

Write-Host 'Release workflow contract passed.' -ForegroundColor Green
