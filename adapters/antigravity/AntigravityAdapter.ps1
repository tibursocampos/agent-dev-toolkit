#Requires -Version 5.1
<#
.SYNOPSIS
  Antigravity adapter module for agent-dev-toolkit.

.DESCRIPTION
  Exposes the stable adapter contract for agent id `antigravity`.
  Get-Capabilities / Get-InstallRoots describe the official ~/.gemini/config layout
  and document the legacy antigravity-ide/plugins bridge as non-default.
  Optional -InstallRoot maps official config/* paths under an in-repo fixture via
  Resolve-InstallRoot (USERPROFILE blocked without -AllowUserHome).
  Publish-Skills copies core/skills (kebab folders) to config/skills and upserts
  config/skills.json (fail-closed: invalid JSON aborts without writing; existing
  files are backed up to skills.json.bak before an upsert write). Publish-Policy
  writes GUARDRAILS.md from core/policy under
  config/plugins/agent-dev-toolkit. Publish-Router materializes skills/dev_persona
  from core/router and upserts managed blocks in config/AGENTS.md and config/GEMINI.md.
  Publish-Hooks is a capability-honest no-op (hooks=false): no writes under
  config/hooks or the legacy antigravity-ide/plugins bridge. Get-SddRoot (-Prepare)
  prepares InstallRoot/sdd (sessions + manifest seed). Invoke-SmokeValidate
  asserts official config/* artifacts (kebab skills, GUARDRAILS, dev_persona,
  skills.json). Uninstall-Toolkit removes keyed toolkit artifacts only.
  Does not write under USERPROFILE without -AllowUserHome.
#>

$script:AntigravityAdapterDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:AntigravityAdapterDirectory)) {
    $script:AntigravityAdapterDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

. (Join-Path $script:AntigravityAdapterDirectory 'AntigravityPathConstants.ps1')
. (Join-Path $script:AntigravityAdapterDirectory 'Publish-AntigravityPolicy.ps1')
. (Join-Path $script:AntigravityAdapterDirectory 'Publish-AntigravityRouter.ps1')
. (Join-Path $script:AntigravityAdapterDirectory 'Invoke-AntigravitySmokeValidate.ps1')
. (Join-Path $script:AntigravityAdapterDirectory 'Uninstall-AntigravityToolkit.ps1')

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_antigravityToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:AntigravityAdapterDirectory)
) 'scripts\_lib'
. (Join-Path $_antigravityToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
. (Join-Path $_antigravityToolkitLibDirectory 'Initialize-SddRootLayout.ps1')
Remove-Variable -Name _antigravityToolkitLibDirectory -ErrorAction SilentlyContinue

$script:AntigravityAdapterAgentId = 'antigravity'

$script:AntigravityAdapterCommandNames = @(
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

# Honest flags: Antigravity IDE has no Cursor-equivalent shell hooks (ENFORCEMENT / hooks investigation).
# Registry declares subagents=native (Antigravity 2.0+); Get-Capabilities uses fail-closed host probe.
$script:AntigravityAdapterSubagentsNative = 'native'
$script:AntigravityAdapterSubagentsNone = 'none'

$script:AntigravityAdapterCapabilityFlags = [ordered]@{
    skills    = $true
    rules     = $true
    hooks     = $false
    router    = $true
    plugin    = $true
    subagents = $script:AntigravityAdapterSubagentsNative
}

$script:AntigravityAdapterConstant = @{
    OfficialUserRootRelativePath       = '.gemini'
    OfficialUserRootDescription        = 'Official Antigravity/Gemini user root is under the user home as .gemini (equivalent to ~/.gemini).'
    OfficialConfigRelativePath         = 'config'
    OfficialConfigDescription          = 'Official runtime layout lives under config/ relative to the Gemini user root (skills, plugins, hooks, GEMINI.md, AGENTS.md, skills.json).'
    OfficialSkillsRelativePath         = 'config/skills'
    OfficialPluginsRelativePath        = 'config/plugins'
    OfficialHooksRelativePath          = 'config/hooks'
    OfficialSkillsJsonRelativePath     = 'config/skills.json'
    OfficialAgentsMdRelativePath       = 'config/AGENTS.md'
    OfficialGeminiMdRelativePath       = 'config/GEMINI.md'
    LegacyBridgeRelativePath           = 'antigravity-ide/plugins'
    LegacyBridgeDescription            = 'Legacy bridge path antigravity-ide/plugins is non-default and not a CI/smoke gate; document or opt-in only.'
    FixtureRelativePath                = 'scripts/validation/fixtures/antigravity-install-root'
    InstallRootOverrideParameter       = 'InstallRoot'
    InstallRootOverrideDescription     = 'Pass -InstallRoot to model ~/.gemini (or an in-repo fixture). Paths under USERPROFILE require -AllowUserHome. Default smoke targets official config/* under InstallRoot, not the legacy bridge.'
    SkillsJsonFileName                 = 'skills.json'
    AgentsMdFileName                   = 'AGENTS.md'
    GeminiMdFileName                   = 'GEMINI.md'
    ResolveInstallRootRelativePath     = 'scripts/_lib/Resolve-InstallRoot.ps1'
    CoreDirectoryName                  = 'core'
    SkillsDirectoryName                = 'skills'
    SkillsJsonEntriesPropertyName      = 'entries'
    SkillsJsonPathPropertyName         = 'path'
    SkillsJsonIdPropertyName           = 'id'
    SkillsJsonBackupSuffix             = '.bak'
    ManagedSkillsJsonEntryId           = 'agent-dev-toolkit'
    LegacyPluginSkillsId               = 'Local.raphadev.antigravity-dev-toolkit'
    PathSeparatorForwardSlash          = '/'
    PathSeparatorBackslash             = '\'
    SubagentsOverrideEnvName           = 'ADT_ANTIGRAVITY_SUBAGENTS'
    AgyCliCommandName                  = 'agy'
    AgyVersionArgument                 = '--version'
    MinCliHarnessProxyVersion          = '1.0.0'
    MinProductSubagentsVersion         = '2.0.0'
    ProductVersionEnvName              = 'ADT_ANTIGRAVITY_PRODUCT_VERSION'
    VersionCaptureRegex                = '(\d+\.\d+\.\d+(?:\.\d+)?)'
    VersionProbeTimeoutMs              = 5000
    JsonConvertDepthShallow            = 5
}

$script:AntigravityAdapterMessage = @{
    NotImplemented            = '{0} is not implemented yet for the Antigravity adapter. Publish/smoke land in later adapter PLAN steps; stubs must not mutate InstallRoot.'
    AgentIdRequired           = 'AgentId is required.'
    InstallRootRequired       = 'InstallRoot is required.'
    CapabilitiesReady         = 'Antigravity adapter capabilities reported (skills/rules/router/plugin; hooks=false - no native shell-hook parity; subagents via fail-closed host probe / ADT_ANTIGRAVITY_SUBAGENTS override). Publish-Skills/Policy/Router ready; Publish-Hooks is a documented no-op; Get-SddRoot (-Prepare) and Invoke-SmokeValidate ready (filesystem-only; hooks/legacy bridge ignored); Uninstall-Toolkit keyed removal ready. SDD runtime prepared on sync.'
    ResolveInstallRootMissing = 'Resolve-InstallRoot helper not found at: {0}'
    SddRootResolved           = 'Antigravity SDD root resolved at {0}.'
    SddRootPrepared           = 'Prepared Antigravity SDD root at {0} (sessionsCreated={1}; manifestCreated={2}).'
    SddRootWouldPrepare       = 'WhatIf: would prepare Antigravity SDD root at {0} (sessions + seed manifest.json if missing).'
    CoreSkillsMissing         = 'Antigravity Publish-Skills: core skills source is missing: {0}'
    SkillsPublished           = 'Antigravity Publish-Skills: published {0} skill folder(s) from core/skills to {1}; skills.json upserted at {2}'
    SkillsWouldPublish        = 'Antigravity Publish-Skills: WhatIf - would publish core/skills to {0} and upsert skills.json at {1}'
    SkillsJsonReadFailed      = 'Antigravity Publish-Skills: failed to read skills.json at {0}: {1}. Aborting without writing to avoid data loss.'
    SkillsJsonInvalidJson     = 'Antigravity Publish-Skills: invalid JSON in skills.json at {0}: {1}. Aborting without writing to avoid data loss.'
    SkillsJsonBackupFailed    = 'Antigravity Publish-Skills: failed to back up skills.json from {0} to {1}: {2}. Aborting without writing.'
    SkillsJsonWriteFailed     = 'Antigravity Publish-Skills: failed to write skills.json at {0}: {1}'
    HooksNoOpNotCapable       = 'Antigravity Publish-Hooks: hooks capability is false - no-op (no files written under config/hooks or legacy bridge antigravity-ide/plugins). Default smoke ignores hooks and does not gate on the legacy bridge.'
    HooksWouldNoOp            = 'Antigravity Publish-Hooks: WhatIf - would no-op (hooks=false); no writes under {0} or legacy bridge {1}'
}

function New-AntigravityAdapterNotImplementedResult {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    return [PSCustomObject]@{
        Success     = $false
        Implemented = $false
        CommandName = $CommandName
        Message     = ($script:AntigravityAdapterMessage.NotImplemented -f $CommandName)
        ExitCode    = 1
    }
}

function Get-AntigravityAdapterCommandNames {
    return @($script:AntigravityAdapterCommandNames)
}

function Get-AntigravityAdapterRepoRoot {
    [CmdletBinding()]
    param()

    $adapterDir = $PSScriptRoot
    $adaptersDir = Split-Path -Parent $adapterDir
    return Split-Path -Parent $adaptersDir
}

function Initialize-AntigravityInstallRootResolver {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue) {
        return
    }

    $repoRoot = Get-AntigravityAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:AntigravityAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:AntigravityAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    # Dot-source in this function scope; callers must invoke Resolve-InstallRoot
    # before this function returns, or use Resolve-AntigravityInstallRootPath.
    . $resolveScript
}

function Resolve-AntigravityInstallRootPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    $repoRoot = Get-AntigravityAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:AntigravityAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:AntigravityAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    # Load helper into this function scope so Resolve-InstallRoot remains callable here.
    if (-not (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue)) {
        . $resolveScript
    }

    return Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
}

function Initialize-AntigravityInstallRootForWrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome
    )

    $repoRoot = Get-AntigravityAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:AntigravityAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:AntigravityAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    # Dot-source in this function scope (Publish callers cannot see Resolve-* from sibling scopes).
    if (-not (Get-Command -Name Initialize-InstallRootForWrite -ErrorAction SilentlyContinue)) {
        . $resolveScript
    }

    return Initialize-InstallRootForWrite -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
}

function Get-AntigravityMappedInstallPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $sep = [System.IO.Path]::DirectorySeparatorChar
    return [PSCustomObject]@{
        FixtureConfigPath       = Join-Path $ResolvedInstallRoot ($script:AntigravityAdapterConstant.OfficialConfigRelativePath -replace '/', $sep)
        FixtureSkillsPath       = Join-Path $ResolvedInstallRoot ($script:AntigravityAdapterConstant.OfficialSkillsRelativePath -replace '/', $sep)
        FixturePluginsPath      = Join-Path $ResolvedInstallRoot ($script:AntigravityAdapterConstant.OfficialPluginsRelativePath -replace '/', $sep)
        FixtureHooksPath        = Join-Path $ResolvedInstallRoot ($script:AntigravityAdapterConstant.OfficialHooksRelativePath -replace '/', $sep)
        FixtureSkillsJsonPath   = Join-Path $ResolvedInstallRoot ($script:AntigravityAdapterConstant.OfficialSkillsJsonRelativePath -replace '/', $sep)
        FixtureAgentsMdPath     = Join-Path $ResolvedInstallRoot ($script:AntigravityAdapterConstant.OfficialAgentsMdRelativePath -replace '/', $sep)
        FixtureGeminiMdPath     = Join-Path $ResolvedInstallRoot ($script:AntigravityAdapterConstant.OfficialGeminiMdRelativePath -replace '/', $sep)
        FixtureGuardrailsPath   = Join-Path $ResolvedInstallRoot ($script:AntigravityPathConstant.OfficialGuardrailsRelativePath -replace '/', $sep)
        FixtureDevPersonaPath   = Join-Path $ResolvedInstallRoot ($script:AntigravityPathConstant.OfficialDevPersonaSkillRelativePath -replace '/', $sep)
        FixtureDevPersonaDir    = Join-Path $ResolvedInstallRoot ($script:AntigravityPathConstant.OfficialDevPersonaRelativePath -replace '/', $sep)
    }
}

function ConvertTo-AntigravityVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RawText
    )

    if ([string]::IsNullOrWhiteSpace($RawText)) {
        return $null
    }

    $match = [regex]::Match($RawText, $script:AntigravityAdapterConstant.VersionCaptureRegex)
    if (-not $match.Success) {
        return $null
    }

    $parsed = $null
    if (-not [version]::TryParse($match.Groups[1].Value, [ref]$parsed)) {
        return $null
    }

    return $parsed
}

function Get-AntigravityAgyCliVersionText {
    [CmdletBinding()]
    param()

    $cliName = $script:AntigravityAdapterConstant.AgyCliCommandName
    $cli = Get-Command -Name $cliName -ErrorAction SilentlyContinue
    if ($null -eq $cli) {
        return $null
    }

    $argument = $script:AntigravityAdapterConstant.AgyVersionArgument
    $timeoutMs = [int]$script:AntigravityAdapterConstant.VersionProbeTimeoutMs
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $cli.Source
        $psi.Arguments = $argument
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        [void]$proc.Start()
        if (-not $proc.WaitForExit($timeoutMs)) {
            try { $proc.Kill() } catch { }
            return $null
        }

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        return (($stdout + [Environment]::NewLine + $stderr).Trim())
    }
    catch {
        return $null
    }
}

function Resolve-AntigravitySubagentsCapability {
    <#
    .SYNOPSIS
      Fail-closed probe for hierarchical subagents (invoke_subagent since Antigravity 2.0).
    .NOTES
      Registry declares native; effective capability may be none when host is pre-2.0 or unverifiable.
      CLI agy is 1.x on the shared 2.0 harness — do not gate on CLI major >= 2.
    #>
    [CmdletBinding()]
    param()

    $native = $script:AntigravityAdapterSubagentsNative
    $none = $script:AntigravityAdapterSubagentsNone
    $overrideName = $script:AntigravityAdapterConstant.SubagentsOverrideEnvName
    $overrideRaw = [Environment]::GetEnvironmentVariable($overrideName)
    if (-not [string]::IsNullOrWhiteSpace($overrideRaw)) {
        $normalized = $overrideRaw.Trim().ToLowerInvariant()
        if ($normalized -eq $native -or $normalized -eq $none) {
            return $normalized
        }
    }

    $minProduct = [version]$script:AntigravityAdapterConstant.MinProductSubagentsVersion
    $productEnvName = $script:AntigravityAdapterConstant.ProductVersionEnvName
    $productRaw = [Environment]::GetEnvironmentVariable($productEnvName)
    if (-not [string]::IsNullOrWhiteSpace($productRaw)) {
        $productVersion = ConvertTo-AntigravityVersion -RawText $productRaw
        if ($null -eq $productVersion) {
            return $none
        }

        if ($productVersion -lt $minProduct) {
            return $none
        }

        return $native
    }

    $cliText = Get-AntigravityAgyCliVersionText
    if ([string]::IsNullOrWhiteSpace($cliText)) {
        return $none
    }

    $cliVersion = ConvertTo-AntigravityVersion -RawText $cliText
    if ($null -eq $cliVersion) {
        return $none
    }

    $minCli = [version]$script:AntigravityAdapterConstant.MinCliHarnessProxyVersion
    if ($cliVersion -ge $minCli) {
        return $native
    }

    return $none
}

function Get-Capabilities {
    <#
    .SYNOPSIS
      Report Antigravity adapter capability flags (honest hooks=false; subagents via host probe).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $AgentId = $script:AntigravityAdapterAgentId
    )

    $resolvedAgentId = if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $script:AntigravityAdapterAgentId
    }
    else {
        $AgentId.Trim()
    }

    $flags = [ordered]@{}
    foreach ($key in $script:AntigravityAdapterCapabilityFlags.Keys) {
        $flags[$key] = $script:AntigravityAdapterCapabilityFlags[$key]
    }

    $flags['subagents'] = Resolve-AntigravitySubagentsCapability

    return [PSCustomObject]@{
        AgentId      = $resolvedAgentId
        Implemented  = $true
        Capabilities = [PSCustomObject]$flags
        Message      = $script:AntigravityAdapterMessage.CapabilitiesReady
    }
}

function Get-InstallRoots {
    <#
    .SYNOPSIS
      Describe official Antigravity/Gemini install roots, config subpaths, and legacy bridge.
      Optional -InstallRoot maps official config/* paths under a fixture via Resolve-InstallRoot.
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
        throw $script:AntigravityAdapterMessage.AgentIdRequired
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $officialFull = $null
    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $officialFull = Join-Path $userHome $script:AntigravityAdapterConstant.OfficialUserRootRelativePath
    }

    $resolvedInstallRoot = $null
    $mapped = $null
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
        $mapped = Get-AntigravityMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    }

    return [PSCustomObject]@{
        Success                        = $true
        Implemented                    = $true
        AgentId                        = $AgentId.Trim()
        OfficialUserRootRelativePath   = $script:AntigravityAdapterConstant.OfficialUserRootRelativePath
        OfficialUserRootDescription    = $script:AntigravityAdapterConstant.OfficialUserRootDescription
        OfficialUserRootPath           = $officialFull
        OfficialConfigRelativePath     = $script:AntigravityAdapterConstant.OfficialConfigRelativePath
        OfficialConfigDescription      = $script:AntigravityAdapterConstant.OfficialConfigDescription
        OfficialSkillsRelativePath     = $script:AntigravityAdapterConstant.OfficialSkillsRelativePath
        OfficialPluginsRelativePath    = $script:AntigravityAdapterConstant.OfficialPluginsRelativePath
        OfficialHooksRelativePath      = $script:AntigravityAdapterConstant.OfficialHooksRelativePath
        OfficialSkillsJsonRelativePath = $script:AntigravityAdapterConstant.OfficialSkillsJsonRelativePath
        OfficialAgentsMdRelativePath   = $script:AntigravityAdapterConstant.OfficialAgentsMdRelativePath
        OfficialGeminiMdRelativePath   = $script:AntigravityAdapterConstant.OfficialGeminiMdRelativePath
        LegacyBridgeRelativePath       = $script:AntigravityAdapterConstant.LegacyBridgeRelativePath
        LegacyBridgeDescription        = $script:AntigravityAdapterConstant.LegacyBridgeDescription
        FixtureRelativePath            = $script:AntigravityAdapterConstant.FixtureRelativePath
        OverrideParameter              = $script:AntigravityAdapterConstant.InstallRootOverrideParameter
        OverrideDescription            = $script:AntigravityAdapterConstant.InstallRootOverrideDescription
        SkillsJsonFileName             = $script:AntigravityAdapterConstant.SkillsJsonFileName
        AgentsMdFileName               = $script:AntigravityAdapterConstant.AgentsMdFileName
        GeminiMdFileName               = $script:AntigravityAdapterConstant.GeminiMdFileName
        ResolvedInstallRoot            = $resolvedInstallRoot
        FixtureConfigPath              = $(if ($null -ne $mapped) { $mapped.FixtureConfigPath } else { $null })
        FixtureSkillsPath              = $(if ($null -ne $mapped) { $mapped.FixtureSkillsPath } else { $null })
        FixturePluginsPath             = $(if ($null -ne $mapped) { $mapped.FixturePluginsPath } else { $null })
        FixtureHooksPath               = $(if ($null -ne $mapped) { $mapped.FixtureHooksPath } else { $null })
        FixtureSkillsJsonPath          = $(if ($null -ne $mapped) { $mapped.FixtureSkillsJsonPath } else { $null })
        FixtureAgentsMdPath            = $(if ($null -ne $mapped) { $mapped.FixtureAgentsMdPath } else { $null })
        FixtureGeminiMdPath            = $(if ($null -ne $mapped) { $mapped.FixtureGeminiMdPath } else { $null })
        FixtureGuardrailsPath          = $(if ($null -ne $mapped) { $mapped.FixtureGuardrailsPath } else { $null })
        FixtureDevPersonaPath          = $(if ($null -ne $mapped) { $mapped.FixtureDevPersonaPath } else { $null })
        FixtureDevPersonaDir           = $(if ($null -ne $mapped) { $mapped.FixtureDevPersonaDir } else { $null })
        OfficialGuardrailsRelativePath = $script:AntigravityPathConstant.OfficialGuardrailsRelativePath
        OfficialDevPersonaRelativePath = $script:AntigravityPathConstant.OfficialDevPersonaRelativePath
        Message                        = ('{0} {1} {2} {3}' -f $script:AntigravityAdapterConstant.OfficialUserRootDescription, $script:AntigravityAdapterConstant.OfficialConfigDescription, $script:AntigravityAdapterConstant.LegacyBridgeDescription, $script:AntigravityAdapterConstant.InstallRootOverrideDescription)
    }
}

function Initialize-AntigravityToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-AntigravityAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ("Antigravity Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Copy-AntigravityCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-AntigravityToolkitManagedTreeLib
    $null = Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot
    return @(Get-ToolkitSourceSkillNames -SourceSkillsRoot $SourceSkillsRoot).Count
}

function Test-AntigravityLegacySkillsJsonPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $EntryPath
    )

    if ([string]::IsNullOrWhiteSpace($EntryPath)) {
        return $false
    }

    $legacyId = $script:AntigravityAdapterConstant.LegacyPluginSkillsId
    $fwd = $script:AntigravityAdapterConstant.PathSeparatorForwardSlash
    $bck = $script:AntigravityAdapterConstant.PathSeparatorBackslash
    $legacyForward = ('{0}{1}skills' -f $legacyId, $fwd)
    $legacyBackslash = ('{0}{1}skills' -f $legacyId, $bck)

    return (
        $EntryPath.IndexOf($legacyForward, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $EntryPath.IndexOf($legacyBackslash, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    )
}

function Get-AntigravitySkillsJsonBackupPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsJsonPath
    )

    return ($SkillsJsonPath + $script:AntigravityAdapterConstant.SkillsJsonBackupSuffix)
}

function Backup-AntigravitySkillsJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsJsonPath,

        [Parameter(Mandatory = $true)]
        [string] $BackupPath
    )

    try {
        Copy-Item -LiteralPath $SkillsJsonPath -Destination $BackupPath -Force -ErrorAction Stop
    }
    catch {
        throw ($script:AntigravityAdapterMessage.SkillsJsonBackupFailed -f $SkillsJsonPath, $BackupPath, $_.Exception.Message)
    }
}

function Read-AntigravitySkillsJsonObject {
    <#
    .SYNOPSIS
      Fail-closed read: missing/empty file returns $null (new skeleton is fine); invalid JSON throws.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsJsonPath
    )

    if (-not (Test-Path -LiteralPath $SkillsJsonPath)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $SkillsJsonPath -Raw -ErrorAction Stop
    }
    catch {
        throw ($script:AntigravityAdapterMessage.SkillsJsonReadFailed -f $SkillsJsonPath, $_.Exception.Message)
    }

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    try {
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        throw ($script:AntigravityAdapterMessage.SkillsJsonInvalidJson -f $SkillsJsonPath, $_.Exception.Message)
    }
}

function Update-AntigravitySkillsJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsJsonPath,

        [Parameter(Mandatory = $true)]
        [string] $PublishedSkillsPath
    )

    $entriesProperty = $script:AntigravityAdapterConstant.SkillsJsonEntriesPropertyName
    $pathProperty = $script:AntigravityAdapterConstant.SkillsJsonPathPropertyName
    $idProperty = $script:AntigravityAdapterConstant.SkillsJsonIdPropertyName
    $managedId = $script:AntigravityAdapterConstant.ManagedSkillsJsonEntryId
    $normalizedPublishedPath = [System.IO.Path]::GetFullPath($PublishedSkillsPath)

    # Fail-closed: invalid JSON / unreadable existing file throws here and no write occurs below.
    $skillsJsonExisted = Test-Path -LiteralPath $SkillsJsonPath
    $skillsJsonContent = Read-AntigravitySkillsJsonObject -SkillsJsonPath $SkillsJsonPath

    if ($null -eq $skillsJsonContent) {
        $skillsJsonContent = New-Object -TypeName PSObject
        $skillsJsonContent | Add-Member -NotePropertyName $entriesProperty -NotePropertyValue @()
    }
    else {
        $entriesMember = $skillsJsonContent.PSObject.Properties[$entriesProperty]
        if ($null -eq $entriesMember) {
            $skillsJsonContent | Add-Member -NotePropertyName $entriesProperty -NotePropertyValue @() -Force
        }
        elseif ($null -eq $entriesMember.Value) {
            $skillsJsonContent | Add-Member -NotePropertyName $entriesProperty -NotePropertyValue @() -Force
        }
    }

    function New-AntigravityManagedSkillsJsonEntry {
        param(
            [Parameter(Mandatory = $true)][string] $EntryId,
            [Parameter(Mandatory = $true)][string] $EntryPath
        )

        $managedEntry = New-Object -TypeName PSObject
        $managedEntry | Add-Member -NotePropertyName $idProperty -NotePropertyValue $EntryId
        $managedEntry | Add-Member -NotePropertyName $pathProperty -NotePropertyValue $EntryPath
        return $managedEntry
    }

    $normalizedEntries = @()
    $entryExists = $false
    foreach ($entry in @($skillsJsonContent.$entriesProperty)) {
        if ($null -eq $entry) {
            continue
        }

        $entryPath = [string]$entry.$pathProperty
        if ([string]::IsNullOrWhiteSpace($entryPath)) {
            continue
        }

        if (Test-AntigravityLegacySkillsJsonPath -EntryPath $entryPath) {
            continue
        }

        $entryId = $null
        if ($entry.PSObject.Properties.Name -contains $idProperty) {
            $entryId = [string]$entry.$idProperty
        }

        $normalizedEntryPath = $entryPath
        try {
            $normalizedEntryPath = [System.IO.Path]::GetFullPath($entryPath)
        }
        catch {
            $normalizedEntryPath = $entryPath
        }

        $isManagedId = (-not [string]::IsNullOrWhiteSpace($entryId)) -and
            [string]::Equals($entryId, $managedId, [System.StringComparison]::OrdinalIgnoreCase)
        $isManagedPath = [string]::Equals($normalizedEntryPath, $normalizedPublishedPath, [System.StringComparison]::OrdinalIgnoreCase)

        if ($isManagedId -or $isManagedPath) {
            if (-not $entryExists) {
                $normalizedEntries += (New-AntigravityManagedSkillsJsonEntry -EntryId $managedId -EntryPath $normalizedPublishedPath)
                $entryExists = $true
            }
            continue
        }

        $normalizedEntries += $entry
    }

    if (-not $entryExists) {
        $normalizedEntries += (New-AntigravityManagedSkillsJsonEntry -EntryId $managedId -EntryPath $normalizedPublishedPath)
    }

    $skillsJsonContent.$entriesProperty = @($normalizedEntries)

    $skillsJsonParent = Split-Path -Parent $SkillsJsonPath
    if (-not (Test-Path -LiteralPath $skillsJsonParent)) {
        New-Item -ItemType Directory -Path $skillsJsonParent -Force | Out-Null
    }

    $backupPath = Get-AntigravitySkillsJsonBackupPath -SkillsJsonPath $SkillsJsonPath
    $backupTaken = $false
    if ($skillsJsonExisted) {
        # Backup before write; a backup failure aborts here without touching the original file.
        Backup-AntigravitySkillsJsonFile -SkillsJsonPath $SkillsJsonPath -BackupPath $backupPath
        $backupTaken = $true
    }

    try {
        $jsonString = $skillsJsonContent | ConvertTo-Json -Depth $script:AntigravityAdapterConstant.JsonConvertDepthShallow
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($SkillsJsonPath, $jsonString, $utf8NoBom)
    }
    catch {
        throw ($script:AntigravityAdapterMessage.SkillsJsonWriteFailed -f $SkillsJsonPath, $_.Exception.Message)
    }

    return [PSCustomObject]@{
        SkillsJsonPath       = $SkillsJsonPath
        PublishedSkillsPath  = $normalizedPublishedPath
        ManagedEntryId       = $managedId
        EntryCount           = @($normalizedEntries).Count
        BackupPath           = $backupPath
        BackupTaken          = $backupTaken
    }
}

function Publish-Skills {
    <#
    .SYNOPSIS
      Publish core/skills (kebab folders) into InstallRoot/config/skills and upsert skills.json.
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
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-AntigravityAdapterRepoRoot
    $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
    $mapped = Get-AntigravityMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot

    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:AntigravityAdapterConstant.CoreDirectoryName) $script:AntigravityAdapterConstant.SkillsDirectoryName
    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:AntigravityAdapterMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    $destSkillsRoot = $mapped.FixtureSkillsPath
    $skillsJsonPath = $mapped.FixtureSkillsJsonPath
    $skillFolderCount = @(Get-ChildItem -LiteralPath $sourceSkillsRoot -Directory -ErrorAction Stop).Count

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success              = $true
            Implemented          = $true
            CommandName          = 'Publish-Skills'
            InstallRoot          = $resolvedInstallRoot
            SourceSkillsRoot     = $sourceSkillsRoot
            DestSkillsRoot       = $destSkillsRoot
            SkillsJsonPath       = $skillsJsonPath
            ManagedSkillsEntryId = $script:AntigravityAdapterConstant.ManagedSkillsJsonEntryId
            SkillFolderCount     = $skillFolderCount
            WhatIf               = $true
            Message              = ($script:AntigravityAdapterMessage.SkillsWouldPublish -f $destSkillsRoot, $skillsJsonPath)
            ExitCode             = 0
        }
    }

    $resolvedInstallRoot = Initialize-AntigravityInstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome
    $mapped = Get-AntigravityMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destSkillsRoot = $mapped.FixtureSkillsPath
    $skillsJsonPath = $mapped.FixtureSkillsJsonPath

    Initialize-AntigravityToolkitManagedTreeLib
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -SkipPlaceholderResolve
    $publishedCount = $publishResult.SkillFolderCount
    $skillsJsonResult = Update-AntigravitySkillsJson -SkillsJsonPath $skillsJsonPath -PublishedSkillsPath $destSkillsRoot

    return [PSCustomObject]@{
        Success               = $true
        Implemented           = $true
        CommandName           = 'Publish-Skills'
        InstallRoot           = $resolvedInstallRoot
        SourceSkillsRoot      = $sourceSkillsRoot
        DestSkillsRoot        = $destSkillsRoot
        SkillsJsonPath        = $skillsJsonResult.SkillsJsonPath
        ManagedSkillsEntryId  = $skillsJsonResult.ManagedEntryId
        SkillFolderCount      = $publishedCount
        SkillsJsonEntryCount  = $skillsJsonResult.EntryCount
        SkillsJsonBackupPath  = $skillsJsonResult.BackupPath
        SkillsJsonBackupTaken = $skillsJsonResult.BackupTaken
        WhatIf                = $false
        Message               = ($script:AntigravityAdapterMessage.SkillsPublished -f $publishedCount, $destSkillsRoot, $skillsJsonResult.SkillsJsonPath)
        ExitCode              = 0
    }
}

function Publish-Policy {
    <#
    .SYNOPSIS
      Generate GUARDRAILS.md under config/plugins/agent-dev-toolkit from core/policy.
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
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    return Invoke-AntigravityPublishPolicy -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Router {
    <#
    .SYNOPSIS
      Materialize skills/dev_persona from core/router and upsert managed AGENTS.md/GEMINI.md blocks.
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
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    return Invoke-AntigravityPublishRouter -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}

function Publish-Hooks {
    <#
    .SYNOPSIS
      Honor Get-Capabilities hooks flag under InstallRoot.

    .DESCRIPTION
      When hooks=false (Antigravity MVP): documented no-op - Success/Implemented,
      no filesystem writes under official config/hooks or legacy antigravity-ide/plugins.
      Default smoke must not require hooks files or the legacy bridge (opt-in only).
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
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    $resolvedInstallRoot = Resolve-AntigravityInstallRootPath -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
    $officialHooksRelative = $script:AntigravityAdapterConstant.OfficialHooksRelativePath
    $legacyBridgeRelative = $script:AntigravityAdapterConstant.LegacyBridgeRelativePath
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $officialHooksPath = Join-Path $resolvedInstallRoot ($officialHooksRelative -replace '/', $sep)
    $legacyBridgePath = Join-Path $resolvedInstallRoot ($legacyBridgeRelative -replace '/', $sep)

    $hooksCapable = $false
    if ($null -ne $script:AntigravityAdapterCapabilityFlags -and $script:AntigravityAdapterCapabilityFlags.Contains('hooks')) {
        $hooksCapable = [bool]$script:AntigravityAdapterCapabilityFlags['hooks']
    }

    if (-not $hooksCapable) {
        $message = if ($WhatIf.IsPresent) {
            ($script:AntigravityAdapterMessage.HooksWouldNoOp -f $officialHooksRelative, $legacyBridgeRelative)
        }
        else {
            $script:AntigravityAdapterMessage.HooksNoOpNotCapable
        }

        return [PSCustomObject]@{
            Success                  = $true
            Implemented              = $true
            NoOp                     = $true
            Skipped                  = $true
            CommandName              = 'Publish-Hooks'
            WhatIf                   = [bool]$WhatIf.IsPresent
            InstallRoot              = $resolvedInstallRoot
            OfficialHooksRelativePath = $officialHooksRelative
            OfficialHooksPath        = $officialHooksPath
            LegacyBridgeRelativePath = $legacyBridgeRelative
            LegacyBridgePath         = $legacyBridgePath
            FilesCopied              = 0
            RequiresShellHooks       = $false
            SmokeIgnoresHooks        = $true
            SmokeTargetsLegacyBridge = $false
            Message                  = $message
            ExitCode                 = 0
        }
    }

    # Future: when hooks capability becomes true, publish under OfficialHooksRelativePath only
    # (never default to LegacyBridgeRelativePath). Unreachable while hooks=false.
    return New-AntigravityAdapterNotImplementedResult -CommandName 'Publish-Hooks'
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
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    return Invoke-ToolkitGetSddRoot `
        -InstallRoot $InstallRoot `
        -RepoRoot (Get-AntigravityAdapterRepoRoot) `
        -Prepare:$Prepare `
        -AllowUserHome:$AllowUserHome `
        -WhatIf:$WhatIf `
        -MessageResolved $script:AntigravityAdapterMessage.SddRootResolved `
        -MessagePrepared $script:AntigravityAdapterMessage.SddRootPrepared `
        -MessageWouldPrepare $script:AntigravityAdapterMessage.SddRootWouldPrepare
}

function Invoke-SmokeValidate {
    <#
    .SYNOPSIS
      Run Antigravity filesystem smoke against a fixture InstallRoot (official config/*).
      Asserts kebab skills, skills.json, GUARDRAILS, dev_persona; ignores hooks/legacy bridge.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    return Invoke-AntigravitySmokeValidate -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome
}

function Uninstall-Toolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts from InstallRoot.
    .DESCRIPTION
      Removes published core skill folders, dev_persona, the managed plugin
      directory (GUARDRAILS), the managed skills.json entry, and managed
      AGENTS.md/GEMINI.md blocks. Preserves alien content, hooks, and the
      legacy bridge. Supports -WhatIf and -AllowUserHome.
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
        throw $script:AntigravityAdapterMessage.InstallRootRequired
    }

    return Invoke-AntigravityUninstallToolkit -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -WhatIf:$WhatIf
}
