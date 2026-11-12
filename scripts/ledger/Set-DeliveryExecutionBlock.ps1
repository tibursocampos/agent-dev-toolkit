#Requires -Version 5.1
<#
.SYNOPSIS
  Atomically replaces one operational JSON block in an integrated-delivery PLAN.
.DESCRIPTION
  This helper is limited to existing DELIVERY operational markers under
  RepoPath/features. It preserves all other bytes and requires the caller's
  hash of the current block payload, so a stale concurrent state update fails
  closed. Blocks are located and hashed with scripts/_lib/DeliveryGrammar.ps1.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $RepoPath,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [Parameter(Mandatory = $true)][ValidatePattern('^(PROGRESS|CHECKPOINT|APPROVAL|STEP:[A-Za-z0-9][A-Za-z0-9._-]*)$')][string] $Block,
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string] $ExpectedBlockHash,
    [Parameter(Mandatory = $true)][string] $PayloadJson,
    [switch] $AsLibrary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libDir = Join-Path (Split-Path -Parent $PSScriptRoot) '_lib'
. (Join-Path $libDir 'DeliveryGrammar.ps1')
. (Join-Path $libDir 'DeliveryAtomicWrite.ps1')

function Write-Result([bool]$Ok, [string]$Code, [bool]$Written) {
    $result = [pscustomobject]@{ ok = $Ok; code = $Code; written = $Written }
    if ($AsLibrary) { return $result }
    return $result | ConvertTo-Json -Compress
}

function ConvertTo-RepoRelativePath([string]$FullPath) {
    if ([string]::IsNullOrEmpty($FullPath)) { return '' }
    return $FullPath.Substring($repo.Length + 1).Replace('\', '/')
}

function Assert-BaselineBeforeStepStart {
    param(
        [Parameter(Mandatory = $true)][object] $StepJson,
        [Parameter(Mandatory = $true)][string] $StepId,
        [Parameter(Mandatory = $true)][object[]] $Blocks
    )

    $checkpointBlock = @($Blocks | Where-Object { $_.Type -ceq 'CHECKPOINT' })
    if ($checkpointBlock.Count -ne 1) { throw 'baseline_missing' }
    $baselineProperty = Get-DeliveryExactProperty -Object $checkpointBlock[0].Json -Name 'baseline_evidence'
    if ($null -eq $baselineProperty -or $baselineProperty.Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$baselineProperty.Value)) { throw 'baseline_missing' }
    $baselineReference = [string]$baselineProperty.Value
    $separator = $baselineReference.IndexOf('/')
    if ($separator -le 0 -or $separator -eq ($baselineReference.Length - 1) -or
        $baselineReference.Substring(0, $separator) -cne $StepId -or $baselineReference.IndexOf('/', $separator + 1) -ge 0) {
        throw 'baseline_ref_invalid'
    }
    $baselineName = $baselineReference.Substring($separator + 1)
    $refsProperty = Get-DeliveryExactProperty -Object $StepJson -Name 'evidence_refs'
    if ($null -eq $refsProperty -or $refsProperty.Value -isnot [System.Array]) { throw 'baseline_missing' }
    $matches = @($refsProperty.Value | Where-Object {
        $name = Get-DeliveryExactProperty -Object $_ -Name 'name'
        $null -ne $name -and $name.Value -is [string] -and [string]$name.Value -ceq $baselineName
    })
    if ($matches.Count -ne 1) { throw 'baseline_missing' }
    $pathProperty = Get-DeliveryExactProperty -Object $matches[0] -Name 'path'
    $hashProperty = Get-DeliveryExactProperty -Object $matches[0] -Name 'sha256'
    if ($null -eq $pathProperty -or $pathProperty.Value -isnot [string] -or
        $null -eq $hashProperty -or $hashProperty.Value -isnot [string] -or
        [string]$hashProperty.Value -cnotmatch '^[A-F0-9]{64}$') { throw 'baseline_ref_invalid' }

    $planRelative = ConvertTo-RepoRelativePath $file
    if ($planRelative -cnotmatch '^(features/[^/]+/[^/]+)/PLAN\.md$') { throw 'baseline_ref_invalid' }
    $expectedPrefix = $Matches[1] + '/evidence/'
    $evidencePath = [string]$pathProperty.Value
    $expectedFilePrefix = $StepId + '--' + $baselineName + '.'
    if ($evidencePath -cnotmatch ('^' + [regex]::Escape($expectedPrefix) + '[^/]+$') -or
        -not [IO.Path]::GetFileName($evidencePath).StartsWith($expectedFilePrefix, [StringComparison]::Ordinal)) {
        throw 'baseline_ref_invalid'
    }
    $fullPath = [IO.Path]::GetFullPath((Join-Path $repo ($evidencePath.Replace('/', [IO.Path]::DirectorySeparatorChar))))
    $repoPrefix = $repo.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'baseline_ref_invalid' }
    $walk = $repo
    foreach ($segment in $evidencePath.Split('/')) {
        $walk = [IO.Path]::Combine($walk, $segment)
        try { $attributes = [IO.File]::GetAttributes($walk) } catch { throw 'baseline_missing' }
        if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'baseline_ref_invalid' }
    }
    if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) { throw 'baseline_missing' }
    $bytes = [IO.File]::ReadAllBytes($fullPath)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $actualHash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '') }
    finally { $sha.Dispose() }
    if ($actualHash -cne [string]$hashProperty.Value) { throw 'baseline_changed' }
}

try {
    $repo = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RepoPath).Path).TrimEnd('\', '/')
    $features = [System.IO.Path]::GetFullPath((Join-Path $repo 'features')).TrimEnd('\', '/')
    $file = [System.IO.Path]::GetFullPath($PlanPath)
    if (-not $file.StartsWith($features + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
        [System.IO.Path]::GetFileName($file).Contains(':')) { throw 'path_outside_features' }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw 'plan_missing' }

    $current = $file
    while ($current.StartsWith($features, [System.StringComparison]::OrdinalIgnoreCase)) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'path_reparse_point' }
        if ($current -ieq $features) { break }
        $current = Split-Path -Parent $current
    }

    $payload = $PayloadJson | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $payload -or $payload -is [System.Array] -or $payload -is [string]) { throw 'payload_must_be_json_object' }
    # The caller's own text is spliced as-is so timestamps and other values are not re-serialized.
    $payloadText = $PayloadJson.Trim()
    if ($payloadText.IndexOfAny([char[]]@([char]13, [char]10)) -ge 0) { throw 'invalid_payload' }
    $originalBytes = [System.IO.File]::ReadAllBytes($file)
    $hasBom = $originalBytes.Length -ge 3 -and $originalBytes[0] -eq 0xEF -and $originalBytes[1] -eq 0xBB -and $originalBytes[2] -eq 0xBF
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $originalText = $encoding.GetString($originalBytes)
    if ($hasBom -and $originalText.StartsWith([string][char]0xFEFF)) { $originalText = $originalText.Substring(1) }
    if ($originalText.Contains([string][char]0xFFFD)) { throw 'plan_invalid_utf8' }

    $parsed = Read-DeliveryBlocks -Text $originalText
    if (-not $parsed.Ok) { throw 'plan_grammar_invalid' }

    if ($Block.StartsWith('STEP:', [System.StringComparison]::Ordinal)) {
        $blockType = 'STEP'
        $blockId = $Block.Substring('STEP:'.Length)
    }
    else {
        $blockType = $Block
        $blockId = $null
    }
    $found = @($parsed.Blocks | Where-Object { ($_.Type -ceq $blockType) -and (([string]$_.Id) -ceq ([string]$blockId)) })
    if ($found.Count -ne 1) { throw 'block_missing' }
    $target = $found[0]

    if ($blockType -ceq 'STEP' -and $null -ne (Get-DeliveryExactProperty -Object $payload -Name 'status') -and
        [string]$payload.status -ceq 'IN_PROGRESS') {
        Assert-BaselineBeforeStepStart -StepJson $payload -StepId $blockId -Blocks @($parsed.Blocks)
    }

    if ((Get-DeliveryBlockHash -Payload $target.Payload) -cne $ExpectedBlockHash.ToUpperInvariant()) {
        throw 'state_conflict'
    }

    # Replace only the payload lines of the located block; terminators and all other lines are kept.
    $segments = [regex]::Split($originalText, '(\r\n|\r|\n)')
    $lineCount = [int](($segments.Length + 1) / 2)
    $payloadFirst = [int]$target.StartLine
    $payloadLast = [int]$target.EndLine - 2
    $payloadTerminator = $segments[(2 * $payloadLast) + 1]
    $rebuilt = New-Object System.Text.StringBuilder
    for ($index = 0; $index -lt $payloadFirst; $index++) {
        [void]$rebuilt.Append($segments[2 * $index]).Append($segments[(2 * $index) + 1])
    }
    [void]$rebuilt.Append($payloadText).Append($payloadTerminator)
    for ($index = [int]$target.EndLine - 1; $index -lt $lineCount; $index++) {
        [void]$rebuilt.Append($segments[2 * $index])
        if ($index -lt ($lineCount - 1)) { [void]$rebuilt.Append($segments[(2 * $index) + 1]) }
    }
    $newText = $rebuilt.ToString()

    $newParsed = Read-DeliveryBlocks -Text $newText
    if (-not $newParsed.Ok) { throw 'invalid_payload' }
    if ((Get-DeliveryNormativeIdentity -Text $newText) -cne (Get-DeliveryNormativeIdentity -Text $originalText)) {
        throw 'identity_changed'
    }

    $newBytes = $encoding.GetBytes($newText)
    if ($hasBom) { $newBytes = [byte[]](@(0xEF, 0xBB, 0xBF) + $newBytes) }
    $replace = Invoke-DeliveryAtomicReplace -Path $file -NewBytes $newBytes -ExpectedOldBytes $originalBytes
    if ($replace.Status -ceq 'restore_failed') {
        $result = [pscustomobject]@{ ok = $false; code = 'state_restore_failed'; written = $false; backup_path = (ConvertTo-RepoRelativePath $replace.BackupPath); conflict_path = (ConvertTo-RepoRelativePath $replace.ConflictPath) }
        if ($AsLibrary) { return $result }
        $result | ConvertTo-Json -Compress
        exit 1
    }
    if ($replace.Status -ceq 'conflict') {
        $result = [pscustomobject]@{ ok = $false; code = 'state_conflict'; written = $false; conflict_path = (ConvertTo-RepoRelativePath $replace.ConflictPath) }
        if ($AsLibrary) { return $result }
        $result | ConvertTo-Json -Compress
        exit 1
    }
    Write-Result $true 'written_and_verified' $true
}
catch {
    $code = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($code)) { $code = 'state_write_failed' }
    if ($AsLibrary) { return [pscustomobject]@{ ok = $false; code = $code; written = $false } }
    Write-Result $false $code $false
    exit 1
}
