# Getting started

End-to-end path from Release bootstrap (or clone) to first skill invoke.

## Prerequisites

Supported OS: **Windows**, **Linux** (Ubuntu, Debian, and derivatives), and **macOS**.

| Requirement | Notes |
|-------------|--------|
| **PowerShell** | **Windows:** 5.1+ or **pwsh 7+** (recommended). **Linux / macOS:** **pwsh 7+ only**. Details: [INSTALL.md § Prerequisites](../INSTALL.md#prerequisites) |
| **Git** | Optional — only for the clone alternative |

## 0. Release bootstrap (recommended)

Download an entrypoint from the latest Release, then run it. Fixed assets: `agent-dev-toolkit.zip` + `agent-dev-toolkit.zip.sha256`. After extract, interactive `toolkit.ps1` opens (Smart Manager). No Git / `gh` / Node / `.exe`. Details: [INSTALL.md § 0](../INSTALL.md#0-release-bootstrap-https--checksum--toolkit).

Windows:

```bat
curl.exe -fsSL -o bootstrap.bat https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.bat
bootstrap.bat
```

(`bootstrap.bat` auto-fetches `bootstrap.ps1` if missing.)

Linux / macOS:

```bash
curl -fsSL -o bootstrap.ps1 https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.ps1
pwsh -NoProfile -File ./bootstrap.ps1
# or bootstrap.sh from the same Release URL
```

Optional non-interactive sync instead of Smart Manager: add `-DirectSync -Agent cursor` (and `-SyncWhatIf` for a safe smoke). Tests: `-SkipSync` / `-NoExtract`.

## 1. Clone the toolkit (alternative)

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## 2. Open the Smart Manager (after bootstrap or clone)

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

Option 0 opens this automatically after extract. From a clone, run the command above. Interactive menu with agent/target wizards and **Help and docs**. **Option 2+** (`-Action Sync` / `sync-agent.ps1`, or bootstrap `-DirectSync`) is for scripting and CI.
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

On first sync, if `preferences.json` is missing under the SDD root, the wizard asks **Always orchestrate** (default) vs **Adaptive** — see [08-orchestrator-mode.md](08-orchestrator-mode.md).

## 6. Run your first skill

Canonical form is the **skill id**. Host prefixes differ (`/id`, `$id`, `use skill id`, OpenCode `skill` tool) — see [02-using-skills.md](02-using-skills.md).

Classic SDD — create a PRD (Cursor/Claude example with `/`):

```text
/sdd-spec
```

Codex / ZCode: `$sdd-spec`. OpenCode: `skill({ name: "sdd-spec" })`.

**First Classic SDD / Orchestrated Delivery write:** the agent asks whether to store SDD artifacts **local (repository)** or **global**. That choice sets where `features/` and `memory-bank/` land for the project (same root for both; never bank under `features/NNN-slug/`).

| Choice | PRD / PLAN / feature tree | Memory bank |
|--------|-------------|-------------|
| Repository | `$Cwd/features/NNN-slug/...` | `$Cwd/memory-bank/` |
| Global | Under `classic.path` on the SDD root (outside the consumer git tree) | Same `<path>/memory-bank/` |

Use **portable paths** in artifacts and slash handoffs (e.g. `features/NNN-slug/US01/PRD/...`), not OS absolute paths. In **repository** mode the agent may add `/features/` to `.gitignore` when `features_versioned` is false (default); choose versioned features when you want those trees in git. There is **no** flat `PRD/` or `PLAN/` at the repo root — only under `features/NNN-slug/USnn|TSnn/`. Details: [STORAGE.md](../../core/sdd/STORAGE.md), [domains/core.md](../domains/core.md) § SDD.

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
| Which work track / skill | [guides/README.md](README.md) |
| Invoke tips per agent | [02-using-skills.md](02-using-skills.md) |
| Full catalog | [SKILLS.md](../SKILLS.md) |
| Adapter layouts | [ADAPTERS.md](../ADAPTERS.md) |
| App architecture A/B/C + confirm gate | [domains/core.md](../domains/core.md) § Code guidelines |

Greenfield domain work: prefer Orchestrated Delivery (`orchestrate-analyze`) so the architect confirm gate can run before implementers load a style overlay — see [02-using-skills.md](02-using-skills.md).
