# Grok Build adapter (`grok`)

Publish surfaces for **Grok Build** (xAI). InstallRoot defaults to an in-repo fixture; paths under `USERPROFILE` require `-AllowUserHome`.

**Live InstallRoot = `~/.grok`** (Claude-style). Publish lands at `skills/`, `rules/`, and `hooks/` **directly under** that root — never nested as `~/.grok/.grok/skills`. Packaging target matches [docs.x.ai/build](https://docs.x.ai/build/overview). Claude/Cursor compat layouts are **not** the sole publish destination. Hooks trust (`/hooks-trust` / `--trust`) is a **human** step; smoke and CI validate filesystem only and never write `trusted_folders.toml`.

## File layout

Registry entry remains `adapters/grok/GrokAdapter.ps1` (thin contract surface). Implementation is Claude-style siblings, dotted in order:

| File | Role |
|------|------|
| `GrokAdapter.ps1` | Entry: `$PSScriptRoot`, dot-source siblings, `Get-Capabilities` / `Get-InstallRoots`, thin `Publish-*` / `Invoke-SmokeValidate` / `Uninstall-Toolkit` wrappers |
| `GrokPathConstants.ps1` | `$script:GrokAdapterConstant` + `$script:GrokAdapterMessage` (shared by siblings) |
| `Publish-GrokSkills.ps1` | Shared path/placeholder helpers + `Invoke-GrokPublishSkills` |
| `Publish-GrokPolicy.ps1` | `Invoke-GrokPublishPolicy` |
| `Publish-GrokRouter.ps1` | `Invoke-GrokPublishRouter` |
| `Publish-GrokHooks.ps1` | `Invoke-GrokPublishHooks` (native JSON; never `trusted_folders.toml`) |
| `Invoke-GrokSmokeValidate.ps1` | Native-layout smoke helpers + `Invoke-GrokSmokeValidate` |
| `Uninstall-GrokToolkit.ps1` | Keyed `Invoke-GrokUninstallToolkit` |

Public `Publish-Skills` (etc.) in `GrokAdapter.ps1` forward to `Invoke-Grok*` implementations — same pattern as Claude.

## Capabilities

| Flag | Value | Notes |
|------|-------|-------|
| `skills` | true | `core/skills` → `skills/<id>/SKILL.md` under InstallRoot |
| `rules` | true | `core/policy` → `rules/*.md` under InstallRoot |
| `hooks` | true | Native JSON under `hooks/` |
| `router` | true | `core/router/AGENTS.md` → `<InstallRoot>/AGENTS.md` |
| `plugin` | false | Marketplace/plugins out of CI green |
| `agents` | true | `core/agents` → `agents/<id>.md` under InstallRoot |
| `subagents` | `native` | Host `spawn_subagent`; see Spawn section |

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Tool **`spawn_subagent`**; config `[subagents]` / `GROK_SUBAGENTS` / `--no-subagents` |
| Toolkit contract | Prefer `spawn_subagent` when `subagents=native`; SPAWN fallback if feature disabled |
| Published files | `Publish-Agents` copies `core/agents/` → `InstallRoot/agents/` (live `~/.grok/agents/`). |

### Official references (subagents)

- [Settings reference — `[subagents]`](https://docs.x.ai/build/settings/reference)
- [CLI reference — `--no-subagents`](https://docs.x.ai/build/cli/reference)
- [Product / CLI](https://x.ai/cli)
- User-guide subagents in [xai-org/grok-build](https://github.com/xai-org/grok-build) (harness docs)


## Publish layout (native)

| Source | Destination under InstallRoot (`~/.grok`) |
|--------|-------------------------------------------|
| `core/skills/<id>/` | `skills/<id>/SKILL.md` (+ assets) |
| `core/policy/{name}.md` | `rules/{name}.md` |
| `core/router/AGENTS.md` | `AGENTS.md` (`.mdc` refs rewritten to `.md`) |
| `core/agents/*.md` | `agents/*.md` |
| Adapter hooks assets | `hooks/toolkit-session-start.json`, `session_start.ps1`, `guard-pre-tool.ps1` (+ `GuardCommon.ps1`) |

Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}` resolve with **`TOOLKIT_ROOT` = InstallRoot** (the parent of `skills/_shared`). Re-sync overwrites managed files; alien files under InstallRoot are left alone.

### Native vs compat

Grok Build may also **read** Claude/Cursor artifacts (`CLAUDE.md`, `.claude/`, `.cursor/`). This adapter **writes** primarily under InstallRoot (`skills|rules|hooks`). `Invoke-SmokeValidate` fails when only compat paths exist without required native artifacts.

## Fixture + smoke

| Item | Path / behavior |
|------|-----------------|
| InstallRoot (CI / smoke) | `scripts/validation/fixtures/grok` (models `~/.grok`) |
| Skills / rules / hooks | `skills/`, `rules/`, `hooks/` (direct children of InstallRoot) |
| Router | `AGENTS.md` at InstallRoot |
| Trust UI | **Out of scope** for CI — no `/hooks-trust`, no `trusted_folders.toml` |

```powershell
$grokFixture = Join-Path $PWD 'scripts\validation\fixtures\grok'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent grok -InstallRoot $grokFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent grok -InstallRoot $grokFixture
```

Live home (`~/.grok/skills`, not `~/.grok/.grok/skills`):

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent grok -InstallRoot "$env:USERPROFILE\.grok" -AllowUserHome
```

## Uninstall (keyed)

Removes only toolkit-managed paths (core skill ids, core policy → rules files, toolkit hook JSON/script, `AGENTS.md`). Preserves alien skills/rules/hooks and `config.toml`. Preserves `sdd/sessions` and `sdd/manifest.json`. Does **not** wipe InstallRoot wholesale.

## Official docs (xAI)

- [Overview](https://docs.x.ai/build/overview)
- [Skills / plugins / marketplaces](https://docs.x.ai/build/features/skills-plugins-marketplaces)
- [Hooks](https://docs.x.ai/build/features/hooks)
- [Project rules](https://docs.x.ai/build/features/project-rules)
- [Subagents](https://docs.x.ai/build/features/subagents)
- Subagents (toolkit): see **Spawn / subagents** above

Public contract summary: [docs/ADAPTERS.md](../../docs/ADAPTERS.md). Architecture: [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md).
