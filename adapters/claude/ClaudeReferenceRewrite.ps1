#Requires -Version 5.1
<#
.SYNOPSIS
  Claude publish-time reference rewrites shared by Publish-Policy, Publish-Skills, Publish-Agents, and Publish-Router.

.DESCRIPTION
  Convert-ClaudeMdcReferencesToMd: Cursor rule names `<name>.mdc` become `<name>.md`.
  Delegates to the shared implementation in adapters/_shared/MdcReferenceRewrite.ps1.

  Convert-ClaudeRepoSourcePathReferences: repo-source paths `core/skills/<path>` and
  `core/policy/<name>.md` become `{{TOOLKIT_ROOT}}/skills/<path>` and
  `{{TOOLKIT_ROOT}}/rules/<name>.md`, using the resolved toolkit root from the placeholder map.
  A path is rewritten only when its repo source exists and is published under that mapping.
  Other occurrences (missing paths, non-markdown policy files) are left unchanged.
#>

. (Join-Path $PSScriptRoot '../_shared/MdcReferenceRewrite.ps1')

function Convert-ClaudeMdcReferencesToMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text
    )

    return Convert-MdcReferencesToMd -Text $Text `
        -SourceExtension $script:ClaudePathConstant.CursorRuleExtension `
        -TargetExtension $script:ClaudePathConstant.MarkdownExtension
}

function Convert-ClaudeRepoSourcePathReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    $toolkitRoot = [string]$PlaceholderMap[$script:ClaudePathConstant.PlaceholderToolkitRoot]
    $pattern = '(?<![A-Za-z0-9_\-./])core/(skills|policy)/([A-Za-z0-9_\-./]*[A-Za-z0-9_\-])'
    $builder = New-Object System.Text.StringBuilder
    $position = 0

    foreach ($match in [regex]::Matches($Text, $pattern)) {
        $section = $match.Groups[1].Value
        $relative = $match.Groups[2].Value
        $repoRelative = 'core/{0}/{1}' -f $section, $relative
        $repoPath = Join-Path $RepoRoot ($repoRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)

        $replacement = $null
        if (Test-Path -LiteralPath $repoPath) {
            if ($section -eq 'skills') {
                $replacement = "$toolkitRoot/skills/$relative"
            }
            elseif ($relative.EndsWith('.md', [System.StringComparison]::Ordinal)) {
                $replacement = "$toolkitRoot/rules/$relative"
            }
        }

        if ($null -ne $replacement) {
            [void]$builder.Append($Text, $position, $match.Index - $position)
            [void]$builder.Append($replacement)
            $position = $match.Index + $match.Length
        }
    }

    [void]$builder.Append($Text, $position, $Text.Length - $position)
    return $builder.ToString()
}

function Convert-ClaudeMdcReferencesInFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $Files
    )

    return @(Convert-MdcReferencesInFiles -Files $Files `
            -SourceExtension $script:ClaudePathConstant.CursorRuleExtension `
            -TargetExtension $script:ClaudePathConstant.MarkdownExtension)
}

function Convert-ClaudeRepoSourcePathReferencesInFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $Files,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $textPattern = $script:ClaudePathConstant.TextFileExtensionPattern
    $changedPaths = New-Object System.Collections.Generic.List[string]
    foreach ($file in $Files) {
        if (-not [System.IO.File]::Exists($file)) { continue }
        if ($file -notmatch $textPattern) { continue }

        $text = [System.IO.File]::ReadAllText($file)
        $updated = Convert-ClaudeRepoSourcePathReferences -Text $text -RepoRoot $RepoRoot -PlaceholderMap $PlaceholderMap
        if (-not [string]::Equals($updated, $text, [System.StringComparison]::Ordinal)) {
            [System.IO.File]::WriteAllText($file, $updated, $utf8NoBom)
            $changedPaths.Add([System.IO.Path]::GetFullPath($file)) | Out-Null
        }
    }

    return @($changedPaths.ToArray())
}

function Invoke-ClaudeManagedReferenceRewrite {
    <#
    .SYNOPSIS
      Apply Claude reference rewrites to managed skill or agent files; returns changed full paths.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $ManagedPaths,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    $markdownPaths = @($ManagedPaths | Where-Object { $_ -like '*.md' })
    $changed = New-Object System.Collections.Generic.List[string]
    foreach ($path in @(Convert-ClaudeMdcReferencesInFiles -Files $markdownPaths)) { $changed.Add($path) | Out-Null }
    foreach ($path in @(Convert-ClaudeRepoSourcePathReferencesInFiles -Files $ManagedPaths -RepoRoot $RepoRoot -PlaceholderMap $PlaceholderMap)) { $changed.Add($path) | Out-Null }

    return @($changed.ToArray() | Select-Object -Unique)
}
