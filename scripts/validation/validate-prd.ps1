#Requires -Version 5.1
<#
.SYNOPSIS
  Structural validation for Classic SDD PRD markdown (REQ-003 / CA2).

.DESCRIPTION
  Deterministic checks only — no LLM. Exit 0 when the PRD has at least one
  REQ-NNN, one acceptance criterion heading (CAn), and required structural
  sections (Execution policy, acceptance, requirements, OOS). Exit 1 otherwise.

.PARAMETER Path
  Absolute or relative path to a PRD .md file.

.EXAMPLE
  .\scripts\validation\validate-prd.ps1 -Path features\005-x\US01\PRD\005_x.md
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
    Write-Host ("validate-prd: FAIL - {0}" -f $Message) -ForegroundColor Red
}

function Write-ValidatePass {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-prd: PASS - {0}" -f $Message) -ForegroundColor Green
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

$reqPattern = $script:ToolkitConstant.SddArtifactReqIdPattern
$acPattern = $script:ToolkitConstant.SddArtifactAcceptancePattern

$reqMatches = [regex]::Matches($text, $reqPattern)
$reqIds = @(
    $reqMatches |
        ForEach-Object { ('REQ-{0}' -f $_.Groups[1].Value.ToUpperInvariant()) } |
        Select-Object -Unique
)

$acMatches = [regex]::Matches($text, $acPattern)

$sectionChecks = @(
    @{ Label = 'Execution policy section'; Pattern = $script:ToolkitConstant.SddArtifactPrdExecutionPolicyPattern },
    @{ Label = 'Acceptance criteria section (## 2.)'; Pattern = $script:ToolkitConstant.SddArtifactPrdAcceptanceSectionPattern },
    @{ Label = 'Requirements section (## 4. REQ-IDs)'; Pattern = $script:ToolkitConstant.SddArtifactPrdRequirementsSectionPattern },
    @{ Label = 'Out-of-scope section (## 5. OOS)'; Pattern = $script:ToolkitConstant.SddArtifactPrdOosSectionPattern }
)

$failures = [System.Collections.Generic.List[string]]::new()
if ($reqIds.Count -lt 1) {
    $failures.Add('missing REQ-NNN identifiers (expected at least one REQ-001 style id)')
}
if ($acMatches.Count -lt 1) {
    $failures.Add('missing acceptance criteria headings (expected ### CAn / ## CAn)')
}
foreach ($sectionCheck in $sectionChecks) {
    if ($text -notmatch $sectionCheck.Pattern) {
        $failures.Add(('missing required section: {0}' -f $sectionCheck.Label))
    }
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-ValidateFail -Message $f
    }
    exit 1
}

Write-ValidatePass -Message ("{0} REQ id(s), {1} CA heading(s)" -f $reqIds.Count, $acMatches.Count)
exit 0
