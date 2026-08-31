#Requires -Version 5.1
<#
.SYNOPSIS
  Hermes Publish-Hooks: plugin-first path/secrets guard + shell agent-hooks dual.

.DESCRIPTION
  1) Copy adapters/hermes/assets/plugins/agent-dev-toolkit-guard -> InstallRoot/plugins/
  2) Best-effort `hermes plugins enable agent-dev-toolkit-guard`; fallback keyed merge
     ONLY plugins.enabled in config.yaml (never gateway/tokens/SOUL.md/memories).
  3) Copy adapters/hermes/assets/agent-hooks (+ GuardCommon.ps1) -> InstallRoot/agent-hooks/
  4) Keyed merge hooks.pre_tool_call (matcher terminal|write_file|patch, fail_closed:true).
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

function Get-HermesAgentHooksAssetsRoot {
    [CmdletBinding()]
    param()
    return (Join-Path (
            Join-Path $script:HermesHooksHelperDirectory $script:HermesAdapterConstant.AssetsDirectoryName
        ) $script:HermesAdapterConstant.AgentHooksDirectoryName)
}

function Copy-HermesDirectoryTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][string] $DestinationRoot
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
        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
        $filesCopied++
    }
    return $filesCopied
}

function Get-HermesShellHookCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $AgentHooksRoot
    )

    $onWindowsHost = $false
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $onWindowsHost = [bool]$IsWindows
    }
    else {
        $onWindowsHost = ($env:OS -match 'Windows')
    }

    if ($onWindowsHost) {
        $ps1 = Join-Path $AgentHooksRoot $script:HermesAdapterConstant.AgentHooksGuardPs1FileName
        return ('pwsh -NoProfile -File "{0}"' -f $ps1)
    }

    $sh = Join-Path $AgentHooksRoot $script:HermesAdapterConstant.AgentHooksGuardShFileName
    return $sh
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
    return [bool]($YamlText -match ("(?m)^\s*-\s*{0}\s*$" -f $escaped))
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

    $text = $YamlText
    if ([string]::IsNullOrWhiteSpace($text)) {
        $text = @"
plugins:
  enabled:
    - $PluginName
"@
        return [PSCustomObject]@{ Text = $text.TrimEnd() + "`n"; Changed = $true }
    }

    if ($text -match '(?m)^plugins:\s*$') {
        if ($text -match '(?m)^  enabled:\s*$') {
            $text = [regex]::Replace(
                $text,
                '(?m)^(  enabled:\s*\r?\n)',
                ('$1    - {0}{1}' -f $PluginName, [Environment]::NewLine),
                1
            )
        }
        else {
            $text = [regex]::Replace(
                $text,
                '(?m)^(plugins:\s*\r?\n)',
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

    # Remove list items whose command references toolkit guard-pre-tool (multi-line YAML maps).
    $pattern = '(?ms)^\s*-\s*matcher:\s*["'']?terminal\|write_file\|patch["'']?\s*\r?\n(?:\s+[^\r\n]*\r?\n)*?\s*command:\s*[^\r\n]*guard-pre-tool[^\r\n]*\r?\n(?:\s+[^\r\n]*\r?\n)*?'
    return [regex]::Replace($YamlText, $pattern, '')
}

function Merge-HermesPreToolCallHook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $YamlText,
        [Parameter(Mandatory = $true)][string] $HookCommand
    )

    $matcher = $script:HermesAdapterConstant.HooksPreToolCallMatcher
    $timeout = [int]$script:HermesAdapterConstant.HooksPreToolCallTimeoutSeconds
    $entry = @"
  pre_tool_call:
    - matcher: "$matcher"
      command: "$HookCommand"
      timeout: $timeout
      fail_closed: true
"@

    $text = Remove-HermesToolkitPreToolCallEntries -YamlText $YamlText
    if ([string]::IsNullOrWhiteSpace($text)) {
        $text = "hooks:`n" + $entry.TrimStart()
        return [PSCustomObject]@{ Text = $text.TrimEnd() + "`n"; Changed = $true }
    }

    if ($text -match '(?m)^hooks:\s*$') {
        # Drop empty pre_tool_call: section remnants then append toolkit entry under hooks.
        if ($text -match '(?m)^  pre_tool_call:\s*$') {
            $text = [regex]::Replace(
                $text,
                '(?m)^  pre_tool_call:\s*\r?\n',
                ('  pre_tool_call:{0}    - matcher: "{1}"{0}      command: "{2}"{0}      timeout: {3}{0}      fail_closed: true{0}' -f [Environment]::NewLine, $matcher, $HookCommand, $timeout),
                1
            )
        }
        else {
            $text = [regex]::Replace(
                $text,
                '(?m)^(hooks:\s*\r?\n)',
                ('$1{0}' -f ($entry.TrimStart() + [Environment]::NewLine)),
                1
            )
        }
    }
    else {
        $text = $text.TrimEnd() + "`n`nhooks:`n" + $entry.TrimStart()
    }

    return [PSCustomObject]@{ Text = $text.TrimEnd() + "`n"; Changed = $true }
}

function Save-HermesConfigYamlKeyedMerge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $ConfigPath,
        [Parameter(Mandatory = $true)][string] $PluginName,
        [Parameter(Mandatory = $true)][string] $HookCommand
    )

    $existing = ''
    if (Test-Path -LiteralPath $ConfigPath) {
        $existing = [System.IO.File]::ReadAllText($ConfigPath)
    }

    $pluginsResult = Merge-HermesPluginsEnabledList -YamlText $existing -PluginName $PluginName
    $hooksResult = Merge-HermesPreToolCallHook -YamlText $pluginsResult.Text -HookCommand $HookCommand

    $parent = Split-Path -Parent $ConfigPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($ConfigPath, $hooksResult.Text, $utf8)

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
            ($script:HermesAdapterMessage.HooksWhatIfOk -f $mapped.FixtureAgentHooksPath)
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
            HooksRoot   = $mapped.FixtureAgentHooksPath
            PluginsRoot = $mapped.FixturePluginsPath
            Message     = $message
            ExitCode    = 0
        }
    }

    $pluginName = $script:HermesAdapterConstant.GuardPluginDirectoryName
    $sourcePluginsRoot = Join-Path (Get-HermesPluginAssetsRoot) $pluginName
    $sourceAgentHooksRoot = Get-HermesAgentHooksAssetsRoot
    $destPluginRoot = Join-Path $mapped.FixturePluginsPath $pluginName
    $destAgentHooksRoot = $mapped.FixtureAgentHooksPath
    $configPath = $mapped.FixtureConfigYamlPath

    if (-not (Test-Path -LiteralPath $sourcePluginsRoot)) {
        throw ($script:HermesAdapterMessage.HooksAssetsMissing -f $sourcePluginsRoot)
    }
    if (-not (Test-Path -LiteralPath $sourceAgentHooksRoot)) {
        throw ($script:HermesAdapterMessage.HooksAssetsMissing -f $sourceAgentHooksRoot)
    }

    $hookCommandPreview = Get-HermesShellHookCommand -AgentHooksRoot $destAgentHooksRoot

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
            HooksRoot        = $destAgentHooksRoot
            ConfigYamlPath   = $configPath
            HookCommand      = $hookCommandPreview
            PluginName       = $pluginName
            Message          = ($script:HermesAdapterMessage.HooksWhatIfPublish -f $destPluginRoot, $destAgentHooksRoot)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $mapped = Get-HermesMappedInstallPaths -ResolvedInstallRoot $resolvedInstallRoot
    $destPluginRoot = Join-Path $mapped.FixturePluginsPath $pluginName
    $destAgentHooksRoot = $mapped.FixtureAgentHooksPath
    $configPath = $mapped.FixtureConfigYamlPath

    $filesCopied = 0
    $filesCopied += Copy-HermesDirectoryTree -SourceRoot $sourcePluginsRoot -DestinationRoot $destPluginRoot
    $filesCopied += Copy-HermesDirectoryTree -SourceRoot $sourceAgentHooksRoot -DestinationRoot $destAgentHooksRoot

    $sharedSource = Join-Path $repoRoot $script:HermesAdapterConstant.SharedGuardCommonRelativePath
    if (Test-Path -LiteralPath $sharedSource) {
        $sharedDest = Join-Path $destAgentHooksRoot $script:HermesAdapterConstant.SharedGuardCommonFileName
        Copy-Item -LiteralPath $sharedSource -Destination $sharedDest -Force
        $filesCopied++
    }

    $enableResult = Invoke-HermesPluginsEnableBestEffort -PluginName $pluginName
    $hookCommand = Get-HermesShellHookCommand -AgentHooksRoot $destAgentHooksRoot
    $yamlMerge = Save-HermesConfigYamlKeyedMerge -ConfigPath $configPath -PluginName $pluginName -HookCommand $hookCommand

    return [PSCustomObject]@{
        Success              = $true
        Implemented          = $true
        Skipped              = $false
        NoOp                 = $false
        CommandName          = 'Publish-Hooks'
        WhatIf               = $false
        InstallRoot          = $resolvedInstallRoot
        PluginsRoot          = $destPluginRoot
        HooksRoot            = $destAgentHooksRoot
        ConfigYamlPath       = $configPath
        HookCommand          = $hookCommand
        PluginName           = $pluginName
        FilesCopied          = $filesCopied
        PluginsEnableStatus  = $enableResult.Status
        PluginsEnableMessage = $enableResult.Message
        ConfigYamlMerged     = $true
        PluginsListChanged   = $yamlMerge.PluginsChanged
        HooksListChanged     = $yamlMerge.HooksChanged
        Message              = ($script:HermesAdapterMessage.HooksPublishedOk -f $filesCopied, $destPluginRoot, $destAgentHooksRoot)
        ExitCode             = 0
    }
}
