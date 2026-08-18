# Getting started

End-to-end path from clone to first skill invoke.

## 1. Clone the toolkit

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## 2. Open the Smart Manager (option 1)

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

This is the **recommended** entry point (option 1). The menu clears the screen, walks you through agent + target selection, and includes **Help and docs**. **Option 2+** (`-Action Sync` / `sync-agent.ps1`) is for scripting and CI — see [INSTALL.md](../INSTALL.md).

Quick path to learn safely:

1. **Validate core only** — confirms the repo is healthy (no home write).
2. **Sync agent** → pick e.g. `cursor` → **Live agent home** (Enter = default) → confirm write under your profile.
3. To learn without touching the profile: same flow → **In-repo fixture** instead.
4. **Validate agent** for the same agent/target.

Non-interactive equivalents and all flags: [INSTALL.md](../INSTALL.md).

## 3. Validate the repo (no home write)

From the menu: **Validate core only**, or:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
```

Optional — same smokes CI runs (menu **Validation lab**, or):

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
```

## 4. Sync your agent

### Option 1 — interactive wizard

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

Choose **Sync agent**, then:

| Target | Use when |
|--------|----------|
| In-repo fixture | Learning / CI-safe (non-interactive omit `-InstallRoot`) |
| Live agent home | Deploy to `~/.cursor`, `~/.claude`, … (wizard Enter default) |
| Custom path | Unusual InstallRoot |

Copilot: the wizard asks for **Mode** `user` or `repo`.

### Option 2+ — scripting / CI

```powershell
# Fixture
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor

# Live Cursor home
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

Same orchestrators as the menu: `sync-agent.ps1` is equivalent for scripting. More agents (including Hermes and OpenHands) and uninstall: [INSTALL.md](../INSTALL.md).

## 5. Open a consumer project

In Cursor / Claude / Copilot / … open the **application** repo you want to change (not only `agent-dev-toolkit`).

Confirm skills are visible (Cursor example after live sync):

```text
%USERPROFILE%\.cursor\skills\sdd-spec\SKILL.md
```

Restart the agent or reload the window if skills do not appear immediately. Trust hooks in the agent UI if prompted (manual; not part of CI).

## 6. Run your first skill

Canonical form is the **skill id**. Host prefixes differ (`/id`, `$id`, `use skill id`, OpenCode `skill` tool) — see [02-using-skills.md](02-using-skills.md).

Classic SDD — create a PRD (Cursor/Claude example with `/`):

```text
/sdd-spec
```

Codex / ZCode: `$sdd-spec`. OpenCode: `skill({ name: "sdd-spec" })`.

**First Classic / Forma C write:** the agent asks whether to store SDD artifacts **local (repository)** or **global**. That choice sets where `features/` and `memory-bank/` land for the project (same root for both; never bank under `features/NNN-slug/`).

| Choice | PRD / PLAN / feature tree | Memory bank |
|--------|---------------------------|-------------|
| Repository | `$Cwd/features/NNN-slug/...` | `$Cwd/memory-bank/` |
| Global | Under `classic.path` on the SDD root (outside the consumer git tree) | Same `<path>/memory-bank/` |

There is **no** flat `PRD/` or `PLAN/` at the repo root — only under `features/NNN-slug/USnn|TSnn/`. Details: [STORAGE.md](../../core/sdd/STORAGE.md), [domains/core.md](../domains/core.md) § SDD.

Then plan and implement one step:

```text
sdd-plan - <prd-path>
sdd-develop - <plan-path> - Step 1
```

Small change without full SDD:

```text
developer
```

or a stack skill such as `dotnet-developer` / `react-developer`.

## 7. Next reading

| Goal | Doc |
|------|-----|
| Which Forma / skill | [guides/README.md](README.md) |
| Invoke tips per agent | [02-using-skills.md](02-using-skills.md) |
| Full catalog | [SKILLS.md](../SKILLS.md) |
| Adapter layouts | [ADAPTERS.md](../ADAPTERS.md) |
| App architecture A/B/C + confirm gate | [domains/core.md](../domains/core.md) § Code guidelines |

Greenfield domain work: prefer Forma C (`orchestrate-analyze`) so the architect confirm gate can run before implementers load a style overlay — see [02-using-skills.md](02-using-skills.md).
