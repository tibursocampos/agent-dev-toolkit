#Requires -Version 5.1
# Tests:
#   Should_PruneRetiredAgentsAndNestedSkillFiles_When_ClaudeSyncRunsAgain
#   Should_KeepEditedAndAlienFiles_When_ClaudeSyncPrunesRetiredFiles
#   Should_RemoveRetiredAgent_When_ClaudeUninstallRuns
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
. (Join-Path $scriptsRoot '_lib\New-ToolkitWorkRoot.ps1')
. (Join-Path $scriptsRoot '_lib\Resolve-InstallRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
. (Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1')
. (Join-Path $repoRoot 'adapters\claude\Uninstall-ClaudeToolkit.ps1')

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }

$retiredAgent = 'retired-agent.md'
$editedAgent = 'retired-edited-agent.md'
$alienAgent = 'user-own-agent.md'
$retiredSkillFiles = @(
    '_shared/retired-flow/FLOW.md',
    '_shared/agents/prompts/retired-prompt.md'
)

function Add-RetiredInstall {
    param([string] $InstallRoot)

    $agentsRoot = Join-Path $InstallRoot 'agents'
    $skillsRoot = Join-Path $InstallRoot 'skills'
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($name in @($retiredAgent, $editedAgent)) {
        $path = Join-Path $agentsRoot $name
        [System.IO.File]::WriteAllText($path, "---`nname: old`n---`nold body`n")
        $paths.Add($path) | Out-Null
    }
    foreach ($relative in $retiredSkillFiles) {
        $path = Join-Path $skillsRoot ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        [System.IO.File]::WriteAllText($path, "old shared body`n")
        $paths.Add($path) | Out-Null
    }
    Update-ToolkitManagedCopyInventory -InstallRoot $InstallRoot -Paths @($paths.ToArray())
    [System.IO.File]::WriteAllText((Join-Path $agentsRoot $editedAgent), "---`nname: old`n---`nedited by operator`n")
    [System.IO.File]::WriteAllText((Join-Path $agentsRoot $alienAgent), "user agent`n")
}

$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $installRoot = Join-Path $work 'install'
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    $agentsRoot = Join-Path $installRoot 'agents'
    $skillsRoot = Join-Path $installRoot 'skills'

    $null = Invoke-ClaudePublishAgents -InstallRoot $installRoot
    $null = Invoke-ClaudePublishSkills -InstallRoot $installRoot
    Add-RetiredInstall -InstallRoot $installRoot

    $null = Invoke-ClaudePublishAgents -InstallRoot $installRoot
    $null = Invoke-ClaudePublishSkills -InstallRoot $installRoot

    $n = 'Should_PruneRetiredAgentsAndNestedSkillFiles_When_ClaudeSyncRunsAgain'
    if (Test-Path -LiteralPath (Join-Path $agentsRoot $retiredAgent)) { Write-Fail $n 'retired agent survived sync' }
    foreach ($relative in $retiredSkillFiles) {
        $path = Join-Path $skillsRoot ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $path) { Write-Fail $n "retired nested skill file survived sync: $relative" }
    }
    if (Test-Path -LiteralPath (Join-Path $skillsRoot '_shared\retired-flow')) { Write-Fail $n 'empty retired directory survived sync' }
    foreach ($agentFile in @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'core\agents') -File -Filter '*.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $agentsRoot $agentFile.Name))) { Write-Fail $n "current agent missing after prune: $($agentFile.Name)" }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $skillsRoot '_shared'))) { Write-Fail $n 'current _shared tree missing after prune' }
    Write-Pass $n

    $n = 'Should_KeepEditedAndAlienFiles_When_ClaudeSyncPrunesRetiredFiles'
    if (-not (Test-Path -LiteralPath (Join-Path $agentsRoot $editedAgent))) { Write-Fail $n 'operator-edited retired agent was deleted' }
    if (-not (Test-Path -LiteralPath (Join-Path $agentsRoot $alienAgent))) { Write-Fail $n 'alien agent was deleted' }
    Write-Pass $n

    $n = 'Should_RemoveRetiredAgent_When_ClaudeUninstallRuns'
    Add-RetiredInstall -InstallRoot $installRoot
    $result = Invoke-ClaudeUninstallToolkit -InstallRoot $installRoot
    if ($null -eq $result) { Write-Fail $n "uninstall returned null" }
    if (Test-Path -LiteralPath (Join-Path $agentsRoot $retiredAgent)) { Write-Fail $n 'retired agent survived uninstall' }
    if (Test-Path -LiteralPath (Join-Path $skillsRoot '_shared')) { Write-Fail $n '_shared survived uninstall' }
    if (-not (Test-Path -LiteralPath (Join-Path $agentsRoot $alienAgent))) { Write-Fail $n 'alien agent removed by uninstall' }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-RetiredManagedFilesPruned: ALL PASS'
exit 0
