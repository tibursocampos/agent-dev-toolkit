#Requires -Version 5.1
<#
.SYNOPSIS
  Hook activation contract: HookActivation shape and state per adapter, publish idempotency,
  WhatIf, Hermes config.yaml gate, no trust/consent writes, strict-mode guard and non-fatal
  hook failure at sync level.

.DESCRIPTION
  Each registry adapter is dot-sourced in turn (same pattern as scripts/_lib/AdapterChecks.ps1)
  and Publish-Hooks runs into temp roots under <repo>/.adt-work/<guid>/. The hermes CLI is hidden
  from PATH for the whole run so the best-effort `hermes plugins enable` cannot touch the operator's
  Hermes home. Run it in a fresh process (validate-core does).
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'scripts/_lib/New-ToolkitWorkRoot.ps1')

$script:HaFailures = New-Object System.Collections.Generic.List[string]
$script:HaExpectedState = [ordered]@{
    antigravity = 'manual'
    claude      = 'manual'
    codex       = 'manual'
    copilot     = 'unavailable'
    cursor      = 'automatic'
    grok        = 'manual'
    hermes      = 'unavailable'
    openhands   = 'manual'
    opencode    = 'automatic'
    zcode       = 'manual'
}
$script:HaValidStates = @('manual', 'automatic', 'unavailable', 'blocked')
$script:HaUtf8 = New-Object System.Text.UTF8Encoding $false

function Write-HaCheck {
    param(
        [Parameter(Mandatory = $true)][string] $Scope,
        [Parameter(Mandatory = $true)][string] $Check,
        [Parameter(Mandatory = $true)][bool] $Ok,
        [string] $Reason = ''
    )

    if ($Ok) {
        Write-Host ('{0}/{1}: PASS' -f $Scope, $Check)
        return
    }
    Write-Host ('{0}/{1}: FAIL - {2}' -f $Scope, $Check, $Reason) -ForegroundColor Red
    $script:HaFailures.Add(('{0}/{1}: {2}' -f $Scope, $Check, $Reason))
}

function Get-HaTreeHashes {
    param([Parameter(Mandatory = $true)][string] $Root)

    $map = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Root)) { return , $map }
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    foreach ($file in @(Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force)) {
        $relative = $file.FullName.Substring($rootFull.Length).TrimStart('\', '/').Replace('\', '/')
        $map[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    return , $map
}

function Get-HaFileHash {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Invoke-HaPublishHooks {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [hashtable] $Extra = @{},
        [switch] $WhatIf
    )

    $command = Get-Command -Name 'Publish-Hooks' -ErrorAction Stop
    $callArgs = @{ InstallRoot = $InstallRoot }
    foreach ($key in @($Extra.Keys)) {
        if ($command.Parameters.ContainsKey($key)) { $callArgs[$key] = $Extra[$key] }
    }
    if ($WhatIf.IsPresent -and $command.Parameters.ContainsKey('WhatIf')) { $callArgs['WhatIf'] = $true }
    return @(& $command @callArgs)
}

function Test-HaResult {
    <#
    .SYNOPSIS
      Checks the Publish-Hooks result shape. Returns the single result object or $null.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $Scope,
        [Parameter(Mandatory = $true)][string] $Check,
        [object[]] $Outputs = @(),
        [Parameter(Mandatory = $true)][string] $State,
        [bool] $Success = $true
    )

    if (@($Outputs).Count -ne 1) {
        Write-HaCheck $Scope ($Check + '-single-result') $false ('Publish-Hooks emitted {0} objects; sync-agent expects one' -f @($Outputs).Count)
        return $null
    }
    $result = $Outputs[0]
    $names = @($result.PSObject.Properties.Name)
    Write-HaCheck $Scope ($Check + '-success') (($names -contains 'Success') -and ($result.Success -eq $Success)) ("expected Success=$Success")
    if ($names -notcontains 'HookActivation') {
        Write-HaCheck $Scope ($Check + '-activation-present') $false 'result has no HookActivation property'
        return $result
    }

    $activation = $result.HookActivation
    $activationNames = @($activation.PSObject.Properties.Name)
    $shapeOk = @(@('State', 'Steps', 'DocsUrl', 'Note') | Where-Object { $activationNames -notcontains $_ }).Count -eq 0
    Write-HaCheck $Scope ($Check + '-activation-shape') $shapeOk 'HookActivation must expose State, Steps, DocsUrl and Note'
    if (-not $shapeOk) { return $result }

    $stateValue = [string]$activation.State
    Write-HaCheck $Scope ($Check + '-activation-state-valid') ($script:HaValidStates -contains $stateValue) ("unknown State '$stateValue'")
    Write-HaCheck $Scope ($Check + '-activation-state') ($stateValue -eq $State) ("expected State '$State', got '$stateValue'")
    Write-HaCheck $Scope ($Check + '-activation-steps') ($stateValue -ne 'manual' -or @($activation.Steps).Count -ge 1) 'State manual must list at least one manual step'
    Write-HaCheck $Scope ($Check + '-activation-note') (-not [string]::IsNullOrWhiteSpace([string]$activation.Note)) 'HookActivation.Note must not be empty'
    return $result
}

function Get-HaActivationSignature {
    param($Result)

    if ($null -eq $Result -or $Result.PSObject.Properties.Name -notcontains 'HookActivation') { return '<none>' }
    $activation = $Result.HookActivation
    return ('{0}|{1}|{2}|{3}' -f [string]$activation.State, (@($activation.Steps) -join ';'), [string]$activation.DocsUrl, [string]$activation.Note)
}

function Test-HaStrictModeGuard {
    <#
    .SYNOPSIS
      Extracts Get-SyncHookActivation from sync-agent.ps1 (strict mode is on here) and checks that a
      publisher result without HookActivation yields null instead of throwing.
    #>
    $syncPath = Join-Path $repoRoot 'scripts/sync-agent.ps1'
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($syncPath, [ref]$null, [ref]$parseErrors)
    $function = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-SyncHookActivation' }, $true)) | Select-Object -First 1
    if ($null -eq $function) {
        Write-HaCheck 'sync' 'strict-mode-guard-extracted' $false 'Get-SyncHookActivation not found in scripts/sync-agent.ps1'
        return
    }
    Invoke-Expression $function.Extent.Text

    $threw = $false
    $missing = $null
    try { $missing = Get-SyncHookActivation -Result ([pscustomobject]@{ Success = $true; Implemented = $true }) } catch { $threw = $true }
    Write-HaCheck 'sync' 'strict-mode-missing-hookactivation' ((-not $threw) -and ($null -eq $missing)) 'a result without HookActivation must yield $null under strict mode'

    $threwNull = $false
    $nullActivation = 'unset'
    try { $nullActivation = Get-SyncHookActivation -Result $null } catch { $threwNull = $true }
    Write-HaCheck 'sync' 'strict-mode-null-result' ((-not $threwNull) -and ($null -eq $nullActivation)) 'a null result must yield $null under strict mode'

    $present = Get-SyncHookActivation -Result ([pscustomobject]@{ HookActivation = [pscustomobject]@{ State = 'manual'; Steps = @('x'); DocsUrl = $null; Note = 'n' } })
    Write-HaCheck 'sync' 'strict-mode-hookactivation-returned' ([string]$present.State -eq 'manual') 'a result with HookActivation must return it'
}

function Invoke-HaHermesConfigCase {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [AllowNull()][string] $ConfigText,
        [Parameter(Mandatory = $true)][bool] $Valid,
        [string[]] $MustKeep = @(),
        [Parameter(Mandatory = $true)][string] $WorkRoot
    )

    $scope = 'hermes'
    $root = Join-Path $WorkRoot ('hermes-config/' + $Name)
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot ([System.IO.Path]::GetFullPath($root))
    $configPath = $mapped.FixtureConfigYamlPath
    if ($null -ne $ConfigText) { [System.IO.File]::WriteAllText($configPath, $ConfigText, $script:HaUtf8) }
    $hashBefore = Get-HaFileHash -Path $configPath
    $pluginName = $script:HermesAdapterConstant.GuardPluginDirectoryName
    $pluginDir = Join-Path $mapped.FixturePluginsPath $pluginName
    $agentHooksDir = $mapped.FixtureAgentHooksPath

    $whatIfResult = Test-HaResult -Scope $scope -Check ("config-$Name-whatif") -Outputs (Invoke-HaPublishHooks -InstallRoot $root -WhatIf) -State ($(if ($Valid) { 'unavailable' } else { 'blocked' })) -Success $Valid
    Write-HaCheck $scope ("config-$Name-whatif-writes-nothing") ((Get-HaFileHash -Path $configPath) -eq $hashBefore -and -not (Test-Path -LiteralPath $pluginDir) -and -not (Test-Path -LiteralPath $agentHooksDir)) 'WhatIf must not change config.yaml or copy hook assets'

    $result = Test-HaResult -Scope $scope -Check ("config-$Name") -Outputs (Invoke-HaPublishHooks -InstallRoot $root) -State ($(if ($Valid) { 'unavailable' } else { 'blocked' })) -Success $Valid

    if ($Valid) {
        $after = [System.IO.File]::ReadAllText($configPath)
        Write-HaCheck $scope ("config-$Name-plugin-enabled") (Test-HermesPluginsEnabledContains -YamlText $after -PluginName $pluginName) 'plugins.enabled must list the guard plugin'
        Write-HaCheck $scope ("config-$Name-structure-after-merge") ((Test-HermesConfigYamlStructure -YamlText $after).Valid) 'merged config must stay inside the supported structure'
        foreach ($keep in $MustKeep) {
            Write-HaCheck $scope ("config-$Name-keeps:" + $keep) ($after.Contains($keep)) ("operator line lost: $keep")
        }
        $second = Invoke-HaPublishHooks -InstallRoot $root
        $secondText = [System.IO.File]::ReadAllText($configPath)
        Write-HaCheck $scope ("config-$Name-idempotent") (($secondText -ceq $after) -and (@($second).Count -eq 1)) 'second publish must not change config.yaml'
    }
    else {
        Write-HaCheck $scope ("config-$Name-byte-identical") ((Get-HaFileHash -Path $configPath) -eq $hashBefore) 'invalid config.yaml must stay byte-for-byte unchanged'
        Write-HaCheck $scope ("config-$Name-no-plugin-copy") (-not (Test-Path -LiteralPath $pluginDir)) 'no guard plugin may be copied when config is blocked'
        Write-HaCheck $scope ("config-$Name-no-agent-hooks") (-not (Test-Path -LiteralPath $agentHooksDir)) 'no agent hooks may be copied when config is blocked'
        Write-HaCheck $scope ("config-$Name-exit-code") ($null -ne $result -and [int]$result.ExitCode -ne 0) 'blocked publish must report a non-zero ExitCode'
    }
}

function Invoke-HaHermesConfigCases {
    param([Parameter(Mandatory = $true)][string] $WorkRoot)

    $valid = @(
        @{ Name = 'absent-config'; Text = $null; MustKeep = @() }
        @{ Name = 'plugins-flow-empty'; Text = "plugins: {}`n"; MustKeep = @() }
        @{ Name = 'plugins-flow-empty-comment'; Text = "plugins: {} # managed elsewhere`n"; MustKeep = @() }
        @{ Name = 'enabled-inline-comments'; Text = "plugins:`n  enabled:`n    - other-plugin # keep me`n"; MustKeep = @('other-plugin # keep me') }
        @{ Name = 'top-level-keys-and-comments'; Text = "# header comment`nmodel: example`nplugins:`n  enabled:`n    - other-plugin`n"; MustKeep = @('model: example', '# header comment') }
    )
    foreach ($case in $valid) {
        Invoke-HaHermesConfigCase -Name $case.Name -ConfigText $case.Text -Valid $true -MustKeep $case.MustKeep -WorkRoot $WorkRoot
    }

    $invalid = @(
        @{ Name = 'four-space-indent'; Text = "plugins:`n    enabled:`n        - other-plugin`n" }
        @{ Name = 'tab-indent'; Text = "plugins:`n`tenabled:`n`t`t- other-plugin`n" }
        @{ Name = 'duplicate-plugins-key'; Text = "plugins: {}`nplugins:`n  enabled:`n    - other-plugin`n" }
        @{ Name = 'enabled-empty-flow'; Text = "plugins:`n  enabled: []`n" }
        @{ Name = 'plugins-scalar'; Text = "plugins: none`n" }
    )
    foreach ($case in $invalid) {
        Invoke-HaHermesConfigCase -Name $case.Name -ConfigText $case.Text -Valid $false -WorkRoot $WorkRoot
    }
}

function Invoke-HaHermesSyncNonFatal {
    <#
    .SYNOPSIS
      Full sync-agent run for hermes with an invalid config.yaml: the hook is blocked, the sync
      continues, exits 0, reports the failure in the summary and leaves config.yaml unchanged.
    #>
    param([Parameter(Mandatory = $true)][string] $WorkRoot)

    $scope = 'sync'
    . (Join-Path $repoRoot 'adapters/hermes/HermesAdapter.ps1')
    $root = Join-Path $WorkRoot 'hermes-sync/install'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot ([System.IO.Path]::GetFullPath($root))
    [System.IO.File]::WriteAllText($mapped.FixtureConfigYamlPath, "plugins:`n    enabled:`n        - other-plugin`n", $script:HaUtf8)
    $hashBefore = Get-HaFileHash -Path $mapped.FixtureConfigYamlPath
    $summaryPath = Join-Path $WorkRoot 'hermes-sync/summary.json'

    $runner = (Get-Process -Id $PID).Path
    $previousSummary = [Environment]::GetEnvironmentVariable('TOOLKIT_SYNC_SUMMARY_PATH')
    [Environment]::SetEnvironmentVariable('TOOLKIT_SYNC_SUMMARY_PATH', $summaryPath)
    try {
        $output = (& $runner -NoProfile -File (Join-Path $repoRoot 'scripts/sync-agent.ps1') -Agent hermes -InstallRoot $root 2>&1 | Out-String)
        $exit = $LASTEXITCODE
    }
    finally {
        [Environment]::SetEnvironmentVariable('TOOLKIT_SYNC_SUMMARY_PATH', $previousSummary)
    }

    Write-HaCheck $scope 'hermes-invalid-config-sync-exit-0' ($exit -eq 0) ("sync-agent exit $exit; output: " + $output.Trim())
    $summary = $null
    if (Test-Path -LiteralPath $summaryPath -PathType Leaf) {
        $summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    $failureCount = if ($null -ne $summary -and $summary.PSObject.Properties.Name -contains 'HookFailures') { @($summary.HookFailures).Count } else { 0 }
    Write-HaCheck $scope 'hermes-invalid-config-summary-lists-failure' ($failureCount -ge 1) 'summary must list the blocked hook failure'
    $blocked = ($null -ne $summary) -and ($summary.PSObject.Properties.Name -contains 'HookActivation') -and ($null -ne $summary.HookActivation) -and ([string]$summary.HookActivation.State -eq 'blocked')
    Write-HaCheck $scope 'hermes-invalid-config-activation-blocked' $blocked 'summary HookActivation.State must be blocked'
    Write-HaCheck $scope 'hermes-invalid-config-byte-identical' ((Get-HaFileHash -Path $mapped.FixtureConfigYamlPath) -eq $hashBefore) 'config.yaml must stay byte-for-byte unchanged'
    $runtimeFile = Join-Path $root 'scripts/inventory/Invoke-MemoryBankInventory.ps1'
    Write-HaCheck $scope 'hermes-invalid-config-runtime-still-published' (Test-Path -LiteralPath $runtimeFile -PathType Leaf) 'a blocked hook must not stop the remaining sync steps'
}

function Invoke-HaAdapter {
    param(
        [Parameter(Mandatory = $true)] $Agent,
        [Parameter(Mandatory = $true)][string] $WorkRoot
    )

    $id = [string]$Agent.id
    . (Join-Path $repoRoot ('adapters/' + $Agent.module))

    $extra = @{}
    if ($id -eq 'copilot') { $extra['Mode'] = 'user' }
    if (-not $script:HaExpectedState.Contains($id)) {
        Write-HaCheck $id 'expected-state-declared' $false 'no expected HookActivation state is recorded in this check'
        return
    }
    $want = [string]$script:HaExpectedState[$id]

    $whatIfRoot = Join-Path $WorkRoot ($id + '/whatif')
    $null = Test-HaResult -Scope $id -Check 'whatif' -Outputs (Invoke-HaPublishHooks -InstallRoot $whatIfRoot -Extra $extra -WhatIf) -State $want
    $whatIfSnapshot = Get-HaTreeHashes -Root $whatIfRoot
    Write-HaCheck $id 'whatif-writes-nothing' ($whatIfSnapshot.Count -eq 0) 'WhatIf must not write any file'

    $root = Join-Path $WorkRoot ($id + '/publish')
    $first = Test-HaResult -Scope $id -Check 'publish-1' -Outputs (Invoke-HaPublishHooks -InstallRoot $root -Extra $extra) -State $want
    $snapshotA = Get-HaTreeHashes -Root $root
    $second = Test-HaResult -Scope $id -Check 'publish-2' -Outputs (Invoke-HaPublishHooks -InstallRoot $root -Extra $extra) -State $want
    $snapshotB = Get-HaTreeHashes -Root $root

    Write-HaCheck $id 'idempotent-activation' ((Get-HaActivationSignature -Result $first) -ceq (Get-HaActivationSignature -Result $second)) 'second publish must report the same HookActivation'
    # Claude keeps a timestamped audit backup per merge (RN03 backup-before-write); those are the only
    # files allowed to differ on republish. Every other published byte must stay the same.
    $auditBackup = '\.bak(\.\d{14})?$'
    $keysA = @($snapshotA.Keys | Where-Object { $_ -notmatch $auditBackup })
    $keysB = @($snapshotB.Keys | Where-Object { $_ -notmatch $auditBackup })
    $changed = @($keysA | Where-Object { $keysB -contains $_ -and $snapshotB[$_] -ne $snapshotA[$_] })
    $added = @($keysB | Where-Object { $keysA -notcontains $_ })
    $removed = @($keysA | Where-Object { $keysB -notcontains $_ })
    Write-HaCheck $id 'idempotent-files' (($changed.Count + $added.Count + $removed.Count) -eq 0) ("changed=[{0}] added=[{1}] removed=[{2}]" -f ($changed -join ', '), ($added -join ', '), ($removed -join ', '))

    $trustNames = @($snapshotB.Keys | Where-Object { $_ -match '(?i)(trust|consent|approv)' })
    Write-HaCheck $id 'no-trust-or-consent-files' ($trustNames.Count -eq 0) ('files: ' + ($trustNames -join ', '))
    $trustKeys = New-Object System.Collections.Generic.List[string]
    foreach ($relative in @($snapshotB.Keys | Where-Object { $_ -match '\.(json|ya?ml|toml)$' })) {
        $text = [System.IO.File]::ReadAllText((Join-Path $root $relative))
        if ($text -match '(?im)^\s*"?(trusted|trust|consent|approved|approval)"?\s*[:=]') { $trustKeys.Add($relative) }
    }
    Write-HaCheck $id 'no-trust-or-consent-keys' ($trustKeys.Count -eq 0) ('keys in: ' + ($trustKeys -join ', '))

    if ($id -eq 'hermes') {
        Invoke-HaHermesConfigCases -WorkRoot $WorkRoot
    }
}

$savedPath = $env:PATH
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $separator = [System.IO.Path]::PathSeparator
    $env:PATH = ((@($env:PATH -split [regex]::Escape($separator)) | Where-Object { $_ -and ($_ -notmatch '(?i)hermes') }) -join $separator)
    $hermesCli = Get-Command -Name 'hermes' -ErrorAction SilentlyContinue
    Write-HaCheck 'env' 'hermes-cli-hidden' ($null -eq $hermesCli) 'hermes CLI still on PATH; plugins enable would change the operator Hermes home'

    Test-HaStrictModeGuard

    $registry = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters/registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($agent in @($registry.agents)) {
        try {
            Invoke-HaAdapter -Agent $agent -WorkRoot $work
        }
        catch {
            Write-HaCheck ([string]$agent.id) 'execution' $false $_.Exception.Message
        }
    }

    try {
        Invoke-HaHermesSyncNonFatal -WorkRoot $work
    }
    catch {
        Write-HaCheck 'sync' 'hermes-invalid-config-sync' $false $_.Exception.Message
    }
}
finally {
    $env:PATH = $savedPath
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

if ($script:HaFailures.Count -gt 0) {
    Write-Host ('Assert-HookActivation: FAILED ({0}):' -f $script:HaFailures.Count) -ForegroundColor Red
    foreach ($failure in $script:HaFailures) { Write-Host ('  ' + $failure) -ForegroundColor Red }
    exit 1
}
Write-Host 'Assert-HookActivation: PASS'
exit 0
