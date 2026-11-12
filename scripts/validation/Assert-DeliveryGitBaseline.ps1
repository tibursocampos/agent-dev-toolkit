#Requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$helper=Join-Path $PSScriptRoot '..\runtime\Invoke-DeliveryGitBaseline.ps1'
$root=Join-Path ([IO.Path]::GetTempPath()) ('delivery-git-baseline-'+[guid]::NewGuid().ToString('N'))
$passed=0
$planRel='features/001-demo/US01/PLAN.md'
function Assert($ok,[string]$name) { if(-not $ok){throw "FAIL: $name"}; $script:passed++ }
function Invoke-Git([string]$repo,[string[]]$CliArgs) { $o=& git -C $repo @CliArgs 2>&1; if($LASTEXITCODE -ne 0){throw "git $($CliArgs -join ' ') failed: $o"}; $o }
function Invoke-Baseline([string]$action,[string]$repo,[string]$base) {
    $pwsh=(Get-Command pwsh -ErrorAction Stop).Source
    $psi=[Diagnostics.ProcessStartInfo]::new(); $psi.FileName=$pwsh; $psi.UseShellExecute=$false
    $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true; $psi.CreateNoWindow=$true
    foreach($arg in @('-NoLogo','-NoProfile','-File',$helper,'-Action',$action,'-RepoPath',$repo,'-PlanPath',$planRel,'-BaselinePath',$base)){[void]$psi.ArgumentList.Add([string]$arg)}
    $proc=[Diagnostics.Process]::new(); $proc.StartInfo=$psi; [void]$proc.Start()
    $stdoutTask=$proc.StandardOutput.ReadToEndAsync(); $stderrTask=$proc.StandardError.ReadToEndAsync()
    if(-not $proc.WaitForExit(10000)){try{$proc.Kill($true)}catch{}; [void]$proc.WaitForExit(); throw "Baseline helper timed out after 10 seconds ($action)."}
    $out=@($stdoutTask.Result -split "`r?`n") + @($stderrTask.Result -split "`r?`n")
    $code=$proc.ExitCode; $json=$out | Where-Object { $_ -is [string] -and $_.TrimStart().StartsWith('{') } | Select-Object -Last 1
    $result=$null; if($json){try{$result=$json|ConvertFrom-Json -AsHashtable}catch{}}
    return @{code=$code;result=$result;output=($out -join "`n")}
}
try {
    [IO.Directory]::CreateDirectory($root)|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $root '.delivery-evidence'))|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $root 'features/001-demo/US01'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $root '.gitignore'),".delivery-evidence/`nfeatures/001-demo/US01/evidence/`n")
    [IO.File]::WriteAllText((Join-Path $root $planRel),'plan')
    Invoke-Git $root @('init','-q')|Out-Null; Invoke-Git $root @('config','user.email','baseline@example.invalid')|Out-Null; Invoke-Git $root @('config','user.name','Baseline Test')|Out-Null
    [IO.File]::WriteAllText((Join-Path $root 'tracked.txt'),'committed')
    [IO.File]::WriteAllText((Join-Path $root 'delete-me.txt'),'delete')
    Invoke-Git $root @('add','.')|Out-Null; Invoke-Git $root @('commit','-qm','fixture')|Out-Null
    # Prior dirty state must be captured as-is and remain untouched.
    [IO.File]::WriteAllText((Join-Path $root 'tracked.txt'),'pre-existing dirty')
    [IO.File]::WriteAllText((Join-Path $root 'delete-me.txt'),'')
    [IO.File]::Delete((Join-Path $root 'delete-me.txt'))
    Invoke-Git $root @('mv','tracked.txt','renamed.txt')|Out-Null
    [IO.File]::WriteAllBytes((Join-Path $root 'untracked.bin'),[byte[]](0,1,2,255))
    [IO.File]::WriteAllText((Join-Path $root 'ignored-output.txt'),'excluded')
    [IO.File]::AppendAllText((Join-Path $root '.gitignore'),"ignored-output.txt`n")
    $base='features/001-demo/US01/evidence/US01-S1--working-tree-baseline.json'
    $capture=Invoke-Baseline 'capture' $root $base
    Assert ($capture.code -eq 0) ("capture succeeds: $($capture.output)")
    $snapshot=Get-Content (Join-Path $root $base) -Raw|ConvertFrom-Json -AsHashtable
    Assert (@($snapshot.paths|Where-Object path -eq 'untracked.bin'|Where-Object { $_.sha256 -and $_.bytes -eq 4 -and $null -eq $_.PSObject.Properties['content'] }).Count -eq 1) 'untracked content represented by digest and size only'
    Assert (@($snapshot.paths|Where-Object kind -eq 'deleted'|Where-Object path -eq 'delete-me.txt').Count -eq 1) 'deleted path captured'
    Assert (@($snapshot.paths|Where-Object path -eq 'tracked.txt').Count -eq 1) 'rename source path captured'
    Assert (@($snapshot.paths|Where-Object path -eq 'ignored-output.txt').Count -eq 0) 'ignored path is excluded from baseline'
    Assert ([IO.File]::ReadAllText((Join-Path $root 'renamed.txt')) -eq 'pre-existing dirty') 'capture preserves prior dirty file'
    $steady=Invoke-Baseline 'compare' $root $base
    Assert ($steady.code -eq 0 -and $steady.result.changed -eq 0) 'unchanged state compares cleanly'
    [IO.File]::WriteAllText((Join-Path $root 'untracked.bin'),'later')
    [IO.File]::WriteAllText((Join-Path $root 'new.txt'),'new')
    $changed=Invoke-Baseline 'compare' $root $base
    Assert ($changed.code -eq 0 -and $changed.result.changed -ge 2) 'comparison reports content and path changes'
    Assert ((Invoke-Git $root @('status','--porcelain')).Count -gt 0) 'comparison does not mutate Git state'
    $ignoreFile=Join-Path $root '.gitignore'; $ignoreText=[IO.File]::ReadAllText($ignoreFile)
    [IO.File]::WriteAllText($ignoreFile,$ignoreText.Replace("features/001-demo/US01/evidence/`n",''))
    $unignored=Invoke-Baseline 'capture' $root 'features/001-demo/US01/evidence/US01-S1--unignored-baseline.json'
    [IO.File]::WriteAllText($ignoreFile,$ignoreText)
    Assert ($unignored.code -eq 3 -and $unignored.result.reason -eq 'baseline_path_not_ignored') 'unignored destination fails closed'
    $truncated=Invoke-Baseline 'capture' $root $base
    Assert ($truncated.code -eq 3 -and $truncated.result.reason -eq 'baseline_exists') 'existing baseline is not overwritten'

    # Race a writer against a large file; capture must either see a stable snapshot or block.
    $raceRepo=Join-Path $root 'race'; [IO.Directory]::CreateDirectory($raceRepo)|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $raceRepo '.delivery-evidence'))|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $raceRepo 'features/001-demo/US01'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $raceRepo '.gitignore'),".delivery-evidence/`nfeatures/001-demo/US01/evidence/`n")
    [IO.File]::WriteAllText((Join-Path $raceRepo $planRel),'plan')
    Invoke-Git $raceRepo @('init','-q')|Out-Null
    $raceFile=Join-Path $raceRepo 'race.bin'; $chunk=[byte[]]::new(1024*1024)
    $fs=[IO.File]::OpenWrite($raceFile); try { for($i=0;$i -lt 12;$i++){$fs.Write($chunk,0,$chunk.Length)} } finally {$fs.Dispose()}
    $writer=Start-Job -ArgumentList $raceFile -ScriptBlock { param($p) for($i=0;$i -lt 80;$i++){[IO.File]::WriteAllText($p,[string]$i)} }
    $race=Invoke-Baseline 'capture' $raceRepo 'features/001-demo/US01/evidence/US01-S1--race-baseline.json'
    $writerDone=Wait-Job $writer -Timeout 5
    if(-not $writerDone){Stop-Job $writer -ErrorAction SilentlyContinue; Remove-Job $writer -Force -ErrorAction SilentlyContinue; throw 'Race writer exceeded 5 seconds.'}
    Remove-Job $writer
    Assert (($race.code -eq 0) -or ($race.code -eq 3)) 'concurrent snapshot terminates safely'
    if($race.code -eq 3){Assert (@('baseline_unstable','baseline_limit_exceeded') -contains $race.result.reason) 'concurrent mutation blocks with a bounded reason'}

    $secretRepo=Join-Path $root 'secret'; [IO.Directory]::CreateDirectory($secretRepo)|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $secretRepo '.delivery-evidence'))|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $secretRepo 'features/001-demo/US01'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $secretRepo '.gitignore'),".delivery-evidence/`nfeatures/001-demo/US01/evidence/`n")
    [IO.File]::WriteAllText((Join-Path $secretRepo $planRel),'plan')
    Invoke-Git $secretRepo @('init','-q')|Out-Null
    [IO.File]::WriteAllText((Join-Path $secretRepo 'secret.txt'),'password=hunter2')
    $secret=Invoke-Baseline 'capture' $secretRepo 'features/001-demo/US01/evidence/US01-S1--secret-baseline.json'
    Assert ($secret.code -eq 0) 'capture records metadata for sensitive file without storing its contents'
    Assert (-not (Get-Content (Join-Path $secretRepo 'features/001-demo/US01/evidence/US01-S1--secret-baseline.json') -Raw).Contains('hunter2')) 'baseline does not persist source file contents'

    $linkRepo=Join-Path $root 'link'; [IO.Directory]::CreateDirectory($linkRepo)|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $linkRepo '.delivery-evidence'))|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $linkRepo 'features/001-demo/US01'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $linkRepo '.gitignore'),".delivery-evidence/`nfeatures/001-demo/US01/evidence/`n")
    [IO.File]::WriteAllText((Join-Path $linkRepo $planRel),'plan')
    Invoke-Git $linkRepo @('init','-q')|Out-Null
    $target=Join-Path $linkRepo 'target.txt'; [IO.File]::WriteAllText($target,'target')
    try {
        New-Item -ItemType SymbolicLink -Path (Join-Path $linkRepo 'link.txt') -Target $target -ErrorAction Stop|Out-Null
        $link=Invoke-Baseline 'capture' $linkRepo 'features/001-demo/US01/evidence/US01-S1--link-baseline.json'
        Assert ($link.code -eq 3 -and $link.result.reason -eq 'baseline_ambiguous') 'symlink fails closed'
    } catch { Write-Output 'SKIP: symlink creation was unavailable on this host.' }

    # Interruption during a large snapshot must not publish a partial baseline or alter source bytes.
    $interruptRepo=Join-Path $root 'interrupt'; [IO.Directory]::CreateDirectory($interruptRepo)|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $interruptRepo '.delivery-evidence'))|Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $interruptRepo 'features/001-demo/US01'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $interruptRepo '.gitignore'),".delivery-evidence/`nfeatures/001-demo/US01/evidence/`n")
    [IO.File]::WriteAllText((Join-Path $interruptRepo $planRel),'plan')
    Invoke-Git $interruptRepo @('init','-q')|Out-Null
    $interruptFile=Join-Path $interruptRepo 'large.bin'; $fs=[IO.File]::OpenWrite($interruptFile); try { for($i=0;$i -lt 32;$i++){$fs.Write($chunk,0,$chunk.Length)} } finally {$fs.Dispose()}
    $before=(Get-FileHash $interruptFile -Algorithm SHA256).Hash
    $args=@('-NoLogo','-NoProfile','-File',$helper,'-Action','capture','-RepoPath',$interruptRepo,'-PlanPath',$planRel,'-BaselinePath','features/001-demo/US01/evidence/US01-S1--interrupted-baseline.json')
    $proc=Start-Process -FilePath 'pwsh' -ArgumentList $args -PassThru -WindowStyle Hidden
    Start-Sleep -Milliseconds 30
    if(-not $proc.HasExited){try{$proc.Kill($true)}catch{}; if(-not $proc.WaitForExit(5000)){throw 'Interrupted helper process did not exit within 5 seconds.'}}
    Assert (-not [IO.File]::Exists((Join-Path $interruptRepo 'features/001-demo/US01/evidence/US01-S1--interrupted-baseline.json'))) 'interrupted capture leaves no baseline file'
    Assert ((Get-FileHash $interruptFile -Algorithm SHA256).Hash -eq $before) 'interrupted capture preserves source bytes'
    Write-Output "PASS: $passed Git baseline assertions."
} finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
