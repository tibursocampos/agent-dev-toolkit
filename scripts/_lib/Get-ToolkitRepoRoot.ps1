#Requires -Version 5.1
<#
.SYNOPSIS
  Resolves the agent-dev-toolkit repository root from a nested path.

.DESCRIPTION
  Walks parents until both core/skills and README.md exist.
#>

$toolkitLibDir = $PSScriptRoot
. (Join-Path $toolkitLibDir 'ToolkitConstants.ps1')

function Get-ToolkitRepoRoot {
    [CmdletBinding()]
    param(
        [string] $FromPath = $PSScriptRoot
    )

    if ([string]::IsNullOrWhiteSpace($FromPath)) {
        throw ($script:ToolkitMessage.FromPathRequired)
    }

    $coreSkillsSegment = $script:ToolkitConstant.CoreSkillsDirectoryName
    $skillsSegment = $script:ToolkitConstant.SkillsDirectoryName
    $readmeName = $script:ToolkitConstant.ReadmeFileName

    $candidate = $FromPath
    while ($true) {
        $coreSkillsPath = Join-Path (Join-Path $candidate $coreSkillsSegment) $skillsSegment
        $readmePath = Join-Path $candidate $readmeName
        if ((Test-Path -LiteralPath $coreSkillsPath) -and (Test-Path -LiteralPath $readmePath)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }

        $parent = Split-Path -Parent $candidate
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $candidate) {
            break
        }

        $candidate = $parent
    }

    throw ($script:ToolkitMessage.ToolkitRepoRootNotFound -f $FromPath)
}

function Import-ToolkitPathLib {
    param([string] $ScriptRoot = $PSScriptRoot)

    $libPath = Join-Path (Split-Path -Parent $ScriptRoot) '_lib\Get-ToolkitRepoRoot.ps1'
    if (-not (Test-Path -LiteralPath $libPath)) {
        throw ($script:ToolkitMessage.ToolkitPathLibNotFound -f $libPath)
    }

    . $libPath
}
