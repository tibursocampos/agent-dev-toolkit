# Requires: PowerShell 5.1+
# Exercises local-instruction selection and seeded validation-finding reporting without invoking remediation tools.
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures\local-instruction-evidence'
$seededFindingsPath = Join-Path $fixtureRoot 'seeded-findings.json'
. (Join-Path (Split-Path -Parent $PSScriptRoot) '_lib\ToolkitValidationFileSystem.ps1')
$initialFixtureHashes = @{}
foreach ($fixtureFile in Get-ToolkitValidationFiles -Root $fixtureRoot -Recurse) {
    $initialFixtureHashes[$fixtureFile.FullName] = Get-ToolkitValidationFileFingerprint -Path $fixtureFile.FullName
}
$contractPaths = @(
    (Join-Path $repoRoot 'core\skills\_shared\developer-common\step-3.5-precommit-validation.md'),
    (Join-Path $repoRoot 'core\skills\code-review\references\verification.md'),
    (Join-Path $repoRoot 'core\agents\security.md')
)

$reparseEnumerationRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-validation-reparse-root-{0}" -f [guid]::NewGuid().ToString('N'))
$reparseEnumerationTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-validation-reparse-target-{0}" -f [guid]::NewGuid().ToString('N'))

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Get-ApplicableInstructionChain {
    param([string] $Root, [string] $RelativePath)

    $directory = Split-Path -Parent $RelativePath
    $segments = @()
    if ($directory) { $segments = @($directory -split '[\\/]') }
    $current = $Root
    $chain = [System.Collections.Generic.List[string]]::new()
    $rootInstruction = Join-Path $current 'AGENTS.md'
    if (Test-Path -LiteralPath $rootInstruction) { $chain.Add($rootInstruction) }

    foreach ($segment in $segments) {
        $current = Join-Path $current $segment
        $instruction = Join-Path $current 'AGENTS.md'
        if (Test-Path -LiteralPath $instruction) { $chain.Add($instruction) }
    }

    return @($chain.ToArray())
}

function New-FindingRecord {
    param(
        [string] $Tool,
        [string] $Scope,
        [bool] $Available,
        [string] $Evidence,
        [string] $Severity,
        [string] $Comparison,
        [string] $Finding,
        [string] $UnavailableReason
    )

    if (-not $Available) {
        return [pscustomobject]@{
            Tool = $Tool; Scope = $Scope; Status = 'SKIPPED'; Evidence = $UnavailableReason
            Severity = 'n/a'; Comparison = 'unavailable'; Finding = 'n/a'; Notes = $UnavailableReason
        }
    }

    return [pscustomobject]@{
        Tool = $Tool; Scope = $Scope; Status = 'FOUND'; Evidence = $Evidence
        Severity = $Severity; Comparison = $Comparison; Finding = $Finding; Notes = ''
    }
}

$rootInstruction = Join-Path $fixtureRoot 'AGENTS.md'
$nestedInstruction = Join-Path $fixtureRoot 'src\AGENTS.md'
$siblingInstruction = Join-Path $fixtureRoot 'sibling\AGENTS.md'
foreach ($path in @($rootInstruction, $nestedInstruction, $siblingInstruction) + $contractPaths) {
    Assert-True (Test-Path -LiteralPath $path) "Required fixture or contract is missing: $path"
}

$sourceChain = Get-ApplicableInstructionChain -Root $fixtureRoot -RelativePath 'src\Widget.cs'
Assert-True ($sourceChain.Count -eq 2) 'Root and nested instruction files should apply to src/Widget.cs.'
Assert-True ($sourceChain[-1] -eq $nestedInstruction) 'The closest nested instruction should be last and control local rules.'
Assert-True ($sourceChain -notcontains $siblingInstruction) 'A sibling instruction must not apply to src/Widget.cs.'

$higherAuthorityRule = 'Host policy: do not run automatic formatters or fixes.'
$nestedText = Read-ToolkitValidationText -Path $nestedInstruction
$conflicts = @()
if ($nestedText -match 'Run an automatic formatter' -and $higherAuthorityRule -match 'do not run automatic formatters or fixes') {
    $conflicts += [pscustomobject]@{
        HigherAuthority = $higherAuthorityRule
        NestedInstruction = $nestedInstruction
        ControllingRule = $higherAuthorityRule
    }
}
Assert-True ($conflicts.Count -eq 1) 'A higher-authority conflict should be surfaced.'
Assert-True ($conflicts[0].ControllingRule -eq $higherAuthorityRule) 'The higher-authority rule should remain controlling.'

Assert-True (Test-Path -LiteralPath $seededFindingsPath) 'Seeded diagnostics fixture is missing.'
$findingSeeds = Read-ToolkitValidationText -Path $seededFindingsPath | ConvertFrom-Json
$seededFindings = @($findingSeeds | ForEach-Object {
    New-FindingRecord -Tool $_.Tool -Scope $_.Scope -Available ([bool]$_.Available) -Evidence $_.Evidence -Severity $_.Severity -Comparison $_.Comparison -Finding $_.Finding -UnavailableReason $_.UnavailableReason
})

$requiredFields = @('Tool', 'Scope', 'Status', 'Evidence', 'Severity', 'Comparison', 'Finding', 'Notes')
foreach ($record in $seededFindings) {
    foreach ($field in $requiredFields) {
        Assert-True ($null -ne $record.PSObject.Properties[$field]) "Finding record missing required field '$field'."
        if ($field -ne 'Notes') {
            Assert-True (-not [string]::IsNullOrWhiteSpace([string]$record.$field)) "Finding record has empty required field '$field'."
        }
    }
}
Assert-True (@($seededFindings | Where-Object Status -eq 'FOUND').Count -eq 3) 'Seeded lint, dependency, and analyzer findings should be reported as FOUND.'
Assert-True (@($seededFindings | Where-Object Status -eq 'SKIPPED').Count -eq 1) 'Unavailable tooling should be reported as SKIPPED.'
Assert-True (($seededFindings | Where-Object Tool -eq 'optional-analyzer').Status -eq 'SKIPPED') 'Unavailable tools must never be reported as PASS.'

# Invoke the configured-tool runner against a local executable fixture. This proves discovery,
# invocation, parsed diagnostics, comparison, and unavailable-tool reporting end to end.
$runnerPath = Join-Path $PSScriptRoot 'Invoke-ConfiguredDiagnostics.ps1'
$configPath = Join-Path $fixtureRoot '.agent-validation-tools.json'
$baselinePath = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-validation-baseline-{0}.json" -f [guid]::NewGuid().ToString('N'))
$invocationMarker = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-validation-invoked-{0}.txt" -f [guid]::NewGuid().ToString('N'))
$previousMarker = $env:FIXTURE_DIAGNOSTIC_MARKER
$env:FIXTURE_DIAGNOSTIC_MARKER = $invocationMarker
$baseline = @(
    [pscustomobject]@{ Tool = 'fixture-analyzer'; Project = $fixtureRoot; File = 'other/Widget.cs'; Rule = 'DEMO001' },
    [pscustomobject]@{ Tool = 'fixture-analyzer'; Project = ($fixtureRoot + '-other'); File = 'src/Widget.cs'; Rule = 'DEMO001' },
    [pscustomobject]@{ Tool = 'different-analyzer'; Project = $fixtureRoot; File = 'src/Widget.cs'; Rule = 'DEMO001' }
)
try {
    $baseline | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $baselinePath
    Push-Location $env:TEMP
    try {
        $untrustedOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -ProjectRoot $fixtureRoot -ChangedPaths @('src/Widget.cs') -ConfigPath $configPath -BaselinePath $baselinePath -MaxOutputLength 512 2>&1)
        Assert-True ($LASTEXITCODE -eq 0) "Untrusted configured diagnostics runner failed: $($untrustedOutput -join "`n")"
        $untrustedRecords = @(($untrustedOutput -join "`n" | ConvertFrom-Json))
        Assert-True (-not (Test-Path -LiteralPath $invocationMarker)) 'Unapproved configured commands must not be invoked.'
        Assert-True ($untrustedRecords.Count -eq 3 -and @($untrustedRecords | Where-Object { $_.Status -ne 'SKIPPED' -or $_.Reason -ne 'configured command not trusted' }).Count -eq 0) 'Unapproved commands must all be SKIPPED with an explicit trust reason.'

        $runnerOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -ProjectRoot $fixtureRoot -ChangedPaths @('src/Widget.cs') -ConfigPath $configPath -BaselinePath $baselinePath -MaxOutputLength 512 -TrustConfiguredCommands 2>&1)
    }
    finally { Pop-Location }
    Assert-True ($LASTEXITCODE -eq 0) "Configured diagnostics runner failed: $($runnerOutput -join "`n")"
        $actualRecords = @((($runnerOutput -join "`n") | ConvertFrom-Json))
        $approvedInvoked = Test-Path -LiteralPath $invocationMarker
}
finally {
    Remove-Item -LiteralPath $baselinePath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $invocationMarker -Force -ErrorAction SilentlyContinue
    if ($null -eq $previousMarker) { Remove-Item Env:\FIXTURE_DIAGNOSTIC_MARKER -ErrorAction SilentlyContinue }
    else { $env:FIXTURE_DIAGNOSTIC_MARKER = $previousMarker }
}
$actualFinding = $actualRecords | Where-Object Tool -eq 'fixture-analyzer' | Select-Object -First 1
Assert-True $approvedInvoked 'Explicit trust approval should invoke the configured executable.'
Assert-True ($null -ne $actualFinding) 'Configured, installed tool should be discovered and invoked after explicit trust approval.'
Assert-True ($actualFinding.Status -eq 'FOUND' -and $actualFinding.Rule -eq 'DEMO001') 'Runner should parse the emitted rule and report FOUND.'
Assert-True ($actualFinding.File -eq 'src/Widget.cs' -and $actualFinding.Project -eq $fixtureRoot) 'Finding should preserve file and project scope.'
Assert-True ($actualFinding.Severity -eq 'warning' -and $actualFinding.Comparison -eq 'new') 'Same rule in another project/file must remain a new finding.'
Assert-True ($actualFinding.Command -notmatch 'fixture-secret-value' -and $actualFinding.Evidence -notmatch 'fixture-secret-value') 'Command arguments and captured output must not expose secret values.'
Assert-True ($actualFinding.Evidence -match '\[REDACTED\]') 'Secret-like diagnostic output must be redacted.'
$exactBaselinePath = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-validation-baseline-{0}.json" -f [guid]::NewGuid().ToString('N'))
try {
    @([pscustomobject]@{ Tool = 'fixture-analyzer'; Project = $fixtureRoot; File = 'src/Widget.cs'; Rule = 'DEMO001' }) | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $exactBaselinePath
    Push-Location $env:TEMP
    try { $exactOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -ProjectRoot $fixtureRoot -ChangedPaths @('src/Widget.cs') -ConfigPath $configPath -BaselinePath $exactBaselinePath -TrustConfiguredCommands 2>&1) }
    finally { Pop-Location }
    Assert-True ($LASTEXITCODE -eq 0) "Configured diagnostics baseline comparison failed: $($exactOutput -join "`n")"
    $exactRecords = @(($exactOutput -join "`n" | ConvertFrom-Json))
    $exactFinding = $exactRecords | Where-Object Tool -eq 'fixture-analyzer' | Select-Object -First 1
    Assert-True ($exactFinding.Comparison -eq 'pre-existing') 'Exact tool/project/file/rule identity should be pre-existing.'
}
finally { Remove-Item -LiteralPath $exactBaselinePath -Force -ErrorAction SilentlyContinue }
$incompleteBaselinePath = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-validation-baseline-{0}.json" -f [guid]::NewGuid().ToString('N'))
try {
    @([pscustomobject]@{ Tool = 'fixture-analyzer'; Project = $fixtureRoot; Rule = 'DEMO001' }) | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $incompleteBaselinePath
    $incompleteOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -ProjectRoot $fixtureRoot -ChangedPaths @('src/Widget.cs') -ConfigPath $configPath -BaselinePath $incompleteBaselinePath -TrustConfiguredCommands 2>&1)
    Assert-True ($LASTEXITCODE -eq 0) "Incomplete baseline handling failed: $($incompleteOutput -join "`n")"
    $incompleteRecords = @(($incompleteOutput -join "`n" | ConvertFrom-Json))
    $incompleteFinding = $incompleteRecords | Where-Object Tool -eq 'fixture-analyzer' | Select-Object -First 1
    Assert-True ($incompleteFinding.Comparison -eq 'unavailable') 'Incomplete baseline identity must make comparison unavailable.'
}
finally { Remove-Item -LiteralPath $incompleteBaselinePath -Force -ErrorAction SilentlyContinue }
$noBaselineOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -ProjectRoot $fixtureRoot -ChangedPaths @('src/Widget.cs') -ConfigPath $configPath -TrustConfiguredCommands 2>&1)
Assert-True ($LASTEXITCODE -eq 0) "Missing baseline handling failed: $($noBaselineOutput -join "`n")"
$noBaselineRecords = @(($noBaselineOutput -join "`n" | ConvertFrom-Json))
$noBaselineFinding = $noBaselineRecords | Where-Object Tool -eq 'fixture-analyzer' | Select-Object -First 1
Assert-True ($noBaselineFinding.Comparison -eq 'unavailable') 'Without baseline data, comparison must be unavailable.'
$longOutput = @($actualRecords | Where-Object Tool -eq 'fixture-long-output' | Select-Object -First 1)
Assert-True ($longOutput.Count -eq 1 -and $longOutput[0].Evidence -match '\[TRUNCATED\]') 'Captured tool output must be bounded and indicate truncation.'
Assert-True ($longOutput[0].Evidence.Length -le 530) 'Captured tool output exceeded the configured bound.'
$missingRecord = $actualRecords | Where-Object Tool -eq 'missing-fixture-tool' | Select-Object -First 1
Assert-True ($missingRecord.Status -eq 'SKIPPED' -and $missingRecord.Reason -eq 'configured tool unavailable') 'Uninstalled configured tooling must be SKIPPED with a reason.'
Assert-True ($missingRecord.Comparison -eq 'unavailable' -and $missingRecord.Severity -eq 'n/a') 'Unavailable tool output must identify unavailable comparison and severity.'

# Recursive validation enumeration must not follow a junction into files outside its root.
try {
    $null = New-Item -ItemType Directory -Path $reparseEnumerationRoot -Force
    $null = New-Item -ItemType Directory -Path $reparseEnumerationTarget -Force
    Set-Content -LiteralPath (Join-Path $reparseEnumerationRoot 'visible.txt') -Value 'inside'
    Set-Content -LiteralPath (Join-Path $reparseEnumerationTarget 'escaped.txt') -Value 'outside'
    $reparseLink = Join-Path $reparseEnumerationRoot 'linked'
    $null = New-Item -ItemType Junction -Path $reparseLink -Target $reparseEnumerationTarget

    $enumeratedFiles = @(Get-ToolkitValidationFiles -Root $reparseEnumerationRoot -Recurse)
    Assert-True (@($enumeratedFiles | Where-Object Name -eq 'visible.txt').Count -eq 1) 'Recursive validation enumeration should retain ordinary files.'
    Assert-True (@($enumeratedFiles | Where-Object Name -eq 'escaped.txt').Count -eq 0) 'Recursive validation enumeration must skip reparse-point directories.'
    Assert-True (@($enumeratedFiles | Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -eq 0) 'Validation enumeration must not return reparse-point files.'
}
finally {
    Remove-Item -LiteralPath (Join-Path $reparseEnumerationRoot 'linked') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $reparseEnumerationRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $reparseEnumerationTarget -Recurse -Force -ErrorAction SilentlyContinue
}

$contractText = ($contractPaths | ForEach-Object { Read-ToolkitValidationText -Path $_ }) -join "`n"
foreach ($forbidden in @('--fix', 'package update', 'suppress', 'quick fix', 'cleanup')) {
    Assert-True ($contractText -match [regex]::Escape($forbidden)) "Contract must explicitly prohibit automatic remediation '$forbidden'."
}

$currentFixtureFiles = @(Get-ToolkitValidationFiles -Root $fixtureRoot -Recurse)
Assert-True ($currentFixtureFiles.Count -eq $initialFixtureHashes.Count) 'Fixture file set changed during validation.'
foreach ($fixtureFile in $currentFixtureFiles) {
    $currentHash = Get-ToolkitValidationFileFingerprint -Path $fixtureFile.FullName
    Assert-True ($currentHash -eq $initialFixtureHashes[$fixtureFile.FullName]) "Fixture was modified during validation: $($fixtureFile.FullName)"
}

Write-Host 'Assert-LocalInstructionEvidenceBehavior: ALL PASS (precedence, conflict, configured-tool discovery/invocation, parsed findings, SKIPPED, no remediation)'
exit 0
