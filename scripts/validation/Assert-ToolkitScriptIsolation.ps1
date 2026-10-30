#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'scripts/_lib/Invoke-ToolkitChildScript.ps1')

$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-toolkit-child-script-{0}' -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

try {
    $childScript = Join-Path $workRoot 'child script with spaces.ps1'
    $resultPath = Join-Path $workRoot 'argument result.txt'
    @'
param(
    [Parameter(Mandatory = $true)][string] $OutputPath,
    [Parameter(Mandatory = $true)][string] $Value,
    [switch] $Quiet,
    [Parameter(Mandatory = $true)][int] $ExitCode
)

Set-Content -LiteralPath $OutputPath -Value ("{0}|{1}" -f $Value, $Quiet.IsPresent) -Encoding UTF8
exit $ExitCode
'@ | Set-Content -LiteralPath $childScript -Encoding UTF8

    $valueWithSpaces = 'argument value with spaces'
    $successCode = Invoke-ToolkitChildScript -ScriptPath $childScript -ArgumentTable @{
        OutputPath = $resultPath
        Value      = $valueWithSpaces
        Quiet      = $true
        ExitCode   = 0
    }
    if ($successCode -ne 0) {
        throw "Expected child exit 0; got $successCode."
    }
    if ((Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8).Trim() -ne "$valueWithSpaces|True") {
        throw 'Child process did not receive string and switch arguments with their values intact.'
    }

    $failureCode = Invoke-ToolkitChildScript -ScriptPath $childScript -ArgumentTable @{
        OutputPath = $resultPath
        Value      = $valueWithSpaces
        Quiet      = $true
        ExitCode   = 23
    }
    if ($failureCode -ne 23) {
        throw "Expected child exit 23; got $failureCode."
    }

    Write-Host 'Assert-ToolkitScriptIsolation: PASS' -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}

exit 0
