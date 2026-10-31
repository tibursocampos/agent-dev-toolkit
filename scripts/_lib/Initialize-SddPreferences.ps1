#Requires -Version 5.1
<#
.SYNOPSIS
  Seed or prompt for {{SDD_ROOT}}/preferences.json (orchestrator + caveman schema).
#>

if (-not (Get-Variable -Scope Script -Name ToolkitConstant -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'ToolkitConstants.ps1')
}

if (-not (Get-Command -Name ConvertTo-ToolkitSddCleanJson -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'Initialize-SddRootLayout.ps1')
}

$script:ToolkitPreferencesConstant = @{
    FileName                 = 'preferences.json'
    DefaultOrchestratorMode  = 'adaptive'
    DefaultCavemanMode       = $true
    OrchestratorModeAlways   = 'always'
    OrchestratorModeAdaptive = 'adaptive'
}

function New-ToolkitDefaultPreferencesObject {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $OrchestratorMode
    )

    $mode = if ([string]::IsNullOrWhiteSpace($OrchestratorMode)) {
        $script:ToolkitPreferencesConstant.DefaultOrchestratorMode
    }
    else {
        $OrchestratorMode.Trim().ToLowerInvariant()
    }

    return [ordered]@{
        caveman_mode      = $script:ToolkitPreferencesConstant.DefaultCavemanMode
        caveman_level     = 'full'
        orchestrator_mode = $mode
        artifact_language = $null
        verify_mode       = $false
    }
}

function Resolve-ToolkitOrchestratorModeFromChoice {
    <#
    .SYNOPSIS
      Map a legacy menu choice to always or adaptive. First sync does not call this.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Choice
    )

    $normalized = $Choice.Trim()
    if ([string]::Equals($normalized, '2', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $script:ToolkitPreferencesConstant.OrchestratorModeAlways
    }
    return $script:ToolkitPreferencesConstant.OrchestratorModeAdaptive
}

function Read-ToolkitPreferenceChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Header,
        [Parameter(Mandatory = $true)][string[]] $Options,
        [Parameter(Mandatory = $true)][string] $Prompt,
        [Parameter(Mandatory = $true)][string] $DefaultChoice
    )

    Write-Host $Header
    foreach ($option in $Options) { Write-Host $option }
    while ($true) {
        $choice = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($choice)) { return $DefaultChoice }
        $choice = $choice.Trim()
        if ($Options | Where-Object { $_ -match ('^\s*\[' + [regex]::Escape($choice) + '\]') }) { return $choice }
        Write-Host 'Invalid option. Choose one of the listed values.' -ForegroundColor Yellow
    }
}

function Invoke-ToolkitEnsurePreferences {
    <#
    .SYNOPSIS
      Create preferences.json when missing. Interactive first sync asks for orchestrator and Caveman preferences.
    .NOTES
      Existing preferences are preserved; non-interactive roots receive deterministic defaults.
      In-session orchestrator adaptive stays in core/policy/orchestrator-session.md.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SddRoot,

        [Parameter()]
        [switch] $Interactive,

        [Parameter()]
        [switch] $WhatIf
    )

    $preferencesPath = Join-Path $SddRoot $script:ToolkitPreferencesConstant.FileName
    if (Test-Path -LiteralPath $preferencesPath) {
        return [PSCustomObject]@{
            Created           = $false
            PreferencesPath   = $preferencesPath
            OrchestratorMode  = $null
        }
    }

    # Keep direct sync non-interactive; only toolkit's explicit interactive flow passes -Interactive.
    $orchestratorMode = $script:ToolkitPreferencesConstant.DefaultOrchestratorMode
    $cavemanMode = $script:ToolkitPreferencesConstant.DefaultCavemanMode

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Created           = $true
            PreferencesPath   = $preferencesPath
            OrchestratorMode  = $orchestratorMode
            CavemanMode       = $cavemanMode
            WhatIf            = $true
        }
    }

    if ($Interactive.IsPresent) {
        $modeChoice = Read-ToolkitPreferenceChoice `
            -Header $script:ToolkitMessage.ToolkitOrchestratorInstallPromptHeader `
            -Options @($script:ToolkitMessage.ToolkitOrchestratorInstallPromptAdaptiveLine, $script:ToolkitMessage.ToolkitOrchestratorInstallPromptAlwaysLine) `
            -Prompt $script:ToolkitMessage.ToolkitOrchestratorInstallPromptMenu `
            -DefaultChoice $script:ToolkitMessage.ToolkitOrchestratorInstallDefaultChoice
        $orchestratorMode = Resolve-ToolkitOrchestratorModeFromChoice -Choice $modeChoice

        $cavemanChoice = Read-ToolkitPreferenceChoice `
            -Header $script:ToolkitMessage.ToolkitCavemanInstallPromptHeader `
            -Options @($script:ToolkitMessage.ToolkitCavemanInstallPromptOnLine, $script:ToolkitMessage.ToolkitCavemanInstallPromptOffLine) `
            -Prompt $script:ToolkitMessage.ToolkitCavemanInstallPromptMenu `
            -DefaultChoice $script:ToolkitMessage.ToolkitCavemanInstallDefaultChoice
        $cavemanMode = [string]::Equals($cavemanChoice, '1', [System.StringComparison]::OrdinalIgnoreCase)
    }

    if (-not (Test-Path -LiteralPath $SddRoot)) {
        New-Item -ItemType Directory -Path $SddRoot -Force | Out-Null
    }

    $seed = New-ToolkitDefaultPreferencesObject -OrchestratorMode $orchestratorMode
    $seed.caveman_mode = $cavemanMode
    $json = ConvertTo-ToolkitSddCleanJson -Object $seed
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($preferencesPath, $json, $utf8NoBom)

    Write-Host ($script:ToolkitMessage.ToolkitOrchestratorPreferencesCreated -f $preferencesPath, $orchestratorMode) -ForegroundColor Green

    return [PSCustomObject]@{
        Created           = $true
        PreferencesPath   = $preferencesPath
        OrchestratorMode  = $orchestratorMode
        CavemanMode       = $cavemanMode
    }
}
