#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$broker = Join-Path $repoRoot 'scripts\validation\fixtures\Invoke-ClassicExternalAccessFixture.ps1'
. (Join-Path $repoRoot 'scripts\_lib\New-ToolkitWorkRoot.ps1')
$fixtureRoot = New-ToolkitWorkRoot -RepoRoot $repoRoot
$externalRoot = Join-Path $fixtureRoot 'Demandas'
$allowedDirectory = Join-Path $externalRoot 'specs'
$outsideRoot = Join-Path $fixtureRoot 'outside'
$seedPath = Join-Path $allowedDirectory 'source.txt'
$writtenPath = Join-Path $allowedDirectory 'written.txt'

function Assert-True([bool] $Value, [string] $Message) {
    if (-not $Value) { throw $Message }
}

$script:platformIsWindows = $env:OS -eq 'Windows_NT'
$script:currentPowerShellExe = if ($script:platformIsWindows -and $PSVersionTable.PSEdition -ne 'Core') { Join-Path $PSHOME 'powershell.exe' } elseif ($script:platformIsWindows) { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'pwsh' }

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

    $readOnlyContext = [ordered]@{ schemaVersion = 1; aliases = [ordered]@{ Demandas = [ordered]@{ root = $externalRoot; operations = @('read') } } }
    $readOnlyScope = [ordered]@{ reference = 'external:Demandas/specs'; operations = @('read') }
    Assert-Denied 'WriteNotGrantedByTrustedMap' 'external:Demandas/specs/denied.txt' 'write' $readOnlyContext $script:scope
    Assert-Denied 'WriteNotApprovedByStep' 'external:Demandas/specs/denied.txt' 'write' $script:context $readOnlyScope
    Assert-Denied 'UnknownAlias' 'external:Unknown/specs/source.txt' 'read' $script:context ([ordered]@{ reference = 'external:Unknown/specs'; operations = @('read') })
    Assert-Denied 'Traversal' 'external:Demandas/specs/../outside/secret.txt' 'read'
    Assert-Denied 'AbsolutePath' 'C:/temp/outside.txt' 'read'

    $junctionPath = Join-Path $allowedDirectory 'escape'
    try {
        $reparseType = if ($script:platformIsWindows) { 'Junction' } else { 'SymbolicLink' }
        New-Item -ItemType $reparseType -Path $junctionPath -Target $outsideRoot -ErrorAction Stop | Out-Null
        Assert-Denied 'IntermediateReparseEscape' 'external:Demandas/specs/escape/secret.txt' 'read'
    } catch {
        if ($_.Exception.Message -match 'should be denied') { throw }
        throw "Required reparse-point fixture could not be created: $($_.Exception.Message)"
    }

    $manifest = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\runtime\runtime-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
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
