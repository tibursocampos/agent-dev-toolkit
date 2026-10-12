#Requires -Version 5.1
<##
.SYNOPSIS
  Verifies canonical SDD contracts, the checked-in projection, and a real publisher fixture.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sourceRoot = Join-Path $repoRoot 'core\sdd'
$projectionRoot = Join-Path $repoRoot 'core\skills\_shared\sdd-artifacts'
$contracts = @('PIPELINE.md', 'STORAGE.md', 'STORAGE-RESOLUTION.md', 'SESSION.md', 'MEMORY-BANK.md')
$memoryBankSourceCommand = '.\scripts\inventory\Invoke-MemoryBankInventory.ps1'
$memoryBankProjectionCommand = 'pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/inventory/Invoke-MemoryBankInventory.ps1"'
$approvedPlaceholderCounts = @{
    'PIPELINE.md' = @{ '{{TOOLKIT_ROOT}}' = 2; '{{SDD_ROOT}}' = 4; '{{GUARDRAILS_PATH}}' = 0 }
    'STORAGE.md' = @{ '{{TOOLKIT_ROOT}}' = 1; '{{SDD_ROOT}}' = 2; '{{GUARDRAILS_PATH}}' = 0 }
    'STORAGE-RESOLUTION.md' = @{ '{{TOOLKIT_ROOT}}' = 0; '{{SDD_ROOT}}' = 5; '{{GUARDRAILS_PATH}}' = 0 }
    'SESSION.md' = @{ '{{TOOLKIT_ROOT}}' = 12; '{{SDD_ROOT}}' = 2; '{{GUARDRAILS_PATH}}' = 0 }
    'MEMORY-BANK.md' = @{ '{{TOOLKIT_ROOT}}' = 3; '{{SDD_ROOT}}' = 0; '{{GUARDRAILS_PATH}}' = 0 }
}

function Read-ContractText {
    param([Parameter(Mandatory = $true)][string] $Path)

    return [System.IO.File]::ReadAllText($Path).Replace("`r`n", "`n").Replace("`r", "`n")
}

function Get-ContractProjection {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $SourceText
    )

    if ($Name -ne 'MEMORY-BANK.md') { return $SourceText }
    $occurrences = [regex]::Matches($SourceText, [regex]::Escape($memoryBankSourceCommand)).Count
    if ($occurrences -ne 1) { return $null }
    return $SourceText.Replace($memoryBankSourceCommand, $memoryBankProjectionCommand)
}

function Get-ComparisonDiagnostic {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Location,
        [Parameter(Mandatory = $true)][string] $Expected,
        [Parameter(Mandatory = $true)][string] $Actual
    )

    if ($Expected -ceq $Actual) { return @() }
    return @('{0}: {1}: unauthorized-drift' -f $Name, $Location)
}

function Get-PresenceDiagnostic {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Location,
        [Parameter(Mandatory = $true)][bool] $Exists
    )

    if ($Exists) { return @() }
    return @('{0}: {1}: missing-contract' -f $Name, $Location)
}

function Add-Diagnostics {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]] $Target,
        [Parameter()] $Items
    )

    foreach ($item in $Items) { if (-not [string]::IsNullOrWhiteSpace($item)) { $Target.Add($item) } }
}

function Get-HashHex16 {
    param([Parameter(Mandatory = $true)][string] $Value)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value.Replace('\', '/').TrimEnd('/'))
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant().Substring(0, 16)
    }
    finally { $sha.Dispose() }
}

function Invoke-IdentityGateCase {
    param(
        [Parameter(Mandatory = $true)][string] $RepoPath,
        [Parameter(Mandatory = $true)][string] $PlanPath,
        [Parameter(Mandatory = $true)][string] $SessionsRoot,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $MissingField
    )

    $repoIdentity = ([System.IO.Path]::GetFullPath($RepoPath)).Replace('\', '/')
    $planIdentity = ([System.IO.Path]::GetFullPath($PlanPath)).Replace('\', '/')
    $repoHash = Get-HashHex16 -Value $repoIdentity
    $planHash = Get-HashHex16 -Value $planIdentity
    $sessionDirectory = Join-Path (Join-Path $SessionsRoot $repoHash) ''
    $sessionPath = Join-Path $sessionDirectory ('plan-{0}-step-3.json' -f $planHash)
    New-Item -ItemType Directory -Path $sessionDirectory -Force | Out-Null

    $identity = [ordered]@{ repo = $repoIdentity; plan_path = $planIdentity; step = 3; workflow = 'classic'; phase = 'develop'; gates = @{ step_confirmed = $false; tests_run = $false } }
    if ($MissingField) { $identity.Remove($MissingField) }
    $json = $identity | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($sessionPath, $json, (New-Object System.Text.UTF8Encoding $false))
    $beforeHash = (Get-FileHash -LiteralPath $sessionPath -Algorithm SHA256).Hash
    $helper = Join-Path $repoRoot 'scripts/session/Invoke-DevelopSessionGate.ps1'
    $helperOutput = @(& pwsh -NoProfile -File $helper -Action status -PlanPath $planIdentity -RepoPath $repoIdentity -SessionsRoot $SessionsRoot -Step 3 2>&1)
    $helperExit = $LASTEXITCODE
    $afterHash = (Get-FileHash -LiteralPath $sessionPath -Algorithm SHA256).Hash
    if ($beforeHash -cne $afterHash) { throw 'Identity gate changed persisted fixture bytes.' }
    if ($MissingField -and $helperExit -eq 0) { throw 'Identity gate accepted a missing persisted field.' }
    if (-not $MissingField -and $helperExit -ne 0) { throw 'Identity gate rejected a complete persisted identity.' }
    return $true
}

function Invoke-ContractSelfChecks {
    param(
        [Parameter(Mandatory = $true)][string] $SessionContract,
        [Parameter(Mandatory = $true)][string] $RepoPath
    )

    $checks = New-Object System.Collections.Generic.List[string]
    foreach ($case in @(
        @{ Name = 'PIPELINE.md'; Location = 'source'; Exists = $false },
        @{ Name = 'STORAGE.md'; Location = 'projection'; Exists = $false },
        @{ Name = 'STORAGE-RESOLUTION.md'; Location = 'projection'; Exists = $false },
        @{ Name = 'SESSION.md'; Location = 'published'; Exists = $false }
    )) {
        $result = @(Get-PresenceDiagnostic -Name $case.Name -Location $case.Location -Exists $case.Exists)
        if ($result.Count -ne 1 -or $result[0] -notmatch 'missing-contract') { throw 'Missing-contract case failed.' }
        [void]$checks.Add('missing')
    }

    $sessionJsonBlocks = [regex]::Matches($SessionContract, '(?s)```json\s*(.*?)\s*```')
    $sessionSchema = $null
    foreach ($block in $sessionJsonBlocks) {
        try {
            $candidate = $block.Groups[1].Value | ConvertFrom-Json -ErrorAction Stop
            if ($null -ne $candidate.PSObject.Properties['plan_path']) { $sessionSchema = $candidate; break }
        } catch { }
    }
    if ($null -eq $sessionSchema -or $null -eq $sessionSchema.PSObject.Properties['repo']) {
        throw 'SESSION.md persisted identity schema is incomplete.'
    }
    $sessionFixtureRoot = Join-Path $repoRoot ('scripts/validation/fixtures/.core-sdd-identity-' + [guid]::NewGuid().ToString('N'))
    try {
        $planFixturePath = Join-Path $sessionFixtureRoot 'PLAN_000_identity_fixture.md'
        New-Item -ItemType Directory -Path (Split-Path -Parent $planFixturePath) -Force | Out-Null
        [System.IO.File]::WriteAllText($planFixturePath, '# Session identity fixture', (New-Object System.Text.UTF8Encoding $false))
        if (-not (Invoke-IdentityGateCase -RepoPath $RepoPath -PlanPath $planFixturePath -SessionsRoot $sessionFixtureRoot -MissingField '')) {
            throw 'Valid identity case failed.'
        }
        foreach ($field in @('repo', 'plan_path')) {
            if (-not (Invoke-IdentityGateCase -RepoPath $RepoPath -PlanPath $planFixturePath -SessionsRoot $sessionFixtureRoot -MissingField $field)) {
                throw ('Missing identity field case failed: {0}.' -f $field)
            }
            [void]$checks.Add('identity')
        }
    }
    finally {
        if (Test-Path -LiteralPath $sessionFixtureRoot) { Remove-Item -LiteralPath $sessionFixtureRoot -Recurse -Force }
    }

    $sentinel = 'S3_SENTINEL_MUST_NOT_LEAK'
    $drift = @(Get-ComparisonDiagnostic -Name 'SESSION.md' -Location 'identity.repo' -Expected 'expected' -Actual $sentinel)
    if ($drift.Count -ne 1 -or $drift[0].Contains($sentinel) -or $drift[0] -notmatch 'unauthorized-drift' -or $drift[0] -match '(?i)pass|success|synchronized') {
        throw 'Redacted drift diagnostic case failed.'
    }
    $repeat = @(Get-ComparisonDiagnostic -Name 'SESSION.md' -Location 'identity.repo' -Expected 'expected' -Actual $sentinel)
    if (($drift -join "`n") -cne ($repeat -join "`n")) { throw 'Deterministic diagnostic case failed.' }
    [void]$checks.Add('redaction-and-determinism')

    $source = Read-ContractText -Path (Join-Path $sourceRoot 'MEMORY-BANK.md')
    $projection = Get-ContractProjection -Name 'MEMORY-BANK.md' -SourceText $source
    if ($null -eq $projection -or $projection -notmatch [regex]::Escape($memoryBankProjectionCommand)) {
        throw 'Named MEMORY-BANK.md projection transform case failed.'
    }
    $unauthorized = @(Get-ComparisonDiagnostic -Name 'MEMORY-BANK.md' -Location 'projection' -Expected $projection -Actual ($projection + ' drift'))
    if ($unauthorized.Count -ne 1) { throw 'Unauthorized transform case failed.' }
    [void]$checks.Add('named-transform')
    return $checks.Count
}

function Resolve-PublishedExpectedText {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $InstallRoot
    )

    foreach ($token in $approvedPlaceholderCounts[$Name].Keys) {
        $actualCount = [regex]::Matches($Text, [regex]::Escape($token)).Count
        if ($actualCount -ne [int]$approvedPlaceholderCounts[$Name][$token]) {
            throw 'Published placeholder inventory differs from the S1 allowlist.'
        }
    }

    $root = $InstallRoot.Replace('\', '/')
    $tokens = [ordered]@{
        '{{TOOLKIT_ROOT}}' = $root
        '{{SDD_ROOT}}' = ($root + '/sdd')
        '{{GUARDRAILS_PATH}}' = ($root + '/rules/guardrails.mdc')
    }
    $resolved = $Text
    foreach ($token in $tokens.Keys) { $resolved = $resolved.Replace($token, [string]$tokens[$token]) }
    return $resolved
}

$script:validationStage = 'source-projection'
try {
    $diagnostics = New-Object System.Collections.Generic.List[string]
    $sessionPath = Join-Path $sourceRoot 'SESSION.md'
    $sessionContract = if (Test-Path -LiteralPath $sessionPath -PathType Leaf) { Read-ContractText -Path $sessionPath } else { '' }

    foreach ($name in $contracts) {
        $sourcePath = Join-Path $sourceRoot $name
        $projectionPath = Join-Path $projectionRoot $name
        Add-Diagnostics -Target $diagnostics -Items (Get-PresenceDiagnostic -Name $name -Location 'core/sdd' -Exists (Test-Path -LiteralPath $sourcePath -PathType Leaf))
        Add-Diagnostics -Target $diagnostics -Items (Get-PresenceDiagnostic -Name $name -Location 'core/skills/_shared/sdd-artifacts' -Exists (Test-Path -LiteralPath $projectionPath -PathType Leaf))
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf) -or -not (Test-Path -LiteralPath $projectionPath -PathType Leaf)) { continue }

        $sourceText = Read-ContractText -Path $sourcePath
        $projectionText = Read-ContractText -Path $projectionPath
        $expectedProjection = Get-ContractProjection -Name $name -SourceText $sourceText
        if ($null -eq $expectedProjection) {
            $diagnostics.Add(('{0}: projection.transform: unauthorized-transform' -f $name))
            continue
        }
        Add-Diagnostics -Target $diagnostics -Items (Get-ComparisonDiagnostic -Name $name -Location 'checked-in-projection' -Expected $expectedProjection -Actual $projectionText)
    }

    if (Test-Path -LiteralPath $sessionPath -PathType Leaf) {
        $identitySchemaBlocks = [regex]::Matches($sessionContract, '(?s)```json\s*(.*?)\s*```')
        $hasRepo = $false
        $hasPlanPath = $false
        foreach ($block in $identitySchemaBlocks) {
            if ($block.Groups[1].Value -match '"repo"\s*:') { $hasRepo = $true }
            if ($block.Groups[1].Value -match '"plan_path"\s*:') { $hasPlanPath = $true }
        }
        if (-not $hasRepo) { $diagnostics.Add('SESSION.md: identity.repo: missing-identity') }
        if (-not $hasPlanPath) { $diagnostics.Add('SESSION.md: identity.plan_path: missing-identity') }
    }

    if ($diagnostics.Count -gt 0) {
        foreach ($diagnostic in $diagnostics) { Write-Host ('FAIL: ' + $diagnostic) -ForegroundColor Red }
        exit 1
    }

    $script:validationStage = 'identity-and-diagnostic-cases'
    $selfCheckCount = Invoke-ContractSelfChecks -SessionContract $sessionContract -RepoPath $repoRoot
    $fixtureRelative = 'scripts/validation/fixtures/.core-sdd-contracts-' + [guid]::NewGuid().ToString('N')
    $installRoot = Join-Path $repoRoot ($fixtureRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $resolvedInstallRoot = [System.IO.Path]::GetFullPath($installRoot)
    $fixtureParent = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'scripts/validation/fixtures')) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedInstallRoot.StartsWith($fixtureParent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Temporary publisher fixture escaped the validation fixtures root.'
    }

    $script:validationStage = 'cursor-publisher-fixture'
    try {
        $publisherOutput = @(& pwsh -NoProfile -File (Join-Path $repoRoot 'scripts/sync-agent.ps1') -Agent cursor -InstallRoot $resolvedInstallRoot 2>&1)
        if ($LASTEXITCODE -ne 0) { throw 'Cursor fixture publisher failed.' }
        $publishedRoot = Join-Path $resolvedInstallRoot 'skills/_shared/sdd-artifacts'
        foreach ($name in $contracts) {
            $publishedPath = Join-Path $publishedRoot $name
            if (-not (Test-Path -LiteralPath $publishedPath -PathType Leaf)) {
                $diagnostics.Add(('{0}: cursor-fixture/{1}: missing-contract' -f $name, $name))
                continue
            }
            $projectionPath = Join-Path $projectionRoot $name
            if (-not (Test-Path -LiteralPath $projectionPath -PathType Leaf)) { continue }
            $projectionText = Read-ContractText -Path $projectionPath
            $expectedPublished = Resolve-PublishedExpectedText -Name $name -Text $projectionText -InstallRoot $resolvedInstallRoot
            $publishedText = Read-ContractText -Path $publishedPath
            Add-Diagnostics -Target $diagnostics -Items (Get-ComparisonDiagnostic -Name $name -Location 'cursor-fixture/skills/_shared/sdd-artifacts' -Expected $expectedPublished -Actual $publishedText)
        }
    }
    finally {
        if (Test-Path -LiteralPath $resolvedInstallRoot) {
            Remove-Item -LiteralPath $resolvedInstallRoot -Recurse -Force
        }
    }

    if ($diagnostics.Count -gt 0) {
        foreach ($diagnostic in $diagnostics) { Write-Host ('FAIL: ' + $diagnostic) -ForegroundColor Red }
        exit 1
    }

    Write-Host ('Assert-CoreSddContracts: PASS ({1} contracts; {0} focused negative/transform checks; cursor publisher fixture)' -f $selfCheckCount, $contracts.Count)
    exit 0
}
catch {
    Write-Host ('FAIL: SDD contracts: {0}: validation-execution' -f $script:validationStage) -ForegroundColor Red
    exit 1
}
