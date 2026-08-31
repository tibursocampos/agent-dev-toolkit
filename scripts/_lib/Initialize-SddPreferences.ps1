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
    DefaultOrchestratorMode  = 'always'
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
        caveman_mode      = $false
        caveman_level     = 'full'
        orchestrator_mode = $mode
        artifact_language = $null
        verify_mode       = $false
    }
}

function Resolve-ToolkitOrchestratorModeFromChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Choice
    )

    $normalized = $Choice.Trim()
    if ([string]::Equals($normalized, '2', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $script:ToolkitPreferencesConstant.OrchestratorModeAdaptive
    }
    return $script:ToolkitPreferencesConstant.OrchestratorModeAlways
}

function Invoke-ToolkitEnsurePreferences {
    <#
    .SYNOPSIS
      Create preferences.json when missing; optional interactive orchestrator mode prompt.
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

    $orchestratorMode = $script:ToolkitPreferencesConstant.DefaultOrchestratorMode
    if ($Interactive.IsPresent) {
        Write-Host $script:ToolkitMessage.ToolkitOrchestratorInstallPromptHeader -ForegroundColor Cyan
        Write-Host $script:ToolkitMessage.ToolkitOrchestratorInstallPromptAlwaysLine
        Write-Host $script:ToolkitMessage.ToolkitOrchestratorInstallPromptAdaptiveLine
        $choice = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitOrchestratorInstallPromptMenu `
            -ValidChoices $script:ToolkitConstant.ToolkitOrchestratorInstallMenuChoices `
            -DefaultChoice $script:ToolkitMessage.ToolkitOrchestratorInstallDefaultChoice
        $orchestratorMode = Resolve-ToolkitOrchestratorModeFromChoice -Choice $choice
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Created           = $true
            PreferencesPath   = $preferencesPath
            OrchestratorMode  = $orchestratorMode
            WhatIf            = $true
        }
    }

    if (-not (Test-Path -LiteralPath $SddRoot)) {
        New-Item -ItemType Directory -Path $SddRoot -Force | Out-Null
    }

    $seed = New-ToolkitDefaultPreferencesObject -OrchestratorMode $orchestratorMode
    $json = ConvertTo-ToolkitSddCleanJson -Object $seed
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($preferencesPath, $json, $utf8NoBom)

    Write-Host ($script:ToolkitMessage.ToolkitOrchestratorPreferencesCreated -f $preferencesPath, $orchestratorMode) -ForegroundColor Green

    return [PSCustomObject]@{
        Created           = $true
        PreferencesPath   = $preferencesPath
        OrchestratorMode  = $orchestratorMode
    }
}
