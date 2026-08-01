#Requires -Version 5.1
# Tests:
#   Should_Fail_When_SyntheticFeaturesStoryPathPresent
#   Should_Pass_When_VersionedDocsAvoidFeaturesStoryArtifacts
#
# Published docs must not link to gitignored features/** story paths
# (broken on clone). Scan docs/, root README/CONTRIBUTING/SECURITY,
# and adapters/*/README.md only.
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

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

function Get-NoFeaturesDocLinkHits {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text,
        [Parameter(Mandatory = $true)][string[]] $Patterns
    )
    $hits = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($pattern in $Patterns) {
        foreach ($match in [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $value = $match.Value
            if ($seen.Add($value)) {
                $hits.Add($value)
            }
        }
    }
    return $hits.ToArray()
}

function Get-NoFeaturesDocLinkScanTargets {
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $targets = [System.Collections.Generic.List[string]]::new()
    $docsRoot = Join-Path $RepoRoot 'docs'
    if (Test-Path -LiteralPath $docsRoot) {
        Get-ChildItem -LiteralPath $docsRoot -Recurse -File -Filter '*.md' | ForEach-Object {
            $targets.Add($_.FullName)
        }
    }

    foreach ($rootName in @('README.md', 'CONTRIBUTING.md', 'SECURITY.md')) {
        $rootPath = Join-Path $RepoRoot $rootName
        if (Test-Path -LiteralPath $rootPath) {
            $targets.Add($rootPath)
        }
    }

    $adaptersRoot = Join-Path $RepoRoot 'adapters'
    if (Test-Path -LiteralPath $adaptersRoot) {
        Get-ChildItem -LiteralPath $adaptersRoot -Directory | ForEach-Object {
            $readme = Join-Path $_.FullName 'README.md'
            if (Test-Path -LiteralPath $readme) {
                $targets.Add($readme)
            }
        }
    }

    return $targets.ToArray()
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-NoFeaturesDocLinksPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-NoFeaturesDocLinksPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$forbiddenPatterns = @(
    $script:ToolkitConstant.NoFeaturesDocLinksSpawnMatrixPattern,
    $script:ToolkitConstant.NoFeaturesDocLinksFeatureFolderPattern
)

# --- Should_Fail_When_SyntheticFeaturesStoryPathPresent ---
$negativeName = 'Should_Fail_When_SyntheticFeaturesStoryPathPresent'
$syntheticBody = $script:ToolkitConstant.NoFeaturesDocLinksSyntheticForbiddenSample
$syntheticHits = @(Get-NoFeaturesDocLinkHits -Text $syntheticBody -Patterns $forbiddenPatterns)
if ($syntheticHits.Count -eq 0) {
    Write-Fail -TestName $negativeName -Reason $script:ToolkitMessage.NoFeaturesDocLinksNegativeExpectedFail
}

Write-Pass -TestName $negativeName

# --- Should_Pass_When_VersionedDocsAvoidFeaturesStoryArtifacts ---
$passName = 'Should_Pass_When_VersionedDocsAvoidFeaturesStoryArtifacts'
$scanTargets = @(Get-NoFeaturesDocLinkScanTargets -RepoRoot $repoRoot)
if ($scanTargets.Count -eq 0) {
    Write-Fail -TestName $passName -Reason $script:ToolkitMessage.NoFeaturesDocLinksNoScanTargets
}

$violations = [System.Collections.Generic.List[string]]::new()
foreach ($path in $scanTargets) {
    $text = Get-Content -LiteralPath $path -Raw
    $hits = @(Get-NoFeaturesDocLinkHits -Text $text -Patterns $forbiddenPatterns)
    if ($hits.Count -eq 0) {
        continue
    }

    $rel = $path
    if ($path.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $path.Substring($repoRoot.Length).TrimStart('\', '/')
    }
    $rel = $rel -replace '\\', '/'
    $violations.Add(('{0}: {1}' -f $rel, ($hits -join ', ')))
}

if ($violations.Count -gt 0) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.NoFeaturesDocLinksViolations -f ($violations.ToArray() -join '; '))
}

Write-Pass -TestName $passName
Write-Host 'Assert-NoFeaturesDocLinks: ALL PASS'
exit 0
