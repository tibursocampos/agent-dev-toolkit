#Requires -Version 5.1
<#
.SYNOPSIS
  Generic adapter CI smoke: publish into a seeded InstallRoot, then validate-agent -SkipCore.

.DESCRIPTION
  Replaces the per-adapter Invoke-*CiSmoke wrappers. The InstallRoot is seeded from
  scripts/validation/fixtures/seed-user-root/ (unrelated operator files plus a stale managed-skills
  marker), published once with sync-agent.ps1, and validated. The operator files must survive.
  Copilot is smoked in both user and repo mode.

.PARAMETER Adapter
  Registry adapter id (required).

.PARAMETER KeepWorkRoot
  Keep <repo>/.adt-work/<guid>/ for debugging.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Adapter,
    [switch] $Quiet,
    [switch] $KeepWorkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'scripts/_lib/New-ToolkitWorkRoot.ps1')
. (Join-Path $repoRoot 'scripts/_lib/ToolkitConstants.ps1')

$registry = Get-Content -LiteralPath (Join-Path $repoRoot 'adapters/registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$agent = @($registry.agents | Where-Object { $_.id -eq $Adapter }) | Select-Object -First 1
if ($null -eq $agent) { Write-Host "Invoke-AdapterCiSmoke: FAIL - unknown adapter '$Adapter'" -ForegroundColor Red; exit 1 }

$displayNames = @{ cursor = 'Cursor'; antigravity = 'Antigravity'; claude = 'Claude'; codex = 'Codex'; copilot = 'Copilot'; opencode = 'OpenCode'; grok = 'Grok'; zcode = 'ZCode'; hermes = 'Hermes'; openhands = 'OpenHands' }
$display = if ($displayNames.ContainsKey($Adapter)) { $displayNames[$Adapter] } else { $Adapter }
$seedRoot = Join-Path $repoRoot 'scripts/validation/fixtures/seed-user-root'
$runner = (Get-Process -Id $PID).Path
$passMarker = $script:ToolkitConstant.AdapterSmokePassMarker
$modes = if ($Adapter -eq 'copilot') { @('user', 'repo') } else { @('') }

function Fail([string] $Reason) {
    Write-Host ("Invoke-{0}CiSmoke: FAIL - {1}" -f $display, $Reason) -ForegroundColor Red
    exit 1
}

function Assert-PublishedSkillReferences([string] $InstallRoot) {
    $layouts = switch ($Adapter) {
        'codex' {
            foreach ($skills in @('skills', 'plugins/agent-dev-toolkit/skills', '.agents/skills')) {
                @{ Skills = $skills; Branch = 'rules/branch-validation.md'; Delivery = 'rules/ai-stealth.md' }
            }
        }
        'claude' { @{ Skills = 'skills'; Branch = 'rules/branch-validation.md'; Delivery = 'rules/ai-stealth.md' } }
        'antigravity' {
            $rules = 'config/plugins/agent-dev-toolkit/GUARDRAILS.md'
            @{ Skills = 'config/skills'; Branch = $rules; Delivery = $rules }
        }
        'hermes' { @{ Skills = 'skills'; Branch = 'AGENTS.md'; Delivery = 'AGENTS.md' } }
        'openhands' { @{ Skills = '.agents/skills'; Branch = 'AGENTS.md'; Delivery = 'AGENTS.md' } }
        { $_ -in 'opencode', 'zcode' } {
            @{ Skills = 'skills'; Branch = 'skills/_shared/policy/branch-validation.md'; Delivery = 'skills/_shared/policy/ai-stealth.md' }
        }
    }
    foreach ($layout in $layouts) {
        $skillsRoot = Join-Path $InstallRoot $layout.Skills
        $toolkitRoot = Split-Path -Parent $skillsRoot
        $references = @(
            @{ Source = 'adt-read-sdd-artifact/references/normalize-path.md'; Target = (Join-Path $toolkitRoot 'scripts/runtime/Resolve-SddSourceContext.ps1'); Text = '' },
            @{ Source = 'adt-developer/SKILL.md'; Target = (Join-Path $InstallRoot $layout.Branch); Text = '# Branch validation before commit/push' },
            @{ Source = 'adt-delivery-implement/SKILL.md'; Target = (Join-Path $InstallRoot $layout.Delivery); Text = '# AI stealth policy' },
            @{ Source = 'adt-developer/SKILL.md'; Target = (Join-Path $skillsRoot '_shared/developer-common/GUIDE.md'); Text = '' }
        )
        foreach ($reference in $references) {
            $source = Join-Path $skillsRoot $reference.Source
            $target = $reference.Target -replace '\\', '/'
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { Fail "missing published skill: $source" }
            if (-not [System.IO.File]::ReadAllText($source).Contains($target)) {
                Fail "published skill $source does not resolve its reference to $target"
            }
            if (-not (Test-Path -LiteralPath $reference.Target -PathType Leaf)) { Fail "missing published reference: $target" }
            if ($reference.Text -and -not [System.IO.File]::ReadAllText($reference.Target).Contains($reference.Text)) {
                Fail "published reference $target does not contain the referenced rule"
            }
        }
    }
}

if (-not $Quiet) { Write-Host ("agent-dev-toolkit {0} CI smoke" -f $display) -ForegroundColor Cyan }
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    foreach ($mode in $modes) {
        $label = if ($mode) { "$Adapter-$mode" } else { $Adapter }
        $installRoot = Join-Path $work ($label + '/install')
        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
        Copy-Item -LiteralPath @(Get-ChildItem -LiteralPath $seedRoot -Force | ForEach-Object { $_.FullName }) -Destination $installRoot -Recurse -Force
        $seedSkillsMarker = Join-Path $installRoot 'skills/.toolkit-managed-skills.json'
        if (-not (Test-Path -LiteralPath $seedSkillsMarker)) { Fail 'seed fixture is incomplete' }

        $syncArgs = @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts/sync-agent.ps1'), '-Agent', $Adapter, '-InstallRoot', $installRoot)
        $validateArgs = @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts/validate-agent.ps1'), '-Agent', $Adapter, '-InstallRoot', $installRoot, '-Quiet', '-SkipCore')
        if ($mode) { $syncArgs += @('-Mode', $mode); $validateArgs += @('-Mode', $mode) }
        if ($Adapter -eq 'codex') { $syncArgs += '-UserScope' }

        Write-Host ('PUBLISH {0}' -f $label)
        $syncOutput = (& $runner @syncArgs 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { Fail ("sync-agent exit {0}: {1}" -f $LASTEXITCODE, $syncOutput.Trim()) }
        $validateOutput = (& $runner @validateArgs 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { Fail ("validate-agent exit {0}: {1}" -f $LASTEXITCODE, $validateOutput.Trim()) }
        if ($validateOutput -notlike ('*{0}*' -f $passMarker)) { Fail ("validate-agent output lacks '{0}': {1}" -f $passMarker, $validateOutput.Trim()) }

        Assert-PublishedSkillReferences -InstallRoot $installRoot

        foreach ($operatorFile in @('README.md', 'notes/operator-notes.txt', 'skills/user-own-skill/SKILL.md')) {
            if (-not (Test-Path -LiteralPath (Join-Path $installRoot $operatorFile) -PathType Leaf)) { Fail ("publishing removed the operator file '{0}'" -f $operatorFile) }
        }
    }
    Write-Host ("Invoke-{0}CiSmoke: PASS" -f $display) -ForegroundColor Green
}
finally {
    if (-not $KeepWorkRoot) { Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work }
}
exit 0
