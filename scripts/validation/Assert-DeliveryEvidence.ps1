#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptsRoot = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $scriptsRoot 'runtime/Invoke-DeliveryEvidence.ps1'

$childHost = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($childHost)) { $childHost = 'pwsh' }
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('delivery-evidence-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$passed = 0
$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false
$planRelative = 'features/001-demo/US01/PLAN.md'
$evidenceRelative = 'features/001-demo/US01/evidence'
$junctionPaths = [System.Collections.Generic.List[string]]::new()

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('{0}: condition failed' -f $Name) }
    $script:passed++
}

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) { throw ('{0}: expected {1}, got {2}' -f $Name, $Expected, $Actual) }
    $script:passed++
}

function Get-TextSha256([string]$Text) {
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($utf8.GetBytes($Text)))
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function New-EvidenceRepo {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [string] $PlanRelative = $planRelative,
        [Parameter(Mandatory = $true)][string] $PlanText
    )

    $repo = Join-Path $tempRoot $Name
    $path = Join-Path $repo ($PlanRelative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [System.IO.File]::WriteAllText($path, $PlanText, $utf8)
    return $repo
}

function Invoke-Helper {
    param([Parameter(Mandatory = $true)][string[]] $CliArgs)

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $helper) + $CliArgs
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

function New-WriteArgs {
    param(
        [Parameter(Mandatory = $true)][string] $Repo,
        [Parameter(Mandatory = $true)][string] $Step,
        [Parameter(Mandatory = $true)][string] $Name,
        [string] $Plan = $planRelative,
        [string] $Extension = 'txt'
    )

    return @('-Action', 'write', '-RepoPath', $Repo, '-PlanPath', $Plan, '-Step', $Step, '-Name', $Name, '-Extension', $Extension)
}

function New-VerifyArgs {
    param(
        [Parameter(Mandatory = $true)][string] $Repo,
        [Parameter(Mandatory = $true)][string] $Step,
        [Parameter(Mandatory = $true)][string] $Name,
        [string] $Plan = $planRelative
    )

    return @('-Action', 'verify', '-RepoPath', $Repo, '-PlanPath', $Plan, '-Step', $Step, '-Name', $Name)
}

function Assert-ExitCode([int]$Expected, $Run, [string]$Name) {
    Assert-Equal ([string]$Expected) ([string]$Run.ExitCode) $Name
}

function Assert-Reason($Run, [string]$Reason, [string]$Name) {
    $actual = ''
    if ($null -ne $Run.Result) { $actual = [string]$Run.Result.reason }
    Assert-Equal $Reason $actual $Name
}

function Assert-NoLeak($Run, [string]$Secret, [string]$Name) {
    $output = $Run.Stdout + "`n" + $Run.Stderr
    if ($output.Contains($Secret)) { throw ('{0}: sensitive value echoed in output' -f $Name) }
    $script:passed++
}

$validPlanText = @(
    '# Test plan',
    '',
    'Normative body: feature behavior.',
    '',
    '## Steps',
    '',
    '### US01-S1 Build',
    'Depends on: none',
    'Validation: run-tests',
    'Evidence: run-log, build-output',
    '',
    '### US01-S2 Verify',
    'Depends on: US01-S1',
    'Validation: run-tests',
    'Evidence: review-notes',
    'Needs evidence: US01-S1/run-log',
    '',
    '<!-- DELIVERY:PROGRESS:BEGIN -->',
    '{"schema":"delivery-progress/v1","cadence":"step_by_step"}',
    '<!-- DELIVERY:PROGRESS:END -->',
    '<!-- DELIVERY:CHECKPOINT:BEGIN -->',
    '{"schema":"delivery-checkpoint/v1","branch":"feature/test","head":"abc123","active_step":null}',
    '<!-- DELIVERY:CHECKPOINT:END -->',
    '<!-- DELIVERY:APPROVAL:BEGIN -->',
    '{"schema":"delivery-approval/v1","state":"pending"}',
    '<!-- DELIVERY:APPROVAL:END -->',
    '<!-- DELIVERY:STEP:US01-S1:BEGIN -->',
    '{"schema":"delivery-step/v1","id":"US01-S1","status":"PENDING","depends_on":[]}',
    '<!-- DELIVERY:STEP:US01-S1:END -->',
    '<!-- DELIVERY:STEP:US01-S2:BEGIN -->',
    '{"schema":"delivery-step/v1","id":"US01-S2","status":"PENDING","depends_on":["US01-S1"]}',
    '<!-- DELIVERY:STEP:US01-S2:END -->'
) -join "`n"
$validPlanText += "`n"

try {
    $repo = New-EvidenceRepo -Name 'roundtrip' -PlanText $validPlanText
    $evidenceDir = Join-Path $repo ($evidenceRelative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    $expectedPath = 'features/001-demo/US01/evidence/US01-S1--run-log.txt'
    $content = 'build passed'
    $expectedSha = Get-TextSha256 $content

    $written = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $repo -Step 'US01-S1' -Name 'run-log') + @('-Content', $content))
    Assert-ExitCode 0 $written 'Should_ExitZero_When_WriteSucceeds'
    Assert-True ($written.Result.ok -eq $true) 'Should_ReturnOk_When_WriteSucceeds'
    Assert-Equal $expectedPath ([string]$written.Result.path) 'Should_UseConventionPath_When_WriteSucceeds'
    Assert-Equal $expectedSha ([string]$written.Result.sha256) 'Should_ReturnContentSha256_When_WriteSucceeds'
    Assert-True ([int64]$written.Result.bytes -eq $utf8.GetByteCount($content)) 'Should_ReturnByteCount_When_WriteSucceeds'
    $onDisk = [System.IO.File]::ReadAllText((Join-Path $repo $expectedPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)), $utf8)
    Assert-Equal $content $onDisk 'Should_WriteExactContent_When_WriteSucceeds'

    $verified = Invoke-Helper -CliArgs (New-VerifyArgs -Repo $repo -Step 'US01-S1' -Name 'run-log')
    Assert-ExitCode 0 $verified 'Should_ExitZero_When_VerifyRoundTrips'
    Assert-Equal $expectedSha ([string]$verified.Result.sha256) 'Should_ReturnSameSha_When_VerifyRoundTrips'
    Assert-Equal $expectedPath ([string]$verified.Result.path) 'Should_ReturnSamePath_When_VerifyRoundTrips'

    $lowerExpected = Invoke-Helper -CliArgs ((New-VerifyArgs -Repo $repo -Step 'US01-S1' -Name 'run-log') + @('-ExpectedSha256', $expectedSha.ToLowerInvariant()))
    Assert-ExitCode 0 $lowerExpected 'Should_ExitZero_When_ExpectedShaDiffersOnlyByCase'

    $leftovers = @(Get-ChildItem -LiteralPath $evidenceDir -Force | Where-Object { $_.Name.StartsWith('.') })
    Assert-Equal '0' ([string]$leftovers.Count) 'Should_LeaveNoTempFiles_When_WriteSucceeds'

    $rewriteTime = [DateTime]::SpecifyKind([DateTime]::Parse('2000-01-01T00:00:00'), [DateTimeKind]::Utc)
    $targetFile = Join-Path $repo ($expectedPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    [System.IO.File]::SetLastWriteTimeUtc($targetFile, $rewriteTime)
    $again = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $repo -Step 'US01-S1' -Name 'run-log') + @('-Content', $content))
    Assert-ExitCode 0 $again 'Should_ExitZero_When_IdenticalContentRewritten'
    Assert-Equal $expectedSha ([string]$again.Result.sha256) 'Should_ReturnSameSha_When_IdenticalContentRewritten'
    Assert-True ([System.IO.File]::GetLastWriteTimeUtc($targetFile) -eq $rewriteTime) 'Should_NotRewrite_When_IdenticalContentExists'

    $different = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $repo -Step 'US01-S1' -Name 'run-log') + @('-Content', 'build failed'))
    Assert-ExitCode 3 $different 'Should_ExitThree_When_ExistingContentDiffers'
    Assert-Reason $different 'evidence_exists_different' 'Should_ReturnEvidenceExistsDifferent_When_ExistingContentDiffers'
    Assert-Equal $content ([System.IO.File]::ReadAllText($targetFile, $utf8)) 'Should_KeepExistingContent_When_ExistingContentDiffers'

    $undeclaredName = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $repo -Step 'US01-S1' -Name 'other-log') + @('-Content', 'x'))
    Assert-ExitCode 3 $undeclaredName 'Should_ExitThree_When_NameIsNotDeclared'
    Assert-Reason $undeclaredName 'evidence_not_declared' 'Should_ReturnEvidenceNotDeclared_When_NameIsNotDeclared'

    $undeclaredStep = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $repo -Step 'US01-S9' -Name 'run-log') + @('-Content', 'x'))
    Assert-ExitCode 3 $undeclaredStep 'Should_ExitThree_When_StepIsNotDeclared'
    Assert-Reason $undeclaredStep 'evidence_not_declared' 'Should_ReturnEvidenceNotDeclared_When_StepIsNotDeclared'

    $otherStepName = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $repo -Step 'US01-S2' -Name 'run-log') + @('-Content', 'x'))
    Assert-Reason $otherStepName 'evidence_not_declared' 'Should_ReturnEvidenceNotDeclared_When_NameBelongsToAnotherStep'

    $sensitiveCases = @(
        @{ Id = 'private_key'; Content = 'key: -----BEGIN OPENSSH PRIVATE KEY----- AAAAB3NzaC1yc2E'; Secret = 'AAAAB3NzaC1yc2E' },
        @{ Id = 'credential_assignment'; Content = 'config password=hunter2hunter2'; Secret = 'hunter2hunter2' },
        @{ Id = 'bearer_token'; Content = 'Authorization: Bearer abcdefghijklmnopqrstuvwxyz0123'; Secret = 'abcdefghijklmnopqrstuvwxyz0123' },
        @{ Id = 'aws_access_key'; Content = 'key AKIAABCDEFGHIJKLMNOP'; Secret = 'AKIAABCDEFGHIJKLMNOP' }
    )
    $sensitiveRepo = New-EvidenceRepo -Name 'sensitive' -PlanText $validPlanText
    $sensitiveEvidenceDir = Join-Path $sensitiveRepo ($evidenceRelative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    foreach ($case in $sensitiveCases) {
        $sensitive = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sensitiveRepo -Step 'US01-S1' -Name 'run-log') + @('-Content', $case.Content))
        Assert-ExitCode 3 $sensitive ('Should_ExitThree_When_{0}Present' -f $case.Id)
        Assert-Reason $sensitive 'sensitive_content_detected' ('Should_ReturnSensitiveContentDetected_When_{0}Present' -f $case.Id)
        Assert-True (([string]$sensitive.Result.message).Contains($case.Id)) ('Should_NameOnlyPatternId_When_{0}Present' -f $case.Id)
        Assert-NoLeak $sensitive $case.Secret ('Should_NotEchoContent_When_{0}Present' -f $case.Id)
    }
    Assert-True (-not (Test-Path -LiteralPath $sensitiveEvidenceDir)) 'Should_NotCreateEvidenceDirectory_When_ContentIsSensitive'

    $sensitiveSourceRelative = 'features/001-demo/scratch/sensitive-source.txt'
    $sensitiveSourcePath = Join-Path $sensitiveRepo ($sensitiveSourceRelative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    New-Item -ItemType Directory -Path (Split-Path -Parent $sensitiveSourcePath) -Force | Out-Null
    [System.IO.File]::WriteAllText($sensitiveSourcePath, 'token: Zx9Qw7Lm2Rt5Yu8Ip', $utf8)
    $sensitiveSource = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sensitiveRepo -Step 'US01-S1' -Name 'run-log') + @('-SourcePath', $sensitiveSourceRelative))
    Assert-Reason $sensitiveSource 'sensitive_content_detected' 'Should_ReturnSensitiveContentDetected_When_SourcePathHasSecret'
    Assert-NoLeak $sensitiveSource 'Zx9Qw7Lm2Rt5Yu8Ip' 'Should_NotEchoSourceContent_When_SourcePathHasSecret'

    $sourceRepo = New-EvidenceRepo -Name 'source-path' -PlanText $validPlanText
    $sourceRelative = 'features/001-demo/scratch/source.txt'
    $sourceFile = Join-Path $sourceRepo ($sourceRelative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    New-Item -ItemType Directory -Path (Split-Path -Parent $sourceFile) -Force | Out-Null
    [System.IO.File]::WriteAllText($sourceFile, 'reviewed notes', $utf8)
    $sourceSha = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.IO.File]::ReadAllBytes($sourceFile)))
    $fromSource = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sourceRepo -Step 'US01-S2' -Name 'review-notes') + @('-SourcePath', $sourceRelative))
    Assert-ExitCode 0 $fromSource 'Should_ExitZero_When_SourcePathIsRepositoryRelative'
    Assert-Equal 'features/001-demo/US01/evidence/US01-S2--review-notes.txt' ([string]$fromSource.Result.path) 'Should_UseConventionPath_When_SourcePathIsUsed'
    Assert-Equal $sourceSha ([string]$fromSource.Result.sha256) 'Should_HashSourceBytes_When_SourcePathIsUsed'

    $traversalSource = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sourceRepo -Step 'US01-S2' -Name 'review-notes') + @('-SourcePath', '../outside.txt'))
    Assert-ExitCode 1 $traversalSource 'Should_ExitOne_When_SourcePathTraverses'

    $absoluteSource = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sourceRepo -Step 'US01-S2' -Name 'review-notes') + @('-SourcePath', $sourceFile))
    Assert-ExitCode 1 $absoluteSource 'Should_ExitOne_When_SourcePathIsAbsolute'

    $bothInputs = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sourceRepo -Step 'US01-S2' -Name 'review-notes') + @('-Content', 'x', '-SourcePath', $sourceRelative))
    Assert-ExitCode 1 $bothInputs 'Should_ExitOne_When_ContentAndSourcePathBothGiven'

    $noInput = Invoke-Helper -CliArgs (New-WriteArgs -Repo $sourceRepo -Step 'US01-S2' -Name 'review-notes')
    Assert-ExitCode 1 $noInput 'Should_ExitOne_When_NeitherContentNorSourcePathGiven'

    $badExtension = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sourceRepo -Step 'US01-S2' -Name 'review-notes' -Extension 'exe') + @('-Content', 'x'))
    Assert-ExitCode 1 $badExtension 'Should_ExitOne_When_ExtensionIsNotAllowed'

    $badName = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sourceRepo -Step 'US01-S2' -Name 'Review_Notes') + @('-Content', 'x'))
    Assert-ExitCode 1 $badName 'Should_ExitOne_When_NameFailsSlugPattern'
    $doubleDashWrite = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $sourceRepo -Step 'US01--S1' -Name 'run-log') + @('-Content', 'x'))
    Assert-ExitCode 1 $doubleDashWrite 'Should_ExitOne_When_WriteStepContainsDoubleHyphen'
    $doubleDashVerify = Invoke-Helper -CliArgs (New-VerifyArgs -Repo $sourceRepo -Step 'US01--S1' -Name 'run-log')
    Assert-ExitCode 1 $doubleDashVerify 'Should_ExitOne_When_VerifyStepContainsDoubleHyphen'

    $badPlanRepo = New-EvidenceRepo -Name 'bad-plan-path' -PlanRelative 'docs/PLAN.md' -PlanText $validPlanText
    $badPlanCases = @(
        @{ Name = 'Should_ExitOne_When_PlanIsOutsideFeatures'; Repo = $badPlanRepo; Plan = 'docs/PLAN.md' },
        @{ Name = 'Should_ExitOne_When_PlanIsNotCanonical'; Repo = $repo; Plan = 'features/001-demo/PLAN.md' },
        @{ Name = 'Should_ExitOne_When_PlanPathTraverses'; Repo = $repo; Plan = 'features/001-demo/../../escape/US01/PLAN.md' },
        @{ Name = 'Should_ExitOne_When_PlanPathIsAbsolute'; Repo = $repo; Plan = (Join-Path $repo $planRelative) }
    )
    foreach ($case in $badPlanCases) {
        $badPlan = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $case.Repo -Step 'US01-S1' -Name 'run-log' -Plan $case.Plan) + @('-Content', 'x'))
        Assert-ExitCode 1 $badPlan $case.Name
    }

    $missingEvidence = Invoke-Helper -CliArgs (New-VerifyArgs -Repo $repo -Step 'US01-S1' -Name 'build-output')
    Assert-ExitCode 3 $missingEvidence 'Should_ExitThree_When_EvidenceMissing'
    Assert-Reason $missingEvidence 'evidence_missing' 'Should_ReturnEvidenceMissing_When_NoFileMatches'

    $changed = Invoke-Helper -CliArgs ((New-VerifyArgs -Repo $repo -Step 'US01-S1' -Name 'run-log') + @('-ExpectedSha256', ('A' * 64)))
    Assert-ExitCode 3 $changed 'Should_ExitThree_When_ExpectedShaDiffers'
    Assert-Reason $changed 'evidence_changed' 'Should_ReturnEvidenceChanged_When_ExpectedShaDiffers'

    $badExpected = Invoke-Helper -CliArgs ((New-VerifyArgs -Repo $repo -Step 'US01-S1' -Name 'run-log') + @('-ExpectedSha256', 'not-a-digest'))
    Assert-ExitCode 1 $badExpected 'Should_ExitOne_When_ExpectedShaMalformed'

    $ambiguousWrite = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $repo -Step 'US01-S1' -Name 'run-log' -Extension 'md') + @('-Content', $content))
    Assert-ExitCode 3 $ambiguousWrite 'Should_ExitThree_When_WriteWouldAddSecondExtension'
    Assert-Reason $ambiguousWrite 'evidence_ambiguous' 'Should_ReturnEvidenceAmbiguous_When_WriteWouldAddSecondExtension'
    [System.IO.File]::WriteAllText((Join-Path $evidenceDir 'US01-S1--run-log.md'), $content, $utf8)
    $ambiguous = Invoke-Helper -CliArgs (New-VerifyArgs -Repo $repo -Step 'US01-S1' -Name 'run-log')
    Assert-ExitCode 3 $ambiguous 'Should_ExitThree_When_TwoFilesMatchOneName'
    Assert-Reason $ambiguous 'evidence_ambiguous' 'Should_ReturnEvidenceAmbiguous_When_TwoFilesMatchOneName'

    $reparseRepo = New-EvidenceRepo -Name 'reparse-ancestor' -PlanRelative 'features/001-demo/US03/PLAN.md' -PlanText $validPlanText
    $externalTarget = Join-Path $tempRoot 'external-target'
    New-Item -ItemType Directory -Path $externalTarget | Out-Null
    $junctionPath = Join-Path $reparseRepo 'features\001-demo\US03\evidence'
    $junctionCreated = $true
    try {
        New-Item -ItemType Junction -Path $junctionPath -Target $externalTarget | Out-Null
    }
    catch {
        $junctionCreated = $false
        Write-Host ('SKIP: reparse-point ancestor check; the OS refused to create a junction: {0}' -f $_.Exception.Message)
    }
    if ($junctionCreated) {
        $junctionPaths.Add($junctionPath)
        $reparseWrite = Invoke-Helper -CliArgs ((New-WriteArgs -Repo $reparseRepo -Step 'US01-S1' -Name 'run-log' -Plan 'features/001-demo/US03/PLAN.md') + @('-Content', $content))
        Assert-ExitCode 1 $reparseWrite 'Should_ExitOne_When_EvidenceDirectoryIsReparsePoint'
        $reparseVerify = Invoke-Helper -CliArgs (New-VerifyArgs -Repo $reparseRepo -Step 'US01-S1' -Name 'run-log' -Plan 'features/001-demo/US03/PLAN.md')
        Assert-ExitCode 1 $reparseVerify 'Should_ExitOne_When_VerifyPathCrossesReparsePoint'
        Assert-True (@(Get-ChildItem -LiteralPath $externalTarget -Force).Count -eq 0) 'Should_NotWriteThroughReparsePoint_When_EvidenceDirectoryIsJunction'
    }

    Write-Output ('PASS: {0} delivery evidence assertions.' -f $passed)
}
finally {
    foreach ($junction in $junctionPaths) {
        if ([System.IO.Directory]::Exists($junction)) { [System.IO.Directory]::Delete($junction, $false) }
    }
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
