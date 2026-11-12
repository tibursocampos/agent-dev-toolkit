#Requires -Version 7.0
<#
.SYNOPSIS
  Captures or compares bounded, read-only evidence of a repository's uncommitted Git state.
.DESCRIPTION
  Snapshots every non-ignored path reported by git status --porcelain=v1 -z, including
  untracked files and deleted/renamed paths, retaining metadata and hashes only. The unit
  PLAN.md is excluded because operational checkpoint writes update it; plan identity checks
  cover that control artifact separately. No Git or worktree mutation occurs.
  Exit codes: 0 success, 3 blocked/ambiguous, 1 invalid invocation or error.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('capture','compare')][string] $Action,
    [Parameter(Mandatory)][string] $RepoPath,
    [Parameter(Mandatory)][string] $PlanPath,
    [Parameter(Mandatory)][string] $BaselinePath,
    [ValidateRange(1,10000)][int] $MaxFiles = 500,
    [ValidateRange(1,104857600)][long] $MaxBytes = 20971520
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Block([string]$Reason,[string]$Message) {
    [Console]::Out.WriteLine((@{ok=$false;reason=$Reason;message=$Message} | ConvertTo-Json -Compress))
    exit 3
}
function Sha([byte[]]$Bytes) { [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($Bytes)) }
function Get-StatusRows {
    # Preserve NUL-delimited porcelain paths through redirected byte output.
    $psi = [System.Diagnostics.ProcessStartInfo]::new('git')
    $psi.ArgumentList.Add('-C'); $psi.ArgumentList.Add($repoFull)
    foreach ($arg in @('status','--porcelain=v1','-z','--untracked-files=all','--ignored=no')) { $psi.ArgumentList.Add($arg) }
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::new(); $p.StartInfo = $psi
    [void]$p.Start()
    $mem = [System.IO.MemoryStream]::new(); $p.StandardOutput.BaseStream.CopyTo($mem)
    $err = $p.StandardError.ReadToEnd(); $p.WaitForExit()
    if ($p.ExitCode -ne 0) { throw "git status failed: $err" }
    $bytes = $mem.ToArray()
    $utf8 = [System.Text.UTF8Encoding]::new($false,$true)
    $tokens = [System.Collections.Generic.List[string]]::new()
    $start = 0
    for ($i=0; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 0) {
            if ($i -gt $start) { $tokens.Add($utf8.GetString($bytes, $start, $i - $start)) }
            $start = $i + 1
        }
    }
    if ($start -lt $bytes.Length) { $tokens.Add($utf8.GetString($bytes, $start, $bytes.Length - $start)) }
    $rows = [System.Collections.Generic.List[object]]::new()
    for ($i=0; $i -lt $tokens.Count; $i++) {
        $entry=$tokens[$i]
        if ($entry.Length -lt 4 -or $entry[2] -ne ' ') { throw 'Unexpected porcelain status; refusing ambiguous baseline.' }
        $xy=$entry.Substring(0,2); $path=$entry.Substring(3)
        $rows.Add(@{path=$path;status=$xy})
        if ($xy.Contains('R') -or $xy.Contains('C')) {
            if (($i+1) -ge $tokens.Count) { throw 'Rename/copy status is incomplete.' }
            $rows.Add(@{path=$tokens[++$i];status='source-of-'+$xy})
        }
    }
    return $rows.ToArray()
}
function Assert-NoReparsePath([string]$Path) {
    $cursor=[IO.DirectoryInfo]::new((Split-Path -Parent $Path))
    while($cursor -and $cursor.FullName.StartsWith($repoPrefix,[StringComparison]::OrdinalIgnoreCase)) {
        if($cursor.Exists -and (($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'Baseline evidence path crosses a reparse point.'}
        if($cursor.FullName.Equals($repoFull,[StringComparison]::OrdinalIgnoreCase)){break}
        $cursor=$cursor.Parent
    }
    if([IO.File]::Exists($Path) -and (([IO.File]::GetAttributes($Path) -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'Baseline evidence file is a reparse point.'}
}
function Snapshot {
    $rows = @(Get-StatusRows | Where-Object { [string]$_.path -cne $planRelative })
    if ($rows.Count -gt $MaxFiles) { Block 'baseline_limit_exceeded' "Status contains $($rows.Count) paths; limit is $MaxFiles." }
    $items=[System.Collections.Generic.List[object]]::new(); [long]$total=0
    foreach ($row in $rows) {
        $path=[string]$row.path
        if ([System.IO.Path]::IsPathRooted($path) -or $path -match '(^|[\\/])\.\.([\\/]|$)' -or $path.Contains("`0")) { Block 'baseline_ambiguous' 'Git reported an unsafe or unrepresentable path.' }
        $full=[System.IO.Path]::GetFullPath((Join-Path $repoFull $path))
        if (-not $full.StartsWith($repoPrefix,[System.StringComparison]::OrdinalIgnoreCase)) { Block 'baseline_ambiguous' 'Git path resolves outside the repository.' }
        $kind='file'; $bytes=[byte[]]@()
        if ([System.IO.File]::Exists($full)) {
            $fi=[System.IO.FileInfo]::new($full)
            if (($fi.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { Block 'baseline_ambiguous' "Reparse point cannot be snapshotted safely: $path" }
            $bytes=[System.IO.File]::ReadAllBytes($full)
        } elseif ([System.IO.Directory]::Exists($full)) {
            Block 'baseline_ambiguous' "Git path is a directory or submodule and cannot be captured as a regular file: $path"
        } else { $kind='deleted' }
        $total += $bytes.LongLength
        if ($total -gt $MaxBytes) { Block 'baseline_limit_exceeded' "File contents exceed the $MaxBytes byte limit." }
        $items.Add(@{path=$path;status=[string]$row.status;kind=$kind;bytes=$bytes.LongLength;sha256=(Sha $bytes)})
    }
    # Reject a snapshot if the set/status or any file bytes changed while being read.
    $again=@(Get-StatusRows | Where-Object { [string]$_.path -cne $planRelative })
    $a=ConvertTo-Json -InputObject @($rows) -Compress -Depth 5; $b=ConvertTo-Json -InputObject @($again) -Compress -Depth 5
    if ($a -cne $b) { Block 'baseline_unstable' 'Git status changed while the snapshot was being read.' }
    foreach ($item in $items) {
        if ($item.kind -eq 'deleted') { if ([IO.File]::Exists((Join-Path $repoFull $item.path))) { Block 'baseline_unstable' "Path changed during snapshot: $($item.path)" } }
        else { $now=[IO.File]::ReadAllBytes((Join-Path $repoFull $item.path)); if ((Sha $now) -cne $item.sha256) { Block 'baseline_unstable' "File changed during snapshot: $($item.path)" } }
    }
    return @{schema='delivery-git-baseline/v1';captured_utc=[DateTime]::UtcNow.ToString('o');repo_root=$repoFull;exclusions='Git-ignored paths, repository metadata, clean paths, and this unit PLAN.md are excluded. PLAN.md is updated to persist execution state; its approved identity is checked separately.';paths=@($items);total_bytes=$total}
}

try {
    $repoFull=[IO.Path]::GetFullPath($RepoPath)
    $rootOut=& git -C $repoFull rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'RepoPath is not inside a Git worktree.' }
    $root=[IO.Path]::GetFullPath(([string]$rootOut).Trim())
    if (-not $repoFull.Equals($root,[StringComparison]::OrdinalIgnoreCase)) { throw 'RepoPath must be the worktree root.' }
    $repoFull=$root; $repoPrefix=$repoFull.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
    $planRelative=$PlanPath.Replace('\\','/')
    if ($planRelative -cnotmatch '^features/[0-9]{3}-[a-z0-9]+(?:-[a-z0-9]+)*/(?:US|TS)[0-9]{2}/PLAN\.md$') { throw 'PlanPath must be a canonical unit PLAN.md path.' }
    $planFull=[IO.Path]::GetFullPath((Join-Path $repoFull $planRelative))
    if (-not $planFull.StartsWith($repoPrefix,[StringComparison]::OrdinalIgnoreCase) -or -not [IO.File]::Exists($planFull)) { throw 'PlanPath must name an existing plan in this repository.' }
    $baseRel=$BaselinePath.Replace('\','/')
    if ([IO.Path]::IsPathRooted($BaselinePath) -or $baseRel -match '(^|/)\.\.(/|$)') { throw 'BaselinePath must be a safe repository-relative path.' }
    $unitDir=$planRelative.Substring(0,$planRelative.LastIndexOf('/'))
    if ($baseRel -cnotmatch ('^' + [regex]::Escape($unitDir) + '/evidence/[A-Za-z0-9][A-Za-z0-9._-]*--[a-z0-9][a-z0-9-]*\.json$')) { throw 'BaselinePath must be a canonical step evidence JSON path under this plan unit.' }
    $baseFull=[IO.Path]::GetFullPath((Join-Path $repoFull $BaselinePath))
    if (-not $baseFull.StartsWith($repoPrefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'BaselinePath escapes the repository.' }
    Assert-NoReparsePath $baseFull
    if ($Action -eq 'capture') {
        $ignored=& git -C $repoFull check-ignore --quiet -- $baseRel 2>$null
        if ($LASTEXITCODE -ne 0) { Block 'baseline_path_not_ignored' 'Baseline evidence path must be Git-ignored.' }
        if ([IO.File]::Exists($baseFull)) { Block 'baseline_exists' 'Refusing to overwrite existing baseline evidence.' }
        $snap=Snapshot
        $json=ConvertTo-Json -InputObject $snap -Depth 10
        $parent=Split-Path -Parent $baseFull; [IO.Directory]::CreateDirectory($parent) | Out-Null
        $tmp=Join-Path $parent ('.git-baseline-'+[guid]::NewGuid().ToString('N')+'.tmp')
        try { [IO.File]::WriteAllText($tmp,$json,[Text.UTF8Encoding]::new($false)); [IO.File]::Move($tmp,$baseFull,$false) }
        finally { if ([IO.File]::Exists($tmp)) { [IO.File]::Delete($tmp) } }
        [Console]::Out.WriteLine((@{ok=$true;action='capture';path=$baseRel;paths=$snap.paths.Count;bytes=$snap.total_bytes;sha256=(Sha ([IO.File]::ReadAllBytes($baseFull)))} | ConvertTo-Json -Compress)); exit 0
    }
    if (-not [IO.File]::Exists($baseFull)) { Block 'baseline_missing' 'Baseline evidence file does not exist.' }
    $baseline=Get-Content -LiteralPath $baseFull -Raw | ConvertFrom-Json -AsHashtable
    if ($baseline.schema -cne 'delivery-git-baseline/v1' -or $baseline.repo_root -cne $repoFull) { Block 'baseline_invalid' 'Baseline schema or repository identity is invalid.' }
    $current=Snapshot
    $old=@{}; foreach ($item in $baseline.paths) { $old[[string]$item.path]=$item }
    $now=@{}; foreach ($item in $current.paths) { $now[[string]$item.path]=$item }
    $paths=@($old.Keys + $now.Keys | Sort-Object -Unique)
    $diff=foreach ($path in $paths) {
        $before=$old[$path]; $after=$now[$path]
        $change=if (-not $before) {'added'} elseif (-not $after) {'removed'} elseif ($before.status -cne $after.status -or $before.sha256 -cne $after.sha256 -or $before.kind -cne $after.kind) {'changed'} else {'unchanged'}
        if ($change -ne 'unchanged') { @{path=$path;change=$change;baseline_status=if($before){$before.status}else{$null};current_status=if($after){$after.status}else{$null};baseline_kind=if($before){$before.kind}else{$null};current_kind=if($after){$after.kind}else{$null};baseline_bytes=if($before){$before.bytes}else{$null};current_bytes=if($after){$after.bytes}else{$null};baseline_sha256=if($before){$before.sha256}else{$null};current_sha256=if($after){$after.sha256}else{$null}} }
    }
    [Console]::Out.WriteLine((@{ok=$true;action='compare';unchanged=($paths.Count-@($diff).Count);changed=@($diff).Count;diff=@($diff);baseline_path=$baseRel;reconcile='Review each changed path against the retained baseline content; no recovery or worktree write was performed.'} | ConvertTo-Json -Compress -Depth 8)); exit 0
}
catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
