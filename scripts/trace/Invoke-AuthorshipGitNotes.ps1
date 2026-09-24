#Requires -Version 5.1
<#
.SYNOPSIS
  Opt-in authorship git-notes helper beside TRACE (REQ-016…018 / WS15).

.DESCRIPTION
  Default is OFF: without -Enable the script never writes git notes (CT5).
  Notes are orthogonal metadata — never TRACE SoT (RN03 / TE06).
  Harvest and validate-trace remain TRACE.jsonl-only; this helper does not
  read or mutate features/NNN-slug/TRACE.jsonl.

.PARAMETER FeatureRoot
  Portable or absolute path to features/NNN-slug/ (recorded in the note payload).

.PARAMETER Enable
  Explicit opt-in. Omit or $false → no git notes write (default off).

.PARAMETER Action
  add (default when -Enable), show, or status.

.PARAMETER Message
  Optional short authorship message (add only). No secrets / PII.

.PARAMETER RepoPath
  Git repository root. Defaults to toolkit repo root discovery.

.EXAMPLE
  # Default off — exits 0 and writes nothing
  .\scripts\trace\Invoke-AuthorshipGitNotes.ps1 -FeatureRoot features\008-toolkit-evolution-remaining

.EXAMPLE
  # Opt-in write
  .\scripts\trace\Invoke-AuthorshipGitNotes.ps1 -FeatureRoot features\008-x -Enable -Message 'operator sign-off'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $FeatureRoot,

    [Parameter(Mandatory = $false)]
    [switch] $Enable,

    [Parameter(Mandatory = $false)]
    [ValidateSet('add', 'show', 'status')]
    [string] $Action = 'add',

    [Parameter(Mandatory = $false)]
    [string] $Message = '',

    [Parameter(Mandatory = $false)]
    [string] $RepoPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'ToolkitConstants.ps1')
if (-not (Get-Command -Name Test-IsPathUnderOrEqual -ErrorAction SilentlyContinue)) {
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
}

$c = $script:ToolkitConstant
$notesRef = $c.AuthorshipGitNotesRefName
$exitOk = [int]$c.AuthorshipGitNotesExitOk
$exitFail = [int]$c.AuthorshipGitNotesExitFail
$traceFileName = $c.SddArtifactTraceFileName
$featureLeafPattern = $c.TraceHarvestFeatureLeafPattern

function Write-AuthorshipResult {
    param(
        [Parameter(Mandatory = $true)][string] $Status,
        [Parameter(Mandatory = $false)][string] $Detail = ''
    )

    $payload = [ordered]@{
        status          = $Status
        enabled         = [bool]$Enable
        default_off     = $true
        notes_are_sot   = $false
        trace_sot       = $traceFileName
        notes_ref       = $notesRef
        action          = $Action
        detail          = $Detail
    }
    $json = $payload | ConvertTo-Json -Compress
    Write-Host $json
}

function Resolve-RepoRootPath {
    if (-not [string]::IsNullOrWhiteSpace($RepoPath)) {
        return (Get-NormalizedFullPath -Path $RepoPath)
    }
    return (Get-ToolkitRepoRoot -FromPath $scriptDir)
}

function Resolve-FeatureRootFullPath {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Root
    )

    $resolved = $Path
    if (-not [System.IO.Path]::IsPathRooted($resolved)) {
        $resolved = Join-Path $Root $Path
    }
    return (Get-NormalizedFullPath -Path $resolved)
}

function Get-PortableFeatureRelative {
    param(
        [Parameter(Mandatory = $true)][string] $FeatureFull,
        [Parameter(Mandatory = $true)][string] $RootFull
    )

    if (-not (Test-IsPathUnderOrEqual -ChildPath $FeatureFull -ParentPath $RootFull)) {
        throw ("FeatureRoot escapes repo root: {0}" -f $FeatureFull)
    }

    $root = $RootFull.TrimEnd('\', '/')
    $full = $FeatureFull
    $relative = $full.Substring($root.Length).TrimStart('\', '/')
    return ($relative -replace '\\', '/')
}

function Test-FeatureLeafName {
    param([Parameter(Mandatory = $true)][string] $PortableRelative)

    $leaf = Split-Path -Leaf ($PortableRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ($leaf -notmatch $featureLeafPattern) {
        throw ("FeatureRoot leaf must match features/NNN-slug: {0}" -f $PortableRelative)
    }
    $normalized = $PortableRelative.Trim('/')
    if ($normalized -notmatch '(?i)^features/') {
        throw ("FeatureRoot must be under features/: {0}" -f $PortableRelative)
    }
}

function Invoke-GitNotes {
    param(
        [Parameter(Mandatory = $true)][string] $WorkingDirectory,
        [Parameter(Mandatory = $true)][string[]] $GitArguments
    )

    $allArgs = @('notes', '--ref={0}' -f $notesRef) + $GitArguments
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git -C $WorkingDirectory @allArgs 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prevEap
    }

    return [pscustomobject]@{
        ExitCode = $code
        Output   = @($output | ForEach-Object { "$_" })
    }
}

try {
    $repoRoot = Resolve-RepoRootPath
    $featureFull = Resolve-FeatureRootFullPath -Path $FeatureRoot -Root $repoRoot
    if (-not (Test-Path -LiteralPath $featureFull -PathType Container)) {
        throw ("FeatureRoot not found: {0}" -f $featureFull)
    }

    $portableFeature = Get-PortableFeatureRelative -FeatureFull $featureFull -RootFull $repoRoot
    Test-FeatureLeafName -PortableRelative $portableFeature

    $tracePath = Join-Path $featureFull $traceFileName
    $tracePresent = Test-Path -LiteralPath $tracePath -PathType Leaf

    if ($Action -eq 'status') {
        $statusLabel = if ($Enable) { 'opt_in_flag_set' } else { $c.AuthorshipGitNotesStatusDisabled }
        Write-AuthorshipResult -Status $statusLabel -Detail (
            'default_off=true; enable_switch={0}; trace_present={1}; notes_never_sot=true' -f [bool]$Enable, $tracePresent
        )
        exit $exitOk
    }

    if ($Action -eq 'show') {
        $show = Invoke-GitNotes -WorkingDirectory $repoRoot -GitArguments @('show')
        $joined = ($show.Output -join [Environment]::NewLine).Trim()
        if ($show.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($joined)) {
            Write-AuthorshipResult -Status $c.AuthorshipGitNotesStatusShown -Detail 'no note for HEAD (notes are optional; TRACE remains SoT)'
            exit $exitOk
        }
        Write-AuthorshipResult -Status $c.AuthorshipGitNotesStatusShown -Detail $joined
        exit $exitOk
    }

    # Action add — default off: never write without -Enable (REQ-016 / CT5)
    if (-not $Enable) {
        Write-AuthorshipResult -Status $c.AuthorshipGitNotesStatusSkipped -Detail (
            'opt-in required; no git notes written; TRACE SoT untouched at {0}' -f $portableFeature
        )
        exit $exitOk
    }

    $head = & git -C $repoRoot rev-parse HEAD 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("git rev-parse HEAD failed: {0}" -f ($head -join ' '))
    }
    $headSha = ("$head").Trim()

    $safeMessage = if ([string]::IsNullOrWhiteSpace($Message)) {
        'authorship opt-in note (not TRACE SoT)'
    }
    else {
        $Message.Trim()
    }

    $noteLines = New-Object System.Collections.Generic.List[string]
    [void]$noteLines.Add('toolkit-authorship: opt-in parallel metadata (REQ-016)')
    [void]$noteLines.Add('notes_are_sot: false')
    [void]$noteLines.Add(('trace_sot: {0}' -f $traceFileName))
    [void]$noteLines.Add(('feature: {0}' -f $portableFeature))
    [void]$noteLines.Add(('commit: {0}' -f $headSha))
    [void]$noteLines.Add(('ts: {0:o}' -f [DateTimeOffset]::UtcNow))
    [void]$noteLines.Add(('message: {0}' -f $safeMessage))
    [void]$noteLines.Add('honesty: see adapters/_shared/trace-emitter-honesty.md; harvest/validate-trace use TRACE only')
    $noteBody = ($noteLines -join [Environment]::NewLine)

    $add = Invoke-GitNotes -WorkingDirectory $repoRoot -GitArguments @('add', '-f', '-m', $noteBody, $headSha)
    if ($add.ExitCode -ne 0) {
        throw ("git notes add failed: {0}" -f ($add.Output -join ' '))
    }

    Write-AuthorshipResult -Status $c.AuthorshipGitNotesStatusWritten -Detail (
        'wrote refs/notes/{0} for {1}; TRACE remains SoT (append-only parallel)' -f $notesRef, $portableFeature
    )
    exit $exitOk
}
catch {
    Write-Host (("validate-authorship-git-notes: FAIL - {0}" -f $_.Exception.Message)) -ForegroundColor Red
    Write-AuthorshipResult -Status 'error' -Detail $_.Exception.Message
    exit $exitFail
}
