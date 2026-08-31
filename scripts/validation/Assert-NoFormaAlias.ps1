#Requires -Version 5.1
# Tests:
#   Should_Fail_When_SyntheticFormaAliasPresent
#   Should_Pass_When_ScopeHasNoFormaAliases
#
# Work-track rename (Frente 0): canonical docs must not retain Forma A/B/C aliases.
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

function Get-NoFormaAliasHits {
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

function Get-NoFormaAliasScanTargets {
    param([Parameter(Mandatory = $true)][string] $RepoRoot)

    $targets = [System.Collections.Generic.List[string]]::new()
    foreach ($dirName in @('core', 'docs', 'docs-site', 'memory-bank')) {
        $dirPath = Join-Path $RepoRoot $dirName
        if (-not (Test-Path -LiteralPath $dirPath)) {
            continue
        }
        Get-ChildItem -LiteralPath $dirPath -Recurse -File -Include '*.md', '*.mdc' | ForEach-Object {
            $targets.Add($_.FullName)
        }
    }

    foreach ($rootName in @('README.md', 'PRODUCT.md')) {
        $rootPath = Join-Path $RepoRoot $rootName
        if (Test-Path -LiteralPath $rootPath) {
            $targets.Add($rootPath)
        }
    }

    return $targets.ToArray()
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-NoFormaAliasPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-NoFormaAliasPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$forbiddenPatterns = @(
    $script:ToolkitConstant.NoFormaAliasFormaLetterPattern,
    $script:ToolkitConstant.NoFormaAliasFormerlyPattern,
    $script:ToolkitConstant.NoFormaAliasFormerlyTrackAliasPattern,
    $script:ToolkitConstant.NoFormaAliasWorkflowsHeadingPattern,
    $script:ToolkitConstant.NoFormaAliasSlashPattern,
    $script:ToolkitConstant.NoFormaAliasPipePattern
)

# --- Should_Fail_When_SyntheticFormaAliasPresent ---
$negativeName = 'Should_Fail_When_SyntheticFormaAliasPresent'
$syntheticBody = $script:ToolkitConstant.NoFormaAliasSyntheticForbiddenSample
$syntheticHits = @(Get-NoFormaAliasHits -Text $syntheticBody -Patterns $forbiddenPatterns)
if ($syntheticHits.Count -eq 0) {
    Write-Fail -TestName $negativeName -Reason $script:ToolkitMessage.NoFormaAliasNegativeExpectedFail
}

Write-Pass -TestName $negativeName

# --- Should_Pass_When_ScopeHasNoFormaAliases ---
$passName = 'Should_Pass_When_ScopeHasNoFormaAliases'
$scanTargets = @(Get-NoFormaAliasScanTargets -RepoRoot $repoRoot)
if ($scanTargets.Count -eq 0) {
    Write-Fail -TestName $passName -Reason $script:ToolkitMessage.NoFormaAliasNoScanTargets
}

$violations = [System.Collections.Generic.List[string]]::new()
foreach ($path in $scanTargets) {
    $text = Get-Content -LiteralPath $path -Raw
    $hits = @(Get-NoFormaAliasHits -Text $text -Patterns $forbiddenPatterns)
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
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.NoFormaAliasViolations -f ($violations.ToArray() -join '; '))
}

Write-Pass -TestName $passName
Write-Host 'Assert-NoFormaAlias: ALL PASS'
exit 0
