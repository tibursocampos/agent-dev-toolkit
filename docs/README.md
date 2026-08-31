# Documentation index

Public documentation for **agent-dev-toolkit**. Start with [INSTALL.md](INSTALL.md) or [guides/01-getting-started.md](guides/01-getting-started.md).

**Install option 1:** interactive Smart Manager — `pwsh -NoProfile -File .\scripts\toolkit.ps1`. **Option 2+** (`-Action Sync` / `sync-agent.ps1`) is for scripting and CI.

## Start here

| Document | Audience | Purpose |
|----------|----------|---------|
| [INSTALL.md](INSTALL.md) | Everyone | Prerequisites, clone, sync, live home, uninstall |
| [guides/README.md](guides/README.md) | Daily usage | Decision tree — which skill / **work track** to use |
| [guides/01-getting-started.md](guides/01-getting-started.md) | New users | End-to-end first use |
| [guides/02-using-skills.md](guides/02-using-skills.md) | Everyone | Invoking skills after sync |
| [VALIDATION.md](VALIDATION.md) | Operators / **Maintainers** / CI | Audiences + validate-core + keyed uninstall asserts + AllowUserHome forward + 10 agent smokes (Copilot is a suite; visitors: read only) |
| [SKILLS.md](SKILLS.md) | Everyone | Canonical skill catalog (38 skills; agent SoT via `help-skills` → CATALOG + OPERATOR) |
| [CREDITS.md](CREDITS.md) | Everyone | Third-party inspiration (Caveman, Impeccable, Spec Kit) |
| [guides/07-caveman-mode.md](guides/07-caveman-mode.md) | Everyone | Caveman default OFF, commands, levels |
| [guides/08-orchestrator-mode.md](guides/08-orchestrator-mode.md) | Everyone | Orchestrator charter, `orchestrator_mode`, commands |

## Overview and architecture

| Document | Purpose |
|----------|---------|
| [overview.md](overview.md) | High-level architecture + domain links |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layers, core paths, per-agent install layouts |
| [ADAPTERS.md](ADAPTERS.md) | Registry, capabilities, per-agent publish details |
| [SPAWN.md](SPAWN.md) | Spawn / subagents matrix (human summary; agents use `core/skills/_shared/agents/SPAWN.md`) |
| Language surfaces | Chat + artifacts = user chat language; spawn/receipts = en-US (`core/skills/_shared/agents/LANGUAGE.md`) |

## Domains (deep dives)

| Domain | Content |
|--------|---------|
| [domains/core.md](domains/core.md) | `core/skills`, policy, router, SDD contracts; [§ Code guidelines and architecture selection](domains/core.md#code-guidelines-and-architecture-selection) (A/B/C, confirm gate, token discipline) |
| [domains/adapters.md](domains/adapters.md) | Registry + implemented adapters (summary → ADAPTERS.md) |
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
| `documentation-plan/plan.md` | Maintainer doc plan (`document-plan` / `document-implement`). **Gitignored** — created/updated at feature **P-DOC** (e.g. 005 modernize SDD contracts). Do not publish via MkDocs. |

For daily skill choice, prefer **[guides/README.md](guides/README.md)** over reading `SKILL.md` files directly.
