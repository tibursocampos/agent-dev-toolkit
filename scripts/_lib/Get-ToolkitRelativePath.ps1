function Get-ToolkitRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $BasePath,
        [Parameter(Mandatory = $true)][string] $TargetPath
    )

    $base = [System.IO.Path]::GetFullPath($BasePath)
    $target = [System.IO.Path]::GetFullPath($TargetPath)
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $baseRoot = [System.IO.Path]::GetPathRoot($base)
    $targetRoot = [System.IO.Path]::GetPathRoot($target)
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }
    if (-not $baseRoot.Equals($targetRoot, $comparison)) { return $target }

    $baseParts = @($base.Substring($baseRoot.Length).Trim('\','/') -split '[\\/]+' | Where-Object { $_ })
    $targetParts = @($target.Substring($targetRoot.Length).Trim('\','/') -split '[\\/]+' | Where-Object { $_ })
    $common = 0
    while ($common -lt $baseParts.Count -and $common -lt $targetParts.Count -and
        $baseParts[$common].Equals($targetParts[$common], $comparison)) { $common++ }

    $relativeParts = @()
    for ($index = $common; $index -lt $baseParts.Count; $index++) { $relativeParts += '..' }
    for ($index = $common; $index -lt $targetParts.Count; $index++) { $relativeParts += $targetParts[$index] }
    if ($relativeParts.Count -eq 0) { return '.' }
    return [string]::Join([string]$separator, [string[]]$relativeParts)
}
