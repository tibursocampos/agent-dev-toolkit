#Requires -Version 5.1
# Tests:
#   Should_KeepEverySkillManifestUnderCeiling_When_CoreSkillsChanged
#
# Ceiling: 31325 bytes per core/skills/**/SKILL.md. It is the current largest manifest
# (core/skills/sdd-develop/SKILL.md, 28477 bytes) plus a 10 percent margin, rounded up.
# The check reads the core source, so it does not depend on the install root path. Published Claude
# copies are larger because placeholders resolve to absolute paths and the frontmatter overlay adds keys.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }

$skillManifestCeilingBytes = 31325

$n = 'Should_KeepEverySkillManifestUnderCeiling_When_CoreSkillsChanged'
$coreSkillsRoot = Join-Path $repoRoot 'core\skills'
$manifests = @(Get-ChildItem -LiteralPath $coreSkillsRoot -Recurse -File -Filter 'SKILL.md')
if ($manifests.Count -eq 0) { Write-Fail $n 'no core SKILL.md manifests found' }
foreach ($manifest in $manifests) {
    if ($manifest.Length -gt $skillManifestCeilingBytes) {
        $relative = $manifest.FullName.Substring($repoRoot.Length).TrimStart('\', '/')
        Write-Fail $n ("{0} is {1} bytes; ceiling is {2} bytes" -f $relative, $manifest.Length, $skillManifestCeilingBytes)
    }
}
Write-Pass $n

Write-Host 'Assert-ClaudeSkillSize: ALL PASS'
exit 0
