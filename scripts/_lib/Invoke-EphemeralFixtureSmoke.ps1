#Requires -Version 5.1
<#
.SYNOPSIS
  Shared ephemeral fixture smoke runner (copy seed -> work, sync+validate, cleanup).

.DESCRIPTION
  Centralizes the pattern used by scripts/validation/Invoke-*CiSmoke*.ps1: clean any
  stale work InstallRoot, copy the versioned seed fixture into it, run
  sync-agent + validate-agent against the ephemeral work InstallRoot, and check the
  adapter smoke pass marker. The work InstallRoot is removed in a finally block
  (pass or fail) unless -KeepWorkRoot is set, so repeated runs never leak
  "*-ci-smoke" directories on disk.

.NOTES
  Does not call `exit`; callers inspect the returned Status/ExitCode and exit
  themselves so this function's finally block always runs to completion first.
  The lock is cooperative; a hostile concurrent reparse-point race remains
  possible because PowerShell 5.1 has no handle-based recursive delete here.
#>

. (Join-Path $PSScriptRoot 'ToolkitConstants.ps1')

# Windows Defender / indexer can transiently lock files immediately after a bulk
# copy into a brand-new directory tree, surfacing as "could not find a part of
# the path" or "used by another process" from the freshly-spawned sync/validate
# process. Retry a couple of times before treating those as a real failure.
$script:EphemeralSmokeTransientErrorPattern = 'Could not find a part of the path|being used by another process|cannot access the file'
$script:EphemeralSmokeMaxCommandAttempts = 3
$script:EphemeralSmokeRetryDelayMilliseconds = 300
$script:EphemeralSmokeRepoRoot = $null
if (-not (Get-Variable -Scope Script -Name EphemeralSmokeFilesystemGateState -ErrorAction SilentlyContinue)) {
    $script:EphemeralSmokeFilesystemGateState = @{}
}

function Enter-EphemeralSmokeFilesystemGate {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $rootFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([char[]]@('\', '/'))
    $key = $rootFull.ToLowerInvariant()
    if ($script:EphemeralSmokeFilesystemGateState.ContainsKey($key)) {
        $script:EphemeralSmokeFilesystemGateState[$key].Depth++
        return
    }
    $lockPath = Join-Path $rootFull '.toolkit-ephemeral-smoke.lock'
    for ($attempt = 1; $attempt -le 600; $attempt++) {
        try {
            $stream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            $script:EphemeralSmokeFilesystemGateState[$key] = [PSCustomObject]@{ Stream = $stream; Depth = 1 }
            return
        }
        catch [System.IO.IOException] {
            if ($attempt -ge 600) { throw "Timed out waiting for cooperative ephemeral smoke gate: $lockPath" }
            Start-Sleep -Milliseconds 100
        }
    }
}

function Exit-EphemeralSmokeFilesystemGate {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $key = ([System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([char[]]@('\', '/'))).ToLowerInvariant()
    if (-not $script:EphemeralSmokeFilesystemGateState.ContainsKey($key)) { return }
    $state = $script:EphemeralSmokeFilesystemGateState[$key]
    $state.Depth--
    if ($state.Depth -gt 0) { return }
    try { $state.Stream.Dispose() } finally { $script:EphemeralSmokeFilesystemGateState.Remove($key) }
}

# Declarative entries for adapters whose CI smoke is the ordinary
# seed -> sync -> validate flow. Exceptional suites keep their own wrappers
# because they intentionally exercise extra matrix or adapter-specific behavior.
$script:EphemeralSmokeAdapterManifest = @(
    [PSCustomObject]@{ AdapterId = 'cursor'; DisplayName = 'Cursor'; SeedFixtureRel = 'scripts/validation/fixtures/cursor-install-root'; WorkFixtureRel = 'scripts/validation/fixtures/cursor-ci-smoke'; SeedCopyMode = 'TextFile'; SeedCopyFile = 'hooks.json'; PassMarker = 'Invoke-CursorCiSmoke: PASS' }
    [PSCustomObject]@{ AdapterId = 'antigravity'; DisplayName = 'Antigravity'; SeedFixtureRel = 'scripts/validation/fixtures/antigravity-install-root'; WorkFixtureRel = 'scripts/validation/fixtures/antigravity-ci-smoke'; SeedCopyMode = 'Default'; SeedCopyFile = $null; PassMarker = 'Invoke-AntigravityCiSmoke: PASS' }
    [PSCustomObject]@{ AdapterId = 'claude'; DisplayName = 'Claude'; SeedFixtureRel = 'scripts/validation/fixtures/claude'; WorkFixtureRel = 'scripts/validation/fixtures/claude-ci-smoke'; SeedCopyMode = 'TextFile'; SeedCopyFile = 'settings.json'; PassMarker = 'Invoke-ClaudeCiSmoke: PASS' }
    [PSCustomObject]@{ AdapterId = 'codex'; DisplayName = 'Codex'; SeedFixtureRel = 'scripts/validation/fixtures/codex'; WorkFixtureRel = 'scripts/validation/fixtures/codex-ci-smoke'; SeedCopyMode = 'ExcludeNames'; SeedCopyFile = 'AGENTS.md'; PassMarker = 'Invoke-CodexCiSmoke: PASS' }
    [PSCustomObject]@{ AdapterId = 'opencode'; DisplayName = 'OpenCode'; SeedFixtureRel = 'scripts/validation/fixtures/opencode'; WorkFixtureRel = 'scripts/validation/fixtures/opencode-ci-smoke'; SeedCopyMode = 'Default'; SeedCopyFile = $null; PassMarker = 'Invoke-OpenCodeCiSmoke: PASS' }
    [PSCustomObject]@{ AdapterId = 'grok'; DisplayName = 'Grok'; SeedFixtureRel = 'scripts/validation/fixtures/grok'; WorkFixtureRel = 'scripts/validation/fixtures/grok-ci-smoke'; SeedCopyMode = 'Default'; SeedCopyFile = $null; PassMarker = 'Invoke-GrokCiSmoke: PASS' }
)

function Invoke-EphemeralSmokeToolkitCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $CommandPath,
        [Parameter(Mandatory = $true)][string[]] $CommandArgs
    )

    $exitCode = 1
    $outputText = ''
    for ($attempt = 1; $attempt -le $script:EphemeralSmokeMaxCommandAttempts; $attempt++) {
        $commandOutput = & pwsh -NoProfile -File $CommandPath @CommandArgs 2>&1
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
        $outputText = ($commandOutput | Out-String)

        if ($exitCode -eq 0) {
            break
        }

        $isTransient = $outputText -match $script:EphemeralSmokeTransientErrorPattern
        if (-not $isTransient -or $attempt -ge $script:EphemeralSmokeMaxCommandAttempts) {
            break
        }

        Start-Sleep -Milliseconds ($script:EphemeralSmokeRetryDelayMilliseconds * $attempt)
    }

    return [PSCustomObject]@{
        ExitCode = [int]$exitCode
        Output   = $outputText
    }
}

function Remove-EphemeralSmokeWorkRootCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter()][string] $RepoRoot
    )

    $canonicalPath = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $Path -Role 'work root' -AllowMissing -AllowCanonicalPath

    if (-not (Test-Path -LiteralPath $canonicalPath -ErrorAction Stop)) {
        return
    }

    $maxAttempts = [Math]::Max($script:EphemeralSmokeMaxCommandAttempts, 5)
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            # Capture and immediately repeat the complete target validation. A
            # changed child or any reparse point is unsafe to remove. There is
            # no safe handle-based recursive delete API available in this
            # PowerShell 5.1 path, so the final Remove-Item remains a residual
            # race window; fail closed on every change observed before it.
            $canonicalPath = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $canonicalPath -Role 'work root' -AllowCanonicalPath
            $beforeRemoval = Get-EphemeralSmokeTreeState -Root $canonicalPath -Role 'work root'
            $canonicalPath = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $canonicalPath -Role 'work root' -AllowCanonicalPath
            $immediatelyBeforeRemoval = Get-EphemeralSmokeTreeState -Root $canonicalPath -Role 'work root'
            Assert-EphemeralSmokeTreeStateUnchanged -Before $beforeRemoval -After $immediatelyBeforeRemoval -Role 'work root'
            $immediatelyBeforeRemoval | ForEach-Object {
                $item = Get-Item -LiteralPath $_.Path -Force -ErrorAction Stop
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    throw ("Refusing to remove changed/reparse child under work root: {0}" -f $_.Path)
                }
            }
            $finalRemovalState = Get-EphemeralSmokeTreeState -Root $canonicalPath -Role 'work root'
            Assert-EphemeralSmokeTreeStateUnchanged -Before $immediatelyBeforeRemoval -After $finalRemovalState -Role 'work root'
            $canonicalPath = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $canonicalPath -Role 'work root' -AllowCanonicalPath
            Remove-Item -LiteralPath $canonicalPath -Recurse -Force -ErrorAction Stop
            if (-not (Test-Path -LiteralPath $canonicalPath -ErrorAction Stop)) {
                return
            }
        }
        catch {
            if ($attempt -ge $maxAttempts) {
                throw ("Failed to prove removal of ephemeral work root after {0} attempts: {1} ({2})" -f $maxAttempts, $canonicalPath, $_.Exception.Message)
            }
            Start-Sleep -Milliseconds ($script:EphemeralSmokeRetryDelayMilliseconds * $attempt)
        }
    }
}

function Remove-EphemeralSmokeWorkRoot {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $Path, [Parameter()][string] $RepoRoot)
    $gateRoot = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Get-EphemeralSmokeRepoRoot -Path $Path } else { $RepoRoot }
    Enter-EphemeralSmokeFilesystemGate -RepoRoot $gateRoot
    try { return Remove-EphemeralSmokeWorkRootCore @PSBoundParameters }
    finally { Exit-EphemeralSmokeFilesystemGate -RepoRoot $gateRoot }
}

function Get-EphemeralSmokeRepoRoot {
    param([Parameter()][string] $RepoRoot, [Parameter(Mandatory = $true)][string] $Path)

    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([char[]]@('\', '/'))
    }
    if (-not [string]::IsNullOrWhiteSpace($script:EphemeralSmokeRepoRoot)) {
        return $script:EphemeralSmokeRepoRoot
    }
    if (Get-Command Get-ToolkitRepoRoot -ErrorAction SilentlyContinue) {
        return [System.IO.Path]::GetFullPath((Get-ToolkitRepoRoot -FromPath $Path)).TrimEnd([char[]]@('\', '/'))
    }

    $probe = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $probe -PathType Container)) {
        $probe = Split-Path -Parent $probe
    }
    while (-not [string]::IsNullOrWhiteSpace($probe)) {
        if (Test-Path -LiteralPath (Join-Path $probe '.git')) {
            return $probe.TrimEnd([char[]]@('\', '/'))
        }
        $parent = Split-Path -Parent $probe
        if ([string]::Equals($parent, $probe, [System.StringComparison]::OrdinalIgnoreCase)) { break }
        $probe = $parent
    }
    throw 'Cannot prove the ephemeral path belongs to a repository root.'
}

function Assert-EphemeralSmokeContainedPath {
    param(
        [Parameter()][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Role,
        [Parameter()][switch] $AllowMissing,
        [Parameter()][switch] $AllowCanonicalPath
    )

    $root = Get-EphemeralSmokeRepoRoot -RepoRoot $RepoRoot -Path $Path
    $rootItem = Get-Item -LiteralPath $root -Force -ErrorAction Stop
    if ($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        throw ("Refusing {0}: repository root is a reparse point: {1}" -f $Role, $root)
    }

    $inputIsRooted = [System.IO.Path]::IsPathRooted($Path) -or $Path -match '^[A-Za-z]:'
    if ($inputIsRooted -and -not $AllowCanonicalPath) {
        throw ("Refusing absolute path for {0}: {1}" -f $Role, $Path)
    }
    if (-not $AllowCanonicalPath -and (($Path -replace '\\', '/') -split '/') -contains '..') {
        throw ("Refusing parent escape for {0}: {1}" -f $Role, $Path)
    }
    $candidate = if ($inputIsRooted) {
        [System.IO.Path]::GetFullPath($Path)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $root ($Path -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar)))
    }
    $rootPrefix = $root.TrimEnd([char[]]@('\', '/')) + [System.IO.Path]::DirectorySeparatorChar
    if ([string]::Equals($candidate, $root, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ("Refusing {0} outside repository root: {1}" -f $Role, $Path)
    }

    $relative = $candidate.Substring($rootPrefix.Length)
    if ($relative -match '(^|[\\/])\.\.([\\/]|$)' -or
        ((-not $AllowCanonicalPath) -and $inputIsRooted)) {
        throw ("Refusing absolute or parent escape for {0}: {1}" -f $Role, $Path)
    }

    $current = $root
    foreach ($segment in ($relative -split '[\\/]')) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -eq '.') { continue }
        $current = Join-Path $current $segment
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                throw ("Refusing {0} through reparse point: {1}" -f $Role, $current)
            }
        }
    }
    if (-not $AllowMissing -and -not (Test-Path -LiteralPath $candidate)) {
        throw ("Required {0} does not exist: {1}" -f $Role, $candidate)
    }
    return $candidate
}

function Get-EphemeralSmokeTreeState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string] $Role
    )

    $rootItem = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
    if (-not $rootItem.PSIsContainer -or ($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw ("Refusing {0}: root is not a plain directory: {1}" -f $Role, $Root)
    }

    $items = @($rootItem) + @(Get-ChildItem -LiteralPath $Root -Force -Recurse -ErrorAction Stop)
    return @($items | ForEach-Object {
        if ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw ("Refusing {0}: changed/reparse child: {1}" -f $Role, $_.FullName)
        }
        [PSCustomObject]@{
            Path = [System.IO.Path]::GetFullPath($_.FullName)
            Attributes = [int]$_.Attributes
            Length = if ($_.PSIsContainer) { [int64]0 } else { [int64]$_.Length }
            LastWriteTimeUtc = $_.LastWriteTimeUtc.Ticks
        }
    } | Sort-Object Path)
}

function Assert-EphemeralSmokeTreeStateUnchanged {
    param(
        [Parameter(Mandatory = $true)][object[]] $Before,
        [Parameter(Mandatory = $true)][object[]] $After,
        [Parameter(Mandatory = $true)][string] $Role
    )

    $beforeText = ($Before | ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.Path, $_.Attributes, $_.Length, $_.LastWriteTimeUtc }) -join "`n"
    $afterText = ($After | ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.Path, $_.Attributes, $_.Length, $_.LastWriteTimeUtc }) -join "`n"
    if (-not [string]::Equals($beforeText, $afterText, [System.StringComparison]::Ordinal)) {
        throw ("Refusing to remove changed {0}: tree changed during final validation." -f $Role)
    }
}

function Assert-EphemeralSmokeSeedWrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $SeedFixtureRoot,
        [Parameter(Mandatory = $true)][string] $WorkInstallRoot,
        [Parameter(Mandatory = $true)][string] $SourcePath,
        [Parameter(Mandatory = $true)][string] $DestinationPath
    )

    # This is intentionally called immediately before every seed write. It
    # validates only the affected source/destination paths; callers snapshot
    # complete trees once per copy phase. A mutation after this check is an
    # irreducible residual race without unsafe native handle APIs; copy/write
    # failures remain fatal.
    $null = Assert-EphemeralSmokeContainedPath -Path $SeedFixtureRoot -Role 'seed fixture' -AllowCanonicalPath
    $null = Assert-EphemeralSmokeContainedPath -Path $WorkInstallRoot -Role 'work root' -AllowCanonicalPath
    $null = Assert-EphemeralSmokeContainedPath -Path $SourcePath -Role 'seed source' -AllowCanonicalPath
    $destinationParent = Split-Path -Parent $DestinationPath
    $null = Assert-EphemeralSmokeContainedPath -Path $destinationParent -Role 'seed destination directory' -AllowCanonicalPath -AllowMissing

    $sourceItem = Get-Item -LiteralPath $SourcePath -Force -ErrorAction Stop
    if ($sourceItem.PSIsContainer -or ($sourceItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw ("Refusing seed write from changed/reparse source: {0}" -f $SourcePath)
    }
    if (Test-Path -LiteralPath $DestinationPath) {
        $destinationItem = Get-Item -LiteralPath $DestinationPath -Force -ErrorAction Stop
        if ($destinationItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw ("Refusing seed write to reparse destination: {0}" -f $DestinationPath)
        }
    }
}

function Assert-EphemeralSmokeDeleteTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string] $Target
    )

    # Call immediately before a single-file deletion. The final Remove-Item
    # still has a residual race without a safe native handle API, so any
    # observed target/root/child change or reparse point is a hard failure.
    $null = Assert-EphemeralSmokeContainedPath -Path $Root -Role 'deletion root' -AllowCanonicalPath
    $null = Assert-EphemeralSmokeContainedPath -Path $Target -Role 'deletion target' -AllowCanonicalPath
    $targetItem = Get-Item -LiteralPath $Target -Force -ErrorAction Stop
    if ($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        throw ("Refusing to remove reparse deletion target: {0}" -f $Target)
    }
}

function Copy-EphemeralSmokeSeedTreeCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $SeedFixtureRoot,
        [Parameter(Mandatory = $true)][string] $WorkInstallRoot,
        [Parameter()][string[]] $ExcludeNames = @()
    )

    # Snapshot each tree once for this logical copy phase. Per-file validation
    # below is limited to the affected paths, avoiding O(n^2) rescans.
    $seedBefore = Get-EphemeralSmokeTreeState -Root $SeedFixtureRoot -Role 'seed fixture'
    $children = @(Get-ChildItem -LiteralPath $SeedFixtureRoot -Force -Recurse -ErrorAction Stop | Sort-Object @{ Expression = { $_.PSIsContainer }; Descending = $true }, FullName)
    foreach ($child in $children) {
        if ($ExcludeNames -contains $child.Name) { continue }
        $relative = $child.FullName.Substring($SeedFixtureRoot.Length).TrimStart([char[]]@('\', '/'))
        $destinationPath = Join-Path $WorkInstallRoot $relative
        if ($child.PSIsContainer) {
            $null = Assert-EphemeralSmokeContainedPath -Path $child.FullName -Role 'seed directory' -AllowCanonicalPath
            $null = Assert-EphemeralSmokeContainedPath -Path $destinationPath -Role 'seed destination directory' -AllowCanonicalPath -AllowMissing
            if ($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                throw ("Refusing changed/reparse seed directory: {0}" -f $child.FullName)
            }
            New-Item -ItemType Directory -Path $destinationPath -Force -ErrorAction Stop | Out-Null
            continue
        }

        Assert-EphemeralSmokeSeedWrite -SeedFixtureRoot $SeedFixtureRoot -WorkInstallRoot $WorkInstallRoot -SourcePath $child.FullName -DestinationPath $destinationPath
        Copy-Item -LiteralPath $child.FullName -Destination $destinationPath -Force -ErrorAction Stop
    }

    # One post-copy source snapshot closes the phase-level mutation check. The
    # work tree is intentionally changed by this phase and is validated by the
    # affected-path checks above.
    $seedAfter = Get-EphemeralSmokeTreeState -Root $SeedFixtureRoot -Role 'seed fixture'
    Assert-EphemeralSmokeTreeStateUnchanged -Before $seedBefore -After $seedAfter -Role 'seed fixture'
}

function Copy-EphemeralSmokeSeedTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $SeedFixtureRoot,
        [Parameter(Mandatory = $true)][string] $WorkInstallRoot,
        [Parameter()][string[]] $ExcludeNames = @()
    )
    $gateRoot = Get-EphemeralSmokeRepoRoot -Path $SeedFixtureRoot
    Enter-EphemeralSmokeFilesystemGate -RepoRoot $gateRoot
    try { return Copy-EphemeralSmokeSeedTreeCore @PSBoundParameters }
    finally { Exit-EphemeralSmokeFilesystemGate -RepoRoot $gateRoot }
}

function Invoke-ManifestAdapterFixtureSmoke {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $AdapterId,
        [Parameter()][switch] $Quiet,
        [Parameter()][switch] $KeepWorkRoot
    )

    $entry = @($script:EphemeralSmokeAdapterManifest | Where-Object { $_.AdapterId -ieq $AdapterId }) | Select-Object -First 1
    if ($null -eq $entry) {
        throw ("No ordinary CI smoke manifest entry exists for adapter '{0}'." -f $AdapterId)
    }

    if (-not $Quiet) {
        Write-Host ('agent-dev-toolkit {0} CI smoke' -f $entry.DisplayName) -ForegroundColor Cyan
    }

    $seedCopy = $null
    $requiredPaths = @()
    switch ([string]$entry.SeedCopyMode) {
        'TextFile' {
            $seedFileName = [string]$entry.SeedCopyFile
            $seedFilePath = Join-Path (Join-Path $RepoRoot ($entry.SeedFixtureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)) $seedFileName
            $requiredPaths = @($seedFilePath)
            $assertSeedWriteCommand = Get-Command Assert-EphemeralSmokeSeedWrite -CommandType Function -ErrorAction Stop
            $seedCopy = {
                param([string] $SeedFixtureRoot, [string] $WorkInstallRoot)
                $sourcePath = Join-Path $SeedFixtureRoot $seedFileName
                $destinationPath = Join-Path $WorkInstallRoot $seedFileName
                & $assertSeedWriteCommand -SeedFixtureRoot $SeedFixtureRoot -WorkInstallRoot $WorkInstallRoot -SourcePath $sourcePath -DestinationPath $destinationPath
                $seedText = [System.IO.File]::ReadAllText($sourcePath)
                & $assertSeedWriteCommand -SeedFixtureRoot $SeedFixtureRoot -WorkInstallRoot $WorkInstallRoot -SourcePath $sourcePath -DestinationPath $destinationPath
                [System.IO.File]::WriteAllText($destinationPath, $seedText, (New-Object System.Text.UTF8Encoding $false))
            }.GetNewClosure()
        }
        'ExcludeNames' {
            $excludedName = [string]$entry.SeedCopyFile
            $copySeedTreeCommand = Get-Command Copy-EphemeralSmokeSeedTree -CommandType Function -ErrorAction Stop
            $seedCopy = {
                param([string] $SeedFixtureRoot, [string] $WorkInstallRoot)
                & $copySeedTreeCommand -SeedFixtureRoot $SeedFixtureRoot -WorkInstallRoot $WorkInstallRoot -ExcludeNames @($excludedName)
            }.GetNewClosure()
        }
        'Default' { }
        default { throw ("Unsupported seed copy mode '{0}' for adapter '{1}'." -f $entry.SeedCopyMode, $entry.AdapterId) }
    }

    $result = Invoke-EphemeralFixtureSmoke `
        -RepoRoot $RepoRoot `
        -SeedFixtureRel $entry.SeedFixtureRel `
        -WorkFixtureRel $entry.WorkFixtureRel `
        -AgentId $entry.AdapterId `
        -AdditionalRequiredPaths $requiredPaths `
        -SeedCopyScriptBlock $seedCopy `
        -Quiet:$Quiet `
        -KeepWorkRoot:$KeepWorkRoot

    if ($result.Status -eq 'PASS') {
        if (-not $Quiet) {
            Write-Host $result.Output
        }
        Write-Host ([string]$entry.PassMarker) -ForegroundColor Green
    }

    return $result
}

function Invoke-EphemeralFixtureSmokeCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $SeedFixtureRel,
        [Parameter(Mandatory = $true)][string] $WorkFixtureRel,
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter()][string] $Mode,
        [Parameter()][string] $SyncAgentRel = $script:ToolkitConstant.SyncAgentRelativePath,
        [Parameter()][string] $ValidateAgentRel = $script:ToolkitConstant.ValidateAgentRelativePath,
        [Parameter()][string[]] $AdditionalRequiredPaths = @(),
        [Parameter()][scriptblock] $SeedCopyScriptBlock,
        [Parameter()][switch] $Quiet,
        [Parameter()][switch] $KeepWorkRoot
    )

    $script:EphemeralSmokeRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([char[]]@('\', '/'))
    $normalizeRel = { param([string] $Relative) return ($Relative -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar) }

    $workInstallRoot = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $WorkFixtureRel -Role 'work root' -AllowMissing

    try {
        # Keep all preconditions inside the outer finally so a stale or
        # partially-created work root is removed on every default failure path.
        $seedFixtureRoot = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $SeedFixtureRel -Role 'seed fixture' -AllowMissing
        $syncAgentPath = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $SyncAgentRel -Role 'sync script' -AllowMissing
        $validateAgentPath = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $ValidateAgentRel -Role 'validate script' -AllowMissing
        $agentLabel = if ([string]::IsNullOrWhiteSpace($Mode)) { $AgentId } else { '{0} Mode={1}' -f $AgentId, $Mode }

        $requiredPaths = @($seedFixtureRoot, $syncAgentPath, $validateAgentPath)
        foreach ($extra in @($AdditionalRequiredPaths)) {
            if ([string]::IsNullOrWhiteSpace($extra)) { continue }
            # Manifest callers may provide an already-canonical path. The helper
            # still proves containment and rejects reparse traversal before it is
            # accepted.
            $requiredPaths += (Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $extra -Role 'required path' -AllowMissing -AllowCanonicalPath)
        }
        foreach ($required in $requiredPaths) {
            if (-not (Test-Path -LiteralPath $required)) {
                Write-Host ($script:ToolkitMessage.EphemeralSmokePreconditionMissing -f $required) -ForegroundColor Red
                return [PSCustomObject]@{
                    Status          = 'FAIL'
                    ExitCode        = 1
                    Phase           = 'preconditions'
                    Output          = ''
                    WorkInstallRoot = $workInstallRoot
                }
            }
        }

        Remove-EphemeralSmokeWorkRoot -RepoRoot $RepoRoot -Path $workInstallRoot
        $null = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $workInstallRoot -Role 'work root' -AllowMissing -AllowCanonicalPath
        New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null
        $null = Assert-EphemeralSmokeContainedPath -RepoRoot $RepoRoot -Path $workInstallRoot -Role 'work root' -AllowCanonicalPath

        if ($SeedCopyScriptBlock) {
            & $SeedCopyScriptBlock $seedFixtureRoot $workInstallRoot
        }
        else {
            Copy-EphemeralSmokeSeedTree -SeedFixtureRoot $seedFixtureRoot -WorkInstallRoot $workInstallRoot
        }

        if (-not $Quiet) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeRunning -f $agentLabel, $workInstallRoot) -ForegroundColor Cyan
        }

        $syncArgs = @('-Agent', $AgentId, '-InstallRoot', $workInstallRoot)
        if (-not [string]::IsNullOrWhiteSpace($Mode)) {
            $syncArgs += @('-Mode', $Mode)
        }

        $syncResult = Invoke-EphemeralSmokeToolkitCommand -CommandPath $syncAgentPath -CommandArgs $syncArgs
        $syncExit = $syncResult.ExitCode
        $syncText = $syncResult.Output
        if ($syncExit -ne 0) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeSyncFailed -f $syncExit, $syncText.Trim()) -ForegroundColor Red
            return [PSCustomObject]@{
                Status          = 'FAIL'
                ExitCode        = [int]$syncExit
                Phase           = 'sync'
                Output          = $syncText
                WorkInstallRoot = $workInstallRoot
            }
        }

        # Core already ran once in CI (validate-core job/step). Skip nested core here.
        $validateArgs = @('-Agent', $AgentId, '-InstallRoot', $workInstallRoot, ('-{0}' -f $script:ToolkitConstant.SkipCoreParameterName))
        if (-not [string]::IsNullOrWhiteSpace($Mode)) {
            $validateArgs += @('-Mode', $Mode)
        }

        $validateResult = Invoke-EphemeralSmokeToolkitCommand -CommandPath $validateAgentPath -CommandArgs $validateArgs
        $validateExit = $validateResult.ExitCode
        $validateText = $validateResult.Output
        if ($validateExit -ne 0) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeValidateFailed -f $validateExit, $validateText.Trim()) -ForegroundColor Red
            return [PSCustomObject]@{
                Status          = 'FAIL'
                ExitCode        = [int]$validateExit
                Phase           = 'validate'
                Output          = $validateText
                WorkInstallRoot = $workInstallRoot
            }
        }

        $adapterSmokePassMarker = $script:ToolkitConstant.AdapterSmokePassMarker
        if ($validateText -notlike ('*{0}*' -f $adapterSmokePassMarker)) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeMarkerMissing -f $adapterSmokePassMarker) -ForegroundColor Red
            Write-Host $validateText
            return [PSCustomObject]@{
                Status          = 'FAIL'
                ExitCode        = 1
                Phase           = 'marker'
                Output          = $validateText
                WorkInstallRoot = $workInstallRoot
            }
        }

        return [PSCustomObject]@{
            Status          = 'PASS'
            ExitCode        = 0
            Phase           = 'done'
            Output          = $validateText
            WorkInstallRoot = $workInstallRoot
        }
    }
    finally {
        if (-not $KeepWorkRoot) {
            Remove-EphemeralSmokeWorkRoot -RepoRoot $RepoRoot -Path $workInstallRoot
        }
    }
}

function Invoke-EphemeralFixtureSmoke {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $SeedFixtureRel,
        [Parameter(Mandatory = $true)][string] $WorkFixtureRel,
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter()][string] $Mode,
        [Parameter()][string] $SyncAgentRel = $script:ToolkitConstant.SyncAgentRelativePath,
        [Parameter()][string] $ValidateAgentRel = $script:ToolkitConstant.ValidateAgentRelativePath,
        [Parameter()][string[]] $AdditionalRequiredPaths = @(),
        [Parameter()][scriptblock] $SeedCopyScriptBlock,
        [Parameter()][switch] $Quiet,
        [Parameter()][switch] $KeepWorkRoot
    )
    Enter-EphemeralSmokeFilesystemGate -RepoRoot $RepoRoot
    try { return Invoke-EphemeralFixtureSmokeCore @PSBoundParameters }
    finally { Exit-EphemeralSmokeFilesystemGate -RepoRoot $RepoRoot }
}
