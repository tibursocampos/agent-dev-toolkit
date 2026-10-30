#Requires -Version 5.1
# Tests:
#   Should_PreserveUserKeys_And_BeIdempotent_When_ClaudeSettingsMerged
#   Should_RemoveOnlyToolkitEntries_When_Uninstall
#   Should_AbortWithoutOverwrite_When_SettingsMalformedOrWrongShape
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
$utf8 = New-Object System.Text.UTF8Encoding $false
function Write-Json { param([string] $Path, [string] $Json) [System.IO.File]::WriteAllText($Path, $Json, $utf8) }
function Read-Json { param([string] $Path) [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json }
function Assert-Merged { param([string] $Name, $Result) if ($null -eq $Result -or $Result.Success -ne $true) { Write-Fail $Name ("merge must succeed: {0}" -f $(if ($Result) { $Result.Message } else { 'null' })) } }

$alienKey = 'operatorCustomKey'
$alienValue = 'must-survive-merge'
$alienMarker = 'alien-notification-hook'
$colocatedMarker = 'user-colocated-userpromptsubmit-hook'
$userAllow = 'Bash(git status)'
$legacyBroad = @('Bash(pwsh *)', 'Bash(powershell *)')

$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    # --- merge: user keys/hooks/permissions survive, toolkit entries upserted once, legacy removed ---
    $n = 'Should_PreserveUserKeys_And_BeIdempotent_When_ClaudeSettingsMerged'
    $h = Join-Path $work 'merge'
    New-Item -ItemType Directory -Path $h -Force | Out-Null
    $sp = Join-Path $h 'settings.json'
    $seed = @{
        $alienKey   = $alienValue
        hooks       = @{
            Notification     = @(@{ hooks = @(@{ type = 'command'; command = $alienMarker }) })
            UserPromptSubmit = @(@{ hooks = @(@{ type = 'command'; command = $colocatedMarker }) })
            PreCompact       = @(@{ hooks = @(@{ type = 'command'; command = 'pwsh -NoProfile -File "C:/old/hooks/context-pre-compact.ps1"' }) })
        }
        permissions = @{ allow = @($userAllow) + $legacyBroad; deny = @('Bash(rm -rf *)') }
    } | ConvertTo-Json -Depth 10
    Write-Json $sp $seed
    Assert-Merged $n (Invoke-ClaudeMergeSettings -InstallRoot $h)
    Assert-Merged $n (Invoke-ClaudeMergeSettings -InstallRoot $h)
    $after = Read-Json $sp
    $bytes = [System.IO.File]::ReadAllBytes($sp)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { Write-Fail $n 'settings.json must be UTF-8 without BOM' }
    if ($after.$alienKey -ne $alienValue) { Write-Fail $n 'unrelated key lost' }
    if ([string]$after.hooks.Notification[0].hooks[0].command -ne $alienMarker) { Write-Fail $n 'alien hook event altered' }
    if (-not ($after.permissions.deny -contains 'Bash(rm -rf *)')) { Write-Fail $n 'permissions.deny lost' }
    $upj = $after.hooks.UserPromptSubmit | ConvertTo-Json -Compress -Depth 10
    if ($upj -notmatch [regex]::Escape($colocatedMarker)) { Write-Fail $n 'colocated alien handler lost' }
    if (@([regex]::Matches($upj, [regex]::Escape('track-sdd-invocation.ps1'))).Count -ne 1) { Write-Fail $n 'toolkit handler must appear exactly once after two merges' }
    if ($after.hooks.PSObject.Properties.Name -contains 'PreCompact') { Write-Fail $n 'legacy toolkit event must be removed' }
    foreach ($eventProperty in $after.hooks.PSObject.Properties) {
        $eventValue = $eventProperty.Value
        if ($eventValue -isnot [System.Array]) { Write-Fail $n ("hooks.{0} must be an array" -f $eventProperty.Name) }
        foreach ($item in $eventValue) {
            if ($item -is [System.Array] -or $item -isnot [System.Management.Automation.PSCustomObject]) { Write-Fail $n ("hooks.{0} items must be matcher-group objects, not nested arrays" -f $eventProperty.Name) }
        }
    }
    $allow = @($after.permissions.allow)
    if (-not ($allow -contains $userAllow)) { Write-Fail $n 'user allow entry lost' }
    foreach ($l in $legacyBroad) { if ($allow -contains $l) { Write-Fail $n "legacy allow '$l' must be stripped" } }
    foreach ($e in @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $h)) {
        if (@($allow | Where-Object { $_ -eq $e }).Count -ne 1) { Write-Fail $n "managed allow '$e' must appear once" }
    }
    if (-not (Test-Path -LiteralPath ($sp + '.bak'))) { Write-Fail $n 'backup settings.json.bak missing' }
    Write-Pass $n

    # --- uninstall: toolkit handlers/allow removed, user entries kept ---
    $n = 'Should_RemoveOnlyToolkitEntries_When_Uninstall'
    $u = Uninstall-Toolkit -InstallRoot $h
    if ($null -eq $u -or $u.Success -ne $true) { Write-Fail $n ("uninstall must succeed: {0}" -f $(if ($u) { $u.Message } else { 'null' })) }
    $un = Read-Json $sp
    $upj = $un.hooks.UserPromptSubmit | ConvertTo-Json -Compress -Depth 10
    if ($upj -notmatch [regex]::Escape($colocatedMarker)) { Write-Fail $n 'alien handler must survive uninstall' }
    if ($upj -match [regex]::Escape('track-sdd-invocation.ps1')) { Write-Fail $n 'toolkit handler must be removed' }
    if ($un.hooks.PSObject.Properties.Name -contains 'PostToolUse') { Write-Fail $n 'toolkit-only event must be removed' }
    if ($un.$alienKey -ne $alienValue -or [string]$un.hooks.Notification[0].hooks[0].command -ne $alienMarker) { Write-Fail $n 'user keys/hooks lost on uninstall' }
    $allow = @($un.permissions.allow)
    if (-not ($allow -contains $userAllow)) { Write-Fail $n 'user allow entry lost on uninstall' }
    foreach ($e in @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $h)) { if ($allow -contains $e) { Write-Fail $n "managed allow '$e' must be removed" } }
    Write-Pass $n

    # --- malformed / wrong-shape settings: abort, bytes unchanged, no backup ---
    $n = 'Should_AbortWithoutOverwrite_When_SettingsMalformedOrWrongShape'
    $cases = @(
        @{ Name = 'invalid-json'; Json = '{ this is not valid json'; Msg = '' },
        @{ Name = 'hooks-array'; Json = ('{{ "{0}": "{1}", "hooks": ["x"], "permissions": {{ "allow": ["{2}"] }} }}' -f $alienKey, $alienValue, $userAllow); Msg = 'hooks must be a JSON object' },
        @{ Name = 'permissions-array'; Json = ('{{ "{0}": "{1}", "hooks": {{}}, "permissions": ["x"] }}' -f $alienKey, $alienValue); Msg = 'permissions must be a JSON object' }
    )
    foreach ($c in $cases) {
        $dir = Join-Path $work $c.Name
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $p = Join-Path $dir 'settings.json'
        Write-Json $p $c.Json
        $m = Invoke-ClaudeMergeSettings -InstallRoot $dir
        if ($null -eq $m -or $m.Success -ne $false) { Write-Fail $n "$($c.Name): merge must fail closed" }
        if ($c.Msg -and [string]$m.Message -notmatch "(?i)$($c.Msg)") { Write-Fail $n "$($c.Name): message must explain: $($m.Message)" }
        if ([System.IO.File]::ReadAllText($p) -ne $c.Json) { Write-Fail $n "$($c.Name): settings.json was modified" }
        if (Test-Path -LiteralPath ($p + '.bak')) { Write-Fail $n "$($c.Name): backup must not be taken on abort" }
    }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

Write-Host 'Assert-ClaudeSettingsMerge: ALL PASS'
exit 0
