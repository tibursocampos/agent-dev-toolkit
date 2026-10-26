#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$broker = Join-Path $repoRoot 'scripts\validation\fixtures\Invoke-ClassicExternalAccessFixture.ps1'
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('adt-classic-external-' + [guid]::NewGuid().ToString('N'))
$externalRoot = Join-Path $fixtureRoot 'Demandas'
$allowedDirectory = Join-Path $externalRoot 'specs'
$outsideRoot = Join-Path $fixtureRoot 'outside'
$seedPath = Join-Path $allowedDirectory 'source.txt'
$writtenPath = Join-Path $allowedDirectory 'written.txt'

function Assert-True([bool] $Value, [string] $Message) {
    if (-not $Value) { throw $Message }
}

function Resolve-PowerShellExecutable {
    param(
        [Parameter(Mandatory = $true)][string] $Edition,
        [Parameter(Mandatory = $true)][string] $PowerShellHome,
        [bool] $PlatformIsWindows = ($env:OS -eq 'Windows_NT')
    )

    if ($Edition -eq 'Desktop') {
        if (-not $PlatformIsWindows) { throw 'Windows PowerShell Desktop is supported only on Windows.' }
        $executableName = 'powershell.exe'
    } elseif ($Edition -eq 'Core') {
        $executableName = if ($PlatformIsWindows) { 'pwsh.exe' } else { 'pwsh' }
    } else {
        throw "Unsupported PowerShell edition: $Edition"
    }
    return Join-Path $PowerShellHome $executableName
}

$selectorHome = [IO.Path]::GetTempPath()
$windowsCoreExecutable = Resolve-PowerShellExecutable -Edition 'Core' -PowerShellHome $selectorHome -PlatformIsWindows $true
$posixCoreExecutable = Resolve-PowerShellExecutable -Edition 'Core' -PowerShellHome $selectorHome -PlatformIsWindows $false
$windowsDesktopExecutable = Resolve-PowerShellExecutable -Edition 'Desktop' -PowerShellHome $selectorHome -PlatformIsWindows $true
Assert-True ([IO.Path]::GetFileName($windowsCoreExecutable) -eq 'pwsh.exe') 'PowerShell Core on Windows must select pwsh.exe.'
Assert-True ([IO.Path]::GetFileName($posixCoreExecutable) -eq 'pwsh') 'PowerShell Core on Linux/macOS must select pwsh without an .exe suffix.'
Assert-True ([IO.Path]::GetFileName($windowsDesktopExecutable) -eq 'powershell.exe') 'Windows PowerShell 5.1 must select powershell.exe.'
$script:platformIsWindows = $env:OS -eq 'Windows_NT'
$script:currentPowerShellExe = Resolve-PowerShellExecutable -Edition ([string]$PSVersionTable.PSEdition) -PowerShellHome $PSHOME -PlatformIsWindows $script:platformIsWindows
Assert-True (Test-Path -LiteralPath $currentPowerShellExe -PathType Leaf) "Current PowerShell executable was not found: $currentPowerShellExe"
Write-Host 'ClassicExternalAccess PowerShellExecutableSelection: PASS (Windows Core, Windows Desktop, and POSIX Core names)'

function Invoke-Broker {
    param(
        [string] $PortablePath,
        [string] $Operation,
        [object] $Context = $script:context,
        [object] $Scope = $script:scope,
        [string] $WriteContent = $null,
        [switch] $WhatIf
    )
    $contextJson = ConvertTo-Json -InputObject $Context -Depth 8 -Compress
    $scopeJson = ConvertTo-Json -InputObject $Scope -Depth 8 -Compress
    $contextBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($contextJson))
    $scopeBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($scopeJson))
    $powerShellExe = $script:currentPowerShellExe
    $arguments = @('-NoProfile','-File',$script:broker,'-PortablePath',$PortablePath,'-Operation',$Operation,'-AuthorizationContextBase64',$contextBase64,'-ApprovedScopeBase64',$scopeBase64)
    if ($PSBoundParameters.ContainsKey('WriteContent')) { $arguments += @('-Content',$WriteContent) }
    if ($WhatIf) { $arguments += '-WhatIf' }
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $powerShellExe @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = ($output -join "`n") }
}

function Assert-Denied {
    param([string] $Name, [string] $PortablePath, [string] $Operation, [object] $Context = $script:context, [object] $Scope = $script:scope)
    $result = Invoke-Broker -PortablePath $PortablePath -Operation $Operation -Context $Context -Scope $Scope
    Assert-True ($result.ExitCode -eq 2 -and $result.Output -match 'classic_external_access_denied') "$Name should be denied; got exit $($result.ExitCode): $($result.Output)"
    Write-Host ("ClassicExternalAccess {0}: PASS (denied before I/O)" -f $Name)
}

try {
    if (-not (Test-Path -LiteralPath $broker -PathType Leaf)) { throw "Missing validation-only fixture: $broker" }
    New-Item -ItemType Directory -Path $allowedDirectory,$outsideRoot -Force | Out-Null
    [IO.File]::WriteAllText($seedPath, 'fixture-read-content', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $outsideRoot 'secret.txt'), 'outside-fixture', [Text.UTF8Encoding]::new($false))

    $script:context = [ordered]@{
        schemaVersion = 1
        aliases = [ordered]@{
            Demandas = [ordered]@{ root = $externalRoot; operations = @('read','write') }
        }
    }
    $script:scope = [ordered]@{ reference = 'external:Demandas/specs'; operations = @('read','write') }

    $read = Invoke-Broker -PortablePath 'external:Demandas/specs/source.txt' -Operation 'read'
    Assert-True ($read.ExitCode -eq 0) "Authorized read should pass: $($read.Output)"
    $readResult = $read.Output | ConvertFrom-Json
    Assert-True ($readResult.decision -eq 'allow' -and $readResult.operation -eq 'read' -and $readResult.content -eq 'fixture-read-content') 'Authorized read must return the fixture content.'
    Assert-True ($readResult.path -eq 'external:Demandas/specs/source.txt') 'Read result must preserve the portable alias path.'
    Assert-True ($read.Output -notmatch [regex]::Escape($externalRoot)) 'Read representation must not expose the physical root.'
    Write-Host 'ClassicExternalAccess AuthorizedReadAndPortableRepresentation: PASS'

    $write = Invoke-Broker -PortablePath 'external:Demandas/specs/written.txt' -Operation 'write' -WriteContent 'fixture-write-content'
    Assert-True ($write.ExitCode -eq 0) "Authorized write should pass: $($write.Output)"
    Assert-True ((Get-Content -LiteralPath $writtenPath -Raw) -eq 'fixture-write-content') 'Authorized write must create the expected file under the external fixture root.'
    $writeResult = $write.Output | ConvertFrom-Json
    Assert-True ($writeResult.path -eq 'external:Demandas/specs/written.txt' -and $write.Output -notmatch [regex]::Escape($externalRoot)) 'Write result must retain only the portable reference.'
    Write-Host 'ClassicExternalAccess AuthorizedWrite: PASS'

    $whatIfPath = Join-Path $allowedDirectory 'whatif.txt'
    $whatIf = Invoke-Broker -PortablePath 'external:Demandas/specs/whatif.txt' -Operation 'write' -WriteContent 'must-not-be-written' -WhatIf
    Assert-True ($whatIf.ExitCode -eq 3) "WhatIf must not return success: $($whatIf.Output)"
    $whatIfJson = @($whatIf.Output -split "`r?`n" | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)
    Assert-True ($whatIfJson.Count -eq 1) "WhatIf must emit a not-performed result: $($whatIf.Output)"
    $whatIfResult = $whatIfJson[0] | ConvertFrom-Json
    Assert-True ($whatIfResult.decision -eq 'not_performed' -and -not (Test-Path -LiteralPath $whatIfPath)) 'WhatIf must identify the write as not performed and leave no target file.'
    Write-Host 'ClassicExternalAccess WhatIfNotPerformed: PASS'

    $readOnlyContext = [ordered]@{ schemaVersion = 1; aliases = [ordered]@{ Demandas = [ordered]@{ root = $externalRoot; operations = @('read') } } }
    $readOnlyScope = [ordered]@{ reference = 'external:Demandas/specs'; operations = @('read') }
    Assert-Denied 'WriteNotGrantedByTrustedMap' 'external:Demandas/specs/denied.txt' 'write' $readOnlyContext $script:scope
    Assert-Denied 'WriteNotApprovedByStep' 'external:Demandas/specs/denied.txt' 'write' $script:context $readOnlyScope
    Assert-Denied 'UnknownAlias' 'external:Unknown/specs/source.txt' 'read' $script:context ([ordered]@{ reference = 'external:Unknown/specs'; operations = @('read') })
    Assert-Denied 'Traversal' 'external:Demandas/specs/../outside/secret.txt' 'read'
    Assert-Denied 'AbsolutePath' 'C:/temp/outside.txt' 'read'
    Assert-Denied 'OutsideApprovedScope' 'external:Demandas/elsewhere/source.txt' 'read'
    Assert-Denied 'MissingReadTarget' 'external:Demandas/specs/missing.txt' 'read'
    Assert-Denied 'EncodedTraversal' 'external:Demandas/specs/%2e%2e/secret.txt' 'read'
    Assert-Denied 'QueryString' 'external:Demandas/specs/source.txt?version=1' 'read'
    Assert-Denied 'DuplicateSeparator' 'external:Demandas//specs/source.txt' 'read'
    Assert-Denied 'MissingWriteContent' 'external:Demandas/specs/no-content.txt' 'write'

    $junctionPath = Join-Path $allowedDirectory 'escape'
    try {
        $reparseType = if ($script:platformIsWindows) { 'Junction' } else { 'SymbolicLink' }
        New-Item -ItemType $reparseType -Path $junctionPath -Target $outsideRoot -ErrorAction Stop | Out-Null
        Assert-Denied 'IntermediateReparseEscape' 'external:Demandas/specs/escape/secret.txt' 'read'
        New-Item -ItemType $reparseType -Path (Join-Path $allowedDirectory 'final-escape') -Target $outsideRoot -ErrorAction Stop | Out-Null
        Assert-Denied 'FinalReparseEscape' 'external:Demandas/specs/final-escape' 'read'
    } catch {
        if ($_.Exception.Message -match 'should be denied') { throw }
        throw "Required reparse-point fixture could not be created: $($_.Exception.Message)"
    }

    $contractPath = Join-Path $repoRoot 'core\skills\_shared\sdd-artifacts\CLASSIC-EXTERNAL-ACCESS.md'
    $acquisitionPath = Join-Path $repoRoot 'core\skills\sdd-develop\references\plan-acquisition.md'
    $manifestPath = Join-Path $repoRoot 'scripts\runtime\runtime-manifest.json'
    $contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
    $acquisitionText = Get-Content -LiteralPath $acquisitionPath -Raw -Encoding UTF8
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($contractText -match 'validation-only' -and $contractText -match 'n\u00e3o comprova enforcement do provider') 'Shared contract must identify the broker as validation-only evidence, not provider enforcement.'
    Assert-True ($acquisitionText -match 'block before external access' -and $acquisitionText -match 'validation-only fixture') 'sdd-develop must fail closed and must not route production operations through the fixture.'
    Assert-True (@($manifest.files | Where-Object { $_.source -match 'ClassicExternalAccess' -or $_.destination -match 'ClassicExternalAccess' }).Count -eq 0) 'Runtime manifest must not publish a caller-supplied authorization fixture.'
    Write-Host 'ClassicExternalAccess BrokerIntegration: PASS (validation-only fixture, fail-closed guidance, not published)'

    Write-Host 'ClassicExternalAccessRuntime: PASS (authorized external I/O, portable representation, fail-closed denials)'
    exit 0
} catch {
    Write-Host ('ClassicExternalAccessRuntime: FAIL - {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
