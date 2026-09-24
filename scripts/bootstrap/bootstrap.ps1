#Requires -Version 5.1
<#
.SYNOPSIS
  Download toolkit Release zip via HTTPS, verify SHA256 (TE01), extract, then hand off to sync-agent.

.DESCRIPTION
  Happy path uses only HTTPS URLs under .../releases/latest/download/...
  (curl.exe or Invoke-WebRequest). Checksum mismatch exits non-zero with no extract
  and no sync-agent/toolkit handoff (TE01).

  After a successful -Extract into the local cache, invokes portable
  scripts/sync-agent.ps1 (Release entrypoint → sync only; does not replace Smart Manager).
  Use -SyncWhatIf for observable smoke without live Publish writes.
  Use -SkipSync to stop after extract (tests / extract-only).

  Release zip / checksum asset names are NOT permanent SoT here — pass
  -ZipAssetName / -ChecksumAssetName or env TOOLKIT_RELEASE_ZIP_ASSET /
  TOOLKIT_RELEASE_CHECKSUM_ASSET. Confirm vs CI before treating names as final.

.PARAMETER Owner
  GitHub owner. Default: env TOOLKIT_RELEASE_OWNER or tibursocampos.

.PARAMETER Repo
  GitHub repo. Default: env TOOLKIT_RELEASE_REPO or agent-dev-toolkit.

.PARAMETER ZipAssetName
  Release asset file name for the zip. Required for network download unless
  -LocalZipPath is set. Confirm vs CI — not hard-coded as permanent SoT.

.PARAMETER ChecksumAssetName
  Optional sidecar checksum asset on the same latest/download URL.
  Confirm vs CI. Ignored when -ExpectedSha256 is provided.

.PARAMETER ExpectedSha256
  Hex SHA256 expected for the zip (test / override). When set, checksum download
  is skipped.

.PARAMETER LocalZipPath
  Offline / smoke path: skip download; verify this zip against ExpectedSha256
  or a local -ChecksumFile.

.PARAMETER ChecksumFile
  Local checksum file (SHA256 hex, optionally "hash  filename").

.PARAMETER CacheDir
  Directory for downloaded assets (default: under TEMP).

.PARAMETER Extract
  When set and checksum matches, extract zip into CacheDir\extracted, then
  invoke sync-agent unless -SkipSync.

.PARAMETER SkipDownload
  With -LocalZipPath: skip network entirely (explicit smoke / TE01 mode).

.PARAMETER Agent
  Registry agent id forwarded to sync-agent.ps1. Default: env TOOLKIT_SYNC_AGENT
  or cursor (INSTALL examples).

.PARAMETER SkipSync
  After successful extract, do not invoke sync-agent (extract-only / TE01 pairing).

.PARAMETER SyncWhatIf
  Forward -WhatIf to sync-agent.ps1 (observable handoff; safe smoke).

.PARAMETER InstallRoot
  Forwarded to sync-agent.ps1 when sync runs.

.PARAMETER AllowUserHome
  Forwarded to sync-agent.ps1 when sync runs.

.PARAMETER Mode
  Forwarded to sync-agent.ps1 (required for -Agent copilot).

.PARAMETER UserScope
  Forwarded to sync-agent.ps1 when sync runs.

.EXAMPLE
  $env:TOOLKIT_RELEASE_ZIP_ASSET = '<confirm-vs-CI>.zip'
  pwsh -NoProfile -File .\scripts\bootstrap\bootstrap.ps1 -Extract -Agent cursor -SyncWhatIf

.EXAMPLE
  # TE01 smoke without network — mismatch must not call sync
  pwsh -NoProfile -File .\scripts\bootstrap\bootstrap.ps1 `
    -LocalZipPath .\sample.zip -ExpectedSha256 '00'*32 -SkipDownload -Extract
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $Owner,

    [Parameter()]
    [string] $Repo,

    [Parameter()]
    [string] $ZipAssetName,

    [Parameter()]
    [string] $ChecksumAssetName,

    [Parameter()]
    [string] $ExpectedSha256,

    [Parameter()]
    [string] $LocalZipPath,

    [Parameter()]
    [string] $ChecksumFile,

    [Parameter()]
    [string] $CacheDir,

    [Parameter()]
    [switch] $Extract,

    [Parameter()]
    [switch] $SkipDownload,

    [Parameter()]
    [string] $Agent,

    [Parameter()]
    [switch] $SkipSync,

    [Parameter()]
    [switch] $SyncWhatIf,

    [Parameter()]
    [string] $InstallRoot,

    [Parameter()]
    [switch] $AllowUserHome,

    [Parameter()]
    [string] $Mode,

    [Parameter()]
    [switch] $UserScope
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- named constants (no magic literals in happy-path logic) ---
$script:BootstrapConstant = @{
    HttpsSchemePrefix              = 'https://'
    ForbiddenHttpSchemePrefix      = 'http://'
    GitHubHost                     = 'github.com'
    ReleasesLatestDownloadSegment  = 'releases/latest/download'
    DefaultOwner                   = 'tibursocampos'
    DefaultRepo                    = 'agent-dev-toolkit'
    DefaultSyncAgent               = 'cursor'
    EnvOwner                       = 'TOOLKIT_RELEASE_OWNER'
    EnvRepo                        = 'TOOLKIT_RELEASE_REPO'
    EnvZipAsset                    = 'TOOLKIT_RELEASE_ZIP_ASSET'
    EnvChecksumAsset               = 'TOOLKIT_RELEASE_CHECKSUM_ASSET'
    EnvSyncAgent                   = 'TOOLKIT_SYNC_AGENT'
    CacheFolderName                = 'agent-dev-toolkit-bootstrap'
    ExtractedFolderName            = 'extracted'
    SyncAgentRelativePath          = 'scripts/sync-agent.ps1'
    SyncAgentFileName              = 'sync-agent.ps1'
    ScriptsFolderName              = 'scripts'
    Sha256Algorithm                = 'SHA256'
    HexHashPattern                 = '^[0-9a-fA-F]{64}$'
    IwrMaximumRedirectionCount     = 0
    # confirm vs CI — placeholders only; never treat as permanent Release SoT
    ConfirmVsCiNote                = 'confirm vs CI'
}

$script:BootstrapMessage = @{
    HttpUrlRejected                = 'Bootstrap happy path allows HTTPS only. Rejected URL: {0}'
    ZipAssetRequired               = 'ZipAssetName (or env {0}) is required for network download. Asset name = {1} — do not invent a permanent SoT name.'
    ExpectedHashRequired           = 'ExpectedSha256 or ChecksumAssetName/ChecksumFile is required to verify the zip.'
    ChecksumMismatch               = 'SHA256 mismatch (TE01). Expected={0} Actual={1}. Aborting without extract or sync.'
    ChecksumOk                     = 'SHA256 verified for {0}'
    DownloadStart                  = 'Downloading {0}'
    ExtractSkipped                 = 'Checksum OK; extract not requested (-Extract omitted). Sync handoff not invoked.'
    ExtractDone                    = 'Extracted to {0}.'
    SyncSkippedExplicit            = 'Extract OK; sync skipped (-SkipSync).'
    SyncSkippedNoExtract           = 'Sync handoff requires successful -Extract. Not invoked.'
    SyncInvokeStart                = 'Invoking sync handoff: {0} -Agent {1}{2}'
    SyncInvokeDone                 = 'Sync handoff completed (exit {0}).'
    SyncInvokeFailed               = 'Sync handoff failed (exit {0}).'
    SyncScriptMissing              = 'sync-agent.ps1 not found. Looked under extract ({0}) and repo ({1}).'
    SyncHostMissing                = 'Neither pwsh nor powershell found to invoke sync-agent.ps1.'
    LocalZipMissing                = 'LocalZipPath not found: {0}'
    InvalidHashFormat              = 'Expected SHA256 must be 64 hex chars. Got: {0}'
    CurlFailed                     = 'curl.exe failed for {0} (exit {1})'
    IwrFailed                      = 'Invoke-WebRequest failed for {0}: {1}'
    IwrRedirectRejected            = 'Invoke-WebRequest redirected away from HTTPS (or AbsoluteUri missing). Rejected final URI: {0}'
    WhatIfSuffix                   = ' -WhatIf'
}

function Get-BootstrapEnvOrDefault {
    param(
        [string] $EnvName,
        [string] $ParamValue,
        [string] $DefaultValue
    )
    if (-not [string]::IsNullOrWhiteSpace($ParamValue)) {
        return $ParamValue.Trim()
    }
    $fromEnv = [Environment]::GetEnvironmentVariable($EnvName)
    if (-not [string]::IsNullOrWhiteSpace($fromEnv)) {
        return $fromEnv.Trim()
    }
    return $DefaultValue
}

function Assert-BootstrapHttpsUrl {
    param([Parameter(Mandatory = $true)][string] $Url)
    $trimmed = $Url.Trim()
    $https = $script:BootstrapConstant.HttpsSchemePrefix
    $http = $script:BootstrapConstant.ForbiddenHttpSchemePrefix
    if ($trimmed.StartsWith($http, [System.StringComparison]::OrdinalIgnoreCase) -and
        -not $trimmed.StartsWith($https, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ($script:BootstrapMessage.HttpUrlRejected -f $trimmed)
    }
    if (-not $trimmed.StartsWith($https, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ($script:BootstrapMessage.HttpUrlRejected -f $trimmed)
    }
}

function New-BootstrapLatestDownloadUrl {
    param(
        [Parameter(Mandatory = $true)][string] $OwnerName,
        [Parameter(Mandatory = $true)][string] $RepoName,
        [Parameter(Mandatory = $true)][string] $AssetName
    )
    $https = $script:BootstrapConstant.HttpsSchemePrefix
    $hostName = $script:BootstrapConstant.GitHubHost
    $segment = $script:BootstrapConstant.ReleasesLatestDownloadSegment
    $url = '{0}{1}/{2}/{3}/{4}/{5}' -f $https, $hostName, $OwnerName, $RepoName, $segment, $AssetName
    Assert-BootstrapHttpsUrl -Url $url
    return $url
}

function Save-BootstrapRemoteFile {
    param(
        [Parameter(Mandatory = $true)][string] $Url,
        [Parameter(Mandatory = $true)][string] $DestinationPath
    )
    Assert-BootstrapHttpsUrl -Url $Url
    Write-Host ($script:BootstrapMessage.DownloadStart -f $Url)

    $destDir = Split-Path -Parent $DestinationPath
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($null -ne $curl) {
        & curl.exe -fsSL --proto '=https' -o $DestinationPath $Url
        if ($LASTEXITCODE -ne 0) {
            throw ($script:BootstrapMessage.CurlFailed -f $Url, $LASTEXITCODE)
        }
        return
    }

    # Match curl --proto =https: never follow redirects to http:// (MaximumRedirection 0),
    # then re-validate AbsoluteUri with Assert-BootstrapHttpsUrl before accepting the file.
    try {
        $maxRedirect = [int]$script:BootstrapConstant.IwrMaximumRedirectionCount
        $response = Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing -MaximumRedirection $maxRedirect
        $finalUri = $Url
        if ($null -ne $response -and $null -ne $response.BaseResponse -and $null -ne $response.BaseResponse.ResponseUri) {
            $finalUri = [string]$response.BaseResponse.ResponseUri.AbsoluteUri
        }
        Assert-BootstrapHttpsUrl -Url $finalUri
    }
    catch {
        $msg = $_.Exception.Message
        # PowerShell often surfaces redirect-as-error when MaximumRedirection is 0.
        if ($msg -match '(?i)redirect|maximum redirection') {
            throw ($script:BootstrapMessage.IwrRedirectRejected -f $Url)
        }
        throw ($script:BootstrapMessage.IwrFailed -f $Url, $msg)
    }
}

function Get-BootstrapSha256Hex {
    param([Parameter(Mandatory = $true)][string] $FilePath)
    $hash = Get-FileHash -LiteralPath $FilePath -Algorithm $script:BootstrapConstant.Sha256Algorithm
    return $hash.Hash.ToLowerInvariant()
}

function Read-BootstrapExpectedSha256 {
    param(
        [string] $ExpectedHex,
        [string] $ChecksumFilePath
    )
    if (-not [string]::IsNullOrWhiteSpace($ExpectedHex)) {
        $hex = $ExpectedHex.Trim()
        if ($hex -notmatch $script:BootstrapConstant.HexHashPattern) {
            throw ($script:BootstrapMessage.InvalidHashFormat -f $hex)
        }
        return $hex.ToLowerInvariant()
    }

    if ([string]::IsNullOrWhiteSpace($ChecksumFilePath) -or -not (Test-Path -LiteralPath $ChecksumFilePath)) {
        throw $script:BootstrapMessage.ExpectedHashRequired
    }

    $raw = (Get-Content -LiteralPath $ChecksumFilePath -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw $script:BootstrapMessage.ExpectedHashRequired
    }

    $firstToken = ($raw -split '\s+')[0]
    if ($firstToken -notmatch $script:BootstrapConstant.HexHashPattern) {
        throw ($script:BootstrapMessage.InvalidHashFormat -f $firstToken)
    }
    return $firstToken.ToLowerInvariant()
}

function Test-BootstrapChecksumOrThrow {
    param(
        [Parameter(Mandatory = $true)][string] $ZipPath,
        [Parameter(Mandatory = $true)][string] $ExpectedHex
    )
    $actual = Get-BootstrapSha256Hex -FilePath $ZipPath
    $expected = $ExpectedHex.ToLowerInvariant()
    if ($actual -ne $expected) {
        throw ($script:BootstrapMessage.ChecksumMismatch -f $expected, $actual)
    }
    Write-Host ($script:BootstrapMessage.ChecksumOk -f $ZipPath)
}

function Expand-BootstrapZipIfRequested {
    param(
        [Parameter(Mandatory = $true)][string] $ZipPath,
        [Parameter(Mandatory = $true)][string] $DestinationDir,
        [Parameter(Mandatory = $true)][bool] $DoExtract
    )
    if (-not $DoExtract) {
        Write-Host $script:BootstrapMessage.ExtractSkipped
        return $false
    }
    if (Test-Path -LiteralPath $DestinationDir) {
        Remove-Item -LiteralPath $DestinationDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $DestinationDir -Force
    Write-Host ($script:BootstrapMessage.ExtractDone -f $DestinationDir)
    return $true
}

function Resolve-BootstrapSyncScriptPath {
    param(
        [string] $ExtractDir,
        [Parameter(Mandatory = $true)][string] $BootstrapScriptDir
    )
    $scriptsFolder = $script:BootstrapConstant.ScriptsFolderName
    $syncFile = $script:BootstrapConstant.SyncAgentFileName
    $relativePortable = $script:BootstrapConstant.SyncAgentRelativePath

    $fromExtract = $null
    if (-not [string]::IsNullOrWhiteSpace($ExtractDir)) {
        $candidate = Join-Path $ExtractDir (Join-Path $scriptsFolder $syncFile)
        if (Test-Path -LiteralPath $candidate) {
            $fromExtract = (Resolve-Path -LiteralPath $candidate).Path
        }
        else {
            # Release zip may nest one folder (repo-name-tag/); probe one level.
            $nested = Get-ChildItem -LiteralPath $ExtractDir -Directory -ErrorAction SilentlyContinue |
                ForEach-Object {
                    Join-Path $_.FullName (Join-Path $scriptsFolder $syncFile)
                } |
                Where-Object { Test-Path -LiteralPath $_ } |
                Select-Object -First 1
            if (-not [string]::IsNullOrWhiteSpace($nested)) {
                $fromExtract = (Resolve-Path -LiteralPath $nested).Path
            }
        }
    }

    # bootstrap lives at scripts/bootstrap/ → sibling sync-agent is scripts/sync-agent.ps1
    $scriptsDir = Split-Path -Parent $BootstrapScriptDir
    $fromRepo = Join-Path $scriptsDir $syncFile

    if (-not [string]::IsNullOrWhiteSpace($fromExtract)) {
        return $fromExtract
    }
    if (Test-Path -LiteralPath $fromRepo) {
        return (Resolve-Path -LiteralPath $fromRepo).Path
    }

    throw ($script:BootstrapMessage.SyncScriptMissing -f $relativePortable, $fromRepo)
}

function Invoke-BootstrapSyncHandoff {
    param(
        [Parameter(Mandatory = $true)][string] $ExtractDir,
        [Parameter(Mandatory = $true)][string] $BootstrapScriptDir,
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter(Mandatory = $true)][bool] $DoWhatIf,
        [string] $SyncInstallRoot,
        [Parameter(Mandatory = $true)][bool] $DoAllowUserHome,
        [string] $SyncMode,
        [Parameter(Mandatory = $true)][bool] $DoUserScope
    )
    $syncPath = Resolve-BootstrapSyncScriptPath -ExtractDir $ExtractDir -BootstrapScriptDir $BootstrapScriptDir
    $whatIfNote = if ($DoWhatIf) { $script:BootstrapMessage.WhatIfSuffix } else { '' }
    Write-Host ($script:BootstrapMessage.SyncInvokeStart -f $script:BootstrapConstant.SyncAgentRelativePath, $AgentId, $whatIfNote)

    # Child host so sync-agent `exit` does not tear down bootstrap mid-handoff.
    $runner = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($null -eq $runner) {
        $runner = Get-Command powershell -ErrorAction SilentlyContinue
    }
    if ($null -eq $runner) {
        throw $script:BootstrapMessage.SyncHostMissing
    }

    $argList = New-Object System.Collections.Generic.List[string]
    [void]$argList.Add('-NoProfile')
    [void]$argList.Add('-File')
    [void]$argList.Add($syncPath)
    [void]$argList.Add('-Agent')
    [void]$argList.Add($AgentId)
    if ($DoWhatIf) {
        [void]$argList.Add('-WhatIf')
    }
    if (-not [string]::IsNullOrWhiteSpace($SyncInstallRoot)) {
        [void]$argList.Add('-InstallRoot')
        [void]$argList.Add($SyncInstallRoot)
    }
    if ($DoAllowUserHome) {
        [void]$argList.Add('-AllowUserHome')
    }
    if (-not [string]::IsNullOrWhiteSpace($SyncMode)) {
        [void]$argList.Add('-Mode')
        [void]$argList.Add($SyncMode)
    }
    if ($DoUserScope) {
        [void]$argList.Add('-UserScope')
    }

    # Portable path scripts/sync-agent.ps1 — do not rewrite sync-agent / toolkit internals.
    & $runner.Source @($argList.ToArray())
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }
    if ($exitCode -ne 0) {
        throw ($script:BootstrapMessage.SyncInvokeFailed -f $exitCode)
    }
    Write-Host ($script:BootstrapMessage.SyncInvokeDone -f $exitCode)
}

# --- resolve inputs ---
$resolvedOwner = Get-BootstrapEnvOrDefault -EnvName $script:BootstrapConstant.EnvOwner -ParamValue $Owner -DefaultValue $script:BootstrapConstant.DefaultOwner
$resolvedRepo = Get-BootstrapEnvOrDefault -EnvName $script:BootstrapConstant.EnvRepo -ParamValue $Repo -DefaultValue $script:BootstrapConstant.DefaultRepo
$resolvedZipAsset = Get-BootstrapEnvOrDefault -EnvName $script:BootstrapConstant.EnvZipAsset -ParamValue $ZipAssetName -DefaultValue ''
$resolvedChecksumAsset = Get-BootstrapEnvOrDefault -EnvName $script:BootstrapConstant.EnvChecksumAsset -ParamValue $ChecksumAssetName -DefaultValue ''
$resolvedAgent = Get-BootstrapEnvOrDefault -EnvName $script:BootstrapConstant.EnvSyncAgent -ParamValue $Agent -DefaultValue $script:BootstrapConstant.DefaultSyncAgent

if ([string]::IsNullOrWhiteSpace($CacheDir)) {
    $CacheDir = Join-Path ([System.IO.Path]::GetTempPath()) $script:BootstrapConstant.CacheFolderName
}
if (-not (Test-Path -LiteralPath $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

$zipPath = $null
$checksumPath = $ChecksumFile
$bootstrapScriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($bootstrapScriptDir)) {
    $bootstrapScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

try {
    if (-not [string]::IsNullOrWhiteSpace($LocalZipPath)) {
        if (-not (Test-Path -LiteralPath $LocalZipPath)) {
            throw ($script:BootstrapMessage.LocalZipMissing -f $LocalZipPath)
        }
        $zipPath = (Resolve-Path -LiteralPath $LocalZipPath).Path
    }
    else {
        if ([string]::IsNullOrWhiteSpace($resolvedZipAsset)) {
            throw ($script:BootstrapMessage.ZipAssetRequired -f $script:BootstrapConstant.EnvZipAsset, $script:BootstrapConstant.ConfirmVsCiNote)
        }
        if ($SkipDownload) {
            throw ($script:BootstrapMessage.LocalZipMissing -f '(SkipDownload requires -LocalZipPath)')
        }

        $zipUrl = New-BootstrapLatestDownloadUrl -OwnerName $resolvedOwner -RepoName $resolvedRepo -AssetName $resolvedZipAsset
        $zipPath = Join-Path $CacheDir $resolvedZipAsset
        Save-BootstrapRemoteFile -Url $zipUrl -DestinationPath $zipPath

        if ([string]::IsNullOrWhiteSpace($ExpectedSha256) -and -not [string]::IsNullOrWhiteSpace($resolvedChecksumAsset) -and [string]::IsNullOrWhiteSpace($checksumPath)) {
            $checksumUrl = New-BootstrapLatestDownloadUrl -OwnerName $resolvedOwner -RepoName $resolvedRepo -AssetName $resolvedChecksumAsset
            $checksumPath = Join-Path $CacheDir $resolvedChecksumAsset
            Save-BootstrapRemoteFile -Url $checksumUrl -DestinationPath $checksumPath
        }
    }

    $expected = Read-BootstrapExpectedSha256 -ExpectedHex $ExpectedSha256 -ChecksumFilePath $checksumPath

    # REQ-004 / TE01: verify BEFORE extract
    Test-BootstrapChecksumOrThrow -ZipPath $zipPath -ExpectedHex $expected

    $extractDir = Join-Path $CacheDir $script:BootstrapConstant.ExtractedFolderName
    $didExtract = Expand-BootstrapZipIfRequested -ZipPath $zipPath -DestinationDir $extractDir -DoExtract:([bool]$Extract)

    # REQ-005: sync only after successful extract; TE01 keeps failure path out of catch below
    if (-not $didExtract) {
        Write-Host $script:BootstrapMessage.SyncSkippedNoExtract
        exit 0
    }

    if ($SkipSync) {
        Write-Host $script:BootstrapMessage.SyncSkippedExplicit
        exit 0
    }

    Invoke-BootstrapSyncHandoff `
        -ExtractDir $extractDir `
        -BootstrapScriptDir $bootstrapScriptDir `
        -AgentId $resolvedAgent `
        -DoWhatIf:([bool]$SyncWhatIf) `
        -SyncInstallRoot $InstallRoot `
        -DoAllowUserHome:([bool]$AllowUserHome) `
        -SyncMode $Mode `
        -DoUserScope:([bool]$UserScope)

    exit 0
}
catch {
    $errText = $_.Exception.Message
    [Console]::Error.WriteLine($errText)
    exit 1
}
