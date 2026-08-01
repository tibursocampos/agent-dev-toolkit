# Claude adapter (`claude`)

Publish surfaces for **Claude Code**. InstallRoot defaults to an in-repo fixture; paths under `USERPROFILE` require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `claude` |
| `subagents` (registry) | `native` |

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Claude Code **Agent** / Task-equivalent spawn |
| Toolkit contract | Prefer Task/Agent naming in skills when `subagents=native`; SPAWN in-parent fallback otherwise |

Matrix: [docs/SPAWN.md](../../docs/SPAWN.md). Contract: `core/skills/_shared/agents/SPAWN.md`.

## Policy → rules mapping

| Source | Destination |
|--------|-------------|
| `core/policy/{name}.md` | `<InstallRoot>/rules/{name}.md` |

- Keep **`.md`** (Claude layout). Cursor may normalize the same core files to `.mdc`; this adapter does not.
- Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}` resolve relative to InstallRoot.
- Re-sync overwrites managed rule files; alien files under `rules/` are left alone.

## Router → CLAUDE.md mapping

| Source | Destination |
|--------|-------------|
| `core/router/AGENTS.md` | `<InstallRoot>/CLAUDE.md` |

- Content is **core router only**.
- After placeholder resolve, path refs ending in `.mdc` are rewritten to `.md` so they match published `rules/`.
- `Publish-Router` is **implemented**; capability `router=true` means `CLAUDE.md`.

## Hooks scripts mapping

| Source | Destination |
|--------|-------------|
| `adapters/claude/assets/hooks/*` | `<InstallRoot>/hooks/*` |

- Publishes **scripts** then merges `<InstallRoot>/settings.json`.
- Merge: hooks **keyed upsert** (`UserPromptSubmit` / `PreCompact` / `PostToolUse`) by managed handler identity; `permissions.allow` **additive** with **narrow** entries only (one `Bash(pwsh -NoProfile -File "<InstallRoot>/hooks/<script>")` per managed hook); unrelated keys preserved; UTF-8 without BOM; backup `settings.json.bak` before overwrite.
- Invalid JSON → abort, no overwrite. Backup failure → abort, no write.
- Re-sync does not duplicate toolkit allow entries. Re-sync **strips** legacy broad `Bash(pwsh *)` / `Bash(powershell *)` unless `-AllowBroadShellPermissions` is passed to `Invoke-ClaudeMergeSettings`.
- Alien files under `hooks/` are left alone.
- **Smoke validates filesystem presence only** — Claude Code hook **trust UI** is out of scope.
- **Security note:** default allow is scoped to the three managed hook command templates (not a standing `pwsh *` / `powershell *` grant). Opt into broad shell allows only via `-AllowBroadShellPermissions` on merge (documented for operators who need it). Review `settings.json` after sync.

## In-repo merge fixture

| Item | Path |
|------|------|
| InstallRoot (CI / smoke) | `scripts/validation/fixtures/claude` |
| Pre-existing `settings.json` | `scripts/validation/fixtures/claude/settings.json` |

Pass `-InstallRoot <repo>/scripts/validation/fixtures/claude`. Do not use `%USERPROFILE%` without `-AllowUserHome`. Seed markers (custom keys, alien `Notification` hook, partial `UserPromptSubmit`, user `permissions.allow`) exercise merge preservation.

## Commands

| Command | Status |
|---------|--------|
| `Publish-Skills` | Implemented |
| `Publish-Policy` | Implemented |
| `Publish-Router` | Implemented |
| `Publish-Hooks` (scripts + settings merge) | Implemented |
| `Invoke-ClaudeMergeSettings` | Implemented |
| `Invoke-SmokeValidate` | Implemented — filesystem only; lists missing relative paths on failure |
| `validate-agent -Agent claude` | Core + smoke against fixture |
| `sync-agent -Agent claude` | Publish-Skills → Policy → Router → Hooks |
| `toolkit.ps1 -Action ListAgents` | Lists registry entry `claude` |
| `Uninstall-Toolkit` | Keyed removal + settings reverse-merge; WhatIf supported |

### Uninstall scope (safe)

Removes only toolkit-managed paths (core skill ids, core policy → rules files, `CLAUDE.md`, asset hook scripts) and reverse-merges `settings.json`: drops **toolkit-managed hook handlers** (same identity as merge) and managed / legacy-broad `permissions.allow` entries. Empty hook events are removed; **alien co-located handlers** on the same event are kept. Preserves alien files and unrelated settings keys. Does **not** wipe InstallRoot or wholesale-replace settings.

### Managed vs preserved inventory

| Surface | Managed (toolkit) | Preserved (operator / alien) |
|---------|-------------------|------------------------------|
| `skills/` | Folders matching `core/skills/*` | Other skill folders / files |
| `rules/` | Files matching `core/policy/*` (`.md`) | Alien rule files |
| `CLAUDE.md` | Whole file from `core/router/AGENTS.md` | Sibling files at InstallRoot |
| `hooks/` | Scripts from `adapters/claude/assets/hooks/*` | Alien hook scripts |
| `settings.json` hooks | Handlers matching managed `pwsh -NoProfile -File ".../hooks/<script>"` on `UserPromptSubmit` / `PreCompact` / `PostToolUse` | Alien events (e.g. `Notification`) and alien handlers co-located on managed events |
| `settings.json` allow | Narrow `Bash(pwsh -NoProfile -File "<InstallRoot>/hooks/<script>")` per managed hook (additive); legacy `Bash(pwsh *)` / `Bash(powershell *)` stripped on re-sync unless `-AllowBroadShellPermissions` | User allows / deny / env / custom keys |
| Encoding / backup | UTF-8 without BOM; `settings.json.bak` before write | Original intact on invalid JSON abort |

**Uninstall note:** reverse-merge removes only toolkit-managed handlers and allow entries — co-located alien handlers on the same event name survive; the event key is removed only when no handlers remain.

Example:

```powershell
.\scripts\sync-agent.ps1 -Agent claude -InstallRoot .\scripts\validation\fixtures\claude
.\scripts\validate-agent.ps1 -Agent claude -InstallRoot .\scripts\validation\fixtures\claude
.\scripts\toolkit.ps1 -Action ListAgents
```

Live home:

```powershell
.\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

## Docs + CI

- [ADAPTERS.md](../../docs/ADAPTERS.md) — Claude layout, merge rules, fixture
- [ARCHITECTURE.md](../../docs/ARCHITECTURE.md) — InstallRoot tree
- [INSTALL.md](../../docs/INSTALL.md) — operator sync
- [VALIDATION.md](../../docs/VALIDATION.md) — `Invoke-ClaudeCiSmoke.ps1`

## Official docs (Anthropic)

- [Features overview](https://code.claude.com/docs/en/features-overview)
- [Memory / CLAUDE.md / rules](https://code.claude.com/docs/en/memory)
- [Skills](https://code.claude.com/docs/en/skills)
- [Hooks](https://code.claude.com/docs/en/hooks)
- [`.claude` directory](https://code.claude.com/docs/en/claude-directory)
- [Steering: skills, hooks, rules, subagents](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
```

Workflow step: `.github/workflows/validate-toolkit.yml` → **Run Claude CI smoke** (no secrets; no home sync).
