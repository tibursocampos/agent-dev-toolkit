# Claude hook script - UserPromptSubmit preference commands (orchestrator and caveman).
# Updates sdd/preferences.json under the user home and returns a confirmation as additional context.
# Fail-open: any error lets the prompt continue unchanged.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

function Invoke-ClaudePreferenceCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Prompt
    )

    $text = $Prompt.Trim().ToLowerInvariant()
    $orchestratorMatch = [regex]::Match($text, '^(orchestrator|orchestrate|parent)\s+(always|adaptive|status)$')
    $cavemanMatch = [regex]::Match($text, '^caveman\s+(on|off|status|lite|full|ultra)$')
    $cavemanOff = ($text -eq 'stop caveman') -or ($text -eq 'normal mode')
    if (-not $orchestratorMatch.Success -and -not $cavemanMatch.Success -and -not $cavemanOff) {
        return ''
    }

    $preferences = Read-ClaudePreferences
    if (-not $preferences.Readable) {
        return ('[Toolkit] Preferences file is unreadable; not changed ({0}).' -f $preferences.Path)
    }
    $values = $preferences.Values

    if ($orchestratorMatch.Success) {
        $mode = $orchestratorMatch.Groups[2].Value
        if ($mode -eq 'status') {
            $current = [string]$values['orchestrator_mode']
            if ([string]::IsNullOrWhiteSpace($current)) {
                $current = 'missing'
            }
            return ('[Orchestrator] Mode active: {0}. Type orchestrator status to review.' -f $current)
        }
        $values['orchestrator_mode'] = $mode
        Write-ClaudePreferences -Values $values
        if ($mode -eq 'always') {
            return '[Orchestrator] Mode set to always (parent orchestrator enforced).'
        }
        return '[Orchestrator] Mode set to adaptive (may keep thin trivial work in-parent).'
    }

    $action = 'off'
    if ($cavemanMatch.Success) {
        $action = $cavemanMatch.Groups[1].Value
    }

    if ($action -eq 'status') {
        $state = 'off'
        if ([bool]$values['caveman_mode']) {
            $state = 'on'
        }
        return ('[Caveman] Mode {0}, level={1}.' -f $state, $values['caveman_level'])
    }

    if ($action -eq 'off') {
        $values['caveman_mode'] = $false
        Write-ClaudePreferences -Values $values
        return '[Caveman] Modo desativado.'
    }

    $values['caveman_mode'] = $true
    if ($action -eq 'on') {
        if ([string]::IsNullOrWhiteSpace([string]$values['caveman_level'])) {
            $values['caveman_level'] = 'full'
        }
        Write-ClaudePreferences -Values $values
        return '[Caveman] Modo ativado (respostas compactas).'
    }

    $values['caveman_level'] = $action
    Write-ClaudePreferences -Values $values
    return ('[Caveman] Modo ativo (respostas compactas, level={0}).' -f $action)
}

$message = ''
try {
    . "$PSScriptRoot\_hook-common.ps1"
    $inputJson = Read-HookInputJson
    $message = Invoke-ClaudePreferenceCommand -Prompt (Get-HookPromptText -InputJson $inputJson)
}
catch {
    $message = ''
}

if ([string]::IsNullOrWhiteSpace($message)) {
    Write-Output '{"continue":true}'
    exit 0
}

$envelope = @{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = $message } }
Write-Output ($envelope | ConvertTo-Json -Compress -Depth 5)
exit 0
