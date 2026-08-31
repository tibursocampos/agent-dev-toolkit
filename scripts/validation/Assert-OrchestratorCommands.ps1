#Requires -Version 5.1
# Tests:
#   Should_Pass_When_OrchestratorCommandsDocumented
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

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-OrchestratorCommandsPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-OrchestratorCommandsPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$testName = 'Should_Pass_When_OrchestratorCommandsDocumented'
$rel = $script:ToolkitConstant.OrchestratorSessionPolicyRelativePath
$full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $full)) {
    Write-Fail -TestName $testName -Reason ("missing {0}" -f $rel)
}

$text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
$required = @($script:ToolkitConstant.OrchestratorCommandMarkers)
foreach ($marker in $required) {
    if ($text -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName $testName -Reason ("orchestrator-session missing: {0}" -f $marker)
    }
}

Write-Pass -TestName $testName
Write-Host 'Assert-OrchestratorCommands: ALL PASS'
exit 0
