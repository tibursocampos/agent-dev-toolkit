---
title: CLI
---

# CLI

`scripts/toolkit.ps1` is the Smart Manager and the non-interactive entry. `scripts/sync-agent.ps1` publishes one agent. `scripts/validate-agent.ps1` checks the repo and then that agent. Uninstall calls `Uninstall-Toolkit`.

Install from a release or a clone is on [Get started](get-started.md). Per-agent layouts are on [Adapters](adapters.md).

## Smart Manager

Option 0 opens this after extract. From a clone:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

| Menu | What it does |
|------|----------------|
| **Sync agent** | Publish skills, policy, and hooks. The wizard picks the agent, then live home (Enter is the default), a fixture, or a custom path |
| **Validate agent** | `validate-core` plus adapter smoke for one agent |
| **Sync then validate** | Sync, then smoke the same target |
| **Validate core only** | Repo contracts only. No agent-home write |
| **Validation lab** | Run `validate-core` or an `Invoke-*CiSmoke` script |
| **Uninstall agent** | Remove keyed toolkit files from InstallRoot. Keeps `sdd/sessions` and `sdd/manifest.json` |
| **Help and docs** | In-menu explanation of actions and flags |

Safe learning path:

1. **Validate core only** — the repo is healthy, and nothing is written under your profile.
2. **Sync agent** → for example `cursor` → **Live agent home** (Enter) → confirm the write.
3. To learn without touching the profile, choose **In-repo fixture**.
4. **Validate agent** for the same agent and target.

| Action | Script | Writes an agent home? |
|--------|--------|------------------------|
| Validate core | `scripts/validation/validate-core.ps1` | No |
| Validate agent | `scripts/validate-agent.ps1 -Agent <id>` | Only if you chose a live or custom InstallRoot |

### Non-interactive `-Action`

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action SyncAndValidate -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

Sync, Validate, and Uninstall require `-Agent` when you skip the menu.

| Flag | Purpose |
|------|---------|
| `-Agent` | Registry id (`cursor`, `claude`, …) |
| `-InstallRoot` | Target root. Omit it and the adapter uses its in-repo fixture |
| `-AllowUserHome` | Required when InstallRoot resolves under `%USERPROFILE%` / `$HOME` |
| `-Mode` | Required for `copilot`: `user` or `repo` |
| `-Quiet` / `-SkipSmoke` | Forwarded to validate-agent / validate-core |
| `-Action Backup` | Exits with failure unless `-ForceStub` (tests). It does not call an adapter |

Optional CI-like smoke from a clone:

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
```

## Sync

The interactive wizard defaults to **[1] Live agent home** (Enter). Confirm before the write. Choose **[2] In-repo fixture** to keep the profile untouched.

Omitting `-InstallRoot` on `sync-agent.ps1` or `-Action Sync` uses the fixture under `scripts/validation/fixtures/`. That is the CI-safe default. It does not change your live agent home.

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
```

### Live home

Paths under `%USERPROFILE%` / `$HOME` are refused unless you pass `-AllowUserHome`.

Cursor → `~/.cursor`:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

If you also sync Claude, Codex, or other agents, turn off Cursor’s **Include third-party Plugins, Skills, and other configs** so the installs stay separate.

Claude Code → `~/.claude`:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude `
  -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

GitHub Copilot requires `-Mode`:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode user `
  -InstallRoot "$env:USERPROFILE\.copilot" -AllowUserHome

pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode repo `
  -InstallRoot "D:\Source\MyApp\.github"
```

Mode `repo` usually points at the consumer repo’s `.github` folder, so `-AllowUserHome` is often unnecessary.

| Agent | Typical InstallRoot |
|-------|---------------------|
| `antigravity` | `$env:USERPROFILE\.gemini` |
| `codex` | `~/.codex` (product, AGENTS, rules). `$` skills under `~/.codex/skills`. Optional USER skills `~/.agents/skills` via `-UserScope` and `-AllowUserHome` |
| `opencode` | `$env:USERPROFILE\.config\opencode` |
| `grok` | `$env:USERPROFILE\.grok` |
| `zcode` | `$env:USERPROFILE\.zcode` |
| `hermes` | `$env:USERPROFILE\.hermes` (skills and `AGENTS.md` sit directly under that root) |
| `openhands` | Project tree as InstallRoot. User skills: `$env:USERPROFILE\.agents` with `-AllowUserHome` (skills land at `skills/`) |

Add `-AllowUserHome` whenever InstallRoot resolves under the user profile. Hermes live home may also be `%LOCALAPPDATA%\hermes` or `$env:HERMES_HOME`. Detail: [Adapters](adapters.md).

Dry run:

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -WhatIf
```

## What sync publishes

| Agent | Typical artifacts under InstallRoot |
|-------|-------------------------------------|
| Cursor | `skills/`, `rules/*.mdc`, `AGENTS.md`, `hooks/`, `hooks.json` |
| Claude | `skills/`, `rules/*.md`, `CLAUDE.md`, `hooks/`, merged `settings.json` |
| Copilot | `skills/`, `instructions/*.instructions.md`, `copilot-instructions.md`, `hooks/` |
| Codex | `plugin/` (and marketplace), `skills/` (`$` mirror), `rules/*.md`, materialized `AGENTS.md`. Optional `.agents/skills` with `-UserScope` |
| OpenCode | `skills/`, `AGENTS.md`, `plugins/*.js` |
| Grok | `skills/`, `rules/`, `hooks/`, `AGENTS.md` (InstallRoot is `~/.grok`) |
| ZCode | `skills/`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json` |
| Hermes | `skills/`, `AGENTS.md` (router plus folded policy; no `rules/`). Seeds `MEMORY.md` if missing. Never writes `SOUL.md` |
| OpenHands | Project: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/hooks.json` plus `hooks/*.sh`, `.plugin/plugin.json`. User skills: `skills/` under `~/.agents` |
| Antigravity | `config/skills`, `config/plugins`, managed markdown |

Every sync also prepares `<InstallRoot>/sdd/` (`sessions/` plus `manifest.json`) via `Get-SddRoot -Prepare`.

### Where feature files land

After prepare, `manifest.json` (schema **v2**) lives under the effective SDD root (`effective_SDD_ROOT` = `<InstallRoot>/sdd`). Per-project settings are `repositories[<cwd>].classic.storage_mode` and `.path`.

| Mode | Where artifacts land |
|------|----------------------|
| **repository** | `$Cwd/features/` and `$Cwd/memory-bank/` |
| **global** | Path under the SDD root (`classic.path`, typically `{{SDD_ROOT}}/<repo-id>/`) — `features/` and `memory-bank/` together there |

Use portable paths in artifact bodies (`features/NNN-slug/US01/PRD/...`). In **repository** mode, default `features_versioned: false` adds `/features/` to `.gitignore` (plus `/docs/features/` and PRD/PLAN safety nets). Set it to `true` to version those trees. Always keep `!/docs/documentation-plan/plan.md`. Global mode does not edit the project `.gitignore`.

The seed never overwrites an existing manifest. Full contract: `core/sdd/STORAGE.md`.

## Verify

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
```

Or open **Validation lab** in the menu. After a live Cursor sync, files such as these should exist:

```text
%USERPROFILE%\.cursor\AGENTS.md
%USERPROFILE%\.cursor\skills\sdd-spec\SKILL.md
%USERPROFILE%\.cursor\rules\guardrails.mdc
```

Restart the agent or reload the window if skills do not appear. Trust hooks in the agent UI if it asks. That trust step is manual and is outside CI.

On first sync, if `preferences.json` is missing under the SDD root, the wizard asks **Always orchestrate** (default) or **Adaptive**.

## Open the project, then the first skill

Open the **application** repo in the agent (this toolkit repo alone is not the consumer project).

Canonical form is the **skill id**. Host prefixes differ (`/`, `$`, `use skill`, OpenCode `skill` tool). After Copilot sync, run `/skills reload`. One example of each skill is on [First use](first-use.md).

Start a feature with analyze. Cursor and Claude:

```text
/orchestrate-analyze
```

Codex and ZCode: `$orchestrate-analyze`. OpenCode: `skill({ name: "orchestrate-analyze" })`.

That skill classifies the request and asks. A clear story can use `/sdd-spec`. One product item, with no feature delivery, uses `/refine-story`. The gates, storage question, and later phases are on [Orchestrated Delivery](orchestrated-delivery.md).

## Uninstall

Uninstall is keyed on every registered adapter. It removes toolkit-managed skills, policy, router files, and hooks. It keeps `sdd/sessions/` and `sdd/manifest.json`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

The menu **Uninstall agent** uses the same target wizard as Sync.

## After `git pull`

Re-run sync for each agent you use. Sync updates managed files in place and prunes managed skills that no longer exist in `core/skills/`. It keeps `sdd/sessions/` and an existing `sdd/manifest.json`. Every sync runs `Get-SddRoot -Prepare`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

