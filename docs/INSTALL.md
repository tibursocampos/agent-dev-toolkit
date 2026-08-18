# Install and sync

Deploy **agent-dev-toolkit** core content into one or more coding agents via adapters.

**Option 1 (recommended):** interactive Smart Manager — `pwsh -NoProfile -File .\scripts\toolkit.ps1` (first command after clone). **Option 2+:** `-Action Sync` / `sync-agent.ps1` for scripting and CI.

> **Repository policy:** public — clone and fork freely. **No upstream contributions.** See [CONTRIBUTING.md](../CONTRIBUTING.md).

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| **PowerShell** | Windows: **5.1+** or **pwsh 7+**. macOS/Linux: **pwsh 7+** ([install guide](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)) |
| **Git** | Clone / update this repo |
| **Target agent** | At least one of: Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, ZCode ADE, Hermes, OpenHands |

## 1. Clone

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## 2. Toolkit CLI (option 1 — recommended)

**Primary entry** — interactive Smart Manager (clear screen, agent/target wizards, Help):

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

| Menu | What it does |
|------|----------------|
| **Sync agent** | Publish skills/policy/hooks — wizard picks agent, then **live home (Enter default)** / fixture / custom path |
| **Validate agent** | `validate-core` + adapter smoke for one agent |
| **Sync then validate** | Sync, then smoke the same target |
| **Validate core only** | Repo contracts only — **no** agent home write |
| **Validation lab** | Run `validate-core` or an `Invoke-*CiSmoke` script |
| **Uninstall agent** | Remove **keyed** toolkit files from InstallRoot (not a full home wipe). Preserves `sdd/sessions` and `sdd/manifest.json` |
| **Help and docs** | In-menu explanation of actions and equivalent flags |

### Validate core vs Validate agent

| Action | Script | Writes agent home? |
|--------|--------|--------------------|
| Validate core | `scripts/validation/validate-core.ps1` | No |
| Validate agent | `scripts/validate-agent.ps1 -Agent <id>` | Only if you chose live/custom InstallRoot |

### Non-interactive `-Action` (CI / scripting)

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action SyncAndValidate -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

Sync / Validate / Uninstall **require** `-Agent` when not using the menu (no silent Cursor/home default).

| Flag | Purpose |
|------|---------|
| `-Agent` | Registry id (`cursor`, `claude`, …) |
| `-InstallRoot` | Target root (omit = adapter in-repo fixture) |
| `-AllowUserHome` | Required when InstallRoot resolves under `%USERPROFILE%` / `$HOME` |
| `-Mode` | Required for `copilot`: `user` or `repo` |
| `-Quiet` / `-SkipSmoke` | Forwarded to validate-agent / validate-core |
| `-Action Backup` | Not implemented (fail-closed unless `-ForceStub` for tests) |

## 3. Sync to an agent (option 2+ — direct scripts)

Prefer the menu (option 1) for day-to-day use. These call the same orchestrators the CLI uses.

### Interactive Sync: live home is the wizard default

In `toolkit.ps1` (no `-Action`), after picking an agent the target menu defaults to **[1] Live agent home** (Enter). Confirm before write. Choose **[2] In-repo fixture** to avoid profile writes.

### Non-interactive default: in-repo fixture (CI-safe)

Omitting `-InstallRoot` on `sync-agent.ps1` / `-Action Sync` uses the adapter’s fixture under `scripts/validation/fixtures/`. Safe for local smoke and CI; does **not** change your live agent home.

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
# or via toolkit:
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
```

### Live home: `-AllowUserHome`

Paths under `%USERPROFILE%` / `$HOME` are refused unless you pass `-AllowUserHome`.

#### Cursor → `~/.cursor`

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

If you also sync Claude/Codex (or other agents), disable Cursor’s **Include third-party Plugins, Skills, and other configs** so installs stay isolated — see [adapters/cursor/README.md](../adapters/cursor/README.md#multi-agent-installs--third-party-skills).

#### Claude Code → `~/.claude`

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude `
  -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

#### GitHub Copilot — Mode `user` | `repo`

`-Mode` is **required** for Copilot.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode user `
  -InstallRoot "$env:USERPROFILE\.copilot" -AllowUserHome

pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode repo `
  -InstallRoot "D:\Source\MyApp\.github"
```

Mode `repo` InstallRoot is typically the consumer repo’s `.github` folder (not under USERPROFILE), so `-AllowUserHome` is often unnecessary.

#### Other agents (live roots)

| Agent | Typical InstallRoot |
|-------|---------------------|
| `antigravity` | `$env:USERPROFILE\.gemini` |
| `codex` | `~/.codex` (product/AGENTS/rules); `$` skills `~/.codex/skills`; optional USER skills `~/.agents/skills` via `-UserScope` + `-AllowUserHome` — see [ADAPTERS.md](ADAPTERS.md) § Codex |
| `opencode` | `$env:USERPROFILE\.config\opencode` |
| `grok` | `$env:USERPROFILE\.grok` |
| `zcode` | `$env:USERPROFILE\.zcode` |
| `hermes` | `$env:USERPROFILE\.hermes` (skills + `AGENTS.md` directly under that root — not `~/.hermes/.hermes/skills`) |
| `openhands` | Project tree as InstallRoot; user skills `$env:USERPROFILE\.agents` + `-AllowUserHome` (skills land at `skills/`, not `~/.agents/.agents/skills`) |

Always add `-AllowUserHome` when the InstallRoot resolves under the user profile.

### Dry run

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -WhatIf
```

## 4. What gets published (by agent)

| Agent | Typical artifacts under InstallRoot |
|-------|-------------------------------------|
| Cursor | `skills/`, `rules/*.mdc`, `AGENTS.md`, `hooks/`, `hooks.json` |
| Claude | `skills/`, `rules/*.md`, `CLAUDE.md`, `hooks/`, merged `settings.json` |
| Copilot | `skills/`, `instructions/*.instructions.md`, `copilot-instructions.md`, `hooks/` |
| Codex | `plugin/` (+ marketplace), `skills/` (`$` mirror), `rules/*.md`, materialized `AGENTS.md`; optional `.agents/skills` with `-UserScope` |
| OpenCode | `skills/`, `AGENTS.md`, `plugins/*.js` |
| Grok | `skills/`, `rules/`, `hooks/`, `AGENTS.md` (InstallRoot = `~/.grok`) |
| ZCode | `skills/`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json` |
| Hermes | `skills/`, `AGENTS.md` (router + folded policy; no `rules/`); seed `MEMORY.md` if missing (never `SOUL.md`) |
| OpenHands | Project: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/hooks.json` + `hooks/*.sh`, `.plugin/plugin.json`. User skills: `skills/` under `~/.agents` |
| Antigravity | `config/skills`, `config/plugins`, managed markdown |

Every sync also prepares `<InstallRoot>/sdd/` (`sessions/` + `manifest.json`) via `Get-SddRoot -Prepare`.

### Storage (SDD artifacts)

After prepare, `manifest.json` (schema **v2**) lives under the effective SDD root (`effective_SDD_ROOT` = `<InstallRoot>/sdd`; docs may still say `{{SDD_ROOT}}`). Per-project Classic settings are `repositories[<cwd>].classic.storage_mode` and `.path`.

| Mode | Where artifacts land |
|------|----------------------|
| **repository** | `$Cwd/features/` + `$Cwd/memory-bank/` |
| **global** | Path under the SDD root (`classic.path`, typically `{{SDD_ROOT}}/<repo-id>/`) — `features/` + `memory-bank/` co-located there |

Seed never overwrites an existing manifest. Full contract: [STORAGE.md](../core/sdd/STORAGE.md). Domain summary: [domains/core.md](domains/core.md) § SDD.

Full layouts: [ARCHITECTURE.md](ARCHITECTURE.md), [ADAPTERS.md](ADAPTERS.md).

## 5. Verify

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
```

Or open **Validation lab** in the interactive menu to run CI smokes. Details: [VALIDATION.md](VALIDATION.md).

After a live Cursor sync, confirm files such as:

```text
%USERPROFILE%\.cursor\AGENTS.md
%USERPROFILE%\.cursor\skills\sdd-spec\SKILL.md
%USERPROFILE%\.cursor\rules\guardrails.mdc
```

## 6. Use skills

Open a **consumer project** in the agent (not only this toolkit repo). Canonical form is the **skill id**; host prefixes differ (`/`, `$`, `use skill`, OpenCode `skill` tool). Matrix: [guides/02-using-skills.md](guides/02-using-skills.md).

Cursor / Claude example:

```text
/sdd-spec
```

Codex / ZCode: `$sdd-spec`. After Copilot sync: `/skills reload`.

See [guides/01-getting-started.md](guides/01-getting-started.md) and [guides/02-using-skills.md](guides/02-using-skills.md).

## 7. Uninstall

Uninstall is **keyed** for every registered adapter: removes toolkit-managed skills, policy/rules, router files, and hooks — not the entire agent home. It **preserves** `sdd/sessions/` and `sdd/manifest.json` (operator runtime state).

CI keyed-uninstall asserts cover all adapters, including Hermes and OpenHands.

Use menu **Uninstall agent** (same wizard as Sync for target), or:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

Details per agent: [ADAPTERS.md](ADAPTERS.md) and `adapters/<agent>/` notes.

## 8. After `git pull`

Re-run sync for each agent you use. Sync is **update-in-place**: it overwrites managed files and **prunes** managed skills that no longer exist in `core/skills/`. It does **not** uninstall then reinstall. `sdd/sessions/` and `sdd/manifest.json` stay intact (manifest is never overwritten if already present). Every sync always runs `Get-SddRoot -Prepare` (creates `sdd/sessions/` if missing; seeds `manifest.json` only when absent).

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
# Sync agent → your agent → live home
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Sync refuses InstallRoot | Path under USERPROFILE without opt-in | Add `-AllowUserHome` or confirm in the wizard |
| Copilot TE02 | Missing/invalid `-Mode` | Pass `-Mode user` or `-Mode repo` (menu asks) |
| Skills missing in IDE | Synced fixture only, or agent needs restart/trust | Sync **live home**; trust hooks in the agent UI if required |
| CI-like local fail | Expecting home write | Use fixtures / Validation lab smokes without live home |

Next: [VALIDATION.md](VALIDATION.md) · [SKILLS.md](SKILLS.md) · [guides/README.md](guides/README.md)
