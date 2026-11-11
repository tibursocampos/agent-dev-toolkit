#Requires -Version 5.1
<#
.SYNOPSIS
  Atomically replaces one operational JSON block in an integrated-delivery PLAN.
.DESCRIPTION
  This helper is limited to existing DELIVERY operational markers under
  RepoPath/features. It preserves all other bytes and requires the caller's
  hash of the previous block, so a stale concurrent state update fails closed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $RepoPath,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [Parameter(Mandatory = $true)][ValidatePattern('^(PROGRESS|CHECKPOINT|APPROVAL|STEP-[A-Za-z0-9-]+)$')][string] $Block,
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string] $ExpectedBlockHash,
    [Parameter(Mandatory = $true)][string] $PayloadJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Sha256([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '') }
    finally { $sha.Dispose() }
}

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
    $payloadText = $payload | ConvertTo-Json -Compress -Depth 30
    $originalBytes = [System.IO.File]::ReadAllBytes($file)
    $hasBom = $originalBytes.Length -ge 3 -and $originalBytes[0] -eq 0xEF -and $originalBytes[1] -eq 0xBB -and $originalBytes[2] -eq 0xBF
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $originalText = $encoding.GetString($originalBytes)
    if ($hasBom -and $originalText.StartsWith([string][char]0xFEFF)) { $originalText = $originalText.Substring(1) }
    if ($originalText.Contains([string][char]0xFFFD)) { throw 'plan_invalid_utf8' }
    $marker = [regex]::Escape($Block)
    $pattern = '(?ms)^<!-- DELIVERY:' + $marker + ':BEGIN -->\r?\n(.*?)\r?\n<!-- DELIVERY:' + $marker + ':END -->$'
    $matches = [regex]::Matches($originalText, $pattern)
    if ($matches.Count -ne 1) { throw 'block_missing_or_duplicate' }
    $oldPayload = $matches[0].Groups[1].Value
    if ((Get-Sha256 ([System.Text.Encoding]::UTF8.GetBytes($oldPayload))) -cne $ExpectedBlockHash.ToUpperInvariant()) {
        throw 'state_conflict'
    }
    $newText = $originalText.Substring(0, $matches[0].Groups[1].Index) + $payloadText + $originalText.Substring($matches[0].Groups[1].Index + $matches[0].Groups[1].Length)
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
