#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$contractPath = Join-Path $repoRoot 'adapters\_shared\authorization-contract.json'
$guardPath = Join-Path $repoRoot 'adapters\_shared\GuardCommon.ps1'
$failures = [System.Collections.Generic.List[string]]::new()
$checks = 0

function Assert-S5($Name, [bool] $Condition, [string] $Reason) {
    $script:checks++
    if (-not $Condition) { $script:failures.Add("${Name}: $Reason") }
    else { Write-Host "${Name}: PASS" }
}

function Read-JsonContract([string] $Path) {
    try { return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop) }
    catch { throw "Invalid JSON contract at ${Path}: $($_.Exception.Message)" }
}

$contract = Read-JsonContract $contractPath
Assert-S5 'Shared contract schema' ($contract.schemaVersion -eq 1 -and @($contract.authorizations).Count -gt 0) 'schemaVersion 1 with non-empty authorizations is required'

$publishers = @(
    @{ Name = 'antigravity'; Publisher = 'adapters\antigravity\Publish-AntigravityHooks.ps1'; Constants = 'adapters\antigravity\AntigravityPathConstants.ps1'; Smoke = 'adapters\antigravity\Invoke-AntigravitySmokeValidate.ps1'; Uninstall = 'adapters\antigravity\Uninstall-AntigravityToolkit.ps1' },
    @{ Name = 'claude'; Publisher = 'adapters\claude\Publish-ClaudeHooks.ps1'; Constants = 'adapters\claude\ClaudePathConstants.ps1'; Smoke = 'adapters\claude\Invoke-ClaudeSmokeValidate.ps1'; Uninstall = 'adapters\claude\Uninstall-ClaudeToolkit.ps1' },
    @{ Name = 'codex'; Publisher = 'adapters\codex\Publish-CodexHooks.ps1'; Constants = 'adapters\codex\CodexPathConstants.ps1'; Smoke = 'adapters\codex\Invoke-CodexSmokeValidate.ps1'; Uninstall = 'adapters\codex\Uninstall-CodexToolkit.ps1' },
    @{ Name = 'copilot'; Publisher = 'adapters\copilot\Publish-CopilotHooks.ps1'; Constants = 'adapters\copilot\CopilotPathConstants.ps1'; Smoke = 'adapters\copilot\Invoke-CopilotSmokeValidate.ps1'; Uninstall = 'adapters\copilot\Uninstall-CopilotToolkit.ps1' },
    @{ Name = 'cursor'; Publisher = 'adapters\cursor\Publish-CursorHooks.ps1'; Constants = 'adapters\cursor\CursorPathConstants.ps1'; Smoke = 'adapters\cursor\Invoke-CursorSmokeValidate.ps1'; Uninstall = 'adapters\cursor\Uninstall-CursorToolkit.ps1' },
    @{ Name = 'grok'; Publisher = 'adapters\grok\Publish-GrokHooks.ps1'; Constants = 'adapters\grok\GrokPathConstants.ps1'; Smoke = 'adapters\grok\Invoke-GrokSmokeValidate.ps1'; Uninstall = 'adapters\grok\Uninstall-GrokToolkit.ps1' },
    @{ Name = 'hermes'; Publisher = 'adapters\hermes\Publish-HermesHooks.ps1'; Constants = 'adapters\hermes\HermesPathConstants.ps1'; Smoke = 'adapters\hermes\Invoke-HermesSmokeValidate.ps1'; Uninstall = 'adapters\hermes\Uninstall-HermesToolkit.ps1' },
    @{ Name = 'openhands'; Publisher = 'adapters\openhands\Publish-OpenHandsHooks.ps1'; Constants = 'adapters\openhands\OpenHandsPathConstants.ps1'; Smoke = 'adapters\openhands\Invoke-OpenHandsSmokeValidate.ps1'; Uninstall = 'adapters\openhands\Uninstall-OpenHandsToolkit.ps1' },
    @{ Name = 'zcode'; Publisher = 'adapters\zcode\Publish-ZCodeHooks.ps1'; Constants = 'adapters\zcode\ZCodePathConstants.ps1'; Smoke = 'adapters\zcode\Invoke-ZCodeSmokeValidate.ps1'; Uninstall = 'adapters\zcode\Uninstall-ZCodeToolkit.ps1' }
)

foreach ($provider in $publishers) {
    $publisherText = Get-Content -LiteralPath (Join-Path $repoRoot $provider.Publisher) -Raw
    $constantsText = Get-Content -LiteralPath (Join-Path $repoRoot $provider.Constants) -Raw
    Assert-S5 "$($provider.Name) publisher" (
        $publisherText -match 'PublishAuthorizationContract\.ps1' -and
        $publisherText -match 'Copy-ToolkitAuthorizationContract' -and
        $publisherText -match 'SharedAuthorizationContractFileName' -and
        $publisherText -match '(?s)Copy-ToolkitAuthorizationContract.{0,500}-InstallRoot\s+\$'
    ) 'publisher must validate and copy the contract beside GuardCommon.ps1'
    Assert-S5 "$($provider.Name) layout constants" (
        $constantsText -match 'SharedAuthorizationContractRelativePath\s*=\s*''adapters/_shared/authorization-contract\.json''' -and
        $constantsText -match 'SharedAuthorizationContractFileName\s*=\s*''authorization-contract\.json'''
    ) 'layout must identify the shared contract source and published filename'

    $smokeText = Get-Content -LiteralPath (Join-Path $repoRoot $provider.Smoke) -Raw
    $uninstallText = Get-Content -LiteralPath (Join-Path $repoRoot $provider.Uninstall) -Raw
    Assert-S5 "$($provider.Name) smoke lifecycle" (
        $smokeText -match 'SharedAuthorizationContractFileName|authorization-contract\.json'
    ) 'smoke validation must account for the published authorization contract'
    Assert-S5 "$($provider.Name) uninstall lifecycle" (
        $uninstallText -match 'SharedAuthorizationContractFileName|authorization-contract\.json'
    ) 'uninstall must account for the published authorization contract'
}

$openCodePublisherText = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters\opencode\Publish-OpenCodeHooks.ps1') -Raw
$openCodeSmokeText = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters\opencode\Invoke-OpenCodeSmokeValidate.ps1') -Raw
$openCodeUninstallText = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters\opencode\Uninstall-OpenCodeToolkit.ps1') -Raw
Assert-S5 'opencode publisher inventory' (
    $openCodePublisherText -match 'Copy-ToolkitFileIfAbsent' -and
    $openCodePublisherText -match 'relativeInventoryPath' -and
    $openCodePublisherText -match 'RelativePath'
) 'OpenCode plugin assets must publish and inventory authorization-contract.json'
Assert-S5 'opencode smoke lifecycle' ($openCodeSmokeText -match 'authorization-contract\.json') 'OpenCode smoke must account for the published authorization contract'
Assert-S5 'opencode uninstall lifecycle' ($openCodeUninstallText -match 'SharedAuthorizationContractFileName|authorization-contract\.json') 'OpenCode uninstall must account for the published authorization contract'

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('adt-auth-contract-' + [guid]::NewGuid().ToString('N'))
$fixtureGuard = Join-Path $fixtureRoot 'GuardCommon.ps1'
$fixtureContract = Join-Path $fixtureRoot 'authorization-contract.json'
try {
    $null = New-Item -ItemType Directory -Path $fixtureRoot -Force
    Copy-Item -LiteralPath $guardPath -Destination $fixtureGuard

    & {
        . $fixtureGuard
        $threw = $false
        try { $null = Get-ToolkitAuthorizationContract } catch { $threw = $_.Exception.Message -match 'Authorization contract is missing' }
        Assert-S5 'Missing runtime contract' $threw 'missing contract must produce an observable fail-closed error'
    }

    Set-Content -LiteralPath $fixtureContract -Value '{"schemaVersion":1,"authorizations":[' -Encoding utf8
    & {
        . $fixtureGuard
        $threw = $false
        try { $null = Get-ToolkitAuthorizationContract } catch { $threw = $_.Exception.Message -match 'Authorization contract is invalid JSON' }
        Assert-S5 'Malformed runtime contract' $threw 'malformed contract must produce an observable fail-closed error'
    }

    Copy-Item -LiteralPath $contractPath -Destination $fixtureContract
    & {
        . $fixtureGuard
        $loaded = Get-ToolkitAuthorizationContract
        Assert-S5 'Valid runtime contract' ($null -ne $loaded -and @($loaded.authorizations).Count -gt 0) 'valid contract must load beside GuardCommon.ps1'
    }
}
finally {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) { throw ($failures -join [Environment]::NewLine) }
Write-Host ("Assert-PowerShellAuthorizationContractPublish: PASS ({0} checks)" -f $checks)
