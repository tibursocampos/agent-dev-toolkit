# Shared helpers for the Codex SubagentStop trace hook (Windows PowerShell 5.1+).
# No path/secret guard is loaded here: Codex registers no PreToolUse hook.

Set-StrictMode -Version Latest

function Read-HookInputJson {
    $raw = ''
    try {
        $stream = [Console]::OpenStandardInput()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.UTF8Encoding]::new($false), $true, 4096, $true)
        $raw = $reader.ReadToEnd()
    }
    catch {
        $raw = ''
    }
    if ([string]::IsNullOrWhiteSpace($raw)) {
        try {
            $raw = [Console]::In.ReadToEnd()
        }
        catch {
            $raw = ''
        }
    }
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }
    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }
}

