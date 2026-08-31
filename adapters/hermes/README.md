# Hermes adapter (`hermes`)

Publish surfaces for **Hermes Agent** (Nous Research). InstallRoot defaults to an in-repo fixture; paths under `USERPROFILE` require `-AllowUserHome`.

**Live InstallRoot = `$HERMES_HOME`** (Windows Native/Desktop: `%LOCALAPPDATA%\hermes` when unset; POSIX/WSL: `~/.hermes`). Publish lands at `skills/` and `AGENTS.md` **directly under** that root — never nested as `$HERMES_HOME/.hermes/skills`. Do not publish a `rules/` tree, Cursor `hooks.json`, gateway tokens, cron/jobs, Kanban, voice, Curator, Profiles, or `inline_shell`. Never write `SOUL.md`. Do not set `skills.external_dirs` when publishing into the official home.

Install the toolkit first (`.\scripts\toolkit.ps1`), then sync this adapter.

## File layout

Registry entry remains `adapters/hermes/HermesAdapter.ps1` (thin contract surface). Implementation is grok-style siblings, dotted in order:

| File | Role |
|------|------|
| `HermesAdapter.ps1` | Entry: `$PSScriptRoot`, dot-source siblings, `Get-Capabilities` / `Get-InstallRoots`, thin `Publish-*` / `Invoke-SmokeValidate` / `Uninstall-Toolkit` wrappers |
| `HermesPathConstants.ps1` | `$script:HermesAdapterConstant` + `$script:HermesAdapterMessage` (shared by siblings) |
| `Publish-HermesSkills.ps1` | Shared path/placeholder helpers + `Invoke-HermesPublishSkills` + MEMORY.md seed + best-effort `hermes skills trust` |
| `Publish-HermesPolicy.ps1` | Fold `core/policy` into `AGENTS.md` + append spawn bridge (`Invoke-HermesPublishPolicy`) |
| `Publish-HermesRouter.ps1` | `Invoke-HermesPublishRouter` (same combined `AGENTS.md`) |
| `Publish-HermesHooks.ps1` | Plugin + `agent-hooks` path/secrets dual (`hooks=true`, `plugin=true`) |
| `Invoke-HermesSmokeValidate.ps1` | Native-layout smoke helpers + `Invoke-HermesSmokeValidate` |
| `Uninstall-HermesToolkit.ps1` | Keyed `Invoke-HermesUninstallToolkit` |
| `assets/spawn-bridge.md` | Hermes-only spawn operability block appended to managed `AGENTS.md` |
| `assets/plugins/agent-dev-toolkit-guard/` | Official Hermes plugin (`plugin.yaml` + `__init__.py` `pre_tool_call`) |
| `assets/agent-hooks/` | Shell dual `guard-pre-tool.sh` / `.ps1` |

Public `Publish-Skills` (etc.) in `HermesAdapter.ps1` forward to `Invoke-Hermes*` implementations — same pattern as Grok.

## Capabilities

| Flag | Value | Notes |
|------|-------|-------|
| `skills` | true | `core/skills` → `skills/<id>/SKILL.md` under InstallRoot (live `$HERMES_HOME/skills`) |
| `rules` | true | **Do not** publish `rules/` or `.mdc`. Fold `core/policy/*.md` into `AGENTS.md` |
| `hooks` | true | Shell dual under `agent-hooks/` + keyed `hooks.pre_tool_call` (`terminal\|write_file\|patch`, `fail_closed: true`) |
| `router` | true | `core/router/AGENTS.md` → `<InstallRoot>/AGENTS.md`, combined with folded policy (idempotent overwrite of managed `AGENTS.md`) |
| `plugin` | true | `plugins/agent-dev-toolkit-guard` + best-effort `hermes plugins enable`; fallback keyed `plugins.enabled` only |
| `agents` | false | No `agents/*.md` roster; `Publish-Agents` no-op |
| `subagents` | `native` | Host `delegate_task`; see Spawn section |

## Hooks / plugin (path + secrets)

Official refs: [Hooks](https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks), [Plugins](https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins).

| Surface | Path / behavior |
|---------|-----------------|
| Plugin | `plugins/agent-dev-toolkit-guard/` — `register(ctx)` → `pre_tool_call` returns `{ action: "block", message }` |
| Shell dual | `agent-hooks/guard-pre-tool.ps1` (+ `.sh`) |
| Config merge | **Only** `plugins.enabled` list + `hooks.pre_tool_call` entry — never gateway/tokens/`SOUL.md`/memories |
| Enable | Best-effort `hermes plugins enable agent-dev-toolkit-guard` |

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Tool **`delegate_task`** (isolated child; optional `role=orchestrator`) |
| Toolkit contract | Prefer `delegate_task` when `subagents=native`; honor `SPAWN.md`. Do **not** emit `delegation.*` YAML (`max_spawn_depth`, worktree isolation, etc.) — that is user config in `config.yaml` |
| Published files | **Skip** roster. Hermes has no `agents/*.md`. `Publish-Agents` is a documented no-op (`agents=false`) |
| Spawn bridge | `adapters/hermes/assets/spawn-bridge.md` is **appended** to managed `AGENTS.md` on Publish-Policy/Router (Hermes-only). Core skills/policy/router must **not** teach `delegate_task` outside the SPAWN host map |

### Official references (subagents / skills / context)

- [Skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills)
- [Creating skills](https://hermes-agent.nousresearch.com/docs/developer-guide/creating-skills)
- [Subagent delegation (`delegate_task`)](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation)
- [Context files (`AGENTS.md`, `MEMORY.md`, `SOUL.md`)](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files)
- [Hooks](https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks)
- [Plugins](https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins)

## Publish layout (native)

| Source | Destination under InstallRoot (`$HERMES_HOME`) |
|--------|-------------------------------------------|
| `core/skills/<id>/` | `skills/<id>/SKILL.md` (+ assets, including `_shared/`) |
| `core/policy/*.md` | Folded into `AGENTS.md` (no `rules/` directory) |
| `core/router/AGENTS.md` | `AGENTS.md` (`.mdc` refs rewritten to `.md`; `rules/` path refs rewritten to this file) |
| `adapters/hermes/assets/spawn-bridge.md` | Appended after folded policy (Hermes-only spawn operability; not in core) |
| `assets/plugins/agent-dev-toolkit-guard/` | `plugins/agent-dev-toolkit-guard/` |
| `assets/agent-hooks/` | `agent-hooks/` (+ published `GuardCommon.ps1`) |
| Missing `MEMORY.md` | Seeded once; never overwritten |
| `SOUL.md` | **Never** created or overwritten |

Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}` resolve with **`TOOLKIT_ROOT` = InstallRoot** and **`GUARDRAILS_PATH` = InstallRoot/AGENTS.md**. Re-sync overwrites managed files; alien files under InstallRoot are left alone.

### MEMORY.md seed

On publish, if `memories/MEMORY.md` is absent at InstallRoot, the adapter writes a short seed file. If it already exists, it is left untouched. `SOUL.md` is never created or overwritten.

### Project skills trust

Official user-home `$HERMES_HOME/skills/` does **not** need trust. If InstallRoot is **not** that official user home (project copy), Publish-Skills tries `hermes skills trust <InstallRoot>`. Trusted roots are stored by the CLI in `skills.trusted_project_dirs` inside the user `$HERMES_HOME/config.yaml`. If the `hermes` CLI is missing, trust is skipped (publish still succeeds). Publish-Hooks may keyed-merge **only** `plugins.enabled` and `hooks.pre_tool_call` in `config.yaml` — never gateway tokens or other secrets.

## Fixture + smoke

| Item | Path / behavior |
|------|-----------------|
| InstallRoot (CI / smoke) | `scripts/validation/fixtures/hermes` (models Hermes home layout) |
| Skills | `skills/` (direct child of InstallRoot) |
| Router + policy | `AGENTS.md` at InstallRoot |
| Plugin + hooks | **Required** — `plugins/agent-dev-toolkit-guard/` + `agent-hooks/` + keyed `config.yaml` |
| Trust CLI | Best-effort; missing `hermes` CLI is not a CI failure |

```powershell
# Install toolkit first, then sync (after the agent is registered).
.\scripts\toolkit.ps1

$hermesFixture = Join-Path $PWD 'scripts\validation\fixtures\hermes'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent hermes -InstallRoot $hermesFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent hermes -InstallRoot $hermesFixture
```

Live home (`$HERMES_HOME/skills`, Windows: `%LOCALAPPDATA%\hermes\skills`):

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent hermes -InstallRoot "$env:LOCALAPPDATA\hermes" -AllowUserHome
# or when HERMES_HOME is set:
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent hermes -InstallRoot $env:HERMES_HOME -AllowUserHome
```

Direct module verification (no registry required):

```powershell
. .\adapters\hermes\HermesAdapter.ps1
Publish-Skills -InstallRoot $hermesFixture
Publish-Policy -InstallRoot $hermesFixture
Publish-Router -InstallRoot $hermesFixture
Publish-Hooks -InstallRoot $hermesFixture
Get-SddRoot -InstallRoot $hermesFixture -Prepare
Invoke-SmokeValidate -InstallRoot $hermesFixture
```

## Uninstall (keyed)

Removes toolkit-managed paths (core skill ids, toolkit-owned `AGENTS.md`, `plugins/agent-dev-toolkit-guard`, `agent-hooks` guard files) and reverse-merges keyed `plugins.enabled` / `hooks.pre_tool_call` from `config.yaml`. Preserves alien skills, other `config.yaml` keys/secrets, `memories/MEMORY.md`, `SOUL.md`, `sdd/sessions`, and `sdd/manifest.json`. Does **not** wipe InstallRoot wholesale. Never deletes gateway tokens.

## Out of scope (do not emit)

- Gateway / platform tokens / unrelated `config.yaml` secrets
- `cron/jobs.json`
- Kanban, voice, Curator, Profiles
- `inline_shell`
- `delegation.*` YAML

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
