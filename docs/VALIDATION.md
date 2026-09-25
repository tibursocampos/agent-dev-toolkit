# Validation and local CI

How to run the in-repo test suite and agent smokes. **None of these steps require writing to a live agent home.**

## Audiences

| Audience | What this doc is for | What to run |
|----------|----------------------|-------------|
| **Visitor** | Understanding that tests exist; **not** expected to run the suite | None — clone/fork and read [REPO_GOVERNANCE.md](REPO_GOVERNANCE.md) / [CONTRIBUTING.md](../CONTRIBUTING.md) |
| **Operator** | Syncing skills to an agent home and checking a fixture install | Optional: [Core suite](#core-suite) (`validate-core`); [Per-agent validate](#per-agent-validate) against a fixture `InstallRoot` — **never** `-AllowUserHome` to “make CI pass” |
| **Maintainer** | Changing this repository (write access / CI owners) | **Required locally before merge:** `validate-core.ps1` (or `validate-all.ps1`). **Parity with Actions:** [What CI runs](#what-ci-runs) / [Local parity](#local-parity) (same scripts as [`.github/workflows/validate-toolkit.yml`](../.github/workflows/validate-toolkit.yml)). Full matrix = `validate-core` + keyed uninstall asserts + `Assert-SyncAllowUserHomeForward` + 10 agent CI smokes (Copilot is a suite) |

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

`validate-core` also wires structural SDD artifact smokes (`validate-prd` / `validate-plan` / CHANGE / EVD / TRACE fixtures, selective-retrieval assert) plus maturity asserts for memory-bank inventory, PLAN-LEDGER, **develop session gate** (`Assert-DevelopSessionGate.ps1`), **InvocationAxes** (WS1), **SiblingReadinessGate** (WS3), **NavigationBlock** (WS7), PublishSpawnKnobs, TRACE archive/harvest, TRACE emitter fail-open, and **product artifact quality** (`Assert-ProductArtifactQuality.ps1` — FEATURE depth, task-shaped titles, AC budget, cap, honest Evidence omit). Those are **scripts**, not LLM validators. They do not introduce a second toolkit CLI or SQLite/FTS.

These prove contracts and scripts exist. They are not a substitute for running inventory, preflight, or harvest on a consumer feature. Operator entry points stay in the table below.

| Assert / script | Role |
|-----------------|------|
| `Assert-MemoryBankInventory.ps1` | Inventory script + `ready` / `not-ready` contract smoke (portable paths in `sources.json`) |
| `Assert-PlanLedgerContract.ps1` | PLAN-LEDGER present + double-claim race |
| `Assert-DevelopSessionGate.ps1` / `validate-session-gates.ps1` | Idempotent develop `step_confirmed` helper + skill MUST `-File` (WS10) |
| `Assert-InvocationAxes.ps1` | Spawn Axis B omit/inherit prose + harness wiring (WS1) |
| `Assert-PublishSpawnKnobs.ps1` | Publish honesty depth/threads/inherit (no child≠parent pin) |
| `Assert-SiblingReadinessGate.ps1` | Clarification READY / NEEDS_CLARIFICATION + B/I fixtures (WS3) |
| `Assert-NavigationBlock.ps1` | `## Related` PRD↔PLAN reciprocity fixture (WS7) |
| `Assert-TraceArchiveContract.ps1` | TRACE living-loop contract smoke |
| `Assert-TraceHarvest.ps1` | Harvest scope / exit behavior |
| `Assert-TraceEmitterFailOpen.ps1` | Fail-open emitter + `TraceEmitCommon` parity |
| `validate-trace.ps1` | Per-feature TRACE validate (`-RequireArchiveComplete` at wave close) |
| `Invoke-PrdPlanChangePreflight.ps1` | PRD/PLAN/CHANGE consistency before O3 |

## Operator scripts (pointers)

Run against a **consumer** feature / bank when closing a wave or before O3 — not required for visitor CI green. Contracts live under `core/skills/_shared/sdd-artifacts/`; do not duplicate schemas here.

| Script | When | Domain detail |
|--------|------|---------------|
| `scripts/inventory/Invoke-MemoryBankInventory.ps1` | Refresh `memory-bank/.inventory/` (`ready` \| `not-ready`; **portable** paths only) | [cli-scripts](domains/cli-scripts.md#memory-bank-inventory) |
| `scripts/validation/Invoke-PrdPlanChangePreflight.ps1` | Before O3 — PRD/PLAN/CHANGE consistency | [cli-scripts](domains/cli-scripts.md#prd--plan--change-preflight) |
| `scripts/session/Invoke-DevelopSessionGate.ps1` | After **sim** — idempotent develop `step_confirmed` (MUST `-File` with claim) | [cli-scripts](domains/cli-scripts.md#shell-allowlist-tip-ws10--req-013) · [core session gate](domains/core.md#plan-ledger--develop-session-gate) |
| `scripts/ledger/Invoke-PlanLedgerClaim.ps1` | O3 parallel step claim / release | [core PLAN-LEDGER](domains/core.md#plan-ledger--develop-session-gate) |
| `scripts/validation/Invoke-SiblingReadinessGate.ps1` | Selective clarify READY / NEEDS_CLARIFICATION check | [core readiness](domains/core.md#clarification-readiness-b--i--minor) |
| `scripts/trace/Invoke-TraceHarvest.ps1` | Summarize `features/NNN-slug/TRACE.jsonl` only | [cli-scripts](domains/cli-scripts.md#trace-harvest) |
| `scripts/validation/validate-trace.ps1` | Structural TRACE check; `-RequireArchiveComplete` at archive | [core TRACE](domains/core.md#trace-archive-living-loop) |
| `scripts/validation/Assert-ProductArtifactQuality.ps1` | Fixture CTs for FEATURE/STORY quality bar (via `validate-core`) | [Product artifact quality](domains/core.md#product-artifact-quality-backlog-item-types) |

Suggested order: **inventory → preflight → develop (session gate + claim) → TRACE harvest**. Emitter honesty (which hosts actually wire TRACE): [adapters.md](domains/adapters.md#trace-emitter-honesty).

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

Other fixture roots: `fixtures/codex` (Codex plugin layout), `fixtures/opencode` (OpenCode config root), `fixtures/grok` (Grok Build), `fixtures/zcode-install-root` (ZCode ADE), `fixtures/antigravity-install-root`, `fixtures/hermes` (`~/.hermes` model), `fixtures/openhands` (OpenHands project tree), `fixtures/install-root` (generic smoke harness). `fixtures/claude` includes the merge seed `settings.json`.

CI harnesses often copy a fixture to an ephemeral work root so the versioned seed stays intact. Local sync residue under fixture InstallRoots (published skill trees, SDD sessions, merge `.bak` files) is listed in the root `.gitignore`. Keep that residue locally for faster re-tests. Do not commit it.

## What CI runs

Workflow: [`.github/workflows/validate-toolkit.yml`](../.github/workflows/validate-toolkit.yml). Trigger: `pull_request` to `master`, `main`, and `develop` (no `push`). Permissions: `contents: read`. Checkout only; no secrets; no home sync for green.

**Jobs (all must be green before merge):**

| Job | Runner | Role |
|-----|--------|------|
| `validate` | `windows-latest` | Full Windows matrix below |
| `validate-ubuntu` | `ubuntu-latest` | `Assert-InstallRootSafety.ps1` + `validate-core` + all 10 agent fixture smokes (`pwsh 7+`) |
| `ci-ok` | `ubuntu-latest` | Gate job (`needs: [validate, validate-ubuntu]`) — **require this check** in branch protection |

### Job `validate` (Windows)

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

Do **not** merge with `validate-ubuntu` red. Auto-merge must wait for `ci-ok`.

### Other workflows

`publish-release-bootstrap.yml` uploads bootstrap release assets (zip `agent-dev-toolkit.zip`, checksum `agent-dev-toolkit.zip.sha256`, and bootstrap entrypoints) on `release` published and on `workflow_dispatch`. `enforce-release-source.yml` runs on `pull_request` to `master` and `main` and fails unless the head branch is `develop`.

`.github/workflows/docs.yml` exists and this page does not document the site.

### Local parity

Mirrors the Windows `validate` job order: `validate-core` → keyed uninstall asserts → `Assert-SyncAllowUserHomeForward` → 10 agent smokes (Copilot is a suite). The Ubuntu job also runs `Assert-InstallRootSafety.ps1` before `validate-core` and the same ten smokes. It does not repeat the keyed uninstall asserts.

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1 -Quiet

pwsh -NoProfile -File .\scripts\validation\Assert-ClaudeKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-CopilotKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-CodexKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-OpenCodeKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-AntigravityKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-GrokKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-CursorKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-ZcodeKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-HermesKeyedUninstall.ps1
pwsh -NoProfile -File .\scripts\validation\Assert-OpenHandsKeyedUninstall.ps1

pwsh -NoProfile -File .\scripts\validation\Assert-SyncAllowUserHomeForward.ps1

pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-AntigravityCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-CodexCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenCodeCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-GrokCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-HermesCiSmoke.ps1 -Quiet
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1 -Quiet
```

## Safety rules

| Rule | Detail |
|------|--------|
| No live home for green | Do not use `-AllowUserHome` to “make CI pass” |
| Trust UIs out of scope | Cursor / Claude / Codex / Grok hook trust dialogs are never required for smoke green |
| JetBrains / Eclipse Copilot | Out of scope — Mode user/repo official surfaces only |
| GLM Coding Plan | Endpoint-only; not ZCode ADE |
| Hermes gateway | `SOUL.md` and `config.yaml` secrets are out of smoke scope |
| OpenHands product runtime | Automation Server, sandbox YAML, and legacy microagents are out of smoke scope |

Live homes such as `~/.cursor`, `~/.claude`, `~/.copilot`, `~/.hermes`, and `~/.agents` are out of smoke scope.

## Related

- Adapter publish details: [ADAPTERS.md](ADAPTERS.md)
- Install / live home: [INSTALL.md](INSTALL.md)
- CLI scripts: [domains/cli-scripts.md](domains/cli-scripts.md)
