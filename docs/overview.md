# Overview

**agent-dev-toolkit** is a multi-agent developer toolkit: one shared **core** of Agent Skills, policy, router, and SDD contracts, plus **adapters** that publish that core into each agent’s native install layout.

## Problem it solves

Teams use different coding agents (Cursor, Claude Code, Codex, Copilot, and others). Duplicating skills and rules per agent drifts quickly. This repo keeps a single source under `core/` and maps it through adapters at sync time.

## Architecture (summary)

```text
┌─────────────────────────────────────────────────────────┐
│  core/                                                  │
│    skills/   policy/   router/   sdd/                   │
└──────────────────────────┬──────────────────────────────┘
                           │ Publish-* (placeholders resolved)
┌──────────────────────────▼──────────────────────────────┐
│  adapters/<agent>/  ← registry.json                     │
│    Cursor · Claude · Codex · Copilot · …                │
└──────────────────────────┬──────────────────────────────┘
                           │ InstallRoot (fixture or live home)
┌──────────────────────────▼──────────────────────────────┐
│  Agent home: ~/.cursor · ~/.claude · ~/.codex · …       │
│  Codex also: optional USER skills under ~/.agents/skills│
└─────────────────────────────────────────────────────────┘
```

| Layer | Responsibility |
|-------|----------------|
| **Core** | Agent-neutral content; no hardcoded IDE home paths (use `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}`); shared `code-guidelines` + architecture selection (A/B/C, one-style load); **38** skills + `_shared` (agent SoT via `help-skills` → `skills-catalog/CATALOG.md` + `OPERATOR.md`) |
| **Adapters** | Map core → agent layout; merge hooks/settings safely; keyed uninstall (all Tier-1) |
| **CLI** | Select agent; sync / validate / list / uninstall |
| **Validation** | Contract suite + fixture smokes; CI never requires `%USERPROFILE%` |

## Workflow for operators

1. **Clone** the repo.
2. **Sync** an agent (`sync-agent.ps1 -Agent <id>`), optionally with `-AllowUserHome` for a live home. Codex defaults to **plugin-only**; add `-UserScope` only when you need the USER skills mirror (see [ADAPTERS.md](ADAPTERS.md) § Codex).
3. **Validate** with `validate-core.ps1` and/or `Invoke-*CiSmoke.ps1` (e.g. `validate-agent.ps1 -Agent codex` against the fixture).
4. **Use skills** in the agent (e.g. `help-skills` → `CATALOG.md` + `OPERATOR.md` for the installed map of **38** skills; parallel specialists are the **router default** after sync — see [SPAWN.md](SPAWN.md); `sdd-spec` after sync; ops: `commit` → `push` → `open-github-pr`).

See [INSTALL.md](INSTALL.md), [VALIDATION.md](VALIDATION.md), [SKILLS.md](SKILLS.md), [guides/02-using-skills.md](guides/02-using-skills.md).

## Domains

| Domain | Doc | What you learn |
|--------|-----|----------------|
| Core | [domains/core.md](domains/core.md) | Skills tree, policy, router, SDD contracts (repository vs global storage); shared guidelines + architecture selection (A/B/C) |
| Git ops | [domains/git-ops.md](domains/git-ops.md) | `/commit` → `/push` → `/open-github-pr`; branch rules; feature vs release templates |
| Adapters | [domains/adapters.md](domains/adapters.md) | Registry, tiers, publish surfaces (incl. Codex dual-root) |
| CLI | [domains/cli-scripts.md](domains/cli-scripts.md) | toolkit / sync / validate parameters |
| Validation & CI | [domains/validation-ci.md](domains/validation-ci.md) | Fixtures, smokes, workflow |

Related deep docs: [ARCHITECTURE.md](ARCHITECTURE.md), [ADAPTERS.md](ADAPTERS.md), [guides/02-using-skills.md](guides/02-using-skills.md).

## Design constraints

- **Fail closed on home:** paths under the user profile need `-AllowUserHome`.
- **Fixture-first CI:** smokes use `scripts/validation/fixtures/…`.
- **Keyed uninstall:** remove toolkit-managed artifacts only for all Tier-1 agents. Preserves `sdd/sessions` and `sdd/manifest.json`.
- **Sync prepare:** every sync runs `Get-SddRoot -Prepare` (`sdd/sessions/` + seed `manifest.json` when absent; seed never overwrites). Manifest schema v2; storage modes in [domains/core.md](domains/core.md) § SDD / [STORAGE.md](../core/sdd/STORAGE.md).
- **Honest capabilities:** registry / `Get-Capabilities` flags reflect real publish support for `skills` / `rules` / `hooks` / `router` / `plugin` (e.g. OpenCode hooks are plugin JS only).
- **Codex dual-root:** plugin skills + CATALOG live under `InstallRoot/plugin`; Publish-Policy writes `InstallRoot/rules`; product/AGENTS/hooks parent is InstallRoot (live `~/.codex`). Optional `-UserScope` mirrors skills to fixture `InstallRoot/.agents/skills` or live `~/.agents/skills` — default sync is **plugin-only**. Do not treat skills and rules as one shared TOOLKIT_ROOT.

## Navigation

- [Documentation index](README.md)
- [Getting started](guides/01-getting-started.md)
- [Using skills](guides/02-using-skills.md)
- [Caveman mode](guides/07-caveman-mode.md)
- [Credits](CREDITS.md)
- [Spawn / subagents](SPAWN.md)
- [Guides hub](guides/README.md)
