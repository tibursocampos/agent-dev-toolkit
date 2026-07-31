#Requires -Version 5.1
# Tests:
#   Should_ExposePluginHooksCapability_When_DecisionA
#   Should_NotRequireShellHooks_When_SmokeOpenCode
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-OpenCodePluginHooksPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$opencodeModulePath = Join-Path $repoRoot 'adapters\opencode\OpenCodeAdapter.ps1'
$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\opencode'
$pluginMarkerFileName = 'agent-dev-toolkit-marker.js'
$pluginsDirName = 'plugins'
$assetsPluginPath = Join-Path $repoRoot 'adapters\opencode\assets\plugins\agent-dev-toolkit-marker.js'
$hooksSemanticsExpected = 'plugin-only'
$mvpDecisionExpected = 'A'
$siblingMarkerName = '.opencode-hooks-sibling-marker'
$shellHookPattern = '\.ps1$'

if (-not (Test-Path -LiteralPath $opencodeModulePath)) {
    Write-Fail -TestName 'Assert-OpenCodePluginHooksPreconditions' -Reason ("missing OpenCode module: {0}" -f $opencodeModulePath)
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-OpenCodePluginHooksPreconditions' -Reason ("missing OpenCode fixture: {0}" -f $fixtureInstallRoot)
}
if (-not (Test-Path -LiteralPath $assetsPluginPath)) {
    Write-Fail -TestName 'Assert-OpenCodePluginHooksPreconditions' -Reason ("missing plugin asset: {0}" -f $assetsPluginPath)
}

. $opencodeModulePath

# --- Should_ExposePluginHooksCapability_When_DecisionA ---
$capsName = 'Should_ExposePluginHooksCapability_When_DecisionA'

$caps = Get-Capabilities
if ($null -eq $caps -or $caps.Implemented -ne $true) {
    Write-Fail -TestName $capsName -Reason 'Get-Capabilities must be implemented'
}
if ($null -eq $caps.Capabilities -or $caps.Capabilities.hooks -ne $true) {
    Write-Fail -TestName $capsName -Reason 'Capabilities.hooks must be true (Decision A)'
}
if ($caps.Capabilities.plugin -ne $true) {
    Write-Fail -TestName $capsName -Reason 'Capabilities.plugin must be true (Decision A)'
}
if ([string]$caps.HooksSemantics -ne $hooksSemanticsExpected) {
    Write-Fail -TestName $capsName -Reason ("HooksSemantics must be {0}, got '{1}'" -f $hooksSemanticsExpected, $caps.HooksSemantics)
}
if ([string]$caps.MvpHooksDecision -ne $mvpDecisionExpected) {
    Write-Fail -TestName $capsName -Reason ("MvpHooksDecision must be {0}, got '{1}'" -f $mvpDecisionExpected, $caps.MvpHooksDecision)
}
if ($null -eq $caps.RequiresShellHooks -or $caps.RequiresShellHooks -ne $false) {
    Write-Fail -TestName $capsName -Reason 'RequiresShellHooks must be false (RN03)'
}
if ([string]::IsNullOrWhiteSpace([string]$caps.HooksNote) -or $caps.HooksNote -notmatch '(?i)RN03|plugin') {
    Write-Fail -TestName $capsName -Reason 'HooksNote must document RN03/plugin-only semantics inline'
}

$destinationPlugin = Join-Path (Join-Path $fixtureInstallRoot $pluginsDirName) $pluginMarkerFileName
if (Test-Path -LiteralPath $destinationPlugin) {
    Remove-Item -LiteralPath $destinationPlugin -Force
}

$siblingMarkerPath = Join-Path $fixtureInstallRoot $siblingMarkerName
Set-Content -LiteralPath $siblingMarkerPath -Value 'preserve-me' -Encoding UTF8

$publishResult = Publish-Hooks -InstallRoot $fixtureInstallRoot
if ($null -eq $publishResult -or $publishResult.Success -ne $true -or $publishResult.Implemented -ne $true) {
    Write-Fail -TestName $capsName -Reason 'Publish-Hooks must succeed with Implemented = true (Decision A)'
}
if ($null -eq $publishResult.NoOp -or $publishResult.NoOp -ne $false) {
    Write-Fail -TestName $capsName -Reason 'Decision A Publish-Hooks must not be a no-op'
}
if ([string]$publishResult.MvpHooksDecision -ne $mvpDecisionExpected) {
    Write-Fail -TestName $capsName -Reason ("Publish-Hooks MvpHooksDecision must be {0}" -f $mvpDecisionExpected)
}
if ($publishResult.FilesCopied -lt 1) {
    Write-Fail -TestName $capsName -Reason 'Publish-Hooks must copy at least one JS plugin file'
}
if (-not (Test-Path -LiteralPath $destinationPlugin)) {
    Write-Fail -TestName $capsName -Reason ("plugin marker missing after publish: {0}" -f $destinationPlugin)
}

$pluginText = [System.IO.File]::ReadAllText($destinationPlugin)
if ([string]::IsNullOrWhiteSpace($pluginText)) {
    Write-Fail -TestName $capsName -Reason 'published plugin must not be empty'
}
if ($pluginText -notmatch 'export\s+(const|async|function|default)') {
    Write-Fail -TestName $capsName -Reason 'published plugin must export a JS plugin entry (OpenCode local plugin shape)'
}
if ($pluginText -match '(?i)\.ps1' -and $pluginText -match '(?i)shell.?hook') {
    Write-Fail -TestName $capsName -Reason 'plugin must not invent shell/PS1 hook parity'
}

$normalizedPluginPath = [System.IO.Path]::GetFullPath([string]$publishResult.PluginPath)
$expectedPluginPath = [System.IO.Path]::GetFullPath($destinationPlugin)
if (-not [string]::Equals($normalizedPluginPath, $expectedPluginPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $capsName -Reason ("PluginPath must be fixture plugins marker, got: {0}" -f $publishResult.PluginPath)
}

if (-not (Test-Path -LiteralPath $siblingMarkerPath)) {
    Write-Fail -TestName $capsName -Reason 'Publish-Hooks must not wipe unrelated InstallRoot files'
}

$firstHash = (Get-FileHash -LiteralPath $destinationPlugin -Algorithm SHA256).Hash
$second = Publish-Hooks -InstallRoot $fixtureInstallRoot
if ($null -eq $second -or $second.Success -ne $true) {
    Write-Fail -TestName $capsName -Reason 're-publish must remain successful (idempotent)'
}
$secondHash = (Get-FileHash -LiteralPath $destinationPlugin -Algorithm SHA256).Hash
if (-not [string]::Equals($firstHash, $secondHash, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail -TestName $capsName -Reason 're-publish must not corrupt the JS plugin marker'
}

Write-Pass -TestName $capsName

# --- Should_NotRequireShellHooks_When_SmokeOpenCode ---
$smokeName = 'Should_NotRequireShellHooks_When_SmokeOpenCode'

if ($null -eq $publishResult.RequiresShellHooks -or $publishResult.RequiresShellHooks -ne $false) {
    Write-Fail -TestName $smokeName -Reason 'Publish-Hooks RequiresShellHooks must be false'
}

$pluginsRoot = Join-Path $fixtureInstallRoot $pluginsDirName
$ps1UnderPlugins = @(Get-ChildItem -LiteralPath $pluginsRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match $shellHookPattern })
if ($ps1UnderPlugins.Count -gt 0) {
    Write-Fail -TestName $smokeName -Reason ("smoke must not require/publish .ps1 hooks under plugins/; found: {0}" -f ($ps1UnderPlugins.Name -join ', '))
}

$jsFiles = @(Get-ChildItem -LiteralPath $pluginsRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -eq '.js' })
if ($jsFiles.Count -lt 1) {
    Write-Fail -TestName $smokeName -Reason 'Decision A requires at least one .js plugin under plugins/ after Publish-Hooks'
}

$whatIf = Publish-Hooks -InstallRoot $fixtureInstallRoot -WhatIf
if ($null -eq $whatIf -or $whatIf.Success -ne $true -or $whatIf.WhatIf -ne $true) {
    Write-Fail -TestName $smokeName -Reason 'Publish-Hooks -WhatIf must succeed without writing'
}
if ($whatIf.RequiresShellHooks -ne $false) {
    Write-Fail -TestName $smokeName -Reason 'WhatIf path must also report RequiresShellHooks = false'
}

Write-Pass -TestName $smokeName

# Keep fixture seed lean: drop published marker and sibling after asserts (keep .gitkeep).
if (Test-Path -LiteralPath $destinationPlugin) {
    Remove-Item -LiteralPath $destinationPlugin -Force
}
if (Test-Path -LiteralPath $siblingMarkerPath) {
    Remove-Item -LiteralPath $siblingMarkerPath -Force
}

Write-Host 'Assert-OpenCodePluginHooks: ALL PASS'
exit 0
