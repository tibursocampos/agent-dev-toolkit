#Requires -Version 5.1
<#
.SYNOPSIS
  Publish-time rewrite of Cursor rule references (`<name>.mdc`) to Markdown rule references (`<name>.md`).

.DESCRIPTION
  Core sources name rules with the Cursor extension. Adapters that publish Markdown rules
  (Claude, Codex) rewrite those references so they match the published rule files.
  The match must follow a name character, so prose that names the extension (for example
  "publishes `.mdc`") is kept.
#>

function Convert-MdcReferencesToMd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $SourceExtension,

        [Parameter(Mandatory = $true)]
        [string] $TargetExtension
    )

    $pattern = '(?<=[A-Za-z0-9_\-])' + [regex]::Escape($SourceExtension) + '(?![A-Za-z0-9_])'
    return [regex]::Replace($Text, $pattern, $TargetExtension.Replace('$', '$$'))
}

function Convert-MdcReferencesInFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $Files,

        [Parameter(Mandatory = $true)]
        [string] $SourceExtension,

        [Parameter(Mandatory = $true)]
        [string] $TargetExtension
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $changedPaths = New-Object System.Collections.Generic.List[string]
    foreach ($file in $Files) {
        if (-not [System.IO.File]::Exists($file)) { continue }
        if ([System.IO.Path]::GetExtension($file) -ne $TargetExtension) { continue }

        $text = [System.IO.File]::ReadAllText($file)
        $updated = Convert-MdcReferencesToMd -Text $text -SourceExtension $SourceExtension -TargetExtension $TargetExtension
        if (-not [string]::Equals($updated, $text, [System.StringComparison]::Ordinal)) {
            [System.IO.File]::WriteAllText($file, $updated, $utf8NoBom)
            $changedPaths.Add([System.IO.Path]::GetFullPath($file)) | Out-Null
        }
    }

    return @($changedPaths.ToArray())
}

function Invoke-ToolkitManagedMdcReferenceRewrite {
    <#
    .SYNOPSIS
      Rewrite rule references in the files recorded by the last managed copy, then refresh their inventory hashes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter(Mandatory = $true)]
        [string] $SourceExtension,

        [Parameter(Mandatory = $true)]
        [string] $TargetExtension
    )

    if ($null -eq $script:ToolkitLastManagedCopyPaths -or $script:ToolkitLastManagedCopyPaths.Count -eq 0) {
        return @()
    }

    Enter-ToolkitFilesystemGate -RootPath $InstallRoot -LockFileName '.toolkit-managed-publish.lock'
    try {
        $changedPaths = @(Convert-MdcReferencesInFiles `
                -Files @($script:ToolkitLastManagedCopyPaths.ToArray()) `
                -SourceExtension $SourceExtension `
                -TargetExtension $TargetExtension)
        if ($changedPaths.Count -gt 0) {
            Update-ToolkitManagedCopyInventory -InstallRoot $InstallRoot -Paths $changedPaths
        }
        return $changedPaths
    }
    finally {
        Exit-ToolkitFilesystemGate -RootPath $InstallRoot -LockFileName '.toolkit-managed-publish.lock'
    }
}
