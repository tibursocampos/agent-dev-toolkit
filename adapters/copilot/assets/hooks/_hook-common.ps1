# Shared helpers for Copilot hooks (Windows PowerShell 5.1+).
# Path/secret guards: adapters/_shared/GuardCommon.ps1 (published beside this file).

Set-StrictMode -Version Latest

$_guardCommonCandidates = @(
    (Join-Path $PSScriptRoot 'GuardCommon.ps1'),
    (Join-Path $PSScriptRoot '..\..\..\_shared\GuardCommon.ps1')
)
$_guardCommonLoaded = $false
foreach ($_guardCandidate in $_guardCommonCandidates) {
    try {
        $_guardFull = [System.IO.Path]::GetFullPath($_guardCandidate)
    }
    catch {
        continue
    }
    if (Test-Path -LiteralPath $_guardFull) {
        . $_guardFull
        $_guardCommonLoaded = $true
        break
    }
}
if (-not $_guardCommonLoaded) {
    throw "GuardCommon.ps1 not found relative to $PSScriptRoot."
}
Remove-Variable -Name _guardCommonCandidates, _guardCommonLoaded, _guardCandidate, _guardFull -ErrorAction SilentlyContinue

function Read-HookInputJson {
    $raw = [Console]::In.ReadToEnd()
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

function Write-CopilotPreToolAllow {
    Write-Output '{"permissionDecision":"allow"}'
    exit 0
}

function Write-CopilotPreToolDeny([string] $Reason) {
    $payload = [ordered]@{
        permissionDecision       = 'deny'
        permissionDecisionReason = $Reason
    }
    Write-Output ($payload | ConvertTo-Json -Compress -Depth 5)
    # Copilot CLI: exit 2 denies the tool call.
    exit 2
}
