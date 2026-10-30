#Requires -Version 5.1
# Tests:
#   Should_PublishClaudeRulesWithoutCursorOnlyKeys_When_PolicyPublished
#   Should_NotPublishPlaceholderOrScriptFiles_When_PolicyPublished
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

$coreRoot = Join-Path $repoRoot 'core\policy'
$coreMarkdown = @(Get-ChildItem -LiteralPath $coreRoot -File -Filter '*.md' | Where-Object { $script:ClaudeUnpublishedPolicyFileNames -notcontains $_.Name })

$n = 'Should_PublishClaudeRulesWithoutCursorOnlyKeys_When_PolicyPublished'
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $installRoot = Join-Path $work 'install'
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    $first = Invoke-ClaudePublishPolicy -InstallRoot $installRoot
    if ($null -eq $first -or $first.Success -ne $true) { Write-Fail $n ("first publish failed: {0}" -f $(if ($first) { $first.Message } else { 'null' })) }
    $second = Invoke-ClaudePublishPolicy -InstallRoot $installRoot
    if ($null -eq $second -or $second.Success -ne $true) { Write-Fail $n ("second publish failed: {0}" -f $(if ($second) { $second.Message } else { 'null' })) }

    $rulesRoot = Join-Path $installRoot 'rules'
    $publishedFiles = @(Get-ChildItem -LiteralPath $rulesRoot -Recurse -File)
    $publishedMarkdown = @($publishedFiles | Where-Object { $_.Extension -eq '.md' })
    if ($publishedMarkdown.Count -ne $coreMarkdown.Count) {
        Write-Fail $n ("expected {0} published rule(s), found {1}" -f $coreMarkdown.Count, $publishedMarkdown.Count)
    }

    foreach ($file in $publishedMarkdown) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        if ($text -match '(?m)^alwaysApply:') { Write-Fail $n ("alwaysApply must not be published: {0}" -f $file.Name) }
        if ($text -match '(?m)^globs:') { Write-Fail $n ("Cursor globs must be mapped or dropped: {0}" -f $file.Name) }
        $frontmatterMatch = [regex]::Match($text, '\A---\r?\n(?<fm>.*?)\r?\n---', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($frontmatterMatch.Success) {
            $problems = @(Test-ClaudeSkillFrontmatterStructure -FrontmatterText $frontmatterMatch.Groups['fm'].Value)
            if ($problems.Count -gt 0) { Write-Fail $n ("frontmatter invalid in {0}: {1}" -f $file.Name, ($problems -join '; ')) }
            if ($frontmatterMatch.Groups['fm'].Value -notmatch '(?m)^description:') { Write-Fail $n ("description must be kept: {0}" -f $file.Name) }
        }
    }

    $coreSample = Join-Path $coreRoot 'guardrails.md'
    if (-not ([System.IO.File]::ReadAllText($coreSample) -match '(?m)^alwaysApply: true')) { Write-Fail $n 'core policy must keep alwaysApply (Cursor source)' }
    Write-Pass $n

    $n = 'Should_NotPublishPlaceholderOrScriptFiles_When_PolicyPublished'
    $scriptFiles = @($publishedFiles | Where-Object { $_.Extension -eq '.ps1' })
    if ($scriptFiles.Count -gt 0) { Write-Fail $n ("rules/ must not contain .ps1: {0}" -f (($scriptFiles | ForEach-Object { $_.Name }) -join ', ')) }
    foreach ($retired in @($script:ClaudeUnpublishedPolicyFileNames)) {
        if (Test-Path -LiteralPath (Join-Path $rulesRoot $retired)) { Write-Fail $n "retired placeholder published: $retired" }
    }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-ClaudePolicyRules: ALL PASS'
exit 0
