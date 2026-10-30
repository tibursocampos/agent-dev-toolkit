function Invoke-ToolkitChildScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter()][hashtable] $ArgumentTable = @{}
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "Child script not found: $ScriptPath"
    }

    $runnerPath = (Get-Process -Id $PID).Path
    if ([string]::IsNullOrWhiteSpace($runnerPath)) {
        throw 'Could not resolve the current PowerShell executable for child-script isolation.'
    }

    $nativeArguments = @('-NoProfile', '-File', $ScriptPath)
    foreach ($key in @($ArgumentTable.Keys | Sort-Object)) {
        $value = $ArgumentTable[$key]
        if ($null -eq $value) {
            continue
        }

        if ($value -is [System.Management.Automation.SwitchParameter]) {
            if ($value.IsPresent) {
                $nativeArguments += ("-{0}" -f $key)
            }
            continue
        }

        if ($value -is [bool]) {
            if ($value) {
                $nativeArguments += ("-{0}" -f $key)
            }
            continue
        }

        $nativeArguments += ("-{0}" -f $key)
        foreach ($item in @($value)) {
            if ($null -ne $item) {
                $nativeArguments += [string]$item
            }
        }
    }

    & $runnerPath @nativeArguments 2>&1 | ForEach-Object {
        Write-Host $_
    }
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        throw "Child script did not return an exit code: $ScriptPath"
    }

    return [int]$exitCode
}
