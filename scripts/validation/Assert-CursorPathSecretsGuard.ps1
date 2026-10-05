#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Pass_When_AllowedPathsAccepted
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_HooksJsonWiresPreToolUse
#
# Frente C1: Cursor preToolUse path + secrets guards.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$guardHarnessScript = Join-Path $libDir 'Invoke-PathSecretsGuardHarness.ps1'

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

foreach ($required in @($repoRootScript, $constantsScript, $guardHarnessScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CursorPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
. $guardHarnessScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksRootRel = $script:ToolkitConstant.CursorHooksAssetsRelativePath
$hooksRoot = Join-Path $repoRoot ($hooksRootRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$commonScript = Join-Path $hooksRoot '_hook-common.ps1'
$guardScript = Join-Path $hooksRoot 'guard-pre-tool.ps1'
$hooksJsonPath = Join-Path $hooksRoot 'hooks.json'

if (-not (Test-Path -LiteralPath $guardScript)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason ("missing guard hook {0}" -f $guardScript)
}
if (-not (Test-Path -LiteralPath $commonScript)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason ("missing hook common {0}" -f $commonScript)
}

. $commonScript

$requiredCommonCommands = @(
    'Test-ToolkitAllowedWritePath',
    'Get-ToolkitSecretFindings',
    'Test-ToolkitWriteToolName'
)
foreach ($cmdName in $requiredCommonCommands) {
    if (-not (Get-Command -Name $cmdName -ErrorAction SilentlyContinue)) {
        Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason ("_hook-common.ps1 missing function {0}" -f $cmdName)
    }
}

Write-Pass -TestName 'Should_Pass_When_GuardHookPresent'

$allowedCases = @(
    'features/004-example/US01/PRD/004_example.md',
    'memory-bank/architecture.md',
    'src/Services/Foo.cs',
    'docs/guides/README.md'
)
foreach ($case in $allowedCases) {
    if (-not (Test-ToolkitAllowedWritePath -RelativePath $case)) {
        Write-Fail -TestName 'Should_Pass_When_AllowedPathsAccepted' -Reason ("expected allowed path: {0}" -f $case)
    }
}
Write-Pass -TestName 'Should_Pass_When_AllowedPathsAccepted'

$forbiddenCases = @(
    'PRD/legacy.md',
    'docs/PRD/legacy.md',
    'node_modules/pkg/index.js'
)
foreach ($case in $forbiddenCases) {
    if (Test-ToolkitAllowedWritePath -RelativePath $case) {
        Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("expected denied path: {0}" -f $case)
    }
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath'

$secretSample = @"
connection = "Server=db;Password=SuperSecret123!;"
"@
$secretFindings = @(Get-ToolkitSecretFindings -Content $secretSample)
if ($secretFindings.Count -lt 1) {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason 'expected secret finding for password connection string'
}
Write-Pass -TestName 'Should_Deny_When_SecretPatternDetected'

$fixtureRoot = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot 'scripts') 'validation') 'fixtures') 'cursor-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force
$denyPayload = @{ hook_event_name = 'preToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path (Join-Path $fixtureRoot 'PRD') 'blocked.md'); content = '# blocked' }; cwd = $fixtureRoot }
$secretPayload = @{ hook_event_name = 'preToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path (Join-Path $fixtureRoot 'src') 'ok.cs'); content = 'const string key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";' }; cwd = $fixtureRoot }

$reparseTarget = Join-Path ([System.IO.Path]::GetTempPath()) 'agent-dev-toolkit-cursor-reparse-target'
$reparseLink = Join-Path (Join-Path $fixtureRoot 'src') 'linked'
$null = New-Item -ItemType Directory -Path $reparseTarget -Force
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $reparseLink) -Force
$reparseItemType = if ($env:OS -eq 'Windows_NT') { 'Junction' } else { 'SymbolicLink' }
$null = New-Item -ItemType $reparseItemType -Path $reparseLink -Target $reparseTarget
$reparsePayload = @{ hook_event_name = 'preToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path $reparseLink 'escape.cs'); content = 'class X {}' }; cwd = $fixtureRoot }

$cases = @(
    [PSCustomObject]@{ TestName = 'Should_Deny_When_GuardHookForbiddenSddPath'; Payload = $denyPayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'guard hook should deny forbidden SDD path' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_GuardHookSecretPatternDetected'; Payload = $secretPayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'guard hook should deny secret content' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_HookIdentityMissing'; Payload = @{ tool_name = 'Write'; tool_input = @{ path = (Join-Path (Join-Path $fixtureRoot 'src') 'missing-identity.cs'); content = 'class X {}' }; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'write without preToolUse identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ShellHookIdentityMissing'; Payload = @{ command = 'Set-Content -Path src\missing-shell-identity.cs -Value x'; cwd = $fixtureRoot }; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'beforeShellExecution without event identity must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_DescendantReparseEscapesWorkspace'; Payload = $reparsePayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'write through an escaping junction must deny' }
)
try {
    Invoke-PathSecretsGuardHarness -AdapterName 'Cursor' -HookScriptPath $guardScript -Cases $cases -GetDecision {
        param($Payload)
        if ($null -eq $Payload) { return $null }
        return [string]$Payload.permission
    }
}
finally {
    Remove-Item -LiteralPath $reparseLink -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $reparseTarget -Force -Recurse -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}

if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason ("missing hooks.json at {0}" -f $hooksJsonPath)
}
$hooksJsonText = Get-Content -LiteralPath $hooksJsonPath -Raw -Encoding UTF8
if ($hooksJsonText -notmatch '(?i)preToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json missing preToolUse event'
}
if ($hooksJsonText -notmatch '(?i)guard-pre-tool\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json must wire guard-pre-tool.ps1'
}
if ($hooksJsonText -notmatch '(?i)failClosed') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'preToolUse guard should set failClosed for security'
}
if ($hooksJsonText -notmatch '(?i)beforeShellExecution') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json missing beforeShellExecution for shell path/secrets guard'
}
if ($hooksJsonText -notmatch '(?i)Delete') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json preToolUse matcher must include Delete'
}
if ($hooksJsonText -notmatch '(?i)Shell') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json preToolUse matcher must include Shell'
}
if ($hooksJsonText -notmatch '(?i)Edit') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json preToolUse matcher must include Edit'
}
if ($hooksJsonText -notmatch '(?i)MultiEdit') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json preToolUse matcher must include MultiEdit'
}
if ($hooksJsonText -notmatch '(?i)search_replace') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json preToolUse matcher must include search_replace'
}
Write-Pass -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse'

$tempRoot = [System.IO.Path]::GetTempPath().TrimEnd('\', '/')
$prdBlockedOutside = Join-Path (Join-Path $tempRoot 'PRD') 'blocked.md'
$prdViaNamedOutside = Join-Path (Join-Path $tempRoot 'PRD') 'via-named-path.md'

$deletePayload = @{
    hook_event_name = 'preToolUse'
    tool_name  = 'Delete'
    tool_input = @{
        path = $prdBlockedOutside
    }
    cwd = $tempRoot
}
$shellPayload = @{
    hook_event_name = 'preToolUse'
    tool_name  = 'Shell'
    tool_input = @{
        command = 'echo secret > PRD/legacy.md'
    }
    cwd = $tempRoot
}

$beforeShellPayload = @{
    hook_event_name = 'beforeShellExecution'
    command = 'Remove-Item -Recurse node_modules/pkg'
    cwd     = $tempRoot
}

$absOutside = Join-Path $tempRoot 'agent-dev-toolkit-guard-abs-outside.cs'
$absPayload = @{
    hook_event_name = 'preToolUse'
    tool_name  = 'Write'
    tool_input = @{
        path    = $absOutside
        content = 'namespace X;'
    }
    cwd = $repoRoot
}

$missingPathPayload = @{
    hook_event_name = 'preToolUse'
    tool_name  = 'Write'
    tool_input = @{
        content = 'namespace X;'
    }
    cwd = $repoRoot
}

$namedPathShell = @{
    hook_event_name = 'preToolUse'
    tool_name  = 'Shell'
    tool_input = @{
        command = ("Set-Content -Path '{0}' -Value 'x'" -f $prdViaNamedOutside)
    }
    cwd = $repoRoot
}

$cases = @(
    [PSCustomObject]@{ TestName = 'Should_Deny_When_DeleteForbiddenPath'; Payload = $deletePayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'guard hook should deny Delete on forbidden SDD path' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ShellForbiddenPath'; Payload = $shellPayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'guard hook should deny Shell writing forbidden path' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_BeforeShellForbiddenPath'; Payload = $beforeShellPayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'beforeShellExecution shape should deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_AbsolutePathOutsideWorkspace'; Payload = $absPayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'absolute .cs outside workspace must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_WriteMissingPath'; Payload = $missingPathPayload; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'write without path must deny' }
    [PSCustomObject]@{ TestName = 'Should_Deny_When_ShellNamedPathOutside'; Payload = $namedPathShell; ExpectedDecision = 'deny'; Acceptance = 'Decision'; FailureReason = 'Set-Content -Path outside workspace must deny' }
)
Invoke-PathSecretsGuardHarness -AdapterName 'Cursor' -HookScriptPath $guardScript -Cases $cases -GetDecision {
    param($Payload)
    if ($null -eq $Payload) { return $null }
    return [string]$Payload.permission
}

if (Test-ToolkitAllowedWritePath -RelativePath $absOutside) {
    Write-Fail -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace' -Reason 'Test-ToolkitAllowedWritePath must reject absolute paths'
}

Write-Host 'Assert-CursorPathSecretsGuard: ALL PASS'
exit 0
