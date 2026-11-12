#Requires -Version 7.0
[CmdletBinding()]
param(
    [string] $RepoPath,
    [string] $InputJson,
    [string] $InputPath,
    [string] $AliasCatalogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\DeliveryInputSources.ps1')

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    [Console]::Error.WriteLine('RepoPath is required.')
    exit 1
}
$hasJson = -not [string]::IsNullOrWhiteSpace($InputJson)
$hasPath = -not [string]::IsNullOrWhiteSpace($InputPath)
if ($hasJson -eq $hasPath) {
    [Console]::Error.WriteLine('Exactly one of InputJson or InputPath is required.')
    exit 1
}
if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
    [Console]::Error.WriteLine('RepoPath must be an existing directory.')
    exit 1
}
$repoFull = [System.IO.Path]::GetFullPath($RepoPath)

$jsonText = $InputJson
if ($hasPath) {
    $inputFull = $null
    try {
        if ([System.IO.Path]::IsPathFullyQualified($InputPath)) {
            $inputFull = [System.IO.Path]::GetFullPath($InputPath)
        }
        else {
            $inputFull = (Resolve-DeliveryContainedPath -Root $repoFull -Relative $InputPath.Replace('\', '/')).Full
        }
    }
    catch {
        $inputFull = $null
    }
    if (($null -eq $inputFull) -or -not (Test-Path -LiteralPath $inputFull -PathType Leaf)) {
        [Console]::Error.WriteLine('InputPath must reference an existing file.')
        exit 1
    }
    try {
        $jsonText = [System.IO.File]::ReadAllText($inputFull, [System.Text.UTF8Encoding]::new($false))
    }
    catch {
        [Console]::Error.WriteLine('InputPath cannot be read.')
        exit 1
    }
}

try {
    $inputObject = ConvertFrom-Json -InputObject $jsonText -ErrorAction Stop
}
catch {
    [Console]::Error.WriteLine('Input is not valid JSON.')
    exit 1
}

$response = $null
$unexpected = $false
try {
    $identity = Get-DeliveryInputSourceIdentity -RepoRoot $repoFull -Input $inputObject -AliasCatalogPath $AliasCatalogPath
    $response = [ordered]@{ ok = $true; identity = $identity }
}
catch {
    $match = [regex]::Match($_.Exception.Message, '\A([a-z_]+): (.*)\z', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($match.Success -and ((Get-DeliveryInputErrorCodes) -contains $match.Groups[1].Value)) {
        $response = [ordered]@{ ok = $false; reason = $match.Groups[1].Value; message = $match.Groups[2].Value }
    }
    else {
        $unexpected = $true
    }
}

if ($unexpected) {
    [Console]::Error.WriteLine('Input source could not be resolved due to an unexpected failure.')
    exit 1
}

[Console]::Out.WriteLine(($response | ConvertTo-Json -Compress))
if ($response.ok) { exit 0 }
exit 3
