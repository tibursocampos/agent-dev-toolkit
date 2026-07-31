#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Cursor Publish-Router (core/router/AGENTS.md -> InstallRoot/AGENTS.md).
#>

function Invoke-CursorPublishRouter {
    <#
    .SYNOPSIS
      Publish core/router/AGENTS.md into InstallRoot/AGENTS.md.
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

    $sourceRouterRoot = Join-Path (Join-Path $repoRoot $script:CursorAdapterConstant.CoreDirectoryName) $script:CursorAdapterConstant.RouterDirectoryName
    $sourceAgentsPath = Join-Path $sourceRouterRoot $script:CursorAdapterConstant.AgentsMarkdownFileName
    if (-not (Test-Path -LiteralPath $sourceAgentsPath)) {
        throw ($script:CursorAdapterMessage.CoreRouterMissing -f $sourceAgentsPath)
    }

    $destAgentsPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.AgentsMarkdownFileName

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success          = $true
            Implemented      = $true
            CommandName      = 'Publish-Router'
            InstallRoot      = $resolvedInstallRoot
            SourceAgentsPath = $sourceAgentsPath
            DestAgentsPath   = $destAgentsPath
            WhatIf           = $true
            Message          = ($script:CursorAdapterMessage.RouterWouldPublish -f $sourceAgentsPath, $destAgentsPath)
            ExitCode         = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destAgentsPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.AgentsMarkdownFileName
    Assert-ToolkitManagedPathContained `
        -CandidatePath $destAgentsPath `
        -RootPath $resolvedInstallRoot `
        -EscapeMessageFormat $script:ToolkitMessage.ManagedCopyPathEscapesRoot `
        -RequireStrictChild

    $raw = [System.IO.File]::ReadAllText($sourceAgentsPath)
    $placeholderMap = Get-CursorPlaceholderMap -InstallRoot $resolvedInstallRoot
    $resolved = Resolve-CursorPlaceholdersInText -Text $raw -PlaceholderMap $placeholderMap
    Assert-CursorPlaceholdersResolvedInFile -FilePath $destAgentsPath -Text $resolved
    Write-CursorUtf8NoBom -Path $destAgentsPath -Content $resolved -InstallRoot $resolvedInstallRoot

    return [PSCustomObject]@{
        Success          = $true
        Implemented      = $true
        CommandName      = 'Publish-Router'
        InstallRoot      = $resolvedInstallRoot
        SourceAgentsPath = $sourceAgentsPath
        DestAgentsPath   = $destAgentsPath
        WhatIf           = $false
        Message          = ($script:CursorAdapterMessage.RouterPublished -f $sourceAgentsPath, $destAgentsPath)
        ExitCode         = 0
    }
}


