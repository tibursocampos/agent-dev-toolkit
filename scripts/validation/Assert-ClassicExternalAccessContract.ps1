#Requires -Version 5.1
<##
.SYNOPSIS
  Checks the Classic SDD external-access contract is wired end to end.
.DESCRIPTION
  Structural contract check only. It does not prove provider/runtime I/O enforcement.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Read-Contract {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    $path = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ("Missing contract file: {0}" -f $RelativePath) }
    return [System.IO.File]::ReadAllText($path)
}

function ConvertTo-ContractConceptText {
    param([Parameter(Mandatory = $true)][string] $Text)

    # Markdown markers, punctuation, casing, and layout are presentation. Keep
    # word boundaries while normalizing them so assertions test concepts.
    $normalized = $Text.ToLowerInvariant() -replace '[^\p{L}\p{N}]+', ' '
    return (($normalized -split '\s+' | Where-Object { $_ }) -join ' ')
}

function Assert-ContractConcepts {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string[]] $RequiredConcepts,
        [Parameter()][string[]] $ForbiddenConcepts = @()
    )

    $normalized = ConvertTo-ContractConceptText $Text
    $tokens = @($normalized -split ' ' | Where-Object { $_ })
    foreach ($concept in $RequiredConcepts) {
        $conceptTokens = @((ConvertTo-ContractConceptText $concept) -split ' ' | Where-Object { $_ })
        foreach ($token in $conceptTokens) {
            if ($tokens -notcontains $token) {
                throw ("{0}: required concept missing: {1}" -f $Name, $concept)
            }
        }
    }
    foreach ($concept in $ForbiddenConcepts) {
        $conceptTokens = @((ConvertTo-ContractConceptText $concept) -split ' ' | Where-Object { $_ })
        if (@($conceptTokens | Where-Object { $tokens -contains $_ }).Count -eq $conceptTokens.Count) {
            throw ("{0}: forbidden concept present: {1}" -f $Name, $concept)
        }
    }
}

try {
    $contract = Read-Contract 'core/skills/_shared/sdd-artifacts/CLASSIC-EXTERNAL-ACCESS.md'
    $spec = Read-Contract 'core/skills/sdd-spec/SKILL.md'
    $plan = Read-Contract 'core/skills/sdd-plan/SKILL.md'
    $develop = Read-Contract 'core/skills/sdd-develop/SKILL.md'
    $acquisition = Read-Contract 'core/skills/sdd-develop/references/plan-acquisition.md'
    $storage = Read-Contract 'core/skills/_shared/sdd-artifacts/STORAGE.md'

    Assert-ContractConcepts -Name 'portable-scope' -Text $contract -RequiredConcepts @(
        'CLASSIC-EXT-SCOPE',
        'external alias relative path',
        'inválido fora raiz workspace',
        'referências internas existentes aceitas',
        'CLASSIC-EXT-NO-ROOT',
        'não registre raiz física drive unc caminho absoluto',
        'CLASSIC-EXT-OPS',
        'read write operações'
    )

    Assert-ContractConcepts -Name 'spec-capture' -Text $spec -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'reject destination outside repository',
        'requested read write operations',
        'never infer wider grant'
    )

    Assert-ContractConcepts -Name 'plan-preservation-and-reapproval' -Text $plan -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'exact portable destination',
        'PRD approved read write operations',
        'fresh PRD content approval before approving PLAN'
    )

    Assert-ContractConcepts -Name 'develop-trusted-handoff' -Text $develop -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'trusted invocation context',
        'never copy map PRD PLAN receipt',
        'effective I O boundary enforce approved scope',
        'block before external access'
    )

    Assert-ContractConcepts -Name 'plan-acquisition-scope' -Text $acquisition -RequiredConcepts @(
        'CLASSIC-EXTERNAL-ACCESS.md',
        'accept alias root mapping trusted invocation context',
        'O3 files grant',
        'block before external access'
    )

    Assert-ContractConcepts -Name 'evidence-separation' -Text $contract -RequiredConcepts @(
        'CLASSIC-EXT-O3-EVIDENCE',
        'somente referência evidência',
        'nunca autorizam leitura escrita Classic'
    )
    Assert-ContractConcepts -Name 'storage-separation' -Text $storage -RequiredConcepts @(
        'Classic SDD implementation access is a separate contract',
        'does not grant Classic read write access'
    )

    # Normalization regression: prose formatting and capitalization may vary.
    Assert-ContractConcepts -Name 'normalization-regression' -Text '**EXTERNAL:** Alias / Relative-Path — READ, WRITE' -RequiredConcepts @(
        'external alias relative path', 'read write'
    )

    Write-Host 'Assert-ClassicExternalAccessContract: PASS (portable scope, propagation, reapproval, trusted mapping, O3 evidence separation)' -ForegroundColor Green
    exit 0
}
catch {
    Write-Host ('Assert-ClassicExternalAccessContract: FAIL - {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
