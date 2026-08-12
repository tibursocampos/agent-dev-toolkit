#Requires -Version 5.1
<#
.SYNOPSIS
  OpenCode adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `opencode`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Router /
  Publish-Hooks / Get-SddRoot (-Prepare) / Invoke-SmokeValidate are implemented
  (optional InstallRoot maps skills/, AGENTS.md, and plugins/ under a fixture that
  models ~/.config/opencode). Publish-Policy is a documented no-op (rules=false).
  Uninstall-Toolkit removes keyed toolkit artifacts only (skills matching
  core/skills, AGENTS.md, Decision A plugin marker) - RN07 no wholesale wipe.
  Does not write under USERPROFILE without -AllowUserHome. Hooks are plugin-JS
  only (HooksSemantics = plugin-only; MVP Decision A publishes a minimal JS
  marker under plugins/). Smoke is filesystem-only (no OpenCode runtime; no .ps1 hooks).

.NOTES
  Capabilities:
  - skills = true (Agent Skills under skills/)
  - router = true (AGENTS.md from core/router)
  - hooks = true with HooksSemantics plugin-only (RN03: no shell/PS1 hooks)
  - plugin = true (Decision A: Publish-Hooks copies assets/plugins/*.js)
  - rules = false (no dedicated OpenCode policy surface; Publish-Policy no-op)

  Official layout (https://opencode.ai/docs/config/, /docs/plugins/):
  - Config root: ~/.config/opencode
  - Skills: ~/.config/opencode/skills/<kebab-id>/SKILL.md
  - Router: ~/.config/opencode/AGENTS.md
  - Plugins: ~/.config/opencode/plugins/*.js (auto-loaded)
#>

$script:OpenCodeAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:OpenCodeAdapterDirectory)) {
    $script:OpenCodeAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:OpenCodeAdapterLibDir = Join-Path $script:OpenCodeAdapterDirectory '..\..\scripts\_lib'
. (Join-Path $script:OpenCodeAdapterLibDir 'Initialize-SddRootLayout.ps1')

. (Join-Path $script:OpenCodeAdapterDirectory 'OpenCodePathConstants.ps1')
. (Join-Path $script:OpenCodeAdapterDirectory 'Publish-OpenCodeSkills.ps1')
. (Join-Path $script:OpenCodeAdapterDirectory 'Publish-OpenCodeRouter.ps1')
. (Join-Path $script:OpenCodeAdapterDirectory 'Publish-OpenCodeHooks.ps1')
. (Join-Path $script:OpenCodeAdapterDirectory 'Invoke-OpenCodeSmokeValidate.ps1')
. (Join-Path $script:OpenCodeAdapterDirectory 'Uninstall-OpenCodeToolkit.ps1')

$script:OpenCodeAdapterAgentId = 'opencode'

$script:OpenCodeAdapterCommandNames = @(
    'Get-Capabilities',
    'Get-InstallRoots',
    'Publish-Skills',
    'Publish-Policy',
    'Publish-Router',
    'Publish-Agents',
    'Publish-Hooks',
    'Get-SddRoot',
    'Invoke-SmokeValidate',
    'Uninstall-Toolkit'
)

$script:OpenCodeAdapterSubagentsNative = 'native'

$script:OpenCodeAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $false
    hooks     = $true
    router    = $true
    plugin    = $true
    agents    = $false
    subagents = $script:OpenCodeAdapterSubagentsNative
}

$script:OpenCodeAdapterConstant = @{
    OfficialUserRootRelativePath     = '.config/opencode'
    OfficialUserRootDescription      = 'Official OpenCode user config root is under the user home as .config/opencode (equivalent to ~/.config/opencode).'
    OfficialSkillsRelativePath       = 'skills'
    OfficialSkillsDescription        = 'OpenCode skills publish under skills/<kebab-id>/SKILL.md relative to the config/InstallRoot.'
    OfficialAgentsFileName           = 'AGENTS.md'
    OfficialAgentsDescription        = 'OpenCode router surface is AGENTS.md at the config/InstallRoot scope (global: ~/.config/opencode/AGENTS.md).'
    OfficialPluginsRelativePath      = 'plugins'
    OfficialPluginsDescription       = 'OpenCode plugins live under plugins/ relative to the config/InstallRoot (Decision A: Publish-Hooks copies a minimal JS marker; see https://opencode.ai/docs/plugins/).'
    FixtureRelativePath              = 'scripts/validation/fixtures/opencode'
    InstallRootOverrideParameter     = 'InstallRoot'
    InstallRootOverrideDescription   = 'Pass -InstallRoot to target an in-repo fixture modeling ~/.config/opencode. Paths under USERPROFILE require -AllowUserHome.'
    HooksSemanticsValue              = 'plugin-only'
    HooksSemanticsDescription        = 'RN03/RN04: Hooks are OpenCode JavaScript plugins only (MVP Decision A publishes plugins/agent-dev-toolkit-marker.js). Shell/PS1 hook parity is not supported; smoke never requires .ps1 hooks.'
    MvpHooksDecisionValue            = 'A'
    ResolveInstallRootRelativePath   = 'scripts/_lib/Resolve-InstallRoot.ps1'
}

$script:OpenCodeAdapterMessage = @{
    NotImplemented            = '{0} is not implemented yet for the OpenCode adapter. Publish/smoke land in later adapter PLAN steps; stubs must not mutate InstallRoot.'
    AgentIdRequired           = 'AgentId is required.'
    InstallRootRequired       = 'InstallRoot is required.'
    CapabilitiesReady         = 'OpenCode adapter capabilities reported (skills/router/hooks=plugin-only Decision A JS plugin; plugin=true). Get-SddRoot (-Prepare) and smoke ready; smoke validates files only (no OpenCode runtime; no shell hooks). SDD runtime prepared on sync.'
    ResolveInstallRootMissing = 'Resolve-InstallRoot helper not found at: {0}'
    SddRootResolved           = 'OpenCode SDD root resolved at {0}.'
    SddRootPrepared           = 'Prepared OpenCode SDD root at {0} (sessionsCreated={1}; manifestCreated={2}).'
    SddRootWouldPrepare       = 'WhatIf: would prepare OpenCode SDD root at {0} (sessions + seed manifest.json if missing).'
}

function New-OpenCodeAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:OpenCodeAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-OpenCodeAdapterCommandNames {
    return @($script:OpenCodeAdapterCommandNames)
}

function Get-OpenCodeAdapterRepoRoot {
    [CmdletBinding()]
    param()

    $adapterDir = $PSScriptRoot
    $adaptersDir = Split-Path -Parent $adapterDir
    return Split-Path -Parent $adaptersDir
}

function Initialize-OpenCodeInstallRootResolver {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue) {
        return
    }

    $repoRoot = Get-OpenCodeAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:OpenCodeAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:OpenCodeAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
}

function Get-OpenCodeMappedInstallPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    return [PSCustomObject]@{
        FixtureSkillsPath  = Join-Path $ResolvedInstallRoot $script:OpenCodeAdapterConstant.OfficialSkillsRelativePath
        FixtureAgentsPath  = Join-Path $ResolvedInstallRoot $script:OpenCodeAdapterConstant.OfficialAgentsFileName
        FixturePluginsPath = Join-Path $ResolvedInstallRoot $script:OpenCodeAdapterConstant.OfficialPluginsRelativePath
    }
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report OpenCode adapter capability flags (skills/router; hooks=plugin-only).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:OpenCodeAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:OpenCodeAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId          = $resolvedAgentId
        Implemented      = $true
        Capabilities     = [PSCustomObject]$script:OpenCodeAdapterCapabilityFlags
        HooksSemantics   = $script:OpenCodeAdapterConstant.HooksSemanticsValue
        HooksNote        = $script:OpenCodeAdapterConstant.HooksSemanticsDescription
        MvpHooksDecision = $script:OpenCodeAdapterConstant.MvpHooksDecisionValue
        RequiresShellHooks = $false
        Message          = $script:OpenCodeAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official OpenCode install roots and map them under an optional InstallRoot fixture.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId,

        [Parameter()]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:OpenCodeAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome ($script:OpenCodeAdapterConstant.OfficialUserRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    }

    $resolvedInstallRoot = $null
    $mapped = $null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        Initialize-OpenCodeInstallRootResolver
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
        $mapped = Get-OpenCodeMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    }

    $relativeNormalized = ([string]$script:OpenCodeAdapterConstant.OfficialUserRootRelativePath) -replace '\\', '/'

    return [PSCustomObject]@{
        Success                      = $true
        Implemented                  = $true
        AgentId                      = $AgentId.Trim()
        OfficialUserRootRelativePath = $relativeNormalized
        OfficialUserRootDescription  = $script:OpenCodeAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath         = $officialFull
        OfficialSkillsRelativePath   = $script:OpenCodeAdapterConstant.OfficialSkillsRelativePath
        OfficialSkillsDescription    = $script:OpenCodeAdapterConstant.OfficialSkillsDescription
        OfficialAgentsFileName       = $script:OpenCodeAdapterConstant.OfficialAgentsFileName
        OfficialAgentsDescription    = $script:OpenCodeAdapterConstant.OfficialAgentsDescription
        OfficialPluginsRelativePath  = $script:OpenCodeAdapterConstant.OfficialPluginsRelativePath
        OfficialPluginsDescription   = $script:OpenCodeAdapterConstant.OfficialPluginsDescription
        FixtureRelativePath          = $script:OpenCodeAdapterConstant.FixtureRelativePath
        OverrideParameter            = $script:OpenCodeAdapterConstant.InstallRootOverrideParameter
        OverrideDescription          = $script:OpenCodeAdapterConstant.InstallRootOverrideDescription
        HooksSemantics               = $script:OpenCodeAdapterConstant.HooksSemanticsValue
        ResolvedInstallRoot          = $resolvedInstallRoot
        FixtureSkillsPath            = $(if ($null -ne $mapped) { $mapped.FixtureSkillsPath } else { $null })
        FixtureAgentsPath            = $(if ($null -ne $mapped) { $mapped.FixtureAgentsPath } else { $null })
        FixturePluginsPath           = $(if ($null -ne $mapped) { $mapped.FixturePluginsPath } else { $null })
        Message                      = ('{0} {1} {2} {3} {4}' -f $script:OpenCodeAdapterConstant.OfficialUserRootDescription, $script:OpenCodeAdapterConstant.OfficialSkillsDescription, $script:OpenCodeAdapterConstant.OfficialAgentsDescription, $script:OpenCodeAdapterConstant.OfficialPluginsDescription, $script:OpenCodeAdapterConstant.InstallRootOverrideDescription)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills into InstallRoot/skills (kebab folders) with placeholder resolution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenCodePublishSkills -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Documented no-op - OpenCode MVP has no dedicated policy/rules surface (rules=false).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Policy'
        NoOp        = $true
        WhatIf      = [bool]$WhatIf.IsPresent
        AllowUserHome = [bool]$AllowUserHome.IsPresent
        InstallRoot = $InstallRoot.Trim()
        FilesCopied = 0
        Message     = $script:OpenCodePublishMessage.PolicyNoOp
        ExitCode    = 0
    }
}

function Publish-Router {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md to InstallRoot/AGENTS.md (OpenCode config-root router).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenCodePublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Agents {
    <#
    .SYNOPSIS
      Documented no-op - OpenCode does not use custom agent markdown files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Agents'
        NoOp        = $true
        WhatIf      = [bool]$WhatIf.IsPresent
        AllowUserHome = [bool]$AllowUserHome.IsPresent
        InstallRoot = $InstallRoot.Trim()
        FilesCopied = 0
        Message     = $script:OpenCodePublishMessage.AgentsNoOp
        ExitCode    = 0
    }
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish minimal OpenCode JS plugin under InstallRoot/plugins (Decision A).
    .DESCRIPTION
      RN03: no shell/PS1 hooks. RN04: Decision A publishes a marker .js plugin;
      smoke asserts filesystem presence only (no OpenCode runtime).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenCodePublishHooks -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Get-SddRoot {
    <#
    .SYNOPSIS
      Resolve `<InstallRoot>/sdd`. With -Prepare, ensure `sessions/` and seed `manifest.json` if missing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $Prepare,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-OpenCodeAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:OpenCodeAdapterMessage.SddRootResolved `
        -MessagePrepared $script:OpenCodeAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:OpenCodeAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run OpenCode filesystem-only smoke against a fixture InstallRoot.
    .DESCRIPTION
      Checks skills/, AGENTS.md, and Decision A plugin marker. TE01 home guard via
      Resolve-InstallRoot. Does not invoke OpenCode runtime or require .ps1 hooks.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenCodeSmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts from InstallRoot.
    .DESCRIPTION
      Removes published skills that match core/skills ids, AGENTS.md, and the
      Decision A plugin marker. Preserves alien files and does not wipe the
      OpenCode config tree wholesale.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:OpenCodeAdapterMessage.InstallRootRequired
    }

    return Invoke-OpenCodeUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
