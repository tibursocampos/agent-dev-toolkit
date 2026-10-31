#Requires -Version 5.1
# ZCode SessionStart hook: emit the spawn digest as additional context.
# Fail-open: any error exits 0 without output so the session still starts.
# The optional first argument is an ownership marker used by the uninstaller.
param([string] $Marker)
$ErrorActionPreference = 'Stop'

try {
    $digestRelative = Join-Path (Join-Path (Join-Path 'skills' '_shared') 'agents') 'SPAWN-DIGEST.md'
    $candidates = @(
        (Join-Path (Split-Path -Parent $PSScriptRoot) $digestRelative),
        (Join-Path (Join-Path $PSScriptRoot '..\..\..\core') $digestRelative)
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $text = [System.IO.File]::ReadAllText($candidate).Trim()
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $envelope = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $text } }
                Write-Output ($envelope | ConvertTo-Json -Compress -Depth 5)
            }
            break
        }
    }
}
catch {
}
exit 0
