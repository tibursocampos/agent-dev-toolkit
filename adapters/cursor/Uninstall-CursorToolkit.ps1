#Requires -Version 5.1
<#
.SYNOPSIS
  Keyed uninstall for Cursor adapter toolkit artifacts.

.DESCRIPTION
  Removes only known toolkit-managed paths under InstallRoot:
  - skills/<id> folders matching core/skills
  - rules/<file>.mdc matching core/policy/*.md
  - AGENTS.md (Publish-Router target) when provenance confirms toolkit ownership
    (.toolkit-managed-publish.json sha256, or legacy hash match to core/router publish)
  - hooks/<script> matching ManagedHookScriptNames
  - reverse-merge InstallRoot/hooks.json (drop toolkit-managed handlers by command identity)

  Operator-edited or drifted AGENTS.md is preserved (not deleted). JSON reverse-merge
  runs before filesystem deletes (Wave2 order).

  Does NOT remove sdd/sessions or sdd/manifest.json (operator runtime state).
  Does not wipe InstallRoot wholesale (RN07 / CU03). Supports -WhatIf.
#>

$script:CursorUninstallModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:CursorUninstallModuleDirectory)) {
    $script:CursorUninstallModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_cursorUninstallLibDir = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:CursorUninstallModuleDirectory)
) 'scripts\_lib'
if (-not (Get-Command -Name Assert-PathUnderInstallRootForDelete -ErrorAction SilentlyContinue)) {
    . (Join-Path $_cursorUninstallLibDir 'Resolve-InstallRoot.ps1')
}
Remove-Variable -Name _cursorUninstallLibDir -ErrorAction SilentlyContinue

$script:CursorUninstallMessage = @{
    InstallRootRequired      = 'InstallRoot is required.'
    NothingFound             = 'Cursor Uninstall-Toolkit: no keyed toolkit artifacts found under {0}.'
    WhatIfOk                 = 'Cursor Uninstall-Toolkit WhatIf: would remove {0} path(s) under {1}.'
    RemovedOk                = 'Cursor Uninstall-Toolkit: removed {0} path(s) under {1}.'
    HooksJsonAbsentOk        = 'hooks.json absent; nothing to reverse-merge.'
    HooksJsonNoManaged       = 'hooks.json had no toolkit-managed handlers to remove.'
    HooksJsonWhatIfOk        = 'WhatIf: would reverse-merge toolkit handlers out of {0}.'
    HooksJsonCleanedOk       = 'Reverse-merged toolkit handlers out of {0}.'
    HooksJsonInvalid         = 'Invalid hooks.json at {0}: {1}'
    SddPreservedNote         = 'SDD sessions/manifest preserved (operator state).'
    RouterPreservedNote      = 'AGENTS.md preserved (operator edit or drift; not toolkit-owned).'
}

function Get-CursorUninstallRepoRoot {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-CursorAdapterRepoRoot -ErrorAction SilentlyContinue) {
        return Get-CursorAdapterRepoRoot
    }

    return (Split-Path -Parent (Split-Path -Parent $script:CursorUninstallModuleDirectory))
}

function Get-CursorManagedSkillIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $coreSkillsRoot = Join-Path (
        Join-Path $RepoRoot $script:CursorAdapterConstant.CoreDirectoryName
    ) $script:CursorAdapterConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $coreSkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $coreSkillsRoot -Directory -Force |
            Select-Object -ExpandProperty Name
    )
}

function Get-CursorManagedRuleDestRelativePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $corePolicyRoot = Join-Path (
        Join-Path $RepoRoot $script:CursorAdapterConstant.CoreDirectoryName
    ) $script:CursorAdapterConstant.PolicyDirectoryName

    if (-not (Test-Path -LiteralPath $corePolicyRoot)) {
        return @()
    }

    $paths = New-Object System.Collections.Generic.List[string]
    $files = Get-ChildItem -LiteralPath $corePolicyRoot -Recurse -File -Force
    $srcExt = $script:CursorAdapterConstant.PolicySourceExtension
    $destExt = $script:CursorAdapterConstant.PolicyDestExtension
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($corePolicyRoot.Length).TrimStart('\', '/')
        if ($relative.EndsWith($srcExt, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relative = $relative.Substring(0, $relative.Length - $srcExt.Length) + $destExt
        }
        $paths.Add($relative) | Out-Null
    }

    return @($paths.ToArray())
}

function Remove-CursorManagedPathIfPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [switch] $WhatIf,

        [Parameter()]
        [switch] $Recurse
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $null = Assert-PathUnderInstallRootForDelete -CandidatePath $Path -InstallRoot $InstallRoot

    if ($WhatIf.IsPresent) {
        return $true
    }

    if ($Recurse.IsPresent) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    else {
        Remove-Item -LiteralPath $Path -Force
    }

    return $true
}

function Remove-CursorToolkitHooksJsonEntries {
    <#
    .SYNOPSIS
      Reverse-merge InstallRoot/hooks.json: drop toolkit-managed handlers; keep aliens.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResolvedInstallRoot,

        [Parameter()]
        [switch] $WhatIf
    )

    $hooksJsonPath = Join-Path $ResolvedInstallRoot $script:CursorAdapterConstant.HooksJsonFileName
    if (-not (Test-Path -LiteralPath $hooksJsonPath)) {
        return [PSCustomObject]@{
            Success         = $true
            HooksJsonTouched = $false
            HooksJsonPath   = $hooksJsonPath
            Message         = $script:CursorUninstallMessage.HooksJsonAbsentOk
        }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($hooksJsonPath)
        $payload = $raw | ConvertFrom-Json
    }
    catch {
        return [PSCustomObject]@{
            Success          = $false
            HooksJsonTouched = $false
            HooksJsonPath    = $hooksJsonPath
            Message          = ($script:CursorUninstallMessage.HooksJsonInvalid -f $hooksJsonPath, $_.Exception.Message)
        }
    }

    $managedNames = @($script:CursorAdapterConstant.ManagedHookScriptNames)
    $hooksObject = $payload.hooks
    if ($null -eq $hooksObject) {
        return [PSCustomObject]@{
            Success          = $true
            HooksJsonTouched = $false
            HooksJsonPath    = $hooksJsonPath
            Message          = $script:CursorUninstallMessage.HooksJsonNoManaged
        }
    }

    $changed = $false
    $newHooks = [ordered]@{}
    foreach ($eventName in @($hooksObject.PSObject.Properties.Name)) {
        $preserved = New-Object System.Collections.Generic.List[object]
        foreach ($entry in @(Get-CursorHookEntryArray $hooksObject.$eventName)) {
            $cmd = Get-CursorHookCommandKey $entry
            if (Test-CursorHookCommandIsToolkitManaged -Command $cmd -ManagedScriptFileNames $managedNames -StrictFileMatch) {
                $changed = $true
                continue
            }
            $preserved.Add($entry) | Out-Null
        }
        if ($preserved.Count -gt 0) {
            $newHooks[$eventName] = @($preserved.ToArray())
        }
        elseif (@(Get-CursorHookEntryArray $hooksObject.$eventName).Count -gt 0) {
            # Event had only toolkit handlers — drop empty event key.
            $changed = $true
        }
    }

    if (-not $changed) {
        return [PSCustomObject]@{
            Success          = $true
            HooksJsonTouched = $false
            HooksJsonPath    = $hooksJsonPath
            Message          = $script:CursorUninstallMessage.HooksJsonNoManaged
        }
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            HooksJsonTouched = $true
            HooksJsonPath    = $hooksJsonPath
            WhatIf           = $true
            Message          = ($script:CursorUninstallMessage.HooksJsonWhatIfOk -f $hooksJsonPath)
        }
    }

    # Reverse-merge contract: preserve every top-level property; replace hooks only.
    $payload.hooks = [PSCustomObject]$newHooks

    $json = ConvertTo-CursorCleanJson -Object $payload
    Write-CursorUtf8NoBom -Path $hooksJsonPath -Content $json -InstallRoot $ResolvedInstallRoot

    return [PSCustomObject]@{
        Success          = $true
        HooksJsonTouched = $true
        HooksJsonPath    = $hooksJsonPath
        Message          = ($script:CursorUninstallMessage.HooksJsonCleanedOk -f $hooksJsonPath)
    }
}

function Invoke-CursorUninstallToolkit {
    <#
    .SYNOPSIS
      Remove keyed toolkit artifacts from Cursor InstallRoot (preserve SDD sessions/manifest).
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
        throw $script:CursorUninstallMessage.InstallRootRequired
    }

    $repoRoot = Get-CursorUninstallRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    . (Join-Path $libDir 'Copy-ToolkitManagedTree.ps1')
    . (Join-Path $libDir 'ToolkitManagedPublishInventory.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $removedPaths = New-Object System.Collections.Generic.List[string]
    $wouldRemovePaths = New-Object System.Collections.Generic.List[string]
    $routerNotes = New-Object System.Collections.Generic.List[string]

    $hooksJsonResult = Remove-CursorToolkitHooksJsonEntries -ResolvedInstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
    if ($null -eq $hooksJsonResult -or $hooksJsonResult.Success -ne $true) {
        $detail = if ($null -ne $hooksJsonResult -and $hooksJsonResult.PSObject.Properties.Name -contains 'Message') {
            [string]$hooksJsonResult.Message
        }
        else {
            'hooks.json reverse-merge failed'
        }
        return [PSCustomObject]@{
            Success          = $false
            Implemented      = $true
            CommandName      = 'Uninstall-Toolkit'
            WhatIf           = [bool]$WhatIf.IsPresent
            InstallRoot      = $resolvedInstallRoot
            RemovedCount     = 0
            RemovedPaths     = @()
            HooksJsonTouched = $false
            KeyedOnly        = $true
            WholesaleWipe    = $false
            SddPreserved     = $true
            Message          = $detail
            ExitCode         = 1
        }
    }

    $skillsRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.SkillsDirectoryName
    foreach ($rawSkillId in (Get-CursorManagedSkillIds -RepoRoot $repoRoot)) {
        try {
            $skillId = Assert-ToolkitManagedSkillName -SkillName $rawSkillId
        }
        catch {
            continue
        }
        $skillPath = Join-Path $skillsRoot $skillId
        $hit = Remove-CursorManagedPathIfPresent -Path $skillPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf -Recurse
        if ($hit) {
            $wouldRemovePaths.Add($skillPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($skillPath) | Out-Null
            }
        }
    }

    $rulesRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.RulesDirectoryName
    foreach ($ruleRelative in (Get-CursorManagedRuleDestRelativePaths -RepoRoot $repoRoot)) {
        $rulePath = Join-Path $rulesRoot ($ruleRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $hit = Remove-CursorManagedPathIfPresent -Path $rulePath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($hit) {
            $wouldRemovePaths.Add($rulePath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($rulePath) | Out-Null
            }
        }
    }

    $agentsPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.AgentsMarkdownFileName
    $routerRemoveResult = Remove-ToolkitManagedWholeFileRouterIfOwned `
        -InstallRoot $resolvedInstallRoot `
        -RelativePath $script:CursorAdapterConstant.AgentsMarkdownFileName `
        -CurrentFilePath $agentsPath `
        -ResolveExpectedPublishContent { Get-CursorRouterPublishContent -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome } `
        -WhatIf:$WhatIf
    if ($routerRemoveResult.Removed -or $routerRemoveResult.WouldRemove) {
        $wouldRemovePaths.Add($agentsPath) | Out-Null
        if ($routerRemoveResult.Removed) {
            $removedPaths.Add($agentsPath) | Out-Null
        }
    }
    elseif ($routerRemoveResult.Preserved -and -not [string]::IsNullOrWhiteSpace($routerRemoveResult.Message)) {
        $routerNotes.Add([string]$routerRemoveResult.Message) | Out-Null
    }

    $customAgentsRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.CustomAgentsDirectoryName
    $sourceAgentsRoot = Get-ToolkitCoreAgentsRoot -RepoRoot $repoRoot
    foreach ($agentFileName in (Get-ToolkitManagedAgentFileNames -SourceAgentsRoot $sourceAgentsRoot)) {
        $agentFilePath = Join-Path $customAgentsRoot $agentFileName
        $hit = Remove-CursorManagedPathIfPresent -Path $agentFilePath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($hit) {
            $wouldRemovePaths.Add($agentFilePath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($agentFilePath) | Out-Null
            }
        }
    }

    $hooksRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.HooksDirectoryName
    foreach ($scriptName in @($script:CursorAdapterConstant.ManagedHookScriptNames)) {
        $hookPath = Join-Path $hooksRoot $scriptName
        $hit = Remove-CursorManagedPathIfPresent -Path $hookPath -InstallRoot $resolvedInstallRoot -WhatIf:$WhatIf
        if ($hit) {
            $wouldRemovePaths.Add($hookPath) | Out-Null
            if (-not $WhatIf.IsPresent) {
                $removedPaths.Add($hookPath) | Out-Null
            }
        }
    }

    $pathCount = if ($WhatIf.IsPresent) { $wouldRemovePaths.Count } else { $removedPaths.Count }
    $baseMessage = if ($pathCount -eq 0 -and -not $hooksJsonResult.HooksJsonTouched) {
        ($script:CursorUninstallMessage.NothingFound -f $resolvedInstallRoot)
    }
    elseif ($WhatIf.IsPresent) {
        ($script:CursorUninstallMessage.WhatIfOk -f $pathCount, $resolvedInstallRoot)
    }
    else {
        ($script:CursorUninstallMessage.RemovedOk -f $pathCount, $resolvedInstallRoot)
    }

    $messageParts = @($baseMessage, $hooksJsonResult.Message, $script:CursorUninstallMessage.SddPreservedNote)
    if ($routerNotes.Count -gt 0) {
        $messageParts += @($routerNotes.ToArray())
    }
    $message = ($messageParts -join '; ')

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Uninstall-Toolkit'
        WhatIf           = [bool]$WhatIf.IsPresent
        InstallRoot      = $resolvedInstallRoot
        RemovedCount     = $pathCount
        RemovedPaths     = $(if ($WhatIf.IsPresent) { @($wouldRemovePaths.ToArray()) } else { @($removedPaths.ToArray()) })
        HooksJsonTouched = [bool]$hooksJsonResult.HooksJsonTouched
        HooksJsonPath    = $hooksJsonResult.HooksJsonPath
        KeyedOnly        = $true
        WholesaleWipe    = $false
        SddPreserved     = $true
        Message          = $message
        ExitCode         = 0
    }
}
