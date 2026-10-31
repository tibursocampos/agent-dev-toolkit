#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Claude Publish-Skills (copy core/skills + resolve placeholders).
#>

$script:ClaudeAdapterModuleDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ClaudeAdapterModuleDirectory)) {
    $script:ClaudeAdapterModuleDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load shared managed-tree helpers at script scope (dotsource inside a function
# would define commands only in that function's local scope).
$_claudeToolkitLibDirectory = Join-Path (
    Split-Path -Parent (Split-Path -Parent $script:ClaudeAdapterModuleDirectory)
) (Join-Path 'scripts' '_lib')
. (Join-Path $_claudeToolkitLibDirectory 'Copy-ToolkitManagedTree.ps1')
Remove-Variable -Name _claudeToolkitLibDirectory -ErrorAction SilentlyContinue

function Get-ClaudeAdapterRepoRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent (Split-Path -Parent $script:ClaudeAdapterModuleDirectory))
}

function Initialize-ClaudeToolkitManagedTreeLib {
    <#
    .SYNOPSIS
      No-op guard: Copy-ToolkitManagedTree.ps1 is loaded at script scope above.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name Invoke-ToolkitManagedSkillsPublish -ErrorAction SilentlyContinue)) {
        $libPath = Join-Path (Join-Path (Get-ClaudeAdapterRepoRoot) (Join-Path 'scripts' '_lib')) 'Copy-ToolkitManagedTree.ps1'
        throw ("Claude Publish-Skills: managed tree lib missing after script-scope load: {0}" -f $libPath)
    }
}

function Get-ClaudeNormalizedForwardSlashPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    return ($full -replace '\\', $script:ClaudePathConstant.PathSeparatorForwardSlash)
}

function Get-ClaudePlaceholderMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    $toolkitRoot = Get-ClaudeNormalizedForwardSlashPath -Path $InstallRoot
    $sddRoot = Get-ClaudeNormalizedForwardSlashPath -Path (Join-Path $InstallRoot $script:ClaudePathConstant.SddDirectoryName)
    $guardrailsPath = Get-ClaudeNormalizedForwardSlashPath -Path (
        Join-Path (Join-Path $InstallRoot $script:ClaudePathConstant.RulesDirectoryName) $script:ClaudePathConstant.GuardrailsFileName
    )

    return [ordered]@{
        ($script:ClaudePathConstant.PlaceholderToolkitRoot)     = $toolkitRoot
        ($script:ClaudePathConstant.PlaceholderSddRoot)         = $sddRoot
        ($script:ClaudePathConstant.PlaceholderGuardrailsPath)  = $guardrailsPath
    }
}

function Get-ClaudeUnresolvedPlaceholderTokens {
    [CmdletBinding()]
    param()

    return @(
        $script:ClaudePathConstant.PlaceholderToolkitRoot,
        $script:ClaudePathConstant.PlaceholderSddRoot,
        $script:ClaudePathConstant.PlaceholderGuardrailsPath
    )
}

function Copy-ClaudeCoreSkillsTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceSkillsRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationSkillsRoot
    )

    Initialize-ClaudeToolkitManagedTreeLib
    return (Copy-ToolkitManagedTree -SourceRoot $SourceSkillsRoot -DestinationRoot $DestinationSkillsRoot)
}

function Resolve-ClaudePlaceholdersInTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    Initialize-ClaudeToolkitManagedTreeLib
    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $PlaceholderMap `
        -TextFileExtensionPattern $script:ClaudePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ClaudeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ClaudePublishMessage.PlaceholderUnresolved
}

function Assert-ClaudePlaceholdersResolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    # Resolve-ClaudePlaceholdersInTree already asserts; keep for callers that only assert.
    Initialize-ClaudeToolkitManagedTreeLib
    $identityMap = [ordered]@{}
    foreach ($token in (Get-ClaudeUnresolvedPlaceholderTokens)) {
        $identityMap[$token] = $token
    }

    Resolve-ToolkitPlaceholdersInTree `
        -RootPath $RootPath `
        -PlaceholderMap $identityMap `
        -TextFileExtensionPattern $script:ClaudePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ClaudeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ClaudePublishMessage.PlaceholderUnresolved
}

function Get-ClaudeSkillFrontmatterOverlayPath {
    [CmdletBinding()]
    param()

    return (Join-Path $script:ClaudeAdapterModuleDirectory $script:ClaudePathConstant.SkillFrontmatterOverlayFileName)
}

function Read-ClaudeSkillFrontmatterOverlay {
    <#
    .SYNOPSIS
      Load adapters/claude/skill-frontmatter.json (skill id -> Claude-only frontmatter fields).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $OverlayPath = (Get-ClaudeSkillFrontmatterOverlayPath)
    )

    if (-not (Test-Path -LiteralPath $OverlayPath -PathType Leaf)) {
        throw ($script:ClaudePublishMessage.SkillFrontmatterOverlayMissing -f $OverlayPath)
    }

    try {
        $document = [System.IO.File]::ReadAllText($OverlayPath) | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw ($script:ClaudePublishMessage.SkillFrontmatterOverlayInvalid -f $OverlayPath, $_.Exception.Message)
    }

    $skillsNode = $document.PSObject.Properties['skills']
    if ($null -eq $skillsNode) {
        throw ($script:ClaudePublishMessage.SkillFrontmatterOverlayInvalid -f $OverlayPath, "root object must contain 'skills'")
    }

    $overlay = [ordered]@{}
    foreach ($skillProperty in $skillsNode.Value.PSObject.Properties) {
        $fields = [ordered]@{}
        foreach ($fieldProperty in $skillProperty.Value.PSObject.Properties) {
            if ($script:ClaudeSkillFrontmatterAllowedKeys -notcontains $fieldProperty.Name) {
                throw ($script:ClaudePublishMessage.SkillFrontmatterOverlayInvalid -f $OverlayPath, ("skill '{0}' sets unsupported key '{1}'" -f $skillProperty.Name, $fieldProperty.Name))
            }
            $fields[$fieldProperty.Name] = $fieldProperty.Value
        }
        $overlay[$skillProperty.Name] = $fields
    }

    return $overlay
}

function ConvertTo-ClaudeFrontmatterScalar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($Value -is [bool]) {
        if ($Value) {
            return 'true'
        }
        return 'false'
    }

    $text = [string]$Value
    if ($text -match '[\r\n]') {
        throw ($script:ClaudePublishMessage.SkillFrontmatterOverlayInvalid -f 'skill-frontmatter.json', 'overlay values must be single-line')
    }

    return ('"{0}"' -f $text.Replace('\', '\\').Replace('"', '\"'))
}

function Split-ClaudeSkillFrontmatter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillText,

        [Parameter(Mandatory = $true)]
        [string] $SkillLabel
    )

    $match = [regex]::Match(
        $SkillText,
        '\A---\r?\n(?<frontmatter>.*?)\r?\n---[ \t]*\r?\n?',
        [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $match.Success) {
        throw ($script:ClaudePublishMessage.SkillFrontmatterMissing -f $SkillLabel)
    }

    return [PSCustomObject]@{
        Frontmatter = $match.Groups['frontmatter'].Value
        Body        = $SkillText.Substring($match.Length)
    }
}

function Test-ClaudeSkillFrontmatterStructure {
    <#
    .SYNOPSIS
      Restricted-subset YAML check for SKILL.md frontmatter (no parser dependency).

    .DESCRIPTION
      Accepts top-level `key: value` mappings with unique keys, indented continuation
      lines for block scalars, quoted or plain scalars without ': ' or ' #', and
      the value shapes used by toolkit skills. Returns problem strings; empty when valid.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $FrontmatterText
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    $seenKeys = @{}
    $currentKey = $null
    $lineNumber = 0

    foreach ($line in @($FrontmatterText -split '\r?\n')) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^\s*#') {
            continue
        }

        if ($line -match '^\s') {
            if ($null -eq $currentKey) {
                $problems.Add(("line {0}: indented content has no owning key" -f $lineNumber))
            }
            continue
        }

        if ($line -notmatch '^(?<key>[A-Za-z][A-Za-z0-9_-]*):(?<gap>\s+|$)(?<value>.*)$') {
            $problems.Add(("line {0}: expected 'key: value'" -f $lineNumber))
            $currentKey = $null
            continue
        }

        $key = $Matches['key']
        $value = $Matches['value'].Trim()
        $currentKey = $key

        if ($seenKeys.ContainsKey($key)) {
            $problems.Add(("line {0}: duplicate key '{1}'" -f $lineNumber, $key))
            continue
        }
        $seenKeys[$key] = $true

        if ($value -eq '' -or $value -match '^[>|][+-]?$') {
            continue
        }

        if ($value.StartsWith('"')) {
            $inner = if ($value.Length -ge 2 -and $value.EndsWith('"')) { $value.Substring(1, $value.Length - 2) } else { $null }
            if ($null -eq $inner -or $inner -match '(?<!\\)"') {
                $problems.Add(("line {0}: unterminated or unescaped double-quoted value for '{1}'" -f $lineNumber, $key))
            }
        }
        elseif ($value.StartsWith("'")) {
            $inner = if ($value.Length -ge 2 -and $value.EndsWith("'")) { $value.Substring(1, $value.Length - 2) } else { $null }
            if ($null -eq $inner -or (($inner -replace "''", '') -match "'")) {
                $problems.Add(("line {0}: unterminated single-quoted value for '{1}'" -f $lineNumber, $key))
            }
        }
        else {
            if ($value -match ':\s' -or $value -match '\s#' -or $value.EndsWith(':')) {
                $problems.Add(("line {0}: plain value for '{1}' contains ': ' or ' #'" -f $lineNumber, $key))
            }
            if ($value -match '^[\[\]{}&*!%@`,#]') {
                $problems.Add(("line {0}: plain value for '{1}' starts with an indicator character" -f $lineNumber, $key))
            }
        }

        if ($key -eq 'disable-model-invocation' -and $value -notin @('true', 'false')) {
            $problems.Add(("line {0}: 'disable-model-invocation' must be true or false" -f $lineNumber))
        }
        if ($key -eq 'name' -and $value.Trim('"', "'") -notmatch '^[a-z0-9][a-z0-9-]*$') {
            $problems.Add(("line {0}: 'name' must be lowercase letters, digits and hyphens" -f $lineNumber))
        }
    }

    return [string[]]$problems.ToArray()
}

function Merge-ClaudeSkillFrontmatterText {
    <#
    .SYNOPSIS
      Replace or append overlay fields in one SKILL.md frontmatter block; body is untouched.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillText,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Fields,

        [Parameter(Mandatory = $true)]
        [string] $SkillLabel
    )

    $newline = if ($SkillText.Contains("`r`n")) { "`r`n" } else { "`n" }
    $parts = Split-ClaudeSkillFrontmatter -SkillText $SkillText -SkillLabel $SkillLabel
    $lines = [System.Collections.Generic.List[string]]::new()
    if ($parts.Frontmatter.Length -gt 0) {
        $lines.AddRange([string[]]@($parts.Frontmatter -split '\r?\n'))
    }

    foreach ($key in @($Fields.Keys)) {
        $rendered = '{0}: {1}' -f $key, (ConvertTo-ClaudeFrontmatterScalar -Value $Fields[$key])
        $index = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match ('^{0}:(\s|$)' -f [regex]::Escape($key))) {
                $index = $i
                break
            }
        }

        if ($index -lt 0) {
            $lines.Add($rendered)
            continue
        }

        $end = $index + 1
        while ($end -lt $lines.Count -and $lines[$end] -match '^\s') {
            $end++
        }
        $lines.RemoveRange($index, $end - $index)
        $lines.Insert($index, $rendered)
    }

    $frontmatterText = $lines -join $newline
    $problems = @(Test-ClaudeSkillFrontmatterStructure -FrontmatterText $frontmatterText)
    if ($problems.Count -gt 0) {
        throw ($script:ClaudePublishMessage.SkillFrontmatterInvalid -f $SkillLabel, ($problems -join '; '))
    }

    return ('---' + $newline + $frontmatterText + $newline + '---' + $newline + $parts.Body)
}

function Invoke-ClaudeSkillFrontmatterOverlay {
    <#
    .SYNOPSIS
      Apply Claude-only frontmatter to published SKILL.md files under SkillsRoot.

    .OUTPUTS
      Full paths of the SKILL.md files rewritten.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot,

        [Parameter()]
        [string] $OverlayPath = (Get-ClaudeSkillFrontmatterOverlayPath)
    )

    $overlay = Read-ClaudeSkillFrontmatterOverlay -OverlayPath $OverlayPath
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $rewritten = [System.Collections.Generic.List[string]]::new()

    foreach ($skillId in @($overlay.Keys)) {
        $safeName = Assert-ToolkitManagedSkillName -SkillName $skillId
        $skillFile = Join-Path (Join-Path $SkillsRoot $safeName) $script:ClaudePathConstant.SkillManifestFileName
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            throw ($script:ClaudePublishMessage.SkillFrontmatterSkillMissing -f $skillId, $skillFile)
        }

        $text = [System.IO.File]::ReadAllText($skillFile)
        $merged = Merge-ClaudeSkillFrontmatterText -SkillText $text -Fields $overlay[$skillId] -SkillLabel $skillId
        [System.IO.File]::WriteAllText($skillFile, $merged, $utf8NoBom)
        $rewritten.Add([System.IO.Path]::GetFullPath($skillFile)) | Out-Null
    }

    return [string[]]$rewritten.ToArray()
}

function Invoke-ClaudePublishSkills {
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
        throw $script:ClaudePublishMessage.InstallRootRequired
    }

    $repoRoot = Get-ClaudeAdapterRepoRoot
    $libDir = Join-Path (Join-Path $repoRoot 'scripts') '_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')
    Initialize-ClaudeToolkitManagedTreeLib

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourceSkillsRoot = Join-Path (Join-Path $repoRoot $script:ClaudePathConstant.CoreDirectoryName) $script:ClaudePathConstant.SkillsDirectoryName
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.SkillsDirectoryName

    if (-not (Test-Path -LiteralPath $sourceSkillsRoot)) {
        throw ($script:ClaudePublishMessage.CoreSkillsMissing -f $sourceSkillsRoot)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success      = $true
            Implemented  = $true
            CommandName  = 'Publish-Skills'
            WhatIf       = $true
            InstallRoot  = $resolvedInstallRoot
            SkillsRoot   = $destinationSkillsRoot
            SourceRoot   = $sourceSkillsRoot
            FilesCopied  = 0
            Message      = ($script:ClaudePublishMessage.WhatIfOk -f $destinationSkillsRoot)
            ExitCode     = 0
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationSkillsRoot = Join-Path $resolvedInstallRoot $script:ClaudePathConstant.SkillsDirectoryName

    $placeholderMap = Get-ClaudePlaceholderMap -InstallRoot $resolvedInstallRoot
    $publishResult = Invoke-ToolkitManagedSkillsPublish `
        -SourceSkillsRoot $sourceSkillsRoot `
        -DestinationSkillsRoot $destinationSkillsRoot `
        -InstallRoot $resolvedInstallRoot `
        -PlaceholderMap $placeholderMap `
        -TextFileExtensionPattern $script:ClaudePathConstant.TextFileExtensionPattern `
        -UnresolvedTokens (Get-ClaudeUnresolvedPlaceholderTokens) `
        -UnresolvedMessageFormat $script:ClaudePublishMessage.PlaceholderUnresolved

    $inventoryLibDir = Join-Path $repoRoot (Join-Path 'scripts' '_lib')
    . (Join-Path $inventoryLibDir 'ToolkitManagedPublishInventory.ps1')
    Enter-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
    try {
        $rewrittenPaths = @(Invoke-ClaudeManagedReferenceRewrite -ManagedPaths @($script:ToolkitLastManagedCopyPaths.ToArray()) -RepoRoot $repoRoot -PlaceholderMap $placeholderMap)
        $overlaidPaths = @(Invoke-ClaudeSkillFrontmatterOverlay -SkillsRoot $destinationSkillsRoot)
        $inventoryPaths = @(@($rewrittenPaths) + @($overlaidPaths) | Select-Object -Unique)
        if ($inventoryPaths.Count -gt 0) {
            Update-ToolkitManagedCopyInventory -InstallRoot $resolvedInstallRoot -Paths $inventoryPaths
        }
    }
    finally {
        Exit-ToolkitFilesystemGate -RootPath $resolvedInstallRoot -LockFileName '.toolkit-managed-publish.lock'
    }

    return [PSCustomObject]@{
        Success     = $true
        Implemented = $true
        CommandName = 'Publish-Skills'
        WhatIf      = $false
        InstallRoot = $resolvedInstallRoot
        SkillsRoot  = $destinationSkillsRoot
        SourceRoot  = $sourceSkillsRoot
        FilesCopied = $publishResult.FilesCopied
        Message     = ($script:ClaudePublishMessage.PublishedOk -f $publishResult.FilesCopied, $destinationSkillsRoot)
        ExitCode    = 0
    }
}
