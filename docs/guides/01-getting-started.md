# Getting started

End-to-end path from clone to first skill invoke.

## 1. Clone the toolkit

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## 2. Open the Smart Manager

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

This is the **recommended** entry point. The menu clears the screen, walks you through agent + target selection, and includes **Help and docs**.

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

### Recommended — interactive wizard

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

Choose **Sync agent**, then:

| Target | Use when |
|--------|----------|
| In-repo fixture | Learning / CI-safe (default) |
| Live agent home | Deploy to `~/.cursor`, `~/.claude`, … |
| Custom path | Unusual InstallRoot |

Copilot: the wizard asks for **Mode** `user` or `repo`.

### Scripting shortcuts

```powershell
# Fixture
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor

# Live Cursor home
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

More agents and uninstall: [INSTALL.md](../INSTALL.md).

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
