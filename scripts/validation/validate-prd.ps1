#Requires -Version 5.1
<#
.SYNOPSIS
  Structural validation for Classic SDD PRD markdown (REQ-003 / CA2).

.DESCRIPTION
  Deterministic structural checks against the canonical PRD template — no LLM.
  Required template sections must be present. Conditional and optional sections
  are checked only when their documented trigger/content is present.

.PARAMETER Path
  Absolute or relative path to a PRD .md file.

.EXAMPLE
  .\scripts\validation\validate-prd.ps1 -Path features\005-x\US01\PRD\005_x.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$scriptsRoot = Split-Path -Parent $scriptDir
$libDir = Join-Path $scriptsRoot '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')

function Write-ValidateFail {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-prd: FAIL - {0}" -f $Message) -ForegroundColor Red
}

function Write-ValidatePass {
    param([Parameter(Mandatory = $true)][string] $Message)
    Write-Host ("validate-prd: PASS - {0}" -f $Message) -ForegroundColor Green
}

$resolved = $Path
if (-not [System.IO.Path]::IsPathRooted($resolved)) {
    $resolved = Join-Path (Get-Location).Path $Path
}

if (-not (Test-Path -LiteralPath $resolved)) {
    Write-ValidateFail -Message ("file not found: {0}" -f $Path)
    exit 1
}

$item = Get-Item -LiteralPath $resolved
if ($item.Length -le 0) {
    Write-ValidateFail -Message ("empty file: {0}" -f $resolved)
    exit 1
}

$text = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-ValidateFail -Message ("empty content: {0}" -f $resolved)
    exit 1
}

$reqPattern = $script:ToolkitConstant.SddArtifactReqIdPattern
$acPattern = $script:ToolkitConstant.SddArtifactAcceptancePattern

$reqMatches = [regex]::Matches($text, $reqPattern)
$reqIds = @(
    $reqMatches |
        ForEach-Object { ('REQ-{0}' -f $_.Groups[1].Value.ToUpperInvariant()) } |
        Select-Object -Unique
)

$acMatches = [regex]::Matches($text, $acPattern)

$sectionChecks = @(
    @{ Label = 'PRD title'; Pattern = '(?im)^#\s+PRD:\s*\S+' },
    @{ Label = 'metadata table'; Pattern = '(?im)^\|\s*(Campo|Field)\s*\|\s*(Valor|Value)\s*\|' },
    @{ Label = 'metadata sequence'; Pattern = '(?im)^\|\s*\*{0,2}(Sequência|Sequence)\*{0,2}\s*\|' },
    @{ Label = 'metadata status'; Pattern = '(?im)^\|\s*\*{0,2}(Status)\*{0,2}\s*\|' },
    @{ Label = 'metadata priority'; Pattern = '(?im)^\|\s*\*{0,2}(Prioridade|Priority)\*{0,2}\s*\|' },
    @{ Label = 'metadata complexity'; Pattern = '(?im)^\|\s*\*{0,2}(Complexidade|Complexity)\*{0,2}\s*\|' },
    @{ Label = 'metadata repository'; Pattern = '(?im)^\|\s*\*{0,2}(Repositório|Repository)\*{0,2}\s*\|' },
    @{ Label = 'metadata stack'; Pattern = '(?im)^\|\s*\*{0,2}Stack\*{0,2}\s*\|' },
    @{ Label = 'Execution policy'; Pattern = $script:ToolkitConstant.SddArtifactPrdExecutionPolicyPattern },
    @{ Label = 'Related navigation section'; Pattern = '(?im)^##\s+Related\s*$' },
    @{ Label = 'overview section'; Pattern = '(?im)^##\s+1\.\s+(Visão geral|Overview)\s*$' },
    @{ Label = 'context subsection'; Pattern = '(?im)^###\s+1\.1\s+(Contexto|Context)\s*$' },
    @{ Label = 'objective subsection'; Pattern = '(?im)^###\s+1\.2\s+(Objetivo|Objective)\s*$' },
    @{ Label = 'acceptance criteria section'; Pattern = $script:ToolkitConstant.SddArtifactPrdAcceptanceSectionPattern },
    @{ Label = 'technical scope section'; Pattern = '(?im)^##\s+3\.\s+(Escopo técnico \(alto nível\)|Technical scope \(high level\))\s*$' },
    @{ Label = 'technical scope components subsection'; Pattern = '(?im)^###\s+3\.1\s+' },
    @{ Label = 'technical scope new components subsection'; Pattern = '(?im)^###\s+3\.2\s+' },
    @{ Label = 'technical scope reuse subsection'; Pattern = '(?im)^###\s+3\.3\s+' },
    @{ Label = 'technical scope data flow subsection'; Pattern = '(?im)^###\s+3\.4\s+' },
    @{ Label = 'requirements section'; Pattern = $script:ToolkitConstant.SddArtifactPrdRequirementsSectionPattern },
    @{ Label = 'functional requirements subsection'; Pattern = '(?im)^###\s+4\.1\s+' },
    @{ Label = 'non-functional requirements subsection'; Pattern = '(?im)^###\s+4\.2\s+' },
    @{ Label = 'MoSCoW subsection'; Pattern = '(?im)^###\s+4\.3\s+' },
    @{ Label = 'business rules subsection'; Pattern = '(?im)^###\s+4\.4\s+' },
    @{ Label = 'out-of-scope section'; Pattern = $script:ToolkitConstant.SddArtifactPrdOosSectionPattern },
    @{ Label = 'error handling section'; Pattern = '(?im)^##\s+8\.\s+(Tratamento de erros|Error handling)\s*$' },
    @{ Label = 'use cases section'; Pattern = '(?im)^##\s+9\.\s+(Casos de uso|Use cases)\s*$' },
    @{ Label = 'use case block'; Pattern = '(?im)^###\s+CU\d+\s+' },
    @{ Label = 'test scenarios section'; Pattern = '(?im)^##\s+10\.\s+(Cenários de teste|Test scenarios)\s*$' },
    @{ Label = 'definition of done section'; Pattern = '(?im)^##\s+11\.\s+(Definição de pronto|Definition of done)\s*$' },
    @{ Label = 'next steps section'; Pattern = '(?im)^##\s+12\.\s+(Próximos passos|Next steps)\s*$' },
    @{ Label = 'references section'; Pattern = '(?im)^##\s+13\.\s+(Referências|References)\s*$' },
    @{ Label = 'change history section'; Pattern = '(?im)^##\s+14\.\s+(Histórico de alterações|Change history)\s*$' }
)

$failures = [System.Collections.Generic.List[string]]::new()
if ($reqIds.Count -lt 1) {
    $failures.Add('missing REQ-NNN identifiers (expected at least one REQ-001 style id)')
}
if ($acMatches.Count -lt 1) {
    $failures.Add('missing acceptance criteria headings (expected ### CAn / ## CAn)')
}
foreach ($sectionCheck in $sectionChecks) {
    if ($text -notmatch $sectionCheck.Pattern) {
        $failures.Add(('missing required section: {0}' -f $sectionCheck.Label))
    }
}

# Metrics, blast radius, migrations, integrations, EARS, and open questions are
# optional/applicability-driven in the template. Do not infer their requirement
# from mentions elsewhere in prose.
# An HTTP method + route or an /api/ route identifies an actual endpoint and
# requires the observable API contract subsection. Other integrations do not.
if ($text -match '(?im)\b(GET|POST|PUT|PATCH|DELETE)\s+/[A-Za-z0-9_./{}:-]+|/api/[A-Za-z0-9_./{}:-]+' -and
    $text -notmatch '(?im)^###\s+7\.3\s+(Contrato observável de API|Observable API contract)\b') {
    $failures.Add('missing applicable section: observable API contract (an API route is described)')
}
if ($text -match '(?im)\b(GET|POST|PUT|PATCH|DELETE)\s+/[A-Za-z0-9_./{}:-]+|/api/[A-Za-z0-9_./{}:-]+' -and
    $text -notmatch '(?im)^##\s+7\.\s+(Integrações|Integrations)') {
    $failures.Add('missing applicable section: integrations (an API route is described)')
}

# Related rows are optional when siblings are unavailable; if rows are given,
# require portable feature paths and reject machine-local absolute paths.
if ($text -match '(?im)^##\s+Related\s*$') {
    $relatedText = [regex]::Match($text, '(?ims)^##\s+Related\s*\r?\n(.*?)(?=^##\s|\z)').Groups[1].Value
    if ($relatedText -match '(?i)([A-Z]:\\|/Users/|/home/|file://)') {
        $failures.Add('Related links must use portable paths')
    }
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-ValidateFail -Message $f
    }
    exit 1
}

Write-ValidatePass -Message ("{0} REQ id(s), {1} CA heading(s)" -f $reqIds.Count, $acMatches.Count)
exit 0
