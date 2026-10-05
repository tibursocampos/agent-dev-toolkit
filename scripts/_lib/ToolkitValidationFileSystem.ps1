#Requires -Version 5.1
<#
.SYNOPSIS
  Shared file-system helpers for validation scripts.

.DESCRIPTION
  These helpers deliberately read the file system on every invocation. They
  do not retain enumeration, text, or fingerprint results because validation
  targets may be mutation-sensitive during a single run.
#>

function Get-ToolkitValidationFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Root,

        [Parameter()]
        [string[]] $Extensions,

        [Parameter()]
        [string] $Filter = '*',

        [Parameter()]
        [switch] $Recurse
    )

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "Validation file root is not a directory: $Root"
    }

    $rootItem = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Validation file root is a reparse point: $Root"
    }

    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $directories = New-Object System.Collections.Generic.Stack[System.IO.DirectoryInfo]
    $directories.Push([System.IO.DirectoryInfo]$rootItem)

    do {
        $directory = $directories.Pop()

        foreach ($file in @(Get-ChildItem -LiteralPath $directory.FullName -File -Filter $Filter -ErrorAction Stop)) {
            if (($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
                $files.Add([System.IO.FileInfo]$file)
            }
        }

        if ($Recurse.IsPresent) {
            foreach ($childDirectory in @(Get-ChildItem -LiteralPath $directory.FullName -Directory -ErrorAction Stop)) {
                if (($childDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
                    $directories.Push([System.IO.DirectoryInfo]$childDirectory)
                }
            }
        }
    } while ($directories.Count -gt 0)

    if ($null -eq $Extensions -or $Extensions.Count -eq 0) {
        return @($files)
    }

    $normalizedExtensions = @($Extensions | ForEach-Object {
        $extension = [string]$_
        if (-not $extension.StartsWith('.')) { $extension = ".{0}" -f $extension }
        $extension.ToLowerInvariant()
    })

    return @($files | Where-Object { $normalizedExtensions -contains $_.Extension.ToLowerInvariant() })
}

function Read-ToolkitValidationText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter()]
        [System.Text.Encoding] $Encoding = ([System.Text.UTF8Encoding]::new($false))
    )

    return [System.IO.File]::ReadAllText($Path, $Encoding)
}

function Get-ToolkitValidationFileFingerprint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop
    return [string]$hash.Hash
}
