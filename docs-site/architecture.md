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
│    OpenCode · Grok · ZCode                              │
└──────────────────────────┬──────────────────────────────┘
                           │ InstallRoot (fixture or live install)
┌──────────────────────────▼──────────────────────────────┐
│  Install root: ~/.cursor · ~/.claude · ~/.copilot · …   │
│  Codex also: plugin skills + InstallRoot/rules (dual)   │
│           + optional ~/.agents/skills (UserScope)       │
└─────────────────────────────────────────────────────────┘
```

## Layers

| Layer | Role |
|-------|------|
| **Core** | Agent Skills (`SKILL.md`), `_shared` (incl. CATALOG via `/help-skills`), policy markdown, neutral router, SDD contracts — no hardcoded IDE install paths |
| **Adapters** | Map core → agent layout; resolve placeholders; merge hooks/settings; toolkit-managed (**keyed**) uninstall |
| **CLI** | `toolkit.ps1` / `sync-agent` / `validate-agent` — select agent, sync, validate, uninstall |
| **Validation** | Contract suite + fixture smoke tests; CI never requires a live `%USERPROFILE%` deploy for green |

After sync, the published router prefers **parallel specialist subagents** for multi-facet work (this session stays parent). Human summary: [docs/SPAWN.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/SPAWN.md); agent contract: `core/skills/_shared/agents/SPAWN.md`.

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
| `{{SDD_ROOT}}` | SDD state root (`preferences.json`, `sessions/`, global features) |
| `{{GUARDRAILS_PATH}}` | Guardrails policy file path for the target agent |

## Entry points

| Script | Purpose |
|--------|---------|
| `scripts/toolkit.ps1` | Interactive toolkit menu (**Smart Manager**) |
| `scripts/sync-agent.ps1` | Publish core into an agent InstallRoot |
| `scripts/validate-agent.ps1` | Core suite + one-agent smoke test |
| `scripts/validation/validate-core.ps1` | Repo contracts only (no install-root write) |
| `.github/workflows/validate-toolkit.yml` | CI: validate-core, uninstall asserts, eight agent smoke tests |

Per-agent install trees (Cursor, Claude, Codex, …) live in the full architecture and adapters docs — not duplicated here. See [Adapters](../adapters/).

## Full docs on GitHub

- [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) — layers, placeholders, entry points, per-agent install layouts, CI
- [docs/overview.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/overview.md) — problem statement, operator workflow, design constraints
- [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) — registry, tiers, publish surfaces, InstallRoot tables
