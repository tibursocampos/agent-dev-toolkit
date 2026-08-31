#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Pass_When_AllowedPathsAccepted
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_SettingsWirePreToolUse
#
# Frente 2.1: Claude PreToolUse path + secrets guards.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

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

function Invoke-GuardHook {
    param(
        [Parameter(Mandatory = $true)][string] $HookScriptPath,
        [Parameter(Mandatory = $true)][hashtable] $Payload
    )

    $json = $Payload | ConvertTo-Json -Compress -Depth 6
    $output = $json | pwsh -NoProfile -File $HookScriptPath 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 0
    }

    $parsed = $null
    try {
        $parsed = $output.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $parsed = $null
    }

    return [PSCustomObject]@{
        ExitCode = [int]$code
        Output   = $output
        Payload  = $parsed
    }
}

function Get-ClaudeGuardDecision {
    param($Payload)
    if ($null -eq $Payload) {
        return $null
    }
    if ($Payload.PSObject.Properties['hookSpecificOutput'] -and $Payload.hookSpecificOutput) {
        return [string]$Payload.hookSpecificOutput.permissionDecision
    }
    return $null
}

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-ClaudePathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksRoot = Join-Path $repoRoot 'adapters\claude\assets\hooks'
$commonScript = Join-Path $hooksRoot '_hook-common.ps1'
$guardScript = Join-Path $hooksRoot 'guard-pre-tool.ps1'
$claudeConstants = Join-Path $repoRoot 'adapters\claude\ClaudePathConstants.ps1'
$claudeAdapter = Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1'

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
    'Get-ToolkitPathSecretsGuardVerdict',
    'Write-ClaudePreToolJson'
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

$fixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\claude-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$denyPayload = @{
    tool_name  = 'Write'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'PRD\blocked.md')
        content = '# blocked'
    }
    cwd = $fixtureRoot
}
$denyResult = Invoke-GuardHook -HookScriptPath $guardScript -Payload $denyPayload
$denyDecision = Get-ClaudeGuardDecision -Payload $denyResult.Payload
if ($denyDecision -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("guard hook should deny forbidden SDD path; output={0}" -f $denyResult.Output.Trim())
}

$secretPayload = @{
    tool_name  = 'Write'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'src\ok.cs')
        content = 'const string key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";'
    }
    cwd = $fixtureRoot
}
$secretResult = Invoke-GuardHook -HookScriptPath $guardScript -Payload $secretPayload
$secretDecision = Get-ClaudeGuardDecision -Payload $secretResult.Payload
if ($secretDecision -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("guard hook should deny secret content; output={0}" -f $secretResult.Output.Trim())
}

$bashPayload = @{
    tool_name  = 'Bash'
    tool_input = @{
        command = 'echo x > PRD/legacy.md'
    }
    cwd = $fixtureRoot
}
$bashResult = Invoke-GuardHook -HookScriptPath $guardScript -Payload $bashPayload
$bashDecision = Get-ClaudeGuardDecision -Payload $bashResult.Payload
if ($bashDecision -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_BashForbiddenPath' -Reason ("guard hook should deny Bash writing forbidden path; output={0}" -f $bashResult.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_BashForbiddenPath'

$absOutside = Join-Path $env:TEMP 'agent-dev-toolkit-guard-abs-outside.cs'
$absPayload = @{
    tool_name  = 'Write'
    tool_input = @{
        path    = $absOutside
        content = 'namespace X;'
    }
    cwd = $repoRoot
}
$absResult = Invoke-GuardHook -HookScriptPath $guardScript -Payload $absPayload
$absDecision = Get-ClaudeGuardDecision -Payload $absResult.Payload
if ($absDecision -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace' -Reason ("absolute .cs outside workspace must deny; output={0}" -f $absResult.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace'

if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}

. $claudeAdapter
$managedHooks = Get-ClaudeManagedHooksObject -InstallRoot (Join-Path $repoRoot 'scripts\validation\fixtures\claude')
if (-not $managedHooks.Contains('PreToolUse')) {
    Write-Fail -TestName 'Should_Pass_When_SettingsWirePreToolUse' -Reason 'Get-ClaudeManagedHooksObject missing PreToolUse'
}
$preEntries = @($managedHooks['PreToolUse'])
$matcherOk = $false
$commandOk = $false
foreach ($entry in $preEntries) {
    if ($entry.Contains('matcher') -and [string]$entry['matcher'] -match 'Write\|Edit\|Bash\|PowerShell') {
        $matcherOk = $true
    }
    foreach ($handler in @($entry['hooks'])) {
        if ($handler.Contains('command') -and [string]$handler['command'] -match 'guard-pre-tool\.ps1') {
            $commandOk = $true
        }
    }
}
if (-not $matcherOk) {
    Write-Fail -TestName 'Should_Pass_When_SettingsWirePreToolUse' -Reason 'PreToolUse matcher must be Write|Edit|Bash|PowerShell'
}
if (-not $commandOk) {
    Write-Fail -TestName 'Should_Pass_When_SettingsWirePreToolUse' -Reason 'PreToolUse must wire guard-pre-tool.ps1'
}
if ($script:ClaudeSettingsJsonConstant.HookMatcherPreToolUse -ne 'Write|Edit|Bash|PowerShell') {
    Write-Fail -TestName 'Should_Pass_When_SettingsWirePreToolUse' -Reason 'ClaudePathConstants HookMatcherPreToolUse incorrect'
}
Write-Pass -TestName 'Should_Pass_When_SettingsWirePreToolUse'

Write-Host 'Assert-ClaudePathSecretsGuard: ALL PASS'
exit 0
