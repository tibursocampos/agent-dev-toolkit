#Requires -Version 5.1
<#
.SYNOPSIS
  Validates skill contract markers declared in skill-contracts.json.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot,
    [string] $ContractPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$contractsFileName = 'skill-contracts.json'
$contractsRelativeDir = 'contracts'
. (Join-Path (Split-Path -Parent $PSScriptRoot) '_lib\ToolkitValidationFileSystem.ps1')
. (Join-Path $PSScriptRoot '_lib\ToolkitPhysicalPath.ps1')

if (-not $RepoRoot) {
    . (Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) '_lib') 'Get-ToolkitRepoRoot.ps1')
    $RepoRoot = Get-ToolkitRepoRoot -FromPath $PSScriptRoot
}

$contractsPath = if ($ContractPath) { $ContractPath } else { Join-Path $PSScriptRoot (Join-Path $contractsRelativeDir $contractsFileName) }
if (-not (Test-Path -LiteralPath $contractsPath)) {
    Write-Host "Missing contracts file: $contractsPath" -ForegroundColor Red
    exit 1
}

$doc = Read-ToolkitValidationText -Path $contractsPath | ConvertFrom-Json
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$failures = New-Object System.Collections.Generic.List[string]

try {
    $skillsRoot = Resolve-ToolkitContainedPath -RootPath $RepoRoot -RelativePath ([string]$doc.skillsRoot)
}
catch {
    Write-Host ("Invalid skillsRoot path: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

function Resolve-SkillContractFilePath {
    param([string] $Skill, [string] $FileName)
    $skillRoot = Resolve-ToolkitContainedPath -RootPath $skillsRoot -RelativePath $Skill
    return Resolve-ToolkitContainedPath -RootPath $skillRoot -RelativePath $FileName
}

# The route matrix is validation metadata only. Check its explicit file routes
# and ownership without treating it as a runtime loader manifest.
if ($doc.PSObject.Properties.Name -contains 'referenceRoutes') {
    $routeSkills = @{}
    foreach ($entry in @($doc.referenceRoutes)) {
        $skill = [string]$entry.skill
        if ([string]::IsNullOrWhiteSpace($skill) -or $routeSkills.ContainsKey($skill)) {
            $failures.Add(("referenceRoutes/{0}/mode=unknown/rule=skill must be nonempty and unique" -f $skill))
            continue
        }
        $routeSkills[$skill] = $true
        $owner = [string]$entry.owner
        $ownerRelativePath = if ($owner.StartsWith('core/skills/')) { $owner.Substring('core/skills/'.Length) } else { $owner }
        try {
            [void](Resolve-ToolkitContainedPath -RootPath $skillsRoot -RelativePath $ownerRelativePath)
        }
        catch {
            $failures.Add(("referenceRoutes/{0}/mode=all/rule=owner-path invalid: {1} ({2})" -f $skill, $owner, $_.Exception.Message))
        }
        $modes = @{}
        foreach ($route in @($entry.routes)) {
            $mode = [string]$route.mode
            if ([string]::IsNullOrWhiteSpace($mode) -or [string]::IsNullOrWhiteSpace([string]$route.condition)) {
                $failures.Add(("referenceRoutes/{0}/mode={1}/rule=condition mode and condition are required" -f $skill, $mode))
            }
            if ($modes.ContainsKey($mode)) { $failures.Add(("referenceRoutes/{0}/mode={1}/rule=mode duplicated" -f $skill, $mode)) }
            $modes[$mode] = $true
            $required = @($route.required)
            $conditional = @($route.conditional)
            $excluded = @($route.excluded)
            foreach ($value in $required + $conditional + $excluded) {
                if ([string]::IsNullOrWhiteSpace([string]$value)) { $failures.Add(("referenceRoutes/{0}/mode={1}/rule=path empty entry" -f $skill, $mode)) }
            }
            foreach ($value in $required + $conditional) {
                if ($excluded -contains $value) { $failures.Add(("referenceRoutes/{0}/mode={1}/rule=path classified both included and excluded: {2}" -f $skill, $mode, $value)) }
            }
            foreach ($value in $required + $conditional) {
                # Only literal repository-relative paths are checked. Descriptive
                # route labels (for example, a selected stack) are not paths.
                $match = [regex]::Match([string]$value, '(?:^|\s)(core/skills/[^\s]+|references/[^\s<>]+|_shared/[^\s]+)')
                if (-not $match.Success) { continue }
                $relative = $match.Groups[1].Value -replace '[,;.)]+$',''
                if (@($relative -split '[\\/]+' | Where-Object { $_ -eq '..' }).Count -gt 0) {
                    $failures.Add(("referenceRoutes/{0}/mode={1}/rule=path-traversal rejected: {2}" -f $skill, $mode, $relative))
                    continue
                }
                if ($relative.StartsWith('core/skills/')) {
                    $baseRoot = $skillsRoot
                    $candidate = Join-Path $skillsRoot ($relative.Substring('core/skills/'.Length))
                }
                elseif ($relative.StartsWith('_shared/')) {
                    $baseRoot = $skillsRoot
                    $candidate = Join-Path $skillsRoot $relative
                }
                else {
                    $baseRoot = Join-Path $skillsRoot $skill
                    $candidate = Join-Path $baseRoot $relative
                }
                try {
                    $withinPhysicalRoot = Test-ToolkitPathWithinRoot -RootPath $baseRoot -CandidatePath $candidate
                    $resolvedCandidate = Resolve-ToolkitPhysicalPath -Path $candidate
                }
                catch {
                    $failures.Add(("referenceRoutes/{0}/mode={1}/rule=path-resolution failed for {2}: {3}" -f $skill, $mode, $relative, $_.Exception.Message))
                    continue
                }
                if (-not $withinPhysicalRoot) {
                    $failures.Add(("referenceRoutes/{0}/mode={1}/rule=path-outside-root rejected: {2}" -f $skill, $mode, $relative))
                    continue
                }
                if (-not (Test-Path -LiteralPath $resolvedCandidate -PathType Leaf)) {
                    $failures.Add(("referenceRoutes/{0}/mode={1}/rule=path missing: {2}" -f $skill, $mode, $relative))
                }
            }
        }
        foreach ($shared in @($entry.sharedRules)) {
            $sharedOwner = [string]$shared.owner
            $sharedOwnerRelativePath = if ($sharedOwner.StartsWith('core/skills/')) { $sharedOwner.Substring('core/skills/'.Length) } else { $sharedOwner }
            try {
                [void](Resolve-ToolkitContainedPath -RootPath $skillsRoot -RelativePath $sharedOwnerRelativePath)
            }
            catch {
                $failures.Add(("referenceRoutes/{0}/mode=all/rule=shared-owner-path invalid: {1} ({2})" -f $skill, $sharedOwner, $_.Exception.Message))
            }
            if (@($shared.consumers).Count -gt 0 -and (@($shared.consumers) -notcontains $skill) -and ([string]$shared.consumers -notmatch [regex]::Escape($skill))) {
                $failures.Add(("referenceRoutes/{0}/mode=all/rule=shared-owner consumer list omits skill" -f $skill))
            }
        }
    }
}

if ($doc.PSObject.Properties.Name -contains 'complexitySources') {
    $seenSources = @{}
    foreach ($sourceRule in @($doc.complexitySources)) {
        $skill = [string]$sourceRule.skill; $mode = [string]$sourceRule.mode; $source = [string]$sourceRule.source
        $key = "$skill|$mode"
        if ($seenSources.ContainsKey($key)) { $failures.Add(("complexitySources/{0}/mode={1}/rule=duplicate" -f $skill, $mode)) }
        $seenSources[$key] = $true
        $expected = if ($skill -eq 'sdd-plan' -and $mode -eq 'Classic direct') { 'approved PRD' } elseif ($skill -eq 'sdd-plan' -and $mode -eq 'O2') { 'FEATURE' } else { $null }
        if ($null -eq $expected -or $source -cne $expected) {
            $failures.Add(("complexitySources/{0}/mode={1}/rule=source expected '{2}', got '{3}'" -f $skill, $mode, $expected, $source))
        }
    }
    foreach ($requiredRule in @(@{Skill='sdd-plan';Mode='Classic direct'}, @{Skill='sdd-plan';Mode='O2'})) {
        if (-not $seenSources.ContainsKey("$($requiredRule.Skill)|$($requiredRule.Mode)")) {
            $failures.Add(("complexitySources/{0}/mode={1}/rule=source missing" -f $requiredRule.Skill, $requiredRule.Mode))
        }
    }
}

if ($doc.PSObject.Properties.Name -contains 'mustNotExistSkills' -and $doc.mustNotExistSkills) {
    foreach ($entry in @($doc.mustNotExistSkills)) {
        try {
            $forbiddenPath = Get-ToolkitSafeRelativePath -RootPath $skillsRoot -RelativePath ([string]$entry.skill)
        }
        catch {
            $failures.Add(("{0}: mustNotExistSkills/{1}/rule=path invalid: {2}" -f $entry.id, $entry.skill, $_.Exception.Message))
            continue
        }
        if (Test-ToolkitForbiddenPathEntryExists -RootPath $skillsRoot -RelativePath ([string]$entry.skill)) {
            try {
                [void](Resolve-ToolkitContainedPath -RootPath $skillsRoot -RelativePath ([string]$entry.skill))
                $failures.Add("$($entry.id): forbidden skill folder exists at $($entry.skill)")
            }
            catch {
                $failures.Add(("{0}: mustNotExistSkills/{1}/rule=path invalid: {2}" -f $entry.id, $entry.skill, $_.Exception.Message))
            }
        }
        else {
            Write-Host ("{0}: PASS (no {1}/)" -f $entry.id, $entry.skill)
        }
    }
}

if ($doc.PSObject.Properties.Name -contains 'mustExistPaths' -and $doc.mustExistPaths) {
    foreach ($entry in @($doc.mustExistPaths)) {
        try {
            [void](Resolve-ToolkitContainedPath -RootPath $RepoRoot -RelativePath ([string]$entry.path))
            Write-Host ("{0}: PASS (exists {1})" -f $entry.id, $entry.path)
        }
        catch {
            $failures.Add(("{0}: mustExistPaths/{1}/rule=path invalid or missing: {2}" -f $entry.id, $entry.path, $_.Exception.Message))
        }
    }
}

foreach ($c in $doc.contracts) {
    # match: each-file (default) = every listed file must hold all markers;
    # any-file = packing-aware union — each mustContain needle in at least one file
    # (SKILL router + references/ after composable split).
    $matchMode = 'each-file'
    if ($c.PSObject.Properties.Name -contains 'match' -and -not [string]::IsNullOrWhiteSpace([string]$c.match)) {
        $matchMode = [string]$c.match
    }

    if ($matchMode -eq 'any-file') {
        $combined = New-Object System.Text.StringBuilder
        $resolvedLabels = New-Object System.Collections.Generic.List[string]
        foreach ($fileName in $c.files) {
            try { $path = Resolve-SkillContractFilePath -Skill ([string]$c.skill) -FileName ([string]$fileName) }
            catch {
                $failures.Add(("{0}: skill={1} rule=file-path invalid {2}: {3}" -f $c.id, $c.skill, $fileName, $_.Exception.Message))
                continue
            }
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                $failures.Add("$($c.id): missing file $($c.skill)/$fileName")
                continue
            }
            $text = Read-ToolkitValidationText -Path $path
            [void]$combined.AppendLine($text)
            $resolvedLabels.Add("$($c.skill)/$fileName")
            if ($c.PSObject.Properties.Name -contains 'mustNotContain' -and $c.mustNotContain) {
                foreach ($needle in $c.mustNotContain) {
                    if ($text.Contains($needle)) {
                        $failures.Add("$($c.id): $($c.skill)/$fileName contains forbidden '$needle'")
                    }
                }
            }
        }
        if ($resolvedLabels.Count -eq 0) {
            continue
        }
        $allText = $combined.ToString()
        $label = ($resolvedLabels -join ' | ')
        if ($c.PSObject.Properties.Name -contains 'mustContain' -and $c.mustContain) {
            foreach ($needle in $c.mustContain) {
                if ($allText -notmatch [regex]::Escape($needle)) {
                    $failures.Add("$($c.id): $label missing required marker '$needle'")
                }
            }
        }
        if ($c.PSObject.Properties.Name -contains 'mustContainAny' -and $c.mustContainAny) {
            $anyHit = $false
            foreach ($needle in $c.mustContainAny) {
                if ($allText -match [regex]::Escape($needle)) { $anyHit = $true; break }
            }
            if (-not $anyHit) {
                $failures.Add("$($c.id): $label missing any of: $($c.mustContainAny -join ' | ')")
            }
        }
        continue
    }

    foreach ($fileName in $c.files) {
        try { $path = Resolve-SkillContractFilePath -Skill ([string]$c.skill) -FileName ([string]$fileName) }
        catch {
            $failures.Add(("{0}: skill={1} rule=file-path invalid {2}: {3}" -f $c.id, $c.skill, $fileName, $_.Exception.Message))
            continue
        }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $failures.Add("$($c.id): missing file $($c.skill)/$fileName")
            continue
        }
        $text = Read-ToolkitValidationText -Path $path
        if ($c.PSObject.Properties.Name -contains 'mustContain' -and $c.mustContain) {
            foreach ($needle in $c.mustContain) {
                if ($text -notmatch [regex]::Escape($needle)) {
                    $failures.Add("$($c.id): $($c.skill)/$fileName missing required marker '$needle'")
                }
            }
        }
        if ($c.PSObject.Properties.Name -contains 'mustContainAny' -and $c.mustContainAny) {
            $anyHit = $false
            foreach ($needle in $c.mustContainAny) {
                if ($text -match [regex]::Escape($needle)) { $anyHit = $true; break }
            }
            if (-not $anyHit) {
                $failures.Add("$($c.id): $($c.skill)/$fileName missing any of: $($c.mustContainAny -join ' | ')")
            }
        }
        if ($c.PSObject.Properties.Name -contains 'mustNotContain' -and $c.mustNotContain) {
            foreach ($needle in $c.mustNotContain) {
                if ($text.Contains($needle)) {
                    $failures.Add("$($c.id): $($c.skill)/$fileName contains forbidden '$needle'")
                }
            }
        }
    }
}

if ($doc.PSObject.Properties.Name -contains 'mustNotContain' -and $doc.mustNotContain) {
    # Scan all skill files under skillsRoot (incl. _shared) for IDE home-path needles.
    $files = @(Get-ToolkitValidationFiles -Root $skillsRoot -Recurse -Extensions @('.md', '.mdc', '.json', '.ps1', '.yml', '.yaml', '.txt'))
    foreach ($file in $files) {
        $text = Read-ToolkitValidationText -Path $file.FullName
        foreach ($needle in @($doc.mustNotContain)) {
            if ($text.Contains($needle)) {
                $rel = $file.FullName.Substring($skillsRoot.Length).TrimStart('\', '/')
                $failures.Add("global-mustNotContain: $rel contains forbidden '$needle'")
            }
        }
    }
}

# CA7 — YAML frontmatter description quoting check
# Find all SKILL.md files under skillsRoot and verify that any description value
# containing ': ' is wrapped in quotes, to prevent YAML parser failures.
$skillFiles = @(Get-ToolkitValidationFiles -Root $skillsRoot -Recurse -Extensions @('.md') |
    Where-Object { $_.Name -eq 'SKILL.md' })
foreach ($sf in $skillFiles) {
    $lines = (Read-ToolkitValidationText -Path $sf.FullName) -split "`n"
    $inFrontmatter = $false
    $frontmatterCount = 0
    foreach ($line in $lines) {
        $trimmed = $line.TrimEnd()
        if ($trimmed -eq '---') {
            $frontmatterCount++
            if ($frontmatterCount -eq 1) { $inFrontmatter = $true; continue }
            if ($frontmatterCount -eq 2) { $inFrontmatter = $false; break }
        }
        if ($inFrontmatter -and $trimmed -match '^description:\s+(.+)$') {
            $val = $Matches[1]
            # If value contains ': ' and is not already quoted (starts with " or ')
            if ($val -match ':\s' -and $val -notmatch '^["'']') {
                $rel = $sf.FullName.Substring($skillsRoot.Length).TrimStart('\', '/')
                $failures.Add("CA7: $rel has unquoted description value containing ': ' — wrap in double quotes")
            }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'Skill contracts validation FAILED:' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Skill contracts validation passed.' -ForegroundColor Green
exit 0
