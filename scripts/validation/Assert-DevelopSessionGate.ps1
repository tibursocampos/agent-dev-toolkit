#Requires -Version 5.1
# Tests:
#   Should_Pass_When_HelperCreatesSessionAndSetsGate
#   Should_Pass_When_SecondRunIsIdempotent_CT5
#   Should_Pass_When_ValidateSessionGatesSeesTrue
#   Should_Fail_When_ValidateSessionGatesBlocked
#   Should_Pass_When_HelperDoesNotTouchLedger_RN04
#   Should_Pass_When_ClaimStillRunsWhenGateAlreadyTrue_CT6
#   Should_Pass_When_SessionContractCitesCanonicalScripts_REQ014
#   Should_Pass_When_AllowlistDocsCiteBothScripts_REQ013
#
# REQ-011 / REQ-012 / REQ-013 / REQ-014 / CA4 / CT5 / CT6: idempotent develop session gate + claim still required.
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

function Get-FileSha256Hex {
    param([Parameter(Mandatory = $true)][string] $Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $hash = $sha.ComputeHash($stream)
            return (([BitConverter]::ToString($hash)).Replace('-', '').ToLowerInvariant())
        }
        finally {
            $stream.Dispose()
        }
    }
    finally {
        $sha.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-DevelopSessionGatePreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-DevelopSessionGatePreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$helperRel = $script:ToolkitConstant.InvokeDevelopSessionGateScriptRelativePath
$claimRel = $script:ToolkitConstant.InvokePlanLedgerClaimScriptRelativePath
$validateRel = $script:ToolkitConstant.ValidateSessionGatesScriptRelativePath
$sessionContractRel = $script:ToolkitConstant.DevelopSessionGateSessionContractRelativePath
$sessionMirrorRel = $script:ToolkitConstant.DevelopSessionGateSessionMirrorRelativePath
$allowlistCursorRel = $script:ToolkitConstant.DevelopSessionGateAllowlistCursorReadmeRelativePath
$allowlistCliRel = $script:ToolkitConstant.DevelopSessionGateAllowlistCliScriptsRelativePath
$fixturePlanRel = $script:ToolkitConstant.PlanLedgerFixturePlanRelativePath

$helperPath = Join-Path $repoRoot ($helperRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$claimPath = Join-Path $repoRoot ($claimRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validatePath = Join-Path $repoRoot ($validateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$sessionContractPath = Join-Path $repoRoot ($sessionContractRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$sessionMirrorPath = Join-Path $repoRoot ($sessionMirrorRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$allowlistCursorPath = Join-Path $repoRoot ($allowlistCursorRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$allowlistCliPath = Join-Path $repoRoot ($allowlistCliRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixturePlanPath = Join-Path $repoRoot ($fixturePlanRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $helperPath)) {
    Write-Fail -TestName 'Should_Pass_When_HelperCreatesSessionAndSetsGate' -Reason ("missing helper {0}" -f $helperRel)
}
if (-not (Test-Path -LiteralPath $claimPath)) {
    Write-Fail -TestName 'Should_Pass_When_ClaimStillRunsWhenGateAlreadyTrue_CT6' -Reason ("missing claim script {0}" -f $claimRel)
}
if (-not (Test-Path -LiteralPath $validatePath)) {
    Write-Fail -TestName 'Should_Pass_When_ValidateSessionGatesSeesTrue' -Reason ("missing validator {0}" -f $validateRel)
}
if (-not (Test-Path -LiteralPath $fixturePlanPath)) {
    Write-Fail -TestName 'Should_Pass_When_HelperCreatesSessionAndSetsGate' -Reason ("missing fixture PLAN {0}" -f $fixturePlanRel)
}

# --- REQ-014: SESSION cites real scripts ---
foreach ($contractPath in @($sessionContractPath, $sessionMirrorPath)) {
    if (-not (Test-Path -LiteralPath $contractPath)) {
        Write-Fail -TestName 'Should_Pass_When_SessionContractCitesCanonicalScripts_REQ014' -Reason ("missing {0}" -f $contractPath)
    }
    $text = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
    foreach ($marker in @(
            'Invoke-DevelopSessionGate.ps1',
            'validate-session-gates.ps1',
            'step_confirmed',
            'idempotent'
        )) {
        if ($text -notmatch [regex]::Escape($marker)) {
            Write-Fail -TestName 'Should_Pass_When_SessionContractCitesCanonicalScripts_REQ014' -Reason ("{0} missing marker '{1}'" -f $contractPath, $marker)
        }
    }
}
Write-Pass -TestName 'Should_Pass_When_SessionContractCitesCanonicalScripts_REQ014'

# --- REQ-013 / RNF-004: allowlist docs cite both scripts; no silent auto-approve; guards intact ---
$allowlistRequiredMarkers = @(
    'Invoke-DevelopSessionGate.ps1',
    'Invoke-PlanLedgerClaim.ps1',
    'opt-in',
    'RNF-004'
)
$allowlistForbiddenMarkers = @(
    'auto-approve all Shell',
    'silent auto-approve'
)
foreach ($pair in @(
        @{ Path = $allowlistCursorPath; Rel = $allowlistCursorRel },
        @{ Path = $allowlistCliPath; Rel = $allowlistCliRel }
    )) {
    if (-not (Test-Path -LiteralPath $pair.Path)) {
        Write-Fail -TestName 'Should_Pass_When_AllowlistDocsCiteBothScripts_REQ013' -Reason ("missing {0}" -f $pair.Rel)
    }
    $allowlistText = Get-Content -LiteralPath $pair.Path -Raw -Encoding UTF8
    foreach ($marker in $allowlistRequiredMarkers) {
        if ($allowlistText -notmatch [regex]::Escape($marker)) {
            Write-Fail -TestName 'Should_Pass_When_AllowlistDocsCiteBothScripts_REQ013' -Reason ("{0} missing marker '{1}'" -f $pair.Rel, $marker)
        }
    }
    foreach ($forbidden in $allowlistForbiddenMarkers) {
        # Docs may mention the forbidden phrase only as a MUST NOT / do not — require negation nearby.
        if ($allowlistText -match [regex]::Escape($forbidden)) {
            $negationOk = ($allowlistText -match ('(?i)(do\s+not|must\s+not|never).{0,80}' + [regex]::Escape($forbidden))) -or
                ($allowlistText -match ([regex]::Escape($forbidden) + '.{0,40}(?i)(do\s+not|must\s+not|never)'))
            if (-not $negationOk) {
                Write-Fail -TestName 'Should_Pass_When_AllowlistDocsCiteBothScripts_REQ013' -Reason ("{0} must not promote '{1}' without negation" -f $pair.Rel, $forbidden)
            }
        }
    }
    if ($allowlistText -notmatch 'path/secrets' -and $allowlistText -notmatch 'GuardCommon' -and $allowlistText -notmatch 'guard-rules') {
        Write-Fail -TestName 'Should_Pass_When_AllowlistDocsCiteBothScripts_REQ013' -Reason ("{0} must cite path/secrets guards intact (RNF-004)" -f $pair.Rel)
    }
}
Write-Pass -TestName 'Should_Pass_When_AllowlistDocsCiteBothScripts_REQ013'

# --- RN04: helper must not embed ledger claim SoT (cite-only of claim script is OK) ---
$helperText = Get-Content -LiteralPath $helperPath -Raw -Encoding UTF8
foreach ($forbidden in @('plan-ledger-claim/v1', 'FileMode]::CreateNew', '.claim.json')) {
    if ($helperText -match [regex]::Escape($forbidden)) {
        Write-Fail -TestName 'Should_Pass_When_HelperDoesNotTouchLedger_RN04' -Reason ("helper must not reimplement ledger (found '{0}')" -f $forbidden)
    }
}
Write-Pass -TestName 'Should_Pass_When_HelperDoesNotTouchLedger_RN04'

$workRoot = Join-Path ([System.IO.Path]::GetTempPath().TrimEnd('\', '/')) ('adt-develop-session-gate-{0}' -f [Guid]::NewGuid().ToString('N'))
$sessionsRoot = Join-Path $workRoot 'sessions'
New-Item -ItemType Directory -Path $sessionsRoot -Force | Out-Null

try {
    $firstOut = & $helperPath -PlanPath $fixturePlanPath -RepoPath $repoRoot -SessionsRoot $sessionsRoot -CurrentStep 4 2>&1 | Out-String
    $firstCode = $LASTEXITCODE
    if ($null -eq $firstCode) { $firstCode = 0 }
    if ($firstCode -ne 0) {
        Write-Fail -TestName 'Should_Pass_When_HelperCreatesSessionAndSetsGate' -Reason ("first ensure exit {0}: {1}" -f $firstCode, $firstOut)
    }
    if ($firstOut -notmatch 'step_confirmed') {
        Write-Fail -TestName 'Should_Pass_When_HelperCreatesSessionAndSetsGate' -Reason 'first ensure output must mention step_confirmed'
    }

    $sessionFiles = @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -Filter 'plan-*.json' -File -ErrorAction SilentlyContinue)
    if ($sessionFiles.Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_HelperCreatesSessionAndSetsGate' -Reason 'expected a develop session JSON under sessions root'
    }
    $sessionFile = $sessionFiles[0]
    $sessionObj = Get-Content -LiteralPath $sessionFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not [bool]$sessionObj.gates.step_confirmed) {
        Write-Fail -TestName 'Should_Pass_When_HelperCreatesSessionAndSetsGate' -Reason 'session file step_confirmed must be true after ensure'
    }
    Write-Pass -TestName 'Should_Pass_When_HelperCreatesSessionAndSetsGate'

    $hashBefore = Get-FileSha256Hex -Path $sessionFile.FullName
    $mtimeBefore = (Get-Item -LiteralPath $sessionFile.FullName).LastWriteTimeUtc
    Start-Sleep -Milliseconds 50

    $secondOut = & $helperPath -PlanPath $fixturePlanPath -RepoPath $repoRoot -SessionsRoot $sessionsRoot -CurrentStep 4 2>&1 | Out-String
    $secondCode = $LASTEXITCODE
    if ($null -eq $secondCode) { $secondCode = 0 }
    if ($secondCode -ne 0) {
        Write-Fail -TestName 'Should_Pass_When_SecondRunIsIdempotent_CT5' -Reason ("second ensure exit {0}: {1}" -f $secondCode, $secondOut)
    }
    if ($secondOut -notmatch [regex]::Escape($script:ToolkitConstant.DevelopSessionGateSkipAlreadyTrue) -and $secondOut -notmatch 'skipped') {
        Write-Fail -TestName 'Should_Pass_When_SecondRunIsIdempotent_CT5' -Reason 'second ensure must report skipped / already-true'
    }

    $hashAfter = Get-FileSha256Hex -Path $sessionFile.FullName
    $mtimeAfter = (Get-Item -LiteralPath $sessionFile.FullName).LastWriteTimeUtc
    if ($hashBefore -ne $hashAfter) {
        Write-Fail -TestName 'Should_Pass_When_SecondRunIsIdempotent_CT5' -Reason 'second ensure must not rewrite session content (hash changed)'
    }
    if ($mtimeAfter -ne $mtimeBefore) {
        Write-Fail -TestName 'Should_Pass_When_SecondRunIsIdempotent_CT5' -Reason 'second ensure must not rewrite session file (mtime changed)'
    }
    Write-Pass -TestName 'Should_Pass_When_SecondRunIsIdempotent_CT5'

    $validateOk = & $validatePath -RepoPath $repoRoot -PlanPath $fixturePlanPath -SessionsRoot $sessionsRoot -RequiredGate step_confirmed 2>&1 | Out-String
    $validateOkCode = $LASTEXITCODE
    if ($null -eq $validateOkCode) { $validateOkCode = 0 }
    if ($validateOkCode -ne 0) {
        Write-Fail -TestName 'Should_Pass_When_ValidateSessionGatesSeesTrue' -Reason ("expected exit 0, got {0}: {1}" -f $validateOkCode, $validateOk)
    }
    Write-Pass -TestName 'Should_Pass_When_ValidateSessionGatesSeesTrue'

    # Blocked path: fresh sessions root with gate false
    $blockedRoot = Join-Path $workRoot 'sessions-blocked'
    New-Item -ItemType Directory -Path $blockedRoot -Force | Out-Null
    $blockedOut = & $helperPath -Action status -PlanPath $fixturePlanPath -RepoPath $repoRoot -SessionsRoot $blockedRoot 2>&1 | Out-String
    $blockedStatusCode = $LASTEXITCODE
    if ($null -eq $blockedStatusCode) { $blockedStatusCode = 0 }
    if ($blockedStatusCode -ne 0) {
        Write-Fail -TestName 'Should_Fail_When_ValidateSessionGatesBlocked' -Reason ("status on missing session should exit 0, got {0}: {1}" -f $blockedStatusCode, $blockedOut)
    }

    $validateBlocked = & $validatePath -RepoPath $repoRoot -PlanPath $fixturePlanPath -SessionsRoot $blockedRoot -RequiredGate step_confirmed 2>&1 | Out-String
    $validateBlockedCode = $LASTEXITCODE
    if ($null -eq $validateBlockedCode) { $validateBlockedCode = 0 }
    $expectedBlocked = [int]$script:ToolkitConstant.SessionGateValidateExitBlocked
    if ($validateBlockedCode -ne $expectedBlocked) {
        Write-Fail -TestName 'Should_Fail_When_ValidateSessionGatesBlocked' -Reason ("expected exit {0}, got {1}: {2}" -f $expectedBlocked, $validateBlockedCode, $validateBlocked)
    }
    Write-Pass -TestName 'Should_Fail_When_ValidateSessionGatesBlocked'

    $ledgerHits = @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -Filter '*.claim.json' -File -ErrorAction SilentlyContinue)
    if ($ledgerHits.Count -gt 0) {
        Write-Fail -TestName 'Should_Pass_When_HelperDoesNotTouchLedger_RN04' -Reason 'helper must not create ledger claim files'
    }
    Write-Pass -TestName 'Should_Pass_When_HelperDoesNotTouchLedger_RN04'

    # CT6: gate already true + claim absent → claim still succeeds; session hash stable
    $ct6Step = 5
    $ct6Holder = 'assert-develop-session-gate-ct6'
    $hashBeforeClaim = Get-FileSha256Hex -Path $sessionFile.FullName
    $claimOut = & $claimPath -Action claim -PlanPath $fixturePlanPath -Step $ct6Step -Holder $ct6Holder -RepoPath $repoRoot -SessionsRoot $sessionsRoot 2>&1 | Out-String
    $claimCode = $LASTEXITCODE
    if ($null -eq $claimCode) { $claimCode = 0 }
    if ($claimCode -ne 0) {
        Write-Fail -TestName 'Should_Pass_When_ClaimStillRunsWhenGateAlreadyTrue_CT6' -Reason ("claim expected exit 0 when gate true and claim absent, got {0}: {1}" -f $claimCode, $claimOut)
    }
    $claimFiles = @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -Filter '*.claim.json' -File -ErrorAction SilentlyContinue)
    if ($claimFiles.Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_ClaimStillRunsWhenGateAlreadyTrue_CT6' -Reason 'claim file not created while step_confirmed already true'
    }
    $hashAfterClaim = Get-FileSha256Hex -Path $sessionFile.FullName
    if ($hashBeforeClaim -ne $hashAfterClaim) {
        Write-Fail -TestName 'Should_Pass_When_ClaimStillRunsWhenGateAlreadyTrue_CT6' -Reason 'claim must not rewrite develop session when gate already true'
    }
    Write-Pass -TestName 'Should_Pass_When_ClaimStillRunsWhenGateAlreadyTrue_CT6'
}
finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Assert-DevelopSessionGate: ALL PASS'
exit 0
