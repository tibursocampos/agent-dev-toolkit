# Agent Dev Toolkit

Unified multi-agent skills **core** with per-agent **adapters**. Sync the same SDD workflows, stack skills, and policy into Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, and ZCode ADE.

**Public** — clone and fork freely; **no upstream contributions**; GitHub Issues are **bugs only** (see [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/REPO_GOVERNANCE.md](docs/REPO_GOVERNANCE.md)). Security: [SECURITY.md](SECURITY.md).

## What this is

| Layer | Role |
|-------|------|
| **Core** | Agent Skills (`core/skills/`), policy, router, SDD contracts — agent-neutral |
| **Adapters** | Publish core into each agent’s install layout (`~/.cursor`, `~/.claude`, …) |
| **CLI** | `toolkit.ps1`, `sync-agent.ps1`, `validate-agent.ps1` |
| **Validation** | In-repo fixtures + CI smokes — no live home write required for green |

## Quick start

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit

# Primary entry — interactive Smart Manager
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

In the menu:

1. **Sync agent** — pick an agent, then **live agent home** (Enter = default; writes under your profile after confirm), **in-repo fixture** (safe), or **custom** path.
2. **Validate core only** — `validate-core` repo contracts with no home write.
3. **Help and docs** — what each action does and equivalent `-Action` flags.

Advanced / scripting flags (`-Action`, `-Agent`, `-InstallRoot`, `-AllowUserHome`, `-Mode`) and CI smokes (`Invoke-CursorCiSmoke`, `Invoke-ClaudeCiSmoke`, …): **[docs/INSTALL.md](docs/INSTALL.md)**, **[docs/VALIDATION.md](docs/VALIDATION.md)**.  
First use end-to-end: **[docs/guides/01-getting-started.md](docs/guides/01-getting-started.md)**.

### Use skills (after sync)

Open a consumer project in your agent and invoke skills by **id** (slash `/` when the host supports it):

| Workflow | Invoke |
|----------|--------|
| Catalog (all adapters) | `help-skills` → static `CATALOG.md` + `OPERATOR.md` |
| Classic SDD | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| Stack shortcut | `developer` or `dotnet-developer` / `react-developer` / … |
| Forma C | `memory-bank-init` → `orchestrate-analyze` → `orchestrate-deliver` → `orchestrate-develop` |
| Greenfield ARCH | Via Forma C analyze: architect draft → **sim** confirm (not a slash skill) |

Parallel specialists for multi-facet work are the **router default** after sync (see `core/router/AGENTS.md`). Catalog: **[docs/SKILLS.md](docs/SKILLS.md)**. Daily decision tree: **[docs/guides/README.md](docs/guides/README.md)**. Credits: **[docs/CREDITS.md](docs/CREDITS.md)**.

## Supported agents

| id | Display name | Typical live root | Notes |
|----|--------------|-------------------|--------|
| `cursor` | Cursor | `~/.cursor` | Skills, `.mdc` rules, hooks |
| `antigravity` | Antigravity | `~/.gemini` | Official `config/*` layout |
| `claude` | Claude Code | `~/.claude` | Skills, rules `.md`, `CLAUDE.md`, settings merge |
| `codex` | Codex | `~/.codex` | Dual-root: plugin skills under `InstallRoot/plugin`; rules via Publish-Policy → `InstallRoot/rules`; optional USER skills `~/.agents/skills` with `-UserScope`; default sync **plugin-only** |
| `copilot` | GitHub Copilot | `~/.copilot` or `.github` | `-Mode user\|repo` required |
| `opencode` | OpenCode | `~/.config/opencode` | Hooks = JS plugins only |
| `grok` | Grok Build | `~/.grok` | Native `.grok` publish |
| `zcode` | ZCode (Z.ai ADE) | `~/.zcode` | ADE filesystem; not GLM Coding Plan |

Per-agent contract: **[docs/ADAPTERS.md](docs/ADAPTERS.md)**.

## Skills preview (38)

| Group | Examples |
|-------|----------|
| Forma A (SDD) | `sdd-spec`, `sdd-plan`, `sdd-develop` |
| Forma B | `refine-story`, `split-story-checklist` |
| Forma C | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| Stack | `developer`, `dotnet-developer`, `java-developer`, `react-developer`, `angular-developer`, `vue-developer`, … |
| Ops | `help-skills`, `code-review`, `commit`, `push`, `open-github-pr`, `test-coverage`, `repair-dotnet-build`, … |

Full list: **[docs/SKILLS.md](docs/SKILLS.md)** · agent SoT: `help-skills` → `_shared/skills-catalog/CATALOG.md` + `OPERATOR.md`.

## Documentation

| Doc | Content |
|-----|---------|
| [docs/README.md](docs/README.md) | Documentation index / TOC |
| [docs/overview.md](docs/overview.md) | Architecture overview (RAG-friendly) |
| [docs/INSTALL.md](docs/INSTALL.md) | Clone, sync, live home, uninstall |
| [docs/VALIDATION.md](docs/VALIDATION.md) | validate-core + keyed uninstall asserts + AllowUserHome forward + 8 agent smokes |
| [docs/SKILLS.md](docs/SKILLS.md) | Skill catalog |
| [docs/CREDITS.md](docs/CREDITS.md) | Third-party inspiration (Caveman, Impeccable, Spec Kit) |
| [docs/guides/07-caveman-mode.md](docs/guides/07-caveman-mode.md) | Caveman default OFF, commands, levels |
| [docs/guides/README.md](docs/guides/README.md) | Decision tree + guides |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers and install layouts |
| [docs/ADAPTERS.md](docs/ADAPTERS.md) | Adapter registry and per-agent publish |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Clone/fork OK; no upstream PRs; Issues = bugs only |
| [docs/REPO_GOVERNANCE.md](docs/REPO_GOVERNANCE.md) | OSS audiences + policy pointers |
| [SECURITY.md](SECURITY.md) | Vulnerability reporting (no invented private email) |

### Domains

| Domain | Content |
|--------|---------|
| [docs/domains/core.md](docs/domains/core.md) | Skills, policy, router, SDD |
| [docs/domains/adapters.md](docs/domains/adapters.md) | Registry + Tier 1 adapters |
| [docs/domains/cli-scripts.md](docs/domains/cli-scripts.md) | toolkit / sync / validate |
| [docs/domains/validation-ci.md](docs/domains/validation-ci.md) | Fixtures and CI workflow |

## Repository layout

```text
agent-dev-toolkit/
  core/                 # skills, policy, router, SDD contracts
  adapters/             # registry.json + per-agent modules
  scripts/              # toolkit.ps1, sync-agent, validate-agent, validation/
  docs/                 # public documentation
  memory-bank/          # durable workspace map (Forma C Step 0)
  .github/workflows/    # validate-toolkit.yml (+ enforce-release-source.yml)
  README.md
  CONTRIBUTING.md
  SECURITY.md
```

## Safety

- Default `InstallRoot` is an **in-repo fixture** — CI never writes under `%USERPROFILE%`.
- Live agent home requires **`-AllowUserHome`**.
- Uninstall is **keyed** (toolkit artifacts only) for all Tier-1 agents — **not** a wholesale home wipe. Preserves `sdd/sessions` and `sdd/manifest.json`.

CI runs `validate-core`, keyed uninstall asserts, `Assert-SyncAllowUserHomeForward`, plus all eight agent CI smokes on push/PR to `develop` / `master` / `main` (see `.github/workflows/validate-toolkit.yml`). Release PRs into `master`/`main` must come from `develop` (`enforce-release-source.yml`).

## License

[MIT](LICENSE) © 2026 Raphael Campos. See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution policy (clone/fork OK; no community PRs).
