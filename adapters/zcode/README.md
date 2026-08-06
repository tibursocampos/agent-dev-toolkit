# ZCode adapter (`zcode`)

Publish surfaces for **ZCode ADE** (`~/.zcode`). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `zcode` |
| Purpose | Publish skills, hooks, and router into a ZCode InstallRoot |
| Sync fixture | `scripts/validation/fixtures/zcode-install-root` |
| `subagents` (registry) | `native` |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent zcode -InstallRoot .\scripts\validation\fixtures\zcode-install-root
```

## How to invoke

| Item | Value |
|------|-------|
| Skills path (live) | `~/.zcode/skills/<id>/SKILL.md` |
| Explicit form | `$id` |
| Examples | `$help-skills`, `$sdd-spec` |
| After sync | Settings → Skills → Refresh if the product requires it |

Canonical form is the skill **id**; `$` is the ZCode host prefix (same token as Codex, different product).

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Primary launches subagents via **Agent** tool; built-ins `general-purpose` / `Explore`; custom under `~/.zcode/agents/` |
| Toolkit contract | Prefer Agent tool when `subagents=native`; SPAWN fallback otherwise |

Do not confuse with the unrelated open-source CLI named “Z-CODE” (different project).

## Uninstall (keyed)

Removes only toolkit-managed paths (core skill ids) and reverse-merges `cli/config.json` / `hooks/hooks.json` (drop toolkit overlay; keep aliens). **`AGENTS.md` is deleted only when provenance confirms toolkit ownership** via InstallRoot `.toolkit-managed-publish.json` (sha256 recorded on publish) or a legacy hash match to resolved `core/router/AGENTS.md`; operator edits are preserved. Preserves alien skills/hooks and **does not** remove `sdd/sessions` or `sdd/manifest.json`. Does **not** wipe InstallRoot wholesale. Supports `-WhatIf`.

### Official references

- [Agents / AGENTS.md](https://zcode.z.ai/en/docs/agents)
- [Subagents](https://zcode.z.ai/en/docs/subagents)
- [Skills](https://zcode.z.ai/en/docs/skill)
- [Hooks](https://zcode.z.ai/en/docs/hooks)
- [Plugins](https://zcode.z.ai/en/docs/plugin)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
