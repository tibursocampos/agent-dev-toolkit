#Requires -Version 5.1
<#
.SYNOPSIS
  Safe merge for Claude Code settings.json (hooks keyed + permissions.allow additive).

.DESCRIPTION
  RN03-RN05/RN08: backup before write; keyed hooks upsert; additive allow; preserve
  unrelated keys; UTF-8 without BOM; abort on invalid JSON, non-object hooks/permissions, or backup failure.
#>

$script:ClaudeSettingsHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeSettingsHelperDirectory)) {
    $script:ClaudeSettingsHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function ConvertTo-ClaudeSettingsHashtable {
    [CmdletBinding()]
    param(
        [Parameter()]
        $InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [string] -or $InputObject -is [ValueType]) {
        return $InputObject
    }

    if ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.Specialized.OrderedDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $result[$key] = ConvertTo-ClaudeSettingsHashtable -InputObject $InputObject[$key]
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IEnumerable]) {
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $InputObject) {
            $list.Add((ConvertTo-ClaudeSettingsHashtable -InputObject $item))
        }
        return , @($list.ToArray())
    }

    if ($InputObject -is [PSCustomObject]) {
        $result = [ordered]@{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $result[$property.Name] = ConvertTo-ClaudeSettingsHashtable -InputObject $property.Value
        }
        return $result
    }

    return $InputObject
}

function Get-ClaudeSettingsFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    return (Join-Path $InstallRoot $script:ClaudePathConstant.SettingsFileName)
}

function Get-ClaudeSettingsBackupPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SettingsPath
    )

    return ($SettingsPath + $script:ClaudePathConstant.SettingsBackupSuffix)
}

function Get-ClaudeSettingsTimestampedBackupPath {
    <#
    .SYNOPSIS
      Timestamped audit-trail backup path: settings.json.bak.<yyyyMMddHHmmss>.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SettingsPath
    )

    $timestamp = (Get-Date).ToString($script:ClaudePathConstant.SettingsBackupTimestampFormat)
    return ($script:ClaudePathConstant.SettingsTimestampedBackupPathFormat -f $SettingsPath, $script:ClaudePathConstant.SettingsBackupSuffix, $timestamp)
}

function New-ClaudeManagedHookHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command
    )

    $handler = [ordered]@{}
    $handler[$script:ClaudeSettingsJsonConstant.HookHandlerTypePropertyName] = $script:ClaudeSettingsJsonConstant.HookCommandTypeValue
    $handler[$script:ClaudeSettingsJsonConstant.HookHandlerCommandPropertyName] = $Command
    return $handler
}

function New-ClaudeManagedHookEventEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command,

        [Parameter()]
        [string] $Matcher
    )

    $handlersProperty = $script:ClaudeSettingsJsonConstant.HookHandlersPropertyName
    $entry = [ordered]@{}
    if (-not [string]::IsNullOrWhiteSpace($Matcher)) {
        $entry[$script:ClaudeSettingsJsonConstant.HookMatcherPropertyName] = $Matcher
    }
    $entry[$handlersProperty] = @(
        (New-ClaudeManagedHookHandler -Command $Command)
    )
    return , @($entry)
}

function Get-ClaudeManagedHookCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $ScriptFileName
    )

    $scriptPath = Join-Path (
        Join-Path $InstallRoot $script:ClaudePathConstant.HooksDirectoryName
    ) $ScriptFileName
    $normalized = Get-ClaudeNormalizedForwardSlashPath -Path $scriptPath
    return ($script:ClaudeSettingsJsonConstant.HookCommandTemplate -f $normalized)
}

function Get-ClaudeManagedHooksObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $c = $script:ClaudeSettingsJsonConstant
    $hooks = [ordered]@{}

    $hooks[$c.HookEventUserPromptSubmit] = New-ClaudeManagedHookEventEntries -Command (
        Get-ClaudeManagedHookCommand -InstallRoot $InstallRoot -ScriptFileName $c.HookScriptUserPromptSubmit
    )

    $hooks[$c.HookEventPreCompact] = New-ClaudeManagedHookEventEntries -Command (
        Get-ClaudeManagedHookCommand -InstallRoot $InstallRoot -ScriptFileName $c.HookScriptPreCompact
    )

    $hooks[$c.HookEventPostToolUse] = New-ClaudeManagedHookEventEntries -Command (
        Get-ClaudeManagedHookCommand -InstallRoot $InstallRoot -ScriptFileName $c.HookScriptPostToolUse
    ) -Matcher $c.HookMatcherPostToolUse

    return $hooks
}

function Get-ClaudeManagedHookScriptFileNameMap {
    <#
    .SYNOPSIS
      Map managed hook event name -> the toolkit script filename that owns it.
      Used as the command/path identity for keyed hook merges.
    #>
    [CmdletBinding()]
    param()

    $c = $script:ClaudeSettingsJsonConstant
    return [ordered]@{
        $c.HookEventUserPromptSubmit = $c.HookScriptUserPromptSubmit
        $c.HookEventPreCompact       = $c.HookScriptPreCompact
        $c.HookEventPostToolUse      = $c.HookScriptPostToolUse
    }
}

function Test-ClaudeManagedHookHandlerCommand {
    <#
    .SYNOPSIS
      Identity check: does a handler command belong to this toolkit's managed
      script for the current event (regardless of InstallRoot prefix)?

    .DESCRIPTION
      Prefers the publish command template
      `pwsh -NoProfile -File ".../hooks/<ManagedScriptFileName>"` (forward or
      backslash separators). Falls back to a hooks/<file> path segment match
      so older InstallRoot prefixes still identify as managed.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [string] $Command,

        [Parameter(Mandatory = $true)]
        [string] $ManagedScriptFileName
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $false
    }

    $hooksSeg = [regex]::Escape($script:ClaudePathConstant.HooksDirectoryName)
    $fileEsc = [regex]::Escape($ManagedScriptFileName)
    $hooksFileSegment = ('[\\/]{0}[\\/]{1}' -f $hooksSeg, $fileEsc)

    # Prefer exact publish template: pwsh -NoProfile -File ".../hooks/<file>"
    $templatePattern = ('pwsh\s+-NoProfile\s+-File\s+"[^"]*{0}"' -f $hooksFileSegment)
    if ($Command -match $templatePattern) {
        return $true
    }

    # Fallback: command references hooks/<managed-file> (any host wrapper).
    return ($Command -match $hooksFileSegment)
}

function Get-ClaudeManagedPermissionsAllowEntries {
    <#
    .SYNOPSIS
      Narrow permissions.allow entries for managed hook scripts at InstallRoot.

    .DESCRIPTION
      One Bash(...) entry per managed hook command template (no Bash(pwsh *)
      wildcards). Optional -AllowBroadShellPermissions re-adds legacy broad
      patterns for operators who explicitly opt in.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowBroadShellPermissions
    )

    $c = $script:ClaudeSettingsJsonConstant
    $format = $c.PermissionsAllowBashFormat
    $entries = New-Object System.Collections.Generic.List[string]

    foreach ($scriptFileName in @(
            $c.HookScriptUserPromptSubmit,
            $c.HookScriptPreCompact,
            $c.HookScriptPostToolUse
        )) {
        $command = Get-ClaudeManagedHookCommand -InstallRoot $InstallRoot -ScriptFileName $scriptFileName
        $entries.Add(($format -f $command)) | Out-Null
    }

    if ($AllowBroadShellPermissions.IsPresent) {
        foreach ($legacy in @($script:ClaudeLegacyBroadPermissionsAllow)) {
            if (-not $entries.Contains($legacy)) {
                $entries.Add($legacy) | Out-Null
            }
        }
    }

    # Enumerate to pipeline; callers must wrap with @(...).
    return [string[]]$entries.ToArray()
}

function Get-ClaudePermissionsAllowEntriesForRemoval {
    <#
    .SYNOPSIS
      Allow entries uninstall/re-sync should strip (narrow for InstallRoot + legacy broad).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $combined = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $InstallRoot)) {
        $combined.Add($entry) | Out-Null
    }
    foreach ($legacy in @($script:ClaudeLegacyBroadPermissionsAllow)) {
        if (-not $combined.Contains($legacy)) {
            $combined.Add($legacy) | Out-Null
        }
    }
    return [string[]]$combined.ToArray()
}

function Remove-ClaudePermissionsAllowEntriesByEquality {
    <#
    .SYNOPSIS
      Drop permissions.allow entries that exactly match EntriesToRemove; preserve others.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Settings,

        [Parameter(Mandatory = $true)]
        [string[]] $EntriesToRemove
    )

    $permissionsKey = $script:ClaudeSettingsJsonConstant.PermissionsPropertyName
    $allowKey = $script:ClaudeSettingsJsonConstant.AllowPropertyName

    if (-not $Settings.Contains($permissionsKey) -or -not ($Settings[$permissionsKey] -is [System.Collections.IDictionary])) {
        return $false
    }

    $permissions = ConvertTo-ClaudeSettingsHashtable -InputObject $Settings[$permissionsKey]
    if (-not $permissions.Contains($allowKey) -or $null -eq $permissions[$allowKey]) {
        $Settings[$permissionsKey] = $permissions
        return $false
    }

    $changed = $false
    $remaining = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @($permissions[$allowKey])) {
        if ($null -eq $entry) { continue }
        $entryText = [string]$entry
        $isTarget = $false
        foreach ($toRemove in $EntriesToRemove) {
            if ([string]::Equals($entryText, $toRemove, [System.StringComparison]::Ordinal)) {
                $isTarget = $true
                break
            }
        }
        if ($isTarget) {
            $changed = $true
        }
        else {
            $remaining.Add($entryText) | Out-Null
        }
    }

    $permissions[$allowKey] = @($remaining.ToArray())
    $Settings[$permissionsKey] = $permissions
    return $changed
}

function Merge-ClaudeHookEventEntries {
    <#
    .SYNOPSIS
      Command-keyed merge for a single hook event's matcher-group entries.

    .DESCRIPTION
      Drops only the handlers this toolkit recognizes as its own (by script
      filename identity) so re-sync does not accumulate duplicates, keeps
      every other (alien) handler untouched, then prepends the freshly
      generated managed entries.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $ExistingEntries,

        [Parameter(Mandatory = $true)]
        [array] $ManagedEntries,

        [Parameter(Mandatory = $true)]
        [string] $ManagedScriptFileName
    )

    $handlersKey = $script:ClaudeSettingsJsonConstant.HookHandlersPropertyName
    $commandKey = $script:ClaudeSettingsJsonConstant.HookHandlerCommandPropertyName

    $preservedEntries = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in @($ExistingEntries)) {
        if ($null -eq $entry -or -not ($entry -is [System.Collections.IDictionary])) {
            continue
        }

        $handlers = @()
        if ($entry.Contains($handlersKey) -and $null -ne $entry[$handlersKey]) {
            $handlers = @($entry[$handlersKey])
        }

        $keptHandlers = [System.Collections.Generic.List[object]]::new()
        foreach ($handler in $handlers) {
            $command = $null
            if ($handler -is [System.Collections.IDictionary] -and $handler.Contains($commandKey)) {
                $command = [string]$handler[$commandKey]
            }
            if (Test-ClaudeManagedHookHandlerCommand -Command $command -ManagedScriptFileName $ManagedScriptFileName) {
                continue
            }
            $keptHandlers.Add($handler) | Out-Null
        }

        if ($keptHandlers.Count -eq 0) {
            continue
        }

        $preservedEntry = [ordered]@{}
        foreach ($key in $entry.Keys) {
            if ($key -eq $handlersKey) {
                continue
            }
            $preservedEntry[$key] = $entry[$key]
        }
        $preservedEntry[$handlersKey] = @($keptHandlers.ToArray())
        $preservedEntries.Add($preservedEntry) | Out-Null
    }

    $merged = [System.Collections.Generic.List[object]]::new()
    foreach ($managedEntry in $ManagedEntries) {
        $merged.Add($managedEntry) | Out-Null
    }
    foreach ($preservedEntry in $preservedEntries) {
        $merged.Add($preservedEntry) | Out-Null
    }

    return , @($merged.ToArray())
}

function Merge-ClaudeHooksKeyed {
    <#
    .SYNOPSIS
      Command/path-keyed hooks merge (Cursor-style upsert): for each managed
      event, replace only the toolkit's own handlers and preserve every
      alien handler co-located on the same event.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Settings,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $ManagedHooks
    )

    $hooksKey = $script:ClaudeSettingsJsonConstant.HooksPropertyName
    if (-not $Settings.Contains($hooksKey) -or $null -eq $Settings[$hooksKey]) {
        $Settings[$hooksKey] = [ordered]@{}
    }
    elseif (-not ($Settings[$hooksKey] -is [System.Collections.IDictionary])) {
        # Fail closed (S-I9): never replace alien non-object hooks with {}.
        throw $script:ClaudePublishMessage.SettingsHooksNotObject
    }
    else {
        $Settings[$hooksKey] = ConvertTo-ClaudeSettingsHashtable -InputObject $Settings[$hooksKey]
    }

    $hooks = $Settings[$hooksKey]
    $scriptFileNameByEvent = Get-ClaudeManagedHookScriptFileNameMap

    foreach ($eventName in $ManagedHooks.Keys) {
        $existingEntries = @()
        if ($hooks.Contains($eventName) -and $null -ne $hooks[$eventName]) {
            $existingEntries = @($hooks[$eventName])
        }

        $hooks[$eventName] = Merge-ClaudeHookEventEntries -ExistingEntries $existingEntries -ManagedEntries @($ManagedHooks[$eventName]) -ManagedScriptFileName $scriptFileNameByEvent[$eventName]
    }
}

function Remove-ClaudeManagedHookHandlersFromEvent {
    <#
    .SYNOPSIS
      Reverse-merge for one event: drop toolkit-managed handlers; keep aliens.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $ExistingEntries,

        [Parameter(Mandatory = $true)]
        [string] $ManagedScriptFileName
    )

    $handlersKey = $script:ClaudeSettingsJsonConstant.HookHandlersPropertyName
    $commandKey = $script:ClaudeSettingsJsonConstant.HookHandlerCommandPropertyName

    $preservedEntries = [System.Collections.Generic.List[object]]::new()
    $removedAny = $false

    foreach ($entry in @($ExistingEntries)) {
        if ($null -eq $entry -or -not ($entry -is [System.Collections.IDictionary])) {
            continue
        }

        $handlers = @()
        if ($entry.Contains($handlersKey) -and $null -ne $entry[$handlersKey]) {
            $handlers = @($entry[$handlersKey])
        }

        $keptHandlers = [System.Collections.Generic.List[object]]::new()
        foreach ($handler in $handlers) {
            $command = $null
            if ($handler -is [System.Collections.IDictionary] -and $handler.Contains($commandKey)) {
                $command = [string]$handler[$commandKey]
            }
            if (Test-ClaudeManagedHookHandlerCommand -Command $command -ManagedScriptFileName $ManagedScriptFileName) {
                $removedAny = $true
                continue
            }
            $keptHandlers.Add($handler) | Out-Null
        }

        if ($keptHandlers.Count -eq 0) {
            if ($handlers.Count -gt 0) {
                $removedAny = $true
            }
            continue
        }

        $preservedEntry = [ordered]@{}
        foreach ($key in $entry.Keys) {
            if ($key -eq $handlersKey) {
                continue
            }
            $preservedEntry[$key] = $entry[$key]
        }
        $preservedEntry[$handlersKey] = @($keptHandlers.ToArray())
        $preservedEntries.Add($preservedEntry) | Out-Null
    }

    return [PSCustomObject]@{
        RemainingEntries = @($preservedEntries.ToArray())
        RemovedAny       = $removedAny
    }
}

function Remove-ClaudeManagedHooksKeyed {
    <#
    .SYNOPSIS
      Reverse-merge hooks: remove only toolkit-managed handlers by identity.
      Empty events are dropped; alien co-located handlers keep the event key.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Settings
    )

    $hooksKey = $script:ClaudeSettingsJsonConstant.HooksPropertyName
    if (-not $Settings.Contains($hooksKey) -or -not ($Settings[$hooksKey] -is [System.Collections.IDictionary])) {
        return $false
    }

    $hooks = ConvertTo-ClaudeSettingsHashtable -InputObject $Settings[$hooksKey]
    $scriptFileNameByEvent = Get-ClaudeManagedHookScriptFileNameMap
    $changed = $false

    foreach ($eventName in @($scriptFileNameByEvent.Keys)) {
        if (-not $hooks.Contains($eventName)) {
            continue
        }

        $existingEntries = @()
        if ($null -ne $hooks[$eventName]) {
            $existingEntries = @($hooks[$eventName])
        }

        $result = Remove-ClaudeManagedHookHandlersFromEvent -ExistingEntries $existingEntries -ManagedScriptFileName $scriptFileNameByEvent[$eventName]
        $remaining = @($result.RemainingEntries)

        if ($remaining.Count -eq 0) {
            if ($existingEntries.Count -gt 0 -or $result.RemovedAny) {
                $hooks.Remove($eventName)
                $changed = $true
            }
        }
        elseif ($result.RemovedAny) {
            $hooks[$eventName] = $remaining
            $changed = $true
        }
    }

    $Settings[$hooksKey] = $hooks
    return $changed
}

function Merge-ClaudePermissionsAllowAdditive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Settings,

        [Parameter(Mandatory = $true)]
        [string[]] $ManagedAllowEntries
    )

    $permissionsKey = $script:ClaudeSettingsJsonConstant.PermissionsPropertyName
    $allowKey = $script:ClaudeSettingsJsonConstant.AllowPropertyName

    if (-not $Settings.Contains($permissionsKey) -or $null -eq $Settings[$permissionsKey]) {
        $Settings[$permissionsKey] = [ordered]@{}
    }
    elseif (-not ($Settings[$permissionsKey] -is [System.Collections.IDictionary])) {
        # Fail closed: never replace alien non-object permissions with {}.
        throw $script:ClaudePublishMessage.SettingsPermissionsNotObject
    }
    else {
        $Settings[$permissionsKey] = ConvertTo-ClaudeSettingsHashtable -InputObject $Settings[$permissionsKey]
    }

    $permissions = $Settings[$permissionsKey]
    $existingAllow = [System.Collections.Generic.List[string]]::new()
    if ($permissions.Contains($allowKey) -and $null -ne $permissions[$allowKey]) {
        foreach ($entry in @($permissions[$allowKey])) {
            if ($null -ne $entry) {
                $existingAllow.Add([string]$entry)
            }
        }
    }

    foreach ($managedEntry in $ManagedAllowEntries) {
        if (-not $existingAllow.Contains($managedEntry)) {
            $existingAllow.Add($managedEntry)
        }
    }

    $permissions[$allowKey] = @($existingAllow.ToArray())
}

function Read-ClaudeSettingsObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SettingsPath
    )

    if (-not (Test-Path -LiteralPath $SettingsPath)) {
        return [ordered]@{}
    }

    $raw = [System.IO.File]::ReadAllText($SettingsPath)
    try {
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw ($script:ClaudePublishMessage.SettingsInvalidJson -f $SettingsPath, $_.Exception.Message)
    }

    if ($null -eq $parsed) {
        return [ordered]@{}
    }

    $asHashtable = ConvertTo-ClaudeSettingsHashtable -InputObject $parsed
    if ($asHashtable -is [System.Collections.IDictionary]) {
        return $asHashtable
    }

    throw ($script:ClaudePublishMessage.SettingsInvalidJson -f $SettingsPath, 'root value must be a JSON object')
}

function Write-ClaudeSettingsUtf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SettingsPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Settings
    )

    $json = $Settings | ConvertTo-Json -Depth $script:ClaudeSettingsJsonConstant.JsonConvertDepth
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($SettingsPath, $json, $utf8NoBom)
}

function Backup-ClaudeSettingsFile {
    <#
    .SYNOPSIS
      Copy settings.json to the latest .bak, and optionally a timestamped
      audit-trail backup (settings.json.bak.<yyyyMMddHHmmss>).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SettingsPath,

        [Parameter(Mandatory = $true)]
        [string] $BackupPath,

        [Parameter()]
        [string] $TimestampedBackupPath
    )

    try {
        Copy-Item -LiteralPath $SettingsPath -Destination $BackupPath -Force -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($TimestampedBackupPath)) {
            Copy-Item -LiteralPath $SettingsPath -Destination $TimestampedBackupPath -Force -ErrorAction Stop
        }
    }
    catch {
        throw ($script:ClaudePublishMessage.SettingsBackupFailed -f $SettingsPath, $BackupPath, $_.Exception.Message)
    }
}

function Invoke-ClaudeMergeSettings {
    <#
    .SYNOPSIS
      Merge toolkit hooks/permissions into InstallRoot/settings.json safely.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $AllowBroadShellPermissions,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:ClaudePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ClaudeAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $settingsPath = Get-ClaudeSettingsFilePath -InstallRoot $resolvedInstallRoot
    $backupPath = Get-ClaudeSettingsBackupPath -SettingsPath $settingsPath
    $timestampedBackupPath = Get-ClaudeSettingsTimestampedBackupPath -SettingsPath $settingsPath
    $settingsExisted = Test-Path -LiteralPath $settingsPath

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success               = $true
            Implemented           = $true
            CommandName           = 'Invoke-ClaudeMergeSettings'
            WhatIf                = $true
            InstallRoot           = $resolvedInstallRoot
            SettingsPath          = $settingsPath
            BackupPath            = $backupPath
            TimestampedBackupPath = $timestampedBackupPath
            BackupTaken           = $false
            Message               = ($script:ClaudePublishMessage.SettingsWhatIfOk -f $settingsPath)
            ExitCode              = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $settingsPath = Get-ClaudeSettingsFilePath -InstallRoot $resolvedInstallRoot
    $backupPath = Get-ClaudeSettingsBackupPath -SettingsPath $settingsPath
    $timestampedBackupPath = Get-ClaudeSettingsTimestampedBackupPath -SettingsPath $settingsPath
    $settingsExisted = Test-Path -LiteralPath $settingsPath

    try {
        $settings = Read-ClaudeSettingsObject -SettingsPath $settingsPath
    }
    catch {
        return [PSCustomObject]@{
            Success               = $false
            Implemented           = $true
            CommandName           = 'Invoke-ClaudeMergeSettings'
            WhatIf                = $false
            InstallRoot           = $resolvedInstallRoot
            SettingsPath          = $settingsPath
            BackupPath            = $backupPath
            TimestampedBackupPath = $timestampedBackupPath
            BackupTaken           = $false
            Message               = $_.Exception.Message
            ExitCode              = 1
        }
    }

    try {
        $managedHooks = Get-ClaudeManagedHooksObject -InstallRoot $resolvedInstallRoot
        Merge-ClaudeHooksKeyed -Settings $settings -ManagedHooks $managedHooks

        # Strip legacy broad Bash(pwsh *) / Bash(powershell *) unless operator opts in.
        if (-not $AllowBroadShellPermissions.IsPresent) {
            [void](Remove-ClaudePermissionsAllowEntriesByEquality -Settings $settings -EntriesToRemove @($script:ClaudeLegacyBroadPermissionsAllow))
        }
        $managedAllow = @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $resolvedInstallRoot -AllowBroadShellPermissions:$AllowBroadShellPermissions)
        Merge-ClaudePermissionsAllowAdditive -Settings $settings -ManagedAllowEntries $managedAllow
    }
    catch {
        return [PSCustomObject]@{
            Success               = $false
            Implemented           = $true
            CommandName           = 'Invoke-ClaudeMergeSettings'
            WhatIf                = $false
            InstallRoot           = $resolvedInstallRoot
            SettingsPath          = $settingsPath
            BackupPath            = $backupPath
            TimestampedBackupPath = $timestampedBackupPath
            BackupTaken           = $false
            Message               = $_.Exception.Message
            ExitCode              = 1
        }
    }

    $backupTaken = $false
    if ($settingsExisted) {
        try {
            Backup-ClaudeSettingsFile -SettingsPath $settingsPath -BackupPath $backupPath -TimestampedBackupPath $timestampedBackupPath
            $backupTaken = $true
        }
        catch {
            return [PSCustomObject]@{
                Success               = $false
                Implemented           = $true
                CommandName           = 'Invoke-ClaudeMergeSettings'
                WhatIf                = $false
                InstallRoot           = $resolvedInstallRoot
                SettingsPath          = $settingsPath
                BackupPath            = $backupPath
                TimestampedBackupPath = $timestampedBackupPath
                BackupTaken           = $false
                Message               = $_.Exception.Message
                ExitCode              = 1
            }
        }
    }

    try {
        $settingsDirectory = Split-Path -Parent $settingsPath
        if (-not (Test-Path -LiteralPath $settingsDirectory)) {
            New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
        }
        Write-ClaudeSettingsUtf8NoBom -SettingsPath $settingsPath -Settings $settings
    }
    catch {
        return [PSCustomObject]@{
            Success               = $false
            Implemented           = $true
            CommandName           = 'Invoke-ClaudeMergeSettings'
            WhatIf                = $false
            InstallRoot           = $resolvedInstallRoot
            SettingsPath          = $settingsPath
            BackupPath            = $backupPath
            TimestampedBackupPath = $timestampedBackupPath
            BackupTaken           = $backupTaken
            Message               = ($script:ClaudePublishMessage.SettingsWriteFailed -f $settingsPath, $_.Exception.Message)
            ExitCode              = 1
        }
    }

    return [PSCustomObject]@{
        Success               = $true
        Implemented           = $true
        CommandName           = 'Invoke-ClaudeMergeSettings'
        WhatIf                = $false
        InstallRoot           = $resolvedInstallRoot
        SettingsPath          = $settingsPath
        BackupPath            = $backupPath
        TimestampedBackupPath = $timestampedBackupPath
        BackupTaken           = $backupTaken
        Message               = ($script:ClaudePublishMessage.SettingsMergedOk -f $settingsPath, $backupTaken)
        ExitCode              = 0
    }
}
