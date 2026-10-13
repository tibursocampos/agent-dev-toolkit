#Requires -Version 5.1
<#
.SYNOPSIS
  Remove exact, inventoried exclusive runtime outputs and prune empty managed roots.
.DESCRIPTION
  Runtime targets come from runtime-manifest.json; accepted adapter ids and
  pruning roots come from uninstall-artifacts.json. Files are removed by their
  published identity even when edited. Unknown files and non-empty directories
  are preserved. Every delete is guarded by the adapter InstallRoot boundary.
#>

function Test-ToolkitOwnedDevelopSessionFile {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo] $File)
    if ($File.Name -notmatch '^plan-[0-9a-f]{16}(?:-step-\d+)?\.json$' -or
        $File.Directory.Name -notmatch '^[0-9a-f]{16}$') { return $false }
    try {
        $session = Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        foreach ($name in @('repo', 'plan_path', 'workflow', 'phase', 'gates', 'updated_at')) {
            if ($null -eq $session.PSObject.Properties[$name]) { return $false }
        }
        if ([string]$session.workflow -ne 'classic' -or
            $null -eq $session.gates.PSObject.Properties['step_confirmed'] -or
            $null -eq $session.gates.PSObject.Properties['tests_run']) { return $false }
        $normalizedRepo = [System.IO.Path]::GetFullPath([string]$session.repo).Replace('\', '/').TrimEnd('/')
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalizedRepo))).Replace('-', '').ToLowerInvariant()).Substring(0, 16)
        }
        finally { $sha.Dispose() }
        return $File.Directory.Name -ceq $hash
    }
    catch { return $false }
}

function Invoke-ToolkitUninstallArtifacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $Adapter,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $InstallRoot,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $RepoRoot,
        [switch] $WhatIf
    )

    if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
        . (Join-Path $PSScriptRoot 'Resolve-InstallRoot.ps1')
    }
    $publishInventoryScript = Join-Path $PSScriptRoot 'ToolkitManagedPublishInventory.ps1'
    $managedTreeScript = Join-Path $PSScriptRoot 'Copy-ToolkitManagedTree.ps1'
    if (-not (Get-Command -Name Remove-ToolkitManagedPublishInventoryIfEmpty -ErrorAction SilentlyContinue)) {
        . $publishInventoryScript
    }
    if (-not (Get-Command -Name Remove-ToolkitFilesystemGateFile -ErrorAction SilentlyContinue)) {
        . $managedTreeScript
    }

    $inventoryPath = Join-Path (Join-Path $RepoRoot 'scripts') 'runtime/uninstall-artifacts.json'
    $manifestPath = Join-Path (Join-Path $RepoRoot 'scripts') 'runtime/runtime-manifest.json'
    if (-not (Test-Path -LiteralPath $inventoryPath -PathType Leaf) -or -not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw 'Toolkit uninstall artifact inventory or runtime manifest is missing.'
    }

    $inventory = Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json -ErrorAction Stop
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -ErrorAction Stop
    $adapterRecord = @($inventory.adapters | Where-Object { [string]::Equals([string]$_.id, $Adapter, [System.StringComparison]::OrdinalIgnoreCase) })
    if ($adapterRecord.Count -ne 1) { throw ("Uninstall inventory must contain exactly one adapter '{0}'." -f $Adapter) }

    $root = [System.IO.Path]::GetFullPath($InstallRoot)
    $removed = New-Object 'System.Collections.Generic.List[string]'
    $targetResults = New-Object 'System.Collections.Generic.List[object]'
    $incomplete = New-Object 'System.Collections.Generic.List[string]'
    $runtimePruneCandidates = New-Object 'System.Collections.Generic.List[object]'
    $pruneRoots = New-Object 'System.Collections.Generic.List[string]'
    $managedSkillRoots = New-Object 'System.Collections.Generic.List[string]'

    function Invoke-ToolkitUninstallRemoval {
        param([string] $Path, [string] $Operation = 'remove')
        try {
            $null = Assert-PathUnderInstallRootForDelete -CandidatePath $Path -InstallRoot $root
        }
        catch {
            return (New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $Path -Adapter $Adapter -Operation $Operation -Reason $_.Exception.Message)
        }
        if ($WhatIf.IsPresent) {
            return (New-ToolkitUninstallTargetResult -Status Complete -TargetPath $Path -Adapter $Adapter -Operation $Operation -Reason 'WhatIf: no mutation performed')
        }
        try {
            Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
            return (New-ToolkitUninstallTargetResult -Status Complete -TargetPath $Path -Adapter $Adapter -Operation $Operation)
        }
        catch {
            return (New-ToolkitUninstallTargetResult -Status Failed -TargetPath $Path -Adapter $Adapter -Operation $Operation -Reason $_.Exception.Message)
        }
    }
    function Add-ToolkitUninstallRemovalResult {
        param([Parameter(Mandatory = $true)]$Result, [Parameter(Mandatory = $true)][string] $Path)
        $targetResults.Add($Result) | Out-Null
        if ($Result.Status -eq 'Complete') { $removed.Add($Path) | Out-Null }
        else { $incomplete.Add(('{0}: {1}' -f $Path, $Result.Reason)) | Out-Null }
    }

    $runtimeRoot = Join-Path $root ([string]$manifest.destinationRoot)
    $runtimeTargets = New-Object 'System.Collections.Generic.List[object]'
    foreach ($entry in @($manifest.files)) {
        $runtimeTargets.Add([PSCustomObject]@{ Root = $runtimeRoot; Entry = $entry }) | Out-Null
    }
    # Mirror sync-agent's finite adapter/mode mapping. Codex user-scope is
    # represented by an InstallRoot/.agents tree; OpenHands project mode is
    # disabled when InstallRoot itself is the live ~/.agents root.
    foreach ($mapping in @($manifest.additionalToolkitRoots)) {
        if (-not [string]::Equals([string]$mapping.adapter, $Adapter, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        $includeMapping = switch ([string]$mapping.when) {
            'always' { $true; break }
            'user-scope' { (Test-Path -LiteralPath (Join-Path $root ([string]$mapping.path)) -PathType Container); break }
            'project' {
                $installLeaf = Split-Path -Leaf $root.TrimEnd('\', '/')
                -not [string]::Equals($installLeaf, '.agents', [System.StringComparison]::OrdinalIgnoreCase)
                break
            }
            default { $false }
        }
        if (-not $includeMapping) { continue }
        $relativeRoot = [string]$mapping.path
        if ([string]::IsNullOrWhiteSpace($relativeRoot) -or [System.IO.Path]::IsPathRooted($relativeRoot) -or ($relativeRoot -split '[\\/]') -contains '..') {
            throw ("Unsafe additional toolkit root for '{0}': {1}" -f $Adapter, $relativeRoot)
        }
        $mappedRoot = [System.IO.Path]::GetFullPath((Join-Path $root ($relativeRoot -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
        if (-not (Test-IsPathUnderOrEqual -ChildPath $mappedRoot -ParentPath $root)) { throw ("Additional toolkit root escapes adapter InstallRoot: {0}" -f $mappedRoot) }
        $mappedRuntimeRoot = Join-Path $mappedRoot ([string]$manifest.destinationRoot)
        foreach ($entry in @($manifest.files)) {
            $runtimeTargets.Add([PSCustomObject]@{ Root = $mappedRuntimeRoot; Entry = $entry }) | Out-Null
        }
        $pruneRoots.Add($mappedRoot) | Out-Null
        if ([string]::IsNullOrWhiteSpace([string]$mapping.path)) { continue }
        $managedSkillRoots.Add((Join-Path $mappedRoot 'skills')) | Out-Null
    }
    foreach ($relativeSkillRoot in @($adapterRecord[0].pruneRoots | Where-Object { [string]$_ -match '(^|/)skills$' })) {
        $managedSkillRoots.Add((Join-Path $root ([string]$relativeSkillRoot -replace '/', [System.IO.Path]::DirectorySeparatorChar))) | Out-Null
    }
    $lifecycleGateEntered = $false
    if (-not $WhatIf.IsPresent) {
        try {
            Enter-ToolkitFilesystemGate -RootPath $root -LockFileName '.toolkit-managed-publish.lock'
            $lifecycleGateEntered = $true
        }
        catch {
            foreach ($runtimeTarget in $runtimeTargets) {
                $entry = $runtimeTarget.Entry
                $target = Join-Path $runtimeTarget.Root ([string]$entry.destination -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                if (Test-Path -LiteralPath $target -PathType Leaf) {
                    $blocked = New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $target -Adapter $Adapter -Operation 'remove-runtime' -Reason ('lifecycle-gate-unavailable: ' + $_.Exception.Message)
                    Add-ToolkitUninstallRemovalResult -Result $blocked -Path $target
                }
            }
            if ($targetResults.Count -eq 0) {
                $blocked = New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $root -Adapter $Adapter -Operation 'acquire-lifecycle-gate' -Reason $_.Exception.Message
                $targetResults.Add($blocked) | Out-Null
                $incomplete.Add(('{0}: {1}' -f $root, $blocked.Reason)) | Out-Null
            }
            return [PSCustomObject]@{
                Adapter = $Adapter
                RemovedPaths = @()
                IncompletePaths = @($incomplete.ToArray())
                TargetResults = @($targetResults.ToArray())
                Status = 'Incomplete'
                WhatIf = $false
            }
        }
    }
    try {
    foreach ($runtimeTarget in $runtimeTargets) {
        $entry = $runtimeTarget.Entry
        $relative = ([string]$entry.destination).Trim()
        if ([string]::IsNullOrWhiteSpace($relative) -or [System.IO.Path]::IsPathRooted($relative) -or ($relative -split '[\\/]') -contains '..') {
            throw ("Unsafe runtime manifest destination: {0}" -f $relative)
        }
        $target = Join-Path $runtimeTarget.Root ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
        $deleteResult = Invoke-ToolkitUninstallRemoval -Path $target
        Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $target
        $runtimePruneCandidates.Add([PSCustomObject]@{ Start = (Split-Path -Parent $target); Root = [string]$runtimeTarget.Root }) | Out-Null
    }

    # Older inventories may omit optional legacy identities. Treat that as an
    # empty list while keeping malformed entries and unsafe paths fail-closed.
    $legacyFilesProperty = $adapterRecord[0].PSObject.Properties['legacyFiles']
    $legacyFiles = if ($null -eq $legacyFilesProperty) { @() } else { @($legacyFilesProperty.Value) }
    foreach ($relative in $legacyFiles) {
        $relative = ([string]$relative).Trim()
        if ([string]::IsNullOrWhiteSpace($relative)) { continue }
        if ([System.IO.Path]::IsPathRooted($relative) -or ($relative -split '[\\/]') -contains '..') {
            throw ("Unsafe legacy file identity for '{0}': {1}" -f $Adapter, $relative)
        }
        $target = Join-Path $root ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
        $deleteResult = Invoke-ToolkitUninstallRemoval -Path $target
        Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $target
        $pruneRoots.Add((Split-Path -Parent $target)) | Out-Null
    }

    # SDD is created by Initialize-SddRootLayout/Initialize-SddPreferences for
    # every adapter. Its manifest, seeded preferences and session JSON are
    # toolkit runtime state; edited bytes do not change that ownership. Keep
    # unknown files and non-empty directories outside these exact surfaces.
    $sddRoot = Join-Path $root 'sdd'
    foreach ($relative in @('sdd/manifest.json', 'sdd/preferences.json')) {
        $target = Join-Path $root ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $deleteResult = Invoke-ToolkitUninstallRemoval -Path $target
            Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $target
        }
    }
    $sessionsRoot = Join-Path $sddRoot 'sessions'
    $sessionsRootExists = $false
    try {
        $sessionsRootExists = Test-Path -LiteralPath $sessionsRoot -PathType Container -ErrorAction Stop
        if ($sessionsRootExists) { $null = Assert-PathUnderInstallRootForDelete -CandidatePath $sessionsRoot -InstallRoot $root }
    }
    catch {
        $sessionsRootExists = $false
        $inspection = New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $sessionsRoot -Adapter $Adapter -Operation 'inspect-session-state' -Reason $_.Exception.Message
        Add-ToolkitUninstallRemovalResult -Result $inspection -Path $sessionsRoot
    }
    if ($sessionsRootExists) {
        $sessionDirectories = @()
        try { $sessionDirectories = @(Get-ChildItem -LiteralPath $sessionsRoot -Directory -Force -ErrorAction Stop) }
        catch {
            $inspection = New-ToolkitUninstallTargetResult -Status Failed -TargetPath $sessionsRoot -Adapter $Adapter -Operation 'enumerate-session-state' -Reason $_.Exception.Message
            Add-ToolkitUninstallRemovalResult -Result $inspection -Path $sessionsRoot
        }
        foreach ($sessionDirectory in $sessionDirectories) {
            if ($sessionDirectory.Name -notmatch '^[0-9a-f]{16}$') { continue }
            try { $null = Assert-PathUnderInstallRootForDelete -CandidatePath $sessionDirectory.FullName -InstallRoot $root }
            catch {
                $unsafeDirectory = New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $sessionDirectory.FullName -Adapter $Adapter -Operation 'inspect-session-state' -Reason $_.Exception.Message
                $targetResults.Add($unsafeDirectory) | Out-Null
                $incomplete.Add(('{0}: {1}' -f $sessionDirectory.FullName, $unsafeDirectory.Reason)) | Out-Null
                continue
            }
            $sessionFiles = @()
            try { $sessionFiles = @(Get-ChildItem -LiteralPath $sessionDirectory.FullName -File -Force -ErrorAction Stop) }
            catch {
                $inspection = New-ToolkitUninstallTargetResult -Status Failed -TargetPath $sessionDirectory.FullName -Adapter $Adapter -Operation 'enumerate-session-state' -Reason $_.Exception.Message
                Add-ToolkitUninstallRemovalResult -Result $inspection -Path $sessionDirectory.FullName
                continue
            }
            foreach ($sessionFile in $sessionFiles) {
                # Only retire canonical toolkit develop-session files. Other JSON
                # under this shared state root may belong to another tool/user.
                if (-not (Test-ToolkitOwnedDevelopSessionFile -File $sessionFile)) { continue }
                $deleteResult = Invoke-ToolkitUninstallRemoval -Path $sessionFile.FullName
                Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $sessionFile.FullName
            }
            $pruneRoots.Add($sessionDirectory.FullName) | Out-Null
        }
        $pruneRoots.Add($sessionsRoot) | Out-Null
    }
    if ($Adapter -in @('cursor', 'claude')) {
        $hookStateFile = Join-Path (Join-Path $root 'hooks-state') 'plan-edit.json'
        if (Test-Path -LiteralPath $hookStateFile -PathType Leaf) {
            $deleteResult = Invoke-ToolkitUninstallRemoval -Path $hookStateFile
            Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $hookStateFile
            $pruneRoots.Add((Split-Path -Parent $hookStateFile)) | Out-Null
        }
    }
    $pruneRoots.Add($sddRoot) | Out-Null

    foreach ($relativeRoot in @($adapterRecord[0].pruneRoots)) {
        $normalized = [string]$relativeRoot
        if ([string]::IsNullOrWhiteSpace($normalized) -or [System.IO.Path]::IsPathRooted($normalized) -or ($normalized -split '[\\/]') -contains '..') {
            throw ("Unsafe uninstall pruning root for '{0}': {1}" -f $Adapter, $normalized)
        }
        $pruneRoots.Add((Join-Path $root ($normalized -replace '/', [System.IO.Path]::DirectorySeparatorChar))) | Out-Null
    }

    # Remove finite adapter-specific publish targets that are absent from the
    # shared runtime manifest (for example, a colocated shared hook helper).
    # Other inventory entries may still be dependencies owned by a different
    # publisher; preserve them and report Incomplete during inventory retire.
    try {
        $authorizedPruneRoots = @($pruneRoots | ForEach-Object { [System.IO.Path]::GetFullPath([string]$_) })
        $publishedFilesProperty = $adapterRecord[0].PSObject.Properties['publishedFiles']
        $publishedFiles = if ($null -eq $publishedFilesProperty) { @() } else { @($publishedFilesProperty.Value) }
        foreach ($relativePath in $publishedFiles) {
            $relativePath = ([string]$relativePath).Trim()
            if ([string]::IsNullOrWhiteSpace($relativePath) -or [System.IO.Path]::IsPathRooted($relativePath) -or ($relativePath -split '[\\/]') -contains '..') {
                throw ("Unsafe managed publish inventory path: {0}" -f $relativePath)
            }
            $managedPath = Join-Path $root ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            $managedPath = [System.IO.Path]::GetFullPath($managedPath)
            if (-not (Test-IsPathUnderOrEqual -ChildPath $managedPath -ParentPath $root)) {
                throw ("Managed publish inventory path escapes InstallRoot: {0}" -f $relativePath)
            }
            if ($Adapter -eq 'copilot' -and [System.IO.Path]::GetFileName($managedPath) -ceq '.gitkeep') { continue }
            if (-not (Test-Path -LiteralPath $managedPath)) { continue }
            $null = Assert-PathUnderInstallRootForDelete -CandidatePath $managedPath -InstallRoot $root
            if (-not (Test-Path -LiteralPath $managedPath -PathType Leaf)) {
                $ambiguous = New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $managedPath -Adapter $Adapter -Operation 'remove-managed-publish-file' -Reason 'inventory-target-is-not-a-file'
                Add-ToolkitUninstallRemovalResult -Result $ambiguous -Path $managedPath
                continue
            }
            $deleteResult = Invoke-ToolkitUninstallRemoval -Path $managedPath -Operation 'remove-managed-publish-file'
            Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $managedPath
            if ($deleteResult.Status -ne 'Complete') { continue }

            $current = Split-Path -Parent $managedPath
            $boundary = $null
            foreach ($candidateRoot in $authorizedPruneRoots) {
                if ((Test-IsPathUnderOrEqual -ChildPath $managedPath -ParentPath $candidateRoot) -and
                    ($null -eq $boundary -or $candidateRoot.Length -gt $boundary.Length)) { $boundary = $candidateRoot }
            }
            while ($null -ne $boundary -and $current.Length -gt $boundary.Length -and (Test-IsPathUnderOrEqual -ChildPath $current -ParentPath $boundary)) {
                $pruneRoots.Add($current) | Out-Null
                $current = Split-Path -Parent $current
            }
        }
    }
    catch {
        $inventoryScan = New-ToolkitUninstallTargetResult -Status Failed -TargetPath (Join-Path $root '.toolkit-managed-publish.json') -Adapter $Adapter -Operation 'remove-managed-publish-files' -Reason $_.Exception.Message
        $targetResults.Add($inventoryScan) | Out-Null
        $incomplete.Add(('.toolkit-managed-publish.json: {0}' -f $_.Exception.Message)) | Out-Null
    }

    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($candidate in $runtimePruneCandidates) {
        $pruneRuntimeRoot = [System.IO.Path]::GetFullPath([string]$candidate.Root)
        $current = [System.IO.Path]::GetFullPath([string]$candidate.Start)
        while ($current.Length -gt $pruneRuntimeRoot.Length -and (Test-IsPathUnderOrEqual -ChildPath $current -ParentPath $pruneRuntimeRoot)) {
            if (-not $seen.Add($current) -or -not (Test-Path -LiteralPath $current -PathType Container)) { break }
            if (@(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop).Count -ne 0) { break }
            $deleteResult = Invoke-ToolkitUninstallRemoval -Path $current -Operation 'prune'
            Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $current
            if ($deleteResult.Status -ne 'Complete') { break }
            $current = Split-Path -Parent $current
        }
    }
    $runtimeRoots = @($runtimeTargets | ForEach-Object { [string]$_.Root } | Select-Object -Unique)
    foreach ($pruneRuntimeRoot in $runtimeRoots) {
      if (Test-Path -LiteralPath $pruneRuntimeRoot -PathType Container) {
        if (@(Get-ChildItem -LiteralPath $pruneRuntimeRoot -Force -ErrorAction Stop).Count -eq 0) {
            $deleteResult = Invoke-ToolkitUninstallRemoval -Path $pruneRuntimeRoot -Operation 'prune'
            Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $pruneRuntimeRoot
        }
      }
    }

    foreach ($managedRoot in $pruneRoots) {
        $managedRoot = [System.IO.Path]::GetFullPath($managedRoot)
        if (-not (Test-IsPathUnderOrEqual -ChildPath $managedRoot -ParentPath $root)) { throw ("Pruning root escapes adapter InstallRoot: {0}" -f $managedRoot) }
        if (-not (Test-Path -LiteralPath $managedRoot -PathType Container)) { continue }
        try {
            if (@(Get-ChildItem -LiteralPath $managedRoot -Force -ErrorAction Stop).Count -ne 0) { continue }
        }
        catch {
            $inspection = New-ToolkitUninstallTargetResult -Status Failed -TargetPath $managedRoot -Adapter $Adapter -Operation 'inspect-prune-root' -Reason $_.Exception.Message
            Add-ToolkitUninstallRemovalResult -Result $inspection -Path $managedRoot
            continue
        }
        $deleteResult = Invoke-ToolkitUninstallRemoval -Path $managedRoot -Operation 'prune'
        Add-ToolkitUninstallRemovalResult -Result $deleteResult -Path $managedRoot
        if ($deleteResult.Status -ne 'Complete') { continue }
        $null = $seen.Add($managedRoot)
    }

    if (-not $WhatIf.IsPresent) {
        # Retire per-root skill ownership manifests only after all listed skill
        # directories have disappeared. A malformed manifest is ambiguous and
        # remains visible as an incomplete target.
        foreach ($skillsRoot in @($managedSkillRoots | Select-Object -Unique)) {
            $skillsManifest = Join-Path $skillsRoot '.toolkit-managed-skills.json'
            if (-not (Test-Path -LiteralPath $skillsManifest -PathType Leaf)) { continue }
            try {
                $null = Assert-PathUnderInstallRootForDelete -CandidatePath $skillsManifest -InstallRoot $root
                $payload = Get-Content -LiteralPath $skillsManifest -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($null -eq $payload -or $null -eq $payload.PSObject.Properties['skills']) { throw 'skills-manifest-missing-skills-property' }
                $remainingSkills = @($payload.skills | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
                $activeSkills = New-Object 'System.Collections.Generic.List[string]'
                foreach ($skillName in $remainingSkills) {
                    $skillPath = Join-Path $skillsRoot ([string]$skillName)
                    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $skillPath -InstallRoot $root
                    if (Test-Path -LiteralPath $skillPath) { $activeSkills.Add([string]$skillName) | Out-Null }
                }
                if ($activeSkills.Count -gt 0) {
                    $result = New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $skillsManifest -Adapter $Adapter -Operation 'retire-skills-inventory' -Reason ('managed-skills-remain: ' + ($activeSkills.ToArray() -join ', '))
                    Add-ToolkitUninstallRemovalResult -Result $result -Path $skillsManifest
                    continue
                }
                $result = Invoke-ToolkitUninstallRemoval -Path $skillsManifest -Operation 'retire-skills-inventory'
                Add-ToolkitUninstallRemovalResult -Result $result -Path $skillsManifest
            }
            catch {
                $result = New-ToolkitUninstallTargetResult -Status Incomplete -TargetPath $skillsManifest -Adapter $Adapter -Operation 'retire-skills-inventory' -Reason $_.Exception.Message
                Add-ToolkitUninstallRemovalResult -Result $result -Path $skillsManifest
            }
        }
        # Retire only stale ownership records and the exact `.gitkeep` marker
        # that managed tree publishers copy as an empty-tree sentinel. Other
        # extant inventory paths remain dependencies and keep the inventory.
        try {
            $managedEntries = Read-ToolkitManagedPublishInventory -InstallRoot $root
            $inventoryPathsToRemove = New-Object System.Collections.Generic.List[string]
            foreach ($relativePath in @($managedEntries.Keys)) {
                $managedPath = Join-Path $root ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                if (-not (Test-Path -LiteralPath $managedPath)) {
                    $inventoryPathsToRemove.Add($relativePath) | Out-Null
                    continue
                }
                if ([System.IO.Path]::GetFileName($relativePath) -ceq '.gitkeep' -and (Test-Path -LiteralPath $managedPath -PathType Leaf)) {
                    if ($Adapter -eq 'copilot') {
                        # Copilot preserves these fixture/user placeholders;
                        # retire only the stale ownership record.
                        $inventoryPathsToRemove.Add($relativePath) | Out-Null
                    }
                    else {
                        $markerResult = Invoke-ToolkitUninstallRemoval -Path $managedPath -Operation 'remove-managed-tree-marker'
                        Add-ToolkitUninstallRemovalResult -Result $markerResult -Path $managedPath
                        if ($markerResult.Status -eq 'Complete') {
                            $inventoryPathsToRemove.Add($relativePath) | Out-Null
                            $markerParent = Split-Path -Parent $managedPath
                            if ((Test-Path -LiteralPath $markerParent -PathType Container) -and @(Get-ChildItem -LiteralPath $markerParent -Force -ErrorAction Stop).Count -eq 0) {
                                $parentResult = Invoke-ToolkitUninstallRemoval -Path $markerParent -Operation 'prune'
                                Add-ToolkitUninstallRemovalResult -Result $parentResult -Path $markerParent
                            }
                        }
                    }
                }
            }
            if ($inventoryPathsToRemove.Count -gt 0) {
                $null = Remove-ToolkitManagedPublishInventoryEntries -InstallRoot $root -RelativePaths @($inventoryPathsToRemove.ToArray())
            }
        }
        catch {
            $inventoryScan = New-ToolkitUninstallTargetResult -Status Failed -TargetPath (Join-Path $root '.toolkit-managed-publish.json') -Adapter $Adapter -Operation 'reconcile-inventory' -Reason $_.Exception.Message
            $targetResults.Add($inventoryScan) | Out-Null
            $incomplete.Add(('.toolkit-managed-publish.json: {0}' -f $_.Exception.Message)) | Out-Null
        }
        $inventoryRetirement = Remove-ToolkitManagedPublishInventoryIfEmpty -InstallRoot $root
        $inventoryResult = New-ToolkitUninstallTargetResult -Status $(if ($inventoryRetirement.Complete) { 'Complete' } else { 'Incomplete' }) -TargetPath (Join-Path $root '.toolkit-managed-publish.json') -Adapter $Adapter -Operation 'retire-inventory' -Reason $inventoryRetirement.Reason
        $targetResults.Add($inventoryResult) | Out-Null
        if (-not $inventoryRetirement.Complete) { $incomplete.Add(('{0}: {1}' -f '.toolkit-managed-publish.json', $inventoryRetirement.Reason)) | Out-Null }
        elseif ($inventoryRetirement.Removed) { $removed.Add((Join-Path $root '.toolkit-managed-publish.json')) | Out-Null }

        # Retire the lock only after all publishers have been excluded by the
        # shared lifecycle mutex and after inventory has no remaining users.
        if ($inventoryRetirement.Complete) {
            $lockRetirement = Remove-ToolkitFilesystemGateFile -RootPath $root -LockFileName '.toolkit-managed-publish.lock'
            $lockResult = New-ToolkitUninstallTargetResult -Status $(if ($lockRetirement.Complete) { 'Complete' } else { 'Incomplete' }) -TargetPath (Join-Path $root '.toolkit-managed-publish.lock') -Adapter $Adapter -Operation 'retire-lock' -Reason $lockRetirement.Reason
            $targetResults.Add($lockResult) | Out-Null
            if (-not $lockRetirement.Complete) { $incomplete.Add(('{0}: {1}' -f '.toolkit-managed-publish.lock', $lockRetirement.Reason)) | Out-Null }
            elseif ($lockRetirement.Removed) { $removed.Add((Join-Path $root '.toolkit-managed-publish.lock')) | Out-Null }
        }
        else { $incomplete.Add(('{0}: inventory-retirement-deferred' -f '.toolkit-managed-publish.lock')) | Out-Null }
    }

    return [PSCustomObject]@{
        Adapter = $Adapter
        RemovedPaths = @($removed.ToArray())
        IncompletePaths = @($incomplete.ToArray())
        TargetResults = @($targetResults.ToArray())
        Status = if ($targetResults.Count -eq 0) { 'Complete' } else { Get-ToolkitUninstallStatus -TargetResults @($targetResults.ToArray()) }
        WhatIf = [bool]$WhatIf.IsPresent
    }
    }
    finally {
        if ($lifecycleGateEntered) {
            Exit-ToolkitFilesystemGate -RootPath $root -LockFileName '.toolkit-managed-publish.lock'
        }
    }
}
