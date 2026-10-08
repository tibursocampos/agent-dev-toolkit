#Requires -Version 5.1
# Static contract checks for US02 CT1-CT6. Does not run a hook, publish, or write a home.
# Tests:
#   Should_RecordProviderOriginSchemaAndStatus_When_HookWasInvestigated
#   Should_KeepConfirmedContractNotes_When_NoPublisherWasAltered
#   Should_OmitCrossProviderHooks_When_StoryEvidenceIsRead
#   Should_LeaveSharedHelperUntouched_When_ClassificationSaysSo
#   Should_KeepPendingHypothesis_When_DeliveryEnds
#   Should_DeclareReadOnlyHome_When_ReportIsChecked
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path (Join-Path $scriptsRoot '_lib') 'Get-ToolkitRepoRoot.ps1'
$classificationRelative = 'features/012-multiprovider-toolkit-corrections/US02/ANALYSIS/hooks-classification.md'
$confirmedContractRelative = 'features/012-multiprovider-toolkit-corrections/US02/EVD/ca2-confirmed-contract.md'
$noCrossGenerationRelative = 'features/012-multiprovider-toolkit-corrections/US02/EVD/ca3-no-cross-generation.md'
$sharedHelperRelative = 'features/012-multiprovider-toolkit-corrections/US02/EVD/ca4-shared-helper.md'
$readOnlyInstallRelative = 'features/012-multiprovider-toolkit-corrections/US02/EVD/ca6-read-only-install.md'
$inventoryHeading = '## Inventário'
$pathHeading = '## Path por provider'
$installHeading = '## Instalação real'
$evidenceStatuses = @(
    'confirmado',
    'descartado',
    'comportamento do provider',
    'hipótese pendente'
)
$pendingHypothesisNeedles = @(
    'Não há parse de `settings.json`',
    'cwd` de runtime é `hipótese pendente`',
    'escape de aspas no path é `hipótese pendente`'
)
$adapterSourceExtensions = @('.ps1', '.json', '.js', '.yml', '.yaml')
$guardCommonRelative = 'adapters/_shared/GuardCommon.ps1'
$guardCommonSymbol = 'Get-ToolkitNormalizedRelativePath'
$secretMarkers = @('BEGIN PRIVATE KEY', 'AKIA', 'sk-', 'password=', 'api_key')
$readOnlyNeedles = @('Leitura apenas', 'publish', 'remoção', 'reparo', 'rollback')

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

function Assert-Includes {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Needle,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    if ($Text.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) {
        Write-Fail -TestName $TestName -Reason ("{0} Missing: {1}" -f $Reason, $Needle)
    }
}

function Get-RepoText {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )
    $fullPath = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Write-Fail -TestName $TestName -Reason ("missing {0}" -f $RelativePath)
    }
    return [System.IO.File]::ReadAllText($fullPath)
}

function Get-SectionBody {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $StartHeading,
        [Parameter(Mandatory = $true)][string] $EndHeading
    )
    $start = $Text.IndexOf($StartHeading, [System.StringComparison]::Ordinal)
    if ($start -lt 0) {
        Write-Fail -TestName $TestName -Reason ("missing heading {0}" -f $StartHeading)
    }
    $from = $start + $StartHeading.Length
    $end = $Text.IndexOf($EndHeading, $from, [System.StringComparison]::Ordinal)
    if ($end -lt 0) {
        Write-Fail -TestName $TestName -Reason ("missing heading {0}" -f $EndHeading)
    }
    return $Text.Substring($from, $end - $from)
}

function Get-TableRecords {
    param([Parameter(Mandatory = $true)][string] $Section)
    $records = New-Object 'System.Collections.Generic.List[object]'
    foreach ($line in [regex]::Split($Section, "\r?\n")) {
        $trim = $line.Trim()
        if ($trim.Length -eq 0 -or $trim.StartsWith('|') -eq $false) {
            continue
        }
        if ($trim.IndexOf('---', [System.StringComparison]::Ordinal) -ge 0) {
            continue
        }
        $escapedPipe = '<<PIPE>>'
        $normalized = $trim.Trim('|').Replace('\|', $escapedPipe)
        $cells = @($normalized.Split('|') | ForEach-Object { $_.Trim().Replace($escapedPipe, '|') })
        if ($cells.Count -lt 4 -or $cells[0] -eq 'Provider') {
            continue
        }
        [void]$records.Add([PSCustomObject]@{ Cells = $cells })
    }
    return $records
}

function Test-HasEvidenceStatus {
    param([Parameter(Mandatory = $true)][string] $Cell)
    foreach ($status in $evidenceStatuses) {
        if ($Cell.IndexOf($status, [System.StringComparison]::Ordinal) -ge 0) {
            return $true
        }
    }
    return $false
}

function Get-BacktickTokens {
    param([Parameter(Mandatory = $true)][string] $Text)
    $tokens = New-Object 'System.Collections.Generic.List[string]'
    foreach ($match in [regex]::Matches($Text, '`([^`]+)`')) {
        $token = $match.Groups[1].Value.Trim()
        if ($token.Length -eq 0 -or $token.Contains('...')) {
            continue
        }
        [void]$tokens.Add($token)
    }
    return @($tokens)
}

function Get-AdapterSlug {
    param([Parameter(Mandatory = $true)][string] $Provider)
    return $Provider.ToLowerInvariant()
}

function Get-AdapterSourceText {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Provider
    )
    $slug = Get-AdapterSlug -Provider $Provider
    $root = Join-Path $repoRoot (Join-Path 'adapters' $slug)
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Fail -TestName $TestName -Reason ("missing adapter directory adapters/{0}" -f $slug)
    }
    $builder = New-Object System.Text.StringBuilder
    foreach ($file in [System.IO.Directory]::EnumerateFiles($root, '*', [System.IO.SearchOption]::AllDirectories)) {
        $extension = [System.IO.Path]::GetExtension($file)
        $allowed = $false
        foreach ($candidate in $adapterSourceExtensions) {
            if ($extension.Equals($candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
                $allowed = $true
                break
            }
        }
        if (-not $allowed) {
            continue
        }
        [void]$builder.AppendLine([System.IO.File]::ReadAllText($file))
    }
    return $builder.ToString()
}

function Test-TokenIsRepoPath {
    param([Parameter(Mandatory = $true)][string] $Token)
    return $Token.StartsWith('adapters/')
}

function Assert-RecordedToken {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Provider,
        [Parameter(Mandatory = $true)][string] $Source,
        [Parameter(Mandatory = $true)][string] $Token,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    if (Test-TokenIsRepoPath -Token $Token) {
        $fullPath = Join-Path $repoRoot ($Token -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $fullPath)) {
            Write-Fail -TestName $TestName -Reason ("{0} Missing file: {1}" -f $Reason, $Token)
        }
        return
    }
    if ($Source.IndexOf($Token, [System.StringComparison]::Ordinal) -lt 0) {
        Write-Fail -TestName $TestName -Reason ("{0} Missing in adapters/{1}: {2}" -f $Reason, (Get-AdapterSlug -Provider $Provider), $Token)
    }
}

function Assert-TokensInAdapterSource {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Provider,
        [Parameter(Mandatory = $true)][string] $Source,
        [string[]] $Tokens = @(),
        [Parameter(Mandatory = $true)][string] $Reason
    )
    foreach ($token in $Tokens) {
        Assert-RecordedToken -TestName $TestName -Provider $Provider -Source $Source -Token $token -Reason $Reason
    }
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-HooksMultiproviderContractsPreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$classification = Get-RepoText -TestName 'Assert-HooksMultiproviderContractsPreconditions' -RelativePath $classificationRelative
$confirmedContract = Get-RepoText -TestName 'Assert-HooksMultiproviderContractsPreconditions' -RelativePath $confirmedContractRelative
$noCrossGeneration = Get-RepoText -TestName 'Assert-HooksMultiproviderContractsPreconditions' -RelativePath $noCrossGenerationRelative
$sharedHelper = Get-RepoText -TestName 'Assert-HooksMultiproviderContractsPreconditions' -RelativePath $sharedHelperRelative
$readOnlyInstall = Get-RepoText -TestName 'Assert-HooksMultiproviderContractsPreconditions' -RelativePath $readOnlyInstallRelative
$inventorySection = Get-SectionBody -TestName 'Assert-HooksMultiproviderContractsPreconditions' -Text $classification -StartHeading $inventoryHeading -EndHeading $pathHeading
$pathSection = Get-SectionBody -TestName 'Assert-HooksMultiproviderContractsPreconditions' -Text $classification -StartHeading $pathHeading -EndHeading $installHeading
$inventoryRecords = @(Get-TableRecords -Section $inventorySection)
$pathRecords = @(Get-TableRecords -Section $pathSection)

# --- Should_RecordProviderOriginSchemaAndStatus_When_HookWasInvestigated (CT1) ---
$ct1Name = 'Should_RecordProviderOriginSchemaAndStatus_When_HookWasInvestigated'
if ($inventoryRecords.Count -eq 0) {
    Write-Fail -TestName $ct1Name -Reason 'inventory has no investigated hooks'
}
foreach ($record in $inventoryRecords) {
    $provider = [string]$record.Cells[0]
    $origin = [string]$record.Cells[1]
    $schemaOrEvent = [string]$record.Cells[2]
    $status = [string]$record.Cells[4]
    if ([string]::IsNullOrWhiteSpace($provider) -or [string]::IsNullOrWhiteSpace($origin) -or [string]::IsNullOrWhiteSpace($schemaOrEvent)) {
        Write-Fail -TestName $ct1Name -Reason ("investigated hook is missing provider, origin, or schema/event: {0}" -f $provider)
    }
    if (-not (Test-HasEvidenceStatus -Cell $status)) {
        Write-Fail -TestName $ct1Name -Reason ("status is outside the four evidence statuses: {0}" -f $provider)
    }
    $adapterSource = Get-AdapterSourceText -TestName $ct1Name -Provider $provider
    $schemaTokens = @(Get-BacktickTokens -Text $schemaOrEvent)
    Assert-TokensInAdapterSource -TestName $ct1Name -Provider $provider -Source $adapterSource -Tokens $schemaTokens -Reason 'schema or event left the adapter source'
}
Write-Pass -TestName $ct1Name

# --- Should_KeepConfirmedContractNotes_When_NoPublisherWasAltered (CT2) ---
$ct2Name = 'Should_KeepConfirmedContractNotes_When_NoPublisherWasAltered'
Assert-Includes -TestName $ct2Name -Text $classification -Needle 'autoria ou contrato lido na fonte' -Reason 'confirmado means source authorship'
Assert-Includes -TestName $ct2Name -Text $classification -Needle 'Não é um defeito de publisher' -Reason 'confirmado is not a publisher defect'
Assert-Includes -TestName $ct2Name -Text $confirmedContract -Needle 'Nenhum publisher, template, asset ou helper foi alterado' -Reason 'S2 did not alter a publisher'
Assert-Includes -TestName $ct2Name -Text $confirmedContract -Needle 'não há destino de fixture' -Reason 'there is no altered-publisher fixture to generate'
Assert-Includes -TestName $ct2Name -Text $classification -Needle 'pwsh -NoProfile -File' -Reason 'confirmed command note is present'
Assert-Includes -TestName $ct2Name -Text $classification -Needle 'session_start.ps1' -Reason 'confirmed script note is present'
Assert-Includes -TestName $ct2Name -Text $pathSection -Needle 'cwd' -Reason 'confirmed cwd notes are present'
foreach ($record in $inventoryRecords) {
    $status = [string]$record.Cells[4]
    if ($status.IndexOf('confirmado', [System.StringComparison]::Ordinal) -lt 0) {
        continue
    }
    $provider = [string]$record.Cells[0]
    $pathRecord = $pathRecords | Where-Object { [string]$_.Cells[0] -eq $provider } | Select-Object -First 1
    if ($null -eq $pathRecord -or [string]::IsNullOrWhiteSpace([string]$pathRecord.Cells[1])) {
        Write-Fail -TestName $ct2Name -Reason ("confirmed provider is missing a cwd note: {0}" -f $provider)
    }
    $adapterSource = Get-AdapterSourceText -TestName $ct2Name -Provider $provider
    $cwdTokens = @(Get-BacktickTokens -Text ([string]$pathRecord.Cells[1]))
    $commandTokens = @(Get-BacktickTokens -Text ([string]$record.Cells[3]))
    Assert-TokensInAdapterSource -TestName $ct2Name -Provider $provider -Source $adapterSource -Tokens $cwdTokens -Reason 'recorded cwd left the adapter source'
    Assert-TokensInAdapterSource -TestName $ct2Name -Provider $provider -Source $adapterSource -Tokens $commandTokens -Reason 'recorded command left the adapter source'
}
Write-Pass -TestName $ct2Name

# --- Should_OmitCrossProviderHooks_When_StoryEvidenceIsRead (CT3) ---
$ct3Name = 'Should_OmitCrossProviderHooks_When_StoryEvidenceIsRead'
Assert-Includes -TestName $ct3Name -Text $noCrossGeneration -Needle 'Não há geração de hook de outro provider' -Reason 'this story did not generate a cross-provider hook'
Assert-Includes -TestName $ct3Name -Text $noCrossGeneration -Needle 'nenhuma fixture cruzada' -Reason 'this story did not publish a cross-provider fixture'
Write-Pass -TestName $ct3Name

# --- Should_LeaveSharedHelperUntouched_When_ClassificationSaysSo (CT4) ---
$ct4Name = 'Should_LeaveSharedHelperUntouched_When_ClassificationSaysSo'
Assert-Includes -TestName $ct4Name -Text $classification -Needle 'adapters/_shared/GuardCommon.ps1` permanece intacto' -Reason 'classification says the shared helper stayed intact'
Assert-Includes -TestName $ct4Name -Text $sharedHelper -Needle 'Este passo não alterou `adapters/_shared/GuardCommon.ps1`' -Reason 'EVD ca4 says this story did not change the shared helper'
$guardCommonText = Get-RepoText -TestName $ct4Name -RelativePath $guardCommonRelative
Assert-Includes -TestName $ct4Name -Text $guardCommonText -Needle $guardCommonSymbol -Reason 'shared helper no longer defines the cited path function'
Write-Pass -TestName $ct4Name

# --- Should_KeepPendingHypothesis_When_DeliveryEnds (CT5) ---
$ct5Name = 'Should_KeepPendingHypothesis_When_DeliveryEnds'
foreach ($needle in $pendingHypothesisNeedles) {
    Assert-Includes -TestName $ct5Name -Text $classification -Needle $needle -Reason 'pending hypothesis entry is missing'
}
Assert-Includes -TestName $ct5Name -Text $noCrossGeneration -Needle 'não foi apagada, convertida' -Reason 'pending hypothesis was not removed or converted'
if ([regex]::IsMatch($classification, 'hipótese pendente[\s\S]{0,60}(removid|apagad|convertid)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
    Write-Fail -TestName $ct5Name -Reason 'a hipótese pendente entry was removed or converted'
}
Write-Pass -TestName $ct5Name

# --- Should_DeclareReadOnlyHome_When_ReportIsChecked (CT6) ---
$ct6Name = 'Should_DeclareReadOnlyHome_When_ReportIsChecked'
foreach ($needle in $readOnlyNeedles) {
    Assert-Includes -TestName $ct6Name -Text $readOnlyInstall -Needle $needle -Reason 'EVD ca6 must declare the read-only install'
}
foreach ($marker in $secretMarkers) {
    if ($readOnlyInstall.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Write-Fail -TestName $ct6Name -Reason 'EVD ca6 contains a secret marker'
    }
}
Write-Pass -TestName $ct6Name
