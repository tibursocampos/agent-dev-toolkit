#Requires -Version 5.1
$script:ToolkitCopyHelperRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')
. (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'adapters') '_shared\PublishAuthorizationContract.ps1')

<#
.SYNOPSIS
  Hermes Publish-Hooks: compatibility plugin/assets with host-owned authorization.

.DESCRIPTION
  1) Copy adapters/hermes/assets/plugins/agent-dev-toolkit-guard -> InstallRoot/plugins/
  2) Best-effort `hermes plugins enable agent-dev-toolkit-guard`; fallback keyed merge
     ONLY plugins.enabled in config.yaml (never gateway/tokens/SOUL.md/memories).
  3) Ship no agent-hooks; legacy agent-hooks guard files are removed by uninstall only.
  4) Remove only legacy Toolkit hooks.pre_tool_call entries; do not register a guard.
  The config.yaml structure is checked before any write; unsupported layouts fail closed.
#>

$script:HermesHooksHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:HermesHooksHelperDirectory)) {
    $script:HermesHooksHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Test-HermesHooksCapable {
    [CmdletBinding()]
    param()

    if ($null -eq $script:HermesAdapterCapabilityFlags) {
        return $true
    }
    if (-not $script:HermesAdapterCapabilityFlags.Contains('hooks')) {
        return $true
    }
    return [bool]$script:HermesAdapterCapabilityFlags['hooks']
}

function Get-HermesPluginAssetsRoot {
    [CmdletBinding()]
    param()
    return (Join-Path (
            Join-Path $script:HermesHooksHelperDirectory $script:HermesAdapterConstant.AssetsDirectoryName
        ) $script:HermesAdapterConstant.PluginsDirectoryName)
}

function Copy-HermesDirectoryTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][string] $DestinationRoot,

        [Parameter()][string] $InstallRoot
    )

    if (-not (Test-Path -LiteralPath $DestinationRoot)) {
        New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
    }

    $filesCopied = 0
    foreach ($file in @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -ErrorAction Stop)) {
        $relative = $file.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
        $destinationPath = Join-Path $DestinationRoot $relative
        $destinationDir = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        $copyArgs = @{
            SourcePath      = $file.FullName
            DestinationPath = $destinationPath
        }
        if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
            $copyArgs.InstallRoot = $InstallRoot
            $copyArgs.RelativePath = $destinationPath.Substring(([System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar).Length) -replace '\\', '/'
        }
        $null = Copy-ToolkitFileIfAbsent @copyArgs
        if ($file.Extension -eq '.sh' -and -not (Test-HermesIsWindowsPlatform)) {
            try {
                if (Get-Command -Name chmod -ErrorAction SilentlyContinue) {
                    & chmod +x -- $destinationPath 2>$null
                }
            }
            catch {
                # Best-effort executable bit; host may still invoke via sh/bash.
            }
        }
        $filesCopied++
    }
    return $filesCopied
}

function ConvertTo-HermesYamlSingleQuotedScalar {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Value
    )

    return ("'{0}'" -f $Value.Replace("'", "''"))
}

function Test-HermesPluginsEnabledContains {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $YamlText,
        [Parameter(Mandatory = $true)][string] $PluginName
    )

    if ([string]::IsNullOrWhiteSpace($YamlText)) {
        return $false
    }

    $escaped = [regex]::Escape($PluginName)
    return [bool]($YamlText -match ("(?m)^[ \t]*-[ \t]*{0}[ \t]*(#[^\r\n]*)?(?=\r?$)" -f $escaped))
}

function Merge-HermesPluginsEnabledList {
    <#
    .SYNOPSIS
      Keyed upsert of plugins.enabled list entry only. Leaves all other YAML untouched.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $YamlText,
        [Parameter(Mandatory = $true)][string] $PluginName
    )

    if (Test-HermesPluginsEnabledContains -YamlText $YamlText -PluginName $PluginName) {
        return [PSCustomObject]@{ Text = $YamlText; Changed = $false }
    }

    $text = [regex]::Replace($YamlText, '(?m)^plugins:[ \t]*\{[ \t]*\}(?<comment>[ \t]*#[^\r\n]*)?(?=[ \t]*\r?$)', 'plugins:${comment}')
    if ([string]::IsNullOrWhiteSpace($text)) {
        $text = @"
plugins:
  enabled:
    - $PluginName
"@
        return [PSCustomObject]@{ Text = $text.TrimEnd() + "`n"; Changed = $true }
    }

    if ($text -match '(?m)^plugins:[ \t]*(#[^\r\n]*)?(?=\r?$)') {
        if ($text -match '(?m)^  enabled:[ \t]*(#[^\r\n]*)?(?=\r?$)') {
            $text = [regex]::Replace(
                $text,
                '(?m)^(  enabled:[ \t]*(?:#[^\r\n]*)?\r?\n)',
                ('$1    - {0}{1}' -f $PluginName, [Environment]::NewLine),
                1
            )
        }
        else {
            $text = [regex]::Replace(
                $text,
                '(?m)^(plugins:[ \t]*(?:#[^\r\n]*)?\r?\n)',
                ('$1  enabled:{0}    - {1}{0}' -f [Environment]::NewLine, $PluginName),
                1
            )
        }
    }
    else {
        $block = @"

plugins:
  enabled:
    - $PluginName
"@
        $text = $text.TrimEnd() + $block
    }

    return [PSCustomObject]@{ Text = $text.TrimEnd() + "`n"; Changed = $true }
}

function Remove-HermesToolkitPreToolCallEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $YamlText
    )

    if ([string]::IsNullOrWhiteSpace($YamlText)) {
        return $YamlText
    }

    # Remove the whole toolkit list item, including keys after command. Stop before the next list item.
    $pattern = '(?ms)^\s*-\s*matcher:\s*["'']?(?:terminal\|write_file\|patch|\.\*)["'']?\s*\r?\n(?:[ \t]+(?!-[ \t])[^\r\n]*\r?\n)*?\s*command:\s*[^\r\n]*guard-pre-tool[^\r\n]*\r?\n(?:[ \t]+(?!-[ \t])[^\r\n]*\r?\n)*'
    return [regex]::Replace($YamlText, $pattern, '')
}

function Test-HermesConfigYamlStructure {
    <#
    .SYNOPSIS
      Structural pre-check of config.yaml before any Hermes write. Not a YAML parser.
      Accepts only the layouts the plugins.enabled merge can edit; anything else fails closed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $YamlText
    )

    $valid = [PSCustomObject]@{ Valid = $true; Reason = '' }
    if ([string]::IsNullOrWhiteSpace($YamlText)) {
        return $valid
    }

    $lines = @($YamlText -split '\r?\n')
    $pluginsIndexes = New-Object System.Collections.Generic.List[int]
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $lineNumber = $index + 1
        if ($line -match '^\t') {
            return [PSCustomObject]@{ Valid = $false; Reason = ('tab indentation at line {0}' -f $lineNumber) }
        }
        if ($line -match '^\s*(#.*)?$' -or $line -match '^(---|\.\.\.)\s*$') {
            continue
        }
        if ($line -match '^\S') {
            if ($line -notmatch '^[A-Za-z_][A-Za-z0-9_.-]*[ \t]*:([ \t]|$)') {
                return [PSCustomObject]@{ Valid = $false; Reason = ('unexpected top-level line {0}' -f $lineNumber) }
            }
            if ($line -match '^plugins[ \t]*:') {
                [void]$pluginsIndexes.Add($index)
            }
        }
    }

    if ($pluginsIndexes.Count -eq 0) {
        return $valid
    }
    if ($pluginsIndexes.Count -gt 1) {
        return [PSCustomObject]@{ Valid = $false; Reason = ('duplicate top-level key plugins at line {0}' -f ($pluginsIndexes[1] + 1)) }
    }

    $start = $pluginsIndexes[0]
    if ($lines[$start] -notmatch '^plugins[ \t]*:[ \t]*(\{[ \t]*\})?[ \t]*(#.*)?$') {
        return [PSCustomObject]@{ Valid = $false; Reason = ('plugins has an inline value other than {{}} at line {0}' -f ($start + 1)) }
    }

    $enabledCount = 0
    for ($index = $start + 1; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        if ($line -match '^\s*(#.*)?$') {
            continue
        }
        if ($line -match '^\S') {
            break
        }
        if ($line -match '^  enabled[ \t]*:[ \t]*(#.*)?$') {
            $enabledCount++
            if ($enabledCount -gt 1) {
                return [PSCustomObject]@{ Valid = $false; Reason = ('duplicate plugins.enabled at line {0}' -f ($index + 1)) }
            }
            continue
        }
        if ($enabledCount -gt 0 -and $line -match '^    -[ \t]+\S') {
            continue
        }
        return [PSCustomObject]@{ Valid = $false; Reason = ('unsupported plugins layout at line {0} (expected a 2-space enabled key with 4-space list items)' -f ($index + 1)) }
    }

    return $valid
}

function Save-HermesConfigYamlKeyedMerge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $ConfigPath,
        [Parameter(Mandatory = $true)][string] $PluginName
    )

    $existing = ''
    if (Test-Path -LiteralPath $ConfigPath) {
        $existing = [System.IO.File]::ReadAllText($ConfigPath)
    }

    $pluginsResult = Merge-HermesPluginsEnabledList -YamlText $existing -PluginName $PluginName
    $cleanedConfig = Remove-HermesToolkitPreToolCallEntries -YamlText $pluginsResult.Text
    $hooksResult = [PSCustomObject]@{ Text = $cleanedConfig; Changed = ($cleanedConfig -ne $pluginsResult.Text) }

    $parent = Split-Path -Parent $ConfigPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    $null = Write-ToolkitFileIfAbsent -Path $ConfigPath -Content $hooksResult.Text -Encoding $utf8
    return [PSCustomObject]@{
        ConfigPath      = $ConfigPath
        PluginsChanged  = [bool]$pluginsResult.Changed
        HooksChanged    = [bool]$hooksResult.Changed
    }
}

function Invoke-HermesPluginsEnableBestEffort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $PluginName
    )

    $cli = Get-Command -Name $script:HermesAdapterConstant.HermesCliCommandName -ErrorAction SilentlyContinue
    if ($null -eq $cli) {
        return [PSCustomObject]@{
            Status  = $script:HermesAdapterConstant.PluginsEnableStatusCliMissing
            Message = $script:HermesAdapterMessage.PluginsEnableCliMissing
        }
    }

    try {
        $args = @(
            $script:HermesAdapterConstant.HermesPluginsVerb,
            $script:HermesAdapterConstant.HermesPluginsEnableAction,
            $PluginName
        )
        & $cli.Source @args 2>&1 | Out-Null
        return [PSCustomObject]@{
            Status  = $script:HermesAdapterConstant.PluginsEnableStatusAttempted
            Message = ($script:HermesAdapterMessage.PluginsEnableAttempted -f $PluginName)
        }
    }
    catch {
        return [PSCustomObject]@{
            Status  = $script:HermesAdapterConstant.PluginsEnableStatusError
            Message = ($script:HermesAdapterMessage.PluginsEnableError -f $PluginName, $_.Exception.Message)
        }
    }
}

function Invoke-HermesPublishHooks {
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
    Initialize-HermesInstallRootResolver
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot

    if (-not (Test-HermesHooksCapable)) {
        $message = if ($WhatIf.IsPresent) {
            ($script:HermesAdapterMessage.HooksWhatIfOk -f $mapped.FixturePluginsPath)
        }
        else {
            ($script:HermesAdapterMessage.HooksNoOp -f $resolvedInstallRoot)
        }

        return [PSCustomObject]@{
            Success     = $true
            Implemented = $true
            Skipped     = $true
            NoOp        = $true
            CommandName = 'Publish-Hooks'
            WhatIf      = [bool]$WhatIf.IsPresent
            InstallRoot = $resolvedInstallRoot
            PluginsRoot = $mapped.FixturePluginsPath
            Message     = $message
            HookActivation = New-HookActivation -State 'unavailable' -Note $script:HermesAdapterMessage.HooksUnavailableNote
            ExitCode    = 0
        }
    }

    $pluginName = $script:HermesAdapterConstant.GuardPluginDirectoryName
    $sourcePluginsRoot = Join-Path (Get-HermesPluginAssetsRoot) $pluginName
    $destPluginRoot = Join-Path $mapped.FixturePluginsPath $pluginName
    $configPath = $mapped.FixtureConfigYamlPath

    if (-not (Test-Path -LiteralPath $sourcePluginsRoot)) {
        throw ($script:HermesAdapterMessage.HooksAssetsMissing -f $sourcePluginsRoot)
    }

    $configCheckText = ''
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $configCheckText = [System.IO.File]::ReadAllText($configPath)
    }
    $configCheck = Test-HermesConfigYamlStructure -YamlText $configCheckText
    if (-not $configCheck.Valid) {
        return [PSCustomObject]@{
            Success        = $false
            Implemented    = $true
            Skipped        = $false
            NoOp           = $false
            CommandName    = 'Publish-Hooks'
            WhatIf         = [bool]$WhatIf.IsPresent
            InstallRoot    = $resolvedInstallRoot
            PluginsRoot    = $mapped.FixturePluginsPath
            ConfigYamlPath = $configPath
            FilesCopied    = 0
            Message        = ($script:HermesAdapterMessage.HooksConfigBlocked -f $configPath, $configCheck.Reason)
            HookActivation = New-HookActivation -State 'blocked' -Steps @($script:HermesAdapterMessage.HooksConfigBlockedStep) -Note $script:HermesAdapterMessage.HooksConfigBlockedNote
            ExitCode       = 1
        }
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            Skipped          = $false
            NoOp             = $false
            CommandName      = 'Publish-Hooks'
            WhatIf           = $true
            InstallRoot      = $resolvedInstallRoot
            PluginsRoot      = $destPluginRoot
            ConfigYamlPath   = $configPath
            PluginName       = $pluginName
            Message          = ($script:HermesAdapterMessage.HooksWhatIfPublish -f $destPluginRoot)
            HookActivation   = New-HookActivation -State 'unavailable' -Note $script:HermesAdapterMessage.HooksUnavailableNote
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destPluginRoot = Join-Path $mapped.FixturePluginsPath $pluginName
    $configPath = $mapped.FixtureConfigYamlPath

    $filesCopied = Copy-HermesDirectoryTree -SourceRoot $sourcePluginsRoot -DestinationRoot $destPluginRoot -InstallRoot $resolvedInstallRoot

    $enableResult = Invoke-HermesPluginsEnableBestEffort -PluginName $pluginName
    $yamlMerge = Save-HermesConfigYamlKeyedMerge -ConfigPath $configPath -PluginName $pluginName

    return [PSCustomObject]@{
        Success              = $true
        Implemented          = $true
        Skipped              = $false
        NoOp                 = $false
        CommandName          = 'Publish-Hooks'
        WhatIf               = $false
        InstallRoot          = $resolvedInstallRoot
        PluginsRoot          = $destPluginRoot
        ConfigYamlPath       = $configPath
        PluginName           = $pluginName
        FilesCopied          = $filesCopied
        PluginsEnableStatus  = $enableResult.Status
        PluginsEnableMessage = $enableResult.Message
        ConfigYamlMerged     = $true
        PluginsListChanged   = $yamlMerge.PluginsChanged
        HooksListChanged     = $yamlMerge.HooksChanged
        Message              = ($script:HermesAdapterMessage.HooksPublishedOk -f $filesCopied, $destPluginRoot)
        HookActivation       = New-HookActivation -State 'unavailable' -Note $script:HermesAdapterMessage.HooksUnavailableNote
        ExitCode             = 0
    }
}
