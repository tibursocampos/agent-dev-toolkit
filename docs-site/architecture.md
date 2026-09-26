---
title: Architecture
---

# Architecture

**agent-dev-toolkit** is one agent-neutral core, published by adapters into each host install root. Operators sync with a PowerShell CLI, then invoke the same skill ids in the host. Evidence: `core/skills/*/SKILL.md` (**42** skills), `adapters/registry.json` (**10** agents).

```text
core/  skills, policy, router, sdd, agents
        │  Publish-* (placeholders resolved at sync)
        ▼
adapters/<id>/  + adapters/registry.json
        │  InstallRoot (in-repo fixture, or live home with -AllowUserHome)
        ▼
host layout   ~/.cursor, ~/.claude, ~/.codex, ~/.copilot or .github, …
```

## Layout

```text
core/          skills, policy, router, sdd contracts, agents
adapters/      per-agent modules, registry.json, _contract
scripts/       toolkit.ps1, sync-agent, validate-agent, _lib, validation, bootstrap
docs/          operator documentation in the repository
.github/workflows/validate-toolkit.yml
.github/workflows/publish-release-bootstrap.yml
.github/workflows/enforce-release-source.yml
```

## Layers

| Layer | Role |
|-------|------|
| Core | Agent Skills (`SKILL.md`), `_shared`, policy markdown, neutral router, SDD contracts. Placeholders stay in source |
| Adapters | Publish skills, policy, router, hooks, and agents into the host layout. Smoke uses a fixture InstallRoot |
| CLI | `scripts/toolkit.ps1` chooses the agent for sync, validate, and uninstall |
| Install root | Destination. Default sync target is an in-repo fixture. A user-profile path needs `-AllowUserHome` |
| CI | `validate-toolkit.yml` on `pull_request` to `master`, `main`, `develop`. A green run does not sync a live home |

Stable adapter commands: `Get-Capabilities`, `Get-InstallRoots`, `Publish-Skills`, `Publish-Policy`, `Publish-Router`, `Publish-Agents`, `Publish-Hooks`, `Get-SddRoot`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`.

`scripts/sync-agent.ps1` runs Publish, then always `Get-SddRoot -Prepare`. CLI actions: `Sync`, `Validate`, `SyncAndValidate`, `ValidateCore`, `ListAgents`, `Uninstall`, `Backup`. Sync, Validate, and Uninstall require `-Agent`. Uninstall is keyed and keeps `sdd/sessions` and an existing `sdd/manifest.json`. Backup fails closed unless `-ForceStub`.

The feature path published from this core is Orchestrated Delivery (`orchestrate-analyze` → `orchestrate-deliver` → `orchestrate-develop`). Deliver runs `sdd-spec` then `sdd-plan`. Develop runs one `sdd-develop` step per child. Detail: [First use](first-use.md). Per-agent flags: [Adapters](adapters.md).

## How a consumer app picks a style

This is separate from the toolkit’s own core and adapter layout. The guidelines pack is `core/skills/_shared/code-guidelines/`.

| Mode | Flow |
|------|------|
| **Greenfield** | Roster specialist **architect** proposes via Layer A (`architecture-selection.md`) → ARCH draft → **sim** → ARCH approved. There is no silent default style |
| **Brownfield** | Mirror the in-repo or approved ARCH style. Re-select only if you ask to change it |

After confirm (or a brownfield mirror): load **one** Layer B file under `principles/architecture/`, then the matching Layer C stack overlay. `orchestrate-analyze` runs the confirm gate when nature is greenfield or `needs_domain` without an established style.

## Source policy

- Product content for agents lives under `core/`.
- Public SDD state file name: `manifest.json`.
- `core/skills/` — 42 skills plus `_shared`. Agents read the map with `help-skills` (`CATALOG.md` and `OPERATOR.md`).
- `core/policy/` — rule bodies (`.md`; adapters may normalize to `.mdc` or instructions).
- `core/router/` — neutral router (`AGENTS.md`). The host file name depends on the adapter.
- `core/sdd/` — `PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`, reached through `Get-SddRoot`.

Specialist prompts under `core/agents/` (`architect`, `database`, `repo-analyst`, `security`, `shell-runner`) publish when `agents` is true. `qa_checklist` has no agent file.

## Placeholders

Core content does not hardcode a single IDE home. Adapters resolve placeholders at publish.

| Placeholder | Meaning |
|-------------|---------|
| `{{TOOLKIT_ROOT}}` | Toolkit install root. Codex splits plugin skills from InstallRoot rules |
| `{{SDD_ROOT}}` | SDD state root (`preferences.json`, `sessions/`, `manifest.json`, optional global Classic tree) |
| `{{GUARDRAILS_PATH}}` | Guardrails policy path for the target agent |

At runtime, skills resolve SDD state via `effective_SDD_ROOT` so a foreign agent’s baked path does not win. `effective_SDD_ROOT` holds sessions, preferences, and `manifest.json` (schema v2), plus optional **global** `features/` and `memory-bank/` when `classic.storage_mode` is `global`. **Repository** mode keeps those trees under the consumer `$Cwd`.

Prepared `mustNotContain` needles: `scripts/validation/contracts/must-not-contain-ide.json`. Core suite: `scripts/validation/validate-core.ps1` (alias `validate-all.ps1`). Brand names may appear in co-author rules. They are not filesystem home paths.

## Entry points

- `scripts/toolkit.ps1`
- `scripts/sync-agent.ps1`
- `scripts/validate-agent.ps1`
- `scripts/validation/validate-core.ps1`
- `scripts/validation/Assert-SyncAllowUserHomeForward.ps1`
- `scripts/validation/Invoke-CursorCiSmoke.ps1`
- `scripts/validation/Invoke-AntigravityCiSmoke.ps1`
- `scripts/validation/Invoke-ClaudeCiSmoke.ps1`
- `scripts/validation/Invoke-CodexCiSmoke.ps1`
- `scripts/validation/Invoke-CopilotCiSmokeSuite.ps1`
- `scripts/validation/Invoke-OpenCodeCiSmoke.ps1`
- `scripts/validation/Invoke-GrokCiSmoke.ps1`
- `scripts/validation/Invoke-ZCodeCiSmoke.ps1`
- `scripts/validation/Invoke-HermesCiSmoke.ps1`
- `scripts/validation/Invoke-OpenHandsCiSmoke.ps1`
- `.github/workflows/validate-toolkit.yml`
- `.github/workflows/publish-release-bootstrap.yml`
- `.github/workflows/enforce-release-source.yml`

## Cursor

InstallRoot models `~/.cursor`.

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Skills from `core/skills/` |
| `rules/*.mdc` | Policy (`.md` → `.mdc`) |
| `AGENTS.md` | Router |
| `hooks/*.ps1` | Including `guard-pre-tool.ps1` and `GuardCommon.ps1` |
| `hooks.json` | `preToolUse` and `beforeShellExecution` (`failClosed`) |
| `agents/*.md` | Roster when `agents=true` |
| `sdd/sessions/` | Sessions (`Get-SddRoot -Prepare`) |
| `sdd/manifest.json` | Seed when absent. Never overwrite an existing file |

Fixture: `scripts/validation/fixtures/cursor-install-root`. Smoke: `Invoke-CursorCiSmoke.ps1` on an ephemeral copy. CI does not write a live `~/.cursor` and does not drive the hooks trust UI.

## Antigravity

InstallRoot models `~/.gemini`.

| Relative path | Role |
|---------------|------|
| `config/skills` | Kebab skills plus `dev_persona` |
| `config/plugins` | Plugin surface (GUARDRAILS under the managed plugin id) |
| `config/hooks` | PreToolUse path and secrets guard when `hooks=true` |
| `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` | Discovery and managed markdown |

`antigravity-ide/plugins` is a legacy bridge, documentation and opt-in only. It is not a CI gate. Live Knowledge Items and the IDE trust UI are out of scope. Smoke: `Invoke-AntigravityCiSmoke.ps1`. Registry `subagents` is `native`. The effective value comes from `Get-Capabilities` (fail-closed probe).

## Codex

Live product home is `~/.codex`. USER skills discovery is `~/.agents/skills`. Plugin skills and InstallRoot rules are not one shared `TOOLKIT_ROOT`.

| Relative path | Role |
|---------------|------|
| `plugin/.codex-plugin/plugin.json` | Plugin manifest (`skills: ./skills/`) |
| `plugin/skills/<kebab-id>/SKILL.md` | Plugin-bundled skills |
| `plugin/skills/_shared/skills-catalog/CATALOG.md` and `OPERATOR.md` | Map via `help-skills` |
| `rules/*.md` | Policy |
| `.agents/plugins/marketplace.json` | Local marketplace entry |
| `AGENTS.md` | Materialized dual-root absolute paths |
| `plugin/hooks/hooks.json` | Plugin hooks. `/hooks` trust is manual |
| `.agents/skills/` | Optional `-UserScope` (live: `$HOME/.agents/skills` plus `-AllowUserHome`) |

Default sync is plugin-only. Fixture: `scripts/validation/fixtures/codex`.

## Claude Code

InstallRoot models `~/.claude` or project `.claude`.

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `rules/*.md` | Policy (`.md`, not `.mdc`) |
| `CLAUDE.md` | Router |
| `hooks/*.ps1` | From `adapters/claude/assets/hooks/` |
| `settings.json` | Keyed hook upsert plus additive `permissions.allow`. UTF-8 without BOM. Backup `.bak` |

Fixture: `scripts/validation/fixtures/claude`. Smoke: `Invoke-ClaudeCiSmoke.ps1`.

## OpenCode

InstallRoot models `~/.config/opencode`.

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `AGENTS.md` | Router |
| `agents/*.md` | `Publish-Agents` |
| `plugins/*.js` | JS plugins. `tool.execute.before` path and secrets throw |

Hooks are plugin-only. Smoke: `Invoke-OpenCodeCiSmoke.ps1` (filesystem only).

## ZCode

InstallRoot models `~/.zcode` (ADE filesystem, not GLM Coding Plan).

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Router |
| `agents/*.md` | Roster |
| `cli/config.json` | Hooks config |
| `hooks/hooks.json` | PreToolUse path and secrets |

Fixture: `scripts/validation/fixtures/zcode-install-root/`. Smoke: `Invoke-ZCodeCiSmoke.ps1`.

## GitHub Copilot

`-Mode user|repo` is required. The relative tree is the same under either root.

| Mode | InstallRoot models | Fixture |
|------|--------------------|---------|
| `user` | `~/.copilot` | `scripts/validation/fixtures/copilot/user` |
| `repo` | `.github` | `scripts/validation/fixtures/copilot/repo` |

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `instructions/*.instructions.md` | Policy |
| `copilot-instructions.md` | Always-on instructions from the router source |
| `hooks/*` | `version:1` `preToolUse` path and secrets |

JetBrains and Eclipse layouts are out of scope. Smoke: `Invoke-CopilotCiSmokeSuite.ps1`.

## Grok Build

InstallRoot is `~/.grok` (or a project `.grok` you pass). The tree is native, not nested `.grok/.grok`.

| Relative path | Role |
|---------------|------|
| `skills` | Skills, live `~/.grok/skills` |
| `rules` | Policy |
| `agents` | Roster |
| `hooks` | PreToolUse. `/hooks-trust` is manual |
| `AGENTS.md` | Router |

Fixture: `scripts/validation/fixtures/grok`.

## Hermes

InstallRoot is the Hermes home. Windows: `%LOCALAPPDATA%\hermes`. POSIX: `~/.hermes`. Skills and `AGENTS.md` sit directly under that root.

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Router plus folded policy. No `rules/` tree |
| `plugins/agent-dev-toolkit-guard` and `agent-hooks/` | Path and secrets hooks |
| `memories/MEMORY.md` | Seeded once if missing |
| `SOUL.md` | Never created or overwritten |

`Publish-Agents` is a no-op (`agents=false`). Subagents: host `delegate_task`. Fixture: `scripts/validation/fixtures/hermes`. Smoke: `Invoke-HermesCiSmoke.ps1`.

## OpenHands

Project InstallRoot is a repository tree.

| Relative path | Role |
|---------------|------|
| `.agents/skills/<id>/SKILL.md` | Skills, not legacy microagents |
| `.agents/agents/*.md` | Roster. Not native spawn |
| `AGENTS.md` | Router plus folded policy |
| `.openhands/hooks.json` and `.openhands/hooks/*.sh` | Shell hooks, including `guard_pre_tool.sh` |
| `.plugin/plugin.json` | Plugin metadata. Skills work without the plugin |

Live user skills: `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` publishes `skills/` under that home. `subagents=none`. Fixture: `scripts/validation/fixtures/openhands`. Smoke: `Invoke-OpenHandsCiSmoke.ps1`.

## CI

`.github/workflows/validate-toolkit.yml` runs on `pull_request` to `master`, `main`, and `develop`. Jobs: `validate` (`windows-latest`), `validate-ubuntu` (`ubuntu-latest`), gate `ci-ok`.

The Windows `validate` job:

1. `validate-core.ps1 -Quiet`
2. Keyed uninstall asserts for Claude, Copilot, Codex, OpenCode, Antigravity, Grok, Cursor, ZCode, Hermes, and OpenHands
3. `Assert-SyncAllowUserHomeForward.ps1`
4. Ten agent smokes (Copilot is a suite): Cursor, Antigravity, Claude, Codex, Copilot suite, OpenCode, Grok, ZCode, Hermes, OpenHands

`validate-ubuntu` runs `Assert-InstallRootSafety.ps1`, `validate-core.ps1 -Quiet`, and the same ten fixture smokes.

`publish-release-bootstrap.yml` uploads the zip, SHA256, and bootstrap entrypoints on `release` published and on `workflow_dispatch`. `enforce-release-source.yml` fails unless a pull request into `master` or `main` comes from `develop`.

`.github/workflows/docs.yml` publishes this site. It is a separate workflow.

Smokes assert published files on fixtures. They do not launch product runtimes.
