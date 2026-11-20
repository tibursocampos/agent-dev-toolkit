#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch] $LegacyFallbackOnly,
    [switch] $ForwardingOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'scripts/_lib/New-ToolkitWorkRoot.ps1')

$workRoot = New-ToolkitWorkRoot -RepoRoot $repoRoot
$syncScript = Join-Path $repoRoot 'scripts/sync-agent.ps1'
$toolkitScript = Join-Path $repoRoot 'scripts/toolkit.ps1'
$validateScript = Join-Path $repoRoot 'scripts/validate-agent.ps1'
$bootstrapScript = Join-Path $repoRoot 'scripts/bootstrap/bootstrap.ps1'
$passed = 0
$pwshPath = (Get-Command pwsh -ErrorAction Stop).Source

function Assert-True {
    param([bool] $Condition, [string] $Name)
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal {
    param([string] $Expected, [string] $Actual, [string] $Name)
    if ($Expected -cne $Actual) { throw ('{0}: expected [{1}], got [{2}]' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Invoke-ChildScript {
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter(Mandatory = $true)][string[]] $Arguments,
        [Parameter(Mandatory = $true)][int] $ExpectedExitCode,
        [Parameter(Mandatory = $true)][string] $Name
    )

    $output = @(& $pwshPath -NoProfile -File $ScriptPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne $ExpectedExitCode) {
        $tail = (@($output | ForEach-Object { [string]$_ } | Select-Object -Last 20) -join [Environment]::NewLine)
        throw ('{0}: expected exit {1}, got {2}.{3}{4}' -f $Name, $ExpectedExitCode, $exitCode, [Environment]::NewLine, $tail)
    }
    $script:passed++
    return $output
}

function Assert-ProfileLayout {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][ValidateSet('both', 'local', 'plugin')][string] $Mode,
        [Parameter(Mandatory = $true)][string] $Name,
        [switch] $AllowStaleCopies
    )

    $statePath = Join-Path $InstallRoot '.agent-dev-toolkit/codex-skill-distribution.json'
    $state = Get-Content -LiteralPath $statePath -Raw -Encoding utf8 | ConvertFrom-Json
    Assert-Equal '1' ([string]$state.schemaVersion) ($Name + '_StateSchemaVersion')
    Assert-Equal $Mode ([string]$state.distribution) ($Name + '_StateDistribution')

    $pluginRoot = Join-Path $InstallRoot 'plugins/agent-dev-toolkit'
    $manifestPath = Join-Path $pluginRoot '.codex-plugin/plugin.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
    $manifestHasSkills = @($manifest.PSObject.Properties.Name) -contains 'skills'
    $pluginSkillPath = Join-Path $pluginRoot 'skills/adt-help-skills/SKILL.md'
    $homeSkillPath = Join-Path $InstallRoot 'skills/adt-help-skills/SKILL.md'
    $marketplacePath = Join-Path $InstallRoot '.agents/plugins/marketplace.json'
    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw -Encoding utf8 | ConvertFrom-Json
    $marketplaceSource = [string]$marketplace.plugins[0].source.path
    $cachePath = Join-Path $InstallRoot 'plugins/cache'
    $pluginExpected = $Mode -in @('both', 'plugin')
    $homeExpected = $Mode -in @('both', 'local')

    Assert-Equal ([string]$pluginExpected) ([string]$manifestHasSkills) ($Name + '_ManifestSkillsDeclaration')
    Assert-Equal 'True' ([string](Test-Path -LiteralPath $manifestPath -PathType Leaf)) ($Name + '_PluginPackageAtCanonicalPath')
    Assert-Equal './plugins/agent-dev-toolkit' $marketplaceSource ($Name + '_MarketplaceSourcePath')
    Assert-Equal 'False' ([string](Test-Path -LiteralPath $cachePath)) ($Name + '_CodexCacheNotToolkitOutput')
    if ($pluginExpected) {
        Assert-Equal './skills/' ([string]$manifest.skills) ($Name + '_ManifestSkillsPath')
    }
    if ($pluginExpected -or -not $AllowStaleCopies) {
        Assert-Equal ([string]$pluginExpected) ([string](Test-Path -LiteralPath $pluginSkillPath -PathType Leaf)) ($Name + '_PluginSkillPresent')
    }
    if ($homeExpected -or -not $AllowStaleCopies) {
        Assert-Equal ([string]$homeExpected) ([string](Test-Path -LiteralPath $homeSkillPath -PathType Leaf)) ($Name + '_HomeSkillPresent')
    }

    $hooksPath = Join-Path $pluginRoot 'hooks/hooks.json'
    $hooks = Get-Content -LiteralPath $hooksPath -Raw -Encoding utf8 | ConvertFrom-Json
    $hookNames = @($hooks.hooks.PSObject.Properties | ForEach-Object { $_.Name })
    Assert-True ($hookNames -contains 'SubagentStop') ($Name + '_TraceHookPresent')
}

function Invoke-ProfileValidation {
    param([Parameter(Mandatory = $true)][string] $InstallRoot, [Parameter(Mandatory = $true)][string] $Name)
    $null = Invoke-ChildScript -ScriptPath $validateScript -Arguments @('-Agent', 'codex', '-InstallRoot', $InstallRoot, '-SkipCore', '-Quiet') -ExpectedExitCode 0 -Name ($Name + '_Validate')
}

try {
    if ($ForwardingOnly) {
        $toolkitPath = Join-Path $repoRoot 'scripts/toolkit.ps1'
        $tokens = $null
        $parseErrors = $null
        $toolkitAst = [System.Management.Automation.Language.Parser]::ParseFile($toolkitPath, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) { throw 'toolkit.ps1 has parser errors' }
        $forwardFunction = $toolkitAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Build-AgentForwardTable'
            }, $true) | Select-Object -First 1
        if ($null -eq $forwardFunction) { throw 'Build-AgentForwardTable was not found' }
        . ([scriptblock]::Create($forwardFunction.Extent.Text))

        $InstallRoot = 'fixture-root'
        $Mode = ''
        $CodexSkillDistribution = 'Both'
        $AllowUserHome = [System.Management.Automation.SwitchParameter]::new($false)
        $UserScope = [System.Management.Automation.SwitchParameter]::new($false)
        $Quiet = $false
        $SkipSmoke = $false
        $script:ToolkitConstant = @{ UserScopeParameterName = 'UserScope' }

        $validationTable = Build-AgentForwardTable -AgentId codex -OverrideCodexSkillDistribution 'Local' -ForValidate
        Assert-True (-not $validationTable.ContainsKey('CodexSkillDistribution')) 'Validation_DoesNotForwardDistribution'
        $syncTable = Build-AgentForwardTable -AgentId codex -OverrideCodexSkillDistribution 'Local'
        Assert-Equal 'Local' ([string]$syncTable.CodexSkillDistribution) 'Sync_ForwardsSelectedDistribution'
        $defaultSyncTable = Build-AgentForwardTable -AgentId codex
        Assert-Equal 'Both' ([string]$defaultSyncTable.CodexSkillDistribution) 'Sync_DefaultsToBoth'

        Write-Output ('PASS: {0} Codex argument-forwarding assertions.' -f $passed)
        exit 0
    }

    if ($LegacyFallbackOnly) {
        $legacyRoot = Join-Path $workRoot 'LegacyBoth'
        $null = Invoke-ChildScript -ScriptPath $syncScript -Arguments @('-Agent', 'codex', '-InstallRoot', $legacyRoot) -ExpectedExitCode 0 -Name 'Legacy_BothDefaultSync'
        $legacyStatePath = Join-Path $legacyRoot '.agent-dev-toolkit/codex-skill-distribution.json'
        Remove-Item -LiteralPath $legacyStatePath -Force
        Invoke-ProfileValidation -InstallRoot $legacyRoot -Name 'LegacyWithoutDistributionState'
        Write-Output ('PASS: {0} legacy distribution fallback assertions.' -f $passed)
        exit 0
    }

    $modes = @(
        @{ Name = 'BothDefault'; Mode = 'both'; UseToolkit = $true; OmitDistribution = $true },
        @{ Name = 'LocalDirect'; Mode = 'local'; UseToolkit = $false; OmitDistribution = $false },
        @{ Name = 'PluginToolkit'; Mode = 'plugin'; UseToolkit = $true; OmitDistribution = $false }
    )

    foreach ($case in $modes) {
        $root = Join-Path $workRoot $case.Name
        $legacyPluginRoot = Join-Path $root 'plugin'
        $legacySentinel = Join-Path $legacyPluginRoot 'preserve-me.txt'
        $null = New-Item -ItemType Directory -Path $legacyPluginRoot -Force
        [System.IO.File]::WriteAllText($legacySentinel, 'legacy toolkit data')
        $arguments = if ($case.UseToolkit) {
            @('-Action', 'Sync', '-Agent', 'codex', '-InstallRoot', $root)
        }
        else {
            @('-Agent', 'codex', '-InstallRoot', $root)
        }
        if (-not $case.OmitDistribution) {
            $arguments += @('-CodexSkillDistribution', $(switch ($case.Mode) { 'both' { 'Both' } 'local' { 'Local' } 'plugin' { 'Plugin' } }))
        }
        $scriptPath = if ($case.UseToolkit) { $toolkitScript } else { $syncScript }
        $null = Invoke-ChildScript -ScriptPath $scriptPath -Arguments $arguments -ExpectedExitCode 0 -Name ($case.Name + '_Sync')
        Assert-Equal 'legacy toolkit data' ([System.IO.File]::ReadAllText($legacySentinel)) ($case.Name + '_LegacySingularPathPreserved')
        Assert-ProfileLayout -InstallRoot $root -Mode $case.Mode -Name $case.Name
        Invoke-ProfileValidation -InstallRoot $root -Name $case.Name
    }

    $legacyRoot = Join-Path $workRoot 'BothDefault'
    $legacyStatePath = Join-Path $legacyRoot '.agent-dev-toolkit/codex-skill-distribution.json'
    Remove-Item -LiteralPath $legacyStatePath -Force
    Invoke-ProfileValidation -InstallRoot $legacyRoot -Name 'LegacyWithoutDistributionState'

    $toolkitValidateRoot = Join-Path $workRoot 'LocalDirect'
    $null = Invoke-ChildScript -ScriptPath $toolkitScript -Arguments @(
        '-Action', 'Validate', '-Agent', 'codex', '-InstallRoot', $toolkitValidateRoot, '-Quiet'
    ) -ExpectedExitCode 0 -Name 'Toolkit_ValidateDoesNotForwardDistribution'

    $syncAndValidateRoot = Join-Path $workRoot 'ToolkitSyncAndValidate'
    $null = Invoke-ChildScript -ScriptPath $toolkitScript -Arguments @(
        '-Action', 'SyncAndValidate', '-Agent', 'codex', '-InstallRoot', $syncAndValidateRoot,
        '-CodexSkillDistribution', 'Local', '-Quiet'
    ) -ExpectedExitCode 0 -Name 'Toolkit_SyncAndValidateLocal'
    Assert-ProfileLayout -InstallRoot $syncAndValidateRoot -Mode 'local' -Name 'Toolkit_SyncAndValidateLocal'

    $switchRoot = Join-Path $workRoot 'SwitchMode'
    $null = Invoke-ChildScript -ScriptPath $syncScript -Arguments @('-Agent', 'codex', '-InstallRoot', $switchRoot, '-CodexSkillDistribution', 'Both') -ExpectedExitCode 0 -Name 'Switch_BothSync'
    $stalePluginSkill = Join-Path $switchRoot 'plugins/agent-dev-toolkit/skills/adt-help-skills/SKILL.md'
    $staleHomeSkill = Join-Path $switchRoot 'skills/adt-help-skills/SKILL.md'
    Assert-True (Test-Path -LiteralPath $stalePluginSkill -PathType Leaf) 'Switch_BothPluginCopyPresent'
    Assert-True (Test-Path -LiteralPath $staleHomeSkill -PathType Leaf) 'Switch_BothHomeCopyPresent'

    $null = Invoke-ChildScript -ScriptPath $syncScript -Arguments @('-Agent', 'codex', '-InstallRoot', $switchRoot, '-CodexSkillDistribution', 'Local') -ExpectedExitCode 0 -Name 'Switch_LocalSync'
    Assert-True (Test-Path -LiteralPath $stalePluginSkill -PathType Leaf) 'Switch_LocalPreservesPluginCopy'
    Assert-True (Test-Path -LiteralPath $staleHomeSkill -PathType Leaf) 'Switch_LocalPreservesHomeCopy'
    Assert-ProfileLayout -InstallRoot $switchRoot -Mode 'local' -Name 'Switch_Local' -AllowStaleCopies
    Invoke-ProfileValidation -InstallRoot $switchRoot -Name 'Switch_Local'

    $null = Invoke-ChildScript -ScriptPath $syncScript -Arguments @('-Agent', 'codex', '-InstallRoot', $switchRoot, '-CodexSkillDistribution', 'Plugin') -ExpectedExitCode 0 -Name 'Switch_PluginSync'
    Assert-True (Test-Path -LiteralPath $stalePluginSkill -PathType Leaf) 'Switch_PluginPreservesPluginCopy'
    Assert-True (Test-Path -LiteralPath $staleHomeSkill -PathType Leaf) 'Switch_PluginPreservesHomeCopy'
    Assert-ProfileLayout -InstallRoot $switchRoot -Mode 'plugin' -Name 'Switch_Plugin' -AllowStaleCopies
    Invoke-ProfileValidation -InstallRoot $switchRoot -Name 'Switch_Plugin'

    $invalidStatePath = Join-Path $switchRoot '.agent-dev-toolkit/codex-skill-distribution.json'
    [System.IO.File]::WriteAllText($invalidStatePath, '{"schemaVersion":99,"distribution":"plugin"}')
    $null = Invoke-ChildScript -ScriptPath $validateScript -Arguments @('-Agent', 'codex', '-InstallRoot', $switchRoot, '-SkipCore', '-Quiet') -ExpectedExitCode 1 -Name 'InvalidState_FailsValidation'

    $bootstrapSource = Join-Path $workRoot 'BootstrapSource'
    $bootstrapSync = Join-Path $bootstrapSource 'scripts/sync-agent.ps1'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $bootstrapSync) -Force
    [System.IO.File]::WriteAllText($bootstrapSync, 'param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Forwarded); [System.IO.File]::WriteAllText($env:ADT_CODEX_DISTRIBUTION_CAPTURE, ($Forwarded | ConvertTo-Json -Compress))')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $bootstrapZip = Join-Path $workRoot 'bootstrap-fixture.zip'
    [System.IO.Compression.ZipFile]::CreateFromDirectory($bootstrapSource, $bootstrapZip)
    $capturePath = Join-Path $workRoot 'bootstrap-forwarded-args.json'
    $env:ADT_CODEX_DISTRIBUTION_CAPTURE = $capturePath
    try {
        $hash = (Get-FileHash -LiteralPath $bootstrapZip -Algorithm SHA256).Hash
        $bootstrapRoot = Join-Path $workRoot 'BootstrapInstall'
        $null = Invoke-ChildScript -ScriptPath $bootstrapScript -Arguments @(
            '-LocalZipPath', $bootstrapZip, '-ExpectedSha256', $hash, '-SkipDownload',
            '-CacheDir', (Join-Path $workRoot 'BootstrapCache'), '-DirectSync', '-Agent', 'codex',
            '-InstallRoot', $bootstrapRoot, '-CodexSkillDistribution', 'Local'
        ) -ExpectedExitCode 0 -Name 'Bootstrap_LocalDistributionForwarding'
        $forwarded = @(Get-Content -LiteralPath $capturePath -Raw -Encoding utf8 | ConvertFrom-Json)
        Assert-True ($forwarded -contains '-CodexSkillDistribution') 'Bootstrap_DistributionFlagForwarded'
        Assert-True ($forwarded -contains 'Local') 'Bootstrap_LocalDistributionForwarded'
        Assert-True ($forwarded -contains $bootstrapRoot) 'Bootstrap_InstallRootForwarded'
    }
    finally {
        Remove-Item Env:\ADT_CODEX_DISTRIBUTION_CAPTURE -ErrorAction SilentlyContinue
    }

    Write-Output ('PASS: {0} Codex skill distribution assertions.' -f $passed)
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $workRoot
}
exit 0
