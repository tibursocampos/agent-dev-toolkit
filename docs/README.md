# Documentation index

Public documentation for **agent-dev-toolkit**. Start with [INSTALL.md](INSTALL.md) or [guides/01-getting-started.md](guides/01-getting-started.md).

## Start here

| Document | Audience | Purpose |
|----------|----------|---------|
| [INSTALL.md](INSTALL.md) | Everyone | Prerequisites, clone, sync, live home, uninstall |
| [guides/README.md](guides/README.md) | Daily usage | Decision tree — which skill / Forma to use |
| [guides/01-getting-started.md](guides/01-getting-started.md) | New users | End-to-end first use |
| [guides/02-using-skills.md](guides/02-using-skills.md) | Everyone | Invoking skills after sync |
| [VALIDATION.md](VALIDATION.md) | Operators / **Maintainers** / CI | Audiences + validate-core + keyed uninstall asserts + AllowUserHome forward + 8 agent smokes (visitors: read only) |
| [SKILLS.md](SKILLS.md) | Everyone | Canonical skill catalog (38 skills; agent SoT via `help-skills` → CATALOG + OPERATOR) |
| [CREDITS.md](CREDITS.md) | Everyone | Third-party inspiration (Caveman, Impeccable, Spec Kit) |
| [guides/07-caveman-mode.md](guides/07-caveman-mode.md) | Everyone | Caveman default OFF, commands, levels |

## Overview and architecture

| Document | Purpose |
|----------|---------|
| [overview.md](overview.md) | High-level architecture + domain links |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layers, core paths, per-agent install layouts |
| [ADAPTERS.md](ADAPTERS.md) | Registry, capabilities, per-agent publish details |
| [SPAWN.md](SPAWN.md) | Tier-1 spawn / subagents matrix (human summary; agents use `core/skills/_shared/agents/SPAWN.md`) |

## Domains (deep dives)

| Domain | Content |
|--------|---------|
| [domains/core.md](domains/core.md) | `core/skills`, policy, router, SDD contracts; [§ Code guidelines and architecture selection](domains/core.md#code-guidelines-and-architecture-selection) (A/B/C, confirm gate, token discipline) |
| [domains/adapters.md](domains/adapters.md) | Registry + Tier 1 adapters (summary → ADAPTERS.md) |
| [domains/cli-scripts.md](domains/cli-scripts.md) | toolkit / sync-agent / validate-agent |
| [domains/validation-ci.md](domains/validation-ci.md) | Fixtures, smoke harnesses, GitHub Actions |

## Policy

| Path | Purpose |
|------|---------|
| [../CONTRIBUTING.md](../CONTRIBUTING.md) | Clone/fork OK; no community PRs; Issues = bugs only |
| [REPO_GOVERNANCE.md](REPO_GOVERNANCE.md) | OSS audiences + policy pointers |
| [../SECURITY.md](../SECURITY.md) | Vulnerability reporting |
| [../README.md](../README.md) | Landing page and quick start |

## Documentation plan

| Path | Purpose |
|------|---------|
| `documentation-plan/` (local / gitignored) | Maintainer-only doc plan (`plan.md` via `document-plan` / `document-implement`). **Not versioned** in this toolkit — create locally when needed; do not link or publish it. |

For daily skill choice, prefer **[guides/README.md](guides/README.md)** over reading `SKILL.md` files directly.
