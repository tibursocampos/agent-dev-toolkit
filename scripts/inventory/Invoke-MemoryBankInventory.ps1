#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only consumer-repo scan; writes memory-bank/.inventory/ evidence index.

.DESCRIPTION
  Scans -RepoPath (consumer workspace) and updates -BankPath/.inventory/sources.json
  with path, last_write_utc, length, sha256 hash, and a 1-2 line summary heuristic.
  Optionally refreshes gaps.md stubs (preserves BLOCKING lines) and appends refresh-history.jsonl.

  Writes ONLY under <bank_root>/.inventory/ — never modifies application source files.

.PARAMETER RepoPath
  Consumer repository root to scan (defaults to toolkit repo when invoked from toolkit).

.PARAMETER BankPath
  Memory bank root (defaults to Join-Path RepoPath 'memory-bank').

.PARAMETER AllowCreateInventory
  Required when .inventory/ does not yet exist under BankPath.

.PARAMETER Action
  Logged in refresh-history.jsonl (inventory | refresh | refresh-light). Default: inventory.

.EXAMPLE
  .\scripts\inventory\Invoke-MemoryBankInventory.ps1 -RepoPath . -BankPath .\memory-bank -AllowCreateInventory
#>
[CmdletBinding()]
param(
    [string] $RepoPath,
    [string] $BankPath,
    [switch] $AllowCreateInventory,
    [ValidateSet('inventory', 'refresh', 'refresh-light')]
    [string] $Action = 'inventory'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'ToolkitConstants.ps1')

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Convert-ToInventoryRelativePath {
    param(
        [Parameter(Mandatory = $true)][string] $FullPath,
        [Parameter(Mandatory = $true)][string] $RootPath
    )

    $root = (Resolve-Path -LiteralPath $RootPath).Path.TrimEnd('\', '/')
    $full = (Resolve-Path -LiteralPath $FullPath).Path
    if (-not $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ("Path escapes repo root: {0}" -f $FullPath)
    }

    $relative = $full.Substring($root.Length).TrimStart('\', '/')
    return ($relative -replace '\\', '/')
}

function Test-PathUnderOrEqual {
    param(
        [Parameter(Mandatory = $true)][string] $CandidatePath,
        [Parameter(Mandatory = $true)][string] $RootPath
    )

    $candidate = (Resolve-Path -LiteralPath $CandidatePath).Path.TrimEnd('\', '/')
    $root = (Resolve-Path -LiteralPath $RootPath).Path.TrimEnd('\', '/')
    return ($candidate.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase))
}

function Get-FileSha256Hex {
    param([Parameter(Mandatory = $true)][string] $LiteralPath)

    $hash = Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256
    return $hash.Hash.ToLowerInvariant()
}

function Get-FileSummaryHeuristic {
    param([Parameter(Mandatory = $true)][string] $LiteralPath)

    $maxChars = 240
    try {
        $lines = @(Get-Content -LiteralPath $LiteralPath -Encoding UTF8 -ErrorAction Stop)
    }
    catch {
        return ''
    }

    $heading = $null
    $firstNonEmpty = $null
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }

        if ($null -eq $firstNonEmpty) {
            $firstNonEmpty = $trimmed
        }

        if ($trimmed -match '^(#{1,6})\s+(.+)$') {
            $heading = $Matches[2].Trim()
            break
        }
    }

    $summary = if ($heading) { $heading } else { $firstNonEmpty }
    if ([string]::IsNullOrWhiteSpace($summary)) {
        return ''
    }

    $summary = ($summary -replace '\s+', ' ').Trim()
    if ($summary.Length -gt $maxChars) {
        return ($summary.Substring(0, $maxChars).TrimEnd() + '…')
    }

    return $summary
}

function Add-InventoryRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Set,
        [AllowEmptyString()][string] $RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return
    }

    $normalized = ($RelativePath -replace '\\', '/').TrimStart('/')
    if ($normalized -match '(^|/)\.\.(/|$)') {
        return
    }

    [void]$Set.Add($normalized)
}

function Add-InventoryPathIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Set,
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )

    $full = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        Add-InventoryRelativePath -Set $Set -RelativePath $RelativePath
    }
}

function Get-PathsFromExistingInventory {
    param(
        [Parameter(Mandatory = $true)][object] $InventoryObject
    )

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    if ($null -ne $InventoryObject.sources) {
        foreach ($entry in @($InventoryObject.sources)) {
            if ($null -ne $entry.path) {
                Add-InventoryRelativePath -Set $paths -RelativePath ([string]$entry.path)
            }
        }
    }

    foreach ($category in @('lockfiles', 'manifests', 'docs', 'entry_points')) {
        if (-not ($InventoryObject.PSObject.Properties.Name -contains $category)) {
            continue
        }

        $bucket = $InventoryObject.$category
        if ($null -eq $bucket) {
            continue
        }

        foreach ($entry in @($bucket)) {
            if ($entry -is [string]) {
                Add-InventoryRelativePath -Set $paths -RelativePath $entry
            }
            elseif ($null -ne $entry.path) {
                Add-InventoryRelativePath -Set $paths -RelativePath ([string]$entry.path)
            }
        }
    }

    return @($paths | Sort-Object)
}

function Get-DefaultInventoryRelativePaths {
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $rootNames = @(
        'README.md', 'SECURITY.md', 'CONTRIBUTING.md', 'LICENSE', '.gitignore', 'AGENTS.md', 'CLAUDE.md'
    )
    foreach ($name in $rootNames) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $name
    }

    $lockfileNames = @(
        'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'bun.lockb',
        'Directory.Packages.props', 'packages.lock.json', 'Cargo.lock', 'poetry.lock',
        'uv.lock', 'go.sum', 'Gemfile.lock', 'composer.lock'
    )
    foreach ($name in $lockfileNames) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $name
    }

    $manifestNames = @(
        'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'Gemfile', 'composer.json'
    )
    foreach ($name in $manifestNames) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $name
    }

    Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath 'adapters/registry.json'
    foreach ($scriptRel in @(
            'scripts/toolkit.ps1',
            'scripts/sync-agent.ps1',
            'scripts/validate-agent.ps1',
            'scripts/validation/validate-core.ps1'
        )) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $scriptRel
    }

    Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath 'core/skills/_shared/agents/SPAWN.md'
    Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath 'core/router/AGENTS.md'

    $globRoots = @(
        @{ Root = $RepoRoot; Pattern = '*.sln' },
        @{ Root = Join-Path $RepoRoot 'scripts/_lib'; Pattern = '*.ps1' },
        @{ Root = Join-Path $RepoRoot 'docs'; Pattern = '*.md' },
        @{ Root = Join-Path $RepoRoot '.github/workflows'; Pattern = '*.yml' },
        @{ Root = Join-Path $RepoRoot 'adapters'; Pattern = '*Adapter.ps1' },
        @{ Root = Join-Path $RepoRoot 'adapters'; Pattern = 'Publish-*.ps1' },
        @{ Root = Join-Path $RepoRoot 'adapters'; Pattern = 'Uninstall-*.ps1' }
    )

    foreach ($spec in $globRoots) {
        if (-not (Test-Path -LiteralPath $spec.Root)) {
            continue
        }

        $matches = @(Get-ChildItem -LiteralPath $spec.Root -Filter $spec.Pattern -File -Recurse -ErrorAction SilentlyContinue)
        foreach ($item in $matches) {
            Add-InventoryRelativePath -Set $paths -RelativePath (Convert-ToInventoryRelativePath -FullPath $item.FullName -RootPath $RepoRoot)
        }
    }

    return @($paths | Sort-Object)
}

function Get-StackHintsFromPaths {
    param(
        [Parameter(Mandatory = $true)][string[]] $RelativePaths
    )

    $hints = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($path in $RelativePaths) {
        $lower = $path.ToLowerInvariant()
        if ($lower -match '\.ps1$') { [void]$hints.Add('powershell') }
        if ($lower -match '\.md$') { [void]$hints.Add('markdown') }
        if ($lower -match 'package\.json|package-lock\.json|pnpm-lock|yarn\.lock|bun\.lockb') { [void]$hints.Add('node') }
        if ($lower -match '\.sln$|\.csproj$|directory\.packages\.props|packages\.lock\.json') { [void]$hints.Add('dotnet') }
        if ($lower -match 'pyproject\.toml|poetry\.lock|uv\.lock') { [void]$hints.Add('python') }
        if ($lower -match 'cargo\.(toml|lock)') { [void]$hints.Add('rust') }
        if ($lower -match 'go\.(mod|sum)') { [void]$hints.Add('go') }
        if ($lower -match 'gemfile|composer\.') { [void]$hints.Add('ruby') }
    }

    return @($hints | Sort-Object)
}

function Test-OpenApiSignal {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string[]] $RelativePaths
    )

    foreach ($path in $RelativePaths) {
        if ($path -match '(?i)(openapi|swagger).*\.(ya?ml|json)$') {
            return $true
        }
    }

    $searchRoots = @(
        (Join-Path $RepoRoot 'docs'),
        (Join-Path $RepoRoot 'api'),
        $RepoRoot
    )
    foreach ($root in $searchRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $hits = @(Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '(?i)^(openapi|swagger).*\.(ya?ml|json)$' })
        if ($hits.Count -gt 0) {
            return $true
        }
    }

    return $false
}

function Test-DatabaseMigrationSignal {
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $patterns = @('**/Migrations/*.cs', '**/migrations/*.sql', '**/prisma/schema.prisma')
    foreach ($pattern in $patterns) {
        $hits = @(Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Filter '*' -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -match '(?i)(\\|/)Migrations(\\|/).+\.cs$' -or
                $_.FullName -match '(?i)(\\|/)migrations(\\|/).+\.sql$' -or
                $_.Name -eq 'schema.prisma'
            })
        if ($hits.Count -gt 0) {
            return $true
        }
    }

    return $false
}

function Test-UiKitSignal {
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $pkgPath = Join-Path $RepoRoot 'package.json'
    if (-not (Test-Path -LiteralPath $pkgPath)) {
        return $false
    }

    try {
        $pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $depNames = @()
        foreach ($prop in @('dependencies', 'devDependencies')) {
            $bucket = $pkg.$prop
            if ($null -ne $bucket) {
                $depNames += @($bucket.PSObject.Properties.Name)
            }
        }

        $uiMarkers = @('react', '@mui/material', 'antd', '@angular/core', 'vue', 'storybook', 'tailwindcss')
        foreach ($marker in $uiMarkers) {
            if ($depNames -contains $marker) {
                return $true
            }
        }
    }
    catch {
        return $false
    }

    return $false
}

function Get-PreservedBlockingLines {
    param([string] $GapsPath)

    if (-not (Test-Path -LiteralPath $GapsPath)) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $GapsPath -Encoding UTF8)
    return @($lines | Where-Object { $_ -match '^\s*-\s+\[[ xX]\]\s+BLOCKING:' })
}

function Update-GapsMarkdownStubs {
    param(
        [Parameter(Mandatory = $true)][string] $GapsPath,
        [Parameter(Mandatory = $true)][bool] $OpenApiDetected,
        [Parameter(Mandatory = $true)][bool] $DatabaseDetected,
        [Parameter(Mandatory = $true)][bool] $UiKitDetected,
        [Parameter(Mandatory = $true)][string[]] $StackHints,
        [string[]] $PreservedBlockingLines = @()
    )

    $openapiHint = if ($OpenApiDetected) { 'yes' } else { 'no' }
    $dbHint = if ($DatabaseDetected) { 'yes' } else { 'no' }
    $uiHint = if ($UiKitDetected) { 'yes' } else { 'no' }
    $stackText = if ($StackHints.Count -gt 0) { ($StackHints -join ', ') } else { 'unknown' }

    $blockingSection = if ($PreservedBlockingLines.Count -gt 0) {
        ($PreservedBlockingLines -join "`n")
    }
    else {
        '_(none)_'
    }

    $content = @"
# Inventory gaps

Unchecked items mean the bank is incomplete for that topic.
Use ``- [ ] BLOCKING:`` only when Step 0 must treat the bank as stale/incomplete.

## MVP coverage

- [ ] project-context filled from evidence
- [ ] tech-stack.json matches detected manifests ($stackText)
- [ ] architecture entry points verified
- [ ] domain-knowledge has at least one evidenced area (or N/A noted)
- [ ] conventions aligned with AGENTS/README
- [ ] known-risks reviewed once

## Phase 2 / rich contracts

When Prior/cited content already has DDL, OpenAPI, or a UI component map, the matching file is **BLOCKING** (write/promote it, or ``- [ ] BLOCKING:`` until written).

- [ ] api-contracts (OpenAPI/Swagger detected: $openapiHint)
- [ ] database-schema (EF/Prisma/SQL migrations detected: $dbHint)
- [ ] component-catalog (design system / large UI kit detected: $uiHint)

## Blocking

$blockingSection

## Notes

Regenerated by Invoke-MemoryBankInventory.ps1. Preserve human BLOCKING flags across refreshes.
"@

    [System.IO.File]::WriteAllText($GapsPath, $content, (Get-Utf8NoBomEncoding))
}

function Add-RefreshHistoryEntry {
    param(
        [Parameter(Mandatory = $true)][string] $HistoryPath,
        [Parameter(Mandatory = $true)][string] $RepoName,
        [Parameter(Mandatory = $true)][string] $HistoryAction,
        [Parameter(Mandatory = $true)][string[]] $Hints
    )

    $entry = [ordered]@{
        at     = (Get-Date).ToUniversalTime().ToString('o')
        action = $HistoryAction
        repo   = $RepoName
        hints  = @($Hints)
    } | ConvertTo-Json -Compress

    Add-Content -LiteralPath $HistoryPath -Value $entry -Encoding UTF8
}

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    $RepoPath = Get-ToolkitRepoRoot -FromPath $scriptDir
}

if (-not (Test-Path -LiteralPath $RepoPath)) {
    throw ("RepoPath not found: {0}" -f $RepoPath)
}

$repoRoot = (Resolve-Path -LiteralPath $RepoPath).Path
$repoName = Split-Path -Leaf $repoRoot

if ([string]::IsNullOrWhiteSpace($BankPath)) {
    $BankPath = Join-Path $repoRoot 'memory-bank'
}

if (-not (Test-Path -LiteralPath $BankPath)) {
    if (-not $AllowCreateInventory) {
        throw ("BankPath not found: {0}. Pass -AllowCreateInventory to create .inventory/." -f $BankPath)
    }

    New-Item -ItemType Directory -Path $BankPath -Force | Out-Null
}

$bankRoot = (Resolve-Path -LiteralPath $BankPath).Path
$inventoryDir = Join-Path $bankRoot '.inventory'
$sourcesPath = Join-Path $inventoryDir 'sources.json'
$gapsPath = Join-Path $inventoryDir 'gaps.md'
$historyPath = Join-Path $inventoryDir 'refresh-history.jsonl'

if (-not (Test-Path -LiteralPath $inventoryDir)) {
    if (-not $AllowCreateInventory) {
        throw ("Inventory directory missing: {0}. Pass -AllowCreateInventory." -f $inventoryDir)
    }

    New-Item -ItemType Directory -Path $inventoryDir -Force | Out-Null
}

$existingInventory = $null
if (Test-Path -LiteralPath $sourcesPath) {
    try {
        $existingInventory = Get-Content -LiteralPath $sourcesPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        Write-Warning ("Existing sources.json could not be parsed; using default discovery only: {0}" -f $_.Exception.Message)
    }
}

$relativePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
if ($null -ne $existingInventory) {
    foreach ($path in @(Get-PathsFromExistingInventory -InventoryObject $existingInventory)) {
        [void]$relativePaths.Add($path)
    }
}

foreach ($path in @(Get-DefaultInventoryRelativePaths -RepoRoot $repoRoot)) {
    [void]$relativePaths.Add($path)
}

$sourceEntries = [System.Collections.Generic.List[object]]::new()
foreach ($relativePath in @($relativePaths | Sort-Object)) {
    $fullPath = Join-Path $repoRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $item = Get-Item -LiteralPath $fullPath
    $sourceEntries.Add([ordered]@{
            path           = ($relativePath -replace '\\', '/')
            last_write_utc = $item.LastWriteTimeUtc.ToString('o')
            length         = $item.Length
            hash           = (Get-FileSha256Hex -LiteralPath $fullPath)
            summary        = (Get-FileSummaryHeuristic -LiteralPath $fullPath)
        })
}

$sortedPaths = @($sourceEntries | ForEach-Object { $_.path })
$stackHints = Get-StackHintsFromPaths -RelativePaths $sortedPaths

$skillsRoot = Join-Path $repoRoot 'core/skills'
$skillCount = 0
if (Test-Path -LiteralPath $skillsRoot) {
    $skillCount = @(Get-ChildItem -LiteralPath $skillsRoot -Directory |
        Where-Object { $_.Name -ne '_shared' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')) }).Count
}

$validationRoot = Join-Path $repoRoot 'scripts/validation'
$assertScriptCount = 0
if (Test-Path -LiteralPath $validationRoot) {
    $assertScriptCount = @(Get-ChildItem -LiteralPath $validationRoot -Filter 'Assert-*.ps1' -File).Count
}

$staleDays = 90
if ($null -ne $existingInventory -and ($existingInventory.PSObject.Properties.Name -contains 'stale_days')) {
    $staleDays = [int]$existingInventory.stale_days
}

$payload = [ordered]@{
    schema_version      = 2
    repo                = $repoName
    repo_path           = $repoRoot
    bank_path           = $bankRoot
    generated_at        = (Get-Date).ToUniversalTime().ToString('o')
    stale_days          = $staleDays
    stack_hints         = @($stackHints)
    skill_count         = $skillCount
    assert_script_count = $assertScriptCount
    sources             = @($sourceEntries)
}

$json = ($payload | ConvertTo-Json -Depth 6)
[System.IO.File]::WriteAllText($sourcesPath, $json, (Get-Utf8NoBomEncoding))

$openApiDetected = Test-OpenApiSignal -RepoRoot $repoRoot -RelativePaths $sortedPaths
$dbDetected = Test-DatabaseMigrationSignal -RepoRoot $repoRoot
$uiDetected = Test-UiKitSignal -RepoRoot $repoRoot
$preservedBlocking = @(Get-PreservedBlockingLines -GapsPath $gapsPath)

Update-GapsMarkdownStubs `
    -GapsPath $gapsPath `
    -OpenApiDetected $openApiDetected `
    -DatabaseDetected $dbDetected `
    -UiKitDetected $uiDetected `
    -StackHints $stackHints `
    -PreservedBlockingLines $preservedBlocking

Add-RefreshHistoryEntry -HistoryPath $historyPath -RepoName $repoName -HistoryAction $Action -Hints $stackHints

Write-Host ("Invoke-MemoryBankInventory: wrote {0} source(s) -> {1}" -f $sourceEntries.Count, $sourcesPath)
exit 0
