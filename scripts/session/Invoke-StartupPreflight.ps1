#Requires -Version 5.1
<#
.SYNOPSIS
  Records and checks the session startup preflight marker (delivery-startup/v1).

.DESCRIPTION
  The marker is a coordinator declaration: it records which startup reads the
  coordinator declared, the subagents capability, and the model choice. It does not
  prove that the model read those files or which model the host applied.

  Action record writes <SessionsRoot>/startup-<SessionId>.json atomically.
  Action check prints one compact JSON result and exits 0 (allowed) or 3 (blocked).
  Invalid parameters and IO errors exit 1.

.PARAMETER Action
  record | check

.PARAMETER SessionId
  Session identifier. Only [A-Za-z0-9._-] is accepted.

.PARAMETER SessionsRoot
  Directory that holds the marker. Created when missing.

.PARAMETER AgentHost
  Host name recorded in the marker (for example claude, codex).

.PARAMETER Capability
  record only: native | none | unknown.

.PARAMETER ReadsDeclared
  record only: startup reads declared by the coordinator (base names, case-insensitive).

.PARAMETER ModelChoiceKind
  record only: inherit | pair | saved_confirmed. Optional.

.PARAMETER Model
  record only: optional model name for the model choice.

.PARAMETER Effort
  record only: optional effort value for the model choice.

.PARAMETER Gate
  check only: spawn | review-record.

.EXAMPLE
  .\scripts\session\Invoke-StartupPreflight.ps1 -Action record -SessionId s1 -SessionsRoot $env:TEMP\adt-startup -AgentHost claude -Capability native -ReadsDeclared guardrails,SESSION,SPAWN-DIGEST,SPAWN,SUBAGENT-MODEL -ModelChoiceKind inherit

.EXAMPLE
  .\scripts\session\Invoke-StartupPreflight.ps1 -Action check -SessionId s1 -SessionsRoot $env:TEMP\adt-startup -AgentHost claude -Gate spawn
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('record', 'check')]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $SessionId,

    [Parameter(Mandatory = $true)]
    [string] $SessionsRoot,

    [Parameter(Mandatory = $true)]
    [string] $AgentHost,

    [ValidateSet('native', 'none', 'unknown')]
    [string] $Capability,

    [string[]] $ReadsDeclared = @(),

    [ValidateSet('inherit', 'pair', 'saved_confirmed')]
    [string] $ModelChoiceKind,

    [string] $Model,

    [string] $Effort,

    [ValidateSet('spawn', 'review-record')]
    [string] $Gate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$exitAllowed = 0
$exitBlocked = 3
$exitError = 1
$script:ExitCode = $exitAllowed

$markerSchema = 'delivery-startup/v1'
$markerPrefix = 'startup-'
$markerRequiredFields = @('schema', 'session_id', 'host', 'subagents_capability', 'reads_declared')
$capabilityValues = @('native', 'none', 'unknown')

$requiredReadsNative = @('guardrails', 'SESSION', 'SPAWN-DIGEST', 'SPAWN', 'SUBAGENT-MODEL')
$requiredReadsLite = @('guardrails', 'SESSION')

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Write-JsonLine {
    param([Parameter(Mandatory = $true)]$Object)
    Write-Output ($Object | ConvertTo-Json -Depth 6 -Compress)
}

function Assert-SessionId {
    param([Parameter(Mandatory = $true)][string] $Value)
    if ($Value -notmatch '^[A-Za-z0-9._-]+\z') {
        throw "SessionId contains characters outside [A-Za-z0-9._-]: '$Value'"
    }
}

function Get-SplitReads {
    param([string[]] $Values = @())
    $result = @()
    foreach ($value in @($Values)) {
        foreach ($part in ([string]$value).Split(',')) {
            if (-not [string]::IsNullOrWhiteSpace($part)) {
                $result += $part.Trim()
            }
        }
    }
    return $result
}

function Get-DeclaredReadNames {
    param([string[]] $Values = @())
    $names = @()
    foreach ($item in @($Values)) {
        if ($null -eq $item) {
            continue
        }
        $entry = ([string]$item).Trim()
        if ($entry.Length -eq 0 -or $entry.Contains('/') -or $entry.Contains('\')) {
            continue
        }
        $extension = [System.IO.Path]::GetExtension($entry)
        if ($extension.Length -gt 0 -and -not $extension.Equals('.md', [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($entry)
        if ($baseName.Length -eq 0) {
            continue
        }
        $names += $baseName.ToLowerInvariant()
    }
    return $names
}

function Get-RequiredReads {
    param([Parameter(Mandatory = $true)][string] $CapabilityValue)
    if ($CapabilityValue -eq 'native') {
        return $requiredReadsNative
    }
    return $requiredReadsLite
}

function Get-MissingReads {
    param(
        [Parameter(Mandatory = $true)][string] $CapabilityValue,
        [string[]] $DeclaredReads = @()
    )
    $declaredNames = @(Get-DeclaredReadNames -Values $DeclaredReads)
    $missing = @()
    foreach ($required in (Get-RequiredReads -CapabilityValue $CapabilityValue)) {
        if ($declaredNames -cnotcontains $required.ToLowerInvariant()) {
            $missing += $required
        }
    }
    return $missing
}

function Get-MarkerPath {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string] $Id
    )
    return (Join-Path $Root ($markerPrefix + $Id + '.json'))
}

function Write-TextAtomic {
    param(
        [Parameter(Mandatory = $true)][string] $TargetPath,
        [Parameter(Mandatory = $true)][string] $Content
    )
    $directory = Split-Path -Parent $TargetPath
    $uniqueSuffix = [guid]::NewGuid().ToString('N')
    $baseName = '.' + [System.IO.Path]::GetFileName($TargetPath) + '.' + $uniqueSuffix
    $tempPath = Join-Path $directory ($baseName + '.tmp')
    $backupPath = Join-Path $directory ($baseName + '.bak')
    try {
        [System.IO.File]::WriteAllText($tempPath, $Content, (Get-Utf8NoBomEncoding))
        if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
            [System.IO.File]::Replace($tempPath, $TargetPath, $backupPath)
        }
        else {
            Move-Item -LiteralPath $tempPath -Destination $TargetPath
        }
    }
    finally {
        foreach ($leftover in @($tempPath, $backupPath)) {
            if (Test-Path -LiteralPath $leftover) {
                Remove-Item -LiteralPath $leftover -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Invoke-RecordAction {
    if ([string]::IsNullOrWhiteSpace($Capability)) {
        throw 'Action record requires -Capability.'
    }
    if ([string]::IsNullOrWhiteSpace($AgentHost)) {
        throw 'Action record requires a non-empty -AgentHost.'
    }

    if (-not (Test-Path -LiteralPath $SessionsRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $SessionsRoot -Force | Out-Null
    }
    $rootFull = (Resolve-Path -LiteralPath $SessionsRoot).Path

    $modelChoice = $null
    if (-not [string]::IsNullOrWhiteSpace($ModelChoiceKind)) {
        $modelChoice = [ordered]@{
            kind   = $ModelChoiceKind
            model  = $(if ([string]::IsNullOrWhiteSpace($Model)) { $null } else { $Model })
            effort = $(if ([string]::IsNullOrWhiteSpace($Effort)) { $null } else { $Effort })
        }
    }

    $reads = @(Get-SplitReads -Values $ReadsDeclared)

    $marker = [ordered]@{
        schema                = $markerSchema
        session_id            = $SessionId
        host                  = $AgentHost
        recorded_utc          = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
        subagents_capability  = $Capability.ToLowerInvariant()
        reads_declared        = $reads
        model_choice          = $modelChoice
    }

    $json = ConvertTo-Json -InputObject $marker -Depth 6
    $markerPath = Get-MarkerPath -Root $rootFull -Id $SessionId
    Write-TextAtomic -TargetPath $markerPath -Content ($json + [Environment]::NewLine)

    Write-JsonLine -Object ([ordered]@{ recorded = $true; marker = $markerPath })
    $script:ExitCode = $exitAllowed
}

function New-CheckResult {
    param(
        [Parameter(Mandatory = $true)][bool] $Allowed,
        [Parameter(Mandatory = $true)][string] $Reason,
        [Parameter(Mandatory = $true)][string] $GateName,
        [string[]] $Missing = @()
    )
    return [ordered]@{
        allowed = $Allowed
        reason  = $Reason
        gate    = $GateName
        missing = @($Missing)
    }
}

function Read-MarkerObject {
    param([Parameter(Mandatory = $true)][string] $Path)
    $raw = [string](Get-Content -LiteralPath $Path -Raw -Encoding UTF8)
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }
    try {
        $parsed = ConvertFrom-Json -InputObject $raw
    }
    catch {
        return $null
    }
    if ($parsed -isnot [System.Management.Automation.PSCustomObject]) {
        return $null
    }
    return $parsed
}

function Test-MarkerShape {
    param([Parameter(Mandatory = $true)] $Marker)
    $names = @($Marker.PSObject.Properties.Name)
    foreach ($field in $markerRequiredFields) {
        if ($names -cnotcontains $field) {
            return $false
        }
    }
    if ($Marker.schema -isnot [string] -or $Marker.schema -cne $markerSchema) {
        return $false
    }
    if ($Marker.session_id -isnot [string] -or [string]::IsNullOrWhiteSpace($Marker.session_id)) {
        return $false
    }
    if ($Marker.host -isnot [string] -or [string]::IsNullOrWhiteSpace($Marker.host)) {
        return $false
    }
    if ($Marker.subagents_capability -isnot [string] -or ($capabilityValues -cnotcontains $Marker.subagents_capability)) {
        return $false
    }
    if ($Marker.reads_declared -isnot [System.Array]) {
        return $false
    }
    return $true
}

function Invoke-CheckAction {
    if ([string]::IsNullOrWhiteSpace($Gate)) {
        throw 'Action check requires -Gate.'
    }

    $markerPath = Get-MarkerPath -Root $SessionsRoot -Id $SessionId
    if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
        Write-JsonLine -Object (New-CheckResult -Allowed $false -Reason 'marker_missing' -GateName $Gate)
        $script:ExitCode = $exitBlocked
        return
    }

    $marker = Read-MarkerObject -Path $markerPath
    if ($null -eq $marker -or -not (Test-MarkerShape -Marker $marker)) {
        Write-JsonLine -Object (New-CheckResult -Allowed $false -Reason 'marker_invalid' -GateName $Gate)
        $script:ExitCode = $exitBlocked
        return
    }

    $markerHost = [string]$marker.host
    $markerSession = [string]$marker.session_id
    $markerCapability = [string]$marker.subagents_capability
    $markerReads = @($marker.reads_declared)
    $markerChoice = $null
    if ($marker.PSObject.Properties.Name -contains 'model_choice') { $markerChoice = $marker.model_choice }

    if (($markerHost -cne $AgentHost) -or ($markerSession -cne $SessionId)) {
        Write-JsonLine -Object (New-CheckResult -Allowed $false -Reason 'host_mismatch' -GateName $Gate)
        $script:ExitCode = $exitBlocked
        return
    }

    $missingReads = @(Get-MissingReads -CapabilityValue $markerCapability -DeclaredReads $markerReads)
    if ($missingReads.Count -gt 0) {
        Write-JsonLine -Object (New-CheckResult -Allowed $false -Reason 'reads_missing' -GateName $Gate -Missing $missingReads)
        $script:ExitCode = $exitBlocked
        return
    }

    $isNative = ($markerCapability -ceq 'native')

    if ($Gate -eq 'spawn' -and -not $isNative) {
        Write-JsonLine -Object (New-CheckResult -Allowed $true -Reason 'spawn_not_applicable' -GateName $Gate)
        $script:ExitCode = $exitAllowed
        return
    }

    if ($isNative) {
        $kindPresent = $false
        if ($null -ne $markerChoice -and ($markerChoice.PSObject.Properties.Name -contains 'kind')) {
            $kindPresent = -not [string]::IsNullOrWhiteSpace([string]$markerChoice.kind)
        }
        if (-not $kindPresent) {
            Write-JsonLine -Object (New-CheckResult -Allowed $false -Reason 'model_choice_missing' -GateName $Gate)
            $script:ExitCode = $exitBlocked
            return
        }
    }

    Write-JsonLine -Object (New-CheckResult -Allowed $true -Reason 'ok' -GateName $Gate)
    $script:ExitCode = $exitAllowed
}

try {
    Assert-SessionId -Value $SessionId

    if ($Action -eq 'record') {
        Invoke-RecordAction
    }
    else {
        Invoke-CheckAction
    }
    exit $script:ExitCode
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit $exitError
}
