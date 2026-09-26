# Overview

**agent-dev-toolkit** is a multi-agent developer toolkit. One agent-neutral **core** (skills, policy, router, SDD contracts, specialist prompts) is published by **adapters** into each host **install root**. Operators sync with a PowerShell CLI, then invoke the same skill ids inside the host.

Evidence for counts and capabilities: `core/skills/*/SKILL.md` frontmatter `name` (42), `core/skills/_shared/skills-catalog/CATALOG.md`, `adapters/registry.json` (10 agents).

## Architecture

```text
core/  skills, policy, router, sdd, agents
        │  Publish-* (placeholders resolved at sync)
        ▼
adapters/<id>/  + adapters/registry.json
        │  InstallRoot (in-repo fixture, or live home with -AllowUserHome)
        ▼
host layout   ~/.cursor, ~/.claude, ~/.codex, ~/.copilot or .github, …
```

| Layer | Responsibility |
|-------|----------------|
| **Core** | Agent-neutral content. Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}` stay in source; adapters resolve them. |
| **Adapters** | Stable commands in `adapters/_contract/AdapterContract.ps1`: `Get-Capabilities`, `Get-InstallRoots`, `Publish-Skills`, `Publish-Policy`, `Publish-Router`, `Publish-Agents`, `Publish-Hooks`, `Get-SddRoot`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`. |
| **Install root** | Destination tree. Default sync target is an in-repo fixture. A path under the user profile is refused unless `-AllowUserHome` is set (`scripts/_lib/Resolve-InstallRoot.ps1`). |
| **CLI** | `scripts/toolkit.ps1` (Smart Manager or `-Action`), `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`. Release entry: `scripts/bootstrap/` downloads `agent-dev-toolkit.zip`, checks SHA256, extracts, then opens the CLI. |

`scripts/sync-agent.ps1` loads the registry module and runs the Publish commands, then always `Get-SddRoot -Prepare` (sessions directory and a seed `manifest.json` only when that file is absent).

## Registry agents (10)

| id | Display name | `subagents` (declared) |
|----|----------------|------------------------|
| `cursor` | Cursor | `native` |
| `antigravity` | Antigravity | `native` (effective value comes from `Get-Capabilities`, fail-closed probe) |
| `claude` | Claude Code | `native` |
| `codex` | Codex | `native` |
| `copilot` | GitHub Copilot | `native` |
| `opencode` | OpenCode | `native` |
| `grok` | Grok Build | `native` |
| `zcode` | ZCode | `native` |
| `hermes` | Hermes | `native` |
| `openhands` | OpenHands | `none` |

`subagents` is the string enum `native` | `none`. OpenHands stays in-parent (SPAWN fallback). Antigravity’s registry value is the 2.0+ product line; spawn only when the effective probe is `native` (`core/skills/_shared/agents/SPAWN.md`).

Host flags that change the CLI:

- **Copilot** requires `-Mode user` or `-Mode repo`.
- **Codex** optional `-UserScope` mirrors skills to a second personal root. Default sync is plugin-only under the Codex install root.
- **Live home** for any agent requires `-AllowUserHome` when the resolved install root is under the user profile.

Specialist prompt files under `core/agents/` (`architect`, `database`, `repo-analyst`, `security`, `shell-runner`) are published when the adapter’s `agents` capability is true. They are roster roles, not extra registry agents. `qa_checklist` is an in-parent role in `core/skills/_shared/agents/ROSTER.md` and has no agent file.

## Skills and the delivery path

**42** invocable skills (kebab-case `name` in each `SKILL.md`). Shared packs under `core/skills/_shared/` are not invocable skills. Agents present the map with skill `help-skills`, which reads `CATALOG.md` and `OPERATOR.md`. Human map, skill by skill: [sessions/09-every-skill.md](sessions/09-every-skill.md).

The complete path is **Orchestrated Delivery**: `memory-bank-init` (Step 0) → `orchestrate-analyze` → `orchestrate-deliver` → `orchestrate-develop`. Analyze classifies the request, asks, sets `needs_*`, calls specialists, and shapes stories. Deliver runs `sdd-spec` then `sdd-plan` for each approved story. Develop runs `sdd-develop` once per PLAN step. How that works: [sessions/01-orchestrated-delivery.md](sessions/01-orchestrated-delivery.md).

`sdd-spec`, `sdd-plan`, and `sdd-develop` remain invocable on their own when one story is already clear ([sessions/02-classic-sdd.md](sessions/02-classic-sdd.md)). `refine-story` is the scorecard and the product-only shape path; O1 applies that scorecard without a separate invoke ([sessions/03-backlog-shape.md](sessions/03-backlog-shape.md)).

Contracts: `core/sdd/` (`PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`) and copies under `core/skills/_shared/sdd-artifacts/`. Feature writes land under `features/NNN-slug/`.

## Language

`core/skills/_shared/agents/LANGUAGE.md` is the surface contract:

| Surface | Language |
|---------|----------|
| User chat and persisted artifacts (FEATURE, STORY, PRD, PLAN, and product `docs/`) | Match the user chat language for the session |
| Spawn / child prompts and agent receipts | en-US |
| Identifiers, tests, commits | English |

`core/policy/user-language-pt-br.md` and `core/policy/sdd-artifact-language-pt-br.md` still ship as install defaults that describe pt-BR chat and pt-BR SDD artifacts. That is a documented trade-off with `LANGUAGE.md`: when chat or `preferences.json` / manifest `artifact_language` says otherwise, follow `LANGUAGE.md`. This documentation set keeps both policy files.

Router index after publish: `core/router/AGENTS.md` (host file name depends on the adapter, often `AGENTS.md`).

## CLI actions and uninstall

Non-interactive `-Action` values: `Sync`, `Validate`, `SyncAndValidate`, `ValidateCore`, `ListAgents`, `Uninstall`, `Backup`.

Sync, Validate, and Uninstall require an explicit `-Agent`. **Uninstall** is keyed: each adapter’s `Uninstall-Toolkit` removes toolkit-managed paths (provenance such as `.toolkit-managed-publish.json`) and leaves alien files, `sdd/sessions`, and an existing `sdd/manifest.json`. **Backup** is a fail-closed stub; it exits with failure unless `-ForceStub` (tooling tests only) and does not call an adapter.

## Validation and CI

In-repo suite: `scripts/validation/validate-core.ps1` (`validate-all.ps1` is an alias). It does not deploy under the user profile.

GitHub Actions:

| Workflow | Role |
|----------|------|
| `.github/workflows/validate-toolkit.yml` | `pull_request` to `master`, `main`, `develop`. Jobs `validate` (`windows-latest`), `validate-ubuntu` (`ubuntu-latest`), gate `ci-ok`. |
| `.github/workflows/publish-release-bootstrap.yml` | Release zip `agent-dev-toolkit.zip` plus SHA256 sidecar and bootstrap entrypoints. |
| `.github/workflows/enforce-release-source.yml` | Pull requests into `master` / `main` must come from `develop`. |

`.github/workflows/docs.yml` is a separate site workflow. Operator docs in this folder do not describe or change that site.

## Repository map

```text
core/                 skills, policy, router, sdd, agents
adapters/             registry.json, _contract, per-agent modules
scripts/              toolkit.ps1, sync-agent.ps1, validate-agent.ps1, bootstrap/, validation/, _lib/
docs/                 this documentation
.github/workflows/    validate, release bootstrap, release-source gate
```

## Where to read next

| Topic | Document |
|-------|----------|
| Layers and per-agent install layouts | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Skill ids and tracks | [SKILLS.md](SKILLS.md) |
| SDD contracts, policy, router | [domains/core.md](domains/core.md) |
| Registry, publish, uninstall | [ADAPTERS.md](ADAPTERS.md) |
| Spawn matrix and Antigravity probe | [SPAWN.md](SPAWN.md) |
| Adapter summary | [domains/adapters.md](domains/adapters.md) |
| Bootstrap, sync, live home | [INSTALL.md](INSTALL.md) |
| CLI and operator scripts | [domains/cli-scripts.md](domains/cli-scripts.md) |
| Local validation and Actions jobs | [VALIDATION.md](VALIDATION.md) |
| How skills relate, session by session | [sessions/README.md](sessions/README.md) |
| Daily entry | [guides/README.md](guides/README.md) |
| Git commit / push / PR | [domains/git-ops.md](domains/git-ops.md) |
| Clone policy, issues, security | [REPO_GOVERNANCE.md](REPO_GOVERNANCE.md), [../CONTRIBUTING.md](../CONTRIBUTING.md), [../SECURITY.md](../SECURITY.md) |
| Third-party inspiration | [CREDITS.md](CREDITS.md) |
