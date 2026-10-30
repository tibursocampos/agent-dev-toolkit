# Claude hook script - record when a PLAN file was edited (checkpoint aid).
# Wiring into settings.json happens during settings merge. Smoke validates file presence only.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
$filePath = Get-HookToolFilePath -InputJson $inputJson

if (Test-PlanFilePath $filePath) {
    Set-PlanEditState $filePath
}

exit 0
