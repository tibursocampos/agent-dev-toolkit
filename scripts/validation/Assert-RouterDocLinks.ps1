#Requires -Version 5.1
# Tests:
#   Should_Pass_When_RouterLinksExist
#   Should_FailValidateCore_When_RouterPointsToMissingDocsPath
#   Should_NotReferenceMissingGuides10to12_When_RouterRead
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'

$forbiddenGuideRelatives = @(
    'docs/guides/10-forma-c-orquestracao.md',
    'docs/guides/11-forma-c-caso-nuget-extract.md',
    'docs/guides/12-forma-c-caso-mobile-app.md'
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

function Get-RouterPathLiterals {
    param(
        [Parameter(Mandatory = $true)][string] $RouterText,
        [Parameter(Mandatory = $true)][string] $Pattern
    )
    $found = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($match in [regex]::Matches($RouterText, $Pattern)) {
        $prefix = $match.Groups[1].Value
        $rest = $match.Groups[2].Value.Trim().TrimEnd(',', '.', ';', ')', ']')
        $rel = if ([string]::IsNullOrWhiteSpace($rest)) {
            '{0}/' -f $prefix
        }
        else {
            '{0}/{1}' -f $prefix, $rest
        }
        if ($seen.Add($rel)) {
            $found.Add($rel)
        }
    }
    return $found.ToArray()
}

function Test-RouterRelativePathExists {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )
    $normalized = $RelativePath.TrimEnd('/')
    $candidate = Join-Path $RepoRoot ($normalized -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ($RelativePath.EndsWith('/')) {
        return Test-Path -LiteralPath $candidate
    }
    return (Test-Path -LiteralPath $candidate)
}

function Get-MissingRouterTargets {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $RelativePaths
    )
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($rel in $RelativePaths) {
        if (-not (Test-RouterRelativePathExists -RepoRoot $RepoRoot -RelativePath $rel)) {
            $missing.Add($rel)
        }
    }
    return $missing.ToArray()
}

function Format-RouterDocLinkTe01 {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    return ($script:ToolkitMessage.RouterDocLinkDoesNotExist -f $RelativePath)
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-RouterDocLinksPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-RouterDocLinksPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$routerRelativePath = $script:ToolkitConstant.RouterAgentsRelativePath
$routerPath = Join-Path $repoRoot ($routerRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $routerPath)) {
    Write-Fail -TestName 'Assert-RouterDocLinksPreconditions' -Reason (Format-RouterDocLinkTe01 -RelativePath $routerRelativePath)
}

$routerText = Get-Content -LiteralPath $routerPath -Raw
$pathLiteralPattern = $script:ToolkitConstant.RouterPathLiteralPattern

# --- Should_FailValidateCore_When_RouterPointsToMissingDocsPath ---
$failName = 'Should_FailValidateCore_When_RouterPointsToMissingDocsPath'
$inventedRel = $script:ToolkitConstant.InventedMissingRouterDocRel
$inventedMissing = @(Get-MissingRouterTargets -RepoRoot $repoRoot -RelativePaths @($inventedRel))
if ($inventedMissing.Count -ne 1) {
    Write-Fail -TestName $failName -Reason ($script:ToolkitMessage.RouterDocLinksNegativeExpectedFail -f $inventedRel)
}

$te01Message = Format-RouterDocLinkTe01 -RelativePath $inventedRel
if ($te01Message -notlike ("*{0}*" -f $inventedRel) -or $te01Message -notlike '*does not exist under repo root*') {
    Write-Fail -TestName $failName -Reason ("TE01 message malformed: {0}" -f $te01Message)
}

Write-Pass -TestName $failName

# --- Should_Pass_When_RouterLinksExist ---
$passName = 'Should_Pass_When_RouterLinksExist'
$pathLiterals = @(Get-RouterPathLiterals -RouterText $routerText -Pattern $pathLiteralPattern)
if ($pathLiterals.Count -eq 0) {
    Write-Fail -TestName $passName -Reason $script:ToolkitMessage.RouterDocLinksNoLiterals
}

$missing = @(Get-MissingRouterTargets -RepoRoot $repoRoot -RelativePaths $pathLiterals)
if ($missing.Count -gt 0) {
    $details = @($missing | ForEach-Object { Format-RouterDocLinkTe01 -RelativePath ([string]$_) })
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.RouterDocLinksMissingTargets -f ($details -join ', '))
}

Write-Pass -TestName $passName

# --- Should_NotReferenceMissingGuides10to12_When_RouterRead ---
$guidesName = 'Should_NotReferenceMissingGuides10to12_When_RouterRead'
$stillReferenced = [System.Collections.Generic.List[string]]::new()
foreach ($forbidden in $forbiddenGuideRelatives) {
    if ($routerText -like ("*{0}*" -f $forbidden)) {
        $stillReferenced.Add($forbidden)
    }
}

if ($stillReferenced.Count -gt 0) {
    Write-Fail -TestName $guidesName -Reason ($script:ToolkitMessage.RouterDocLinksForbiddenGuides -f ($stillReferenced.ToArray() -join ', '))
}

Write-Pass -TestName $guidesName
exit 0
