# Requires: PowerShell 5.1+
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $ProjectRoot,
    [Parameter(Mandatory = $true)][string[]] $ChangedPaths,
    [string] $ConfigPath,
    [string] $BaselinePath,
    [ValidateRange(256, 65536)][int] $MaxOutputLength = 8000,
    [switch] $TrustConfiguredCommands
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectRoot).Path
if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $ConfigPath = Join-Path $project '.agent-validation-tools.json' }
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$baselineFindings = @()
if (-not [string]::IsNullOrWhiteSpace($BaselinePath)) {
    $baselineFindings = @(Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json)
}
$records = [System.Collections.Generic.List[object]]::new()

function Protect-Output {
    param([string] $Value)
    $safe = $Value
    $patterns = @(
        '(?is)-----BEGIN [^-]*PRIVATE KEY-----.*?-----END [^-]*PRIVATE KEY-----',
        '(?i)(authorization\s*:\s*bearer\s+)[A-Za-z0-9._~+/-]+=*',
        '(?i)(bearer\s+)[A-Za-z0-9._~+/-]+=*',
        '(?i)(api[_-]?key|access[_-]?token|client[_-]?secret|password|passwd|secret|connection[_-]?string)(\s*[=:]\s*)([^\s,;]+)',
        '(?i)(https?://)[^/@\s]+:[^/@\s]+@',
        '\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
        '\b(AKIA)[A-Z0-9]{16}\b',
        '\b(gh[pousr]_|github_pat_)[A-Za-z0-9_]{20,}\b'
    )
    foreach ($pattern in $patterns) {
        $safe = [regex]::Replace($safe, $pattern, {
            param($match)
            if ($match.Groups.Count -gt 3 -and $match.Groups[2].Success) { return $match.Groups[1].Value + $match.Groups[2].Value + '[REDACTED]' }
            if ($match.Groups.Count -gt 1 -and $match.Groups[1].Success) { return $match.Groups[1].Value + '[REDACTED]' }
            return '[REDACTED]'
        })
    }
    if ($safe.Length -gt $MaxOutputLength) {
        $safe = $safe.Substring(0, $MaxOutputLength) + "`n[TRUNCATED]"
    }
    return $safe
}

function Get-FindingComparison {
    param([string] $ToolName, [string] $ProjectPath, [string] $FilePath, [string] $RuleName)
    if ([string]::IsNullOrWhiteSpace($ToolName) -or [string]::IsNullOrWhiteSpace($ProjectPath) -or
        [string]::IsNullOrWhiteSpace($FilePath) -or [string]::IsNullOrWhiteSpace($RuleName) -or
        $ToolName -eq 'n/a' -or $FilePath -eq 'n/a' -or $RuleName -eq 'n/a' -or $baselineFindings.Count -eq 0) { return 'unavailable' }
    foreach ($baseline in $baselineFindings) {
        foreach ($field in @('Tool', 'Project', 'File', 'Rule')) {
            if ([string]::IsNullOrWhiteSpace([string]$baseline.$field)) { return 'unavailable' }
        }
    }
    foreach ($baseline in $baselineFindings) {
        if ([string]$baseline.Tool -eq $ToolName -and
            [string]$baseline.Project -eq $ProjectPath -and
            [string]$baseline.File -eq $FilePath -and
            [string]$baseline.Rule -eq $RuleName) { return 'pre-existing' }
    }
    return 'new'
}

foreach ($tool in @($config.tools)) {
    if (-not $TrustConfiguredCommands) {
        $toolName = [string]$tool.name
        $scope = [string]$tool.scope
        if ([string]::IsNullOrWhiteSpace($scope)) { $scope = ($ChangedPaths -join ', ') }
        $records.Add([pscustomobject]@{ Tool = $toolName; Command = "$toolName (not run)"; Project = $project; Scope = $scope; Status = 'SKIPPED'; Evidence = 'Configured command was not run because explicit trust approval was not supplied.'; File = 'n/a'; Rule = 'n/a'; Severity = 'n/a'; Comparison = 'unavailable'; Finding = 'n/a'; Reason = 'configured command not trusted' })
        continue
    }

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
    Push-Location -LiteralPath $project
    try {
        $output = @(& $resolvedCommand @arguments 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally { Pop-Location }
    $raw = $output -join "`n"
    $matches = @()
    if (-not [string]::IsNullOrWhiteSpace([string]$tool.findingPattern)) {
        foreach ($match in [regex]::Matches($raw, [string]$tool.findingPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)) { $matches += $match }
    }
    if ($matches.Count -eq 0) {
        $status = if ($exitCode -eq 0) { 'PASS' } else { 'FOUND' }
        $safeRaw = Protect-Output $raw
        $commandLabel = "$($tool.name) ($([System.IO.Path]::GetFileName($resolvedCommand)))"
        $records.Add([pscustomobject]@{ Tool = [string]$tool.name; Command = $commandLabel; Project = $project; Scope = $scope; Status = $status; Evidence = if ($safeRaw) { $safeRaw } else { "exit code $exitCode" }; File = 'n/a'; Rule = if ($status -eq 'FOUND') { 'tool-exit' } else { 'n/a' }; Severity = if ($status -eq 'FOUND') { 'unknown' } else { 'n/a' }; Comparison = 'unavailable'; Finding = if ($status -eq 'FOUND') { "tool exited $exitCode without a parsed finding" } else { 'no findings' }; Reason = '' })
        continue
    }
    foreach ($match in $matches) {
        $rule = [string]$match.Groups['rule'].Value
        if (-not $rule) { $rule = 'diagnostic' }
        $file = [string]$match.Groups['file'].Value
        if (-not $file) { $file = $scope }
        $severity = [string]$match.Groups['severity'].Value
        if (-not $severity) { $severity = 'unknown' }
        $comparison = Get-FindingComparison -ToolName ([string]$tool.name) -ProjectPath $project -FilePath $file -RuleName $rule
        $safeMatch = Protect-Output ([string]$match.Value)
        $commandLabel = "$($tool.name) ($([System.IO.Path]::GetFileName($resolvedCommand)))"
        $records.Add([pscustomobject]@{ Tool = [string]$tool.name; Command = $commandLabel; Project = $project; Scope = $scope; Status = 'FOUND'; Evidence = $safeMatch; File = $file; Rule = $rule; Severity = $severity; Comparison = $comparison; Finding = $safeMatch; Reason = '' })
    }
}

$records | ConvertTo-Json -Depth 5
