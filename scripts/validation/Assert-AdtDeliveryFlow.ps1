#Requires -Version 5.1
# Structural validator for the adt-delivery-* skills and their shared contract files.
# Checks: shared files exist; each SKILL.md has name/description frontmatter; every cited
# {{TOOLKIT_ROOT}}/skills/, /scripts/ and /rules/*.mdc path resolves.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$skillsRoot = Join-Path $repoRoot 'core/skills'
$policyRoot = Join-Path $repoRoot 'core/policy'
$adtSharedRoot = Join-Path $skillsRoot '_shared/adt-delivery'
$skillIds = @('adt-delivery-flow', 'adt-delivery-refine', 'adt-delivery-plan', 'adt-delivery-implement')
$sharedFileNames = @('STORAGE-FEATURE.md', 'PLAN-LIFECYCLE.md', 'PLAN-TEMPLATE.md', 'TRIAGE.md', 'DISPLAY.md', 'HANDOFF.md', 'SCENARIOS.md')
$citePattern = '\{\{TOOLKIT_ROOT\}\}/(skills|scripts|rules)/([^\s\x60"''()|]+)'
$script:failureCount = 0

function Write-Result([string] $TestName, [string[]] $Problems) {
    $list = @($Problems | Where-Object { $_ })
    if ($list.Count -eq 0) {
        Write-Host ('{0}: PASS' -f $TestName)
        return
    }
    foreach ($problem in $list) {
        $script:failureCount++
        Write-Host ('{0}: FAIL - {1}' -f $TestName, $problem)
    }
}

function Get-RelativePath([string] $FullPath) { $FullPath.Substring($repoRoot.Length).TrimStart('\', '/').Replace('\', '/') }

function Get-MarkdownFiles([string] $Directory, [switch] $Recurse) {
    if (Test-Path -LiteralPath $Directory -PathType Container) {
        return @(Get-ChildItem -LiteralPath $Directory -File -Filter '*.md' -Recurse:$Recurse | ForEach-Object { $_.FullName })
    }
    return @()
}

function Get-SharedFileProblems {
    foreach ($name in $sharedFileNames) {
        $path = Join-Path $adtSharedRoot $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { "core/skills/_shared/adt-delivery/${name}: missing" }
    }
}

function Get-SkillFileProblems {
    foreach ($id in $skillIds) {
        $path = Join-Path (Join-Path $skillsRoot $id) 'SKILL.md'
        $rel = Get-RelativePath $path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { "${rel}: missing"; continue }
        $lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
        if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') { "${rel}: frontmatter must start with '---'"; continue }
        $end = -1
        for ($i = 1; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq '---') { $end = $i; break } }
        if ($end -lt 0) { "${rel}: frontmatter closing '---' missing"; continue }
        $name = $null; $description = $null
        for ($i = 1; $i -lt $end; $i++) {
            if ($lines[$i].StartsWith('name:')) { $name = $lines[$i].Substring(5).Trim() }
            if ($lines[$i].StartsWith('description:')) { $description = $lines[$i].Substring(12).Trim() }
        }
        if ($name -ne $id) { "${rel}: frontmatter name must equal '$id'" }
        if ([string]::IsNullOrWhiteSpace($description)) { "${rel}: frontmatter description missing or empty" }
    }
}

function Get-CitePathProblems {
    $files = @()
    foreach ($id in $skillIds) {
        $skillDir = Join-Path $skillsRoot $id
        $files += Join-Path $skillDir 'SKILL.md'
        $files += Get-MarkdownFiles -Directory (Join-Path $skillDir 'references')
    }
    $files += Get-MarkdownFiles -Directory $adtSharedRoot -Recurse
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        $rel = Get-RelativePath $file
        $fileLines = [System.IO.File]::ReadAllLines($file, [System.Text.Encoding]::UTF8)
        for ($i = 0; $i -lt $fileLines.Count; $i++) {
            foreach ($match in [regex]::Matches($fileLines[$i], $citePattern)) {
                $kind = $match.Groups[1].Value
                $rest = ($match.Groups[2].Value -split '#')[0].TrimEnd('.', ',', ';', ':', '/')
                if ($rest.Length -eq 0 -or $rest.IndexOfAny([char[]]@('<', '*', ' ')) -ge 0) { continue }
                $target = ''
                if ($kind -eq 'skills') { $target = Join-Path $skillsRoot $rest }
                elseif ($kind -eq 'scripts') { $target = Join-Path (Join-Path $repoRoot 'scripts') $rest }
                elseif ($rest.EndsWith('.mdc', [System.StringComparison]::Ordinal)) {
                    $target = Join-Path $policyRoot (($rest.Substring(0, $rest.Length - 4)) + '.md')
                }
                if ($target -and -not (Test-Path -LiteralPath $target -PathType Leaf)) {
                    "${rel}:$($i + 1): cited path does not resolve: {{TOOLKIT_ROOT}}/$kind/$rest"
                }
            }
        }
    }
}

Write-Result 'Should_HaveSharedFiles_When_ADTSharedRead' @(Get-SharedFileProblems)
Write-Result 'Should_HaveValidFrontmatter_When_ADTSkillsRead' @(Get-SkillFileProblems)
Write-Result 'Should_ResolveEveryCitedPath_When_ADTFilesRead' @(Get-CitePathProblems)

if ($script:failureCount -gt 0) {
    Write-Host ('Assert-AdtDeliveryFlow: FAILED with {0} problem(s)' -f $script:failureCount)
    exit 1
}
Write-Host 'Assert-AdtDeliveryFlow: ALL PASS'
exit 0
