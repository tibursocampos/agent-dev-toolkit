#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptsRoot = Split-Path -Parent $PSScriptRoot
$writer = Join-Path $scriptsRoot 'ledger/Set-DeliveryExecutionBlock.ps1'
. (Join-Path $scriptsRoot '_lib/DeliveryGrammar.ps1')
. (Join-Path $scriptsRoot '_lib/DeliveryAtomicWrite.ps1')

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-atomic-write-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0
$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Get-TestBytes([string]$Text) {
    return , $utf8.GetBytes($Text)
}

function Get-TestText([string]$Path) {
    return $utf8.GetString([System.IO.File]::ReadAllBytes($Path))
}

function New-TestCase([string]$Name, [string]$Initial) {
    $directory = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $file = Join-Path $directory 'PLAN.md'
    [System.IO.File]::WriteAllBytes($file, (Get-TestBytes $Initial))
    return $file
}

function Get-StateLeftovers([string]$Directory) {
    return ,@(Get-ChildItem -LiteralPath $Directory -Force -File | Where-Object { $_.Name -like '.delivery-state.*' })
}

function Get-ConflictFiles([string]$Directory) {
    return ,@(Get-ChildItem -LiteralPath $Directory -Force -File | Where-Object { $_.Name -like '*.conflict-*' })
}

function Get-BlockHashFromFile([string]$Path, [string]$Type, [string]$Id = '') {
    $parsed = Read-DeliveryBlocks -Text ([System.IO.File]::ReadAllText($Path))
    $block = @($parsed.Blocks | Where-Object { ($_.Type -ceq $Type) -and (([string]$_.Id) -ceq $Id) })[0]
    return (Get-DeliveryBlockHash -Payload $block.Payload)
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-ChildScript([string[]]$Arguments) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $childHost
    $startInfo.Arguments = (@($Arguments | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = ($stdoutTask.Result + $stderrTask.Result) }
}

$overwriteHook = { [System.IO.File]::WriteAllBytes($script:hookTarget, $script:hookBytes) }
$appendHook = { [System.IO.File]::AppendAllText($script:hookTarget, ' appended', $utf8) }
$deleteHook = { [System.IO.File]::Delete($script:hookTarget) }

try {
    $normal = New-TestCase 'normal' 'original'
    $normalResult = Invoke-DeliveryAtomicReplace -Path $normal -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original')
    Assert-Equal 'written' ([string]$normalResult.Status) 'normal replace status'
    Assert-Equal '' ([string]$normalResult.ConflictPath) 'normal replace has no conflict path'
    Assert-Equal 'new' (Get-TestText $normal) 'normal replace writes new bytes'
    Assert-Equal '0' ([string](Get-StateLeftovers (Split-Path -Parent $normal)).Count) 'normal replace leaves no temp, backup or restore files'
    Assert-Equal '0' ([string](Get-ConflictFiles (Split-Path -Parent $normal)).Count) 'normal replace preserves nothing'

    $overwrite = New-TestCase 'overwrite' 'original'
    $script:hookTarget = $overwrite
    $script:hookBytes = Get-TestBytes 'concurrent'
    $overwriteResult = Invoke-DeliveryAtomicReplace -Path $overwrite -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original') -AfterReplace $overwriteHook
    Assert-Equal 'conflict' ([string]$overwriteResult.Status) 'concurrent overwrite reports conflict'
    Assert-Equal 'original' (Get-TestText $overwrite) 'concurrent overwrite restores original bytes'
    $overwriteConflicts = @(Get-ConflictFiles (Split-Path -Parent $overwrite))
    Assert-Equal '1' ([string]$overwriteConflicts.Count) 'concurrent overwrite preserves one conflict file'
    Assert-Equal 'concurrent' (Get-TestText $overwriteConflicts[0].FullName) 'preserved file holds exactly the concurrent bytes'
    Assert-Equal ([System.IO.Path]::GetFileName($overwriteConflicts[0].FullName)) (Split-Path -Leaf $overwriteResult.ConflictPath) 'ConflictPath names the preserved file'
    Assert-Equal '0' ([string](Get-StateLeftovers (Split-Path -Parent $overwrite)).Count) 'concurrent overwrite leaves no temp, backup or restore files'

    $append = New-TestCase 'append' 'original'
    $script:hookTarget = $append
    $appendResult = Invoke-DeliveryAtomicReplace -Path $append -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original') -AfterReplace $appendHook
    Assert-Equal 'conflict' ([string]$appendResult.Status) 'concurrent append reports conflict'
    Assert-Equal 'original' (Get-TestText $append) 'concurrent append restores original bytes'
    $appendConflicts = @(Get-ConflictFiles (Split-Path -Parent $append))
    Assert-Equal '1' ([string]$appendConflicts.Count) 'concurrent append preserves one conflict file'
    Assert-Equal 'new appended' (Get-TestText $appendConflicts[0].FullName) 'appended bytes are preserved in full'
    Assert-Equal '0' ([string](Get-StateLeftovers (Split-Path -Parent $append)).Count) 'concurrent append leaves no temp, backup or restore files'

    $deleted = New-TestCase 'deleted' 'original'
    $script:hookTarget = $deleted
    $deletedResult = Invoke-DeliveryAtomicReplace -Path $deleted -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original') -AfterReplace $deleteHook
    Assert-Equal 'conflict' ([string]$deletedResult.Status) 'concurrent delete reports conflict without throwing'
    Assert-Equal '' ([string]$deletedResult.ConflictPath) 'concurrent delete has nothing to preserve'
    Assert-Equal 'original' (Get-TestText $deleted) 'concurrent delete restores original bytes'
    Assert-Equal '0' ([string](Get-ConflictFiles (Split-Path -Parent $deleted)).Count) 'concurrent delete creates no conflict file'
    Assert-Equal '0' ([string](Get-StateLeftovers (Split-Path -Parent $deleted)).Count) 'concurrent delete leaves no temp, backup or restore files'

    $stale = New-TestCase 'stale-expected' 'changed-before'
    $staleResult = Invoke-DeliveryAtomicReplace -Path $stale -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original')
    Assert-Equal 'conflict' ([string]$staleResult.Status) 'stale expected old bytes report conflict'
    Assert-Equal 'changed-before' (Get-TestText $stale) 'stale expected old bytes keep the concurrent content'
    $staleConflicts = @(Get-ConflictFiles (Split-Path -Parent $stale))
    Assert-Equal '1' ([string]$staleConflicts.Count) 'stale expected old bytes preserve the attempted content'
    Assert-Equal 'new' (Get-TestText $staleConflicts[0].FullName) 'stale expected old bytes preserve the new bytes not written'
    Assert-Equal '0' ([string](Get-StateLeftovers (Split-Path -Parent $stale)).Count) 'stale expected old bytes leave no temp, backup or restore files'

    $restoreFail = New-TestCase 'restore-failure' 'original'
    $script:hookTarget = $restoreFail
    $script:hookBytes = Get-TestBytes 'concurrent'
    $throwBeforeRestore = { throw 'injected restore failure' }
    $restoreFailResult = Invoke-DeliveryAtomicReplace -Path $restoreFail -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original') -AfterReplace $overwriteHook -BeforeRestore $throwBeforeRestore
    Assert-Equal 'restore_failed' ([string]$restoreFailResult.Status) 'failed restore reports restore_failed'
    $restoreDir = Split-Path -Parent $restoreFail
    $restoreLeftovers = @(Get-StateLeftovers $restoreDir)
    Assert-Equal '1' ([string]$restoreLeftovers.Count) 'failed restore keeps only the backup'
    Assert-Equal ([System.IO.Path]::GetFileName($restoreFailResult.BackupPath)) $restoreLeftovers[0].Name 'restore_failed names the kept backup'
    Assert-True ($restoreLeftovers[0].Name -like '*.bak') 'kept file is the backup'
    Assert-Equal 'original' (Get-TestText $restoreFailResult.BackupPath) 'kept backup holds the original bytes'
    $restoreConflicts = @(Get-ConflictFiles $restoreDir)
    Assert-Equal '1' ([string]$restoreConflicts.Count) 'failed restore keeps the preserved concurrent file'
    Assert-Equal 'concurrent' (Get-TestText $restoreConflicts[0].FullName) 'failed restore preserved file holds the concurrent bytes'
    Assert-Equal ([System.IO.Path]::GetFileName($restoreConflicts[0].FullName)) (Split-Path -Leaf $restoreFailResult.ConflictPath) 'restore_failed names the preserved file'

    $replaceFail = New-TestCase 'after-replace-failure' 'original'
    $throwAfterReplace = { throw 'injected after-replace failure' }
    $replaceFailResult = Invoke-DeliveryAtomicReplace -Path $replaceFail -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original') -AfterReplace $throwAfterReplace
    Assert-Equal 'restore_failed' ([string]$replaceFailResult.Status) 'throwing after-replace hook reports restore_failed'
    Assert-Equal '' ([string]$replaceFailResult.ConflictPath) 'throwing after-replace hook preserves no conflict file'
    $replaceFailLeftovers = @(Get-StateLeftovers (Split-Path -Parent $replaceFail))
    Assert-Equal '1' ([string]$replaceFailLeftovers.Count) 'throwing after-replace hook keeps only the backup'
    Assert-Equal 'original' (Get-TestText $replaceFailResult.BackupPath) 'throwing after-replace hook keeps the original bytes in the backup'
    Assert-Equal 'new' (Get-TestText $replaceFail) 'throwing after-replace hook leaves the replaced target untouched'

    $collide = New-TestCase 'same-millisecond' 'original'
    $sentinels = @{}
    for ($offset = 0; $offset -le 300; $offset++) {
        $sentinelPath = $collide + '.conflict-' + (Get-DeliveryConflictStamp -Moment ([DateTime]::UtcNow.AddMilliseconds($offset)))
        if (-not $sentinels.ContainsKey($sentinelPath)) {
            $sentinelText = 'sentinel-' + $sentinels.Count
            [System.IO.File]::WriteAllBytes($sentinelPath, (Get-TestBytes $sentinelText))
            $sentinels[$sentinelPath] = $sentinelText
        }
    }
    $script:hookTarget = $collide
    $script:hookBytes = Get-TestBytes 'concurrent-1'
    $firstCollide = Invoke-DeliveryAtomicReplace -Path $collide -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original') -AfterReplace $overwriteHook
    Assert-Equal 'conflict' ([string]$firstCollide.Status) 'collision candidate run reports conflict'
    Assert-True (-not $sentinels.ContainsKey([string]$firstCollide.ConflictPath)) 'conflict file does not reuse a pre-existing name'
    $script:hookBytes = Get-TestBytes 'concurrent-2'
    $secondCollide = Invoke-DeliveryAtomicReplace -Path $collide -NewBytes (Get-TestBytes 'new') -ExpectedOldBytes (Get-TestBytes 'original') -AfterReplace $overwriteHook
    Assert-Equal 'conflict' ([string]$secondCollide.Status) 'second conflict reports conflict'
    Assert-True ([string]$firstCollide.ConflictPath -cne [string]$secondCollide.ConflictPath) 'two conflicts get distinct preserved files'
    $untouched = 0
    foreach ($key in $sentinels.Keys) {
        if ((Get-TestText $key) -ceq $sentinels[$key]) { $untouched++ }
    }
    Assert-Equal ([string]$sentinels.Count) ([string]$untouched) 'pre-existing conflict files are not overwritten'
    Assert-Equal 'concurrent-1' (Get-TestText $firstCollide.ConflictPath) 'first preserved file keeps its bytes'
    Assert-Equal 'concurrent-2' (Get-TestText $secondCollide.ConflictPath) 'second preserved file keeps its bytes'
    Assert-Equal 'original' (Get-TestText $collide) 'collision case restores original bytes'

    $cliRepo = Join-Path $tempRoot 'cli-repo'
    $cliDir = Join-Path $cliRepo 'features/unit'
    New-Item -ItemType Directory -Path $cliDir -Force | Out-Null
    $cliPlan = Join-Path $cliDir 'PLAN.md'
    $nl = [string][char]10
    $cliOldPayload = '{"schema":"delivery-progress/v1","cadence":"step_by_step"}'
    $cliText = @('# Plan', '', '<!-- DELIVERY:PROGRESS:BEGIN -->', $cliOldPayload, '<!-- DELIVERY:PROGRESS:END -->', '', 'Approved body.', '') -join $nl
    [System.IO.File]::WriteAllText($cliPlan, $cliText, $utf8)
    $cliHash = Get-BlockHashFromFile $cliPlan 'PROGRESS'
    $cliNewPayload = '{"schema":"delivery-progress/v1","cadence":"continuous","current_stage":"implementation"}'
    $cliRun = Invoke-ChildScript @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $writer, '-RepoPath', $cliRepo, '-PlanPath', $cliPlan, '-Block', 'PROGRESS', '-ExpectedBlockHash', $cliHash, '-PayloadJson', $cliNewPayload)
    $cliResult = $cliRun.Output.Trim() | ConvertFrom-Json
    Assert-Equal '0' ([string]$cliRun.ExitCode) 'setter CLI normal write exit code'
    Assert-Equal 'written_and_verified' ([string]$cliResult.code) 'setter CLI normal write code'
    Assert-Equal 'True' ([string]$cliResult.written) 'setter CLI normal write reports written'
    Assert-Equal 'True' ([string](Get-TestText $cliPlan).Contains('"current_stage":"implementation"')) 'setter CLI writes the new payload'
    Assert-Equal 'True' ([string](Get-TestText $cliPlan).Contains('Approved body.')) 'setter CLI preserves normative body'
    Assert-Equal '0' ([string](Get-StateLeftovers $cliDir).Count) 'setter CLI leaves no temp, backup or restore files'

    Write-Output ('PASS: {0} atomic write assertions on PowerShell {1}.' -f $passed, $PSVersionTable.PSVersion)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
