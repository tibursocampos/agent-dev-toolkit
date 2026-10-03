# Requires: PowerShell 5.1+
# Exercises local-instruction selection and seeded validation-finding reporting without invoking remediation tools.
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures\local-instruction-evidence'
$seededFindingsPath = Join-Path $fixtureRoot 'seeded-findings.json'
$initialFixtureHashes = @{}
foreach ($fixtureFile in Get-ChildItem -LiteralPath $fixtureRoot -File -Recurse) {
    $initialFixtureHashes[$fixtureFile.FullName] = (Get-FileHash -LiteralPath $fixtureFile.FullName -Algorithm SHA256).Hash
}
$contractPaths = @(
    (Join-Path $repoRoot 'core\skills\_shared\developer-common\step-3.5-precommit-validation.md'),
    (Join-Path $repoRoot 'core\skills\code-review\references\verification.md'),
    (Join-Path $repoRoot 'core\agents\security.md')
)

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
$nestedText = Get-Content -LiteralPath $nestedInstruction -Raw
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
$findingSeeds = Get-Content -LiteralPath $seededFindingsPath -Raw | ConvertFrom-Json
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
$runnerOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -ProjectRoot $fixtureRoot -ChangedPaths @('src/Widget.cs') -ConfigPath $configPath -BaselineRules @('BASE001') 2>&1)
Assert-True ($LASTEXITCODE -eq 0) "Configured diagnostics runner failed: $($runnerOutput -join "`n")"
$actualRecords = @((($runnerOutput -join "`n") | ConvertFrom-Json))
$actualFinding = $actualRecords | Where-Object Tool -eq 'fixture-analyzer' | Select-Object -First 1
Assert-True ($null -ne $actualFinding) 'Configured, installed tool should be discovered and invoked.'
Assert-True ($actualFinding.Status -eq 'FOUND' -and $actualFinding.Rule -eq 'DEMO001') 'Runner should parse the emitted rule and report FOUND.'
Assert-True ($actualFinding.File -eq 'src/Widget.cs' -and $actualFinding.Project -eq $fixtureRoot) 'Finding should preserve file and project scope.'
Assert-True ($actualFinding.Severity -eq 'warning' -and $actualFinding.Comparison -eq 'new') 'Finding should preserve severity and classify comparison.'
$missingRecord = $actualRecords | Where-Object Tool -eq 'missing-fixture-tool' | Select-Object -First 1
Assert-True ($missingRecord.Status -eq 'SKIPPED' -and $missingRecord.Reason -eq 'configured tool unavailable') 'Uninstalled configured tooling must be SKIPPED with a reason.'
Assert-True ($missingRecord.Comparison -eq 'unavailable' -and $missingRecord.Severity -eq 'n/a') 'Unavailable tool output must identify unavailable comparison and severity.'

$contractText = ($contractPaths | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n"
foreach ($forbidden in @('--fix', 'package update', 'suppress', 'quick fix', 'cleanup')) {
    Assert-True ($contractText -match [regex]::Escape($forbidden)) "Contract must explicitly prohibit automatic remediation '$forbidden'."
}

$currentFixtureFiles = @(Get-ChildItem -LiteralPath $fixtureRoot -File -Recurse)
Assert-True ($currentFixtureFiles.Count -eq $initialFixtureHashes.Count) 'Fixture file set changed during validation.'
foreach ($fixtureFile in $currentFixtureFiles) {
    $currentHash = (Get-FileHash -LiteralPath $fixtureFile.FullName -Algorithm SHA256).Hash
    Assert-True ($currentHash -eq $initialFixtureHashes[$fixtureFile.FullName]) "Fixture was modified during validation: $($fixtureFile.FullName)"
}

Write-Host 'Assert-LocalInstructionEvidenceBehavior: ALL PASS (precedence, conflict, configured-tool discovery/invocation, parsed findings, SKIPPED, no remediation)'
exit 0
