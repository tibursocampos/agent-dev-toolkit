# Validation and local CI

How to run the in-repo test suite and agent smokes. **None of these steps require writing to a live agent home.**

## Audiences

| Audience | What this doc is for | What to run |
|----------|----------------------|-------------|
| **Visitor** | Understanding that tests exist; **not** expected to run the suite | None — clone/fork and read [REPO_GOVERNANCE.md](REPO_GOVERNANCE.md) / [CONTRIBUTING.md](../CONTRIBUTING.md) |
| **Operator** | Syncing skills to an agent home and checking a fixture install | Optional: [Core suite](#core-suite) (`validate-core`); [Per-agent validate](#per-agent-validate) against a fixture `InstallRoot` — **never** `-AllowUserHome` to “make CI pass” |
| **Maintainer** | Changing this repository (write access / CI owners) | **Required locally before merge:** `validate-core.ps1` (or `validate-all.ps1`). **Parity with Actions:** [What CI runs](#what-ci-runs) / [Local parity](domains/validation-ci.md#local-parity) (same scripts as [`.github/workflows/validate-toolkit.yml`](../.github/workflows/validate-toolkit.yml)). Full matrix = `validate-core` + keyed uninstall asserts + `Assert-SyncAllowUserHomeForward` + 10 agent CI smokes (Copilot is a suite) |

**Maintainers vs visitors:** Visitors do not need PowerShell validation. Maintainers own the green bar — run **validate-core** on every change that touches contracts, skills, router, or validation scripts; run the relevant **CI smoke** when an adapter or publish path changes. Operators may run the same scripts against fixtures; that does not grant upstream PR rights ([CONTRIBUTING.md](../CONTRIBUTING.md)).

Policy context: [REPO_GOVERNANCE.md](REPO_GOVERNANCE.md).

## Core suite

Validates contracts, skill graph, fixtures, and the smoke harness wiring — **no** `%USERPROFILE%` deploy:

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1

# Alias:
pwsh -NoProfile -File .\scripts\validation\validate-all.ps1
```

Quiet mode (CI):

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1 -Quiet
```

Smoke harness alone (fixture `InstallRoot` under the repo):

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-SmokeHarness.ps1
```

`validate-core` also wires structural SDD artifact smokes (`validate-prd` / `validate-plan` / CHANGE / EVD / TRACE fixtures, selective-retrieval assert) plus maturity asserts for memory-bank inventory, PLAN-LEDGER, TRACE archive/harvest, TRACE emitter fail-open, and **product artifact quality** (`Assert-ProductArtifactQuality.ps1` — FEATURE depth, task-shaped titles, AC budget, cap, honest Evidence omit). Those are **scripts**, not LLM validators. They do not introduce a second toolkit CLI or SQLite/FTS.

## Operator scripts (pointers)

Run against a **consumer** feature / bank when closing a wave or before O3 — not required for visitor CI green. Contracts live under `core/skills/_shared/sdd-artifacts/`; do not duplicate schemas here.

| Script | When | Domain detail |
|--------|------|---------------|
| `scripts/inventory/Invoke-MemoryBankInventory.ps1` | Refresh `memory-bank/.inventory/` (`ready` \| `not-ready`) | [cli-scripts](domains/cli-scripts.md#memory-bank-inventory) |
| `scripts/validation/Invoke-PrdPlanChangePreflight.ps1` | Before O3 — PRD/PLAN/CHANGE consistency | [cli-scripts](domains/cli-scripts.md#prd--plan--change-preflight) |
| `scripts/trace/Invoke-TraceHarvest.ps1` | Summarize `features/NNN-slug/TRACE.jsonl` only | [cli-scripts](domains/cli-scripts.md#trace-harvest) |
| `scripts/ledger/Invoke-PlanLedgerClaim.ps1` | O3 parallel step claim / release | [core PLAN-LEDGER](domains/core.md#plan-ledger-atomic-step-claim) |
| `scripts/validation/validate-trace.ps1` | Structural TRACE check; `-RequireArchiveComplete` at archive | [core TRACE](domains/core.md#trace-archive-living-loop) |
| `scripts/validation/Assert-ProductArtifactQuality.ps1` | Fixture CTs for FEATURE/STORY quality bar (via `validate-core`) | [Product artifact quality](domains/core.md#product-artifact-quality-backlog-item-types) |

Suggested order: **inventory → preflight → develop → TRACE harvest**. Emitter honesty (which hosts actually wire TRACE): [adapters.md](domains/adapters.md#trace-emitter-honesty).

`Assert-HermesSpawnIsolation.ps1` (check name `hermes-spawn-isolation`) keeps Hermes `delegate_task` out of core policy/router/skills (SPAWN host-map allowlist only) and proves the Hermes AGENTS spawn bridge does not leak into other adapters’ published `AGENTS.md` / rules.

## Per-agent validate

Runs `validate-core`, then the adapter’s `Invoke-SmokeValidate` against a fixture InstallRoot (default from the registry / adapter):

```powershell
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode repo
```

## CI smoke harnesses

These mirror [`.github/workflows/validate-toolkit.yml`](../.github/workflows/validate-toolkit.yml). Prefer them locally when you want the same ephemeral-copy behavior as Actions.

| Script | What it covers |
|--------|----------------|
| `Invoke-CursorCiSmoke.ps1` | Cursor sync+validate on ephemeral copy of Cursor fixture |
| `Invoke-AntigravityCiSmoke.ps1` | Antigravity sync+validate on ephemeral Antigravity fixture |
| `Invoke-ClaudeCiSmoke.ps1` | Claude sync+validate on ephemeral Claude fixture |
| `Invoke-CodexCiSmoke.ps1` | Codex sync+validate on ephemeral Codex fixture |
| `Invoke-CopilotCiSmokeSuite.ps1` | Copilot Mode `user` + Mode `repo` + home guard |
| `Invoke-OpenCodeCiSmoke.ps1` | OpenCode filesystem sync+validate on ephemeral fixture (**not** product runtime) |
| `Invoke-GrokCiSmoke.ps1` | Grok sync+validate on ephemeral Grok fixture |
| `Invoke-ZCodeCiSmoke.ps1` | ZCode ADE fixture InstallRoot |
| `Invoke-HermesCiSmoke.ps1` | Hermes sync+validate on ephemeral Hermes fixture (models `~/.hermes`) |
| `Invoke-OpenHandsCiSmoke.ps1` | OpenHands filesystem sync+validate on ephemeral project fixture |

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-AntigravityCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CodexCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenCodeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-GrokCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-HermesCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1
```

### Manual fixture sync (same idea)

```powershell
$cursorFixture = Join-Path $PWD 'scripts\validation\fixtures\cursor-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor -InstallRoot $cursorFixture

$claudeFixture = Join-Path $PWD 'scripts\validation\fixtures\claude'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot $claudeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude -InstallRoot $claudeFixture

$copilotUser = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$copilotRepo = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
```

Other fixture roots: `fixtures/codex`, `fixtures/opencode`, `fixtures/grok`, `fixtures/zcode-install-root`, `fixtures/antigravity-install-root`, `fixtures/hermes`, `fixtures/openhands`.

## What CI runs

Workflow: `.github/workflows/validate-toolkit.yml` on `windows-latest` (checkout only; no secrets; no home sync for green):

1. `validate-core.ps1 -Quiet`
2. Keyed uninstall asserts (separate step — not inside validate-core): `Assert-ClaudeKeyedUninstall.ps1`, `Assert-CopilotKeyedUninstall.ps1`, `Assert-CodexKeyedUninstall.ps1`, `Assert-OpenCodeKeyedUninstall.ps1`, `Assert-AntigravityKeyedUninstall.ps1`, `Assert-GrokKeyedUninstall.ps1`, `Assert-CursorKeyedUninstall.ps1`, `Assert-ZcodeKeyedUninstall.ps1`, `Assert-HermesKeyedUninstall.ps1`, `Assert-OpenHandsKeyedUninstall.ps1`
3. `Assert-SyncAllowUserHomeForward.ps1` (disposable USERPROFILE probe; not a live-home sync for green)
4. `Invoke-CursorCiSmoke.ps1 -Quiet`
5. `Invoke-AntigravityCiSmoke.ps1 -Quiet`
6. `Invoke-ClaudeCiSmoke.ps1 -Quiet`
7. `Invoke-CodexCiSmoke.ps1 -Quiet`
8. `Invoke-CopilotCiSmokeSuite.ps1 -Quiet`
9. `Invoke-OpenCodeCiSmoke.ps1 -Quiet` (filesystem fixture smoke — **not** OpenCode product runtime)
10. `Invoke-GrokCiSmoke.ps1 -Quiet`
11. `Invoke-ZCodeCiSmoke.ps1 -Quiet`
12. `Invoke-HermesCiSmoke.ps1 -Quiet`
13. `Invoke-OpenHandsCiSmoke.ps1 -Quiet`

## Safety rules

| Rule | Detail |
|------|--------|
| No live home for green | Do not use `-AllowUserHome` to “make CI pass” |
| Trust UIs out of scope | Cursor / Claude / Codex / Grok hook trust dialogs are never required for smoke green |
| JetBrains / Eclipse Copilot | Out of scope — Mode user/repo official surfaces only |

## Related

- Domain deep dive: [domains/validation-ci.md](domains/validation-ci.md)
- Adapter publish details: [ADAPTERS.md](ADAPTERS.md)
- Install / live home: [INSTALL.md](INSTALL.md)
