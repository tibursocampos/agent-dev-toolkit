#Requires -Version 5.1
# Structural validator for the adt-delivery-* skills, their shared contract files and SCENARIOS.md.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$skillsRoot = Join-Path $repoRoot 'core/skills'
$adtSharedRoot = Join-Path $skillsRoot '_shared/adt-delivery'
$scenarioPath = Join-Path $adtSharedRoot 'SCENARIOS.md'
$catalogPath = Join-Path $skillsRoot '_shared/skills-catalog/CATALOG.md'
$liveStagePath = Join-Path $skillsRoot '_shared/sdd-artifacts/LIVE-STAGE-TABLE.md'
$ordinal = [System.StringComparison]::Ordinal; $tick = [string][char]96; $script:failureCount = 0

# Per-skill table: Cap is the Caveman cap that skill must declare.
$stages = @(@{ Id = 'adt-delivery-flow'; Cap = 'Lite' }, @{ Id = 'adt-delivery-refine'; Cap = 'Lite' },
    @{ Id = 'adt-delivery-plan'; Cap = 'Lite' }, @{ Id = 'adt-delivery-implement'; Cap = 'Full' })
$stageIds = @($stages | ForEach-Object { $_.Id })
$reusedSkillIds = @('run-tests', 'code-review')
$sharedFileNames = @('STORAGE-FEATURE.md', 'PLAN-LIFECYCLE.md', 'PLAN-TEMPLATE.md', 'TRIAGE.md', 'DISPLAY.md', 'HANDOFF.md', 'SCENARIOS.md')
$removedConceptPatterns = @('\bsha-?256\b', '\bdigest\b', '\bhash\b', 'PLAN-GUIDE')
$citePattern = '\{\{TOOLKIT_ROOT\}\}/skills/([^\s\x60"''()|]+)'
$templatePrefix = '{{TOOLKIT_ROOT}}/skills/'; $scenarioHeader = '| ID | Area | Scenario | Expected | Check | Rule source | Anchor | Status |'

# Shared-file token checks: each literal must appear in the file's plain text.
$sharedContentChecks = @(
    @{ Test = 'Should_ContainOutcomeNames_When_HANDOFFRead'; File = 'HANDOFF.md'; Literals = @('done', 'blocked', 'failed', 'open_question') }
    @{ Test = 'Should_ListStageHeadings_When_DISPLAYRead'; File = 'DISPLAY.md'; Literals = @($stageIds | ForEach-Object { "### $_" }) }
    @{ Test = 'Should_ListSixFlags_When_TRIAGERead'; File = 'TRIAGE.md'; Literals = @('needs_api', 'needs_domain', 'needs_database', 'needs_frontend', 'needs_security', 'needs_devops') }
    @{ Test = 'Should_HaveTemplateSections_When_PLANTEMPLATERead'; File = 'PLAN-TEMPLATE.md'; Literals = @('## Normative content', '## Operational record') }
    @{ Test = 'Should_HaveApprovalStates_When_PLANLIFECYCLERead'; File = 'PLAN-LIFECYCLE.md'; Literals = @('Approval: pending | approved') }
)
# Scenario matrix: report bucket -> test name.
$scenarioTests = [ordered]@{
    Parse = 'Should_ParseScenarioTable_When_SCENARIOSRead'; Id = 'Should_HaveUniqueIds_When_ScenarioRowsRead'
    Check = 'Should_UseKnownCheckValues_When_ScenarioRowsRead'; Rule = 'Should_ResolveRuleSource_When_ScenarioRowRead'
    Anchor = 'Should_FindAnchor_When_ScenarioRowRead'; Status = 'Should_RecordStatusProperly_When_ScenarioRowRead'
}

function Write-Pass([string] $TestName) { Write-Host ('{0}: PASS' -f $TestName) }
function Write-Fail([string] $TestName, [string] $Reason) { $script:failureCount++; Write-Host ('{0}: FAIL - {1}' -f $TestName, $Reason) }
function Complete-Test([string] $TestName, [AllowNull()][AllowEmptyCollection()][string[]] $Problems) {
    $list = @($Problems | Where-Object { $_ })
    if ($list.Count -eq 0) { Write-Pass $TestName } else { foreach ($problem in $list) { Write-Fail $TestName $problem } }
}

function Get-RelativePath([string] $FullPath) { $FullPath.Substring($repoRoot.Length).TrimStart('\', '/').Replace('\', '/') }
function Get-FileLines([string] $Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return , ([System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) }
    return , ([string[]]@())
}
function Get-FileText([string] $Path) { if (Test-Path -LiteralPath $Path -PathType Leaf) { [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) } else { '' } }
function Get-MarkdownFiles([string] $Directory, [switch] $Recurse) {
    if (Test-Path -LiteralPath $Directory -PathType Container) { Get-ChildItem -LiteralPath $Directory -File -Filter '*.md' -Recurse:$Recurse }
}
function Get-CleanCell([AllowNull()][string] $Value) { if ($null -eq $Value) { '' } else { $Value.Trim([char[]]@(' ', [char]9, [char]96)) } }
function Get-PlainText([AllowNull()][string] $Text) { if ($null -eq $Text) { '' } else { [regex]::Replace($Text.Replace($tick, ''), '\s+', ' ') } }

# Body under an exact heading line, or $null when the heading is absent.
function Get-Section([AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines, [string] $Heading) {
    $level = ([regex]::Match($Heading, '^#+')).Value.Length
    $start = [Array]::IndexOf(@($Lines | ForEach-Object { $_.TrimEnd() }), $Heading)
    if ($start -lt 0) { return $null }
    $body = @()
    for ($j = $start + 1; $j -lt $Lines.Count -and -not [regex]::IsMatch($Lines[$j], "^#{1,$level}\s"); $j++) { $body += $Lines[$j] }
    [string]::Join("`n", $body)
}

# Emits one problem per literal missing from Text.
function Get-MissingLiterals([AllowEmptyString()][string] $Text, [string[]] $Literals, [string] $Rel, [string] $Context = 'missing', [switch] $IgnoreCase) {
    $comparison = if ($IgnoreCase) { [System.StringComparison]::OrdinalIgnoreCase } else { $ordinal }
    foreach ($literal in $Literals) { if ($Text.IndexOf($literal, $comparison) -lt 0) { "${Rel}: $Context '$literal'" } }
}

# Emits one problem per heading that is missing or appears out of order.
function Test-OrderedHeadings([string] $Rel, [string[]] $Headings, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines) {
    $cursor = -1
    foreach ($heading in $Headings) {
        $found = -1
        for ($i = $cursor + 1; $i -lt $Lines.Count -and $found -lt 0; $i++) { if ($Lines[$i].StartsWith($heading, $ordinal)) { $found = $i } }
        if ($found -lt 0) { "${Rel}: heading '$heading' missing or out of order" } else { $cursor = $found }
    }
}

# Emits "Rel:line: Message" for every line matching Pattern (case-insensitive).
function Get-LineProblems([string] $Rel, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines, [string] $Pattern, [string] $Message) {
    for ($i = 0; $i -lt $Lines.Count; $i++) { if ([regex]::IsMatch($Lines[$i], $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) { "${Rel}:$($i + 1): $Message" } }
}

function Get-FrontmatterProblems([string] $Id, [string] $Rel, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines) {
    if ($Lines.Count -lt 2 -or $Lines[0].TrimEnd() -ne '---') { "${Rel}: line 1 must be '---'" }
    $fmEnd = -1
    for ($i = 1; $i -lt $Lines.Count -and $fmEnd -lt 0; $i++) { if ($Lines[$i].TrimEnd() -eq '---') { $fmEnd = $i } }
    if ($fmEnd -lt 0) { "${Rel}: closing '---' missing"; $fmEnd = $Lines.Count }
    $nameIdx = -1; $descIdx = -1
    for ($i = 1; $i -lt $fmEnd; $i++) { if ($nameIdx -lt 0 -and $Lines[$i].StartsWith('name:', $ordinal)) { $nameIdx = $i }; if ($descIdx -lt 0 -and $Lines[$i].StartsWith('description:', $ordinal)) { $descIdx = $i } }
    if ($nameIdx -lt 0) { "${Rel}: 'name:' missing from frontmatter" }
    elseif ($Lines[$nameIdx].Substring(5).Trim() -ne $Id) { "${Rel}: name '$($Lines[$nameIdx].Substring(5).Trim())' must equal folder '$Id'" }
    if ($descIdx -lt 0) { "${Rel}: 'description:' missing from frontmatter"; return }
    $value = $Lines[$descIdx].Substring($Lines[$descIdx].IndexOf(':') + 1).Trim()
    if ($value.Length -eq 0) { "${Rel}: description is empty" }
    if ($value.StartsWith('|', $ordinal) -or $value.StartsWith('>', $ordinal)) { "${Rel}: description must be a one-line plain scalar, not a block" }
    if ($descIdx + 1 -lt $fmEnd -and [regex]::IsMatch($Lines[$descIdx + 1], '^\s')) { "${Rel}: description continues on an indented line; it must be one line" }
    if (-not $value.Contains($Id)) { "${Rel}: description must contain the skill id '$Id'" }
    if ($value.Length -gt 1024) { "${Rel}: description is $($value.Length) chars; limit is 1024" }
    if ($value.Contains(': ')) { "${Rel}: description value contains ': ' after the key colon" }
    if ($value.Contains(' #')) { "${Rel}: description value contains ' #' after the key colon" }
}

function Get-GatePointerProblems([string] $Rel, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines) {
    Get-MissingLiterals -Text ($Lines -join "`n") -Literals @('Read `_shared/skill-boilerplate.md` first.', 'ADT exceptions to the Classic gates') -Rel $Rel
}

function Get-SkeletonProblems([string] $Id, [string] $Rel, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines) {
    $skeleton = @('## STOP - Read before ANY tool call', "# Skill: $Id", '## Trigger', '## Outcome', '## Terminal outcomes',
        '## Flow contract: reads, writes, where, when', '## Lazy-load (only when needed)', '## Process',
        '### Step -1b - Caveman Mode', '## Must not', '## Handoff')
    Test-OrderedHeadings -Rel $Rel -Headings $skeleton -Lines $Lines
}

function Get-CavemanProblems([string] $Rel, [string] $Expected, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines) {
    $found = $null
    foreach ($line in $Lines) { $m = [regex]::Match($line, '^### Step -1b - Caveman Mode \((Lite|Full) cap\)'); if ($m.Success) { $found = $m.Groups[1].Value; break } }
    if ($null -eq $found) { "${Rel}: heading '### Step -1b - Caveman Mode (X cap)' missing" }
    elseif ($found -cne $Expected) { "${Rel}: Caveman cap is $found; expected $Expected" }
}

function Get-CommandPlaybookProblems([string] $Id, [string] $Rel, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines, [AllowEmptyCollection()][AllowEmptyString()][string[]] $CommandLines, [string] $CommandRel) {
    $suffix = "$Id/references/command.md"
    $lazy = Get-Section -Lines $Lines -Heading '## Lazy-load (only when needed)'
    $cells = @(); if ($null -ne $lazy) { $cells = @([regex]::Split($lazy, "`n") | Where-Object { $_.Trim().StartsWith('|', $ordinal) } | ForEach-Object { [regex]::Split($_, '\|') }) }
    if ($null -eq $lazy) { "${Rel}: '## Lazy-load (only when needed)' section missing" }
    elseif (@($cells | Where-Object { $_.Trim().Replace($tick, '').EndsWith($suffix, $ordinal) }).Count -eq 0) { "${Rel}: Lazy-load table has no row whose path ends with '$suffix'" }
    if ($CommandLines.Count -eq 0) { "${CommandRel}: file missing or empty"; return }
    if (-not ($CommandLines | Where-Object { $_.Trim() -eq '| Step | Action | Lazy section / contract |' })) { "${CommandRel}: header row '| Step | Action | Lazy section / contract |' missing" }
    $stage = Get-Section -Lines $CommandLines -Heading '## Stage table'
    if ($null -eq $stage) { "${CommandRel}: '## Stage table' section missing" }
    elseif (-not $stage.Contains('DISPLAY.md')) { "${CommandRel}: '## Stage table' section does not mention DISPLAY.md" }
}

function Get-TerminalProblems([string] $Rel, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines) {
    $section = Get-Section -Lines $Lines -Heading '## Terminal outcomes'
    if ($null -eq $section) { "${Rel}: '## Terminal outcomes' section missing"; return }
    $plain = Get-PlainText $section
    if (-not $plain.Contains('HANDOFF.md')) { "${Rel}: '## Terminal outcomes' does not mention HANDOFF.md" }
    foreach ($name in @('done', 'blocked', 'failed', 'open_question')) { if (-not [regex]::IsMatch($plain, "\b$name\b")) { "${Rel}: '## Terminal outcomes' does not mention '$name'" } }
}

function Get-AntiPatternProblems([string] $Rel, [AllowEmptyCollection()][AllowEmptyString()][string[]] $Lines) {
    $section = Get-Section -Lines $Lines -Heading '## Must not'
    if ($null -eq $section) { "${Rel}: '## Must not' section missing"; return }
    Get-MissingLiterals -Text (Get-PlainText $section) -Literals @('Fall back from global to local storage', 'Use cold reviewers', 'Write the chat progress table into PLAN.md') -Rel $Rel -Context "'## Must not' lacks the phrase" -IgnoreCase
}

function Get-CitePathProblems {
    $files = @()
    foreach ($id in $stageIds) {
        $skillDir = Join-Path $skillsRoot $id
        $files += Join-Path $skillDir 'SKILL.md'
        $files += @(Get-MarkdownFiles -Directory (Join-Path $skillDir 'references') | ForEach-Object { $_.FullName })
    }
    $files += @(Get-MarkdownFiles -Directory $adtSharedRoot -Recurse | ForEach-Object { $_.FullName })
    foreach ($file in $files) {
        $rel = Get-RelativePath $file
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { "${rel}: file missing"; continue }
        $fileLines = Get-FileLines $file
        for ($i = 0; $i -lt $fileLines.Count; $i++) {
            foreach ($match in [regex]::Matches($fileLines[$i], $citePattern)) {
                $rest = ($match.Groups[1].Value -split '#')[0].TrimEnd('.', ',', ';', ':', '/')
                if ($rest.Length -eq 0 -or $rest.IndexOfAny([char[]]@('<', '*', ' ')) -ge 0) { continue }
                if (-not (Test-Path -LiteralPath (Join-Path $skillsRoot $rest))) { "${rel}:$($i + 1): cited path missing: core/skills/$rest" }
            }
        }
    }
}

function Get-RemovedConceptProblems {
    $roots = @($stageIds | ForEach-Object { Join-Path $skillsRoot $_ }) + @($adtSharedRoot)
    foreach ($root in $roots) {
        foreach ($file in (Get-MarkdownFiles -Directory $root -Recurse)) {
            $rel = Get-RelativePath $file.FullName
            $lines = Get-FileLines $file.FullName
            foreach ($pattern in $removedConceptPatterns) { Get-LineProblems -Rel $rel -Lines $lines -Pattern $pattern -Message "matches removed concept /$pattern/" }
        }
    }
}

function Get-ReusedSkillProblems {
    foreach ($id in $reusedSkillIds) {
        $dir = Join-Path $skillsRoot $id
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { "core/skills/${id}: folder missing"; continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $dir -Recurse -File)) {
            Get-LineProblems -Rel (Get-RelativePath $file.FullName) -Lines (Get-FileLines $file.FullName) -Pattern 'adt-delivery' -Message 'mentions adt-delivery'
        }
    }
}

function Get-ResolutionProblems {
    $file = Join-Path $skillsRoot 'code-review/references/sdd-resolution.md'
    $rel = Get-RelativePath $file
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { "${rel}: file missing"; return }
    Get-MissingLiterals -Text (Get-FileText $file) -Literals @('features/*/PLAN.md') -Rel $rel
    Get-LineProblems -Rel $rel -Lines (Get-FileLines $file) -Pattern '\b(adt|delivery)\b' -Message 'contains an adt or delivery word'
}

function Get-DiscoverProblems {
    $catalogRel = Get-RelativePath $catalogPath
    $liveRel = Get-RelativePath $liveStagePath
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) { "${catalogRel}: file missing" } else { Get-MissingLiterals -Text (Get-FileText $catalogPath) -Literals @($stageIds | ForEach-Object { "$tick$_$tick" }) -Rel $catalogRel }
    $liveLines = Get-FileLines $liveStagePath
    if (-not (Test-Path -LiteralPath $liveStagePath -PathType Leaf)) { "${liveRel}: file missing" }
    elseif ($liveLines.Count -lt 3) { "${liveRel}: fewer than 3 lines; line 3 cannot be checked" }
    else { Get-MissingLiterals -Text $liveLines[2] -Literals $stageIds -Rel "${liveRel}:3" }
}

# Parses SCENARIOS.md and buckets problems under each scenarioTests key.
function Get-ScenarioReport {
    $rel = Get-RelativePath $scenarioPath
    $report = @{}; foreach ($key in $scenarioTests.Keys) { $report[$key] = New-Object System.Collections.Generic.List[string] }
    $lines = Get-FileLines $scenarioPath
    $headerIdx = [Array]::IndexOf(@($lines | ForEach-Object { $_.Trim().StartsWith($scenarioHeader, $ordinal) }), $true)
    if (-not (Test-Path -LiteralPath $scenarioPath -PathType Leaf)) { $report.Parse.Add("${rel}: file missing") }
    elseif ($headerIdx -lt 0) { $report.Parse.Add("${rel}: scenario table header not found") }
    $rows = New-Object System.Collections.Generic.List[object]
    for ($i = $headerIdx + 1; $headerIdx -ge 0 -and $i -lt $lines.Count -and $lines[$i].Trim().StartsWith('|', $ordinal); $i++) {
        if ($lines[$i].Trim() -match '^\|[\s:|-]+\|$') { continue }
        $inner = $lines[$i].Trim().Substring(1) -replace '\|$', ''
        $rows.Add([pscustomobject]@{ Line = $i + 1; Cells = @([regex]::Split($inner, '\|') | ForEach-Object { $_.Trim() }) })
    }
    if ($rows.Count -lt 30) { $report.Parse.Add("${rel}: $($rows.Count) data rows found; need at least 30") }
    foreach ($row in $rows) { if ($row.Cells.Count -ne 8) { $report.Parse.Add("${rel}:$($row.Line): $($row.Cells.Count) cells; expected 8") } }

    $valid = @($rows | Where-Object { $_.Cells.Count -eq 8 })
    if ($valid.Count -eq 0) { foreach ($key in 'Id', 'Check', 'Rule', 'Anchor', 'Status') { $report[$key].Add("${rel}: no valid scenario rows to evaluate") }; return $report }

    $seen = @{}; $ruleCache = @{}
    foreach ($row in $valid) {
        $cells = @($row.Cells | ForEach-Object { Get-CleanCell $_ })
        $id = $cells[0]; $check = $cells[4]; $rule = $cells[5]; $anchor = $cells[6]; $status = $cells[7]
        $label = $id; if (-not $label) { $label = "line $($row.Line)" }
        if (-not $id) { $report.Id.Add("${label}: empty ID") }
        elseif ($seen.ContainsKey($id)) { $report.Id.Add("${label}: duplicate ID (first at line $($seen[$id]))") }
        else { $seen[$id] = $row.Line }
        if (($check -cne 'static') -and ($check -cne 'run')) { $report.Check.Add("${label}: check '$check' must be 'static' or 'run'") }

        if ($rule.StartsWith($templatePrefix, $ordinal)) { $rule = $rule.Substring($templatePrefix.Length) }
        $ruleExists = $false
        if (-not $rule) { $report.Rule.Add("${label}: rule source is empty") }
        else { $ruleExists = Test-Path -LiteralPath (Join-Path $skillsRoot $rule) -PathType Leaf; if (-not $ruleExists) { $report.Rule.Add("${label}: rule source not found: core/skills/$rule") } }

        if (-not $anchor) { $report.Anchor.Add("${label}: anchor is empty") }
        elseif ($ruleExists) {
            if (-not $ruleCache.ContainsKey($rule)) { $ruleCache[$rule] = Get-FileText (Join-Path $skillsRoot $rule) }
            if ($ruleCache[$rule].IndexOf($anchor, $ordinal) -lt 0) { $report.Anchor.Add("${label}: anchor not found literally in core/skills/${rule}: $anchor") }
        }
        if (-not [regex]::IsMatch($status, '^(not run$|pass \d{4}-\d{2}-\d{2} \S|fail \d{4}-\d{2}-\d{2} \S)')) { $report.Status.Add("${label}: status '$status' must be 'not run', 'pass YYYY-MM-DD <evidence>' or 'fail YYYY-MM-DD <evidence>'") }
    }
    $report
}

foreach ($stage in $stages) {
    $id = $stage.Id; $skillDir = Join-Path $skillsRoot $id
    $rel = Get-RelativePath (Join-Path $skillDir 'SKILL.md'); $lines = Get-FileLines (Join-Path $skillDir 'SKILL.md')
    $cmdRel = Get-RelativePath (Join-Path $skillDir 'references/command.md'); $cmdLines = Get-FileLines (Join-Path $skillDir 'references/command.md')
    Complete-Test "Should_HaveValidFrontmatter_When_$id" @(Get-FrontmatterProblems $id $rel $lines)
    Complete-Test "Should_ShowGatePointer_When_$id" @(Get-GatePointerProblems $rel $lines)
    Complete-Test "Should_KeepSkeletonOrder_When_$id" @(Get-SkeletonProblems $id $rel $lines)
    Complete-Test "Should_UseDeclaredCavemanCap_When_$id" @(Get-CavemanProblems $rel $stage.Cap $lines)
    Complete-Test "Should_ListCommandPlaybook_When_$id" @(Get-CommandPlaybookProblems $id $rel $lines $cmdLines $cmdRel)
    Complete-Test "Should_MapTerminalOutcomes_When_$id" @(Get-TerminalProblems $rel $lines)
    Complete-Test "Should_ForbidSharedAntiPatterns_When_$id" @(Get-AntiPatternProblems $rel $lines)
    $size = @()
    if ($lines.Count -gt 150) { $size += "${rel}: $($lines.Count) lines; limit is 150" }
    if ($cmdLines.Count -gt 40) { $size += "${cmdRel}: $($cmdLines.Count) lines; limit is 40" }
    Complete-Test "Should_StayRouterSized_When_$id" $size
}

Complete-Test 'Should_ResolveEveryCitedPath_When_ADTFilesRead' @(Get-CitePathProblems)
Complete-Test 'Should_HaveSharedFiles_When_ADTSharedRead' @($sharedFileNames | ForEach-Object { if (-not (Test-Path -LiteralPath (Join-Path $adtSharedRoot $_) -PathType Leaf)) { "core/skills/_shared/adt-delivery/${_}: missing" } })
foreach ($check in $sharedContentChecks) {
    $text = Get-PlainText (Get-FileText (Join-Path $adtSharedRoot $check.File))
    Complete-Test $check.Test @(Get-MissingLiterals -Text $text -Literals $check.Literals -Rel "core/skills/_shared/adt-delivery/$($check.File)")
}
Complete-Test 'Should_NotMentionRemovedConcepts_When_ADTFilesRead' @(Get-RemovedConceptProblems)
Complete-Test 'Should_LeaveReusedSkillsUntouched_When_ADTAdded' @(Get-ReusedSkillProblems)
Complete-Test 'Should_AcceptExplicitFeaturePlan_When_CodeReviewResolves' @(Get-ResolutionProblems)
Complete-Test 'Should_BeDiscoverable_When_CatalogRead' @(Get-DiscoverProblems)
$scenario = Get-ScenarioReport
foreach ($key in $scenarioTests.Keys) { Complete-Test $scenarioTests[$key] @($scenario[$key]) }

if ($script:failureCount -gt 0) {
    Write-Host ('Assert-AdtDeliveryFlow: FAILED with {0} problem(s)' -f $script:failureCount)
    exit 1
}
Write-Host 'Assert-AdtDeliveryFlow: ALL PASS'
exit 0
