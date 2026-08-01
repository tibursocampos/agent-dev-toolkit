#Requires -Version 5.1
# Tests:
#   Should_ListTier1Agents_When_RegistryLoaded
#   Should_ExposeRequiredAdapterCommands_When_ContractDotSourced
#   Should_ExposeUninstallAllowUserHomeAndWhatIf_When_EachTier1Loaded
#   Should_DocumentPublishAndSmokeApis_When_AdaptersDocRead
#   Should_ExposeSubagentsCapability_When_RegistryLoaded
#   Should_MatchModuleSubagents_When_EachTier1Loaded
#   Should_MatchModuleBooleanCapabilities_When_EachTier1Loaded
#   Should_IncludeSubagentsInContractCapabilityNames
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRootScript = Join-Path (Split-Path -Parent $scriptDir) '_lib\Get-ToolkitRepoRoot.ps1'

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
    Write-Fail -TestName 'Assert-AdapterContractPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$registryPath = Join-Path $repoRoot 'adapters\registry.json'
$contractPath = Join-Path $repoRoot 'adapters\_contract\AdapterContract.ps1'
$adaptersDocPath = Join-Path $repoRoot 'docs\ADAPTERS.md'

$expectedTier1Ids = @(
    'cursor',
    'antigravity',
    'claude',
    'codex',
    'copilot',
    'opencode',
    'grok',
    'zcode'
)

$subagentsCapabilityName = 'subagents'
$subagentsNativeValue = 'native'
$subagentsNoneValue = 'none'
$expectedSubagentsByAgentId = @{
    cursor      = $subagentsNativeValue
    claude      = $subagentsNativeValue
    antigravity = $subagentsNativeValue
    codex       = $subagentsNativeValue
    copilot     = $subagentsNativeValue
    opencode    = $subagentsNativeValue
    grok        = $subagentsNativeValue
    zcode       = $subagentsNativeValue
}

$requiredCommands = @(
    'Get-Capabilities',
    'Get-InstallRoots',
    'Publish-Skills',
    'Publish-Policy',
    'Publish-Router',
    'Publish-Hooks',
    'Get-SddRoot',
    'Invoke-SmokeValidate',
    'Uninstall-Toolkit'
)

$requiredDocMarkers = @(
    'Get-Capabilities',
    'Publish-Skills',
    'Publish-Policy',
    'Publish-Router',
    'Publish-Hooks',
    'Invoke-SmokeValidate',
    'Get-SddRoot',
    'Uninstall-Toolkit',
    'skills',
    'rules',
    'hooks',
    'router',
    'sdd',
    'plugin',
    'subagents',
    'registry.json'
)

foreach ($required in @($registryPath, $contractPath, $adaptersDocPath)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-AdapterContractPreconditions' -Reason ("missing {0}" -f $required)
    }
}

# --- Should_ListTier1Agents_When_RegistryLoaded ---
$listName = 'Should_ListTier1Agents_When_RegistryLoaded'
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
if ($null -eq $registry.agents) {
    Write-Fail -TestName $listName -Reason 'registry.agents is missing'
}

$ids = @($registry.agents | ForEach-Object { $_.id })
foreach ($expectedId in $expectedTier1Ids) {
    if ($ids -notcontains $expectedId) {
        Write-Fail -TestName $listName -Reason ("missing Tier 1 id: {0}" -f $expectedId)
    }
}

if ($ids.Count -ne $expectedTier1Ids.Count) {
    Write-Fail -TestName $listName -Reason ("expected {0} agents, got {1}" -f $expectedTier1Ids.Count, $ids.Count)
}

foreach ($agent in $registry.agents) {
    if ([string]::IsNullOrWhiteSpace([string]$agent.module)) {
        Write-Fail -TestName $listName -Reason ("agent {0} missing module path" -f $agent.id)
    }
    $moduleFull = Join-Path (Join-Path $repoRoot 'adapters') ([string]$agent.module)
    if (-not (Test-Path -LiteralPath $moduleFull)) {
        Write-Fail -TestName $listName -Reason ("module missing for {0}: {1}" -f $agent.id, $moduleFull)
    }
}

Write-Pass -TestName $listName

# --- Should_ExposeSubagentsCapability_When_RegistryLoaded ---
$subagentsRegistryName = 'Should_ExposeSubagentsCapability_When_RegistryLoaded'
foreach ($agent in $registry.agents) {
    $caps = $agent.capabilities
    if ($null -eq $caps) {
        Write-Fail -TestName $subagentsRegistryName -Reason ("agent {0} missing capabilities" -f $agent.id)
    }

    $propNames = @($caps.PSObject.Properties.Name)
    if ($propNames -notcontains $subagentsCapabilityName) {
        Write-Fail -TestName $subagentsRegistryName -Reason ("agent {0} missing capabilities.{1}" -f $agent.id, $subagentsCapabilityName)
    }

    $actual = [string]$caps.subagents
    $expected = [string]$expectedSubagentsByAgentId[$agent.id]
    if ([string]::IsNullOrWhiteSpace($expected)) {
        Write-Fail -TestName $subagentsRegistryName -Reason ("no expected {0} matrix value for agent {1}" -f $subagentsCapabilityName, $agent.id)
    }

    if ($actual -ne $expected) {
        Write-Fail -TestName $subagentsRegistryName -Reason ("agent {0}: expected {1}={2}, got {3}" -f $agent.id, $subagentsCapabilityName, $expected, $actual)
    }

    if (($actual -ne $subagentsNativeValue) -and ($actual -ne $subagentsNoneValue)) {
        Write-Fail -TestName $subagentsRegistryName -Reason ("agent {0}: {1} must be '{2}' or '{3}', got '{4}'" -f $agent.id, $subagentsCapabilityName, $subagentsNativeValue, $subagentsNoneValue, $actual)
    }
}

Write-Pass -TestName $subagentsRegistryName

# --- Should_MatchModuleSubagents_When_EachTier1Loaded ---
# Isolated child process per module (avoids Get-Capabilities name collisions).
# Antigravity: ADT_ANTIGRAVITY_SUBAGENTS=native so declared registry value is comparable in CI without agy.
$moduleSubagentsName = 'Should_MatchModuleSubagents_When_EachTier1Loaded'
$antigravityOverrideEnvName = 'ADT_ANTIGRAVITY_SUBAGENTS'
$childProbePath = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-subagents-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$childProbeBody = @'
param(
    [Parameter(Mandatory = $true)][string] $ModulePath,
    [Parameter(Mandatory = $true)][string] $AgentId,
    [Parameter(Mandatory = $true)][string] $ExpectedSubagents,
    [Parameter()][string] $OverrideEnvName,
    [Parameter()][string] $OverrideEnvValue
)
$ErrorActionPreference = 'Stop'
if (-not [string]::IsNullOrWhiteSpace($OverrideEnvName) -and -not [string]::IsNullOrWhiteSpace($OverrideEnvValue)) {
    [Environment]::SetEnvironmentVariable($OverrideEnvName, $OverrideEnvValue)
}
. $ModulePath
$caps = Get-Capabilities -AgentId $AgentId
if ($null -eq $caps -or $caps.Implemented -ne $true) {
    Write-Error ('Get-Capabilities not implemented for {0}' -f $AgentId)
    exit 1
}
$actual = [string]$caps.Capabilities.subagents
if ($actual -ne $ExpectedSubagents) {
    Write-Error ('agent {0}: Get-Capabilities.subagents expected {1}, got {2}' -f $AgentId, $ExpectedSubagents, $actual)
    exit 1
}
exit 0
'@
try {
    Set-Content -LiteralPath $childProbePath -Value $childProbeBody -Encoding UTF8
    foreach ($agent in $registry.agents) {
        $moduleFull = Join-Path (Join-Path $repoRoot 'adapters') ([string]$agent.module)
        $expectedEffective = [string]$expectedSubagentsByAgentId[$agent.id]
        $registryValue = [string]$agent.capabilities.subagents
        if ($registryValue -ne $expectedEffective) {
            Write-Fail -TestName $moduleSubagentsName -Reason ("agent {0}: registry precondition mismatch" -f $agent.id)
        }

        $childArgs = @(
            '-NoProfile',
            '-File', $childProbePath,
            '-ModulePath', $moduleFull,
            '-AgentId', [string]$agent.id,
            '-ExpectedSubagents', $expectedEffective
        )
        if ([string]$agent.id -eq 'antigravity') {
            $childArgs += @('-OverrideEnvName', $antigravityOverrideEnvName, '-OverrideEnvValue', $subagentsNativeValue)
        }

        $childOut = & pwsh @childArgs 2>&1
        $childExit = $LASTEXITCODE
        if ($null -eq $childExit) { $childExit = 0 }
        if ($childExit -ne 0) {
            Write-Fail -TestName $moduleSubagentsName -Reason ("agent {0}: {1}" -f $agent.id, (($childOut | Out-String).Trim()))
        }
    }
}
finally {
    if (Test-Path -LiteralPath $childProbePath) {
        Remove-Item -LiteralPath $childProbePath -Force -ErrorAction SilentlyContinue
    }
}

Write-Pass -TestName $moduleSubagentsName

# --- Should_MatchModuleBooleanCapabilities_When_EachTier1Loaded ---
# Isolated child process per module reconciles every boolean capability flag
# (skills, rules, hooks, router, sdd, plugin) between registry.json and the
# module's own Get-Capabilities output. subagents is a native/none enum and is
# already reconciled above; it is intentionally excluded here.
$moduleCapabilitiesName = 'Should_MatchModuleBooleanCapabilities_When_EachTier1Loaded'
$booleanCapabilityNames = @('skills', 'rules', 'hooks', 'router', 'sdd', 'plugin')
$capabilitiesProbePath = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-capabilities-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$capabilitiesProbeBody = @'
param(
    [Parameter(Mandatory = $true)][string] $ModulePath,
    [Parameter(Mandatory = $true)][string] $AgentId,
    [Parameter(Mandatory = $true)][string] $CapabilityNamesCsv,
    [Parameter(Mandatory = $true)][string] $ExpectedCapabilitiesJson
)
$ErrorActionPreference = 'Stop'
. $ModulePath
$caps = Get-Capabilities -AgentId $AgentId
if ($null -eq $caps -or $caps.Implemented -ne $true) {
    Write-Error ('Get-Capabilities not implemented for {0}' -f $AgentId)
    exit 1
}

$expected = $ExpectedCapabilitiesJson | ConvertFrom-Json
$capabilityNames = $CapabilityNamesCsv -split ','
$mismatches = @()
foreach ($name in $capabilityNames) {
    $expectedValue = [bool]$expected.$name
    $actualValue = [bool]$caps.Capabilities.$name
    if ($actualValue -ne $expectedValue) {
        $mismatches += ('{0}: registry={1}, module={2}' -f $name, $expectedValue, $actualValue)
    }
}

if ($mismatches.Count -gt 0) {
    Write-Error ('agent {0}: capability mismatch(es) - {1}' -f $AgentId, ($mismatches -join '; '))
    exit 1
}
exit 0
'@
try {
    Set-Content -LiteralPath $capabilitiesProbePath -Value $capabilitiesProbeBody -Encoding UTF8
    foreach ($agent in $registry.agents) {
        $moduleFull = Join-Path (Join-Path $repoRoot 'adapters') ([string]$agent.module)
        $caps = $agent.capabilities
        if ($null -eq $caps) {
            Write-Fail -TestName $moduleCapabilitiesName -Reason ("agent {0} missing capabilities" -f $agent.id)
        }

        $propNames = @($caps.PSObject.Properties.Name)
        foreach ($name in $booleanCapabilityNames) {
            if ($propNames -notcontains $name) {
                Write-Fail -TestName $moduleCapabilitiesName -Reason ("agent {0} missing capabilities.{1}" -f $agent.id, $name)
            }
        }

        $expectedCapabilitiesJson = $caps | Select-Object $booleanCapabilityNames | ConvertTo-Json -Compress
        $childArgs = @(
            '-NoProfile',
            '-File', $capabilitiesProbePath,
            '-ModulePath', $moduleFull,
            '-AgentId', [string]$agent.id,
            '-CapabilityNamesCsv', ($booleanCapabilityNames -join ','),
            '-ExpectedCapabilitiesJson', $expectedCapabilitiesJson
        )

        $childOut = & pwsh @childArgs 2>&1
        $childExit = $LASTEXITCODE
        if ($null -eq $childExit) { $childExit = 0 }
        if ($childExit -ne 0) {
            Write-Fail -TestName $moduleCapabilitiesName -Reason ("agent {0}: {1}" -f $agent.id, (($childOut | Out-String).Trim()))
        }
    }
}
finally {
    if (Test-Path -LiteralPath $capabilitiesProbePath) {
        Remove-Item -LiteralPath $capabilitiesProbePath -Force -ErrorAction SilentlyContinue
    }
}

Write-Pass -TestName $moduleCapabilitiesName

# --- Should_ExposeUninstallAllowUserHomeAndWhatIf_When_EachTier1Loaded ---
# toolkit.ps1 may splat -AllowUserHome / -WhatIf into Uninstall-Toolkit; every
# Tier-1 module must bind those switches (stubs may accept and ignore).
$uninstallParamsName = 'Should_ExposeUninstallAllowUserHomeAndWhatIf_When_EachTier1Loaded'
$requiredUninstallParameterNames = @('AllowUserHome', 'WhatIf')
$uninstallProbePath = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-uninstall-params-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$uninstallProbeBody = @'
param(
    [Parameter(Mandatory = $true)][string] $ModulePath,
    [Parameter(Mandatory = $true)][string] $AgentId,
    [Parameter(Mandatory = $true)][string] $RequiredParameterNamesCsv
)
$ErrorActionPreference = 'Stop'
. $ModulePath
$command = Get-Command -Name Uninstall-Toolkit -ErrorAction Stop
$requiredNames = $RequiredParameterNamesCsv -split ','
$missing = @()
foreach ($name in $requiredNames) {
    if (-not $command.Parameters.ContainsKey($name)) {
        $missing += $name
    }
}
if ($missing.Count -gt 0) {
    Write-Error ('agent {0}: Uninstall-Toolkit missing parameter(s): {1}' -f $AgentId, ($missing -join ', '))
    exit 1
}
exit 0
'@
try {
    Set-Content -LiteralPath $uninstallProbePath -Value $uninstallProbeBody -Encoding UTF8
    foreach ($agent in $registry.agents) {
        $moduleFull = Join-Path (Join-Path $repoRoot 'adapters') ([string]$agent.module)
        $childArgs = @(
            '-NoProfile',
            '-File', $uninstallProbePath,
            '-ModulePath', $moduleFull,
            '-AgentId', [string]$agent.id,
            '-RequiredParameterNamesCsv', ($requiredUninstallParameterNames -join ',')
        )

        $childOut = & pwsh @childArgs 2>&1
        $childExit = $LASTEXITCODE
        if ($null -eq $childExit) { $childExit = 0 }
        if ($childExit -ne 0) {
            Write-Fail -TestName $uninstallParamsName -Reason ("agent {0}: {1}" -f $agent.id, (($childOut | Out-String).Trim()))
        }
    }
}
finally {
    if (Test-Path -LiteralPath $uninstallProbePath) {
        Remove-Item -LiteralPath $uninstallProbePath -Force -ErrorAction SilentlyContinue
    }
}

Write-Pass -TestName $uninstallParamsName

# --- Should_ExposeRequiredAdapterCommands_When_ContractDotSourced ---
$commandsName = 'Should_ExposeRequiredAdapterCommands_When_ContractDotSourced'
. $contractPath

$exposed = @(Get-AdapterContractCommandNames)
foreach ($commandName in $requiredCommands) {
    if ($exposed -notcontains $commandName) {
        Write-Fail -TestName $commandsName -Reason ("contract list missing {0}" -f $commandName)
    }
    $command = Get-Command -Name $commandName -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Write-Fail -TestName $commandsName -Reason ("command not defined after dot-source: {0}" -f $commandName)
    }
}

$caps = Get-Capabilities -AgentId 'cursor'
if ($null -eq $caps -or $caps.Implemented -ne $false) {
    Write-Fail -TestName $commandsName -Reason 'Get-Capabilities stub must report Implemented = false'
}

if ($null -eq $caps.Capabilities -or [string]$caps.Capabilities.subagents -ne $subagentsNoneValue) {
    Write-Fail -TestName $commandsName -Reason ("Get-Capabilities stub must default {0} to '{1}' (never mint native)" -f $subagentsCapabilityName, $subagentsNoneValue)
}

$publishResult = Publish-Skills -InstallRoot (Join-Path $repoRoot 'scripts\validation\fixtures\install-root')
if ($null -eq $publishResult -or $publishResult.Implemented -ne $false -or $publishResult.Success -ne $false) {
    Write-Fail -TestName $commandsName -Reason 'Publish-Skills stub must return not-implemented without writing'
}

$smokeResult = Invoke-SmokeValidate -InstallRoot (Join-Path $repoRoot 'scripts\validation\fixtures\install-root')
if ($null -eq $smokeResult -or $smokeResult.Implemented -ne $false -or $smokeResult.Success -ne $false) {
    Write-Fail -TestName $commandsName -Reason 'Invoke-SmokeValidate stub must return not-implemented without home publish'
}

# Contract Uninstall-Toolkit must also bind AllowUserHome/WhatIf for splat safety.
$contractUninstall = Get-Command -Name Uninstall-Toolkit -ErrorAction SilentlyContinue
if ($null -eq $contractUninstall) {
    Write-Fail -TestName $commandsName -Reason 'Uninstall-Toolkit not defined after contract dot-source'
}
foreach ($paramName in $requiredUninstallParameterNames) {
    if (-not $contractUninstall.Parameters.ContainsKey($paramName)) {
        Write-Fail -TestName $commandsName -Reason ("contract Uninstall-Toolkit missing parameter: {0}" -f $paramName)
    }
}

Write-Pass -TestName $commandsName

# --- Should_IncludeSubagentsInContractCapabilityNames ---
$subagentsNamesName = 'Should_IncludeSubagentsInContractCapabilityNames'
$capabilityNames = @(Get-AdapterCapabilityNames)
if ($capabilityNames -notcontains $subagentsCapabilityName) {
    Write-Fail -TestName $subagentsNamesName -Reason ("Get-AdapterCapabilityNames missing {0}" -f $subagentsCapabilityName)
}

Write-Pass -TestName $subagentsNamesName

# --- Should_DocumentPublishAndSmokeApis_When_AdaptersDocRead ---
$docName = 'Should_DocumentPublishAndSmokeApis_When_AdaptersDocRead'
$docText = Get-Content -LiteralPath $adaptersDocPath -Raw
foreach ($marker in $requiredDocMarkers) {
    if ($docText -notlike ("*{0}*" -f $marker)) {
        Write-Fail -TestName $docName -Reason ("docs/ADAPTERS.md missing marker: {0}" -f $marker)
    }
}

Write-Pass -TestName $docName

Write-Host 'Assert-AdapterContract: ALL PASS'
exit 0
