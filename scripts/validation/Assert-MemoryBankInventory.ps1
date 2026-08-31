#Requires -Version 5.1
# Tests:
#   Should_Pass_When_InventoryScriptExists
#   Should_Pass_When_InventoryRunsOnFixture
#
# Frente C2: memory-bank inventory script exists and produces enriched sources.json.
# Runs against a temp copy of the fixture so machine-absolute paths never land in the committed tree.
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
    Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason ("missing fixture README at {0}" -f $fixtureRel)
}

# Drop any leftover generated inventory under the committed fixture seed.
$committedInventory = Join-Path $fixtureRoot 'memory-bank\.inventory'
if (Test-Path -LiteralPath $committedInventory) {
    Remove-Item -LiteralPath $committedInventory -Recurse -Force
}

$workRoot = Join-Path $env:TEMP ('adt-memory-bank-inventory-{0}' -f [Guid]::NewGuid().ToString('N'))
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

    if ($exitCode -ne 0) {
        Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason ("Invoke-MemoryBankInventory.ps1 exited {0}" -f $exitCode)
    }

    if (-not (Test-Path -LiteralPath $workSources)) {
        Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason 'temp sources.json was not created'
    }

    $inventory = Get-Content -LiteralPath $workSources -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $inventory.sources -or @($inventory.sources).Count -lt 1) {
        Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason 'temp sources.json must contain at least one source entry'
    }

    $requiredProps = @('path', 'last_write_utc', 'length', 'hash', 'summary')
    foreach ($entry in @($inventory.sources)) {
        foreach ($prop in $requiredProps) {
            if ($null -eq $entry.$prop -or [string]::IsNullOrWhiteSpace([string]$entry.$prop)) {
                Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason ("source entry missing {0}: {1}" -f $prop, ($entry.path))
            }
        }

        if ([string]$entry.hash -notmatch '^[a-f0-9]{64}$') {
            Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason ("invalid sha256 hash for {0}" -f $entry.path)
        }
    }

    $readmeEntry = @($inventory.sources | Where-Object { $_.path -eq 'README.md' } | Select-Object -First 1)
    if ($null -eq $readmeEntry) {
        Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason 'temp sources.json must index README.md'
    }

    if ([string]$readmeEntry.summary -notmatch 'Memory bank inventory fixture') {
        Write-Fail -TestName 'Should_Pass_When_InventoryRunsOnFixture' -Reason 'README summary heuristic did not capture fixture heading'
    }

    Write-Pass -TestName 'Should_Pass_When_InventoryRunsOnFixture'
    Write-Host 'Assert-MemoryBankInventory: ALL PASS'
    exit 0
}
finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
