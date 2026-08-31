#Requires -Version 5.1
<#
.SYNOPSIS
  Interactive / non-interactive CLI for agent-dev-toolkit (multi-agent).

.DESCRIPTION
  Smart Manager menu (clear screen, wizards, help) and -Action/-Agent flags for
  Sync, Validate, core validation, registry listing, and Uninstall.
  Sync/Validate/Uninstall always require an explicit agent (no silent home default).
  Backup remains a fail-closed stub unless -ForceStub (non-interactive only).

.PARAMETER Agent
  Registry agent id. Required for Sync / Validate / Uninstall when using -Action.

.PARAMETER Action
  Non-interactive action: Sync, Validate, SyncAndValidate, ValidateCore,
  ListAgents, Uninstall, Backup.

.PARAMETER InstallRoot
  Forwarded to sync-agent / validate-agent / Uninstall-Toolkit when set.

.PARAMETER AllowUserHome
  Forwarded to sync-agent / validate-agent / Uninstall-Toolkit.

.PARAMETER UserScope
  Forwarded to sync-agent for adapters that declare Publish-Skills -UserScope (Codex).
  Opt-in only — do not combine with the always-on ~/.codex/skills mirror unless you
  intentionally want a second Personal discovery root (duplicates $ picks).

.PARAMETER Quiet
  Forwarded to validate-agent / validate-core.

.PARAMETER SkipSmoke
  Forwarded to validate-agent.

.PARAMETER Mode
  Forwarded to sync-agent / validate-agent / Uninstall-Toolkit. Required for -Agent copilot (user|repo).

.PARAMETER ForceStub
  Acknowledge unimplemented Backup stub and allow a success exit (tooling tests only).

.PARAMETER WhatIf
  Optional. For -Action Sync / SyncAndValidate, forwarded to sync-agent.ps1
  (Publish-* / Get-SddRoot -Prepare when adapters declare -WhatIf).
  For -Action Uninstall, forwarded to adapter Uninstall-Toolkit when that
  command declares a -WhatIf parameter. Ignored for other actions.

.EXAMPLE
  .\scripts\toolkit.ps1

.EXAMPLE
  .\scripts\toolkit.ps1 -Action ListAgents

.EXAMPLE
  .\scripts\toolkit.ps1 -Action Sync -Agent cursor -AllowUserHome -InstallRoot "$env:USERPROFILE\.cursor"

.EXAMPLE
  .\scripts\toolkit.ps1 -Action Sync -Agent cursor -WhatIf

.EXAMPLE
  .\scripts\toolkit.ps1 -Action Uninstall -Agent claude -WhatIf
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $Agent,

    [Parameter()]
    [string] $Action,

    [Parameter()]
    [string] $InstallRoot,

    [Parameter()]
    [string] $Mode,

    [Parameter()]
    [switch] $AllowUserHome,

    [Parameter()]
    [switch] $UserScope,

    [Parameter()]
    [switch] $Quiet,

    [Parameter()]
    [switch] $SkipSmoke,

    [Parameter()]
    [switch] $ForceStub,

    [Parameter()]
    [switch] $WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$libDir = Join-Path $scriptDir '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'ToolkitCliUi.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'Resolve-RegistryAgent.ps1')
. (Join-Path $libDir 'Resolve-InstallRoot.ps1')
. (Join-Path $libDir 'Resolve-AdapterFixtureInstallRoot.ps1')
. (Join-Path $libDir 'Assert-CopilotAgentMode.ps1')
. (Join-Path $libDir 'Initialize-SddRootLayout.ps1')
. (Join-Path $libDir 'Initialize-SddPreferences.ps1')

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir

function Get-ToolkitValidActions {
    return @(
        $script:ToolkitConstant.ToolkitActionSync,
        $script:ToolkitConstant.ToolkitActionValidate,
        $script:ToolkitConstant.ToolkitActionSyncAndValidate,
        $script:ToolkitConstant.ToolkitActionValidateCore,
        $script:ToolkitConstant.ToolkitActionListAgents,
        $script:ToolkitConstant.ToolkitActionUninstall,
        $script:ToolkitConstant.ToolkitActionBackup
    )
}

function Show-ToolkitMainMenu {
    Clear-ToolkitScreen
    Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitBannerTitle -RepoRoot $repoRoot -Subtitle $script:ToolkitMessage.ToolkitMenuWhatHint
    Write-Host $script:ToolkitMessage.ToolkitMenuSyncLine
    Write-Host $script:ToolkitMessage.ToolkitMenuValidateLine
    Write-Host $script:ToolkitMessage.ToolkitMenuSyncValidateLine
    Write-Host $script:ToolkitMessage.ToolkitMenuValidateCoreLine
    Write-Host $script:ToolkitMessage.ToolkitMenuValidationLabLine
    Write-Host $script:ToolkitMessage.ToolkitMenuUninstallLine
    Write-Host $script:ToolkitMessage.ToolkitMenuHelpLine
    Write-Host $script:ToolkitMessage.ToolkitMenuExitLine
    Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan
}

function Show-RegistryAgents {
    param(
        [Parameter(Mandatory = $true)]
        $Registry,

        [Parameter()]
        [switch] $IncludeBack
    )

    Write-Host $script:ToolkitMessage.ToolkitAvailableAgentsHeader -ForegroundColor Cyan
    if ($IncludeBack) {
        Write-Host $script:ToolkitMessage.ToolkitAgentBackLine -ForegroundColor DarkGray
    }
    $index = 1
    foreach ($entry in @($Registry.agents)) {
        Write-Host ($script:ToolkitMessage.ToolkitAgentListLine -f $index, $entry.id, $entry.displayName)
        $index++
    }
}

function Resolve-ToolkitAgentSelection {
    param(
        [Parameter()]
        [string] $AgentId,

        [Parameter(Mandatory = $true)]
        [bool] $AllowPrompt
    )

    $registry = Get-AdapterRegistry -RepoRoot $repoRoot
    $ids = Get-AdapterAvailableAgentIds -Registry $registry
    Show-RegistryAgents -Registry $registry

    if (-not [string]::IsNullOrWhiteSpace($AgentId)) {
        $null = Resolve-RegistryAgent -RepoRoot $repoRoot -AgentId $AgentId
        return $AgentId.Trim()
    }

    if (-not $AllowPrompt) {
        throw ($script:ToolkitMessage.ToolkitActionRequiresAgent -f 'Sync/Validate/Uninstall', (Format-AdapterAgentIdList -AgentIds $ids))
    }

    throw ($script:ToolkitMessage.ToolkitActionRequiresAgent -f 'Sync/Validate/Uninstall', (Format-AdapterAgentIdList -AgentIds $ids))
}

function Invoke-ToolkitAgentWizard {
    <#
    .SYNOPSIS
      Interactive agent picker. Returns agent id, or $null if Back.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Title = $script:ToolkitMessage.ToolkitAgentWizardTitle
    )

    while ($true) {
        Clear-ToolkitScreen
        Show-ToolkitHeader -Title $Title -RepoRoot $repoRoot
        $registry = Get-AdapterRegistry -RepoRoot $repoRoot
        $ids = @(Get-AdapterAvailableAgentIds -Registry $registry)
        Show-RegistryAgents -Registry $registry -IncludeBack

        $valid = @($script:ToolkitConstant.ToolkitChoiceBack) + @(1..$ids.Count | ForEach-Object { [string]$_ }) + $ids
        $raw = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitAgentPrompt -ValidChoices $valid

        if ([string]::Equals($raw, $script:ToolkitConstant.ToolkitChoiceBack, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $null
        }

        $asNumber = 0
        if ([int]::TryParse($raw, [ref]$asNumber) -and $asNumber -ge 1 -and $asNumber -le $ids.Count) {
            return [string]$ids[$asNumber - 1]
        }

        try {
            $null = Resolve-RegistryAgent -RepoRoot $repoRoot -AgentId $raw
            return $raw.Trim()
        }
        catch {
            Write-ToolkitWarn -Message $_.Exception.Message
            Pause-Toolkit
        }
    }
}

function Get-ToolkitLiveHomePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId,

        [Parameter()]
        [string] $ResolvedMode
    )

    $resolved = Resolve-RegistryAgent -RepoRoot $repoRoot -AgentId $AgentId
    . $resolved.ModulePath

    $roots = $null
    if (Get-Command -Name Get-InstallRoots -ErrorAction SilentlyContinue) {
        try {
            if ((Test-IsCopilotAgentId -AgentId $AgentId) -and -not [string]::IsNullOrWhiteSpace($ResolvedMode)) {
                $roots = Get-InstallRoots -AgentId $AgentId -Mode $ResolvedMode
            }
            else {
                $roots = Get-InstallRoots -AgentId $AgentId
            }
        }
        catch {
            $roots = $null
        }
    }

    $pathProp = $script:ToolkitConstant.OfficialUserRootPathProperty
    if ($null -ne $roots -and $roots.PSObject.Properties.Name -contains $pathProp) {
        $path = [string]$roots.$pathProp
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            return $path
        }
    }

    $relProp = $script:ToolkitConstant.OfficialUserRootRelativeProperty
    if ($null -ne $roots -and $roots.PSObject.Properties.Name -contains $relProp) {
        $rel = [string]$roots.$relProp
        if (-not [string]::IsNullOrWhiteSpace($rel) -and -not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
            return (Join-Path $env:USERPROFILE ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar))
        }
    }

    return $null
}

function Invoke-ToolkitCopilotModeWizard {
    [CmdletBinding()]
    param()

    Clear-ToolkitScreen
    Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitCopilotModeTitle -RepoRoot $repoRoot
    Write-Host $script:ToolkitMessage.ToolkitCopilotModeUserLine
    Write-Host $script:ToolkitMessage.ToolkitCopilotModeRepoLine
    Write-Host $script:ToolkitMessage.ToolkitCopilotModeBackLine
    Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan

    $choice = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitMenuPrompt -ValidChoices $script:ToolkitConstant.ToolkitCopilotModeMenuChoices
    switch ($choice) {
        '1' { return $script:ToolkitConstant.CopilotModeUser }
        '2' { return $script:ToolkitConstant.CopilotModeRepo }
        default { return $null }
    }
}

function Test-ToolkitPathUnderUserProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        return $false
    }

    try {
        $full = [System.IO.Path]::GetFullPath($Path)
        $profileFull = [System.IO.Path]::GetFullPath($env:USERPROFILE)
        return $full.StartsWith($profileFull, [System.StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        return $false
    }
}

function Invoke-ToolkitTargetWizard {
    <#
    .SYNOPSIS
      Pick fixture / live home / custom. Returns hashtable or $null on Back.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId,

        [Parameter()]
        [string] $ResolvedMode
    )

    $livePath = Get-ToolkitLiveHomePath -AgentId $AgentId -ResolvedMode $ResolvedMode
    $liveLabel = if ([string]::IsNullOrWhiteSpace($livePath)) {
        $script:ToolkitMessage.ToolkitTargetLiveUnknown
    }
    else {
        $livePath
    }
    $showCodexDual = [string]::Equals($AgentId.Trim(), 'codex', [System.StringComparison]::OrdinalIgnoreCase)

    while ($true) {
        Clear-ToolkitScreen
        Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitTargetWizardTitle -RepoRoot $repoRoot -Subtitle ("Agent: {0}" -f $AgentId)
        Write-Host ($script:ToolkitMessage.ToolkitTargetLiveLine -f $liveLabel)
        if ($showCodexDual) {
            Write-Host $script:ToolkitMessage.ToolkitTargetLiveCodexDualLine
        }
        Write-Host $script:ToolkitMessage.ToolkitTargetFixtureLine
        Write-Host $script:ToolkitMessage.ToolkitTargetCustomLine
        Write-Host $script:ToolkitMessage.ToolkitTargetBackLine
        Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan

        $choice = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitTargetMenuPromptWithDefault -ValidChoices $script:ToolkitConstant.ToolkitTargetMenuChoices -DefaultChoice $script:ToolkitMessage.ToolkitTargetMenuDefaultChoice
        switch ($choice) {
            '0' { return $null }
            '1' {
                if ([string]::IsNullOrWhiteSpace($livePath)) {
                    Write-ToolkitWarn -Message ($script:ToolkitMessage.ToolkitLiveHomeUnavailable -f $AgentId)
                    Pause-Toolkit
                    continue
                }
                if (-not (Confirm-ToolkitYesNo -Prompt $script:ToolkitMessage.ToolkitLiveHomeConfirm -DefaultYes:$true)) {
                    Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitCancelled
                    Pause-Toolkit
                    continue
                }
                return @{
                    InstallRoot    = $livePath
                    AllowUserHome  = $true
                    TargetKind     = $script:ToolkitMessage.ToolkitTargetKindLive
                    UseFixture     = $false
                }
            }
            '2' {
                return @{
                    InstallRoot    = $null
                    AllowUserHome  = $false
                    TargetKind     = $script:ToolkitMessage.ToolkitTargetKindFixture
                    UseFixture     = $true
                }
            }
            '3' {
                $custom = Read-Host $script:ToolkitMessage.ToolkitCustomPathPrompt
                if ([string]::IsNullOrWhiteSpace($custom)) {
                    Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitCustomPathRequired
                    Pause-Toolkit
                    continue
                }
                $allow = $false
                if (Test-ToolkitPathUnderUserProfile -Path $custom.Trim()) {
                    if (-not (Confirm-ToolkitYesNo -Prompt $script:ToolkitMessage.ToolkitAllowUserHomeConfirm -DefaultYes:$false)) {
                        Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitCancelled
                        Pause-Toolkit
                        continue
                    }
                    $allow = $true
                }
                return @{
                    InstallRoot    = $custom.Trim()
                    AllowUserHome  = $allow
                    TargetKind     = $script:ToolkitMessage.ToolkitTargetKindCustom
                    UseFixture     = $false
                }
            }
        }
    }
}

function Confirm-ToolkitRunPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId,

        [Parameter()]
        [string] $ResolvedMode,

        [Parameter(Mandatory = $true)]
        [hashtable] $Target
    )

    Clear-ToolkitScreen
    Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitSummaryTitle -RepoRoot $repoRoot
    Write-Host ($script:ToolkitMessage.ToolkitSummaryAgent -f $AgentId)
    if (-not [string]::IsNullOrWhiteSpace($ResolvedMode)) {
        Write-Host ($script:ToolkitMessage.ToolkitSummaryMode -f $ResolvedMode)
    }
    Write-Host ($script:ToolkitMessage.ToolkitSummaryTargetKind -f $Target.TargetKind)
    $rootDisplay = if ($Target.UseFixture -or [string]::IsNullOrWhiteSpace([string]$Target.InstallRoot)) {
        '(adapter default fixture)'
    }
    else {
        [string]$Target.InstallRoot
    }
    Write-Host ($script:ToolkitMessage.ToolkitSummaryInstallRoot -f $rootDisplay)
    Write-Host ($script:ToolkitMessage.ToolkitSummaryAllowUserHome -f $(if ($Target.AllowUserHome) { ' yes' } else { ' no' }))
    Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan

    $choice = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitConfirmRunPrompt -ValidChoices $script:ToolkitConstant.ToolkitConfirmRunChoices
    if ([string]::Equals($choice, $script:ToolkitConstant.ToolkitChoiceBack, [System.StringComparison]::OrdinalIgnoreCase)) {
        return 'back'
    }
    if (
        [string]::Equals($choice, $script:ToolkitConstant.ToolkitChoiceYes, [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($choice, $script:ToolkitConstant.ToolkitChoiceYesShort, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        return 'run'
    }
    return 'cancel'
}

function Invoke-ToolkitInteractiveAgentFlow {
    <#
    .SYNOPSIS
      Agent + optional Copilot mode + target + confirm. Returns context or $null if aborted.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FlowTitle
    )

    $agentId = Invoke-ToolkitAgentWizard -Title $FlowTitle
    if ([string]::IsNullOrWhiteSpace($agentId)) {
        return $null
    }

    $resolvedMode = $null
    if (Test-IsCopilotAgentId -AgentId $agentId) {
        $resolvedMode = Invoke-ToolkitCopilotModeWizard
        if ([string]::IsNullOrWhiteSpace($resolvedMode)) {
            return $null
        }
    }

    while ($true) {
        $target = Invoke-ToolkitTargetWizard -AgentId $agentId -ResolvedMode $resolvedMode
        if ($null -eq $target) {
            return $null
        }

        $decision = Confirm-ToolkitRunPlan -AgentId $agentId -ResolvedMode $resolvedMode -Target $target
        switch ($decision) {
            'run' {
                return @{
                    AgentId       = $agentId
                    Mode          = $resolvedMode
                    InstallRoot   = $target.InstallRoot
                    AllowUserHome = [bool]$target.AllowUserHome
                    UseFixture    = [bool]$target.UseFixture
                }
            }
            'back' { continue }
            default {
                Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitCancelled
                return $null
            }
        }
    }
}

function Invoke-ToolkitScript {
    param(
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [Parameter()][hashtable] $ArgumentTable = @{}
    )

    $fullPath = Join-Path $repoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Write-ToolkitError -Message ("Error: file not found ({0})" -f $fullPath)
        return $false
    }

    $displayParts = @()
    foreach ($key in @($ArgumentTable.Keys)) {
        $value = $ArgumentTable[$key]
        if ($value -is [switch] -or $value -eq $true) {
            $displayParts += ("-{0}" -f $key)
        }
        elseif ($null -ne $value -and $value -ne $false) {
            $displayParts += ("-{0}" -f $key)
            $displayParts += [string]$value
        }
    }
    $argDisplay = ($displayParts -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($argDisplay)) {
        Write-Host ("`n>>> Running: {0}" -f $RelativePath) -ForegroundColor Yellow
    }
    else {
        Write-Host ("`n>>> Running: {0} {1}" -f $RelativePath, $argDisplay) -ForegroundColor Yellow
    }

    $exitCode = 0
    try {
        & $fullPath @ArgumentTable
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            $exitCode = 0
        }
    }
    catch {
        Write-ToolkitError -Message (">>> Error: {0}" -f $_.Exception.Message)
        return $false
    }

    if ($exitCode -eq 0) {
        Write-Host (">>> Success: {0} (exit 0)" -f $RelativePath) -ForegroundColor Green
        return $true
    }

    Write-Host (">>> Failed: {0} (exit {1})" -f $RelativePath, $exitCode) -ForegroundColor Red
    return $false
}

function Build-AgentForwardTable {
    param(
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter()][string] $OverrideInstallRoot,
        [Parameter()][string] $OverrideMode,
        [Parameter()][Nullable[bool]] $OverrideAllowUserHome,
        [Parameter()][switch] $ForValidate
    )

    $table = @{
        Agent = $AgentId
    }

    $effectiveRoot = if (-not [string]::IsNullOrWhiteSpace($OverrideInstallRoot)) {
        $OverrideInstallRoot
    }
    else {
        $InstallRoot
    }
    if (-not [string]::IsNullOrWhiteSpace($effectiveRoot)) {
        $table['InstallRoot'] = $effectiveRoot
    }

    $effectiveMode = if (-not [string]::IsNullOrWhiteSpace($OverrideMode)) {
        $OverrideMode
    }
    else {
        $Mode
    }
    if (-not [string]::IsNullOrWhiteSpace($effectiveMode)) {
        $table['Mode'] = $effectiveMode
    }

    $allow = $AllowUserHome.IsPresent
    if ($null -ne $OverrideAllowUserHome) {
        $allow = [bool]$OverrideAllowUserHome
    }
    if ($allow) {
        $table['AllowUserHome'] = $true
    }

    if ($UserScope.IsPresent) {
        $table[$script:ToolkitConstant.UserScopeParameterName] = $true
    }

    if ($ForValidate) {
        if ($Quiet) { $table['Quiet'] = $true }
        if ($SkipSmoke) { $table['SkipSmoke'] = $true }
    }

    return $table
}

function Invoke-ToolkitPostSyncPreferences {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $OverrideInstallRoot,

        [Parameter()]
        [Nullable[bool]] $OverrideAllowUserHome,

        [Parameter()]
        [switch] $Interactive,

        [Parameter()]
        [switch] $WhatIf
    )

    $effectiveRoot = if (-not [string]::IsNullOrWhiteSpace($OverrideInstallRoot)) {
        $OverrideInstallRoot
    }
    else {
        $InstallRoot
    }

    if ([string]::IsNullOrWhiteSpace($effectiveRoot)) {
        return
    }

    $allow = $AllowUserHome.IsPresent
    if ($null -ne $OverrideAllowUserHome) {
        $allow = [bool]$OverrideAllowUserHome
    }

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $effectiveRoot -AllowUserHome:$allow -RepoRoot $repoRoot
    $sddResult = Invoke-ToolkitGetSddRoot -InstallRoot $resolvedInstallRoot -RepoRoot $repoRoot -Prepare -AllowUserHome:$allow -WhatIf:$WhatIf.IsPresent
    if ($null -eq $sddResult -or [string]::IsNullOrWhiteSpace([string]$sddResult.SddRoot)) {
        return
    }

    $null = Invoke-ToolkitEnsurePreferences -SddRoot $sddResult.SddRoot -Interactive:$Interactive.IsPresent -WhatIf:$WhatIf.IsPresent
}

function Invoke-ToolkitSync {
    param(
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter()][string] $OverrideInstallRoot,
        [Parameter()][string] $OverrideMode,
        [Parameter()][Nullable[bool]] $OverrideAllowUserHome,
        [Parameter()][switch] $PromptOrchestratorMode
    )

    Write-ToolkitStepBanner -Title ("Sync agent ({0})" -f $AgentId)
    $syncTable = Build-AgentForwardTable -AgentId $AgentId -OverrideInstallRoot $OverrideInstallRoot -OverrideMode $OverrideMode -OverrideAllowUserHome $OverrideAllowUserHome
    if ($WhatIf.IsPresent) {
        $syncTable[$script:ToolkitConstant.WhatIfParameterName] = $true
    }
    $syncOk = (Invoke-ToolkitScript -RelativePath $script:ToolkitConstant.SyncAgentRelativePath -ArgumentTable $syncTable)
    if (-not $syncOk) {
        return $false
    }

    Invoke-ToolkitPostSyncPreferences `
        -OverrideInstallRoot $OverrideInstallRoot `
        -OverrideAllowUserHome $OverrideAllowUserHome `
        -Interactive:$PromptOrchestratorMode.IsPresent `
        -WhatIf:$WhatIf.IsPresent

    return $true
}

function Invoke-ToolkitValidate {
    param(
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter()][string] $OverrideInstallRoot,
        [Parameter()][string] $OverrideMode,
        [Parameter()][Nullable[bool]] $OverrideAllowUserHome
    )

    Write-ToolkitStepBanner -Title ("Validate agent ({0})" -f $AgentId)
    return (Invoke-ToolkitScript -RelativePath $script:ToolkitConstant.ValidateAgentRelativePath -ArgumentTable (
            Build-AgentForwardTable -AgentId $AgentId -OverrideInstallRoot $OverrideInstallRoot -OverrideMode $OverrideMode -OverrideAllowUserHome $OverrideAllowUserHome -ForValidate
        ))
}

function Invoke-ToolkitValidateCore {
    Write-ToolkitStepBanner -Title 'Validate core'
    $coreTable = @{}
    if ($Quiet) { $coreTable['Quiet'] = $true }
    return (Invoke-ToolkitScript -RelativePath $script:ToolkitConstant.ValidateCoreRelativePath -ArgumentTable $coreTable)
}

function Invoke-ToolkitListAgents {
    Write-ToolkitStepBanner -Title 'List registry agents'
    $registry = Get-AdapterRegistry -RepoRoot $repoRoot
    Show-RegistryAgents -Registry $registry
    return $true
}

function Invoke-ToolkitUninstall {
    param(
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter()][string] $OverrideInstallRoot,
        [Parameter()][string] $OverrideMode,
        [Parameter()][Nullable[bool]] $OverrideAllowUserHome
    )

    Write-ToolkitStepBanner -Title ("Uninstall agent ({0})" -f $AgentId)

    $effectiveMode = if (-not [string]::IsNullOrWhiteSpace($OverrideMode)) { $OverrideMode } else { $Mode }
    $effectiveAllow = $AllowUserHome.IsPresent
    if ($null -ne $OverrideAllowUserHome) {
        $effectiveAllow = [bool]$OverrideAllowUserHome
    }
    $effectiveRoot = if (-not [string]::IsNullOrWhiteSpace($OverrideInstallRoot)) { $OverrideInstallRoot } else { $InstallRoot }

    $resolved = Resolve-RegistryAgent -RepoRoot $repoRoot -AgentId $AgentId
    $resolvedMode = Assert-CopilotAgentMode -AgentId $resolved.AgentId -Mode $effectiveMode

    . $resolved.ModulePath

    $uninstallCommand = Get-Command -Name 'Uninstall-Toolkit' -ErrorAction SilentlyContinue
    if ($null -eq $uninstallCommand) {
        Write-ToolkitError -Message ($script:ToolkitMessage.ToolkitUninstallCommandMissing -f $resolved.AgentId)
        return $false
    }

    $targetInstallRoot = $effectiveRoot
    if ([string]::IsNullOrWhiteSpace($targetInstallRoot)) {
        if ((Test-IsCopilotAgentId -AgentId $resolved.AgentId) -and -not [string]::IsNullOrWhiteSpace($resolvedMode)) {
            $copilotFixtureRel = if ($resolvedMode -eq $script:ToolkitConstant.CopilotModeRepo) {
                $script:ToolkitConstant.CopilotFixtureRepoRel
            }
            else {
                $script:ToolkitConstant.CopilotFixtureUserRel
            }
            $targetInstallRoot = Join-Path $repoRoot ($copilotFixtureRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        }
        else {
            $targetInstallRoot = Resolve-AdapterFixtureInstallRoot -RepoRoot $repoRoot -AgentId $resolved.AgentId
        }
    }

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $targetInstallRoot -AllowUserHome:$effectiveAllow -RepoRoot $repoRoot

    Write-Host ("InstallRoot: {0}" -f $resolvedInstallRoot) -ForegroundColor Cyan
    Write-Host ("Module: {0}" -f $resolved.ModuleRelative) -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($resolvedMode)) {
        Write-Host ("Mode: {0}" -f $resolvedMode) -ForegroundColor Cyan
    }

    $uninstallArgs = @{
        InstallRoot = $resolvedInstallRoot
    }
    if ($effectiveAllow) {
        $uninstallArgs[$script:ToolkitConstant.AllowUserHomeParameterName] = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($resolvedMode)) {
        $uninstallArgs[$script:ToolkitConstant.ModeParameterName] = $resolvedMode
    }
    $whatIfParameterName = $script:ToolkitConstant.WhatIfParameterName
    if ($WhatIf.IsPresent -and $uninstallCommand.Parameters.ContainsKey($whatIfParameterName)) {
        $uninstallArgs[$whatIfParameterName] = $true
    }

    $result = & $uninstallCommand @uninstallArgs
    if ($null -eq $result) {
        Write-ToolkitError -Message ($script:ToolkitMessage.ToolkitUninstallFailed -f $resolved.AgentId, 'Uninstall-Toolkit returned no result')
        return $false
    }

    if ($result.PSObject.Properties.Name -contains 'Implemented' -and $result.Implemented -eq $false) {
        $detail = if ($result.PSObject.Properties.Name -contains 'Message') { [string]$result.Message } else { 'Uninstall-Toolkit' }
        Write-ToolkitError -Message ($script:ToolkitMessage.AdapterNotImplemented -f $resolved.AgentId, $detail)
        return $false
    }

    if ($result.PSObject.Properties.Name -contains 'Success' -and $result.Success -eq $false) {
        $detail = if ($result.PSObject.Properties.Name -contains 'Message') { [string]$result.Message } else { 'Uninstall-Toolkit' }
        Write-ToolkitError -Message ($script:ToolkitMessage.ToolkitUninstallFailed -f $resolved.AgentId, $detail)
        return $false
    }

    Write-ToolkitSuccess -Message $script:ToolkitMessage.ToolkitUninstallCompleted
    return $true
}

function Invoke-ToolkitStubAction {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter()][switch] $AllowForceStubSuccess
    )

    Write-ToolkitStepBanner -Title $Name
    Write-ToolkitWarn -Message ($script:ToolkitMessage.ToolkitStubComingSoon -f $Name)

    if ($AllowForceStubSuccess -and $ForceStub) {
        Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitBackupStubForced
        return $true
    }

    if ($Name -eq $script:ToolkitConstant.ToolkitActionBackup) {
        Write-ToolkitError -Message $script:ToolkitMessage.ToolkitBackupStubRefused
    }

    return $false
}

function Invoke-ToolkitAction {
    param(
        [Parameter(Mandatory = $true)][string] $ActionName,
        [Parameter()][string] $AgentId,
        [Parameter(Mandatory = $true)][bool] $AllowPrompt,
        [Parameter()][hashtable] $Context
    )

    $normalized = $ActionName.Trim()
    $valid = Get-ToolkitValidActions
    $match = @($valid | Where-Object { [string]::Equals($_, $normalized, [System.StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1)
    if ($null -eq $match -or $match.Count -eq 0) {
        throw ($script:ToolkitMessage.ToolkitInvalidAction -f $ActionName, ($valid -join ', '))
    }

    $actionKey = [string]$match[0]
    $overrideRoot = $null
    $overrideMode = $null
    $overrideAllow = $null
    if ($null -ne $Context) {
        if ($Context.ContainsKey('InstallRoot')) { $overrideRoot = $Context.InstallRoot }
        if ($Context.ContainsKey('Mode')) { $overrideMode = $Context.Mode }
        if ($Context.ContainsKey('AllowUserHome')) { $overrideAllow = [bool]$Context.AllowUserHome }
        if ($Context.ContainsKey('AgentId') -and [string]::IsNullOrWhiteSpace($AgentId)) {
            $AgentId = [string]$Context.AgentId
        }
    }

    switch ($actionKey) {
        { $_ -eq $script:ToolkitConstant.ToolkitActionListAgents } {
            return (Invoke-ToolkitListAgents)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionValidateCore } {
            return (Invoke-ToolkitValidateCore)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionUninstall } {
            $selected = Resolve-ToolkitAgentSelection -AgentId $AgentId -AllowPrompt:$AllowPrompt
            return (Invoke-ToolkitUninstall -AgentId $selected -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionBackup } {
            return (Invoke-ToolkitStubAction -Name $script:ToolkitConstant.ToolkitActionBackup -AllowForceStubSuccess)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionSync } {
            $selected = Resolve-ToolkitAgentSelection -AgentId $AgentId -AllowPrompt:$AllowPrompt
            return (Invoke-ToolkitSync -AgentId $selected -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionValidate } {
            $selected = Resolve-ToolkitAgentSelection -AgentId $AgentId -AllowPrompt:$AllowPrompt
            return (Invoke-ToolkitValidate -AgentId $selected -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionSyncAndValidate } {
            $selected = Resolve-ToolkitAgentSelection -AgentId $AgentId -AllowPrompt:$AllowPrompt
            $syncOk = Invoke-ToolkitSync -AgentId $selected -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow
            if (-not $syncOk) {
                Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitSkippingValidateAfterSync
                return $false
            }
            return (Invoke-ToolkitValidate -AgentId $selected -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow)
        }
        default {
            throw ($script:ToolkitMessage.ToolkitInvalidAction -f $ActionName, ($valid -join ', '))
        }
    }
}

function Invoke-ToolkitActionFromContext {
    param(
        [Parameter(Mandatory = $true)][string] $ActionName,
        [Parameter(Mandatory = $true)][hashtable] $Context
    )

    $agentId = [string]$Context.AgentId
    $overrideRoot = $Context.InstallRoot
    $overrideMode = $Context.Mode
    $overrideAllow = [bool]$Context.AllowUserHome

    switch ($ActionName) {
        { $_ -eq $script:ToolkitConstant.ToolkitActionSync } {
            return (Invoke-ToolkitSync -AgentId $agentId -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow -PromptOrchestratorMode)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionValidate } {
            return (Invoke-ToolkitValidate -AgentId $agentId -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionSyncAndValidate } {
            $syncOk = Invoke-ToolkitSync -AgentId $agentId -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow -PromptOrchestratorMode
            if (-not $syncOk) {
                Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitSkippingValidateAfterSync
                return $false
            }
            return (Invoke-ToolkitValidate -AgentId $agentId -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow)
        }
        { $_ -eq $script:ToolkitConstant.ToolkitActionUninstall } {
            return (Invoke-ToolkitUninstall -AgentId $agentId -OverrideInstallRoot $overrideRoot -OverrideMode $overrideMode -OverrideAllowUserHome $overrideAllow)
        }
        default {
            throw ($script:ToolkitMessage.ToolkitInvalidAction -f $ActionName, ($script:ToolkitConstant.ToolkitActionSync))
        }
    }
}

function Invoke-ToolkitValidationLab {
    while ($true) {
        Clear-ToolkitScreen
        Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitLabTitle -RepoRoot $repoRoot
        Write-Host $script:ToolkitMessage.ToolkitLabCoreLine
        foreach ($smoke in @($script:ToolkitConstant.CiSmokeScripts)) {
            Write-Host ($script:ToolkitMessage.ToolkitLabSmokeLine -f $smoke.Id, $smoke.Label)
        }
        Write-Host $script:ToolkitMessage.ToolkitLabBackLine
        Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan

        $choice = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitMenuPrompt -ValidChoices $script:ToolkitConstant.ToolkitLabMenuChoices
        if ($choice -eq $script:ToolkitConstant.ToolkitChoiceBack) {
            return
        }
        if ($choice -eq '1') {
            $null = Invoke-ToolkitValidateCore
            Pause-Toolkit
            continue
        }

        $matched = @($script:ToolkitConstant.CiSmokeScripts | Where-Object { [string]$_.Id -eq $choice } | Select-Object -First 1)
        if ($matched.Count -eq 0) {
            Write-ToolkitWarn -Message $script:ToolkitMessage.ToolkitInvalidMenuOptionRetry
            continue
        }
        $null = Invoke-ToolkitScript -RelativePath $matched[0].RelativePath -ArgumentTable @{ Quiet = $true }
        Pause-Toolkit
    }
}

function Invoke-ToolkitHelpMenu {
    while ($true) {
        Clear-ToolkitScreen
        Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitHelpTitle -RepoRoot $repoRoot
        Write-Host $script:ToolkitMessage.ToolkitHelpActionsLine
        Write-Host $script:ToolkitMessage.ToolkitHelpCoreVsAgentLine
        Write-Host $script:ToolkitMessage.ToolkitHelpFlagsLine
        Write-Host $script:ToolkitMessage.ToolkitHelpBackLine
        Write-Host $script:ToolkitConstant.ToolkitMenuRule -ForegroundColor Cyan

        $choice = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitMenuPrompt -ValidChoices $script:ToolkitConstant.ToolkitHelpMenuChoices
        switch ($choice) {
            '0' { return }
            '1' {
                Clear-ToolkitScreen
                Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitHelpActionsLine -RepoRoot $repoRoot
                Write-Host $script:ToolkitMessage.ToolkitHelpActionsBody
                Pause-Toolkit
            }
            '2' {
                Clear-ToolkitScreen
                Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitHelpCoreVsAgentLine -RepoRoot $repoRoot
                Write-Host $script:ToolkitMessage.ToolkitHelpCoreVsAgentBody
                Pause-Toolkit
            }
            '3' {
                Clear-ToolkitScreen
                Show-ToolkitHeader -Title $script:ToolkitMessage.ToolkitHelpFlagsLine -RepoRoot $repoRoot
                Write-Host $script:ToolkitMessage.ToolkitHelpFlagsBody
                Pause-Toolkit
            }
        }
    }
}

# --- Entry ---
if (-not [string]::IsNullOrWhiteSpace($Action)) {
    try {
        $ok = Invoke-ToolkitAction -ActionName $Action -AgentId $Agent -AllowPrompt:$false
        if ($ok) { exit 0 }
        exit 1
    }
    catch {
        Write-ToolkitError -Message $_.Exception.Message
        exit 1
    }
}

while ($true) {
    try {
        Show-ToolkitMainMenu
        $choice = Read-ToolkitChoice -Prompt $script:ToolkitMessage.ToolkitMenuPrompt -ValidChoices $script:ToolkitConstant.ToolkitMainMenuChoices
        $ran = $true

        switch ($choice) {
            '0' {
                Write-Host $script:ToolkitMessage.ToolkitExiting -ForegroundColor Cyan
                exit 0
            }
            '1' {
                $ctx = Invoke-ToolkitInteractiveAgentFlow -FlowTitle $script:ToolkitMessage.ToolkitMenuSyncLine
                if ($null -eq $ctx) { $ran = $false; break }
                $null = Invoke-ToolkitActionFromContext -ActionName $script:ToolkitConstant.ToolkitActionSync -Context $ctx
            }
            '2' {
                $ctx = Invoke-ToolkitInteractiveAgentFlow -FlowTitle $script:ToolkitMessage.ToolkitMenuValidateLine
                if ($null -eq $ctx) { $ran = $false; break }
                $null = Invoke-ToolkitActionFromContext -ActionName $script:ToolkitConstant.ToolkitActionValidate -Context $ctx
            }
            '3' {
                $ctx = Invoke-ToolkitInteractiveAgentFlow -FlowTitle $script:ToolkitMessage.ToolkitMenuSyncValidateLine
                if ($null -eq $ctx) { $ran = $false; break }
                $null = Invoke-ToolkitActionFromContext -ActionName $script:ToolkitConstant.ToolkitActionSyncAndValidate -Context $ctx
            }
            '4' {
                $null = Invoke-ToolkitValidateCore
            }
            '5' {
                Invoke-ToolkitValidationLab
                $ran = $false
            }
            '6' {
                $ctx = Invoke-ToolkitInteractiveAgentFlow -FlowTitle $script:ToolkitMessage.ToolkitMenuUninstallLine
                if ($null -eq $ctx) { $ran = $false; break }
                $null = Invoke-ToolkitActionFromContext -ActionName $script:ToolkitConstant.ToolkitActionUninstall -Context $ctx
            }
            '7' {
                Invoke-ToolkitHelpMenu
                $ran = $false
            }
        }

        if ($ran) {
            Pause-Toolkit
        }
    }
    catch {
        Write-ToolkitError -Message $_.Exception.Message
        Pause-Toolkit
    }
}
