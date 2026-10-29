#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\_lib\New-ToolkitWorkRoot.ps1')
$guard = Join-Path $PSScriptRoot 'Invoke-O3ReceiptValidation.ps1'
$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
$repo = Join-Path $work 'repo'
$external = Join-Path $work 'Demandas'
$outside = Join-Path $work 'outside'
$rootsPath = Join-Path $work 'authorized-roots.json'
$scopePath = Join-Path $work 'authorized-scope.json'
$plan = Join-Path $repo 'features\000-receipt\US01\PLAN\PLAN_000_receipt.md'
$scope = @('features/000-receipt/US01', 'external:Demandas')
$roots = @{ Demandas = $external }
$noBom = New-Object Text.UTF8Encoding $false
$exe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }

function New-Receipt([string[]] $Files) {
    return [ordered]@{
        planPath = 'features/000-receipt/US01/PLAN/PLAN_000_receipt.md'
        step = 1; status = 'done'; files = $Files; testsSummary = 'Focused receipt validation PASS'
    }
}
function Invoke-ReceiptGuard($Receipt) {
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $Receipt -Depth 8 -Compress)))
    [IO.File]::WriteAllText($rootsPath, (ConvertTo-Json -InputObject $roots -Compress), $noBom)
    [IO.File]::WriteAllText($scopePath, (ConvertTo-Json -InputObject $scope -Compress), $noBom)
    $out = @(& $exe -NoProfile -File $guard -ReceiptJsonBase64 $b64 -RepoRoot $repo -PlanPath $plan -Step 1 -AllowedPathPrefixesPath $scopePath -AuthorizedRootsPath $rootsPath 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($out -join ' ') }
}
function Assert-Accepted($Receipt, [string] $Case) {
    $r = Invoke-ReceiptGuard $Receipt
    if ($r.ExitCode -ne 0 -or $r.Output -notmatch 'receipt_validation: PASS') { throw "$Case should pass; exit $($r.ExitCode): $($r.Output)" }
    Write-Host "O3ReceiptValidation ${Case}: PASS (accepted)"
}
function Assert-Rejected($Receipt, [string] $Case) {
    $r = Invoke-ReceiptGuard $Receipt
    if ($r.ExitCode -ne 2 -or $r.Output -notmatch 'receipt_invalid') { throw "$Case should fail closed; exit $($r.ExitCode): $($r.Output)" }
    Write-Host "O3ReceiptValidation ${Case}: PASS (rejected)"
}

try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $plan), $external, $outside -Force | Out-Null
    [IO.File]::WriteAllText($plan, '# plan')
    [IO.File]::WriteAllText((Join-Path $repo 'features\000-receipt\US01\changed.cs'), 'internal')
    [IO.File]::WriteAllText((Join-Path $external 'input.json'), '{}')
    [IO.File]::WriteAllText((Join-Path $outside 'secret.txt'), 'outside')

    Assert-Accepted (New-Receipt @('features\000-receipt\US01\changed.cs', 'external:Demandas/input.json')) 'ValidInternalAndExternalAlias'
    Assert-Rejected (New-Receipt @('external:Demandas/../outside/secret.txt')) 'Traversal'
    Assert-Rejected (New-Receipt @('C:/temp/secret.txt')) 'DriveAbsolute'
    $secret = New-Receipt @('external:Demandas/input.json')
    $secret.testsSummary = 'PASS with password=example-secret'
    Assert-Rejected $secret 'SecretInSummary'

    try {
        New-Item -ItemType Junction -Path (Join-Path $external 'escape') -Target $outside | Out-Null
        Assert-Rejected (New-Receipt @('external:Demandas/escape/secret.txt')) 'ReparseEscape'
    } catch [System.Management.Automation.RuntimeException] {
        if ($_.Exception.Message -like '*should fail closed*') { throw }
        Write-Host ("O3ReceiptValidation ReparseEscape: SKIPPED ({0})" -f $_.Exception.Message)
    }
}
finally {
    $esc = Join-Path $external 'escape'
    if (Test-Path -LiteralPath $esc) { (Get-Item -LiteralPath $esc -Force).Delete() }
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}
exit 0
