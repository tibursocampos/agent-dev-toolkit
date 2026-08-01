#Requires -Version 5.1
<#
.SYNOPSIS
  Shared ephemeral fixture smoke runner (copy seed -> work, sync+validate, cleanup).

.DESCRIPTION
  Centralizes the pattern used by scripts/validation/Invoke-*CiSmoke*.ps1: clean any
  stale work InstallRoot, copy the versioned seed fixture into it, run
  sync-agent + validate-agent against the ephemeral work InstallRoot, and check the
  adapter smoke pass marker. The work InstallRoot is removed in a finally block
  (pass or fail) unless -KeepWorkRoot is set, so repeated runs never leak
  "*-ci-smoke" directories on disk.

.NOTES
  Does not call `exit`; callers inspect the returned Status/ExitCode and exit
  themselves so this function's finally block always runs to completion first.
#>

. (Join-Path $PSScriptRoot 'ToolkitConstants.ps1')

# Windows Defender / indexer can transiently lock files immediately after a bulk
# copy into a brand-new directory tree, surfacing as "could not find a part of
# the path" or "used by another process" from the freshly-spawned sync/validate
# process. Retry a couple of times before treating those as a real failure.
$script:EphemeralSmokeTransientErrorPattern = 'Could not find a part of the path|being used by another process|cannot access the file'
$script:EphemeralSmokeMaxCommandAttempts = 3
$script:EphemeralSmokeRetryDelayMilliseconds = 300

function Invoke-EphemeralSmokeToolkitCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $CommandPath,
        [Parameter(Mandatory = $true)][string[]] $CommandArgs
    )

    $exitCode = 1
    $outputText = ''
    for ($attempt = 1; $attempt -le $script:EphemeralSmokeMaxCommandAttempts; $attempt++) {
        $commandOutput = & pwsh -NoProfile -File $CommandPath @CommandArgs 2>&1
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
        $outputText = ($commandOutput | Out-String)

        if ($exitCode -eq 0) {
            break
        }

        $isTransient = $outputText -match $script:EphemeralSmokeTransientErrorPattern
        if (-not $isTransient -or $attempt -ge $script:EphemeralSmokeMaxCommandAttempts) {
            break
        }

        Start-Sleep -Milliseconds ($script:EphemeralSmokeRetryDelayMilliseconds * $attempt)
    }

    return [PSCustomObject]@{
        ExitCode = [int]$exitCode
        Output   = $outputText
    }
}

function Remove-EphemeralSmokeWorkRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $maxAttempts = [Math]::Max($script:EphemeralSmokeMaxCommandAttempts, 5)
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object {
                    try { $_.Attributes = 'Normal' } catch { }
                }
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            if (-not (Test-Path -LiteralPath $Path)) {
                return
            }
        }
        catch {
            if ($attempt -ge $maxAttempts) {
                Write-Host ("WARN: failed to remove ephemeral work root after {0} attempts: {1} ({2})" -f $maxAttempts, $Path, $_.Exception.Message) -ForegroundColor Yellow
                return
            }
            Start-Sleep -Milliseconds ($script:EphemeralSmokeRetryDelayMilliseconds * $attempt)
        }
    }
}

function Invoke-EphemeralFixtureSmoke {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $SeedFixtureRel,
        [Parameter(Mandatory = $true)][string] $WorkFixtureRel,
        [Parameter(Mandatory = $true)][string] $AgentId,
        [Parameter()][string] $Mode,
        [Parameter()][string] $SyncAgentRel = $script:ToolkitConstant.SyncAgentRelativePath,
        [Parameter()][string] $ValidateAgentRel = $script:ToolkitConstant.ValidateAgentRelativePath,
        [Parameter()][string[]] $AdditionalRequiredPaths = @(),
        [Parameter()][scriptblock] $SeedCopyScriptBlock,
        [Parameter()][switch] $Quiet,
        [Parameter()][switch] $KeepWorkRoot
    )

    $seedFixtureRoot = Join-Path $RepoRoot $SeedFixtureRel
    $workInstallRoot = Join-Path $RepoRoot $WorkFixtureRel
    $syncAgentPath = Join-Path $RepoRoot $SyncAgentRel
    $validateAgentPath = Join-Path $RepoRoot $ValidateAgentRel
    $agentLabel = if ([string]::IsNullOrWhiteSpace($Mode)) { $AgentId } else { '{0} Mode={1}' -f $AgentId, $Mode }

    $requiredPaths = @($seedFixtureRoot, $syncAgentPath, $validateAgentPath) + $AdditionalRequiredPaths
    foreach ($required in $requiredPaths) {
        if (-not (Test-Path -LiteralPath $required)) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokePreconditionMissing -f $required) -ForegroundColor Red
            return [PSCustomObject]@{
                Status          = 'FAIL'
                ExitCode        = 1
                Phase           = 'preconditions'
                Output          = ''
                WorkInstallRoot = $workInstallRoot
            }
        }
    }

    try {
        Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
        New-Item -ItemType Directory -Path $workInstallRoot -Force | Out-Null

        if ($SeedCopyScriptBlock) {
            & $SeedCopyScriptBlock $seedFixtureRoot $workInstallRoot
        }
        else {
            Get-ChildItem -LiteralPath $seedFixtureRoot -Force | Copy-Item -Destination $workInstallRoot -Recurse -Force
        }

        if (-not $Quiet) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeRunning -f $agentLabel, $workInstallRoot) -ForegroundColor Cyan
        }

        $syncArgs = @('-Agent', $AgentId, '-InstallRoot', $workInstallRoot)
        if (-not [string]::IsNullOrWhiteSpace($Mode)) {
            $syncArgs += @('-Mode', $Mode)
        }

        $syncResult = Invoke-EphemeralSmokeToolkitCommand -CommandPath $syncAgentPath -CommandArgs $syncArgs
        $syncExit = $syncResult.ExitCode
        $syncText = $syncResult.Output
        if ($syncExit -ne 0) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeSyncFailed -f $syncExit, $syncText.Trim()) -ForegroundColor Red
            return [PSCustomObject]@{
                Status          = 'FAIL'
                ExitCode        = [int]$syncExit
                Phase           = 'sync'
                Output          = $syncText
                WorkInstallRoot = $workInstallRoot
            }
        }

        # Core already ran once in CI (validate-core job/step). Skip nested core here.
        $validateArgs = @('-Agent', $AgentId, '-InstallRoot', $workInstallRoot, ('-{0}' -f $script:ToolkitConstant.SkipCoreParameterName))
        if (-not [string]::IsNullOrWhiteSpace($Mode)) {
            $validateArgs += @('-Mode', $Mode)
        }

        $validateResult = Invoke-EphemeralSmokeToolkitCommand -CommandPath $validateAgentPath -CommandArgs $validateArgs
        $validateExit = $validateResult.ExitCode
        $validateText = $validateResult.Output
        if ($validateExit -ne 0) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeValidateFailed -f $validateExit, $validateText.Trim()) -ForegroundColor Red
            return [PSCustomObject]@{
                Status          = 'FAIL'
                ExitCode        = [int]$validateExit
                Phase           = 'validate'
                Output          = $validateText
                WorkInstallRoot = $workInstallRoot
            }
        }

        $adapterSmokePassMarker = $script:ToolkitConstant.AdapterSmokePassMarker
        if ($validateText -notlike ('*{0}*' -f $adapterSmokePassMarker)) {
            Write-Host ($script:ToolkitMessage.EphemeralSmokeMarkerMissing -f $adapterSmokePassMarker) -ForegroundColor Red
            Write-Host $validateText
            return [PSCustomObject]@{
                Status          = 'FAIL'
                ExitCode        = 1
                Phase           = 'marker'
                Output          = $validateText
                WorkInstallRoot = $workInstallRoot
            }
        }

        return [PSCustomObject]@{
            Status          = 'PASS'
            ExitCode        = 0
            Phase           = 'done'
            Output          = $validateText
            WorkInstallRoot = $workInstallRoot
        }
    }
    finally {
        if (-not $KeepWorkRoot) {
            Remove-EphemeralSmokeWorkRoot -Path $workInstallRoot
        }
    }
}
