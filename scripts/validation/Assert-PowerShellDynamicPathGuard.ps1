#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Get-Item (Join-Path $scriptDir '..\..')).FullName
$guardCommon = Join-Path $repoRoot 'adapters\_shared\GuardCommon.ps1'
if (-not (Test-Path -LiteralPath $guardCommon -PathType Leaf)) {
    throw "missing GuardCommon.ps1: $guardCommon"
}
. $guardCommon

function Assert-PathDecision {
    param(
        [string] $Name,
        [string] $Path,
        [string] $ExpectedDecision,
        [string] $ExpectedReason = ''
    )

    $verdict = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{
        path = $Path
        content = 'class Ct12Fixture {}'
    }) -WorkspaceRoot $repoRoot
    if ([string]$verdict.Decision -ne $ExpectedDecision) {
        throw "$Name expected $ExpectedDecision, got $($verdict.Decision): $($verdict.Reason)"
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedReason) -and [string]$verdict.Reason -ne $ExpectedReason) {
        throw "$Name expected reason $ExpectedReason, got $($verdict.Reason)"
    }
    Write-Host "${Name}: PASS"
}

$insideRoot = Join-Path $repoRoot 'features\014-improve-and-fix-disagreements\US01\EVD'
$outsideRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'agent-dev-toolkit-ct12-outside'
$variableName = 'ADT_CT12_GUARD_ROOT'
$savedValue = [Environment]::GetEnvironmentVariable($variableName, 'Process')
try {
    [Environment]::SetEnvironmentVariable($variableName, $insideRoot, 'Process')
    Assert-PathDecision -Name 'Should_Allow_When_EnvPathExpandsInsideWorkspace' -Path '$env:ADT_CT12_GUARD_ROOT\inside.md' -ExpectedDecision 'allow'
    Assert-PathDecision -Name 'Should_Allow_When_PercentPathExpandsInsideWorkspace' -Path '%ADT_CT12_GUARD_ROOT%\percent.md' -ExpectedDecision 'allow'

    [Environment]::SetEnvironmentVariable($variableName, $outsideRoot, 'Process')
    Assert-PathDecision -Name 'Should_Deny_When_EnvPathExpandsOutsideWorkspace' -Path '$env:ADT_CT12_GUARD_ROOT\outside.md' -ExpectedDecision 'deny' -ExpectedReason 'outside_workspace'

    Assert-PathDecision -Name 'Should_Deny_When_PathExpressionIsUnsupported' -Path '$($env:ADT_CT12_GUARD_ROOT)\expression.md' -ExpectedDecision 'deny' -ExpectedReason 'unsupported_path_expression'
    [Environment]::SetEnvironmentVariable('ADT_CT12_CT12_UNSET', $null, 'Process')
    Assert-PathDecision -Name 'Should_Deny_When_EnvPathIsUnset' -Path '$env:ADT_CT12_CT12_UNSET\missing.md' -ExpectedDecision 'deny' -ExpectedReason 'environment_variable_unset:ADT_CT12_CT12_UNSET'
}
finally {
    [Environment]::SetEnvironmentVariable($variableName, $savedValue, 'Process')
}

Write-Host 'Assert-PowerShellDynamicPathGuard: ALL PASS'
