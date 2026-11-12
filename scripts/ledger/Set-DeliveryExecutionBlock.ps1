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
    [Parameter(Mandatory = $true)][string] $PayloadJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libDir = Join-Path (Split-Path -Parent $PSScriptRoot) '_lib'
. (Join-Path $libDir 'DeliveryGrammar.ps1')

function Write-Result([bool]$Ok, [string]$Code, [bool]$Written) {
    [pscustomobject]@{ ok = $Ok; code = $Code; written = $Written } | ConvertTo-Json -Compress
}

$temp = ''
$backup = ''
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
    $directory = Split-Path -Parent $file
    $temp = Join-Path $directory ('.delivery-state.' + [Guid]::NewGuid().ToString('N') + '.tmp')
    $backup = Join-Path $directory ('.delivery-state.' + [Guid]::NewGuid().ToString('N') + '.bak')
    [System.IO.File]::WriteAllBytes($temp, $newBytes)

    # The displaced bytes reveal a concurrent edit between read and replacement.
    [System.IO.File]::Replace($temp, $file, $backup)
    $displaced = [System.IO.File]::ReadAllBytes($backup)
    $readback = [System.IO.File]::ReadAllBytes($file)
    if ([Convert]::ToBase64String($displaced) -cne [Convert]::ToBase64String($originalBytes) -or
        [Convert]::ToBase64String($readback) -cne [Convert]::ToBase64String($newBytes)) {
        $restore = Join-Path $directory ('.delivery-state.' + [Guid]::NewGuid().ToString('N') + '.restore')
        $unexpected = Join-Path $directory ('.delivery-state.' + [Guid]::NewGuid().ToString('N') + '.new')
        [System.IO.File]::Copy($backup, $restore, $true)
        [System.IO.File]::Replace($restore, $file, $unexpected)
        Remove-Item -LiteralPath $unexpected -Force -ErrorAction SilentlyContinue
        throw 'state_conflict_or_readback_failed_restored'
    }
    Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
    $backup = ''
    Write-Result $true 'written_and_verified' $true
}
catch {
    $code = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($code)) { $code = 'state_write_failed' }
    Write-Result $false $code $false
    exit 1
}
finally {
    foreach ($path in @($temp, $backup)) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}
