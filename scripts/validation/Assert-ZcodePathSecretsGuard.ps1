#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_HooksJsonWiresPreToolUse
#
# Frente 2.6: ZCode PreToolUse path + secrets guard.
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
    if ($null -eq $code) { $code = 0 }
    $parsed = $null
    try {
        $parsed = $output.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $parsed = $null
    }
    return [PSCustomObject]@{ ExitCode = [int]$code; Output = $output; Payload = $parsed }
}

function Get-ZCodeGuardDecision {
    param($Payload)
    if ($null -eq $Payload -or -not $Payload.hookSpecificOutput) {
        return $null
    }
    return [string]$Payload.hookSpecificOutput.permissionDecision
}

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-ZcodePathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$hooksDir = Join-Path $repoRoot 'adapters\zcode\hooks'
$guardScript = Join-Path $hooksDir 'guard-pre-tool.ps1'
$hooksJsonPath = Join-Path $hooksDir 'hooks.json'
$cliConfigPath = Join-Path $repoRoot 'adapters\zcode\cli\config.json'

if (-not (Test-Path -LiteralPath $guardScript)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'missing ZCode guard-pre-tool.ps1'
}
Write-Pass -TestName 'Should_Pass_When_GuardHookPresent'

$fixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\zcode-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$deny = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    tool_name  = 'Write'
    tool_input = @{
        file_path = (Join-Path $fixtureRoot 'PRD\blocked.md')
        content   = '# blocked'
    }
    cwd = $fixtureRoot
}
$decision = Get-ZCodeGuardDecision $deny.Payload
$denied = ($deny.ExitCode -eq 2) -or ($decision -eq 'deny')
if (-not $denied) {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("expected deny; exit={0} output={1}" -f $deny.ExitCode, $deny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath'

$secret = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    tool_name  = 'Write'
    tool_input = @{
        file_path = (Join-Path $fixtureRoot 'src\ok.ts')
        content   = 'const key = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd";'
    }
    cwd = $fixtureRoot
}
$secretDecision = Get-ZCodeGuardDecision $secret.Payload
$secretDenied = ($secret.ExitCode -eq 2) -or ($secretDecision -eq 'deny')
if (-not $secretDenied) {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("expected secret deny; exit={0} output={1}" -f $secret.ExitCode, $secret.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretPatternDetected'

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

$hooksText = Get-Content -LiteralPath $hooksJsonPath -Raw -Encoding UTF8
if ($hooksText -notmatch 'PreToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json missing PreToolUse'
}
if ($hooksText -notmatch 'guard-pre-tool\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json missing guard-pre-tool.ps1'
}
if ($hooksText -notmatch 'Write\|Edit\|Bash\|PowerShell') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'hooks.json missing Write|Edit|Bash|PowerShell matcher'
}

$cliText = Get-Content -LiteralPath $cliConfigPath -Raw -Encoding UTF8
$cliObj = $cliText | ConvertFrom-Json
if (-not $cliObj.hooks.enabled) {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'cli/config.json hooks.enabled must be true'
}
if ($cliText -notmatch 'PreToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'cli/config.json missing PreToolUse event'
}
Write-Pass -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse'

Write-Host 'Assert-ZcodePathSecretsGuard: ALL PASS'
exit 0
