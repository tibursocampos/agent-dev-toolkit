#Requires -Version 5.1
# Tests:
#   Should_Fail_When_OrchestrateCitesTaskWithoutFallback
#   Should_MentionSpawnAndFallback_When_OrchestrateCitesTask
#   Should_DegradeMultiAngle_When_SubagentsNotNative
#   Should_PassValidateCore_When_SpawnContractsHold
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

function Test-BodyMeetsTaskSpawnFallbackContract {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Body,
        [Parameter(Mandatory = $true)][string] $TaskMarker,
        [Parameter(Mandatory = $true)][string] $SpawnMarker,
        [Parameter(Mandatory = $true)][string] $FallbackMarker
    )
    if ($Body.IndexOf($TaskMarker, [System.StringComparison]::Ordinal) -lt 0) {
        return $true
    }

    $hasSpawn = $Body.IndexOf($SpawnMarker, [System.StringComparison]::Ordinal) -ge 0
    $hasFallback = $Body.IndexOf($FallbackMarker, [System.StringComparison]::Ordinal) -ge 0
    return ($hasSpawn -and $hasFallback)
}

function Get-OrchestrateSkillBodies {
    param(
        [Parameter(Mandatory = $true)][string] $SkillsRoot,
        [Parameter(Mandatory = $true)][string] $NamePrefix,
        [Parameter(Mandatory = $true)][string] $SkillFileName,
        [Parameter(Mandatory = $true)][string] $ReferenceFileName
    )
    $bodies = [System.Collections.Generic.List[object]]::new()
    if (-not (Test-Path -LiteralPath $SkillsRoot)) {
        return $bodies.ToArray()
    }

    $dirs = @(Get-ChildItem -LiteralPath $SkillsRoot -Directory | Where-Object { $_.Name.StartsWith($NamePrefix, [System.StringComparison]::Ordinal) })
    foreach ($dir in $dirs) {
        $skillPath = Join-Path $dir.FullName $SkillFileName
        if (-not (Test-Path -LiteralPath $skillPath)) {
            continue
        }

        $parts = [System.Collections.Generic.List[string]]::new()
        $parts.Add((Get-Content -LiteralPath $skillPath -Raw))
        $referencePath = Join-Path $dir.FullName $ReferenceFileName
        if (Test-Path -LiteralPath $referencePath) {
            $parts.Add((Get-Content -LiteralPath $referencePath -Raw))
        }

        $bodies.Add([pscustomobject]@{
                SkillName = $dir.Name
                Body      = ($parts -join "`n")
            })
    }

    return $bodies.ToArray()
}

function Get-OrchestrateSkillsMissingSpawnFallback {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $SkillBodies,
        [Parameter(Mandatory = $true)][string] $TaskMarker,
        [Parameter(Mandatory = $true)][string] $SpawnMarker,
        [Parameter(Mandatory = $true)][string] $FallbackMarker
    )
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $SkillBodies) {
        if (-not (Test-BodyMeetsTaskSpawnFallbackContract -Body ([string]$item.Body) -TaskMarker $TaskMarker -SpawnMarker $SpawnMarker -FallbackMarker $FallbackMarker)) {
            $missing.Add([string]$item.SkillName)
        }
    }
    return $missing.ToArray()
}

function Test-CodeReviewMultiAngleSpawnFallback {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Body,
        [Parameter(Mandatory = $true)][string] $SpawnMarker,
        [Parameter(Mandatory = $true)][string] $FallbackMarker,
        [Parameter(Mandatory = $true)][string] $InParentMarker
    )
    $hasSpawn = $Body.IndexOf($SpawnMarker, [System.StringComparison]::Ordinal) -ge 0
    $hasFallback = $Body.IndexOf($FallbackMarker, [System.StringComparison]::Ordinal) -ge 0
    $hasInParent = $Body.IndexOf($InParentMarker, [System.StringComparison]::Ordinal) -ge 0
    return ($hasSpawn -and $hasFallback -and $hasInParent)
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-OrchestrateSpawnFallbackPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-OrchestrateSpawnFallbackPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$taskMarker = $script:ToolkitConstant.SpawnTaskCitationMarker
$spawnMarker = $script:ToolkitConstant.SpawnContractMarker
$fallbackMarker = $script:ToolkitConstant.SpawnFallbackMarker
$inParentMarker = $script:ToolkitConstant.SpawnInParentMarker
$skillsRoot = Join-Path $repoRoot ((Join-Path $script:ToolkitConstant.CoreSkillsDirectoryName $script:ToolkitConstant.SkillsDirectoryName) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$namePrefix = $script:ToolkitConstant.OrchestrateSkillNamePrefix
$skillFileName = $script:ToolkitConstant.OrchestrateSkillFileName
$referenceFileName = $script:ToolkitConstant.OrchestrateReferenceFileName
$codeReviewDirName = $script:ToolkitConstant.CodeReviewSkillDirectoryName

# --- Should_Fail_When_OrchestrateCitesTaskWithoutFallback ---
$failName = 'Should_Fail_When_OrchestrateCitesTaskWithoutFallback'
$syntheticBad = "Spawn a $taskMarker child when ready."
if (Test-BodyMeetsTaskSpawnFallbackContract -Body $syntheticBad -TaskMarker $taskMarker -SpawnMarker $spawnMarker -FallbackMarker $fallbackMarker) {
    Write-Fail -TestName $failName -Reason $script:ToolkitMessage.OrchestrateTaskWithoutFallbackExpectedFail
}

Write-Pass -TestName $failName

# --- Should_MentionSpawnAndFallback_When_OrchestrateCitesTask ---
$mentionName = 'Should_MentionSpawnAndFallback_When_OrchestrateCitesTask'
if (-not (Test-Path -LiteralPath $skillsRoot)) {
    Write-Fail -TestName $mentionName -Reason $script:ToolkitMessage.OrchestrateSkillsDirMissing
}

$skillBodies = @(Get-OrchestrateSkillBodies -SkillsRoot $skillsRoot -NamePrefix $namePrefix -SkillFileName $skillFileName -ReferenceFileName $referenceFileName)
$missingSpawnFallback = @(Get-OrchestrateSkillsMissingSpawnFallback -SkillBodies $skillBodies -TaskMarker $taskMarker -SpawnMarker $spawnMarker -FallbackMarker $fallbackMarker)
if ($missingSpawnFallback.Count -gt 0) {
    Write-Fail -TestName $mentionName -Reason ($script:ToolkitMessage.OrchestrateTaskWithoutSpawnFallback -f ($missingSpawnFallback -join ', '))
}

Write-Pass -TestName $mentionName

# --- Should_DegradeMultiAngle_When_SubagentsNotNative ---
$multiAngleName = 'Should_DegradeMultiAngle_When_SubagentsNotNative'
$codeReviewSkillPath = Join-Path $skillsRoot ((Join-Path $codeReviewDirName $skillFileName) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $codeReviewSkillPath)) {
    Write-Fail -TestName $multiAngleName -Reason ($script:ToolkitMessage.CodeReviewSkillMissing -f $codeReviewSkillPath)
}

$codeReviewBody = Get-Content -LiteralPath $codeReviewSkillPath -Raw
$codeReviewRefPath = Join-Path $skillsRoot ((Join-Path $codeReviewDirName $referenceFileName) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $codeReviewRefPath) {
    $codeReviewBody = $codeReviewBody + "`n" + (Get-Content -LiteralPath $codeReviewRefPath -Raw)
}

if (-not (Test-CodeReviewMultiAngleSpawnFallback -Body $codeReviewBody -SpawnMarker $spawnMarker -FallbackMarker $fallbackMarker -InParentMarker $inParentMarker)) {
    Write-Fail -TestName $multiAngleName -Reason $script:ToolkitMessage.CodeReviewMissingSpawnFallback
}

Write-Pass -TestName $multiAngleName

# --- Should_PassValidateCore_When_SpawnContractsHold ---
$passValidateName = 'Should_PassValidateCore_When_SpawnContractsHold'
if ($skillBodies.Count -eq 0) {
    Write-Fail -TestName $passValidateName -Reason $script:ToolkitMessage.OrchestrateSkillsDirMissing
}

Write-Pass -TestName $passValidateName

Write-Host 'Assert-OrchestrateSpawnFallback: ALL PASS'
exit 0
