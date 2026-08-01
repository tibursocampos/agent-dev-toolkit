#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Cursor Publish-Hooks (scripts + hooks.json keyed merge).

.DESCRIPTION
  Mapping: adapters/cursor/assets/hooks/* -> <InstallRoot>/hooks/*
  Merges InstallRoot/hooks.json with Claude-style keyed upsert.
  Includes ConvertTo-CursorCleanJson, Write-CursorUtf8NoBom, and merge helpers.
  Smoke validates filesystem presence - Cursor trust UI is out of scope.
#>

$script:CursorHooksHelperDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CursorHooksHelperDirectory)) {
    $script:CursorHooksHelperDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Script-scope load so path-gate asserts are available to Copy-/Write- helpers.
$_cursorHooksLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CursorHooksHelperDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
    . (Join-Path $_cursorHooksLibDir 'Copy-ToolkitManagedTree.ps1')
}
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_cursorHooksLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _cursorHooksLibDir -ErrorAction SilentlyContinue

function ConvertTo-CursorCleanJson {
    param(
        $Object,
        [int] $Depth = 10
    )

    $raw = $Object | ConvertTo-Json -Depth $Depth
    $raw = [regex]::Replace($raw, '\\u([0-9a-fA-F]{4})', {
            param($m)
            $cp = [Convert]::ToInt32($m.Groups[1].Value, 16)
            if ($cp -ge 0x20 -and $cp -ne 0x22 -and $cp -ne 0x5C) {
                [char]$cp
            }
            else {
                $m.Value
            }
        })
    $lines = $raw -split "`n"
    return ($lines | ForEach-Object {
            if ($_ -match '^( {4,})') {
                $indentDepth = [math]::Floor($Matches[1].Length / 4)
                ('  ' * $indentDepth) + $_.TrimStart()
            }
            else {
                $_
            }
        }) -join "`n"
}

function Write-CursorUtf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Content,
        [Parameter(Mandatory = $true)][string] $InstallRoot
    )

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        $hooksRepoRoot = Split-Path -Parent (Split-Path -Parent $script:CursorHooksHelperDirectory)
        . (Join-Path (Join-Path $hooksRepoRoot 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1')
    }

    Assert-ToolkitManagedPathContained `
        -CandidatePath $Path `
        -RootPath $InstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tempPath = $Path + $script:CursorAdapterConstant.AtomicWriteTempSuffix
    $maxAttempts = [int]$script:CursorAdapterConstant.AtomicWriteMaxAttempts
    $delayMs = [int]$script:CursorAdapterConstant.AtomicWriteRetryDelayMilliseconds
    $lastError = $null

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            Assert-ToolkitManagedPathContained `
                -CandidatePath $tempPath `
                -RootPath $InstallRoot `
                -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
                -RequireStrictChild
            [System.IO.File]::WriteAllText($tempPath, $Content, $utf8NoBom)
            Move-Item -LiteralPath $tempPath -Destination $Path -Force
            return
        }
        catch {
            $lastError = $_
            if (Test-Path -LiteralPath $tempPath) {
                $null = Assert-PathUnderInstallRootForDelete -CandidatePath $tempPath -InstallRoot $InstallRoot
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            }
            if ($attempt -lt $maxAttempts) {
                Start-Sleep -Milliseconds $delayMs
            }
        }
    }

    $detail = if ($null -ne $lastError) { [string]$lastError.Exception.Message } else { 'unknown error' }
    throw ($script:CursorAdapterMessage.AtomicWriteFailed -f $Path, $maxAttempts, $detail)
}

function Get-CursorHookEntryArray {
    param($Entries)

    if ($null -eq $Entries) {
        return @()
    }
    if ($Entries -is [System.Collections.ArrayList]) {
        return $Entries.ToArray()
    }
    if ($Entries -is [System.Array]) {
        return $Entries
    }
    if ($Entries.PSObject.Properties['command']) {
        return @($Entries)
    }
    return @($Entries)
}

function Get-CursorHookCommandKey {
    param($Entry)

    if ($null -eq $Entry) {
        return $null
    }
    $prop = $Entry.PSObject.Properties['command']
    if (-not $prop -or [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
        return $null
    }
    return [string]$prop.Value
}

function Test-CursorManagedHookCommand {
    <#
    .SYNOPSIS
      Identity check: does a hooks.json command belong to a toolkit-managed hook script?

    .DESCRIPTION
      Prefers powershell/pwsh -File ".../hooks/<ManagedScriptFileName>" (quoted or
      unquoted; forward or backslash separators). Unless -StrictFileMatch is set,
      falls back to a hooks/<file> path-segment match so older InstallRoot prefixes
      still identify as managed during publish merge.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [string] $Command,

        [Parameter(Mandatory = $true)]
        [string] $ManagedScriptFileName,

        [Parameter()]
        [switch] $StrictFileMatch
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $false
    }

    $hooksSeg = [regex]::Escape($script:CursorAdapterConstant.HooksDirectoryName)
    $fileEsc = [regex]::Escape($ManagedScriptFileName)
    $hooksFileSegment = ('[\\/]{0}[\\/]{1}' -f $hooksSeg, $fileEsc)

    $quotedTemplate = ('(?i)(pwsh|powershell)\s+[^\r\n]*-File\s+"[^"]*{0}"' -f $hooksFileSegment)
    if ($Command -match $quotedTemplate) {
        return $true
    }

    $unquotedTemplate = ('(?i)(pwsh|powershell)\s+[^\r\n]*-File\s+\S*{0}' -f $hooksFileSegment)
    if ($Command -match $unquotedTemplate) {
        return $true
    }

    if ($StrictFileMatch.IsPresent) {
        return $false
    }

    return ($Command -match $hooksFileSegment)
}

function Get-CursorManagedHookScriptNamesFromEntries {
    param($ToolkitEntries)

    $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in (Get-CursorHookEntryArray $ToolkitEntries)) {
        $cmd = Get-CursorHookCommandKey $entry
        if ([string]::IsNullOrWhiteSpace($cmd)) {
            continue
        }
        foreach ($scriptName in $script:CursorAdapterConstant.ManagedHookScriptNames) {
            if (Test-CursorManagedHookCommand -Command $cmd -ManagedScriptFileName $scriptName) {
                [void]$names.Add($scriptName)
            }
        }
    }
    return , @($names)
}

function Test-CursorHookCommandIsToolkitManaged {
    param(
        [Parameter()]
        [AllowNull()]
        [string] $Command,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $ManagedScriptFileNames,

        [Parameter()]
        [switch] $StrictFileMatch
    )

    if ([string]::IsNullOrWhiteSpace($Command) -or $null -eq $ManagedScriptFileNames -or $ManagedScriptFileNames.Count -eq 0) {
        return $false
    }

    foreach ($scriptName in $ManagedScriptFileNames) {
        if (Test-CursorManagedHookCommand -Command $Command -ManagedScriptFileName $scriptName -StrictFileMatch:$StrictFileMatch) {
            return $true
        }
    }
    return $false
}

function Merge-CursorHookEventEntries {
    <#
    .SYNOPSIS
      Claude-style keyed upsert for one Cursor hooks.json event array.

    .DESCRIPTION
      Drops only handlers this toolkit recognizes as its own (by hooks/<script>
      identity from current toolkit entries) so re-sync replaces stale toolkit
      commands instead of skipping on exact command-key match. Preserves every
      other (alien) command, then prepends the freshly generated toolkit entries.
    #>
    param(
        $UserEntries,
        $ToolkitEntries
    )

    $toolkitList = @(Get-CursorHookEntryArray $ToolkitEntries)
    $managedScriptNames = @(Get-CursorManagedHookScriptNamesFromEntries $toolkitList)

    $preserved = [System.Collections.ArrayList]::new()
    foreach ($entry in (Get-CursorHookEntryArray $UserEntries)) {
        $cmd = Get-CursorHookCommandKey $entry
        if (Test-CursorHookCommandIsToolkitManaged -Command $cmd -ManagedScriptFileNames $managedScriptNames) {
            continue
        }
        [void]$preserved.Add($entry)
    }

    $merged = [System.Collections.ArrayList]::new()
    foreach ($entry in $toolkitList) {
        $cmd = Get-CursorHookCommandKey $entry
        if ([string]::IsNullOrWhiteSpace($cmd)) {
            continue
        }
        [void]$merged.Add($entry)
    }
    foreach ($entry in $preserved) {
        [void]$merged.Add($entry)
    }
    return @($merged)
}

function Get-CursorHooksPayloadHashtable {
    param($HooksObject)

    $hooksHash = [ordered]@{}
    foreach ($eventName in $HooksObject.PSObject.Properties.Name) {
        $hooksHash[$eventName] = @(Get-CursorHookEntryArray $HooksObject.$eventName)
    }
    return $hooksHash
}

function Read-CursorHooksJsonObject {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter()][switch] $OptionalMissing
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        if ($OptionalMissing.IsPresent) {
            return [PSCustomObject]@{
                version = $script:CursorAdapterConstant.HooksJsonVersionDefault
                hooks   = [PSCustomObject]@{}
            }
        }
        throw ($script:CursorAdapterMessage.HooksSourceMissing -f $Path)
    }

    $raw = [System.IO.File]::ReadAllText($Path)
    try {
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        throw ($script:CursorAdapterMessage.HooksJsonInvalid -f $Path, $_.Exception.Message)
    }
}

function Merge-CursorHooksJsonContent {
    param(
        [Parameter(Mandatory = $true)][string] $ToolkitHooksPath,
        [Parameter(Mandatory = $true)][string] $UserHooksPath
    )

    $toolkit = Read-CursorHooksJsonObject -Path $ToolkitHooksPath
    $user = Read-CursorHooksJsonObject -Path $UserHooksPath -OptionalMissing

    if (-not ($user.PSObject.Properties['version'])) {
        $user | Add-Member -MemberType NoteProperty -Name 'version' -Value $script:CursorAdapterConstant.HooksJsonVersionDefault -Force
    }
    if (-not ($user.PSObject.Properties['hooks'])) {
        $user | Add-Member -MemberType NoteProperty -Name 'hooks' -Value ([PSCustomObject]@{}) -Force
    }
    if (-not ($toolkit.PSObject.Properties['hooks'])) {
        $toolkit | Add-Member -MemberType NoteProperty -Name 'hooks' -Value ([PSCustomObject]@{}) -Force
    }

    $changed = $false
    foreach ($eventName in $toolkit.hooks.PSObject.Properties.Name) {
        $toolkitEntries = $toolkit.hooks.$eventName
        $userProp = $user.hooks.PSObject.Properties[$eventName]
        $userEntries = if ($userProp) { $userProp.Value } else { $null }
        $merged = Merge-CursorHookEventEntries -UserEntries $userEntries -ToolkitEntries $toolkitEntries
        $before = if ($userEntries) { $userEntries | ConvertTo-Json -Compress -Depth 8 } else { '' }
        $after = if ($merged) { $merged | ConvertTo-Json -Compress -Depth 8 } else { '' }
        if ($before -ne $after) {
            $user.hooks | Add-Member -MemberType NoteProperty -Name $eventName -Value ([object[]]$merged) -Force
            $changed = $true
        }
    }

    $payload = [ordered]@{
        version = $user.version
        hooks   = Get-CursorHooksPayloadHashtable $user.hooks
    }

    return [PSCustomObject]@{
        Changed = $changed
        Payload = $payload
    }
}

function Copy-CursorHookScripts {
    param(
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][string] $DestRoot,
        [Parameter(Mandatory = $true)][string] $InstallRoot
    )

    if (-not (Get-Command -Name Assert-ToolkitManagedPathContained -ErrorAction SilentlyContinue)) {
        $hooksRepoRoot = Split-Path -Parent (Split-Path -Parent $script:CursorHooksHelperDirectory)
        . (Join-Path (Join-Path $hooksRepoRoot 'scripts\_lib') 'Copy-ToolkitManagedTree.ps1')
    }

    $sourceRootFull = [System.IO.Path]::GetFullPath($SourceRoot)
    $destRootFull = [System.IO.Path]::GetFullPath($DestRoot)
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destRootFull -InstallRoot $InstallRoot

    if (-not (Test-Path -LiteralPath $destRootFull)) {
        New-Item -ItemType Directory -Path $destRootFull -Force | Out-Null
    }

    # Re-assert after create / when dest already existed as a reparse child.
    $destRootFull = [System.IO.Path]::GetFullPath($destRootFull)
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destRootFull -InstallRoot $InstallRoot

    $excludeName = $script:CursorAdapterConstant.HooksJsonFileName
    $copied = 0
    Get-ChildItem -LiteralPath $sourceRootFull -File -ErrorAction Stop | ForEach-Object {
        if ($_.Name -eq $excludeName) {
            return
        }

        Assert-ToolkitManagedPathContained `
            -CandidatePath $_.FullName `
            -RootPath $sourceRootFull `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot

        $destPath = Join-Path $destRootFull $_.Name
        Assert-ToolkitManagedPathContained `
            -CandidatePath $destPath `
            -RootPath $destRootFull `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot
        Assert-ToolkitManagedPathContained `
            -CandidatePath $destPath `
            -RootPath $InstallRoot `
            -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
            -RequireStrictChild

        Copy-Item -LiteralPath $_.FullName -Destination $destPath -Force
        $copied++
    }
    return $copied
}

function Invoke-CursorPublishHooks {
    <#
    .SYNOPSIS
      Publish hook scripts under InstallRoot/hooks and merge hooks.json at InstallRoot root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $WhatIf,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    $repoRoot = Get-CursorAdapterRepoRoot
    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot

    $sourceHooksRoot = Join-Path $script:CursorHooksHelperDirectory $script:CursorAdapterConstant.HooksAssetsRelativePath
    $sourceHooksJson = Join-Path $sourceHooksRoot $script:CursorAdapterConstant.HooksJsonFileName
    if (-not (Test-Path -LiteralPath $sourceHooksRoot) -or -not (Test-Path -LiteralPath $sourceHooksJson)) {
        throw ($script:CursorAdapterMessage.HooksSourceMissing -f $sourceHooksRoot)
    }

    $destHooksRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.HooksDirectoryName
    $destHooksJson = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.HooksJsonFileName
    $scriptCount = @(Get-ChildItem -LiteralPath $sourceHooksRoot -File -ErrorAction Stop |
            Where-Object { $_.Name -ne $script:CursorAdapterConstant.HooksJsonFileName }).Count

    # Validate toolkit + user JSON before any mutation (TE03: fail closed, do not truncate).
    $null = Merge-CursorHooksJsonContent -ToolkitHooksPath $sourceHooksJson -UserHooksPath $destHooksJson

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Hooks'
            InstallRoot      = $resolvedInstallRoot
            SourceHooksRoot  = $sourceHooksRoot
            DestHooksRoot    = $destHooksRoot
            DestHooksJson    = $destHooksJson
            HookScriptCount  = $scriptCount
            WhatIf           = $true
            Message          = ($script:CursorAdapterMessage.HooksWouldPublish -f $scriptCount, $destHooksRoot, $destHooksJson)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destHooksRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.HooksDirectoryName
    $destHooksJson = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.HooksJsonFileName
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destHooksRoot -InstallRoot $resolvedInstallRoot
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destHooksJson `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild
    if (-not (Test-Path -LiteralPath $destHooksRoot)) {
        New-Item -ItemType Directory -Path $destHooksRoot -Force | Out-Null
    }
    Assert-ToolkitManagedDestinationUnderInstallRoot -DestinationPath $destHooksRoot -InstallRoot $resolvedInstallRoot

    $publishedScripts = Copy-CursorHookScripts -SourceRoot $sourceHooksRoot -DestRoot $destHooksRoot -InstallRoot $resolvedInstallRoot
    $mergeResult = Merge-CursorHooksJsonContent -ToolkitHooksPath $sourceHooksJson -UserHooksPath $destHooksJson
    $json = ConvertTo-CursorCleanJson -Object $mergeResult.Payload
    Write-CursorUtf8NoBom -Path $destHooksJson -Content $json -InstallRoot $resolvedInstallRoot

    return [PSCustomObject]@{
        Success         = $true
        Implemented     = $true
        CommandName     = 'Publish-Hooks'
        InstallRoot     = $resolvedInstallRoot
        SourceHooksRoot = $sourceHooksRoot
        DestHooksRoot   = $destHooksRoot
        DestHooksJson   = $destHooksJson
        HookScriptCount = $publishedScripts
        HooksChanged    = [bool]$mergeResult.Changed
        WhatIf          = $false
        Message         = ($script:CursorAdapterMessage.HooksPublished -f $publishedScripts, $destHooksRoot, $destHooksJson)
        ExitCode        = 0
    }
}

