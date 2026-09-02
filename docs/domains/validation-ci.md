# Domain: Validation and CI

In-repo validation keeps CI green without syncing to a live agent home.

## Core suite

Entry: `scripts/validation/validate-core.ps1` (alias `validate-all.ps1`).

Covers skill contracts, must-not-contain IDE needles, graph/fixtures, and smoke harness wiring. Does **not** deploy under `%USERPROFILE%`.

## Fixtures

Versioned InstallRoots under `scripts/validation/fixtures/`:

| Fixture | Agent |
|---------|-------|
| `cursor-install-root/` | Cursor |
| `claude/` | Claude Code (includes merge seed `settings.json`) |
| `copilot/user`, `copilot/repo` | Copilot modes |
| `codex/` | Codex plugin layout |
| `opencode/` | OpenCode config root |
| `grok/` | Grok Build |
| `zcode-install-root/` | ZCode ADE |
| `hermes/` | Hermes (`~/.hermes` model) |
| `openhands/` | OpenHands project tree |
| `antigravity-install-root/` | Antigravity |
| `install-root/` | Generic smoke harness |

CI harnesses often copy a fixture to an **ephemeral** work root so the versioned seed stays intact. Local sync residue under fixture InstallRoots (published skill trees, SDD sessions, merge `.bak` files) is listed in root `.gitignore` — keep locally for faster re-tests; do not commit.

## Smoke harnesses

| Script | Used in CI |
|--------|------------|
| `Invoke-CursorCiSmoke.ps1` | Yes |
| `Invoke-AntigravityCiSmoke.ps1` | Yes |
| `Invoke-ClaudeCiSmoke.ps1` | Yes |
| `Invoke-CodexCiSmoke.ps1` | Yes |
| `Invoke-CopilotCiSmokeSuite.ps1` | Yes |
| `Invoke-OpenCodeCiSmoke.ps1` | Yes |
| `Invoke-GrokCiSmoke.ps1` | Yes |
| `Invoke-ZCodeCiSmoke.ps1` | Yes |
| `Invoke-HermesCiSmoke.ps1` | Yes |
| `Invoke-OpenHandsCiSmoke.ps1` | Yes |
| `Invoke-SmokeHarness.ps1` | Core / local |

Operator guide: [VALIDATION.md](../VALIDATION.md).

## Operator / maturity asserts (wired in validate-core)

These prove contracts and scripts exist — they are **not** a substitute for running inventory/preflight/harvest on a consumer feature. Full operator entry points: [cli-scripts.md](cli-scripts.md).

| Assert / script | Role |
|-----------------|------|
| `Assert-MemoryBankInventory.ps1` | Inventory script + `ready`/`not-ready` contract smoke |
| `Assert-PlanLedgerContract.ps1` | PLAN-LEDGER present + double-claim race |
| `Assert-TraceArchiveContract.ps1` | TRACE living-loop contract smoke |
| `Assert-TraceHarvest.ps1` | Harvest scope / exit behavior |
| `Assert-TraceEmitterFailOpen.ps1` | Fail-open emitter + `TraceEmitCommon` parity |
| `validate-trace.ps1` | Per-feature TRACE validate (`-RequireArchiveComplete` at wave close) |
| `Invoke-PrdPlanChangePreflight.ps1` | PRD/PLAN/CHANGE consistency before O3 |

Domain narrative: [TRACE](core.md#trace-archive-living-loop) · [PLAN-LEDGER](core.md#plan-ledger-atomic-step-claim) · [emitter honesty](adapters.md#trace-emitter-honesty).

## GitHub Actions

Workflow: [`.github/workflows/validate-toolkit.yml`](../../.github/workflows/validate-toolkit.yml)

| Property | Value |
|----------|--------|
| Runner | `windows-latest` |
| Triggers | push/PR to `master`, `main`, `develop` |
| Permissions | `contents: read` |
| Secrets | None |
| Home sync | Never |

Job steps (order):

1. `validate-core.ps1 -Quiet`
2. Keyed uninstall asserts (Claude, Copilot, Codex, OpenCode, Antigravity, Grok, Cursor, ZCode, Hermes, OpenHands) — **not** wired into validate-core
3. `Assert-SyncAllowUserHomeForward.ps1`
4. Ten agent CI smokes (Copilot is a suite): Cursor → Antigravity → Claude → Codex → Copilot suite → OpenCode → Grok → ZCode → Hermes → OpenHands

OpenCode smoke is filesystem-only (no product runtime).

## Local parity

Mirrors CI order: `validate-core` → keyed uninstall asserts → `Assert-SyncAllowUserHomeForward` → 10 agent smokes (Copilot is a suite).

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

## Out of smoke scope

- Live `~/.cursor`, `~/.claude`, `~/.copilot`, `~/.hermes`, `~/.agents`, …
- Agent hook **trust** UIs
- Copilot JetBrains/Eclipse host layouts
- GLM Coding Plan (endpoint-only) — not ZCode ADE
- Hermes gateway / `SOUL.md` / `config.yaml` secrets
- OpenHands Automation Server, sandbox YAML, or legacy microagents

## Related

- [domains/cli-scripts.md](cli-scripts.md)
- [ADAPTERS.md](../ADAPTERS.md)
- [ARCHITECTURE.md](../ARCHITECTURE.md)
