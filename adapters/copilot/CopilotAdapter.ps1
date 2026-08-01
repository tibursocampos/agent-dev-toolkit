#Requires -Version 5.1
<#
.SYNOPSIS
  GitHub Copilot adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `copilot`.
  Get-Capabilities / Get-InstallRoots / Publish-Skills / Publish-Policy / Publish-Hooks
  (Mode user|repo), Invoke-SmokeValidate, and keyed Uninstall-Toolkit are implemented;
  Publish-Router is a documented no-op (router=false). Does not write under USERPROFILE
  without -AllowUserHome. CLI requires -Mode user|repo (validated by sync/validate/
  uninstall). Official surfaces only: ~/.copilot/... (user) and .github/... (repo).
  Mode repo publishes under InstallRoot fixture modeling .github - never the toolkit
  working-tree .github by default. JetBrains/Eclipse Copilot IDE layouts are out of
  scope. Smoke validates filesystem presence only - Copilot IDE extension is out of
  scope. Uninstall removes only toolkit-managed paths (skills/policy/hooks keys).
#>

$script:CopilotAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CopilotAdapterDirectory)) {
    $script:CopilotAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

. (Join-Path $script:CopilotAdapterDirectory 'CopilotPathConstants.ps1')
. (Join-Path $script:CopilotAdapterDirectory 'Publish-CopilotSkills.ps1')
. (Join-Path $script:CopilotAdapterDirectory 'Publish-CopilotPolicy.ps1')
. (Join-Path $script:CopilotAdapterDirectory 'Publish-CopilotHooks.ps1')
. (Join-Path $script:CopilotAdapterDirectory 'Invoke-CopilotSmokeValidate.ps1')
. (Join-Path $script:CopilotAdapterDirectory 'Uninstall-CopilotToolkit.ps1')

$script:CopilotAdapterAgentId = 'copilot'

$script:CopilotAdapterCommandNames = @(
    'Get-Capabilities',
    'Get-InstallRoots',
    'Publish-Skills',
    'Publish-Policy',
    'Publish-Router',
    'Publish-Hooks',
    'Get-SddRoot',
    'Invoke-SmokeValidate',
    'Uninstall-Toolkit'
)

$script:CopilotAdapterSubagentsNative = 'native'

$script:CopilotAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $true
    router    = $false
    sdd       = $false
    plugin    = $false
    subagents = $script:CopilotAdapterSubagentsNative
}

$script:CopilotAdapterConstant = @{
    ModeUser                           = 'user'
    ModeRepo                           = 'repo'
    OfficialUserRootRelativePath       = '.copilot'
    OfficialUserRootDescription        = 'Official GitHub Copilot user install root is under the user home as .copilot (equivalent to ~/.copilot).'
    OfficialRepoRootRelativePath       = '.github'
    OfficialRepoRootDescription        = 'Official GitHub Copilot repo customization root is .github under the repository.'
    OfficialSkillsRelativePath         = 'skills'
    OfficialSkillsDescription          = 'Agent Skills live under skills/ (user: ~/.copilot/skills; repo: .github/skills).'
    OfficialInstructionsDirRelativePath = 'instructions'
    OfficialInstructionsDirDescription = 'Additional *.instructions.md files live under instructions/ (user: ~/.copilot/instructions; repo: .github/instructions).'
    OfficialInstructionsFileName       = 'copilot-instructions.md'
    OfficialInstructionsFileDescription = 'Primary always-on instructions file is copilot-instructions.md at the mode root (user: ~/.copilot/copilot-instructions.md; repo: .github/copilot-instructions.md).'
    OfficialHooksRelativePath          = 'hooks'
    OfficialHooksDescription           = 'Hooks files live under hooks/ (user: ~/.copilot/hooks; repo: .github/hooks).'
    FixtureUserRelativePath            = 'scripts/validation/fixtures/copilot/user'
    FixtureRepoRelativePath            = 'scripts/validation/fixtures/copilot/repo'
    InstallRootOverrideParameter       = 'InstallRoot'
    InstallRootOverrideDescription     = 'Pass -InstallRoot to target an in-repo fixture or an explicit path. Paths under USERPROFILE require -AllowUserHome. Mode user InstallRoot models ~/.copilot; Mode repo InstallRoot models .github.'
    ModeParameterName                  = 'Mode'
    ModeDescription                    = 'Required for sync/validate/uninstall: -Mode user|repo selects the official layout published in that run.'
    ExcludedIdeNote                    = 'JetBrains and Eclipse Copilot IDE layouts are out of scope; only ~/.copilot and .github official surfaces are supported.'
    ExcludedJetBrainsPathToken         = 'JetBrains'
    ExcludedEclipsePathToken           = 'Eclipse'
    ResolveInstallRootRelativePath     = 'scripts/_lib/Resolve-InstallRoot.ps1'
}

$script:CopilotAdapterMessage = @{
    NotImplemented            = '{0} is not implemented yet for the Copilot adapter. Publish/smoke land in later adapter PLAN steps; stubs must not mutate InstallRoot.'
    AgentIdRequired           = 'AgentId is required.'
    InstallRootRequired       = 'InstallRoot is required.'
    ModeRequiredForMapping    = 'Mode is required to map Copilot InstallRoot paths. Use -Mode user or -Mode repo.'
    ModeInvalidForMapping     = 'Invalid Mode "{0}". Use -Mode user or -Mode repo.'
    CapabilitiesReady         = 'Copilot adapter capabilities reported (skills/rules/hooks; router=false). Mode user|repo required at CLI; Publish-Skills/Policy/Hooks, Invoke-SmokeValidate, and keyed Uninstall-Toolkit ready for both modes (repo via InstallRoot fixture modeling .github). Official surfaces only (~/.copilot and .github); JetBrains/Eclipse excluded. Smoke is filesystem-only.'
    ResolveInstallRootMissing = 'Resolve-InstallRoot helper not found at: {0}'
}

function New-CopilotAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:CopilotAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-CopilotAdapterCommandNames {
    return @($script:CopilotAdapterCommandNames)
}

function Get-CopilotAdapterRepoRoot {
    [CmdletBinding()]
    param()

    $adapterDir = $PSScriptRoot
    $adaptersDir = Split-Path -Parent $adapterDir
    return Split-Path -Parent $adaptersDir
}

function Initialize-CopilotInstallRootResolver {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue) {
        return
    }

    $repoRoot = Get-CopilotAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:CopilotAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:CopilotAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
}

function Get-CopilotNormalizedMode {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Mode
    )

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        return $null
    }

    return $Mode.Trim().ToLowerInvariant()
}

function Assert-CopilotModeForPathMapping {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Mode
    )

    $normalized = Get-CopilotNormalizedMode -Mode $Mode
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        throw $script:CopilotAdapterMessage.ModeRequiredForMapping
    }

    $valid = @(
        $script:CopilotAdapterConstant.ModeUser,
        $script:CopilotAdapterConstant.ModeRepo
    )
    if ($valid -notcontains $normalized) {
        throw ($script:CopilotAdapterMessage.ModeInvalidForMapping -f $Mode)
    }

    return $normalized
}

function Get-CopilotMappedInstallPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter(Mandatory = $true)]
        [ValidateSet('user', 'repo')]
        [string] $Mode
    )

    $skills = Join-Path $ResolvedInstallRoot $script:CopilotAdapterConstant.OfficialSkillsRelativePath
    $instructionsDir = Join-Path $ResolvedInstallRoot $script:CopilotAdapterConstant.OfficialInstructionsDirRelativePath
    $instructionsFile = Join-Path $ResolvedInstallRoot $script:CopilotAdapterConstant.OfficialInstructionsFileName
    $hooks = Join-Path $ResolvedInstallRoot $script:CopilotAdapterConstant.OfficialHooksRelativePath

    return [PSCustomObject]@{
        Mode                         = $Mode
        FixtureSkillsPath            = $skills
        FixtureInstructionsDirPath   = $instructionsDir
        FixtureInstructionsFilePath  = $instructionsFile
        FixtureHooksPath             = $hooks
        ModeledOfficialRootRelative  = $(if ($Mode -eq $script:CopilotAdapterConstant.ModeUser) {
                $script:CopilotAdapterConstant.OfficialUserRootRelativePath
            }
            else {
                $script:CopilotAdapterConstant.OfficialRepoRootRelativePath
            })
    }
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Copilot adapter capability flags (skills/rules/hooks).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:CopilotAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:CopilotAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$script:CopilotAdapterCapabilityFlags
        Message      = $script:CopilotAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official Copilot install roots and map them under InstallRoot by Mode.
    .DESCRIPTION
      Mode user: InstallRoot models ~/.copilot (skills, instructions, hooks under that root).
      Mode repo: InstallRoot models .github (skills, instructions, hooks under that root).
      When InstallRoot is set, Resolve-InstallRoot enforces USERPROFILE fail-closed unless -AllowUserHome.
      Excluded: JetBrains/Eclipse IDE layout paths (not mapped).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentId,

        [Parameter()]
        [string] $Mode,

        [Parameter()]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        throw $script:CopilotAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialUserFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialUserFull = Join-Path $userHome $script:CopilotAdapterConstant.OfficialUserRootRelativePath
    }

    $normalizedMode = Get-CopilotNormalizedMode -Mode $Mode
    $resolvedInstallRoot = $null
    $mapped = $null

    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        $normalizedMode = Assert-CopilotModeForPathMapping -Mode $Mode
        Initialize-CopilotInstallRootResolver
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
        $mapped = Get-CopilotMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot -Mode $normalizedMode
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Mode)) {
        $normalizedMode = Assert-CopilotModeForPathMapping -Mode $Mode
    }

    return [PSCustomObject]@{
        Success                            = $true
        Implemented                        = $true
        AgentId                            = $AgentId.Trim()
        Mode                               = $normalizedMode
        ValidModes                         = @($script:CopilotAdapterConstant.ModeUser, $script:CopilotAdapterConstant.ModeRepo)
        OfficialUserRootRelativePath       = $script:CopilotAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription        = $script:CopilotAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath               = $officialUserFull
        OfficialRepoRootRelativePath       = $script:CopilotAdapterConstant.OfficialRepoRootRelativePath
        OfficialRepoRootDescription        = $script:CopilotAdapterConstant.OfficialRepoRootDescription
        OfficialSkillsRelativePath         = $script:CopilotAdapterConstant.OfficialSkillsRelativePath
        OfficialSkillsDescription          = $script:CopilotAdapterConstant.OfficialSkillsDescription
        OfficialInstructionsDirRelativePath = $script:CopilotAdapterConstant.OfficialInstructionsDirRelativePath
        OfficialInstructionsDirDescription = $script:CopilotAdapterConstant.OfficialInstructionsDirDescription
        OfficialInstructionsFileName       = $script:CopilotAdapterConstant.OfficialInstructionsFileName
        OfficialInstructionsFileDescription = $script:CopilotAdapterConstant.OfficialInstructionsFileDescription
        OfficialHooksRelativePath          = $script:CopilotAdapterConstant.OfficialHooksRelativePath
        OfficialHooksDescription           = $script:CopilotAdapterConstant.OfficialHooksDescription
        FixtureUserRelativePath            = $script:CopilotAdapterConstant.FixtureUserRelativePath
        FixtureRepoRelativePath            = $script:CopilotAdapterConstant.FixtureRepoRelativePath
        OverrideParameter                  = $script:CopilotAdapterConstant.InstallRootOverrideParameter
        OverrideDescription                = $script:CopilotAdapterConstant.InstallRootOverrideDescription
        ModeParameter                      = $script:CopilotAdapterConstant.ModeParameterName
        ModeDescription                    = $script:CopilotAdapterConstant.ModeDescription
        ExcludedIdeNote                    = $script:CopilotAdapterConstant.ExcludedIdeNote
        ExcludedJetBrainsPathToken         = $script:CopilotAdapterConstant.ExcludedJetBrainsPathToken
        ExcludedEclipsePathToken           = $script:CopilotAdapterConstant.ExcludedEclipsePathToken
        ResolvedInstallRoot                = $resolvedInstallRoot
        ModeledOfficialRootRelative        = $(if ($null -ne $mapped) { $mapped.ModeledOfficialRootRelative } else { $null })
        FixtureSkillsPath                  = $(if ($null -ne $mapped) { $mapped.FixtureSkillsPath } else { $null })
        FixtureInstructionsDirPath         = $(if ($null -ne $mapped) { $mapped.FixtureInstructionsDirPath } else { $null })
        FixtureInstructionsFilePath        = $(if ($null -ne $mapped) { $mapped.FixtureInstructionsFilePath } else { $null })
        FixtureHooksPath                   = $(if ($null -ne $mapped) { $mapped.FixtureHooksPath } else { $null })
        Message                            = ('{0} {1} {2} {3} {4} {5}' -f $script:CopilotAdapterConstant.OfficialUserRootDescription, $script:CopilotAdapterConstant.OfficialRepoRootDescription, $script:CopilotAdapterConstant.OfficialSkillsDescription, $script:CopilotAdapterConstant.InstallRootOverrideDescription, $script:CopilotAdapterConstant.ModeDescription, $script:CopilotAdapterConstant.ExcludedIdeNote)
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills into InstallRoot/skills for -Mode user|repo (kebab folders + placeholders).
    .DESCRIPTION
      Mode user: InstallRoot models ~/.copilot. Mode repo: InstallRoot models .github.
      Does not write under USERPROFILE without -AllowUserHome.
      Mode repo must use a fixture InstallRoot - not the toolkit working-tree .github.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [string] $Mode,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotAdapterMessage.InstallRootRequired
    }

    return Invoke-CopilotPublishSkills -InstallRoot $InstallRoot -Mode $Mode -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Publish Copilot instructions from core policy/router (Mode user|repo).
    .DESCRIPTION
      core/policy/*.md -> InstallRoot/instructions/*.instructions.md (no Cursor .mdc).
      core/router/AGENTS.md -> InstallRoot/copilot-instructions.md.
      Mode user: ~/.copilot model. Mode repo: .github model via InstallRoot fixture.
      Smoke is filesystem-only.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [string] $Mode,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotAdapterMessage.InstallRootRequired
    }

    return Invoke-CopilotPublishPolicy -InstallRoot $InstallRoot -Mode $Mode -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Documented no-op - Copilot MVP has no dedicated router surface (router=false).
    .DESCRIPTION
      Router guidance from core/router is folded into copilot-instructions.md via Publish-Policy.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [string] $Mode,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotAdapterMessage.InstallRootRequired
    }

    $normalizedMode = $null
    if (-not [string]::IsNullOrWhiteSpace($Mode)) {
        $normalizedMode = Get-CopilotNormalizedMode -Mode $Mode
    }

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Router'
        NoOp        = $true
        WhatIf      = [bool]$WhatIf.IsPresent
        Mode        = $normalizedMode
        InstallRoot = $InstallRoot.Trim()
        FilesCopied = 0
        Message     = $script:CopilotPublishMessage.RouterNoOp
        ExitCode    = 0
    }
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Publish Copilot hooks files when hooks capable (Mode user|repo).
    .DESCRIPTION
      adapters/copilot/assets/hooks/* -> InstallRoot/hooks/*. When hooks=false: no-op.
      Mode repo: InstallRoot models .github (fixture only by default). Smoke is filesystem-only.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [string] $Mode,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotAdapterMessage.InstallRootRequired
    }

    return Invoke-CopilotPublishHooks -InstallRoot $InstallRoot -Mode $Mode -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Get-SddRoot {
    <#
    .SYNOPSIS
      Resolve the published SDD root under InstallRoot. Stub - sdd capability is false for Copilot MVP.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotAdapterMessage.InstallRootRequired
    }

    return New-CopilotAdapterNotImplementedResult -CommandName 'Get-SddRoot'
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run Copilot filesystem smoke against a fixture InstallRoot for -Mode user|repo.
    .DESCRIPTION
      Checks skills, instructions, and hooks (when capable). TE01 InstallRoot safety,
      TE02 Mode, TE03 missing artifacts, TE04 hooks capable but missing. No Copilot
      IDE / GitHub login. ExitCode 0 on PASS; 1 on FAIL (CI-friendly).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [string] $Mode,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotAdapterMessage.InstallRootRequired
    }

    return Invoke-CopilotSmokeValidateCore -InstallRoot $InstallRoot -Mode $Mode -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts from InstallRoot for -Mode user|repo.
    .DESCRIPTION
      Deletes only paths published from core/skills, core/policy -> instructions,
      copilot-instructions.md, and adapter hook assets. Leaves alien files and
      InstallRoot tree itself intact (RN07 / CU04).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [string] $Mode,
        [Parameter()]
        [switch] $AllowUserHome,
        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotAdapterMessage.InstallRootRequired
    }

    return Invoke-CopilotUninstallToolkit -InstallRoot $InstallRoot -Mode $Mode -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
