# Claude TRACE emitter - PostToolUse / SubagentStop (REQ-006 / CA6).
# Fail-open: never blocks the host skill; never echoes tool bodies.

#Requires -Version 5.1
$ErrorActionPreference = 'Continue'

try {
    . "$PSScriptRoot\_hook-common.ps1"
}
catch {
    exit 0
}

$_traceEmitCandidates = @(
    (Join-Path $PSScriptRoot 'TraceEmitCommon.ps1'),
    (Join-Path $PSScriptRoot '..\..\..\_shared\TraceEmitCommon.ps1')
)
$_traceEmitLoaded = $false
foreach ($_traceCandidate in $_traceEmitCandidates) {
    try {
        $_traceFull = [System.IO.Path]::GetFullPath($_traceCandidate)
    }
    catch {
        continue
    }
    if (Test-Path -LiteralPath $_traceFull) {
        try {
            . $_traceFull
            $_traceEmitLoaded = $true
            break
        }
        catch {
            continue
        }
    }
}
Remove-Variable -Name _traceEmitCandidates, _traceCandidate, _traceFull -ErrorAction SilentlyContinue

if (-not $_traceEmitLoaded) {
    exit 0
}
Remove-Variable -Name _traceEmitLoaded -ErrorAction SilentlyContinue

try {
    $inputJson = Read-HookInputJson
    $hookName = ''
    if ($inputJson -and ($inputJson.PSObject.Properties.Name -contains 'hook_event_name')) {
        $hookName = [string]$inputJson.hook_event_name
    }
    elseif ($inputJson -and ($inputJson.PSObject.Properties.Name -contains 'hookEventName')) {
        $hookName = [string]$inputJson.hookEventName
    }
    $null = Invoke-TraceEmitterFromHookInput -InputObject $inputJson -HostId 'claude' -HookName $hookName
}
catch {
    # Fail-open: swallow.
}

exit 0
