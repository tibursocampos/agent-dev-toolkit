#Requires -Version 5.1
# Tests:
#   Should_Pass_When_InventoryScriptExists
#   Should_Pass_When_InventoryStatusReady
#   Should_Pass_When_InventoryStatusNotReady_NoSources
#   Should_Pass_When_PathEscapeYieldsNotReady
#   Should_Pass_When_SecretNamedSourceSummaryRedacted
#   Should_Fail_When_SiblingPrefixPathRejected
#
# Frente C2 + TS01 PASSO 1: inventory emits hash+summary governance status ready|not-ready.
# Runs against temp copies of fixtures so machine-absolute paths never land in the committed tree.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

# Mirror inventory script local constants (parallel-wave safe; not ToolkitConstants).
$script:StatusReady = 'ready'
$script:StatusNotReady = 'not-ready'
$script:ExitReady = 0
$script:ExitNotReady = 2
$script:ReasonNoSourcesPrefix = 'no_sources:'
$script:ReasonPathEscapePrefix = 'path_escape:'
$script:Sha256HexPattern = '^[a-f0-9]{64}$'

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

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Assert-NoWritesOutsideInventory {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $WorkRoot,
        [Parameter(Mandatory = $true)][string] $WorkBank
    )

    $allowedRoot = [System.IO.Path]::GetFullPath((Join-Path $WorkBank '.inventory'))
    $workFull = [System.IO.Path]::GetFullPath($WorkRoot)
    $files = @(Get-ChildItem -LiteralPath $WorkRoot -Recurse -File -Force -ErrorAction SilentlyContinue)
    foreach ($file in $files) {
        $full = [System.IO.Path]::GetFullPath($file.FullName)
        $relOk = $full.StartsWith($workFull, [System.StringComparison]::OrdinalIgnoreCase)
        if (-not $relOk) {
            Write-Fail -TestName $TestName -Reason ("write escaped work root: {0}" -f $full)
        }

        $name = $file.Name
        if ($name -eq 'README.md') {
            continue
        }

        if (-not $full.StartsWith($allowedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Fail -TestName $TestName -Reason ("unexpected write outside .inventory: {0}" -f $full)
        }
    }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-MemoryBankInventoryPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-MemoryBankInventoryPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$inventoryScriptRel = $script:ToolkitConstant.InvokeMemoryBankInventoryScriptRelativePath
$inventoryScriptPath = Join-Path $repoRoot ($inventoryScriptRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$fixtureRel = $script:ToolkitConstant.MemoryBankInventoryFixtureRelativeDir
$fixtureRoot = Join-Path $repoRoot ($fixtureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $inventoryScriptPath)) {
    Write-Fail -TestName 'Should_Pass_When_InventoryScriptExists' -Reason ("missing inventory script {0}" -f $inventoryScriptRel)
}

Write-Pass -TestName 'Should_Pass_When_InventoryScriptExists'

$fixtureReadme = Join-Path $fixtureRoot 'README.md'

if (-not (Test-Path -LiteralPath $fixtureReadme)) {
    Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason ("missing fixture README at {0}" -f $fixtureRel)
}

# Drop any leftover generated inventory under the committed fixture seed.
$committedInventory = Join-Path $fixtureRoot 'memory-bank\.inventory'
if (Test-Path -LiteralPath $committedInventory) {
    Remove-Item -LiteralPath $committedInventory -Recurse -Force
}

# --- CT1 ready ---
$workRoot = Join-Path $env:TEMP ('adt-memory-bank-inventory-ready-{0}' -f [Guid]::NewGuid().ToString('N'))
$workBank = Join-Path $workRoot 'memory-bank'
$workSources = Join-Path $workBank '.inventory\sources.json'

try {
    New-Item -ItemType Directory -Path $workRoot -Force | Out-Null
    Copy-Item -LiteralPath $fixtureReadme -Destination (Join-Path $workRoot 'README.md') -Force

    & $inventoryScriptPath -RepoPath $workRoot -BankPath $workBank -AllowCreateInventory -Action inventory
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }

    if ($exitCode -ne $script:ExitReady) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason ("expected exit {0}, got {1}" -f $script:ExitReady, $exitCode)
    }

    if (-not (Test-Path -LiteralPath $workSources)) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason 'temp sources.json was not created'
    }

    $inventory = Get-Content -LiteralPath $workSources -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $inventory.sources -or @($inventory.sources).Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason 'temp sources.json must contain at least one source entry'
    }

    if ([string]$inventory.status -ne $script:StatusReady) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason ("expected status ready, got {0}" -f $inventory.status)
    }

    if ([string]::IsNullOrWhiteSpace([string]$inventory.status_reason)) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason 'status_reason must be non-empty'
    }

    if ([string]$inventory.inventory_hash -notmatch $script:Sha256HexPattern) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason 'inventory_hash must be sha256 hex'
    }

    if ([string]::IsNullOrWhiteSpace([string]$inventory.inventory_summary)) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason 'inventory_summary must be non-empty'
    }

    $requiredProps = @('path', 'last_write_utc', 'length', 'hash', 'summary')
    foreach ($entry in @($inventory.sources)) {
        foreach ($prop in $requiredProps) {
            if ($null -eq $entry.$prop -or [string]::IsNullOrWhiteSpace([string]$entry.$prop)) {
                Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason ("source entry missing {0}: {1}" -f $prop, ($entry.path))
            }
        }

        if ([string]$entry.hash -notmatch $script:Sha256HexPattern) {
            Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason ("invalid sha256 hash for {0}" -f $entry.path)
        }
    }

    $readmeEntry = @($inventory.sources | Where-Object { $_.path -eq 'README.md' } | Select-Object -First 1)
    if ($null -eq $readmeEntry) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason 'temp sources.json must index README.md'
    }

    if ([string]$readmeEntry.summary -notmatch 'Memory bank inventory fixture') {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusReady' -Reason 'README summary heuristic did not capture fixture heading'
    }

    Assert-NoWritesOutsideInventory -TestName 'Should_Pass_When_InventoryStatusReady' -WorkRoot $workRoot -WorkBank $workBank
    Write-Pass -TestName 'Should_Pass_When_InventoryStatusReady'
}
finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- CT2 not-ready (no sources) ---
$emptyRoot = Join-Path $env:TEMP ('adt-memory-bank-inventory-empty-{0}' -f [Guid]::NewGuid().ToString('N'))
$emptyBank = Join-Path $emptyRoot 'memory-bank'
$emptySources = Join-Path $emptyBank '.inventory\sources.json'

try {
    New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null

    & $inventoryScriptPath -RepoPath $emptyRoot -BankPath $emptyBank -AllowCreateInventory -Action inventory
    $emptyExit = $LASTEXITCODE
    if ($null -eq $emptyExit) {
        $emptyExit = 0
    }

    if ($emptyExit -ne $script:ExitNotReady) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusNotReady_NoSources' -Reason ("expected exit {0}, got {1}" -f $script:ExitNotReady, $emptyExit)
    }

    if (-not (Test-Path -LiteralPath $emptySources)) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusNotReady_NoSources' -Reason 'sources.json must still be written for not-ready'
    }

    $emptyInventory = Get-Content -LiteralPath $emptySources -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$emptyInventory.status -ne $script:StatusNotReady) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusNotReady_NoSources' -Reason ("expected not-ready, got {0}" -f $emptyInventory.status)
    }

    if ([string]$emptyInventory.status_reason -notlike ($script:ReasonNoSourcesPrefix + '*')) {
        Write-Fail -TestName 'Should_Pass_When_InventoryStatusNotReady_NoSources' -Reason ("unexpected reason: {0}" -f $emptyInventory.status_reason)
    }

    $emptyFiles = @(Get-ChildItem -LiteralPath $emptyRoot -Recurse -File -Force)
    foreach ($file in $emptyFiles) {
        $full = [System.IO.Path]::GetFullPath($file.FullName)
        $allowed = [System.IO.Path]::GetFullPath((Join-Path $emptyBank '.inventory'))
        if (-not $full.StartsWith($allowed, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Fail -TestName 'Should_Pass_When_InventoryStatusNotReady_NoSources' -Reason ("write outside inventory: {0}" -f $full)
        }
    }

    Write-Pass -TestName 'Should_Pass_When_InventoryStatusNotReady_NoSources'
}
finally {
    if (Test-Path -LiteralPath $emptyRoot) {
        Remove-Item -LiteralPath $emptyRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- RNF-004 path escape → not-ready ---
$escapeRoot = Join-Path $env:TEMP ('adt-memory-bank-inventory-escape-{0}' -f [Guid]::NewGuid().ToString('N'))
$escapeBank = Join-Path $escapeRoot 'memory-bank'
$escapeInventoryDir = Join-Path $escapeBank '.inventory'
$escapeSources = Join-Path $escapeInventoryDir 'sources.json'
$escapeMarker = Join-Path (Split-Path -Parent $escapeRoot) ('adt-escape-marker-{0}.txt' -f [Guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path $escapeRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $escapeInventoryDir -Force | Out-Null
    'fixture' | Set-Content -LiteralPath (Join-Path $escapeRoot 'README.md') -Encoding UTF8
    'secret' | Set-Content -LiteralPath $escapeMarker -Encoding UTF8

    $seed = [ordered]@{
        schema_version = 3
        sources        = @(
            [ordered]@{ path = '../' + [System.IO.Path]::GetFileName($escapeMarker) }
        )
    }
    [System.IO.File]::WriteAllText($escapeSources, ($seed | ConvertTo-Json -Depth 6), (Get-Utf8NoBomEncoding))

    & $inventoryScriptPath -RepoPath $escapeRoot -BankPath $escapeBank -AllowCreateInventory -Action inventory
    $escapeExit = $LASTEXITCODE
    if ($null -eq $escapeExit) {
        $escapeExit = 0
    }

    if ($escapeExit -ne $script:ExitNotReady) {
        Write-Fail -TestName 'Should_Pass_When_PathEscapeYieldsNotReady' -Reason ("expected exit {0}, got {1}" -f $script:ExitNotReady, $escapeExit)
    }

    $escapeInventory = Get-Content -LiteralPath $escapeSources -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$escapeInventory.status -ne $script:StatusNotReady) {
        Write-Fail -TestName 'Should_Pass_When_PathEscapeYieldsNotReady' -Reason ("expected not-ready, got {0}" -f $escapeInventory.status)
    }

    if ([string]$escapeInventory.status_reason -notlike ($script:ReasonPathEscapePrefix + '*')) {
        Write-Fail -TestName 'Should_Pass_When_PathEscapeYieldsNotReady' -Reason ("expected path_escape reason, got {0}" -f $escapeInventory.status_reason)
    }

    # Seeded escape path must not be indexed; README may still be discovered → if only escape was seeded and README exists, ready could win unless escape takes priority.
    # Escape hits are evaluated before empty/ready — status must remain not-ready.
    $escapedIndexed = @($escapeInventory.sources | Where-Object { [string]$_.path -match '\.\.' })
    if ($escapedIndexed.Count -gt 0) {
        Write-Fail -TestName 'Should_Pass_When_PathEscapeYieldsNotReady' -Reason 'escaped relative path must not appear in sources'
    }

    if (Test-Path -LiteralPath $escapeMarker) {
        # Marker file outside repo must remain untouched (inventory never writes there).
        $markerText = Get-Content -LiteralPath $escapeMarker -Raw -Encoding UTF8
        if ($markerText -notmatch 'secret') {
            Write-Fail -TestName 'Should_Pass_When_PathEscapeYieldsNotReady' -Reason 'escape marker outside repo was modified'
        }
    }

    Write-Pass -TestName 'Should_Pass_When_PathEscapeYieldsNotReady'
}
finally {
    if (Test-Path -LiteralPath $escapeRoot) {
        Remove-Item -LiteralPath $escapeRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $escapeMarker) {
        Remove-Item -LiteralPath $escapeMarker -Force -ErrorAction SilentlyContinue
    }
}

# --- Secret-named source: summary must not echo file contents ---
$secretRoot = Join-Path $env:TEMP ('adt-memory-bank-inventory-secret-{0}' -f [Guid]::NewGuid().ToString('N'))
$secretBank = Join-Path $secretRoot 'memory-bank'
$secretInventoryDir = Join-Path $secretBank '.inventory'
$secretSources = Join-Path $secretInventoryDir 'sources.json'
$secretPayload = 'API_KEY=supersecret-must-not-land-in-summary'
$script:ExpectedSummaryRedacted = '[redacted: secret-named source]'

try {
    New-Item -ItemType Directory -Path $secretInventoryDir -Force | Out-Null
    'fixture' | Set-Content -LiteralPath (Join-Path $secretRoot 'README.md') -Encoding UTF8
    $secretPayload | Set-Content -LiteralPath (Join-Path $secretRoot '.env') -Encoding UTF8

    $seed = [ordered]@{
        schema_version = 3
        sources        = @(
            [ordered]@{ path = 'README.md' },
            [ordered]@{ path = '.env' }
        )
    }
    [System.IO.File]::WriteAllText($secretSources, ($seed | ConvertTo-Json -Depth 6), (Get-Utf8NoBomEncoding))

    & $inventoryScriptPath -RepoPath $secretRoot -BankPath $secretBank -AllowCreateInventory -Action inventory
    $secretExit = $LASTEXITCODE
    if ($null -eq $secretExit) {
        $secretExit = 0
    }

    if ($secretExit -ne $script:ExitReady) {
        Write-Fail -TestName 'Should_Pass_When_SecretNamedSourceSummaryRedacted' -Reason ("expected exit {0}, got {1}" -f $script:ExitReady, $secretExit)
    }

    $secretInventory = Get-Content -LiteralPath $secretSources -Raw -Encoding UTF8 | ConvertFrom-Json
    $envEntry = @($secretInventory.sources | Where-Object { $_.path -eq '.env' } | Select-Object -First 1)
    if ($null -eq $envEntry) {
        Write-Fail -TestName 'Should_Pass_When_SecretNamedSourceSummaryRedacted' -Reason '.env must remain indexed (hash ok; summary redacted)'
    }

    if ([string]$envEntry.summary -ne $script:ExpectedSummaryRedacted) {
        Write-Fail -TestName 'Should_Pass_When_SecretNamedSourceSummaryRedacted' -Reason ("expected redacted summary, got '{0}'" -f $envEntry.summary)
    }

    if ([string]$envEntry.summary -match 'supersecret' -or [string]$envEntry.summary -match 'API_KEY') {
        Write-Fail -TestName 'Should_Pass_When_SecretNamedSourceSummaryRedacted' -Reason 'summary leaked secret payload'
    }

    $envAfter = Get-Content -LiteralPath (Join-Path $secretRoot '.env') -Raw -Encoding UTF8
    if ($envAfter.Trim() -ne $secretPayload) {
        Write-Fail -TestName 'Should_Pass_When_SecretNamedSourceSummaryRedacted' -Reason 'inventory must not modify secret-named source file'
    }

    Write-Pass -TestName 'Should_Pass_When_SecretNamedSourceSummaryRedacted'
}
finally {
    if (Test-Path -LiteralPath $secretRoot) {
        Remove-Item -LiteralPath $secretRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- RNF-004 sibling-prefix (repo vs repo-evil) must not count as under ---
$inventorySource = Get-Content -LiteralPath $inventoryScriptPath -Raw -Encoding UTF8
if ($inventorySource -notmatch 'Test-IsPathUnderOrEqual') {
    Write-Fail -TestName 'Should_Fail_When_SiblingPrefixPathRejected' -Reason 'inventory must reuse Test-IsPathUnderOrEqual for path boundaries'
}

$siblingParent = Join-Path $env:TEMP ('adt-memory-bank-inventory-sibling-{0}' -f [Guid]::NewGuid().ToString('N'))
$siblingRepo = Join-Path $siblingParent 'repo'
$siblingEvil = Join-Path $siblingParent 'repo-evil'
$siblingBank = Join-Path $siblingRepo 'memory-bank'
$siblingSources = Join-Path $siblingBank '.inventory\sources.json'
$evilReadme = Join-Path $siblingEvil 'README.md'

try {
    New-Item -ItemType Directory -Path $siblingRepo, $siblingEvil -Force | Out-Null
    'repo-only' | Set-Content -LiteralPath (Join-Path $siblingRepo 'README.md') -Encoding UTF8
    'evil-secret-marker-should-not-index' | Set-Content -LiteralPath $evilReadme -Encoding UTF8

    if (-not (Get-Command -Name Test-IsPathUnderOrEqual -ErrorAction SilentlyContinue)) {
        . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    }

    if (Test-IsPathUnderOrEqual -ChildPath $siblingEvil -ParentPath $siblingRepo) {
        Write-Fail -TestName 'Should_Fail_When_SiblingPrefixPathRejected' -Reason 'Test-IsPathUnderOrEqual must reject repo-evil under repo'
    }

    & $inventoryScriptPath -RepoPath $siblingRepo -BankPath $siblingBank -AllowCreateInventory -Action inventory
    $siblingExit = $LASTEXITCODE
    if ($null -eq $siblingExit) {
        $siblingExit = 0
    }

    if ($siblingExit -ne $script:ExitReady) {
        Write-Fail -TestName 'Should_Fail_When_SiblingPrefixPathRejected' -Reason ("expected exit {0}, got {1}" -f $script:ExitReady, $siblingExit)
    }

    $siblingInventory = Get-Content -LiteralPath $siblingSources -Raw -Encoding UTF8 | ConvertFrom-Json
    $evilIndexed = @($siblingInventory.sources | Where-Object {
            ([string]$_.path -match '(?i)repo-evil') -or
            ([string]$_.summary -match 'evil-secret-marker-should-not-index')
        })
    if ($evilIndexed.Count -gt 0) {
        Write-Fail -TestName 'Should_Fail_When_SiblingPrefixPathRejected' -Reason 'sibling repo-evil content must not be indexed under repo'
    }

    Write-Pass -TestName 'Should_Fail_When_SiblingPrefixPathRejected'
}
finally {
    if (Test-Path -LiteralPath $siblingParent) {
        Remove-Item -LiteralPath $siblingParent -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Assert-MemoryBankInventory: ALL PASS'
exit 0
