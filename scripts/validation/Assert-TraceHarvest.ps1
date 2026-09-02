#Requires -Version 5.1
# Tests:
#   Should_Pass_When_TraceHarvestScriptExists
#   Should_Pass_When_HarvestIncludesRunMetrics
#   Should_Fail_When_FeatureRootOutOfScope
#   Should_Fail_When_SessionsPathRejected
#   Should_Fail_When_SiblingPrefixFeatureRootRejected
#   Should_Pass_When_HarvestNeverReadsSessions
#
# REQ-007 / CA7 + TE05: feature-scoped TRACE harvest with metrics; no sdd/sessions dump.
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

function Invoke-HarvestCapture {
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter(Mandatory = $true)][hashtable] $Arguments
    )

    $output = & $ScriptPath @Arguments 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 0
    }

    return [PSCustomObject]@{
        ExitCode = [int]$code
        Output   = $output.Trim()
    }
}

function Convert-HarvestJson {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Raw
    )

    $jsonLine = ($Raw -split "`r?`n" | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)
    if ([string]::IsNullOrWhiteSpace($jsonLine)) {
        Write-Fail -TestName $TestName -Reason ("expected JSON object in output, got: {0}" -f $Raw)
    }

    try {
        return ($jsonLine | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        Write-Fail -TestName $TestName -Reason ("invalid harvest JSON: {0}" -f $_.Exception.Message)
    }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-TraceHarvestPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-TraceHarvestPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

# Single source of truth: ToolkitConstants (no parallel-wave local mirrors).
$script:HarvestExitOk = $script:ToolkitConstant.TraceHarvestExitOk
$script:HarvestExitFail = $script:ToolkitConstant.TraceHarvestExitFail
$script:HarvestStatusOk = $script:ToolkitConstant.TraceHarvestStatusOk
$script:HarvestStatusError = $script:ToolkitConstant.TraceHarvestStatusError
$script:HarvestScriptRelativePath = $script:ToolkitConstant.InvokeTraceHarvestScriptRelativePath
$script:HarvestValidFixtureRelativeDir = $script:ToolkitConstant.TraceHarvestValidFixtureRelativeDir
$script:HarvestFixtureFeatureSlug = $script:ToolkitConstant.TraceHarvestFixtureFeatureSlug

$harvestScriptPath = Join-Path $repoRoot ($script:HarvestScriptRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validFixtureDir = Join-Path $repoRoot ($script:HarvestValidFixtureRelativeDir -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validTracePath = Join-Path $validFixtureDir $script:ToolkitConstant.SddArtifactTraceFileName

if (-not (Test-Path -LiteralPath $harvestScriptPath)) {
    Write-Fail -TestName 'Should_Pass_When_TraceHarvestScriptExists' -Reason ("missing {0}" -f $script:HarvestScriptRelativePath)
}

Write-Pass -TestName 'Should_Pass_When_TraceHarvestScriptExists'

if (-not (Test-Path -LiteralPath $validTracePath)) {
    Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason ("missing fixture TRACE at {0}" -f $script:HarvestValidFixtureRelativeDir)
}

# --- CT6: harvest includes tokens/duration/spawn when present ---
$workRoot = Join-Path $env:TEMP ('adt-trace-harvest-metrics-{0}' -f [Guid]::NewGuid().ToString('N'))
$featureRel = ('features/{0}' -f $script:HarvestFixtureFeatureSlug)
$workFeature = Join-Path $workRoot ($featureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

try {
    New-Item -ItemType Directory -Path $workFeature -Force | Out-Null
    Copy-Item -LiteralPath $validTracePath -Destination (Join-Path $workFeature $script:ToolkitConstant.SddArtifactTraceFileName) -Force

    $capture = Invoke-HarvestCapture -ScriptPath $harvestScriptPath -Arguments @{
        FeatureRoot = $workFeature
        RepoPath    = $workRoot
    }

    if ($capture.ExitCode -ne $script:HarvestExitOk) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason ("expected exit {0}, got {1}; output={2}" -f $script:HarvestExitOk, $capture.ExitCode, $capture.Output)
    }

    $payload = Convert-HarvestJson -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Raw $capture.Output

    if ([string]$payload.status -ne $script:HarvestStatusOk) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason ("expected status ok, got {0}" -f $payload.status)
    }

    if ([int]$payload.event_count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason 'event_count must be >= 1'
    }

    if (-not [bool]$payload.metrics_present.tokens) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason 'metrics_present.tokens must be true'
    }
    if (-not [bool]$payload.metrics_present.duration) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason 'metrics_present.duration must be true'
    }
    if (-not [bool]$payload.metrics_present.spawn) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason 'metrics_present.spawn must be true'
    }

    $eventsWithMetrics = @($payload.events | Where-Object {
            ($null -ne $_.PSObject.Properties['tokens']) -or
            ($null -ne $_.PSObject.Properties['duration']) -or
            ($null -ne $_.PSObject.Properties['spawn'])
        })
    if ($eventsWithMetrics.Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason 'at least one event must include tokens/duration/spawn'
    }

    if ([bool]$payload.sessions_read) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason 'sessions_read must be false'
    }

    if (($capture.Output -match '(?i)sdd[/\\]sessions') -and ($capture.Output -notmatch 'sessions_denied|sessions_read')) {
        Write-Fail -TestName 'Should_Pass_When_HarvestIncludesRunMetrics' -Reason 'harvest output must not dump sdd/sessions content'
    }

    Write-Pass -TestName 'Should_Pass_When_HarvestIncludesRunMetrics'
}
finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- TE05: feature root out of scope ---
$outsideRoot = Join-Path $env:TEMP ('adt-trace-harvest-outside-{0}' -f [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $outsideRoot -Force | Out-Null
    $captureOutside = Invoke-HarvestCapture -ScriptPath $harvestScriptPath -Arguments @{
        FeatureRoot = $outsideRoot
        RepoPath    = $repoRoot
    }

    if ($captureOutside.ExitCode -ne $script:HarvestExitFail) {
        Write-Fail -TestName 'Should_Fail_When_FeatureRootOutOfScope' -Reason ("expected exit {0}, got {1}; output={2}" -f $script:HarvestExitFail, $captureOutside.ExitCode, $captureOutside.Output)
    }

    $payloadOutside = Convert-HarvestJson -TestName 'Should_Fail_When_FeatureRootOutOfScope' -Raw $captureOutside.Output
    if ([string]$payloadOutside.status -ne $script:HarvestStatusError) {
        Write-Fail -TestName 'Should_Fail_When_FeatureRootOutOfScope' -Reason ("expected status error, got {0}" -f $payloadOutside.status)
    }

    $reasonOutside = [string]$payloadOutside.status_reason
    if ($reasonOutside -notmatch '^(path_escape|invalid_scope):') {
        Write-Fail -TestName 'Should_Fail_When_FeatureRootOutOfScope' -Reason ("expected path_escape|invalid_scope reason, got {0}" -f $reasonOutside)
    }

    Write-Pass -TestName 'Should_Fail_When_FeatureRootOutOfScope'
}
finally {
    if (Test-Path -LiteralPath $outsideRoot) {
        Remove-Item -LiteralPath $outsideRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- SEC: reject sdd/sessions path ---
$sessionsProbe = Join-Path $env:TEMP ('adt-trace-harvest-sessions-{0}\sdd\sessions\fake' -f [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $sessionsProbe -Force | Out-Null
    $captureSessions = Invoke-HarvestCapture -ScriptPath $harvestScriptPath -Arguments @{
        FeatureRoot = $sessionsProbe
        RepoPath    = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $sessionsProbe)))
    }

    if ($captureSessions.ExitCode -ne $script:HarvestExitFail) {
        Write-Fail -TestName 'Should_Fail_When_SessionsPathRejected' -Reason ("expected exit {0}, got {1}; output={2}" -f $script:HarvestExitFail, $captureSessions.ExitCode, $captureSessions.Output)
    }

    $payloadSessions = Convert-HarvestJson -TestName 'Should_Fail_When_SessionsPathRejected' -Raw $captureSessions.Output
    if ([string]$payloadSessions.status_reason -notmatch '^sessions_denied:') {
        Write-Fail -TestName 'Should_Fail_When_SessionsPathRejected' -Reason ("expected sessions_denied reason, got {0}" -f $payloadSessions.status_reason)
    }

    Write-Pass -TestName 'Should_Fail_When_SessionsPathRejected'
}
finally {
    $sessionsTop = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $sessionsProbe))
    if (Test-Path -LiteralPath $sessionsTop) {
        Remove-Item -LiteralPath $sessionsTop -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- RNF-004 sibling-prefix: repo-evil must not count as under repo ---
$siblingParent = Join-Path $env:TEMP ('adt-trace-harvest-sibling-{0}' -f [Guid]::NewGuid().ToString('N'))
$siblingRepo = Join-Path $siblingParent 'repo'
$siblingEvil = Join-Path $siblingParent 'repo-evil'
$siblingEvilFeature = Join-Path $siblingEvil ('features/{0}' -f $script:HarvestFixtureFeatureSlug).Replace('/', [System.IO.Path]::DirectorySeparatorChar)

try {
    New-Item -ItemType Directory -Path $siblingRepo, $siblingEvilFeature -Force | Out-Null
    Copy-Item -LiteralPath $validTracePath -Destination (Join-Path $siblingEvilFeature $script:ToolkitConstant.SddArtifactTraceFileName) -Force

    $harvestSource = Get-Content -LiteralPath $harvestScriptPath -Raw -Encoding UTF8
    if ($harvestSource -notmatch 'Test-IsPathUnderOrEqual') {
        Write-Fail -TestName 'Should_Fail_When_SiblingPrefixFeatureRootRejected' -Reason 'harvest must reuse Test-IsPathUnderOrEqual for path boundaries'
    }

    $captureSibling = Invoke-HarvestCapture -ScriptPath $harvestScriptPath -Arguments @{
        FeatureRoot = $siblingEvilFeature
        RepoPath    = $siblingRepo
    }

    if ($captureSibling.ExitCode -ne $script:HarvestExitFail) {
        Write-Fail -TestName 'Should_Fail_When_SiblingPrefixFeatureRootRejected' -Reason ("expected exit {0}, got {1}; output={2}" -f $script:HarvestExitFail, $captureSibling.ExitCode, $captureSibling.Output)
    }

    $payloadSibling = Convert-HarvestJson -TestName 'Should_Fail_When_SiblingPrefixFeatureRootRejected' -Raw $captureSibling.Output
    if ([string]$payloadSibling.status_reason -notmatch '^path_escape:') {
        Write-Fail -TestName 'Should_Fail_When_SiblingPrefixFeatureRootRejected' -Reason ("expected path_escape reason, got {0}" -f $payloadSibling.status_reason)
    }

    Write-Pass -TestName 'Should_Fail_When_SiblingPrefixFeatureRootRejected'
}
finally {
    if (Test-Path -LiteralPath $siblingParent) {
        Remove-Item -LiteralPath $siblingParent -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- RNF: harvest must deny sdd/sessions (constants + script wiring; no dump) ---
$harvestSource = Get-Content -LiteralPath $harvestScriptPath -Raw -Encoding UTF8
$constantsSource = Get-Content -LiteralPath $constantsScript -Raw -Encoding UTF8
if ($constantsSource -notmatch 'sessions_denied' -or $constantsSource -notmatch 'sdd[/\\]sessions') {
    Write-Fail -TestName 'Should_Pass_When_HarvestNeverReadsSessions' -Reason 'ToolkitConstants must define sessions_denied + sdd/sessions deny pattern'
}
if ($harvestSource -notmatch 'TraceHarvestReasonSessionsDenied' -or $harvestSource -notmatch 'TraceHarvestSessionsSegmentPattern') {
    Write-Fail -TestName 'Should_Pass_When_HarvestNeverReadsSessions' -Reason 'harvest script must wire TraceHarvest sessions deny constants'
}
if ($harvestSource -match '(?i)Get-ChildItem[^\r\n]*sdd[/\\]sessions') {
    Write-Fail -TestName 'Should_Pass_When_HarvestNeverReadsSessions' -Reason 'harvest must not enumerate sdd/sessions'
}
if ($harvestSource -notmatch 'SddArtifactTraceFileName|TRACE\.jsonl') {
    Write-Fail -TestName 'Should_Pass_When_HarvestNeverReadsSessions' -Reason 'harvest must read TRACE.jsonl only'
}

Write-Pass -TestName 'Should_Pass_When_HarvestNeverReadsSessions'

Write-Host 'Assert-TraceHarvest: ALL PASS'
exit 0
