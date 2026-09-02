#Requires -Version 5.1
<#
.SYNOPSIS
  Fail-open TRACE.jsonl append helpers for adapter hook emitters (REQ-006 / CA6).

.DESCRIPTION
  Allowlisted schema only. Never throws to the host. Never echoes tool bodies,
  prompts, or secrets into TRACE or stdout. Path policy: append only under a
  feature-scoped TRACE.jsonl (portable features/NNN-slug).

  TOOLKIT_TRACE_FEATURE_ROOT is a trusted-CI-only override: set it to an in-repo
  fixture features/NNN-slug directory for asserts/CI. Never point it at live
  USERPROFILE homes or untrusted operator paths — it bypasses cwd walk-up.
#>

Set-StrictMode -Version Latest

$script:TraceEmitterAllowedEvents = @(
    'note',
    'step_done',
    'develop_start',
    'specialist_complete',
    'spawn',
    'gate',
    'retrieval'
)

$script:TraceEmitterAllowedKeys = @(
    'ts',
    'event',
    'feature',
    'summary',
    'role',
    'reason',
    'outcome',
    'gate_id',
    'paths',
    'targets',
    'status',
    'tokens',
    'duration',
    'spawn',
    'host',
    'hook'
)

# Extra must never inject host bodies / large opaque blobs via these keys.
$script:TraceEmitterExtraDropKeys = @(
    'response'
)

$script:TraceEmitterForbiddenKeyPattern = '(?i)^(tool_input|tool_output|tool_response|prompt|content|body|command|arguments|args|password|secret|token|authorization|api[_-]?key|connectionstring|private[_-]?key)$'

$script:TraceEmitterEnvFeatureRoot = 'TOOLKIT_TRACE_FEATURE_ROOT'
$script:TraceEmitterEnvForceFail = 'TOOLKIT_TRACE_FORCE_FAIL'
$script:TraceEmitterEnvHostId = 'TOOLKIT_TRACE_HOST'
$script:TraceEmitterTraceFileName = 'TRACE.jsonl'
$script:TraceEmitterFeaturePrefix = 'features/'
$script:TraceEmitterSummaryMaxLength = 160
$script:TraceEmitterExtraMaxDepth = 4

function Test-TraceEmitterForceFail {
    $raw = [string]$env:TOOLKIT_TRACE_FORCE_FAIL
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $false
    }
    return $raw -match '^(?i)(1|true|yes)$'
}

function Get-TraceEmitterPortableFeature {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FeatureRootPath
    )

    $full = [System.IO.Path]::GetFullPath($FeatureRootPath)
    $normalized = $full.Replace('\', '/')
    $marker = '/' + $script:TraceEmitterFeaturePrefix
    $idx = $normalized.ToLowerInvariant().LastIndexOf($marker.ToLowerInvariant())
    if ($idx -lt 0) {
        # Accept root that IS features/NNN-slug
        $leaf = Split-Path -Leaf $normalized
        $parent = Split-Path -Parent $normalized
        $parentLeaf = if ($parent) { Split-Path -Leaf $parent } else { '' }
        if ($parentLeaf -eq 'features' -and $leaf -match '^\d{3}-') {
            return ($script:TraceEmitterFeaturePrefix + $leaf)
        }
        return $null
    }

    $fromFeatures = $normalized.Substring($idx + 1)
    if ($fromFeatures -notmatch '^features/\d{3}-[^/]+') {
        return $null
    }
    $parts = $fromFeatures -split '/'
    if ($parts.Count -lt 2) {
        return $null
    }
    return ($parts[0] + '/' + $parts[1])
}

function Resolve-TraceEmitterFeatureRoot {
    <#
    .SYNOPSIS
      Resolve feature root for TRACE append.

    .DESCRIPTION
      Prefer TOOLKIT_TRACE_FEATURE_ROOT when set. That env var is trusted-CI-only
      (fixture features/NNN-slug). Do not use it for live USERPROFILE homes.
    #>
    $override = [string]$env:TOOLKIT_TRACE_FEATURE_ROOT
    if (-not [string]::IsNullOrWhiteSpace($override)) {
        try {
            $full = [System.IO.Path]::GetFullPath($override.Trim())
            if (Test-Path -LiteralPath $full -PathType Container) {
                return $full
            }
        }
        catch {
            return $null
        }
        return $null
    }

    # Live: walk up from cwd for features/NNN-slug (no USERPROFILE invent).
    try {
        $cursor = [System.IO.Path]::GetFullPath((Get-Location).Path)
    }
    catch {
        return $null
    }

    for ($i = 0; $i -lt 12; $i++) {
        $name = Split-Path -Leaf $cursor
        $parent = Split-Path -Parent $cursor
        $parentName = if ($parent) { Split-Path -Leaf $parent } else { '' }
        if ($parentName -eq 'features' -and $name -match '^\d{3}-') {
            return $cursor
        }
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            break
        }
        $cursor = $parent
    }

    return $null
}

function Test-TraceEmitterPathUnderFeatureRoot {
    param(
        [Parameter(Mandatory = $true)][string] $CandidatePath,
        [Parameter(Mandatory = $true)][string] $FeatureRootPath
    )

    try {
        $candidateFull = [System.IO.Path]::GetFullPath($CandidatePath)
        $rootFull = [System.IO.Path]::GetFullPath($FeatureRootPath)
    }
    catch {
        return $false
    }

    $rootPrefix = $rootFull.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    return $candidateFull.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($candidateFull, $rootFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-TraceEmitterRedactedSummary {
    <#
    .SYNOPSIS
      Truncate + redact operational text. Aligns with GuardCommon secret shapes.
    #>
    param([AllowNull()][string] $Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $trimmed = $Text.Trim()
    if ($trimmed.Length -gt $script:TraceEmitterSummaryMaxLength) {
        $trimmed = $trimmed.Substring(0, $script:TraceEmitterSummaryMaxLength)
    }

    # Strip secret-looking fragments (GuardCommon + connection-string shapes).
    $trimmed = [regex]::Replace($trimmed, '(?i)(bearer\s+)\S+', '$1***')
    $trimmed = [regex]::Replace($trimmed, '(?i)(api[_-]?key\s*[=:]\s*)[''"]?[A-Za-z0-9_\-]{8,}', '$1***')
    $trimmed = [regex]::Replace($trimmed, '(?i)(password\s*[=:]\s*)[^;\s''"]{4,}', '$1***')
    $trimmed = [regex]::Replace($trimmed, 'gh[pousr]_[A-Za-z0-9_]{20,}', 'gh*_***')
    $trimmed = [regex]::Replace($trimmed, 'AKIA[0-9A-Z]{16}', 'AKIA***')
    $trimmed = [regex]::Replace($trimmed, 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}', 'eyJ***.***.***')
    $trimmed = [regex]::Replace($trimmed, '(?i)(AccountKey\s*=\s*)[A-Za-z0-9+/=]{20,}', '$1***')
    $trimmed = [regex]::Replace($trimmed, '(?i)(ConnectionString\s*[=:]\s*)\S+', '$1***')
    $trimmed = [regex]::Replace($trimmed, '(?i)((?:Server|Data Source|Initial Catalog|User ID|Uid|Pwd)\s*=\s*)[^;]+', '$1***')
    $trimmed = [regex]::Replace($trimmed, '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----', '-----BEGIN PRIVATE KEY-----***')
    return $trimmed
}

function Convert-TraceEmitterExtraValue {
    <#
    .SYNOPSIS
      Redact/truncate string Extra values; drop forbidden/dangerous keys; recurse shallowly.
    #>
    param(
        [Parameter()][AllowNull()] $Value,
        [Parameter()][int] $Depth = 0
    )

    if ($Depth -gt $script:TraceEmitterExtraMaxDepth) {
        return $null
    }
    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string]) {
        return (Get-TraceEmitterRedactedSummary -Text $Value)
    }

    if ($Value -is [bool] -or $Value -is [byte] -or $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int] -or $Value -is [uint32] -or $Value -is [long] -or $Value -is [uint64] -or
        $Value -is [float] -or $Value -is [double] -or $Value -is [decimal]) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $out = [ordered]@{}
        foreach ($key in @($Value.Keys)) {
            $keyText = [string]$key
            if ([string]::IsNullOrWhiteSpace($keyText)) {
                continue
            }
            if ($keyText -match $script:TraceEmitterForbiddenKeyPattern) {
                continue
            }
            if ($script:TraceEmitterExtraDropKeys -contains $keyText) {
                continue
            }
            $converted = Convert-TraceEmitterExtraValue -Value $Value[$key] -Depth ($Depth + 1)
            if ($null -ne $converted) {
                $out[$keyText] = $converted
            }
        }
        return $out
    }

    # PSCustomObject / note-property bags before IEnumerable (JSON spawn/duration shapes).
    if ($null -ne $Value.PSObject) {
        $noteProps = @($Value.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' })
        if ($noteProps.Length -gt 0) {
            $out = [ordered]@{}
            foreach ($prop in $noteProps) {
                $keyText = [string]$prop.Name
                if ([string]::IsNullOrWhiteSpace($keyText)) {
                    continue
                }
                if ($keyText -match $script:TraceEmitterForbiddenKeyPattern) {
                    continue
                }
                if ($script:TraceEmitterExtraDropKeys -contains $keyText) {
                    continue
                }
                $converted = Convert-TraceEmitterExtraValue -Value $prop.Value -Depth ($Depth + 1)
                if ($null -ne $converted) {
                    $out[$keyText] = $converted
                }
            }
            return $out
        }
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $list = New-Object System.Collections.ArrayList
        foreach ($item in $Value) {
            $converted = Convert-TraceEmitterExtraValue -Value $item -Depth ($Depth + 1)
            if ($null -ne $converted) {
                [void]$list.Add($converted)
            }
        }
        return @($list)
    }

    return (Get-TraceEmitterRedactedSummary -Text ([string]$Value))
}

function New-TraceEmitterAllowlistedEvent {
    param(
        [Parameter(Mandatory = $true)][string] $EventName,
        [Parameter(Mandatory = $true)][string] $FeaturePortable,
        [Parameter()][string] $Summary = '',
        [Parameter()][string] $HostId = '',
        [Parameter()][string] $HookName = '',
        [Parameter()][string] $Role = '',
        [Parameter()][string] $Outcome = '',
        [Parameter()][object] $Duration = $null,
        [Parameter()][hashtable] $Extra = $null
    )

    if ($script:TraceEmitterAllowedEvents -notcontains $EventName) {
        return $null
    }

    $payload = [ordered]@{
        ts      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        event   = $EventName
        feature = $FeaturePortable
    }

    $summarySafe = Get-TraceEmitterRedactedSummary -Text $Summary
    if (-not [string]::IsNullOrWhiteSpace($summarySafe)) {
        $payload['summary'] = $summarySafe
    }
    if (-not [string]::IsNullOrWhiteSpace($HostId)) {
        $payload['host'] = $HostId
    }
    if (-not [string]::IsNullOrWhiteSpace($HookName)) {
        $payload['hook'] = $HookName
    }
    if (-not [string]::IsNullOrWhiteSpace($Role)) {
        $payload['role'] = $Role
    }
    if (-not [string]::IsNullOrWhiteSpace($Outcome)) {
        $payload['outcome'] = $Outcome
    }
    if ($null -ne $Duration) {
        $payload['duration'] = $Duration
    }

    if ($null -ne $Extra) {
        foreach ($key in $Extra.Keys) {
            $keyText = [string]$key
            if ($script:TraceEmitterAllowedKeys -notcontains $keyText) {
                continue
            }
            if ($keyText -match $script:TraceEmitterForbiddenKeyPattern) {
                continue
            }
            if ($script:TraceEmitterExtraDropKeys -contains $keyText) {
                continue
            }
            if ($payload.Contains($keyText)) {
                continue
            }
            $converted = Convert-TraceEmitterExtraValue -Value $Extra[$key]
            if ($null -ne $converted) {
                $payload[$keyText] = $converted
            }
        }
    }

    return $payload
}

function Add-TraceEmitterEvent {
    <#
    .SYNOPSIS
      Append one allowlisted TRACE event. Fail-open: returns $false on any error; never throws.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Event
    )

    try {
        if (Test-TraceEmitterForceFail) {
            return $false
        }

        foreach ($required in @('ts', 'event', 'feature')) {
            if (-not $Event.Contains($required) -or [string]::IsNullOrWhiteSpace([string]$Event[$required])) {
                return $false
            }
        }

        $eventName = [string]$Event['event']
        if ($script:TraceEmitterAllowedEvents -notcontains $eventName) {
            return $false
        }

        foreach ($key in @($Event.Keys)) {
            $keyText = [string]$key
            if ($script:TraceEmitterAllowedKeys -notcontains $keyText) {
                return $false
            }
            if ($keyText -match $script:TraceEmitterForbiddenKeyPattern) {
                return $false
            }
        }

        $featureRoot = Resolve-TraceEmitterFeatureRoot
        if ([string]::IsNullOrWhiteSpace($featureRoot)) {
            return $false
        }

        $portable = Get-TraceEmitterPortableFeature -FeatureRootPath $featureRoot
        if ([string]::IsNullOrWhiteSpace($portable)) {
            return $false
        }

        # Force portable feature field (never OS absolute).
        $Event['feature'] = $portable

        if ($Event.Contains('summary') -and $null -ne $Event['summary']) {
            $Event['summary'] = Get-TraceEmitterRedactedSummary -Text ([string]$Event['summary'])
        }
        if ($Event.Contains('spawn') -and $null -ne $Event['spawn']) {
            $Event['spawn'] = Convert-TraceEmitterExtraValue -Value $Event['spawn']
        }
        if ($Event.Contains('reason') -and $null -ne $Event['reason'] -and $Event['reason'] -is [string]) {
            $Event['reason'] = Get-TraceEmitterRedactedSummary -Text ([string]$Event['reason'])
        }

        $tracePath = Join-Path $featureRoot $script:TraceEmitterTraceFileName
        if (-not (Test-TraceEmitterPathUnderFeatureRoot -CandidatePath $tracePath -FeatureRootPath $featureRoot)) {
            return $false
        }

        $line = ($Event | ConvertTo-Json -Compress -Depth 6)
        if ([string]::IsNullOrWhiteSpace($line)) {
            return $false
        }

        # Refuse lines that look like they embedded raw env/secret dumps.
        if ($line -match '(?i)("Bearer\s+[A-Za-z0-9\._\-]+"|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|AccountKey\s*=\s*[A-Za-z0-9+/=]{20,})') {
            return $false
        }

        $dir = Split-Path -Parent $tracePath
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        Add-Content -LiteralPath $tracePath -Value $line -Encoding UTF8
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-TraceEmitterFromHookInput {
    <#
    .SYNOPSIS
      Map host hook stdin JSON to an allowlisted TRACE append. Always fail-open.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string] $HostId,

        [Parameter()]
        [string] $HookName = ''
    )

    try {
        if ($null -eq $InputObject) {
            return $false
        }

        $resolvedHook = $HookName
        if ([string]::IsNullOrWhiteSpace($resolvedHook)) {
            if ($InputObject.PSObject.Properties.Name -contains 'hook_event_name') {
                $resolvedHook = [string]$InputObject.hook_event_name
            }
            elseif ($InputObject.PSObject.Properties.Name -contains 'hookEventName') {
                $resolvedHook = [string]$InputObject.hookEventName
            }
        }

        $hookLower = $resolvedHook.ToLowerInvariant()
        $eventName = 'note'
        $role = ''
        $outcome = ''
        $summary = ''
        $duration = $null

        if ($hookLower -match 'subagentstop') {
            $eventName = 'specialist_complete'
            if ($InputObject.PSObject.Properties.Name -contains 'subagent_type') {
                $role = [string]$InputObject.subagent_type
            }
            elseif ($InputObject.PSObject.Properties.Name -contains 'agent_type') {
                $role = [string]$InputObject.agent_type
            }
            if ([string]::IsNullOrWhiteSpace($role)) {
                $role = 'subagent'
            }
            if ($InputObject.PSObject.Properties.Name -contains 'status') {
                $outcome = [string]$InputObject.status
            }
            else {
                $outcome = 'completed'
            }
            if ($InputObject.PSObject.Properties.Name -contains 'description') {
                $summary = Get-TraceEmitterRedactedSummary -Text ([string]$InputObject.description)
            }
            elseif ($InputObject.PSObject.Properties.Name -contains 'summary') {
                # Host summary may be long; redact + truncate — never store full transcript.
                $summary = Get-TraceEmitterRedactedSummary -Text ([string]$InputObject.summary)
            }
            else {
                $summary = 'subagentStop'
            }
            if ($InputObject.PSObject.Properties.Name -contains 'duration_ms') {
                try {
                    $ms = [double]$InputObject.duration_ms
                    if ($ms -ge 0) {
                        $duration = @{ ms = $ms }
                    }
                }
                catch {
                    $duration = $null
                }
            }
        }
        elseif ($hookLower -match 'posttooluse') {
            $eventName = 'note'
            $toolName = ''
            if ($InputObject.PSObject.Properties.Name -contains 'tool_name') {
                $toolName = [string]$InputObject.tool_name
            }
            elseif ($InputObject.PSObject.Properties.Name -contains 'toolName') {
                $toolName = [string]$InputObject.toolName
            }
            if ([string]::IsNullOrWhiteSpace($toolName)) {
                $summary = 'postToolUse'
            }
            else {
                $summary = ('postToolUse tool={0}' -f $toolName)
            }
        }
        else {
            $summary = if ([string]::IsNullOrWhiteSpace($resolvedHook)) { 'hook' } else { $resolvedHook }
        }

        $featureRoot = Resolve-TraceEmitterFeatureRoot
        if ([string]::IsNullOrWhiteSpace($featureRoot)) {
            return $false
        }
        $portable = Get-TraceEmitterPortableFeature -FeatureRootPath $featureRoot
        if ([string]::IsNullOrWhiteSpace($portable)) {
            return $false
        }

        $payload = New-TraceEmitterAllowlistedEvent `
            -EventName $eventName `
            -FeaturePortable $portable `
            -Summary $summary `
            -HostId $HostId `
            -HookName $resolvedHook `
            -Role $role `
            -Outcome $outcome `
            -Duration $duration

        if ($null -eq $payload) {
            return $false
        }

        return (Add-TraceEmitterEvent -Event $payload)
    }
    catch {
        return $false
    }
}
