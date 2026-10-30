#Requires -Version 5.1
# Tests:
#   Should_SetToolsPerRole_When_ClaudeAgentsPublished
#   Should_KeepSpawnKnobs_When_ClaudeAgentToolsAdded
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

$coreAgentsRoot = Join-Path $repoRoot 'core\agents'
$coreAgentFiles = @(Get-ChildItem -LiteralPath $coreAgentsRoot -File -Filter '*.md')
$roleNames = @($coreAgentFiles | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) })

$n = 'Should_SetToolsPerRole_When_ClaudeAgentsPublished'
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $installRoot = Join-Path $work 'install'
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    $first = Invoke-ClaudePublishAgents -InstallRoot $installRoot
    if ($null -eq $first -or $first.Success -ne $true) { Write-Fail $n ("first publish failed: {0}" -f $(if ($first) { $first.Message } else { 'null' })) }
    $second = Invoke-ClaudePublishAgents -InstallRoot $installRoot
    if ($null -eq $second -or $second.Success -ne $true) { Write-Fail $n ("second publish failed: {0}" -f $(if ($second) { $second.Message } else { 'null' })) }

    if ($roleNames.Count -ne $script:ClaudeAgentToolsByRole.Count) {
        Write-Fail $n ("core has {0} agent(s) but tools map has {1}" -f $roleNames.Count, $script:ClaudeAgentToolsByRole.Count)
    }

    foreach ($role in $roleNames) {
        if (-not $script:ClaudeAgentToolsByRole.Contains($role)) { Write-Fail $n "no tools mapping for core agent '$role'" }
        $publishedFile = Join-Path (Join-Path $installRoot 'agents') ($role + '.md')
        if (-not (Test-Path -LiteralPath $publishedFile -PathType Leaf)) { Write-Fail $n "published agent missing: $role" }
        $text = [System.IO.File]::ReadAllText($publishedFile)
        $frontmatter = (Split-ClaudeSkillFrontmatter -SkillText $text -SkillLabel $role).Frontmatter
        $problems = @(Test-ClaudeSkillFrontmatterStructure -FrontmatterText $frontmatter)
        if ($problems.Count -gt 0) { Write-Fail $n ("frontmatter invalid for '{0}': {1}" -f $role, ($problems -join '; ')) }

        $toolsLines = @($frontmatter -split '\r?\n' | Where-Object { $_ -match '^tools:' })
        $expectedTools = 'tools: ' + [string]$script:ClaudeAgentToolsByRole[$role]
        if ($toolsLines.Count -ne 1 -or $toolsLines[0] -ne $expectedTools) {
            Write-Fail $n ("'{0}' expected one line '{1}', got {2}" -f $role, $expectedTools, ($toolsLines -join ' | '))
        }
        $disallowed = @($frontmatter -split '\r?\n' | Where-Object { $_ -eq 'disallowedTools: Agent' })
        if ($disallowed.Count -ne 1) { Write-Fail $n "'$role' must keep exactly one 'disallowedTools: Agent'" }
        $modelLines = @($frontmatter -split '\r?\n' | Where-Object { $_ -eq 'model: inherit' })
        if ($modelLines.Count -ne 1) { Write-Fail $n "'$role' must keep exactly one 'model: inherit'" }
    }
    Write-Pass $n

    $n = 'Should_KeepSpawnKnobs_When_ClaudeAgentToolsAdded'
    Assert-MarkdownAgentsSpawnKnobs -AgentsRoot (Join-Path $installRoot 'agents') -Label 'claude-agents-tools'
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-ClaudeAgentTools: ALL PASS'
exit 0
