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
$preferencesInitializer = Join-Path $libDir 'Initialize-SddPreferences.ps1'
$rootLayoutInitializer = Join-Path $libDir 'Initialize-SddRootLayout.ps1'
if (-not (Test-Path -LiteralPath $preferencesInitializer) -or -not (Test-Path -LiteralPath $rootLayoutInitializer)) {
    Write-Fail -TestName 'Assert-PreferencesSchemaPreconditions' -Reason 'preference initializer dependencies are missing'
}
. $rootLayoutInitializer
. $preferencesInitializer
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
$storageDoc = Get-Content -LiteralPath (Join-Path $repoRoot 'core\sdd\STORAGE-RESOLUTION.md') -Raw -Encoding UTF8
$cavemanPolicy = Get-Content -LiteralPath (Join-Path $repoRoot 'core\policy\caveman-mode.md') -Raw -Encoding UTF8
if ($storageDoc -notmatch '"caveman_mode": true' -or $cavemanPolicy -notmatch 'caveman_mode": true') {
    Write-Fail -TestName 'Should_DocumentCavemanOnAsDefault' -Reason 'storage and Caveman policy must document the on default'
}
Write-Pass -TestName 'Should_DocumentCavemanOnAsDefault'

$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-preferences-' + [Guid]::NewGuid().ToString('N'))
$script:PreferenceTestAnswers = [System.Collections.Queue]::new()
$script:PreferenceTestPromptCount = 0
function Read-Host {
    param([string] $Prompt)
    $script:PreferenceTestPromptCount++
    if ($script:PreferenceTestAnswers.Count -gt 0) { return [string]$script:PreferenceTestAnswers.Dequeue() }
    return ''
}
function Set-PreferenceTestAnswers {
    param([string[]] $Answers)
    $script:PreferenceTestAnswers.Clear()
    foreach ($answer in $Answers) { $script:PreferenceTestAnswers.Enqueue($answer) }
    $script:PreferenceTestPromptCount = 0
}

try {
    $interactiveRoot = Join-Path $fixtureRoot 'interactive'
    Set-PreferenceTestAnswers -Answers @('2', '2')
    $interactiveOutput = Invoke-ToolkitEnsurePreferences -SddRoot $interactiveRoot -Interactive *>&1 | Out-String
    $interactivePath = Join-Path $interactiveRoot 'preferences.json'
    $interactivePreferences = Get-Content -LiteralPath $interactivePath -Raw | ConvertFrom-Json
    if ($interactivePreferences.orchestrator_mode -ne 'adaptive' -or $interactivePreferences.caveman_mode -ne $false -or $script:PreferenceTestPromptCount -ne 2) {
        Write-Fail -TestName 'Should_PersistInteractivePreferenceChoices' -Reason 'interactive first sync must ask twice and persist adaptive / Caveman off'
    }
    if ($interactiveOutput -notmatch 'disables response compression' -or $interactiveOutput -notmatch 'recommended' -or $interactiveOutput -notmatch 'Adaptive' -or $interactiveOutput -notmatch 'Always orchestrate' -or $interactiveOutput -notmatch 'On \(recommended default\)') {
        Write-Fail -TestName 'Should_ExplainCavemanInstallChoice' -Reason 'interactive flow must display both choices, recommend Caveman on, and explain that off disables response compression'
    }
    Write-Pass -TestName 'Should_PersistInteractivePreferenceChoices'
    Write-Pass -TestName 'Should_ExplainCavemanInstallChoice'

    $nonInteractiveRoot = Join-Path $fixtureRoot 'non-interactive'
    Set-PreferenceTestAnswers -Answers @()
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $nonInteractiveRoot
    $nonInteractivePreferences = Get-Content -LiteralPath (Join-Path $nonInteractiveRoot 'preferences.json') -Raw | ConvertFrom-Json
    if ($nonInteractivePreferences.orchestrator_mode -ne 'always' -or $nonInteractivePreferences.caveman_mode -ne $true -or $script:PreferenceTestPromptCount -ne 0) {
        Write-Fail -TestName 'Should_UseDefaults_When_NonInteractiveFirstSync' -Reason 'non-interactive first sync must default to always / Caveman on without prompting'
    }
    Write-Pass -TestName 'Should_UseDefaults_When_NonInteractiveFirstSync'

    $interactiveDefaultRoot = Join-Path $fixtureRoot 'interactive-defaults'
    Set-PreferenceTestAnswers -Answers @('', '')
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $interactiveDefaultRoot -Interactive
    $interactiveDefaults = Get-Content -LiteralPath (Join-Path $interactiveDefaultRoot 'preferences.json') -Raw | ConvertFrom-Json
    if ($interactiveDefaults.orchestrator_mode -ne 'always' -or $interactiveDefaults.caveman_mode -ne $true -or $script:PreferenceTestPromptCount -ne 2) {
        Write-Fail -TestName 'Should_UseRecommendedChoices_When_InteractiveInputIsBlank' -Reason 'blank interactive choices must select always / Caveman on'
    }
    Write-Pass -TestName 'Should_UseRecommendedChoices_When_InteractiveInputIsBlank'

    $existingRoot = Join-Path $fixtureRoot 'existing'
    $null = New-Item -ItemType Directory -Path $existingRoot -Force
    $existingPath = Join-Path $existingRoot 'preferences.json'
    $existingJson = '{"caveman_mode":false,"caveman_level":"lite","orchestrator_mode":"adaptive","artifact_language":"pt-BR","verify_mode":true}'
    [System.IO.File]::WriteAllText($existingPath, $existingJson, (New-Object System.Text.UTF8Encoding $false))
    Set-PreferenceTestAnswers -Answers @()
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $existingRoot -Interactive
    $afterExisting = Get-Content -LiteralPath $existingPath -Raw
    if ($afterExisting -ne $existingJson -or $script:PreferenceTestPromptCount -ne 0) {
        Write-Fail -TestName 'Should_PreserveExistingPreferences' -Reason 'existing preferences, including explicit Caveman false, must remain byte-for-byte unchanged'
    }
    Write-Pass -TestName 'Should_PreserveExistingPreferences'

    $whatIfRoot = Join-Path $fixtureRoot 'what-if'
    Set-PreferenceTestAnswers -Answers @()
    $null = Invoke-ToolkitEnsurePreferences -SddRoot $whatIfRoot -Interactive -WhatIf
    if ((Test-Path -LiteralPath $whatIfRoot) -or $script:PreferenceTestPromptCount -ne 0) {
        Write-Fail -TestName 'Should_NotPromptOrWrite_When_WhatIf' -Reason 'WhatIf must not prompt or create the root/preferences file'
    }
    Write-Pass -TestName 'Should_NotPromptOrWrite_When_WhatIf'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

$modelCostPath = Join-Path $repoRoot 'core\policy\model-cost-awareness.md'
$modelCostText = Get-Content -LiteralPath $modelCostPath -Raw -Encoding UTF8
if ($modelCostText -match '(?i)alwaysApply:\s*true|COST NOTICE|high-cost model') {
    Write-Fail -TestName 'Should_RetireModelCostPolicy' -Reason 'model cost policy must not be always-on or emit cost guidance'
}
Write-Pass -TestName 'Should_RetireModelCostPolicy'

Write-Pass -TestName $testName
Write-Host 'Assert-PreferencesSchema: ALL PASS'
exit 0
