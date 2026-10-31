---
title: Architecture
---

# Architecture

**agent-dev-toolkit** is one agent-neutral core, published by adapters into each host install root. Operators sync with a PowerShell CLI, then invoke the same skill ids in the host. Evidence: `core/skills/*/SKILL.md` (**46** skills), `adapters/registry.json` (**10** agents).

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
memory-bank/   durable workspace map (Orchestrated Delivery Step 0)
.github/workflows/validate-toolkit.yml
.github/workflows/master-release-ci.yml
.github/workflows/enforce-release-source.yml
.github/workflows/release.yml
.github/workflows/publish-release-bootstrap.yml
.github/workflows/docs.yml
```

## Layers

| Layer | Role |
|-------|------|
| Core | Agent Skills (`SKILL.md`), `_shared`, policy markdown, neutral router, SDD contracts. Placeholders stay in source |
| Adapters | Publish skills, policy, router, hooks, and agents into the host layout. Smoke uses a fixture InstallRoot |
| CLI | `scripts/toolkit.ps1` chooses the agent for sync, validate, and uninstall |
| Install root | Destination. Default sync target is an in-repo fixture. A user-profile path needs `-AllowUserHome` |
| CI and release | `validate-toolkit.yml` on `pull_request` to `develop` emits aggregate checks `validate` and `ci-ok` after core, adapter-smoke, and strict docs jobs. Release PRs to `master` / `main` emit `ci-ok` for branch direction and `release-source` for source, metadata, and App readiness; they do not rerun the full suite. A green run does not sync a live home |

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
- `core/skills/` — 46 skills plus `_shared`. Agents read the map with `help-skills` (`CATALOG.md` and `OPERATOR.md`).
- `core/policy/` — rule bodies (`.md`; adapters may normalize to `.mdc` or instructions).
- `core/router/` — neutral router (`AGENTS.md`). The host file name depends on the adapter.
- `core/skills/_shared/sdd-artifacts/` — `PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`, reached through `Get-SddRoot`.

Specialist prompts under `core/agents/` (`architect`, `database`, `repo-analyst`, `security`, `shell-runner`) publish when `agents` is true. `qa_checklist` has no agent file.

## Placeholders

Core content does not hardcode a single IDE home. Adapters resolve placeholders at publish.

| Placeholder | Meaning |
|-------------|---------|
| `{{TOOLKIT_ROOT}}` | Toolkit install root. Codex splits plugin skills from InstallRoot rules |
| `{{SDD_ROOT}}` | SDD state root (`preferences.json`, `sessions/`, `manifest.json`, optional global Classic tree) |
| `{{GUARDRAILS_PATH}}` | Guardrails policy path for the target agent |

At runtime, skills resolve SDD state via `effective_SDD_ROOT` so a foreign agent’s baked path does not win. Runtime scripts under `<InstallRoot>/scripts/<area>` resolve an omitted `-SddRoot` to `<InstallRoot>/sdd`; helpers do not infer it from the user profile. `effective_SDD_ROOT` holds sessions, preferences, and `manifest.json` (schema v2), plus optional **global** `features/` and `memory-bank/` when `classic.storage_mode` is `global`. **Repository** mode keeps those trees under the consumer `$Cwd`.

Published skills resolve their declared runtime helpers from the installed toolkit tree. Session helpers reject persisted repository or PLAN identity mismatches before state changes. Fixture and static checks prove those publication and session contracts; they do not prove a live host, IDE, or hook run.

Prepared `mustNotContain` needles: `scripts/validation/contracts/must-not-contain-ide.json`. Core suite: `scripts/validation/validate-core.ps1` (alias `validate-all.ps1`). Brand names may appear in co-author rules. They are not filesystem home paths.

## Entry points

- `scripts/toolkit.ps1`
- `scripts/sync-agent.ps1`
- `scripts/validate-agent.ps1`
- `scripts/validation/validate-core.ps1`
- `scripts/validation/Assert-SyncAllowUserHomeForward.ps1`
- `scripts/validation/Invoke-AdapterCiSmoke.ps1 -Adapter <id>` (ids from `adapters/registry.json`: cursor, antigravity, claude, codex, copilot, opencode, grok, zcode, hermes, openhands)
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
| `hooks/*.ps1` | Compatibility assets; they do not decide authorization |
| `hooks.json` | Managed hooks; Toolkit authorization entries are removed on sync |
| `agents/*.md` | Roster when `agents=true` |
| `sdd/sessions/` | Sessions (`Get-SddRoot -Prepare`) |
| `sdd/manifest.json` | Seed when absent. Never overwrite an existing file |

Fixture: `scripts/validation/fixtures/cursor-install-root`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter cursor` on an ephemeral copy. CI does not write a live `~/.cursor` and does not drive the hooks trust UI.

## Antigravity

InstallRoot models `~/.gemini`.

| Relative path | Role |
|---------------|------|
| `config/skills` | Kebab skills plus `dev_persona` |
| `config/plugins` | Plugin surface (GUARDRAILS under the managed plugin id) |
| `config/hooks` | Provider hook configuration; no Toolkit authorization decision |
| `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` | Discovery and managed markdown |

`antigravity-ide/plugins` is a legacy bridge, documentation and opt-in only. It is not a CI gate. Live Knowledge Items and the IDE trust UI are out of scope. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter antigravity`. Registry `subagents` is `native`. The effective value comes from `Get-Capabilities` (fail-closed probe).

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

Fixture: `scripts/validation/fixtures/claude`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter claude`.

## OpenCode

InstallRoot models `~/.config/opencode`.

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `AGENTS.md` | Router |
| `agents/*.md` | `Publish-Agents` |
| `plugins/*.js` | JS plugins. The compatibility marker installs no authorization hook |

Hooks are plugin-only. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter opencode` (filesystem only).

## ZCode

InstallRoot models `~/.zcode` (ADE filesystem, not GLM Coding Plan).

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Router |
| `agents/*.md` | Roster |
| `cli/config.json` | Hooks config |
| `hooks/hooks.json` | PreToolUse configuration; Toolkit does not decide authorization |

Fixture: `scripts/validation/fixtures/zcode-install-root/`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter zcode`.

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
| `hooks/*` | No active hook registered (`HookActivation` `unavailable`); no Toolkit authorization decision |
| `agents/nome.agent.md` | One catalog agent file in repo mode. Mode user does not publish agents |

JetBrains and Eclipse layouts are out of scope. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter copilot`.

## Grok Build

InstallRoot is `~/.grok` (or a project `.grok` you pass). The tree is native, not nested `.grok/.grok`.

| Relative path | Role |
|---------------|------|
| `skills` | Skills, live `~/.grok/skills` |
| `rules` | Policy |
| `agents` | Roster |
| `hooks` | Compatibility PreToolUse hooks. `/hooks-trust` is manual |
| `AGENTS.md` | Router |

Fixture: `scripts/validation/fixtures/grok`.

## Hermes

InstallRoot is the Hermes home. Windows: `%LOCALAPPDATA%\hermes`. POSIX: `~/.hermes`. Skills and `AGENTS.md` sit directly under that root.

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Router plus folded policy. No `rules/` tree |
| `plugins/agent-dev-toolkit-guard` | Compatibility plugin; registers no hook; authorization remains with Hermes |
| `memories/MEMORY.md` | Seeded once if missing |
| `SOUL.md` | Never created or overwritten |

`Publish-Agents` is a no-op (`agents=false`). The hook merge keeps non-toolkit keys and removes legacy toolkit `pre_tool_call` entries. A structural `config.yaml` check runs before any change. Subagents: host `delegate_task`. Fixture: `scripts/validation/fixtures/hermes`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter hermes`.

## OpenHands

Project InstallRoot is a repository tree.

| Relative path | Role |
|---------------|------|
| `.agents/skills/<id>/SKILL.md` | Skills, not legacy microagents |
| `.agents/agents/*.md` | Roster. Not native spawn |
| `AGENTS.md` | Router plus folded policy |
| `.openhands/hooks.json` and `.openhands/hooks/*.sh` | Shell hooks, including `guard_pre_tool.sh` |
| `.plugin/plugin.json` | Plugin metadata. Skills work without the plugin |

Live user skills: `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` publishes `skills/` under that home. `subagents=none`. Fixture: `scripts/validation/fixtures/openhands`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter openhands`.

## CI

`.github/workflows/validate-toolkit.yml` runs on `pull_request` to `develop` only. Its topology is `validate-core` (`windows-latest`) -> `adapter-smoke` (`ubuntu-latest` matrix over the 10 adapters) and `adapter-smoke-windows` (codex only); alongside them `docs-strict` builds MkDocs strictly. Aggregate check `validate` depends on every validation job; `ci-ok` depends on those jobs and `validate`.

The Windows `validate-core` job runs `validate-core.ps1` and `Assert-SyncAllowUserHomeForward.ps1`. Adapter smoke runs on an Ubuntu matrix (10 adapters) plus one Windows smoke (codex).

Adapter smoke is the generic `Invoke-AdapterCiSmoke.ps1 -Adapter <id>`, seeded under `.adt-work/`.

`master-release-ci.yml` emits `ci-ok` on pull requests into `master`/`main` after checking that the head is `develop`. `enforce-release-source.yml` emits `release-source`; it validates source direction, release metadata, and release-sync App credentials and permissions.

The normal release flow begins when an opted-in `develop` → `master`/`main` PR merges. `release.yml` preflights App credentials, creates a tag and release for the promoted commit, calls `publish-release-bootstrap.yml` to upload the zip, SHA256, and bootstrap entrypoints, and requests a normal reconciliation PR back to `develop`. Reconciliation runs after each merged release PR. If publication succeeded but reconciliation failed, run `release.yml` from the promoted commit on `master`/`main` with `reconcile_only=true` and a blank version; it retries reconciliation without creating another tag. Asset-only failures can be retried by dispatching `publish-release-bootstrap.yml` with the existing tag.

Workflows emit checks; GitHub rulesets and branch protection decide which are required. As checked on 2026-10-29, `protect-develop` requires `validate`, legacy branch protection also requires `ci-ok`, and `protect-release` requires `release-source`. Recheck the remote settings before relying on this snapshot.

`.github/workflows/docs.yml` publishes this site. It is a separate workflow.

Smokes assert published files on fixtures. They do not launch product runtimes.
