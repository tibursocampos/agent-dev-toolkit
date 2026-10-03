# Requires: PowerShell 5.1+
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $ProjectRoot,
    [Parameter(Mandatory = $true)][string[]] $ChangedPaths,
    [string] $ConfigPath,
    [string[]] $BaselineRules = @()
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectRoot).Path
if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $ConfigPath = Join-Path $project '.agent-validation-tools.json' }
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$records = [System.Collections.Generic.List[object]]::new()

foreach ($tool in @($config.tools)) {
    $toolPath = [string]$tool.command
    if (-not [System.IO.Path]::IsPathRooted($toolPath)) {
        $localCandidate = Join-Path $project $toolPath
        if (Test-Path -LiteralPath $localCandidate -PathType Leaf) { $toolPath = (Resolve-Path -LiteralPath $localCandidate).Path }
    }
    $resolvedCommand = $null
    if (Test-Path -LiteralPath $toolPath -PathType Leaf) { $resolvedCommand = (Resolve-Path -LiteralPath $toolPath).Path }
    else {
        $command = Get-Command -Name $toolPath -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $resolvedCommand = $command.Source }
    }

    $scope = [string]$tool.scope
    if ([string]::IsNullOrWhiteSpace($scope)) { $scope = ($ChangedPaths -join ', ') }
    if (-not $resolvedCommand) {
        $records.Add([pscustomobject]@{ Tool = [string]$tool.name; Command = [string]$tool.command; Project = $project; Scope = $scope; Status = 'SKIPPED'; Evidence = "Configured command '$($tool.command)' was not found; no package was installed."; File = 'n/a'; Rule = 'n/a'; Severity = 'n/a'; Comparison = 'unavailable'; Finding = 'n/a'; Reason = 'configured tool unavailable' })
        continue
    }

    $arguments = @()
    foreach ($argument in @($tool.arguments)) {
        $value = [string]$argument
        $value = $value.Replace('{project}', $project)
        $value = $value.Replace('{changed}', ($ChangedPaths -join ' '))
        $arguments += $value
    }
    $output = @(& $resolvedCommand @arguments 2>&1 | ForEach-Object { [string]$_ })
    $exitCode = $LASTEXITCODE
    $raw = $output -join "`n"
    $matches = @()
    if (-not [string]::IsNullOrWhiteSpace([string]$tool.findingPattern)) {
        foreach ($match in [regex]::Matches($raw, [string]$tool.findingPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)) { $matches += $match }
    }
    if ($matches.Count -eq 0) {
        $status = if ($exitCode -eq 0) { 'PASS' } else { 'FOUND' }
        $records.Add([pscustomobject]@{ Tool = [string]$tool.name; Command = "$resolvedCommand $($arguments -join ' ')"; Project = $project; Scope = $scope; Status = $status; Evidence = if ($raw) { $raw } else { "exit code $exitCode" }; File = 'n/a'; Rule = if ($status -eq 'FOUND') { 'tool-exit' } else { 'n/a' }; Severity = if ($status -eq 'FOUND') { 'unknown' } else { 'n/a' }; Comparison = 'unavailable'; Finding = if ($status -eq 'FOUND') { "tool exited $exitCode without a parsed finding" } else { 'no findings' }; Reason = '' })
        continue
    }
    foreach ($match in $matches) {
        $rule = [string]$match.Groups['rule'].Value
        if (-not $rule) { $rule = 'diagnostic' }
        $file = [string]$match.Groups['file'].Value
        if (-not $file) { $file = $scope }
        $severity = [string]$match.Groups['severity'].Value
        if (-not $severity) { $severity = 'unknown' }
        $comparison = if ($BaselineRules -contains $rule) { 'pre-existing' } else { 'new' }
        $records.Add([pscustomobject]@{ Tool = [string]$tool.name; Command = "$resolvedCommand $($arguments -join ' ')"; Project = $project; Scope = $scope; Status = 'FOUND'; Evidence = $match.Value; File = $file; Rule = $rule; Severity = $severity; Comparison = $comparison; Finding = [string]$match.Value; Reason = '' })
    }
}

$records | ConvertTo-Json -Depth 5
