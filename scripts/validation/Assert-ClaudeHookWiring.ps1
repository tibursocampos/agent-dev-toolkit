#Requires -Version 5.1
# Tests:
#   Should_ResolveEveryClaudeHookCommand_When_HooksPublished
#   Should_WireEveryManagedHookScript_When_HooksPublished
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
. (Join-Path $scriptsRoot '_lib\New-ToolkitWorkRoot.ps1')
. (Join-Path $scriptsRoot '_lib\Resolve-InstallRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
. (Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1')

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }

# Script files that are helpers loaded by other hooks rather than entry points.
$helperScriptNames = @('TraceEmitCommon.ps1')

function Get-HookScriptPathsFromCommand {
    param([string] $Command)
    $paths = @()
    foreach ($match in [regex]::Matches($Command, '-File\s+"(?<path>[^"]+)"')) {
        $paths += $match.Groups['path'].Value
    }
    return $paths
}

$n = 'Should_ResolveEveryClaudeHookCommand_When_HooksPublished'
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    $installRoot = Join-Path $work 'install'
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    $publish = Invoke-ClaudePublishHooks -InstallRoot $installRoot
    if ($null -eq $publish -or $publish.Success -ne $true) {
        Write-Fail $n ("hooks publish failed: {0}" -f $(if ($publish) { $publish.Message } else { 'null' }))
    }

    $hooksRoot = [System.IO.Path]::GetFullPath((Join-Path $installRoot 'hooks'))
    $settingsPath = Join-Path $installRoot 'settings.json'
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) { Write-Fail $n 'settings.json was not written' }
    $settings = [System.IO.File]::ReadAllText($settingsPath) | ConvertFrom-Json

    $referenced = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    $commands = New-Object System.Collections.Generic.List[string]

    $hooksNode = $settings.PSObject.Properties['hooks']
    if ($null -ne $hooksNode -and $null -ne $hooksNode.Value) {
        foreach ($eventProperty in $hooksNode.Value.PSObject.Properties) {
            foreach ($entry in @($eventProperty.Value)) {
                if ($null -eq $entry) { continue }
                $handlersNode = $entry.PSObject.Properties['hooks']
                if ($null -eq $handlersNode) { continue }
                foreach ($handler in @($handlersNode.Value)) {
                    $commandNode = $handler.PSObject.Properties['command']
                    if ($null -eq $commandNode) { continue }
                    $commands.Add([string]$commandNode.Value)
                }
            }
        }
    }

    $permissionsNode = $settings.PSObject.Properties['permissions']
    if ($null -ne $permissionsNode -and $null -ne $permissionsNode.Value) {
        $allowNode = $permissionsNode.Value.PSObject.Properties['allow']
        if ($null -ne $allowNode) {
            foreach ($allowEntry in @($allowNode.Value)) {
                if ([string]$allowEntry -like 'Bash(pwsh *-File*') { $commands.Add([string]$allowEntry) }
            }
        }
    }

    if ($commands.Count -eq 0) { Write-Fail $n 'settings.json declares no hook command' }

    foreach ($command in $commands) {
        $paths = @(Get-HookScriptPathsFromCommand -Command $command)
        if ($paths.Count -eq 0) { Write-Fail $n ("hook command has no -File script: {0}" -f $command) }
        foreach ($path in $paths) {
            $full = [System.IO.Path]::GetFullPath($path)
            if (-not $full.StartsWith($hooksRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Fail $n ("hook script is outside the published hooks directory: {0}" -f $path)
            }
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                Write-Fail $n ("hook command points to a missing script: {0}" -f $path)
            }
            [void]$referenced.Add((Split-Path -Leaf $full))
        }
    }
    Write-Pass $n

    $n = 'Should_WireEveryManagedHookScript_When_HooksPublished'
    $entryPoints = @(Get-ChildItem -LiteralPath $hooksRoot -File -Filter '*.ps1' |
        Where-Object { $_.Name -notlike '_*' -and $helperScriptNames -notcontains $_.Name })
    if ($entryPoints.Count -eq 0) { Write-Fail $n 'no published hook entry points found' }
    foreach ($script in $entryPoints) {
        if (-not $referenced.Contains($script.Name)) {
            Write-Fail $n ("published hook script is not wired in settings.json: {0}" -f $script.Name)
        }
    }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-ClaudeHookWiring: ALL PASS'
exit 0
