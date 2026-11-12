#Requires -Version 7.0
<#
.SYNOPSIS
  Writes and verifies operational evidence files for one integrated-delivery unit.
.DESCRIPTION
  Evidence files live under features/NNN-slug/<UNIT>/evidence/<step-id>--<name>.<ext>.
  The write action accepts only a name that the step declares in its Evidence line, rejects
  sensitive content, and writes atomically. The verify action checks that exactly one file
  exists for the step and name, optionally against an expected SHA-256. Neither action edits
  the PLAN or the STEP blocks. Writes one compact JSON line to stdout.
  Exit codes: 0 ok, 3 blocked, 1 thrown error.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('write', 'verify')][string] $Action,
    [Parameter(Mandatory = $true)][string] $RepoPath,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [Parameter(Mandatory = $true)][string] $Step,
    [Parameter(Mandatory = $true)][string] $Name,
    [string] $Content,
    [string] $SourcePath,
    [ValidateSet('json', 'txt', 'md')][string] $Extension = 'txt',
    [string] $ExpectedSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')

$sensitivePatterns = [ordered]@{
    private_key           = '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    credential_assignment = '(?i)\b(password|passwd|secret|api[_-]?key|token)\s*[:=]\s*\S+'
    bearer_token          = '(?i)bearer\s+[A-Za-z0-9._~+/-]{20,}'
    aws_access_key        = 'AKIA[0-9A-Z]{16}'
}
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Exit-Blocked {
    param(
        [Parameter(Mandatory = $true)][string] $Reason,
        [Parameter(Mandatory = $true)][string] $Message
    )

    $verdict = [pscustomobject]@{ ok = $false; reason = $Reason; message = $Message }
    [Console]::Out.WriteLine(($verdict | ConvertTo-Json -Compress))
    exit 3
}

function Exit-Success {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Sha256,
        [Parameter(Mandatory = $true)][long] $Bytes
    )

    $result = [pscustomobject]@{ ok = $true; path = $Path; sha256 = $Sha256; bytes = $Bytes }
    [Console]::Out.WriteLine(($result | ConvertTo-Json -Compress))
    exit 0
}

function Get-BytesSha256Hex {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]] $Bytes)

    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($Bytes))
}

function Get-EvidenceCandidates {
    param(
        [Parameter(Mandatory = $true)][string] $Directory,
        [Parameter(Mandatory = $true)][string] $Step,
        [Parameter(Mandatory = $true)][string] $Name
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return }
    $prefix = $Step + '--' + $Name + '.'
    $found = [System.Collections.Generic.List[object]]::new()
    foreach ($item in @(Get-ChildItem -LiteralPath $Directory -File -Force)) {
        if (-not $item.Name.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($item.Name.Substring($prefix.Length) -cmatch '^[A-Za-z0-9]+\z') { $found.Add($item) }
    }
    foreach ($match in $found) { $match }
}

try {
    $hasContent = $PSBoundParameters.ContainsKey('Content')
    $hasSource = $PSBoundParameters.ContainsKey('SourcePath')
    $hasExpected = $PSBoundParameters.ContainsKey('ExpectedSha256')

    if ($Action -eq 'write') {
        if ($hasExpected) { throw 'ExpectedSha256 applies only to verify.' }
        if ($hasContent -eq $hasSource) { throw 'Write requires exactly one of -Content or -SourcePath.' }
    }
    else {
        if ($hasContent -or $hasSource) { throw 'Verify does not accept -Content or -SourcePath.' }
        if ($hasExpected -and ($ExpectedSha256 -notmatch '^[0-9A-Fa-f]{64}\z')) { throw 'ExpectedSha256 must be 64 hexadecimal characters.' }
    }
    if ($Step -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]*\z') { throw 'Step must match ^[A-Za-z0-9][A-Za-z0-9._-]*$.' }
    if ($Step.Contains('--')) { throw 'Step must not contain the -- separator.' }
    if ($Name -cnotmatch '^[a-z0-9][a-z0-9-]*\z') { throw 'Name must match ^[a-z0-9][a-z0-9-]*$.' }

    $repoFull = [System.IO.Path]::GetFullPath($RepoPath)
    $planRelative = $PlanPath.Replace('\', '/')
    if (-not [regex]::IsMatch($planRelative, '^features/[0-9]{3}-[a-z0-9]+(?:-[a-z0-9]+)*/(?:US|TS)[0-9]{2}/PLAN\.md\z')) {
        throw 'PlanPath must be the canonical features/NNN-slug/(USnn|TSnn)/PLAN.md path.'
    }
    $planFull = Get-SafeFullPath $repoFull $planRelative
    Assert-NoReparseAncestors $planFull $repoFull
    if (-not (Test-Path -LiteralPath $planFull -PathType Leaf)) { throw 'PlanPath does not name an existing file.' }

    $evidenceRelative = $planRelative.Substring(0, $planRelative.LastIndexOf('/')) + '/evidence'
    $evidenceFull = Get-SafeFullPath $repoFull $evidenceRelative
    Assert-NoReparseAncestors $evidenceFull $repoFull

    if ($Action -eq 'write') {
        $planText = [System.IO.File]::ReadAllText($planFull, [System.Text.Encoding]::UTF8)
        $declared = Get-DeliveryDeclaredSteps -Text $planText
        $stepEntry = @($declared.Steps | Where-Object { $_.Id -ceq $Step })
        if (($stepEntry.Count -eq 0) -or ($Name -cnotin @($stepEntry[0].Evidence))) {
            Exit-Blocked -Reason 'evidence_not_declared' -Message ('Step {0} does not declare evidence {1} in its Evidence line.' -f $Step, $Name)
        }

        if ($hasContent) {
            $bytes = $utf8NoBom.GetBytes([string]$Content)
        }
        else {
            $sourceFull = Get-SafeFullPath $repoFull $SourcePath
            Assert-NoReparseAncestors $sourceFull $repoFull
            if (-not (Test-Path -LiteralPath $sourceFull -PathType Leaf)) { throw 'SourcePath does not name an existing file.' }
            $bytes = [System.IO.File]::ReadAllBytes($sourceFull)
        }

        $scanText = $utf8NoBom.GetString($bytes)
        foreach ($pattern in $sensitivePatterns.GetEnumerator()) {
            if ([regex]::IsMatch($scanText, [string]$pattern.Value)) {
                Exit-Blocked -Reason 'sensitive_content_detected' -Message ('Content matches sensitive pattern {0}; nothing was written.' -f $pattern.Key)
            }
        }

        $fileName = '{0}--{1}.{2}' -f $Step, $Name, $Extension
        $targetRelative = $evidenceRelative + '/' + $fileName
        $targetFull = Get-SafeFullPath $evidenceFull $fileName
        Assert-NoReparseAncestors $targetFull $repoFull

        $sha = Get-BytesSha256Hex -Bytes $bytes
        $others = @(Get-EvidenceCandidates -Directory $evidenceFull -Step $Step -Name $Name |
                Where-Object { -not $_.Name.Equals($fileName, [System.StringComparison]::OrdinalIgnoreCase) })
        if ($others.Count -gt 0) {
            Exit-Blocked -Reason 'evidence_ambiguous' -Message 'Another evidence file already exists for this step and name.'
        }

        if (Test-Path -LiteralPath $targetFull -PathType Leaf) {
            $existingSha = Get-BytesSha256Hex -Bytes ([System.IO.File]::ReadAllBytes($targetFull))
            if ($existingSha -cne $sha) {
                Exit-Blocked -Reason 'evidence_exists_different' -Message 'Evidence file already exists with different content.'
            }
            Exit-Success -Path $targetRelative -Sha256 $sha -Bytes $bytes.Length
        }

        New-Item -ItemType Directory -Path $evidenceFull -Force | Out-Null
        $temp = Join-Path $evidenceFull ('.delivery-evidence-' + [guid]::NewGuid().ToString('N') + '.tmp')
        $conflict = $false
        try {
            [System.IO.File]::WriteAllBytes($temp, $bytes)
            try {
                [System.IO.File]::Move($temp, $targetFull, $false)
            }
            catch [System.IO.IOException] {
                if (-not (Test-Path -LiteralPath $targetFull -PathType Leaf)) { throw }
                $concurrentSha = Get-BytesSha256Hex -Bytes ([System.IO.File]::ReadAllBytes($targetFull))
                if ($concurrentSha -cne $sha) { $conflict = $true }
            }
        }
        finally {
            if (Test-Path -LiteralPath $temp -PathType Leaf) { Remove-Item -LiteralPath $temp -Force }
        }
        if ($conflict) {
            Exit-Blocked -Reason 'evidence_exists_different' -Message 'Evidence file was created with different content during the write.'
        }
        Exit-Success -Path $targetRelative -Sha256 $sha -Bytes $bytes.Length
    }

    $candidates = @(Get-EvidenceCandidates -Directory $evidenceFull -Step $Step -Name $Name)
    if ($candidates.Count -eq 0) {
        Exit-Blocked -Reason 'evidence_missing' -Message 'No evidence file matches this step and name.'
    }
    if ($candidates.Count -gt 1) {
        Exit-Blocked -Reason 'evidence_ambiguous' -Message 'More than one evidence file matches this step and name.'
    }
    $file = $candidates[0]
    Assert-NoReparseAncestors $file.FullName $repoFull
    $verifyBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $verifySha = Get-BytesSha256Hex -Bytes $verifyBytes
    if ($hasExpected -and -not [string]::Equals($verifySha, $ExpectedSha256, [System.StringComparison]::OrdinalIgnoreCase)) {
        Exit-Blocked -Reason 'evidence_changed' -Message 'Evidence file SHA-256 differs from the expected value.'
    }
    Exit-Success -Path ($evidenceRelative + '/' + $file.Name) -Sha256 $verifySha -Bytes $verifyBytes.Length
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
