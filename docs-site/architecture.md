# Architecture

**agent-dev-toolkit** keeps one agent-neutral **core** (skills, policy, router, SDD contracts) and **adapters** that publish it into each agent’s native install layout. Operators sync via CLI; CI validates against fixtures, not live installs.

For the product walkthrough, start at [Get started](../get-started/). Per-agent publish surfaces: [Adapters](../adapters/). After sync: [Using skills](../using-skills/).

## High-level flow

```text
┌─────────────────────────────────────────────────────────┐
│  core/                                                  │
│    skills/   policy/   router/   sdd/                   │
└──────────────────────────┬──────────────────────────────┘
                           │ Publish-* (placeholders resolved)
┌──────────────────────────▼──────────────────────────────┐
│  adapters/<agent>/  ← registry.json                     │
│    Cursor · Claude · Codex · Copilot · Antigravity ·    │
│    OpenCode · Grok · ZCode · Hermes · OpenHands         │
└──────────────────────────┬──────────────────────────────┘
                           │ InstallRoot (fixture or live install)
┌──────────────────────────▼──────────────────────────────┐
│  Install root: ~/.cursor · ~/.claude · ~/.hermes · …    │
│  Codex also: plugin skills + InstallRoot/rules (dual)   │
│           + optional ~/.agents/skills (UserScope)       │
│  OpenHands: project .agents/skills · live ~/.agents     │
└─────────────────────────────────────────────────────────┘
```

## Layers

| Layer | Role |
|-------|------|
| **Core** | Agent Skills (`SKILL.md`), `_shared` (incl. CATALOG via `/help-skills`), policy markdown, neutral router, SDD contracts — no hardcoded IDE install paths |
| **Adapters** | Map core → agent layout; resolve placeholders; merge hooks/settings; toolkit-managed (**keyed**) uninstall |
| **CLI** | `toolkit.ps1` / `sync-agent` / `validate-agent` — select agent, sync, validate, uninstall |
| **Validation** | Contract suite + fixture smoke tests; CI never requires a live `%USERPROFILE%` deploy for green |

After sync, the published router prefers **parallel specialist subagents** for multi-facet work (this session stays parent). Caps: `*-developer` children **≤ 2**; `orchestrate-*` parallel **≤ 4** (wave if more). Human summary: [docs/SPAWN.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/SPAWN.md); agent contract: `core/skills/_shared/agents/SPAWN.md`. Language surfaces: `core/skills/_shared/agents/LANGUAGE.md` (chat + artifacts match user chat; spawn/receipts **en-US**).

## Repo layout

```text
core/          # skills (kebab), policy, router, sdd contracts
adapters/      # per-agent modules + registry.json + _contract
scripts/       # toolkit.ps1, sync-agent, validate-agent, _lib, validation
docs/          # public documentation (source of truth for deep dives)
.github/workflows/validate-toolkit.yml
```

## Path placeholders

Core content must not hardcode a single IDE user-profile root. Adapters resolve these at publish:

| Placeholder | Meaning |
|-------------|---------|
| `{{TOOLKIT_ROOT}}` | Agent toolkit install root (destination-aware; Codex splits plugin skills vs InstallRoot `rules/`) |
| `{{SDD_ROOT}}` | SDD state under InstallRoot (`sessions/`, `preferences.json`, `manifest.json` v2, optional **global** feature trees) |
| `{{GUARDRAILS_PATH}}` | Guardrails policy file path for the target agent |

At runtime, skills prefer host-aware **`effective_SDD_ROOT`** (`<InstallRoot>/sdd`) over a baked `{{SDD_ROOT}}` from another agent home — see [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) and [core/sdd/STORAGE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/core/sdd/STORAGE.md).

**Repository vs global artifacts:** **repository** mode keeps Classic `features/` + `memory-bank/` in the application project cwd; **global** mode keeps the same tree under `{{SDD_ROOT}}/<repo-id>/`. The InstallRoot `sdd/` folder always holds sessions, prefs, and the per-repo manifest — not the repository-mode feature tree.

## Entry points

| Script | Purpose |
|--------|---------|
| `scripts/toolkit.ps1` | Interactive toolkit menu (**Smart Manager**) |
| `scripts/sync-agent.ps1` | Publish core into an agent InstallRoot |
| `scripts/validate-agent.ps1` | Core suite + one-agent smoke test |
| `scripts/validation/validate-core.ps1` | Repo contracts only (no install-root write) |
| `.github/workflows/validate-toolkit.yml` | CI: validate-core, uninstall asserts, ten agent smoke tests |

Per-agent install trees (Cursor, Claude, Codex, …) live in the full architecture and adapters docs — not duplicated here. See [Adapters](../adapters/).

## Maturity contracts (same call flow)

Feature **006** surfaces live under `core/skills/_shared/sdd-artifacts/` and related packs. Same Classic SDD / Backlog Refine / Orchestrated Delivery skill ids — more gates and artifacts, not a second toolkit.

| Surface | What it does | Deep dive |
|---------|--------------|-----------|
| **Invocation** | `direct` vs `orchestrated` (`INVOCATION-CONTEXTS.md`) | [domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md#invocation-contexts-direct-vs-orchestrated) |
| **Provenance** | `agreed` vs `invented` (`CONTRACT-PROVENANCE.md`) | [domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md#contract-provenance-agreed-vs-invented) |
| **`read-sdd-artifact`** | Normalize FEATURE/STORY/PRD/PLAN → `source_context` | [domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md#skill-read-sdd-artifact-source_context) |
| **PLAN-LEDGER** | Atomic O3 step claim (`PLAN-LEDGER-CONTRACT.md`) | [domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md#plan-ledger-atomic-step-claim) |
| **TRACE archive** | Living loop SoT: `features/NNN-slug/TRACE.jsonl` only | [domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md#trace-archive-living-loop) |

Do **not** invent alternate TRACE roots (`.agent-trace/`, OpenSpec / `.specs/` / `.specify/`, SQLite/FTS as SoT). Host emitters are claimed only where wired — [Adapters](../adapters/).

## Full docs on GitHub

- [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) — layers, placeholders, entry points, per-agent install layouts, CI
- [docs/overview.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/overview.md) — problem statement, operator workflow, design constraints
- [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) — registry, publish surfaces, InstallRoot tables
- [docs/domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md) — SDD contracts, invocation, TRACE, PLAN-LEDGER
