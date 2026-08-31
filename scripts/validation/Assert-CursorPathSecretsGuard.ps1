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

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CursorPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
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

$fixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\cursor-path-guard-work'
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
if ($null -eq $denyResult.Payload -or $denyResult.Payload.permission -ne 'deny') {
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
if ($null -eq $secretResult.Payload -or $secretResult.Payload.permission -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("guard hook should deny secret content; output={0}" -f $secretResult.Output.Trim())
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

$deletePayload = @{
    tool_name  = 'Delete'
    tool_input = @{
        path = (Join-Path $env:TEMP 'PRD\blocked.md')
    }
    cwd = $env:TEMP
}
# Path check does not require the file to exist.
$deleteDeny = Invoke-GuardHook -HookScriptPath $guardScript -Payload $deletePayload
if ($null -eq $deleteDeny.Payload -or $deleteDeny.Payload.permission -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_DeleteForbiddenPath' -Reason ("guard hook should deny Delete on forbidden SDD path; output={0}" -f $deleteDeny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_DeleteForbiddenPath'

$shellPayload = @{
    tool_name  = 'Shell'
    tool_input = @{
        command = 'echo secret > PRD/legacy.md'
    }
    cwd = $env:TEMP
}
$shellDeny = Invoke-GuardHook -HookScriptPath $guardScript -Payload $shellPayload
if ($null -eq $shellDeny.Payload -or $shellDeny.Payload.permission -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_ShellForbiddenPath' -Reason ("guard hook should deny Shell writing forbidden path; output={0}" -f $shellDeny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ShellForbiddenPath'

$beforeShellPayload = @{
    command = 'Remove-Item -Recurse node_modules/pkg'
    cwd     = $env:TEMP
}
$beforeShellDeny = Invoke-GuardHook -HookScriptPath $guardScript -Payload $beforeShellPayload
if ($null -eq $beforeShellDeny.Payload -or $beforeShellDeny.Payload.permission -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_BeforeShellForbiddenPath' -Reason ("beforeShellExecution shape should deny; output={0}" -f $beforeShellDeny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_BeforeShellForbiddenPath'

$absOutside = Join-Path $env:TEMP 'agent-dev-toolkit-guard-abs-outside.cs'
$absPayload = @{
    tool_name  = 'Write'
    tool_input = @{
        path    = $absOutside
        content = 'namespace X;'
    }
    cwd = $repoRoot
}
$absDeny = Invoke-GuardHook -HookScriptPath $guardScript -Payload $absPayload
if ($null -eq $absDeny.Payload -or $absDeny.Payload.permission -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace' -Reason ("absolute .cs outside workspace must deny; output={0}" -f $absDeny.Output.Trim())
}
if (Test-ToolkitAllowedWritePath -RelativePath $absOutside) {
    Write-Fail -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace' -Reason 'Test-ToolkitAllowedWritePath must reject absolute paths'
}
Write-Pass -TestName 'Should_Deny_When_AbsolutePathOutsideWorkspace'

$missingPathPayload = @{
    tool_name  = 'Write'
    tool_input = @{
        content = 'namespace X;'
    }
    cwd = $repoRoot
}
$missingPathDeny = Invoke-GuardHook -HookScriptPath $guardScript -Payload $missingPathPayload
if ($null -eq $missingPathDeny.Payload -or $missingPathDeny.Payload.permission -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_WriteMissingPath' -Reason ("write without path must deny; output={0}" -f $missingPathDeny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_WriteMissingPath'

$namedPathShell = @{
    tool_name  = 'Shell'
    tool_input = @{
        command = ("Set-Content -Path '{0}' -Value 'x'" -f (Join-Path $env:TEMP 'PRD\via-named-path.md'))
    }
    cwd = $repoRoot
}
$namedPathDeny = Invoke-GuardHook -HookScriptPath $guardScript -Payload $namedPathShell
if ($null -eq $namedPathDeny.Payload -or $namedPathDeny.Payload.permission -ne 'deny') {
    Write-Fail -TestName 'Should_Deny_When_ShellNamedPathOutside' -Reason ("Set-Content -Path outside workspace must deny; output={0}" -f $namedPathDeny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ShellNamedPathOutside'

Write-Host 'Assert-CursorPathSecretsGuard: ALL PASS'
exit 0
