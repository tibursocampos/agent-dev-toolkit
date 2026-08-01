#Requires -Version 5.1
# Tests:
#   Should_UseCanonicalCloneUrl_When_EntrypointsRead
#   Should_NotContainClonePlaceholder_When_EntrypointsGreped
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'

$canonicalCloneUrl = 'https://github.com/tibursocampos/agent-dev-toolkit.git'
$clonePlaceholder = '<this-repo-url>'
$entrypointRels = @(
    'README.md',
    'docs/INSTALL.md',
    'docs/guides/01-getting-started.md'
)

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-CanonicalCloneUrlPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

# --- Should_UseCanonicalCloneUrl_When_EntrypointsRead ---
$urlName = 'Should_UseCanonicalCloneUrl_When_EntrypointsRead'
$missingUrl = @()
foreach ($rel in $entrypointRels) {
    $path = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Fail -TestName $urlName -Reason ("missing entrypoint: {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -notlike ("*{0}*" -f $canonicalCloneUrl)) {
        $missingUrl += $rel
    }
}

if ($missingUrl.Count -gt 0) {
    Write-Fail -TestName $urlName -Reason ("canonical clone URL missing in: {0}" -f ($missingUrl -join ', '))
}

Write-Pass -TestName $urlName

# --- Should_NotContainClonePlaceholder_When_EntrypointsGreped ---
$placeholderName = 'Should_NotContainClonePlaceholder_When_EntrypointsGreped'
$withPlaceholder = @()
foreach ($rel in $entrypointRels) {
    $path = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -like ("*{0}*" -f $clonePlaceholder)) {
        $withPlaceholder += $rel
    }
}

if ($withPlaceholder.Count -gt 0) {
    Write-Fail -TestName $placeholderName -Reason ("clone placeholder still present in: {0}" -f ($withPlaceholder -join ', '))
}

Write-Pass -TestName $placeholderName
exit 0
