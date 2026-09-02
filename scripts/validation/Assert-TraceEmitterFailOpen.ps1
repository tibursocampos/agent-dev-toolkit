#Requires -Version 5.1
# Tests:
#   Should_Pass_When_SharedTraceEmitCommonPresent
#   Should_Pass_When_AssetCopiesMatchSharedHash
#   Should_Pass_When_HonestyMatrixDocumentsHosts
#   Should_Append_When_ValidFixtureRoot
#   Should_Redact_When_SecretLikeSummaryAndExtra
#   Should_Exit0_When_ForcedFail
#   Should_Not_Echo_SensitiveToolBody
#   Should_Pass_When_CursorHooksWireEmitters
#   Should_Pass_When_EmitterAssetsPresentWithoutLiveHome
#
# REQ-006 / CA6 / RNF-001 / RNF-002 / RNF-004: fail-open TRACE emitters.
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

function Resolve-TraceEmitterHostShell {
    # hooks.json uses Windows PowerShell; emit scripts are #Requires -Version 5.1.
    foreach ($name in @('powershell', 'pwsh')) {
        $cmd = Get-Command -Name $name -ErrorAction SilentlyContinue
        if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace([string]$cmd.Source)) {
            return [string]$cmd.Source
        }
    }
    return $null
}

foreach ($required in @($repoRootScript, $constantsScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-TraceEmitterFailOpenPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$sharedRel = $script:ToolkitConstant.TraceEmitCommonRelativePath
$honestyRel = $script:ToolkitConstant.TraceEmitterHonestyRelativePath
$sharedPath = Join-Path $repoRoot ($sharedRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$honestyPath = Join-Path $repoRoot ($honestyRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $sharedPath)) {
    Write-Fail -TestName 'Should_Pass_When_SharedTraceEmitCommonPresent' -Reason ("missing {0}" -f $sharedRel)
}
$sharedText = Get-Content -LiteralPath $sharedPath -Raw -Encoding UTF8
foreach ($marker in @('Add-TraceEmitterEvent', 'Invoke-TraceEmitterFromHookInput', 'TOOLKIT_TRACE_FORCE_FAIL', 'TOOLKIT_TRACE_FEATURE_ROOT', 'fail-open', 'trusted-CI-only', 'Convert-TraceEmitterExtraValue')) {
    if ($sharedText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_SharedTraceEmitCommonPresent' -Reason ("missing marker {0}" -f $marker)
    }
}
if ($sharedText -notmatch 'gh\[pousr\]_') {
    Write-Fail -TestName 'Should_Pass_When_SharedTraceEmitCommonPresent' -Reason 'missing github token redaction pattern'
}
Write-Pass -TestName 'Should_Pass_When_SharedTraceEmitCommonPresent'

$sharedHash = (Get-FileHash -LiteralPath $sharedPath -Algorithm SHA256).Hash
foreach ($assetRel in @($script:ToolkitConstant.TraceEmitCommonAssetRelativePaths)) {
    $assetPath = Join-Path $repoRoot ($assetRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $assetPath)) {
        Write-Fail -TestName 'Should_Pass_When_AssetCopiesMatchSharedHash' -Reason ("missing asset copy {0}" -f $assetRel)
    }
    $assetHash = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash
    if ($assetHash -ne $sharedHash) {
        Write-Fail -TestName 'Should_Pass_When_AssetCopiesMatchSharedHash' -Reason ("hash drift vs shared: {0}" -f $assetRel)
    }
}
Write-Pass -TestName 'Should_Pass_When_AssetCopiesMatchSharedHash'

if (-not (Test-Path -LiteralPath $honestyPath)) {
    Write-Fail -TestName 'Should_Pass_When_HonestyMatrixDocumentsHosts' -Reason ("missing {0}" -f $honestyRel)
}
$honestyText = Get-Content -LiteralPath $honestyPath -Raw -Encoding UTF8
foreach ($marker in @('Cursor', 'Claude', 'Codex', 'OpenHands', 'fail-open', 'REQ-006', 'Honesty', 'trusted-CI-only', 'TOOLKIT_TRACE_FEATURE_ROOT')) {
    if ($honestyText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_HonestyMatrixDocumentsHosts' -Reason ("honesty missing {0}" -f $marker)
    }
}
if ($honestyText -notmatch 'do not fake' -and $honestyText -notmatch 'Not.*claimed' -and $honestyText -notmatch '\*\*None\*\*') {
    Write-Fail -TestName 'Should_Pass_When_HonestyMatrixDocumentsHosts' -Reason 'honesty must document hosts without full TRACE surface'
}
Write-Pass -TestName 'Should_Pass_When_HonestyMatrixDocumentsHosts'

# Fixture feature root under scripts/validation/fixtures (never USERPROFILE).
$fixtureRoot = Join-Path $scriptDir ($script:ToolkitConstant.TraceEmitterFixtureRelativeDir -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$userProfile = [string]$env:USERPROFILE
if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
    $fixtureFull = [System.IO.Path]::GetFullPath($fixtureRoot)
    $profileFull = [System.IO.Path]::GetFullPath($userProfile)
    if ($fixtureFull.StartsWith($profileFull.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail -TestName 'Should_Pass_When_EmitterAssetsPresentWithoutLiveHome' -Reason 'fixture root must not live under USERPROFILE'
    }
}

if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
$featureRoot = Join-Path $fixtureRoot 'features\006-trace-emitter-fixture'
New-Item -ItemType Directory -Path $featureRoot -Force | Out-Null

. $sharedPath

$env:TOOLKIT_TRACE_FEATURE_ROOT = $featureRoot
Remove-Item Env:TOOLKIT_TRACE_FORCE_FAIL -ErrorAction SilentlyContinue

$payload = New-TraceEmitterAllowlistedEvent -EventName 'note' -FeaturePortable 'features/006-trace-emitter-fixture' -Summary 'append-ok' -HostId 'fixture' -HookName 'postToolUse'
$ok = Add-TraceEmitterEvent -Event $payload
if (-not $ok) {
    Write-Fail -TestName 'Should_Append_When_ValidFixtureRoot' -Reason 'Add-TraceEmitterEvent returned false'
}
$tracePath = Join-Path $featureRoot 'TRACE.jsonl'
if (-not (Test-Path -LiteralPath $tracePath)) {
    Write-Fail -TestName 'Should_Append_When_ValidFixtureRoot' -Reason 'TRACE.jsonl missing after append'
}
$line = Get-Content -LiteralPath $tracePath -TotalCount 1
if ($line -notmatch '"event"\s*:\s*"note"' -or $line -notmatch 'features/006-trace-emitter-fixture') {
    Write-Fail -TestName 'Should_Append_When_ValidFixtureRoot' -Reason ("unexpected TRACE line: {0}" -f $line)
}
if ($line -match '[A-Za-z]:/') {
    Write-Fail -TestName 'Should_Append_When_ValidFixtureRoot' -Reason 'TRACE line must use portable feature path'
}
Write-Pass -TestName 'Should_Append_When_ValidFixtureRoot'

# Successful append with secret-like summary/Extra — TRACE + stdout must stay clean.
$plantToken = 'ghp_TESTNOTREAL_aaaaabbbbbcccccddddd'
$plantPassword = 'SuperSecretPlant99'
$plantConn = 'Server=db.example;password=ConnSecretPlant99;AccountKey=abcdefghijklmnopqrstuvwxyz0123456789ABCD'
$plantResponse = 'RAW_HOST_RESPONSE_BODY_MUST_DROP'
$secretSummary = ("note bearer {0} password={1}" -f $plantToken, $plantPassword)
$extra = @{
    role     = 'fixture-role'
    reason   = $plantConn
    response = $plantResponse
    spawn    = @{
        role    = 'child'
        reason  = ("api_key={0}" -f $plantToken)
        outcome = 'completed'
    }
}
$secretPayload = New-TraceEmitterAllowlistedEvent `
    -EventName 'specialist_complete' `
    -FeaturePortable 'features/006-trace-emitter-fixture' `
    -Summary $secretSummary `
    -HostId 'fixture' `
    -HookName 'subagentStop' `
    -Role 'fixture-role' `
    -Outcome 'completed' `
    -Extra $extra
$secretOk = Add-TraceEmitterEvent -Event $secretPayload
if (-not $secretOk) {
    Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason 'secret-like append returned false (expected redact+append)'
}
$secretLines = @(Get-Content -LiteralPath $tracePath)
$secretLine = $secretLines[-1]
foreach ($leak in @($plantToken, $plantPassword, 'ConnSecretPlant99', $plantResponse, 'abcdefghijklmnopqrstuvwxyz0123456789ABCD')) {
    if ($secretLine -match [regex]::Escape($leak)) {
        Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason ("TRACE.jsonl leaked secret fragment: {0}" -f $leak)
    }
}
if ($secretLine -match '"response"') {
    Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason 'Extra response key must be dropped'
}
if ($secretLine -notmatch 'gh\*_\*\*\*' -and $secretLine -notmatch '\*\*\*') {
    Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason 'expected redaction markers in TRACE line'
}

$hostShell = Resolve-TraceEmitterHostShell
if ([string]::IsNullOrWhiteSpace($hostShell)) {
    Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason 'neither powershell nor pwsh available'
}
$cursorEmit = Join-Path $repoRoot ($script:ToolkitConstant.CursorTraceEmitScriptRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $cursorEmit)) {
    Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason ("missing {0}" -f $script:ToolkitConstant.CursorTraceEmitScriptRelativePath)
}

$hookSecretInput = [pscustomobject]@{
    hook_event_name = 'subagentStop'
    subagent_type   = 'explore'
    status          = 'completed'
    description     = ("done bearer {0} password={1}" -f $plantToken, $plantPassword)
}
$hookJson = $hookSecretInput | ConvertTo-Json -Compress -Depth 6
$beforeHookCount = @(Get-Content -LiteralPath $tracePath).Count
$hookOutput = $hookJson | & $hostShell -NoProfile -ExecutionPolicy Bypass -File $cursorEmit 2>&1 | Out-String
$hookCode = $LASTEXITCODE
if ($null -eq $hookCode) { $hookCode = 0 }
if ($hookCode -ne 0) {
    Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason ("emit-trace exit {0} (expected 0 fail-open)" -f $hookCode)
}
$afterHookCount = @(Get-Content -LiteralPath $tracePath).Count
if ($afterHookCount -le $beforeHookCount) {
    Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason 'successful emit did not append TRACE line'
}
$hookLine = (Get-Content -LiteralPath $tracePath)[-1]
foreach ($leak in @($plantToken, $plantPassword)) {
    if ($hookLine -match [regex]::Escape($leak) -or $hookOutput -match [regex]::Escape($leak)) {
        Write-Fail -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra' -Reason ("hook emit leaked secret to TRACE/stdout: {0}" -f $leak)
    }
}
Write-Pass -TestName 'Should_Redact_When_SecretLikeSummaryAndExtra'

$env:TOOLKIT_TRACE_FORCE_FAIL = '1'
$beforeCount = @(Get-Content -LiteralPath $tracePath).Count
$hookInput = [pscustomobject]@{
    hook_event_name = 'postToolUse'
    tool_name       = 'Write'
    tool_input      = @{ content = 'SECRET_TOKEN=super-secret-value-should-not-echo' }
}

$json = $hookInput | ConvertTo-Json -Compress -Depth 6
$output = $json | & $hostShell -NoProfile -ExecutionPolicy Bypass -File $cursorEmit 2>&1 | Out-String
$code = $LASTEXITCODE
if ($null -eq $code) { $code = 0 }
if ($code -ne 0) {
    Write-Fail -TestName 'Should_Exit0_When_ForcedFail' -Reason ("exit {0} (expected 0 fail-open)" -f $code)
}
$afterCount = @(Get-Content -LiteralPath $tracePath).Count
if ($afterCount -ne $beforeCount) {
    Write-Fail -TestName 'Should_Exit0_When_ForcedFail' -Reason 'forced fail still appended TRACE line'
}
Write-Pass -TestName 'Should_Exit0_When_ForcedFail'

if ($output -match 'super-secret-value-should-not-echo' -or $output -match 'SECRET_TOKEN=') {
    Write-Fail -TestName 'Should_Not_Echo_SensitiveToolBody' -Reason 'emitter stdout echoed sensitive tool body'
}
Write-Pass -TestName 'Should_Not_Echo_SensitiveToolBody'

Remove-Item Env:TOOLKIT_TRACE_FORCE_FAIL -ErrorAction SilentlyContinue

$hooksJsonPath = Join-Path $repoRoot ($script:ToolkitConstant.CursorHooksJsonRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
    Write-Fail -TestName 'Should_Pass_When_CursorHooksWireEmitters' -Reason 'missing cursor hooks.json'
}
$hooksJson = Get-Content -LiteralPath $hooksJsonPath -Raw -Encoding UTF8
if ($hooksJson -notmatch '"postToolUse"' -or $hooksJson -notmatch '"subagentStop"') {
    Write-Fail -TestName 'Should_Pass_When_CursorHooksWireEmitters' -Reason 'hooks.json missing postToolUse/subagentStop'
}
if ($hooksJson -notmatch 'emit-trace\.ps1') {
    Write-Fail -TestName 'Should_Pass_When_CursorHooksWireEmitters' -Reason 'hooks.json must wire emit-trace.ps1'
}
if ($hooksJson -notmatch 'powershell' -and $hooksJson -notmatch 'pwsh') {
    Write-Fail -TestName 'Should_Pass_When_CursorHooksWireEmitters' -Reason 'hooks.json must invoke powershell or pwsh'
}
Write-Pass -TestName 'Should_Pass_When_CursorHooksWireEmitters'

$assetRels = @(
    $script:ToolkitConstant.CursorTraceEmitScriptRelativePath,
    $script:ToolkitConstant.ClaudeTraceEmitScriptRelativePath,
    $script:ToolkitConstant.CodexTraceEmitScriptRelativePath
)
foreach ($rel in $assetRels) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName 'Should_Pass_When_EmitterAssetsPresentWithoutLiveHome' -Reason ("missing asset {0}" -f $rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_EmitterAssetsPresentWithoutLiveHome'

Remove-Item Env:TOOLKIT_TRACE_FEATURE_ROOT -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}

Write-Host 'Assert-TraceEmitterFailOpen: ALL PASS'
exit 0
