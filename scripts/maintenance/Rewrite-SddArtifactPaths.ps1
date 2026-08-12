#Requires -Version 5.1
<#
.SYNOPSIS
  Rewrites absolute SDD artifact paths under a live SDD tree to InstallRoot-relative `sdd/` paths.

.DESCRIPTION
  Recursively scans *.md under -Root (default: $env:USERPROFILE\.cursor\sdd) and replaces
  absolute user-home paths and tilde-home embeds (~/.cursor/sdd, ~/.claude/sdd, slash or
  backslash) that point at the SDD tree with portable InstallRoot-relative paths
  (sdd/<repo-id>/...). Does not rewrite .cursor/plans, .cursor/skills, or .claude/skills
  cites. UTF-8 encoding is preserved; files are written only when content changes.

.PARAMETER Root
  Absolute path to the SDD tree root (the folder that contains <repo-id>/features/...).

.PARAMETER WhatIf
  Dry-run: report scanned/changed counts and sample replacements without writing files.

.EXAMPLE
  .\scripts\maintenance\Rewrite-SddArtifactPaths.ps1 -WhatIf

.EXAMPLE
  .\scripts\maintenance\Rewrite-SddArtifactPaths.ps1 -Root "$env:USERPROFILE\.cursor\sdd"
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $Root = (Join-Path $env:USERPROFILE '.cursor\sdd'),

    [Parameter()]
    [switch] $WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RewriteSddConstant = @{
    MarkdownGlob              = '*.md'
    PortableSddPrefix         = 'sdd/'
    MaxWhatIfSamples          = 25
    Utf8Bom0                  = 0xEF
    Utf8Bom1                  = 0xBB
    Utf8Bom2                  = 0xBF
    # Absolute and tilde-home SDD roots only (.cursor/sdd or .claude/sdd). Plans/skills trees
    # are excluded by requiring the sdd segment immediately after the IDE home folder.
    AbsoluteSddPathPattern    = '(?i)(?:[A-Za-z]:)?[/\\]+Users[/\\][^/\\]+[/\\]\.(?:cursor|claude)[/\\]sdd[/\\]([^\s`"''\)\|\]]*)'
    TildeSddPathPattern       = '(?i)~[/\\]+\.(?:cursor|claude)[/\\]sdd[/\\]([^\s`"''\)\|\]]*)'
}

$script:RewriteSddMessage = @{
    RootRequired     = 'Root is required.'
    RootMissing      = 'SDD root not found: {0}'
    ModeWhatIf       = 'Mode: WhatIf (dry-run; no files will be written).'
    ModeApply        = 'Mode: Apply (files with changes will be written).'
    Summary          = 'Files scanned: {0}; files changed: {1}; replacements: {2}'
    SampleHeader     = 'Sample replacements (up to {0}):'
    SampleLine       = '  {0}'
    SampleBefore     = '    before: {0}'
    SampleAfter      = '    after:  {0}'
    NoChanges        = 'No absolute SDD path replacements needed.'
    DoneWhatIf       = 'Dry-run complete.'
    DoneApply        = 'Apply complete.'
}

function Test-Utf8BomPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]] $Bytes
    )

    return (
        $Bytes.Length -ge 3 -and
        $Bytes[0] -eq $script:RewriteSddConstant.Utf8Bom0 -and
        $Bytes[1] -eq $script:RewriteSddConstant.Utf8Bom1 -and
        $Bytes[2] -eq $script:RewriteSddConstant.Utf8Bom2
    )
}

function Read-MarkdownUtf8 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = Test-Utf8BomPresent -Bytes $bytes
    $encoding = New-Object System.Text.UTF8Encoding $false
    $text = $encoding.GetString($bytes)
    if ($hasBom -and $text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
        $text = $text.Substring(1)
    }

    return [pscustomobject]@{
        Text   = $text
        HasBom = $hasBom
    }
}

function Write-MarkdownUtf8 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Content,

        [Parameter(Mandatory = $true)]
        [bool] $WithBom
    )

    $encoding = New-Object System.Text.UTF8Encoding $WithBom
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function ConvertTo-PortableSddPathMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Text.RegularExpressions.Match] $Match
    )

    $remainder = $Match.Groups[1].Value
    if (-not [string]::IsNullOrEmpty($remainder)) {
        $remainder = $remainder.Replace('\', '/')
    }

    return ($script:RewriteSddConstant.PortableSddPrefix + $remainder)
}

function Invoke-SddArtifactPathRewrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    $patterns = @(
        $script:RewriteSddConstant.AbsoluteSddPathPattern
        $script:RewriteSddConstant.TildeSddPathPattern
    )
    $replacementCount = 0
    $samples = New-Object System.Collections.Generic.List[object]

    $evaluator = {
        param([System.Text.RegularExpressions.Match] $m)

        $after = ConvertTo-PortableSddPathMatch -Match $m
        $script:replacementCountLocal++
        if ($script:samplesLocal.Count -lt [int]$script:RewriteSddConstant.MaxWhatIfSamples) {
            $script:samplesLocal.Add([pscustomobject]@{
                    Before = $m.Value
                    After  = $after
                }) | Out-Null
        }
        return $after
    }

    # ScriptBlock MatchEvaluator needs mutable counters in script scope for PS 5.1
    $script:replacementCountLocal = 0
    $script:samplesLocal = New-Object System.Collections.Generic.List[object]

    $newContent = $Content
    foreach ($pattern in $patterns) {
        $newContent = [regex]::Replace($newContent, $pattern, $evaluator)
    }

    $replacementCount = [int]$script:replacementCountLocal
    foreach ($sample in $script:samplesLocal) {
        $samples.Add($sample) | Out-Null
    }

    return [pscustomobject]@{
        Content           = $newContent
        ReplacementCount  = $replacementCount
        Samples           = $samples
        Changed           = ($replacementCount -gt 0 -and $newContent -cne $Content)
    }
}

if ([string]::IsNullOrWhiteSpace($Root)) {
    throw $script:RewriteSddMessage.RootRequired
}

$resolvedRoot = $Root
if (-not [System.IO.Path]::IsPathRooted($resolvedRoot)) {
    $resolvedRoot = Join-Path (Get-Location).Path $resolvedRoot
}
$resolvedRoot = [System.IO.Path]::GetFullPath($resolvedRoot)

if (-not (Test-Path -LiteralPath $resolvedRoot)) {
    throw ($script:RewriteSddMessage.RootMissing -f $resolvedRoot)
}

if ($WhatIf.IsPresent) {
    Write-Host $script:RewriteSddMessage.ModeWhatIf
}
else {
    Write-Host $script:RewriteSddMessage.ModeApply
}

Write-Host ("Root: {0}" -f $resolvedRoot)

$markdownFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Filter $script:RewriteSddConstant.MarkdownGlob)
$filesScanned = $markdownFiles.Count
$filesChanged = 0
$totalReplacements = 0
$reportSamples = New-Object System.Collections.Generic.List[object]

foreach ($file in $markdownFiles) {
    $read = Read-MarkdownUtf8 -Path $file.FullName
    $rewrite = Invoke-SddArtifactPathRewrite -Content $read.Text
    if (-not $rewrite.Changed) {
        continue
    }

    $filesChanged++
    $totalReplacements += [int]$rewrite.ReplacementCount

    if ($reportSamples.Count -lt [int]$script:RewriteSddConstant.MaxWhatIfSamples) {
        $rel = $file.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/')
        foreach ($sample in $rewrite.Samples) {
            if ($reportSamples.Count -ge [int]$script:RewriteSddConstant.MaxWhatIfSamples) {
                break
            }
            $reportSamples.Add([pscustomobject]@{
                    File   = $rel
                    Before = $sample.Before
                    After  = $sample.After
                }) | Out-Null
        }
    }

    if (-not $WhatIf.IsPresent) {
        Write-MarkdownUtf8 -Path $file.FullName -Content $rewrite.Content -WithBom $read.HasBom
    }
}

Write-Host ($script:RewriteSddMessage.Summary -f $filesScanned, $filesChanged, $totalReplacements)

if ($totalReplacements -eq 0) {
    Write-Host $script:RewriteSddMessage.NoChanges
}
elseif ($reportSamples.Count -gt 0) {
    Write-Host ($script:RewriteSddMessage.SampleHeader -f $script:RewriteSddConstant.MaxWhatIfSamples)
    $grouped = $reportSamples | Group-Object -Property File
    foreach ($group in $grouped) {
        Write-Host ($script:RewriteSddMessage.SampleLine -f $group.Name)
        foreach ($item in $group.Group) {
            Write-Host ($script:RewriteSddMessage.SampleBefore -f $item.Before)
            Write-Host ($script:RewriteSddMessage.SampleAfter -f $item.After)
        }
    }
}

if ($WhatIf.IsPresent) {
    Write-Host $script:RewriteSddMessage.DoneWhatIf
}
else {
    Write-Host $script:RewriteSddMessage.DoneApply
}

[pscustomobject]@{
    Root              = $resolvedRoot
    WhatIf            = [bool]$WhatIf.IsPresent
    FilesScanned      = $filesScanned
    FilesChanged      = $filesChanged
    ReplacementCount  = $totalReplacements
    Samples           = @($reportSamples.ToArray())
}
