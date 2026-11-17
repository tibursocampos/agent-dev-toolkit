#Requires -Version 5.1
# Tests:
#   Should_PruneRetiredAgentsAndNestedSkillFiles_When_ClaudeSyncRunsAgain
#   Should_KeepEditedAndAlienFiles_When_ClaudeSyncPrunesRetiredFiles
#   Should_RemoveRetiredAgent_When_ClaudeUninstallRuns
#   Should_PublishCodexAgents_When_FirstRun
#   Should_DeleteNothing_When_CodexPublishRunsWhatIf
#   Should_PruneRetiredCodexAgent_When_CodexSyncRunsAgain
#   Should_KeepEditedRetiredCodexAgent_When_CodexSyncPrunesIt
#   Should_LeaveUnrecordedUserAgentUntouched_When_CodexSyncRuns
#   Should_DeleteNothing_When_CodexUninstallRunsWhatIf
#   Should_RemoveRecordedRetiredCodexAgent_When_CodexUninstallRuns
#   Should_ReleaseCodexAgentInventoryEntries_When_CodexUninstallRemovesThem
#   Should_KeepEditedRetiredCodexAgent_When_CodexUninstallRuns
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
. (Join-Path $scriptsRoot '_lib\New-ToolkitWorkRoot.ps1')
. (Join-Path $scriptsRoot '_lib\Resolve-InstallRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
. (Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1')
. (Join-Path $repoRoot 'adapters\claude\Uninstall-ClaudeToolkit.ps1')
. (Join-Path $repoRoot 'adapters\codex\CodexAdapter.ps1')
. (Join-Path $scriptsRoot '_lib\ToolkitManagedPublishInventory.ps1')

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

function Add-CodexRecordedAgent {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $Name
    )

    $utf8 = New-Object System.Text.UTF8Encoding $false
    $content = "name = '{0}'`n" -f [System.IO.Path]::GetFileNameWithoutExtension($Name)
    $path = Join-Path (Join-Path $InstallRoot 'agents') $Name
    $null = Write-ToolkitFileIfAbsent -Path $path -Content $content -Encoding $utf8 -InstallRoot $InstallRoot -RelativePath ('agents/' + $Name)
}

function Test-CodexInventoryHasAgent {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $Name
    )

    return (Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot).ContainsKey('agents/' + $Name)
}

$codexWork = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $codexRoot = Join-Path $codexWork 'codex-home'
    New-Item -ItemType Directory -Path $codexRoot -Force | Out-Null
    $codexAgentsRoot = Join-Path $codexRoot 'agents'
    $codexSourceNames = @(
        Get-ChildItem -LiteralPath (Join-Path $repoRoot 'core\agents') -File -Filter '*.md' |
            ForEach-Object { [System.IO.Path]::ChangeExtension($_.Name, '.toml') }
    )
    $userAgentPath = Join-Path $codexAgentsRoot 'my-own-agent.toml'
    $userAgentText = "name = 'my-own-agent'`n"

    $n = 'Should_PublishCodexAgents_When_FirstRun'
    $null = Invoke-CodexPublishAgents -InstallRoot $codexRoot
    foreach ($name in $codexSourceNames) {
        if (-not (Test-Path -LiteralPath (Join-Path $codexAgentsRoot $name))) { Write-Fail $n "current codex agent missing after first publish: $name" }
        if (-not (Test-CodexInventoryHasAgent -InstallRoot $codexRoot -Name $name)) { Write-Fail $n "current codex agent not recorded in inventory: $name" }
    }
    [System.IO.File]::WriteAllText($userAgentPath, $userAgentText, (New-Object System.Text.UTF8Encoding $false))
    Write-Pass $n

    $n = 'Should_DeleteNothing_When_CodexPublishRunsWhatIf'
    Add-CodexRecordedAgent -InstallRoot $codexRoot -Name 'retired-whatif.toml'
    $null = Invoke-CodexPublishAgents -InstallRoot $codexRoot -WhatIf
    if (-not (Test-Path -LiteralPath (Join-Path $codexAgentsRoot 'retired-whatif.toml'))) { Write-Fail $n 'WhatIf deleted a retired codex agent file' }
    if (-not (Test-CodexInventoryHasAgent -InstallRoot $codexRoot -Name 'retired-whatif.toml')) { Write-Fail $n 'WhatIf released a retired codex agent from the inventory' }
    Write-Pass $n

    $n = 'Should_PruneRetiredCodexAgent_When_CodexSyncRunsAgain'
    Add-CodexRecordedAgent -InstallRoot $codexRoot -Name 'retired-sample.toml'
    $null = Invoke-CodexPublishAgents -InstallRoot $codexRoot
    foreach ($retired in @('retired-sample.toml', 'retired-whatif.toml')) {
        if (Test-Path -LiteralPath (Join-Path $codexAgentsRoot $retired)) { Write-Fail $n "retired codex agent survived sync: $retired" }
        if (Test-CodexInventoryHasAgent -InstallRoot $codexRoot -Name $retired) { Write-Fail $n "retired codex agent still recorded after prune: $retired" }
    }
    foreach ($name in $codexSourceNames) {
        if (-not (Test-Path -LiteralPath (Join-Path $codexAgentsRoot $name))) { Write-Fail $n "current codex agent missing after prune: $name" }
        if (-not (Test-CodexInventoryHasAgent -InstallRoot $codexRoot -Name $name)) { Write-Fail $n "current codex agent no longer recorded after prune: $name" }
    }
    Write-Pass $n

    $n = 'Should_KeepEditedRetiredCodexAgent_When_CodexSyncPrunesIt'
    Add-CodexRecordedAgent -InstallRoot $codexRoot -Name 'retired-edited-sample.toml'
    [System.IO.File]::WriteAllText((Join-Path $codexAgentsRoot 'retired-edited-sample.toml'), "name = 'retired-edited-sample'`nedited by operator`n", (New-Object System.Text.UTF8Encoding $false))
    $null = Invoke-CodexPublishAgents -InstallRoot $codexRoot -WarningVariable codexWarnings -WarningAction SilentlyContinue
    if (-not (Test-Path -LiteralPath (Join-Path $codexAgentsRoot 'retired-edited-sample.toml'))) { Write-Fail $n 'operator-edited retired codex agent was deleted' }
    if (Test-CodexInventoryHasAgent -InstallRoot $codexRoot -Name 'retired-edited-sample.toml') { Write-Fail $n 'edited retired codex agent was not released from the inventory' }
    if (@($codexWarnings | Where-Object { [string]$_ -like 'Kept retired file edited after publish*' }).Count -eq 0) { Write-Fail $n 'no warning emitted for kept edited retired codex agent' }
    Write-Pass $n

    $n = 'Should_LeaveUnrecordedUserAgentUntouched_When_CodexSyncRuns'
    if (-not (Test-Path -LiteralPath $userAgentPath)) { Write-Fail $n 'unrecorded user codex agent was deleted' }
    if ([System.IO.File]::ReadAllText($userAgentPath) -cne $userAgentText) { Write-Fail $n 'unrecorded user codex agent was modified' }
    if (Test-CodexInventoryHasAgent -InstallRoot $codexRoot -Name 'my-own-agent.toml') { Write-Fail $n 'unrecorded user codex agent was added to the inventory' }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $codexWork
}

function Get-CodexInventoryAgentKeys {
    param([Parameter(Mandatory = $true)][string] $InstallRoot)

    if (-not (Test-Path -LiteralPath (Get-ToolkitManagedPublishInventoryPath -InstallRoot $InstallRoot) -PathType Leaf)) { return @() }
    return @(Read-ToolkitManagedPublishInventory -InstallRoot $InstallRoot).Keys | Where-Object { $_ -like 'agents/*' }
}

$codexUninstallWork = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $utf8 = New-Object System.Text.UTF8Encoding $false

    $cleanRoot = Join-Path $codexUninstallWork 'codex-clean'
    New-Item -ItemType Directory -Path $cleanRoot -Force | Out-Null
    $cleanAgentsRoot = Join-Path $cleanRoot 'agents'
    $null = Invoke-CodexPublishAgents -InstallRoot $cleanRoot
    Add-CodexRecordedAgent -InstallRoot $cleanRoot -Name 'retired-uninstall.toml'
    $cleanUserPath = Join-Path $cleanAgentsRoot 'my-own-uninstall-agent.toml'
    [System.IO.File]::WriteAllText($cleanUserPath, "name = 'my-own-uninstall-agent'`n", $utf8)

    $n = 'Should_DeleteNothing_When_CodexUninstallRunsWhatIf'
    $null = Invoke-CodexUninstallToolkit -InstallRoot $cleanRoot -WhatIf
    if (-not (Test-Path -LiteralPath (Join-Path $cleanAgentsRoot 'retired-uninstall.toml'))) { Write-Fail $n 'WhatIf deleted a recorded retired codex agent' }
    if (-not (Test-CodexInventoryHasAgent -InstallRoot $cleanRoot -Name 'retired-uninstall.toml')) { Write-Fail $n 'WhatIf released a recorded retired codex agent' }
    Write-Pass $n

    $n = 'Should_RemoveRecordedRetiredCodexAgent_When_CodexUninstallRuns'
    $cleanResult = Invoke-CodexUninstallToolkit -InstallRoot $cleanRoot
    if (Test-Path -LiteralPath (Join-Path $cleanAgentsRoot 'retired-uninstall.toml')) { Write-Fail $n 'recorded retired codex agent survived uninstall' }
    foreach ($name in $codexSourceNames) {
        if (Test-Path -LiteralPath (Join-Path $cleanAgentsRoot $name)) { Write-Fail $n "current codex agent survived uninstall: $name" }
    }
    if (-not (Test-Path -LiteralPath $cleanUserPath)) { Write-Fail $n 'unrecorded user codex agent removed by uninstall' }
    Write-Pass $n

    $n = 'Should_ReleaseCodexAgentInventoryEntries_When_CodexUninstallRemovesThem'
    $leftoverAgentKeys = @(Get-CodexInventoryAgentKeys -InstallRoot $cleanRoot)
    if ($leftoverAgentKeys.Count -gt 0) { Write-Fail $n ('codex agent entries still recorded after uninstall: ' + ($leftoverAgentKeys -join ', ')) }
    if ($cleanResult.Status -ne 'Complete') { Write-Fail $n ('uninstall status not Complete: ' + ($cleanResult.IncompletePaths -join '; ')) }
    Write-Pass $n

    $editedRoot = Join-Path $codexUninstallWork 'codex-edited'
    New-Item -ItemType Directory -Path $editedRoot -Force | Out-Null
    $editedAgentsRoot = Join-Path $editedRoot 'agents'
    $null = Invoke-CodexPublishAgents -InstallRoot $editedRoot
    Add-CodexRecordedAgent -InstallRoot $editedRoot -Name 'retired-uninstall-edited.toml'
    [System.IO.File]::WriteAllText((Join-Path $editedAgentsRoot 'retired-uninstall-edited.toml'), "name = 'retired-uninstall-edited'`nedited by operator`n", $utf8)

    $n = 'Should_KeepEditedRetiredCodexAgent_When_CodexUninstallRuns'
    $editedResult = Invoke-CodexUninstallToolkit -InstallRoot $editedRoot -WarningVariable editedWarnings -WarningAction SilentlyContinue
    if (-not (Test-Path -LiteralPath (Join-Path $editedAgentsRoot 'retired-uninstall-edited.toml'))) { Write-Fail $n 'operator-edited retired codex agent was deleted by uninstall' }
    if (-not (Test-CodexInventoryHasAgent -InstallRoot $editedRoot -Name 'retired-uninstall-edited.toml')) { Write-Fail $n 'operator-edited retired codex agent was released from the inventory' }
    if ($editedResult.Status -eq 'Complete') { Write-Fail $n 'uninstall reported Complete while an operator-edited managed agent remains' }
    if (@($editedWarnings | Where-Object { [string]$_ -like 'Kept retired file edited after publish*' }).Count -eq 0) { Write-Fail $n 'no warning emitted for kept edited retired codex agent' }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $codexUninstallWork
}

Write-Host 'Assert-RetiredManagedFilesPruned: ALL PASS'
exit 0
