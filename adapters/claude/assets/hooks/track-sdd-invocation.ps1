# Claude hook script - track SDD skill invocations (`use skill <id>` or `/<id>`); always allow continuation.
# Wiring into settings.json happens during settings merge. Smoke validates file presence only.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

try {
    . "$PSScriptRoot\_hook-common.ps1"
    $inputJson = Read-HookInputJson
    $prompt = Get-HookPromptText -InputJson $inputJson
    if (Test-SddSkillPrompt $prompt) {
        $skillName = Get-SddSkillNameFromPrompt $prompt
        if ($skillName) {
            Set-SddState $skillName
        }
    }
}
catch {
    # Fail-open: skill tracking must never block the prompt.
}

Write-Output '{"continue":true}'
exit 0
