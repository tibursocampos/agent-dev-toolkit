#Requires -Version 5.1
<#
.SYNOPSIS
  Loads adapters/registry.json and resolves a Tier agent entry + module path.

.DESCRIPTION
  Shared by sync-agent / validate-agent orchestrators. Fail-closed on missing
  registry, unknown agent id, or missing module file.
#>

$toolkitLibDir = $PSScriptRoot
. (Join-Path $toolkitLibDir 'ToolkitConstants.ps1')
. (Join-Path $toolkitLibDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $toolkitLibDir 'Resolve-InstallRoot.ps1')

function Get-AdapterRegistryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    return (Join-Path (Join-Path $RepoRoot $script:ToolkitConstant.AdaptersDirectoryName) $script:ToolkitConstant.RegistryFileName)
}

function Get-AdapterRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $registryPath = Get-AdapterRegistryPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $registryPath)) {
        throw ($script:ToolkitMessage.RegistryMissing -f $registryPath)
    }

    $registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
    if ($null -eq $registry.agents) {
        throw ($script:ToolkitMessage.RegistryAgentsMissing -f $registryPath)
    }

    return $registry
}

function Get-AdapterAvailableAgentIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Registry
    )

    return @($Registry.agents | ForEach-Object { [string]$_.id })
}

function Format-AdapterAgentIdList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $AgentIds
    )

    return ($AgentIds -join ', ')
}

function Resolve-RegistryAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [string] $AgentId
    )

    if ([string]::IsNullOrWhiteSpace($AgentId)) {
        $registry = Get-AdapterRegistry -RepoRoot $RepoRoot
        $ids = Get-AdapterAvailableAgentIds -Registry $registry
        throw ($script:ToolkitMessage.AgentRequired -f (Format-AdapterAgentIdList -AgentIds $ids))
    }

    $registry = Get-AdapterRegistry -RepoRoot $RepoRoot
    $ids = Get-AdapterAvailableAgentIds -Registry $registry
    $normalized = $AgentId.Trim()
    $entry = @($registry.agents | Where-Object { [string]::Equals([string]$_.id, $normalized, [System.StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1)

    if ($null -eq $entry -or $entry.Count -eq 0) {
        throw ($script:ToolkitMessage.AgentUnknown -f $normalized, (Format-AdapterAgentIdList -AgentIds $ids))
    }

    $agent = $entry[0]
    $moduleRelative = [string]$agent.module
    $adaptersRoot = Join-Path $RepoRoot $script:ToolkitConstant.AdaptersDirectoryName
    $moduleFull = Join-Path $adaptersRoot $moduleRelative
    if (-not (Test-Path -LiteralPath $moduleFull)) {
        throw ($script:ToolkitMessage.AdapterModuleMissing -f $agent.id, $moduleFull)
    }

    $modulePath = (Resolve-Path -LiteralPath $moduleFull).Path
    $adaptersRootResolved = (Resolve-Path -LiteralPath $adaptersRoot).Path
    if (-not (Test-IsPathUnderOrEqual -ChildPath $modulePath -ParentPath $adaptersRootResolved)) {
        throw ($script:ToolkitMessage.AdapterModuleEscapesAdaptersRoot -f $agent.id, $modulePath, $adaptersRootResolved)
    }

    return [PSCustomObject]@{
        AgentId          = [string]$agent.id
        DisplayName      = [string]$agent.displayName
        ModuleRelative   = $moduleRelative
        ModulePath       = $modulePath
        RegistryEntry    = $agent
        AvailableAgentIds = $ids
    }
}

function Assert-AgentParameterPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [AllowEmptyString()]
        [string] $AgentId
    )

    if (-not [string]::IsNullOrWhiteSpace($AgentId)) {
        return
    }

    $registry = Get-AdapterRegistry -RepoRoot $RepoRoot
    $ids = Get-AdapterAvailableAgentIds -Registry $registry
    throw ($script:ToolkitMessage.AgentRequired -f (Format-AdapterAgentIdList -AgentIds $ids))
}
