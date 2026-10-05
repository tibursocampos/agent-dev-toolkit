Set-StrictMode -Version Latest

function Write-ValidationTelemetryRecord {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [hashtable] $Record
    )

    try {
        $directory = Split-Path -Parent $Path
        if (-not [string]::IsNullOrWhiteSpace($directory)) {
            New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop | Out-Null
        }

        $json = [PSCustomObject]$Record | ConvertTo-Json -Compress -Depth 8
        Add-Content -LiteralPath $Path -Value $json -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        # Observability must never alter validation behavior.
        Write-Warning ("Validation telemetry unavailable: {0}" -f $_.Exception.Message)
    }
}

function Get-ValidationTelemetryPath {
    if (-not [string]::IsNullOrWhiteSpace($env:VALIDATION_RESULTS_PATH)) {
        return $env:VALIDATION_RESULTS_PATH
    }

    return $null
}

function Write-ValidationTelemetryUnavailable {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Reason
    )

    # Telemetry is best-effort. Make an absent sink visible without changing
    # the functional result of the validation that requested it.
    Write-Warning ("Validation telemetry unavailable (SKIPPED): {0}" -f $Reason)
}

function Write-ValidationTelemetryCheck {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $JobName,
        [Parameter(Mandatory = $true)]
        [string] $CheckName,
        [Parameter(Mandatory = $true)]
        [string] $Status,
        [Parameter(Mandatory = $true)]
        [int] $ExitCode,
        [Parameter(Mandatory = $true)]
        [double] $DurationMs,
        [Parameter(Mandatory = $true)]
        [string] $StartedAtUtc,
        [Parameter(Mandatory = $true)]
        [string] $FinishedAtUtc,
        [Parameter(Mandatory = $true)]
        [string] $ScriptPath
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-ValidationTelemetryUnavailable -Reason 'no output path was configured.'
        return
    }

    Write-ValidationTelemetryRecord -Path $Path -Record @{
        schemaVersion = 1
        recordType    = 'check'
        jobName       = $JobName
        checkName     = $CheckName
        scriptPath    = $ScriptPath
        status        = $Status
        exitCode      = $ExitCode
        durationMs    = [math]::Round($DurationMs, 2)
        startedAtUtc  = $StartedAtUtc
        finishedAtUtc = $FinishedAtUtc
    }
}

function Write-ValidationTelemetryJob {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $JobName,
        [Parameter(Mandatory = $true)]
        [string] $Status,
        [Parameter(Mandatory = $true)]
        [double] $DurationMs,
        [Parameter(Mandatory = $true)]
        [string] $StartedAtUtc,
        [Parameter(Mandatory = $true)]
        [string] $FinishedAtUtc
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-ValidationTelemetryUnavailable -Reason 'no output path was configured.'
        return
    }

    Write-ValidationTelemetryRecord -Path $Path -Record @{
        schemaVersion = 1
        recordType    = 'job'
        jobName       = $JobName
        status        = $Status
        durationMs    = [math]::Round($DurationMs, 2)
        startedAtUtc  = $StartedAtUtc
        finishedAtUtc = $FinishedAtUtc
    }
}

function Invoke-ValidationCheckWithTelemetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $JobName,
        [Parameter(Mandatory = $true)]
        [string] $CheckName,
        [Parameter(Mandatory = $true)]
        [string] $ScriptPath,
        [Parameter(Mandatory = $true)]
        [scriptblock] $Action
    )

    $startedAt = [DateTimeOffset]::UtcNow
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $exitCode = 1

    try {
        & $Action
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
        return $exitCode
    }
    catch {
        $exitCode = 1
        throw
    }
    finally {
        $timer.Stop()
        $finishedAt = [DateTimeOffset]::UtcNow
        $status = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
        Write-ValidationTelemetryCheck `
            -Path $Path `
            -JobName $JobName `
            -CheckName $CheckName `
            -Status $status `
            -ExitCode $exitCode `
            -DurationMs $timer.Elapsed.TotalMilliseconds `
            -StartedAtUtc $startedAt.ToString('o') `
            -FinishedAtUtc $finishedAt.ToString('o') `
            -ScriptPath $ScriptPath
    }
}
