# afterFileEdit - record when a PLAN file was edited (checkpoint aid for preCompact).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_hook-common.ps1"

$inputJson = Read-HookInputJson
$filePath = if ($inputJson -and $inputJson.file_path) { [string]$inputJson.file_path } else { '' }

if (Test-PlanFilePath $filePath) {
    Set-PlanEditState $filePath
}

# afterFileEdit has no supported output fields; exit 0 with no stdout payload.
exit 0
