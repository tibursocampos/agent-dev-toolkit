#Requires -Version 5.1
$script:ToolkitCopyHelperRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path (Join-Path $script:ToolkitCopyHelperRepoRoot 'scripts') '_lib') 'Copy-ToolkitManagedTree.ps1')

<#
.SYNOPSIS
  Helpers for Copilot Publish-Policy (core policy/router -> Copilot instructions).

.DESCRIPTION
  Mapping (Mode user|repo; relative paths identical under InstallRoot):
  - core/policy/{name}.md -> InstallRoot/instructions/{name}.instructions.md (no Cursor .mdc)
  - core/router/AGENTS.md -> InstallRoot/copilot-instructions.md
  Mode user: InstallRoot models ~/.copilot. Mode repo: InstallRoot models .github.
  Placeholders resolved after copy. Re-publish overwrites managed files; does not delete aliens.
  Policy frontmatter is mapped to Copilot applyTo: alwaysApply: true -> applyTo "**"; a globs
  value -> applyTo; on-demand rules get no applyTo. Rule references (`<name>.mdc`, `rules/`) are
  rewritten through Get-CopilotRuleReferenceMap in Publish-CopilotSkills.ps1.
  Smoke is filesystem-only - Copilot IDE extension is out of scope.
  Mode repo must target a fixture InstallRoot - never the toolkit working-tree .github by default.
#>

function Convert-CopilotPolicyFrontmatterToApplyTo {
    <#
    .SYNOPSIS
      Maps a Cursor-style policy frontmatter block to Copilot instructions frontmatter.

    .DESCRIPTION
      alwaysApply: true -> applyTo: "**". Otherwise a globs value, when present, becomes
      applyTo. A rule with neither stays on demand and carries no applyTo, because Copilot
      applies path-specific instructions only when applyTo matches. The alwaysApply key is
      dropped from the published file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $body = if ($Text.Length -gt 0 -and [int][char]$Text[0] -eq 0xFEFF) { $Text.Substring(1) } else { $Text }
    $match = [regex]::Match($body, '\A---\r?\n(?<frontmatter>.*?)\r?\n---[ \t]*\r?\n', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $match.Success) {
        return $body
    }

    $description = $null
    $alwaysApply = $false
    $globs = $null
    foreach ($line in ($match.Groups['frontmatter'].Value -split '\r?\n')) {
        if ($line -match '^description:\s*(.*)$') {
            $description = $Matches[1]
        }
        elseif ($line -match '^alwaysApply:\s*(true|false)\s*$') {
            $alwaysApply = ($Matches[1] -eq 'true')
        }
        elseif ($line -match '^globs:\s*(.*)$') {
            $globs = $Matches[1].Trim().Trim('"', "'")
        }
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('---')
    if (-not [string]::IsNullOrEmpty($description)) {
        $lines.Add('description: ' + $description)
    }
    if ($alwaysApply) {
        $lines.Add($script:CopilotPathConstant.ApplyToAllFrontmatterToken)
    }
    elseif (-not [string]::IsNullOrEmpty($globs)) {
        $lines.Add('applyTo: "' + $globs + '"')
    }
    $lines.Add('---')

    return (($lines -join "`n") + "`n" + $body.Substring($match.Length))
}

function Convert-CopilotHomeAgentsPathToInstructionsFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $separator = $script:CopilotPathConstant.PathSeparatorForwardSlash
    $agentsFileName = $script:CopilotPathConstant.RouterSourceFileName
    $instructionsFileName = $script:CopilotPathConstant.CopilotInstructionsFileName
    $normalizedRoot = (Get-CopilotNormalizedForwardSlashPath -Path $InstallRoot).TrimEnd($separator)
    $instructionsPath = $normalizedRoot + $separator + $instructionsFileName
    $resolvedHomeAgentsPath = $normalizedRoot + $separator + $agentsFileName
    $placeholderHomeAgentsPath = $script:CopilotPathConstant.PlaceholderToolkitRoot + $separator + $agentsFileName

    $updated = $Text.Replace($placeholderHomeAgentsPath, $instructionsPath)
    return $updated.Replace($resolvedHomeAgentsPath, $instructionsPath)
}

function Update-CopilotTreeHomeAgentsReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        return @()
    }

    $extensionPattern = $script:CopilotPathConstant.TextFileExtensionPattern
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $changedPaths = New-Object System.Collections.Generic.List[string]
    $files = Get-ChildItem -LiteralPath $RootPath -Recurse -File -ErrorAction Stop
    foreach ($file in $files) {
        if ($file.Name -notmatch $extensionPattern -and $file.Extension -notmatch $extensionPattern) {
            continue
        }

        $text = [System.IO.File]::ReadAllText($file.FullName)
        $updated = Convert-CopilotHomeAgentsPathToInstructionsFile -Text $text -InstallRoot $InstallRoot
        if ([string]::Equals($updated, $text, [System.StringComparison]::Ordinal)) {
            continue
        }

        Assert-ToolkitManagedWriteDestination -DestinationPath $file.FullName -InstallRoot $InstallRoot
        [System.IO.File]::WriteAllText($file.FullName, $updated, $utf8NoBom)
        $changedPaths.Add([System.IO.Path]::GetFullPath($file.FullName)) | Out-Null
    }

    if ($changedPaths.Count -gt 0) {
        Update-ToolkitManagedCopyInventory -InstallRoot $InstallRoot -Paths @($changedPaths.ToArray())
    }

    return @($changedPaths.ToArray())
}

function Get-CopilotInstructionsDestinationName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceFileName
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFileName)
    return ($baseName + $script:CopilotPathConstant.InstructionsFileExtension)
}

function Copy-CopilotCorePolicyAsInstructions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationInstructionsRoot,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    if (-not (Test-Path -LiteralPath $DestinationInstructionsRoot)) {
        Assert-ToolkitManagedWriteDestination `
            -DestinationPath (Join-Path $DestinationInstructionsRoot 'placeholder.instructions.md') `
            -InstallRoot $InstallRoot
        New-Item -ItemType Directory -Path $DestinationInstructionsRoot -Force | Out-Null
    }
    Assert-ToolkitManagedWriteDestination `
        -DestinationPath (Join-Path $DestinationInstructionsRoot 'placeholder.instructions.md') `
        -InstallRoot $InstallRoot

    $filesCopied = 0
    $sourceExt = $script:CopilotPathConstant.PolicySourceExtension
    $sourceFiles = Get-ChildItem -LiteralPath $SourcePolicyRoot -File -Filter ('*{0}' -f $sourceExt)
    foreach ($file in $sourceFiles) {
        $destinationName = Get-CopilotInstructionsDestinationName -SourceFileName $file.Name
        $destinationPath = Join-Path $DestinationInstructionsRoot $destinationName
        Assert-ToolkitManagedWriteDestination -DestinationPath $destinationPath -InstallRoot $InstallRoot
        $raw = [System.IO.File]::ReadAllText($file.FullName)
        $converted = Convert-CopilotPolicyFrontmatterToApplyTo -Text $raw
        $converted = Convert-CopilotHomeAgentsPathToInstructionsFile -Text $converted -InstallRoot $InstallRoot
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $relativeInventoryPath = ('instructions/{0}' -f $destinationName)
        $null = Write-ToolkitFileIfAbsent `
            -Path $destinationPath `
            -Content $converted `
            -Encoding $utf8NoBom `
            -InstallRoot $InstallRoot `
            -RelativePath $relativeInventoryPath
        $filesCopied++
    }

    return $filesCopied
}

function Publish-CopilotRouterAsInstructionsFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceRouterFile,

        [Parameter(Mandatory = $true)]
        [string] $DestinationInstructionsFile,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap,

        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $destinationDir = Split-Path -Parent $DestinationInstructionsFile
    if (-not (Test-Path -LiteralPath $destinationDir)) {
        Assert-ToolkitManagedWriteDestination -DestinationPath $DestinationInstructionsFile -InstallRoot $InstallRoot
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }
    Assert-ToolkitManagedWriteDestination -DestinationPath $DestinationInstructionsFile -InstallRoot $InstallRoot

    $raw = [System.IO.File]::ReadAllText($SourceRouterFile)
    $updated = Convert-CopilotHomeAgentsPathToInstructionsFile -Text $raw -InstallRoot $InstallRoot
    foreach ($key in $PlaceholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$PlaceholderMap[$key])
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $null = Write-ToolkitFileIfAbsent `
        -Path $DestinationInstructionsFile `
        -Content $updated `
        -Encoding $utf8NoBom `
        -InstallRoot $InstallRoot `
        -RelativePath 'copilot-instructions.md'
}

function Invoke-CopilotPublishPolicy {
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
        throw $script:CopilotPublishMessage.InstallRootRequired
    }

    $normalizedMode = Get-CopilotPublishNormalizedMode -Mode $Mode

    $repoRoot = Get-CopilotPublishAdapterRepoRoot
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:CopilotPathConstant.CoreDirectoryName) $script:CopilotPathConstant.PolicyDirectoryName
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:CopilotPathConstant.CoreDirectoryName) $script:CopilotPathConstant.RouterDirectoryName
    ) $script:CopilotPathConstant.RouterSourceFileName
    $destinationInstructionsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.InstructionsDirectoryName
    $destinationInstructionsFile = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CopilotInstructionsFileName

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:CopilotPublishMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }
    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:CopilotPublishMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success                    = $true
            Implemented                = $true
            CommandName                = 'Publish-Policy'
            WhatIf                     = $true
            Mode                       = $normalizedMode
            InstallRoot                = $resolvedInstallRoot
            InstructionsRoot           = $destinationInstructionsRoot
            CopilotInstructionsPath    = $destinationInstructionsFile
            SourceRoot                 = $sourcePolicyRoot
            RouterSourcePath           = $sourceRouterFile
            FilesCopied                = 0
            Message                    = ($script:CopilotPublishMessage.PolicyWhatIfOk -f $destinationInstructionsRoot, $normalizedMode)
            ExitCode                   = 0
            SmokeFilesystemOnlyNote    = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationInstructionsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.InstructionsDirectoryName
    $destinationInstructionsFile = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CopilotInstructionsFileName

    Enter-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
    try {
        $filesCopied = Copy-CopilotCorePolicyAsInstructions `
            -SourcePolicyRoot $sourcePolicyRoot `
            -DestinationInstructionsRoot $destinationInstructionsRoot `
            -InstallRoot $resolvedInstallRoot
        $placeholderMap = Get-CopilotPlaceholderMap -InstallRoot $resolvedInstallRoot
        Assert-ToolkitManagedWriteDestination `
            -DestinationPath (Join-Path $destinationInstructionsRoot 'placeholder.instructions.md') `
            -InstallRoot $resolvedInstallRoot
        $changedPaths = @(Resolve-CopilotPlaceholdersInTree -RootPath $destinationInstructionsRoot -PlaceholderMap $placeholderMap)
        if ($changedPaths.Count -gt 0) {
            Update-ToolkitManagedCopyInventory -InstallRoot $resolvedInstallRoot -Paths $changedPaths
        }
        Assert-CopilotPlaceholdersResolved -RootPath $destinationInstructionsRoot
        $null = Update-CopilotTreeHomeAgentsReferences -RootPath $destinationInstructionsRoot -InstallRoot $resolvedInstallRoot

        Publish-CopilotRouterAsInstructionsFile `
            -SourceRouterFile $sourceRouterFile `
            -DestinationInstructionsFile $destinationInstructionsFile `
            -PlaceholderMap $placeholderMap `
            -InstallRoot $resolvedInstallRoot
        $filesCopied++

        $placeholders = @(
            $script:CopilotPathConstant.PlaceholderToolkitRoot,
            $script:CopilotPathConstant.PlaceholderSddRoot,
            $script:CopilotPathConstant.PlaceholderGuardrailsPath
        )
        $instructionsText = [System.IO.File]::ReadAllText($destinationInstructionsFile)
        foreach ($placeholder in $placeholders) {
            if ($instructionsText.Contains($placeholder)) {
                throw ($script:CopilotPublishMessage.PlaceholderUnresolved -f $placeholder, $destinationInstructionsFile)
            }
        }

        return [PSCustomObject]@{
            Success                    = $true
            Implemented                = $true
            CommandName                = 'Publish-Policy'
            WhatIf                     = $false
            Mode                       = $normalizedMode
            InstallRoot                = $resolvedInstallRoot
            InstructionsRoot           = $destinationInstructionsRoot
            CopilotInstructionsPath    = $destinationInstructionsFile
            SourceRoot                 = $sourcePolicyRoot
            RouterSourcePath           = $sourceRouterFile
            FilesCopied                = $filesCopied
            Message                    = ($script:CopilotPublishMessage.PolicyPublishedOk -f $filesCopied, $destinationInstructionsRoot, $normalizedMode)
            ExitCode                   = 0
            SmokeFilesystemOnlyNote    = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        }
    }
    finally {
        Exit-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
    }
}
