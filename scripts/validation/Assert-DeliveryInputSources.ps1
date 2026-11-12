#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptsRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $scriptsRoot '_lib/DeliveryInputSources.ps1')
$cliScript = Join-Path $scriptsRoot 'runtime/Get-DeliveryInputSourceIdentity.ps1'

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-input-sources-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0
$utf8 = [System.Text.UTF8Encoding]::new($false)
$reparsePaths = [System.Collections.Generic.List[string]]::new()
$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)

function Assert-True {
    param([bool] $Condition, [string] $Name)
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal {
    param([string] $Expected, [string] $Actual, [string] $Name)
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Assert-Throws {
    param([string] $Code, [string] $Name, [scriptblock] $Action)
    $message = $null
    try { & $Action } catch { $message = $_.Exception.Message }
    if ($null -eq $message) { throw ('{0}: expected {1} but nothing was thrown' -f $Name, $Code) }
    if (-not $message.StartsWith($Code + ': ', [System.StringComparison]::Ordinal)) { throw ('{0}: expected {1}, got: {2}' -f $Name, $Code, $message) }
    if ($message.Contains($tempRoot) -or $message.Contains($tempRoot.Replace('\', '/'))) { throw ('{0}: message exposes the temp root' -f $Name) }
    $script:passed++
}

function Get-FileSha256Hex {
    param([string] $Path)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.IO.File]::ReadAllBytes($Path)))
}

function Get-TextSha256Hex {
    param([string] $Text)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($utf8.GetBytes($Text)))
}

function Write-TextFile {
    param([string] $Path, [string] $Text)
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Get-ExpectedFilesetIdentity {
    param([string] $Directory, [string[]] $Members)
    $sorted = [string[]]@($Members)
    [System.Array]::Sort($sorted, [System.StringComparer]::Ordinal)
    $items = foreach ($member in $sorted) {
        $hash = Get-FileSha256Hex -Path (Join-Path $Directory ($member.Replace('/', [System.IO.Path]::DirectorySeparatorChar)))
        '{"path":"' + $member + '","sha256":"' + $hash + '"}'
    }
    return Get-TextSha256Hex -Text ('[' + ($items -join ',') + ']')
}

function Get-ExpectedRevisionIdentity {
    param([string] $AliasName, [string] $Commit, [string] $Tree)
    return Get-TextSha256Hex -Text ('{"kind":"revision","alias":"' + $AliasName + '","commit":"' + $Commit + '","tree":"' + $Tree + '"}')
}

function Get-Fixture {
    param([string] $Path)
    return [System.IO.Path]::GetFullPath($Path)
}

function Invoke-Git {
    param([string] $Repo, [string[]] $Arguments)
    $output = & git -C $Repo @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw ('git fixture command failed in temp repository: {0}' -f ($Arguments -join ' ')) }
    return (@($output) -join "`n")
}

function New-GitFixture {
    param([string] $Name, [string] $Content)
    $repo = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Path $repo | Out-Null
    Invoke-Git -Repo $repo -Arguments @('-c', 'init.defaultBranch=main', 'init', '-q') | Out-Null
    Write-TextFile -Path (Join-Path $repo 'notes.txt') -Text $Content
    Invoke-Git -Repo $repo -Arguments @('add', '--', 'notes.txt') | Out-Null
    Invoke-Git -Repo $repo -Arguments @('-c', 'user.name=t', '-c', 'user.email=t@t.t', '-c', 'commit.gpgsign=false', 'commit', '-q', '-m', 'test: seed fixture') | Out-Null
    return $repo
}

function ConvertTo-ProcessArgument([string] $Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-Cli {
    param([string[]] $CliArgs)
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $cliScript) + $CliArgs
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $childHost
    $startInfo.Arguments = (@($argList | ForEach-Object { ConvertTo-ProcessArgument ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $stdoutText = $stdoutTask.Result
    $parsed = $null
    if ($stdoutText.Trim().Length -gt 0) {
        try { $parsed = $stdoutText.Trim() | ConvertFrom-Json } catch { $parsed = $null }
    }
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Result = $parsed; Stdout = $stdoutText; Stderr = $stderrText }
}

function New-TestJunction {
    param([string] $Path, [string] $Target)
    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
    $reparsePaths.Add($Path)
}

function Remove-ReparsePaths {
    foreach ($path in $reparsePaths) {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($null -eq $item) { continue }
        if ($item.PSIsContainer) { [System.IO.Directory]::Delete($path, $false) }
        else { [System.IO.File]::Delete($path) }
    }
}

try {
    $demoRoot = Get-Fixture (Join-Path $tempRoot 'demo-root')
    Write-TextFile -Path (Join-Path $demoRoot 'a.txt') -Text 'alpha'
    Write-TextFile -Path (Join-Path $demoRoot 'sub/b.txt') -Text 'beta'
    Write-TextFile -Path (Join-Path $demoRoot 'set/a.txt') -Text 'one'
    Write-TextFile -Path (Join-Path $demoRoot 'set/b.txt') -Text 'two'
    Write-TextFile -Path (Join-Path $demoRoot 'set/sub/c.txt') -Text 'three'
    Write-TextFile -Path (Join-Path $demoRoot 'grow.txt') -Text 'grow'
    New-Item -ItemType Directory -Path (Join-Path $demoRoot 'empty-dir') | Out-Null
    $outsideRoot = Get-Fixture (Join-Path $tempRoot 'outside-dir')
    Write-TextFile -Path (Join-Path $outsideRoot 'secret.txt') -Text 'outside'

    $demoEntry = [ordered]@{ name = 'demo'; root = $demoRoot; kind = 'directory' }
    $catalogPath = Get-Fixture (Join-Path $tempRoot 'aliases-one.json')
    Write-TextFile -Path $catalogPath -Text ((([ordered]@{ schema = 'delivery-input-aliases/v1'; aliases = @($demoEntry) }) | ConvertTo-Json -Depth 5))

    $otherRoot = Get-Fixture (Join-Path $tempRoot 'other-root')
    Write-TextFile -Path (Join-Path $otherRoot 'x.txt') -Text 'other'
    $twoEntries = @($demoEntry, [ordered]@{ name = 'other'; root = $otherRoot; kind = 'directory' })
    $gitOneCommit = ''
    $gitOneTree = ''
    $gitTwoCommit = ''
    $gitTwoTree = ''
    if ($gitAvailable) {
        $gitOne = New-GitFixture -Name 'git-one' -Content 'first repository'
        $gitTwo = New-GitFixture -Name 'git-two' -Content 'second repository'
        $gitOneCommit = (Invoke-Git -Repo $gitOne -Arguments @('rev-parse', 'HEAD')).Trim()
        $gitOneTree = (Invoke-Git -Repo $gitOne -Arguments @('rev-parse', 'HEAD^{tree}')).Trim()
        $gitTwoCommit = (Invoke-Git -Repo $gitTwo -Arguments @('rev-parse', 'HEAD')).Trim()
        $gitTwoTree = (Invoke-Git -Repo $gitTwo -Arguments @('rev-parse', 'HEAD^{tree}')).Trim()
        $twoEntries += [ordered]@{ name = 'repo-one'; root = $gitOne; kind = 'git' }
        $twoEntries += [ordered]@{ name = 'repo-two'; root = $gitTwo; kind = 'git' }
    }
    $twoCatalogPath = Get-Fixture (Join-Path $tempRoot 'aliases-two.json')
    Write-TextFile -Path $twoCatalogPath -Text ((([ordered]@{ schema = 'delivery-input-aliases/v1'; aliases = $twoEntries }) | ConvertTo-Json -Depth 5))

    $alphaSha = Get-FileSha256Hex -Path (Join-Path $demoRoot 'a.txt')
    $betaSha = Get-FileSha256Hex -Path (Join-Path $demoRoot 'sub/b.txt')
    $setFileInput = '{"path":"alias:demo/a.txt"}'

    $catalogOne = Read-DeliveryAliasCatalog -Path $catalogPath
    Assert-True ($catalogOne -is [System.Collections.Hashtable]) 'Should_ReturnHashtable_When_CatalogHasOneAlias'
    Assert-True ($catalogOne.Contains('demo') -and $catalogOne.Count -eq 1) 'Should_ReturnOneAlias_When_CatalogHasOneAlias'
    Assert-Equal $demoRoot $catalogOne['demo'].Root 'Should_ReturnFullRoot_When_CatalogHasOneAlias'
    Assert-Equal 'directory' $catalogOne['demo'].Kind 'Should_ReturnKind_When_CatalogHasOneAlias'

    $catalogTwo = Read-DeliveryAliasCatalog -Path $twoCatalogPath
    Assert-True ($catalogTwo.Count -eq $twoEntries.Count -and $catalogTwo.Count -ge 2) 'Should_ReturnAllAliases_When_CatalogHasTwoOrMoreAliases'
    Assert-Equal 'directory' $catalogTwo['other'].Kind 'Should_ReturnDirectoryKind_When_CatalogHasTwoAliases'
    if ($gitAvailable) { Assert-Equal 'git' $catalogTwo['repo-one'].Kind 'Should_ReturnGitKind_When_CatalogHasGitAlias' }

    $singleGitCatalog = Get-Fixture (Join-Path $tempRoot 'aliases-single-git.json')
    Write-TextFile -Path $singleGitCatalog -Text ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"repo-one","root":"' + $gitOne.Replace('\', '/') + '","kind":"git"}]}')
    $singleGit = Read-DeliveryAliasCatalog -Path $singleGitCatalog
    Assert-True ($singleGit.Contains('repo-one')) 'Should_AcceptOneElementAliasesArray_When_RawJson'

    $catalogCases = @(
        @{ Name = 'Should_RejectCatalog_When_FileMissing'; Code = 'alias_catalog_missing'; Path = (Join-Path $tempRoot 'no-such-catalog.json') },
        @{ Name = 'Should_RejectCatalog_When_PathEmpty'; Code = 'alias_catalog_missing'; Path = '' },
        @{ Name = 'Should_RejectCatalog_When_PathNull'; Code = 'alias_catalog_missing'; Path = $null }
    )
    foreach ($case in $catalogCases) {
        Assert-Throws -Code $case.Code -Name $case.Name -Action { Read-DeliveryAliasCatalog -Path $case.Path }
    }
    $emptyCatalog = Get-Fixture (Join-Path $tempRoot 'empty-catalog.json')
    Write-TextFile -Path $emptyCatalog -Text ''
    Assert-Throws -Code 'alias_catalog_missing' -Name 'Should_RejectCatalog_When_FileEmpty' -Action { Read-DeliveryAliasCatalog -Path $emptyCatalog }

    $invalidCatalogs = [ordered]@{
        Should_RejectCatalog_When_JsonInvalid = '{"schema":'
        Should_RejectCatalog_When_KeyUnknown = ('{"schema":"delivery-input-aliases/v1","aliases":[],"extra":1}')
        Should_RejectCatalog_When_AliasKeyUnknown = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"directory","note":"x"}]}')
        Should_RejectCatalog_When_KeyCaseDiffers = ('{"schema":"delivery-input-aliases/v1","aliases":[{"Name":"demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"directory"}]}')
        Should_RejectCatalog_When_SchemaWrong = ('{"schema":"delivery-input-aliases/v2","aliases":[]}')
        Should_RejectCatalog_When_AliasNameUppercase = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"Demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"directory"}]}')
        Should_RejectCatalog_When_NameDuplicated = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"directory"},{"name":"demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"directory"}]}')
        Should_RejectCatalog_When_RootRelative = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"relative/dir","kind":"directory"}]}')
        Should_RejectCatalog_When_RootIsFile = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + $catalogPath.Replace('\', '/') + '","kind":"directory"}]}')
        Should_RejectCatalog_When_RootMissing = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + (Get-Fixture (Join-Path $tempRoot 'no-such-root')).Replace('\', '/') + '","kind":"directory"}]}')
        Should_RejectCatalog_When_GitKindWithoutDotGit = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"git"}]}')
        Should_RejectCatalog_When_KindUnknown = ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"file"}]}')
    }
    $caseIndex = 0
    foreach ($name in $invalidCatalogs.Keys) {
        $caseIndex++
        $badCatalog = Get-Fixture (Join-Path $tempRoot ('bad-catalog-{0}.json' -f $caseIndex))
        Write-TextFile -Path $badCatalog -Text $invalidCatalogs[$name]
        Assert-Throws -Code 'alias_catalog_invalid' -Name $name -Action { Read-DeliveryAliasCatalog -Path $badCatalog }
    }

    $junctionRoot = Get-Fixture (Join-Path $tempRoot 'junction-root')
    $junctionCatalog = Get-Fixture (Join-Path $tempRoot 'junction-catalog.json')
    $junctionCreated = $true
    try {
        New-TestJunction -Path $junctionRoot -Target $demoRoot
    }
    catch {
        $junctionCreated = $false
        Write-Host ('SKIP: alias root reparse-point check; the OS refused to create a junction: {0}' -f $_.Exception.Message)
    }
    if ($junctionCreated) {
        Write-TextFile -Path $junctionCatalog -Text ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + $junctionRoot.Replace('\', '/') + '","kind":"directory"}]}')
        Assert-Throws -Code 'alias_catalog_invalid' -Name 'Should_RejectCatalog_When_RootIsReparsePoint' -Action { Read-DeliveryAliasCatalog -Path $junctionCatalog }
    }

    $duplicateKeyCatalog = Get-Fixture (Join-Path $tempRoot 'duplicate-key-catalog.json')
    Write-TextFile -Path $duplicateKeyCatalog -Text ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"demo","root":"' + $demoRoot.Replace('\', '/') + '","kind":"directory","kind":"directory"}]}')
    $duplicateKeyOutcome = 'crashed'
    try {
        [void](Read-DeliveryAliasCatalog -Path $duplicateKeyCatalog)
        $duplicateKeyOutcome = 'returned'
    }
    catch {
        if ($_.Exception.Message -cmatch '\Aalias_catalog_[a-z]+: ') { $duplicateKeyOutcome = 'coded' }
    }
    Assert-True ($duplicateKeyOutcome -ne 'crashed') 'Should_NotCrash_When_CatalogHasDuplicateKeys'

    $resolved = Resolve-DeliveryAliasPath -Catalog $catalogOne -AliasPath 'alias:demo/sub/b.txt'
    Assert-Equal ([System.IO.Path]::GetFullPath((Join-Path $demoRoot 'sub\b.txt'))) $resolved.Full 'Should_ResolveNestedPath_When_AliasPathValid'
    Assert-Equal 'sub/b.txt' $resolved.Relative 'Should_ReturnRelative_When_AliasPathValid'
    Assert-Equal 'demo' $resolved.Alias 'Should_ReturnAliasName_When_AliasPathValid'
    $resolvedRoot = Resolve-DeliveryAliasPath -Catalog $catalogOne -AliasPath 'alias:demo'
    Assert-Equal $demoRoot $resolvedRoot.Full 'Should_ResolveRoot_When_AliasHasNoRelativePart'

    Assert-Throws -Code 'alias_unknown' -Name 'Should_RejectAlias_When_NameUnknown' -Action { Resolve-DeliveryAliasPath -Catalog $catalogOne -AliasPath 'alias:other/a.txt' }
    Assert-Throws -Code 'alias_unknown' -Name 'Should_RejectAlias_When_NameDiffersByCase' -Action { Resolve-DeliveryAliasPath -Catalog $catalogOne -AliasPath 'alias:Demo/a.txt' }

    $pathCases = @(
        @{ Name = 'Should_RejectPath_When_ParentSegment'; Path = 'alias:demo/../outside.txt' },
        @{ Name = 'Should_RejectPath_When_Backslash'; Path = 'alias:demo/sub\b.txt' },
        @{ Name = 'Should_RejectPath_When_BackslashBeforeName'; Path = 'alias:demo\a.txt' },
        @{ Name = 'Should_RejectPath_When_DriveForm'; Path = 'alias:demo/C:/x.txt' },
        @{ Name = 'Should_RejectPath_When_TrailingSlash'; Path = 'alias:demo/sub/' },
        @{ Name = 'Should_RejectPath_When_CurrentSegment'; Path = 'alias:demo/./a.txt' },
        @{ Name = 'Should_RejectPath_When_EmptySegment'; Path = 'alias:demo//a.txt' },
        @{ Name = 'Should_RejectPath_When_DoubleSlash'; Path = 'alias:demo//server/share' }
    )
    foreach ($case in $pathCases) {
        Assert-Throws -Code 'source_path_invalid' -Name $case.Name -Action { Resolve-DeliveryAliasPath -Catalog $catalogOne -AliasPath $case.Path }
        Assert-Throws -Code 'source_path_invalid' -Name ($case.Name + 'ThroughIdentity') -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = $case.Path }) -AliasCatalogPath $catalogPath }
    }

    $identityNoCatalog = { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/a.txt' }) }
    Assert-Throws -Code 'alias_catalog_missing' -Name 'Should_RequireCatalog_When_AliasPathUsedWithoutCatalog' -Action $identityNoCatalog

    $identity = Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/a.txt' }) -AliasCatalogPath $catalogPath
    Assert-Equal $alphaSha $identity 'Should_ReturnFileSha256_When_AliasFileValid'
    Assert-True ($identity -cmatch '\A[0-9A-F]{64}\z') 'Should_ReturnUppercaseHex_When_AliasFileValid'

    $explicitFile = Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/a.txt'; source = [pscustomobject]@{ kind = 'file' } }) -AliasCatalogPath $catalogPath
    Assert-Equal $alphaSha $explicitFile 'Should_MatchAbsentSource_When_SourceKindFile'

    Write-TextFile -Path (Join-Path $demoRoot 'changing.txt') -Text 'before'
    $beforeChange = Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/changing.txt' }) -AliasCatalogPath $catalogPath
    Write-TextFile -Path (Join-Path $demoRoot 'changing.txt') -Text 'after'
    $afterChange = Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/changing.txt' }) -AliasCatalogPath $catalogPath
    Assert-True ($beforeChange -cne $afterChange) 'Should_ChangeIdentity_When_FileBytesChange'
    Assert-Equal (Get-FileSha256Hex -Path (Join-Path $demoRoot 'changing.txt')) $afterChange 'Should_MatchIndependentSha_When_FileBytesChange'

    Assert-Throws -Code 'source_missing' -Name 'Should_RejectFile_When_Missing' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/none.txt' }) -AliasCatalogPath $catalogPath }
    Assert-Throws -Code 'source_unreadable' -Name 'Should_RejectFile_When_PathIsDirectory' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/sub' }) -AliasCatalogPath $catalogPath }

    $hugeFile = Join-Path $demoRoot 'huge.bin'
    $hugeStream = [System.IO.File]::Create($hugeFile)
    $hugeStream.SetLength(52428801)
    $hugeStream.Close()
    Assert-Throws -Code 'source_too_large' -Name 'Should_RejectFile_When_OverFiftyMegabytes' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/huge.bin' }) -AliasCatalogPath $catalogPath }
    Remove-Item -LiteralPath $hugeFile -Force

    $appendSeam = { param($Path) [System.IO.File]::AppendAllText($Path, 'x', $utf8) }
    Assert-Throws -Code 'source_changed_during_read' -Name 'Should_RejectFile_When_ChangedDuringRead' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/grow.txt' }) -AliasCatalogPath $catalogPath -AfterFirstRead $appendSeam }
    Assert-Equal (Get-FileSha256Hex -Path (Join-Path $demoRoot 'grow.txt')) (Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/grow.txt' }) -AliasCatalogPath $catalogPath) 'Should_ReturnStableIdentity_When_NoConcurrentChange'

    $outsideJunctionCreated = $true
    try { New-TestJunction -Path (Join-Path $demoRoot 'jlink') -Target $outsideRoot } catch {
        $outsideJunctionCreated = $false
        Write-Host ('SKIP: junction escape cases; the OS refused to create a junction: {0}' -f $_.Exception.Message)
    }
    if ($outsideJunctionCreated) {
        Assert-Throws -Code 'source_reparse_point' -Name 'Should_RejectPath_When_JunctionPointsOutsideRoot' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/jlink/secret.txt' }) -AliasCatalogPath $catalogPath }
        Assert-Throws -Code 'source_reparse_point' -Name 'Should_RejectPath_When_JunctionIsTarget' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/jlink' }) -AliasCatalogPath $catalogPath }
    }

    $danglingTarget = Get-Fixture (Join-Path $tempRoot 'dangling-target')
    New-Item -ItemType Directory -Path $danglingTarget | Out-Null
    $danglingJunctionCreated = $true
    try { New-TestJunction -Path (Join-Path $demoRoot 'djunk') -Target $danglingTarget } catch { $danglingJunctionCreated = $false }
    if ($danglingJunctionCreated) {
        Remove-Item -LiteralPath $danglingTarget -Recurse -Force
        Assert-Throws -Code 'source_reparse_point' -Name 'Should_RejectPath_When_DanglingJunction' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/djunk/x.txt' }) -AliasCatalogPath $catalogPath }
    }

    $symlinkCreated = $true
    try {
        New-Item -ItemType SymbolicLink -Path (Join-Path $demoRoot 'flink.txt') -Target (Join-Path $outsideRoot 'secret.txt') | Out-Null
        $reparsePaths.Add((Join-Path $demoRoot 'flink.txt'))
        New-Item -ItemType SymbolicLink -Path (Join-Path $demoRoot 'dangle.txt') -Target (Join-Path $outsideRoot 'nothing.txt') | Out-Null
        $reparsePaths.Add((Join-Path $demoRoot 'dangle.txt'))
    }
    catch {
        $symlinkCreated = $false
        Write-Host ('SKIP: symbolic link cases; the OS refused to create a symbolic link: {0}' -f $_.Exception.Message)
    }
    if ($symlinkCreated) {
        Assert-Throws -Code 'source_reparse_point' -Name 'Should_RejectFile_When_SymlinkPointsOutside' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/flink.txt' }) -AliasCatalogPath $catalogPath }
        Assert-Throws -Code 'source_reparse_point' -Name 'Should_RejectFile_When_DanglingSymlink' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/dangle.txt' }) -AliasCatalogPath $catalogPath }
    }

    $setMembers = @('a.txt', 'b.txt', 'sub/c.txt')
    $setDir = Join-Path $demoRoot 'set'
    $expectedSet = Get-ExpectedFilesetIdentity -Directory $setDir -Members $setMembers
    $setFileset = { param($Members) Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/set'; source = [pscustomobject]@{ kind = 'fileset'; files = [object[]]$Members } }) -AliasCatalogPath $catalogPath }
    $setIdentity = & $setFileset $setMembers
    Assert-Equal $expectedSet $setIdentity 'Should_MatchIndependentFilesetIdentity_When_MembersValid'
    Assert-Equal $expectedSet (& $setFileset @('sub/c.txt', 'b.txt', 'a.txt')) 'Should_BeStableUnderFileOrder_When_MembersReordered'
    Assert-Equal $expectedSet (& $setFileset @('sub/c.txt', 'a.txt', 'b.txt')) 'Should_BeStableUnderFileOrderVariant_When_MembersReordered'

    Write-TextFile -Path (Join-Path $setDir 'sub/d.txt') -Text 'four'
    $withAddedFile = Get-ExpectedFilesetIdentity -Directory $setDir -Members @('a.txt', 'b.txt', 'sub/c.txt', 'sub/d.txt')
    Assert-True ($withAddedFile -cne $expectedSet) 'Should_ChangeIdentity_When_FileAddedToFileset'
    Assert-Equal $withAddedFile (& $setFileset @('a.txt', 'b.txt', 'sub/c.txt', 'sub/d.txt')) 'Should_MatchIndependentIdentity_When_FileAddedToFileset'
    Assert-True ((& $setFileset @('a.txt', 'b.txt')) -cne $expectedSet) 'Should_ChangeIdentity_When_FileRemovedFromFileset'

    $originalA = [System.IO.File]::ReadAllText((Join-Path $setDir 'a.txt'), $utf8)
    Write-TextFile -Path (Join-Path $setDir 'a.txt') -Text 'changed'
    Assert-True ((& $setFileset $setMembers) -cne $expectedSet) 'Should_ChangeIdentity_When_FileBytesChangeInFileset'
    Write-TextFile -Path (Join-Path $setDir 'a.txt') -Text $originalA
    Assert-Equal $expectedSet (& $setFileset $setMembers) 'Should_RestoreIdentity_When_FileBytesRestored'

    Assert-Throws -Code 'fileset_collision' -Name 'Should_RejectFileset_When_NamesCollideByCase' -Action { & $setFileset @('a.txt', 'A.txt') }
    Assert-Throws -Code 'fileset_collision' -Name 'Should_RejectFileset_When_NameDuplicated' -Action { & $setFileset @('a.txt', 'a.txt') }
    Assert-Throws -Code 'source_missing' -Name 'Should_RejectFileset_When_MemberMissing' -Action { & $setFileset @('a.txt', 'missing.txt') }
    Assert-Throws -Code 'fileset_invalid' -Name 'Should_RejectFileset_When_FilesEmpty' -Action { & $setFileset @() }
    Assert-Throws -Code 'fileset_invalid' -Name 'Should_RejectFileset_When_FilesNotArray' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/set'; source = [pscustomobject]@{ kind = 'fileset'; files = 'a.txt' } }) -AliasCatalogPath $catalogPath }
    Assert-Throws -Code 'source_path_invalid' -Name 'Should_RejectFileset_When_MemberTraverses' -Action { & $setFileset @('../a.txt') }
    Assert-Throws -Code 'source_path_invalid' -Name 'Should_RejectFileset_When_MemberAbsolute' -Action { & $setFileset @('/a.txt') }

    $oneElementJson = ConvertFrom-Json -InputObject '{"path":"alias:demo/set","source":{"kind":"fileset","files":["a.txt"]}}'
    $oneElementIdentity = Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input $oneElementJson -AliasCatalogPath $catalogPath
    Assert-Equal (Get-ExpectedFilesetIdentity -Directory $setDir -Members @('a.txt')) $oneElementIdentity 'Should_AcceptOneElementFilesArray_When_JsonInput'

    $repoFileset = Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'set'; source = [pscustomobject]@{ kind = 'fileset'; files = @('a.txt', 'b.txt') } })
    Assert-Equal (Get-ExpectedFilesetIdentity -Directory $setDir -Members @('a.txt', 'b.txt')) $repoFileset 'Should_ResolveRepositoryRelativeFileset_When_RepoRootGiven'

    Assert-Throws -Code 'source_kind_invalid' -Name 'Should_RejectRepositoryFile_When_NoSource' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'set/a.txt' }) }
    Assert-Throws -Code 'source_kind_invalid' -Name 'Should_RejectSource_When_FileHasExtraKey' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/a.txt'; source = [pscustomobject]@{ kind = 'file'; files = @('a.txt') } }) -AliasCatalogPath $catalogPath }
    Assert-Throws -Code 'source_kind_invalid' -Name 'Should_RejectSource_When_KindUnknown' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/a.txt'; source = [pscustomobject]@{ kind = 'directory' } }) -AliasCatalogPath $catalogPath }
    Assert-Throws -Code 'source_kind_invalid' -Name 'Should_RejectSource_When_FilesetMissingFiles' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'alias:demo/set'; source = [pscustomobject]@{ kind = 'fileset' } }) -AliasCatalogPath $catalogPath }

    if ($gitAvailable) {
        $revisionSource = { param($Path, $Revision) Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = $Path; source = [pscustomobject]@{ kind = 'revision'; revision = $Revision } }) -AliasCatalogPath $twoCatalogPath }
        $validRevision = & $revisionSource 'alias:repo-one' $gitOneCommit
        Assert-Equal (Get-ExpectedRevisionIdentity -AliasName 'repo-one' -Commit $gitOneCommit -Tree $gitOneTree) $validRevision 'Should_MatchIndependentRevisionIdentity_When_CommitIdFull'
        Assert-True ($validRevision -cmatch '\A[0-9A-F]{64}\z') 'Should_ReturnUppercaseHex_When_RevisionValid'
        $secondRevision = & $revisionSource 'alias:repo-two' $gitTwoCommit
        Assert-True ($secondRevision -cne $validRevision) 'Should_DifferByRepository_When_TwoRepositoriesUsed'
        Assert-Equal (Get-ExpectedRevisionIdentity -AliasName 'repo-two' -Commit $gitTwoCommit -Tree $gitTwoTree) $secondRevision 'Should_MatchIndependentRevisionIdentity_When_SecondRepository'

        Assert-Throws -Code 'revision_invalid' -Name 'Should_RejectRevision_When_BranchName' -Action { & $revisionSource 'alias:repo-one' 'main' }
        Assert-Throws -Code 'revision_invalid' -Name 'Should_RejectRevision_When_Abbreviated' -Action { & $revisionSource 'alias:repo-one' $gitOneCommit.Substring(0, 7) }
        Assert-Throws -Code 'revision_unavailable' -Name 'Should_RejectRevision_When_WellFormedUnknown' -Action { & $revisionSource 'alias:repo-one' ('a' * 40) }
        Assert-Throws -Code 'source_kind_invalid' -Name 'Should_RejectRevision_When_AliasIsDirectory' -Action { & $revisionSource 'alias:demo' $gitOneCommit }
        Assert-Throws -Code 'source_kind_invalid' -Name 'Should_RejectRevision_When_PathHasRelativePart' -Action { & $revisionSource 'alias:repo-one/notes.txt' $gitOneCommit }
        Assert-Throws -Code 'source_kind_invalid' -Name 'Should_RejectRevision_When_PathIsRepositoryRelative' -Action { Get-DeliveryInputSourceIdentity -RepoRoot $demoRoot -Input ([pscustomobject]@{ path = 'a.txt'; source = [pscustomobject]@{ kind = 'revision'; revision = $gitOneCommit } }) -AliasCatalogPath $twoCatalogPath }
        Assert-Throws -Code 'alias_unknown' -Name 'Should_RejectRevision_When_AliasUnknown' -Action { & $revisionSource 'alias:repo-three' $gitOneCommit }
        Assert-Throws -Code 'revision_invalid' -Name 'Should_RejectRevision_When_NotHex' -Action { & $revisionSource 'alias:repo-one' ('g' * 40) }
    }
    else {
        Write-Host 'SKIP: revision cases; git is not available on this host.'
    }

    $fakeGitRoot = Get-Fixture (Join-Path $tempRoot 'fake-git-root')
    New-Item -ItemType Directory -Path (Join-Path $fakeGitRoot '.git') -Force | Out-Null
    $noGitCatalog = Get-Fixture (Join-Path $tempRoot 'aliases-no-git.json')
    Write-TextFile -Path $noGitCatalog -Text ('{"schema":"delivery-input-aliases/v1","aliases":[{"name":"repo-one","root":"' + $fakeGitRoot.Replace('\', '/') + '","kind":"git"}]}')
    $emptyPathDir = Get-Fixture (Join-Path $tempRoot 'empty-path-dir')
    New-Item -ItemType Directory -Path $emptyPathDir | Out-Null
    $noGitProbe = Get-Fixture (Join-Path $tempRoot 'no-git-probe.ps1')
    Write-TextFile -Path $noGitProbe -Text @'
param([string] $Library, [string] $Catalog, [string] $RepoRoot)
. $Library
try {
    [void](Get-DeliveryInputSourceIdentity -RepoRoot $RepoRoot -Input ([pscustomobject]@{ path = 'alias:repo-one'; source = [pscustomobject]@{ kind = 'revision'; revision = ('a' * 40) } }) -AliasCatalogPath $Catalog)
    [Console]::Out.WriteLine('no-error')
}
catch {
    [Console]::Out.WriteLine($_.Exception.Message)
}
'@
    $noGitStart = [System.Diagnostics.ProcessStartInfo]::new()
    $noGitStart.FileName = $childHost
    foreach ($argument in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $noGitProbe, '-Library', (Join-Path $scriptsRoot '_lib/DeliveryInputSources.ps1'), '-Catalog', $noGitCatalog, '-RepoRoot', $demoRoot)) {
        $noGitStart.ArgumentList.Add($argument)
    }
    $noGitStart.UseShellExecute = $false
    $noGitStart.RedirectStandardOutput = $true
    $noGitStart.RedirectStandardError = $true
    $noGitStart.CreateNoWindow = $true
    $noGitStart.Environment['PATH'] = $emptyPathDir
    $noGitProcess = [System.Diagnostics.Process]::Start($noGitStart)
    $noGitErrorTask = $noGitProcess.StandardError.ReadToEndAsync()
    $noGitOutput = $noGitProcess.StandardOutput.ReadToEnd()
    $noGitProcess.WaitForExit()
    [void]$noGitErrorTask.Result
    $noGitMessage = $noGitOutput.Trim()
    if ($noGitMessage.StartsWith('git_unavailable: ', [System.StringComparison]::Ordinal)) {
        $script:passed++
    }
    else {
        Write-Host ('SKIP: git_unavailable case; the PATH override did not make git unavailable: {0}' -f $noGitMessage)
    }

    $cliRepo = $demoRoot
    $cliOk = Invoke-Cli -CliArgs @('-RepoPath', $cliRepo, '-InputJson', $setFileInput, '-AliasCatalogPath', $catalogPath)
    Assert-Equal '0' ([string]$cliOk.ExitCode) 'Should_ExitZero_When_CliResolves'
    Assert-True ($cliOk.Result.ok -eq $true) 'Should_ReturnOk_When_CliResolves'
    Assert-Equal $alphaSha ([string]$cliOk.Result.identity) 'Should_ReturnIdentity_When_CliResolves'
    Assert-True (-not $cliOk.Stdout.Trim().Contains("`n")) 'Should_PrintSingleLine_When_CliResolves'

    $cliBlocked = Invoke-Cli -CliArgs @('-RepoPath', $cliRepo, '-InputJson', '{"path":"alias:demo/none.txt"}', '-AliasCatalogPath', $catalogPath)
    Assert-Equal '3' ([string]$cliBlocked.ExitCode) 'Should_ExitThree_When_CliBlocked'
    Assert-Equal 'source_missing' ([string]$cliBlocked.Result.reason) 'Should_ReturnReason_When_CliBlocked'
    Assert-True ($cliBlocked.Result.ok -eq $false) 'Should_ReturnNotOk_When_CliBlocked'

    $cliInvalidJson = Invoke-Cli -CliArgs @('-RepoPath', $cliRepo, '-InputJson', '{bad', '-AliasCatalogPath', $catalogPath)
    Assert-Equal '1' ([string]$cliInvalidJson.ExitCode) 'Should_ExitOne_When_CliJsonInvalid'

    $cliNeither = Invoke-Cli -CliArgs @('-RepoPath', $cliRepo)
    Assert-Equal '1' ([string]$cliNeither.ExitCode) 'Should_ExitOne_When_CliInputMissing'

    $cliMissingRepo = Invoke-Cli -CliArgs @('-RepoPath', (Join-Path $tempRoot 'no-such-repo'), '-InputJson', $setFileInput, '-AliasCatalogPath', $catalogPath)
    Assert-Equal '1' ([string]$cliMissingRepo.ExitCode) 'Should_ExitOne_When_CliRepoMissing'

    Write-TextFile -Path (Join-Path $demoRoot 'input.json') -Text $setFileInput
    $cliPathInput = Invoke-Cli -CliArgs @('-RepoPath', $cliRepo, '-InputPath', 'input.json', '-AliasCatalogPath', $catalogPath)
    Assert-Equal '0' ([string]$cliPathInput.ExitCode) 'Should_ExitZero_When_CliReadsRepositoryRelativeInputPath'
    Assert-Equal $alphaSha ([string]$cliPathInput.Result.identity) 'Should_ReturnIdentity_When_CliReadsInputPath'

    foreach ($output in @($cliOk, $cliBlocked, $cliInvalidJson)) {
        $combined = $output.Stdout + "`n" + $output.Stderr
        Assert-True (-not $combined.Contains($demoRoot)) 'Should_NotPrintAliasRoot_When_CliRuns'
        Assert-True (-not $combined.Contains($demoRoot.Replace('\', '/'))) 'Should_NotPrintAliasRootForwardSlash_When_CliRuns'
    }

    Write-Output ('PASS: {0} delivery input source assertions.' -f $passed)
}
finally {
    Remove-ReparsePaths
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
