#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Hermes Publish-Skills (copy core/skills + resolve placeholders).
#>

$script:HermesAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:HermesAdapterModuleDirectory)) {
    $script:HermesAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_hermesToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:HermesAdapterModuleDirectory)
) 'scripts\_lib'
. (Join-Path $_hermesToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _hermesToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-HermesAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:HermesAdapterModuleDirectory))
}

function Initialize-HermesInstallRootResolver {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Resolve-InstallRoot -ErrorAction SilentlyContinue) {
        return
    }

    $repoRoot = Get-HermesAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:HermesAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:HermesAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
}

function Test-HermesIsWindowsPlatform {
    [CmdletBinding()]
    param()

    if ($PSVersionTable.PSObject.Properties.Name -contains 'Platform') {
        if ($PSVersionTable.Platform -eq 'Win32NT') {
            return $true
        }
        if ($PSVersionTable.Platform -eq 'Unix') {
            return $false
        }
    }

    if ($PSVersionTable.PSObject.Properties.Name -contains 'PSVersion' -and $PSVersionTable.PSVersion.Major -ge 6) {
        return [bool]$IsWindows
    }

    return ($env:OS -like '*Windows*')
}

function Get-HermesEnvironmentVariableValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    $processValue = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if (-not [string]::IsNullOrWhiteSpace($processValue)) {
        return $processValue.Trim()
    }

    $userValue = [Environment]::GetEnvironmentVariable($Name, 'User')
    if (-not [string]::IsNullOrWhiteSpace($userValue)) {
        return $userValue.Trim()
    }

    $machineValue = [Environment]::GetEnvironmentVariable($Name, 'Machine')
    if (-not [string]::IsNullOrWhiteSpace($machineValue)) {
        return $machineValue.Trim()
    }

    return $null
}

function Resolve-HermesOfficialUserRoot {
    [CmdletBinding()]
    param()

    $envName = $script:HermesAdapterConstant.HermesHomeEnvironmentVariableName
    $fromEnv = Get-HermesEnvironmentVariableValue -Name $envName
    if (-not [string]::IsNullOrWhiteSpace($fromEnv)) {
        $expanded = [Environment]::ExpandEnvironmentVariables($fromEnv)
        return [System.IO.Path]::GetFullPath($expanded)
    }

    if (Test-HermesIsWindowsPlatform) {
        $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
        if ([string]::IsNullOrWhiteSpace($localAppData)) {
            $userHome = [Environment]::GetFolderPath('UserProfile')
            $localAppData = Join-Path $userHome 'AppData\Local'
        }

        return [System.IO.Path]::GetFullPath(
            (Join-Path $localAppData $script:HermesAdapterConstant.WindowsHermesDirectoryName)
        )
    }

    $userHome = [Environment]::GetFolderPath('UserProfile')
    if ([string]::IsNullOrWhiteSpace($userHome)) {
        return $null
    }

    return [System.IO.Path]::GetFullPath(
        (Join-Path $userHome $script:HermesAdapterConstant.OfficialUserRootRelativePath)
    )
}

function Get-HermesMemoryFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $memoriesDir = Join-Path $ResolvedInstallRoot $script:HermesAdapterConstant.MemoriesDirectoryName
    return (Join-Path $memoriesDir $script:HermesAdapterConstant.MemoryFileName)
}

function Get-HermesMappedInstallPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $skillsRel = $script:HermesAdapterConstant.OfficialSkillsRelativePath -replace '/', $sep
    $agentHooksRel = $script:HermesAdapterConstant.AgentHooksDirectoryName -replace '/', $sep
    $pluginsRel = $script:HermesAdapterConstant.PluginsDirectoryName -replace '/', $sep
    $gatewayHooksRel = $script:HermesAdapterConstant.GatewayHooksDirectoryName -replace '/', $sep
    $agentsPath = Join-Path $ResolvedInstallRoot $script:HermesAdapterConstant.OfficialAgentsFileName

    return [PSCustomObject]@{
        FixtureUserRootPath      = $ResolvedInstallRoot
        FixtureProjectRootPath   = $ResolvedInstallRoot
        FixtureSkillsPath        = Join-Path $ResolvedInstallRoot $skillsRel
        FixtureRulesPath         = $agentsPath
        FixtureHooksPath         = Join-Path $ResolvedInstallRoot $gatewayHooksRel
        FixtureAgentHooksPath    = Join-Path $ResolvedInstallRoot $agentHooksRel
        FixturePluginsPath       = Join-Path $ResolvedInstallRoot $pluginsRel
        FixtureConfigYamlPath    = Join-Path $ResolvedInstallRoot $script:HermesAdapterConstant.ConfigYamlFileName
        FixtureProjectAgentsPath = $agentsPath
        FixtureMemoryPath        = Get-HermesMemoryFilePath -ResolvedInstallRoot $ResolvedInstallRoot
        FixtureSoulPath          = Join-Path $ResolvedInstallRoot $script:HermesAdapterConstant.SoulFileName
    }
}

function Get-HermesNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:HermesAdapterConstant.PathSeparatorForwardSlash)
}

function Get-HermesSupportedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:HermesAdapterConstant.PlaceholderToolkitRoot,
        $script:HermesAdapterConstant.PlaceholderSddRoot,
        $script:HermesAdapterConstant.PlaceholderGuardrailsPath
    )
}

function Get-HermesPlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-HermesNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-HermesNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:HermesAdapterConstant.SddDirectoryName)
    $guardrailsPath = Get-HermesNormalizedForwardSlashPath -Path (
        Join-Path $InstallRoot $script:HermesAdapterConstant.OfficialAgentsFileName
    )

    return [ordered]@{
        ($script:HermesAdapterConstant.PlaceholderToolkitRoot)    = $toolkitRoot
        ($script:HermesAdapterConstant.PlaceholderSddRoot)        = $sddRoot
        ($script:HermesAdapterConstant.PlaceholderGuardrailsPath) = $guardrailsPath
    }
}

function Initialize-HermesToolkitManagedTreeLib {
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-HermesAdapterRepoRoot) 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1'
        throw ($script:HermesAdapterMessage.ManagedTreeLibMissing -f $libPath)
    }
}

function Copy-HermesCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-HermesToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Resolve-HermesPlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-HermesToolkitManagedTreeLib
    $tokens = @(Get-HermesSupportedPlaceholderTokens)
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:HermesAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens $tokens `
        -UnresolvedMessageFormat $script:HermesAdapterMessage.PlaceholderUnresolved
}

function Assert-HermesPlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Initialize-HermesToolkitManagedTreeLib
    $tokens = @(Get-HermesSupportedPlaceholderTokens)
    $identityMap = [ordered]@{}
    foreach ($token in $tokens) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:HermesAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens $tokens `
        -UnresolvedMessageFormat $script:HermesAdapterMessage.PlaceholderUnresolved
}

function Write-HermesUtf8NoBomFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Test-HermesInstallRootIsOfficialUserHome {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $officialHome = Resolve-HermesOfficialUserRoot
    if ([string]::IsNullOrWhiteSpace($officialHome)) {
        return $false
    }

    $comparison = [System.StringComparison]::OrdinalIgnoreCase
    return [string]::Equals(
        [System.IO.Path]::GetFullPath($ResolvedInstallRoot),
        [System.IO.Path]::GetFullPath($officialHome),
        $comparison
    )
}

function Initialize-HermesMemoryFileIfMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    $memoryPath = Get-HermesMemoryFilePath -ResolvedInstallRoot $ResolvedInstallRoot
    if (Test-Path -LiteralPath $memoryPath) {
        return [PSCustomObject]@{
            Path    = $memoryPath
            Created = $false
        }
    }

    $memoriesDir = Split-Path -Parent $memoryPath
    if (-not (Test-Path -LiteralPath $memoriesDir)) {
        New-Item -ItemType Directory -Path $memoriesDir -Force | Out-Null
    }

    Write-HermesUtf8NoBomFile -Path $memoryPath -Content $script:HermesAdapterConstant.MemorySeedContent
    return [PSCustomObject]@{
        Path    = $memoryPath
        Created = $true
    }
}

function Invoke-HermesProjectSkillsTrust {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot
    )

    if (Test-HermesInstallRootIsOfficialUserHome -ResolvedInstallRoot $ResolvedInstallRoot) {
        return [PSCustomObject]@{
            Attempted = $false
            Skipped   = $true
            Status    = $script:HermesAdapterConstant.SkillsTrustStatusUserHome
            Message   = $script:HermesAdapterMessage.SkillsTrustUserHome
        }
    }

    $cliName = $script:HermesAdapterConstant.HermesCliCommandName
    $cli = Get-Command -Name $cliName -ErrorAction SilentlyContinue
    if ($null -eq $cli) {
        return [PSCustomObject]@{
            Attempted = $false
            Skipped   = $true
            Status    = $script:HermesAdapterConstant.SkillsTrustStatusCliMissing
            Message   = $script:HermesAdapterMessage.SkillsTrustCliMissing
        }
    }

    try {
        $trustArgs = @(
            $script:HermesAdapterConstant.HermesSkillsTrustVerb,
            $script:HermesAdapterConstant.HermesSkillsTrustAction,
            $ResolvedInstallRoot
        )
        $null = & $cliName @trustArgs 2>&1
        return [PSCustomObject]@{
            Attempted = $true
            Skipped   = $false
            Status    = $script:HermesAdapterConstant.SkillsTrustStatusAttempted
            Message   = ($script:HermesAdapterMessage.SkillsTrustAttempted -f $ResolvedInstallRoot)
        }
    }
    catch {
        return [PSCustomObject]@{
            Attempted = $false
            Skipped   = $true
            Status    = $script:HermesAdapterConstant.SkillsTrustStatusError
            Message   = ($script:HermesAdapterMessage.SkillsTrustError -f $ResolvedInstallRoot, $_.Exception.Message)
        }
    }
}

function Invoke-HermesPublishSkills {
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
        throw $script:HermesAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-HermesAdapterRepoRoot
    $resolveScript = Join-Path $repoRoot ($script:HermesAdapterConstant.ResolveInstallRootRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        throw ($script:HermesAdapterMessage.ResolveInstallRootMissing -f $resolveScript)
    }

    . $resolveScript
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:HermesAdapterConstant.CoreDirectoryName) $script:HermesAdapterConstant.SkillsDirectoryName
    $destinationSkillsRoot = $mapped.FixtureSkillsPath

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:HermesAdapterMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success           = $true
            Implemented       = $true
            CommandName       = 'Publish-Skills'
            WhatIf            = $true
            InstallRoot       = $resolvedInstallRoot
            SkillsRoot        = $destinationSkillsRoot
            SourceRoot        = $sourceSkillsRoot
            FilesCopied       = 0
            SkillsTrustStatus = $null
            Message           = ($script:HermesAdapterMessage.WhatIfOk -f $destinationSkillsRoot)
            ExitCode          = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destinationSkillsRoot = $mapped.FixtureSkillsPath

    Initialize-HermesToolkitManagedTreeLib
    $placeholderMap = Get-HermesPlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:HermesAdapterConstant.TextFileExtensionPattern `
        -UnresolvedTokens @(Get-HermesSupportedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:HermesAdapterMessage.PlaceholderUnresolved

    $null = Initialize-HermesMemoryFileIfMissing -ResolvedInstallRoot $resolvedInstallRoot
    $trustResult = Invoke-HermesProjectSkillsTrust -ResolvedInstallRoot $resolvedInstallRoot

    return [PSCustomObject]@{
        Success           = $true
        Implemented       = $true
        CommandName       = 'Publish-Skills'
        WhatIf            = $false
        InstallRoot       = $resolvedInstallRoot
        SkillsRoot        = $destinationSkillsRoot
        SourceRoot        = $sourceSkillsRoot
        FilesCopied       = $publishResult.FilesCopied
        SkillsTrustStatus = $trustResult.Status
        SkillsTrustNote   = $script:HermesAdapterConstant.SkillsTrustNote
        Message           = ('{0} {1}' -f ($script:HermesAdapterMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot), $trustResult.Message)
        ExitCode          = 0
    }
}
