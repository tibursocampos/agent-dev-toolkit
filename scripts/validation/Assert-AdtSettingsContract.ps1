#Requires -Version 7.0
# Tests:
#   Should_DeclareContractMarkers_When_SkillManifestInspected
#   Should_KeepManifestPortable_When_SkillManifestInspected
#   Should_MatchInstallerTemplate_When_StorageBlockParsed
#   Should_NotWrite_When_QueryingAnyFixture
#   Should_SaveOnlyDefault_When_SavingPair
#   Should_NotRewrite_When_SavingIdenticalPair
#   Should_RemoveOnlyDefault_When_ReturningToInheritance
#   Should_RefuseWithoutWrite_When_FileUnreadableOrIncompatible
#   Should_RefuseSave_When_ReferenceUnavailableOrPairInvalid
#   Should_CreateFromTemplate_When_FileAbsentAndSaving
#   Should_NotCreateFile_When_TemplateUnreadable
#   Should_RefuseWrite_When_ContentChangedSinceRead
#   Should_RestoreOriginal_When_RereadMismatch
#   Should_KeepSubagentModels_When_ClaudeHookRewritesPreferences
#   Should_SaveOnlyAfterConfirmedUse_AndPreserveOldValueOnFailure
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$scriptsRoot = Split-Path -Parent $scriptDir
. (Join-Path $scriptsRoot '_lib\Get-ToolkitRepoRoot.ps1')
. (Join-Path $scriptsRoot '_lib\New-ToolkitWorkRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$fixtureRoot = Join-Path $scriptDir 'fixtures\adt-settings'
$sessionChoiceFixtureRoot = Join-Path $scriptDir 'fixtures\subagent-session-choice'

function Write-Pass { param([string] $TestName) Write-Host ("{0}: PASS" -f $TestName) }
function Write-Fail { param([string] $TestName, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $TestName, $Reason); exit 1 }
function Read-JsonText { param([string] $Text) ConvertFrom-Json -InputObject $Text -AsHashtable -ErrorAction Stop }
function Get-JsonDigest { param([object] $Value) ConvertTo-Json -InputObject $Value -Depth 20 -Compress }
function Get-Hash { param([string] $Path) (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Copy-Fixture { param([string] $Name, [string] $Target) Copy-Item -LiteralPath (Join-Path $fixtureRoot $Name) -Destination $Target -Force }
function Test-ValidPair { param([object] $Pair) return ($Pair -is [System.Collections.IDictionary] -and $Pair.model -is [string] -and -not [string]::IsNullOrWhiteSpace($Pair.model) -and $Pair.effort -is [string] -and -not [string]::IsNullOrWhiteSpace($Pair.effort)) }

# Local contract reference; it operates only on caller-supplied copies and fixture/reference inputs.
function Invoke-PreferenceReference {
    param([string] $Path, [ValidateSet('query','save','inherit')][string] $Operation,
        [string] $Model, [string] $Effort, [string] $ReferencePath,
        [scriptblock] $BeforeWrite, [scriptblock] $AfterWrite,
        [object] $Template = $null)
    $exists = Test-Path -LiteralPath $Path -PathType Leaf
    if (-not $exists -and $Operation -ne 'save') { return [pscustomobject]@{ Result='inherit'; Value=$null } }
    $t0 = if ($exists) { [System.IO.File]::ReadAllText($Path) } else { $null }
    $data = if ($exists) { try { Read-JsonText $t0 } catch { return [pscustomobject]@{ Result='unreadable' } } } else { $null }
    if ($exists -and ($data -isnot [System.Collections.IDictionary] -or ($data.Contains('subagent_models') -and $data.subagent_models -isnot [System.Collections.IDictionary]))) { return [pscustomobject]@{ Result='incompatible-shape' } }
    if ($Operation -eq 'query') {
        if ($data.Contains('subagent_models') -and $data.subagent_models.Contains('default') -and -not (Test-ValidPair $data.subagent_models.default)) { return [pscustomobject]@{ Result='invalid-pair' } }
        return [pscustomobject]@{ Result='query'; Value=$(if ($data.Contains('subagent_models')) {$data.subagent_models.default} else {$null}) }
    }
    if ($Operation -eq 'save') {
        if (-not (Test-ValidPair @{model=$Model;effort=$Effort})) { return [pscustomobject]@{ Result='invalid-pair' } }
        if (-not (Test-Path -LiteralPath $ReferencePath -PathType Leaf) -or ([System.IO.File]::ReadAllText($ReferencePath) -notmatch [regex]::Escape($Model)) -or ([System.IO.File]::ReadAllText($ReferencePath) -notmatch [regex]::Escape($Effort))) { return [pscustomobject]@{ Result='reference-unavailable' } }
        if (-not $exists) {
            if ($null -eq $Template) { return [pscustomobject]@{ Result='template-unreadable' } }
            $data = [ordered]@{}; foreach ($key in $Template.Keys) { $data[$key]=$Template[$key] }
        }
        if ($exists -and $data.Contains('subagent_models') -and $data.subagent_models.Contains('default') -and $data.subagent_models.default.model -ceq $Model -and $data.subagent_models.default.effort -ceq $Effort) { return [pscustomobject]@{ Result='unchanged' } }
        if (-not $data.Contains('subagent_models')) { $data.subagent_models=[ordered]@{} }
        $data.subagent_models.default=[ordered]@{model=$Model;effort=$Effort}
    } else {
        if (-not $data.Contains('subagent_models') -or -not $data.subagent_models.Contains('default')) { return [pscustomobject]@{ Result='inherit' } }
        $data.subagent_models.Remove('default')
    }
    $expected=Get-JsonDigest $data
    if ($BeforeWrite) { & $BeforeWrite $Path }
    if ($exists -and [System.IO.File]::ReadAllText($Path) -cne $t0) { return [pscustomobject]@{ Result='changed-since-read' } }
    $json=ConvertTo-Json -InputObject $data -Depth 20
    $json=$json -replace "`r`n?", "`n"
    [System.IO.File]::WriteAllText($Path,$json,[System.Text.UTF8Encoding]::new($false))
    if ($AfterWrite) { & $AfterWrite $Path }
    try { $actual=Get-JsonDigest (Read-JsonText ([System.IO.File]::ReadAllText($Path))) } catch { $actual='' }
    if ($actual -cne $expected) {
        if ($exists) { [System.IO.File]::WriteAllText($Path,$t0,[System.Text.UTF8Encoding]::new($false)) }
        else { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
        return [pscustomobject]@{ Result='reread-mismatch'; Restored=($exists -and [System.IO.File]::ReadAllText($Path) -ceq $t0) }
    }
    return [pscustomobject]@{ Result='saved'; Value=(Read-JsonText ([System.IO.File]::ReadAllText($Path))) }
}

# Models the US03 confirmation gate before calling the existing field-scoped writer.
function Invoke-ConfirmedSessionPreferenceUpdate {
    param([string] $Path, [PSCustomObject] $Case, [string] $ReferencePath)
    if (-not [bool]$Case.given.pairWasUsed -or -not [bool]$Case.given.explicitConfirmation) {
        return [pscustomobject]@{ Result='not-confirmed-use' }
    }
    $afterWrite = if ([bool]$Case.given.simulateWriteFailure) { { param($target) [System.IO.File]::WriteAllText($target, 'corrupt') } } else { $null }
    return Invoke-PreferenceReference -Path $Path -Operation save -Model 'fixture-model-b' -Effort 'fixture-effort-b' -ReferencePath $ReferencePath -AfterWrite $afterWrite
}

try {
    $skillPath=Join-Path $repoRoot 'core\skills\adt-settings\SKILL.md'
    $skill=[System.IO.File]::ReadAllText($skillPath)
    $n='Should_DeclareContractMarkers_When_SkillManifestInspected'
    foreach ($marker in @('subagent_models.default','SUBAGENT-OPTIONS.md','STORAGE-RESOLUTION.md','Never print an absolute path','changed-since-read','unreadable','incompatible-shape','invalid-pair','reference-unavailable','template-unreadable','write-failed','reread-mismatch','no-explicit-request')) { if ($skill -notmatch [regex]::Escape($marker)) { Write-Fail $n "missing marker $marker" } }
    Write-Pass $n

    $n='Should_KeepManifestPortable_When_SkillManifestInspected'
    $featurePathToken='features' + '/'
    if ($skill.Contains($featurePathToken) -or $skill -match '(?:[A-Za-z]:\\|/Users/|/home/)' -or $skill -match '(?i)fixture-model-[ab]') { Write-Fail $n 'manifest contains a feature path, absolute path, or model list' }
    Write-Pass $n

    $n='Should_MatchInstallerTemplate_When_StorageBlockParsed'
    . (Join-Path $scriptsRoot '_lib\Initialize-SddPreferences.ps1')
    $defaults=New-ToolkitDefaultPreferencesObject
    $storage=[System.IO.File]::ReadAllText((Join-Path $repoRoot 'core\skills\_shared\sdd-artifacts\STORAGE-RESOLUTION.md'))
    $block=[regex]::Match($storage,'(?s)### Preferences structure.*?```json\s*(\{.*?\})\s*```')
    if (-not $block.Success) { Write-Fail $n 'preferences JSON block missing' }
    $template=Read-JsonText $block.Groups[1].Value
    if ((Get-JsonDigest $template) -cne (Get-JsonDigest $defaults)) { Write-Fail $n 'template differs from installer object' }
    Write-Pass $n

    $n='Should_SaveOnlyAfterConfirmedUse_AndPreserveOldValueOnFailure'
    $confirmedUseFixturePath=Join-Path $sessionChoiceFixtureRoot 'us03-confirmed-use-save-cases.json'
    if(-not (Test-Path -LiteralPath $confirmedUseFixturePath -PathType Leaf)){Write-Fail $n 'US03 confirmed-use fixture missing'}
    $confirmedUseFixture=Get-Content -LiteralPath $confirmedUseFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
    if($confirmedUseFixture.schemaVersion -ne 1 -or @($confirmedUseFixture.cases).Count -ne 4){Write-Fail $n 'US03 confirmed-use fixture must contain four cases'}
    $work=New-ToolkitWorkRoot -RepoRoot $repoRoot
    try {
        $prefs=Join-Path $work 'confirmed-use.json'; $ref=Join-Path $fixtureRoot 'reference-stub.md'
        foreach($case in $confirmedUseFixture.cases){
            Copy-Fixture 'prefs-with-default.json' $prefs; $oldHash=Get-Hash $prefs
            $result=Invoke-ConfirmedSessionPreferenceUpdate -Path $prefs -Case $case -ReferencePath $ref
            if($result.Result -cne [string]$case.expect.result){Write-Fail $n ("{0}: expected {1}, got {2}" -f $case.id,$case.expect.result,$result.Result)}
            if(-not [bool]$case.expect.saveRequested){
                if((Get-Hash $prefs) -cne $oldHash){Write-Fail $n ("{0}: preference changed without confirmed pair use" -f $case.id)}
            } elseif($case.given.simulateWriteFailure){
                if(-not [bool]$result.Restored -or (Get-Hash $prefs) -cne $oldHash){Write-Fail $n ("{0}: failed write did not restore prior value" -f $case.id)}
            } else {
                $expected=Read-JsonText ([System.IO.File]::ReadAllText((Join-Path $fixtureRoot 'expected-after-save.json')))
                $actual=Read-JsonText ([System.IO.File]::ReadAllText($prefs))
                if((Get-JsonDigest $actual) -cne (Get-JsonDigest $expected)){Write-Fail $n ("{0}: confirmed write changed unexpected fields" -f $case.id)}
            }
        }
    }
    finally { Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work }
    Write-Pass $n

    $n='Should_NotWrite_When_QueryingAnyFixture'
    $fixtureFiles=@(Get-ChildItem -LiteralPath $fixtureRoot -File)
    $before=@{}; foreach($f in $fixtureFiles){$before[$f.Name]=Get-Hash $f.FullName}
    foreach($name in @('prefs-base.json','prefs-with-default.json','prefs-invalid-default.json','prefs-unreadable.json','prefs-not-object.json','prefs-subagent-models-array.json')) {
        $path=Join-Path $fixtureRoot $name; $null=Invoke-PreferenceReference -Path $path -Operation query -ReferencePath (Join-Path $fixtureRoot 'reference-stub.md')
    }
    foreach($f in $fixtureFiles){if((Get-Hash $f.FullName) -cne $before[$f.Name]){Write-Fail $n "fixture changed: $($f.Name)"}}
    Write-Pass $n

    $work=New-ToolkitWorkRoot -RepoRoot $repoRoot
    try {
        $prefs=Join-Path $work 'prefs.json'; $ref=Join-Path $work 'reference.md'; Copy-Fixture 'prefs-with-default.json' $prefs; Copy-Fixture 'reference-stub.md' $ref
        $r=Invoke-PreferenceReference $prefs save 'fixture-model-b' 'fixture-effort-b' $ref
        $expected=Read-JsonText ([System.IO.File]::ReadAllText((Join-Path $fixtureRoot 'expected-after-save.json')))
        if($r.Result -ne 'saved' -or (Get-JsonDigest (Read-JsonText ([System.IO.File]::ReadAllText($prefs)))) -cne (Get-JsonDigest $expected)){Write-Fail 'Should_SaveOnlyDefault_When_SavingPair' 'saved JSON differs from fixture'}
        Write-Pass 'Should_SaveOnlyDefault_When_SavingPair'

        Copy-Fixture 'prefs-with-default.json' $prefs; $hash=Get-Hash $prefs
        $r=Invoke-PreferenceReference $prefs save 'fixture-model-a' 'fixture-effort-a' $ref
        if($r.Result -ne 'unchanged' -or (Get-Hash $prefs) -cne $hash){Write-Fail 'Should_NotRewrite_When_SavingIdenticalPair' 'identical save rewrote the file'}
        Write-Pass 'Should_NotRewrite_When_SavingIdenticalPair'

        $r=Invoke-PreferenceReference $prefs inherit 'fixture-model-a' 'fixture-effort-a' $ref
        $expected=Read-JsonText ([System.IO.File]::ReadAllText((Join-Path $fixtureRoot 'expected-after-reset.json')))
        if((Get-JsonDigest (Read-JsonText ([System.IO.File]::ReadAllText($prefs)))) -cne (Get-JsonDigest $expected)){Write-Fail 'Should_RemoveOnlyDefault_When_ReturningToInheritance' 'reset changed unexpected content'}
        $hash=Get-Hash $prefs; $null=Invoke-PreferenceReference $prefs inherit '' '' $ref
        $base=Join-Path $work 'base.json'; Copy-Fixture 'prefs-base.json' $base; $baseHash=Get-Hash $base; $null=Invoke-PreferenceReference $base inherit '' '' $ref
        $absent=Join-Path $work 'absent.json'; $null=Invoke-PreferenceReference $absent inherit '' '' $ref
        Remove-Item -LiteralPath $ref
        $withoutReference=Join-Path $work 'without-ref.json'; Copy-Fixture 'prefs-with-default.json' $withoutReference
        $null=Invoke-PreferenceReference $withoutReference inherit '' '' $ref
        if((Get-Hash $prefs) -cne $hash -or (Get-Hash $base) -cne $baseHash -or (Test-Path $absent) -or (Read-JsonText ([System.IO.File]::ReadAllText($withoutReference))).subagent_models.Contains('default')){Write-Fail 'Should_RemoveOnlyDefault_When_ReturningToInheritance' 'reset not idempotent or reference incorrectly required'}
        Write-Pass 'Should_RemoveOnlyDefault_When_ReturningToInheritance'

        foreach($name in @('prefs-unreadable.json','prefs-not-object.json','prefs-subagent-models-array.json')) {
            $bad=Join-Path $work $name; Copy-Fixture $name $bad; $hash=Get-Hash $bad
            foreach($op in @('query','save','inherit')) { $res=Invoke-PreferenceReference $bad $op 'fixture-model-a' 'fixture-effort-a' $ref; if($res.Result -notin @('unreadable','incompatible-shape')){Write-Fail 'Should_RefuseWithoutWrite_When_FileUnreadableOrIncompatible' "unexpected result $($res.Result) for $name/$op"} }
            if((Get-Hash $bad) -cne $hash){Write-Fail 'Should_RefuseWithoutWrite_When_FileUnreadableOrIncompatible' "rewrote $name"}
        }
        Write-Pass 'Should_RefuseWithoutWrite_When_FileUnreadableOrIncompatible'

        Copy-Fixture 'prefs-base.json' $prefs; $hash=Get-Hash $prefs
        $r=Invoke-PreferenceReference $prefs save 'not-listed' 'fixture-effort-a' $ref
        $noRef=Join-Path $work 'missing-reference.md'; $r2=Invoke-PreferenceReference $prefs save 'fixture-model-a' 'fixture-effort-a' $noRef
        if($r.Result -ne 'reference-unavailable' -or $r2.Result -ne 'reference-unavailable' -or (Get-Hash $prefs) -cne $hash){Write-Fail 'Should_RefuseSave_When_ReferenceUnavailableOrPairInvalid' 'invalid reference/pair was not refused without write'}
        Write-Pass 'Should_RefuseSave_When_ReferenceUnavailableOrPairInvalid'

        Copy-Fixture 'reference-stub.md' $ref
        $absent=Join-Path $work 'new\preferences.json'; New-Item -ItemType Directory -Path (Split-Path -Parent $absent) -Force|Out-Null
        $r=Invoke-PreferenceReference $absent save 'fixture-model-a' 'fixture-effort-a' $ref -Template $defaults
        $raw=[System.IO.File]::ReadAllBytes($absent); $text=[System.IO.File]::ReadAllText($absent)
        if($r.Result -ne 'saved' -or $raw.Length -ge 3 -and $raw[0..2] -ceq @(239,187,191) -or $text.Contains("`r")){Write-Fail 'Should_CreateFromTemplate_When_FileAbsentAndSaving' 'new file encoding or content invalid'}
        Write-Pass 'Should_CreateFromTemplate_When_FileAbsentAndSaving'
        $none=Join-Path $work 'template-unreadable.json'; $r=Invoke-PreferenceReference $none save 'fixture-model-a' 'fixture-effort-a' $ref
        if($r.Result -ne 'template-unreadable' -or (Test-Path $none)){Write-Fail 'Should_NotCreateFile_When_TemplateUnreadable' 'created file without readable template'}
        Write-Pass 'Should_NotCreateFile_When_TemplateUnreadable'

        Copy-Fixture 'prefs-base.json' $prefs
        $r=Invoke-PreferenceReference $prefs save 'fixture-model-a' 'fixture-effort-a' $ref -Template $defaults -BeforeWrite {param($p)[System.IO.File]::AppendAllText($p,' ')}
        if($r.Result -ne 'changed-since-read'){Write-Fail 'Should_RefuseWrite_When_ContentChangedSinceRead' "got $($r.Result)"}
        Write-Pass 'Should_RefuseWrite_When_ContentChangedSinceRead'
        Copy-Fixture 'prefs-base.json' $prefs; $original=[System.IO.File]::ReadAllText($prefs)
        $r=Invoke-PreferenceReference $prefs save 'fixture-model-a' 'fixture-effort-a' $ref -Template $defaults -AfterWrite {param($p)[System.IO.File]::WriteAllText($p,'corrupt')}
        if($r.Result -ne 'reread-mismatch' -or -not $r.Restored -or [System.IO.File]::ReadAllText($prefs) -cne $original){Write-Fail 'Should_RestoreOriginal_When_RereadMismatch' 'original content not restored after mismatch'}
        Write-Pass 'Should_RestoreOriginal_When_RereadMismatch'
    }
    finally { Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work }

    $n='Should_KeepSubagentModels_When_ClaudeHookRewritesPreferences'
    $work=New-ToolkitWorkRoot -RepoRoot $repoRoot
    $oldProfile=$env:USERPROFILE; $oldHome=$env:HOME
    try {
        $env:USERPROFILE=$work; $env:HOME=$work
        . (Join-Path $repoRoot 'adapters\claude\assets\hooks\_hook-common.ps1')
        $target=Get-ClaudePreferencesPath; New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force|Out-Null
        Copy-Fixture 'prefs-with-default.json' $target
        $read=Read-ClaudePreferences
        if(-not $read.Readable){Write-Fail $n 'hook could not read preferences fixture'}
        Write-ClaudePreferences -Values $read.Values
        $after=Read-JsonText ([System.IO.File]::ReadAllText($target)); $expected=Read-JsonText ([System.IO.File]::ReadAllText((Join-Path $fixtureRoot 'prefs-with-default.json')))
        if((Get-JsonDigest $after.subagent_models) -cne (Get-JsonDigest $expected.subagent_models) -or (Get-JsonDigest $after.custom_key) -cne (Get-JsonDigest $expected.custom_key)){Write-Fail $n 'hook rewrite dropped subagent_models or custom key'}
        Write-Pass $n
    }
    finally { $env:USERPROFILE=$oldProfile; $env:HOME=$oldHome; Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work }
}
catch { Write-Fail 'Assert-AdtSettingsContract' $_.Exception.Message }

Write-Host 'Assert-AdtSettingsContract: ALL PASS'
exit 0
