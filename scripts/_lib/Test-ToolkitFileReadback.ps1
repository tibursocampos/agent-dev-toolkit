#Requires -Version 5.1
<#
.SYNOPSIS
  Shared readback comparison for owner-side writes of small UTF-8 (no BOM) text files.

.DESCRIPTION
  Returns $true only when the file exists as a leaf and its UTF-8 text equals the
  expected text exactly (ordinal, case-sensitive, no BOM stripping). Used by the
  develop-session gate, the PLAN ledger claim and the step-state writer after a
  write, so all fail closed on a missing or divergent file in the same way.

.PARAMETER Path
  File that was just written.

.PARAMETER ExpectedText
  Exact text the file must contain.
#>
function Test-ToolkitFileReadback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $ExpectedText
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    $encoding = New-Object System.Text.UTF8Encoding $false
    $actual = $encoding.GetString([System.IO.File]::ReadAllBytes($Path))
    return [string]::Equals($actual, $ExpectedText, [System.StringComparison]::Ordinal)
}
