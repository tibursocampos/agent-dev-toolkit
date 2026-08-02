# Cursor adapter (`cursor`)

Publish surfaces for **Cursor** (`~/.cursor`). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `cursor` |
| Purpose | Publish skills, rules, hooks, and router into a Cursor InstallRoot |
| Sync fixture | `scripts/validation/fixtures/cursor-install-root` |
| `subagents` (registry) | `native` |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot .\scripts\validation\fixtures\cursor-install-root
```

## File layout

Registry entry remains `adapters/cursor/CursorAdapter.ps1` (thin contract surface). Implementation is Claude/Grok-style siblings, dotted in order:

| File | Role |
|------|------|
| `CursorAdapter.ps1` | Entry: `$PSScriptRoot`, dot-source siblings, `Get-Capabilities` / `Get-InstallRoots`, `Get-SddRoot` (+ SDD layout helpers), thin `Publish-*` / `Invoke-SmokeValidate` / `Uninstall-Toolkit` wrappers |
| `CursorPathConstants.ps1` | `$script:CursorAdapterConstant` + `$script:CursorAdapterMessage` (shared by siblings) |
| `Publish-CursorSkills.ps1` | Path/placeholder helpers + `Invoke-CursorPublishSkills` |
| `Publish-CursorPolicy.ps1` | `Publish-CursorPolicyAsMdcRules` + `Invoke-CursorPublishPolicy` |
| `Publish-CursorRouter.ps1` | `Invoke-CursorPublishRouter` |
| `Publish-CursorHooks.ps1` | Merge helpers, `Copy-CursorHookScripts`, `Write-CursorUtf8NoBom`, `Invoke-CursorPublishHooks` |
| `Invoke-CursorSmokeValidate.ps1` | Filesystem smoke helpers + `Invoke-CursorSmokeValidate` |
| `Uninstall-CursorToolkit.ps1` | Keyed `Invoke-CursorUninstallToolkit` |

Public `Publish-Skills` (etc.) in `CursorAdapter.ps1` forward to `Invoke-Cursor*` implementations — same pattern as Claude/Grok.

Non-`Copy-ToolkitManagedTree` writes under InstallRoot are fail-closed via `Assert-ToolkitManagedDestinationUnderInstallRoot` / `Assert-ToolkitManagedPathContained` / `Assert-PathUnderInstallRootForDelete` (hooks copy, hooks.json/AGENTS.md/SDD atomic write, policy prune).

## Capabilities

| Flag | Value | Notes |
|------|-------|-------|
| `skills` | true | `core/skills` → `skills/<id>/SKILL.md` |
| `rules` | true | `core/policy` → `rules/*.mdc` |
| `hooks` | true | Scripts under `hooks/` + root `hooks.json` merge |
| `router` | true | `core/router/AGENTS.md` → `AGENTS.md` |
| `plugin` | false | — |
| `subagents` | `native` | Host Task tool; see Spawn section |

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry | `native` |
| Effective (`Get-Capabilities`) | `native` (static) |
| Host mechanism | Cursor **Task** tool |
| Toolkit contract | `core/skills/_shared/agents/SPAWN.md` + `SUBAGENT-MODEL.md` |

Skills prefer Task when `subagents=native`; fallback in-parent when Task unavailable (never hard-fail).

## Hooks merge

`Publish-Hooks` merges `hooks.json` with **Claude-style keyed upsert**: toolkit-owned commands (identity = `hooks/<managed-script>.ps1`) are replaced and prepended; alien commands and alien event keys are preserved. Re-sync does not keep stale toolkit entries solely because the exact `command` string already exists.

## Uninstall (keyed)

Removes only toolkit-managed paths (core skill ids, core policy → `rules/*.mdc`, toolkit hook scripts, `AGENTS.md`) and reverse-merges `hooks.json` (drop toolkit-managed handlers by strict `-File` command identity; keep aliens and alien top-level keys). Publish merge may match broader `hooks/<script>` paths; uninstall matching is strict `-File`. Preserves alien skills/rules/hooks and **does not** remove `sdd/sessions` or `sdd/manifest.json`. Does **not** wipe InstallRoot wholesale. Supports `-WhatIf`.

## Official docs (Cursor)

- [Rules + AGENTS.md](https://cursor.com/docs/rules)
- [Skills](https://cursor.com/docs/context/skills)
- [Hooks](https://cursor.com/docs/hooks)
- [Subagents](https://cursor.com/docs/context/subagents)
- [Agent best practices](https://cursor.com/blog/agent-best-practices)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
