#Requires -Version 5.1
# Tests:
#   Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization
#   Should_RemoveLegacyFailClosedShellHook_When_HermesConfigMerged
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$pluginPath = Join-Path $repoRoot 'adapters\hermes\assets\plugins\agent-dev-toolkit-guard\__init__.py'
$publishPath = Join-Path $repoRoot 'adapters\hermes\Publish-HermesHooks.ps1'
if (-not (Test-Path -LiteralPath $pluginPath) -or -not (Test-Path -LiteralPath $publishPath)) {
    throw 'Hermes compatibility plugin or publisher is missing'
}

$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if ($null -eq $python) { throw 'Python is required to evaluate the Hermes plugin boundary' }

$probe = @'
import importlib.util, pathlib, sys
spec = importlib.util.spec_from_file_location("adt_guard", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
secret = "ghp_TESTNOTREAL_aaaaabbbbbcccccddddd"
cases = [
    ("write_file", {"path": "PRD/legacy.md", "content": "x"}),
    ("write_file", {"path": "/tmp/toolkit-temp.md", "content": "x"}),
    ("future_provider_tool", {"opaque": True}),
    ("write_file", {"path": "src/test.py", "content": secret}),
]
for name, args in cases:
    if module.evaluate_tool_call(name, args) is not None:
        raise SystemExit(f"Toolkit vetoed {name}")
print("host-owns-authorization-ok")
'@
$output = & $python.Source -c $probe $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $output -notmatch 'host-owns-authorization-ok') {
    throw ("Hermes plugin must return control to native authorization: {0}" -f $output.Trim())
}
Write-Host 'Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization: PASS'
$pluginText = Get-Content -LiteralPath $pluginPath -Raw -Encoding UTF8
if ($pluginText -match 'register_hook\(') { throw 'Hermes compatibility plugin must not register a Toolkit authorization callback' }

$publisherText = Get-Content -LiteralPath $publishPath -Raw -Encoding UTF8
if ($publisherText -notmatch 'Remove-HermesToolkitPreToolCallEntries' -or
    $publisherText -match 'Merge-HermesPreToolCallHook -YamlText \$pluginsResult\.Text') {
    throw 'Hermes publisher must strip legacy fail-closed Toolkit shell-hook entries'
}
Write-Host 'Should_RemoveLegacyFailClosedShellHook_When_HermesConfigMerged: PASS'
Write-Host 'Assert-HermesPathSecretsGuard: ALL PASS'
exit 0
