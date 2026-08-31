# OpenHands adapter (`openhands`)

Publish surfaces for **OpenHands**. Default InstallRoot is an in-repo **project** fixture; paths under `USERPROFILE` require `-AllowUserHome`.

**Project InstallRoot** (CI / typical sync) models a repository tree: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/`, `.plugin/`. **Live user skills** (`~/.agents/skills`) use `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` so skills land at `skills/` directly under that home — never `~/.agents/.agents/skills`. `AGENTS.md`, hooks, and plugin metadata are project-scoped (not the user-home tree).

This adapter does **not** emit Automation Server config, cron, GitHub webhooks, sandbox YAML, LLM model config, or secrets.

## File layout

| File | Role |
|------|------|
| `OpenHandsAdapter.ps1` | Entry: `$PSScriptRoot`, dot-source siblings, `Get-Capabilities` / `Get-InstallRoots`, thin `Publish-*` / `Invoke-SmokeValidate` / `Uninstall-Toolkit` wrappers |
| `OpenHandsPathConstants.ps1` | `$script:OpenHandsAdapterConstant` + `$script:OpenHandsAdapterMessage` |
| `Publish-OpenHandsSkills.ps1` | Shared path/placeholder helpers + `Invoke-OpenHandsPublishSkills` + `.plugin/plugin.json` |
| `Publish-OpenHandsPolicy.ps1` | `Invoke-OpenHandsPublishPolicy` (fold into `AGENTS.md`) |
| `Publish-OpenHandsRouter.ps1` | `Invoke-OpenHandsPublishRouter` (router + folded policy) |
| `Publish-OpenHandsAgents.ps1` | `Invoke-OpenHandsPublishAgents` |
| `Publish-OpenHandsHooks.ps1` | `Invoke-OpenHandsPublishHooks` (shell hooks; never `.ps1`) |
| `Invoke-OpenHandsSmokeValidate.ps1` | Native-layout smoke helpers |
| `Uninstall-OpenHandsToolkit.ps1` | Keyed `Invoke-OpenHandsUninstallToolkit` |
| `assets/hooks/session_start.sh` | SessionStart hook script copied to `.openhands/hooks/` |

## Capabilities

| Flag | Value | Notes |
|------|-------|-------|
| `skills` | true | `core/skills` → `.agents/skills/<id>/SKILL.md` (Agent Skills; **not** legacy microagents). Placeholders resolved; `_shared/` copied. Works **without** the plugin. |
| `rules` | true | **Does not** publish a Cursor `.mdc` `rules/` tree. Folds `core/policy` into `AGENTS.md` with the router. |
| `hooks` | true | Shell entrypoint `.sh` under `.openhands/hooks/` (`session_start.sh`, `guard_pre_tool.sh`); may ship colocated `.ps1` + `GuardCommon.ps1` for GuardCommon evaluation. Filesystem only. |
| `router` | true | `core/router/AGENTS.md` → `InstallRoot/AGENTS.md` (plus folded policy). |
| `plugin` | true | `.plugin/plugin.json` packages skills+hooks metadata. Skills still work without the plugin. |
| `agents` | true | `core/agents/*.md` → `.agents/agents/*.md` (SDK/plugin roster). **Canvas Profile is not this roster.** |
| `subagents` | `none` | Canvas/ACP is not parent→child. SDK `TaskToolSet` exists but is not Canvas. SPAWN fallback in-parent. Never `native`. |

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `none` |
| Host mechanism | OpenHands **loop** runs until `FinishAction` on the **main** agent. Canvas / ACP is not parent→child spawn (not Cursor Task, not Hermes `delegate_task`). SDK `TaskToolSet` is not the Canvas product. |
| Toolkit contract | SPAWN fallback **in-parent**. Do not claim `native`. |
| Published files | `Publish-Agents` writes `.agents/agents/*.md` as an SDK/plugin **roster**. That is not Canvas Profile and not native subagent spawn. |

### Official references (spawn)

- Skills / `AGENTS.md`: [Skills overview](https://docs.openhands.dev/overview/skills)
- Hooks: [Repository hooks](https://docs.openhands.dev/openhands/usage/customization/hooks)
- Plugins: [Plugins](https://docs.openhands.dev/overview/plugins)

## Publish layout (project InstallRoot)

| Source | Destination under InstallRoot |
|--------|-------------------------------|
| `core/skills/<id>/` | `.agents/skills/<id>/SKILL.md` (+ `_shared/`) |
| `core/policy/*.md` | Folded into `AGENTS.md` (no `rules/` tree) |
| `core/router/AGENTS.md` | `AGENTS.md` (`.mdc` refs rewritten to `.md`; `rules/` pointers rewritten to the folded section) |
| `core/agents/*.md` | `.agents/agents/*.md` |
| Adapter hook asset | `.openhands/hooks.json`, `.openhands/hooks/session_start.sh`, `.openhands/hooks/guard_pre_tool.sh` (+ ps1/GuardCommon helper) |
| Plugin metadata | `.plugin/plugin.json` (points at `./.agents/skills/` and `./.openhands/hooks.json`) |

Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}` resolve with **`TOOLKIT_ROOT` = InstallRoot/.agents`** (parent of `skills/_shared`). `GUARDRAILS_PATH` is `InstallRoot/AGENTS.md` because policy is folded there. Re-sync overwrites managed files; alien files under InstallRoot are left alone.

When InstallRoot is the live user home `~/.agents`, `TOOLKIT_ROOT` is that directory and skills publish at `skills/` (no nested `.agents`).

## Install

Prefer the toolkit CLI first (registry wiring for `openhands` is a later wave; until then, dot-source the adapter as shown under Fixture + smoke):

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent openhands -InstallRoot .\scripts\validation\fixtures\openhands
```

Secondary example (`sync-agent` fails until the registry lists `openhands`):

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent openhands -InstallRoot .\scripts\validation\fixtures\openhands
```

Live user skills home:

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent openhands -InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome
```

## Fixture + smoke

| Item | Path / behavior |
|------|-----------------|
| InstallRoot (CI / smoke) | `scripts/validation/fixtures/openhands` (project tree) |
| Skills | `.agents/skills/` |
| Agents roster | `.agents/agents/` |
| Hooks | `.openhands/hooks.json` + `.openhands/hooks/*.sh` |
| Plugin | `.plugin/plugin.json` |
| Router + folded policy | `AGENTS.md` |
| Automation Server / sandbox | **Not published** |

Until registry wave 2, local smoke:

```powershell
$fixture = Join-Path $PWD 'scripts\validation\fixtures\openhands'
$work = Join-Path $env:TEMP 'openhands-adapter-smoke'
Copy-Item $fixture $work -Recurse -Force
. .\adapters\openhands\OpenHandsAdapter.ps1
Publish-Skills -InstallRoot $work
Publish-Policy -InstallRoot $work
Publish-Router -InstallRoot $work
Publish-Agents -InstallRoot $work
Publish-Hooks -InstallRoot $work
Get-SddRoot -InstallRoot $work -Prepare
Invoke-SmokeValidate -InstallRoot $work
Uninstall-Toolkit -InstallRoot $work
```

Or: `pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1`

## Uninstall (keyed)

Removes only toolkit-managed paths (core skill ids, toolkit hook JSON/script, `.plugin/plugin.json`, roster agent markdown, owned `AGENTS.md`). Preserves alien skills/hooks/plugin/agents files and `sdd/sessions` / `sdd/manifest.json`. Does **not** wipe InstallRoot wholesale.

## Official docs (OpenHands)

- [Skills overview](https://docs.openhands.dev/overview/skills) — `AGENTS.md`, `.agents/skills/`, `~/.agents/skills/`; prefer Agent Skills over legacy `.openhands/microagents/`
- [Creating skills](https://docs.openhands.dev/overview/skills/creating)
- [Repository hooks](https://docs.openhands.dev/openhands/usage/customization/hooks) — `.openhands/hooks.json` + `.openhands/hooks/*.sh`
- [Plugins](https://docs.openhands.dev/overview/plugins) — `.plugin/plugin.json`; plugin `hooks/hooks.json` is the packaged form (this adapter publishes **repository** hooks under `.openhands/` and metadata at `.plugin/plugin.json`)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
