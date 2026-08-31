#Requires -Version 5.1
<#
.SYNOPSIS
  Shared path-allow / path-deny / secret-pattern helpers for adapter pre-tool hooks.

.DESCRIPTION
  Dot-source from adapter hook scripts (or from Cursor _hook-common.ps1).
  Host-agnostic: callers map host tool names and input shapes before calling these helpers.
  Contract reference: adapters/_shared/guard-rules.md
#>

Set-StrictMode -Version Latest

function Test-ToolkitPathIsUnderWorkspaceRoot {
    param(
        [string] $FullPath,
        [string] $RootFull
    )

    if ([string]::IsNullOrWhiteSpace($FullPath) -or [string]::IsNullOrWhiteSpace($RootFull)) {
        return $false
    }

    $full = $FullPath.TrimEnd('\', '/')
    $root = $RootFull.TrimEnd('\', '/')
    if ($full.Equals($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $alt = [System.IO.Path]::AltDirectorySeparatorChar
    $rootPrefix = $root + $sep
    $rootPrefixAlt = $root + $alt
    if ($FullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    if ($sep -ne $alt -and $FullPath.StartsWith($rootPrefixAlt, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $false
}

function Get-ToolkitNormalizedRelativePath {
    <#
    .SYNOPSIS
      Map a file path to a workspace-relative `/` path.
    .OUTPUTS
      Relative path string when inside workspace; empty string for blank input;
      $null when the path resolves outside the workspace root (or is absolute with no root).
    #>
    param(
        [string] $FilePath,
        [string] $WorkspaceRoot
    )

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        return ''
    }

    $fullPath = $FilePath
    if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
        if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
            $fullPath = Join-Path $WorkspaceRoot $FilePath
        }
        else {
            # Relative with no workspace: keep as normalized relative candidate.
            return (($FilePath -replace '\\', '/').TrimStart('/'))
        }
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath($fullPath)
    }
    catch {
        return ''
    }

    $rootFull = ''
    if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($WorkspaceRoot)
        }
        catch {
            $rootFull = ''
        }
    }

    if ([string]::IsNullOrWhiteSpace($rootFull)) {
        # Absolute path without a workspace root cannot be validated as in-repo.
        return $null
    }

    if (Test-ToolkitPathIsUnderWorkspaceRoot -FullPath $fullPath -RootFull $rootFull) {
        $relative = $fullPath.Substring($rootFull.TrimEnd('\', '/').Length).TrimStart('\', '/')
        return ($relative -replace '\\', '/')
    }

    # Outside workspace (includes sibling-prefix cases like agent-dev-toolkit-evil).
    return $null
}

function Test-ToolkitForbiddenSddPath {
    param([string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    $norm = ($RelativePath -replace '\\', '/').TrimStart('/')
    if ($norm -match '^(PRD|PLAN)/') {
        return $true
    }
    if ($norm -match '^docs/(PRD|PLAN|backlog)/') {
        return $true
    }
    if ($norm -match '(^|/)\.cursor/plans/') {
        return $true
    }
    return $false
}

function Test-ToolkitDeniedPathSegment {
    param([string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    $norm = '/' + (($RelativePath -replace '\\', '/').Trim('/')) + '/'
    $denied = @(
        '/.git/',
        '/node_modules/',
        '/bin/',
        '/obj/',
        '/dist/',
        '/build/',
        '/coverage/',
        '/.vs/',
        '/target/',
        '/vendor/'
    )
    foreach ($segment in $denied) {
        if ($norm -match [regex]::Escape($segment)) {
            return $true
        }
    }
    return $false
}

function Test-ToolkitAllowedWritePath {
    param([string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    # Extension / prefix allowlist applies only to workspace-relative paths.
    $asFsPath = ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ([System.IO.Path]::IsPathRooted($asFsPath)) {
        return $false
    }

    if (Test-ToolkitForbiddenSddPath -RelativePath $RelativePath) {
        return $false
    }
    if (Test-ToolkitDeniedPathSegment -RelativePath $RelativePath) {
        return $false
    }

    $norm = (($RelativePath -replace '\\', '/').TrimStart('/')).ToLowerInvariant()
    $sddPrefixes = @(
        'features/',
        'memory-bank/',
        'docs/',
        '.cursor/sdd/'
    )
    foreach ($prefix in $sddPrefixes) {
        if ($norm.StartsWith($prefix)) {
            return $true
        }
    }

    $appDirPrefixes = @(
        'src/', 'test/', 'tests/', 'app/', 'lib/', 'pkg/', 'internal/', 'cmd/',
        'api/', 'server/', 'client/', 'backend/', 'frontend/', 'services/',
        'components/', 'pages/', 'assets/', 'public/', 'wwwroot/',
        'infrastructure/', 'application/', 'domain/', 'presentation/',
        'core/', 'scripts/', 'adapters/', 'docs-site/', '.github/'
    )
    foreach ($prefix in $appDirPrefixes) {
        if ($norm.StartsWith($prefix)) {
            return $true
        }
    }

    $ext = [System.IO.Path]::GetExtension($norm)
    $appExtensions = @(
        '.cs', '.ts', '.tsx', '.js', '.jsx', '.py', '.java', '.kt', '.go', '.rs',
        '.vue', '.svelte', '.css', '.scss', '.sass', '.less', '.html', '.htm',
        '.sql', '.razor', '.cshtml', '.fs', '.fsx', '.rb', '.php', '.swift', '.m',
        '.h', '.cpp', '.c', '.hpp', '.json', '.yaml', '.yml', '.toml', '.xml',
        '.md', '.mdc', '.ps1', '.sh', '.dart', '.ex', '.exs', '.sln', '.csproj',
        '.fsproj', '.props', '.targets', '.gradle', '.kts', '.lock', '.config'
    )
    if ($appExtensions -contains $ext) {
        return $true
    }

    return $false
}

# Friendly alias used by shared docs / future adapters.
function Test-AllowedPath {
    param([string] $RelativePath)
    return (Test-ToolkitAllowedWritePath -RelativePath $RelativePath)
}

function Test-ToolkitSecretFalsePositive {
    param([string] $Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $true
    }
    if ($Line -match '(?i)YOUR_|example|<TOKEN>|xxx|placeholder|Configuration\[|Environment\.Get|process\.env') {
        return $true
    }
    return $false
}

function Get-ToolkitSecretFindings {
    param([string] $Content)

    $findings = [System.Collections.ArrayList]::new()
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return @()
    }

    $patterns = @(
        @{ Name = 'aws_access_key'; Pattern = 'AKIA[0-9A-Z]{16}' },
        @{ Name = 'api_key_literal'; Pattern = '(?i)api[_-]?key\s*=\s*[''"]?[a-z0-9_\-]{8,}' },
        @{ Name = 'github_token'; Pattern = 'gh[pousr]_[A-Za-z0-9_]{20,}' },
        @{ Name = 'jwt'; Pattern = 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' },
        @{ Name = 'password_conn'; Pattern = '(?i)password\s*=\s*[^;\s''"]{4,}' },
        @{ Name = 'private_key'; Pattern = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' },
        @{ Name = 'azure_account_key'; Pattern = '(?i)AccountKey\s*=\s*[A-Za-z0-9+/=]{20,}' }
    )

    $lineNo = 0
    foreach ($line in ($Content -split "`r?`n")) {
        $lineNo++
        if (Test-ToolkitSecretFalsePositive -Line $line) {
            continue
        }
        foreach ($entry in $patterns) {
            if ($line -match $entry.Pattern) {
                [void]$findings.Add([PSCustomObject]@{
                        Type = $entry.Name
                        Line = $lineNo
                    })
                break
            }
        }
    }

    return @($findings)
}

# Friendly alias: returns $true when any secret pattern matches.
function Test-SecretPatterns {
    param([string] $Content)
    $findings = @(Get-ToolkitSecretFindings -Content $Content)
    return ($findings.Count -gt 0)
}

function Get-WriteToolPathFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }
    foreach ($name in @('path', 'file_path', 'filePath', 'target_file', 'TargetFile', 'AbsolutePath')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            return [string]$prop.Value
        }
    }
    return ''
}

function Get-WriteToolContentFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }

    $parts = [System.Collections.ArrayList]::new()
    foreach ($name in @('contents', 'content', 'new_string', 'newText', 'text', 'CodeContent', 'ReplacementContent')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            [void]$parts.Add([string]$prop.Value)
        }
    }

    $editsProp = $ToolInput.PSObject.Properties['edits']
    if ($editsProp -and $null -ne $editsProp.Value) {
        foreach ($edit in @($editsProp.Value)) {
            $newProp = $edit.PSObject.Properties['new_string']
            if ($newProp -and -not [string]::IsNullOrWhiteSpace([string]$newProp.Value)) {
                [void]$parts.Add([string]$newProp.Value)
            }
        }
    }

    $chunksProp = $ToolInput.PSObject.Properties['ReplacementChunks']
    if ($chunksProp -and $null -ne $chunksProp.Value) {
        foreach ($chunk in @($chunksProp.Value)) {
            foreach ($chunkField in @('ReplacementContent', 'new_string', 'content')) {
                $chunkProp = $chunk.PSObject.Properties[$chunkField]
                if ($chunkProp -and -not [string]::IsNullOrWhiteSpace([string]$chunkProp.Value)) {
                    [void]$parts.Add([string]$chunkProp.Value)
                    break
                }
            }
        }
    }

    return ($parts -join "`n")
}

function Test-ToolkitWriteToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)(Write|StrReplace|search_replace|Edit|MultiEdit)$'
}

function Test-ToolkitShellToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)(Shell|Bash|PowerShell)$'
}

function Test-ToolkitDeleteToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)Delete$'
}

function Test-ToolkitApplyPatchToolName {
    param([string] $ToolName)

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }
    return $ToolName -match '^(?i)(apply_patch)$'
}

function Get-ShellCommandFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }
    foreach ($name in @('command', 'cmd', 'shell_command', 'script', 'CommandLine')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            return [string]$prop.Value
        }
    }
    return ''
}

function Get-DeleteToolPathFromInput {
    param($ToolInput)
    return (Get-WriteToolPathFromInput -ToolInput $ToolInput)
}

function Get-ApplyPatchContentFromInput {
    param($ToolInput)

    if ($null -eq $ToolInput) {
        return ''
    }

    $fromWrite = Get-WriteToolContentFromInput -ToolInput $ToolInput
    if (-not [string]::IsNullOrWhiteSpace($fromWrite)) {
        return $fromWrite
    }

    foreach ($name in @('command', 'patch', 'input')) {
        $prop = $ToolInput.PSObject.Properties[$name]
        if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            return [string]$prop.Value
        }
    }
    return ''
}

function Get-ApplyPatchPathsFromContent {
    param([string] $PatchContent)

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ([string]::IsNullOrWhiteSpace($PatchContent)) {
        return @()
    }

    foreach ($line in ($PatchContent -split "`r?`n")) {
        if ($line -match '(?i)^\*\*\*\s+(?:Add|Update|Delete)\s+File:\s+(.+)$') {
            [void]$paths.Add($Matches[1].Trim().Trim('"').Trim("'"))
        }
        elseif ($line -match '(?i)^diff --git a/(.+?) b/(.+)$') {
            [void]$paths.Add($Matches[1].Trim())
            [void]$paths.Add($Matches[2].Trim())
        }
        elseif ($line -match '(?i)^(?:\+\+\+|---)\s+[ab]/(.+)$') {
            $p = $Matches[1].Trim()
            if ($p -ne '/dev/null') {
                [void]$paths.Add($p)
            }
        }
    }
    return @($paths)
}

function Get-PathsReferencedInShellCommand {
    param([string] $Command)

    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ([string]::IsNullOrWhiteSpace($Command)) {
        return @()
    }

    $patterns = @(
        '(?i)(?:^|[\s;&|])(?:>{1,2})\s*["'']?([^\s"'';|&;]+)',
        '(?i)(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|\bri\b|\brm\b|\bdel\b|\berase\b|\btee\b)\s+(?:-[A-Za-z]+\s+[^\s]+\s+)*["'']?([^\s"'';|&;]+)',
        '(?i)(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|Get-Content|Get-ChildItem)\s+[^\r\n]{0,400}?-(?:LiteralPath|FilePath|Path)\s+["'']?([^\s"'';|&;]+)',
        '(?i)-(?:LiteralPath|FilePath|Path)\s+["'']?([^\s"'';|&;]+)',
        '(?i)(?:rm|rmdir|unlink|mv|cp|install)\s+(?:-[a-zA-Z0-9\-]+\s+)*["'']?([^\s"'';|&;]+)',
        '(?i)(?:^|[\s;&|])(?:cat|echo|printf)\s+[^\r\n]{0,200}(?:>{1,2})\s*["'']?([^\s"'';|&;]+)'
    )
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Command, $pattern)) {
            if ($match.Groups.Count -gt 1 -and -not [string]::IsNullOrWhiteSpace($match.Groups[1].Value)) {
                $candidate = $match.Groups[1].Value.Trim().Trim('"').Trim("'")
                # Skip PowerShell switch-looking tokens mistaken for paths.
                if ($candidate.StartsWith('-')) {
                    continue
                }
                if ($candidate -match '[\\/.]' -or $candidate -match '\.(cs|ts|js|json|md|ps1|sh|yml|yaml|toml|xml|txt)$') {
                    [void]$paths.Add($candidate)
                }
            }
        }
    }

    # Also catch legacy/forbidden SDD path literals anywhere in the command.
    foreach ($literal in @('PRD/', 'PLAN/', 'docs/PRD/', 'docs/PLAN/', 'docs/backlog/', '.cursor/plans/', 'node_modules/', '.git/')) {
        if ($Command -match [regex]::Escape($literal)) {
            [void]$paths.Add($literal.TrimEnd('/'))
        }
    }

    return @($paths)
}

function Get-ToolkitPathSecretsGuardVerdict {
    <#
    .SYNOPSIS
      Host-agnostic allow/deny for write, delete, shell, and apply_patch tool calls.
    #>
    param(
        [string] $ToolName,
        [object] $ToolInput,
        [string] $WorkspaceRoot,
        [string] $DirectShellCommand = ''
    )

    $allow = [PSCustomObject]@{
        Decision     = 'allow'
        Reason       = ''
        UserMessage  = ''
        AgentMessage = ''
        RelativePath = ''
        SecretType   = ''
    }

    $isWrite = Test-ToolkitWriteToolName -ToolName $ToolName
    $isDelete = Test-ToolkitDeleteToolName -ToolName $ToolName
    $isShell = Test-ToolkitShellToolName -ToolName $ToolName
    $isPatch = Test-ToolkitApplyPatchToolName -ToolName $ToolName

    if (-not ($isWrite -or $isDelete -or $isShell -or $isPatch)) {
        return $allow
    }

    $pathsToCheck = [System.Collections.Generic.List[string]]::new()
    $contentToScan = ''

    if ($isWrite) {
        $filePath = Get-WriteToolPathFromInput -ToolInput $ToolInput
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'missing_path'
                UserMessage  = 'Blocked: write/edit tool missing file path.'
                AgentMessage = 'Hook denied write/edit because tool_input has no path/file_path. Fail-closed: path is required.'
                RelativePath = ''
                SecretType   = ''
            }
        }
        $pathsToCheck.Add($filePath) | Out-Null
        $contentToScan = Get-WriteToolContentFromInput -ToolInput $ToolInput
    }
    elseif ($isDelete) {
        $filePath = Get-DeleteToolPathFromInput -ToolInput $ToolInput
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'missing_path'
                UserMessage  = 'Blocked: delete tool missing file path.'
                AgentMessage = 'Hook denied Delete because tool_input has no path. Fail-closed: path is required.'
                RelativePath = ''
                SecretType   = ''
            }
        }
        $pathsToCheck.Add($filePath) | Out-Null
    }
    elseif ($isPatch) {
        $patchBody = Get-ApplyPatchContentFromInput -ToolInput $ToolInput
        $contentToScan = $patchBody
        foreach ($p in @(Get-ApplyPatchPathsFromContent -PatchContent $patchBody)) {
            $pathsToCheck.Add($p) | Out-Null
        }
    }
    elseif ($isShell) {
        $shellCmd = $DirectShellCommand
        if ([string]::IsNullOrWhiteSpace($shellCmd)) {
            $shellCmd = Get-ShellCommandFromInput -ToolInput $ToolInput
        }
        $contentToScan = $shellCmd
        foreach ($p in @(Get-PathsReferencedInShellCommand -Command $shellCmd)) {
            $pathsToCheck.Add($p) | Out-Null
        }
    }

    foreach ($rawPath in $pathsToCheck) {
        $relativePath = Get-ToolkitNormalizedRelativePath -FilePath $rawPath -WorkspaceRoot $WorkspaceRoot
        if ($null -eq $relativePath) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'outside_workspace'
                UserMessage  = ("Blocked: path outside workspace ({0})." -f $rawPath)
                AgentMessage = ("Hook denied tool targeting '{0}'. Paths must resolve under the workspace root; extension allowlists do not apply outside the workspace." -f $rawPath)
                RelativePath = $rawPath
                SecretType   = ''
            }
        }
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            # Bare forbidden tokens from shell scan (e.g. "PRD").
            if ((Test-ToolkitForbiddenSddPath -RelativePath $rawPath) -or (Test-ToolkitDeniedPathSegment -RelativePath $rawPath)) {
                return [PSCustomObject]@{
                    Decision     = 'deny'
                    Reason       = 'forbidden_path'
                    UserMessage  = ("Blocked: path outside allowed scopes ({0})." -f $rawPath)
                    AgentMessage = ("Hook denied tool targeting '{0}'. SDD artifacts belong under features/; avoid legacy PRD/PLAN trees and denied segments." -f $rawPath)
                    RelativePath = $rawPath
                    SecretType   = ''
                }
            }
            continue
        }

        if (-not (Test-ToolkitAllowedWritePath -RelativePath $relativePath)) {
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'forbidden_path'
                UserMessage  = ("Blocked: path outside allowed scopes ({0})." -f $relativePath)
                AgentMessage = ("Hook denied tool targeting '{0}'. SDD artifacts belong under features/ (see sdd-pipeline-guards). Application code must live under standard source trees or use an allowed extension." -f $relativePath)
                RelativePath = $relativePath
                SecretType   = ''
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($contentToScan)) {
        $secretFindings = @(Get-ToolkitSecretFindings -Content $contentToScan)
        if ($secretFindings.Count -gt 0) {
            $first = $secretFindings[0]
            return [PSCustomObject]@{
                Decision     = 'deny'
                Reason       = 'secret_pattern'
                UserMessage  = ("Blocked: possible secret ({0}) near line {1}." -f $first.Type, $first.Line)
                AgentMessage = ("Hook denied tool because content matches secret pattern '{0}'. Use env var names or placeholders. Never commit API keys, tokens, passwords, or private keys." -f $first.Type)
                RelativePath = ''
                SecretType   = [string]$first.Type
            }
        }
    }

    return $allow
}

function Resolve-ToolkitGuardCommonPath {
    <#
    .SYNOPSIS
      Locate adapters/_shared/GuardCommon.ps1 from a hook script directory.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string] $FromDirectory
    )

    $candidates = @(
        (Join-Path $FromDirectory 'GuardCommon.ps1'),
        (Join-Path $FromDirectory '..\..\..\_shared\GuardCommon.ps1'),
        (Join-Path $FromDirectory '..\..\..\..\_shared\GuardCommon.ps1')
    )
    foreach ($candidate in $candidates) {
        try {
            $full = [System.IO.Path]::GetFullPath($candidate)
        }
        catch {
            continue
        }
        if (Test-Path -LiteralPath $full) {
            return $full
        }
    }
    return $null
}
