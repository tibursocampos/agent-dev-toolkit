#Requires -Version 5.1
# Tests:
#   Should_AppendAndRedact_When_SecretLikeSummaryAndExtra
#   Should_Exit0_NoAppend_NoEcho_When_ForcedFail
#   Should_Exit0_NoAppend_When_NormalPostToolUse
#   Should_Exit0_NoAppend_NoEcho_When_CodexSubagentStopForcedFail
#   Should_AppendRedacted_When_CodexSubagentStop
#   Should_Exit0_NoAppend_When_CodexPostToolUseWired
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'New-ToolkitWorkRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

function Write-Pass { param([string] $Name) Write-Host ("{0}: PASS" -f $Name) }
function Write-Fail { param([string] $Name, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $Name, $Reason); exit 1 }

$hostShell = $null
foreach ($name in @('powershell', 'pwsh')) {
    $cmd = Get-Command -Name $name -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { $hostShell = [string]$cmd.Source; break }
}
if (-not $hostShell) { Write-Fail 'TraceEmitterFailOpen' 'neither powershell nor pwsh available' }

$sharedPath = Join-Path $repoRoot ($script:ToolkitConstant.TraceEmitCommonRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$cursorEmit = Join-Path $repoRoot ($script:ToolkitConstant.CursorTraceEmitScriptRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
foreach ($p in @($sharedPath, $cursorEmit)) { if (-not (Test-Path -LiteralPath $p)) { Write-Fail 'TraceEmitterFailOpen' "missing $p" } }

$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $featureRoot = Join-Path $work 'features\006-trace-emitter-fixture'
    New-Item -ItemType Directory -Path $featureRoot -Force | Out-Null
    $tracePath = Join-Path $featureRoot 'TRACE.jsonl'
    . $sharedPath
    $env:TOOLKIT_TRACE_FEATURE_ROOT = $featureRoot
    Remove-Item Env:TOOLKIT_TRACE_FORCE_FAIL -ErrorAction SilentlyContinue

    # --- append with secret-like summary/extra: portable path, secrets and response body redacted/dropped ---
    $token = 'ghp_TESTNOTREAL_aaaaabbbbbcccccddddd'
    $pwd1 = 'SuperSecretPlant99'
    $conn = 'Server=db.example;password=ConnSecretPlant99;AccountKey=abcdefghijklmnopqrstuvwxyz0123456789ABCD'
    $payload = New-TraceEmitterAllowlistedEvent -EventName 'specialist_complete' -FeaturePortable 'features/006-trace-emitter-fixture' `
        -Summary ("note bearer {0} password={1}" -f $token, $pwd1) -HostId 'fixture' -HookName 'subagentStop' -Role 'fixture-role' -Outcome 'completed' `
        -Extra @{ role = 'fixture-role'; reason = $conn; response = 'RAW_HOST_RESPONSE_BODY_MUST_DROP' }
    $n = 'Should_AppendAndRedact_When_SecretLikeSummaryAndExtra'
    if (-not (Add-TraceEmitterEvent -Event $payload)) { Write-Fail $n 'append returned false' }
    $line = Get-Content -LiteralPath $tracePath -Raw
    if ($line -notmatch 'features/006-trace-emitter-fixture' -or $line -match '[A-Za-z]:/') { Write-Fail $n "non-portable path: $line" }
    foreach ($leak in @($token, $pwd1, 'ConnSecretPlant99', 'RAW_HOST_RESPONSE_BODY_MUST_DROP', 'abcdefghijklmnopqrstuvwxyz0123456789ABCD')) {
        if ($line -match [regex]::Escape($leak)) { Write-Fail $n "leaked: $leak" }
    }
    Write-Pass $n

    # --- forced failure: exit 0, nothing appended, tool body not echoed ---
    $env:TOOLKIT_TRACE_FORCE_FAIL = '1'
    $before = (Get-Item -LiteralPath $tracePath).Length
    $json = [pscustomobject]@{ hook_event_name = 'postToolUse'; tool_name = 'Write'; tool_input = @{ content = 'SECRET_TOKEN=super-secret-value-should-not-echo' } } | ConvertTo-Json -Compress -Depth 6
    $out = $json | & $hostShell -NoProfile -ExecutionPolicy Bypass -File $cursorEmit 2>&1 | Out-String
    $code = $LASTEXITCODE
    $n = 'Should_Exit0_NoAppend_NoEcho_When_ForcedFail'
    if ($code -ne 0) { Write-Fail $n "exit $code" }
    if ((Get-Item -LiteralPath $tracePath).Length -ne $before) { Write-Fail $n 'forced fail still appended' }
    if ($out -match 'super-secret-value-should-not-echo') { Write-Fail $n 'tool body echoed' }
    Write-Pass $n
    Remove-Item Env:TOOLKIT_TRACE_FORCE_FAIL -ErrorAction SilentlyContinue

    # --- normal postToolUse: exit 0, no per-tool TRACE line, body not echoed ---
    $before = (Get-Item -LiteralPath $tracePath).Length
    $json = [pscustomobject]@{ hook_event_name = 'postToolUse'; tool_name = 'Read'; tool_input = @{ content = 'NORMAL_TOOL_BODY_MUST_NOT_ECHO' } } | ConvertTo-Json -Compress -Depth 6
    $out = $json | & $hostShell -NoProfile -ExecutionPolicy Bypass -File $cursorEmit 2>&1 | Out-String
    $code = $LASTEXITCODE
    $n = 'Should_Exit0_NoAppend_When_NormalPostToolUse'
    if ($code -ne 0) { Write-Fail $n "exit $code" }
    if ((Get-Item -LiteralPath $tracePath).Length -ne $before) { Write-Fail $n 'per-tool TRACE line appended' }
    if ($out -match 'NORMAL_TOOL_BODY_MUST_NOT_ECHO') { Write-Fail $n 'tool body echoed' }
    Write-Pass $n

    # --- Codex SubagentStop (the only trace hook Codex registers) ---
    $codexEmit = Join-Path $repoRoot ($script:ToolkitConstant.CodexTraceEmitScriptRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $codexEmit -PathType Leaf)) { Write-Fail 'TraceEmitterFailOpen' "missing $codexEmit" }
    $codexStop = [pscustomobject]@{ hook_event_name = 'SubagentStop'; subagent_type = 'fixture-role'; description = ("finished with bearer {0} password={1}" -f $token, $pwd1) } | ConvertTo-Json -Compress -Depth 6

    $n = 'Should_Exit0_NoAppend_NoEcho_When_CodexSubagentStopForcedFail'
    $before = (Get-Item -LiteralPath $tracePath).Length
    $env:TOOLKIT_TRACE_FORCE_FAIL = '1'
    $out = $codexStop | & $hostShell -NoProfile -ExecutionPolicy Bypass -File $codexEmit 2>&1 | Out-String
    $code = $LASTEXITCODE
    Remove-Item Env:TOOLKIT_TRACE_FORCE_FAIL -ErrorAction SilentlyContinue
    if ($code -ne 0) { Write-Fail $n "exit $code" }
    if ((Get-Item -LiteralPath $tracePath).Length -ne $before) { Write-Fail $n 'forced fail still appended' }
    if ($out -match [regex]::Escape($token)) { Write-Fail $n 'secret echoed' }
    Write-Pass $n

    $n = 'Should_AppendRedacted_When_CodexSubagentStop'
    $before = (Get-Item -LiteralPath $tracePath).Length
    $out = $codexStop | & $hostShell -NoProfile -ExecutionPolicy Bypass -File $codexEmit 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($code -ne 0) { Write-Fail $n "exit $code" }
    if ((Get-Item -LiteralPath $tracePath).Length -le $before) { Write-Fail $n 'SubagentStop appended nothing' }
    $lastLine = @(Get-Content -LiteralPath $tracePath)[-1]
    if ($lastLine -notmatch 'specialist_complete') { Write-Fail $n "last TRACE line is not specialist_complete: $lastLine" }
    foreach ($leak in @($token, $pwd1)) {
        if ($lastLine -match [regex]::Escape($leak)) { Write-Fail $n "leaked: $leak" }
    }
    Write-Pass $n

    $n = 'Should_Exit0_NoAppend_When_CodexPostToolUseWired'
    $before = (Get-Item -LiteralPath $tracePath).Length
    $json = [pscustomobject]@{ hook_event_name = 'PostToolUse'; tool_name = 'Read'; tool_input = @{ content = 'CODEX_TOOL_BODY_MUST_NOT_ECHO' } } | ConvertTo-Json -Compress -Depth 6
    $out = $json | & $hostShell -NoProfile -ExecutionPolicy Bypass -File $codexEmit 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($code -ne 0) { Write-Fail $n "exit $code" }
    if ((Get-Item -LiteralPath $tracePath).Length -ne $before) { Write-Fail $n 'per-tool TRACE line appended' }
    if ($out -match 'CODEX_TOOL_BODY_MUST_NOT_ECHO') { Write-Fail $n 'tool body echoed' }
    Write-Pass $n
}
finally {
    Remove-Item Env:TOOLKIT_TRACE_FEATURE_ROOT -ErrorAction SilentlyContinue
    Remove-Item Env:TOOLKIT_TRACE_FORCE_FAIL -ErrorAction SilentlyContinue
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-TraceEmitterFailOpen: ALL PASS'
exit 0
