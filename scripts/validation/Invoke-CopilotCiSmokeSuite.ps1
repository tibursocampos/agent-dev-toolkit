#Requires -Version 5.1
<#
.SYNOPSIS
  In-repo Copilot CI smoke matrix (Mode user + Mode repo).

.DESCRIPTION
  Copies the versioned Copilot fixture seed for each mode into its own ephemeral
  work InstallRoot, then chains sync-agent + validate-agent for both Copilot
  modes. Does not require a GitHub Copilot profile, IDE extension, or login.
  Does not write under USERPROFILE. Each ephemeral work InstallRoot is removed
  after evaluation (pass or fail) unless -KeepWorkRoot is set.

.PARAMETER Quiet
  Suppress per-mode banners; print summary only.

.PARAMETER KeepWorkRoot
  Skip deleting the ephemeral work InstallRoots after evaluation (debugging aid).

.EXAMPLE
  pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
#>
[CmdletBinding()]
param(
    [switch] $Quiet,
    [switch] $KeepWorkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'Invoke-EphemeralFixtureSmoke.ps1')

$suiteTitle = 'agent-dev-toolkit Copilot CI smoke suite'
$agentId = $script:ToolkitConstant.CopilotAgentId
$suiteModes = @(
    @{
        Mode           = $script:ToolkitConstant.CopilotModeUser
        SeedFixtureRel = $script:ToolkitConstant.CopilotFixtureUserRel
        WorkFixtureRel = $script:ToolkitConstant.CopilotWorkFixtureUserRel
    },
    @{
        Mode           = $script:ToolkitConstant.CopilotModeRepo
        SeedFixtureRel = $script:ToolkitConstant.CopilotFixtureRepoRel
        WorkFixtureRel = $script:ToolkitConstant.CopilotWorkFixtureRepoRel
    }
)

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

function Assert-CopilotSkillTreeMatchesSource {
    param(
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][string] $DestinationRoot,
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $Mode
    )

    $root = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd([char[]]@('\', '/')) -replace '\\', '/'
    $replacements = [ordered]@{
        '{{TOOLKIT_ROOT}}' = $root
        '{{SDD_ROOT}}' = ($root + '/sdd')
        '{{GUARDRAILS_PATH}}' = ($root + '/instructions/guardrails.instructions.md')
    }
    $sourceFiles = @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -File | Sort-Object FullName)
    $expectedRelativePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $managedSkillNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($sourceDirectory in (Get-ChildItem -LiteralPath $SourceRoot -Directory)) {
        [void]$managedSkillNames.Add($sourceDirectory.Name)
    }
    foreach ($sourceFile in $sourceFiles) {
        $relative = $sourceFile.FullName.Substring($SourceRoot.Length).TrimStart([char[]]@('\', '/'))
        [void]$expectedRelativePaths.Add($relative)
        $destinationFile = Join-Path $DestinationRoot $relative
        if (-not (Test-Path -LiteralPath $destinationFile -PathType Leaf)) {
            throw ("Mode={0}: copied skill file is missing: {1}" -f $Mode, $relative)
        }

        $expected = [System.IO.File]::ReadAllText($sourceFile.FullName)
        foreach ($token in $replacements.Keys) {
            $expected = $expected.Replace([string]$token, [string]$replacements[$token])
        }
        $actual = [System.IO.File]::ReadAllText($destinationFile)
        if (-not [string]::Equals($expected, $actual, [System.StringComparison]::Ordinal)) {
            throw ("Mode={0}: generated skill content differs from canonical source beyond placeholder rendering: {1}" -f $Mode, $relative)
        }

        if ($sourceFile.Name -ceq 'SKILL.md' -and $sourceFile.Directory.Parent.FullName -eq [System.IO.Path]::GetFullPath($SourceRoot).TrimEnd([char[]]@('\', '/'))) {
            $folderName = $sourceFile.Directory.Name
            $content = [System.IO.File]::ReadAllText($destinationFile)
            if ($content -notmatch '(?s)^---\r?\n.*?\r?\n---') {
                throw ("Mode={0}: skill frontmatter missing for {1}" -f $Mode, $folderName)
            }
            $frontmatter = [regex]::Match($content, '(?s)^---\r?\n(.*?)\r?\n---').Groups[1].Value
            $nameMatch = [regex]::Match($frontmatter, '(?m)^name:\s*([^\r\n]+)\s*$')
            $descriptionMatch = [regex]::Match($frontmatter, '(?ms)^description:\s*(.+?)(?=\r?\n\w[\w-]*:|\z)')
            if (-not $nameMatch.Success -or $nameMatch.Groups[1].Value.Trim() -cne $folderName -or
                $folderName -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or -not $descriptionMatch.Success -or
                [string]::IsNullOrWhiteSpace($descriptionMatch.Groups[1].Value.Trim())) {
                throw ("Mode={0}: generated skill discovery metadata invalid for {1}" -f $Mode, $folderName)
            }
        }
    }

    foreach ($generatedFile in (Get-ChildItem -LiteralPath $DestinationRoot -Recurse -File)) {
        $relative = $generatedFile.FullName.Substring($DestinationRoot.Length).TrimStart([char[]]@('\', '/'))
        $firstSegment = ($relative -split '[\\/]')[0]
        if ($firstSegment -eq '.toolkit-managed-skills.json' -or -not $managedSkillNames.Contains($firstSegment)) {
            continue
        }
        if (-not $expectedRelativePaths.Contains($relative)) {
            throw ("Mode={0}: generated managed skill tree contains a non-source file: {1}" -f $Mode, $relative)
        }
    }
    return $sourceFiles.Count
}

function Assert-CopilotAgentAndHookMaterialization {
    param(
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $Mode,
        [Parameter(Mandatory = $true)][string] $RepoRoot
    )

    $agentsRoot = Join-Path $InstallRoot 'agents'
    $sourceAgentsRoot = Join-Path $RepoRoot 'core/agents'
    $expectedInstructionFlag = @('architect', 'database', 'repo-analyst', 'security')
    foreach ($source in (Get-ChildItem -LiteralPath $sourceAgentsRoot -File -Filter '*.md')) {
        $agentId = $source.BaseName
        $profilePath = Join-Path $agentsRoot ($agentId + '.agent.md')
        $legacyPath = Join-Path $agentsRoot ($agentId + '.md')
        if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
            throw ("Mode={0}: canonical custom agent .agent.md profile is missing: {1}" -f $Mode, $agentId)
        }
        if (-not (Test-Path -LiteralPath $legacyPath -PathType Leaf)) {
            throw ("Mode={0}: Copilot CLI custom agent .md profile is missing: {1}" -f $Mode, $agentId)
        }

        # Keep both host surfaces. The legacy .md file is also a supported CLI
        # profile and may be a pre-existing, unowned user file; do not require
        # its deletion to satisfy the canonical VS Code .agent.md check.

        $profile = [System.IO.File]::ReadAllText($profilePath)
        if ($profile -notmatch '(?s)^---\r?\n.*?\r?\n---') {
            throw ("Mode={0}: custom agent profile has no YAML frontmatter: {1}" -f $Mode, $agentId)
        }
        $hasRepoInstructions = $profile -match '(?m)^include-custom-instructions:\s*true\s*$'
        $shouldInclude = $expectedInstructionFlag -contains $agentId
        if ($hasRepoInstructions -ne $shouldInclude) {
            throw ("Mode={0}: include-custom-instructions mismatch for {1}" -f $Mode, $agentId)
        }
        if ($profile -notmatch ("(?m)^name:\s*{0}\s*$" -f [regex]::Escape($agentId)) -or
            $profile -notmatch '(?m)^description:\s*\S') {
            throw ("Mode={0}: custom agent name/description metadata invalid: {1}" -f $Mode, $agentId)
        }
    }

    $hooksRoot = Join-Path $InstallRoot 'hooks'
    $hooksConfig = Get-Content -LiteralPath (Join-Path $hooksRoot 'hooks.json') -Raw | ConvertFrom-Json
    $hook = @($hooksConfig.hooks.preToolUse | Where-Object { $_.type -eq 'command' }) | Select-Object -First 1
    if ($null -eq $hook -or [string]::IsNullOrWhiteSpace([string]$hook.cwd)) {
        throw ("Mode={0}: preToolUse command hook is missing cwd" -f $Mode)
    }
    $cwd = [string]$hook.cwd
    if (-not [System.IO.Path]::IsPathRooted($cwd)) {
        $cwd = Join-Path $RepoRoot $cwd
    }
    $resolvedHookScript = [System.IO.Path]::GetFullPath((Join-Path $cwd 'guard-pre-tool.ps1'))
    $expectedHookScript = [System.IO.Path]::GetFullPath((Join-Path $hooksRoot 'guard-pre-tool.ps1'))
    if (-not [string]::Equals($resolvedHookScript, $expectedHookScript, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolvedHookScript -PathType Leaf) -or
        [string]$hook.command -notmatch '(?i)-File\s+\./guard-pre-tool\.ps1') {
        throw ("Mode={0}: preToolUse command does not resolve from its configured cwd to the published hook script" -f $Mode)
    }
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host $suiteTitle -ForegroundColor Cyan
    Write-Host ('=' * $suiteTitle.Length) -ForegroundColor Cyan
    Write-Host 'Filesystem-only; no Copilot profile / IDE extension required.' -ForegroundColor DarkGray
    Write-Host ''
}

$results = @()
foreach ($entry in $suiteModes) {
    $seedFixtureRoot = Join-Path $repoRoot ($entry.SeedFixtureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $seedFixtureRoot)) {
        Write-Host ("Missing fixture InstallRoot: {0}" -f $seedFixtureRoot) -ForegroundColor Red
        exit 1
    }

    $result = Invoke-EphemeralFixtureSmoke `
        -RepoRoot $repoRoot `
        -SeedFixtureRel $entry.SeedFixtureRel `
        -WorkFixtureRel $entry.WorkFixtureRel `
        -AgentId $agentId `
        -Mode $entry.Mode `
        -Quiet:$Quiet `
        -KeepWorkRoot:$true

    $seededFailureStatus = 'SKIPPED'
    $skillCopyStatus = 'SKIPPED'
    $workInstallRoot = Join-Path $repoRoot ($entry.WorkFixtureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ($result.Status -eq 'PASS') {
        try {
            Assert-CopilotAgentAndHookMaterialization -InstallRoot $workInstallRoot -Mode $entry.Mode -RepoRoot $repoRoot
            $sourceSkillsRoot = Join-Path (Join-Path $repoRoot 'core') 'skills'
            $destinationSkillsRoot = Join-Path $workInstallRoot 'skills'
            $copiedSkillFiles = Assert-CopilotSkillTreeMatchesSource `
                -SourceRoot $sourceSkillsRoot `
                -DestinationRoot $destinationSkillsRoot `
                -InstallRoot $workInstallRoot `
                -Mode $entry.Mode
            $skillCopyStatus = 'SOURCE_MATCH({0})' -f $copiedSkillFiles

            $adapterPath = Join-Path (Join-Path $repoRoot 'adapters/copilot') 'CopilotAdapter.ps1'
            . $adapterPath
            $primaryInstructions = Join-Path $workInstallRoot 'copilot-instructions.md'
            if (-not (Test-Path -LiteralPath $primaryInstructions -PathType Leaf)) {
                throw ("Seed precondition missing: {0}" -f $primaryInstructions)
            }

            Remove-Item -LiteralPath $primaryInstructions -Force
            $seeded = Invoke-SmokeValidate -InstallRoot $workInstallRoot -Mode $entry.Mode
            if ($seeded.EvidenceType -ne 'static' -or $seeded.HostExecutionStatus -ne 'SKIPPED') {
                throw 'Smoke result did not distinguish static evidence from host execution.'
            }
            if ($seeded.Success -or $seeded.FailureCode -ne 'static-check-failed') {
                throw 'Smoke did not detect seeded missing primary instructions.'
            }
            $seededFailureStatus = 'DETECTED'
        }
        catch {
            Write-Host ("Seeded failure check Mode={0}: FAIL - {1}" -f $entry.Mode, $_.Exception.Message) -ForegroundColor Red
            $result = [PSCustomObject]@{ Status = 'FAIL'; ExitCode = 1 }
            $seededFailureStatus = 'FAIL'
        }
        finally {
            if (-not $KeepWorkRoot) {
                Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
            }
        }
    }
    elseif (-not $KeepWorkRoot) {
        Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
    }

    $results += [PSCustomObject]@{
        Mode     = $entry.Mode
        Status   = $result.Status
        Evidence = 'static'
        SkillCopy = $skillCopyStatus
        HostExecution = 'SKIPPED'
        SeededFailure = $seededFailureStatus
        ExitCode = $result.ExitCode
    }

    if ($result.Status -eq 'FAIL') {
        break
    }
}

Write-Host ''
Write-Host 'Copilot CI smoke summary' -ForegroundColor Cyan
Write-Host '------------------------' -ForegroundColor Cyan
foreach ($result in $results) {
    $color = if ($result.Status -eq 'PASS') { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    Write-Host ("  Mode={0}: {1}; Evidence={2}; SkillCopy={3}; HostExecution={4}; SeededFailure={5}" -f $result.Mode, $result.Status, $result.Evidence, $result.SkillCopy, $result.HostExecution, $result.SeededFailure) -ForegroundColor $color
}

$failed = @($results | Where-Object { $_.Status -ne 'PASS' })
if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host 'Copilot CI smoke suite FAILED.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Copilot CI smoke suite PASSED (user + repo; no home deploy).' -ForegroundColor Green
exit 0
