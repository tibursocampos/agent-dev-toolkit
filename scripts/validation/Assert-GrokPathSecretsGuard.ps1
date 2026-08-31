#Requires -Version 5.1
# Tests:
#   Should_Pass_When_GuardHookPresent
#   Should_Deny_When_ForbiddenSddPath
#   Should_Deny_When_SecretPatternDetected
#   Should_Pass_When_HooksJsonWiresPreToolUse
#   Should_Pass_When_AgentsCapabilityTrue
#
# Frente 2.7: Grok PreToolUse path + secrets + agents publish.
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

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-GrokPathSecretsGuardPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$guardScript = Join-Path $repoRoot 'adapters\grok\assets\hooks\guard-pre-tool.ps1'
$publishHooks = Join-Path $repoRoot 'adapters\grok\Publish-GrokHooks.ps1'
$grokAdapter = Join-Path $repoRoot 'adapters\grok\GrokAdapter.ps1'
$registryPath = Join-Path $repoRoot 'adapters\registry.json'

if (-not (Test-Path -LiteralPath $guardScript)) {
    Write-Fail -TestName 'Should_Pass_When_GuardHookPresent' -Reason 'missing Grok guard-pre-tool.ps1'
}
Write-Pass -TestName 'Should_Pass_When_GuardHookPresent'

$fixtureRoot = Join-Path $repoRoot 'scripts\validation\fixtures\grok-path-guard-work'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force

$deny = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    tool_name  = 'Write'
    tool_input = @{
        path    = (Join-Path $fixtureRoot 'PRD\blocked.md')
        content = '# blocked'
    }
    cwd = $fixtureRoot
}
$denied = ($deny.ExitCode -eq 2) -or ($null -ne $deny.Payload -and [string]$deny.Payload.decision -eq 'deny')
if (-not $denied) {
    Write-Fail -TestName 'Should_Deny_When_ForbiddenSddPath' -Reason ("expected deny; exit={0} output={1}" -f $deny.ExitCode, $deny.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_ForbiddenSddPath'

$secret = Invoke-GuardHook -HookScriptPath $guardScript -Payload @{
    tool_name  = 'Bash'
    tool_input = @{ command = 'echo ghp_TESTNOTREAL_aaaaabbbbbcccccddddd > src/ok.txt' }
    cwd        = $fixtureRoot
}
$secretDenied = ($secret.ExitCode -eq 2) -or ($null -ne $secret.Payload -and [string]$secret.Payload.decision -eq 'deny')
if (-not $secretDenied) {
    Write-Fail -TestName 'Should_Deny_When_SecretPatternDetected' -Reason ("expected secret deny; exit={0} output={1}" -f $secret.ExitCode, $secret.Output.Trim())
}
Write-Pass -TestName 'Should_Deny_When_SecretPatternDetected'

Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

. (Join-Path $repoRoot 'adapters\grok\GrokPathConstants.ps1')
. $publishHooks
$session = 'C:/tmp/session_start.ps1'
$guard = 'C:/tmp/guard-pre-tool.ps1'
$hooksObj = New-GrokMinimalHooksObject -SessionStartScriptPath $session -GuardPreToolScriptPath $guard
$hooksText = ($hooksObj | ConvertTo-Json -Depth 8)
if ($hooksText -notmatch 'PreToolUse') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing PreToolUse'
}
if ($hooksText -notmatch 'guard-pre-tool\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing guard-pre-tool.ps1'
}
if ($hooksText -notmatch 'Write\|Edit\|Bash') {
    Write-Fail -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse' -Reason 'missing Write|Edit|Bash matcher'
}
Write-Pass -TestName 'Should_Pass_When_HooksJsonWiresPreToolUse'

. $grokAdapter
$caps = Get-Capabilities
if (-not $caps.Capabilities.agents) {
    Write-Fail -TestName 'Should_Pass_When_AgentsCapabilityTrue' -Reason 'Get-Capabilities agents must be true'
}
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$grokEntry = @($registry.agents | Where-Object { $_.id -eq 'grok' })[0]
if (-not $grokEntry.capabilities.agents) {
    Write-Fail -TestName 'Should_Pass_When_AgentsCapabilityTrue' -Reason 'registry.json grok.agents must be true'
}
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'adapters\grok\Publish-GrokAgents.ps1'))) {
    Write-Fail -TestName 'Should_Pass_When_AgentsCapabilityTrue' -Reason 'missing Publish-GrokAgents.ps1'
}
Write-Pass -TestName 'Should_Pass_When_AgentsCapabilityTrue'

Write-Host 'Assert-GrokPathSecretsGuard: ALL PASS'
exit 0
