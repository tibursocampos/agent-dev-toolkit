#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$temp = Join-Path ([IO.Path]::GetTempPath()) ('adt-auth-link-' + [guid]::NewGuid().ToString('N'))
$homeRoot = Join-Path $temp 'home'
$outside = Join-Path $temp 'outside'
$sdd = Join-Path (Join-Path $homeRoot '.codex') 'sdd'
$null = New-Item -ItemType Directory -Path $sdd -Force
$null = New-Item -ItemType Directory -Path $outside -Force
$oldProfile = $env:USERPROFILE; $oldHome = $env:HOME; $oldHermes = $env:HERMES_HOME; $oldLocalAppData = $env:LOCALAPPDATA

function Test-PhysicalFixtureEnvironmentError {
    param([Parameter(Mandatory = $true)][System.Management.Automation.ErrorRecord] $ErrorRecord)

    $text = $ErrorRecord.Exception.ToString()
    return $text -match '(?i)access[^\r\n]*denied|eacces|eperm|operation not permitted|not have sufficient privilege|privilege'
}

$nestedJunctionCreated = $false
$nestedJunctionSkipReason = $null
$hermesJunctionCreated = $false
$hermesJunctionSkipReason = $null
$physicalResults = [System.Collections.Generic.List[object]]::new()
$scriptExitCode = 0

function Add-PhysicalValidationResult {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][ValidateSet('PASS', 'SKIPPED', 'FAIL')][string] $Status,
        [string] $Reason = ''
    )

    $physicalResults.Add([PSCustomObject]@{
        Name = $Name
        Status = $Status
        Reason = $Reason
    })
}

try {
    $env:USERPROFILE = $homeRoot; $env:HOME = $homeRoot; $env:HERMES_HOME = ''; $env:LOCALAPPDATA = ''
    $portable = Get-Content -LiteralPath (Join-Path $repo 'adapters\_shared\authorization-contract.json') -Raw | ConvertFrom-Json
    foreach ($copy in @('adapters\opencode\assets\plugins\authorization-contract.json', 'adapters\hermes\assets\plugins\agent-dev-toolkit-guard\authorization-contract.json')) {
        $candidate = Get-Content -LiteralPath (Join-Path $repo $copy) -Raw | ConvertFrom-Json
        if ((ConvertTo-Json -InputObject $candidate -Depth 8 -Compress) -ne (ConvertTo-Json -InputObject $portable -Depth 8 -Compress)) { throw ("Portable contract drift: {0}" -f $copy) }
    }
    $link = Join-Path $sdd 'escape'
    try {
        $null = New-Item -ItemType Junction -Path $link -Target $outside -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $link)) { throw 'junction creation returned without creating the fixture.' }
        $nestedJunctionCreated = $true
    }
    catch {
        if (Test-PhysicalFixtureEnvironmentError -ErrorRecord $_) {
            $nestedJunctionSkipReason = $_.Exception.Message
        }
        else {
            throw
        }
    }
    . (Join-Path $repo 'adapters\_shared\GuardCommon.ps1')
    $workspace = Join-Path $temp 'workspace'; $null = New-Item -ItemType Directory -Path $workspace
    if ($nestedJunctionCreated) {
        $verdict = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{ path = (Join-Path $link 'probe.json'); content = '{}' }) -WorkspaceRoot $workspace
        if ($verdict.Decision -ne 'deny') { Write-Host ('canonical=' + (Get-ToolkitCanonicalPathForGuard -Path (Join-Path $link 'probe.json') -WorkspaceRoot $workspace)); Write-Host ('sdd=' + (Test-ToolkitPathIsUnderLocalSddRoot -FilePath (Join-Path $link 'probe.json'))); Write-Host ($verdict | ConvertTo-Json -Compress); throw 'PowerShell authorized a path through an SDD junction to outside.' }
        Write-Host 'PowerShell: nested SDD junction escape: PASS'
        Add-PhysicalValidationResult -Name 'PowerShell nested SDD junction escape' -Status 'PASS'
    }
    else {
        Write-Host ('PowerShell: nested SDD junction escape: SKIPPED - physical junction creation blocked by current ACL/privilege ({0}); no bypass attempted.' -f $nestedJunctionSkipReason)
        Add-PhysicalValidationResult -Name 'PowerShell nested SDD junction escape' -Status 'SKIPPED' -Reason $nestedJunctionSkipReason
    }

    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
        $js = Join-Path $repo 'adapters\opencode\assets\plugins\agent-dev-toolkit-marker.js'
        $probe = @'
import {pathToFileURL} from 'node:url'; import path from 'node:path';
const m=await import(pathToFileURL(process.argv[1]).href); const home=process.env.USERPROFILE;
if(!m.evaluateAuthorization('file.write','workspace')||!m.evaluateAuthorization('file.write','local_sdd')||m.evaluateAuthorization('file.write','outside')) throw new Error('portable effect/scope contract assertion failed');
if(process.argv[2]==='physical') {
  const v=m.evaluatePathSecretsGuard('write',{path:path.join(home,'.codex','sdd','escape','probe.json'),content:'{}'},process.cwd());
  if(v.decision!=='deny') throw new Error('OpenCode authorized junction escape');
}
console.log('OpenCode: authorization contract probe passed');
'@
        $probeMode = if ($nestedJunctionCreated) { 'physical' } else { 'contract-only' }
        & $node.Source --input-type=module -e $probe $js $probeMode
        if ($LASTEXITCODE -ne 0) { throw 'OpenCode junction probe failed.' }
        if ($nestedJunctionCreated) {
            Write-Host 'OpenCode: SDD junction escape: PASS'
            Add-PhysicalValidationResult -Name 'OpenCode SDD junction escape' -Status 'PASS'
        }
        else {
            Write-Host ('OpenCode: SDD junction escape: SKIPPED - physical junction creation blocked by current ACL/privilege ({0}); no bypass attempted.' -f $nestedJunctionSkipReason)
            Add-PhysicalValidationResult -Name 'OpenCode SDD junction escape' -Status 'SKIPPED' -Reason $nestedJunctionSkipReason
        }
    }
    else {
        Write-Host 'OpenCode: SDD junction escape: SKIPPED - node runtime unavailable; physical case was not executed.'
        Add-PhysicalValidationResult -Name 'OpenCode SDD junction escape' -Status 'SKIPPED' -Reason 'node runtime unavailable'
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $py = Join-Path $repo 'adapters\hermes\assets\plugins\agent-dev-toolkit-guard\__init__.py'
        $hermesHome = Join-Path $homeRoot '.hermes'
        $hermesSdd = Join-Path $hermesHome 'sdd'
        $hermesOutside = Join-Path $temp 'hermes-outside'
        $null = New-Item -ItemType Directory -Path $hermesHome -Force
        $null = New-Item -ItemType Directory -Path $hermesOutside -Force
        try {
            $null = New-Item -ItemType Junction -Path $hermesSdd -Target $hermesOutside -ErrorAction Stop
            if (-not (Test-Path -LiteralPath $hermesSdd)) { throw 'junction creation returned without creating the fixture.' }
            $hermesJunctionCreated = $true
        }
        catch {
            if (Test-PhysicalFixtureEnvironmentError -ErrorRecord $_) {
                $hermesJunctionSkipReason = $_.Exception.Message
            }
            else {
                throw
            }
        }
        $probe = @'
import importlib.util,os,sys
s=importlib.util.spec_from_file_location('g',sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
assert m._authorized('file.write','workspace') and m._authorized('file.write','local_sdd') and not m._authorized('file.write','outside')
if len(sys.argv) > 2 and sys.argv[2] == 'physical':
 root=os.path.join(os.environ['USERPROFILE'],'.hermes','sdd')
 v=m.evaluate_tool_call('write_file',{'path':os.path.join(root,'probe.json'),'content':'{}'})
 if os.path.realpath(root)==os.path.abspath(root): raise RuntimeError('Hermes root junction fixture was not created')
 if not v or v.get('action')!='block': raise RuntimeError('Hermes authorized a write through a redirected SDD root')
 print('Hermes: whole SDD root junction escape: PASS')
else:
 print('Hermes: authorization contract probe passed')
'@
        $probeMode = if ($hermesJunctionCreated) { 'physical' } else { 'contract-only' }
        & $python.Source -c $probe $py $probeMode
        if ($LASTEXITCODE -ne 0) { throw 'Hermes junction probe failed.' }
        if (-not $hermesJunctionCreated) {
            Write-Host ('Hermes: whole SDD root junction escape: SKIPPED - physical junction creation blocked by current ACL/privilege ({0}); no bypass attempted.' -f $hermesJunctionSkipReason)
            Add-PhysicalValidationResult -Name 'Hermes whole SDD root junction escape' -Status 'SKIPPED' -Reason $hermesJunctionSkipReason
        }
        elseif ($hermesJunctionCreated) {
            Add-PhysicalValidationResult -Name 'Hermes whole SDD root junction escape' -Status 'PASS'
        }
    }
    else {
        Write-Host 'Hermes: whole SDD root junction escape: SKIPPED - python runtime unavailable; physical case was not executed.'
        Add-PhysicalValidationResult -Name 'Hermes whole SDD root junction escape' -Status 'SKIPPED' -Reason 'python runtime unavailable'
    }
}
catch {
    $scriptExitCode = 1
    Add-PhysicalValidationResult -Name 'Assert-AuthorizationSymlinkConformance' -Status 'FAIL' -Reason $_.Exception.Message
}
finally {
    $env:USERPROFILE = $oldProfile
    $env:HOME = $oldHome
    $env:HERMES_HOME = $oldHermes
    $env:LOCALAPPDATA = $oldLocalAppData
    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction Stop
    }
}

$overallStatus = if ($scriptExitCode -ne 0 -or @($physicalResults | Where-Object Status -eq 'FAIL').Count -gt 0) {
    'FAIL'
} elseif (@($physicalResults | Where-Object Status -eq 'PASS').Count -gt 0) {
    'PASS'
} else {
    'SKIPPED'
}

$structuredResult = [PSCustomObject]@{
    Validator = 'Assert-AuthorizationSymlinkConformance'
    Status = $overallStatus
    Results = @($physicalResults)
}
Write-Output ($structuredResult | ConvertTo-Json -Compress -Depth 5)
if ($overallStatus -eq 'FAIL') { $scriptExitCode = 1 }
exit $scriptExitCode
