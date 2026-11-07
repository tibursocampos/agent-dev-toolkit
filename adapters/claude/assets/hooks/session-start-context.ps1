# Claude hook script - SessionStart: report preferences. The always-on policy resolves effective subagent capability before loading spawn contracts.
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

$context = $stateLine

if ([string]::IsNullOrWhiteSpace($context)) {
    Write-Output '{"continue":true}'
    exit 0
}

$envelope = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $context } }
Write-Output ($envelope | ConvertTo-Json -Compress -Depth 5)
exit 0
