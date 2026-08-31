#Requires -Version 5.1
# Tests:
#   Should_PreserveUnrelatedKeys_When_ClaudeSettingsMerged
#   Should_MergeHooksByKey_When_ClaudeSettingsMerged
#   Should_PreserveAlienHandler_When_ColocatedOnManagedEvent
#   Should_AddPermissionsAllowEntries_When_ClaudeSettingsMerged
#   Should_WriteUtf8WithoutBom_When_ClaudeSettingsSaved
#   Should_NotDuplicateToolkitAllowEntries_When_SyncRunsTwice
#   Should_AbortWithoutOverwrite_When_SettingsJsonInvalid
#   Should_AbortWithoutWiping_When_HooksIsNotObject
#   Should_AbortWithoutWiping_When_PermissionsIsNotObject
#   Should_PreserveAlienHandler_When_UninstallRemovesToolkitHooks
#   Should_LoadClaudeMergeFixture_When_SmokeStarts
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
$repoRootScript = Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1'

function Write-Pass {
    param([Parameter(Mandatory = $true)][string] $TestName)
    Write-Host ("{0}: PASS" -f $TestName)
}

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)][string] $TestName,
        [Parameter(Mandatory = $true)][string] $Reason
    )
    Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason)
    exit 1
}

function Get-Utf8NoBomEncoding {
    return (New-Object System.Text.UTF8Encoding $false)
}

function Write-JsonFileNoBom {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Json
    )
    [System.IO.File]::WriteAllText($Path, $Json, (Get-Utf8NoBomEncoding))
}

function Read-SettingsObject {
    param([Parameter(Mandatory = $true)][string] $Path)
    return ([System.IO.File]::ReadAllText($Path) | ConvertFrom-Json)
}

function Test-FileHasUtf8Bom {
    param([Parameter(Mandatory = $true)][string] $Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 3) {
        return $false
    }
    return ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

function New-MergeHarnessRoot {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $Name
    )
    $root = Join-Path $RepoRoot ("scripts\validation\fixtures\claude-merge-harness\{0}" -f $Name)
    if (Test-Path -LiteralPath $root) {
        Remove-Item -LiteralPath $root -Recurse -Force
    }
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

if (-not (Test-Path -LiteralPath $repoRootScript)) {
    Write-Fail -TestName 'Assert-ClaudeSettingsMergePreconditions' -Reason ("missing {0}" -f $repoRootScript)
}

. $repoRootScript

$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$claudeModulePath = Join-Path $repoRoot 'adapters\claude\ClaudeAdapter.ps1'

if (-not (Test-Path -LiteralPath $claudeModulePath)) {
    Write-Fail -TestName 'Assert-ClaudeSettingsMergePreconditions' -Reason ("missing Claude module: {0}" -f $claudeModulePath)
}

. $claudeModulePath

$alienKeyName = 'operatorCustomKey'
$alienKeyValue = 'must-survive-merge'
$alienHookEvent = 'Notification'
$alienHookMarker = 'alien-notification-hook'
$userAllowEntry = 'Bash(git status)'
$legacyBroadAllowPwsh = 'Bash(pwsh *)'
$legacyBroadAllowPowershell = 'Bash(powershell *)'
$managedHookEvents = @('UserPromptSubmit', 'PreCompact', 'PostToolUse', 'PreToolUse')
$invalidJsonMarker = '{ this is not valid json'


$resolveInstallRootScript = Join-Path $scriptsRoot '_lib\Resolve-InstallRoot.ps1'
if (-not (Test-Path -LiteralPath $resolveInstallRootScript)) {
    Write-Fail -TestName 'Assert-ClaudeSettingsMergePreconditions' -Reason ("missing {0}" -f $resolveInstallRootScript)
}
. $resolveInstallRootScript

$fixtureInstallRoot = Join-Path $repoRoot 'scripts\validation\fixtures\claude'
$fixtureSettingsPath = Join-Path $fixtureInstallRoot 'settings.json'
$fixtureReadmePath = Join-Path $fixtureInstallRoot 'README.md'
$documentedRelativePath = 'scripts/validation/fixtures/claude'
$staleManagedHookCommand = 'stale-user-prompt'
$userProfile = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($userProfile)) {
    Write-Fail -TestName 'Assert-ClaudeSettingsMergePreconditions' -Reason 'USERPROFILE is not set'
}
if (-not (Test-Path -LiteralPath $fixtureInstallRoot)) {
    Write-Fail -TestName 'Assert-ClaudeSettingsMergePreconditions' -Reason ("missing Claude fixture: {0}" -f $fixtureInstallRoot)
}
if (-not (Test-Path -LiteralPath $fixtureSettingsPath)) {
    Write-Fail -TestName 'Assert-ClaudeSettingsMergePreconditions' -Reason ("missing seed settings.json: {0}" -f $fixtureSettingsPath)
}
if (-not (Test-Path -LiteralPath $fixtureReadmePath)) {
    Write-Fail -TestName 'Assert-ClaudeSettingsMergePreconditions' -Reason ("missing fixture README: {0}" -f $fixtureReadmePath)
}

# --- Should_PreserveUnrelatedKeys_When_ClaudeSettingsMerged ---
$testName = 'Should_PreserveUnrelatedKeys_When_ClaudeSettingsMerged'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'preserve-keys'
$settingsPath = Join-Path $harness 'settings.json'
$seed = @{
    $alienKeyName = $alienKeyValue
    hooks         = @{
        $alienHookEvent = @(
            @{
                hooks = @(
                    @{
                        type    = 'command'
                        command = $alienHookMarker
                    }
                )
            }
        )
    }
    permissions   = @{
        allow = @($userAllowEntry)
        deny  = @('Bash(rm -rf *)')
    }
} | ConvertTo-Json -Depth 10
Write-JsonFileNoBom -Path $settingsPath -Json $seed

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("merge must succeed: {0}" -f $(if ($merge) { $merge.Message } else { 'null' }))
}

$after = Read-SettingsObject -Path $settingsPath
if ($after.$alienKeyName -ne $alienKeyValue) {
    Write-Fail -TestName $testName -Reason ("unrelated key '{0}' was not preserved" -f $alienKeyName)
}
if (-not $after.hooks.PSObject.Properties.Name -contains $alienHookEvent) {
    Write-Fail -TestName $testName -Reason ("alien hook event '{0}' was removed" -f $alienHookEvent)
}
$alienCmd = [string]$after.hooks.$alienHookEvent[0].hooks[0].command
if ($alienCmd -ne $alienHookMarker) {
    Write-Fail -TestName $testName -Reason 'alien hook command was altered'
}
if (-not ($after.permissions.deny -contains 'Bash(rm -rf *)')) {
    Write-Fail -TestName $testName -Reason 'permissions.deny must be preserved'
}
if (-not (Test-Path -LiteralPath ($settingsPath + '.bak'))) {
    Write-Fail -TestName $testName -Reason 'backup settings.json.bak must exist after merge over existing file'
}
$timestampedBackups = @(Get-ChildItem -LiteralPath $harness -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^settings\.json\.bak\.\d{14}$' })
if ($timestampedBackups.Count -lt 1) {
    Write-Fail -TestName $testName -Reason 'timestamped backup settings.json.bak.<yyyyMMddHHmmss> must exist after merge over existing file'
}
Write-Pass -TestName $testName

# --- Should_MergeHooksByKey_When_ClaudeSettingsMerged ---
$testName = 'Should_MergeHooksByKey_When_ClaudeSettingsMerged'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'hooks-keyed'
$settingsPath = Join-Path $harness 'settings.json'
$seed = @{
    hooks = @{
        $alienHookEvent     = @(@{ hooks = @(@{ type = 'command'; command = $alienHookMarker }) })
        UserPromptSubmit    = @(@{ hooks = @(@{ type = 'command'; command = 'stale-user-prompt' }) })
    }
} | ConvertTo-Json -Depth 10
Write-JsonFileNoBom -Path $settingsPath -Json $seed

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("merge must succeed: {0}" -f $(if ($merge) { $merge.Message } else { 'null' }))
}

$after = Read-SettingsObject -Path $settingsPath
foreach ($eventName in $managedHookEvents) {
    if (-not ($after.hooks.PSObject.Properties.Name -contains $eventName)) {
        Write-Fail -TestName $testName -Reason ("managed hook event missing: {0}" -f $eventName)
    }
}
$userPromptCmd = [string]$after.hooks.UserPromptSubmit[0].hooks[0].command
if ($userPromptCmd -match 'stale-user-prompt') {
    Write-Fail -TestName $testName -Reason 'managed UserPromptSubmit must be upserted (stale value remains)'
}
if ($userPromptCmd -notmatch 'context-before-prompt\.ps1') {
    Write-Fail -TestName $testName -Reason 'UserPromptSubmit must point at context-before-prompt.ps1'
}
if (-not ($after.hooks.PSObject.Properties.Name -contains $alienHookEvent)) {
    Write-Fail -TestName $testName -Reason 'alien hook event must remain'
}
Write-Pass -TestName $testName

# --- Should_PreserveAlienHandler_When_ColocatedOnManagedEvent ---
$testName = 'Should_PreserveAlienHandler_When_ColocatedOnManagedEvent'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'hooks-colocated'
$settingsPath = Join-Path $harness 'settings.json'
$colocatedAlienMarker = 'user-colocated-userpromptsubmit-hook'
$seed = @{
    hooks = @{
        UserPromptSubmit = @(@{ hooks = @(@{ type = 'command'; command = $colocatedAlienMarker }) })
    }
} | ConvertTo-Json -Depth 10
Write-JsonFileNoBom -Path $settingsPath -Json $seed

$firstMerge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $firstMerge -or $firstMerge.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("first merge must succeed: {0}" -f $(if ($firstMerge) { $firstMerge.Message } else { 'null' }))
}

$afterFirst = Read-SettingsObject -Path $settingsPath
$userPromptEntriesFirst = @($afterFirst.hooks.UserPromptSubmit)
$firstEntryCmd = [string]$userPromptEntriesFirst[0].hooks[0].command
if ($firstEntryCmd -notmatch 'context-before-prompt\.ps1') {
    Write-Fail -TestName $testName -Reason 'toolkit handler must be present (upserted) on the managed event'
}
$colocatedJsonFirst = ($userPromptEntriesFirst | ConvertTo-Json -Compress -Depth 10)
if ($colocatedJsonFirst -notmatch [regex]::Escape($colocatedAlienMarker)) {
    Write-Fail -TestName $testName -Reason 'alien handler co-located on the same managed event must survive the merge'
}

# Re-sync must not duplicate the toolkit handler nor drop the alien one.
$secondMerge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $secondMerge -or $secondMerge.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("second merge must succeed: {0}" -f $(if ($secondMerge) { $secondMerge.Message } else { 'null' }))
}

$afterSecond = Read-SettingsObject -Path $settingsPath
$userPromptEntriesSecond = @($afterSecond.hooks.UserPromptSubmit)
$colocatedJsonSecond = ($userPromptEntriesSecond | ConvertTo-Json -Compress -Depth 10)
$toolkitOccurrences = @([regex]::Matches($colocatedJsonSecond, [regex]::Escape('context-before-prompt.ps1'))).Count
if ($toolkitOccurrences -ne 1) {
    Write-Fail -TestName $testName -Reason ("toolkit handler must appear once after re-sync, got {0}" -f $toolkitOccurrences)
}
if ($colocatedJsonSecond -notmatch [regex]::Escape($colocatedAlienMarker)) {
    Write-Fail -TestName $testName -Reason 'alien handler co-located on the same managed event must survive re-sync'
}
Write-Pass -TestName $testName

# --- Should_AddPermissionsAllowEntries_When_ClaudeSettingsMerged ---
$testName = 'Should_AddPermissionsAllowEntries_When_ClaudeSettingsMerged'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'allow-additive'
$settingsPath = Join-Path $harness 'settings.json'
$seed = @{
    permissions = @{
        allow = @($userAllowEntry, $legacyBroadAllowPwsh, $legacyBroadAllowPowershell)
    }
} | ConvertTo-Json -Depth 10
Write-JsonFileNoBom -Path $settingsPath -Json $seed

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("merge must succeed: {0}" -f $(if ($merge) { $merge.Message } else { 'null' }))
}

$after = Read-SettingsObject -Path $settingsPath
$allow = @($after.permissions.allow)
if (-not ($allow -contains $userAllowEntry)) {
    Write-Fail -TestName $testName -Reason 'user allow entry must remain'
}
$expectedManagedAllow = @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $harness)
if ($expectedManagedAllow.Count -lt 1) {
    Write-Fail -TestName $testName -Reason 'expected at least one narrow managed allow entry'
}
foreach ($entry in $expectedManagedAllow) {
    if (-not ($allow -contains $entry)) {
        Write-Fail -TestName $testName -Reason ("toolkit allow missing: {0}" -f $entry)
    }
    if ($entry -eq $legacyBroadAllowPwsh -or $entry -eq $legacyBroadAllowPowershell) {
        Write-Fail -TestName $testName -Reason 'default managed allow must not be legacy broad wildcards'
    }
}
if ($allow -contains $legacyBroadAllowPwsh -or $allow -contains $legacyBroadAllowPowershell) {
    Write-Fail -TestName $testName -Reason 'legacy Bash(pwsh *) / Bash(powershell *) must be stripped by default re-sync'
}
Write-Pass -TestName $testName

# --- Should_WriteUtf8WithoutBom_When_ClaudeSettingsSaved ---
$testName = 'Should_WriteUtf8WithoutBom_When_ClaudeSettingsSaved'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'utf8-nobom'
$settingsPath = Join-Path $harness 'settings.json'
Write-JsonFileNoBom -Path $settingsPath -Json '{ "permissions": { "allow": [] } }'

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("merge must succeed: {0}" -f $(if ($merge) { $merge.Message } else { 'null' }))
}
if (Test-FileHasUtf8Bom -Path $settingsPath) {
    Write-Fail -TestName $testName -Reason 'settings.json must be UTF-8 without BOM'
}
Write-Pass -TestName $testName

# --- Should_NotDuplicateToolkitAllowEntries_When_SyncRunsTwice ---
$testName = 'Should_NotDuplicateToolkitAllowEntries_When_SyncRunsTwice'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'allow-idempotent'
$settingsPath = Join-Path $harness 'settings.json'
Write-JsonFileNoBom -Path $settingsPath -Json ('{{ "permissions": {{ "allow": ["{0}"] }} }}' -f $userAllowEntry)

$first = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $first -or $first.Success -ne $true) {
    Write-Fail -TestName $testName -Reason 'first merge must succeed'
}
$second = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $second -or $second.Success -ne $true) {
    Write-Fail -TestName $testName -Reason 'second merge must succeed'
}

$after = Read-SettingsObject -Path $settingsPath
$allow = @($after.permissions.allow)
$expectedManagedAllow = @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $harness)
foreach ($entry in $expectedManagedAllow) {
    $count = @($allow | Where-Object { $_ -eq $entry }).Count
    if ($count -ne 1) {
        Write-Fail -TestName $testName -Reason ("toolkit '{0}' must appear once, got {1}" -f $entry, $count)
    }
}
if ($allow -contains $legacyBroadAllowPwsh -or $allow -contains $legacyBroadAllowPowershell) {
    Write-Fail -TestName $testName -Reason 'legacy broad wildcards must not appear after default sync'
}
if (-not ($allow -contains $userAllowEntry)) {
    Write-Fail -TestName $testName -Reason 'user allow entry must remain after re-sync'
}
Write-Pass -TestName $testName

# --- Should_AbortWithoutOverwrite_When_SettingsJsonInvalid ---
$testName = 'Should_AbortWithoutOverwrite_When_SettingsJsonInvalid'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'invalid-json'
$settingsPath = Join-Path $harness 'settings.json'
Write-JsonFileNoBom -Path $settingsPath -Json $invalidJsonMarker
$beforeBytes = [System.IO.File]::ReadAllBytes($settingsPath)

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $false) {
    Write-Fail -TestName $testName -Reason 'merge must fail closed on invalid JSON'
}
$afterBytes = [System.IO.File]::ReadAllBytes($settingsPath)
if ($afterBytes.Length -ne $beforeBytes.Length) {
    Write-Fail -TestName $testName -Reason 'invalid settings.json must not be overwritten'
}
for ($i = 0; $i -lt $beforeBytes.Length; $i++) {
    if ($afterBytes[$i] -ne $beforeBytes[$i]) {
        Write-Fail -TestName $testName -Reason 'invalid settings.json bytes must remain unchanged'
    }
}
if (Test-Path -LiteralPath ($settingsPath + '.bak')) {
    Write-Fail -TestName $testName -Reason 'backup must not be taken when JSON is invalid'
}
$rawAfter = [System.IO.File]::ReadAllText($settingsPath)
if ($rawAfter -ne $invalidJsonMarker) {
    Write-Fail -TestName $testName -Reason 'original invalid content must be preserved'
}
Write-Pass -TestName $testName

# --- Should_AbortWithoutWiping_When_HooksIsNotObject ---
$testName = 'Should_AbortWithoutWiping_When_HooksIsNotObject'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'hooks-not-object'
$settingsPath = Join-Path $harness 'settings.json'
$nonDictHooksMarker = 'alien-hooks-array-must-survive'
$seedNonDictHooks = ('{{ "{0}": "{1}", "hooks": ["{2}"], "permissions": {{ "allow": ["{3}"] }} }}' -f $alienKeyName, $alienKeyValue, $nonDictHooksMarker, $userAllowEntry)
Write-JsonFileNoBom -Path $settingsPath -Json $seedNonDictHooks
$beforeNonDictBytes = [System.IO.File]::ReadAllBytes($settingsPath)

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $false) {
    Write-Fail -TestName $testName -Reason 'merge must fail closed when hooks is not a JSON object'
}
if ([string]::IsNullOrWhiteSpace([string]$merge.Message) -or $merge.Message -notmatch '(?i)hooks must be a JSON object') {
    Write-Fail -TestName $testName -Reason ("merge failure message must explain non-object hooks: {0}" -f $(if ($merge) { $merge.Message } else { 'null' }))
}
$afterNonDictBytes = [System.IO.File]::ReadAllBytes($settingsPath)
if ($afterNonDictBytes.Length -ne $beforeNonDictBytes.Length) {
    Write-Fail -TestName $testName -Reason 'settings.json must not be overwritten when hooks is not an object'
}
for ($i = 0; $i -lt $beforeNonDictBytes.Length; $i++) {
    if ($afterNonDictBytes[$i] -ne $beforeNonDictBytes[$i]) {
        Write-Fail -TestName $testName -Reason 'settings.json bytes must remain unchanged when hooks is not an object'
    }
}
if (Test-Path -LiteralPath ($settingsPath + '.bak')) {
    Write-Fail -TestName $testName -Reason 'backup must not be taken when hooks merge is aborted'
}
$rawAfterNonDict = [System.IO.File]::ReadAllText($settingsPath)
if ($rawAfterNonDict -ne $seedNonDictHooks) {
    Write-Fail -TestName $testName -Reason 'original non-object hooks content must be preserved'
}
$afterNonDict = Read-SettingsObject -Path $settingsPath
if ($afterNonDict.$alienKeyName -ne $alienKeyValue) {
    Write-Fail -TestName $testName -Reason 'unrelated keys must survive abort'
}
$hooksAfter = @($afterNonDict.hooks)
if ($hooksAfter.Count -ne 1 -or [string]$hooksAfter[0] -ne $nonDictHooksMarker) {
    Write-Fail -TestName $testName -Reason 'non-object hooks array must not be wiped to {}'
}
Write-Pass -TestName $testName

# --- Should_AbortWithoutWiping_When_PermissionsIsNotObject ---
$testName = 'Should_AbortWithoutWiping_When_PermissionsIsNotObject'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'permissions-not-object'
$settingsPath = Join-Path $harness 'settings.json'
$nonDictPermissionsMarker = 'alien-permissions-array-must-survive'
$seedNonDictPermissions = ('{{ "{0}": "{1}", "hooks": {{}}, "permissions": ["{2}"] }}' -f $alienKeyName, $alienKeyValue, $nonDictPermissionsMarker)
Write-JsonFileNoBom -Path $settingsPath -Json $seedNonDictPermissions
$beforeNonDictPermBytes = [System.IO.File]::ReadAllBytes($settingsPath)

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $false) {
    Write-Fail -TestName $testName -Reason 'merge must fail closed when permissions is not a JSON object'
}
if ([string]::IsNullOrWhiteSpace([string]$merge.Message) -or $merge.Message -notmatch '(?i)permissions must be a JSON object') {
    Write-Fail -TestName $testName -Reason ("merge failure message must explain non-object permissions: {0}" -f $(if ($merge) { $merge.Message } else { 'null' }))
}
$afterNonDictPermBytes = [System.IO.File]::ReadAllBytes($settingsPath)
if ($afterNonDictPermBytes.Length -ne $beforeNonDictPermBytes.Length) {
    Write-Fail -TestName $testName -Reason 'settings.json must not be overwritten when permissions is not an object'
}
for ($i = 0; $i -lt $beforeNonDictPermBytes.Length; $i++) {
    if ($afterNonDictPermBytes[$i] -ne $beforeNonDictPermBytes[$i]) {
        Write-Fail -TestName $testName -Reason 'settings.json bytes must remain unchanged when permissions is not an object'
    }
}
if (Test-Path -LiteralPath ($settingsPath + '.bak')) {
    Write-Fail -TestName $testName -Reason 'backup must not be taken when permissions merge is aborted'
}
$rawAfterNonDictPerm = [System.IO.File]::ReadAllText($settingsPath)
if ($rawAfterNonDictPerm -ne $seedNonDictPermissions) {
    Write-Fail -TestName $testName -Reason 'original non-object permissions content must be preserved'
}
$afterNonDictPerm = Read-SettingsObject -Path $settingsPath
if ($afterNonDictPerm.$alienKeyName -ne $alienKeyValue) {
    Write-Fail -TestName $testName -Reason 'unrelated keys must survive abort'
}
$permissionsAfter = @($afterNonDictPerm.permissions)
if ($permissionsAfter.Count -ne 1 -or [string]$permissionsAfter[0] -ne $nonDictPermissionsMarker) {
    Write-Fail -TestName $testName -Reason 'non-object permissions array must not be wiped to {}'
}
Write-Pass -TestName $testName

# --- Should_PreserveAlienHandler_When_UninstallRemovesToolkitHooks ---
$testName = 'Should_PreserveAlienHandler_When_UninstallRemovesToolkitHooks'
$harness = New-MergeHarnessRoot -RepoRoot $repoRoot -Name 'uninstall-colocated'
$settingsPath = Join-Path $harness 'settings.json'
$uninstallAlienMarker = 'user-colocated-survives-uninstall'
$seed = @{
    hooks = @{
        UserPromptSubmit = @(@{ hooks = @(@{ type = 'command'; command = $uninstallAlienMarker }) })
    }
    permissions = @{
        allow = @($userAllowEntry)
    }
} | ConvertTo-Json -Depth 10
Write-JsonFileNoBom -Path $settingsPath -Json $seed

$merge = Invoke-ClaudeMergeSettings -InstallRoot $harness
if ($null -eq $merge -or $merge.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("merge must succeed: {0}" -f $(if ($merge) { $merge.Message } else { 'null' }))
}

$beforeUninstall = Read-SettingsObject -Path $settingsPath
$beforeJson = ($beforeUninstall.hooks.UserPromptSubmit | ConvertTo-Json -Compress -Depth 10)
if ($beforeJson -notmatch [regex]::Escape($uninstallAlienMarker)) {
    Write-Fail -TestName $testName -Reason 'precondition: alien handler must be co-located after merge'
}
if ($beforeJson -notmatch [regex]::Escape('context-before-prompt.ps1')) {
    Write-Fail -TestName $testName -Reason 'precondition: toolkit handler must be present after merge'
}

$uninstall = Uninstall-Toolkit -InstallRoot $harness
if ($null -eq $uninstall -or $uninstall.Success -ne $true) {
    Write-Fail -TestName $testName -Reason ("uninstall must succeed: {0}" -f $(if ($uninstall) { $uninstall.Message } else { 'null' }))
}

$afterUninstall = Read-SettingsObject -Path $settingsPath
if (-not ($afterUninstall.hooks.PSObject.Properties.Name -contains 'UserPromptSubmit')) {
    Write-Fail -TestName $testName -Reason 'UserPromptSubmit event must remain when an alien handler is co-located'
}
$afterJson = ($afterUninstall.hooks.UserPromptSubmit | ConvertTo-Json -Compress -Depth 10)
if ($afterJson -notmatch [regex]::Escape($uninstallAlienMarker)) {
    Write-Fail -TestName $testName -Reason 'alien handler co-located on UserPromptSubmit must survive uninstall'
}
if ($afterJson -match [regex]::Escape('context-before-prompt.ps1')) {
    Write-Fail -TestName $testName -Reason 'toolkit managed handler must be removed on uninstall'
}
if ($afterUninstall.hooks.PSObject.Properties.Name -contains 'PreCompact') {
    Write-Fail -TestName $testName -Reason 'PreCompact must be removed when only toolkit handlers were present'
}
if ($afterUninstall.hooks.PSObject.Properties.Name -contains 'PostToolUse') {
    Write-Fail -TestName $testName -Reason 'PostToolUse must be removed when only toolkit handlers were present'
}
$allowAfter = @($afterUninstall.permissions.allow)
if (-not ($allowAfter -contains $userAllowEntry)) {
    Write-Fail -TestName $testName -Reason 'user allow entry must survive uninstall'
}
foreach ($entry in @(Get-ClaudeManagedPermissionsAllowEntries -InstallRoot $harness)) {
    if ($allowAfter -contains $entry) {
        Write-Fail -TestName $testName -Reason ("managed allow entry must be removed on uninstall: {0}" -f $entry)
    }
}
if ($allowAfter -contains $legacyBroadAllowPwsh -or $allowAfter -contains $legacyBroadAllowPowershell) {
    Write-Fail -TestName $testName -Reason 'legacy broad allow entries must not remain after uninstall'
}
Write-Pass -TestName $testName

# --- Should_LoadClaudeMergeFixture_When_SmokeStarts ---
$testName = 'Should_LoadClaudeMergeFixture_When_SmokeStarts'

$resolved = Resolve-InstallRoot -InstallRoot $fixtureInstallRoot
$expectedResolved = [System.IO.Path]::GetFullPath($fixtureInstallRoot)
$comparison = [System.StringComparison]::OrdinalIgnoreCase

if (-not [string]::Equals([System.IO.Path]::GetFullPath($resolved), $expectedResolved, $comparison)) {
    Write-Fail -TestName $testName -Reason ("Resolve-InstallRoot mismatch: {0}" -f $resolved)
}

if (-not (Test-IsPathUnderOrEqual -ChildPath $resolved -ParentPath $repoRoot)) {
    Write-Fail -TestName $testName -Reason 'fixture InstallRoot must resolve under toolkit repo'
}

$normalizedUserProfile = [System.IO.Path]::GetFullPath($userProfile)
if (Test-IsPathUnderOrEqual -ChildPath $resolved -ParentPath $normalizedUserProfile) {
    Write-Fail -TestName $testName -Reason 'Claude merge fixture must not resolve under USERPROFILE'
}

$readmeText = Get-Content -LiteralPath $fixtureReadmePath -Raw
if ($readmeText -notmatch [regex]::Escape($documentedRelativePath)) {
    Write-Fail -TestName $testName -Reason ("fixture README must document {0}" -f $documentedRelativePath)
}
if ($readmeText -notmatch '(?i)InstallRoot') {
    Write-Fail -TestName $testName -Reason 'fixture README must document InstallRoot usage'
}
if ($readmeText -match '(?i)InstallRoot[^\r\n]{0,80}(%USERPROFILE%|\$env:USERPROFILE)') {
    Write-Fail -TestName $testName -Reason 'fixture README must not set InstallRoot under USERPROFILE'
}

if (Test-FileHasUtf8Bom -Path $fixtureSettingsPath) {
    Write-Fail -TestName $testName -Reason 'seed settings.json must be UTF-8 without BOM'
}

try {
    $settings = [System.IO.File]::ReadAllText($fixtureSettingsPath) | ConvertFrom-Json
}
catch {
    Write-Fail -TestName $testName -Reason ("seed settings.json must parse as JSON: {0}" -f $_.Exception.Message)
}

if ($null -eq $settings) {
    Write-Fail -TestName $testName -Reason 'seed settings.json parsed to null'
}

if ($settings.$alienKeyName -ne $alienKeyValue) {
    Write-Fail -TestName $testName -Reason ("seed must include alien key {0}={1}" -f $alienKeyName, $alienKeyValue)
}

if (-not ($settings.hooks.PSObject.Properties.Name -contains $alienHookEvent)) {
    Write-Fail -TestName $testName -Reason ("seed must include alien hook event {0}" -f $alienHookEvent)
}

$alienCmd = [string]$settings.hooks.$alienHookEvent[0].hooks[0].command
if ($alienCmd -ne $alienHookMarker) {
    Write-Fail -TestName $testName -Reason 'seed alien hook command marker missing'
}

if (-not ($settings.hooks.PSObject.Properties.Name -contains 'UserPromptSubmit')) {
    Write-Fail -TestName $testName -Reason 'seed must include partial managed hook UserPromptSubmit'
}

$staleCmd = [string]$settings.hooks.UserPromptSubmit[0].hooks[0].command
if ($staleCmd -ne $staleManagedHookCommand) {
    Write-Fail -TestName $testName -Reason 'seed UserPromptSubmit must be partial/stale for merge asserts'
}

$allow = @($settings.permissions.allow)
if (-not ($allow -contains $userAllowEntry)) {
    Write-Fail -TestName $testName -Reason ("seed permissions.allow must include {0}" -f $userAllowEntry)
}

if (-not ($settings.permissions.deny -contains 'Bash(rm -rf *)')) {
    Write-Fail -TestName $testName -Reason 'seed permissions.deny must be present for preservation asserts'
}

$rawSettings = [System.IO.File]::ReadAllText($fixtureSettingsPath)
if ($rawSettings -match '(?i)%USERPROFILE%|\$env:USERPROFILE|C:\\Users\\') {
    Write-Fail -TestName $testName -Reason 'seed settings.json must not embed USERPROFILE / home paths'
}

Write-Pass -TestName $testName

# Cleanup ephemeral harness trees (best-effort; a just-written timestamped
# backup can transiently lock on Windows, matching cleanup elsewhere in this suite).
$harnessRoot = Join-Path $repoRoot 'scripts\validation\fixtures\claude-merge-harness'
if (Test-Path -LiteralPath $harnessRoot) {
    Remove-Item -LiteralPath $harnessRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Assert-ClaudeSettingsMerge: ALL PASS'
exit 0