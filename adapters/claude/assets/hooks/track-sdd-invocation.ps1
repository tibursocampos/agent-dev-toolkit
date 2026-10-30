# Claude hook script - track SDD skill invocations; always allow continuation.
# Wiring into settings.json happens during settings merge. Smoke validates file presence only.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
$prompt = if ($inputJson -and $inputJson.prompt) { [string]$inputJson.prompt } else { '' }

if (Test-SddSkillPrompt $prompt) {
    if ($prompt -match '(?i)use\s+skill\s+(\S+)') {
        Set-SddState $Matches[1].ToLowerInvariant()
    }
}

Write-HookJson @{ continue = $true }
