#Requires -Version 5.1
# Tests:
#   Should_Allow_When_ShellHasNoPath
#   Should_Allow_When_ShellInvokesRepoValidationScript
#   Should_Allow_When_ShellUsesCanonicalFeaturePlan
#   Should_Allow_When_ShellUsesCanonicalFeaturePrd
#   Should_Deny_When_ShellContainsSecret
#   Should_Deny_When_ShellTargetsRootPlanTree
#   Should_Deny_When_ShellTargetsRootPrdTree
#   Should_Deny_When_ShellPathEscapesWorkspace
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'

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

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-GuardShellCanonicalPathsPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$hookCommon = Join-Path $repoRoot 'adapters/cursor/assets/hooks/_hook-common.ps1'
if (-not (Test-Path -LiteralPath $hookCommon)) {
    Write-Fail -TestName 'Assert-GuardShellCanonicalPathsPreconditions' -Reason ("missing {0}" -f $hookCommon)
}

. $hookCommon
if (-not (Get-Command -Name Get-ToolkitPathSecretsGuardVerdict -ErrorAction SilentlyContinue)) {
    Write-Fail -TestName 'Assert-GuardShellCanonicalPathsPreconditions' -Reason 'GuardCommon verdict was not loaded'
}

function Assert-GuardShellDecision {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Command,
        [Parameter(Mandatory = $true)][string] $ExpectedDecision
    )

    $verdict = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Shell' -WorkspaceRoot $repoRoot -DirectShellCommand $Command
    if ($verdict.Decision -ne $ExpectedDecision) {
        Write-Fail -TestName $TestName -Reason ("expected {0}, got {1}: {2}" -f $ExpectedDecision, $verdict.Decision, $verdict.UserMessage)
    }
    Write-Pass -TestName $TestName
}

Assert-GuardShellDecision -TestName 'Should_Allow_When_ShellHasNoPath' -ExpectedDecision 'allow' -Command 'Get-Date'
Assert-GuardShellDecision -TestName 'Should_Allow_When_ShellInvokesRepoValidationScript' -ExpectedDecision 'allow' -Command 'pwsh -NoProfile -File "scripts/validation/validate-evidence.ps1" -StoryRoot "features/012-multiprovider-toolkit-corrections/US02" -Level cheap'
Assert-GuardShellDecision -TestName 'Should_Allow_When_ShellUsesCanonicalFeaturePlan' -ExpectedDecision 'allow' -Command 'pwsh -NoProfile -File "C:/Users/example/.cursor/scripts/session/Invoke-DevelopSessionGate.ps1" -PlanPath "features/012-multiprovider-toolkit-corrections/US02/PLAN/PLAN_012_hooks_multiprovider.md" -RepoPath "." -SddRoot "C:/Users/example/.cursor/sdd" -Step 1'
Assert-GuardShellDecision -TestName 'Should_Allow_When_ShellUsesCanonicalFeaturePrd' -ExpectedDecision 'allow' -Command 'Get-Content -LiteralPath "features/012-multiprovider-toolkit-corrections/US08/PRD/012_reducao_de_testes.md"'
Assert-GuardShellDecision -TestName 'Should_Deny_When_ShellContainsSecret' -ExpectedDecision 'deny' -Command 'Write-Output password=fixturetoken'
Assert-GuardShellDecision -TestName 'Should_Deny_When_ShellTargetsRootPlanTree' -ExpectedDecision 'deny' -Command 'Remove-Item -Recurse -Path PLAN/legacy'
Assert-GuardShellDecision -TestName 'Should_Deny_When_ShellTargetsRootPrdTree' -ExpectedDecision 'deny' -Command 'Remove-Item -Recurse -Path PRD/legacy'
Assert-GuardShellDecision -TestName 'Should_Deny_When_ShellPathEscapesWorkspace' -ExpectedDecision 'deny' -Command 'Set-Content -LiteralPath "../outside-workspace.txt" -Value outside'
