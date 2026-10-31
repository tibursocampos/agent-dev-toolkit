# Claude hook script - SessionStart: add the current SDD preference state and the spawn digest as additional context.
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

$digestText = ''
try {
    $digestRelative = Join-Path (Join-Path (Join-Path 'skills' '_shared') 'agents') 'SPAWN-DIGEST.md'
    $digestCandidates = @(
        (Join-Path (Join-Path (Get-ClaudeHookUserHome) '.claude') $digestRelative),
        (Join-Path (Join-Path $PSScriptRoot '..\..\..\..\core') $digestRelative)
    )
    foreach ($candidate in $digestCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $digestText = [System.IO.File]::ReadAllText($candidate).Trim()
            break
        }
    }
}
catch {
    $digestText = ''
}

$context = (@($stateLine, $digestText) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n`n"

if ([string]::IsNullOrWhiteSpace($context)) {
    Write-Output '{"continue":true}'
    exit 0
}

$envelope = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $context } }
Write-Output ($envelope | ConvertTo-Json -Compress -Depth 5)
exit 0
