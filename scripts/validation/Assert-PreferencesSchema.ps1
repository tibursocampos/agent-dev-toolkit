#Requires -Version 5.1
# Tests:
#   Should_Pass_When_PreferencesSchemaDocumented
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
    Write-Fail -TestName 'Assert-PreferencesSchemaPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}
if (-not (Test-Path -LiteralPath $constantsScript)) {
    Write-Fail -TestName 'Assert-PreferencesSchemaPreconditions' -Reason ("missing {0}" -f $constantsScript)
}

. $repoRootScript
. $constantsScript
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

$testName = 'Should_Pass_When_PreferencesSchemaDocumented'
$paths = @($script:ToolkitConstant.PreferencesSchemaDocRelativePaths)
$keys = @($script:ToolkitConstant.PreferencesSchemaKeyMarkers)

foreach ($rel in $paths) {
    $full = Join-Path $repoRoot ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Fail -TestName $testName -Reason ("missing {0}" -f $rel)
    }
    $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    foreach ($key in $keys) {
        if ($text -notmatch [regex]::Escape($key)) {
            Write-Fail -TestName $testName -Reason ("{0} missing preferences key: {1}" -f $rel, $key)
        }
    }
}

$modelCostPath = Join-Path $repoRoot 'core\policy\model-cost-awareness.md'
if (-not (Test-Path -LiteralPath $modelCostPath)) {
    Write-Fail -TestName 'Should_Pass_When_ModelCostPolicyDocumented' -Reason 'missing core/policy/model-cost-awareness.md'
}
$modelCostText = Get-Content -LiteralPath $modelCostPath -Raw -Encoding UTF8
foreach ($marker in @('first turn', 'Do **not** repeat', '**Never block** execution')) {
    if ($modelCostText -notmatch [regex]::Escape($marker)) {
        Write-Fail -TestName 'Should_Pass_When_ModelCostPolicyDocumented' -Reason ("model-cost-awareness.md missing marker: {0}" -f $marker)
    }
}
Write-Pass -TestName 'Should_Pass_When_ModelCostPolicyDocumented'

Write-Pass -TestName $testName
Write-Host 'Assert-PreferencesSchema: ALL PASS'
exit 0
