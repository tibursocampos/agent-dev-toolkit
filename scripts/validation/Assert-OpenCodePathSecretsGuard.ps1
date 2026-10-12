#Requires -Version 5.1
# Tests:
#   Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization
#   Should_NotExposeSecretValue_When_HeuristicPatternMatches
#   Should_Pass_When_AgentsCapabilityTrue
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$pluginPath = Join-Path $repoRoot 'adapters\opencode\assets\plugins\agent-dev-toolkit-marker.js'
$adapterPath = Join-Path $repoRoot 'adapters\opencode\OpenCodeAdapter.ps1'
if (-not (Test-Path -LiteralPath $pluginPath) -or -not (Test-Path -LiteralPath $adapterPath)) {
    throw 'OpenCode plugin or adapter source is missing'
}

$nodeCmd = Get-Command -Name node -ErrorAction SilentlyContinue
if ($null -eq $nodeCmd) { throw 'node is required to evaluate the OpenCode plugin authorization boundary' }

$eval = @'
import { pathToFileURL } from 'url';
const m = await import(pathToFileURL(process.argv[1]).href);
const root = process.cwd();
const secret = 'ghp_TESTNOTREAL_aaaaabbbbbcccccddddd';
const cases = [
  ['write', { path: 'PRD/legacy.md', content: '# x' }],
  ['write', { path: '/tmp/toolkit-temp.md', content: '# x' }],
  ['new_provider_tool', { opaque: true }],
  ['write', { path: 'src/safe.ts', content: `const token = "${secret}";` }],
];
for (const [tool, args] of cases) {
  const verdict = m.evaluatePathSecretsGuard(tool, args, root);
  if (verdict.decision !== 'allow') { console.error(JSON.stringify(verdict)); process.exit(1); }
  if (JSON.stringify(verdict).includes(secret)) { console.error('secret value leaked'); process.exit(1); }
}
console.log('host-owns-authorization-ok');
'@
$output = & node --input-type=module -e $eval $pluginPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $output -notmatch 'host-owns-authorization-ok') {
    throw ("OpenCode evaluator must not veto path/tool operations or expose heuristic secret values: {0}" -f $output.Trim())
}
Write-Host 'Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization: PASS'
Write-Host 'Should_NotExposeSecretValue_When_HeuristicPatternMatches: PASS'

. $adapterPath
$caps = Get-Capabilities
if (-not $caps.Capabilities.agents) { throw 'OpenCode Get-Capabilities agents must remain true' }
Write-Host 'Should_Pass_When_AgentsCapabilityTrue: PASS'
Write-Host 'Assert-OpenCodePathSecretsGuard: ALL PASS'
exit 0
