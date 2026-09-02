#Requires -Version 5.1
<#
.SYNOPSIS
  SPAWN-aligned Publish knobs (depth/threads/inherit) for adapter Publish-Agents.

.DESCRIPTION
  REQ-008 / CA8 / RNF-002: supply-chain knobs are only depth, threads, and model
  inherit. Caps match SPAWN.md (developer <=2, orchestrate <=4). Do not pin a
  child Task model slug different from the parent session (Axis B/C).
#>

$script:SpawnPublishKnob = @{
    DeveloperConcurrentCap   = 2
    OrchestrateConcurrentCap = 4
    ModelInheritToken        = 'inherit'
    HonestyRelativePath      = 'adapters/_shared/spawn-publish-honesty.md'
    CoreAgentsRelativeDir    = 'core/agents'
    DivergentModelProbeSlugs = @('luna', 'terra', 'gpt-5.6-luna-medium', 'gpt-5.6-terra-medium')
    TomlModelKeyPattern      = '(?m)^\s*model\s*='
    MarkdownModelInheritPattern = '(?m)^model:\s*inherit\s*$'
    MarkdownModelAnyPattern  = '(?m)^model:\s*(.+)\s*$'
    CodexHonestyCommentPrefix = '# toolkit.spawn.'
}

function Get-SpawnPublishCaps {
    [CmdletBinding()]
    param()
    return [PSCustomObject]@{
        DeveloperConcurrentCap   = [int]$script:SpawnPublishKnob.DeveloperConcurrentCap
        OrchestrateConcurrentCap = [int]$script:SpawnPublishKnob.OrchestrateConcurrentCap
        ModelInheritToken        = [string]$script:SpawnPublishKnob.ModelInheritToken
    }
}

function Get-SpawnPublishHonestyComments {
    [CmdletBinding()]
    param()
    $caps = Get-SpawnPublishCaps
    $prefix = $script:SpawnPublishKnob.CodexHonestyCommentPrefix
    return @(
        ($prefix + 'developer_threads = {0}  # SPAWN *-developer concurrent cap' -f $caps.DeveloperConcurrentCap)
        ($prefix + 'orchestrate_threads = {0}  # SPAWN orchestrate-* concurrent cap' -f $caps.OrchestrateConcurrentCap)
        ($prefix + 'model = inherit  # omit model key -> parent session (Axis B); do not pin child!=parent')
    )
}

function Get-AgentFrontmatterModelValue {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $MarkdownText)

    if ($MarkdownText -match '(?s)\A---\r?\n(.*?)\r?\n---') {
        $fm = $Matches[1]
        if ($fm -match $script:SpawnPublishKnob.MarkdownModelAnyPattern) {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return ''
}

function Test-SpawnModelIsInheritOrEmpty {
    [CmdletBinding()]
    param([Parameter()][string] $ModelValue)

    if ([string]::IsNullOrWhiteSpace($ModelValue)) {
        return $true
    }
    return ($ModelValue.Trim().ToLowerInvariant() -eq $script:SpawnPublishKnob.ModelInheritToken)
}

function Test-SpawnModelMatchesDivergentProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $NormalizedModel,
        [Parameter(Mandatory = $true)][string] $Probe
    )

    $probeNorm = $Probe.ToLowerInvariant()
    if ($NormalizedModel -eq $probeNorm) {
        return $true
    }

    # Hyphen/dot/underscore-bounded token only (avoid luna matching lunaria, terra matching territory).
    $pattern = '(^|[^a-z0-9])' + [regex]::Escape($probeNorm) + '([^a-z0-9]|$)'
    return [bool]($NormalizedModel -match $pattern)
}

function Assert-SpawnModelNotDivergentPin {
    [CmdletBinding()]
    param(
        [Parameter()][string] $ModelValue,
        [Parameter(Mandatory = $true)][string] $SourcePath
    )

    if (Test-SpawnModelIsInheritOrEmpty -ModelValue $ModelValue) {
        return
    }

    $normalized = $ModelValue.Trim().ToLowerInvariant()
    foreach ($probe in @($script:SpawnPublishKnob.DivergentModelProbeSlugs)) {
        if (Test-SpawnModelMatchesDivergentProbe -NormalizedModel $normalized -Probe $probe) {
            throw ("Publish spawn knobs forbid divergent model pin '{0}' in {1}. Use model: inherit (omit on Codex TOML)." -f $ModelValue, $SourcePath)
        }
    }

    throw ("Publish spawn knobs require model inherit/omit; got '{0}' in {1}." -f $ModelValue, $SourcePath)
}

function Assert-MarkdownAgentsSpawnKnobs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $AgentsRoot,
        [Parameter()][string] $Label = 'agents'
    )

    if (-not (Test-Path -LiteralPath $AgentsRoot)) {
        throw ("Spawn knobs agents root missing ({0}): {1}" -f $Label, $AgentsRoot)
    }

    $caps = Get-SpawnPublishCaps
    if ($caps.DeveloperConcurrentCap -gt 2 -or $caps.OrchestrateConcurrentCap -gt 4) {
        throw ("Spawn caps exceed SPAWN.md (developer<=2 orchestrate<=4); got {0}/{1}" -f $caps.DeveloperConcurrentCap, $caps.OrchestrateConcurrentCap)
    }

    $files = @(Get-ChildItem -LiteralPath $AgentsRoot -File -Filter '*.md' -ErrorAction Stop)
    if ($files.Count -eq 0) {
        throw ("Spawn knobs: no .md agents under {0}" -f $AgentsRoot)
    }

    foreach ($file in $files) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        $model = Get-AgentFrontmatterModelValue -MarkdownText $text
        Assert-SpawnModelNotDivergentPin -ModelValue $model -SourcePath $file.FullName
        if (-not (Test-SpawnModelIsInheritOrEmpty -ModelValue $model)) {
            throw ("Spawn knobs: {0} must use model: inherit" -f $file.Name)
        }
        if ($text -notmatch $script:SpawnPublishKnob.MarkdownModelInheritPattern) {
            throw ("Spawn knobs: {0} missing 'model: inherit' frontmatter" -f $file.Name)
        }
    }
}

function Assert-CodexTomlSpawnKnobs {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $TomlText)

    $caps = Get-SpawnPublishCaps
    $prefix = $script:SpawnPublishKnob.CodexHonestyCommentPrefix
    $devNeedle = $prefix + ('developer_threads = {0}' -f $caps.DeveloperConcurrentCap)
    $orchNeedle = $prefix + ('orchestrate_threads = {0}' -f $caps.OrchestrateConcurrentCap)
    $inheritNeedle = $prefix + 'model = inherit'

    if ($TomlText -notmatch [regex]::Escape($devNeedle)) {
        throw 'Codex TOML missing SPAWN developer_threads honesty comment'
    }
    if ($TomlText -notmatch [regex]::Escape($orchNeedle)) {
        throw 'Codex TOML missing SPAWN orchestrate_threads honesty comment'
    }
    if ($TomlText -notmatch [regex]::Escape($inheritNeedle)) {
        throw 'Codex TOML missing SPAWN model inherit honesty comment'
    }
    if ($TomlText -match $script:SpawnPublishKnob.TomlModelKeyPattern) {
        throw 'Codex TOML must omit model key (parent inherit); do not pin child!=parent'
    }
}
