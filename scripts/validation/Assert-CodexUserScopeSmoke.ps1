#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'adapters/codex/CodexAdapter.ps1')

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-user-scope-smoke-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0
$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false
$toolkitSkillIds = @(Get-CodexToolkitSkillIds -RepoRoot $repoRoot)

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected [{1}], got [{2}]' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function New-UserRoot {
    param([Parameter(Mandatory = $true)][string] $Name)

    $root = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

function New-SkillFolder {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string] $Name,
        [switch] $WithManifest
    )

    $dir = Join-Path $Root $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    if ($WithManifest) {
        [System.IO.File]::WriteAllText((Join-Path $dir 'SKILL.md'), ('# {0}' -f $Name) + "`n", $utf8)
    }
}

function New-TextFile {
    param([Parameter(Mandatory = $true)][string] $Path)

    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, "# fixture`n", $utf8)
}

function New-ManagedMarker {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [string[]] $SkillNames = @()
    )

    Write-ToolkitManagedSkillsManifest -DestinationSkillsRoot $Root -SkillNames $SkillNames | Out-Null
}

function Invoke-UserSkillsCheck {
    param([Parameter(Mandatory = $true)][string] $Root)

    return Test-CodexUserSkillsFixture -UserSkillsRoot $Root -ToolkitSkillIds $toolkitSkillIds
}

try {
    Assert-True ($toolkitSkillIds -contains 'adt-help-skills') 'Should_ListHelpSkills_When_CoreSkillsEnumerated'
    Assert-True ($toolkitSkillIds -notcontains '_shared') 'Should_ExcludeShared_When_CoreSkillsEnumerated'

    $absentRoot = Join-Path $tempRoot 'absent'
    $absent = Invoke-UserSkillsCheck -Root $absentRoot
    Assert-True ([bool]$absent.Ok) 'Should_Pass_When_UserRootAbsent'
    Assert-True (-not [bool]$absent.Mirrored) 'Should_NotExpectMirror_When_UserRootAbsent'

    $emptyRoot = New-UserRoot -Name 'empty'
    $empty = Invoke-UserSkillsCheck -Root $emptyRoot
    Assert-True ([bool]$empty.Ok) 'Should_Pass_When_UserRootEmpty'
    Assert-True (-not [bool]$empty.Mirrored) 'Should_NotExpectMirror_When_UserRootEmpty'

    $foreignRoot = New-UserRoot -Name 'foreign-only'
    New-SkillFolder -Root $foreignRoot -Name 'impeccable' -WithManifest
    $foreign = Invoke-UserSkillsCheck -Root $foreignRoot
    Assert-True ([bool]$foreign.Ok) 'Should_Pass_When_UserRootHoldsOnlyForeignSkill'
    Assert-True (-not [bool]$foreign.Mirrored) 'Should_NotExpectMirror_When_UserRootHoldsOnlyForeignSkill'

    $foreignBareRoot = New-UserRoot -Name 'foreign-bare'
    New-SkillFolder -Root $foreignBareRoot -Name 'impeccable'
    New-SkillFolder -Root $foreignBareRoot -Name 'other-tool' -WithManifest
    $foreignBare = Invoke-UserSkillsCheck -Root $foreignBareRoot
    Assert-True ([bool]$foreignBare.Ok) 'Should_NotFailIncomplete_When_ForeignFolderLacksSkillMd'
    Assert-True (-not [bool]$foreignBare.Mirrored) 'Should_NotExpectMirror_When_ForeignFolderLacksSkillMd'

    $completeRoot = New-UserRoot -Name 'complete'
    New-SkillFolder -Root $completeRoot -Name 'impeccable' -WithManifest
    New-SkillFolder -Root $completeRoot -Name 'adt-help-skills' -WithManifest
    New-SkillFolder -Root $completeRoot -Name 'adt-commit' -WithManifest
    New-TextFile -Path (Get-CodexSmokeSkillsCatalogPath -SkillsRoot $completeRoot)
    New-ManagedMarker -Root $completeRoot -SkillNames @('adt-commit', 'adt-help-skills')
    $complete = Invoke-UserSkillsCheck -Root $completeRoot
    Assert-True ([bool]$complete.Ok) 'Should_Pass_When_CompleteToolkitMirror'
    Assert-True ([bool]$complete.Mirrored) 'Should_ExpectMirror_When_CompleteToolkitMirror'

    $markerOnlyRoot = New-UserRoot -Name 'marker-only'
    New-ManagedMarker -Root $markerOnlyRoot -SkillNames @('adt-help-skills')
    $markerOnly = Invoke-UserSkillsCheck -Root $markerOnlyRoot
    Assert-True (-not [bool]$markerOnly.Ok) 'Should_Fail_When_ManagedMarkerListsSkillsButHelpSkillsMissing'
    Assert-True ([bool]$markerOnly.Mirrored) 'Should_ExpectMirror_When_ManagedMarkerListsSkills'
    Assert-Equal ($script:CodexSmokeMessage.UserSkillsHelpSkillsMissing -f (Get-CodexSmokeHelpSkillsManifestPath -SkillsRoot $markerOnlyRoot)) ([string]$markerOnly.Message) 'Should_ReturnHelpSkillsMissing_When_ManagedMarkerListsSkills'

    $staleMarkerRoot = New-UserRoot -Name 'stale-marker'
    New-ManagedMarker -Root $staleMarkerRoot -SkillNames @()
    New-SkillFolder -Root $staleMarkerRoot -Name 'impeccable' -WithManifest
    $staleMarker = Invoke-UserSkillsCheck -Root $staleMarkerRoot
    Assert-True ([bool]$staleMarker.Ok) 'Should_Pass_When_ManagedMarkerListsNoSkills'
    Assert-True (-not [bool]$staleMarker.Mirrored) 'Should_NotExpectMirror_When_ManagedMarkerListsNoSkills'

    $toolkitIdRoot = New-UserRoot -Name 'toolkit-id-no-help'
    New-SkillFolder -Root $toolkitIdRoot -Name 'adt-commit' -WithManifest
    $toolkitIdNoHelp = Invoke-UserSkillsCheck -Root $toolkitIdRoot
    Assert-True (-not [bool]$toolkitIdNoHelp.Ok) 'Should_Fail_When_ToolkitSkillIdPresentButHelpSkillsMissing'
    Assert-True ([bool]$toolkitIdNoHelp.Mirrored) 'Should_ExpectMirror_When_ToolkitSkillIdPresent'
    Assert-Equal ($script:CodexSmokeMessage.UserSkillsHelpSkillsMissing -f (Get-CodexSmokeHelpSkillsManifestPath -SkillsRoot $toolkitIdRoot)) ([string]$toolkitIdNoHelp.Message) 'Should_ReturnHelpSkillsMissing_When_ToolkitSkillIdPresent'

    $incompleteRoot = New-UserRoot -Name 'toolkit-folder-incomplete'
    New-SkillFolder -Root $incompleteRoot -Name 'adt-commit'
    New-SkillFolder -Root $incompleteRoot -Name 'impeccable' -WithManifest
    $incomplete = Invoke-UserSkillsCheck -Root $incompleteRoot
    Assert-True (-not [bool]$incomplete.Ok) 'Should_Fail_When_ToolkitSkillFolderLacksSkillMd'
    Assert-True ([bool]$incomplete.Mirrored) 'Should_ExpectMirror_When_ToolkitSkillFolderLacksSkillMd'
    Assert-Equal ($script:CodexSmokeMessage.UserSkillsIncomplete -f (Join-Path (Join-Path $incompleteRoot 'adt-commit') 'SKILL.md')) ([string]$incomplete.Message) 'Should_ReturnIncomplete_When_ToolkitSkillFolderLacksSkillMd'

    $noCatalogRoot = New-UserRoot -Name 'no-catalog'
    New-SkillFolder -Root $noCatalogRoot -Name 'adt-help-skills' -WithManifest
    New-ManagedMarker -Root $noCatalogRoot -SkillNames @('adt-help-skills')
    $noCatalog = Invoke-UserSkillsCheck -Root $noCatalogRoot
    Assert-True (-not [bool]$noCatalog.Ok) 'Should_Fail_When_CatalogMissingForExpectedMirror'
    Assert-Equal ($script:CodexSmokeMessage.UserSkillsCatalogMissing -f (Get-CodexSmokeSkillsCatalogPath -SkillsRoot $noCatalogRoot)) ([string]$noCatalog.Message) 'Should_ReturnCatalogMissing_When_CatalogAbsentForExpectedMirror'

    Write-Output ('PASS: {0} Codex USER-scope smoke assertions.' -f $passed)
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
