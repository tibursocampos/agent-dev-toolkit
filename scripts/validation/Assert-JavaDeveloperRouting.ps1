#Requires -Version 5.1
# Tests:
#   Should_FailValidateCore_When_JavaDeveloperMissingFromDisk
#   Should_FailValidateCore_When_JavaMissingFromCatalogOrRoutes
#   Should_PassValidateCore_When_JavaPresentAndRouted
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

function Test-JavaDeveloperSkillOnDisk {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativeSkillPath
    )
    $candidate = Join-Path $RepoRoot ($RelativeSkillPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $candidate)) {
        return $false
    }
    $item = Get-Item -LiteralPath $candidate
    return ($item.Length -gt 0)
}

function Get-JavaRoutingSurfaceGaps {
    param(
        [Parameter(Mandatory = $true)][hashtable] $SurfaceTexts,
        [Parameter(Mandatory = $true)][string] $CatalogToken,
        [Parameter(Mandatory = $true)][string] $RouteToken,
        [Parameter(Mandatory = $true)][string] $MavenPomFileName,
        [Parameter(Mandatory = $true)][string] $GradleBuildFileName
    )
    $gaps = [System.Collections.Generic.List[string]]::new()
    foreach ($name in @($SurfaceTexts.Keys | Sort-Object)) {
        $body = [string]$SurfaceTexts[$name]
        if ($body.IndexOf($CatalogToken, [System.StringComparison]::Ordinal) -lt 0) {
            $gap = '{0}:missing-token:{1}' -f $name, $CatalogToken
            $gaps.Add($gap)
        }
    }

    $routingBody = [string]$SurfaceTexts['routing']
    if ($routingBody.IndexOf($RouteToken, [System.StringComparison]::Ordinal) -lt 0) {
        $gap = 'routing:missing-route:{0}' -f $RouteToken
        $gaps.Add($gap)
    }

    $developerBody = [string]$SurfaceTexts['developer']
    if ($developerBody.IndexOf($MavenPomFileName, [System.StringComparison]::Ordinal) -lt 0) {
        $gap = 'developer:missing-signal:{0}' -f $MavenPomFileName
        $gaps.Add($gap)
    }
    if ($developerBody.IndexOf($GradleBuildFileName, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $gap = 'developer:missing-signal:{0}' -f $GradleBuildFileName
        $gaps.Add($gap)
    }

    return $gaps.ToArray()
}

function Read-RequiredSurfaceText {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [Parameter(Mandatory = $true)][string] $TestName
    )
    $fullPath = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Write-Fail -TestName $TestName -Reason ($script:ToolkitMessage.JavaRoutingSurfaceMissing -f $RelativePath)
    }
    return (Get-Content -LiteralPath $fullPath -Raw)
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-JavaDeveloperRoutingPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-JavaDeveloperRoutingPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$skillDirName = $script:ToolkitConstant.JavaDeveloperSkillDirectoryName
$skillFileName = $script:ToolkitConstant.JavaDeveloperSkillFileName
$catalogToken = $script:ToolkitConstant.JavaDeveloperCatalogToken
$routeToken = $script:ToolkitConstant.JavaDeveloperRouteToken
$mavenPom = $script:ToolkitConstant.JavaMavenPomFileName
$gradleBuild = $script:ToolkitConstant.JavaGradleBuildFileName
$inventedMissingRel = $script:ToolkitConstant.InventedMissingJavaSkillRel
$javaSkillRel = ('{0}/{1}/{2}/{3}' -f $script:ToolkitConstant.CoreSkillsDirectoryName, $script:ToolkitConstant.SkillsDirectoryName, $skillDirName, $skillFileName)

# --- Should_FailValidateCore_When_JavaDeveloperMissingFromDisk ---
$failDiskName = 'Should_FailValidateCore_When_JavaDeveloperMissingFromDisk'
if (Test-JavaDeveloperSkillOnDisk -RepoRoot $repoRoot -RelativeSkillPath $inventedMissingRel) {
    Write-Fail -TestName $failDiskName -Reason ($script:ToolkitMessage.JavaDeveloperMissingFromDiskExpectedFail -f $inventedMissingRel)
}

Write-Pass -TestName $failDiskName

# --- Should_FailValidateCore_When_JavaMissingFromCatalogOrRoutes ---
$failCatalogName = 'Should_FailValidateCore_When_JavaMissingFromCatalogOrRoutes'
$syntheticSurfaces = @{
    routing   = 'Python | /python-developer'
    developer = 'Detect .csproj and package.json only'
    catalog   = 'dotnet-developer and python-developer'
    agents    = 'Stack developers without JVM specialist'
}
$syntheticGaps = @(Get-JavaRoutingSurfaceGaps -SurfaceTexts $syntheticSurfaces -CatalogToken $catalogToken -RouteToken $routeToken -MavenPomFileName $mavenPom -GradleBuildFileName $gradleBuild)
if ($syntheticGaps.Count -eq 0) {
    Write-Fail -TestName $failCatalogName -Reason $script:ToolkitMessage.JavaMissingFromCatalogOrRoutesExpectedFail
}

Write-Pass -TestName $failCatalogName

# --- Should_PassValidateCore_When_JavaPresentAndRouted ---
$passName = 'Should_PassValidateCore_When_JavaPresentAndRouted'
if (-not (Test-JavaDeveloperSkillOnDisk -RepoRoot $repoRoot -RelativeSkillPath $javaSkillRel)) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.JavaDeveloperMissingFromDisk -f $javaSkillRel)
}

$surfaceTexts = @{
    routing   = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.RoutingMdRelativePath -TestName $passName)
    developer = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.DeveloperSkillRelativePath -TestName $passName)
    catalog   = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.SkillsCatalogRelativePath -TestName $passName)
    agents    = (Read-RequiredSurfaceText -RepoRoot $repoRoot -RelativePath $script:ToolkitConstant.RouterAgentsRelativePath -TestName $passName)
}

$realGaps = @(Get-JavaRoutingSurfaceGaps -SurfaceTexts $surfaceTexts -CatalogToken $catalogToken -RouteToken $routeToken -MavenPomFileName $mavenPom -GradleBuildFileName $gradleBuild)
if ($realGaps.Count -gt 0) {
    Write-Fail -TestName $passName -Reason ($script:ToolkitMessage.JavaMissingFromCatalogOrRoutes -f ($realGaps -join ', '))
}

Write-Pass -TestName $passName

Write-Host 'Assert-JavaDeveloperRouting: ALL PASS'
exit 0
