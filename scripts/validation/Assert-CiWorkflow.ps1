#Requires -Version 5.1
# Tests:
#   Should_DocumentCiWorkflowContract_When_WorkflowPresent
#   Should_DocumentCiSmokePaths_When_DocsPresent
#
# Static contract for .github/workflows/validate-toolkit.yml.
# Does NOT re-invoke validate-core (this assert is part of the validate-core suite).
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
$constantsScript = Join-Path $libDir 'ToolkitConstants.ps1'
$repoRootScript = Join-Path $libDir 'Get-ToolkitRepoRoot.ps1'

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

foreach ($required in @($constantsScript, $repoRootScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Fail -TestName 'Assert-CiWorkflowPreconditions' -Reason ("missing {0}" -f $required)
    }
}

. $constantsScript
. $repoRootScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$workflowRel = $script:ToolkitConstant.CiWorkflowRelativePath
$validateCoreRel = $script:ToolkitConstant.ValidateCoreRelativePath
$workflowPath = Join-Path $repoRoot ($workflowRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$validateCorePath = Join-Path $repoRoot ($validateCoreRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$allowUserHomeForwardAssertName = $script:ToolkitConstant.AssertSyncAllowUserHomeForwardScriptName
$keyedUninstallCiAsserts = @($script:ToolkitConstant.KeyedUninstallCiAsserts)

if (-not (Test-Path -LiteralPath $workflowPath)) {
    Write-Fail -TestName 'Assert-CiWorkflowPreconditions' -Reason ("missing workflow: {0}" -f $workflowRel)
}

if (-not (Test-Path -LiteralPath $validateCorePath)) {
    Write-Fail -TestName 'Assert-CiWorkflowPreconditions' -Reason ("missing validate-core: {0}" -f $validateCoreRel)
}

# --- Should_DocumentCiWorkflowContract_When_WorkflowPresent ---
$ciName = 'Should_DocumentCiWorkflowContract_When_WorkflowPresent'
$workflowText = Get-Content -LiteralPath $workflowPath -Raw
$validateCoreText = Get-Content -LiteralPath $validateCorePath -Raw

$requiredWorkflowMarkers = @(
    'validate-core.ps1',
    'actions/checkout',
    'pwsh',
    'permissions:',
    'contents: read',
    $allowUserHomeForwardAssertName
)

foreach ($marker in $requiredWorkflowMarkers) {
    if ($workflowText -notlike ("*{0}*" -f $marker)) {
        Write-Fail -TestName $ciName -Reason ("workflow missing marker '{0}'" -f $marker)
    }
}

foreach ($keyedAssert in $keyedUninstallCiAsserts) {
    if ($workflowText -notlike ("*{0}*" -f $keyedAssert.ScriptName)) {
        Write-Fail -TestName $ciName -Reason ("workflow missing keyed uninstall assert '{0}'" -f $keyedAssert.ScriptName)
    }
}

# Keyed uninstall must stay out of validate-core (nest validate-agent → validate-core recursion).
if ($validateCoreText -like '*KeyedUninstallCiAsserts*' -or $validateCoreText -like '*KeyedUninstallCoreAsserts*') {
    Write-Fail -TestName $ciName -Reason 'validate-core must not wire keyed uninstall asserts (recursion via validate-agent)'
}

$forbiddenWorkflowMarkers = @(
    'sync-cursor.ps1',
    'secrets.',
    'pull_request_target'
)

foreach ($marker in $forbiddenWorkflowMarkers) {
    if ($workflowText -like ("*{0}*" -f $marker)) {
        Write-Fail -TestName $ciName -Reason ("workflow must not contain '{0}'" -f $marker)
    }
}

# Allow dedicated Assert-SyncAllowUserHomeForward step/comments; block generic live-home sync/validate with -AllowUserHome.
if ($workflowText -match '(?im)(?:sync-agent|validate-agent)\.ps1[^\r\n]*AllowUserHome') {
    Write-Fail -TestName $ciName -Reason 'workflow must not pass -AllowUserHome to sync-agent/validate-agent (use Assert-SyncAllowUserHomeForward probe only)'
}

Write-Pass -TestName $ciName

# --- Should_DocumentCiSmokePaths_When_DocsPresent ---
$docsName = 'Should_DocumentCiSmokePaths_When_DocsPresent'

$validationDocRel = 'docs/VALIDATION.md'
$validationDocPath = Join-Path $repoRoot ($validationDocRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $validationDocPath)) {
    Write-Fail -TestName $docsName -Reason ("missing doc: {0}" -f $validationDocRel)
}

$validationText = Get-Content -LiteralPath $validationDocPath -Raw
$validationMarkers = @(
    'validate-core',
    'Invoke-CursorCiSmoke',
    'validate-toolkit.yml'
)
foreach ($marker in $validationMarkers) {
    if ($validationText -notlike ("*{0}*" -f $marker)) {
        Write-Fail -TestName $docsName -Reason ("{0} missing marker '{1}'" -f $validationDocRel, $marker)
    }
}

$readmePath = Join-Path $repoRoot $script:ToolkitConstant.ReadmeFileName
$readmeText = Get-Content -LiteralPath $readmePath -Raw
$readmeMarkers = @(
    'validate-core',
    'Invoke-CursorCiSmoke',
    'docs/VALIDATION.md',
    'docs/ADAPTERS.md'
)
foreach ($marker in $readmeMarkers) {
    if ($readmeText -notlike ("*{0}*" -f $marker)) {
        Write-Fail -TestName $docsName -Reason ("README missing marker '{0}'" -f $marker)
    }
}

Write-Pass -TestName $docsName

Write-Host 'Assert-CiWorkflow: ALL PASS'
exit 0
