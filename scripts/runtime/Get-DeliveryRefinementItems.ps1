#Requires -Version 7.0
<#
.SYNOPSIS
  Read-only lister for the items of an integrated-delivery REFINEMENT.
.DESCRIPTION
  Prints one compact JSON line with the normative identity of the refinement and its items
  (id, title, body hash, superseded_by). With -Id only that item is listed. Exit codes: 0 ok,
  3 blocked (invalid path, missing file, grammar failure, unknown id), 1 invalid parameters or
  thrown error.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $RepoPath,
    [Parameter(Mandatory = $true)][string] $RefinementPath,
    [string] $Id = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')

function Exit-WithBlocked {
    param(
        [Parameter(Mandatory = $true)][string] $Reason,
        [Parameter(Mandatory = $true)][string] $Message
    )

    $report = [pscustomobject]@{ ok = $false; reason = $Reason; message = $Message }
    [Console]::Out.WriteLine(($report | ConvertTo-Json -Compress -Depth 5))
    exit 3
}

try {
    if (($Id.Length -gt 0) -and ($Id -cnotmatch '^(D|CA|R)-[0-9]{3,}$')) {
        throw 'Id must match ^(D|CA|R)-[0-9]{3,}$.'
    }

    $repoFull = [System.IO.Path]::GetFullPath($RepoPath)
    if (-not (Test-Path -LiteralPath $repoFull -PathType Container)) {
        throw 'RepoPath must be an existing directory.'
    }

    if ($RefinementPath -cnotmatch '^features/[0-9]{3}-[a-z0-9]+(?:-[a-z0-9]+)*/REFINEMENT\.md$') {
        Exit-WithBlocked -Reason 'refinement_reference_invalid' -Message 'RefinementPath must be the canonical features/NNN-slug/REFINEMENT.md with forward slashes.'
    }

    $full = $null
    try {
        $full = Get-SafeFullPath $repoFull $RefinementPath
        Assert-NoReparseAncestors $full $repoFull
    }
    catch {
        Exit-WithBlocked -Reason 'refinement_reference_unknown' -Message ('Refinement path escapes the repository or crosses a reparse point: {0}' -f $_.Exception.Message)
    }

    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Exit-WithBlocked -Reason 'refinement_reference_unknown' -Message ('Refinement {0} does not exist.' -f $RefinementPath)
    }

    $text = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    $blocks = Read-DeliveryBlocks -Text $text
    if (-not $blocks.Ok) {
        $blockCodes = @($blocks.Errors | ForEach-Object { [string]$_.code } | Select-Object -Unique)
        Exit-WithBlocked -Reason 'refinement_reference_invalid' -Message ('Refinement DELIVERY blocks do not parse: {0}.' -f ($blockCodes -join ', '))
    }

    $parsed = Get-DeliveryRefinementItems -Text $text
    $itemErrors = @($parsed.Errors)
    if ($itemErrors.Count -gt 0) {
        Exit-WithBlocked -Reason 'refinement_reference_invalid' -Message ('Refinement item grammar is invalid: {0}' -f [string]$itemErrors[0].message)
    }

    $identity = Get-DeliveryNormativeIdentity -Text $text
    $selected = @($parsed.Items)
    if ($Id.Length -gt 0) {
        $selected = @($parsed.Items | Where-Object { $_.Id -ceq $Id })
        if ($selected.Count -eq 0) {
            Exit-WithBlocked -Reason 'refinement_reference_unknown' -Message ('Refinement {0} has no item {1}.' -f $RefinementPath, $Id)
        }
    }

    $rows = @(foreach ($item in $selected) {
            [pscustomobject]@{
                id            = [string]$item.Id
                title         = [string]$item.Title
                hash          = [string]$item.Hash
                superseded_by = $(if (([string]$item.SupersededBy).Length -gt 0) { [string]$item.SupersededBy } else { $null })
            }
        })

    $report = [pscustomobject]@{ ok = $true; identity = $identity; items = [object[]]$rows }
    [Console]::Out.WriteLine(($report | ConvertTo-Json -Compress -Depth 5))
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
