#Requires -Version 5.1
<##
.SYNOPSIS
  Regression assertion that evidence cannot escape through a descendant junction.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('validate-evidence-reparse-' + [guid]::NewGuid().ToString('N'))
$storyRoot = Join-Path $fixtureRoot 'features\000-fixture-evidence\TS01'
$externalRoot = Join-Path $fixtureRoot 'external-target'
$evdRoot = Join-Path $storyRoot 'EVD'
$junctionPath = Join-Path $evdRoot 'external'
$statePath = Join-Path $storyRoot 'STATE.md'
$validatorPath = Join-Path $PSScriptRoot '..\..\..\..\validate-evidence.ps1'

try {
    New-Item -ItemType Directory -Path $evdRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $externalRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $externalRoot 'escape.md') -Value 'outside-fixture' -Encoding UTF8
    Set-Content -LiteralPath $statePath -Value @'
# STATE

## AC evidence matrix
| AC | Evidence | Result |
| --- | --- | --- |
| AC1 | EVD/external/escape.md | pass |
'@ -Encoding UTF8
    New-Item -ItemType Junction -Path $junctionPath -Target $externalRoot | Out-Null

    & $validatorPath -StoryRoot $storyRoot -RepoPath $fixtureRoot -Level cheap *> $null
    if ($LASTEXITCODE -eq 0) {
        throw 'validator accepted evidence through a descendant junction'
    }

    Write-Host 'Assert-ReparseEscape: PASS'
    exit 0
}
finally {
    if (Test-Path -LiteralPath $junctionPath) {
        Remove-Item -LiteralPath $junctionPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
