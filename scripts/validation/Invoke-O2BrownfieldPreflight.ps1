#Requires -Version 5.1
<#
.SYNOPSIS
  Deterministic O2 gate for brownfield analysis evidence.

.DESCRIPTION
  Runs the document-level brownfield analysis validator and reports an explicit
  ALLOW or BLOCK decision for the Orchestrated Delivery O2 sufficiency gate.
  It is read-only and never rewrites the analysis artifact.

.PARAMETER AnalysisPath
  Brownfield analysis Markdown document to validate.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $AnalysisPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$validatorPath = Join-Path $PSScriptRoot 'validate-brownfield-analysis.ps1'
if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    Write-Output ("o2-brownfield-preflight: BLOCK reason=validator_missing detail={0}" -f $validatorPath)
    exit 1
}

$validatorOutput = & $validatorPath -Path $AnalysisPath 2>&1 | Out-String
$validatorExitCode = $LASTEXITCODE
if ($null -eq $validatorExitCode) { $validatorExitCode = 0 }

if (-not [string]::IsNullOrWhiteSpace($validatorOutput)) {
    Write-Output $validatorOutput.TrimEnd()
}

if ([int]$validatorExitCode -ne 0) {
    Write-Output ("o2-brownfield-preflight: BLOCK reason=analysis_invalid path={0}" -f $AnalysisPath)
    exit 1
}

Write-Output ("o2-brownfield-preflight: ALLOW path={0}" -f $AnalysisPath)
exit 0
