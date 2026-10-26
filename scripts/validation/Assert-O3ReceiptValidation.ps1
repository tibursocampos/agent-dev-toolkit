#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$guard = Join-Path $PSScriptRoot 'Invoke-O3ReceiptValidation.ps1'
$fixture = Join-Path $PSScriptRoot ('fixtures\o3-receipt-validation-' + [guid]::NewGuid().ToString('N'))
$repo = Join-Path $fixture 'repo'
$external = Join-Path $fixture 'Demandas'
$outside = Join-Path $fixture 'outside'
$rootsPath = Join-Path $fixture 'authorized-roots.json'
$scopePath = Join-Path $fixture 'authorized-scope.json'
$plan = Join-Path $repo 'features\000-receipt\US01\PLAN\PLAN_000_receipt.md'
$scope = @('features/000-receipt/US01', 'external:Demandas')
$roots = @{ Demandas = $external }

function Assert-True([bool] $Value, [string] $Message) { if (-not $Value) { throw $Message } }
function ConvertTo-ContractConceptText([string] $Text) {
    $normalized = $Text.ToLowerInvariant() -replace '[^\p{L}\p{N}]+', ' '
    return (($normalized -split '\s+' | Where-Object { $_ }) -join ' ')
}
function Assert-DocumentConcepts([string] $Text, [string] $Name, [string[]] $RequiredConcepts) {
    $tokens = @((ConvertTo-ContractConceptText $Text) -split ' ' | Where-Object { $_ })
    foreach ($concept in $RequiredConcepts) {
        $requiredTokens = @((ConvertTo-ContractConceptText $concept) -split ' ' | Where-Object { $_ })
        foreach ($token in $requiredTokens) {
            if ($tokens -notcontains $token) {
                throw "$Name is missing required concept '$concept' (token '$token')."
            }
        }
    }
}
function New-Receipt([string[]] $Files) {
    return [ordered]@{
        planPath = 'features/000-receipt/US01/PLAN/PLAN_000_receipt.md'
        step = 1
        status = 'done'
        files = $Files
        testsSummary = 'Focused receipt validation PASS'
    }
}
function Invoke-ReceiptGuard($Receipt, [string[]] $Allowed = $scope, [hashtable] $ExternalRoots = $roots) {
    $json = ConvertTo-Json -InputObject $Receipt -Depth 8 -Compress
    $jsonBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
    [IO.File]::WriteAllText($rootsPath, (ConvertTo-Json -InputObject $ExternalRoots -Compress), (New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($scopePath, (ConvertTo-Json -InputObject $Allowed -Compress), (New-Object Text.UTF8Encoding $false))
    $powerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
    $output = @(& $powerShellExe -NoProfile -File $guard -ReceiptJsonBase64 $jsonBase64 -RepoRoot $repo -PlanPath $plan -Step 1 -AllowedPathPrefixesPath $scopePath -AuthorizedRootsPath $rootsPath 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join ' ') }
}
function Invoke-ContainmentPredicate([string] $Root, [string] $Target) {
    $powerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
    $output = @(& $powerShellExe -NoProfile -File $guard -RepoRoot $repo -PlanPath $plan -Step 1 -AllowedPathPrefixesPath $scopePath -AuthorizedRootsPath $rootsPath -TestCaseSensitiveScope -TestContainmentOnly -TestContainmentRoot $Root -TestContainmentTarget $Target 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join ' ') }
}
function Invoke-FinalPathProbe([string] $Path) {
    [IO.File]::WriteAllText($rootsPath, (ConvertTo-Json -InputObject $roots -Compress), (New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($scopePath, (ConvertTo-Json -InputObject $scope -Compress), (New-Object Text.UTF8Encoding $false))
    $powerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
    $output = @(& $powerShellExe -NoProfile -File $guard -RepoRoot $repo -PlanPath $plan -Step 1 -AllowedPathPrefixesPath $scopePath -AuthorizedRootsPath $rootsPath -TestFinalPathOnly -TestPath $Path 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join ' ') }
}
function Get-CanonicalReceipt($Result) {
    $match = [regex]::Match([string]$Result.Output, '(?:^|\s)canonical_receipt:\s*(\{.*\})')
    if (-not $match.Success) { throw "Guard did not return a canonical receipt projection: $($Result.Output)" }
    return $match.Groups[1].Value | ConvertFrom-Json -ErrorAction Stop
}
function Assert-Rejected($Receipt, [string] $Case, [string[]] $Allowed = $scope, [hashtable] $ExternalRoots = $roots, [switch] $ForceCaseSensitiveScope) {
    $json = ConvertTo-Json -InputObject $Receipt -Depth 8 -Compress
    $jsonBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
    [IO.File]::WriteAllText($rootsPath, (ConvertTo-Json -InputObject $ExternalRoots -Compress), (New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllText($scopePath, (ConvertTo-Json -InputObject $Allowed -Compress), (New-Object Text.UTF8Encoding $false))
    $powerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
    $guardArguments = @('-NoProfile','-File',$guard,'-ReceiptJsonBase64',$jsonBase64,'-RepoRoot',$repo,'-PlanPath',$plan,'-Step','1','-AllowedPathPrefixesPath',$scopePath,'-AuthorizedRootsPath',$rootsPath)
    if ($ForceCaseSensitiveScope) { $guardArguments += '-TestCaseSensitiveScope' }
    $output = @(& $powerShellExe @guardArguments 2>&1)
    $result = [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join ' ') }
    Assert-True ($result.ExitCode -eq 2 -and $result.Output -match 'receipt_invalid') "$Case should fail closed; got exit $($result.ExitCode): $($result.Output)"
    Write-Host ("O3ReceiptValidation {0}: PASS (rejected)" -f $Case)
}

try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $plan),$external,$outside -Force | Out-Null
    [IO.File]::WriteAllText($plan, '# plan')
    [IO.File]::WriteAllText((Join-Path $repo 'features\000-receipt\US01\changed.cs'), 'internal')
    [IO.File]::WriteAllText((Join-Path $external 'input.json'), '{}')
    [IO.File]::WriteAllText((Join-Path $outside 'secret.txt'), 'outside')

    $valid = Invoke-ReceiptGuard (New-Receipt @('features\000-receipt\US01\changed.cs','external:Demandas/input.json'))
    Assert-True ($valid.ExitCode -eq 0 -and $valid.Output -match 'receipt_validation: PASS') "Valid internal and authorized external paths should pass: $($valid.Output)"
    Assert-True ((Get-CanonicalReceipt $valid).status -ceq 'done') 'Canonical receipt projection must retain done.'
    Write-Host 'O3ReceiptValidation ValidInternalAndAuthorizedAlias: PASS'

    $expectedPathRoot = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($fixture))
    $finalPathProbe = Invoke-FinalPathProbe $expectedPathRoot
    $finalPathMatch = [regex]::Match([string]$finalPathProbe.Output, '(?:^|\s)final_path:\s*(.+)$')
    $pathComparison = if ($env:OS -eq 'Windows_NT') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    Assert-True ($finalPathProbe.ExitCode -eq 0 -and $finalPathMatch.Success) "Root path normalization probe must succeed: $($finalPathProbe.Output)"
    $normalizedPathRoot = $finalPathMatch.Groups[1].Value.Trim()
    Assert-True ($normalizedPathRoot.Equals($expectedPathRoot, $pathComparison) -and [IO.Path]::GetPathRoot($normalizedPathRoot).Equals($normalizedPathRoot, $pathComparison)) "Final path normalization must preserve the rooted separator ('$expectedPathRoot'); got '$normalizedPathRoot'."
    Write-Host 'O3ReceiptValidation DriveRootRemainsRooted: PASS'

    foreach ($statusAlias in @('completed','Completed',' complete ')) {
        $aliasedDone = New-Receipt @('external:Demandas/input.json')
        $aliasedDone.status = $statusAlias
        $aliasedResult = Invoke-ReceiptGuard $aliasedDone
        Assert-True ($aliasedResult.ExitCode -eq 0) "Status alias '$statusAlias' should be accepted as done: $($aliasedResult.Output)"
        Assert-True ((Get-CanonicalReceipt $aliasedResult).status -ceq 'done') "Status alias '$statusAlias' must normalize to canonical done."
    }
    Write-Host 'O3ReceiptValidation CompletedStatusAliasesNormalizeToDone: PASS'
    $doneAliasWithReason = New-Receipt @('external:Demandas/input.json')
    $doneAliasWithReason.status = 'completed'
    $doneAliasWithReason.blockedReason = 'Stale blocker'
    Assert-Rejected $doneAliasWithReason 'CompletedAliasStillUsesDoneInvariants'

    $validBlocked = New-Receipt @('external:Demandas/input.json')
    $validBlocked.status = 'blocked'
    $validBlocked.testsSummary = 'Focused checks BLOCKED'
    $validBlocked.blockedReason = 'Required input is missing'
    $blockedResult = Invoke-ReceiptGuard $validBlocked
    Assert-True ($blockedResult.ExitCode -eq 0 -and (Get-CanonicalReceipt $blockedResult).status -ceq 'blocked') 'Blocked status and reason must remain unchanged.'

    $validFailed = New-Receipt @('external:Demandas/input.json')
    $validFailed.status = 'failed'
    $validFailed.testsSummary = 'Focused checks FAIL'
    $validFailed.blockedReason = 'The focused validation failed'
    $failedResult = Invoke-ReceiptGuard $validFailed
    Assert-True ($failedResult.ExitCode -eq 0 -and (Get-CanonicalReceipt $failedResult).status -ceq 'failed') 'Failed status and reason must remain unchanged.'
    Write-Host 'O3ReceiptValidation BlockedAndFailedRemainCanonical: PASS'

    Assert-Rejected (New-Receipt @('external:Unknown/input.json')) 'UnknownAlias' @('external:Unknown')
    Assert-Rejected (New-Receipt @('external:Demandas/../outside/secret.txt')) 'Traversal'
    Assert-Rejected (New-Receipt @('C:/temp/secret.txt')) 'DriveAbsolute'
    Assert-Rejected (New-Receipt @('//server/share/secret.txt')) 'UNCAbsolute'
    Assert-Rejected (New-Receipt @('external:Demandas/missing.json')) 'MissingFile'
    Assert-Rejected (New-Receipt @('external:Demandas/input.json','external:Demandas/input.json')) 'Duplicate'
    Assert-Rejected (New-Receipt @('external:Demandas/%2e%2e/input.json')) 'EncodedTraversal'
    Assert-Rejected (New-Receipt @('external:Demandas/input.json?version=1')) 'QueryString'
    Assert-Rejected (New-Receipt @('external:Demandas/input.json#fragment')) 'Fragment'
    Assert-Rejected (New-Receipt @('external:Demandas\input.json/more')) 'MixedSeparators'
    Assert-Rejected (New-Receipt @('features/000-receipt/US01/changed.cs','features\000-receipt\US01\changed.cs')) 'DuplicateAfterSeparatorNormalization'

    Assert-Rejected (New-Receipt @('Features/000-receipt/US01/changed.cs')) 'CaseSensitiveScopeComparisonUnit' @('features/000-receipt/US01') $roots -ForceCaseSensitiveScope
    Write-Host 'O3ReceiptValidation CaseSensitiveScopeComparisonUnit: PASS'

    $caseSensitiveAuthorizedRoot = Join-Path $fixture 'Demandas'
    $resolvedCaseVariantSibling = Join-Path $fixture 'DEMANDAS\escape\secret.txt'
    $containmentEscape = Invoke-ContainmentPredicate $caseSensitiveAuthorizedRoot $resolvedCaseVariantSibling
    Assert-True ($containmentEscape.ExitCode -eq 3 -and $containmentEscape.Output -match 'containment: outside') 'A case-mismatched sibling resolved from a reparse point must remain outside an authorized root.'
    $containmentInside = Invoke-ContainmentPredicate $caseSensitiveAuthorizedRoot (Join-Path $caseSensitiveAuthorizedRoot 'input.json')
    Assert-True ($containmentInside.ExitCode -eq 0 -and $containmentInside.Output -match 'containment: within') 'An exact-case target below an authorized root must remain within scope.'
    Write-Host 'O3ReceiptValidation CaseSensitiveResolvedContainmentUnit: PASS'

    if ($env:OS -eq 'Windows_NT' -and -not ('O3ReceiptCaseSensitiveDirectoryController' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
public static class O3ReceiptCaseSensitiveDirectoryController {
    [StructLayout(LayoutKind.Sequential)] private struct FileCaseSensitiveInfo { public uint Flags; }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] private static extern IntPtr CreateFileW(string name, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool SetFileInformationByHandle(IntPtr handle, int informationClass, ref FileCaseSensitiveInfo information, uint size);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern bool CloseHandle(IntPtr handle);
    public static void Enable(string path) {
        IntPtr handle = CreateFileW(path, 0x100, 7, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero);
        if (handle == new IntPtr(-1)) throw new Win32Exception(Marshal.GetLastWin32Error());
        try {
            FileCaseSensitiveInfo information = new FileCaseSensitiveInfo();
            information.Flags = 1;
            if (!SetFileInformationByHandle(handle, 23, ref information, (uint)Marshal.SizeOf(typeof(FileCaseSensitiveInfo))))
                throw new Win32Exception(Marshal.GetLastWin32Error());
        } finally { CloseHandle(handle); }
    }
}
'@
    }
    $caseSensitiveDirectory = Join-Path $repo 'CaseSensitiveScopeRoot'
    New-Item -ItemType Directory -Path $caseSensitiveDirectory -Force | Out-Null
    $caseSensitiveDirectoryEnabled = $false
    if ($env:OS -eq 'Windows_NT') {
        try {
            [O3ReceiptCaseSensitiveDirectoryController]::Enable($caseSensitiveDirectory)
            $caseSensitiveDirectoryEnabled = $true
        } catch {
            Write-Host ("O3ReceiptValidation WindowsPerDirectoryCaseSensitivity: SKIPPED (filesystem/OS did not permit enabling the directory flag: {0})" -f $_.Exception.GetType().Name)
        }
    }
    if ($caseSensitiveDirectoryEnabled) {
        $lowerCaseTarget = Join-Path $caseSensitiveDirectory 'features\000-receipt\US01\changed.cs'
        $upperCaseTarget = Join-Path $caseSensitiveDirectory 'Features\000-receipt\US01\changed.cs'
        New-Item -ItemType Directory -Path (Split-Path -Parent $lowerCaseTarget),(Split-Path -Parent $upperCaseTarget) -Force | Out-Null
        [IO.File]::WriteAllText($lowerCaseTarget, 'lower-case target')
        [IO.File]::WriteAllText($upperCaseTarget, 'upper-case target')
        $receipt = New-Receipt @('CaseSensitiveScopeRoot/Features/000-receipt/US01/changed.cs')
        $result = Invoke-ReceiptGuard $receipt @('CaseSensitiveScopeRoot/features/000-receipt/US01') $roots
        Assert-True ($result.ExitCode -eq 2 -and $result.Output -match 'outside coordinator scope') 'A path whose case differs under a case-sensitive Windows directory must fail coordinator scope.'
        Write-Host 'O3ReceiptValidation WindowsPerDirectoryCaseSensitivity: PASS (rejected out-of-scope casing)'
    }

    $caseProbe = Join-Path $fixture 'CaseSensitivityProbe'
    [IO.File]::WriteAllText($caseProbe, 'case-sensitive-filesystem-probe')
    $caseSensitiveFilesystem = -not (Test-Path -LiteralPath (Join-Path $fixture 'casesensitivityprobe'))
    if ($caseSensitiveFilesystem) {
        $caseVariantPath = Join-Path $repo 'Features\000-receipt\US01\case-variant.cs'
        New-Item -ItemType Directory -Path (Split-Path -Parent $caseVariantPath) -Force | Out-Null
        [IO.File]::WriteAllText($caseVariantPath, 'case-sensitive path')
        Assert-Rejected (New-Receipt @('Features/000-receipt/US01/case-variant.cs')) 'CaseSensitiveScopePrefix' @('features/000-receipt/US01')
    } else {
        Write-Host 'O3ReceiptValidation CaseSensitiveScopePrefix: SKIPPED (filesystem is case-insensitive)'
    }

    $secretSummary = New-Receipt @('external:Demandas/input.json')
    $secretSummary.testsSummary = 'PASS with password=example-secret'
    Assert-Rejected $secretSummary 'SecretRedaction'
    $posixSummary = New-Receipt @('external:Demandas/input.json')
    $posixSummary.testsSummary = 'PASS; evidence at /home/agent/run/result.txt'
    Assert-Rejected $posixSummary 'PosixAbsolutePathInTestsSummary'
    $posixBlockedReason = New-Receipt @('external:Demandas/input.json')
    $posixBlockedReason.status = 'blocked'
    $posixBlockedReason.blockedReason = 'Missing artifact under /tmp/agent/session'
    Assert-Rejected $posixBlockedReason 'PosixAbsolutePathInBlockedReason'
    Assert-Rejected (New-Receipt @('/tmp/agent/result.txt')) 'PosixAbsolutePathInFiles'
    $piiSummary = New-Receipt @('external:Demandas/input.json')
    $piiSummary.testsSummary = 'PASS for person@example.com'
    Assert-Rejected $piiSummary 'PiiRedaction'
    Assert-Rejected (New-Receipt @('external:Demandas/password=example-secret.json')) 'FilePathSecretRedaction'
    Assert-Rejected (New-Receipt @('external:Demandas/person@example.com/input.json')) 'FilePathPiiRedaction'
    Assert-Rejected (New-Receipt @('external:Demandas/logs/agent.txt')) 'LogDirectoryRedaction'
    Assert-Rejected (New-Receipt @('external:Demandas/session.transcript')) 'TranscriptFileRedaction'
    Assert-Rejected (New-Receipt @('external:Demandas/input.json')) 'RelativeAuthorizedRoot' $scope @{ Demandas = 'relative/Demandas' }
    Assert-Rejected (New-Receipt @('external:Demandas/input.json')) 'DriveRelativeAuthorizedRoot' $scope @{ Demandas = 'C:relative/Demandas' }
    $unknownStatus = New-Receipt @('external:Demandas/input.json')
    $unknownStatus.status = 'completed_with_warnings'
    Assert-Rejected $unknownStatus 'UnknownStatus'

    try {
        New-Item -ItemType Junction -Path (Join-Path $external 'escape') -Target $outside | Out-Null
    } catch {
        throw "Cannot establish the reparse-point escape fixture required by this Windows runtime test: $($_.Exception.Message)"
    }
    Assert-Rejected (New-Receipt @('external:Demandas/escape/secret.txt')) 'IntermediateReparseEscape'

    $receiptContract = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\_shared\agents\RECEIPT.md') -Raw -Encoding UTF8
    $spawnContract = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\_shared\agents\SPAWN.md') -Raw -Encoding UTF8
    $o3Skill = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\orchestrate-develop\SKILL.md') -Raw -Encoding UTF8
    $storageContract = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\_shared\sdd-artifacts\STORAGE.md') -Raw -Encoding UTF8
    $o1Contract = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\orchestrate-analyze\SKILL.md') -Raw -Encoding UTF8
    $o1Synthesis = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\orchestrate-analyze\references\story-synthesis.md') -Raw -Encoding UTF8
    $o2Contract = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\orchestrate-deliver\SKILL.md') -Raw -Encoding UTF8
    $o2PerStory = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\orchestrate-deliver\references\per-story-contracts.md') -Raw -Encoding UTF8
    $o2Handoff = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\orchestrate-deliver\references\continuity-handoff.md') -Raw -Encoding UTF8
    $featureTemplate = Get-Content -LiteralPath (Join-Path $repoRoot 'core\skills\_shared\templates\features\FEATURE.md') -Raw -Encoding UTF8
    $manifest = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\runtime\runtime-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-DocumentConcepts $receiptContract 'Receipt contract path policy' @('external alias relative path', 'no absolute root')
    Assert-DocumentConcepts $receiptContract 'Receipt contract status policy' @('producer exactly done blocked failed', 'complete completed compatibility aliases')
    Assert-True ($spawnContract -match 'Invoke-O3ReceiptValidation\.ps1') 'Spawn guidance must require the runtime guard.'
    Assert-True ($o3Skill -match 'Invoke-O3ReceiptValidation\.ps1') 'O3 flow must invoke the runtime guard before reconciliation.'
    Assert-DocumentConcepts $o3Skill 'O3 producer guidance' @('status done', 'canonical receipt')
    Assert-True (@($manifest.files | Where-Object { $_.source -eq 'scripts/validation/Invoke-O3ReceiptValidation.ps1' }).Count -eq 1) 'Runtime manifest must publish the O3 receipt guard.'
    Assert-DocumentConcepts $storageContract 'Shared path contract' @('external alias relative path', 'O1 records portable reference', 'O1 O2 do not authorize aliases')
    foreach ($document in @(
        [pscustomobject]@{ Name = 'O1 guidance'; Text = $o1Contract },
        [pscustomobject]@{ Name = 'O1 story synthesis'; Text = $o1Synthesis },
        [pscustomobject]@{ Name = 'FEATURE template'; Text = $featureTemplate }
    )) { Assert-DocumentConcepts $document.Text $document.Name @('external alias relative path') }
    Assert-DocumentConcepts $o2Contract 'O2 guidance' @('external alias relative path')
    Assert-DocumentConcepts $o2PerStory 'O2 per-story guidance' @('preserve exact alias relative path')
    Assert-DocumentConcepts $o2Handoff 'O2 handoff' @('external alias relative path')

    # The contract checks ignore Markdown decoration, punctuation, case, and spacing.
    Assert-DocumentConcepts '**EXTERNAL:** Alias / Relative-Path — NO ABSOLUTE ROOT' 'normalization regression' @('external alias relative path', 'no absolute root')
    Write-Host 'O3ReceiptValidationContracts: PASS (receipt, spawn, O3 invocation, O1 capture, O2 preservation, runtime publication)'
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
exit 0
