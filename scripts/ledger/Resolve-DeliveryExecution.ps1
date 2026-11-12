#Requires -Version 5.1
<#
.SYNOPSIS
  Evaluates eligibility and safe resumption for an integrated-delivery PLAN.
.DESCRIPTION
  Read-only decision helper. It never edits the PLAN or repository. Operational
  blocks are JSON between the exact DELIVERY markers in EXECUTION.md. Block
  parsing, required-block rules, and the normative identity come from
  scripts/_lib/DeliveryGrammar.ps1.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [Parameter(Mandatory = $true)][string] $ReviewRecordPath,
    [string] $AliasCatalogPath = '',
    [Parameter(Mandatory = $true)][ValidateSet('step_by_step', 'continuous')][string] $Cadence,
    [Parameter(Mandatory = $true)][string] $CurrentInputIdentity,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string] $CurrentBranch,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string] $CurrentHead,
    [switch] $Resume,
    [switch] $StepAuthorization,
    [switch] $ContinuousAuthorization,
    [switch] $AsLibrary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libDir = Join-Path (Split-Path -Parent $PSScriptRoot) '_lib'
. (Join-Path $libDir 'DeliveryGrammar.ps1')

function New-Decision([bool]$Allowed, [string]$Reason, [string]$Step = '') {
    [pscustomobject]@{ allowed = $Allowed; reason = $Reason; step = $Step }
}

function Get-BlockJson([object[]]$Blocks, [string]$Type) {
    foreach ($block in $Blocks) {
        if ($block.Type -ceq $Type) { return $block.Json }
    }
    throw ('block_{0}_missing' -f $Type)
}

function Test-Field($Object, [string]$Name) {
    return ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name])
}

function Get-VerifiedReviewIdentity {
    param([string]$PlanFullPath)

    $location = Get-EvidenceLocation -PlanFullPath $PlanFullPath
    if ($null -eq $location) { throw 'review_gate_target_invalid' }
    $repoRoot = [string]$location.Root
    $repoPrefix = $repoRoot.TrimEnd([char] [System.IO.Path]::DirectorySeparatorChar, [char] [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $PlanFullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'review_gate_target_invalid' }
    $relativePlan = $PlanFullPath.Substring($repoPrefix.Length).Replace('\', '/')
    if ($relativePlan -notmatch '^features/[^/]+/(US|TS)[0-9]{2}/PLAN\.md$') { throw 'review_gate_target_invalid' }
    $checker = Join-Path (Split-Path -Parent $PSScriptRoot) 'runtime/Test-DeliveryReviewRecord.ps1'
    if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) { throw 'review_gate_unavailable' }
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        try {
            $arguments = @{ RepoPath = $repoRoot; TargetPath = $relativePlan; RecordPath = $ReviewRecordPath; AsLibrary = $true }
            if (-not [string]::IsNullOrWhiteSpace($AliasCatalogPath)) { $arguments['AliasCatalogPath'] = $AliasCatalogPath }
            $check = & $checker @arguments
        }
        catch { throw 'review_gate_invalid_result' }
        if ($null -eq $check -or $null -eq $check.Result) { throw 'review_gate_invalid_result' }
        $verdict = $check.Result
        if ([int]$check.ExitCode -ne 0) {
            if (Test-Field $verdict 'reason') { throw ('review_gate_' + [string]$verdict.reason) }
            throw 'review_gate_denied'
        }
        if (-not (Test-Field $verdict 'allowed') -or $verdict.allowed -ne $true -or -not (Test-Field $verdict 'identity') -or
            -not (Test-Field $verdict.identity 'review_identity') -or -not (Test-Field $verdict.identity 'material_input_identity')) {
            throw 'review_gate_invalid_result'
        }
        return $verdict.identity
    }
    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($null -eq $pwshCommand) { throw 'review_gate_runtime_unavailable' }
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $checker, '-RepoPath', $repoRoot, '-TargetPath', $relativePlan, '-RecordPath', $ReviewRecordPath)
    if (-not [string]::IsNullOrWhiteSpace($AliasCatalogPath)) { $arguments += @('-AliasCatalogPath', $AliasCatalogPath) }
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $pwshCommand.Source
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $quoted = foreach ($argument in $arguments) { '"' + ([string]$argument).Replace('"', '\\"') + '"' }
    $startInfo.Arguments = [string]::Join(' ', $quoted)
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(5000)) {
        try { $process.Kill($true) } catch { }
        [void]$process.WaitForExit(2000)
        throw 'review_gate_timeout'
    }
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    if ($process.ExitCode -ne 0) {
        try { $verdict = $stdout | ConvertFrom-Json } catch { throw 'review_gate_invalid_result' }
        if (Test-Field $verdict 'reason') { throw ('review_gate_' + [string]$verdict.reason) }
        throw 'review_gate_denied'
    }
    try { $verdict = $stdout | ConvertFrom-Json } catch { throw 'review_gate_invalid_result' }
    if (-not (Test-Field $verdict 'allowed') -or $verdict.allowed -ne $true -or -not (Test-Field $verdict 'identity') -or
        -not (Test-Field $verdict.identity 'review_identity') -or -not (Test-Field $verdict.identity 'material_input_identity')) {
        throw 'review_gate_invalid_result'
    }
    return $verdict.identity
}

function Assert-ExecutionAuthorization {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object] $Progress,
        [Parameter(Mandatory = $true)][ValidateSet('step', 'continuous')][string] $ExpectedKind,
        [Parameter(Mandatory = $true)][string] $PlanIdentity,
        [Parameter(Mandatory = $true)][string] $StepId
    )

    if (-not (Test-Field $Progress 'authorization') -or ($Progress.authorization -isnot [System.Management.Automation.PSCustomObject])) {
        throw 'authorization_record_missing'
    }
    $authorization = $Progress.authorization
    if (-not (Test-Field $authorization 'kind') -or ($authorization.kind -isnot [string]) -or ($authorization.kind -cne $ExpectedKind)) {
        throw 'authorization_kind_mismatch'
    }
    if (-not (Test-Field $authorization 'plan_identity') -or ($authorization.plan_identity -isnot [string]) -or ($authorization.plan_identity -cne $PlanIdentity)) {
        throw 'authorization_identity_mismatch'
    }
    $scopeRequired = ($ExpectedKind -ceq 'step') -or (Test-Field $authorization 'step_ids')
    if (-not $scopeRequired) { return }
    if (-not (Test-Field $authorization 'step_ids') -or ($authorization.step_ids -isnot [System.Array])) {
        throw 'authorization_scope_excludes_step'
    }
    $scopeIds = @($authorization.step_ids)
    if ($scopeIds.Count -eq 0) { throw 'authorization_scope_excludes_step' }
    foreach ($scopeId in $scopeIds) {
        if ($scopeId -isnot [string]) { throw 'authorization_scope_excludes_step' }
    }
    if (-not ($scopeIds -ccontains $StepId)) { throw 'authorization_scope_excludes_step' }
}

function Get-EvidenceLocation {
    param([Parameter(Mandatory = $true)][string] $PlanFullPath)

    $cursor = $PlanFullPath
    while ($true) {
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrEmpty($parent) -or ($parent -ceq $cursor)) { return $null }
        if (((Split-Path -Leaf $parent) -ceq 'features') -and ($cursor -cne $PlanFullPath)) {
            return [pscustomobject]@{
                Root    = (Split-Path -Parent $parent)
                Feature = (Split-Path -Leaf $cursor)
                Unit    = (Split-Path -Leaf (Split-Path -Parent $PlanFullPath))
            }
        }
        $cursor = $parent
    }
}

function Get-FileSha256Hex {
    param([Parameter(Mandatory = $true)][string] $Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function New-EvidenceFailure {
    param(
        [Parameter(Mandatory = $true)][string] $Reason,
        [Parameter(Mandatory = $true)][string] $Reference
    )

    return [pscustomobject]@{ Reason = $Reason; Evidence = $Reference }
}

function Get-EvidenceFailure {
    param(
        [Parameter(Mandatory = $true)][string] $Step,
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][AllowNull()][object] $Location,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Blocks,
        [Parameter(Mandatory = $true)][ValidateSet('evidence', 'baseline')][string] $Kind
    )

    $reference = $Step + '/' + $Name
    $missing = $Kind + '_missing'
    $invalid = $Kind + '_ref_invalid'
    $changed = $Kind + '_changed'

    $producer = $null
    foreach ($block in $Blocks) {
        if (($block.Type -ceq 'STEP') -and ([string]$block.Id -ceq $Step)) {
            $producer = $block.Json
            break
        }
    }

    $named = [System.Collections.Generic.List[object]]::new()
    if (Test-Field $producer 'evidence_refs') {
        foreach ($entry in @($producer.evidence_refs)) {
            if ((Test-Field $entry 'name') -and ([string]$entry.name -ceq $Name)) { $named.Add($entry) }
        }
    }
    if ($named.Count -eq 0) { return (New-EvidenceFailure -Reason $missing -Reference $reference) }
    if ($named.Count -gt 1) { return (New-EvidenceFailure -Reason $invalid -Reference $reference) }
    $ref = $named[0]
    if (($null -eq $Location) -or -not (Test-Field $ref 'path') -or -not (Test-Field $ref 'sha256')) {
        return (New-EvidenceFailure -Reason $invalid -Reference $reference)
    }

    $path = [string]$ref.path
    $pathMatch = [regex]::Match($path, '\Afeatures/([^/\\:]+)/([^/\\:]+)/evidence/([^/\\:]+)\z')
    if (-not $pathMatch.Success) { return (New-EvidenceFailure -Reason $invalid -Reference $reference) }
    $feature = $pathMatch.Groups[1].Value
    $unit = $pathMatch.Groups[2].Value
    $fileName = $pathMatch.Groups[3].Value
    if (($feature -cne [string]$Location.Feature) -or ($unit -cne [string]$Location.Unit)) {
        return (New-EvidenceFailure -Reason $invalid -Reference $reference)
    }
    $fileStem = $Step + '--' + $Name + '.'
    if (($fileName.Length -le $fileStem.Length) -or -not $fileName.StartsWith($fileStem, [System.StringComparison]::Ordinal)) {
        return (New-EvidenceFailure -Reason $invalid -Reference $reference)
    }

    $current = [string]$Location.Root
    $attributes = [System.IO.FileAttributes]::Normal
    foreach ($segment in @('features', $feature, $unit, 'evidence', $fileName)) {
        $current = [System.IO.Path]::Combine($current, $segment)
        try {
            $attributes = [System.IO.File]::GetAttributes($current)
        }
        catch {
            return (New-EvidenceFailure -Reason $missing -Reference $reference)
        }
        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            return (New-EvidenceFailure -Reason $invalid -Reference $reference)
        }
    }
    if (($attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
        return (New-EvidenceFailure -Reason $missing -Reference $reference)
    }

    if ((Get-FileSha256Hex -Path $current) -cne [string]$ref.sha256) {
        return (New-EvidenceFailure -Reason $changed -Reference $reference)
    }
    return $null
}

function Get-OrphanBaselineFailure {
    param(
        [Parameter(Mandatory = $true)][string] $StepId,
        [Parameter(Mandatory = $true)][object] $Checkpoint,
        [Parameter(Mandatory = $true)][object] $Location,
        [Parameter(Mandatory = $true)][object[]] $Blocks
    )

    if (-not (Test-Field $Checkpoint 'active_step') -or [string]$Checkpoint.active_step -cne $StepId) {
        return (New-EvidenceFailure -Reason 'baseline_ref_invalid' -Reference ($StepId + '/git-baseline'))
    }
    if (-not (Test-Field $Checkpoint 'baseline_evidence') -or
        [string]::IsNullOrWhiteSpace([string]$Checkpoint.baseline_evidence)) {
        return (New-EvidenceFailure -Reason 'baseline_missing' -Reference ($StepId + '/git-baseline'))
    }
    $baselineText = [string]$Checkpoint.baseline_evidence
    $separator = $baselineText.IndexOf('/')
    if ($separator -le 0 -or $separator -eq ($baselineText.Length - 1) -or
        $baselineText.Substring(0, $separator) -cne $StepId -or $baselineText.IndexOf('/', $separator + 1) -ge 0) {
        return (New-EvidenceFailure -Reason 'baseline_ref_invalid' -Reference $baselineText)
    }
    return (Get-EvidenceFailure -Step $StepId -Name $baselineText.Substring($separator + 1) -Location $Location -Blocks $Blocks -Kind 'baseline')
}

function New-DependencyFailure {
    param(
        [Parameter(Mandatory = $true)][string] $Reason,
        [string] $Dependency = ''
    )

    return [pscustomobject]@{ Reason = $Reason; Dependency = $Dependency }
}

function Test-AcceptanceEvidence {
    param([AllowNull()][object] $Value)

    if ($null -eq $Value) { return $false }
    if ($Value -is [System.DateTime]) { return $true }
    if ($Value -is [string]) { return ($Value.Trim().Length -gt 0) }
    if ($Value -is [System.Array]) {
        foreach ($item in $Value) {
            if ($item -is [System.DateTime]) { return $true }
            if (($item -is [string]) -and ($item.Trim().Length -gt 0)) { return $true }
        }
    }
    return $false
}

function Test-DeclaredValidationEvidence {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object] $Step,
        [Parameter(Mandatory = $true)][string] $DeclaredCommand
    )

    $resultsProperty = Get-DeliveryExactProperty -Object $Step -Name 'validation_results'
    if ($null -eq $resultsProperty -or $resultsProperty.Value -isnot [System.Array]) { return $false }
    foreach ($result in @($resultsProperty.Value)) {
        $command = Get-DeliveryExactProperty -Object $result -Name 'command'
        $status = Get-DeliveryExactProperty -Object $result -Name 'result'
        if ($null -eq $command -or $command.Value -isnot [string] -or
            $null -eq $status -or $status.Value -isnot [string]) { continue }
        if ([string]$command.Value -ine $DeclaredCommand.Trim() -or
            ([string]$status.Value).Trim() -inotmatch '^(pass|passed|success|succeeded)$') { continue }
        $exitCode = Get-DeliveryExactProperty -Object $result -Name 'exit_code'
        if ($null -ne $exitCode -and $exitCode.Value -ne 0) { continue }
        return $true
    }
    return $false
}

function Get-PlanDependencyFailure {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $PlanText,
        [Parameter(Mandatory = $true)][string] $PlanFullPath,
        [Parameter(Mandatory = $true)][AllowNull()][object] $Location
    )

    $declaration = Get-DeliveryPlanDependencies -Text $PlanText
    if (@($declaration.Errors).Count -gt 0) {
        return (New-DependencyFailure -Reason 'plan_dependency_invalid')
    }

    foreach ($dependency in @($declaration.Dependencies)) {
        $dependencyPath = [string]$dependency.Path
        if ($null -eq $Location) {
            return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
        }

        $root = [string]$Location.Root
        $candidate = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($root, $dependencyPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)))
        $featuresPrefix = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($root, 'features')) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($featuresPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
            $candidate.Equals($PlanFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
        }

        $walk = [System.IO.Path]::GetFullPath($root)
        $missing = $false
        foreach ($segment in $dependencyPath.Split('/')) {
            $walk = [System.IO.Path]::Combine($walk, $segment)
            $attributes = [System.IO.FileAttributes]::Normal
            try {
                $attributes = [System.IO.File]::GetAttributes($walk)
            }
            catch {
                $missing = $true
                break
            }
            if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
            }
        }
        if ($missing -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (New-DependencyFailure -Reason 'plan_dependency_missing' -Dependency $dependencyPath)
        }

        $predecessorText = [System.IO.File]::ReadAllText($candidate, [System.Text.Encoding]::UTF8)
        if ($predecessorText.Contains([string][char]0xFFFD)) {
            return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
        }
        $predecessorBlocks = Read-DeliveryBlocks -Text $predecessorText
        if (-not $predecessorBlocks.Ok) {
            return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
        }

        $recomputedIdentity = Get-DeliveryNormativeIdentity -Text $predecessorText
        if ([string]$dependency.Identity -cne $recomputedIdentity) {
            return (New-DependencyFailure -Reason 'plan_dependency_identity_changed' -Dependency $dependencyPath)
        }

        $approvalJson = $null
        foreach ($block in @($predecessorBlocks.Blocks)) {
            if ($block.Type -ceq 'APPROVAL') { $approvalJson = $block.Json }
        }
        if ($null -eq $approvalJson) {
            return (New-DependencyFailure -Reason 'plan_dependency_not_approved' -Dependency $dependencyPath)
        }
        $approvalState = Get-DeliveryExactProperty -Object $approvalJson -Name 'state'
        $approvalIdentity = Get-DeliveryExactProperty -Object $approvalJson -Name 'identity'
        if (($null -eq $approvalState) -or ($approvalState.Value -isnot [string]) -or ($approvalState.Value -cne 'approved')) {
            return (New-DependencyFailure -Reason 'plan_dependency_not_approved' -Dependency $dependencyPath)
        }
        if (($null -eq $approvalIdentity) -or ($approvalIdentity.Value -isnot [string]) -or ($approvalIdentity.Value -cne $recomputedIdentity)) {
            return (New-DependencyFailure -Reason 'plan_dependency_not_approved' -Dependency $dependencyPath)
        }

        $predecessorDeclared = Get-DeliveryDeclaredSteps -Text $predecessorText
        if (@($predecessorDeclared.Errors).Count -gt 0) {
            return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
        }

        foreach ($stepId in @($dependency.Steps)) {
            $stepJson = $null
            $stepFound = $false
            foreach ($block in @($predecessorBlocks.Blocks)) {
                if (($block.Type -ceq 'STEP') -and ([string]$block.Id -ceq [string]$stepId)) {
                    $stepJson = $block.Json
                    $stepFound = $true
                    break
                }
            }
            if (-not $stepFound -or ($null -eq $stepJson)) {
                return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
            }

            $declaredStep = @($predecessorDeclared.Steps | Where-Object { [string]$_.Id -ceq [string]$stepId }) | Select-Object -First 1
            if ($null -eq $declaredStep -or [string]::IsNullOrWhiteSpace([string]$declaredStep.Validation)) {
                return (New-DependencyFailure -Reason 'plan_dependency_invalid' -Dependency $dependencyPath)
            }

            $statusProperty = Get-DeliveryExactProperty -Object $stepJson -Name 'status'
            if (($null -eq $statusProperty) -or ($statusProperty.Value -isnot [string]) -or ($statusProperty.Value -cne 'COMPLETED')) {
                return (New-DependencyFailure -Reason 'plan_dependency_step_incomplete' -Dependency $dependencyPath)
            }

            $evidenceProperty = Get-DeliveryExactProperty -Object $stepJson -Name 'acceptance_evidence'
            if (($null -eq $evidenceProperty) -or -not (Test-AcceptanceEvidence -Value $evidenceProperty.Value)) {
                return (New-DependencyFailure -Reason 'plan_dependency_evidence_missing' -Dependency $dependencyPath)
            }
            if (-not (Test-DeclaredValidationEvidence -Step $stepJson -DeclaredCommand ([string]$declaredStep.Validation))) {
                return (New-DependencyFailure -Reason 'plan_dependency_validation_missing' -Dependency $dependencyPath)
            }
        }
    }

    return $null
}

$grammarCodes = @()
$denialEvidence = ''
$denialDependency = ''

try {
    if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) { throw 'plan_missing' }
    $resolved = (Resolve-Path -LiteralPath $PlanPath).Path
    $text = [System.IO.File]::ReadAllText($resolved, [System.Text.Encoding]::UTF8)
    if ($text.Contains([string][char]0xFFFD)) { throw 'plan_invalid_utf8' }

    $parsed = Read-DeliveryBlocks -Text $text
    $stepIds = @($parsed.Blocks | Where-Object { $_.Type -ceq 'STEP' } | ForEach-Object { [string]$_.Id })
    $grammarIssues = [System.Collections.Generic.List[object]]::new()
    if (-not $parsed.Ok) {
        foreach ($issue in @($parsed.Errors)) { $grammarIssues.Add($issue) }
    }
    # Assign before enumerating: an empty result from the library is otherwise seen as one element.
    $requirementIssues = @(Test-DeliveryRequiredBlocks -Result $parsed -Kind PLAN -StepIds $stepIds)
    foreach ($issue in @($requirementIssues)) {
        $grammarIssues.Add($issue)
    }
    if ($grammarIssues.Count -gt 0) {
        $grammarCodes = @($grammarIssues | ForEach-Object { [string]$_.code } | Select-Object -Unique)
        if ($grammarCodes -contains 'legacy_step_marker') { throw 'legacy_marker' }
        throw 'grammar_invalid'
    }

    $planIdentity = Get-DeliveryNormativeIdentity -Text $text
    $progress = Get-BlockJson -Blocks @($parsed.Blocks) -Type 'PROGRESS'
    $checkpoint = Get-BlockJson -Blocks @($parsed.Blocks) -Type 'CHECKPOINT'
    $approval = Get-BlockJson -Blocks @($parsed.Blocks) -Type 'APPROVAL'
    $verifiedReviewIdentity = Get-VerifiedReviewIdentity -PlanFullPath $resolved
    if (-not (Test-Field $approval 'state') -or $approval.state -cne 'approved') { throw 'plan_not_approved' }
    if (-not (Test-Field $approval 'identity') -or $approval.identity -cne $planIdentity) { throw 'approval_identity_stale' }
    if (-not (Test-Field $approval 'input_identity') -or $approval.input_identity -cne $CurrentInputIdentity -or
        $approval.input_identity -cne [string]$verifiedReviewIdentity.material_input_identity) { throw 'material_input_identity_stale' }
    if (-not (Test-Field $approval 'review_identity') -or $approval.review_identity -cne [string]$verifiedReviewIdentity.review_identity) { throw 'review_identity_stale' }
    if (-not (Test-Field $approval 'review_state') -or $approval.review_state -notin @('reviewed', 'bypassed')) { throw 'review_required' }
    if ($approval.review_state -ceq 'bypassed' -and
        ((-not (Test-Field $approval 'review_bypass_reason')) -or [string]::IsNullOrWhiteSpace([string]$approval.review_bypass_reason) -or
         (-not (Test-Field $approval 'review_bypass_operator_choice')) -or [string]$approval.review_bypass_operator_choice -cne 'bypass')) {
        throw 'review_bypass_evidence_missing'
    }
    if ((Test-Field $approval 'blocking_findings') -and @($approval.blocking_findings).Count -gt 0) { throw 'blocking_review_findings' }
    if ((Test-Field $approval 'unresolved_decisions') -and @($approval.unresolved_decisions).Count -gt 0) { throw 'material_decision_unresolved' }
    if (-not (Test-Field $progress 'cadence')) { throw 'cadence_missing' }
    if ($progress.cadence -cne $Cadence) { throw 'cadence_mismatch' }

    $declared = Get-DeliveryDeclaredSteps -Text $text
    $declaredSteps = @($declared.Steps)
    foreach ($declaredError in @($declared.Errors)) {
        if ([string]$declaredError.code -cne 'evidence_declaration_invalid') { throw 'declared_step_graph_invalid' }
    }
    $location = Get-EvidenceLocation -PlanFullPath $resolved
    $locationKind = 'git'
    if ((Test-Field $checkpoint 'location_kind') -and ($checkpoint.location_kind -ceq 'directory')) { $locationKind = 'directory' }

    $dependencyFailure = Get-PlanDependencyFailure -PlanText $text -PlanFullPath $resolved -Location $location
    if ($null -ne $dependencyFailure) {
        $denialDependency = [string]$dependencyFailure.Dependency
        throw ([string]$dependencyFailure.Reason)
    }

    if ($locationKind -ceq 'directory') {
        $baselineText = [string]$checkpoint.baseline_evidence
        $baselineSeparator = $baselineText.IndexOf('/')
        $baselineFailure = Get-EvidenceFailure -Step $baselineText.Substring(0, $baselineSeparator) -Name $baselineText.Substring($baselineSeparator + 1) -Location $location -Blocks @($parsed.Blocks) -Kind 'baseline'
        if ($null -ne $baselineFailure) {
            $denialEvidence = [string]$baselineFailure.Evidence
            throw ([string]$baselineFailure.Reason)
        }
    }

    if ($Resume -and ($locationKind -ceq 'git')) {
        if (-not (Test-Field $checkpoint 'branch') -or $checkpoint.branch -cne $CurrentBranch) { throw 'branch_mismatch' }
        if (-not (Test-Field $checkpoint 'head') -or $checkpoint.head -cne $CurrentHead) { throw 'head_mismatch' }
    }

    $steps = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    $dependencies = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    $stepOrder = [System.Collections.Generic.List[string]]::new()
    foreach ($block in @($parsed.Blocks | Where-Object { $_.Type -ceq 'STEP' })) {
        $step = $block.Json
        $stepId = [string]$block.Id
        if (-not (Test-Field $step 'id') -or $step.id -cne $stepId -or -not (Test-Field $step 'status')) { throw 'step_block_invalid_shape' }
        $stepDependencies = [System.Collections.Generic.List[string]]::new()
        if (Test-Field $step 'depends_on') {
            if ($step.depends_on -isnot [System.Array]) { throw 'step_block_invalid_shape' }
            foreach ($dependency in @($step.depends_on)) {
                if ($dependency -isnot [string]) { throw 'step_block_invalid_shape' }
                $stepDependencies.Add($dependency)
            }
        }
        $steps[$stepId] = $step
        $dependencies[$stepId] = $stepDependencies
        $stepOrder.Add($stepId)
    }
    if ($steps.Count -eq 0) { throw 'step_blocks_missing' }
    # The plan prose is normative; depends_on in operational blocks is only a
    # checked copy. Never use that copy to release a step at selection time.
    $declaredById = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    foreach ($declaredStep in $declaredSteps) {
        $declaredById[[string]$declaredStep.Id] = $declaredStep
    }
    if ($declaredById.Count -ne $steps.Count) { throw 'declared_step_graph_invalid' }
    foreach ($id in $stepOrder) {
        if (-not $declaredById.ContainsKey($id)) { throw 'declared_step_graph_invalid' }
        $declaredDependencies = @($declaredById[$id].DependsOn)
        $operationalDependencies = @($dependencies[$id])
        if ((Test-Field $steps[$id] 'depends_on') -and (($declaredDependencies.Count -ne $operationalDependencies.Count) -or
            @($declaredDependencies | Where-Object { $operationalDependencies -cnotcontains $_ }).Count -gt 0 -or
            @($operationalDependencies | Where-Object { $declaredDependencies -cnotcontains $_ }).Count -gt 0)) {
            throw 'depends_on_mismatch'
        }
        $dependencies[$id] = [System.Collections.Generic.List[string]]::new()
        foreach ($dependencyId in $declaredDependencies) { $dependencies[$id].Add([string]$dependencyId) }
    }
    if ((Test-Field $checkpoint 'active_step') -and -not [string]::IsNullOrWhiteSpace([string]$checkpoint.active_step)) {
        $activeId = [string]$checkpoint.active_step
        if (-not $steps.ContainsKey($activeId)) { throw 'checkpoint_active_step_missing' }
        if ($steps[$activeId].status -ceq 'IN_PROGRESS') {
            if ($locationKind -ceq 'git') {
                $orphanBaselineFailure = Get-OrphanBaselineFailure -StepId $activeId -Checkpoint $checkpoint -Location $location -Blocks @($parsed.Blocks)
                if ($null -ne $orphanBaselineFailure) { $denialEvidence = [string]$orphanBaselineFailure.Evidence; throw ([string]$orphanBaselineFailure.Reason) }
            }
            throw 'orphaned_in_progress_reconcile_required'
        }
        throw 'checkpoint_active_step_inconsistent'
    }
    foreach ($id in $stepOrder) {
        $step = $steps[$id]
        if ($step.status -ceq 'BLOCKED') { throw 'blocked_step_requires_resolution' }
        if ($step.status -ceq 'IN_PROGRESS') {
            if ($locationKind -ceq 'git') {
                $orphanBaselineFailure = Get-OrphanBaselineFailure -StepId $id -Checkpoint $checkpoint -Location $location -Blocks @($parsed.Blocks)
                if ($null -ne $orphanBaselineFailure) { $denialEvidence = [string]$orphanBaselineFailure.Evidence; throw ([string]$orphanBaselineFailure.Reason) }
            }
            throw 'orphaned_in_progress_reconcile_required'
        }
        foreach ($dependency in $dependencies[$id]) {
            if (-not $steps.ContainsKey($dependency) -or $dependency -ceq $id) { throw 'dependency_invalid' }
            if ($steps[$dependency].status -ceq 'COMPLETED') {
                $predecessor = $steps[$dependency]
                if (-not (Test-Field $predecessor 'acceptance_evidence') -or
                    -not (Test-AcceptanceEvidence -Value $predecessor.acceptance_evidence)) { throw 'dependency_evidence_missing' }
                $requiredValidation = [string]$declaredById[$dependency].Validation
                $validationPassed = $false
                $validationResults = @()
                if (Test-Field $predecessor 'validation_results') { $validationResults = @($predecessor.validation_results) }
                foreach ($validation in $validationResults) {
                    if ((Test-Field $validation 'command') -and (Test-Field $validation 'result') -and
                        ([string]$validation.command).Trim() -ieq $requiredValidation.Trim() -and
                        ([string]$validation.result).Trim() -imatch '^(pass|passed|success|succeeded)$' -and
                        ((-not (Test-Field $validation 'exit_code')) -or [int]$validation.exit_code -eq 0)) {
                        $validationPassed = $true
                        break
                    }
                }
                if (-not $validationPassed) { throw 'dependency_validation_missing' }
            }
        }
    }
    $eligibleId = ''
    foreach ($id in $stepOrder) {
        $candidate = $steps[$id]
        if ($candidate.status -cne 'PENDING') { continue }
        $dependenciesReady = $true
        foreach ($dependency in $dependencies[$id]) {
            if ($steps[$dependency].status -cne 'COMPLETED') { $dependenciesReady = $false; break }
        }
        if ($dependenciesReady) { $eligibleId = $id; break }
    }
    if ([string]::IsNullOrWhiteSpace($eligibleId)) { throw 'no_eligible_step' }
    if ($Cadence -eq 'step_by_step' -and -not $StepAuthorization) { throw 'step_authorization_required' }
    if ($Cadence -eq 'continuous' -and -not $ContinuousAuthorization) { throw 'continuous_authorization_required' }
    $authorizationKind = 'continuous'
    if ($Cadence -ceq 'step_by_step') { $authorizationKind = 'step' }
    Assert-ExecutionAuthorization -Progress $progress -ExpectedKind $authorizationKind -PlanIdentity $planIdentity -StepId $eligibleId

    $candidateNeeds = @()
    $candidateStartLine = 0
    $candidateEndLine = 0
    for ($declaredIndex = 0; $declaredIndex -lt $declaredSteps.Count; $declaredIndex++) {
        if ([string]$declaredSteps[$declaredIndex].Id -ceq $eligibleId) {
            $candidateNeeds = @($declaredSteps[$declaredIndex].Needs)
            $candidateStartLine = [int]$declaredSteps[$declaredIndex].Line
            $candidateEndLine = [int]::MaxValue
            if ($declaredIndex + 1 -lt $declaredSteps.Count) { $candidateEndLine = [int]$declaredSteps[$declaredIndex + 1].Line }
        }
    }
    foreach ($declaredError in @($declared.Errors)) {
        $errorLine = [int]$declaredError.line
        if (([string]$declaredError.code -ceq 'evidence_declaration_invalid') -and ($errorLine -ge $candidateStartLine) -and ($errorLine -lt $candidateEndLine)) {
            $denialEvidence = $eligibleId
            throw 'evidence_ref_invalid'
        }
    }
    foreach ($need in $candidateNeeds) {
        $needFailure = Get-EvidenceFailure -Step ([string]$need.Step) -Name ([string]$need.Name) -Location $location -Blocks @($parsed.Blocks) -Kind 'evidence'
        if ($null -ne $needFailure) {
            $denialEvidence = [string]$needFailure.Evidence
            throw ([string]$needFailure.Reason)
        }
    }

    $decision = New-Decision $true 'next_step_eligible' $eligibleId
    if ($AsLibrary) { return [pscustomobject]@{ ExitCode = 0; Result = $decision } }
    return $decision | ConvertTo-Json -Compress
}
catch {
    $reason = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($reason)) { $reason = 'execution_state_invalid' }
    $decision = New-Decision $false $reason ''
    if ($grammarCodes.Count -gt 0) {
        $decision | Add-Member -NotePropertyName errors -NotePropertyValue $grammarCodes
    }
    if ($denialEvidence.Length -gt 0) {
        $decision | Add-Member -NotePropertyName evidence -NotePropertyValue $denialEvidence
    }
    if ($denialDependency.Length -gt 0) {
        $decision | Add-Member -NotePropertyName dependency -NotePropertyValue $denialDependency
    }
    if ($AsLibrary) { return [pscustomobject]@{ ExitCode = 1; Result = $decision } }
    $decision | ConvertTo-Json -Compress
    exit 1
}
