# Domain: CLI scripts

Operator entry points under `scripts/`.

## Scripts

| Script | Role |
|--------|------|
| `scripts/toolkit.ps1` | Interactive Smart Manager (wizards + Help) or `-Action` / `-Agent` orchestrator |
| `scripts/sync-agent.ps1` | Load registry module; run `Publish-*`, then always `Get-SddRoot -Prepare` |
| `scripts/validate-agent.ps1` | Always `validate-core`, then adapter `Invoke-SmokeValidate` |
| `scripts/validation/validate-core.ps1` | Core contract suite (alias `validate-all.ps1`) |
| `scripts/validation/Invoke-*CiSmoke.ps1` | CI-parity smoke harnesses |
| `scripts/inventory/Invoke-MemoryBankInventory.ps1` | Read-only bank inventory (`ready` \| `not-ready`) |
| `scripts/validation/Invoke-PrdPlanChangePreflight.ps1` | PRD → PLAN → CHANGE preflight before O3 |
| `scripts/trace/Invoke-TraceHarvest.ps1` | Feature-scoped TRACE harvest |
| `scripts/ledger/Invoke-PlanLedgerClaim.ps1` | PLAN-LEDGER claim / status / release |

Shared helpers: `scripts/_lib/` (`Resolve-InstallRoot`, `Resolve-RegistryAgent`, toolkit constants, …).

## Operator workflow (inventory → preflight → develop → harvest)

Same skill call flow; these scripts add deterministic gates/evidence — not a second toolkit CLI.

| Order | Script | Exit / status |
|-------|--------|---------------|
| 1. Inventory | `Invoke-MemoryBankInventory.ps1` | `0` = `ready`; `2` = `not-ready` (writes only under `memory-bank/.inventory/`) |
| 2. Preflight | `Invoke-PrdPlanChangePreflight.ps1` | `0` allow; `1` usage; `2` block (read-only; runs validate-prd/plan/change) |
| 3. Develop | Classic SDD / O3 (`sdd-develop`, optional PLAN-LEDGER claim) | SESSION gates + optional ledger hold |
| 4. TRACE harvest | `Invoke-TraceHarvest.ps1` | `0` ok; `2` fail (reads **only** `features/NNN-slug/TRACE.jsonl`) |

Contracts (do not paste full schema here): [TRACE archive](core.md#trace-archive-living-loop), [PLAN-LEDGER](core.md#plan-ledger-atomic-step-claim), [VALIDATION.md](../VALIDATION.md).

### Memory-bank inventory

```powershell
pwsh -NoProfile -File .\scripts\inventory\Invoke-MemoryBankInventory.ps1 `
  -RepoPath . -BankPath .\memory-bank -AllowCreateInventory
```

- Scans the consumer repo; updates `memory-bank/.inventory/sources.json` (path, `last_write_utc`, length, sha256, short summary).
- Emits inventory-level `inventory_hash`, `inventory_summary`, and `status` `ready` \| `not-ready` (+ `status_reason`).
- Never modifies application source. Secret-named leaves get a redacted summary heuristic.
- Assert smoke: `scripts/validation/Assert-MemoryBankInventory.ps1` (wired in `validate-core`).

### PRD / PLAN / CHANGE preflight

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-PrdPlanChangePreflight.ps1 `
  -FeatureRoot features\<NNN-slug> `
  -PlanPath features\<NNN-slug>\<story>\PLAN\PLAN_....md
```

Deterministic only — no LLM. Invokes structural validate-prd / validate-plan / validate-change; blocks O3 with an explicit reason when inconsistent. Optional `-PrdPath`, `-ChangePath`, `-Nature`.

### TRACE harvest

```powershell
pwsh -NoProfile -File .\scripts\trace\Invoke-TraceHarvest.ps1 `
  -FeatureRoot features\<NNN-slug>
```

Summarizes events from that feature’s `TRACE.jsonl` only (includes `tokens` / `duration` / `spawn` when present). Path escape or sessions-root reads fail explicitly — never dumps `sdd/sessions`. Assert: `Assert-TraceHarvest.ps1`.

### PLAN-LEDGER CLI

```powershell
pwsh -NoProfile -File .\scripts\ledger\Invoke-PlanLedgerClaim.ps1 `
  -Action claim -PlanPath features\<...>\PLAN\PLAN_....md -Step 2 -Holder <id> `
  -RepoPath . -SessionsRoot <sessions-root>
```

See [core.md PLAN-LEDGER](core.md#plan-ledger-atomic-step-claim).

## toolkit.ps1

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor -WhatIf
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude -WhatIf
```

Interactive menu: Sync / Validate / Sync+Validate / Validate core / Validation lab / Uninstall / Help. Sync / Validate / Uninstall **require** an agent id (wizard or `-Agent`). Backup is non-interactive stub only (`-Action Backup`). `-WhatIf` forwards to `sync-agent.ps1` for Sync / SyncAndValidate, and to adapter `Uninstall-Toolkit` when that command declares `-WhatIf`.

## sync-agent.ps1

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent <id> [-InstallRoot <path>] [-Mode user|repo] [-AllowUserHome] [-WhatIf]
```

| Parameter | Behavior |
|-----------|----------|
| `-Agent` | Required registry id |
| `-InstallRoot` | Target root; interactive wizard defaults to **live home**; non-interactive / CI default = in-repo fixture |
| `-Mode` | Required for `copilot` (`user` \| `repo`) |
| `-AllowUserHome` | Opt-in for USERPROFILE paths |
| `-WhatIf` | Forwarded to Publish-* |

Order (typical): Publish-Skills → Policy → Router → Hooks; then SDD prepare when capable.

## validate-agent.ps1

```powershell
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent <id> [-InstallRoot <path>] [-Mode user|repo] [-AllowUserHome]
```

1. Runs core validation.
2. Runs adapter smoke against InstallRoot (documented no-op only when smoke is not applicable — missing `-Agent` still fails).

## Examples

```powershell
# Fixture sync (safe)
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor

# Live Cursor
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome

# Copilot both modes (fixtures)
$u = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$r = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $u
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $r
```

## Related

- [INSTALL.md](../INSTALL.md)
- [VALIDATION.md](../VALIDATION.md)
- [domains/validation-ci.md](validation-ci.md)
- [ADAPTERS.md](../ADAPTERS.md)
