#Requires -Version 5.1
<#
.SYNOPSIS
  Registry-driven adapter validation checks (publish layout, keyed uninstall, path/secrets guard).

.DESCRIPTION
  Every adapter is published at most once per process (sync-agent.ps1 in a child pwsh, into
  <work>/<id>/install). Mutation scenarios (uninstall) run on a Copy-Item of that publish.
  Checks are declared by adapters/registry.json (capabilities, publishSurface, publish,
  pathGuard) and scripts/runtime/uninstall-artifacts.json; a few ids add small extra hooks
  for behaviour that is genuinely distinct (codex marketplace, cursor/zcode fail-closed JSON,
  cursor published contract projection).

  Dot-source this file, then call Invoke-AdapterChecks.
#>


$script:AdtFailures = New-Object System.Collections.Generic.List[string]
$script:AdtPublishCache = @{}
$script:AdtPublishLog = New-Object System.Collections.Generic.List[object]

function Write-AdtCheck {
    param(
        [Parameter(Mandatory = $true)][string] $Adapter,
        [Parameter(Mandatory = $true)][string] $Check,
        [Parameter(Mandatory = $true)][bool] $Ok,
        [string] $Reason = ''
    )

    if ($Ok) {
        Write-Host ('{0}/{1}: PASS' -f $Adapter, $Check)
    }
    else {
        Write-Host ('{0}/{1}: FAIL - {2}' -f $Adapter, $Check, $Reason) -ForegroundColor Red
        $script:AdtFailures.Add(('{0}/{1}: {2}' -f $Adapter, $Check, $Reason))
    }
}

function Get-AdtRepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}

function ConvertTo-AdtRelative {
    param([string] $Root, [string] $Path)
    return $Path.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')
}

function Get-AdtTreeFiles {
    param([Parameter(Mandatory = $true)][string] $Root)

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($file in [System.IO.Directory]::EnumerateFiles($rootFull, '*', [System.IO.SearchOption]::AllDirectories)) {
        $list.Add((ConvertTo-AdtRelative -Root $rootFull -Path $file))
    }
    return $list.ToArray()
}

function Get-AdtRegistryAgents {
    param([string] $Adapter = 'all')

    $registry = Get-Content -LiteralPath (Join-Path (Get-AdtRepoRoot) 'adapters/registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $agents = @($registry.agents)
    if ([string]::IsNullOrWhiteSpace($Adapter) -or $Adapter -eq 'all') { return $agents }
    $selected = @($agents | Where-Object { $_.id -eq $Adapter })
    if ($selected.Count -eq 0) { throw "Unknown adapter '$Adapter'. Known: $(($agents | ForEach-Object { $_.id }) -join ', ')" }
    return $selected
}

function Get-AdtProperty {
    param($Object, [string] $Name, $Default = $null)
    if ($null -ne $Object -and @($Object.PSObject.Properties | ForEach-Object { $_.Name }) -contains $Name) { return $Object.$Name }
    return $Default
}

# --- publish (once per adapter per process) ---------------------------------------------

function Get-AdtPublish {
    param(
        [Parameter(Mandatory = $true)] $Agent,
        [Parameter(Mandatory = $true)][string] $WorkRoot
    )

    $id = [string]$Agent.id
    if ($script:AdtPublishCache.ContainsKey($id)) { return $script:AdtPublishCache[$id] }

    $repoRoot = Get-AdtRepoRoot
    $installRoot = Join-Path $WorkRoot ($id + '/install')
    $spec = Get-AdtProperty $Agent 'publish' $null
    $syncArgs = @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts/sync-agent.ps1'), '-Agent', $id, '-InstallRoot', $installRoot)
    $userScope = [bool](Get-AdtProperty $spec 'userScope' $false)
    $mode = [string](Get-AdtProperty $spec 'mode' '')
    if ($userScope) { $syncArgs += '-UserScope' }
    if (-not [string]::IsNullOrWhiteSpace($mode)) { $syncArgs += @('-Mode', $mode) }

    $runner = (Get-Process -Id $PID).Path
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $output = @(& $runner @syncArgs 2>&1)
    $exit = $LASTEXITCODE
    $watch.Stop()
    $script:AdtPublishLog.Add([pscustomobject]@{ Adapter = $id; Seconds = [math]::Round($watch.Elapsed.TotalSeconds, 1); Exit = $exit })
    Write-Host ('PUBLISH {0}: exit={1} {2}s' -f $id, $exit, [math]::Round($watch.Elapsed.TotalSeconds, 1))
    if ($exit -ne 0) {
        throw ("sync-agent failed for adapter '{0}' (exit {1}): {2}" -f $id, $exit, ($output -join [Environment]::NewLine))
    }

    $record = [pscustomobject]@{
        Id          = $id
        InstallRoot = $installRoot
        UserScope   = $userScope
        Mode        = $mode
        Files       = @(Get-AdtTreeFiles -Root $installRoot)
    }
    $script:AdtPublishCache[$id] = $record
    return $record
}

function New-AdtPublishCopy {
    param(
        [Parameter(Mandatory = $true)] $Publish,
        [Parameter(Mandatory = $true)][string] $Destination
    )

    $source = $Publish.InstallRoot
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Copy-Item -Path (Join-Path $source '*') -Destination $Destination -Recurse -Force
    foreach ($hidden in @(Get-ChildItem -LiteralPath $source -Force | Where-Object { $_.Name.StartsWith('.') })) {
        Copy-Item -LiteralPath $hidden.FullName -Destination (Join-Path $Destination $hidden.Name) -Recurse -Force
    }

    # Published configs embed the absolute install root; retarget them. Markdown is never
    # rewritten (router ownership hashes depend on the exact published bytes).
    $pairs = @(
        , @($source, $Destination)
        , @($source.Replace('\', '/'), $Destination.Replace('\', '/'))
        , @($source.Replace('/', '\'), $Destination.Replace('/', '\'))
    )
    $textExtensions = @('.json', '.yaml', '.yml', '.toml')
    foreach ($file in [System.IO.Directory]::EnumerateFiles($Destination, '*', [System.IO.SearchOption]::AllDirectories)) {
        if ($textExtensions -notcontains [System.IO.Path]::GetExtension($file).ToLowerInvariant()) { continue }
        $text = [System.IO.File]::ReadAllText($file)
        $changed = $false
        foreach ($pair in $pairs) {
            if ($text.IndexOf($pair[0], [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $text = [regex]::Replace($text, [regex]::Escape($pair[0]), $pair[1].Replace('$', '$$'), 'IgnoreCase')
                $changed = $true
            }
        }
        if ($changed) { [System.IO.File]::WriteAllText($file, $text, (New-Object System.Text.UTF8Encoding $false)) }
    }
    return $Destination
}

# --- publish layout ---------------------------------------------------------------------

function Get-AdtManagedSkillRoots {
    param($Publish)
    return @($Publish.Files | Where-Object { $_ -eq '.toolkit-managed-skills.json' -or $_.EndsWith('/.toolkit-managed-skills.json') } |
            ForEach-Object { if ($_ -eq '.toolkit-managed-skills.json') { '' } else { $_.Substring(0, $_.Length - '/.toolkit-managed-skills.json'.Length) } })
}

function Test-AdapterPublishLayout {
    param(
        [Parameter(Mandatory = $true)] $Agent,
        [Parameter(Mandatory = $true)] $Publish
    )

    $id = [string]$Agent.id
    $repoRoot = Get-AdtRepoRoot
    $caps = $Agent.capabilities
    $root = $Publish.InstallRoot
    $files = $Publish.Files
    $nonSkill = @($files | Where-Object { $_ -notmatch '(^|/)skills/' })

    # skills: every managed skills root carries all core skills
    $coreSkillDirs = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'core/skills') -Directory -Force | Select-Object -ExpandProperty Name)
    $coreSkillIds = @($coreSkillDirs | Where-Object { Test-Path -LiteralPath (Join-Path $repoRoot "core/skills/$_/SKILL.md") })
    $skillRoots = @(Get-AdtManagedSkillRoots -Publish $Publish)
    Write-AdtCheck $id 'skills-root-present' ($skillRoots.Count -ge 1) 'no .toolkit-managed-skills.json marker found in the publish'
    foreach ($skillRoot in $skillRoots) {
        $prefix = if ($skillRoot -eq '') { '' } else { $skillRoot + '/' }
        $missing = @($coreSkillIds | Where-Object { $files -notcontains ($prefix + $_ + '/SKILL.md') })
        $label = if ($skillRoot -eq '') { '.' } else { $skillRoot }
        Write-AdtCheck $id ('skills-equal:' + $label) ($missing.Count -eq 0) ('missing skills: ' + ($missing -join ', '))
        $manifest = Get-Content -LiteralPath (Join-Path $root ($prefix + '.toolkit-managed-skills.json')) -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($manifest.PSObject.Properties.Name -contains 'skills') {
            $names = @($manifest.skills | ForEach-Object { if ($_ -is [string]) { $_ } else { [string]$_.id } })
            $absent = @($coreSkillIds | Where-Object { $names -notcontains $_ })
            Write-AdtCheck $id ('skills-manifest:' + $label) ($absent.Count -eq 0) ('manifest lacks: ' + ($absent -join ', '))
        }
    }

    # router with the orchestrator section
    if ($caps.router -eq $true) {
        $routerNames = @('AGENTS.md', 'CLAUDE.md', 'GEMINI.md')
        $routers = @($nonSkill | Where-Object { $parts = $_.Split('/'); $parts.Count -le 3 -and $routerNames -contains $parts[-1] })
        Write-AdtCheck $id 'router-present' ($routers.Count -ge 1) 'no AGENTS.md/CLAUDE.md/GEMINI.md published'
        foreach ($whole in @($Agent.publishSurface.wholeFileRouter)) {
            Write-AdtCheck $id ('router-file:' + $whole) ($files -contains $whole) 'whole-file router missing at install root'
        }
        $hasOrchestrator = $false
        foreach ($router in $routers) {
            if ([System.IO.File]::ReadAllText((Join-Path $root $router)) -match 'Parallel specialists|ORCHESTRATOR CHARTER') { $hasOrchestrator = $true; break }
        }
        Write-AdtCheck $id 'router-orchestrator-section' $hasOrchestrator 'published router lacks the orchestrator section'
    }

    # rules / instructions (hosts without a rules surface carry the orchestrator text in the router)
    if ($caps.rules -eq $true) {
        $rule = @($nonSkill | Where-Object { $_ -match '(?i)(^|/)orchestrator-session[^/]*$' })
        Write-AdtCheck $id 'rules-orchestrator-session' ($rule.Count -ge 1) 'orchestrator-session rule/instruction file missing'
        $guardrails = @($nonSkill | Where-Object { $_ -match '(?i)(^|/)guardrails[^/]*$' })
        Write-AdtCheck $id 'rules-guardrails' ($guardrails.Count -ge 1) 'guardrails rule file missing'
    }

    # hooks
    if ($caps.hooks -eq $true) {
        $hookFiles = @($nonSkill | Where-Object { $_ -match '(?i)(^|/)(hooks|agent-hooks|plugins)/|(^|/)hooks\.json$' })
        Write-AdtCheck $id 'hooks-present' ($hookFiles.Count -ge 1) 'no hook or plugin assets published'
    }

    # agents roster
    if ($caps.agents -eq $true) {
        $agentFiles = @($nonSkill | Where-Object { $_ -match '(^|/)\.?agents/[^/]+$' } | ForEach-Object { $_.Split('/')[-1] })
        $coreAgents = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'core/agents') -File -Filter '*.md' -Force | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) })
        $absentAgents = @($coreAgents | Where-Object { $name = $_; -not (@($agentFiles | Where-Object { $_ -eq $name -or $_.StartsWith($name + '.') }).Count -gt 0) })
        Write-AdtCheck $id 'agents-roster' ($absentAgents.Count -eq 0) ('agents not published: ' + ($absentAgents -join ', '))
    }

    # plugin surface
    if ($caps.plugin -eq $true) {
        $pluginFiles = @($files | Where-Object { $_ -match '(?i)plugin' })
        Write-AdtCheck $id 'plugin-present' ($pluginFiles.Count -ge 1) 'plugin capability declared but no plugin assets published'
    }

    # runtime-script allowlist per toolkit root
    $manifest = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/runtime/runtime-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $roots = New-Object System.Collections.Generic.List[string]
    $roots.Add('')
    foreach ($extra in @($manifest.additionalToolkitRoots | Where-Object { $_.adapter -eq $id })) {
        $when = [string]$extra.when
        if ($when -eq 'always' -or $when -eq 'project' -or ($when -eq 'user-scope' -and $Publish.UserScope)) { $roots.Add([string]$extra.path) }
    }
    foreach ($toolkitRoot in $roots) {
        $runtimePrefix = $(if ($toolkitRoot -eq '') { '' } else { $toolkitRoot + '/' }) + $manifest.destinationRoot + '/'
        $absent = @($manifest.files | Where-Object { $files -notcontains ($runtimePrefix + $_.destination) } | ForEach-Object { $_.destination })
        $leaked = @($files | Where-Object { $_.StartsWith($runtimePrefix) -and $_ -match '(^|/)(adapters|core)/|(^|/)sync-agent\.ps1$' })
        $label = if ($toolkitRoot -eq '') { '.' } else { $toolkitRoot }
        Write-AdtCheck $id ('runtime-scripts:' + $label) ($absent.Count -eq 0 -and $leaked.Count -eq 0) ('missing=' + ($absent -join ',') + ' leaked=' + ($leaked -join ','))
    }

    $takesRoot = (Get-Command Get-InstallRoots).Parameters.ContainsKey('InstallRoot')
    $rootsInfo = $null
    try { $rootsInfo = if ($takesRoot) { Get-InstallRoots -AgentId $id -InstallRoot $root } else { Get-InstallRoots -AgentId $id } } catch { $rootsInfo = $null }
    $rootsOk = $null -ne $rootsInfo -and (Get-AdtProperty $rootsInfo 'Success' $false) -eq $true
    Write-AdtCheck $id 'install-roots-map' $rootsOk 'Get-InstallRoots must report Success'
    $probe = Join-Path ([Environment]::GetFolderPath('UserProfile')) ('.adt-userhome-probe-' + $id)
    $threwResolve = $false
    try { $null = Resolve-InstallRoot -InstallRoot $probe } catch { $threwResolve = ($_.Exception.Message -match 'AllowUserHome') }
    $threwAdapter = -not $takesRoot
    if ($takesRoot) { try { $null = Get-InstallRoots -AgentId $id -InstallRoot $probe } catch { $threwAdapter = ($_.Exception.Message -match 'AllowUserHome') } }
    Write-AdtCheck $id 'userhome-guard' ($threwResolve -and $threwAdapter -and -not (Test-Path -LiteralPath $probe)) "resolve=$threwResolve adapter=$threwAdapter; USERPROFILE install roots must require -AllowUserHome"

    # per-id extras
    switch ($id) {
        'codex' { Test-CodexMarketplaceLayout -Publish $Publish }
        'cursor' { Test-CursorPublishedContracts -Publish $Publish }
    }
}

function Test-CodexMarketplaceLayout {
    param([Parameter(Mandatory = $true)] $Publish)

    $root = $Publish.InstallRoot
    $marketplacePath = Join-Path $root '.agents/plugins/marketplace.json'
    $ok = Test-Path -LiteralPath $marketplacePath
    Write-AdtCheck 'codex' 'marketplace-present' $ok 'marketplace.json missing'
    if (-not $ok) { return }
    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
    $entry = @($marketplace.plugins | Where-Object { [string]$_.name -eq 'agent-dev-toolkit' }) | Select-Object -First 1
    Write-AdtCheck 'codex' 'marketplace-entry' ($null -ne $entry -and -not [string]::IsNullOrWhiteSpace([string]$marketplace.name) -and
        $null -ne $marketplace.interface -and -not [string]::IsNullOrWhiteSpace([string]$marketplace.interface.displayName)) 'marketplace needs name, interface.displayName and the agent-dev-toolkit entry'
    if ($null -eq $entry) { return }
    $source = if ($entry.source -is [string]) { [string]$entry.source } else { [string]$entry.source.path }
    Write-AdtCheck 'codex' 'marketplace-source-path' ($source -eq './plugin' -and $null -ne $entry.policy -and -not [string]::IsNullOrWhiteSpace([string]$entry.policy.installation) -and -not [string]::IsNullOrWhiteSpace([string]$entry.category)) "source.path must be ./plugin with policy.installation and category (got '$source')"
    $pluginJson = Join-Path $root 'plugin/.codex-plugin/plugin.json'
    $pluginOk = (Test-Path -LiteralPath $pluginJson) -and ([string]((Get-Content -LiteralPath $pluginJson -Raw | ConvertFrom-Json).name) -eq 'agent-dev-toolkit')
    Write-AdtCheck 'codex' 'plugin-manifest' $pluginOk 'plugin/.codex-plugin/plugin.json missing or wrong name'
    $mirrors = @('plugin/skills', 'skills', '.agents/skills') | Where-Object { $Publish.UserScope -or $_ -ne '.agents/skills' }
    foreach ($mirror in $mirrors) {
        $present = @('help-skills/SKILL.md', '_shared/skills-catalog/CATALOG.md', '_shared/skills-catalog/OPERATOR.md') | Where-Object { $Publish.Files -notcontains ($mirror + '/' + $_) }
        Write-AdtCheck 'codex' ('help-catalog:' + $mirror) (@($present).Count -eq 0) ('missing: ' + (@($present) -join ', '))
    }
}

function Test-CursorPublishedContracts {
    param([Parameter(Mandatory = $true)] $Publish)

    $repoRoot = Get-AdtRepoRoot
    $root = $Publish.InstallRoot.Replace('\', '/')
    $names = @('PIPELINE.md', 'STORAGE.md', 'STORAGE-RESOLUTION.md', 'SESSION.md', 'MEMORY-BANK.md')
    $bad = New-Object System.Collections.Generic.List[string]
    foreach ($name in $names) {
        $source = Join-Path $repoRoot ('core/skills/_shared/sdd-artifacts/' + $name)
        $published = Join-Path $Publish.InstallRoot ('skills/_shared/sdd-artifacts/' + $name)
        if (-not (Test-Path -LiteralPath $published -PathType Leaf)) { $bad.Add("$name missing"); continue }
        $expected = [System.IO.File]::ReadAllText($source).Replace('{{TOOLKIT_ROOT}}', $root).Replace('{{SDD_ROOT}}', $root + '/sdd').Replace('{{GUARDRAILS_PATH}}', $root + '/rules/guardrails.mdc')
        $actual = [System.IO.File]::ReadAllText($published)
        if ($expected.Replace("`r`n", "`n") -ne $actual.Replace("`r`n", "`n")) { $bad.Add("$name differs from the source projection") }
    }
    Write-AdtCheck 'cursor' 'published-sdd-contracts' ($bad.Count -eq 0) ($bad -join '; ')
}

# --- keyed uninstall --------------------------------------------------------------------

function Invoke-AdtUninstall {
    param([string] $AdapterId, [string] $Mode, [string] $InstallRoot, [switch] $WhatIf)
    $callArgs = @{ InstallRoot = $InstallRoot }
    if (-not [string]::IsNullOrWhiteSpace($Mode)) { $callArgs['Mode'] = $Mode }
    if ($WhatIf) { $callArgs['WhatIf'] = $true }
    return Uninstall-Toolkit @callArgs
}

function Test-AdapterKeyedUninstall {
    param(
        [Parameter(Mandatory = $true)] $Agent,
        [Parameter(Mandatory = $true)] $Publish,
        [Parameter(Mandatory = $true)][string] $WorkRoot
    )

    $id = [string]$Agent.id
    $repoRoot = Get-AdtRepoRoot
    $artifacts = (Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/runtime/uninstall-artifacts.json') -Raw -Encoding UTF8 | ConvertFrom-Json).adapters |
        Where-Object { $_.id -eq $id } | Select-Object -First 1
    Write-AdtCheck $id 'uninstall-artifacts-declared' ($null -ne $artifacts) 'adapter missing from scripts/runtime/uninstall-artifacts.json'
    if ($null -eq $artifacts) { return }

    $mut = Join-Path $WorkRoot ($id + '/uninstall')
    $null = New-AdtPublishCopy -Publish $Publish -Destination $mut
    $mode = [string]$Publish.Mode
    $before = $Publish.Files
    $utf8 = New-Object System.Text.UTF8Encoding $false

    # sentinels the uninstaller must never touch
    $sentinels = New-Object System.Collections.Generic.List[string]
    function Add-Sentinel([string] $Relative) {
        $full = Join-Path $mut $Relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
        [System.IO.File]::WriteAllText($full, "operator-sentinel`n", $utf8)
        $sentinels.Add($Relative)
    }
    Add-Sentinel 'operator-sentinel.txt'
    $topDirs = @($before | Where-Object { $_.Contains('/') } | ForEach-Object { $_.Split('/')[0] } | Sort-Object -Unique | Where-Object { $_ -notin @('scripts', 'sdd') })
    foreach ($dir in $topDirs) { Add-Sentinel ($dir + '/operator-sentinel.txt') }
    if ($before | Where-Object { $_.StartsWith('sdd/') }) {
        New-Item -ItemType Directory -Path (Join-Path $mut 'sdd/sessions') -Force | Out-Null
        Add-Sentinel 'sdd/sessions/operator-session-probe.json'
    }

    # alien skill beside toolkit skills + stale names-only managed skill folder
    $staleDirs = New-Object System.Collections.Generic.List[string]
    foreach ($skillRoot in @(Get-AdtManagedSkillRoots -Publish $Publish)) {
        $prefix = if ($skillRoot -eq '') { '' } else { $skillRoot + '/' }
        Add-Sentinel ($prefix + 'operator-alien-skill/SKILL.md')
        $staleRel = $prefix + 'retired-toolkit-skill'
        New-Item -ItemType Directory -Path (Join-Path $mut $staleRel) -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $mut ($staleRel + '/SKILL.md')), "legacy managed skill`n", $utf8)
        $staleDirs.Add($staleRel)
        $manifestPath = Join-Path $mut ($prefix + '.toolkit-managed-skills.json')
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        if ($manifest.PSObject.Properties.Name -contains 'skills') {
            $manifest.skills = @($manifest.skills) + @('retired-toolkit-skill')
            [System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8), $utf8)
        }
    }

    # shared JSON config: an operator key must survive the reverse merge
    $overlay = $null
    foreach ($shared in @($artifacts.sharedConfig)) {
        $candidate = ([string]$shared).Split(':')[0].Trim()
        if ($candidate.EndsWith('.json') -and $candidate -notlike 'plugin/*' -and $before -contains $candidate) { $overlay = $candidate; break }
    }
    if ($null -ne $overlay) {
        $overlayPath = Join-Path $mut $overlay
        $payload = Get-Content -LiteralPath $overlayPath -Raw | ConvertFrom-Json
        $payload | Add-Member -NotePropertyName 'operatorCustomKey' -NotePropertyValue 'must-survive-merge' -Force
        [System.IO.File]::WriteAllText($overlayPath, ($payload | ConvertTo-Json -Depth 20), $utf8)
    }

    # mixed router: operator text appended to a whole-file router must never be lost
    $routerNote = 'operator router note must survive'
    $mixedRouter = $null

    if ($id -eq 'cursor' -or $id -eq 'zcode') { Test-AdtInvalidJsonFailsClosed -AdapterId $id -Mode $mode -Mut $mut -Publish $Publish }

    # WhatIf must not mutate
    $countBefore = 0
    $whatIf = @(Invoke-AdtUninstall -AdapterId $id -Mode $mode -InstallRoot $mut -WhatIf)[-1]
    $countAfterWhatIf = 0
    $whatIfOk = $null -ne $whatIf -and $whatIf.Success -eq $true -and $whatIf.WhatIf -eq $true -and $countBefore -eq $countAfterWhatIf
    Write-AdtCheck $id 'uninstall-whatif' $whatIfOk "WhatIf must succeed without changing the tree (before=$countBefore after=$countAfterWhatIf)"

    $result = @(Invoke-AdtUninstall -AdapterId $id -Mode $mode -InstallRoot $mut)[-1]
    $resultOk = $null -ne $result -and $result.Implemented -eq $true -and $result.Success -eq $true -and $result.ExitCode -eq 0 -and $result.RemovedCount -ge 1 -and $result.KeyedOnly -eq $true -and $result.WholesaleWipe -ne $true
    $resultText = if ($null -eq $result) { 'null' } else { [string]$result.Message }
    $fields = if ($null -eq $result) { "" } else { "impl=$($result.Implemented) ok=$($result.Success) status=$($result.Status) exit=$($result.ExitCode) removed=$($result.RemovedCount) keyed=$($result.KeyedOnly) wipe=$($result.WholesaleWipe) incomplete=$(@($result.IncompletePaths).Count)" }
    Write-AdtCheck $id 'uninstall-result' $resultOk "unexpected uninstall result: $fields"

    $lost = @($sentinels | Where-Object { -not (Test-Path -LiteralPath (Join-Path $mut $_) -PathType Leaf) })
    Write-AdtCheck $id 'uninstall-keeps-unrelated' ($lost.Count -eq 0) ('sentinels removed: ' + ($lost -join ', '))
    Write-AdtCheck $id 'uninstall-keeps-install-root' (Test-Path -LiteralPath $mut) 'InstallRoot itself must not be wiped'

    $residual = @($staleDirs | Where-Object { Test-Path -LiteralPath (Join-Path $mut $_) })
    Write-AdtCheck $id 'uninstall-removes-stale-managed-skill' ($residual.Count -eq 0) ('stale managed skill folders remain: ' + ($residual -join ', '))

    $skillLeft = @($before | Where-Object { $_ -match '(^|/)skills/[^/]+/SKILL\.md$' -and (Test-Path -LiteralPath (Join-Path $mut $_)) })
    Write-AdtCheck $id 'uninstall-removes-toolkit-skills' ($skillLeft.Count -eq 0) ('toolkit skills remain: ' + (($skillLeft | Select-Object -First 5) -join ', '))

    $pruneRoots = @($artifacts.pruneRoots | ForEach-Object { ([string]$_).Trim() })
    $sharedPaths = @($artifacts.sharedConfig | ForEach-Object { ([string]$_).Split(':')[0].Trim() })
    $statePrefixes = @($artifacts.state | ForEach-Object { ([string]$_).Split(' ')[0] } | Where-Object { $_.EndsWith('/**') } | ForEach-Object { $_.Substring(0, $_.Length - 2) })
    $pruneLeft = New-Object System.Collections.Generic.List[string]
    foreach ($rel in $before) {
        if ($rel -match '(^|/)\.(gitkeep|toolkit-managed)') { continue }
        if ($sharedPaths -contains $rel) { continue }
        $underPrune = $false
        foreach ($prune in $pruneRoots) { if ($rel.StartsWith($prune + '/')) { $underPrune = $true; break } }
        if (-not $underPrune) { continue }
        $isState = $false
        foreach ($prefix in $statePrefixes) { if ($rel.StartsWith($prefix)) { $isState = $true; break } }
        if ($isState) { continue }
        if (Test-Path -LiteralPath (Join-Path $mut $rel)) { $pruneLeft.Add($rel) }
    }
    Write-AdtCheck $id 'uninstall-removes-published-files' ($pruneLeft.Count -eq 0) ('published files remain under prune roots: ' + (($pruneLeft | Select-Object -First 8) -join ', '))

    if ($null -ne $overlay) {
        $survived = $false
        $overlayPath = Join-Path $mut $overlay
        if (Test-Path -LiteralPath $overlayPath) {
            try { $survived = ((Get-Content -LiteralPath $overlayPath -Raw | ConvertFrom-Json).operatorCustomKey -eq 'must-survive-merge') } catch { $survived = $false }
        }
        Write-AdtCheck $id ('uninstall-reverse-merge:' + $overlay) $survived 'operator key lost from shared JSON config'
    }

    if ($null -ne $mixedRouter) {
        $routerPath = Join-Path $mut $mixedRouter
        $noteKept = (Test-Path -LiteralPath $routerPath) -and ([System.IO.File]::ReadAllText($routerPath).Contains($routerNote))
        Write-AdtCheck $id ('uninstall-mixed-router:' + $mixedRouter) $noteKept 'operator text appended to the router was lost'
    }

    $again = Invoke-AdtUninstall -AdapterId $id -Mode $mode -InstallRoot $mut
    Write-AdtCheck $id 'uninstall-idempotent' ($null -ne $again -and $again.Success -eq $true) 'second uninstall must stay successful'
    Remove-Item -LiteralPath $mut -Recurse -Force -ErrorAction SilentlyContinue
}

function Test-AdtInvalidJsonFailsClosed {
    param([string] $AdapterId, [string] $Mode, [string] $Mut, $Publish)

    $target = if ($AdapterId -eq 'cursor') { 'hooks.json' } else { 'hooks/hooks.json' }
    $path = Join-Path $Mut $target
    if (-not (Test-Path -LiteralPath $path)) {
        Write-AdtCheck $AdapterId 'uninstall-fails-closed-on-invalid-json' $false "$target missing from publish"
        return
    }
    $original = [System.IO.File]::ReadAllText($path)
    [System.IO.File]::WriteAllText($path, '{ "version": 1, "hooks": { invalid }', (New-Object System.Text.UTF8Encoding $false))
    $result = Invoke-AdtUninstall -AdapterId $AdapterId -Mode $Mode -InstallRoot $Mut
    $anyToolkitSkill = @($Publish.Files | Where-Object { $_ -match '(^|/)skills/[^/]+/SKILL\.md$' } | Select-Object -First 1)
    $stillThere = $anyToolkitSkill.Count -eq 1 -and (Test-Path -LiteralPath (Join-Path $Mut $anyToolkitSkill[0]))
    Write-AdtCheck $AdapterId 'uninstall-fails-closed-on-invalid-json' ($null -ne $result -and $result.Success -eq $false -and $result.ExitCode -ne 0 -and $stillThere) 'invalid shared JSON must fail the uninstall before any filesystem removal'
    [System.IO.File]::WriteAllText($path, $original, (New-Object System.Text.UTF8Encoding $false))
}

# --- path / secrets guard ---------------------------------------------------------------

function Test-AdtGuardDenied {
    param([int] $ExitCode, [string] $Output)
    return ($ExitCode -eq 2) -or ($Output -match '"(permissionDecision|decision)"\s*:\s*"deny"')
}

function Get-AdtGuardPayload {
    param([string] $Shape, [string] $Tool, [string] $Path, [string] $Content, [string] $Command, [string] $Cwd)

    if ($Shape -eq 'copilot') {
        $toolArgs = if ($Tool -eq 'bash') { @{ command = $Command } } else { @{ path = $Path; content = $Content } }
        return @{ hookEventName = 'preToolUse'; toolName = $Tool; toolArgs = ($toolArgs | ConvertTo-Json -Compress); cwd = $Cwd }
    }
    $toolInput = if ($Tool -eq 'Bash') { @{ command = $Command } } else { @{ path = $Path; file_path = $Path; content = $Content } }
    return @{ hook_event_name = 'PreToolUse'; tool_name = $Tool; tool_input = $toolInput; cwd = $Cwd }
}

function Test-AdapterPathGuard {
    param(
        [Parameter(Mandatory = $true)] $Agent,
        [Parameter(Mandatory = $true)] $Publish,
        [Parameter(Mandatory = $true)][string] $WorkRoot
    )

    $id = [string]$Agent.id
    $repoRoot = Get-AdtRepoRoot
    $guard = Get-AdtProperty $Agent 'pathGuard' $null
    Write-AdtCheck $id 'pathguard-declared' ($null -ne $guard) 'registry pathGuard entry missing'
    if ($null -eq $guard) { return }

    foreach ($asset in @(Get-AdtProperty $guard 'requiredAssets' @())) {
        Write-AdtCheck $id ('pathguard-asset:' + $asset) (Test-Path -LiteralPath (Join-Path $repoRoot $asset) -PathType Leaf) 'required guard/lifecycle asset missing'
    }
    foreach ($asset in @(Get-AdtProperty $guard 'forbiddenAssets' @())) {
        Write-AdtCheck $id ('pathguard-absent:' + $asset) (-not (Test-Path -LiteralPath (Join-Path $repoRoot $asset))) 'authorization asset must not be shipped for a host-authorized adapter'
    }
    $hooksConfig = [string](Get-AdtProperty $guard 'hooksConfig' '')
    if ((Get-AdtProperty $guard 'preToolUseEmpty' $false) -and $hooksConfig) {
        $config = Get-Content -LiteralPath (Join-Path $repoRoot $hooksConfig) -Raw -Encoding UTF8 | ConvertFrom-Json
        $handlers = foreach ($eventName in @('preToolUse', 'beforeShellExecution')) { if ($config.hooks.PSObject.Properties.Name -contains $eventName) { @($config.hooks.$eventName) } }
        Write-AdtCheck $id 'pathguard-no-veto-hook-registered' (@($handlers).Count -eq 0) 'host-owned authorization must not register pre-tool hooks'
    }

    $script = [string](Get-AdtProperty $guard 'script' '')
    if ($script -eq '') { return }
    $scriptPath = Join-Path $repoRoot $script
    Write-AdtCheck $id 'pathguard-script-present' (Test-Path -LiteralPath $scriptPath -PathType Leaf) "missing $script"
    if (-not (Test-Path -LiteralPath $scriptPath)) { return }

    $shape = [string](Get-AdtProperty $guard 'payload' 'snake')
    $workspace = Join-Path $WorkRoot ($id + '/guard-workspace')
    New-Item -ItemType Directory -Path (Join-Path $workspace 'src') -Force | Out-Null
    $secret = 'ghp_TESTNOTREAL_aaaaabbbbbcccccddddd'
    $writeTool = if ($shape -eq 'copilot') { 'write' } else { 'Write' }
    $shellTool = if ($shape -eq 'copilot') { 'bash' } else { 'Bash' }
    $cases = @(
        [pscustomobject]@{ Name = 'host-owns-forbidden-sdd-path'; Payload = (Get-AdtGuardPayload $shape $writeTool (Join-Path $workspace 'PRD/blocked.md') '# blocked' '' $workspace) }
        [pscustomobject]@{ Name = 'host-owns-secret-write-and-redacts'; Payload = (Get-AdtGuardPayload $shape $writeTool (Join-Path $workspace 'src/ok.cs') "const key = `"$secret`";" '' $workspace) }
        [pscustomobject]@{ Name = 'host-owns-secret-shell-and-redacts'; Payload = (Get-AdtGuardPayload $shape $shellTool '' '' "echo $secret > src/ok.txt" $workspace) }
    )
    foreach ($case in $cases) {
        $run = Invoke-PathSecretsGuardHook -HookScriptPath $scriptPath -Payload $case.Payload
        $denied = Test-AdtGuardDenied -ExitCode $run.ExitCode -Output $run.Output
        $leaked = $run.Output.IndexOf($secret, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        Write-AdtCheck $id ('pathguard:' + $case.Name) (-not $denied -and -not $leaked) ("hook vetoed host authorization or leaked the secret; exit={0} output={1}" -f $run.ExitCode, $run.Output.Trim())
    }

    if ([string](Get-AdtProperty $guard 'mode' 'host') -eq 'hook') {
        Test-AdtHookModeGuard -AdapterId $id -ScriptPath $scriptPath -Workspace $workspace -Secret $secret
    }
}

function Test-AdtHookModeGuard {
    param([string] $AdapterId, [string] $ScriptPath, [string] $Workspace, [string] $Secret)

    $repoRoot = Get-AdtRepoRoot
    $runner = (Get-Process -Id $PID).Path
    $decisionOf = { param($Run) if ($null -ne $Run.Payload -and $null -ne $Run.Payload.hookSpecificOutput) { [string]$Run.Payload.hookSpecificOutput.permissionDecision } else { '' } }

    $allow = @(
        @{ Name = 'allows-read-only-tool'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Read'; tool_input = @{ path = (Join-Path $Workspace 'src/known.cs') }; cwd = $Workspace }; Want = 'allow' }
        @{ Name = 'allows-mutating-tool-in-workspace'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path $Workspace 'src/known.cs'); content = 'class X {}' }; cwd = $Workspace }; Want = 'allow' }
        @{ Name = 'allows-apply-patch-forbidden-path'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'apply_patch'; tool_input = @{ command = "*** Add File: PRD/blocked.md`n+# blocked" }; cwd = $Workspace }; Want = 'allow' }
        @{ Name = 'allows-unknown-tool'; Payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'FutureCodexTool'; tool_input = @{}; cwd = $Workspace }; Want = 'allow' }
        @{ Name = 'denies-missing-hook-identity'; Payload = @{ tool_name = 'Write'; tool_input = @{ path = (Join-Path $Workspace 'src/missing.cs'); content = 'class X {}' }; cwd = $Workspace }; Want = 'deny' }
        @{ Name = 'denies-missing-shell-hook-identity'; Payload = @{ tool_name = 'Bash'; tool_input = @{ command = 'Set-Content -Path src\missing.cs -Value x' }; cwd = $Workspace }; Want = 'deny' }
        @{ Name = 'denies-invalid-hook-identity'; Payload = @{ hook_event_name = 'PostToolUse'; tool_name = 'Read'; tool_input = @{}; cwd = $Workspace }; Want = 'deny' }
    )
    foreach ($case in $allow) {
        $run = Invoke-PathSecretsGuardHook -HookScriptPath $ScriptPath -Payload $case.Payload
        $decision = & $decisionOf $run
        Write-AdtCheck $AdapterId ('pathguard-hook:' + $case.Name) ($decision -eq $case.Want) ("expected $($case.Want), got '$decision'; output=" + $run.Output.Trim())
    }
    foreach ($raw in @(@{ Name = 'denies-malformed-input'; Text = '{not-json' }, @{ Name = 'denies-empty-input'; Text = '' })) {
        $output = $raw.Text | & $runner -NoProfile -File $ScriptPath 2>&1 | Out-String
        $parsed = $null
        try { $parsed = $output.Trim() | ConvertFrom-Json -ErrorAction Stop } catch { $parsed = $null }
        $decision = if ($null -ne $parsed -and $null -ne $parsed.hookSpecificOutput) { [string]$parsed.hookSpecificOutput.permissionDecision } else { '' }
        Write-AdtCheck $AdapterId ('pathguard-hook:' + $raw.Name) ($decision -eq 'deny') ("raw input must be denied; output=" + $output.Trim())
    }

    # descendant reparse point escaping the workspace stays host-authorized
    $target = Join-Path (Split-Path -Parent $Workspace) 'reparse-target'
    $link = Join-Path $Workspace 'src/linked'
    try {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        $linkType = if ($env:OS -eq 'Windows_NT') { 'Junction' } else { 'SymbolicLink' }
        New-Item -ItemType $linkType -Path $link -Target $target | Out-Null
        $payload = @{ hook_event_name = 'PreToolUse'; tool_name = 'Write'; tool_input = @{ path = (Join-Path $link 'escape.cs'); content = 'class X {}' }; cwd = $Workspace }
        $run = Invoke-PathSecretsGuardHook -HookScriptPath $ScriptPath -Payload $payload
        Write-AdtCheck $AdapterId 'pathguard-hook:allows-escaping-reparse-path' ((& $decisionOf $run) -eq 'allow') ('output=' + $run.Output.Trim())
    }
    catch {
        Write-Host ('{0}/pathguard-hook:allows-escaping-reparse-path: SKIPPED - reparse point unavailable ({1})' -f $AdapterId, $_.Exception.Message)
    }
    finally {
        Remove-Item -LiteralPath $link -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $target -Force -Recurse -ErrorAction SilentlyContinue
    }

    # source-level behaviour of the shared hook helpers
    $common = Join-Path (Split-Path -Parent $ScriptPath) '_hook-common.ps1'
    if (Test-Path -LiteralPath $common) {
        . $common
        $mixed = @(Get-ToolkitSecretFindings -Content 'example documentation: api_key=realfixturevalue123')
        $placeholder = @(Get-ToolkitSecretFindings -Content 'example documentation: api_key=YOUR_API_KEY')
        $placeholderThenReal = @(Get-ToolkitSecretFindings -Content 'api_key=YOUR_API_KEY api_key=realfixturevalue123')
        Write-AdtCheck $AdapterId 'pathguard-hook:secret-finding-rules' ($mixed.Count -gt 0 -and $placeholder.Count -eq 0 -and $placeholderThenReal.Count -gt 0) 'placeholder candidates are exempt only when exact; real candidates on the same line must still be found'
    }

    # hooks wiring + agent toml emission
    $adapterModule = Join-Path $repoRoot 'adapters/codex/CodexAdapter.ps1'
    . $adapterModule
    $hooksObject = New-CodexPreToolUseHooksObject
    $preTool = @($hooksObject.hooks.PreToolUse)
    $wired = $preTool.Count -eq 1 -and $preTool[0].matcher -eq '.*' -and ($hooksObject | ConvertTo-Json -Depth 8) -match 'guard-pre-tool\.ps1'
    Write-AdtCheck $AdapterId 'pathguard-hook:hooks-wire-catch-all-pretooluse' $wired 'expected one catch-all PreToolUse group wired to guard-pre-tool.ps1'
    $toml = Convert-CodexAgentMarkdownToToml -MarkdownText "---`nname: sample-agent`ndescription: Sample for toml emit test.`nmodel: inherit`n---`n`n# sample-agent`n`nDo useful work.`n" -SourcePath 'sample.md'
    $tomlOk = ($toml -match '(?m)^name = ') -and ($toml -match '(?m)^description = ') -and ($toml -match 'developer_instructions = ') -and ($toml -match 'Do useful work') -and
    $toml.Contains('# toolkit.spawn.model = inherit') -and $toml.Contains('# toolkit.spawn.developer_threads = 2') -and $toml.Contains('# toolkit.spawn.orchestrate_threads = 4') -and ($toml -notmatch '(?m)^\s*model\s*=')
    Write-AdtCheck $AdapterId 'pathguard-hook:agents-emit-toml' $tomlOk 'agent markdown must map to toml with inherit honesty comments and no model key'
    $threw = $false
    try { [void](Convert-CodexAgentMarkdownToToml -MarkdownText "---`nname: bad-agent`ndescription: Must reject divergent model pin.`nmodel: gpt-5.6-luna-medium`n---`n`n# bad-agent`n" -SourcePath 'bad.md') } catch { $threw = $true }
    Write-AdtCheck $AdapterId 'pathguard-hook:agents-reject-divergent-model-pin' $threw 'a divergent model pin must be rejected'
}

# --- driver -----------------------------------------------------------------------------

function Test-AdapterStaticRegistry {
    $repoRoot = Get-AdtRepoRoot
    $artifacts = (Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/runtime/uninstall-artifacts.json') -Raw -Encoding UTF8 | ConvertFrom-Json).adapters
    foreach ($agent in @(Get-AdtRegistryAgents)) {
        $id = [string]$agent.id
        $dir = Join-Path $repoRoot ('adapters/' + $id)
        $caps = $agent.capabilities
        Write-AdtCheck $id 'static-module' (Test-Path -LiteralPath (Join-Path $repoRoot ('adapters/' + $agent.module)) -PathType Leaf) 'module file missing'
        $need = [ordered]@{ 'Publish-*Router.ps1' = $caps.router; 'Publish-*Policy.ps1' = $caps.rules; 'Publish-*Hooks.ps1' = $caps.hooks; 'Publish-*Agents.ps1' = $caps.agents; 'Uninstall-*.ps1' = $true }
        foreach ($pattern in $need.Keys) {
            if ($need[$pattern] -eq $true) {
                Write-AdtCheck $id ('static-publisher:' + $pattern) (@(Get-ChildItem -LiteralPath $dir -Filter $pattern -File -ErrorAction SilentlyContinue).Count -ge 1) "declared capability has no $pattern"
            }
        }
        $guard = Get-AdtProperty $agent 'pathGuard' $null
        Write-AdtCheck $id 'static-pathguard-declared' ($null -ne $guard) 'registry pathGuard missing'
        if ($null -ne $guard) {
            $assets = @(@(Get-AdtProperty $guard 'requiredAssets' @()) + @(Get-AdtProperty $guard 'script' @()) + @(Get-AdtProperty $guard 'hooksConfig' @()) | Where-Object { $_ })
            $missing = @($assets | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_)) })
            Write-AdtCheck $id 'static-pathguard-assets' ($missing.Count -eq 0) ('missing: ' + ($missing -join ', '))
            foreach ($asset in @(Get-AdtProperty $guard 'forbiddenAssets' @())) {
                Write-AdtCheck $id 'static-pathguard-forbidden' (-not (Test-Path -LiteralPath (Join-Path $repoRoot $asset))) "$asset must not exist"
            }
            if ((Get-AdtProperty $guard 'preToolUseEmpty' $false) -and $guard.hooksConfig) {
                $cfg = Get-Content -LiteralPath (Join-Path $repoRoot $guard.hooksConfig) -Raw -Encoding UTF8 | ConvertFrom-Json
                $h = foreach ($e in 'preToolUse', 'beforeShellExecution') { if (@($cfg.hooks.PSObject.Properties | ForEach-Object { $_.Name }) -contains $e) { @($cfg.hooks.$e) } }
                Write-AdtCheck $id 'static-pathguard-no-veto' (@($h).Count -eq 0) 'host-owned authorization must not register pre-tool hooks'
            }
        }
        $art = @($artifacts | Where-Object { $_.id -eq $id }) | Select-Object -First 1
        Write-AdtCheck $id 'static-uninstall-artifacts' ($null -ne $art) 'missing from uninstall-artifacts.json'
        if ($null -ne $art) {
            $bad = @(@($art.pruneRoots) + @($art.sharedConfig) | ForEach-Object { ([string]$_).Split(':')[0].Trim() } | Where-Object { $_ -match '^([A-Za-z]:|/|\\)' -or $_ -match '(^|[\\/])\.\.([\\/]|$)' })
            Write-AdtCheck $id 'static-uninstall-paths-contained' ($bad.Count -eq 0 -and @($art.pruneRoots).Count -ge 1) ('unsafe or empty roots: ' + ($bad -join ', '))
            Write-AdtCheck $id 'static-uninstaller-file' (Test-Path -LiteralPath (Join-Path $repoRoot ([string]$art.uninstaller))) "missing $($art.uninstaller)"
        }
    }
    $noSkill = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'core/skills') -Directory | Where-Object { $_.Name -ne '_shared' -and -not (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')) } | ForEach-Object { $_.Name })
    Write-AdtCheck 'core' 'static-skills-have-SKILL.md' ($noSkill.Count -eq 0) ('no SKILL.md: ' + ($noSkill -join ', '))
}

function Invoke-AdapterChecks {
    [CmdletBinding()]
    param([string] $Adapter = '', [switch] $All, [switch] $KeepWork)

    $repoRoot = Get-AdtRepoRoot
    . (Join-Path $repoRoot 'scripts/_lib/New-ToolkitWorkRoot.ps1')
    . (Join-Path $repoRoot 'scripts/_lib/Resolve-InstallRoot.ps1')
    . (Join-Path $repoRoot 'scripts/_lib/Invoke-PathSecretsGuardHarness.ps1')

    $script:AdtFailures.Clear()
    $script:AdtPublishCache = @{}
    $script:AdtPublishLog.Clear()
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    Test-AdapterStaticRegistry

    $selected = if ($All) { @(Get-AdtRegistryAgents) } elseif ($Adapter) { @(Get-AdtRegistryAgents -Adapter $Adapter) } else { @(Get-AdtRegistryAgents -Adapter 'claude') }
    $work = New-ToolkitWorkRoot -RepoRoot $repoRoot
    try {
        foreach ($agent in $selected) {
            $id = [string]$agent.id
            try {
                . (Join-Path $repoRoot ('adapters/' + $agent.module))
                $publish = Get-AdtPublish -Agent $agent -WorkRoot $work
                Test-AdapterPublishLayout -Agent $agent -Publish $publish
                Test-AdapterKeyedUninstall -Agent $agent -Publish $publish -WorkRoot $work
                if ($Adapter -or $All) { Test-AdapterPathGuard -Agent $agent -Publish $publish -WorkRoot $work }
            }
            catch { Write-AdtCheck $id 'execution' $false $_.Exception.Message }
        }
    }
    finally { if (-not $KeepWork) { Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work } }

    Write-Host ('publishes={0}; total={1}s' -f $script:AdtPublishLog.Count, [math]::Round($watch.Elapsed.TotalSeconds, 1))
    if ($script:AdtFailures.Count -gt 0) {
        Write-Host ('FAILED ({0}):' -f $script:AdtFailures.Count) -ForegroundColor Red
        foreach ($f in $script:AdtFailures) { Write-Host ('  ' + $f) -ForegroundColor Red }
        return 1
    }
    return 0
}
