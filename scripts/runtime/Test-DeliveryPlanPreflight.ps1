#Requires -Version 7.0
<#
.SYNOPSIS
  Read-only preflight for an integrated-delivery PLAN.
.DESCRIPTION
  Checks the declared steps, the STEP blocks, the declared dependency graph, and the APPROVAL
  identity. Optionally runs the review-record checker. Writes one compact JSON line to stdout and
  never edits the PLAN or the repository. Exit codes: 0 ok, 3 issues, 1 thrown error.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $RepoPath,
    [Parameter(Mandatory = $true)][string] $PlanPath,
    [string] $ExpectedIdentity = '',
    [string] $ReviewRecordPath = '',
    [string] $AliasCatalogPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_lib\DeliveryReviewRecord.ps1')

function New-PreflightIssue {
    param(
        [Parameter(Mandatory = $true)][string] $Code,
        [Parameter(Mandatory = $true)][string] $Message,
        [string] $Step = ''
    )

    return [pscustomobject]@{ code = $Code; message = $Message; step = $Step }
}

function Exit-WithPreflight {
    param(
        [Parameter(Mandatory = $true)][bool] $Ok,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Identity,
        [object[]] $Issues = @()
    )

    $report = [pscustomobject]@{ ok = $Ok; identity = $Identity; issues = [object[]]@($Issues) }
    [Console]::Out.WriteLine(($report | ConvertTo-Json -Compress -Depth 5))
    if ($Ok) { exit 0 }
    exit 3
}

function Find-DeliveryPlanCycle {
    param(
        [Parameter(Mandatory = $true)][string] $Node,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.Dictionary[string, object]] $Edges,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.Dictionary[string, int]] $State,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]] $Path
    )

    $State[$Node] = 1
    $Path.Add($Node)
    foreach ($next in @($Edges[$Node])) {
        if ($State.ContainsKey($next) -and ($State[$next] -eq 1)) {
            $start = $Path.IndexOf($next)
            return , ([string[]]$Path.GetRange($start, $Path.Count - $start).ToArray())
        }
        if (-not $State.ContainsKey($next)) {
            $found = Find-DeliveryPlanCycle -Node $next -Edges $Edges -State $State -Path $Path
            if ($null -ne $found) { return , $found }
        }
    }
    $State[$Node] = 2
    $Path.RemoveAt($Path.Count - 1)
    return $null
}

function Test-StringSetsEqual {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $Left,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $Right
    )

    foreach ($item in $Left) {
        if ($Right -cnotcontains $item) { return $false }
    }
    foreach ($item in $Right) {
        if ($Left -cnotcontains $item) { return $false }
    }
    return $true
}

function Get-DeliveryAncestorSet {
    param(
        [Parameter(Mandatory = $true)][string] $Node,
        [Parameter(Mandatory = $true)][System.Collections.Generic.Dictionary[string, object]] $Edges
    )

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $stack = [System.Collections.Generic.Stack[string]]::new()
    $stack.Push($Node)
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        if (-not $Edges.ContainsKey($current)) { continue }
        foreach ($next in @($Edges[$current])) {
            if ($seen.Add([string]$next)) { $stack.Push([string]$next) }
        }
    }
    return , $seen
}

function Get-StepDependsOnSet {
    param([AllowNull()][object] $Json)

    $property = Get-DeliveryExactProperty -Object $Json -Name 'depends_on'
    if ($null -eq $property) { return , ([string[]]@()) }
    return , ([string[]]@($property.Value | ForEach-Object { [string]$_ }))
}

function Read-PlanDependencyTarget {
    param(
        [Parameter(Mandatory = $true)][string] $RepoFull,
        [Parameter(Mandatory = $true)][string] $RelativePath
    )

    $full = $null
    try {
        $full = Get-SafeFullPath $RepoFull $RelativePath
        Assert-NoReparseAncestors $full $RepoFull
    }
    catch {
        return [pscustomobject]@{ State = 'invalid'; Text = $null; Message = $_.Exception.Message }
    }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        return [pscustomobject]@{ State = 'missing'; Text = $null; Message = '' }
    }
    $text = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    return [pscustomobject]@{ State = 'ok'; Text = $text; Message = '' }
}

function Get-PlanDependencyEdges {
    param(
        [Parameter(Mandatory = $true)][string] $Node,
        [Parameter(Mandatory = $true)][hashtable] $Context
    )

    if ($Node -ceq [string]$Context.PlanRelative) {
        $text = [string]$Context.PlanText
    }
    else {
        if (-not $Context.Cache.ContainsKey($Node)) {
            $target = Read-PlanDependencyTarget -RepoFull ([string]$Context.RepoFull) -RelativePath $Node
            if ($target.State -ceq 'ok') { $Context.Cache[$Node] = $target.Text } else { $Context.Cache[$Node] = $null }
        }
        $text = $Context.Cache[$Node]
    }
    if ($null -eq $text) { return , ([string[]]@()) }

    $declaration = Get-DeliveryPlanDependencies -Text ([string]$text)
    return , ([string[]]@($declaration.Dependencies | ForEach-Object { [string]$_.Path }))
}

function Find-PlanDependencyCycle {
    param(
        [Parameter(Mandatory = $true)][string] $Node,
        [Parameter(Mandatory = $true)][hashtable] $Context,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.Dictionary[string, int]] $State,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]] $Path
    )

    $State[$Node] = 1
    $Path.Add($Node)
    if (($Path.Count - 1) -gt 20) {
        return [pscustomobject]@{ Chain = [string[]]$Path.ToArray(); DepthExceeded = $true }
    }
    $edges = Get-PlanDependencyEdges -Node $Node -Context $Context
    foreach ($next in [string[]]$edges) {
        if ($State.ContainsKey($next) -and ($State[$next] -eq 1)) {
            $start = $Path.IndexOf($next)
            $chain = [string[]]($Path.GetRange($start, $Path.Count - $start).ToArray() + $next)
            return [pscustomobject]@{ Chain = $chain; DepthExceeded = $false }
        }
        if (-not $State.ContainsKey($next)) {
            $found = Find-PlanDependencyCycle -Node $next -Context $Context -State $State -Path $Path
            if ($null -ne $found) { return $found }
        }
    }
    $State[$Node] = 2
    $Path.RemoveAt($Path.Count - 1)
    return $null
}

function ConvertTo-ProcessArgument {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Value)

    if ($Value.Length -eq 0) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-ReviewChecker {
    param(
        [Parameter(Mandatory = $true)][string] $CheckerPath,
        [Parameter(Mandatory = $true)][string[]] $Arguments
    )

    $argList = @('-NoProfile', '-File', $CheckerPath) + $Arguments
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = (Get-Process -Id $PID).Path
    $startInfo.Arguments = (@($argList | ForEach-Object { ConvertTo-ProcessArgument ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Stdout = $stdoutTask.Result; Stderr = $stderrText }
}

try {
    if (($ExpectedIdentity.Length -gt 0) -and ($ExpectedIdentity -cnotmatch '^[0-9A-F]{64}$')) {
        throw 'ExpectedIdentity must be 64 uppercase hex characters.'
    }

    $repoFull = [System.IO.Path]::GetFullPath($RepoPath)
    $planRelative = $PlanPath.Replace('\', '/')
    $segments = $planRelative -split '/'
    if ($segments[0] -cne 'features') { throw 'PlanPath must be repository-relative under features/.' }
    $planFull = Get-SafeFullPath $repoFull $PlanPath
    Assert-NoReparseAncestors $planFull $repoFull

    $issues = [System.Collections.Generic.List[object]]::new()
    $identity = ''

    $canonicalShape = $planRelative -cmatch '^features/\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*/(?:US|TS)\d{2}/PLAN\.md$'
    $draftShape = $planRelative -cmatch '^features/\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*/scratch/delivery-review/[A-Za-z0-9][A-Za-z0-9._-]*\.md$'
    if ((-not $canonicalShape -and -not $draftShape) -or -not (Test-Path -LiteralPath $planFull -PathType Leaf)) {
        $issues.Add((New-PreflightIssue -Code 'plan_path_invalid' -Message 'PlanPath must be features/NNN-slug/(USnn|TSnn)/PLAN.md or features/NNN-slug/scratch/delivery-review/<name>.md, and name an existing file.'))
        Exit-WithPreflight -Ok $false -Identity '' -Issues $issues.ToArray()
    }

    $planText = [System.IO.File]::ReadAllText($planFull, [System.Text.Encoding]::UTF8)

    $declared = Get-DeliveryDeclaredSteps -Text $planText
    $declaredSteps = @($declared.Steps)
    foreach ($declaredError in @($declared.Errors)) {
        $owner = ''
        foreach ($declaredStep in $declaredSteps) {
            if ($declaredStep.Line -eq $declaredError.line) { $owner = $declaredStep.Id }
        }
        $issues.Add((New-PreflightIssue -Code ([string]$declaredError.code) -Message ([string]$declaredError.message) -Step $owner))
    }

    $declaredIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($declaredStep in $declaredSteps) { [void]$declaredIds.Add([string]$declaredStep.Id) }

    $edges = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    foreach ($declaredStep in $declaredSteps) {
        $targets = [System.Collections.Generic.List[string]]::new()
        foreach ($dependency in @($declaredStep.DependsOn)) {
            if ($dependency -ceq $declaredStep.Id) {
                $issues.Add((New-PreflightIssue -Code 'dependency_self' -Message ('Step {0} depends on itself.' -f $declaredStep.Id) -Step $declaredStep.Id))
                continue
            }
            if (-not $declaredIds.Contains($dependency)) {
                if ([string]::IsNullOrEmpty($dependency)) {
                    $unknownMessage = ('Step {0} lists an empty dependency id.' -f $declaredStep.Id)
                }
                else {
                    $unknownMessage = ('Step {0} depends on undeclared step {1}.' -f $declaredStep.Id, $dependency)
                }
                $issues.Add((New-PreflightIssue -Code 'dependency_unknown' -Message $unknownMessage -Step $declaredStep.Id))
                continue
            }
            if (-not $targets.Contains($dependency)) { $targets.Add($dependency) }
        }
        $edges[[string]$declaredStep.Id] = $targets
    }

    $visitState = [System.Collections.Generic.Dictionary[string, int]]::new([System.StringComparer]::Ordinal)
    $cycle = $null
    foreach ($declaredStep in $declaredSteps) {
        if ($visitState.ContainsKey([string]$declaredStep.Id)) { continue }
        $cycle = Find-DeliveryPlanCycle -Node ([string]$declaredStep.Id) -Edges $edges -State $visitState -Path ([System.Collections.Generic.List[string]]::new())
        if ($null -ne $cycle) { break }
    }
    if ($null -ne $cycle) {
        $cycleText = (@($cycle) + $cycle[0]) -join ' -> '
        $issues.Add((New-PreflightIssue -Code 'dependency_cycle' -Message ('Dependency cycle: {0}.' -f $cycleText) -Step $cycle[0]))
    }

    $evidenceNames = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    foreach ($declaredStep in $declaredSteps) {
        $evidenceNames[[string]$declaredStep.Id] = [string[]]@($declaredStep.Evidence)
    }
    foreach ($declaredStep in $declaredSteps) {
        $ownerId = [string]$declaredStep.Id
        foreach ($need in @($declaredStep.Needs)) {
            $sourceId = [string]$need.Step
            $needName = [string]$need.Name
            $reference = $sourceId + '/' + $needName
            if (-not $evidenceNames.ContainsKey($sourceId)) {
                $issues.Add((New-PreflightIssue -Code 'evidence_source_unknown' -Message ('Step {0} needs evidence {1} from undeclared step {2}.' -f $ownerId, $reference, $sourceId) -Step $ownerId))
                continue
            }
            if (@($evidenceNames[$sourceId]) -cnotcontains $needName) {
                $issues.Add((New-PreflightIssue -Code 'evidence_name_undeclared' -Message ('Step {0} needs evidence {1}, but step {2} declares no Evidence name {3}.' -f $ownerId, $reference, $sourceId, $needName) -Step $ownerId))
            }
            $isPredecessor = $false
            if ($sourceId -cne $ownerId) {
                $ancestors = Get-DeliveryAncestorSet -Node $ownerId -Edges $edges
                $isPredecessor = $ancestors.Contains($sourceId)
            }
            if (-not $isPredecessor) {
                $issues.Add((New-PreflightIssue -Code 'evidence_source_not_predecessor' -Message ('Step {0} needs evidence {1}, but step {2} is not a transitive predecessor of {0}.' -f $ownerId, $reference, $sourceId) -Step $ownerId))
            }
        }
    }

    $parsed = Read-DeliveryBlocks -Text $planText
    if (-not $parsed.Ok) {
        $grammarCodes = @($parsed.Errors | ForEach-Object { [string]$_.code } | Select-Object -Unique)
        $issues.Add((New-PreflightIssue -Code 'grammar_invalid' -Message ('DELIVERY grammar rejected the PLAN: {0}.' -f ($grammarCodes -join ', '))))
    }
    else {
        $identity = Get-DeliveryNormativeIdentity -Text $planText
        $declaredIdList = [string[]]@($declaredSteps | ForEach-Object { [string]$_.Id })

        foreach ($requirement in @(Test-DeliveryRequiredBlocks -Result $parsed -Kind PLAN -StepIds $declaredIdList)) {
            $issues.Add((New-PreflightIssue -Code ([string]$requirement.code) -Message ([string]$requirement.message)))
        }

        $stepJsonById = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
        $approvalJson = $null
        foreach ($block in @($parsed.Blocks)) {
            if ($block.Type -ceq 'STEP') { $stepJsonById[[string]$block.Id] = $block.Json }
            elseif ($block.Type -ceq 'APPROVAL') { $approvalJson = $block.Json }
        }

        foreach ($declaredStep in $declaredSteps) {
            if (-not $stepJsonById.ContainsKey([string]$declaredStep.Id)) { continue }
            $declaredSet = [string[]]@($declaredStep.DependsOn)
            $blockSet = Get-StepDependsOnSet -Json $stepJsonById[[string]$declaredStep.Id]
            if (-not (Test-StringSetsEqual -Left $declaredSet -Right $blockSet)) {
                $issues.Add((New-PreflightIssue -Code 'depends_on_mismatch' -Message ('Step {0} depends_on [{1}] differs from declared Depends on [{2}].' -f $declaredStep.Id, ($blockSet -join ', '), ($declaredSet -join ', ')) -Step ([string]$declaredStep.Id)))
            }
        }

        if ($null -ne $approvalJson) {
            $approvalState = Get-DeliveryExactProperty -Object $approvalJson -Name 'state'
            $approvalIdentity = Get-DeliveryExactProperty -Object $approvalJson -Name 'identity'
            if (($null -ne $approvalState) -and (([string]$approvalState.Value) -ceq 'approved') -and
                ($null -ne $approvalIdentity) -and (([string]$approvalIdentity.Value) -cne $identity)) {
                $issues.Add((New-PreflightIssue -Code 'approval_identity_stale' -Message 'APPROVAL identity does not match the recomputed normative identity.'))
            }
        }

        $checkpointJson = $null
        foreach ($block in @($parsed.Blocks)) {
            if ($block.Type -ceq 'CHECKPOINT') { $checkpointJson = $block.Json }
        }
        if ($null -ne $checkpointJson) {
            $locationKind = Get-DeliveryExactProperty -Object $checkpointJson -Name 'location_kind'
            $baseline = Get-DeliveryExactProperty -Object $checkpointJson -Name 'baseline_evidence'
            if (($null -ne $locationKind) -and ($locationKind.Value -is [string]) -and ($locationKind.Value -ceq 'directory') -and
                ($null -ne $baseline) -and ($baseline.Value -is [string]) -and ([string]$baseline.Value).Contains('/')) {
                $baselineText = [string]$baseline.Value
                $baselineSeparator = $baselineText.IndexOf('/')
                $baselineStep = $baselineText.Substring(0, $baselineSeparator)
                $baselineName = $baselineText.Substring($baselineSeparator + 1)
                if (-not $evidenceNames.ContainsKey($baselineStep) -or (@($evidenceNames[$baselineStep]) -cnotcontains $baselineName)) {
                    $issues.Add((New-PreflightIssue -Code 'baseline_reference_unknown' -Message ('CHECKPOINT baseline_evidence {0} names an undeclared step or Evidence name.' -f $baselineText) -Step $baselineStep))
                }
            }
        }

        if (($ExpectedIdentity.Length -gt 0) -and ($ExpectedIdentity -cne $identity)) {
            $issues.Add((New-PreflightIssue -Code 'identity_changed' -Message 'The recomputed normative identity differs from the expected identity.'))
        }
    }

    $dependencyDeclaration = Get-DeliveryPlanDependencies -Text $planText
    foreach ($dependencyError in @($dependencyDeclaration.Errors)) {
        $issues.Add((New-PreflightIssue -Code 'plan_dependency_invalid' -Message ('Line {0}: {1}' -f $dependencyError.line, $dependencyError.message)))
    }

    foreach ($dependency in @($dependencyDeclaration.Dependencies)) {
        $dependencyPath = [string]$dependency.Path
        if ($dependencyPath -ceq $planRelative) { continue }

        $target = Read-PlanDependencyTarget -RepoFull $repoFull -RelativePath $dependencyPath
        if ($target.State -ceq 'invalid') {
            $issues.Add((New-PreflightIssue -Code 'plan_dependency_invalid' -Message ('Dependency {0} is not a safe repository path: {1}' -f $dependencyPath, $target.Message)))
            continue
        }
        if ($target.State -ceq 'missing') {
            $issues.Add((New-PreflightIssue -Code 'plan_dependency_missing' -Message ('Dependency {0} does not exist.' -f $dependencyPath)))
            continue
        }

        $targetBlocks = Read-DeliveryBlocks -Text $target.Text
        if (-not $targetBlocks.Ok) {
            $issues.Add((New-PreflightIssue -Code 'plan_dependency_invalid' -Message ('Dependency {0} does not parse as DELIVERY grammar.' -f $dependencyPath)))
            continue
        }

        $targetIdentity = Get-DeliveryNormativeIdentity -Text $target.Text
        if ([string]$dependency.Identity -cne $targetIdentity) {
            $issues.Add((New-PreflightIssue -Code 'plan_dependency_identity_changed' -Message ('Dependency {0} declares identity {1}, but its current normative identity is {2}.' -f $dependencyPath, $dependency.Identity, $targetIdentity)))
        }

        $targetStepIds = @((Get-DeliveryDeclaredSteps -Text $target.Text).Steps | ForEach-Object { [string]$_.Id })
        foreach ($requiredStep in @($dependency.Steps)) {
            if ($targetStepIds -cnotcontains [string]$requiredStep) {
                $issues.Add((New-PreflightIssue -Code 'plan_dependency_step_unknown' -Message ('Dependency {0} requires step {1}, which the predecessor does not declare.' -f $dependencyPath, $requiredStep)))
            }
        }
    }

    $dependencyContext = @{ RepoFull = $repoFull; PlanRelative = $planRelative; PlanText = $planText; Cache = @{} }
    $dependencyCycle = Find-PlanDependencyCycle -Node $planRelative -Context $dependencyContext `
        -State ([System.Collections.Generic.Dictionary[string, int]]::new([System.StringComparer]::Ordinal)) `
        -Path ([System.Collections.Generic.List[string]]::new())
    if ($null -ne $dependencyCycle) {
        $chainText = (@($dependencyCycle.Chain) -join ' -> ')
        if ([bool]$dependencyCycle.DepthExceeded) {
            $issues.Add((New-PreflightIssue -Code 'plan_dependency_cycle' -Message ('Plan dependency chain exceeds the depth limit of 20: {0}.' -f $chainText)))
        }
        else {
            $issues.Add((New-PreflightIssue -Code 'plan_dependency_cycle' -Message ('Plan dependency cycle: {0}.' -f $chainText)))
        }
    }

    if ($ReviewRecordPath.Length -gt 0) {
        $checker = Join-Path $PSScriptRoot 'Test-DeliveryReviewRecord.ps1'
        $checkerArguments = @('-RepoPath', $RepoPath, '-TargetPath', $PlanPath, '-RecordPath', $ReviewRecordPath)
        if ($AliasCatalogPath.Length -gt 0) { $checkerArguments += @('-AliasCatalogPath', $AliasCatalogPath) }
        $run = Invoke-ReviewChecker -CheckerPath $checker -Arguments $checkerArguments
        $verdict = $null
        if ($run.ExitCode -ne 1) {
            try { $verdict = $run.Stdout.Trim() | ConvertFrom-Json } catch { $verdict = $null }
        }
        if (($null -eq $verdict) -or ($null -eq $verdict.PSObject.Properties['allowed'])) {
            $firstErrorLine = [regex]::Split($run.Stderr, '\r?\n') | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 1
            $checkerMessage = 'checker failed'
            if ($null -ne $firstErrorLine) { $checkerMessage = 'checker failed: ' + $firstErrorLine }
            $issues.Add((New-PreflightIssue -Code 'review_gate_blocked' -Message $checkerMessage))
        }
        elseif (-not [bool]$verdict.allowed) {
            $issues.Add((New-PreflightIssue -Code 'review_gate_blocked' -Message ('Review gate blocked: {0}.' -f [string]$verdict.reason)))
        }
    }

    Exit-WithPreflight -Ok ($issues.Count -eq 0) -Identity $identity -Issues $issues.ToArray()
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
