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

function Get-WorkflowJobBlock {
    param(
        [Parameter(Mandatory = $true)][string] $WorkflowText,
        [Parameter(Mandatory = $true)][string] $JobName
    )

    $Lines = $WorkflowText -split "`r?`n"
    $jobPattern = '^  {0}:\s*$' -f [regex]::Escape($JobName)
    $start = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $jobPattern) {
            $start = $index
            break
        }
    }

    if ($start -lt 0) {
        return $null
    }

    $end = $Lines.Count
    for ($index = $start + 1; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^  [A-Za-z0-9_-]+:\s*$') {
            $end = $index
            break
        }
    }

    return ($Lines[$start..($end - 1)] -join "`n")
}

function Assert-WorkflowJob {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Jobs,
        [Parameter(Mandatory = $true)][string] $JobName,
        [Parameter(Mandatory = $true)][string[]] $Markers,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    if (-not $Jobs.ContainsKey($JobName)) {
        Write-Fail -TestName $TestName -Reason ("workflow missing job '{0}'" -f $JobName)
    }

    foreach ($marker in $Markers) {
        if ($Jobs[$JobName] -notmatch $marker) {
            Write-Fail -TestName $TestName -Reason ("job '{0}' missing marker '{1}'" -f $JobName, $marker)
        }
    }
}

function Get-MatrixEntries {
    param(
        [Parameter(Mandatory = $true)][string] $JobBlock
    )

    $entries = @()
    $pattern = '(?m)^\s*-\s*\{\s*adapter:\s*(?<adapter>[^,}]+),\s*script:\s*(?<script>[^}]+)\s*\}'
    foreach ($match in [regex]::Matches($JobBlock, $pattern)) {
        $entries += [pscustomobject]@{
            Adapter = $match.Groups['adapter'].Value.Trim()
            Script  = $match.Groups['script'].Value.Trim()
        }
    }

    return $entries
}

function Assert-MatrixContract {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Jobs,
        [Parameter(Mandatory = $true)][string] $JobName,
        [Parameter(Mandatory = $true)][hashtable[]] $ExpectedEntries,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    if (-not $Jobs.ContainsKey($JobName)) {
        Write-Fail -TestName $TestName -Reason ("workflow missing job '{0}'" -f $JobName)
    }

    $actualEntries = @(Get-MatrixEntries -JobBlock $Jobs[$JobName])
    if ($actualEntries.Count -ne $ExpectedEntries.Count) {
        Write-Fail -TestName $TestName -Reason ("job '{0}' matrix entry count must be {1}, got {2}" -f $JobName, $ExpectedEntries.Count, $actualEntries.Count)
    }

    $actualKeys = @($actualEntries | ForEach-Object { '{0}|{1}' -f $_.Adapter, $_.Script })
    if (@($actualKeys | Sort-Object -Unique).Count -ne $actualKeys.Count) {
        Write-Fail -TestName $TestName -Reason ("job '{0}' matrix contains duplicate adapter/script entries" -f $JobName)
    }

    $expectedKeys = @($ExpectedEntries | ForEach-Object { '{0}|{1}' -f $_.Adapter, $_.Script })
    if (@($expectedKeys | Sort-Object -Unique).Count -ne $expectedKeys.Count) {
        Write-Fail -TestName $TestName -Reason ("assertion has duplicate expected entries for job '{0}'" -f $JobName)
    }

    $unexpected = @($actualKeys | Where-Object { $_ -notin $expectedKeys })
    $missing = @($expectedKeys | Where-Object { $_ -notin $actualKeys })
    if ($unexpected.Count -gt 0 -or $missing.Count -gt 0) {
        Write-Fail -TestName $TestName -Reason ("job '{0}' matrix membership mismatch; missing=[{1}] unexpected=[{2}]" -f $JobName, ($missing -join ', '), ($unexpected -join ', '))
    }
}

function Get-NeedsEntries {
    param(
        [Parameter(Mandatory = $true)][string] $JobBlock
    )

    return @([regex]::Matches($JobBlock, '(?m)^\s*-\s*(?<job>[A-Za-z0-9_-]+)\s*$') | ForEach-Object { $_.Groups['job'].Value })
}

function Assert-ExactNeeds {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Jobs,
        [Parameter(Mandatory = $true)][string] $JobName,
        [Parameter(Mandatory = $true)][string[]] $ExpectedJobs,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    if (-not $Jobs.ContainsKey($JobName)) {
        Write-Fail -TestName $TestName -Reason ("workflow missing job '{0}'" -f $JobName)
    }

    $actualJobs = @(Get-NeedsEntries -JobBlock $Jobs[$JobName])
    if ($actualJobs.Count -ne $ExpectedJobs.Count) {
        Write-Fail -TestName $TestName -Reason ("job '{0}' needs count must be {1}, got {2}" -f $JobName, $ExpectedJobs.Count, $actualJobs.Count)
    }
    if (@($actualJobs | Sort-Object -Unique).Count -ne $actualJobs.Count) {
        Write-Fail -TestName $TestName -Reason ("job '{0}' needs contains duplicate dependencies" -f $JobName)
    }

    $missing = @($ExpectedJobs | Where-Object { $_ -notin $actualJobs })
    $unexpected = @($actualJobs | Where-Object { $_ -notin $ExpectedJobs })
    if ($missing.Count -gt 0 -or $unexpected.Count -gt 0) {
        Write-Fail -TestName $TestName -Reason ("job '{0}' needs mismatch; missing=[{1}] unexpected=[{2}]" -f $JobName, ($missing -join ', '), ($unexpected -join ', '))
    }
}

function Assert-ExactWorkflowJobs {
    param(
        [Parameter(Mandatory = $true)][string] $WorkflowText,
        [Parameter(Mandatory = $true)][string[]] $ExpectedJobs,
        [Parameter(Mandatory = $true)][string] $WorkflowName,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    $jobsStart = [regex]::Match($WorkflowText, '(?m)^jobs:\s*$')
    if (-not $jobsStart.Success) {
        Write-Fail -TestName $TestName -Reason ("workflow '{0}' is missing jobs section" -f $WorkflowName)
    }
    $jobsText = $WorkflowText.Substring($jobsStart.Index)
    $actualJobs = @([regex]::Matches($jobsText, '(?m)^  (?<job>[A-Za-z0-9_-]+):\s*$') | ForEach-Object { $_.Groups['job'].Value })
    if ($actualJobs.Count -ne $ExpectedJobs.Count) {
        Write-Fail -TestName $TestName -Reason ("workflow '{0}' job count must be {1}, got {2}" -f $WorkflowName, $ExpectedJobs.Count, $actualJobs.Count)
    }
    if (@($actualJobs | Sort-Object -Unique).Count -ne $actualJobs.Count) {
        Write-Fail -TestName $TestName -Reason ("workflow '{0}' contains duplicate job names" -f $WorkflowName)
    }

    $missing = @($ExpectedJobs | Where-Object { $_ -notin $actualJobs })
    $unexpected = @($actualJobs | Where-Object { $_ -notin $ExpectedJobs })
    if ($missing.Count -gt 0 -or $unexpected.Count -gt 0) {
        Write-Fail -TestName $TestName -Reason ("workflow '{0}' job membership mismatch; missing=[{1}] unexpected=[{2}]" -f $WorkflowName, ($missing -join ', '), ($unexpected -join ', '))
    }
}

function Assert-CheckoutCredentialsAreNotPersisted {
    param(
        [Parameter(Mandatory = $true)][string] $WorkflowText,
        [Parameter(Mandatory = $true)][string] $WorkflowName,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    $checkoutMatches = @([regex]::Matches($WorkflowText, '(?im)^\s*uses:\s*actions/checkout(?:@[^\s#]+)?\s*$'))
    if ($checkoutMatches.Count -eq 0) {
        return
    }

    foreach ($checkoutMatch in $checkoutMatches) {
        $remainingText = $WorkflowText.Substring($checkoutMatch.Index + $checkoutMatch.Length)
        $nextStep = [regex]::Match($remainingText, '(?m)^\s*-\s+|(?m)^\s{2}[A-Za-z0-9_-]+:\s*$')
        $checkoutBlock = if ($nextStep.Success) {
            $remainingText.Substring(0, $nextStep.Index)
        } else {
            $remainingText
        }

        if ($checkoutBlock -notmatch '(?im)^\s*persist-credentials:\s*false\s*$') {
            Write-Fail -TestName $TestName -Reason ("workflow '{0}' every actions/checkout step must set persist-credentials: false" -f $WorkflowName)
        }
    }
}

function Assert-ThirdPartyActionsArePinned {
    param(
        [Parameter(Mandatory = $true)][string] $WorkflowText,
        [Parameter(Mandatory = $true)][string] $WorkflowName,
        [Parameter(Mandatory = $true)][string] $TestName
    )

    $usesMatches = [regex]::Matches($WorkflowText, '(?im)^\s*uses:\s*(?<action>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)@(?<ref>[^\s#]+)\s*(?:#.*)?$')
    foreach ($usesMatch in $usesMatches) {
        $action = $usesMatch.Groups['action'].Value
        $ref = $usesMatch.Groups['ref'].Value
        if ($ref -notmatch '^[0-9a-fA-F]{40}$') {
            Write-Fail -TestName $TestName -Reason ("workflow '{0}' action '{1}' must use a full 40-character commit SHA; found '{2}'" -f $WorkflowName, $action, $ref)
        }
    }
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
$validationTelemetryPath = Join-Path $repoRoot (Join-Path 'scripts/_lib' 'Invoke-ValidationTelemetry.ps1')
$allowUserHomeForwardAssertName = $script:ToolkitConstant.AssertSyncAllowUserHomeForwardScriptName
$keyedUninstallCiAsserts = @($script:ToolkitConstant.KeyedUninstallCiAsserts)

if (-not (Test-Path -LiteralPath $workflowPath)) {
    Write-Fail -TestName 'Assert-CiWorkflowPreconditions' -Reason ("missing workflow: {0}" -f $workflowRel)
}

if (-not (Test-Path -LiteralPath $validateCorePath)) {
    Write-Fail -TestName 'Assert-CiWorkflowPreconditions' -Reason ("missing validate-core: {0}" -f $validateCoreRel)
}

if (-not (Test-Path -LiteralPath $validationTelemetryPath)) {
    Write-Fail -TestName 'Assert-CiWorkflowPreconditions' -Reason ("missing validation telemetry helper: {0}" -f $validationTelemetryPath)
}

# --- Should_DocumentCiWorkflowContract_When_WorkflowPresent ---
$ciName = 'Should_DocumentCiWorkflowContract_When_WorkflowPresent'
$workflowText = Get-Content -LiteralPath $workflowPath -Raw
$validateCoreText = Get-Content -LiteralPath $validateCorePath -Raw
$workflowJobs = @{}
foreach ($jobName in @(
        'validate',
        'validate-windows-keyed-uninstall',
        'validate-windows-adapter-smoke',
        'validate-ubuntu',
        'validate-ubuntu-adapter-smoke',
        'docs-strict',
        'ci-ok'
    )) {
    $workflowJobs[$jobName] = Get-WorkflowJobBlock -WorkflowText $workflowText -JobName $jobName
}

$requiredWorkflowMarkers = @(
    'validate-core.ps1',
    'actions/checkout',
    'pwsh',
    'permissions:',
    'contents: read',
    'ubuntu-latest',
    'validate-ubuntu',
    'ci-ok',
    $allowUserHomeForwardAssertName
)

foreach ($marker in $requiredWorkflowMarkers) {
    if ($workflowText -notlike ("*{0}*" -f $marker)) {
        Write-Fail -TestName $ciName -Reason ("workflow missing marker '{0}'" -f $marker)
    }
}

$workflowDirectory = Join-Path $repoRoot '.github/workflows'
$repositoryWorkflowFiles = @(
    Get-ChildItem -LiteralPath $workflowDirectory -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.yml', '.yaml') }
)
if ($repositoryWorkflowFiles.Count -eq 0) {
    Write-Fail -TestName $ciName -Reason 'repository must contain at least one YAML workflow'
}
foreach ($repositoryWorkflowFile in $repositoryWorkflowFiles) {
    $repositoryWorkflowText = Get-Content -LiteralPath $repositoryWorkflowFile.FullName -Raw
    Assert-ThirdPartyActionsArePinned -WorkflowText $repositoryWorkflowText -WorkflowName $repositoryWorkflowFile.Name -TestName $ciName
    Assert-CheckoutCredentialsAreNotPersisted -WorkflowText $repositoryWorkflowText -WorkflowName $repositoryWorkflowFile.Name -TestName $ciName
}

# -like treats [] as wildcards; use -match for the needs gate line.
Assert-WorkflowJob -Jobs $workflowJobs -JobName 'validate' -TestName $ciName -Markers @(
    '(?m)^\s*runs-on:\s*windows-latest\s*$'
    'validate-core\.ps1'
    [regex]::Escape($allowUserHomeForwardAssertName)
)

$matrixJobs = @(
    'validate-windows-keyed-uninstall'
    'validate-windows-adapter-smoke'
    'validate-ubuntu-adapter-smoke'
)
foreach ($matrixJob in $matrixJobs) {
    Assert-WorkflowJob -Jobs $workflowJobs -JobName $matrixJob -TestName $ciName -Markers @(
        '(?m)^\s*strategy:\s*$'
        '(?m)^\s*fail-fast:\s*false\s*$'
        '(?m)^\s*max-parallel:\s*4\s*$'
        '(?m)^\s*matrix:\s*$'
    )
}

Assert-WorkflowJob -Jobs $workflowJobs -JobName 'validate-windows-keyed-uninstall' -TestName $ciName -Markers @(
    '(?m)^\s*needs:\s*validate\s*$'
    'Run keyed uninstall assert'
)

Assert-WorkflowJob -Jobs $workflowJobs -JobName 'validate-windows-adapter-smoke' -TestName $ciName -Markers @(
    '(?m)^\s*needs:\s*validate\s*$'
    'Run adapter smoke'
)

Assert-WorkflowJob -Jobs $workflowJobs -JobName 'validate-ubuntu' -TestName $ciName -Markers @(
    '(?m)^\s*runs-on:\s*ubuntu-latest\s*$'
    'validate-core\.ps1'
)
if ($workflowJobs['validate-ubuntu'] -match '(?i)Run InstallRoot safety assert|Assert-InstallRootSafety\.ps1') {
    Write-Fail -TestName $ciName -Reason 'validate-ubuntu must rely on validate-core for the InstallRoot safety check'
}

Assert-WorkflowJob -Jobs $workflowJobs -JobName 'validate-ubuntu-adapter-smoke' -TestName $ciName -Markers @(
    '(?m)^\s*needs:\s*validate-ubuntu\s*$'
    'Run adapter smoke'
)

Assert-WorkflowJob -Jobs $workflowJobs -JobName 'docs-strict' -TestName $ciName -Markers @(
    '(?m)^\s*runs-on:\s*ubuntu-latest\s*$'
    'actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065'
    'pip install -r docs-site/requirements-docs.txt'
)

$ciOkNeeds = @(
    'validate'
    'validate-windows-keyed-uninstall'
    'validate-windows-adapter-smoke'
    'validate-ubuntu'
    'validate-ubuntu-adapter-smoke'
)
foreach ($requiredJob in $ciOkNeeds) {
    if ($workflowJobs['ci-ok'] -notmatch ('(?m)^\s*-\s*{0}\s*$' -f [regex]::Escape($requiredJob))) {
        Write-Fail -TestName $ciName -Reason ("ci-ok must depend on '{0}'" -f $requiredJob)
    }
}

foreach ($keyedAssert in $keyedUninstallCiAsserts) {
    if ($workflowText -notlike ("*{0}*" -f $keyedAssert.ScriptName)) {
        Write-Fail -TestName $ciName -Reason ("workflow missing keyed uninstall assert '{0}'" -f $keyedAssert.ScriptName)
    }
}

$adapterSmokeScripts = @(
    'Invoke-CursorCiSmoke.ps1',
    'Invoke-AntigravityCiSmoke.ps1',
    'Invoke-ClaudeCiSmoke.ps1',
    'Invoke-CodexCiSmoke.ps1',
    'Invoke-CopilotCiSmokeSuite.ps1',
    'Invoke-OpenCodeCiSmoke.ps1',
    'Invoke-GrokCiSmoke.ps1',
    'Invoke-ZCodeCiSmoke.ps1',
    'Invoke-HermesCiSmoke.ps1',
    'Invoke-OpenHandsCiSmoke.ps1'
)
foreach ($adapterSmokeScript in $adapterSmokeScripts) {
    foreach ($matrixJob in @('validate-windows-adapter-smoke', 'validate-ubuntu-adapter-smoke')) {
        if ($workflowJobs[$matrixJob] -notlike ("*{0}*" -f $adapterSmokeScript)) {
            Write-Fail -TestName $ciName -Reason ("job '{0}' missing adapter smoke assert '{1}'" -f $matrixJob, $adapterSmokeScript)
        }
    }
}

$expectedKeyedMatrix = @(
    @{ Adapter = 'Claude'; Script = 'Assert-ClaudeKeyedUninstall.ps1' }
    @{ Adapter = 'Copilot'; Script = 'Assert-CopilotKeyedUninstall.ps1' }
    @{ Adapter = 'Codex'; Script = 'Assert-CodexKeyedUninstall.ps1' }
    @{ Adapter = 'OpenCode'; Script = 'Assert-OpenCodeKeyedUninstall.ps1' }
    @{ Adapter = 'Antigravity'; Script = 'Assert-AntigravityKeyedUninstall.ps1' }
    @{ Adapter = 'Grok'; Script = 'Assert-GrokKeyedUninstall.ps1' }
    @{ Adapter = 'Cursor'; Script = 'Assert-CursorKeyedUninstall.ps1' }
    @{ Adapter = 'ZCode'; Script = 'Assert-ZcodeKeyedUninstall.ps1' }
    @{ Adapter = 'Hermes'; Script = 'Assert-HermesKeyedUninstall.ps1' }
    @{ Adapter = 'OpenHands'; Script = 'Assert-OpenHandsKeyedUninstall.ps1' }
)
$expectedSmokeMatrix = @(
    @{ Adapter = 'Cursor'; Script = 'Invoke-CursorCiSmoke.ps1' }
    @{ Adapter = 'Antigravity'; Script = 'Invoke-AntigravityCiSmoke.ps1' }
    @{ Adapter = 'Claude'; Script = 'Invoke-ClaudeCiSmoke.ps1' }
    @{ Adapter = 'Codex'; Script = 'Invoke-CodexCiSmoke.ps1' }
    @{ Adapter = 'Copilot'; Script = 'Invoke-CopilotCiSmokeSuite.ps1' }
    @{ Adapter = 'OpenCode'; Script = 'Invoke-OpenCodeCiSmoke.ps1' }
    @{ Adapter = 'Grok'; Script = 'Invoke-GrokCiSmoke.ps1' }
    @{ Adapter = 'ZCode'; Script = 'Invoke-ZCodeCiSmoke.ps1' }
    @{ Adapter = 'Hermes'; Script = 'Invoke-HermesCiSmoke.ps1' }
    @{ Adapter = 'OpenHands'; Script = 'Invoke-OpenHandsCiSmoke.ps1' }
)
Assert-MatrixContract -Jobs $workflowJobs -JobName 'validate-windows-keyed-uninstall' -ExpectedEntries $expectedKeyedMatrix -TestName $ciName
Assert-MatrixContract -Jobs $workflowJobs -JobName 'validate-windows-adapter-smoke' -ExpectedEntries $expectedSmokeMatrix -TestName $ciName
Assert-MatrixContract -Jobs $workflowJobs -JobName 'validate-ubuntu-adapter-smoke' -ExpectedEntries $expectedSmokeMatrix -TestName $ciName
Assert-ExactNeeds -Jobs $workflowJobs -JobName 'ci-ok' -ExpectedJobs @(
    'validate'
    'validate-windows-keyed-uninstall'
    'validate-windows-adapter-smoke'
    'validate-ubuntu'
    'validate-ubuntu-adapter-smoke'
    'docs-strict'
) -TestName $ciName

$workflowTopology = @(
    @{ RelativePath = '.github/workflows/docs.yml'; ExpectedJobs = @('build', 'deploy'); Required = @('jobs:', 'build:', 'runs-on: ubuntu-latest', 'mkdocs build --strict -f docs-site/mkdocs.yml', 'deploy:', 'needs: build', 'actions/deploy-pages@d6db90164ac5ed86f2b6aed7e0febac5b3c0c03e') }
    @{ RelativePath = '.github/workflows/enforce-release-source.yml'; ExpectedJobs = @('release-source'); Required = @('jobs:', 'release-source:', 'branches: [master, main]', 'github.head_ref', 'develop') }
    @{ RelativePath = '.github/workflows/publish-release-bootstrap.yml'; ExpectedJobs = @('publish'); Required = @('release:', 'types: [published]', 'workflow_dispatch:', 'permissions:', 'contents: write', 'publish:', 'actions/checkout@11d5960a326750d5838078e36cf38b85af677262', 'gh release upload') }
)
foreach ($workflow in $workflowTopology) {
    $path = Join-Path $repoRoot ($workflow.RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Fail -TestName $ciName -Reason ("workflow topology missing '{0}'" -f $workflow.RelativePath)
    }
    $text = Get-Content -LiteralPath $path -Raw
    Assert-ExactWorkflowJobs -WorkflowText $text -ExpectedJobs $workflow.ExpectedJobs -WorkflowName $workflow.RelativePath -TestName $ciName
    foreach ($marker in $workflow.Required) {
        if ($text.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
            Write-Fail -TestName $ciName -Reason ("workflow '{0}' missing topology marker '{1}'" -f $workflow.RelativePath, $marker)
        }
    }
}

$releaseWorkflowPath = Join-Path $repoRoot '.github/workflows/publish-release-bootstrap.yml'
$releaseWorkflowText = Get-Content -LiteralPath $releaseWorkflowPath -Raw
if ($releaseWorkflowText -notmatch '(?m)^\s*RELEASE_TAG:\s*\$\{\{\s*github\.event\.release\.tag_name\s*\|\|\s*inputs\.tag\s*\}\}\s*$') {
    Write-Fail -TestName $ciName -Reason 'release bootstrap workflow must pass the release tag through step env'
}
if ($releaseWorkflowText -match '(?m)TAG\s*=\s*"\$\{\{\s*github\.event\.release\.tag_name\s*\}\}"') {
    Write-Fail -TestName $ciName -Reason 'release bootstrap workflow must not interpolate the release tag directly in shell code'
}
foreach ($requiredReleaseMarker in @(
        "required: true"
        'github.event_name == ''release'''
        'github.event_name == ''workflow_dispatch'''
        "github.ref == 'refs/heads/master'"
        "github.ref == 'refs/heads/main'"
        'RELEASE_TAG:'
        'ref: ${{ env.RELEASE_TAG }}'
        'fetch-depth: 0'
        'Verify exact release tag checkout'
        'refs/tags/${CHECKED_OUT_TAG}'
        '"${tag_commit}" == "${head_commit}"'
        'v[0-9]+\.[0-9]+\.[0-9]+$'
    )) {
    if ($releaseWorkflowText.IndexOf($requiredReleaseMarker, [System.StringComparison]::Ordinal) -lt 0) {
        Write-Fail -TestName $ciName -Reason ("release bootstrap workflow missing provenance guard '{0}'" -f $requiredReleaseMarker)
    }
}
if ($releaseWorkflowText -match '(?m)ref:\s*\$\{\{\s*inputs\.tag\s*\}\}') {
    Write-Fail -TestName $ciName -Reason 'release bootstrap checkout must use the environment-backed ref'
}
if ($releaseWorkflowText -match '(?m)\$\{\{\s*github\.[^}]+\}\}') {
    $shellBlocks = [regex]::Matches($releaseWorkflowText, '(?ms)\s+run:\s*\|\s*(?<body>.*?)(?=\r?\n\s+- name:|\r?\n\s+uses:|\z)')
    foreach ($shellBlock in $shellBlocks) {
        if ($shellBlock.Groups['body'].Value -match '\$\{\{') {
            Write-Fail -TestName $ciName -Reason 'release bootstrap shell commands must not interpolate GitHub expressions'
        }
    }
}

$gitignorePath = Join-Path $repoRoot '.gitignore'
if (-not (Test-Path -LiteralPath $gitignorePath)) {
    Write-Fail -TestName $ciName -Reason 'missing .gitignore for generated fixture protection'
}
$gitignoreText = Get-Content -LiteralPath $gitignorePath -Raw
foreach ($pattern in @(
        'scripts/validation/fixtures/.runtime-script-publish-*/'
        'scripts/validation/fixtures/*-keyed-uninstall-repo-work/'
        'scripts/validation/fixtures/*-keyed-uninstall-user-work/'
        'scripts/validation/fixtures/antigravity-keyed-uninstall-work/'
        'scripts/validation/fixtures/copilot/user/agents/'
        'scripts/validation/fixtures/copilot/user/scripts/'
        'scripts/validation/fixtures/sdd-artifacts/evidence/reparse-escape/'
    )) {
    if ($gitignoreText -notlike ("*{0}*" -f $pattern)) {
        Write-Fail -TestName $ciName -Reason (".gitignore missing generated fixture pattern '{0}'" -f $pattern)
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

# --- Should_PreserveValidationTelemetryOnUnexpectedFailure_When_WrappersRun ---
$telemetryName = 'Should_PreserveValidationTelemetryOnUnexpectedFailure_When_WrappersRun'
$telemetryText = Get-Content -LiteralPath $validationTelemetryPath -Raw
foreach ($marker in @(
        'function Invoke-ValidationCheckWithTelemetry'
        'try {'
        'catch {'
        'finally {'
        'Write-ValidationTelemetryCheck'
    )) {
    if ($telemetryText.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
        Write-Fail -TestName $telemetryName -Reason ("telemetry helper missing marker '{0}'" -f $marker)
    }
}

$wrapperCount = @([regex]::Matches($workflowText, '(?m)^\s*\$exitCode\s*=\s*Invoke-ValidationCheckWithTelemetry\s*`')).Count
if ($wrapperCount -ne 6) {
    Write-Fail -TestName $telemetryName -Reason ("workflow must wrap all six validation entry points with finally-backed telemetry; found {0}" -f $wrapperCount)
}

if ($workflowJobs['ci-ok'] -notmatch '(?m)^\s*if:\s*always\(\)\s*$') {
    Write-Fail -TestName $telemetryName -Reason 'ci-ok must use if: always() so it can evaluate failed or skipped dependencies'
}
foreach ($marker in @(
        'REQUIRED_DEPENDENCY_RESULTS:'
        'toJSON\(needs\)'
        'ConvertFrom-Json'
        "-ne 'success'"
        'Required validation dependencies did not all succeed'
    )) {
    if ($workflowJobs['ci-ok'] -notmatch $marker) {
        Write-Fail -TestName $telemetryName -Reason ("ci-ok missing explicit dependency-result gate marker '{0}'" -f $marker)
    }
}
Write-Pass -TestName $telemetryName

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
