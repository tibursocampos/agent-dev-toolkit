#Requires -Version 5.1
<#
.SYNOPSIS
  Structural validation for feature CHANGE.md (REQ-004 / CA3).

.DESCRIPTION
  Deterministic checks only — no LLM. Exit 0 when CHANGE.md has ADDED,
  MODIFIED, and REMOVED section headings. Exit 1 otherwise.

.PARAMETER Path
  Absolute or relative path to a CHANGE.md file under features/NNN-slug/.

.EXAMPLE
  .\scripts\validation\validate-change.ps1 -Path features\005-x\CHANGE.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Path
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

function Write-ValidateFail {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-change: FAIL - {0}" -f $Message) -ForegroundColor Red
}

function Write-ValidatePass {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-change: PASS - {0}" -f $Message) -ForegroundColor Green
}

$resolved = $Path
if (-not [System.IO.Path]::IsPathRooted($resolved)) {
    $resolved = Join-Path (Get-Location).Path $Path
}

if (-not (Test-Path -LiteralPath $resolved)) {
    Write-ValidateFail -Message ("file not found: {0}" -f $Path)
    exit 1
}

$item = Get-Item -LiteralPath $resolved
if ($item.Length -le 0) {
    Write-ValidateFail -Message ("empty file: {0}" -f $resolved)
    exit 1
}

$text = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-ValidateFail -Message ("empty content: {0}" -f $resolved)
    exit 1
}

$sectionPattern = $script:ToolkitConstant.SddArtifactChangeSectionPattern
$requiredSections = @('ADDED', 'MODIFIED', 'REMOVED')
$found = @{}
$recognizedAliases = [System.Collections.Generic.List[string]]::new()
foreach ($name in $requiredSections) {
    $found[$name] = $false
}

foreach ($m in [regex]::Matches($text, $sectionPattern)) {
    $rawLabel = $m.Groups[1].Value.Trim()
    $alias = Resolve-SddArtifactAlias -Domain 'change-section' -Value $rawLabel
    if ($alias.Recognized -and $found.ContainsKey($alias.Canonical)) {
        $found[$alias.Canonical] = $true
        if ($rawLabel -cnotmatch '^(?i)(ADDED|MODIFIED|REMOVED)$') {
            [void]$recognizedAliases.Add(("'{0}' => {1}" -f $rawLabel, $alias.Canonical))
        }
    }
}

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($name in $requiredSections) {
    if (-not $found[$name]) {
        $translation = switch ($name) {
            'ADDED' { 'ADDED/ADICIONADO/INCLUÍDO' }
            'MODIFIED' { 'MODIFIED/MODIFICADO/ALTERADO' }
            'REMOVED' { 'REMOVED/REMOVIDO/EXCLUÍDO' }
        }
        $failures.Add(("missing ## {0} section heading (accepted aliases: {1})" -f $name, $translation))
    }
}

# Forbid OpenSpec-style trees as the current baseline convention
$forbiddenCurrent = $script:ToolkitConstant.SddArtifactChangeForbiddenCurrentPattern
if ($text -match $forbiddenCurrent) {
    $failures.Add('CHANGE must not treat openspec/ .specs/ or .specify/ as current-spec roots')
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-ValidateFail -Message $f
    }
    exit 1
}

$aliasSummary = if ($recognizedAliases.Count -gt 0) { "; normalized: {0}" -f ([string]::Join(', ', $recognizedAliases.ToArray())) } else { '' }
Write-ValidatePass -Message ('ADDED, MODIFIED, and REMOVED sections present' + $aliasSummary)
exit 0
