# Requires: PowerShell 5.1+
# Tests:
#   Should_HaveKebabSkillFolders_When_CoreSkillsCopied
#   Should_IncludeSharedGuidelines_When_CoreSkillsCopied
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$skillsRoot = Join-Path $repoRoot 'core\skills'

if (-not (Test-Path -LiteralPath $skillsRoot)) {
    Write-Error 'core/skills is missing'
    exit 1
}

$skillsItem = Get-Item -LiteralPath $skillsRoot
if ($skillsItem.LinkType) {
    Write-Error ("core/skills must be a real directory copy, not a {0}" -f $skillsItem.LinkType)
    exit 1
}

$skillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name)
if ($skillDirs.Count -lt 2) {
    Write-Error ("Expected multiple skill folders under core/skills; found {0}" -f $skillDirs.Count)
    exit 1
}

$nonKebab = @()
foreach ($dir in $skillDirs) {
    $name = $dir.Name
    if ($name -eq '_shared') {
        continue
    }
    if ($name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        $nonKebab += $name
    }
}

if ($nonKebab.Count -gt 0) {
    Write-Error ("Non-kebab skill folders: {0}" -f ($nonKebab -join ', '))
    exit 1
}

Write-Host 'Should_HaveKebabSkillFolders_When_CoreSkillsCopied: PASS'

$sharedRoot = Join-Path $skillsRoot '_shared'
if (-not (Test-Path -LiteralPath $sharedRoot)) {
    Write-Error 'core/skills/_shared is missing'
    exit 1
}

$sharedHasContent = @(Get-ChildItem -LiteralPath $sharedRoot -Recurse -File).Count -gt 0
if (-not $sharedHasContent) {
    Write-Error 'core/skills/_shared has no files'
    exit 1
}

Write-Host 'Should_IncludeSharedGuidelines_When_CoreSkillsCopied: PASS'
exit 0
