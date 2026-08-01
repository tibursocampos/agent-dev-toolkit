#Requires -Version 5.1
<#
.SYNOPSIS
  Validates -Mode for GitHub Copilot agent orchestration (TE02 / CA3).

.DESCRIPTION
  Copilot sync/validate/uninstall require -Mode user|repo. Other agents ignore Mode.
#>

$toolkitLibDirForMode = $PSScriptRoot
. (Join-Path $toolkitLibDirForMode 'ToolkitConstants.ps1')

function Test-IsCopilotAgentId {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        return $false
    }

    return [string]::Equals($AgentId.Trim(), $script:ToolkitConstant.CopilotAgentId, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-CopilotValidModeList {
    return @($script:ToolkitConstant.CopilotValidModes)
}

function Assert-CopilotAgentMode {
    <#
    .SYNOPSIS
      Fail closed when agent is copilot and -Mode is missing or not user|repo (TE02).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId,

        [Parameter()]
        [AllowEmptyString()]
        [string] $Mode
    )

    if (-not (Test-IsCopilotAgentId -AgentId $AgentId)) {
        return $null
    }

    $validModes = Get-CopilotValidModeList
    $validList = ($validModes -join ', ')
    $agentKey = $script:ToolkitConstant.CopilotAgentId

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        throw ($script:ToolkitMessage.CopilotModeRequired -f $agentKey, $validList, $agentKey)
    }

    $normalized = $Mode.Trim().ToLowerInvariant()
    $isValid = $false
    foreach ($candidate in $validModes) {
        if ([string]::Equals($normalized, $candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
            $isValid = $true
            break
        }
    }

    if (-not $isValid) {
        throw ($script:ToolkitMessage.CopilotModeInvalid -f $Mode.Trim(), $agentKey, $validList, $agentKey)
    }

    return $normalized
}
