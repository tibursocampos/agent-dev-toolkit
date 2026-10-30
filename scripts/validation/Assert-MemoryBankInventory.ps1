#Requires -Version 5.1
# Tests:
#   Should_Pass_When_InventoryCreatedReady
#   Should_MarkNotReady_When_NoSources
#   Should_MarkNotReady_When_PathEscapeSeeded
#   Should_RedactSummary_When_SecretNamedSource
#   Should_MarkNotReady_When_SourceDriftsOrDisappears
#   Should_NotIndexSibling_When_PathSharesRepoPrefix
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$libDir = Join-Path (Split-Path -Parent $scriptDir) '_lib'
. (Join-Path $libDir 'ToolkitConstants.ps1')
. (Join-Path $libDir 'Get-ToolkitRepoRoot.ps1')
. (Join-Path $libDir 'New-ToolkitWorkRoot.ps1')
. (Join-Path $libDir 'Resolve-InstallRoot.ps1')
$repoRoot = Get-ToolkitRepoRoot -FromPath $scriptDir
$inv = Join-Path $repoRoot ($script:ToolkitConstant.InvokeMemoryBankInventoryScriptRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)

$ExitReady = 0
$ExitNotReady = 2
$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-Pass { param([string] $Name) Write-Host ("{0}: PASS" -f $Name) }
function Write-Fail { param([string] $Name, [string] $Reason) Write-Error ("{0}: FAIL - {1}" -f $Name, $Reason); exit 1 }

function Invoke-Inventory {
    param([string] $Repo, [string] $Bank, [string] $Action = 'inventory')
    & $inv -RepoPath $Repo -BankPath $Bank -AllowCreateInventory -Action $Action 2>$null 6>$null | Out-Null
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
    $src = Join-Path $Bank '.inventory\sources.json'
    $doc = $null
    if (Test-Path -LiteralPath $src) { $doc = Get-Content -LiteralPath $src -Raw -Encoding UTF8 | ConvertFrom-Json }
    return [pscustomobject]@{ Code = $code; Doc = $doc; Path = $src }
}

if (-not (Test-Path -LiteralPath $inv)) { Write-Fail 'Should_Pass_When_InventoryCreatedReady' 'missing inventory script' }

$work = New-ToolkitWorkRoot -RepoRoot $repoRoot
try {
    # --- create: ready, schema, hashes, portable roots, writes confined to .inventory ---
    $r = Join-Path $work 'ready'
    $b = Join-Path $r 'memory-bank'
    New-Item -ItemType Directory -Path $r -Force | Out-Null
    '# Memory bank inventory fixture' | Set-Content -LiteralPath (Join-Path $r 'README.md') -Encoding UTF8
    $res = Invoke-Inventory $r $b
    $n = 'Should_Pass_When_InventoryCreatedReady'
    if ($res.Code -ne $ExitReady) { Write-Fail $n "exit $($res.Code)" }
    $d = $res.Doc
    if ([int]$d.schema_version -ne 3 -or [string]$d.status -ne 'ready') { Write-Fail $n 'schema/status' }
    if ([string]$d.inventory_hash -notmatch '^[a-f0-9]{64}$') { Write-Fail $n 'inventory_hash' }
    if ([string]$d.repo_path -ne '.' -or [string]$d.bank_path -ne 'memory-bank') { Write-Fail $n 'roots not portable' }
    $e = @($d.sources | Where-Object { $_.path -eq 'README.md' })[0]
    if ($null -eq $e -or [string]$e.hash -notmatch '^[a-f0-9]{64}$' -or [string]$e.summary -notmatch 'Memory bank inventory fixture') { Write-Fail $n 'README entry' }
    $allowed = [System.IO.Path]::GetFullPath((Join-Path $b '.inventory'))
    foreach ($f in @(Get-ChildItem -LiteralPath $r -Recurse -File -Force)) {
        if ($f.Name -ne 'README.md' -and -not $f.FullName.StartsWith($allowed, [System.StringComparison]::OrdinalIgnoreCase)) { Write-Fail $n "write outside .inventory: $($f.FullName)" }
    }
    Write-Pass $n

    # --- no sources ---
    $r = Join-Path $work 'empty'
    $b = Join-Path $r 'memory-bank'
    New-Item -ItemType Directory -Path $r -Force | Out-Null
    $res = Invoke-Inventory $r $b
    $n = 'Should_MarkNotReady_When_NoSources'
    if ($res.Code -ne $ExitNotReady -or [string]$res.Doc.status -ne 'not-ready' -or [string]$res.Doc.status_reason -notlike 'no_sources:*') { Write-Fail $n "exit $($res.Code)" }
    Write-Pass $n

    # --- path escape ---
    $r = Join-Path $work 'escape'
    $b = Join-Path $r 'memory-bank'
    New-Item -ItemType Directory -Path (Join-Path $b '.inventory') -Force | Out-Null
    'fixture' | Set-Content -LiteralPath (Join-Path $r 'README.md') -Encoding UTF8
    'secret' | Set-Content -LiteralPath (Join-Path $work 'outside.txt') -Encoding UTF8
    $seed = [ordered]@{ schema_version = 3; sources = @([ordered]@{ path = '../outside.txt' }) }
    [System.IO.File]::WriteAllText((Join-Path $b '.inventory\sources.json'), ($seed | ConvertTo-Json -Depth 6), $utf8)
    $res = Invoke-Inventory $r $b
    $n = 'Should_MarkNotReady_When_PathEscapeSeeded'
    if ($res.Code -ne $ExitNotReady -or [string]$res.Doc.status_reason -notlike 'path_escape:*') { Write-Fail $n "exit $($res.Code) reason $($res.Doc.status_reason)" }
    if (@($res.Doc.sources | Where-Object { [string]$_.path -match '\.\.' }).Count -gt 0) { Write-Fail $n 'escaped path indexed' }
    if ((Get-Content -LiteralPath (Join-Path $work 'outside.txt') -Raw) -notmatch 'secret') { Write-Fail $n 'outside file modified' }
    Write-Pass $n

    # --- secret-named source: summary redacted, file untouched ---
    $r = Join-Path $work 'secret'
    $b = Join-Path $r 'memory-bank'
    New-Item -ItemType Directory -Path (Join-Path $b '.inventory') -Force | Out-Null
    'fixture' | Set-Content -LiteralPath (Join-Path $r 'README.md') -Encoding UTF8
    $sf = [System.IO.Path]::Combine($r, 'credentials.json')
    $payload = 'API_KEY=supersecret-must-not-land-in-summary'
    [System.IO.File]::WriteAllText($sf, $payload, $utf8)
    $seed = [ordered]@{ schema_version = 3; sources = @(
            [ordered]@{ path = 'README.md'; hash = (Get-FileHash -LiteralPath (Join-Path $r 'README.md') -Algorithm SHA256).Hash.ToLowerInvariant() },
            [ordered]@{ path = 'credentials.json'; hash = (Get-FileHash -LiteralPath $sf -Algorithm SHA256).Hash.ToLowerInvariant() }) }
    [System.IO.File]::WriteAllText((Join-Path $b '.inventory\sources.json'), ($seed | ConvertTo-Json -Depth 6), $utf8)
    $res = Invoke-Inventory $r $b
    $n = 'Should_RedactSummary_When_SecretNamedSource'
    $se = @($res.Doc.sources | Where-Object { $_.path -eq 'credentials.json' })[0]
    if ($res.Code -ne $ExitReady -or $null -eq $se) { Write-Fail $n "exit $($res.Code) or entry missing" }
    if ([string]$se.summary -ne '[redacted: secret-named source]') { Write-Fail $n "summary '$($se.summary)'" }
    if ([System.IO.File]::ReadAllText($sf).Trim() -ne $payload) { Write-Fail $n 'secret file modified' }
    Write-Pass $n

    # --- refresh: stable when unchanged, not-ready on drift and on missing source ---
    $r = Join-Path $work 'drift'
    $b = Join-Path $r 'memory-bank'
    New-Item -ItemType Directory -Path $r -Force | Out-Null
    'Drift fixture' | Set-Content -LiteralPath (Join-Path $r 'README.md') -Encoding UTF8
    'Second source' | Set-Content -LiteralPath (Join-Path $r 'AGENTS.md') -Encoding UTF8
    $n = 'Should_MarkNotReady_When_SourceDriftsOrDisappears'
    if ((Invoke-Inventory $r $b).Code -ne $ExitReady) { Write-Fail $n 'initial inventory' }
    if ((Invoke-Inventory $r $b 'refresh-light').Code -ne $ExitReady) { Write-Fail $n 'unchanged refresh must stay ready' }
    'changed' | Add-Content -LiteralPath (Join-Path $r 'README.md') -Encoding UTF8
    $res = Invoke-Inventory $r $b 'refresh-light'
    if ($res.Code -ne $ExitNotReady -or [string]$res.Doc.status_reason -notlike 'source_drift:*') { Write-Fail $n 'drift not flagged' }
    Remove-Item -LiteralPath (Join-Path $r 'README.md') -Force
    $res = Invoke-Inventory $r $b 'refresh-light'
    if ($res.Code -ne $ExitNotReady -or [string]$res.Doc.status_reason -notlike '*source_drift:*missing:README.md*') { Write-Fail $n 'missing source not flagged' }
    Write-Pass $n

    # --- sibling prefix (repo vs repo-evil) ---
    $p = Join-Path $work 'sibling'
    $r = Join-Path $p 'repo'
    $evil = Join-Path $p 'repo-evil'
    New-Item -ItemType Directory -Path $r, $evil -Force | Out-Null
    'repo-only' | Set-Content -LiteralPath (Join-Path $r 'README.md') -Encoding UTF8
    'evil-marker-should-not-index' | Set-Content -LiteralPath (Join-Path $evil 'README.md') -Encoding UTF8
    $n = 'Should_NotIndexSibling_When_PathSharesRepoPrefix'
    if (Test-IsPathUnderOrEqual -ChildPath $evil -ParentPath $r) { Write-Fail $n 'prefix sibling treated as child' }
    $res = Invoke-Inventory $r (Join-Path $r 'memory-bank')
    if ($res.Code -ne $ExitReady) { Write-Fail $n "exit $($res.Code)" }
    if (@($res.Doc.sources | Where-Object { [string]$_.path -match 'repo-evil' -or [string]$_.summary -match 'evil-marker' }).Count -gt 0) { Write-Fail $n 'sibling indexed' }
    Write-Pass $n
}
finally {
    Remove-ToolkitWorkRoot -RepoRoot $repoRoot -Path $work
}

exit 0
