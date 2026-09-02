#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only consumer-repo scan; writes memory-bank/.inventory/ evidence index with governance status.

.DESCRIPTION
  Scans -RepoPath (consumer workspace) and updates -BankPath/.inventory/sources.json
  with path, last_write_utc, length, sha256 hash, and a 1-2 line summary heuristic.
  Emits inventory-level inventory_hash, inventory_summary, and status ready|not-ready + status_reason.
  Exit 0 = ready; exit 2 = not-ready (TE01). Path escape / no sources / incomplete hash => not-ready.
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
if (-not (Get-Command -Name Test-IsPathUnderOrEqual -ErrorAction SilentlyContinue)) {
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
}

# Local governance constants (PASSO 1 / REQ-001) — keep out of shared ToolkitConstants during parallel waves.
$script:InventorySchemaVersion = 3
$script:InventoryStatusReady = 'ready'
$script:InventoryStatusNotReady = 'not-ready'
$script:InventoryExitReady = 0
$script:InventoryExitNotReady = 2
$script:InventoryReasonReady = 'sources indexed with hash and summary'
$script:InventoryReasonNoSources = 'no_sources: no readable sources under repo root'
$script:InventoryReasonPathEscape = 'path_escape: source path escapes repo root'
$script:InventoryReasonIncompleteHash = 'incomplete_hash: one or more sources missing sha256'
$script:InventoryReasonInvalidRoot = 'invalid_root: repo or bank root is missing or not a directory'
$script:Sha256HexPattern = '^[a-f0-9]{64}$'
$script:InventorySummaryRedacted = '[redacted: secret-named source]'
# Leaf / relative-path patterns — skip first-line heuristic so secrets never land in sources.json summary.
$script:InventorySecretFileNamePatterns = @(
    '(?i)^\.env$',
    '(?i)^\.env\..+$',
    '(?i)^credentials\.json$',
    '(?i)^secrets\.json$',
    '(?i)^.*secret.*$',
    '(?i)^id_rsa$',
    '(?i)^id_dsa$',
    '(?i)^id_ed25519$',
    '(?i)^.*\.pem$',
    '(?i)^.*\.key$'
)

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Convert-ToInventoryRelativePath {
    param(
        [Parameter(Mandatory = $true)][string] $FullPath,
        [Parameter(Mandatory = $true)][string] $RootPath
    )

    if (-not (Test-IsPathUnderOrEqual -ChildPath $FullPath -ParentPath $RootPath)) {
        throw ("Path escapes repo root: {0}" -f $FullPath)
    }

    $root = (Get-NormalizedFullPath -Path $RootPath).TrimEnd('\', '/')
    $full = Get-NormalizedFullPath -Path $FullPath
    $relative = $full.Substring($root.Length).TrimStart('\', '/')
    return ($relative -replace '\\', '/')
}

function Test-PathUnderOrEqual {
    param(
        [Parameter(Mandatory = $true)][string] $CandidatePath,
        [Parameter(Mandatory = $true)][string] $RootPath
    )

    return (Test-IsPathUnderOrEqual -ChildPath $CandidatePath -ParentPath $RootPath)
}

function Get-FileSha256Hex {
    param([Parameter(Mandatory = $true)][string] $LiteralPath)

    $hash = Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256
    return $hash.Hash.ToLowerInvariant()
}

function Test-IsSecretNamedInventorySource {
    param(
        [Parameter(Mandatory = $true)][string] $LiteralPath,
        [string] $RelativePath = ''
    )

    $leaf = [System.IO.Path]::GetFileName($LiteralPath)
    foreach ($pattern in $script:InventorySecretFileNamePatterns) {
        if ($leaf -match $pattern) {
            return $true
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($RelativePath)) {
        $normalized = ($RelativePath -replace '\\', '/').TrimStart('/')
        $segments = @($normalized.Split('/') | Where-Object { $_ -ne '' })
        foreach ($segment in $segments) {
            foreach ($pattern in $script:InventorySecretFileNamePatterns) {
                if ($segment -match $pattern) {
                    return $true
                }
            }
        }
    }

    return $false
}

function Get-FileSummaryHeuristic {
    param(
        [Parameter(Mandatory = $true)][string] $LiteralPath,
        [string] $RelativePath = ''
    )

    if (Test-IsSecretNamedInventorySource -LiteralPath $LiteralPath -RelativePath $RelativePath) {
        return $script:InventorySummaryRedacted
    }

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
        [AllowEmptyString()][string] $RelativePath,
        [System.Collections.Generic.List[string]] $PathEscapeHits = $null
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return
    }

    $normalized = ($RelativePath -replace '\\', '/').TrimStart('/')
    if ($normalized -match '(^|/)\.\.(/|$)') {
        if ($null -ne $PathEscapeHits) {
            [void]$PathEscapeHits.Add($normalized)
        }
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
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [System.Collections.Generic.List[string]] $PathEscapeHits = $null
    )

    $full = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        Add-InventoryRelativePath -Set $Set -RelativePath $RelativePath -PathEscapeHits $PathEscapeHits
    }
}

function Get-PathsFromExistingInventory {
    param(
        [Parameter(Mandatory = $true)][object] $InventoryObject,
        [System.Collections.Generic.List[string]] $PathEscapeHits = $null
    )

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    if ($null -ne $InventoryObject.sources) {
        foreach ($entry in @($InventoryObject.sources)) {
            if ($null -ne $entry.path) {
                Add-InventoryRelativePath -Set $paths -RelativePath ([string]$entry.path) -PathEscapeHits $PathEscapeHits
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
                Add-InventoryRelativePath -Set $paths -RelativePath $entry -PathEscapeHits $PathEscapeHits
            }
            elseif ($null -ne $entry.path) {
                Add-InventoryRelativePath -Set $paths -RelativePath ([string]$entry.path) -PathEscapeHits $PathEscapeHits
            }
        }
    }

    return @($paths | Sort-Object)
}

function Get-DefaultInventoryRelativePaths {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [System.Collections.Generic.List[string]] $PathEscapeHits = $null
    )

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $rootNames = @(
        'README.md', 'SECURITY.md', 'CONTRIBUTING.md', 'LICENSE', '.gitignore', 'AGENTS.md', 'CLAUDE.md'
    )
    foreach ($name in $rootNames) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $name -PathEscapeHits $PathEscapeHits
    }

    $lockfileNames = @(
        'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'bun.lockb',
        'Directory.Packages.props', 'packages.lock.json', 'Cargo.lock', 'poetry.lock',
        'uv.lock', 'go.sum', 'Gemfile.lock', 'composer.lock'
    )
    foreach ($name in $lockfileNames) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $name -PathEscapeHits $PathEscapeHits
    }

    $manifestNames = @(
        'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'Gemfile', 'composer.json'
    )
    foreach ($name in $manifestNames) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $name -PathEscapeHits $PathEscapeHits
    }

    Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath 'adapters/registry.json' -PathEscapeHits $PathEscapeHits
    foreach ($scriptRel in @(
            'scripts/toolkit.ps1',
            'scripts/sync-agent.ps1',
            'scripts/validate-agent.ps1',
            'scripts/validation/validate-core.ps1'
        )) {
        Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath $scriptRel -PathEscapeHits $PathEscapeHits
    }

    Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath 'core/skills/_shared/agents/SPAWN.md' -PathEscapeHits $PathEscapeHits
    Add-InventoryPathIfExists -Set $paths -RepoRoot $RepoRoot -RelativePath 'core/router/AGENTS.md' -PathEscapeHits $PathEscapeHits

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
            try {
                $relative = Convert-ToInventoryRelativePath -FullPath $item.FullName -RootPath $RepoRoot
                Add-InventoryRelativePath -Set $paths -RelativePath $relative -PathEscapeHits $PathEscapeHits
            }
            catch {
                if ($null -ne $PathEscapeHits) {
                    [void]$PathEscapeHits.Add(($item.FullName -replace '\\', '/'))
                }
            }
        }
    }

    return @($paths | Sort-Object)
}

function Get-InventoryAggregateHash {
    param(
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]] $SourceEntries = @()
    )

    $entries = @()
    if ($null -ne $SourceEntries) {
        $entries = @($SourceEntries)
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $entries) {
        if ($null -eq $entry) {
            continue
        }
        $path = [string]$entry.path
        $hash = [string]$entry.hash
        if ([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($hash)) {
            continue
        }
        [void]$lines.Add(('{0}:{1}' -f $path, $hash.ToLowerInvariant()))
    }

    $sorted = @($lines | Sort-Object)
    $material = [string]::Join("`n", $sorted)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($material)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    return -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
}

function Get-InventoryAggregateSummary {
    param(
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]] $SourceEntries = @(),
        [AllowEmptyCollection()]
        [AllowNull()]
        [string[]] $StackHints = @()
    )

    $entries = @()
    if ($null -ne $SourceEntries) {
        $entries = @($SourceEntries)
    }

    $hints = @()
    if ($null -ne $StackHints) {
        $hints = @($StackHints | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    }

    $count = $entries.Length
    $stackText = if ($hints.Length -gt 0) { ($hints -join ', ') } else { 'unknown' }
    return ('{0} source(s); stack: {1}' -f $count, $stackText)
}

function Test-SourcePathUnderRepo {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )

    $full = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    return (Test-IsPathUnderOrEqual -ChildPath $full -ParentPath $RepoRoot)
}

function Write-InventoryGovernancePayload {
    param(
        [Parameter(Mandatory = $true)][string] $SourcesPath,
        [Parameter(Mandatory = $true)]$Payload
    )

    $json = ($Payload | ConvertTo-Json -Depth 6)
    [System.IO.File]::WriteAllText($SourcesPath, $json, (Get-Utf8NoBomEncoding))
}

function Get-StackHintsFromPaths {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $RelativePaths
    )

    $hints = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($path in @($RelativePaths)) {
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
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $RelativePaths
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
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $StackHints,
        [AllowEmptyCollection()]
        [string[]] $PreservedBlockingLines = @()
    )

    $hintList = @()
    if ($null -ne $StackHints) {
        $hintList = @($StackHints)
    }
    $openapiHint = if ($OpenApiDetected) { 'yes' } else { 'no' }
    $dbHint = if ($DatabaseDetected) { 'yes' } else { 'no' }
    $uiHint = if ($UiKitDetected) { 'yes' } else { 'no' }
    $stackText = if ($hintList.Length -gt 0) { ($hintList -join ', ') } else { 'unknown' }

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
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $Hints
    )

    $hintList = @()
    if ($null -ne $Hints) {
        $hintList = @($Hints)
    }

    $entry = [ordered]@{
        at     = (Get-Date).ToUniversalTime().ToString('o')
        action = $HistoryAction
        repo   = $RepoName
        hints  = @($hintList)
    } | ConvertTo-Json -Compress

    Add-Content -LiteralPath $HistoryPath -Value $entry -Encoding UTF8
}

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    $RepoPath = Get-ToolkitRepoRoot -FromPath $scriptDir
}

$pathEscapeHits = [System.Collections.Generic.List[string]]::new()
$governanceStatus = $script:InventoryStatusReady
$governanceReason = $script:InventoryReasonReady
$exitCode = $script:InventoryExitReady

if ([string]::IsNullOrWhiteSpace($RepoPath) -or -not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
    throw ("{0} (RepoPath={1})" -f $script:InventoryReasonInvalidRoot, $RepoPath)
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

if (-not (Test-Path -LiteralPath $BankPath -PathType Container)) {
    throw ("{0} (BankPath={1})" -f $script:InventoryReasonInvalidRoot, $BankPath)
}

$bankRoot = (Resolve-Path -LiteralPath $BankPath).Path
$inventoryDir = Join-Path $bankRoot '.inventory'
$sourcesPath = Join-Path $inventoryDir 'sources.json'
$gapsPath = Join-Path $inventoryDir 'gaps.md'
$historyPath = Join-Path $inventoryDir 'refresh-history.jsonl'

# Contracted writes: only under bank_root/.inventory (never app sources).
$inventoryDirFull = [System.IO.Path]::GetFullPath($inventoryDir)
if (-not (Test-IsPathUnderOrEqual -ChildPath $inventoryDirFull -ParentPath $bankRoot)) {
    throw ("Inventory directory escapes bank root: {0}" -f $inventoryDir)
}

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
    foreach ($path in @(Get-PathsFromExistingInventory -InventoryObject $existingInventory -PathEscapeHits $pathEscapeHits)) {
        [void]$relativePaths.Add($path)
    }
}

foreach ($path in @(Get-DefaultInventoryRelativePaths -RepoRoot $repoRoot -PathEscapeHits $pathEscapeHits)) {
    [void]$relativePaths.Add($path)
}

$sourceEntries = [System.Collections.Generic.List[object]]::new()
$incompleteHash = $false
foreach ($relativePath in @($relativePaths | Sort-Object)) {
    if (-not (Test-SourcePathUnderRepo -RepoRoot $repoRoot -RelativePath $relativePath)) {
        [void]$pathEscapeHits.Add(($relativePath -replace '\\', '/'))
        continue
    }

    $fullPath = Join-Path $repoRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $item = Get-Item -LiteralPath $fullPath
    $hash = $null
    try {
        $hash = Get-FileSha256Hex -LiteralPath $fullPath
    }
    catch {
        $incompleteHash = $true
        continue
    }

    if ([string]::IsNullOrWhiteSpace($hash) -or ($hash -notmatch $script:Sha256HexPattern)) {
        $incompleteHash = $true
        continue
    }

    $sourceEntries.Add([ordered]@{
            path           = ($relativePath -replace '\\', '/')
            last_write_utc = $item.LastWriteTimeUtc.ToString('o')
            length         = $item.Length
            hash           = $hash
            summary        = (Get-FileSummaryHeuristic -LiteralPath $fullPath -RelativePath $relativePath)
        })
}

$sortedPaths = @($sourceEntries | ForEach-Object { $_.path })
if ($null -eq $sortedPaths) {
    $sortedPaths = @()
}
$stackHints = @(Get-StackHintsFromPaths -RelativePaths $sortedPaths)
if ($null -eq $stackHints) {
    $stackHints = @()
}
$inventoryHash = Get-InventoryAggregateHash -SourceEntries @($sourceEntries.ToArray())
$inventorySummary = Get-InventoryAggregateSummary -SourceEntries @($sourceEntries.ToArray()) -StackHints $stackHints

if ($pathEscapeHits.Count -gt 0) {
    $governanceStatus = $script:InventoryStatusNotReady
    $governanceReason = $script:InventoryReasonPathEscape
    $exitCode = $script:InventoryExitNotReady
}
elseif ($incompleteHash) {
    $governanceStatus = $script:InventoryStatusNotReady
    $governanceReason = $script:InventoryReasonIncompleteHash
    $exitCode = $script:InventoryExitNotReady
}
elseif ($sourceEntries.Count -lt 1) {
    $governanceStatus = $script:InventoryStatusNotReady
    $governanceReason = $script:InventoryReasonNoSources
    $exitCode = $script:InventoryExitNotReady
}

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
    schema_version      = $script:InventorySchemaVersion
    repo                = $repoName
    repo_path           = $repoRoot
    bank_path           = $bankRoot
    generated_at        = (Get-Date).ToUniversalTime().ToString('o')
    stale_days          = $staleDays
    status              = $governanceStatus
    status_reason       = $governanceReason
    inventory_hash      = $inventoryHash
    inventory_summary   = $inventorySummary
    stack_hints         = @($stackHints)
    skill_count         = $skillCount
    assert_script_count = $assertScriptCount
    sources             = @($sourceEntries)
}

Write-InventoryGovernancePayload -SourcesPath $sourcesPath -Payload $payload

# gaps/history only when we successfully stayed inside bank_root/.inventory
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

Write-Host ("Invoke-MemoryBankInventory: status={0}; reason={1}; hash={2}; summary={3}; sources={4} -> {5}" -f `
        $governanceStatus, $governanceReason, $inventoryHash, $inventorySummary, $sourceEntries.Count, $sourcesPath)
exit $exitCode
