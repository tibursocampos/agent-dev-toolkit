#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardCommonShimPresent
#   Should_Detect_When_ShimDeniesValidInput
#   Should_Detect_When_MalformedInputIsAllowed
#   Should_Not_Flag_When_ShimReturnsHostAuthorization
#   Should_Verify_HostAuthorization_When_EnvPathExpandsInsideWorkspace
#   Should_Verify_HostAuthorization_When_EnvPathExpandsOutsideWorkspace
#   Should_Verify_HostAuthorization_When_PercentPathIsDynamic
#   Should_Verify_HostAuthorization_When_EnvVariableIsUnset
#   Should_Verify_HostAuthorization_When_PathExpressionIsUnsupported
#
# Host-owned contract (Codex and Copilot publish no PreToolUse guard; the Codex hook cases were removed):
#   - adapters/_shared/GuardCommon.ps1 is a compatibility shim. Get-ToolkitPathSecretsGuardVerdict
#     returns allow / host_authorization for every input, including dynamic paths. The provider host
#     owns path authorization; the shim carries no deny logic and is not a sandbox.
#   - A detector self-test proves the contract check flags a shim that denies valid input and a hook
#     that allows malformed input, and does not flag the host-owned shim result.
#   - This script verifies the host-owned contract only. It is a contract check (host-owned shim),
#     not an enforcement gate: it does not prove that any host blocks dynamic paths.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Get-Item (Join-Path $scriptDir '..\..')).FullName
$guardCommon = Join-Path $repoRoot 'adapters\_shared\GuardCommon.ps1'
foreach ($required in @($guardCommon)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "missing required file: $required"
    }
}

. $guardCommon

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

function Get-HostOwnedContractViolations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Observations
    )

    $violations = New-Object System.Collections.Generic.List[string]
    foreach ($observation in $Observations) {
        $decision = [string]$observation.Decision
        $reason = [string]$observation.Reason
        switch ([string]$observation.Kind) {
            'ShimValidInput' {
                if ($decision -ne 'allow' -or $reason -ne 'host_authorization') {
                    $violations.Add(("{0}: shim must return allow/host_authorization for input the host owns; got {1}/{2}" -f $observation.Name, $decision, $reason))
                }
            }
            'HookValidInput' {
                if ($decision -ne 'allow') {
                    $violations.Add(("{0}: hook must allow input the host owns; got '{1}'" -f $observation.Name, $decision))
                }
            }
            'HookMalformedInput' {
                if ($decision -ne 'deny') {
                    $violations.Add(("{0}: hook must deny malformed or identity-less input fail-closed; got '{1}'" -f $observation.Name, $decision))
                }
            }
            default {
                $violations.Add(("{0}: unknown observation kind '{1}'" -f $observation.Name, $observation.Kind))
            }
        }
    }
    return $violations.ToArray()
}

function Invoke-HookRawInput {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][Parameter(Mandatory = $true)][string] $RawInput,
        [Parameter(Mandatory = $true)][string] $HookPath
    )

    $hostCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($null -eq $hostCommand) {
        $hostCommand = Get-Command powershell -ErrorAction SilentlyContinue
    }
    if ($null -eq $hostCommand) {
        throw 'PowerShell host is unavailable for the hook harness.'
    }
    return ($RawInput | & $hostCommand.Source -NoProfile -File $HookPath 2>&1 | Out-String)
}

function Get-HookPermissionDecision {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $HookOutput)

    $parsed = $null
    try {
        $parsed = $HookOutput.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $parsed = $null
    }
    if ($null -ne $parsed -and $null -ne $parsed.hookSpecificOutput) {
        return [string]$parsed.hookSpecificOutput.permissionDecision
    }
    return ''
}

# Detector self-test: the contract check must flag contract breaks and must not flag the host-owned result.
$selfTests = @(
    @{ TestName = 'Should_Detect_When_ShimDeniesValidInput'; Observation = [pscustomobject]@{ Name = 'synthetic-shim-deny'; Kind = 'ShimValidInput'; Decision = 'deny'; Reason = 'outside_workspace' }; ExpectViolation = $true },
    @{ TestName = 'Should_Detect_When_MalformedInputIsAllowed'; Observation = [pscustomobject]@{ Name = 'synthetic-hook-allow'; Kind = 'HookMalformedInput'; Decision = 'allow'; Reason = '' }; ExpectViolation = $true },
    @{ TestName = 'Should_Not_Flag_When_ShimReturnsHostAuthorization'; Observation = [pscustomobject]@{ Name = 'synthetic-shim-allow'; Kind = 'ShimValidInput'; Decision = 'allow'; Reason = 'host_authorization' }; ExpectViolation = $false }
)
foreach ($selfTest in $selfTests) {
    $found = @(Get-HostOwnedContractViolations -Observations @($selfTest.Observation))
    $flagged = $found.Count -gt 0
    if ($flagged -ne [bool]$selfTest.ExpectViolation) {
        Write-Fail -TestName $selfTest.TestName -Reason ("detector self-test expected violation={0}, got violation={1}" -f $selfTest.ExpectViolation, $flagged)
    }
    Write-Pass -TestName $selfTest.TestName
}

if (-not (Get-Command -Name Get-ToolkitPathSecretsGuardVerdict -ErrorAction SilentlyContinue)) {
    Write-Fail -TestName 'Should_Pass_When_GuardCommonShimPresent' -Reason 'Get-ToolkitPathSecretsGuardVerdict not loaded from GuardCommon.ps1'
}
Write-Pass -TestName 'Should_Pass_When_GuardCommonShimPresent'

$shimObservations = New-Object System.Collections.Generic.List[object]
$hookObservations = New-Object System.Collections.Generic.List[object]

$shimCases = @(
    @{ TestName = 'Should_Verify_HostAuthorization_When_EnvPathExpandsInsideWorkspace'; Path = '$env:ADT_DYN_GUARD_ROOT\inside.md'; EnvRoot = (Join-Path $repoRoot 'scripts\validation') },
    @{ TestName = 'Should_Verify_HostAuthorization_When_EnvPathExpandsOutsideWorkspace'; Path = '$env:ADT_DYN_GUARD_ROOT\outside.md'; EnvRoot = (Join-Path ([System.IO.Path]::GetTempPath()) 'agent-dev-toolkit-dyn-guard-outside') },
    @{ TestName = 'Should_Verify_HostAuthorization_When_PercentPathIsDynamic'; Path = '%ADT_DYN_GUARD_ROOT%\percent.md'; EnvRoot = (Join-Path ([System.IO.Path]::GetTempPath()) 'agent-dev-toolkit-dyn-guard-outside') },
    @{ TestName = 'Should_Verify_HostAuthorization_When_EnvVariableIsUnset'; Path = '$env:ADT_DYN_GUARD_UNSET_FIXTURE\missing.md'; EnvRoot = $null },
    @{ TestName = 'Should_Verify_HostAuthorization_When_PathExpressionIsUnsupported'; Path = '$($env:ADT_DYN_GUARD_ROOT)\expression.md'; EnvRoot = (Join-Path $repoRoot 'scripts\validation') }
)

$savedRoot = [Environment]::GetEnvironmentVariable('ADT_DYN_GUARD_ROOT', 'Process')
$savedUnset = [Environment]::GetEnvironmentVariable('ADT_DYN_GUARD_UNSET_FIXTURE', 'Process')
try {
    [Environment]::SetEnvironmentVariable('ADT_DYN_GUARD_UNSET_FIXTURE', $null, 'Process')
    foreach ($case in $shimCases) {
        [Environment]::SetEnvironmentVariable('ADT_DYN_GUARD_ROOT', $case.EnvRoot, 'Process')
        $verdict = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{
            path = $case.Path
            content = 'dynamic path fixture'
        }) -WorkspaceRoot $repoRoot
        $shimObservations.Add([pscustomobject]@{
            Name = $case.TestName
            Kind = 'ShimValidInput'
            Decision = [string]$verdict.Decision
            Reason = [string]$verdict.Reason
        })
    }
}
finally {
    [Environment]::SetEnvironmentVariable('ADT_DYN_GUARD_ROOT', $savedRoot, 'Process')
    [Environment]::SetEnvironmentVariable('ADT_DYN_GUARD_UNSET_FIXTURE', $savedUnset, 'Process')
}

$allObservations = @($shimObservations.ToArray()) + @($hookObservations.ToArray())
foreach ($observation in $allObservations) {
    $violations = @(Get-HostOwnedContractViolations -Observations @($observation))
    if ($violations.Count -gt 0) {
        Write-Fail -TestName $observation.Name -Reason $violations[0]
    }
    Write-Pass -TestName $observation.Name
}

Write-Host 'Assert-PowerShellDynamicPathGuard: contract check (host-owned shim); not an enforcement gate'
Write-Host 'Assert-PowerShellDynamicPathGuard: ALL PASS'
exit 0
