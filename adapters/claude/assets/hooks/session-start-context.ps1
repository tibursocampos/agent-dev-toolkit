# Claude hook script - SessionStart: add the current SDD preference state as additional context.
# Fail-open: on any error the session starts without the extra context.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$stateLine = ''
try {
    . "$PSScriptRoot\_hook-common.ps1"
    $stateLine = Format-ClaudePreferencesStateLine -Preferences (Read-ClaudePreferences)
}
catch {
    $stateLine = ''
}

if ([string]::IsNullOrWhiteSpace($stateLine)) {
    Write-Output '{"continue":true}'
    exit 0
}

$envelope = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $stateLine } }
Write-Output ($envelope | ConvertTo-Json -Compress -Depth 5)
exit 0
