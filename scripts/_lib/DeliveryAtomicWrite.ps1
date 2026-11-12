#Requires -Version 5.1

function Test-DeliveryByteArrayEqual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyCollection()][byte[]] $Left,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyCollection()][byte[]] $Right
    )

    if ($null -eq $Left -or $null -eq $Right) { return ($null -eq $Left -and $null -eq $Right) }
    if ($Left.Length -ne $Right.Length) { return $false }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) { return $false }
    }
    return $true
}

function Get-DeliveryConflictStamp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][DateTime] $Moment
    )

    $utc = $Moment.ToUniversalTime()
    $invariant = [System.Globalization.CultureInfo]::InvariantCulture
    return $utc.ToString('yyyyMMdd', $invariant) + 'T' + $utc.ToString('HHmmssfff', $invariant) + 'Z'
}

function New-DeliveryConflictCopy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $BasePath,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]] $Bytes
    )

    $candidateBase = $BasePath + '.conflict-' + (Get-DeliveryConflictStamp -Moment ([DateTime]::UtcNow))
    $attempt = 0
    while ($true) {
        $candidate = $candidateBase
        if ($attempt -gt 0) { $candidate = $candidateBase + '-' + $attempt }
        try {
            $stream = [System.IO.FileStream]::new($candidate, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            try {
                $stream.Write($Bytes, 0, $Bytes.Length)
                $stream.Flush()
            }
            finally {
                $stream.Dispose()
            }
            return $candidate
        }
        catch [System.IO.IOException] {
            if (-not [System.IO.File]::Exists($candidate)) { throw }
            $attempt++
        }
    }
}

function Invoke-DeliveryAtomicReplace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]] $NewBytes,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]] $ExpectedOldBytes,
        [scriptblock] $AfterReplace,
        [scriptblock] $BeforeRestore
    )

    $target = [System.IO.Path]::GetFullPath($Path)
    $directory = [System.IO.Path]::GetDirectoryName($target)
    $stem = Join-Path $directory ('.delivery-state.' + [Guid]::NewGuid().ToString('N'))
    $temp = $stem + '.tmp'
    $backup = $stem + '.bak'
    $restore = $stem + '.restore'
    $conflictPath = ''
    $keepBackup = $false

    try {
        [System.IO.File]::WriteAllBytes($temp, $NewBytes)
        # The displaced bytes reveal a concurrent edit between read and replacement.
        [System.IO.File]::Replace($temp, $target, $backup)
        # From here the backup is the only copy of the displaced bytes until the original is confirmed back in place.
        $keepBackup = $true
        try {
            if ($null -ne $AfterReplace) { $null = & $AfterReplace }

            $displaced = [System.IO.File]::ReadAllBytes($backup)
            $current = $null
            if ([System.IO.File]::Exists($target)) { $current = [System.IO.File]::ReadAllBytes($target) }
            if ((Test-DeliveryByteArrayEqual -Left $displaced -Right $ExpectedOldBytes) -and
                (Test-DeliveryByteArrayEqual -Left $current -Right $NewBytes)) {
                $keepBackup = $false
                return [pscustomobject]@{ Status = 'written'; ConflictPath = ''; BackupPath = '' }
            }

            if ($null -ne $current) {
                $conflictPath = New-DeliveryConflictCopy -BasePath $target -Bytes $current
            }
            if ($null -ne $BeforeRestore) { $null = & $BeforeRestore }
            [System.IO.File]::Copy($backup, $restore, $false)
            if ([System.IO.File]::Exists($target)) {
                [System.IO.File]::Replace($restore, $target, $temp)
            }
            else {
                [System.IO.File]::Move($restore, $target)
            }
            $keepBackup = $false
            return [pscustomobject]@{ Status = 'conflict'; ConflictPath = $conflictPath; BackupPath = '' }
        }
        catch {
            return [pscustomobject]@{ Status = 'restore_failed'; ConflictPath = $conflictPath; BackupPath = $backup }
        }
    }
    finally {
        foreach ($leftover in @($temp, $restore)) {
            Remove-Item -LiteralPath $leftover -Force -ErrorAction SilentlyContinue
        }
        if (-not $keepBackup) {
            Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
        }
    }
}
