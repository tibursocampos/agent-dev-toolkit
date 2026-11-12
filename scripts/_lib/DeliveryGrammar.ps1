#Requires -Version 5.1

function Get-DeliverySha256Hex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function ConvertTo-DeliveryNormalizedText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) { $Text = $Text.Substring(1) }
    return $Text.Replace("`r`n", "`n").Replace("`r", "`n")
}

function New-DeliveryIssue {
    param(
        [Parameter(Mandatory = $true)][string] $Code,
        [Parameter(Mandatory = $true)][string] $Message,
        [Parameter(Mandatory = $true)][int] $Line
    )

    return [pscustomobject]@{ code = $Code; message = $Message; line = $Line }
}

function New-DeliveryRequirementIssue {
    param(
        [Parameter(Mandatory = $true)][string] $Code,
        [Parameter(Mandatory = $true)][string] $Message
    )

    return [pscustomobject]@{ code = $Code; message = $Message }
}

function Get-DeliveryMarkerIssueCode {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Line)

    if ($Line.StartsWith('<!-- DELIVERY:STEP-', [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ code = 'legacy_step_marker'; message = 'Legacy STEP-<id> marker form is rejected; use STEP:<id>.' }
    }
    if ($Line.StartsWith('<!-- DELIVERY:STEP:', [System.StringComparison]::Ordinal)) {
        $token = $Line.Substring('<!-- DELIVERY:STEP:'.Length).Split([char]':')[0]
        if ($token -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
            return [pscustomobject]@{ code = 'invalid_step_id'; message = 'STEP marker id does not match the allowed pattern.' }
        }
    }
    return [pscustomobject]@{ code = 'unknown_marker'; message = 'Unrecognized DELIVERY marker line.' }
}

function Get-DeliveryExpectedSchema {
    param([Parameter(Mandatory = $true)][string] $Type)

    switch ($Type) {
        'PROGRESS' { return 'delivery-progress/v1' }
        'CHECKPOINT' { return 'delivery-checkpoint/v1' }
        'APPROVAL' { return 'delivery-approval/v1' }
        'STEP' { return 'delivery-step/v1' }
    }
}

function Get-DeliveryFenceOpener {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Line)

    $match = [regex]::Match($Line, '^ {0,3}(`{3,})[^`]*$')
    if ($match.Success) {
        return [pscustomobject]@{ Char = '`'; Length = $match.Groups[1].Length }
    }

    $match = [regex]::Match($Line, '^ {0,3}(~{3,})')
    if ($match.Success) {
        return [pscustomobject]@{ Char = '~'; Length = $match.Groups[1].Length }
    }

    return $null
}

function Test-DeliveryFenceCloser {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Line,
        [Parameter(Mandatory = $true)][string] $FenceChar,
        [Parameter(Mandatory = $true)][int] $MinLength
    )

    $pattern = '^ {0,3}' + [regex]::Escape($FenceChar) + '{' + $MinLength + ',}[ \t]*$'
    return [regex]::IsMatch($Line, $pattern)
}

function Get-DeliveryExactProperty {
    param(
        [Parameter(Mandatory = $true)][object] $Object,
        [Parameter(Mandatory = $true)][string] $Name
    )

    foreach ($property in $Object.PSObject.Properties) {
        if ($property.Name -ceq $Name) { return $property }
    }
    return $null
}

function New-DeliveryFieldSpec {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Kind,
        [switch] $Required,
        [switch] $RequiredWhenApproved,
        [string[]] $Allowed = @()
    )

    return [pscustomobject]@{
        Name                 = $Name
        Kind                 = $Kind
        Required             = [bool]$Required
        RequiredWhenApproved = [bool]$RequiredWhenApproved
        Allowed              = [string[]]$Allowed
    }
}

function Get-DeliveryFieldSpecs {
    param([Parameter(Mandatory = $true)][string] $Type)

    switch -CaseSensitive ($Type) {
        'PROGRESS' {
            return @(
                New-DeliveryFieldSpec -Name 'cadence' -Kind 'string' -Required -Allowed @('step_by_step', 'continuous')
                New-DeliveryFieldSpec -Name 'current_stage' -Kind 'string'
                New-DeliveryFieldSpec -Name 'completed' -Kind 'integer'
                New-DeliveryFieldSpec -Name 'total' -Kind 'integer'
                New-DeliveryFieldSpec -Name 'approval_identity' -Kind 'string'
                New-DeliveryFieldSpec -Name 'authorization' -Kind 'object'
            )
        }
        'CHECKPOINT' {
            return @(
                New-DeliveryFieldSpec -Name 'branch' -Kind 'string' -Required
                New-DeliveryFieldSpec -Name 'head' -Kind 'string' -Required
                New-DeliveryFieldSpec -Name 'active_step' -Kind 'string-or-null' -Required
                New-DeliveryFieldSpec -Name 'run_id' -Kind 'string'
                New-DeliveryFieldSpec -Name 'updated_utc' -Kind 'string'
                New-DeliveryFieldSpec -Name 'last_completed' -Kind 'string-or-null'
                New-DeliveryFieldSpec -Name 'next_eligible' -Kind 'string-array'
                New-DeliveryFieldSpec -Name 'repositories' -Kind 'object-array'
                New-DeliveryFieldSpec -Name 'input_identity' -Kind 'string'
                New-DeliveryFieldSpec -Name 'location_kind' -Kind 'string' -Allowed @('git', 'directory')
                New-DeliveryFieldSpec -Name 'baseline_evidence' -Kind 'evidence-ref-or-null'
            )
        }
        'APPROVAL' {
            return @(
                New-DeliveryFieldSpec -Name 'state' -Kind 'string' -Required -Allowed @('pending', 'approved', 'superseded')
                New-DeliveryFieldSpec -Name 'identity' -Kind 'string' -RequiredWhenApproved
                New-DeliveryFieldSpec -Name 'input_identity' -Kind 'string' -RequiredWhenApproved
                New-DeliveryFieldSpec -Name 'review_state' -Kind 'string' -RequiredWhenApproved -Allowed @('reviewed', 'bypassed', 'not_run')
                New-DeliveryFieldSpec -Name 'review_bypass_reason' -Kind 'string-or-null'
                New-DeliveryFieldSpec -Name 'review_bypass_operator_choice' -Kind 'string-or-null'
                New-DeliveryFieldSpec -Name 'blocking_findings' -Kind 'array'
                New-DeliveryFieldSpec -Name 'unresolved_decisions' -Kind 'array'
                New-DeliveryFieldSpec -Name 'operator_choice' -Kind 'object'
                New-DeliveryFieldSpec -Name 'review_identity' -Kind 'string'
                New-DeliveryFieldSpec -Name 'approved_utc' -Kind 'string'
            )
        }
        'STEP' {
            return @(
                New-DeliveryFieldSpec -Name 'id' -Kind 'string' -Required
                New-DeliveryFieldSpec -Name 'status' -Kind 'string' -Required -Allowed @('PENDING', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED')
                New-DeliveryFieldSpec -Name 'depends_on' -Kind 'string-array'
                New-DeliveryFieldSpec -Name 'run_id' -Kind 'string'
                New-DeliveryFieldSpec -Name 'started_utc' -Kind 'string'
                New-DeliveryFieldSpec -Name 'ended_utc' -Kind 'string'
                New-DeliveryFieldSpec -Name 'acceptance_evidence' -Kind 'array-or-string'
                New-DeliveryFieldSpec -Name 'validation_results' -Kind 'object-array'
                New-DeliveryFieldSpec -Name 'blocker' -Kind 'string-or-null'
                New-DeliveryFieldSpec -Name 'evidence_refs' -Kind 'object-array'
            )
        }
    }
}

function Get-DeliveryNestedFieldSpecs {
    param([Parameter(Mandatory = $true)][string] $Name)

    switch -CaseSensitive ($Name) {
        'operator_choice' {
            return @(
                New-DeliveryFieldSpec -Name 'choice' -Kind 'string'
                New-DeliveryFieldSpec -Name 'evidence' -Kind 'string'
            )
        }
        'authorization' {
            return @(
                New-DeliveryFieldSpec -Name 'kind' -Kind 'string'
                New-DeliveryFieldSpec -Name 'scope' -Kind 'string'
                New-DeliveryFieldSpec -Name 'granted_utc' -Kind 'string'
                New-DeliveryFieldSpec -Name 'plan_identity' -Kind 'string'
                New-DeliveryFieldSpec -Name 'step_ids' -Kind 'string-array'
            )
        }
        'repositories' {
            return @(
                New-DeliveryFieldSpec -Name 'path' -Kind 'string'
                New-DeliveryFieldSpec -Name 'base' -Kind 'string'
                New-DeliveryFieldSpec -Name 'branch' -Kind 'string'
                New-DeliveryFieldSpec -Name 'head' -Kind 'string'
            )
        }
        'validation_results' {
            return @(
                New-DeliveryFieldSpec -Name 'command' -Kind 'string' -Required
                New-DeliveryFieldSpec -Name 'result' -Kind 'string' -Required
                New-DeliveryFieldSpec -Name 'exit_code' -Kind 'integer'
                New-DeliveryFieldSpec -Name 'at_utc' -Kind 'string'
            )
        }
        'evidence_refs' {
            return @(
                New-DeliveryFieldSpec -Name 'name' -Kind 'evidence-slug' -Required
                New-DeliveryFieldSpec -Name 'path' -Kind 'non-blank-string' -Required
                New-DeliveryFieldSpec -Name 'sha256' -Kind 'sha256-hex' -Required
            )
        }
    }
    return @()
}

function Find-DeliveryFieldSpec {
    param(
        [Parameter(Mandatory = $true)][object[]] $Specs,
        [Parameter(Mandatory = $true)][string] $Name
    )

    foreach ($spec in $Specs) {
        if ($spec.Name -ceq $Name) { return $spec }
    }
    return $null
}

function Test-DeliveryJsonString {
    param([AllowNull()][object] $Value)

    # Windows PowerShell 7 ConvertFrom-Json turns ISO 8601 strings into DateTime; they are JSON strings.
    return (($Value -is [string]) -or ($Value -is [System.DateTime]))
}

function Test-DeliveryValueKind {
    param(
        [AllowNull()][object] $Value,
        [Parameter(Mandatory = $true)][string] $Kind
    )

    switch -CaseSensitive ($Kind) {
        'string' { return (Test-DeliveryJsonString -Value $Value) }
        'string-or-null' { return (($null -eq $Value) -or (Test-DeliveryJsonString -Value $Value)) }
        'integer' { return (($Value -is [int]) -or ($Value -is [long])) }
        'object' { return ($Value -is [System.Management.Automation.PSCustomObject]) }
        'array' { return ($Value -is [System.Array]) }
        'array-or-string' { return ((Test-DeliveryJsonString -Value $Value) -or ($Value -is [System.Array])) }
        'string-array' {
            if ($Value -isnot [System.Array]) { return $false }
            foreach ($item in $Value) {
                if (-not (Test-DeliveryJsonString -Value $item)) { return $false }
            }
            return $true
        }
        'object-array' {
            if ($Value -isnot [System.Array]) { return $false }
            foreach ($item in $Value) {
                if ($item -isnot [System.Management.Automation.PSCustomObject]) { return $false }
            }
            return $true
        }
        'evidence-slug' { return (($Value -is [string]) -and ($Value -cmatch '^[a-z0-9][a-z0-9-]*$')) }
        'evidence-ref-or-null' {
            return (($null -eq $Value) -or (($Value -is [string]) -and ($Value -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]*/[a-z0-9][a-z0-9-]*$')))
        }
        'non-blank-string' { return (($Value -is [string]) -and ($Value.Trim().Length -gt 0)) }
        'sha256-hex' { return (($Value -is [string]) -and ($Value -cmatch '^[0-9A-F]{64}$')) }
    }
    return $false
}

function Get-DeliveryValueDescription {
    param([Parameter(Mandatory = $true)][string] $Kind)

    switch -CaseSensitive ($Kind) {
        'string' { return 'a string' }
        'string-or-null' { return 'a string or null' }
        'integer' { return 'an integer' }
        'object' { return 'an object' }
        'array' { return 'an array' }
        'array-or-string' { return 'an array or a string' }
        'string-array' { return 'an array of strings' }
        'object-array' { return 'an array of objects' }
        'evidence-slug' { return 'a lowercase evidence name' }
        'evidence-ref-or-null' { return 'a string in the form <step-id>/<name>, or null' }
        'non-blank-string' { return 'a non-blank string' }
        'sha256-hex' { return 'an uppercase hexadecimal SHA-256 digest of 64 characters' }
    }
    return 'a valid value'
}

function Get-DeliveryObjectFieldIssues {
    param(
        [Parameter(Mandatory = $true)][string] $Type,
        [Parameter(Mandatory = $true)][object] $Object,
        [Parameter(Mandatory = $true)][object[]] $Specs,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Prefix,
        [Parameter(Mandatory = $true)][int] $Line
    )

    $issues = [System.Collections.Generic.List[object]]::new()
    $isTopLevel = ($Prefix -ceq '')
    $stateProperty = Get-DeliveryExactProperty -Object $Object -Name 'state'
    $isApproved = $isTopLevel -and ($null -ne $stateProperty) -and ($stateProperty.Value -is [string]) -and ($stateProperty.Value -ceq 'approved')

    foreach ($property in @($Object.PSObject.Properties)) {
        $name = [string]$property.Name
        if ($isTopLevel -and ($name -ceq 'schema')) { continue }

        $displayName = $Prefix + $name
        $spec = Find-DeliveryFieldSpec -Specs $Specs -Name $name
        if ($null -eq $spec) {
            $issues.Add((New-DeliveryIssue -Code 'unknown_property' -Message ('{0} block property ''{1}'' is not allowed.' -f $Type, $displayName) -Line $Line))
            continue
        }

        $value = $property.Value
        if (-not (Test-DeliveryValueKind -Value $value -Kind $spec.Kind)) {
            $issues.Add((New-DeliveryIssue -Code 'invalid_field' -Message ('{0} block field ''{1}'' must be {2}.' -f $Type, $displayName, (Get-DeliveryValueDescription -Kind $spec.Kind)) -Line $Line))
            continue
        }

        $allowed = @($spec.Allowed)
        if (($allowed.Count -gt 0) -and (($value -isnot [string]) -or ($allowed -cnotcontains $value))) {
            $issues.Add((New-DeliveryIssue -Code 'invalid_field' -Message ('{0} block field ''{1}'' must be one of: {2}.' -f $Type, $displayName, ($allowed -join ', ')) -Line $Line))
            continue
        }

        if (($spec.Kind -ceq 'object') -or ($spec.Kind -ceq 'object-array')) {
            $nestedSpecs = @(Get-DeliveryNestedFieldSpecs -Name $name)
            if ($nestedSpecs.Count -gt 0) {
                if ($spec.Kind -ceq 'object') {
                    foreach ($issue in @(Get-DeliveryObjectFieldIssues -Type $Type -Object $value -Specs $nestedSpecs -Prefix ($displayName + '.') -Line $Line)) {
                        $issues.Add($issue)
                    }
                }
                else {
                    $entries = @($value)
                    for ($entryIndex = 0; $entryIndex -lt $entries.Count; $entryIndex++) {
                        $entry = $entries[$entryIndex]
                        foreach ($issue in @(Get-DeliveryObjectFieldIssues -Type $Type -Object $entry -Specs $nestedSpecs -Prefix ('{0}[{1}].' -f $displayName, $entryIndex) -Line $Line)) {
                            $issues.Add($issue)
                        }
                    }
                }
            }
        }
    }

    foreach ($spec in @($Specs)) {
        if ($null -ne (Get-DeliveryExactProperty -Object $Object -Name $spec.Name)) { continue }
        $isRequired = [bool]$spec.Required -or ($isApproved -and [bool]$spec.RequiredWhenApproved)
        if ($isRequired) {
            $issues.Add((New-DeliveryIssue -Code 'missing_field' -Message ('{0} block is missing required field ''{1}''.' -f $Type, ($Prefix + $spec.Name)) -Line $Line))
        }
    }

    return $issues.ToArray()
}

function Get-DeliveryCheckpointLocationIssues {
    param(
        [Parameter(Mandatory = $true)][object] $Object,
        [Parameter(Mandatory = $true)][int] $Line
    )

    $issues = [System.Collections.Generic.List[object]]::new()
    $kindProperty = Get-DeliveryExactProperty -Object $Object -Name 'location_kind'
    if (($null -eq $kindProperty) -or ($kindProperty.Value -isnot [string]) -or ($kindProperty.Value -cne 'directory')) {
        return $issues.ToArray()
    }

    foreach ($name in @('branch', 'head')) {
        $property = Get-DeliveryExactProperty -Object $Object -Name $name
        if (($null -ne $property) -and ($property.Value -is [string]) -and ($property.Value -cne '')) {
            $issues.Add((New-DeliveryIssue -Code 'invalid_field' -Message ('CHECKPOINT block field ''{0}'' must be an empty string when location_kind is directory.' -f $name) -Line $Line))
        }
    }

    $baselineProperty = Get-DeliveryExactProperty -Object $Object -Name 'baseline_evidence'
    if ($null -eq $baselineProperty) {
        $issues.Add((New-DeliveryIssue -Code 'missing_field' -Message 'CHECKPOINT block is missing field ''baseline_evidence'', which is required when location_kind is directory.' -Line $Line))
    }
    elseif ($null -eq $baselineProperty.Value) {
        $issues.Add((New-DeliveryIssue -Code 'invalid_field' -Message 'CHECKPOINT block field ''baseline_evidence'' must be a non-blank string when location_kind is directory.' -Line $Line))
    }

    return $issues.ToArray()
}

function Get-DeliveryPayloadResult {
    param(
        [Parameter(Mandatory = $true)][string] $Type,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Payload,
        [Parameter(Mandatory = $true)][int] $Line
    )

    $issues = [System.Collections.Generic.List[object]]::new()
    $json = $null
    $parsed = $null
    $parsedOk = $false

    if ($Payload.Trim().Length -gt 0) {
        try {
            $parsed = ConvertFrom-Json -InputObject $Payload -ErrorAction Stop
            $parsedOk = $true
        }
        catch {
            $parsedOk = $false
        }
    }

    if (-not $parsedOk) {
        $issues.Add((New-DeliveryIssue -Code 'invalid_json' -Message 'Block payload is not valid JSON.' -Line $Line))
    }
    elseif ($parsed -isnot [System.Management.Automation.PSCustomObject]) {
        $issues.Add((New-DeliveryIssue -Code 'json_not_object' -Message 'Block payload must be a single JSON object.' -Line $Line))
    }
    else {
        $json = $parsed
        $schemaProperty = Get-DeliveryExactProperty -Object $parsed -Name 'schema'
        if ($null -eq $schemaProperty) {
            $issues.Add((New-DeliveryIssue -Code 'missing_schema' -Message ('{0} block has no schema property.' -f $Type) -Line $Line))
        }
        elseif (-not (Test-DeliveryJsonString -Value $schemaProperty.Value)) {
            $issues.Add((New-DeliveryIssue -Code 'invalid_field' -Message ('{0} block field ''schema'' must be a string.' -f $Type) -Line $Line))
        }
        elseif (($schemaProperty.Value -isnot [string]) -or ($schemaProperty.Value -cne (Get-DeliveryExpectedSchema -Type $Type))) {
            $issues.Add((New-DeliveryIssue -Code 'wrong_schema' -Message ('{0} block schema must be {1}.' -f $Type, (Get-DeliveryExpectedSchema -Type $Type)) -Line $Line))
        }

        foreach ($issue in @(Get-DeliveryObjectFieldIssues -Type $Type -Object $parsed -Specs @(Get-DeliveryFieldSpecs -Type $Type) -Prefix '' -Line $Line)) {
            $issues.Add($issue)
        }

        if ($Type -ceq 'CHECKPOINT') {
            foreach ($issue in @(Get-DeliveryCheckpointLocationIssues -Object $parsed -Line $Line)) {
                $issues.Add($issue)
            }
        }
    }

    return [pscustomobject]@{ Json = $json; Issues = $issues.ToArray() }
}

function Read-DeliveryBlocks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    $lines = (ConvertTo-DeliveryNormalizedText -Text $Text).Split([char]10)
    $errors = [System.Collections.Generic.List[object]]::new()
    $blocks = [System.Collections.Generic.List[object]]::new()
    $seenTypes = @{}
    $seenStepIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $fence = $null
    $open = $null

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $lineNumber = $index + 1

        if ($null -ne $fence) {
            if (Test-DeliveryFenceCloser -Line $line -FenceChar $fence.Char -MinLength $fence.Length) {
                $fence = $null
            }
            if ($null -ne $open) { $open.Lines.Add($line) }
            continue
        }

        $opener = Get-DeliveryFenceOpener -Line $line
        if ($null -ne $opener) {
            $fence = [pscustomobject]@{ Char = $opener.Char; Length = $opener.Length; Line = $lineNumber }
            if ($null -ne $open) { $open.Lines.Add($line) }
            continue
        }

        if ($line.StartsWith('<!-- DELIVERY:', [System.StringComparison]::Ordinal)) {
            $match = [regex]::Match($line, '^<!-- DELIVERY:(PROGRESS|CHECKPOINT|APPROVAL):(BEGIN|END) -->$')
            if ($match.Success) {
                $type = $match.Groups[1].Value
                $id = $null
            }
            else {
                $match = [regex]::Match($line, '^<!-- DELIVERY:STEP:([A-Za-z0-9][A-Za-z0-9._-]*):(BEGIN|END) -->$')
                if (-not $match.Success) {
                    $issue = Get-DeliveryMarkerIssueCode -Line $line
                    $errors.Add((New-DeliveryIssue -Code $issue.code -Message $issue.message -Line $lineNumber))
                    if ($null -ne $open) { $open.Lines.Add($line) }
                    continue
                }
                $type = 'STEP'
                $id = $match.Groups[1].Value
            }
            $edge = $match.Groups[2].Value

            if ($edge -ceq 'BEGIN') {
                if ($null -ne $open) {
                    $errors.Add((New-DeliveryIssue -Code 'nested_block' -Message ('BEGIN marker found inside the block opened at line {0}; the outer block is discarded.' -f $open.StartLine) -Line $lineNumber))
                }
                $open = [pscustomobject]@{
                    Type      = $type
                    Id        = $id
                    StartLine = $lineNumber
                    Lines     = [System.Collections.Generic.List[string]]::new()
                }
                continue
            }

            if ($null -eq $open) {
                $errors.Add((New-DeliveryIssue -Code 'unbalanced_block' -Message 'END marker has no matching BEGIN marker.' -Line $lineNumber))
                continue
            }
            if (([string]$open.Type -cne $type) -or ([string]$open.Id -cne [string]$id)) {
                $errors.Add((New-DeliveryIssue -Code 'mismatched_end' -Message ('END marker does not match the block opened at line {0}; that block is discarded.' -f $open.StartLine) -Line $lineNumber))
                $open = $null
                continue
            }

            $startLine = [int]$open.StartLine
            $payload = [string]::Join("`n", $open.Lines.ToArray())
            $parsedBlock = Get-DeliveryPayloadResult -Type $type -Payload $payload -Line $startLine
            foreach ($issue in $parsedBlock.Issues) { $errors.Add($issue) }

            if ($type -ceq 'STEP') {
                if ($null -ne $parsedBlock.Json) {
                    $idValue = $null
                    $idProperty = @($parsedBlock.Json.PSObject.Properties | Where-Object { $_.Name -ceq 'id' })
                    if ($idProperty.Count -gt 0) { $idValue = $idProperty[0].Value }
                    if (-not (($idValue -is [string]) -and ($idValue -ceq $id))) {
                        $errors.Add((New-DeliveryIssue -Code 'step_id_mismatch' -Message ('STEP block payload id must equal the marker id {0}.' -f $id) -Line $startLine))
                    }
                }
                if (-not $seenStepIds.Add([string]$id)) {
                    $errors.Add((New-DeliveryIssue -Code 'duplicate_step_id' -Message ('STEP id {0} appears more than once.' -f $id) -Line $startLine))
                }
            }
            else {
                if ($seenTypes.ContainsKey($type)) {
                    $errors.Add((New-DeliveryIssue -Code 'duplicate_block' -Message ('{0} block appears more than once.' -f $type) -Line $startLine))
                }
                $seenTypes[$type] = $true
            }

            $blocks.Add([pscustomobject]@{
                    Type      = $type
                    Id        = $id
                    Payload   = $payload
                    Json      = $parsedBlock.Json
                    StartLine = $startLine
                    EndLine   = $lineNumber
                })
            $open = $null
            continue
        }

        if ($null -ne $open) { $open.Lines.Add($line) }
    }

    if ($null -ne $fence) {
        $errors.Add((New-DeliveryIssue -Code 'unclosed_fence' -Message ('Fenced code block opened at line {0} is not closed before end of text.' -f $fence.Line) -Line $fence.Line))
    }

    if ($null -ne $open) {
        $errors.Add((New-DeliveryIssue -Code 'unbalanced_block' -Message 'BEGIN marker has no matching END marker.' -Line ([int]$open.StartLine)))
    }

    return [pscustomobject]@{
        Ok     = ($errors.Count -eq 0)
        Errors = $errors.ToArray()
        Blocks = $blocks.ToArray()
    }
}

function Get-DeliveryNormativeProjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    $normalized = ConvertTo-DeliveryNormalizedText -Text $Text
    $result = Read-DeliveryBlocks -Text $normalized
    if (-not $result.Ok) {
        $codes = @($result.Errors | ForEach-Object { [string]$_.code } | Select-Object -Unique)
        throw ('Normative projection requires valid DELIVERY blocks: {0}' -f ($codes -join ', '))
    }

    $lines = $normalized.Split([char]10)
    $remove = [bool[]]::new($lines.Count)
    foreach ($block in $result.Blocks) {
        for ($lineNumber = $block.StartLine; $lineNumber -le $block.EndLine; $lineNumber++) {
            $remove[$lineNumber - 1] = $true
        }
    }

    $kept = [System.Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if (-not $remove[$index]) { $kept.Add($lines[$index]) }
    }

    $projection = [string]::Join("`n", $kept.ToArray()).TrimEnd([char]10)
    return $projection + "`n"
}

function Get-DeliveryNormativeIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    return Get-DeliverySha256Hex -Text (Get-DeliveryNormativeProjection -Text $Text)
}

function Get-DeliveryBlockHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Payload
    )

    $normalized = (ConvertTo-DeliveryNormalizedText -Text $Payload).TrimEnd([char]10)
    return Get-DeliverySha256Hex -Text $normalized
}

function Test-DeliveryRequiredBlocks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object] $Result,
        [Parameter(Mandatory = $true)][ValidateSet('PLAN', 'REFINEMENT')][string] $Kind,
        [string[]] $StepIds = @()
    )

    $blocks = @($Result.Blocks)
    $issues = [System.Collections.Generic.List[object]]::new()

    if ($Kind -eq 'PLAN') {
        $singleTypes = @('PROGRESS', 'CHECKPOINT', 'APPROVAL')
    }
    else {
        $singleTypes = @('APPROVAL')
    }

    foreach ($type in $singleTypes) {
        $count = @($blocks | Where-Object { $_.Type -ceq $type }).Count
        if ($count -eq 0) {
            $issues.Add((New-DeliveryRequirementIssue -Code 'missing_block' -Message ('Required {0} block is missing.' -f $type)))
        }
        elseif ($count -gt 1) {
            $issues.Add((New-DeliveryRequirementIssue -Code 'unexpected_block' -Message ('{0} block must appear exactly once.' -f $type)))
        }
    }

    if ($Kind -eq 'PLAN') {
        foreach ($id in $StepIds) {
            $count = @($blocks | Where-Object { $_.Type -ceq 'STEP' -and $_.Id -ceq $id }).Count
            if ($count -eq 0) {
                $issues.Add((New-DeliveryRequirementIssue -Code 'missing_step' -Message ('Declared STEP {0} has no block.' -f $id)))
            }
            elseif ($count -gt 1) {
                $issues.Add((New-DeliveryRequirementIssue -Code 'unexpected_block' -Message ('STEP {0} block must appear exactly once.' -f $id)))
            }
        }
        foreach ($block in @($blocks | Where-Object { $_.Type -ceq 'STEP' })) {
            if ($StepIds -cnotcontains $block.Id) {
                $issues.Add((New-DeliveryRequirementIssue -Code 'undeclared_step' -Message ('STEP {0} is not declared in the PLAN.' -f $block.Id)))
            }
        }
    }
    else {
        foreach ($block in $blocks) {
            if ($block.Type -cne 'APPROVAL') {
                $issues.Add((New-DeliveryRequirementIssue -Code 'unexpected_block' -Message ('{0} block is not allowed in a REFINEMENT.' -f $block.Type)))
            }
        }
    }

    return $issues.ToArray()
}

function Get-DeliveryEvidenceNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Value,
        [Parameter(Mandatory = $true)][int] $Line,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]] $Errors
    )

    $names = [System.Collections.Generic.List[string]]::new()
    if ($Value -ceq 'none') { return , $names.ToArray() }

    $tokens = @($Value.Split(','))
    if (($tokens.Count -gt 1) -and (@($tokens | Where-Object { $_.Trim() -ceq 'none' }).Count -gt 0)) {
        $Errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message 'Evidence line combines ''none'' with other names.' -Line $Line))
        return , $names.ToArray()
    }

    foreach ($token in $tokens) {
        $name = $token.Trim()
        if ($name.Length -eq 0) {
            $Errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message 'Evidence line has an empty name between commas.' -Line $Line))
            continue
        }
        if ($name -cnotmatch '^[a-z0-9][a-z0-9-]*$') {
            $Errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message ('Evidence name ''{0}'' must match ^[a-z0-9][a-z0-9-]*$.' -f $name) -Line $Line))
            continue
        }
        if ($names.Contains($name)) {
            $Errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message ('Evidence name ''{0}'' is declared more than once in the same step.' -f $name) -Line $Line))
            continue
        }
        $names.Add($name)
    }

    return , $names.ToArray()
}

function Get-DeliveryNeedsReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Value,
        [Parameter(Mandatory = $true)][int] $Line,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]] $Errors
    )

    $references = [System.Collections.Generic.List[object]]::new()
    if ($Value -ceq 'none') { return , $references.ToArray() }

    $tokens = @($Value.Split(','))
    if (($tokens.Count -gt 1) -and (@($tokens | Where-Object { $_.Trim() -ceq 'none' }).Count -gt 0)) {
        $Errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message 'Needs evidence line combines ''none'' with other references.' -Line $Line))
        return , $references.ToArray()
    }

    foreach ($token in $tokens) {
        $reference = $token.Trim()
        $match = [regex]::Match($reference, '^([A-Za-z0-9][A-Za-z0-9._-]*)/([a-z0-9][a-z0-9-]*)$')
        if (-not $match.Success) {
            $Errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message ('Needs evidence token ''{0}'' must have the form <step-id>/<name>.' -f $reference) -Line $Line))
            continue
        }
        $references.Add([pscustomobject]@{ Step = $match.Groups[1].Value; Name = $match.Groups[2].Value })
    }

    return , $references.ToArray()
}

function Get-DeliveryDeclaredSteps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    $lines = (ConvertTo-DeliveryNormalizedText -Text $Text).Split([char]10)
    $errors = [System.Collections.Generic.List[object]]::new()
    $steps = [System.Collections.Generic.List[object]]::new()
    $seenIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $seenFoldedIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $sectionFound = $false
    $inSection = $false
    $current = $null
    $fence = $null

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $lineNumber = $index + 1

        if ($null -ne $fence) {
            if (Test-DeliveryFenceCloser -Line $line -FenceChar $fence.Char -MinLength $fence.Length) {
                $fence = $null
            }
            continue
        }

        $opener = Get-DeliveryFenceOpener -Line $line
        if ($null -ne $opener) {
            $fence = [pscustomobject]@{ Char = $opener.Char; Length = $opener.Length }
            continue
        }

        $sectionMatch = [regex]::Match($line, '^## (.*)$')
        if ($sectionMatch.Success) {
            $title = [regex]::Replace($sectionMatch.Groups[1].Value.Trim(), '^\d+\. ', '')
            $inSection = (($title -ieq 'Steps') -or ($title -ieq 'Step'))
            if ($inSection) { $sectionFound = $true }
            $current = $null
            continue
        }
        if (-not $inSection) { continue }

        $stepMatch = [regex]::Match($line, '^### (.*)$')
        if ($stepMatch.Success) {
            $current = $null
            $token = ($stepMatch.Groups[1].Value.Trim() -split '\s+')[0]
            if ($token -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
                $errors.Add((New-DeliveryIssue -Code 'step_id_invalid' -Message ('Step heading id ''{0}'' does not match the step id pattern.' -f $token) -Line $lineNumber))
                continue
            }
            if ($token.Contains('--')) {
                $errors.Add((New-DeliveryIssue -Code 'step_id_invalid' -Message ('Step heading id ''{0}'' contains a double hyphen, which is reserved as the evidence file separator.' -f $token) -Line $lineNumber))
                continue
            }
            if (-not $seenIds.Add($token)) {
                $errors.Add((New-DeliveryIssue -Code 'duplicate_declared_step' -Message ('Step {0} is declared more than once.' -f $token) -Line $lineNumber))
                continue
            }
            if (-not $seenFoldedIds.Add($token)) {
                $errors.Add((New-DeliveryIssue -Code 'duplicate_declared_step' -Message ('Step {0} differs only by case from an earlier step id; file systems alias them.' -f $token) -Line $lineNumber))
                continue
            }
            $current = [pscustomobject]@{ Id = $token; DependsOn = $null; Validation = ''; Line = $lineNumber; Evidence = $null; Needs = $null }
            $steps.Add($current)
            continue
        }
        if ($null -eq $current) { continue }

        $dependsMatch = [regex]::Match($line, '^Depends on:[ \t]*(.*?)[ \t]*$')
        if ($dependsMatch.Success) {
            $value = $dependsMatch.Groups[1].Value
            if (($null -eq $current.DependsOn) -and ($value -ceq 'none')) {
                $current.DependsOn = [string[]]@()
            }
            elseif (($null -eq $current.DependsOn) -and ($value.Length -gt 0)) {
                $current.DependsOn = [string[]]@($value.Split(',') | ForEach-Object { $_.Trim() })
            }
            continue
        }

        $validationMatch = [regex]::Match($line, '^Validation:[ \t]*(.*?)[ \t]*$')
        if ($validationMatch.Success -and ([string]::IsNullOrEmpty($current.Validation))) {
            $current.Validation = $validationMatch.Groups[1].Value
        }

        $evidenceMatch = [regex]::Match($line, '^Evidence:[ \t]*(.*?)[ \t]*$')
        if ($evidenceMatch.Success) {
            if ($null -eq $current.Evidence) {
                $current.Evidence = Get-DeliveryEvidenceNames -Value $evidenceMatch.Groups[1].Value -Line $lineNumber -Errors $errors
            }
            else {
                $errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message ('Step {0} repeats the Evidence line; the second Evidence line is at line {1}.' -f $current.Id, $lineNumber) -Line $lineNumber))
            }
            continue
        }

        $needsMatch = [regex]::Match($line, '^Needs evidence:[ \t]*(.*?)[ \t]*$')
        if ($needsMatch.Success) {
            if ($null -eq $current.Needs) {
                $current.Needs = Get-DeliveryNeedsReferences -Value $needsMatch.Groups[1].Value -Line $lineNumber -Errors $errors
            }
            else {
                $errors.Add((New-DeliveryIssue -Code 'evidence_declaration_invalid' -Message ('Step {0} repeats the Needs evidence line; the second Needs evidence line is at line {1}.' -f $current.Id, $lineNumber) -Line $lineNumber))
            }
            continue
        }
    }

    if ($steps.Count -eq 0) {
        $message = if ($sectionFound) { 'The Steps section declares no valid step headings.' } else { 'The PLAN has no ## Steps section.' }
        $errors.Add((New-DeliveryIssue -Code 'steps_section_missing' -Message $message -Line 0))
    }
    foreach ($step in $steps) {
        if ($null -eq $step.DependsOn) {
            $errors.Add((New-DeliveryIssue -Code 'step_depends_missing' -Message ('Step {0} has no usable ''Depends on:'' line.' -f $step.Id) -Line $step.Line))
            $step.DependsOn = [string[]]@()
        }
        if ($null -eq $step.Evidence) { $step.Evidence = [string[]]@() }
        if ($null -eq $step.Needs) { $step.Needs = [object[]]@() }
        if ([string]::IsNullOrWhiteSpace($step.Validation)) {
            $errors.Add((New-DeliveryIssue -Code 'step_validation_missing' -Message ('Step {0} has no usable ''Validation:'' line.' -f $step.Id) -Line $step.Line))
        }
    }

    return [pscustomobject]@{ Steps = $steps.ToArray(); Errors = $errors.ToArray() }
}

function Get-DeliveryPlanDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    $lines = (ConvertTo-DeliveryNormalizedText -Text $Text).Split([char]10)
    $errors = [System.Collections.Generic.List[object]]::new()
    $dependencies = [System.Collections.Generic.List[object]]::new()
    $seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $sectionCount = 0
    $inSection = $false
    $fence = $null

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $lineNumber = $index + 1

        if ($null -ne $fence) {
            if (Test-DeliveryFenceCloser -Line $line -FenceChar $fence.Char -MinLength $fence.Length) {
                $fence = $null
            }
            continue
        }

        $opener = Get-DeliveryFenceOpener -Line $line
        if ($null -ne $opener) {
            $fence = [pscustomobject]@{ Char = $opener.Char; Length = $opener.Length }
            continue
        }

        $sectionMatch = [regex]::Match($line, '^## (.*)$')
        if ($sectionMatch.Success) {
            $title = [regex]::Replace($sectionMatch.Groups[1].Value.Trim(), '^\d+\. ', '')
            $inSection = ($title -ieq 'Plan dependencies')
            if ($inSection) {
                $sectionCount++
                if ($sectionCount -gt 1) {
                    $errors.Add((New-DeliveryIssue -Code 'plan_dependency_invalid' -Message 'The Plan dependencies heading appears more than once.' -Line $lineNumber))
                }
            }
            continue
        }

        if (-not $inSection) {
            if ($line.StartsWith('Requires plan:', [System.StringComparison]::Ordinal)) {
                $errors.Add((New-DeliveryIssue -Code 'plan_dependency_invalid' -Message 'Requires plan line is outside the Plan dependencies heading; dependency lines must live under that heading.' -Line $lineNumber))
            }
            continue
        }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $requiresMatch = [regex]::Match($line, '^Requires plan: (\S+) identity=(\S+) steps=(\S+)$')
        if (-not $requiresMatch.Success) {
            $errors.Add((New-DeliveryIssue -Code 'plan_dependency_invalid' -Message 'Plan dependencies accepts only lines of the form ''Requires plan: <path> identity=<HEX> steps=<id>[,<id>...]''.' -Line $lineNumber))
            continue
        }

        $path = $requiresMatch.Groups[1].Value
        $identity = $requiresMatch.Groups[2].Value
        $steps = [string[]]@($requiresMatch.Groups[3].Value.Split(','))
        $problem = ''

        if (($path.Contains('..')) -or ($path.Contains(':')) -or ($path.Contains('\')) -or $path.StartsWith('/', [System.StringComparison]::Ordinal)) {
            $problem = 'the path must be repository-relative, with forward slashes, and must not contain ''..'' or a drive'
        }
        elseif ($path -cnotmatch '^features/[0-9]{3}-[a-z0-9]+(?:-[a-z0-9]+)*/(?:US|TS)[0-9]{2}/PLAN\.md$') {
            $problem = 'the path must be features/NNN-slug/(US|TS)nn/PLAN.md'
        }
        elseif ($identity -cnotmatch '^[0-9A-F]{64}$') {
            $problem = 'the identity must be 64 uppercase hexadecimal characters'
        }
        else {
            foreach ($step in $steps) {
                if ($step -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
                    $problem = ('step id ''{0}'' does not match the step id pattern' -f $step)
                    break
                }
            }
        }
        if (($problem.Length -eq 0) -and -not $seenPaths.Add($path)) {
            $problem = 'a Requires plan line for this path already exists'
        }

        if ($problem.Length -gt 0) {
            $errors.Add((New-DeliveryIssue -Code 'plan_dependency_invalid' -Message ('Requires plan line for ''{0}'' is invalid: {1}.' -f $path, $problem) -Line $lineNumber))
            continue
        }

        $dependencies.Add([pscustomobject]@{
                Path     = $path
                Identity = $identity
                Steps    = $steps
                Line     = $lineNumber
            })
    }

    return [pscustomobject]@{ Dependencies = $dependencies.ToArray(); Errors = $errors.ToArray() }
}

function Get-DeliveryFencedLineMask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines
    )

    $mask = [bool[]]::new($Lines.Count)
    $fence = $null
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $line = $Lines[$index]
        if ($null -ne $fence) {
            $mask[$index] = $true
            if (Test-DeliveryFenceCloser -Line $line -FenceChar $fence.Char -MinLength $fence.Length) { $fence = $null }
            continue
        }

        $opener = Get-DeliveryFenceOpener -Line $line
        if ($null -ne $opener) {
            $mask[$index] = $true
            $fence = [pscustomobject]@{ Char = $opener.Char; Length = $opener.Length }
        }
    }
    return , $mask
}

function Get-DeliveryMarkdownHeadingLevel {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Line)

    $match = [regex]::Match($Line, '^(#{1,3})(?:[ \t].*)?$')
    if ($match.Success) { return $match.Groups[1].Value.Length }
    return 0
}

function Get-DeliveryRefinementItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    $lines = (ConvertTo-DeliveryNormalizedText -Text $Text).Split([char]10)
    $fenced = Get-DeliveryFencedLineMask -Lines $lines
    $errors = [System.Collections.Generic.List[object]]::new()
    $items = [System.Collections.Generic.List[object]]::new()
    $seenLines = [System.Collections.Generic.Dictionary[string, int]]::new([System.StringComparer]::Ordinal)

    $headings = [System.Collections.Generic.List[int]]::new()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($fenced[$index]) { continue }
        if ((Get-DeliveryMarkdownHeadingLevel -Line $lines[$index]) -gt 0) { $headings.Add($index) }
    }

    for ($position = 0; $position -lt $headings.Count; $position++) {
        $start = $headings[$position]
        $headingMatch = [regex]::Match($lines[$start], '^### (.*)$')
        if (-not $headingMatch.Success) { continue }
        $parts = @($headingMatch.Groups[1].Value.Trim() -split '[ \t]+', 2)
        $id = [string]$parts[0]
        if ($id -cnotmatch '^(D|CA|R)-[0-9]{3,}$') { continue }
        $title = ''
        if ($parts.Count -gt 1) { $title = ([string]$parts[1]).Trim() }

        $end = $lines.Count
        if ($position + 1 -lt $headings.Count) { $end = $headings[$position + 1] }
        $bodyLines = [System.Collections.Generic.List[string]]::new()
        for ($index = $start; $index -lt $end; $index++) { $bodyLines.Add($lines[$index]) }
        while (($bodyLines.Count -gt 0) -and [string]::IsNullOrWhiteSpace($bodyLines[$bodyLines.Count - 1])) {
            $bodyLines.RemoveAt($bodyLines.Count - 1)
        }
        $body = [string]::Join("`n", $bodyLines.ToArray()) + "`n"

        $lineNumber = $start + 1
        if ($seenLines.ContainsKey($id)) {
            $errors.Add((New-DeliveryIssue -Code 'refinement_item_invalid' -Message ('Refinement item {0} is defined at line {1} and again at line {2}.' -f $id, $seenLines[$id], $lineNumber) -Line $lineNumber))
            continue
        }
        $seenLines[$id] = $lineNumber

        $supersededBy = ''
        foreach ($bodyLine in $bodyLines) {
            $statusMatch = [regex]::Match($bodyLine, '^Status: superseded by (\S+)[ \t]*$')
            if ($statusMatch.Success) {
                $supersededBy = $statusMatch.Groups[1].Value
                break
            }
        }

        $items.Add([pscustomobject]@{
                Id           = $id
                Title        = $title
                Line         = $lineNumber
                Body         = $body
                Hash         = Get-DeliverySha256Hex -Text $body
                SupersededBy = $supersededBy
            })
    }

    return [pscustomobject]@{ Items = $items.ToArray(); Errors = $errors.ToArray() }
}

function Get-DeliveryRefinementReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text
    )

    $lines = (ConvertTo-DeliveryNormalizedText -Text $Text).Split([char]10)
    $fenced = Get-DeliveryFencedLineMask -Lines $lines
    $errors = [System.Collections.Generic.List[object]]::new()
    $references = [System.Collections.Generic.List[object]]::new()
    $seenLines = [System.Collections.Generic.Dictionary[string, int]]::new([System.StringComparer]::Ordinal)
    $sectionCount = 0
    $inSection = $false

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($fenced[$index]) { continue }
        $line = $lines[$index]
        $lineNumber = $index + 1

        $sectionMatch = [regex]::Match($line, '^## (.*)$')
        if ($sectionMatch.Success) {
            $title = [regex]::Replace($sectionMatch.Groups[1].Value.Trim(), '^\d+\. ', '')
            $inSection = ($title -ieq 'Refinement references')
            if ($inSection) {
                $sectionCount++
                if ($sectionCount -gt 1) {
                    $errors.Add((New-DeliveryIssue -Code 'refinement_reference_invalid' -Message 'The Refinement references heading appears more than once.' -Line $lineNumber))
                }
            }
            continue
        }

        if (-not $inSection) {
            if ($line.TrimStart().StartsWith('Uses:', [System.StringComparison]::Ordinal)) {
                $errors.Add((New-DeliveryIssue -Code 'refinement_reference_invalid' -Message 'Uses line is outside the Refinement references heading.' -Line $lineNumber))
            }
            continue
        }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $usesMatch = [regex]::Match($line, '^Uses: (\S+) (\S+) hash=(\S+)$')
        if (-not $usesMatch.Success) {
            $errors.Add((New-DeliveryIssue -Code 'refinement_reference_invalid' -Message 'Refinement references accepts only lines of the form ''Uses: <path> <ID> hash=<HEX>''.' -Line $lineNumber))
            continue
        }

        $path = $usesMatch.Groups[1].Value
        $id = $usesMatch.Groups[2].Value
        $hash = $usesMatch.Groups[3].Value
        $problem = ''
        if ($path -cnotmatch '^features/[0-9]{3}-[a-z0-9]+(?:-[a-z0-9]+)*/REFINEMENT\.md$') {
            $problem = 'the path must be features/NNN-slug/REFINEMENT.md with forward slashes and without ''..'' or a drive'
        }
        elseif ($id -cnotmatch '^(D|CA|R)-[0-9]{3,}$') {
            $problem = 'the ID must match ^(D|CA|R)-[0-9]{3,}$'
        }
        elseif ($hash -cnotmatch '^[0-9A-F]{64}$') {
            $problem = 'the hash must be 64 uppercase hexadecimal characters'
        }
        if ($problem.Length -gt 0) {
            $errors.Add((New-DeliveryIssue -Code 'refinement_reference_invalid' -Message ('Uses line for ''{0}'' {1} is invalid: {2}.' -f $path, $id, $problem) -Line $lineNumber))
            continue
        }

        $key = $path + "`n" + $id
        if ($seenLines.ContainsKey($key)) {
            $errors.Add((New-DeliveryIssue -Code 'refinement_reference_invalid' -Message ('Uses line for ''{0}'' {1} repeats the reference at line {2}.' -f $path, $id, $seenLines[$key]) -Line $lineNumber))
            continue
        }
        $seenLines[$key] = $lineNumber
        $references.Add([pscustomobject]@{ Path = $path; Id = $id; Hash = $hash; Line = $lineNumber })
    }

    return [pscustomobject]@{ References = $references.ToArray(); Errors = $errors.ToArray() }
}
