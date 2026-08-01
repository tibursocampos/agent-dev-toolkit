#Requires -Version 5.1
<#
.SYNOPSIS
  Shared interactive UI helpers for toolkit.ps1 Smart Manager.
#>

function Clear-ToolkitScreen {
    [CmdletBinding()]
    param()

    try {
        Clear-Host
    }
    catch {
        # Some hosts reject Clear-Host; continue without failing the CLI.
    }
}

function Show-ToolkitHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Title,

        [Parameter()]
        [string] $RepoRoot,

        [Parameter()]
        [string] $Subtitle
    )

    Write-Host ''
    Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan
    Write-Host (" {0}" -f $Title) -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-Host (" {0}" -f $Subtitle) -ForegroundColor DarkGray
    }
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        Write-Host (" Repo: {0}" -f $RepoRoot) -ForegroundColor DarkGray
    }
    Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan
}

function Write-ToolkitHint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    Write-Host $Message -ForegroundColor DarkGray
}

function Write-ToolkitWarn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    Write-Host $Message -ForegroundColor Yellow
}

function Write-ToolkitError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    Write-Host $Message -ForegroundColor Red
}

function Write-ToolkitSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    Write-Host $Message -ForegroundColor Green
}

function Write-ToolkitStepBanner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Title,

        [ConsoleColor] $Color = [ConsoleColor]::Cyan
    )

    Write-Host ''
    Write-Host ("========== {0} ==========" -f $Title) -ForegroundColor $Color
}

function Pause-Toolkit {
    [CmdletBinding()]
    param()

    Write-Host ''
    Write-ToolkitHint -Message $script:ToolkitMessage.ToolkitPressEnter
    $null = Read-Host
}

function Read-ToolkitChoice {
    <#
    .SYNOPSIS
      Prompt until the user enters a choice in ValidChoices (case-insensitive).
      Empty Enter returns -DefaultChoice when set. Never throws on invalid input.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Prompt,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $ValidChoices,

        [Parameter()]
        [string] $DefaultChoice
    )

    # Force a true string[]; never pass a bare '' as -ValidChoices (Mandatory bind fails).
    $normalizedValid = [System.Collections.Generic.List[string]]::new()
    foreach ($item in @($ValidChoices)) {
        if ($null -eq $item) {
            continue
        }
        $normalizedValid.Add([string]$item)
    }
    if ($normalizedValid.Count -lt 1) {
        throw 'Read-ToolkitChoice: ValidChoices must contain at least one non-null choice.'
    }

    $hasDefault = -not [string]::IsNullOrWhiteSpace($DefaultChoice)
    while ($true) {
        $raw = Read-Host $Prompt
        if ($null -eq $raw) {
            $raw = ''
        }
        $trimmed = $raw.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -and $hasDefault) {
            return $DefaultChoice.Trim()
        }
        foreach ($choice in $normalizedValid) {
            if ([string]::Equals($trimmed, $choice, [System.StringComparison]::OrdinalIgnoreCase)) {
                return $choice
            }
        }
        Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitInvalidMenuOptionRetry
    }
}

function Confirm-ToolkitYesNo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Prompt,

        [Parameter()]
        [bool] $DefaultYes = $false
    )

    $hint = if ($DefaultYes) {
        $script:ToolkitMessage.ToolkitYesNoHintDefaultYes
    }
    else {
        $script:ToolkitMessage.ToolkitYesNoHintDefaultNo
    }
    $fullPrompt = '{0} {1}' -f $Prompt, $hint
    # Do not include '' in ValidChoices: Mandatory [string[]] rejects empty string on bind (PS 5.1/7).
    $valid = @(
        [string]$script:ToolkitConstant.ToolkitChoiceYes,
        [string]$script:ToolkitConstant.ToolkitChoiceNo,
        [string]$script:ToolkitConstant.ToolkitChoiceYesShort,
        [string]$script:ToolkitConstant.ToolkitChoiceNoShort
    )
    $defaultChoice = if ($DefaultYes) {
        [string]$script:ToolkitConstant.ToolkitChoiceYes
    }
    else {
        [string]$script:ToolkitConstant.ToolkitChoiceNo
    }
    $answer = Read-ToolkitChoice -Prompt $fullPrompt -ValidChoices $valid -DefaultChoice $defaultChoice
    return (
        [string]::Equals($answer, $script:ToolkitConstant.ToolkitChoiceYes, [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($answer, $script:ToolkitConstant.ToolkitChoiceYesShort, [System.StringComparison]::OrdinalIgnoreCase)
    )
}
