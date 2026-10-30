#Requires -Version 5.1
# Tests:
#   Should_ValidateSkillFrontmatterOverlay_When_ClaudeOverlayDeclared
#   Should_MergeClaudeOnlyFrontmatter_When_SkillsPublished
#   Should_KeepCoreSkillFrontmatterNeutral_When_ClaudePublished
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
. (Join-Path $scriptsRoot '_lib\New-ToolkitWorkRoot.ps1')
. (Join-Path $scriptsRoot '_lib\Resolve-InstallRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
. (Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1')

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }

function Get-TopLevelFrontmatterLines {
    param([string] $Text, [string] $Key)
    $frontmatter = (Split-ClaudeSkillFrontmatter -SkillText $Text -SkillLabel $Key).Frontmatter
    return @($frontmatter -split '\r?\n' | Where-Object { $_ -match ('^{0}:' -f [regex]::Escape($Key)) })
}

$coreSkillsRoot = Join-Path (Join-Path $repoRoot 'core') 'skills'
$overlay = Read-ClaudeSkillFrontmatterOverlay

# --- overlay targets exist in core, merge yields one line per field, core stays neutral ---
$n = 'Should_ValidateSkillFrontmatterOverlay_When_ClaudeOverlayDeclared'
foreach ($skillId in @($overlay.Keys)) {
    $skillFile = Join-Path (Join-Path $coreSkillsRoot $skillId) 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) { Write-Fail $n "overlay skill '$skillId' has no core SKILL.md" }
    $coreText = [System.IO.File]::ReadAllText($skillFile)
    $fields = $overlay[$skillId]
    foreach ($key in @($fields.Keys)) {
        if ($key -ne 'name' -and @(Get-TopLevelFrontmatterLines -Text $coreText -Key $key).Count -ne 0) {
            Write-Fail $n "core SKILL.md for '$skillId' must not carry Claude-only key '$key'"
        }
    }
    $merged = Merge-ClaudeSkillFrontmatterText -SkillText $coreText -Fields $fields -SkillLabel $skillId
    $mergedFrontmatter = (Split-ClaudeSkillFrontmatter -SkillText $merged -SkillLabel $skillId).Frontmatter
    $problems = @(Test-ClaudeSkillFrontmatterStructure -FrontmatterText $mergedFrontmatter)
    if ($problems.Count -gt 0) { Write-Fail $n ("merged frontmatter for '{0}' invalid: {1}" -f $skillId, ($problems -join '; ')) }
    foreach ($key in @($fields.Keys)) {
        $lines = @(Get-TopLevelFrontmatterLines -Text $merged -Key $key)
        $expected = '{0}: {1}' -f $key, (ConvertTo-ClaudeFrontmatterScalar -Value $fields[$key])
        if ($lines.Count -ne 1 -or $lines[0] -ne $expected) { Write-Fail $n ("'{0}' in '{1}' expected one line '{2}', got {3}" -f $key, $skillId, $expected, $lines.Count) }
    }
    $mergedAgain = Merge-ClaudeSkillFrontmatterText -SkillText $merged -Fields $fields -SkillLabel $skillId
    if ($mergedAgain -ne $merged) { Write-Fail $n ("merge is not idempotent for '{0}'" -f $skillId) }
}

$allCoreSkillFiles = @(Get-ChildItem -LiteralPath $coreSkillsRoot -Recurse -File -Filter 'SKILL.md')
foreach ($file in $allCoreSkillFiles) {
    $fm = (Split-ClaudeSkillFrontmatter -SkillText ([System.IO.File]::ReadAllText($file.FullName)) -SkillLabel $file.FullName).Frontmatter
    $problems = @(Test-ClaudeSkillFrontmatterStructure -FrontmatterText $fm)
    if ($problems.Count -gt 0) { Write-Fail $n ("core frontmatter invalid in {0}: {1}" -f $file.FullName, ($problems -join '; ')) }
}
Write-Pass $n

# --- publish twice into a work root: overlay applied, idempotent, body and other keys preserved ---
$n = 'Should_MergeClaudeOnlyFrontmatter_When_SkillsPublished'
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $installRoot = Join-Path $work 'install'
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    $first = Invoke-ClaudePublishSkills -InstallRoot $installRoot
    if ($null -eq $first -or $first.Success -ne $true) { Write-Fail $n ("first publish failed: {0}" -f $(if ($first) { $first.Message } else { 'null' })) }
    $second = Invoke-ClaudePublishSkills -InstallRoot $installRoot
    if ($null -eq $second -or $second.Success -ne $true) { Write-Fail $n ("second publish failed: {0}" -f $(if ($second) { $second.Message } else { 'null' })) }

    $publishedRoot = Join-Path $installRoot 'skills'
    foreach ($skillId in @($overlay.Keys)) {
        $publishedFile = Join-Path (Join-Path $publishedRoot $skillId) 'SKILL.md'
        if (-not (Test-Path -LiteralPath $publishedFile -PathType Leaf)) { Write-Fail $n "published SKILL.md missing for '$skillId'" }
        $publishedText = [System.IO.File]::ReadAllText($publishedFile)
        $publishedFrontmatter = (Split-ClaudeSkillFrontmatter -SkillText $publishedText -SkillLabel $skillId).Frontmatter
        $problems = @(Test-ClaudeSkillFrontmatterStructure -FrontmatterText $publishedFrontmatter)
        if ($problems.Count -gt 0) { Write-Fail $n ("published frontmatter invalid for '{0}': {1}" -f $skillId, ($problems -join '; ')) }
        foreach ($key in @($overlay[$skillId].Keys)) {
            $lines = @(Get-TopLevelFrontmatterLines -Text $publishedText -Key $key)
            $expected = '{0}: {1}' -f $key, (ConvertTo-ClaudeFrontmatterScalar -Value $overlay[$skillId][$key])
            if ($lines.Count -ne 1 -or $lines[0] -ne $expected) { Write-Fail $n ("published '{0}' for '{1}' expected '{2}', got {3} line(s)" -f $key, $skillId, $expected, $lines.Count) }
        }
    }

    $codeReviewDir = Join-Path $publishedRoot 'code-review'
    if (-not (Test-Path -LiteralPath (Join-Path $codeReviewDir 'SKILL.md') -PathType Leaf)) { Write-Fail $n 'code-review directory name must stay unchanged on disk' }

    $publishedDirs = @(Get-ChildItem -LiteralPath $publishedRoot -Directory | Where-Object { $_.Name -ne '_shared' })
    $unchangedSkill = $publishedDirs | Where-Object { $overlay.Keys -notcontains $_.Name } | Select-Object -First 1
    if ($null -eq $unchangedSkill) { Write-Fail $n 'expected at least one skill without overlay' }
    $coreUnchanged = [System.IO.File]::ReadAllText((Join-Path (Join-Path $coreSkillsRoot $unchangedSkill.Name) 'SKILL.md'))
    $publishedUnchanged = [System.IO.File]::ReadAllText((Join-Path $unchangedSkill.FullName 'SKILL.md'))
    if ((Split-ClaudeSkillFrontmatter -SkillText $coreUnchanged -SkillLabel 'core').Frontmatter -ne (Split-ClaudeSkillFrontmatter -SkillText $publishedUnchanged -SkillLabel 'published').Frontmatter) {
        Write-Fail $n ("skill '{0}' without overlay must keep its frontmatter" -f $unchangedSkill.Name)
    }
    Write-Pass $n

    # --- core neutrality: the core tree itself is unchanged by publish ---
    $n = 'Should_KeepCoreSkillFrontmatterNeutral_When_ClaudePublished'
    $coreCommit = [System.IO.File]::ReadAllText((Join-Path (Join-Path $coreSkillsRoot 'commit') 'SKILL.md'))
    if ($coreCommit -match '(?m)^disable-model-invocation:') { Write-Fail $n 'core commit SKILL.md was modified by Claude overlay' }
    if (@(Get-TopLevelFrontmatterLines -Text ([System.IO.File]::ReadAllText((Join-Path (Join-Path $coreSkillsRoot 'code-review') 'SKILL.md'))) -Key 'name') -notcontains 'name: code-review') {
        Write-Fail $n 'core code-review name must stay code-review'
    }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-ClaudeSkillFrontmatter: ALL PASS'
exit 0
