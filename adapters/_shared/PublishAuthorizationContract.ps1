#Requires -Version 5.1

function Assert-ToolkitAuthorizationContractSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Authorization contract source is missing: $SourcePath"
    }

    try {
        $contract = Get-Content -LiteralPath $SourcePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Authorization contract source is invalid JSON: $SourcePath. $($_.Exception.Message)"
    }

    if ($null -eq $contract -or $contract.schemaVersion -ne 1 -or $null -eq $contract.authorizations) {
        throw "Authorization contract source is invalid: expected schemaVersion 1 and authorizations: $SourcePath"
    }

    $authorizations = @($contract.authorizations)
    if ($authorizations.Count -eq 0) {
        throw "Authorization contract source is invalid: authorizations cannot be empty: $SourcePath"
    }

    foreach ($authorization in $authorizations) {
        if ($null -eq $authorization -or
            $null -eq $authorization.PSObject.Properties['effect'] -or
            $null -eq $authorization.PSObject.Properties['scope'] -or
            [string]::IsNullOrWhiteSpace([string]$authorization.effect) -or
            [string]::IsNullOrWhiteSpace([string]$authorization.scope)) {
            throw "Authorization contract source is invalid: every authorization needs effect and scope: $SourcePath"
        }
    }

    return $contract
}

function Copy-ToolkitAuthorizationContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath,

        [Parameter(Mandatory = $true)]
        [string] $DestinationPath,

        [Parameter()]
        [string] $InstallRoot,

        [Parameter()]
        [string] $RelativePath
    )

    $null = Assert-ToolkitAuthorizationContractSource -SourcePath $SourcePath
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot) -and [string]::IsNullOrWhiteSpace($RelativePath)) {
        $rootFull = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
        $destinationFull = [System.IO.Path]::GetFullPath($DestinationPath)
        $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
        if (-not $destinationFull.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Authorization contract destination is outside InstallRoot: $DestinationPath"
        }
        $RelativePath = $destinationFull.Substring($rootPrefix.Length) -replace '\\', '/'
    }
    $copyParameters = @{
        SourcePath      = $SourcePath
        DestinationPath = $DestinationPath
    }
    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) { $copyParameters.InstallRoot = $InstallRoot }
    if (-not [string]::IsNullOrWhiteSpace($RelativePath)) { $copyParameters.RelativePath = $RelativePath }
    $null = Copy-ToolkitFileIfAbsent @copyParameters
    return $DestinationPath
}
