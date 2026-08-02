# Get started

Clone the toolkit, validate the repo, sync an agent, then invoke a skill in an **application project** (the project you are building).

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| **PowerShell** | Windows: 5.1+ or pwsh 7+. macOS/Linux: pwsh 7+ |
| **Git** | Clone / update this repo |
| **Target agent** | At least one of: Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, ZCode ADE (agent filesystem host) |

## 1. Clone

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## 2. Open the interactive toolkit menu (Smart Manager)

Primary entry — agent/target wizards and Help:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

| Menu | Result |
|------|--------|
| **Validate core only** | Repo contracts only — **no** install-root write |
| **Sync agent** | Publish skills/policy/hooks to a chosen target |
| **Validate agent** | `validate-core` + adapter smoke test for one agent |
| **Sync then validate** | Sync, then smoke-test the same target |
| **Uninstall agent** | Remove **toolkit-managed** (**keyed**) files (not a full install wipe) |

## 3. Validate the repo (safe)

Confirms the toolkit is healthy without writing an agent install root:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
```

## 4. Sync an agent

### Safe default — in-repo fixture

Non-interactive sync **omits** `-InstallRoot` and writes the adapter fixture under `scripts/validation/fixtures/`. Use this for learning and CI-safe checks; it does **not** change your live install.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
```

In the interactive menu, pick **In-repo fixture** when you want the same safe path.

### Live install — explicit opt-in

Paths under `%USERPROFILE%` / `$HOME` are refused unless you pass `-AllowUserHome` (or confirm in the wizard). Interactive Sync defaults the target menu to **Live agent home** (the live install path) — confirm before write.

#### Cursor → `~/.cursor`

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

#### Claude Code → `~/.claude`

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude `
  -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

#### GitHub Copilot — Mode required

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode user `
  -InstallRoot "$env:USERPROFILE\.copilot" -AllowUserHome

pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode repo `
  -InstallRoot "D:\Source\MyApp\.github"
```

Mode `repo` InstallRoot is usually the application project's `.github` folder, so `-AllowUserHome` is often unnecessary.

#### Other live install paths

| Agent | Typical InstallRoot |
|-------|---------------------|
| `antigravity` | `$env:USERPROFILE\.gemini` |
| `codex` | `~/.codex` (USER skills: `~/.agents/skills`) |
| `opencode` | `$env:USERPROFILE\.config\opencode` |
| `grok` | `$env:USERPROFILE\.grok` |
| `zcode` | `$env:USERPROFILE\.zcode` |

Always add `-AllowUserHome` when InstallRoot resolves under the user profile. Layout details: [Adapters](../adapters/).

### Dry run

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -WhatIf
```

## 5. What gets published

Every sync prepares `<InstallRoot>/sdd/` (`sessions/` + `manifest.json`). Typical artifacts:

| Agent | Under InstallRoot |
|-------|-------------------|
| Cursor | `skills/`, `rules/*.mdc`, `AGENTS.md`, `hooks/` |
| Claude | `skills/`, `rules/*.md`, `CLAUDE.md`, hooks + merged `settings.json` |
| Copilot | `skills/`, `instructions/`, `copilot-instructions.md` |
| Others | See [Adapters](../adapters/) and [Architecture](../architecture/) |

## 6. Open an application project

Open the **application** repo you want to change (not only this toolkit). After a live Cursor sync, confirm files such as:

```text
%USERPROFILE%\.cursor\AGENTS.md
%USERPROFILE%\.cursor\skills\sdd-spec\SKILL.md
```

Restart or reload the agent if skills do not appear. Trust hooks in the agent UI if prompted.

## 7. First skill

```text
/sdd-spec
```

Then plan and implement one step:

```text
/sdd-plan - <prd-path>
/sdd-develop - <plan-path> - Step 1
```

Small change without full SDD: `/developer` or a stack skill such as `/dotnet-developer`. Choosing a workflow (**Forma** A/B/C): [Using skills](../using-skills/).

After `/commit` and `/push`, open a PR with `/open-github-pr` (feature → `develop`; release mode `develop` → `master`/`main`). Details: [Using skills](../using-skills/).

## 8. After `git pull`

Re-run sync for each agent you use. Sync is **update-in-place**: overwrites managed files and prunes managed skills removed from `core/skills/`. It preserves `sdd/sessions/` and `sdd/manifest.json`.

## 9. Uninstall (toolkit-managed)

Removes toolkit-managed skills, policy/rules, router files, and hooks — not the entire agent install. Preserves `sdd/sessions/` and `sdd/manifest.json`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Sync refuses InstallRoot | Add `-AllowUserHome` or confirm in the wizard |
| Copilot sync failed (missing Mode) | Pass `-Mode user` or `-Mode repo` |
| Skills missing in IDE | Sync **live install**; restart/trust hooks if required |
| Expected an install-root write in CI-like run | Use fixtures / omit live InstallRoot |

Next: [Using skills](../using-skills/) · [Adapters](../adapters/) · [Maintainers](../maintainers/)
